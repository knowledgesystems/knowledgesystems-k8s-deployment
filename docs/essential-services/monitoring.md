# Monitoring
We use Datadog and AWS CloudWatch for monitoring. For cBioPortal, datadog is deployed in multiple clusters and other AWS services are attached to AWS CloudWatch dashboard. Tables below shows bookmarks for common dashboards.

## Datadog Dashboards
{.compact}
| Name | URL | Description |
|------|-----|-------------|
| Kubernetes Compute Overview | [Link][dd-k8s-compute] | List of all node groups in our public/private clusters, together with other metrics such as usage, traces, profiles |
| API Traces/Logs - Public Portal (cbioportal.org) | [Link][dd-traces-public] | Traces/logs for the public portal deployed at cbioportal.org |
| API Traces/Logs - Genie Public/Private | [Link][dd-traces-genie] | Traces/logs for the genie public and private portals |
| Endpoint Stats - Public Portal (cbioportal.org) | [Link][dd-endpoint-stats-public] | API Endpoint Stats for the public portal deployed at cbioportal.org |

[dd-k8s-compute]: https://app.datadoghq.com/orchestration/explorer/node?query=kube_cluster_name%3Acbioportal-prod%20OR%20kube_cluster_name%3Acbioportal-prod-a9438edd%20OR%20kube_cluster_name%3Acbioportal-prod-a9438edd&explorer-na-groups=false&groups=label%23eks.amazonaws.com%2Fnodegroup&pod-explorer-cols=name%2Cstatus%2Ccluster%2Cnamespace%2Cnode%2Cage%2Cready%2Crestarts%2Ccpu_usage_limits%2Cmemory_usage_limits&ptfu=false
[dd-traces-public]: https://app.datadoghq.com/apm/traces?query=service%3Acbioportal%20env%3Aeks-public%20-status%3Aok%20%40http.status_code%3A%5B400%20TO%20600%5D%20-%40http.status_code%3A429%20-%40http.status_code%3A404&agg_m=count&agg_m_source=base&agg_t=count&cols=core_service%2Ccore_resource_name%2Clog_duration%2Clog_http.method%2Clog_http.status_code&fromUser=false&historicalData=true&messageDisplay=inline&sort=desc&spanType=all&storage=hot&view=spans&start=1755786818134&end=1756391618134&paused=false
[dd-traces-genie]: https://app.datadoghq.com/apm/traces?query=service%3Acbioportal%20%28env%3Aeks-genie-public%20OR%20env%3Aeks-genie-private%29%20-status%3Aok%20%40http.status_code%3A%5B401%20TO%20520%5D&agg_m=count&agg_m_source=base&agg_t=count&cols=core_service%2Ccore_resource_name%2Clog_duration%2Clog_http.method%2Clog_http.status_code&fromUser=false&historicalData=true&messageDisplay=inline&sort=desc&spanType=all&storage=hot&view=spans&start=1755786879059&end=1756391679059&paused=false
[dd-endpoint-stats-public]: https://app.datadoghq.com/software?env=eks-public&fromUser=false&hostGroup=%2A&selectedComponent=endpoint&start=1746553729059&end=1747158529059

## AWS CloudWatch Dashboards
{.compact}
| Name | URL | Description |
|------|-----|-------------|
| cBioPortal | [Link][cw-cbioportal] | Custom CloudWatch Dashboard prepared for cBioPortal |

[cw-cbioportal]: https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards/dashboard/cBioPortal

## CronJob alerting

CronJob run outcomes are reported to Slack through Datadog, not ArgoCD. Argo computes
Application health from its immediate git-tracked children only, so the Jobs a CronJob
controller spawns at runtime are never reflected in Application health — ArgoCD
Notifications cannot see them.

No cluster-side change is needed for the metrics. The pinned Datadog Helm chart
defaults `datadog.kubeStateMetricsCore.enabled` to true, no `values.yaml` overrides it,
and both cbioportal clusters enable the Cluster Agent, so `kubernetes_state.job.*` and
`kubernetes_state.cronjob.*` are already collected.

Monitor definitions live in [`tools/datadog-monitors/`][dd-cronjob-monitors] and are
applied with the Datadog API — see the README there. All of them notify
`@slack-cBioPortal-cronjob-status`.

{.compact}
| Monitor | Catches |
|---|---|
| `cronjob-failed` | A Job run failed — bad exit code, OOMKill, image pull error, deadline exceeded |
| `cronjob-missed-run-frequent` | An AWS credential refresher stopped being scheduled |
| `cronjob-missed-run-daily` | The daily ClickHouse clone stopped being scheduled |
| `cronjob-missed-run-weekly` | The weekly public DB dump stopped being scheduled |

The two split cleanly: `cronjob-failed` covers "it ran and broke", the `missed-run`
tiers cover "it never ran" — a CronJob that is suspended or deleted emits no failure
metric at all, so the failure monitor alone would stay silent.

Every query is scoped to `kube_cluster_name:cbioportal-*`. The OncoKB clusters run
their own CronJobs and are deliberately out of scope.

> [!NOTE]
> The `missed-run` monitors track time since the CronJob was last *scheduled*, not
> since it last *succeeded*. The stricter metric needs agent 7.68.0 and the clusters
> pin 7.52.0. See the README in `tools/datadog-monitors/`.

[dd-cronjob-monitors]: https://github.com/knowledgesystems/knowledgesystems-k8s-deployment/tree/master/tools/datadog-monitors

> [!WARNING]
> Kubernetes only observes a container's exit code, so no monitor can see an error the
> job's script swallows. A script without `set -e`, or one ending in a pipeline whose
> last command succeeds, exits 0 on a partial failure.
