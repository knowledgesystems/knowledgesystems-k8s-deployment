# Datadog CronJob monitors

Alerting for the CronJobs running in the Knowledge Systems clusters. Datadog monitors
live in the Datadog account rather than the cluster, so Argo does not apply these —
create or update them with the Datadog API:

```sh
export DD_API_KEY=... DD_APP_KEY=...
for f in tools/datadog-monitors/*.json; do
  curl -sS -X POST "https://api.datadoghq.com/api/v1/monitor" \
    -H "Content-Type: application/json" \
    -H "DD-API-KEY: ${DD_API_KEY}" \
    -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
    -d @"$f"
done
```

To update an existing monitor, `PUT` the same body to `/api/v1/monitor/<id>`.

## Prerequisites

- The `@slack-ks-alerts` handle in each `message` is a placeholder. Replace it with the
  real channel handle from the Datadog Slack integration before the first POST.
- No cluster-side change is needed. The Datadog Helm chart pinned in
  `apps/argocd/datadog.yaml` (3.109.2) defaults `datadog.kubeStateMetricsCore.enabled`
  to true, none of the `apps/datadog/values.yaml` files override it, and every cluster
  running a CronJob sets `clusterAgent.enabled: true` — so `kubernetes_state.job.*` and
  `kubernetes_state.cronjob.*` are already being collected.

## What each monitor covers

| File | Catches |
|---|---|
| `cronjob-failed.json` | A Job run failed, in any cluster — bad exit code, OOMKill, image pull error, `activeDeadlineSeconds` exceeded |
| `cronjob-missed-run-frequent.json` | A 6-hourly AWS credential refresher stopped succeeding |
| `cronjob-missed-run-daily.json` | A daily CronJob stopped succeeding |
| `cronjob-missed-run-weekly.json` | The weekly public DB dump stopped succeeding |

The `missed-run` monitors matter more than the failure monitor: a CronJob that is
suspended, deleted, or never scheduled emits no failure metric at all, so
`cronjob-failed.json` alone would stay silent.

The `missed-run` monitors name CronJobs explicitly, because the threshold has to match
each job's cadence. Adding a CronJob to a cluster means adding its name to the matching
tier here.

## Scope

These monitors watch the cluster, not this repo, so they also cover CronJobs defined
elsewhere — `cbioportal-public-db-dump-weekly` is managed from `portal-configuration`
but still alerts here.

Clusters `397229547211` (cbioportal-dev) and `762447640649` (oncokb-dev) have no
Datadog deployment, so nothing running there is covered.

## Known behaviour

`kubernetes_state.job.completion.failed` is a gauge on a Job object, and these CronJobs
set `failedJobsHistoryLimit: 1`, so the failed Job lingers and the monitor stays in
ALERT until that object is garbage collected. `timeout_h: 12` in `cronjob-failed.json`
force-resolves it so the next failure alerts again.

Kubernetes only observes a container's exit code. A script that swallows an error — no
`set -e`, or a pipeline whose last command succeeds — exits 0, and no monitor here can
tell that apart from a real success.
