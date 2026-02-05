# Resource Tagging
Tagging resources is critical for tracking and analyzing our AWS costs. All required tag keys listed below are now configured as **cost allocation tags** in AWS, which means they directly enable cost reporting and analysis in AWS Cost Explorer. Proper tagging allows us to break down spending by application, team, owner, and specific resource, making it possible to identify cost trends, optimize spending, and allocate costs accurately across teams. For resources managed through Terraform, automated methods should be used to inject tags into all resources.

## Required Tags
As part of our cost analysis, we have a set of required tags that need to be added to new and existing resources. These tags are configured as cost allocation tags in AWS.

{.compact}
| Tag Key       | Details                                                                                                                                            | Example            |
|---------------|----------------------------------------------------------------------------------------------------------------------------------------------------|--------------------|
| cdsi-app      | Name of the application. Helps us track total spending per application and identify which apps are driving costs.                                  | cbioportal         |
| cdsi-team     | Team name within CDSI. Allows us to allocate costs to specific teams and understand spending patterns across the organization.                     | data-visualization |
| cdsi-owner    | Email of the resource owner. Provides accountability and a point of contact for cost-related questions or optimization opportunities.              | nasirz1@mskcc.org  |
| resource-name | Name of the specific resource. Enables granular cost tracking at the individual resource level (e.g., database name, bucket name, nodegroup name). | cbioportal-prod-db |

For example, the following set of tags have been added to the cbioportal redis nodegroup in AWS EKS.
```yaml
tags:
  cdsi-app: cbioportal
  cdsi-team: data-visualization
  cdsi-owner: nasirz1@mskcc.org
  resource-name: cbioportal-redis # This matches the nodegroup name in AWS EKS
```

### Resource-Name Tag Guidelines

The `resource-name` tag value should match the actual name of the resource in AWS:

{.compact}
| AWS Service | Resource Type | resource-name Example     |
|-------------|---------------|---------------------------|
| RDS         | Database      | cbioportal-prod-db        |
| S3          | Bucket        | cbioportal-datahub        |
| EKS         | Nodegroup     | cbioportal-redis          |
| EKS         | Cluster       | cbioportal-prod           |
| EC2         | Instance      | knowledgesystems-importer |

## Resource Scope
There are a lot of AWS resources that we utilize. However, it is not possible nor practical to tag all those resources. After careful usage analysis, we decided that it's better to require tags for those resources that cost us the most. Therefore, when tagging new and existing resources, make sure the following services and resources are tagged at the very least.

{.compact}
| AWS Service | Resource Type             |
|-------------|---------------------------|
| EKS         | Clusters, Nodegroups      |
| EC2         | Instances, Load balancers |
| RDS         | Databases                 |
| S3          | Buckets                   |