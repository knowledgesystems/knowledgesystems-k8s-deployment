#!/usr/bin/env python3
"""Create or update the beta cBioPortalChat handoff agents: router -> data | navigation.

Beta and prod share one MongoDB, so this script writes only the three agent ids
in MANAGED_IDS and the `aclentries` rows that point at them. The unified beta
agent (--source-agent) is read for its tools, instructions, author and sharing,
never written. Safe to re-run: unchanged agents are left alone.

    MONGO_URI=mongodb://localhost:27017/cBioAgent ./setup_handoff_agents.py --dry-run
"""

import argparse
import datetime
import os
import sys
from pathlib import Path

from pymongo import MongoClient

ROUTER_ID = "agent_cbiobeta_router"
DATA_ID = "agent_cbiobeta_data"
NAV_ID = "agent_cbiobeta_navigation"
MANAGED_IDS = (ROUTER_ID, DATA_ID, NAV_ID)

DEFAULT_SOURCE_ID = "agent_OHVSJI9Gd6gwsDnFSL-Xl"
DEFAULT_DB = "cBioAgent"

HAIKU = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
SONNET = "us.anthropic.claude-sonnet-5"
PROVIDER = "bedrock"

DB_SERVER = "cbioportal-database"
MCP_DELIMITER = "_mcp_"
# LibreChat names each handoff tool `lc_transfer_to_<destination agent id>`.
TRANSFER_PREFIX = "lc_transfer_to_"

PROMPTS_DIR = Path(__file__).resolve().parent / "prompts"

MANAGED_FIELDS = (
    "name",
    "description",
    "instructions",
    "provider",
    "model",
    "model_parameters",
    "tools",
    "mcpServerNames",
    "edges",
    "author",
    "category",
)


def read_prompt(name):
    return (PROMPTS_DIR / f"{name}.md").read_text().strip()


def mcp_server_names(tools):
    return sorted({t.split(MCP_DELIMITER, 1)[1] for t in tools if MCP_DELIMITER in t})


def build_agents(source):
    source_tools = list(source.get("tools") or [])
    db_tools = [t for t in source_tools if t.endswith(MCP_DELIMITER + DB_SERVER)]
    if not db_tools:
        sys.exit(f"source agent {source['id']} has no {DB_SERVER} MCP tools; refusing to build agents without them")
    base_instructions = (source.get("instructions") or "").strip()

    router_prompt = (
        read_prompt("router")
        .replace("<<NAV_TOOL>>", TRANSFER_PREFIX + NAV_ID)
        .replace("<<DATA_TOOL>>", TRANSFER_PREFIX + DATA_ID)
    )
    edges = [
        {
            "from": ROUTER_ID,
            "to": NAV_ID,
            "edgeType": "handoff",
            "description": (
                "Navigation agent (Sonnet). Use for any question that needs a cBioPortal link, URL, "
                "study view, OncoPrint, plot, survival curve, patient view, group comparison, or cohort, "
                "including questions that first need a data lookup. Use when unsure."
            ),
        },
        {
            "from": ROUTER_ID,
            "to": DATA_ID,
            "edgeType": "handoff",
            "description": (
                "Data agent (Haiku). Use only when the answer is text or tables from cBioPortal data "
                "(counts, frequencies, study or sample lists, data availability) and needs no link or view."
            ),
        },
    ]

    common = {"provider": PROVIDER, "author": source["author"], "category": source.get("category") or "general"}
    agents = [
        {
            "id": ROUTER_ID,
            "name": "cBioPortalChat Router (beta)",
            "description": "Classifies each question and hands off to the data or navigation agent.",
            "instructions": router_prompt,
            "model": HAIKU,
            # The router only emits one argument-free tool call.
            "model_parameters": {"model": HAIKU, "temperature": 0, "maxTokens": 256},
            "tools": [],
            "edges": edges,
        },
        {
            "id": DATA_ID,
            "name": "cBioPortalChat Data (beta)",
            "description": "Answers data questions with the cbioportal-database MCP.",
            "instructions": f"{read_prompt('data')}\n\n{base_instructions}".strip(),
            "model": HAIKU,
            "model_parameters": {"model": HAIKU, "temperature": 0, "promptCache": True},
            "tools": db_tools,
            "edges": [],
        },
        {
            "id": NAV_ID,
            "name": "cBioPortalChat Navigation (beta)",
            "description": "Builds cBioPortal links and study-view navigation.",
            "instructions": f"{read_prompt('navigation')}\n\n{base_instructions}".strip(),
            "model": SONNET,
            "model_parameters": {"model": SONNET, "temperature": 0, "promptCache": True},
            "tools": source_tools,
            "edges": [],
        },
    ]
    for agent in agents:
        agent.update(common)
        agent["mcpServerNames"] = mcp_server_names(agent["tools"])
        if source.get("tenantId") is not None:
            agent["tenantId"] = source["tenantId"]
    return agents


def version_snapshot(fields, now):
    snapshot = {k: v for k, v in fields.items() if k != "author"}
    snapshot.update(createdAt=now, updatedAt=now)
    return snapshot


def upsert_agent(db, desired, dry_run):
    now = datetime.datetime.now(datetime.timezone.utc)
    existing = db.agents.find_one({"id": desired["id"]})
    if existing is None:
        doc = dict(desired)
        doc.update(
            conversation_starters=[],
            tool_resources={},
            is_promoted=False,
            versions=[version_snapshot(desired, now)],
            createdAt=now,
            updatedAt=now,
        )
        print(
            f"create {desired['id']} ({desired['model']}, {len(desired['tools'])} tools, {len(desired['edges'])} edges)"
        )
        if dry_run:
            return None
        return db.agents.insert_one(doc).inserted_id

    changed = {k: desired[k] for k in MANAGED_FIELDS if existing.get(k) != desired[k]}
    if not changed:
        print(f"unchanged {desired['id']}")
        return existing["_id"]
    print(f"update {desired['id']}: {', '.join(sorted(changed))}")
    if not dry_run:
        db.agents.update_one(
            {"_id": existing["_id"]},
            {
                "$set": {**changed, "updatedAt": now},
                "$push": {"versions": version_snapshot({k: desired[k] for k in MANAGED_FIELDS}, now)},
            },
        )
    return existing["_id"]


def acl_key(entry):
    return (entry["principalType"], entry.get("principalId"), entry["resourceType"])


def sync_acl(db, source_oid, agent_id, agent_oid, dry_run):
    """Give the managed agent exactly the sharing rows the source agent has."""
    source_rows = list(db.aclentries.find({"resourceId": source_oid}))
    if not source_rows:
        sys.exit("source agent has no aclentries rows; users could not reach the new agents")
    current = {} if agent_oid is None else {acl_key(r): r for r in db.aclentries.find({"resourceId": agent_oid})}
    wanted = set()
    for row in source_rows:
        key = acl_key(row)
        wanted.add(key)
        fields = {
            k: row[k]
            for k in (
                "principalType",
                "principalId",
                "principalModel",
                "resourceType",
                "permBits",
                "roleId",
                "grantedBy",
                "tenantId",
            )
            if k in row
        }
        have = current.get(key)
        if have is not None and all(have.get(k) == v for k, v in fields.items()):
            continue
        print(
            f"  acl {'update' if have else 'grant'} {agent_id}: {key[0]} {key[1] or ''} {key[2]} permBits={row.get('permBits')}"
        )
        if dry_run:
            continue
        if have is None:
            db.aclentries.insert_one(
                {**fields, "resourceId": agent_oid, "grantedAt": datetime.datetime.now(datetime.timezone.utc)}
            )
        else:
            db.aclentries.update_one({"_id": have["_id"]}, {"$set": fields})
    for key, row in current.items():
        if key not in wanted:
            print(f"  acl revoke {agent_id}: {key[0]} {key[1] or ''} {key[2]}")
            if not dry_run:
                db.aclentries.delete_one({"_id": row["_id"]})


def delete_agents(db, dry_run):
    for agent_id in MANAGED_IDS:
        existing = db.agents.find_one({"id": agent_id}, {"_id": 1})
        if existing is None:
            print(f"absent {agent_id}")
            continue
        acl_count = db.aclentries.count_documents({"resourceId": existing["_id"]})
        print(f"delete {agent_id} and {acl_count} aclentries rows")
        if not dry_run:
            db.aclentries.delete_many({"resourceId": existing["_id"]})
            db.agents.delete_one({"_id": existing["_id"]})


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--mongo-uri", default=os.environ.get("MONGO_URI"), help="defaults to $MONGO_URI")
    parser.add_argument("--db", default=None, help=f"database name; defaults to the URI's, else {DEFAULT_DB}")
    parser.add_argument(
        "--source-agent",
        default=DEFAULT_SOURCE_ID,
        help="unified beta agent to copy tools, instructions and sharing from",
    )
    parser.add_argument("--dry-run", action="store_true", help="print the planned changes and write nothing")
    parser.add_argument(
        "--delete", action="store_true", help="remove the three managed agents and their aclentries rows"
    )
    args = parser.parse_args()

    if not args.mongo_uri:
        parser.error("--mongo-uri or MONGO_URI is required")
    if args.source_agent in MANAGED_IDS:
        parser.error("--source-agent must not be one of the managed agents")

    client = MongoClient(args.mongo_uri, serverSelectionTimeoutMS=10000)
    db = client[args.db] if args.db else client.get_default_database(DEFAULT_DB)
    print(f"database {db.name}{' (dry run)' if args.dry_run else ''}")

    if args.delete:
        delete_agents(db, args.dry_run)
        return

    source = db.agents.find_one({"id": args.source_agent})
    if source is None:
        sys.exit(f"source agent {args.source_agent} not found in {db.name}.agents")

    for desired in build_agents(source):
        oid = upsert_agent(db, desired, args.dry_run)
        sync_acl(db, source["_id"], desired["id"], oid, args.dry_run)


if __name__ == "__main__":
    main()
