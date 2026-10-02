# cbioportal-go

Go reimplementation of the cBioPortal backend (REST API + bundled React frontend),
served at https://go.cbioportal.org. Backed by ClickHouse; data is imported daily
from `cBioPortal/datahub`.

## Components (all in `default` namespace)

| Resource | Purpose |
|---|---|
| `Deployment cbioportal-go` | Single replica of `inodb/cbioportal-go:latest` on port 8080 (API + frontend from `/app/frontend`). Keel rolls it on new `:latest` digests; Reloader rolls it when `cbioportal-go-active` or `clickhouse-go-portal` changes. |
| `PVC cbioportal-go-data` | 1Gi `efs-sc` volume at `/data` holding the session store (`/data/sessions.json`). |
| `Service cbioportal-go` | ClusterIP, port 80 → 8080. |
| `Ingress cbioportal-go-ingress` | Traefik + cert-manager TLS (`go-cbioportal-cert`) for go.cbioportal.org, with the `ipblock` and `ratelimit-host` middlewares. |
| `ConfigMap cbioportal-go-active` | Blue/green pointer: `CBIOPORTAL_DB`, `CBIOPORTAL_RAW_DB`, `CBIOPORTAL_REF_DB`. |
| `CronJob cbioportal-go-import-daily` | Daily 06:00 UTC datahub import into the inactive color, then flips the pointer. |
| `ServiceAccount/Role/RoleBinding cbioportal-go-import-job*` | Lets the CronJob `get`/`patch` only `cbioportal-go-active`. |
| `Application cbioportal-go` (`apps/argocd/`) | Auto-sync (prune + selfHeal) of this directory. |

Both workloads run on the `workload=cbio-dev` node pool (arm64 spot), alongside the
other dev/preview cBioPortal instances.

## Blue/green pointer

ClickHouse holds two sets of databases, `dev_cbioportal_public_go_{blue,green}` plus
their `_raw` and `_ref` companions. `cbioportal-go-active` names the set being served.

1. The CronJob's `import` initContainer reads the live `CBIOPORTAL_DB` (as `ACTIVE_DB`),
   rebuilds the *other* color from datahub, and writes the new values to
   `/work/state.env`.
2. The `patch-pointer` container merges those three keys into `cbioportal-go-active`.
3. Reloader sees the ConfigMap change and restarts `cbioportal-go` on the new databases.

A failed import never reaches step 2, so the site keeps serving the previous color.

The ConfigMap in git is only the initial seed. The Argo Application lists the three keys
under `ignoreDifferences` with `RespectIgnoreDifferences=true` + `ServerSideApply=true`,
so syncs and selfHeal keep the CronJob's values. To point the site at a color by hand,
`kubectl patch` the ConfigMap; editing the seed in git has no effect on a live cluster.

## Trigger an import manually

```bash
kubectl -n default create job --from=cronjob/cbioportal-go-import-daily \
  cbioportal-go-import-manual-$(date +%s)
kubectl -n default logs -f job/<job-name> -c import
```

## Out-of-repo prerequisites

- **Secrets** (`portal-configuration`, branch `go-cbioportal-org`, under
  `secrets/cbioportal-go/`): `clickhouse-go-portal` (read-only user for the API) and
  `clickhouse-go-import` (user that can create/drop the `dev_cbioportal_public_go_*`
  databases), each with `CLICKHOUSE_URL`, `CLICKHOUSE_USER`, `CLICKHOUSE_PASSWORD`.
  Merge that branch so the `portal-configuration` Application syncs them.
- **ClickHouse** databases and users for the `dev_cbioportal_public_go_*` prefix.
- **DNS**: a `go.cbioportal.org` record pointing at the Traefik load balancer (same
  target as the other `*.cbioportal.org` hosts). cert-manager issues the certificate
  over HTTP-01 once the record resolves.
- **Image**: `inodb/cbioportal-go:latest` on Docker Hub (multi-arch amd64+arm64, uid
  10001), containing `/app/frontend`, `/app/deploy/import-datahub.sh` and
  `/app/deploy/datahub-studies.txt`.
- **Argo**: the `argocd` app-of-apps is manual-sync; sync it to create the
  `cbioportal-go` Application.
