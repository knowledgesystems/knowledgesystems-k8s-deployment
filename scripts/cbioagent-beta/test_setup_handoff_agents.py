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
You have two capabilities: Query (data answers) and Navigate (links into cBioPortal).

## Capability Selection
Run Query, then Navigate, by default. Call navigate_to_study_view after every data answer.

## Query Workflow
1. Call list_studies to find candidate studies.
2. Use run_query for counts and frequencies.
3. Surface study IDs for Navigate. Pass them to Navigate Step 1.

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
- **Both:** Query results first, then URL(s).

## Strict Constraints
Never invent study IDs.
Cite the REST API base URL for code questions.
"""

BUDGET_TEXT = (
    "Tool budget for each user message: aim to finish within six tool rounds. A tool round is one of your responses "
    "that contains tool calls. Independent calls issued together in one response count as a single round, so batch "
    "calls that do not depend on each other's results. Count only rounds made since the latest user message. Gather "
    "only the evidence needed for a useful answer, and stop earlier when you have enough. After your sixth tool round, "
    "make no further tool calls: give your best useful final answer using only the information already available. "
    "Present the confirmed findings and any verified links, state uncertainty or missing evidence explicitly, and say "
    "which part of the request remains unanswered. Do not invent results, counts, or links. If the evidence is "
    "insufficient, explain what you could establish and suggest one focused follow-up the user can ask in a new "
    "message. Do not mention an internal step limit, and never end with a tool error in place of an answer."
)
BUDGET_LABEL = "Tool budget for each user message:"
# Copies the old exact-label check missed, plus an edited copy that keeps the budget's key sentences.
BUDGET_VARIANTS = {
    "lowercase": BUDGET_TEXT.replace("Tool budget", "tool budget"),
    "extra space": BUDGET_TEXT.replace("Tool budget", "Tool  budget"),
    "line break": BUDGET_TEXT.replace("Tool budget", "Tool\nbudget"),
    "edited": BUDGET_TEXT.replace("Tool budget for each user message:", "**Budget:**").replace(
        " Do not invent results, counts, or links.", ""
    ),
}
LABEL_QUOTE = 'Documentation note: the label "Tool budget for each user message:" is reserved for future guidance.'
ROUTER_TRANSFER_LINE = "Always respond with exactly one transfer call; never answer the question yourself."

DB_TOOL = "sys__all__sys_mcp_cbioportal-database"
NAV_TOOL = "sys__all__sys_mcp_cbioportal-navigator"
FAST_TOOLS = [
    "get_alteration_frequency_mcp_cbioportal-database",
    "get_top_altered_genes_mcp_cbioportal-database",
    "get_gene_frequency_by_cancer_type_mcp_cbioportal-database",
    "get_profiled_counts_mcp_cbioportal-database",
    "list_studies_mcp_cbioportal-database",
]
# A source agent that lists cbioportal-database tools one by one instead of the all-tools entry.
EXPLICIT_DB_TOOLS = [*FAST_TOOLS, "clickhouse_run_select_query_mcp_cbioportal-database"]
# The cbioportal-mcp #154 tools, which a unified agent configured before #154 doesn't list.
AGGREGATE_TOOLS = [t for t in FAST_TOOLS if not t.startswith("list_studies")]
PRE_154_DB_TOOLS = [t for t in EXPLICIT_DB_TOOLS if t not in AGGREGATE_TOOLS]


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
        stripped, removed = m.strip_navigation(BASE_INSTRUCTIONS)
        self.assertEqual(
            removed[:4], ["## Capability Selection", "## Navigate Workflow", "### Navigation Tools", "### Link First"]
        )
        self.assertTrue(removed[4].startswith("item '- **Navigation only:**"))
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

    def test_removed_items_in_document_order(self):
        section = "## Capability Selection\nRun Query, then Navigate, by default. Call navigate_to_study_view after every data answer.\n"
        reordered = BASE_INSTRUCTIONS.replace(section, "") + "\n" + section
        _, removed = m.strip_navigation(reordered)
        self.assertEqual(removed[-1], "## Capability Selection")
        self.assertTrue(removed[-2].startswith("item '- **Navigation only:**"))

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
        self.assertEqual(out.count("\ncreate "), 4)
        self.assertIn(f"create {m.ROUTER_ID} ({m.HAIKU}, 0 tools, 3 edges)", out)
        self.assertIn(f"create {m.FAST_ID} ({m.HAIKU}, 5 tools, 1 edges)", out)
        creates = [ln.split()[1] for ln in out.splitlines() if ln.startswith("create ")]
        self.assertEqual(creates[-1], m.ROUTER_ID)

    def test_apply_builds_expected_agents(self):
        run(self.db)
        router, data, nav, fast = (self.agent(i) for i in m.MANAGED_IDS)

        self.assertEqual(router["tools"], [])
        self.assertEqual([e["to"] for e in router["edges"]], [m.NAV_ID, m.DATA_ID, m.FAST_ID])
        self.assertEqual({e["from"] for e in router["edges"]}, {m.ROUTER_ID})
        self.assertEqual({e["edgeType"] for e in router["edges"]}, {"handoff"})
        self.assertNotIn("<<", router["instructions"])
        self.assertIn(m.TRANSFER_PREFIX + m.NAV_ID, router["instructions"])

        self.assertEqual(data["tools"], [DB_TOOL])
        self.assertEqual(data["mcpServerNames"], ["cbioportal-database"])
        data_md = m.read_prompt("data")
        self.assertTrue(data["instructions"].endswith(f"{data_md}\n\n{BUDGET_TEXT}"))
        data_base = data["instructions"][: -len(f"{data_md}\n\n{BUDGET_TEXT}")]
        for marker in m.NAV_TOOL_MARKERS:
            self.assertNotIn(marker, data_base)
        self.assertIsNone(re.search(r"navigate_to_[a-z]", data["instructions"]))
        for heading in ("Capability Selection", "Navigate Workflow", "Link First", "Navigation only:"):
            self.assertNotIn(heading, data["instructions"])
        self.assertIn("## Query Workflow", data["instructions"])
        self.assertIn("You have only Query", data_md)
        self.assertIn("including the site root", data_md)
        self.assertIn("https://www.cbioportal.org/api", data_md)

        self.assertEqual(nav["model"], m.SONNET)
        self.assertEqual(nav["tools"], [DB_TOOL, NAV_TOOL])
        self.assertTrue(nav["instructions"].endswith(f"{BASE_INSTRUCTIONS.strip()}\n\n{BUDGET_TEXT}"))

        self.assertEqual(
            router["model_parameters"],
            {"model": m.HAIKU, "thinking": False, "maxOutputTokens": 256, "temperature": 0, "promptCacheTtl": "1h"},
        )
        haiku_params = {
            "model": m.HAIKU,
            "thinking": False,
            "maxOutputTokens": 4096,
            "temperature": 0,
            "promptCache": True,
            "promptCacheTtl": "1h",
        }
        self.assertEqual(data["model_parameters"], haiku_params)
        self.assertEqual(fast["model_parameters"], haiku_params)
        self.assertEqual(
            nav["model_parameters"],
            {
                "model": m.SONNET,
                "thinking": False,
                "maxOutputTokens": 4096,
                "promptCache": True,
                "promptCacheTtl": "1h",
            },
        )
        for a in (router, data, nav, fast):
            self.assertEqual(self.db.aclentries.count_documents({"resourceId": a["_id"]}), 3)
            self.assertEqual(len(a["versions"]), 1)
            self.assertNotIn("author", a["versions"][0])
            self.assertEqual(a["versions"][0]["model_parameters"], a["model_parameters"])

    def test_dry_run_prints_strip_report(self):
        out = run(self.db, "--dry-run")
        for heading in ("## Capability Selection", "## Navigate Workflow", "### Link First", "Navigation only:"):
            self.assertIn(heading, out)
        stripped, _ = m.strip_navigation(BASE_INSTRUCTIONS)
        self.assertIn(f"{len(BASE_INSTRUCTIONS.strip())} -> {len(stripped)} chars", out)
        mentions = [ln.split("(data.md overrides): ", 1)[1] for ln in out.splitlines() if "data.md overrides" in ln]
        self.assertEqual(
            mentions,
            [
                "You have two capabilities: Query (data answers) and Navigate (links into cBioPortal).",
                "3. Surface study IDs for Navigate. Pass them to Navigate Step 1.",
                "- **Both:** Query results first, then URL(s).",
                "Cite the REST API base URL for code questions.",
            ],
        )
        removed_lines = [ln.strip() for ln in out.splitlines() if ln.startswith("  - ")]
        self.assertEqual(
            removed_lines,
            [
                "- ## Capability Selection",
                "- ## Navigate Workflow",
                "- ### Navigation Tools",
                "- ### Link First",
                "- item '- **Navigation only:** one line per link from navigate_to_pa'",
            ],
        )
        self.assertNotIn("removed from the unified prompt", run(self.db))

    def test_budget_is_last_and_once_in_specialists_only(self):
        self.assertEqual(m.read_prompt("budget"), BUDGET_TEXT)
        run(self.db)
        router, data, nav, fast = (self.agent(i) for i in m.MANAGED_IDS)
        self.assertEqual(m.BUDGETED_IDS, (m.DATA_ID, m.NAV_ID))
        for a in (data, nav):
            self.assertEqual(a["instructions"].count(BUDGET_LABEL), 1, a["id"])
            self.assertEqual(a["instructions"].count("six tool rounds"), 1, a["id"])
            self.assertTrue(a["instructions"].endswith("\n\n" + BUDGET_TEXT), a["id"])
            self.assertEqual(a["versions"][-1]["instructions"], a["instructions"])
        self.assertNotIn(BUDGET_LABEL, router["instructions"])
        self.assertNotIn("tool round", router["instructions"])
        self.assertEqual(router["instructions"].count(ROUTER_TRANSFER_LINE), 1)
        self.assertNotIn(BUDGET_LABEL, fast["instructions"])
        self.assertEqual(m.budget_copies(fast["instructions"], BUDGET_TEXT), 0)
        self.assertIn("one tool round, two at most", fast["instructions"])

    def test_budget_in_unified_prompt_aborts_before_writing(self):
        # Anywhere in the unified prompt, including inside a section NAV_SECTIONS strips from the data agent.
        for instructions in (
            f"{BASE_INSTRUCTIONS}\n## Tool Budget\n{BUDGET_TEXT}\n",
            BASE_INSTRUCTIONS.replace("### Link First\n", f"### Link First\n{BUDGET_TEXT}\n"),
        ):
            self.db.agents.update_one({"_id": self.source["_id"]}, {"$set": {"instructions": instructions}})
            before = snapshot(self.db)
            for args in ((), ("--dry-run",)):
                with self.assertRaises(SystemExit) as ctx, contextlib.redirect_stdout(io.StringIO()):
                    run(self.db, *args)
                self.assertIn("already contain", str(ctx.exception.code))
                self.assertIn("tool budget", str(ctx.exception.code))
            self.assertEqual(snapshot(self.db), before)

    def test_budget_variant_in_unified_prompt_aborts_before_writing(self):
        for name, variant in BUDGET_VARIANTS.items():
            with self.subTest(name):
                instructions = f"{BASE_INSTRUCTIONS}\n## Tool Budget\n{variant}\n"
                self.db.agents.update_one({"_id": self.source["_id"]}, {"$set": {"instructions": instructions}})
                before = snapshot(self.db)
                for args in ((), ("--dry-run",)):
                    with self.assertRaises(SystemExit) as ctx, contextlib.redirect_stdout(io.StringIO()):
                        run(self.db, *args)
                    self.assertIn("already contain", str(ctx.exception.code))
                self.assertEqual(snapshot(self.db), before)

    def test_quoting_the_budget_label_does_not_abort(self):
        instructions = f"{BASE_INSTRUCTIONS}\n{LABEL_QUOTE}\n"
        self.db.agents.update_one({"_id": self.source["_id"]}, {"$set": {"instructions": instructions}})
        self.assertEqual(run(self.db, "--dry-run").count("\ncreate "), 4)
        run(self.db)
        for agent_id in (m.DATA_ID, m.NAV_ID):
            text = self.agent(agent_id)["instructions"]
            self.assertTrue(text.endswith("\n\n" + BUDGET_TEXT), agent_id)
            self.assertEqual(text.count("six tool rounds"), 1, agent_id)
        self.assertIn(LABEL_QUOTE, self.agent(m.NAV_ID)["instructions"])

    def test_budget_in_prompt_file_aborts(self):
        orig = m.read_prompt
        for copy_text in (BUDGET_TEXT, *BUDGET_VARIANTS.values()):
            for target, agent_id in (
                ("data", m.DATA_ID),
                ("navigation", m.NAV_ID),
                ("router", m.ROUTER_ID),
                ("fast", m.FAST_ID),
            ):
                with self.subTest(target=target, copy=copy_text[:30]):
                    m.read_prompt = lambda name, t=target, c=copy_text: orig(name) + ("\n\n" + c if name == t else "")
                    try:
                        before = snapshot(self.db)
                        with self.assertRaises(SystemExit) as ctx, contextlib.redirect_stdout(io.StringIO()):
                            run(self.db)
                        self.assertIn(agent_id, str(ctx.exception.code))
                        self.assertEqual(snapshot(self.db), before)
                    finally:
                        m.read_prompt = orig

    def test_router_recursion_limit_below_cap_aborts_before_writing(self):
        run(self.db)
        self.db.agents.update_one({"id": m.ROUTER_ID}, {"$set": {"recursion_limit": 10}})
        self.db.agents.update_one({"_id": self.source["_id"]}, {"$set": {"instructions": BASE_INSTRUCTIONS + "\nNew."}})
        before = snapshot(self.db)
        for args in ((), ("--dry-run",)):
            with self.assertRaises(SystemExit) as ctx, contextlib.redirect_stdout(io.StringIO()):
                run(self.db, *args)
            self.assertIn("recursion_limit 10", str(ctx.exception.code))
            self.assertIn("24", str(ctx.exception.code))
        self.assertEqual(snapshot(self.db), before)
        self.assertEqual(self.agent(m.ROUTER_ID)["recursion_limit"], 10)

    def test_router_recursion_limit_at_or_above_cap_or_unset_is_kept(self):
        run(self.db)
        for limit in (24, 50, 0, None):
            with self.subTest(limit=limit):
                self.db.agents.update_one({"id": m.ROUTER_ID}, {"$set": {"recursion_limit": limit}})
                run(self.db, "--dry-run")
                self.assertEqual(run(self.db).count("unchanged "), 4)
                self.assertEqual(self.agent(m.ROUTER_ID)["recursion_limit"], limit)

    def test_dry_run_shows_budget(self):
        out = run(self.db, "--dry-run")
        self.assertIn(
            f"tool budget (prompts/budget.md), last section of {m.DATA_ID} and {m.NAV_ID}: "
            f"{BUDGET_LABEL} aim to finish within six tool rounds.",
            out,
        )
        self.assertNotIn("tool budget (prompts/budget.md)", run(self.db))

    def test_managed_diff_reports_only_changed_fields(self):
        desired = {"id": m.DATA_ID, "name": "n", "model": m.HAIKU}
        self.assertEqual(m.managed_diff({"name": "n", "model": m.HAIKU}, desired), {})
        self.assertEqual(m.managed_diff({"name": "old", "model": m.HAIKU, "extra": 1}, desired), {"name": "n"})

    def test_explicit_null_tenant_is_unchanged(self):
        run(self.db)
        self.db.agents.update_many({"id": {"$in": list(m.MANAGED_IDS)}}, {"$set": {"tenantId": None}})
        self.assertEqual(run(self.db).count("unchanged "), 4)

    def test_tenant_change_leaves_old_copies_reported(self):
        self.db.agents.update_one({"_id": self.source["_id"]}, {"$set": {"tenantId": "t1"}})
        run(self.db)
        self.db.agents.update_one({"_id": self.source["_id"]}, {"$unset": {"tenantId": ""}})
        out = run(self.db)
        self.assertEqual(out.count("\ncreate "), 4)
        self.assertEqual(out.count("tenantId='t1'; not touched"), 4)
        self.assertEqual(self.db.agents.count_documents({"id": {"$in": list(m.MANAGED_IDS)}, "tenantId": "t1"}), 4)

    def test_delete_requires_source_agent(self):
        run(self.db)
        before = snapshot(self.db)
        with self.assertRaises(SystemExit) as ctx, contextlib.redirect_stdout(io.StringIO()):
            run(self.db, "--delete", "--source-agent", "agent_missing")
        self.assertIn("agent_missing not found", str(ctx.exception.code))
        self.assertEqual(snapshot(self.db), before)

    def test_rerun_is_idempotent(self):
        run(self.db)
        before = snapshot(self.db)
        out = run(self.db)
        self.assertEqual(snapshot(self.db), before)
        self.assertEqual(out.count("unchanged "), 4)

    def test_update_snapshot_matches_create_shape(self):
        run(self.db)
        self.db.agents.update_one(
            {"_id": self.source["_id"]}, {"$set": {"instructions": BASE_INSTRUCTIONS + "\nNew rule."}}
        )
        out = run(self.db)
        self.assertIn("update agent_cbiobeta_data: instructions", out)
        self.assertIn("update agent_cbiobeta_navigation: instructions", out)
        self.assertIn("unchanged agent_cbiobeta_router", out)
        self.assertIn("unchanged agent_cbiobeta_fast", out)
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

    def test_previous_navigation_thinking_is_turned_off(self):
        run(self.db)
        old = {"model": m.SONNET, "thinking": True, "effort": "low", "maxOutputTokens": 8192, "promptCache": True}
        self.db.agents.update_one({"id": m.NAV_ID}, {"$set": {"model_parameters": old}})
        out = run(self.db)
        self.assertIn("update agent_cbiobeta_navigation: model_parameters", out)
        params = self.agent(m.NAV_ID)["model_parameters"]
        self.assertIs(params["thinking"], False)
        self.assertNotIn("effort", params)
        self.assertEqual(params["maxOutputTokens"], 4096)

    def test_other_tenant_agent_is_untouched(self):
        others = [
            {"_id": ObjectId(), "id": agent_id, "tenantId": "other", "model": "keep-me", "author": self.author}
            for agent_id in (m.ROUTER_ID, m.FAST_ID)
        ]
        self.db.agents.insert_many(copy.deepcopy(others))
        run(self.db)
        for other in others:
            self.assertEqual(self.db.agents.find_one({"_id": other["_id"]}), other)
            self.assertEqual(self.agent(other["id"])["model"], m.HAIKU)
        run(self.db, "--delete")
        for other in others:
            self.assertEqual(self.db.agents.find_one({"_id": other["_id"]}), other)

    def test_source_tenant_is_propagated(self):
        self.db.agents.update_one({"_id": self.source["_id"]}, {"$set": {"tenantId": "t1"}})
        run(self.db)
        self.assertEqual(self.db.agents.count_documents({"id": {"$in": list(m.MANAGED_IDS)}, "tenantId": "t1"}), 4)
        self.assertEqual(run(self.db).count("unchanged "), 4)

    def test_missing_nav_heading_aborts_before_writing(self):
        self.db.agents.update_one(
            {"_id": self.source["_id"]}, {"$set": {"instructions": BASE_INSTRUCTIONS.replace("### Link First", "")}}
        )
        before = snapshot(self.db)
        with self.assertRaises(SystemExit) as ctx, contextlib.redirect_stdout(io.StringIO()):
            run(self.db)
        self.assertIn("Link First", str(ctx.exception.code))
        self.assertEqual(snapshot(self.db), before)

    def test_fast_agent(self):
        run(self.db)
        fast = self.agent(m.FAST_ID)
        self.assertEqual(fast["name"], "cBioPortalChat Fast (beta)")
        self.assertEqual(fast["provider"], "bedrock")
        self.assertEqual(fast["model"], m.HAIKU)
        self.assertEqual(fast["author"], self.author)
        self.assertEqual(fast["tools"], FAST_TOOLS)
        self.assertEqual(fast["mcpServerNames"], ["cbioportal-database"])
        self.assertEqual(
            fast["instructions"], m.read_prompt("fast").replace("<<DATA_TOOL>>", m.TRANSFER_PREFIX + m.DATA_ID)
        )
        self.assertNotIn("<<", fast["instructions"])
        # Built from fast.md alone, not the unified prompt.
        self.assertNotIn("## Query Workflow", fast["instructions"])
        for text in (
            "never construct or output any cbioportal.org URL",
            "Never copy a `url` value from `list_studies`",
            "https://www.cbioportal.org/api",
            "numerator and denominator",
            "Never guess a study ID",
            "`fallback_reason`",
        ):
            self.assertIn(text, fast["instructions"])
        for name in m.FAST_TOOL_NAMES:
            self.assertIn(f"`{name}(", fast["instructions"])
        for marker in m.NAV_TOOL_MARKERS:
            self.assertNotIn(marker, fast["instructions"])
        self.assertEqual(self.db.aclentries.count_documents({"resourceId": fast["_id"]}), 3)

    def test_fast_escalation_edge(self):
        run(self.db)
        fast = self.agent(m.FAST_ID)
        self.assertEqual(len(fast["edges"]), 1)
        edge = fast["edges"][0]
        self.assertEqual((edge["from"], edge["to"], edge["edgeType"]), (m.FAST_ID, m.DATA_ID, "handoff"))
        self.assertTrue(edge["description"])
        self.assertIn(m.TRANSFER_PREFIX + m.DATA_ID, fast["instructions"])
        # The escalation target is a managed agent users can reach.
        self.assertEqual(self.db.aclentries.count_documents({"resourceId": self.agent(m.DATA_ID)["_id"]}), 3)
        self.assertEqual(self.agent(m.DATA_ID)["edges"], [])
        self.assertEqual(self.agent(m.NAV_ID)["edges"], [])

    def test_router_prompt_routes_fast(self):
        run(self.db)
        text = self.agent(m.ROUTER_ID)["instructions"]
        nav, data, fast = (m.TRANSFER_PREFIX + i for i in (m.NAV_ID, m.DATA_ID, m.FAST_ID))
        for tool in (nav, data, fast):
            self.assertIn(tool, text)
        # Navigation rules come first, so a link or view request never reaches the fast agent.
        self.assertLess(text.index(f"1. Call `{nav}`"), text.index(f"2. Call `{fast}`"))
        self.assertLess(text.index(f"2. Call `{fast}`"), text.index(f"3. Call `{data}`"))
        self.assertIn(f"If you are unsure between `{fast}` and `{data}`, call `{data}`.", text)
        self.assertIn(f"If you are unsure whether a link or view is needed, call `{nav}`.", text)
        self.assertIn("Fast examples:", text)
        self.assertIn("Not fast (data):", text)
        self.assertIn("Not fast (navigation):", text)
        for excluded in ("filter", "survival", "co-occurrence", "comparisons", "follow-up"):
            self.assertIn(excluded, text.split("Fast examples:")[0])
        self.assertIn("Top 10 most mutated genes in luad_tcga_pan_can_atlas_2018", text)
        self.assertIn("What about in the MSK cohort?", text)
        self.assertIn(ROUTER_TRANSFER_LINE, text)

    def test_router_prompt_keeps_patient_level_frequencies_off_fast(self):
        run(self.db)
        text = self.agent(m.ROUTER_ID)["instructions"]
        rule = (
            "Patient-level alteration frequencies or prevalence are not fast; "
            "only sample-level alteration frequencies are supported."
        )
        self.assertIn(rule, text)
        self.assertLess(text.index(rule), text.index("Fast examples:"))
        example = '- "What percentage of patients in msk_impact_2017 have a KRAS mutation?" (patient-level frequency)'
        not_fast = text.split("Not fast (data):", 1)[1].split("Not fast (navigation):", 1)[0]
        self.assertIn(example, not_fast)
        fast_examples = text.split("Fast examples:", 1)[1].split("Not fast (data):", 1)[0]
        self.assertNotIn("patients", fast_examples.replace("How many samples and patients are in", ""))

    def test_fast_prompt_validates_before_the_first_call(self):
        text = m.read_prompt("fast")
        check = (
            "Before any tool call, validate the latest message independently; do not assume the router classified "
            "it correctly. Every requested qualifier and counting unit must be supported by the matching tool above. "
            "Otherwise transfer to data before calling it. Never substitute sample-level frequencies for "
            "patient-level frequencies."
        )
        self.assertIn(check, text)
        self.assertLess(text.index(check), text.index("1. Once the question passes that check, call the matching"))
        self.assertIn("- the question fails the check above;", text)
        self.assertIn("patient-level alteration frequency or prevalence", text)
        self.assertIn("Only sample-level alteration frequencies are supported.", text)

    def test_fast_prompt_states_each_tools_counting_unit(self):
        text = m.read_prompt("fast")
        lines = {
            name: next(ln for ln in text.splitlines() if ln.startswith(f"- `{name}(")) for name in m.FAST_TOOL_NAMES
        }
        for name in ("get_alteration_frequency", "get_top_altered_genes", "get_gene_frequency_by_cancer_type"):
            self.assertIn("Counts samples only", lines[name], name)
        self.assertIn("`altered_samples` of `profiled_samples`", lines["get_alteration_frequency"])
        counts = lines["get_profiled_counts"]
        self.assertIn("samples and how many patients", counts)
        self.assertIn("no alteration counts", counts)
        self.assertIn("Patient counts are supported only as study or data-type totals from `get_profiled_counts`", text)

    def test_fast_prompt_zero_altered_exception(self):
        text = m.read_prompt("fast")
        exception = text[text.index("For `get_alteration_frequency`, answer a genuine zero") :].split("\n\n", 1)[0]
        for condition in (
            "there is no `error_message` or `note`",
            "the returned gene and study identify the requested gene and study",
            "`altered_samples` = 0, `profiled_samples` > 0, and `frequency_pct` = 0",
            "Read compact rows using their `columns`.",
            'Report "0 of N profiled samples (0%)"',
            "Do not require `fallback_reason`.",
            "Never interpret missing rows or `0/0` as 0%.",
        ):
            self.assertIn(condition, exception)
        self.assertNotIn("precomputed", text)
        self.assertNotIn("built_at", text)
        self.assertIn(
            "- the tool returns `error_message`, a `note`, missing or empty `rows`, or a `fallback_reason`; "
            "or a frequency row has `profiled_samples` ≤ 0 or `frequency_pct` = null;",
            text,
        )

    def test_explicit_source_tools_verify_fast_tools(self):
        self.db.agents.update_one({"_id": self.source["_id"]}, {"$set": {"tools": [*EXPLICIT_DB_TOOLS, NAV_TOOL]}})
        out = run(self.db, "--dry-run")
        self.assertIn(f"{m.FAST_ID} tools: {', '.join(FAST_TOOLS)}", out)
        self.assertNotIn("not verified", out)
        self.assertNotIn("not verified", run(self.db))
        self.assertEqual(self.agent(m.FAST_ID)["tools"], FAST_TOOLS)
        self.assertEqual(self.agent(m.DATA_ID)["tools"], EXPLICIT_DB_TOOLS)

    def test_all_tools_source_is_reported_unverified(self):
        warning = f"warning: {m.FAST_ID} tools not verified"
        out = run(self.db, "--dry-run")
        self.assertIn(f"{m.FAST_ID} tools: {', '.join(FAST_TOOLS)}", out)
        self.assertEqual(out.count(warning), 1)
        out = run(self.db)
        self.assertEqual(out.count(warning), 1)
        self.assertIn("create agent_cbiobeta_fast", out)
        self.assertEqual(run(self.db).count(warning), 1)

    def use_pre_154_source(self):
        self.db.agents.update_one({"_id": self.source["_id"]}, {"$set": {"tools": [*PRE_154_DB_TOOLS, NAV_TOOL]}})

    def test_source_without_fast_tools_appends_them(self):
        self.use_pre_154_source()
        warning = (
            f"warning: {m.FAST_ID} tools not verified: the source agent doesn't list them, so they were added "
            "without checking the MCP server; confirm beta's cbioportal-database MCP server lists "
            "get_alteration_frequency, get_top_altered_genes, get_gene_frequency_by_cancer_type, get_profiled_counts "
            "(cbioportal-mcp #154)"
        )
        before = snapshot(self.db)
        out = run(self.db, "--dry-run")
        self.assertEqual(snapshot(self.db), before)
        self.assertIn(f"{m.FAST_ID} tools: {', '.join(FAST_TOOLS)}", out)
        self.assertIn(f"not in the source agent: {', '.join(AGGREGATE_TOOLS)}", out)
        self.assertEqual(out.count(warning), 1)
        self.assertEqual(out.count("\ncreate "), 4)

        self.assertEqual(run(self.db).count(warning), 1)
        self.assertEqual(self.agent(m.FAST_ID)["tools"], FAST_TOOLS)
        self.assertEqual(self.agent(m.DATA_ID)["tools"], [*PRE_154_DB_TOOLS, *AGGREGATE_TOOLS])
        self.assertEqual(self.agent(m.NAV_ID)["tools"], [*PRE_154_DB_TOOLS, NAV_TOOL, *AGGREGATE_TOOLS])
        self.assertEqual(self.agent(m.DATA_ID)["mcpServerNames"], ["cbioportal-database"])
        self.assertEqual(self.agent(m.NAV_ID)["mcpServerNames"], ["cbioportal-database", "cbioportal-navigator"])
        self.assertEqual(run(self.db).count("unchanged "), 4)

    def test_existing_agents_without_fast_tools_are_updated(self):
        # Data and navigation built before the fast path copied the pre-#154 tool list; fast doesn't exist yet.
        self.use_pre_154_source()
        run(self.db)
        self.db.agents.update_one({"id": m.DATA_ID}, {"$set": {"tools": PRE_154_DB_TOOLS}})
        self.db.agents.update_one({"id": m.NAV_ID}, {"$set": {"tools": [*PRE_154_DB_TOOLS, NAV_TOOL]}})
        fast = self.agent(m.FAST_ID)
        self.db.aclentries.delete_many({"resourceId": fast["_id"]})
        self.db.agents.delete_one({"_id": fast["_id"]})
        out = run(self.db, "--dry-run")
        self.assertIn(f"update {m.DATA_ID}: tools\n", out)
        self.assertIn(f"update {m.NAV_ID}: tools\n", out)
        self.assertIn(f"create {m.FAST_ID} ({m.HAIKU}, 5 tools, 1 edges)", out)
        self.assertIn(f"unchanged {m.ROUTER_ID}", out)

    def test_unified_agent_is_never_written(self):
        self.use_pre_154_source()

        def source_state():
            rows = self.db.aclentries.find({"resourceId": self.source["_id"]})
            return self.db.agents.find_one({"_id": self.source["_id"]}), sorted(repr(sorted(r.items())) for r in rows)

        before = copy.deepcopy(source_state())
        source_before = before[0]
        for args in (("--dry-run",), (), (), ("--delete",)):
            run(self.db, *args)
            self.assertEqual(source_state(), before)
        self.assertNotIn(AGGREGATE_TOOLS[0], source_before["tools"])
        for agent_id in (m.DEFAULT_SOURCE_ID, "agent_prod_unified"):
            with self.assertRaises(SystemExit) as ctx, contextlib.redirect_stdout(io.StringIO()):
                m.upsert_agent(self.db, {"id": agent_id, "model": m.HAIKU, "tools": [], "edges": []}, False)
            self.assertIn(f"refusing to write {agent_id}", str(ctx.exception.code))
        self.assertEqual(self.db.agents.find_one({"_id": self.source["_id"]}), source_before)

    def test_partial_fast_tools_appends_only_missing(self):
        tools = [t for t in EXPLICIT_DB_TOOLS if not t.startswith("get_profiled_counts")]
        self.db.agents.update_one({"_id": self.source["_id"]}, {"$set": {"tools": tools}})
        out = run(self.db)
        self.assertIn("confirm beta's cbioportal-database MCP server lists get_profiled_counts (", out)
        self.assertEqual(self.agent(m.DATA_ID)["tools"], [*tools, "get_profiled_counts_mcp_cbioportal-database"])
        self.assertEqual(self.agent(m.FAST_ID)["tools"], FAST_TOOLS)

    def test_fast_placeholder_left_aborts(self):
        orig = m.read_prompt
        m.read_prompt = lambda name: orig(name) + ("\n<<OTHER_TOOL>>" if name == "fast" else "")
        try:
            before = snapshot(self.db)
            with self.assertRaises(SystemExit) as ctx, contextlib.redirect_stdout(io.StringIO()):
                run(self.db, "--dry-run")
            self.assertIn("prompts/fast.md", str(ctx.exception.code))
            self.assertEqual(snapshot(self.db), before)
        finally:
            m.read_prompt = orig

    def test_fast_prompt_change_updates_only_fast(self):
        run(self.db)
        orig = m.read_prompt
        m.read_prompt = lambda name: orig(name) + ("\nExtra rule." if name == "fast" else "")
        try:
            out = run(self.db)
        finally:
            m.read_prompt = orig
        self.assertIn(f"update {m.FAST_ID}: instructions", out)
        self.assertEqual(out.count("unchanged "), 3)
        self.assertEqual(len(self.agent(m.FAST_ID)["versions"]), 2)

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
