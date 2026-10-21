# cell-explorer

Production deployment of [cell-explorer-py](https://github.com/cBioPortal/cell-explorer-py)
on `cbioportal-prod`. Served at https://cell-explorer.cbioportal.org.

Two-replica FastAPI app (serves API + frontend) on a dedicated `workload=cell-explorer`
spot nodegroup (2 nodes), with its catalog in Postgres (`DATABASE_URL` in the Secret). Zarr datasets
are fetched directly over HTTPS from the public cbioportal imaging bucket — no datasource
signing is configured (all datasets are public).

This app is brought up **manually, one resource at a time** (see Rollout), and its ArgoCD
Application is **manual-sync** (no automated/selfHeal/prune).

## Configuration (lives in `portal-configuration`)

The Deployment loads **all** runtime config via `envFrom` — a ConfigMap and a Secret that
are **not** in this repo. Both live in the private `portal-configuration` repo under
`argocd/aws/203403084713/clusters/cbioportal-prod/` (`configmaps/` and `secrets/cell-explorer/`).
During the manual bring-up below, apply them by hand; ongoing, the `portal-configuration`
ArgoCD Application reconciles them:

- **ConfigMap `cell-explorer-config`** — `configmaps/cell-explorer-configmap.yaml`
  (non-secret env: `ENVIRONMENT`, Keycloak URL/realm/client, CORS, `ZARR_ACCESS_ORIGIN`,
  cookie max-ages).
- **Secret `cell-explorer-secrets`** — `secrets/cell-explorer/cell-explorer-secrets.yaml`:
  - `KEYCLOAK_CLIENT_SECRET` — from the Keycloak `cell-explorer` realm
  - `ANTHROPIC_API_KEY` — chat agent
  - `ADMIN_API_KEY` — admin API (generate: `python -c "import secrets; print(secrets.token_urlsafe(32))"`)
  - `CLI_STATE_SECRET` — CLI auth (generate the same way)
  - `DATABASE_URL` — catalog Postgres (`postgresql+asyncpg://…?ssl=require`)
  - optional Langfuse: `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY`, `LANGFUSE_BASE_URL`

Both set `namespace: cell-explorer`, so until this app creates that namespace they
error-then-self-heal on the `portal-configuration` Application. The pod stays in
`CreateContainerConfigError` until both exist.

## Rollout (manual, one resource at a time)

Bring it up in this order with `terraform`/`kubectl`, validating each step before the next:

1. **Nodegroup** — `terraform apply` in `iac/.../cbioportal-prod/eks` to create the
   `cell-explorer` spot nodegroup; wait for 2 nodes `Ready`.
2. **Namespace** — `kubectl apply -f namespace.yaml`.
3. **Config + Secret** — apply the ConfigMap and Secret from `portal-configuration`
   (`configmaps/cell-explorer-configmap.yaml`, `secrets/cell-explorer/cell-explorer-secrets.yaml`).
4. **PVC** — not needed; `pvc.yaml` only keeps the retired SQLite volume.
5. **Deployment + Service** — `kubectl apply -f deployment.yaml`; watch the pod reach
   `Ready` (`/health`). It stays in `CreateContainerConfigError` until step 3 exists.
6. **Ingress** — `kubectl apply -f ingress.yaml`.
7. **ArgoCD** — once validated, sync the manual-sync `cell-explorer` Application to bring
   everything under GitOps. It will not auto-sync; sync by hand.

### DNS

Point `cell-explorer.cbioportal.org` at the cluster's Traefik ingress load balancer
(same ELB as other `*.cbioportal.org` apps). cert-manager issues the TLS cert
automatically once DNS resolves and the ACME challenge can reach Traefik. The Ingress
uses `ingressClassName`/annotation `traefik` (the cluster's active controller — nginx is
not deployed).

### Seed the dataset catalog

Using `ADMIN_API_KEY`, create datasources/datasets via the admin API
(`POST /api/admin/datasources`, `POST /api/admin/datasets`). Mark public datasets
`is_public: true` so they serve without datasource credentials.

## Notes
- Image tag is pinned (not `latest`). To deploy a new version, bump it in **both**
  `deployment.yaml` and `image-prepull.yaml`.
- Spot nodegroup (2 nodes, single AZ): one replica runs on each node
  (`topologySpreadConstraints`), and the PodDisruptionBudget keeps one serving while a
  node drains. Instance types are diversified (`m7i`/`m6i`/`m5` large) so the ASG can
  find spot capacity. The `image-prepull` DaemonSet keeps the image cached on both nodes
  so a replacement pod skips the image pull.
- `RollingUpdate` (maxSurge 1, maxUnavailable 0): deploys and Reloader restarts bring up
  a new pod before stopping an old one, so neither takes the site down.
- Each pod runs `alembic upgrade head` on start; a no-op unless a release adds a migration.
- Keycloak realm session timeouts gate re-login; keep the cookie max-ages in the
  `cell-explorer-config` ConfigMap (in `portal-configuration`) `<=` the realm's
  `ssoSessionMaxLifespan`.
