"""Tests for add_domain_tools.py against an in-memory MongoDB (mongomock).

pip install pymongo mongomock
python -m unittest scripts/cbioagent-prod/test_add_domain_tools.py
"""

import contextlib
import copy
import datetime
import io
import sys
import unittest
from pathlib import Path
from unittest import mock

import mongomock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import add_domain_tools as m

EXISTING_TOOLS = [
    "clickhouse_run_select_query_mcp_cbioportal-database",
    "list_studies_mcp_cbioportal-database",
    "navigate_to_study_view_mcp_cbioportal-navigator",
]
THEN = datetime.datetime(2026, 1, 1)


def agent(**overrides):
    return {
        "id": m.PROD_AGENT_ID,
        "name": "cBioPortalChat",
        "author": "author-oid",
        "instructions": "prompt",
        "tools": list(EXISTING_TOOLS),
        "versions": [{"tools": list(EXISTING_TOOLS)}],
        "updatedAt": THEN,
        **overrides,
    }


class AddDomainToolsTest(unittest.TestCase):
    def setUp(self):
        self.db = mongomock.MongoClient().db

    def run_script(self, **kwargs):
        with contextlib.redirect_stdout(io.StringIO()):
            return m.run(self.db, **kwargs)

    def stored(self, agent_id=m.PROD_AGENT_ID):
        return self.db.agents.find_one({"id": agent_id})

    def test_tool_names(self):
        self.assertEqual(
            m.DOMAIN_TOOLS,
            (
                "get_alteration_frequency_mcp_cbioportal-database",
                "get_top_altered_genes_mcp_cbioportal-database",
                "get_gene_frequency_by_cancer_type_mcp_cbioportal-database",
                "get_profiled_counts_mcp_cbioportal-database",
            ),
        )

    def test_dry_run_writes_nothing(self):
        self.db.agents.insert_one(agent())
        before = copy.deepcopy(self.stored())
        self.assertTrue(self.run_script(apply=False))
        self.assertEqual(self.stored(), before)

    def test_apply_appends_keeping_existing_order(self):
        self.db.agents.insert_one(agent())
        self.assertTrue(self.run_script(apply=True))
        self.assertEqual(self.stored()["tools"], EXISTING_TOOLS + list(m.DOMAIN_TOOLS))

    def test_apply_pushes_a_full_version_snapshot(self):
        self.db.agents.insert_one(agent())
        self.run_script(apply=True)
        stored = self.stored()
        self.assertEqual(len(stored["versions"]), 2)
        snapshot = stored["versions"][-1]
        self.assertEqual(snapshot["tools"], stored["tools"])
        self.assertEqual(snapshot["instructions"], "prompt")
        self.assertEqual(snapshot["updatedAt"], stored["updatedAt"])
        self.assertGreater(stored["updatedAt"], THEN)
        for field in m.NOT_VERSIONED:
            self.assertNotIn(field, snapshot)

    def test_rerun_is_a_no_op(self):
        self.db.agents.insert_one(agent())
        self.run_script(apply=True)
        before = copy.deepcopy(self.stored())
        self.assertFalse(self.run_script(apply=True))
        self.assertEqual(self.stored(), before)

    def test_adds_only_missing_tools(self):
        self.db.agents.insert_one(agent(tools=[*EXISTING_TOOLS, m.DOMAIN_TOOLS[1]]))
        self.run_script(apply=True)
        tools = self.stored()["tools"]
        self.assertEqual(sorted(tools), sorted(EXISTING_TOOLS + list(m.DOMAIN_TOOLS)))
        self.assertEqual(len(tools), len(set(tools)))

    def test_all_tools_entry_needs_no_change(self):
        all_tools = f"{m.MCP_ALL}{m.MCP_DELIMITER}{m.DB_SERVER}"
        self.db.agents.insert_one(agent(tools=[all_tools]))
        self.assertFalse(self.run_script(apply=True))
        self.assertEqual(self.stored()["tools"], [all_tools])

    def test_writes_only_the_prod_agent(self):
        self.db.agents.insert_one(agent())
        other = agent(id="agent_OHVSJI9Gd6gwsDnFSL-Xl")
        self.db.agents.insert_one(other)
        self.run_script(apply=True)
        self.assertEqual(self.stored(other["id"])["tools"], EXISTING_TOOLS)

    def test_remove_undoes_apply(self):
        self.db.agents.insert_one(agent())
        self.run_script(apply=True)
        self.assertTrue(self.run_script(apply=True, remove=True))
        self.assertEqual(self.stored()["tools"], EXISTING_TOOLS)
        self.assertFalse(self.run_script(apply=True, remove=True))

    def test_missing_agent_exits(self):
        with self.assertRaises(SystemExit):
            self.run_script(apply=True)

    def test_duplicate_agent_exits_without_writing(self):
        self.db.agents.insert_one(agent(tenantId="a"))
        self.db.agents.insert_one(agent(tenantId="b"))
        with self.assertRaises(SystemExit):
            self.run_script(apply=True)
        for doc in self.db.agents.find():
            self.assertEqual(doc["tools"], EXISTING_TOOLS)

    def test_no_database_tools_exits_without_writing(self):
        tools = ["navigate_to_study_view_mcp_cbioportal-navigator"]
        self.db.agents.insert_one(agent(tools=tools))
        with self.assertRaises(SystemExit):
            self.run_script(apply=True)
        self.assertEqual(self.stored()["tools"], tools)

    def test_concurrent_edit_is_not_overwritten(self):
        self.db.agents.insert_one(agent())
        edited = [*EXISTING_TOOLS, "edited_in_ui_mcp_cbioportal-database"]
        real_find = self.db.agents.find

        def find_then_edit(*args, **kwargs):
            docs = list(real_find(*args, **kwargs))
            self.db.agents.update_one({"id": m.PROD_AGENT_ID}, {"$set": {"tools": edited}})
            return iter(docs)

        with mock.patch.object(self.db.agents, "find", find_then_edit), self.assertRaises(SystemExit):
            self.run_script(apply=True)
        self.assertEqual(self.stored()["tools"], edited)
        self.assertEqual(len(self.stored()["versions"]), 1)


if __name__ == "__main__":
    unittest.main()
