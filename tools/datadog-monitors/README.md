# Datadog CronJob monitors

Alerting for the CronJobs running in the `cbioportal-*` clusters. Datadog monitors live
in the Datadog account rather than the cluster, so Argo does not apply these — create or
update them with the Datadog API:

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

- All four notify to `@slack-cBioPortal-cronjob-status`. The Datadog Slack integration
  must be installed and that channel connected, or the handle silently resolves to
  nothing.
- No cluster-side change is needed. The Datadog Helm chart pinned in
  `apps/argocd/datadog.yaml` (3.109.2) defaults `datadog.kubeStateMetricsCore.enabled`
  to true, none of the `apps/datadog/values.yaml` files override it, and both cbioportal
  clusters set `clusterAgent.enabled: true` — so `kubernetes_state.job.*` and
  `kubernetes_state.cronjob.*` are already being collected.

## What each monitor covers

| File | Catches |
|---|---|
| `cronjob-failed.json` | A Job run failed — bad exit code, OOMKill, image pull error, `activeDeadlineSeconds` exceeded |
| `cronjob-missed-run-frequent.json` | An AWS credential refresher stopped being scheduled |
| `cronjob-missed-run-daily.json` | The daily ClickHouse clone stopped being scheduled |
| `cronjob-missed-run-weekly.json` | The weekly public DB dump stopped being scheduled |

The `missed-run` monitors matter more than the failure monitor: a CronJob that is
suspended, deleted, or never scheduled emits no failure metric at all, so
`cronjob-failed.json` alone would stay silent.

The two split cleanly: `cronjob-failed` covers "it ran and broke", the `missed-run`
tiers cover "it never ran".

`cronjob-failed.json` picks up any new CronJob automatically. The `missed-run` monitors
name theirs explicitly, because the threshold has to match each job's cadence — adding
a CronJob means adding its name to the matching tier here.

## Scope

Every query is scoped to `kube_cluster_name:cbioportal-*`, which covers
`cbioportal-prod-a9438edd` (203403084713) and `cbioportal-prod-6acc6d70` (666628074417).
The OncoKB clusters (`oncokb-research-444e139c`, `oncokb-production-3dfc6ef2`) run their
own CronJobs and are deliberately excluded.

The queries use the functional `AND` / `IN` syntax rather than comma-separated filters,
because Datadog rejects symbolic boolean syntax (`,`, `!`) mixed with `IN`.

`cronjob-failed.json` also filters on `kube_cronjob:*`. `kubernetes_state.job.*` is
tagged with `kube_job` **or** `kube_cronjob` — a one-off Job carries no `kube_cronjob`
tag, so without that filter every standalone Job in the cluster reports under an empty
group and any old failed one holds the monitor in ALERT permanently.

These monitors watch the cluster, not this repo, so they also cover CronJobs defined
elsewhere — `cbioportal-public-db-dump-weekly` is managed from `portal-configuration`
but still alerts here.

## Agent version constraint

The clusters pin agent **7.52.0**. `kubernetes_state.cronjob.duration_since_last_successful`
— the metric that would express "has not *succeeded* recently" — only exists from agent
**7.68.0**, so the `missed-run` monitors use
`kubernetes_state.cronjob.duration_since_last_schedule` instead. That measures time
since the CronJob controller last *created* a Job, not since one last succeeded.

The practical difference: a CronJob that runs on time but fails every time satisfies
these monitors. `cronjob-failed.json` is what catches that case. Upgrading the agent
past 7.68.0 would let the `missed-run` tiers switch to the stricter metric, and the
thresholds would carry over unchanged.

## Known behaviour

`kubernetes_state.job.completion.failed` is a gauge on a Job object, and these CronJobs
set `failedJobsHistoryLimit: 1`, so the failed Job lingers and the monitor stays in
ALERT until that object is garbage collected — including for a failure from weeks ago.
`timeout_h: 12` in `cronjob-failed.json` force-resolves it so the next failure alerts
again.

`find-failed-jobs.sh` lists the Job objects currently holding the monitor in ALERT, with
their age and owning CronJob. Deleting a stale one clears it:
`kubectl -n <ns> delete job <name>`.

Kubernetes only observes a container's exit code. A script that swallows an error — no
`set -e`, or a pipeline whose last command succeeds — exits 0, and no monitor here can
tell that apart from a real success.
