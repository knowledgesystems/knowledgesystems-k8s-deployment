# OncoKB System
This is the documentation describing the current running apps in varies production environments.


## Environments

### oncokb.org
- All apps under oncokb.org is managed by k8s. 
- Cluster is in us-east-1
- Access cluster
  - We shared the AWS account with cBioPortal. Please reach out to Ino de Bruijn(debruiji@mskcc.org) for access
    - Currently, HZ, CL and SC have the access to the prod cluster
  - See [HERE](https://github.mskcc.org/CloudArchitecture/CloudDocs/blob/master/user-docs/aws/accounts.md#logging-in-to-aws) for details on how to log in to the cluster
  - Once logged in, you need to switch to k8s context to see the cluster.
    - Use `aws eks --region us-east-1 update-kubeconfig --name <cluster name>` if it's first time accessing the cluster
    - Use `kubectl config use-context <cluster name>`to switch to cluster
- Update infrastructure
  - We use kops to update the size of ec2 instances. Other resources are manually created/updated or throw aws cli. Please reach out to HZ for more info.

### eucentral.oncokb.org
- All apps under eucentral.oncokb.org is managed by k8s.
- Cluster is in eu-central-1
- We shared the AWS account with cBioPortal. Please reach out to Ino de Bruijn(debruiji@mskcc.org) for access
    - Currently, HZ, CL and SC have the access to the prod cluster
- Update infrastructure
  - We use aws eks created/updated ec2 resource. Other resource through website or aws cli. Please reach out to HZ for more info.

### oncokb.aws.mskcc.org
- All apps under oncokb.dev.aws.mskcc.org is managed by k8s.
- Cluster is in us-east-1
- We use standard private VPC account from MSK. Please reach out to [MSK security for access](https://thespot.mskcc.org/esc/?id=sc_cat_item&sys_id=cee42b7cdb09a010701a2a591396198b).
    - Currently, HZ, CL and SC have the access to the prod cluster
- Access cluster
  - We use standard private VPC account from MSK. Please reach out to [MSK security for access](https://thespot.mskcc.org/esc/?id=sc_cat_item&sys_id=cee42b7cdb09a010701a2a591396198b).
    - Currently, HZ, CL and SC have the access to the prod cluster
  - See [HERE](https://github.mskcc.org/CloudArchitecture/CloudDocs/blob/master/user-docs/aws/accounts.md#logging-in-to-aws) for details on how to log in to the cluster
  - Once logged in, you need to switch to k8s context to see the cluster.
    - Use `aws eks --region us-east-1 update-kubeconfig --name <cluster name>` if it's first time accessing the cluster
    - Use `kubectl config use-context <cluster name>`to switch to cluster
- Update infrastructure
  - We use Azure pipeline to deploy AWS resources
  - Please see [HERE](https://dev.azure.com/MSKDevOps/OncoKB/_build) for all the deployment pipelines
    - Please reach out to HZ if you don't have the access to the Azure account

### oncokb.dev.aws.mskcc.org
- All apps under oncokb.dev.aws.mskcc.org is managed by k8s.
- Cluster is in us-east-1
- Access cluster
  - See the same section of `oncokb.aws.mskcc.org` environment for details
- Update infrastructure
  - See the same section of `oncokb.aws.mskcc.org` environment for details
