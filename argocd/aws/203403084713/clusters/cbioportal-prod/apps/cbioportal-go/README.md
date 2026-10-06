# cbioportal-go

> [!WARNING]
> **Experimental.** go.cbioportal.org runs
> [cbioportal-go](https://github.com/cBioPortal/cbioportal-go), an experiment to
> reimplement cBioPortal in Go. It is not an official cBioPortal release and
> not a supported service: results may differ from www.cbioportal.org, and it
> may change, break or be taken down at any time. Every page shows an
> "experimental preview" banner.

Go reimplementation of the cBioPortal backend (REST API + bundled React frontend),
served at https://go.cbioportal.org. Backed by ClickHouse Cloud; an hourly job mirrors
production's data (zero-copy clone of the live `cbioportal_public_<color>`) after each
production import. Studies
can also be loaded by hand with `deploy/publish-local-studies.sh` from the
cbioportal-go repo.

## Components (all in `default` namespace)

| Resource | Purpose |
|---|---|
| `Deployment cbioportal-go` | 2 replicas of `cbioportal/cbioportal-go:latest` on port 8080 (API + frontend from `/app/frontend`), stateless: sessions in the public session service, logins in the public session Redis. Keel rolls it on new `:latest` digests; Reloader rolls it when `cbioportal-go-active` or `clickhouse-go-portal` changes. |
| `Service cbioportal-go` | ClusterIP, port 80 → 8080. |
| `Deployment` / `Service cbioportal-go-api` | API-only, stateless, 2 replicas on the same databases; receives a mirrored share of www's non-browser API traffic. |
| `Deployment` / `Service cbioportal-go-www`, `TraefikService cbioportal-www-mirror-{green,blue}` | The same, for a mirrored share of www's browser API traffic. |
| `PodDisruptionBudget cbioportal-go`, `cbioportal-go-api` | Keep one pod serving through node drains. |
| `Ingress cbioportal-go-ingress` | Traefik + cert-manager TLS (`go-cbioportal-cert`) for go.cbioportal.org, with the `ipblock` and `ratelimit-host` middlewares. |
| `ConfigMap cbioportal-go-active` | Blue/green pointer: `CBIOPORTAL_DB`, `CBIOPORTAL_RAW_DB`, `CBIOPORTAL_REF_DB`. |
| `CronJob cbioportal-go-mirror-daily` | Hourly: when production serves a new import (and none is running), clones it into the inactive color, builds the Go portal's tables, then flips the pointer; otherwise leaves the pointer as is. |
| `ServiceAccount/Role/RoleBinding cbioportal-go-mirror-job*` | Lets the CronJob `get`/`patch` only `cbioportal-go-active`. |
| `Application cbioportal-go` (`apps/argocd/`) | Auto-sync (prune + selfHeal) of this directory. |

Both workloads run on the `workload=cbio-dev` node pool (arm64 spot), alongside the
other dev/preview cBioPortal instances.

## Blue/green pointer

ClickHouse holds two sets of databases, `dev_cbioportal_public_go_{blue,green}` plus
their `_raw` and `_ref` companions. `cbioportal-go-active` names the set being served.

What the three databases of a color hold (the API reads all three: `-db`, `-raw-db`,
`-ref-db`):

| Database | Holds | Built by the mirror job as |
|---|---|---|
| `…_<color>_ref` | Reference data the API joins against: genes, gene aliases, cancer types, reference-genome positions. | A zero-copy `CLONE AS` of every production table (minus auth/credential tables). Production already has the reference tables, and the rest of the clone is the source for the other two databases. |
| `…_<color>_raw` | Per-gene data in the "staging" shape the API reads for a few endpoints (expression, CNA, methylation and generic-assay matrices, profiles, timeline). | Views over production's `genetic_alteration_derived` / `generic_assay_data_derived` and copies of a few small tables — no bulk copy. |
| `…_<color>` | The portal model the API mainly serves: studies, samples, patients, clinical data, mutations, CNA, structural variants, case lists, gene panels, and the study-view `*_derived` tables. | Views over the clone's `*_derived` tables plus tables copied from production's normalized tables (tens of millions of rows at most). |

The names come from cbioportal-go's file importer, where `_raw` holds the staged
study files and `_ref` the reference data loaded from the cBioPortal seed dump; the
mirror fills the same three roles from production instead.

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
README), with the import credentials in the environment:

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
- **Image**: `cbioportal/cbioportal-go:latest` on Docker Hub (multi-arch amd64+arm64, uid
  10001) with the API as entrypoint and the frontend in `/app/frontend`.
- **Argo**: the `argocd` app-of-apps is manual-sync; sync it to create the
  `cbioportal-go` Application.

## Mirrored API traffic

`apps/cbioportal-api/cbioportal-api-mirror.yaml` defines one Traefik mirroring
service per color (`cbioportal-api-mirror-green` / `-blue`). www.cbioportal.org's
non-browser catch-all route uses the one for the live API pool: clients are
served by the Java API pool as before, and `percent` of requests (POST bodies
up to 1 MiB) are also sent to `cbioportal-go-api`, whose responses are
discarded. The import pipeline's color swap renames `-green` <-> `-blue` in that
route like the Java services, so it follows the API pool. To stop mirroring,
point the route back at `cbioportal-backend-public-api-<color>`, then delete
the mirror file.

## Metrics and logs

Both deployments serve Prometheus metrics on port 9090 (`METRICS_ADDR`, not
exposed by the Services), scraped by Datadog's OpenMetrics check through the
pod annotation (namespace `cbioportal_go`), and write a JSON access log line
per request (`ACCESS_LOG`). Their ClickHouse queries carry `log_comment`
(`go.cbioportal.org`, `cbioportal-go-api`) in `system.query_log`.
