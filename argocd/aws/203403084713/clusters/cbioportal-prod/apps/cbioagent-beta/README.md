# cbioagent-beta

Beta LibreChat instance at **https://beta.chat.cbioportal.org**, used to test new agent variants (e.g. `cBioDBAgentBeta`, `cBioNavigatorBeta`) and LibreChat changes before promoting to prod.

## Shared backend

Beta is a second LibreChat frontend plus its **own ClickHouse MCP and ClickHouse data buffers**. Everything else is reused from prod:

| Backend | Shared | Notes |
|---------|--------|-------|
| MongoDB (`cbioagent-mongodb`) | yes | Same `cBioAgent` database — all agents, conversations, and users are visible in both instances |
| meilisearch (`cbioagent-meilisearch`) | yes | Only if configured via `librechat-credentials-env` |
| RAG API (`cbioagent-librechat-rag-api`) | yes | Same |
| Navigator MCP (`cbioportal-navigator`) | yes (today) | May gain a `-beta` variant in the future |
| ClickHouse MCP (`cbioagent-clickhouse-mcp`) | **no** | Beta runs `cbioagent-clickhouse-mcp-beta` (`cbioportal/mcp:beta`) — see below |
| ClickHouse buffers (`cbioportal_public_librechat_{blue,green}`) | **no** | Beta reads `cbioportal_public_librechat_beta_{blue,green}`, built by its own clone cron. Both clones read the same production source DB. |
| ClickHouse Secrets (`clickhouse-mcp`, `clickhouse-librechat-admin`) | yes | Same `llm_user` / admin credentials |
| Images PVC (`cbioagent-librechat-images`) | yes | Both deployments mount the same RWX PVC |
| `librechat-credentials-env` Secret | yes | Contains `MONGO_URI`, `MEILI_HOST`, etc. — all pointing at prod backends |

This is wired up by disabling every sub-chart (`mongodb`, `meilisearch`, `librechat-rag-api`) in [`values.yaml`](./values.yaml) and letting the LibreChat container read connection URIs from the shared Secret.

## Files

| File | Purpose |
|------|---------|
| [`values.yaml`](./values.yaml) | Helm values for the upstream LibreChat chart (`helm/librechat` at `v0.7.9-rc1`). Produces Deployment/Service `cbioagent-librechat-beta`. |
| [`librechat-config.yaml`](./librechat-config.yaml) | `librechat-config-beta` ConfigMap — mounted by the pod at `/app/librechat.yaml`. Contains the `modelSpecs` list (beta agents only), MCP server wiring, and welcome/greeting copy. |
| [`ingress.yaml`](./ingress.yaml) | `cbioagent-beta-ingress` → `beta.chat.cbioportal.org`, backed by the `cbioagent-librechat-beta` Service. |
| [`cbioagent-clickhouse-mcp-beta.yaml`](./cbioagent-clickhouse-mcp-beta.yaml) | Deployment/Service `cbioagent-clickhouse-mcp-beta` (in-cluster only). Image `cbioportal/mcp:beta`, rolled by Keel on new digests and by Reloader when `clickhouse-mcp-active-beta` changes. Datadog service / LLM Obs app `cbioportal-mcp-beta`. |
| [`cbioagent-clickhouse-clone-daily-beta.yaml`](./cbioagent-clickhouse-clone-daily-beta.yaml) | CronJob `cbioagent-clickhouse-clone-daily-beta` (15:00 UTC, two hours after prod's), the `clickhouse-mcp-active-beta` pointer ConfigMap, and its own ServiceAccount/Role/RoleBinding (can patch only the beta pointer). Clones the production color into the idle `cbioportal_public_librechat_beta_*` buffer, applies the SQL from `cbioportal/mcp:beta` (portable → portal-specific → final), drops the query cache, then flips the pointer. |

The corresponding ArgoCD Application is at [`../argocd/cbioagent-beta.yaml`](../argocd/cbioagent-beta.yaml) and mirrors the prod `cbioagent` app's dual-source pattern (raw manifests from this repo + the helm chart from `danny-avila/LibreChat`).

## ClickHouse MCP (beta)

`cbioportal/cbioportal-mcp` PRs merged to its `beta` branch publish `cbioportal/mcp:beta`. Both the beta MCP pod and the beta clone's `fetch-sql` step use that tag, so schema/SQL changes and server changes land in beta's buffers and beta's MCP only; prod (`:latest`, `cbioportal_public_librechat_{blue,green}`) is untouched.

### ClickHouse admin prerequisite (one-time)

`llm_user` grants are keyed by database name. They survive the clone's `DROP DATABASE` + `CREATE DATABASE`, but prod's grants on `cbioportal_public_librechat_{blue,green}` do **not** cover the beta names. A ClickHouse admin must run, once (grants can be issued before the databases exist):

```sql
GRANT SELECT ON cbioportal_public_librechat_beta_blue.*  TO llm_user;
GRANT SELECT ON cbioportal_public_librechat_beta_green.* TO llm_user;
-- Needed once the dictionaries from cbioportal-mcp#155 ship in :beta
GRANT dictGet ON cbioportal_public_librechat_beta_blue.*  TO llm_user;
GRANT dictGet ON cbioportal_public_librechat_beta_green.* TO llm_user;
```

Mirror whatever else prod's `llm_user` holds on the prod buffers (`SHOW GRANTS FOR llm_user`). The admin user also needs `SYSTEM DROP QUERY CACHE`; without it the clone logs a WARN and continues. The query cache is server-wide, so the beta drop also empties prod's cache (cold cache, never stale results).

### Rollout order

1. Make sure `cbioportal/mcp:beta` exists on Docker Hub (the MCP repo's `beta` branch has been built at least once). Until it does, both the MCP pod and the clone's `fetch-sql` step fail to pull.
2. Apply the grants above.
3. Manually sync the `cbioagent-beta` Argo Application. The beta MCP starts pointing at `cbioportal_public_librechat_beta_blue`, which doesn't exist yet, so beta database queries fail until step 4 finishes.
4. Build the first buffer once instead of waiting for the schedule:
   ```sh
   kubectl -n default create job --from=cronjob/cbioagent-clickhouse-clone-daily-beta clone-beta-manual-$(date +%s)
   kubectl -n default logs -f job/<that job> --all-containers
   ```
   The first run sees the seed buffer doesn't exist and builds into it (`bootstrapping into it` in the log).
5. Verify the pointer and the MCP:
   ```sh
   kubectl -n default get configmap clickhouse-mcp-active-beta -o jsonpath='{.data.CLICKHOUSE_DATABASE}'
   kubectl -n default rollout status deploy/cbioagent-clickhouse-mcp-beta
   ```
   Then ask a database question on beta.chat.cbioportal.org.
6. Only then merge the beta LibreChat PRs (#654, #655, #653). They all edit `librechat-config.yaml`, so merge and sync them one at a time.

## Updating prompts or agents

Beta agents live in MongoDB like prod agents — see the root project `CLAUDE.md` for how to query/patch them. The `modelSpecs` preset in `librechat-config.yaml` also has copies of the greeting / agent IDs; keep these in sync with MongoDB when changing them.

## Relationship to prod

Keep `values.yaml` in sync with [`../cbioagent/values.yaml`](../cbioagent/values.yaml) for anything that should behave the same way across environments (probes, resources, image tag, etc.). The intentional differences are:

- `fullnameOverride: cbioagent-librechat-beta` (prod has none)
- `replicaCount: 1` (prod: 2)
- `existingConfigYaml: librechat-config-beta` (prod: `librechat-config`)
- `DOMAIN_CLIENT` / `DOMAIN_SERVER` point at `beta.chat.cbioportal.org`
- All sub-charts disabled (prod enables `librechat-rag-api`)
- `librechat-config.yaml` points `cbioportal-database` at `cbioagent-clickhouse-mcp-beta` (prod: `cbioagent-clickhouse-mcp`)
