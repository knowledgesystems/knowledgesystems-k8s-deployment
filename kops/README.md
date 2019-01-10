# Set up Kubernets cluster with kops
Note: this documentation depends on what version of kops and kubernetes you are
using. We try to keep it up to date but the websites of those projects
themselves will have more information if you run into issues.

- Install aws command line client (get admin key)
- Make an S3 bucket for keeping track of K8s state using aws command line
  client (with name `NAME`)
- Install [kops](https://github.com/kubernetes/kops) (creates kubernetes cluster on amazon)
 
Then:
```
export STATE_STORE=s3://random-k8s-state-store-name
export NAME=genome-nexus.review.k8s.local
# create config
kops create cluster --state=${STATE_STORE} --cloud=aws --zones=us-east-1a,us-east-1c --node-count=2  --node-size=t2.medium --master-size=t2.medium ${NAME}
# create cluster
kops update cluster ${NAME} --yes --state ${STATE_STORE}
```

## Notes
- using existing VPC gave DNS problems: https://github.com/kubernetes/kops/issues/5236
