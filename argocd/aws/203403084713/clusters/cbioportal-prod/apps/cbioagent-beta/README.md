# cbioagent-beta

Beta LibreChat instance at **https://beta.chat.cbioportal.org**, used to test new agent variants (e.g. `cBioDBAgentBeta`, `cBioNavigatorBeta`) and LibreChat changes before promoting to prod.

## Shared backend

Beta is **only a second LibreChat frontend** — it reuses every backend service from prod:

| Backend | Shared | Notes |
|---------|--------|-------|
| MongoDB (`cbioagent-mongodb`) | yes | Same `cBioAgent` database — all agents, conversations, and users are visible in both instances |
| meilisearch (`cbioagent-meilisearch`) | yes | Only if configured via `librechat-credentials-env` |
| RAG API (`cbioagent-librechat-rag-api`) | yes | Same |
| Navigator MCP (`cbioportal-navigator`) | yes (today) | May gain a `-beta` variant in the future |
| ClickHouse MCP (`cbioagent-clickhouse-mcp`) | yes | |
| Images PVC (`cbioagent-librechat-images`) | yes | Both deployments mount the same RWX PVC |
| `librechat-credentials-env` Secret | yes | Contains `MONGO_URI`, `MEILI_HOST`, etc. — all pointing at prod backends |

This is wired up by disabling every sub-chart (`mongodb`, `meilisearch`, `librechat-rag-api`) in [`values.yaml`](./values.yaml) and letting the LibreChat container read connection URIs from the shared Secret.

## Files

| File | Purpose |
|------|---------|
| [`values.yaml`](./values.yaml) | Helm values for the upstream LibreChat chart (`helm/librechat` at `v0.7.9-rc1`). Produces Deployment/Service `cbioagent-librechat-beta`. |
| [`librechat-config.yaml`](./librechat-config.yaml) | `librechat-config-beta` ConfigMap — mounted by the pod at `/app/librechat.yaml`. Contains the `modelSpecs` list (beta agents only), MCP server wiring, and welcome/greeting copy. |
| [`ingress.yaml`](./ingress.yaml) | `cbioagent-beta-ingress` → `beta.chat.cbioportal.org`, backed by the `cbioagent-librechat-beta` Service. |

The corresponding ArgoCD Application is at [`../argocd/cbioagent-beta.yaml`](../argocd/cbioagent-beta.yaml) and mirrors the prod `cbioagent` app's dual-source pattern (raw manifests from this repo + the helm chart from `danny-avila/LibreChat`).

## Updating prompts or agents

Beta agents live in MongoDB like prod agents — see the root project `CLAUDE.md` for how to query/patch them. The `modelSpecs` preset in `librechat-config.yaml` also has copies of the greeting / agent IDs; keep these in sync with MongoDB when changing them.

The default spec points at a handoff router (Haiku) that routes to a data agent (Haiku) or a navigation agent (Sonnet). Those three agent records are managed by [`scripts/cbioagent-beta/setup_handoff_agents.py`](../../../../../../../scripts/cbioagent-beta/README.md).

## Relationship to prod

Keep `values.yaml` in sync with [`../cbioagent/values.yaml`](../cbioagent/values.yaml) for anything that should behave the same way across environments (probes, resources, image tag, etc.). The intentional differences are:

- `fullnameOverride: cbioagent-librechat-beta` (prod has none)
- `replicaCount: 1` (prod: 2)
- `existingConfigYaml: librechat-config-beta` (prod: `librechat-config`)
- `DOMAIN_CLIENT` / `DOMAIN_SERVER` point at `beta.chat.cbioportal.org`
- All sub-charts disabled (prod enables `librechat-rag-api`)
