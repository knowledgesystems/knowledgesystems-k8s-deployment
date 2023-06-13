# Creating EKS Cluster

## Creating cbioportal-prod cluster
We used the scripts from DIGITs to create the IAM roles, security groups and the cluster. The script for adding nodegroups using a CloudFormation template
does not work well, so we decided to start using `eksctl` to create nodegroups.

For more details, please see https://github.mskcc.org/knowledgesystems/portal-configuration/tree/master/public-eks-cluster/eks

## App Versions

| App    | Version                                                        |
|--------|----------------------------------------------------------------|
| eksctl | [v0.144.0](https://github.com/weaveworks/eksctl/tree/v0.144.0) |

 
