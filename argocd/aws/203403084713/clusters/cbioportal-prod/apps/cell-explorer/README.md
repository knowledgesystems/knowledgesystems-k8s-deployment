# cell-explorer

Production deployment of [cell-explorer-py](https://github.com/cBioPortal/cell-explorer-py)
on `cbioportal-prod`. Served at https://cell-explorer.cbioportal.org.

Single-replica FastAPI app (serves API + frontend) on a dedicated `workload=cell-explorer`
node, with an EBS-backed SQLite catalog at `/app/data`. Zarr datasets are fetched directly
over HTTPS from the public cbioportal imaging bucket — no datasource signing is configured
(all datasets are public).

## One-time manual steps

### 1. Secret

The `cell-explorer-secrets` Secret is **not** in this repo — it lives in the private
`portal-configuration` repo under `secrets/cell-explorer/` (cluster secrets convention).
It must provide these keys, all consumed via `envFrom.secretRef` by the Deployment:

- `KEYCLOAK_CLIENT_SECRET` — from the Keycloak `cell-explorer` realm
- `ANTHROPIC_API_KEY` — chat agent
- `ADMIN_API_KEY` — admin API (generate: `python -c "import secrets; print(secrets.token_urlsafe(32))"`)
- `CLI_STATE_SECRET` — CLI auth (generate the same way)
- optional Langfuse: `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY`, `LANGFUSE_BASE_URL`

### 2. DNS

Point `cell-explorer.cbioportal.org` at the cluster's nginx ingress load balancer
(same target as other `*.cbioportal.org` apps). cert-manager issues the TLS cert
automatically once DNS resolves.

### 3. Seed the dataset catalog

Using `ADMIN_API_KEY`, create datasources/datasets via the admin API
(`POST /api/admin/datasources`, `POST /api/admin/datasets`). Mark public datasets
`is_public: true` so they serve without datasource credentials.

## Notes
- Image tag is pinned (not `latest`). Bump it here to deploy a new version.
- `Recreate` deploy strategy: the RWO EBS volume can't be shared across pods, so the
  old pod stops before the new one starts. Brief downtime on each deploy is expected.
- Keycloak realm session timeouts gate re-login; cookie max-ages in `configmap.yaml`
  must stay `<=` the realm's `ssoSessionMaxLifespan`.
