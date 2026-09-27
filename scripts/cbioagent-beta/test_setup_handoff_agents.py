"""Tests for setup_handoff_agents.py against an in-memory MongoDB (mongomock).

pip install pymongo mongomock
python -m unittest scripts/cbioagent-beta/test_setup_handoff_agents.py
"""

import contextlib
import copy
import io
import re
import sys
import unittest
from pathlib import Path

import mongomock
from bson import ObjectId

sys.path.insert(0, str(Path(__file__).resolve().parent))
import setup_handoff_agents as m

BASE_INSTRUCTIONS = """# cBioPortalChat

## Overview
You answer questions about cBioPortal data and build links into cBioPortal.

## Capability Selection
Run Query, then Navigate, by default. Call navigate_to_study_view after every data answer.

## Query Workflow
1. Call list_studies to find candidate studies.
2. Use run_query for counts and frequencies.

## Navigate Workflow
Call resolve_and_route first, then get_studyviewfilter_options when filtering.

### Navigation Tools
- navigate_to_results_view for OncoPrints.

## Interaction Guidelines

### Link First
Always provide a URL, even when not asked.

### Response Format
- **Query only:** a short table with the numbers.
- **Navigation only:** one line per link from navigate_to_patient_view,
  followed by what the view shows.

  Keep each link on its own line.
- **Both:** the table, then one sentence of context.

## Strict Constraints
Never invent study IDs.
"""

DB_TOOL = "sys__all__sys_mcp_cbioportal-database"
NAV_TOOL = "sys__all__sys_mcp_cbioportal-navigator"


def run(db, *args):
    sys.argv = ["setup_handoff_agents.py", "--mongo-uri", "mongodb://localhost/cBioAgent", *args]
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        m.main()
    return out.getvalue()


def snapshot(db):
    return (
        sorted(repr(sorted(d.items())) for d in db.agents.find()),
        sorted(repr(sorted(d.items())) for d in db.aclentries.find()),
    )


class StripNavigationTest(unittest.TestCase):
    def test_removes_navigation_sections_and_branch(self):
        stripped = m.strip_navigation(BASE_INSTRUCTIONS)
        for heading in ("## Capability Selection", "## Navigate Workflow", "### Navigation Tools", "### Link First"):
            self.assertNotIn(heading, stripped)
        self.assertNotIn("Navigation only:", stripped)
        self.assertNotIn("Keep each link on its own line.", stripped)
        for marker in m.NAV_TOOL_MARKERS:
            self.assertNotIn(marker, stripped)
        for kept in (
            "## Overview",
            "## Query Workflow",
            "run_query",
            "**Query only:**",
            "**Both:**",
            "## Strict Constraints",
        ):
            self.assertIn(kept, stripped)

    def test_missing_heading_fails(self):
        with self.assertRaisesRegex(ValueError, "Link First"):
            m.strip_navigation(BASE_INSTRUCTIONS.replace("### Link First", "### Links"))

    def test_missing_branch_marker_fails(self):
        with self.assertRaisesRegex(ValueError, "Navigation only"):
            m.strip_navigation(BASE_INSTRUCTIONS.replace("**Navigation only:**", "**Links:**"))

    def test_leftover_navigator_tool_fails(self):
        extra = BASE_INSTRUCTIONS.replace("Never invent study IDs.", "Never invent study IDs; use resolve_and_route.")
        with self.assertRaisesRegex(ValueError, "resolve_and_route"):
            m.strip_navigation(extra)


class SetupHandoffAgentsTest(unittest.TestCase):
    def setUp(self):
        self.client = mongomock.MongoClient()
        self._orig_client = m.MongoClient
        m.MongoClient = lambda *a, **k: self.client
        self.db = self.client["cBioAgent"]
        self.author = ObjectId()
        self.source = {
            "_id": ObjectId(),
            "id": m.DEFAULT_SOURCE_ID,
            "author": self.author,
            "provider": "bedrock",
            "model": m.HAIKU,
            "instructions": BASE_INSTRUCTIONS,
            "tools": [DB_TOOL, NAV_TOOL],
            "category": "general",
        }
        self.prod = {"_id": ObjectId(), "id": "agent_prod_unified", "author": self.author, "model": "x", "tools": []}
        self.db.agents.insert_many([self.source, self.prod])
        self.db.aclentries.insert_many(
            [
                {
                    "principalType": "user",
                    "principalId": self.author,
                    "principalModel": "User",
                    "resourceType": "agent",
                    "resourceId": self.source["_id"],
                    "permBits": 15,
                },
                {"principalType": "public", "resourceType": "agent", "resourceId": self.source["_id"], "permBits": 1},
                {
                    "principalType": "public",
                    "resourceType": "remoteAgent",
                    "resourceId": self.source["_id"],
                    "permBits": 1,
                },
                {"principalType": "public", "resourceType": "agent", "resourceId": self.prod["_id"], "permBits": 1},
            ]
        )

    def tearDown(self):
        m.MongoClient = self._orig_client

    def agent(self, agent_id):
        return self.db.agents.find_one({"id": agent_id, "tenantId": None})

    def test_dry_run_writes_nothing(self):
        before = snapshot(self.db)
        out = run(self.db, "--dry-run")
        self.assertEqual(snapshot(self.db), before)
        self.assertEqual(out.count("\ncreate "), 3)

    def test_apply_builds_expected_agents(self):
        run(self.db)
        router, data, nav = (self.agent(i) for i in m.MANAGED_IDS)

        self.assertEqual(router["tools"], [])
        self.assertEqual([e["to"] for e in router["edges"]], [m.NAV_ID, m.DATA_ID])
        self.assertNotIn("<<", router["instructions"])
        self.assertIn(m.TRANSFER_PREFIX + m.NAV_ID, router["instructions"])

        self.assertEqual(data["tools"], [DB_TOOL])
        self.assertEqual(data["mcpServerNames"], ["cbioportal-database"])
        data_md = m.read_prompt("data")
        self.assertTrue(data["instructions"].endswith(data_md))
        data_base = data["instructions"][: -len(data_md)]
        for marker in m.NAV_TOOL_MARKERS:
            self.assertNotIn(marker, data_base)
        self.assertIsNone(re.search(r"navigate_to_[a-z]", data["instructions"]))
        for heading in ("Capability Selection", "Navigate Workflow", "Link First", "Navigation only:"):
            self.assertNotIn(heading, data["instructions"])
        self.assertIn("## Query Workflow", data["instructions"])

        self.assertEqual(nav["model"], m.SONNET)
        self.assertEqual(nav["tools"], [DB_TOOL, NAV_TOOL])
        self.assertTrue(nav["instructions"].endswith(BASE_INSTRUCTIONS.strip()))

        self.assertEqual(
            router["model_parameters"], {"model": m.HAIKU, "thinking": False, "maxOutputTokens": 256, "temperature": 0}
        )
        self.assertEqual(
            data["model_parameters"],
            {"model": m.HAIKU, "thinking": False, "maxOutputTokens": 8192, "temperature": 0, "promptCache": True},
        )
        self.assertEqual(
            nav["model_parameters"],
            {"model": m.SONNET, "thinking": True, "effort": "low", "maxOutputTokens": 8192, "promptCache": True},
        )
        for a in (router, data, nav):
            self.assertEqual(self.db.aclentries.count_documents({"resourceId": a["_id"]}), 3)
            self.assertEqual(len(a["versions"]), 1)
            self.assertNotIn("author", a["versions"][0])
            self.assertEqual(a["versions"][0]["model_parameters"], a["model_parameters"])

    def test_rerun_is_idempotent(self):
        run(self.db)
        before = snapshot(self.db)
        out = run(self.db)
        self.assertEqual(snapshot(self.db), before)
        self.assertEqual(out.count("unchanged "), 3)

    def test_update_snapshot_matches_create_shape(self):
        run(self.db)
        self.db.agents.update_one(
            {"_id": self.source["_id"]}, {"$set": {"instructions": BASE_INSTRUCTIONS + "\nNew rule."}}
        )
        out = run(self.db)
        self.assertIn("update agent_cbiobeta_data: instructions", out)
        self.assertIn("update agent_cbiobeta_navigation: instructions", out)
        self.assertIn("unchanged agent_cbiobeta_router", out)
        data = self.agent(m.DATA_ID)
        self.assertEqual(len(data["versions"]), 2)
        first, second = data["versions"]
        self.assertEqual(set(first), set(second))
        self.assertTrue(second["instructions"].startswith(data["instructions"][:40]))

    def test_old_model_parameters_are_replaced(self):
        run(self.db)
        self.db.agents.update_one(
            {"id": m.NAV_ID}, {"$set": {"model_parameters": {"model": m.SONNET, "temperature": 0, "promptCache": True}}}
        )
        out = run(self.db)
        self.assertIn("update agent_cbiobeta_navigation: model_parameters", out)
        self.assertNotIn("temperature", self.agent(m.NAV_ID)["model_parameters"])

    def test_other_tenant_agent_is_untouched(self):
        other = {"_id": ObjectId(), "id": m.ROUTER_ID, "tenantId": "other", "model": "keep-me", "author": self.author}
        self.db.agents.insert_one(other)
        run(self.db)
        self.assertEqual(self.db.agents.find_one({"_id": other["_id"]}), other)
        self.assertEqual(self.agent(m.ROUTER_ID)["model"], m.HAIKU)
        run(self.db, "--delete")
        self.assertEqual(self.db.agents.find_one({"_id": other["_id"]}), other)

    def test_source_tenant_is_propagated(self):
        self.db.agents.update_one({"_id": self.source["_id"]}, {"$set": {"tenantId": "t1"}})
        run(self.db)
        self.assertEqual(self.db.agents.count_documents({"id": {"$in": list(m.MANAGED_IDS)}, "tenantId": "t1"}), 3)
        self.assertEqual(run(self.db).count("unchanged "), 3)

    def test_missing_nav_heading_aborts_before_writing(self):
        self.db.agents.update_one(
            {"_id": self.source["_id"]}, {"$set": {"instructions": BASE_INSTRUCTIONS.replace("### Link First", "")}}
        )
        before = snapshot(self.db)
        with self.assertRaises(SystemExit) as ctx, contextlib.redirect_stdout(io.StringIO()):
            run(self.db)
        self.assertIn("Link First", str(ctx.exception.code))
        self.assertEqual(snapshot(self.db), before)

    def test_delete_removes_only_managed_agents(self):
        run(self.db)
        prod_before = copy.deepcopy(self.db.agents.find_one({"_id": self.prod["_id"]}))
        source_before = copy.deepcopy(self.db.agents.find_one({"_id": self.source["_id"]}))
        before = snapshot(self.db)
        run(self.db, "--delete", "--dry-run")
        self.assertEqual(snapshot(self.db), before)
        run(self.db, "--delete")
        self.assertEqual(self.db.agents.count_documents({"id": {"$in": list(m.MANAGED_IDS)}}), 0)
        self.assertEqual(self.db.aclentries.count_documents({}), 4)
        self.assertEqual(self.db.agents.find_one({"_id": self.prod["_id"]}), prod_before)
        self.assertEqual(self.db.agents.find_one({"_id": self.source["_id"]}), source_before)


if __name__ == "__main__":
    unittest.main()
