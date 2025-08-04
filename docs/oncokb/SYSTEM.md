# OncoKB System
This is the documentation describing the current running apps in varies production environments.


## Environments

### oncokb.org
- All apps under oncokb.org is managed by ArgoCD. 
- Cluster is in us-east-1
- Access cluster
  - We shared the AWS account with cBioPortal. Please reach out to Ino de Bruijn(debruiji@mskcc.org) for access
  - See [HERE](https://github.mskcc.org/CloudArchitecture/CloudDocs/blob/master/user-docs/aws/accounts.md#logging-in-to-aws) for details on how to log in to the cluster
  - Once logged in, you need to switch to k8s context to see the cluster.
    - Use `aws eks --region us-east-1 update-kubeconfig --name <cluster name>` if it's first time accessing the cluster
    - Use `kubectl config use-context <cluster name>`to switch to cluster
- Update infrastructure
  - We use Terraform to manage infrastructure. Reach out to Zain Nasir (nasirz1@mskcc.org) for more info.

### eucentral.oncokb.org
- All apps under eucentral.oncokb.org is managed by k8s.
- Cluster is in eu-central-1
- This is under the legacy AWS account. Please reach out to Ino de Bruijn(debruiji@mskcc.org) for access
- Update infrastructure
  - We use aws eks created/updated ec2 resource. Other resource through website or aws cli.

### oncokb.aws.mskcc.org
- All apps under oncokb.dev.aws.mskcc.org is managed by ArgoCD.
- Cluster is in us-east-1
- We use standard private VPC account from MSK. Please reach out to [MSK security for access](https://thespot.mskcc.org/esc/?id=sc_cat_item&sys_id=cee42b7cdb09a010701a2a591396198b).
- Access cluster
  - We use standard private VPC account from MSK. Please reach out to [MSK security for access](https://thespot.mskcc.org/esc/?id=sc_cat_item&sys_id=cee42b7cdb09a010701a2a591396198b).
  - See [HERE](https://github.mskcc.org/CloudArchitecture/CloudDocs/blob/master/user-docs/aws/accounts.md#logging-in-to-aws) for details on how to log in to the cluster
  - Once logged in, you need to switch to k8s context to see the cluster.
    - Use `aws eks --region us-east-1 update-kubeconfig --name <cluster name>` if it's first time accessing the cluster
    - Use `kubectl config use-context <cluster name>`to switch to cluster
- Update infrastructure
  - We use Terraform to manage infrastructure. Reach out to Zain Nasir (nasirz1@mskcc.org) for more info.

### oncokb.dev.aws.mskcc.org
- All apps under oncokb.dev.aws.mskcc.org is managed by ArgoCD.
- Cluster is in us-east-1
- Access cluster
  - See the same section of `oncokb.aws.mskcc.org` environment for details
- Update infrastructure
  - See the same section of `oncokb.aws.mskcc.org` environment for details
