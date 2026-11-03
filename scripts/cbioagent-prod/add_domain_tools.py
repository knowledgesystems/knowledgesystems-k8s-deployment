#!/usr/bin/env python3
"""Add the four cbioportal-mcp #154 domain tools to the prod cBioPortalChat agent's tool list.

The prod agent lists its cbioportal-database tools one by one, so a new server tool is invisible to it until
it is added here. Writes only PROD_AGENT_ID. Dry run unless --apply is given. Safe to re-run: an agent that
already has the tools is left alone. The dry run only reads, so it can run at any time. Run --apply only
after the prod MCP image with #154 has rolled and a clone has applied its sql/4; see README.md.

    MONGO_URI=mongodb://localhost:27017/cBioAgent ./add_domain_tools.py
"""

import argparse
import datetime
import os
import sys

from pymongo import MongoClient

PROD_AGENT_ID = "agent_9ZXhcwLIsROBQX0u4JS5F"
DEFAULT_DB = "cBioAgent"

DB_SERVER = "cbioportal-database"
MCP_DELIMITER = "_mcp_"
# LibreChat's "every tool of this server" entry: `sys__all__sys_mcp_<server>`.
MCP_ALL = "sys__all__sys"
DOMAIN_TOOLS = tuple(
    name + MCP_DELIMITER + DB_SERVER
    for name in (
        "get_alteration_frequency",
        "get_top_altered_genes",
        "get_gene_frequency_by_cancer_type",
        "get_profiled_counts",
    )
)
# Record fields not copied into a `versions` entry.
NOT_VERSIONED = ("_id", "__v", "versions", "author")


def plan(tools, remove):
    """Return the agent's new tool list and the tools that changed; exit if the list isn't the expected shape."""
    db_tools = [t for t in tools if t.endswith(MCP_DELIMITER + DB_SERVER)]
    if not db_tools:
        sys.exit(f"{PROD_AGENT_ID} has no {DB_SERVER} tools; refusing to change an unexpected tool list")
    if MCP_ALL + MCP_DELIMITER + DB_SERVER in db_tools:
        print(f"{PROD_AGENT_ID} has the all-tools entry for {DB_SERVER}; its tool list needs no change")
        return tools, []
    if remove:
        return [t for t in tools if t not in DOMAIN_TOOLS], [t for t in DOMAIN_TOOLS if t in tools]
    missing = [t for t in DOMAIN_TOOLS if t not in tools]
    return [*tools, *missing], missing


def run(db, apply, remove=False):
    """Apply the change to `db.agents`. Returns True if the agent was, or in a dry run would be, written."""
    agents = list(db.agents.find({"id": PROD_AGENT_ID}))
    if len(agents) != 1:
        sys.exit(f"expected one {PROD_AGENT_ID} in {db.name}.agents, found {len(agents)}; changing nothing")
    agent = agents[0]

    tools = list(agent.get("tools") or [])
    new_tools, changed = plan(tools, remove)
    if not changed:
        print(f"unchanged {PROD_AGENT_ID} ({len(tools)} tools)")
        return False

    verb = "remove" if remove else "add"
    print(f"{verb if apply else 'would ' + verb} on {PROD_AGENT_ID} ({len(tools)} -> {len(new_tools)} tools):")
    for tool in changed:
        print(f"  {tool}")
    if not apply:
        return True

    now = datetime.datetime.now(datetime.timezone.utc)
    snapshot = {k: v for k, v in agent.items() if k not in NOT_VERSIONED}
    snapshot.update(tools=new_tools, createdAt=now, updatedAt=now)
    # Matching the tool list read above makes a concurrent edit in the LibreChat UI fail here, not get overwritten.
    result = db.agents.update_one(
        {"_id": agent["_id"], "tools": agent.get("tools")},
        {"$set": {"tools": new_tools, "updatedAt": now}, "$push": {"versions": snapshot}},
    )
    if result.modified_count != 1:
        sys.exit(f"{PROD_AGENT_ID} changed while this ran; nothing written. Re-run.")
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--mongo-uri", default=os.environ.get("MONGO_URI"), help="defaults to $MONGO_URI")
    parser.add_argument("--db", default=None, help=f"database name; defaults to the URI's, else {DEFAULT_DB}")
    parser.add_argument("--apply", action="store_true", help="write the change; without it, only print the plan")
    parser.add_argument("--remove", action="store_true", help="take the four tools back out (for a rollback)")
    args = parser.parse_args()

    if not args.mongo_uri:
        parser.error("--mongo-uri or MONGO_URI is required")

    client = MongoClient(args.mongo_uri, serverSelectionTimeoutMS=10000)
    db = client[args.db] if args.db else client.get_default_database(DEFAULT_DB)
    print(f"database {db.name}{'' if args.apply else ' (dry run)'}")
    run(db, args.apply, args.remove)


if __name__ == "__main__":
    main()
