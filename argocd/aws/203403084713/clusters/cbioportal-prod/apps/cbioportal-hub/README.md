# cbioportal-hub

Per-PR preview cBioPortal instance at https://hub.cbioportal.org. Imports studies from `cBioPortal/datahub` PRs labeled `preview`. See commit `84357773` for the original setup.

## Components (all in `default` namespace)

| Resource | Purpose |
|---|---|
| `Deployment cbioportal-hub` | Java cBioPortal **v7** serving the UI/API |
| `Deployment cbioportal-hub-clickhouse` | ClickHouse 24.8 + 50Gi PVC, init-seeded from `db-scripts/clickhouse/` bundled in the v7 cbioportal image |
| `Service cbioportal-hub` / `Service cbioportal-hub-clickhouse` | ClusterIP wiring (hub on 80, ClickHouse on 8123/9000) |
| `Ingress cbioportal-hub-ingress` | Traefik + cert-manager TLS for hub.cbioportal.org |
| `Job gene-panel-seed` | One-shot, imports reference gene panels into a fresh DB |
| `ApplicationSet datahub-pr-import-set` (`apps/argocd/`) | Generates one `datahub-import-<PR#>` Application per `preview`-labeled PR; each renders the helm chart at `import-job-helm/` into a Job |

## v7 + ClickHouse architecture notes

- cBioPortal v7 dropped MySQL — see [v6→v7 migration guide](https://docs.cbioportal.org/migration-v6-to-v7/). Hub mirrors the official [`cbioportal-docker-compose`](https://github.com/cBioPortal/cbioportal-docker-compose) v7 setup translated to k8s.
- The ClickHouse Deployment's initContainer extracts `schema.sql`, `seed-cbioportal_hg19_hg38_v2.14.5.sql.gz`, and `clickhouse.sql` from the **cbioportal v7 image** at `/cbioportal/db-scripts/clickhouse/...` into a shared emptyDir. ClickHouse's `docker-entrypoint-initdb.d` then runs the `load_*.sh` scripts (in `cbioportal-hub-clickhouse-init-scripts` ConfigMap) in lexical order: schema → seed → derived tables.
- Importer pods (per-PR `import-job-helm/templates/import-job.yaml` and `gene-panel-seed-job.yaml`) re-pack the runtime `application.properties` into `core-IMPORTER.jar` at start — mirrors `cbioportal-docker-compose/entrypoint.sh`. Skipping that step means the importer uses the JAR's bundled (wrong) DB connection.
- The same script also copies `/cbioportal/db-scripts/clickhouse/clickhouse.sql` to `/cbioportal/clickhouse.sql` so `metaImport.py` can refresh derived tables after each study.
- Connection: `jdbc:ch://cbioportal-hub-clickhouse:8123/cbioportal`, user `cbio_user`. Creds are inline plaintext in the manifests (preview-only).

## GitHub status integration (`hub-preview-bot`)

The import Job posts a **Check Run** + a **Deployment** on the source PR, so reviewers see import status and a clickable preview link directly in the PR UI.

**How auth works.** The Job mints an installation access token from a GitHub App ("cBioPortal Datahub Preview") on the fly via JWT, using credentials in the `hub-preview-bot` Secret. The Secret is declared in the private `knowledgesystems/portal-configuration` repo at:

```
argocd/aws/203403084713/clusters/cbioportal-prod/secrets/cbioportal-hub/hub-preview-bot.yaml
```

ArgoCD's `portal-configuration` Application syncs it into this cluster's `default` namespace automatically.

**Secret schema:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: hub-preview-bot
  namespace: default
stringData:
  client-id: "Iv23li..."                   # GitHub App Client ID (preferred over App ID)
  installation-id: "<numeric installation id on cBioPortal/datahub>"
  private-key: |
    -----BEGIN RSA PRIVATE KEY-----
    ...
    -----END RSA PRIVATE KEY-----
```

**Rotating the App's private key.** When the existing key is compromised, expired, or simply being rotated:

1. https://github.com/organizations/cBioPortal/settings/apps/cbioportal-datahub-preview → **Private keys** → **Generate a private key** (downloads a new `.pem`)
2. On the same page, **Delete** the old key
3. Update `private-key:` in the portal-configuration secret yaml, commit, push to master
4. ArgoCD picks it up within ~3 min; the next import Job uses the new key

**Disabling status posting (e.g. App is broken, GitHub API outage).** Delete or rename the `hub-preview-bot` Secret. The Job's `secretKeyRef` and volume mount are `optional: true`; the script's `gh_token` returns 1 when `/etc/gh-app/key.pem` is missing, and all `gh_api` calls become no-ops. Imports continue to run normally — no PR status updates.

## Things to be aware of when debugging

- `cbioportal-hub-mysql` boots with a wrapper command — see `cbioportal-hub-mysql.yaml` for first-boot vs subsequent-boot behavior (initial DB init can't have `/var/lib/mysql/tmp` present, so tmpdir is `/tmp` on first boot only).
- `gene-panel-seed` Job has `argocd.argoproj.io/sync-options: Replace=true` and TTL 24h; if the PVC is rebuilt, delete the completed Job manually so ArgoCD recreates it (otherwise reference panels stay un-seeded and study imports referencing IMPACT468 etc. fail with `Gene panel cannot be found in database`).
- All LFS fetching uses `git lfs pull --include=<path>/** --exclude=''` — the `--exclude=''` is required to override `fetchexclude=*` in datahub's `.lfsconfig`, which routes LFS to AWS S3 via API Gateway (not GitHub LFS).
