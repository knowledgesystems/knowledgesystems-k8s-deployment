# knowledgesystems-k8s-deployment

Public Kubernetes glue for the Knowledge Systems group: Argo Applications, Deployments, Services, Ingresses, Helm values. Cluster-level secrets and private per-deployment config live in `portal-configuration` (private repo).

## Layout

```
argocd/aws/<account>/clusters/<cluster>/
  apps/
    argocd/          # Argo Application files (app-of-apps target)
    <app-name>/      # Per-app manifests (Deployment, Service, Ingress, values.yaml, etc.)
```

Three AWS accounts in use:
- **203403084713** — cBioPortal Public
- **666628074417** — MSK
- **762447640649** / **175678591974** — OncoKB

## Conventions

### Comments

- **Current state only.** Comments describe what the code does *now*. Don't reference prior implementations, previous bugs, or what changed — `git log` / `git blame` carry that.
- **Bias toward fewer comments.** Add one when the *why* is non-obvious (a hidden constraint, a workaround for a specific bug, behavior that would surprise a reader). If removing the comment would not confuse a future reader, don't write it.
- **No "why I changed this" comments.** Bad: `# Switched from X to Y because the old approach …`. Good: `# Pinned static binary for reproducibility`.

### Argo Application style

- App-of-apps target: every Application file in `apps/argocd/` is picked up by the parent `argocd` Application.
- Prefer `automated: {prune: true, selfHeal: true}` for apps that should track git automatically. The `argocd` app-of-apps is intentionally manual-sync (gate adding/removing Applications).
- When something in-cluster mutates a Resource (e.g. a CronJob patches a ConfigMap), pair `ignoreDifferences` on the field with `syncOptions: [RespectIgnoreDifferences=true, ServerSideApply=true]` on the Application. ServerSideApply lets Argo build the patch from managed-fields and skip the ignored JSON pointer.

### Kustomize subdir pattern

For ConfigMaps whose data is prose-shaped (markdown, SQL, scripts), prefer real `.md`/`.sql`/`.sh` files plus a `kustomization.yaml` with `configMapGenerator` + `disableNameSuffixHash: true` — kept in `portal-configuration` so the source is editable as proper files. A dedicated Argo Application (e.g. `cbioagent-msk-configmaps`) points at the Kustomize subdir; the broader portal-configuration Application uses `directory.exclude` so it doesn't apply `kustomization.yaml` as a plain manifest.

### Secrets

Don't add Secret manifests to this repo. They live in `portal-configuration` under `secrets/<app>/`.

## Dev servers

Headless dev server — bind to `0.0.0.0` (not `localhost`) and report `http://macbook-server-1337:<port>`.
