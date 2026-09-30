# cbioagent-beta handoff router

Beta cBioPortalChat routes each question through LibreChat's built-in agent handoffs:

```
cBioPortalChatBeta modelSpec
  -> agent_cbiobeta_router      Haiku 4.5, no MCP tools, thinking off, maxOutputTokens 256
       -> agent_cbiobeta_navigation  Sonnet 5, all tools of the unified agent  (links, study view, plots, cohorts)
       -> agent_cbiobeta_data        Haiku 4.5, cbioportal-database MCP only    (text / table answers)
       -> agent_cbiobeta_fast        Haiku 4.5, 4 #154 tools + list_studies     (templated frequency / count questions)
            -> agent_cbiobeta_data   (escalation when the fast tool can't answer)
```

Navigation goes to Sonnet because the benchmark shows it passes navigation questions that Haiku fails. The models score the same on database and analysis questions, so the cheaper Haiku handles those. A question that needs a data lookup **and** a link or view goes to navigation, and so does any question the router is unsure about. The routing rules are in [`prompts/router.md`](prompts/router.md); the fast path is described [below](#fast-path). The specialists are built from the unified beta agent's (`agent_OHVSJI9Gd6gwsDnFSL-Xl`) current instructions:

- **navigation:** [`prompts/navigation.md`](prompts/navigation.md), followed by the full unified prompt, then [`prompts/budget.md`](prompts/budget.md) last.
- **data:** the unified prompt with its navigation parts removed, followed by [`prompts/data.md`](prompts/data.md), so the override wins, then [`prompts/budget.md`](prompts/budget.md) last. The removed parts are the `Capability Selection`, `Navigate Workflow` and `Link First` sections (each through its subsections) and the `Navigation only:` response branch; they are listed in `NAV_SECTIONS` / `NAV_BRANCH_MARKER` in the script. The script stops without writing anything if any of them is missing, or if `navigate_to_`, `resolve_and_route` or `get_studyviewfilter_options` survives the strip. When the unified prompt is restructured, update those constants and re-run. `data.md` also tells the data agent:
  - it has only the Query capability, so any step that feeds Navigate doesn't apply;
  - it has no navigator tools;
  - it must never output any cbioportal.org URL, including the site root. The two exceptions are the "no studies match, browse the site" fallback and the REST API base URL (`https://www.cbioportal.org/api`) for code-usage questions;
  - it must never copy a `url` from `list_studies`;
  - it should send link requests back through the router in a new message.

## Fast path

Recurring templated questions ("how often is KRAS mutated in msk_impact_2017", "top 10 mutated genes in STUDY", "which cancer types have the highest IDH1 frequency", "how many samples are in STUDY") are answered by `agent_cbiobeta_fast` in two model calls after the router: one tool call, then the answer. A study named in words adds one `list_studies` call. So a fast turn is 3 generations (router, tool call, answer), or 4 with a study lookup.

- **Tools** (`FAST_TOOL_NAMES`): exactly `get_alteration_frequency`, `get_top_altered_genes`, `get_gene_frequency_by_cancer_type` and `get_profiled_counts` from cbioportal-mcp #154, plus `list_studies`, all as `<tool>_mcp_cbioportal-database`. `list_studies(search)` is the database MCP's only tool that maps a study name to its `cancer_study_identifier`. The others don't: `search_oncotree` resolves OncoTree cancer-type codes, not studies; `get_study_guide` needs the ID already; `list_study_guides` covers only studies with a curated guide. No `clickhouse_*` tool, so the fast agent can't fall into writing SQL.
  - If the unified agent lists `cbioportal-database` tools one by one, the script exits unless all five are there. If it has the all-tools entry (`sys__all__sys_mcp_cbioportal-database`), the tool list can't show whether beta's MCP server has #154's tools, so both a dry run and an apply print `warning: agent_cbiobeta_fast tools not verified`. Check the server's tool list before applying.
- **Instructions:** [`prompts/fast.md`](prompts/fast.md) only, not the unified prompt. The tools do the SQL, so the unified prompt's schema and workflow text would only add input tokens. `fast.md` first has the agent check the question itself, without trusting the router: every qualifier and counting unit must be one the matching tool supports, or it transfers to data before any tool call. The alteration-frequency tools count samples only (`altered_samples` of `profiled_samples`); `get_profiled_counts` has patient totals but no alteration counts. So a patient-level frequency ("what percentage of patients have a KRAS mutation") is never answered with sample counts; `router.md` also keeps such questions away from fast. Then `fast.md` says to call the matching tool (at most one `list_studies` lookup before it), answer only from the tool output with its numerator and denominator, never invent or extrapolate, and never output a cbioportal.org URL (the same two exceptions as `data.md`).
- **Escalation:** the fast agent has one handoff edge, to `agent_cbiobeta_data` (`lc_transfer_to_agent_cbiobeta_data`). It hands off when the tool returns `error_message`, a `note`, no `rows` or a `fallback_reason`, when `list_studies` finds no match or several, or when the question needs more than one fast tool. The data agent gets the whole history, including the fast agent's tool calls and results, so it can reuse them. `fast.md` also covers a missing transfer tool (say what was found, suggest asking again). One exception: `get_alteration_frequency` reports a requested alteration that is absent from the study through its live fallback, with `fallback_reason` `no precomputed row (gene unaltered in study, or unknown)` or `no precomputed row for alteration_type=<type> (0 altered)` (cbioportal-mcp `domain_tools.py` L559, L579 on `beta`). The fast agent answers "0 of N profiled samples (0%)" directly only when there is no `error_message`, the reason starts with `no precomputed row`, the result names the requested gene and study, and the requested row has `altered_samples` 0, `profiled_samples` > 0 and `frequency_pct` 0. That can't fire for real failures: an unknown study or gene returns only `error_message` (L597, L600), and a missing precomputed table gives `precomputed table unavailable (...)` (L562).
- **Forcing the tool call:** not possible in this LibreChat version, so it is enforced by the prompt only. `@librechat/agents` 3.2.46 binds tools with `model.bindTools(tools)` and passes no `tool_choice` (`dist/esm/llm/init.mjs:42`), and `@langchain/aws` sets Bedrock `toolChoice` only from call options (`dist/chat_models.js:593`), which LibreChat never sets for agents. A `tool_choice` key in `model_parameters` would not help: `bedrockInputParser` moves unknown keys into `additionalModelRequestFields` (`packages/data-provider/src/bedrock.ts:349-358`), and forcing a tool on every call would also block the answer call after the tool result.
- **Budget:** `fast.md` carries its own budget: one tool round, two at most, then answer or hand off. [`prompts/budget.md`](prompts/budget.md) (six rounds) is **not** appended: it would contradict the two-round limit, and the fast agent's only way to spend more rounds is to hand off. The script exits if `budget.md` (full text or a key sentence) ends up in the fast or router instructions. Under #664's cap of 24 graph steps, the worst case (router 2 + fast 2 rounds and a handoff, about 6 + data 6 rounds and the answer, about 13) is about 21. `budget.md` counts every round since the latest user message, so the data agent's six include the fast agent's.

## Tool budget (pairs with #664)

[`prompts/budget.md`](prompts/budget.md) is the soft tool-round budget approved in #664 ("aim to finish within six tool rounds", then answer with what is available). #664 sets the hard backstop, `recursionLimit` / `maxRecursionLimit` **24** in beta's `librechat-config.yaml`; at that cap LibreChat shows a raw `Recursion limit of 24 reached` error with no final answer, so the budget is what makes the model stop and answer first.

- The script appends `budget.md` as the **last** section of the data and navigation agents, exactly once each. It stops without writing if either ends up with zero or several copies, or doesn't end with it (for example, the text pasted into `data.md` too). Copies are counted as described in the next bullet but one.
- The router doesn't get it: it makes no tool rounds. The fast agent doesn't get it either; it has a tighter budget of its own (see [Fast path](#fast-path)). Instead [`prompts/router.md`](prompts/router.md) ends with "Always respond with exactly one transfer call; never answer the question yourself." The script stops if the budget ever reaches the router.
- **Duplication guard: the script fails, it does not skip.** If the unified agent's instructions already contain the budget (e.g. from #664's unified-only rollout route), both a dry run and an apply exit before writing anything. A copy is found after collapsing whitespace and ignoring case, by the full `budget.md` text **or** either of its key sentences (`BUDGET_KEY_SENTENCES`: "aim to finish within six tool rounds", "After your sixth tool round, make no further tool calls"). So a reformatted or edited copy is caught, while a note that only quotes the heading `Tool budget for each user message:` is not. If `budget.md` is reworded, the script exits until `BUDGET_KEY_SENTENCES` is updated to match. Remove that copy from `agent_OHVSJI9Gd6gwsDnFSL-Xl`, then re-run. Trade-off: beta conversations started before the switch still run on the unified agent (they bypass the router) and are then under #664's cap without the budget; start a new chat. The check runs on the unified prompt before `NAV_SECTIONS` stripping, and the budget is appended after stripping, so stripping can't remove it from the data agent.
- `recursion_limit`: LibreChat reads it only from the **entry** agent, which is `agent_cbiobeta_router` here; the specialists' values are ignored. It must be **≥24 or unset** for #664's cap to apply. The script never writes the field (it isn't in `MANAGED_FIELDS`): a router it creates has none, so the YAML value applies. If the existing router has a positive `recursion_limit` below 24, both a dry run and an apply exit before writing anything, naming the value; unset it or raise it to ≥24 by hand, then re-run. 0, unset and ≥24 pass.

**Order:** rerun this setup (steps 1–3 under [Apply](#apply)) and confirm the budget is live on the data and navigation agents, **then** sync #664's `cbioagent-beta` Argo Application. Syncing the cap first would let long answers end on the raw recursion error instead of a budgeted answer. On an existing setup, expect `update agent_cbiobeta_data: instructions`, `update agent_cbiobeta_navigation: instructions` and `update agent_cbiobeta_router: instructions` (the transfer line).

**Rollback:** undo in the reverse order. Revert #664's config (`recursionLimit: 50` / `maxRecursionLimit: 100`) and sync beta first, so the cap is never live without the budget. Then revert the budget commit, run the dry run, and re-run the script; it pushes the reverted instructions as a new entry in each record's `versions`. Rolling back only the cap needs no rerun of this script.

## How the handoff works (LibreChat `v0.8.7-custom-v3`, `@librechat/agents` 3.2.46)

- Handoffs are the `edges` array on an agent record (`{from, to, edgeType: "handoff", description}`). LibreChat gives the source agent one tool per edge, `lc_transfer_to_<agent id>`, with `description` as the tool description. The router has three edges (navigation, data, fast), and the fast agent has one (data). A specialist's own edges work: `discoverConnectedAgents` collects the edges of every agent it reaches from the router (`packages/api/src/agents/discovery.ts:289-297`), and `MultiAgentGraph.createHandoffTools` builds transfer tools for every source agent, not only the entry one (`@librechat/agents` `dist/esm/graphs/MultiAgentGraph.mjs:161-176`). No `librechat.yaml` change is needed: edge discovery isn't gated by an `agents.capabilities` entry (only the deprecated `agent_ids` chain uses `chain`), and beta sets no `capabilities` list, so it gets the defaults anyway.
- A handoff target must exist, and the user must have VIEW on it through `aclentries`. On the Agents API (`/api/agents/v1/...`) that is `remoteAgent` VIEW. The script gives each new agent the same `aclentries` rows as the unified agent.
- The target receives the whole message history, including tool calls and results from earlier turns. The transfer call itself is filtered out. It runs with its **own** tools, instructions and `model_parameters`.
- **Generation parameters follow #659: thinking off on every agent, Haiku and Sonnet alike, and a 4096-token output cap on the data, navigation and fast agents.** The router keeps 256, since it only emits one argument-free transfer call. The modelSpec preset reaches only the spec's agent, the router. Since cBioPortal/LibreChat#36 and #37, the fork forwards the preset's `model` plus the allowlisted `thinking`, `thinkingBudget`, `effort`, `maxOutputTokens`, `maxTokens`, `temperature`, `promptCache` and `promptCacheTtl` to it, overriding the router record. The preset therefore sets the same `thinking: false` and a 256 cap (`maxTokens: 256`), replacing #659's 4096 for this spec only. The handoff targets never see the preset. So the script sets every generation parameter in each record's `model_parameters`:

  | Agent | `model_parameters` |
  |---|---|
  | router | Haiku 4.5, `thinking: false`, `maxOutputTokens: 256`, `temperature: 0`, `promptCacheTtl: "1h"` |
  | data | Haiku 4.5, `thinking: false`, `maxOutputTokens: 4096`, `temperature: 0`, `promptCache: true`, `promptCacheTtl: "1h"` |
  | navigation | Sonnet 5, `thinking: false` (no `effort`), `maxOutputTokens: 4096`, `promptCache: true`, `promptCacheTtl: "1h"` |
  | fast | Haiku 4.5, `thinking: false`, `maxOutputTokens: 4096`, `temperature: 0`, `promptCache: true`, `promptCacheTtl: "1h"` |

  Key names match `bedrockInputParser` at `7430a52` (`packages/data-provider/src/bedrock.ts`). It accepts both `maxOutputTokens` and `maxTokens` and copies one to the other, with `maxOutputTokens` winning when both are set (`:525-529`). The records use `maxOutputTokens`, which is also the name on #36's preset allowlist.
  `thinking: false` has to be explicit: when `thinking` is unset, the Bedrock parser turns it on with a 2000-token budget. Navigation has no `temperature`, because Anthropic's API rejects `temperature`/`top_p`/`top_k` on Sonnet 5 with a 400 (sampling parameters are removed on that model), and `omitsSamplingParameters` at `7430a52` doesn't drop them for Sonnet 5.
- Every turn starts at the router again, so each question is routed on its own. A follow-up such as "now give me the link" goes to navigation.
- **Existing conversations bypass the router.** A conversation stores the `agent_id` it started with, so beta conversations created before the switch keep running on the unified agent. Only new chats use the router. Start a new chat when testing.

## Latency and prompt caching

- **Router hop.** Each turn adds one Haiku 4.5 Bedrock call. The input is the router prompt, two small tool definitions and the conversation history, and the output is a single tool call with no arguments (about 20–40 tokens). Expect roughly **0.5–1.5 s** extra per turn, dominated by Haiku's time to first token. It grows with long histories, because the router reads the full history. Specialist setup adds little, since MCP tool definitions come from the server registry cache. These are estimates; the benchmark below measures the real value.
- **Caching.** Bedrock caches by exact prefix (tools → system → messages) and per model, so each agent keeps its own cache and switching agents does not invalidate another agent's. Each specialist's prefix is stable across turns and users. LibreChat puts a "transferred from <source agent name>" preamble at the top of the specialist's system prompt. It is fixed for a given source, so the data agent keeps one cache prefix for turns from the router and another for turns escalated by the fast agent. Consecutive turns on the same specialist within the 1-hour TTL hit the cache.
- **1-hour TTL.** Every managed agent sets `promptCacheTtl: "1h"` in its `model_parameters`, and LibreChat `v0.8.7-custom-v3` (`7430a52`) honours it from the agent's own record for Bedrock:
  - `initializeAgent` merges `agent.model_parameters` into the options (`packages/api/src/agents/initialize.ts:596-602`); `extractLibreChatParams` removes only `resendFiles`, `promptPrefix`, `maxContextTokens`, `fileTokenLimit` and `modelLabel` (`packages/api/src/utils/llm.ts:29-37`).
  - `initializeBedrock` runs them through `bedrockInputParser`, which keeps `promptCacheTtl` as a known key (`packages/data-provider/src/bedrock.ts:316, 341`) and drops it only when `promptCache` isn't true (`:514-516`), then `bedrockOutputParser`, which keeps every `tConversationSchema` key, including `promptCacheTtl: z.enum(['5m', '1h'])` (`packages/data-provider/src/schemas.ts:923`).
  - The result becomes the agent's `clientOptions` (`initialize.ts:1141`, `run.ts:1080`). `@librechat/agents` 3.2.46 reads `clientOptions.promptCacheTtl` for the system, message and tool cache points (`dist/esm/agents/AgentContext.mjs:466-468`, `graphs/Graph.mjs:974-976`, `llm/bedrock/index.mjs:60, 80`).

  The beta modelSpec preset also sets `promptCacheTtl: 1h` (#653). Through #36 it reaches only the router, where it wins over the record; the two values are the same (like the preset's `thinking: false` and `maxTokens: 256`). The duplication is intended. The specialists never see the preset, so their TTL has to live in their records. The router's own copy keeps it at 1h when the router runs without the spec, e.g. an Agents API request with no `spec`. Change both together.
  The same library already defaults Claude on Bedrock to `1h` when the key is unset (`dist/esm/messages/cache.mjs:16-18, 79-81`), so on this version the setting pins the current behavior rather than changing it; it keeps the TTL if a later library changes the default. The router sets no `promptCache`; the parser defaults it to true for Claude models (`bedrock.ts:502-504`), so its TTL isn't dropped. A 1-hour cache write costs 2× base input instead of 1.25×, and cache reads are what make it pay. After a switch (data → navigation), the new specialist's tools and system prefix are still warm if anyone has used it recently, and only its copy of the conversation history is written fresh. The router's prefix is below Haiku 4.5's minimum cacheable size, so the router is billed in full every turn, but that input is small. The fast agent's prefix (a short prompt and five tool definitions) is probably below it too; its input is small for the same reason. The first requests after apply are cache writes, because the specialists' prefixes differ from the unified agent's.

## Apply

MongoDB is shared with prod. The script writes only `agent_cbiobeta_router`, `agent_cbiobeta_data`, `agent_cbiobeta_navigation`, `agent_cbiobeta_fast` and their `aclentries` rows. It reads the unified beta agent and never writes it. Prod's modelSpecs don't reference the new ids.

Run the script **before** merging the `librechat-config.yaml` change: once Argo syncs the ConfigMap, beta's `cBioPortalChatBeta` spec points at `agent_cbiobeta_router`.

```bash
pip install pymongo
# Port-forward the shared MongoDB (cbioportal-prod cluster, default namespace)
kubectl port-forward svc/cbioagent-mongodb 27017:27017 &
# MONGO_URI is in the librechat-credentials-env Secret (portal-configuration); point its host at localhost:27017
export MONGO_URI='mongodb://<user>:<pass>@localhost:27017/cBioAgent?authSource=admin'
```

1. Dry run: `./setup_handoff_agents.py --dry-run`. It writes nothing.
2. Check the output. On a first apply it must contain exactly these four create lines (plus `acl grant` lines under each):
   ```
   create agent_cbiobeta_data (us.anthropic.claude-haiku-4-5-20251001-v1:0, <n> tools, 0 edges)
   create agent_cbiobeta_navigation (us.anthropic.claude-sonnet-5, <n> tools, 0 edges)
   create agent_cbiobeta_fast (us.anthropic.claude-haiku-4-5-20251001-v1:0, 5 tools, 1 edges)
   create agent_cbiobeta_router (us.anthropic.claude-haiku-4-5-20251001-v1:0, 0 tools, 3 edges)
   ```
   The router is written last, so its new edges never point at an agent that doesn't exist yet.
   On a setup that already has the other three, expect `create agent_cbiobeta_fast ...`, `update agent_cbiobeta_router: edges, instructions, model_parameters` and `update agent_cbiobeta_data: model_parameters` / `update agent_cbiobeta_navigation: model_parameters` (the `promptCacheTtl` key), and nothing else.
   A different line, such as `update ...` on a first run, or an exit mentioning `NAV_SECTIONS`, means stop and investigate. The dry run also prints what was removed from the data agent's copy of the unified prompt: each heading, the `Navigation only:` item, and the character counts. It then lists every remaining line that mentions navigate, link, url or cbioportal.org (case-insensitive), which `data.md` overrides. Read them to confirm nothing else still sends the data agent toward navigation. A `tool budget (prompts/budget.md), last section of agent_cbiobeta_data and agent_cbiobeta_navigation: ...` line confirms the budget; an exit saying the instructions `already contain the tool budget` means the unified agent already has a copy, and an exit naming `recursion_limit` means the router's limit is below 24 (see [Tool budget](#tool-budget-pairs-with-664)). An `agent_cbiobeta_fast tools: ...` line lists the fast agent's five tools; if a `warning: agent_cbiobeta_fast tools not verified` line follows (an apply prints it too), confirm that beta's `cbioportal-database` server lists them (cbioportal-mcp #154) before applying. An exit naming a `_mcp_cbioportal-database` tool means the unified agent lists its tools one by one and lacks that one. A `note: ... not touched` line means a copy of a managed id exists under a different tenantId; it's left alone.
3. Apply: `./setup_handoff_agents.py`. Re-running is safe; unchanged agents print `unchanged`.

After changing a file in `prompts/`, or the unified agent's instructions or tools, re-run steps 1–3 to update the four agents. `fast.md` doesn't use the unified prompt, so a change there alone shows `update agent_cbiobeta_fast: instructions` and three `unchanged` lines.

## Validate on beta

In a **new** chat on beta.chat.cbioportal.org, after the pod has rolled:

- **Data question**, e.g. "How many studies have whole exome sequencing data?": the router hands off to `agent_cbiobeta_data`. The turn must contain **no `navigate_to_*` (or `resolve_and_route`) tool call and no `cbioportal.org` URL** in the answer.
- **Navigation question**, e.g. "Give me an OncoPrint for EGFR and KRAS in TCGA lung adenocarcinoma": the router hands off to `agent_cbiobeta_navigation`, and the answer has a working cBioPortal link.
- **Fast questions**, e.g. "What percentage of samples in msk_impact_2017 have a KRAS mutation?", "Top 10 most mutated genes in luad_tcga_pan_can_atlas_2018", "How many samples and patients are in the MSK-IMPACT 2017 study?": the router hands off to `agent_cbiobeta_fast`, which calls one #154 tool (plus `list_studies` for the named study) and answers with the tool's numerator and denominator, with no cbioportal.org URL.
- **Not fast**, e.g. "Do TP53 and PIK3CA mutations co-occur in breast cancer?", "TP53 mutation frequency in patients over 60 in TCGA breast cancer", "Compare EGFR mutation frequency between lung adenocarcinoma and squamous cell carcinoma", and a follow-up "What about in the MSK cohort?": the router hands off to `agent_cbiobeta_data`, never to `agent_cbiobeta_fast`. "What is the KRAS mutation frequency in msk_impact_2017? Include a link." goes to navigation.
- None of these turns returns a Bedrock 400. No turn (router, data, navigation or fast) shows thinking blocks or `reasoning_content`.

Then run `cbioportal-mcp-qa --target beta --repeats 3` and compare median latency and pass rate by question category against the single-agent baseline. For the fast path, check each result's trace:

- Templated questions (the four shapes above, with an explicit gene and/or study) should show `routed_to=agent_cbiobeta_fast`, `handoffs=1` and 1–2 fast-agent model calls after the router, so `llm_calls` 3 (4 with a study lookup) and 1–2 tool rounds.
- Non-template data questions must **not** show `agent_cbiobeta_fast` anywhere in `handoff_evidence`. Any that do are router mistakes to fix in `router.md`.
- An escalated fast turn shows `routed_to=agent_cbiobeta_data` with `handoffs=2` (router → fast → data). The runner records the agent of the final model call, so these count as data. Count them from `handoff_evidence`; if they are frequent, the router is sending too much to fast.

The runner needs no change for the new agent: `routed_to` is the last generation's agent id, whatever it is (`cbioportal_mcp_qa/traces.py:161-162`), and `describe_agents` follows `edges` from the router, so it also records the fast agent's prompt fingerprint.

## Tests

```bash
pip install pymongo mongomock
python -m unittest scripts/cbioagent-beta/test_setup_handoff_agents.py
```

## Point beta at a different agent

The beta default is `modelSpecs.list[0].preset.agent_id` in [`librechat-config.yaml`](../../argocd/aws/203403084713/clusters/cbioportal-prod/apps/cbioagent-beta/librechat-config.yaml) (`agent_cbiobeta_router`). Change it and merge. Argo syncs the ConfigMap and reloader restarts the beta pod.

## Rollback

1. Revert the `librechat-config.yaml` change (set `agent_id` back to `agent_OHVSJI9Gd6gwsDnFSL-Xl` and restore the Sonnet spec). The unified agent is never modified, so this restores the previous behavior exactly.
2. Optional: `./setup_handoff_agents.py --delete --dry-run`, then `--delete`, removes the four agents and their `aclentries` rows. Only do this after step 1 is live, because deleting while the spec still references the router breaks beta.

**Fast path only:** revert the fast-path commit and re-run the dry run, then the script. The router goes back to two edges and the old `router.md`, so nothing routes to fast any more; `agent_cbiobeta_fast` stays in MongoDB, unused, because the script no longer manages it. Remove it by hand (the agent and its `aclentries` rows), or run `--delete` from the fast-path commit **before** reverting, which removes all four agents, so only do that as part of a full rollback. The `promptCacheTtl` keys also go away on the other agents, which changes nothing on `@librechat/agents` 3.2.46 (its default is already `1h`).
