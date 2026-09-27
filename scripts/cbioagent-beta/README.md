# cbioagent-beta handoff router

Beta cBioPortalChat routes each question through LibreChat's built-in agent handoffs:

```
cBioPortalChatBeta modelSpec
  -> agent_cbiobeta_router      Haiku 4.5, no MCP tools, thinking off, maxOutputTokens 256
       -> agent_cbiobeta_navigation  Sonnet 5, all tools of the unified agent  (links, study view, plots, cohorts)
       -> agent_cbiobeta_data        Haiku 4.5, cbioportal-database MCP only    (text / table answers)
```

Navigation goes to Sonnet because the benchmark shows it passes navigation questions that Haiku fails. The models score the same on database and analysis questions, so the cheaper Haiku handles those. A question that needs a data lookup **and** a link or view goes to navigation, and so does any question the router is unsure about. The routing rules are in [`prompts/router.md`](prompts/router.md). The specialists' instructions are [`prompts/data.md`](prompts/data.md) or [`prompts/navigation.md`](prompts/navigation.md), followed by the unified beta agent's (`agent_OHVSJI9Gd6gwsDnFSL-Xl`) current instructions.

## How the handoff works (LibreChat `v0.8.7-custom-v3`, `@librechat/agents` 3.2.46)

- Handoffs are the `edges` array on the router's agent record (`{from, to, edgeType: "handoff", description}`). LibreChat gives the router one tool per edge, `lc_transfer_to_<agent id>`, with `description` as the tool description. No `librechat.yaml` change is needed: edge discovery isn't gated by an `agents.capabilities` entry (only the deprecated `agent_ids` chain uses `chain`), and beta sets no `capabilities` list, so it gets the defaults anyway.
- A handoff target must exist, and the user must have VIEW on it through `aclentries`. On the Agents API (`/api/agents/v1/...`) that is `remoteAgent` VIEW. The script gives each new agent the same `aclentries` rows as the unified agent.
- The target receives the whole message history, including tool calls and results from earlier turns. The transfer call itself is filtered out. It runs with its **own** tools, instructions and `model_parameters`.
- Of the modelSpec preset, only `model` reaches an agent (the router), through the fork's spec override. `compactAgentsSchema` strips `temperature`, `promptCache`, `thinking`, `effort` and max-token settings. So the script sets every generation parameter in each record's `model_parameters`. Key names match `bedrockInputParser` at `7430a52`:

  | Agent | `model_parameters` |
  |---|---|
  | router | Haiku 4.5, `thinking: false`, `maxOutputTokens: 256`, `temperature: 0` |
  | data | Haiku 4.5, `thinking: false`, `maxOutputTokens: 8192`, `temperature: 0`, `promptCache: true` |
  | navigation | Sonnet 5, `thinking: true` + `effort: "low"` (adaptive), `maxOutputTokens: 8192`, `promptCache: true` |

  `thinking: false` is required on Haiku 4.5: when `thinking` is unset, the Bedrock parser turns it on with a 2000-token budget. Navigation has no `temperature`, because Sonnet 5 rejects sampling parameters with a 400 and this parser only strips them for Opus 4.7+ and Mythos-class models.
- Every turn starts at the router again, so each question is routed on its own. A follow-up such as "now give me the link" goes to navigation.

## Latency and prompt caching

- **Router hop.** Each turn adds one Haiku 4.5 Bedrock call. The input is the router prompt, two small tool definitions and the conversation history, and the output is a single tool call with no arguments (about 20–40 tokens). Expect roughly **0.5–1.5 s** extra per turn, dominated by Haiku's time to first token. It grows with long histories, because the router reads the full history. Specialist setup adds little, since MCP tool definitions come from the server registry cache. These are estimates; the benchmark below measures the real value.
- **Caching.** Bedrock caches by exact prefix (tools → system → messages) and per model, so each agent keeps its own cache and switching agents does not invalidate another agent's. Each specialist's prefix is stable across turns and users. LibreChat puts a fixed "transferred from cBioPortalChat Router (beta)" preamble at the top of the specialist's system prompt, and it doesn't change between turns. Consecutive turns on the same specialist within the 5-minute TTL hit the cache. After a switch (data → navigation), the new specialist's tools and system prefix are still warm if anyone has used it recently, and only its copy of the conversation history is written fresh. The router's prefix is below Haiku 4.5's minimum cacheable size, so the router is billed in full every turn, but that input is small. The first requests after apply are cache writes, because the specialists' prefixes differ from the unified agent's.

## Apply

MongoDB is shared with prod. The script writes only `agent_cbiobeta_router`, `agent_cbiobeta_data`, `agent_cbiobeta_navigation` and their `aclentries` rows. It reads the unified beta agent and never writes it. Prod's modelSpecs don't reference the new ids.

```bash
pip install pymongo
# Port-forward the shared MongoDB (cbioportal-prod cluster, default namespace)
kubectl port-forward svc/cbioagent-mongodb 27017:27017 &
# MONGO_URI is in the librechat-credentials-env Secret (portal-configuration); point its host at localhost:27017
export MONGO_URI='mongodb://<user>:<pass>@localhost:27017/cBioAgent?authSource=admin'

./setup_handoff_agents.py --dry-run   # review the plan
./setup_handoff_agents.py             # create/update; re-run any time — unchanged agents are skipped
```

Run the script **before** merging the `librechat-config.yaml` change: once Argo syncs the ConfigMap, beta's `cBioPortalChatBeta` spec points at `agent_cbiobeta_router`. After changing a file in `prompts/`, or the unified agent's instructions or tools, re-run the script to update the three agents.

## Point beta at a different agent

The beta default is `modelSpecs.list[0].preset.agent_id` in [`librechat-config.yaml`](../../argocd/aws/203403084713/clusters/cbioportal-prod/apps/cbioagent-beta/librechat-config.yaml) (`agent_cbiobeta_router`). Change it and merge. Argo syncs the ConfigMap and reloader restarts the beta pod.

## Rollback

1. Revert the `librechat-config.yaml` change (set `agent_id` back to `agent_OHVSJI9Gd6gwsDnFSL-Xl` and restore the Sonnet spec). The unified agent is never modified, so this restores the previous behavior exactly.
2. Optional: `./setup_handoff_agents.py --delete --dry-run`, then `--delete`, removes the three agents and their `aclentries` rows. Only do this after step 1 is live, because deleting while the spec still references the router breaks beta.
