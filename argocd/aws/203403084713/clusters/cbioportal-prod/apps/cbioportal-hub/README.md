# cbioportal-hub

https://hub.cbioportal.org previews the studies of `cBioPortal/datahub` pull
requests labelled `preview`. It runs
[cbioportal-go](https://github.com/cBioPortal/cbioportal-go) on the ClickHouse
Cloud service of go.cbioportal.org.

## Components (all in `default` namespace)

| Resource | Purpose |
|---|---|
| `Deployment` / `Service cbioportal-go-hub` | 2 replicas of `cbioportal/cbioportal-go:latest` (API + frontend), no login. Sessions in each pod's memory, so the Service has a sticky cookie; they are lost on restart. Keel rolls it on new `:latest` digests. |
| `PodDisruptionBudget cbioportal-go-hub` | Keeps one pod serving through node drains. |
| `Ingress cbioportal-hub-ingress` | Traefik + cert-manager TLS for hub.cbioportal.org. |
| `ApplicationSet datahub-pr-import-set` (`apps/argocd/`) | One `datahub-import-<PR#>` Application per `preview`-labelled PR, rendering `import-job-helm/` into a Job per PR commit. |

## Databases

| Database | Holds |
|---|---|
| `dev_cbioportal_hub_go` | The portal tables the API serves. |
| `dev_cbioportal_hub_go_raw` | The staged study files of every imported study, the shared gene panels, the import lock and the import log. |
| `dev_cbioportal_hub_go_ref` | Genes, aliases, cancer types from datahub's seed dump. |

The Deployment reads them as the user of the `clickhouse-go-portal` Secret,
the import Jobs write them as `go_import` (`clickhouse-go-import`), which
needs SELECT, INSERT, ALTER, CREATE TABLE, CREATE VIEW, DROP TABLE, DROP VIEW
and TRUNCATE on the three databases.

## Per-PR import

The Job runs `/app/deploy/hub-import.sh` from the cbioportal-go image (source:
[ops/cbioportal.org/hub-import.sh](https://github.com/cBioPortal/cbioportal-go/blob/main/ops/cbioportal.org/hub-import.sh)):

1. Lists the PR's changed studies (`public/<study>`, `crdc/gdc/<study>`) and
   reference gene panels; stops if this commit was imported completely already (Argo
   recreates finished Jobs after their 24 h TTL).
2. Posts an in-progress Check Run and Deployment on the PR.
3. Sparse, blobless checkout of `pull/<PR>/head`; a Job whose commit is no
   longer the PR head stops ("superseded").
4. Takes the hub import lock (a table in the raw database): one import at a
   time; a lock without a heartbeat for 10 minutes is taken over; waits up
   to 2 h.
5. Loads the reference data and the shared gene panels when the hub has
   none, and reloads the gene panels when the PR changes them.
6. Per study: downloads its LFS files (datahub's LFS store, else the PR
   head repository's GitHub LFS) and runs `cbioportal-import ingest`, which
   replaces the study's earlier rows. A study that fails is removed from the
   hub.
7. One `cbioportal-import transform`. It builds every table under a staging
   name and publishes them all at the end, so a failed transform leaves the
   hub as it was; the PR's studies are then removed and the hub rebuilt
   without them.
8. Completes the Check Run (success, neutral when partial, failure) and the
   Deployment status, with links to the imported studies.

While a study is being ingested (minutes), its pages may show it half
loaded: some study-level objects read the raw database directly.

### `hub-import-only:` (restrict to a subset)

For large multi-study PRs add to the PR body:

```markdown
## Preview Configuration

hub-import-only:
- public/acc_tcga_pan_can_atlas_2018
- public/brca_tcga_pan_can_atlas_2018
```

The list is intersected with the PR's changed studies. Paths are as on disk
(`public/<study>`, `crdc/gdc/<study>`). Validation is skipped: datahub's own
CI runs the validators.

### Removing a study

Closing a PR leaves its studies on the hub. To remove one, from a pod with
the cbioportal-go image and `envFrom: clickhouse-go-import`:

```bash
cbioportal-import remove-study <study_id> --db dev_cbioportal_hub_go_raw
cbioportal-import transform --raw-db dev_cbioportal_hub_go_raw \
  --db dev_cbioportal_hub_go --ref-db dev_cbioportal_hub_go_ref
```

TODO: remove a PR's studies automatically when it closes.

## GitHub status integration (`hub-preview-bot`)

The Job mints an installation token of the GitHub App "cBioPortal Datahub
Preview" from the `hub-preview-bot` Secret (portal-configuration,
`argocd/aws/203403084713/clusters/cbioportal-prod/secrets/cbioportal-hub/hub-preview-bot.yaml`;
keys `client-id`, `installation-id`, `private-key`). The Secret is optional:
without it the import runs and posts nothing.

To rotate the key: generate a new private key at
https://github.com/organizations/cBioPortal/settings/apps/cbioportal-datahub-preview,
delete the old one, update `private-key:` in the portal-configuration secret
and push; the next Job uses it.
