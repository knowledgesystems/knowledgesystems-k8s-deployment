# cbioportal-go

> [!WARNING]
> **Experimental.** go.cbioportal.org runs
> [cbioportal-go](https://github.com/cBioPortal/cbioportal-go), an experiment to
> reimplement cBioPortal in Go. It is not an official cBioPortal release and
> not a supported service: results may differ from www.cbioportal.org, and it
> may change, break or be taken down at any time. Every page shows an
> "experimental preview" banner.

Go reimplementation of the cBioPortal backend (REST API + bundled React frontend),
served at https://go.cbioportal.org. Backed by ClickHouse Cloud; a daily job mirrors
production's data (zero-copy clone of the live `cbioportal_public_<color>`). Studies
can also be loaded by hand with `deploy/publish-local-studies.sh` from the
cbioportal-go repo.

## Components (all in `default` namespace)

| Resource | Purpose |
|---|---|
| `Deployment cbioportal-go` | Single replica of `inodb/cbioportal-go:latest` on port 8080 (API + frontend from `/app/frontend`). Keel rolls it on new `:latest` digests; Reloader rolls it when `cbioportal-go-active` or `clickhouse-go-portal` changes. |
| `PVC cbioportal-go-data` | 1Gi `efs-sc` volume at `/data` holding the session store (`/data/sessions.json`). |
| `Service cbioportal-go` | ClusterIP, port 80 → 8080. |
| `Ingress cbioportal-go-ingress` | Traefik + cert-manager TLS (`go-cbioportal-cert`) for go.cbioportal.org, with the `ipblock` and `ratelimit-host` middlewares. |
| `ConfigMap cbioportal-go-active` | Blue/green pointer: `CBIOPORTAL_DB`, `CBIOPORTAL_RAW_DB`, `CBIOPORTAL_REF_DB`. |
| `CronJob cbioportal-go-mirror-daily` | Daily 14:00 UTC: clones the live production color into the inactive color, builds the Go portal's tables, then flips the pointer. |
| `ServiceAccount/Role/RoleBinding cbioportal-go-mirror-job*` | Lets the CronJob `get`/`patch` only `cbioportal-go-active`. |
| `Application cbioportal-go` (`apps/argocd/`) | Auto-sync (prune + selfHeal) of this directory. |

Both workloads run on the `workload=cbio-dev` node pool (arm64 spot), alongside the
other dev/preview cBioPortal instances.

## Blue/green pointer

ClickHouse holds two sets of databases, `dev_cbioportal_public_go_{blue,green}` plus
their `_raw` and `_ref` companions. `cbioportal-go-active` names the set being served.

The mirror CronJob rebuilds the inactive color every day and switches the site to it
when the build succeeds; a failed run leaves the site on the previous color. To switch
by hand (e.g. after loading studies into the inactive color, see below):

```bash
kubectl -n default patch configmap cbioportal-go-active --type=merge -p \
  '{"data":{"CBIOPORTAL_DB":"dev_cbioportal_public_go_green","CBIOPORTAL_RAW_DB":"dev_cbioportal_public_go_green_raw","CBIOPORTAL_REF_DB":"dev_cbioportal_public_go_green_ref"}}'
```

Reloader sees the ConfigMap change and restarts `cbioportal-go` on the new databases.

The ConfigMap in git is only the initial seed. The Argo Application lists the three keys
under `ignoreDifferences` with `RespectIgnoreDifferences=true` + `ServerSideApply=true`,
so syncs and selfHeal keep the patched values; editing the seed in git has no effect on
a live cluster.

## Loading studies

From a machine with the studies staged in a local ClickHouse (see the cbioportal-go
README), with the `go_import` credentials in the environment:

```bash
deploy/publish-local-studies.sh dev_cbioportal_public_go_blue \
  seed-cbioportal_hg19_hg38_v2.14.5.sql.gz msk_impact_2017 acbc_mskcc_2015
```

## Out-of-repo prerequisites

- **Secrets** (`portal-configuration`, branch `go-cbioportal-org`, under
  `secrets/cbioportal-go/`): `clickhouse-go-portal` (read-only user for the API) and
  `clickhouse-go-import` (user of the mirror CronJob: reads the live production color, writes the
  `dev_cbioportal_public_go_*` databases), each with `CLICKHOUSE_URL`, `CLICKHOUSE_USER`, `CLICKHOUSE_PASSWORD`.
  Merge that branch so the `portal-configuration` Application syncs them.
- **ClickHouse** databases and users for the `dev_cbioportal_public_go_*` prefix.
- **DNS**: a `go.cbioportal.org` record pointing at the Traefik load balancer (same
  target as the other `*.cbioportal.org` hosts). cert-manager issues the certificate
  over HTTP-01 once the record resolves.
- **Image**: `inodb/cbioportal-go:latest` on Docker Hub (multi-arch amd64+arm64, uid
  10001) with the API as entrypoint and the frontend in `/app/frontend`.
- **Argo**: the `argocd` app-of-apps is manual-sync; sync it to create the
  `cbioportal-go` Application.
