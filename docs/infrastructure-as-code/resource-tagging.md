# Resource Tagging
Tagging resources is very important for tracking our AWS costs. Proper tagging can be achieved through multiple ways, including manually adding tags through AWS console. For resources managed through Terraform, we use automated methods to inject tags into all resources.

## Required Tags
As part of our cost analysis, we have a set of required tags that need to be added to new and existing resources.

{.compact}
| Tag Key    | Details                     | Example            |
|------------|-----------------------------|--------------------|
| cdsi-app   | Name of the app             | cbioportal         |
| cdsi-team  | Team name within CDSI       | data-visualization |
| cdsi-owner | Email of the resource owner | nasirz1@mskcc.org  |

For example, the following set of tags have been added to AWS resources related to cBioPortal.
```yaml
tags:
  cdsi-app: cbioportal
  cdsi-team: data-visualization
  cdsi-owner: nasirz1@mskcc.org
```

## Resource Scope
There are a lot of AWS resources that we utilize. However, it is not possible nor practical to tag all those resources. After careful usage analysis, we decided that it's better to require tags for those resources that cost us the most. Therefore, when tagging new and existing resources, make sure the following services and resources are tagged at the very least.

{.compact}
| AWS Service | Resource Type             |
|-------------|---------------------------|
| EKS         | Clusters, Nodegroups      |
| EC2         | Instances, Load balancers |
| RDS         | Databases                 |
| S3          | Buckets                   |