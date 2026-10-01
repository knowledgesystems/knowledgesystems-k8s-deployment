# cbioagent-beta

> **Hard prerequisite:** don't merge or sync the beta ClickHouse MCP / clone job until `docker manifest inspect cbioportal/mcp:beta` succeeds. The tag is published by cbioportal-mcp#158; until then the MCP pod and the clone's `fetch-sql` step can't pull.

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
| [`cbioagent-clickhouse-clone-daily-beta.yaml`](./cbioagent-clickhouse-clone-daily-beta.yaml) | CronJob `cbioagent-clickhouse-clone-daily-beta` (16:00 UTC, three hours after prod's), the `clickhouse-mcp-active-beta` pointer ConfigMap, and its own ServiceAccount/Role/RoleBinding (can patch only the beta pointer). Clones the production color into the idle `cbioportal_public_librechat_beta_*` buffer, checks each cloned table's row count against the source, applies the SQL from `cbioportal/mcp:beta` (portable → portal-specific → final; final is skipped when the image has no `sql/final/`), then flips the pointer. Aborts before touching ClickHouse if any shipped SQL file fails to parse with `clickhouse format`, or uses database-level DDL, `USE`, cross-database `EXCHANGE`/`RENAME`, inline `INSERT` data, or names a prod database. |

The corresponding ArgoCD Application is at [`../argocd/cbioagent-beta.yaml`](../argocd/cbioagent-beta.yaml) and mirrors the prod `cbioagent` app's dual-source pattern (raw manifests from this repo + the helm chart from `danny-avila/LibreChat`).

## ClickHouse MCP (beta)

`cbioportal/cbioportal-mcp` PRs merged to its `beta` branch publish `cbioportal/mcp:beta`. Both the beta MCP pod and the beta clone's `fetch-sql` step use that tag, so schema/SQL changes and server changes land in beta's buffers and beta's MCP, not prod's (`:latest`, `cbioportal_public_librechat_{blue,green}`).

This isolation has limits. The clone runs the image's SQL with the same ClickHouse admin credentials prod's clone uses, scoped only by `--database`. The clone job's preflight runs each file through `clickhouse format --multiquery --oneline` (ClickHouse's own parser, from the job's image). A file the parser rejects aborts the job. The denylist then runs over the raw text and the formatted queries, and catches the obvious ways out:
- `DROP`/`RENAME`/`ATTACH`/`DETACH` `DATABASE`;
- `USE`;
- db-qualified `EXCHANGE`/`RENAME TABLE`;
- `INSERT … VALUES`/`FORMAT` inline data, which the formatter doesn't parse (use `INSERT … SELECT`);
- any `cbioportal_public_librechat_{blue,green}` or `cbioportal_public_{blue,green}` name.

It's still a denylist, not a sandbox. It doesn't catch, for example, a cross-database `INSERT INTO other.t SELECT …` or `ALTER … MOVE PARTITION … TO TABLE other.t` unless a prod name appears literally.

One quirk: a file whose last chunk is only a `#` or `/* */` comment fails to format ("Empty query") and aborts the job. End files with a statement or a `--` comment. Review SQL changes on the `beta` branch as if they could reach prod. Both clones also share the ClickHouse server's CPU and memory.

### ClickHouse admin prerequisite (one-time)

`llm_user` grants are keyed by database name. They survive the clone's `DROP DATABASE` + `CREATE DATABASE`, but prod's grants on `cbioportal_public_librechat_{blue,green}` do **not** cover the beta names. A ClickHouse admin must run, once (grants can be issued before the databases exist):

```sql
GRANT SELECT ON cbioportal_public_librechat_beta_blue.*  TO llm_user;
GRANT SELECT ON cbioportal_public_librechat_beta_green.* TO llm_user;
-- Needed once the dictionaries from cbioportal-mcp#155 ship in :beta
GRANT dictGet ON cbioportal_public_librechat_beta_blue.*  TO llm_user;
GRANT dictGet ON cbioportal_public_librechat_beta_green.* TO llm_user;
```

Mirror whatever else prod's `llm_user` holds on the prod buffers (`SHOW GRANTS FOR llm_user`).

### Query cache (off by default)

The clone job's `DROP_QUERY_CACHE` env var is `"false"`. Set it to `"true"` only while piloting `CBIOPORTAL_MCP_QUERY_CACHE_ENABLED` on the beta MCP: the swap doesn't invalidate cached results, so the job then runs `SYSTEM DROP QUERY CACHE` before the flip. That cache is server-wide, so the drop also empties prod's cache (prod gets cold-cache latency, not wrong results). The admin user needs the `SYSTEM DROP QUERY CACHE` privilege; without it the job logs a WARN and continues.

### Rollout order

1. Confirm `docker manifest inspect cbioportal/mcp:beta` succeeds (built by cbioportal-mcp#158). This gates both the merge and the sync. Until it does, both the MCP pod and the clone's `fetch-sql` step fail to pull.
2. Apply the grants above.
3. Manually sync the `cbioagent-beta` Argo Application the first time **without prune**, with someone watching the sync. Check the diff first: it should only add the beta MCP, the clone job objects and the pointer ConfigMap, and modify `librechat-config-beta`. The beta MCP starts pointing at the seed `cbioportal_public_librechat_beta_blue`, which doesn't exist yet, so beta database queries fail until step 4 publishes a buffer. That's expected.
4. Build the first buffer once instead of waiting for the schedule:
   ```sh
   kubectl -n default create job --from=cronjob/cbioagent-clickhouse-clone-daily-beta clone-beta-manual-$(date +%s)
   kubectl -n default logs -f job/<that job> --all-containers
   ```
   The job always builds the color the pointer does *not* name, so the first run builds `cbioportal_public_librechat_beta_green` (the log says `does not exist yet (first run)`). It patches the pointer only after the whole build succeeds; a failed run leaves the pointer and the live buffer untouched.

   Until the second run also builds `beta_blue`, an Argo sync that resets the pointer to its seed would point the MCP at a missing database. Re-run the job to recover.
5. Verify the pointer and the MCP:
   ```sh
   kubectl -n default get configmap clickhouse-mcp-active-beta -o jsonpath='{.data.CLICKHOUSE_DATABASE}'
   kubectl -n default rollout status deploy/cbioagent-clickhouse-mcp-beta
   ```
   Then ask a database question on beta.chat.cbioportal.org.
6. Only then merge the beta LibreChat PRs (#654, #655, #653). They all edit `librechat-config.yaml`, so merge and sync them one at a time.

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
- `librechat-config.yaml` points `cbioportal-database` at `cbioagent-clickhouse-mcp-beta` (prod: `cbioagent-clickhouse-mcp`)
