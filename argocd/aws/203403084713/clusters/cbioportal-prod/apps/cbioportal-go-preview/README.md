# cbioportal-go PR previews

A [cBioPortal/cbioportal-go](https://github.com/cBioPortal/cbioportal-go) pull
request labelled `preview` gets its own instance at
`https://pr-<N>.gopreview.cbioportal.org`, running the PR's image on its own
ClickHouse Cloud databases built by the PR's importer. Removing the label or
closing the PR removes it.

## Flow

1. cbioportal-go's `docker.yml` pushes `cbioportal/cbioportal-go:pr-<N>` and
   `:sha-<commit>` for labelled same-repo PRs (on labelling and each push).
2. `ApplicationSet cbioportal-go-preview-set` (`apps/argocd/`) creates
   `Application cbioportal-go-pr-<N>` from `chart/` with the PR number and
   head commit.
3. `CronJob cbioportal-go-pr-<N>-setup-<sha>` (every 5 min) runs the PR
   image's `/app/deploy/pr-preview-setup.sh`: it reads the PR description's
   "Preview Configuration", creates `dev_cbioportal_go_pr<N>{,_raw,_ref}`,
   loads the data and posts a "Preview" Check Run and a Deployment on the PR.
   It rebuilds only when the head commit or the configuration changed, then
   restarts the API.
4. `Deployment cbioportal-go-pr-<N>` (1 replica, `:sha-<commit>`), Service and
   Ingress (cert-manager HTTP-01 certificate per host). www.cbioportal.org's
   portal settings and OncoKB token; sessions in the pod's memory; no login.
5. On deletion, the PostDelete hook Job `cbioportal-go-pr-<N>-teardown` drops
   the databases. `CronJob cbioportal-go-preview-gc` (daily, `Application
   cbioportal-go-preview`) drops those of closed or unlabelled PRs as a
   safety net.

Pods started before their image exists wait in `ImagePullBackOff` until
the build pushes it. A new commit replaces the setup CronJob, so a run still
waiting for an older image is deleted.

## Data (PR description)

```
## Preview Configuration

preview-data: prod                # default: zero-copy clone of production
preview-data: datahub-pr 2372     # reference data + the studies a datahub PR changes
preview-data: studies             # reference data + the listed studies (datahub master)
preview-studies:
- public/msk_impact_2017
```

## Prerequisites

- **ClickHouse:** `go_import` (Secret `clickhouse-go-import`) builds and
  serves the preview databases; it needs grants on `dev_cbioportal_go_pr*`.
- **GitHub App** "cBioPortal Datahub Preview" installed on
  cBioPortal/cbioportal-go: Secret `hub-preview-bot` (default namespace) for
  the Jobs, and the repo-creds Secret `cbioportal-go-preview-github-app`
  (argocd namespace) for the ApplicationSet; both in portal-configuration.
- **DNS:** `*.gopreview.cbioportal.org` CNAME to the Traefik load balancer,
  not proxied.
