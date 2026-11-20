# cbioportal-hub

https://hub.cbioportal.org shows every study on `cBioPortal/datahub`'s
`master` branch, kept up to date within minutes of each merge. Each datahub
pull request labelled `preview` gets a preview of its own at
`https://datahub-pr-<N>.gopreview.cbioportal.org`. Both run
[cbioportal-go](https://github.com/cBioPortal/cbioportal-go) on the
ClickHouse Cloud service of go.cbioportal.org. The full description is in
cbioportal-go's
[docs/deployment.md](https://github.com/cBioPortal/cbioportal-go/blob/main/docs/deployment.md#hubcbioportalorg).

## Components (all in `default` namespace)

| Resource | Purpose |
|---|---|
| `Deployment` / `Service cbioportal-go-hub` | 2 replicas of `cbioportal/cbioportal-go:latest` (API + frontend), no login. Sessions in each pod's memory, so the Service has a sticky cookie; they are lost on restart. Keel rolls it on new `:latest` digests. |
| `PodDisruptionBudget cbioportal-go-hub` | Keeps one pod serving through node drains. |
| `Ingress cbioportal-hub-ingress` | Traefik + cert-manager TLS for hub.cbioportal.org. |
| `CronJob cbioportal-hub-master-sync` | Every minute, `cbioportal-ops hub sync-master`: imports what changed on datahub's `master` since the last imported commit (see below). |
| `CronJob cbioportal-hub-preview-gc` | Daily, `cbioportal-ops hub gc`: drops the databases of PR previews whose PR is closed or unlabelled. |
| `ApplicationSet datahub-pr-import-set` (`apps/argocd/`) | One `datahub-import-<PR#>` Application per `preview`-labelled PR, rendering `import-job-helm/`: the preview's API (`Deployment`, `Service`, `Ingress datahub-pr-<N>`), an import Job per PR commit, and a PostDelete hook that drops the preview's databases. |

## Databases

| Database | Holds |
|---|---|
| `dev_cbioportal_hub_go` | The hub's portal tables the API serves. |
| `dev_cbioportal_hub_go_raw` | The staged study files of every study on `master`, the shared gene panels, the import lock and the master sync log (`_hub_master_sync`). |
| `dev_cbioportal_hub_go_ref` | Genes, aliases, cancer types from datahub's seed dump. |
| `dev_cbioportal_go_prdatahub<N>`, `_raw`, `_ref` | The preview of datahub PR N, built and dropped by its own jobs. |

The hub Deployment reads the hub's databases as the user of the
`clickhouse-go-portal` Secret. The jobs and the PR previews use `go_import`
(`clickhouse-go-import`), which needs SELECT, INSERT, ALTER, CREATE TABLE,
CREATE VIEW, DROP TABLE, DROP VIEW and TRUNCATE on the hub's three
databases, and also CREATE and DROP DATABASE on the previews'
(`dev_cbioportal_go_pr*`).

## Following master

The CronJob runs every minute with `concurrencyPolicy: Forbid`. Each run:

1. Reads `master`'s head commit with `git ls-remote`, and stops within
   seconds when it is the last commit imported (`_hub_master_sync`).
2. Otherwise lists the files changed since the last imported commit and
   imports every changed study in one import at the head commit, however
   many merges happened in between. Studies deleted from `master` are
   removed, and the shared gene panels are loaded again when they changed.
3. Records the head commit only when the import succeeded. A commit whose
   import failed is tried again after 30 minutes (`RETRY_AFTER`); a newer
   commit at once.

The first run, with nothing recorded, imports all of `master` (hours) and
removes the studies the hub held that `master` does not have.

## Per-PR preview

The Job runs `/app/deploy/hub-import.sh` from the cbioportal-go image (source:
[ops/cbioportal.org/hub-import.sh](https://github.com/cBioPortal/cbioportal-go/blob/main/ops/cbioportal.org/hub-import.sh)):

1. Lists the PR's changed studies (`public/<study>`, `crdc/gdc/<study>`) and
   reference gene panels; stops if this commit was imported completely
   already (Argo recreates finished Jobs after their 24 h TTL).
2. Posts an in-progress Check Run and Deployment on the PR.
3. Sparse, blobless checkout of `pull/<PR>/head`; a Job whose commit is no
   longer the PR head stops ("superseded").
4. Takes the preview's import lock, so the Jobs of one PR's commits run one
   at a time.
5. With `hub-preview: all` (first import only): copies the hub's staged
   studies and reference data into the preview (about 20 s), holding the
   hub's import lock.
6. Imports the PR's studies, validating each with cbioportal-core's
   `validateData.py` in the background.
7. Completes the Check Run and the Deployment status, with links to the
   imported studies on the preview.

### PR description settings

```markdown
hub-preview: all

hub-import-only:
- public/acc_tcga_pan_can_atlas_2018
```

| Setting | Effect |
|---|---|
| none, or `hub-preview: changed` | The preview holds the reference data and the PR's changed studies (the default). |
| `hub-preview: all` | The preview starts from a copy of every study on hub.cbioportal.org, with the PR's studies on top; the first build takes about an hour. Changing the setting rebuilds the preview with the next commit. |
| `hub-import-only:` | Limits the import to these of the PR's changed studies. Paths are as on disk (`public/<study>`, `crdc/gdc/<study>`). |

Closing the PR or removing the label deletes the Application; its PostDelete
hook (`cbioportal-ops hub teardown <N>`) drops the preview's databases.

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
