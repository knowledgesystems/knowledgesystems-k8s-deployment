# Monitoring
We use Datadog and AWS CloudWatch for monitoring. For cBioPortal, datadog is deployed in multiple clusters and other AWS services are attached to AWS CloudWatch dashboard. Tables below shows bookmarks for common dashboards.

## Datadog Dashboards
{.compact}
| Name    | URL                     | Description            |
|------------|-----------------------------|--------------------|
| Kubernetes Compute Overview   | [Link](https://app.datadoghq.com/orchestration/explorer/node?query=kube_cluster_name%3Acbioportal-prod%20OR%20kube_cluster_name%3Acbioportal-prod-a9438edd%20OR%20kube_cluster_name%3Acbioportal-prod-a9438edd&explorer-na-groups=false&groups=label%23eks.amazonaws.com%2Fnodegroup&pod-explorer-cols=name%2Cstatus%2Ccluster%2Cnamespace%2Cnode%2Cage%2Cready%2Crestarts%2Ccpu_usage_limits%2Cmemory_usage_limits&ptfu=false)             | List of all node groups in our public/private clusters, together with other metrics such as usage, traces, profiles         |
| API Traces/Logs - Public Portal (cbioportal.org)  | [Link](https://app.datadoghq.com/apm/traces?query=service%3Acbioportal%20env%3Aeks-public&agg_m=count&agg_m_source=base&agg_t=count&cols=core_service%2Ccore_resource_name%2Clog_duration%2Clog_http.method%2Clog_http.status_code&fromUser=false&historicalData=true&messageDisplay=inline&sort=desc&spanType=all&storage=hot&view=spans&start=1746553544332&end=1747158344332&paused=false)       | Traces/logs for the public portal deployed at cbioportal.org |
| API Traces/Logs - Genie Public/Private | [Link](https://app.datadoghq.com/apm/traces?query=service%3Acbioportal%20env%3Aeks-genie-public%20OR%20env%3Aeks-genie-private&agg_m=count&agg_m_source=base&agg_t=count&cols=core_service%2Ccore_resource_name%2Clog_duration%2Clog_http.method%2Clog_http.status_code&fromUser=false&historicalData=true&messageDisplay=inline&sort=desc&spanType=all&storage=hot&view=spans&start=1746553595513&end=1747158395513&paused=false) | Traces/logs for the genie public and private portals  |
| Endpoint Stats - Public Portal (cbioportal.org) | [Link](https://app.datadoghq.com/software?env=eks-public&fromUser=false&hostGroup=%2A&selectedComponent=endpoint&start=1746553729059&end=1747158529059) | API Endpoint Stats for the public portal deployed at cbioportal.org  |

## AWS CloudWatch Dashboards
{.compact}
| Name    | URL                     | Description            |
|------------|-----------------------------|--------------------|
| cBioPortal   | [Link](https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards/dashboard/cBioPortal)             | Custom CloudWatch Dashboard prepared for cBioPortal         |