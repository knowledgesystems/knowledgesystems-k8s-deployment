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
| ClickHouse MCP Secret (`clickhouse-mcp-beta`) | **no** | Beta MCP uses its own `llm_user_beta` credentials; prod keeps `clickhouse-mcp` and `llm_user` |
| ClickHouse clone admin Secret (`clickhouse-librechat-admin`) | yes | Beta clone still uses the shared admin credentials for DDL and copying data |
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

### ClickHouse admin and Secret prerequisites (one-time)

A ClickHouse admin must create a dedicated beta user and grant only `SELECT` on both beta buffers. These grants are keyed by database name, so they survive the clone's `DROP DATABASE` + `CREATE DATABASE` and may be issued before the databases exist. Use a new password kept outside this repository:

```sql
CREATE USER llm_user_beta IDENTIFIED BY '<new-beta-password>' SETTINGS readonly = 1, optimize_use_implicit_projections = 0 CONST;
GRANT SELECT ON cbioportal_public_librechat_beta_blue.* TO llm_user_beta;
GRANT SELECT ON cbioportal_public_librechat_beta_green.* TO llm_user_beta;
```

`optimize_use_implicit_projections = 0 CONST` changes no results today: the beta buffers have no projections since cbioportal-mcp#169 reverted #156. It is set up front so that #156 can be re-tested on beta without recreating the user. With projections present, ClickHouse's implicit-projection shortcut can overcount plain `count()` queries, and #156's startup check refuses to run unless this setting is locked on the MCP user. `CONST` stops queries from turning it back on. Prod's `llm_user` already has the same setting.

Create the beta MCP Secret out of band in the `default` namespace (the beta pointer ConfigMap and clone job explicitly use `namespace: default`). First inspect **key names only** in prod's Secret; this does not print their values:

```sh
kubectl get secret clickhouse-mcp -n default -o json | jq '.data | keys'
```

Copy every prod key, including `DD_API_KEY` for Datadog LLM Observability, except `CLICKHOUSE_USER`, `CLICKHOUSE_PASSWORD`, and `CLICKHOUSE_DATABASE` if present. Replace the first two with the dedicated beta credentials; the beta pointer ConfigMap supplies the database. This example prompts without echoing the password, keeps it out of shell history, and pipes Secret data directly to `kubectl apply` without displaying it:

```sh
printf 'New beta ClickHouse password: ' >&2
IFS= read -rs BETA_CLICKHOUSE_PASSWORD
printf '\n' >&2
export BETA_CLICKHOUSE_PASSWORD
kubectl get secret clickhouse-mcp -n default -o json |
  jq '{apiVersion: "v1", kind: "Secret",
       metadata: {name: "clickhouse-mcp-beta", namespace: "default"},
       type: .type,
       data: (.data |
         .CLICKHOUSE_USER = ("llm_user_beta" | @base64) |
         .CLICKHOUSE_PASSWORD = (env.BETA_CLICKHOUSE_PASSWORD | @base64) |
         del(.CLICKHOUSE_DATABASE))}' |
  kubectl apply -f -
unset BETA_CLICKHOUSE_PASSWORD
```

As a manual fallback, create the Secret with `kubectl create secret generic` after reviewing the prod key list. The placeholders below are not credentials; include any additional keys present in prod's Secret. Supplying real values as shell literals may put them in shell history, so prefer the piped command above:

```sh
kubectl create secret generic clickhouse-mcp-beta -n default \
  --from-literal=CLICKHOUSE_HOST='<clickhouse-host>' \
  --from-literal=CLICKHOUSE_PORT='<clickhouse-http-port>' \
  --from-literal=CLICKHOUSE_USER='llm_user_beta' \
  --from-literal=CLICKHOUSE_PASSWORD='<new-beta-password>' \
  --from-literal=DD_API_KEY='<prod-dd-api-key>' \
  --from-literal=CLICKHOUSE_SECURE='<true-or-false>' \
  --from-literal=CLICKHOUSE_VERIFY='<true-or-false>' \
  --from-literal=CLICKHOUSE_MCP_SERVER_TRANSPORT='http' \
  --from-literal=CLICKHOUSE_MCP_BIND_HOST='0.0.0.0' \
  --from-literal=CLICKHOUSE_MCP_BIND_PORT='8000'
```

The manual example covers the ClickHouse connection and HTTP listener variables from [mcp-clickhouse 0.5.0](https://github.com/ClickHouse/mcp-clickhouse/blob/v0.5.0/README.md#clickhouse-database-connection) and the [cbioportal-mcp environment example](https://github.com/cBioPortal/cbioportal-mcp#configuration), plus `DD_API_KEY`. It is not an exhaustive key list: preserve any prod tuning keys such as `CLICKHOUSE_MCP_QUERY_TIMEOUT`, `CLICKHOUSE_SEND_RECEIVE_TIMEOUT`, `CLICKHOUSE_CONNECT_TIMEOUT`, `CBIOPORTAL_MCP_MAX_CONCURRENT_QUERIES`, and `CLICKHOUSE_MCP_MAX_WORKERS`. Keep the last two concurrency settings consistent or the server exits at startup. `CLICKHOUSE_MCP_HTTP_PATH` is set directly in the beta Deployment. `CLICKHOUSE_DATABASE` comes from `clickhouse-mcp-active-beta`, loaded after this Secret. The database port above is the HTTP port, not the native TCP port used by `clickhouse client`.

Verify the beta user's effective grants by logging in as that user (the client prompts for its password):

```sh
clickhouse client --host <clickhouse-host> --port <native-tcp-port> --secure --user llm_user_beta --password -q 'SHOW GRANTS'
```

Use the native port and TLS flag appropriate for the ClickHouse client connection. The output should contain `SELECT` on only `cbioportal_public_librechat_beta_blue.*` and `cbioportal_public_librechat_beta_green.*`, with no prod database grants. Navigator MCP and LibreChat beta connect to MCP Services and do not consume `clickhouse-mcp`; the beta clone consumes `clickhouse-librechat-admin` for DDL, so none of these switch Secrets.

### Query cache (off by default)

The clone job's `DROP_QUERY_CACHE` env var is `"false"`. Set it to `"true"` only while piloting `CBIOPORTAL_MCP_QUERY_CACHE_ENABLED` on the beta MCP. The default `readonly = 1` user setting makes that pilot disable itself; a pilot also needs `readonly = 2` on `llm_user_beta` (or suitable `CHANGEABLE_IN_READONLY` constraints). Keep `readonly = 1` for normal operation. The swap doesn't invalidate cached results, so the job then runs `SYSTEM DROP QUERY CACHE` before the flip. That cache is server-wide, so the drop also empties prod's cache (prod gets cold-cache latency, not wrong results). The admin user needs the `SYSTEM DROP QUERY CACHE` privilege; without it the job logs a WARN and continues.

### Rollout order

1. Confirm `docker manifest inspect cbioportal/mcp:beta` succeeds (built by cbioportal-mcp#158). This gates both the merge and the sync. Until it does, both the MCP pod and the clone's `fetch-sql` step fail to pull.
2. Create `llm_user_beta` with the two beta `SELECT` grants, create `clickhouse-mcp-beta` in `default`, and verify its grants as above **before syncing**. Without the Secret, the beta MCP pod fails to start.
3. Manually sync the `cbioagent-beta` Argo Application the first time **without prune**, with someone watching the sync. Check the diff first: it should only add the beta MCP, the clone job objects and the pointer ConfigMap, and modify `librechat-config-beta`. The beta MCP starts pointing at the seed `cbioportal_public_librechat_beta_blue`, which doesn't exist yet. Its startup `CHECK GRANT` may crash-loop until step 4 builds a buffer and flips the pointer; that's expected.
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
