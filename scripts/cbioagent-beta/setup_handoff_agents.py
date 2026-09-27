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
import re
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

# Sections of the unified agent's instructions that drive navigation. The data agent has no
# navigator tools, so they are removed from its copy; a missing heading or a navigator tool
# name left afterwards is a hard error rather than a silently mis-instructed agent.
NAV_SECTIONS = ("Capability Selection", "Navigate Workflow", "Link First")
NAV_BRANCH_MARKER = "Navigation only:"
NAV_TOOL_MARKERS = ("navigate_to_", "resolve_and_route", "get_studyviewfilter_options")
HEADING = re.compile(r"^(#{1,6})\s+(.+?)\s*#*\s*$")

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
    "tenantId",
)


def read_prompt(name):
    return (PROMPTS_DIR / f"{name}.md").read_text().strip()


def indent_of(line):
    return len(line) - len(line.lstrip())


def is_block_start(line, indent):
    stripped = line.lstrip()
    return indent_of(line) <= indent and (
        HEADING.match(stripped) is not None or re.match(r"(?:[-*+]|\d+[.)]|\*\*)\s*", stripped) is not None
    )


def strip_navigation(instructions):
    """Remove the NAV_SECTIONS sections and the NAV_BRANCH_MARKER item from `instructions`.

    Returns (stripped text, headings/items removed).
    """
    if NAV_BRANCH_MARKER not in instructions:
        raise ValueError(f"marker {NAV_BRANCH_MARKER!r} not found")
    lines = instructions.splitlines()
    drop = set()

    headings = [(i, len(m.group(1)), m.group(2)) for i, line in enumerate(lines) if (m := HEADING.match(line))]
    for title in NAV_SECTIONS:
        matches = [(i, level) for i, level, text in headings if text == title]
        if not matches:
            raise ValueError(f"heading {title!r} not found")
        for start, level in matches:
            end = next((i for i, lvl, _ in headings if i > start and lvl <= level), len(lines))
            drop.update(range(start, end))
    removed = [lines[i].strip() for i, _, _ in headings if i in drop]

    for start, line in enumerate(lines):
        if NAV_BRANCH_MARKER not in line or start in drop:
            continue
        indent = indent_of(line)
        end = start + 1
        while end < len(lines):
            nxt = lines[end]
            if nxt.strip() and is_block_start(nxt, indent):
                break
            if not nxt.strip():
                following = next((ln for ln in lines[end + 1 :] if ln.strip()), None)
                if following is None or indent_of(following) <= indent:
                    break
            end += 1
        drop.update(range(start, end))
        removed.append(f"item {line.strip()[:60]!r}")

    stripped = "\n".join(line for i, line in enumerate(lines) if i not in drop)
    stripped = re.sub(r"\n{3,}", "\n\n", stripped).strip()
    # Checked here, before data.md is appended: data.md names these tools to forbid them.
    leftovers = sorted({m for m in NAV_TOOL_MARKERS if m in stripped})
    if leftovers:
        raise ValueError(f"navigator tool names still present after stripping: {', '.join(leftovers)}")
    return stripped, removed


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
    if "<<" in router_prompt:
        sys.exit("prompts/router.md has an unreplaced <<PLACEHOLDER>>")
    try:
        data_base, removed = strip_navigation(base_instructions)
    except ValueError as err:
        sys.exit(
            f"cannot build the data agent's instructions from {source['id']}: {err}. "
            "Update NAV_SECTIONS / NAV_BRANCH_MARKER in this script to match the unified agent's current prompt."
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
            # The router only emits one argument-free tool call. Bedrock Haiku 4.5 thinks with a
            # 2000-token budget unless `thinking` is explicitly false.
            "model_parameters": {"model": HAIKU, "thinking": False, "maxOutputTokens": 256, "temperature": 0},
            "tools": [],
            "edges": edges,
        },
        {
            "id": DATA_ID,
            "name": "cBioPortalChat Data (beta)",
            "description": "Answers data questions with the cbioportal-database MCP.",
            # The data.md override goes last so it wins over anything left in the shared prompt.
            "instructions": f"{data_base}\n\n{read_prompt('data')}".strip(),
            "model": HAIKU,
            "model_parameters": {
                "model": HAIKU,
                "thinking": False,
                "maxOutputTokens": 8192,
                "temperature": 0,
                "promptCache": True,
            },
            "tools": db_tools,
            "edges": [],
        },
        {
            "id": NAV_ID,
            "name": "cBioPortalChat Navigation (beta)",
            "description": "Builds cBioPortal links and study-view navigation.",
            "instructions": f"{read_prompt('navigation')}\n\n{base_instructions}".strip(),
            "model": SONNET,
            # No temperature. Anthropic's API rejects temperature/top_p/top_k on Sonnet 5 with a 400
            # (sampling parameters are removed on that model), and with thinking enabled it also
            # rejects any temperature other than 1 on every model. This LibreChat version drops
            # neither for Sonnet 5 before calling Bedrock, so the key must stay absent.
            "model_parameters": {
                "model": SONNET,
                "thinking": True,
                "effort": "low",
                "maxOutputTokens": 8192,
                "promptCache": True,
            },
            "tools": source_tools,
            "edges": [],
        },
    ]
    for agent in agents:
        agent.update(common)
        agent["mcpServerNames"] = mcp_server_names(agent["tools"])
        if source.get("tenantId") is not None:
            agent["tenantId"] = source["tenantId"]
    report = {
        "removed": removed,
        "base_chars": len(base_instructions),
        "stripped_chars": len(data_base),
        "data_chars": len(agents[1]["instructions"]),
        "navigate_mentions": [ln.strip() for ln in data_base.splitlines() if "Navigate" in ln],
    }
    return agents, report


def print_strip_report(report):
    print("data agent instructions, removed from the unified prompt:")
    for entry in report["removed"]:
        print(f"  - {entry}")
    print(
        f"  {report['base_chars']} -> {report['stripped_chars']} chars after stripping, "
        f"{report['data_chars']} with data.md"
    )
    for line in report["navigate_mentions"]:
        print(f"  still mentions Navigate (neutralized by data.md): {line[:100]}")


def agent_filter(agent_id, tenant_id):
    # {"tenantId": None} also matches documents with no tenantId field.
    return {"id": agent_id, "tenantId": tenant_id}


def managed_values(desired):
    return {k: desired[k] for k in MANAGED_FIELDS if k in desired}


def managed_diff(existing, desired):
    """Return ($set fields, $unset fields) that make `existing` match `desired`.

    Fields absent from `desired` (only tenantId can be) are compared as None and unset.
    """
    to_set, to_unset = {}, []
    for k in MANAGED_FIELDS:
        want = desired.get(k)
        if existing.get(k) == want:
            continue
        if want is None:
            to_unset.append(k)
        else:
            to_set[k] = want
    return to_set, to_unset


def version_snapshot(desired, now):
    snapshot = {"id": desired["id"], **managed_values(desired)}
    del snapshot["author"]
    snapshot.update(createdAt=now, updatedAt=now)
    return snapshot


def upsert_agent(db, desired, dry_run):
    now = datetime.datetime.now(datetime.timezone.utc)
    existing = db.agents.find_one(agent_filter(desired["id"], desired.get("tenantId")))
    if existing is None:
        doc = {"id": desired["id"], **managed_values(desired)}
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

    to_set, to_unset = managed_diff(existing, desired)
    if not to_set and not to_unset:
        print(f"unchanged {desired['id']}")
        return existing["_id"]
    print(f"update {desired['id']}: {', '.join(sorted([*to_set, *to_unset]))}")
    if not dry_run:
        update = {"$set": {**to_set, "updatedAt": now}, "$push": {"versions": version_snapshot(desired, now)}}
        if to_unset:
            update["$unset"] = {k: "" for k in to_unset}
        db.agents.update_one({"_id": existing["_id"]}, update)
    return existing["_id"]


def warn_other_tenants(db, tenant_id):
    """Report managed ids under another tenant: left behind if the source agent's tenantId changed."""
    for doc in db.agents.find({"id": {"$in": list(MANAGED_IDS)}}, {"id": 1, "tenantId": 1}):
        if doc.get("tenantId") != tenant_id:
            print(
                f"note: {doc['id']} also exists with tenantId={doc.get('tenantId')!r}; not touched. "
                "If it is stale, remove it by hand."
            )


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


def delete_agents(db, tenant_id, dry_run):
    for agent_id in MANAGED_IDS:
        existing = db.agents.find_one(agent_filter(agent_id, tenant_id), {"_id": 1})
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

    source = db.agents.find_one({"id": args.source_agent})
    if source is None:
        # --delete needs it too: its tenantId scopes which copies of the managed ids are removed.
        sys.exit(f"source agent {args.source_agent} not found in {db.name}.agents")
    tenant_id = source.get("tenantId")
    if args.delete:
        delete_agents(db, tenant_id, args.dry_run)
        return

    agents, report = build_agents(source)
    if args.dry_run:
        print_strip_report(report)
    for desired in agents:
        oid = upsert_agent(db, desired, args.dry_run)
        sync_acl(db, source["_id"], desired["id"], oid, args.dry_run)
    warn_other_tenants(db, tenant_id)


if __name__ == "__main__":
    main()
