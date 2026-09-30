# cbioagent-beta handoff router

Beta cBioPortalChat routes each question through LibreChat's built-in agent handoffs:

```
cBioPortalChatBeta modelSpec
  -> agent_cbiobeta_router      Haiku 4.5, no MCP tools, thinking off, maxOutputTokens 256
       -> agent_cbiobeta_navigation  Sonnet 5, all tools of the unified agent  (links, study view, plots, cohorts)
       -> agent_cbiobeta_data        Haiku 4.5, cbioportal-database MCP only    (text / table answers)
```

Navigation goes to Sonnet because the benchmark shows it passes navigation questions that Haiku fails. The models score the same on database and analysis questions, so the cheaper Haiku handles those. A question that needs a data lookup **and** a link or view goes to navigation, and so does any question the router is unsure about. The routing rules are in [`prompts/router.md`](prompts/router.md). The specialists are built from the unified beta agent's (`agent_OHVSJI9Gd6gwsDnFSL-Xl`) current instructions:

- **navigation:** [`prompts/navigation.md`](prompts/navigation.md), followed by the full unified prompt, then [`prompts/budget.md`](prompts/budget.md) last.
- **data:** the unified prompt with its navigation parts removed, followed by [`prompts/data.md`](prompts/data.md), so the override wins, then [`prompts/budget.md`](prompts/budget.md) last. The removed parts are the `Capability Selection`, `Navigate Workflow` and `Link First` sections (each through its subsections) and the `Navigation only:` response branch; they are listed in `NAV_SECTIONS` / `NAV_BRANCH_MARKER` in the script. The script stops without writing anything if any of them is missing, or if `navigate_to_`, `resolve_and_route` or `get_studyviewfilter_options` survives the strip. When the unified prompt is restructured, update those constants and re-run. `data.md` also tells the data agent:
  - it has only the Query capability, so any step that feeds Navigate doesn't apply;
  - it has no navigator tools;
  - it must never output any cbioportal.org URL, including the site root. The two exceptions are the "no studies match, browse the site" fallback and the REST API base URL (`https://www.cbioportal.org/api`) for code-usage questions;
  - it must never copy a `url` from `list_studies`;
  - it should send link requests back through the router in a new message.

## Tool budget (pairs with #664)

[`prompts/budget.md`](prompts/budget.md) is the soft tool-round budget approved in #664 ("aim to finish within six tool rounds", then answer with what is available). #664 sets the hard backstop, `recursionLimit` / `maxRecursionLimit` **24** in beta's `librechat-config.yaml`; at that cap LibreChat shows a raw `Recursion limit of 24 reached` error with no final answer, so the budget is what makes the model stop and answer first.

- The script appends `budget.md` as the **last** section of the data and navigation agents, exactly once each. It stops without writing if either ends up with zero or several copies, or doesn't end with it (for example, the text pasted into `data.md` too). Copies are counted as described in the next bullet but one.
- The router doesn't get it: it makes no tool rounds. Instead [`prompts/router.md`](prompts/router.md) ends with "Always respond with exactly one transfer call; never answer the question yourself." The script stops if the budget ever reaches the router.
- **Duplication guard: the script fails, it does not skip.** If the unified agent's instructions already contain the budget (e.g. from #664's unified-only rollout route), both a dry run and an apply exit before writing anything. A copy is found after collapsing whitespace and ignoring case, by the full `budget.md` text **or** either of its key sentences (`BUDGET_KEY_SENTENCES`: "aim to finish within six tool rounds", "After your sixth tool round, make no further tool calls"). So a reformatted or edited copy is caught, while a note that only quotes the heading `Tool budget for each user message:` is not. If `budget.md` is reworded, the script exits until `BUDGET_KEY_SENTENCES` is updated to match. Remove that copy from `agent_OHVSJI9Gd6gwsDnFSL-Xl`, then re-run. Trade-off: beta conversations started before the switch still run on the unified agent (they bypass the router) and are then under #664's cap without the budget; start a new chat. The check runs on the unified prompt before `NAV_SECTIONS` stripping, and the budget is appended after stripping, so stripping can't remove it from the data agent.
- `recursion_limit`: LibreChat reads it only from the **entry** agent, which is `agent_cbiobeta_router` here; the specialists' values are ignored. It must be **≥24 or unset** for #664's cap to apply. The script never writes the field (it isn't in `MANAGED_FIELDS`): a router it creates has none, so the YAML value applies. If the existing router has a positive `recursion_limit` below 24, both a dry run and an apply exit before writing anything, naming the value; unset it or raise it to ≥24 by hand, then re-run. 0, unset and ≥24 pass.

**Order:** rerun this setup (steps 1–3 under [Apply](#apply)) and confirm the budget is live on the data and navigation agents, **then** sync #664's `cbioagent-beta` Argo Application. Syncing the cap first would let long answers end on the raw recursion error instead of a budgeted answer. On an existing setup, expect `update agent_cbiobeta_data: instructions`, `update agent_cbiobeta_navigation: instructions` and `update agent_cbiobeta_router: instructions` (the transfer line).

**Rollback:** undo in the reverse order. Revert #664's config (`recursionLimit: 50` / `maxRecursionLimit: 100`) and sync beta first, so the cap is never live without the budget. Then revert the budget commit, run the dry run, and re-run the script; it pushes the reverted instructions as a new entry in each record's `versions`. Rolling back only the cap needs no rerun of this script.

## How the handoff works (LibreChat `v0.8.7-custom-v3`, `@librechat/agents` 3.2.46)

- Handoffs are the `edges` array on the router's agent record (`{from, to, edgeType: "handoff", description}`). LibreChat gives the router one tool per edge, `lc_transfer_to_<agent id>`, with `description` as the tool description. No `librechat.yaml` change is needed: edge discovery isn't gated by an `agents.capabilities` entry (only the deprecated `agent_ids` chain uses `chain`), and beta sets no `capabilities` list, so it gets the defaults anyway.
- A handoff target must exist, and the user must have VIEW on it through `aclentries`. On the Agents API (`/api/agents/v1/...`) that is `remoteAgent` VIEW. The script gives each new agent the same `aclentries` rows as the unified agent.
- The target receives the whole message history, including tool calls and results from earlier turns. The transfer call itself is filtered out. It runs with its **own** tools, instructions and `model_parameters`.
- **Generation parameters follow #659: thinking off on every agent, Haiku and Sonnet alike, and a 4096-token output cap on the data and navigation agents.** The router keeps 256, since it only emits one argument-free transfer call. The modelSpec preset reaches only the spec's agent, the router: since cBioPortal/LibreChat#36, the fork forwards the preset's `model` plus the allowlisted `thinking`, `thinkingBudget`, `effort`, `maxOutputTokens`, `temperature`, `promptCache` and `promptCacheTtl` to it. The handoff targets never see the preset. So the script sets every generation parameter in each record's `model_parameters`:

  | Agent | `model_parameters` |
  |---|---|
  | router | Haiku 4.5, `thinking: false`, `maxOutputTokens: 256`, `temperature: 0` |
  | data | Haiku 4.5, `thinking: false`, `maxOutputTokens: 4096`, `temperature: 0`, `promptCache: true` |
  | navigation | Sonnet 5, `thinking: false` (no `effort`), `maxOutputTokens: 4096`, `promptCache: true` |

  Key names match `bedrockInputParser` at `7430a52` (`packages/data-provider/src/bedrock.ts`). It accepts both `maxOutputTokens` and `maxTokens` and copies one to the other, with `maxOutputTokens` winning when both are set (`:525-529`). The records use `maxOutputTokens`, which is also the name on #36's preset allowlist. #659's preset `maxTokens: 4096` isn't on that allowlist, so it doesn't change the router's 256.
  `thinking: false` has to be explicit: when `thinking` is unset, the Bedrock parser turns it on with a 2000-token budget. Navigation has no `temperature`, because Anthropic's API rejects `temperature`/`top_p`/`top_k` on Sonnet 5 with a 400 (sampling parameters are removed on that model), and `omitsSamplingParameters` at `7430a52` doesn't drop them for Sonnet 5.
- Every turn starts at the router again, so each question is routed on its own. A follow-up such as "now give me the link" goes to navigation.
- **Existing conversations bypass the router.** A conversation stores the `agent_id` it started with, so beta conversations created before the switch keep running on the unified agent. Only new chats use the router. Start a new chat when testing.

## Latency and prompt caching

- **Router hop.** Each turn adds one Haiku 4.5 Bedrock call. The input is the router prompt, two small tool definitions and the conversation history, and the output is a single tool call with no arguments (about 20–40 tokens). Expect roughly **0.5–1.5 s** extra per turn, dominated by Haiku's time to first token. It grows with long histories, because the router reads the full history. Specialist setup adds little, since MCP tool definitions come from the server registry cache. These are estimates; the benchmark below measures the real value.
- **Caching.** Bedrock caches by exact prefix (tools → system → messages) and per model, so each agent keeps its own cache and switching agents does not invalidate another agent's. Each specialist's prefix is stable across turns and users. LibreChat puts a fixed "transferred from cBioPortalChat Router (beta)" preamble at the top of the specialist's system prompt, and it doesn't change between turns. Consecutive turns on the same specialist within the 5-minute TTL hit the cache. After a switch (data → navigation), the new specialist's tools and system prefix are still warm if anyone has used it recently, and only its copy of the conversation history is written fresh. The router's prefix is below Haiku 4.5's minimum cacheable size, so the router is billed in full every turn, but that input is small. The first requests after apply are cache writes, because the specialists' prefixes differ from the unified agent's.

## Apply

MongoDB is shared with prod. The script writes only `agent_cbiobeta_router`, `agent_cbiobeta_data`, `agent_cbiobeta_navigation` and their `aclentries` rows. It reads the unified beta agent and never writes it. Prod's modelSpecs don't reference the new ids.

Run the script **before** merging the `librechat-config.yaml` change: once Argo syncs the ConfigMap, beta's `cBioPortalChatBeta` spec points at `agent_cbiobeta_router`.

```bash
pip install pymongo
# Port-forward the shared MongoDB (cbioportal-prod cluster, default namespace)
kubectl port-forward svc/cbioagent-mongodb 27017:27017 &
# MONGO_URI is in the librechat-credentials-env Secret (portal-configuration); point its host at localhost:27017
export MONGO_URI='mongodb://<user>:<pass>@localhost:27017/cBioAgent?authSource=admin'
```

1. Dry run: `./setup_handoff_agents.py --dry-run`. It writes nothing.
2. Check the output. On a first apply it must contain exactly these three create lines (plus `acl grant` lines under each):
   ```
   create agent_cbiobeta_router (us.anthropic.claude-haiku-4-5-20251001-v1:0, 0 tools, 2 edges)
   create agent_cbiobeta_data (us.anthropic.claude-haiku-4-5-20251001-v1:0, <n> tools, 0 edges)
   create agent_cbiobeta_navigation (us.anthropic.claude-sonnet-5, <n> tools, 0 edges)
   ```
   A different line, such as `update ...` on a first run, or an exit mentioning `NAV_SECTIONS`, means stop and investigate. The dry run also prints what was removed from the data agent's copy of the unified prompt: each heading, the `Navigation only:` item, and the character counts. It then lists every remaining line that mentions navigate, link, url or cbioportal.org (case-insensitive), which `data.md` overrides. Read them to confirm nothing else still sends the data agent toward navigation. A `tool budget (prompts/budget.md), last section of agent_cbiobeta_data and agent_cbiobeta_navigation: ...` line confirms the budget; an exit saying the instructions `already contain the tool budget` means the unified agent already has a copy, and an exit naming `recursion_limit` means the router's limit is below 24 (see [Tool budget](#tool-budget-pairs-with-664)). A `note: ... not touched` line means a copy of a managed id exists under a different tenantId; it's left alone.
3. Apply: `./setup_handoff_agents.py`. Re-running is safe; unchanged agents print `unchanged`.

After changing a file in `prompts/`, or the unified agent's instructions or tools, re-run steps 1–3 to update the three agents.

## Validate on beta

In a **new** chat on beta.chat.cbioportal.org, after the pod has rolled:

- **Data question**, e.g. "How many studies have whole exome sequencing data?": the router hands off to `agent_cbiobeta_data`. The turn must contain **no `navigate_to_*` (or `resolve_and_route`) tool call and no `cbioportal.org` URL** in the answer.
- **Navigation question**, e.g. "Give me an OncoPrint for EGFR and KRAS in TCGA lung adenocarcinoma": the router hands off to `agent_cbiobeta_navigation`, and the answer has a working cBioPortal link.
- Neither turn returns a Bedrock 400. No turn (router, data or navigation) shows thinking blocks or `reasoning_content`.

Then run `cbioportal-mcp-qa --target beta --repeats 3` and compare median latency and pass rate by question category against the single-agent baseline.

## Tests

```bash
pip install pymongo mongomock
python -m unittest scripts/cbioagent-beta/test_setup_handoff_agents.py
```

## Point beta at a different agent

The beta default is `modelSpecs.list[0].preset.agent_id` in [`librechat-config.yaml`](../../argocd/aws/203403084713/clusters/cbioportal-prod/apps/cbioagent-beta/librechat-config.yaml) (`agent_cbiobeta_router`). Change it and merge. Argo syncs the ConfigMap and reloader restarts the beta pod.

## Rollback

1. Revert the `librechat-config.yaml` change (set `agent_id` back to `agent_OHVSJI9Gd6gwsDnFSL-Xl` and restore the Sonnet spec). The unified agent is never modified, so this restores the previous behavior exactly.
2. Optional: `./setup_handoff_agents.py --delete --dry-run`, then `--delete`, removes the three agents and their `aclentries` rows. Only do this after step 1 is live, because deleting while the spec still references the router breaks beta.
