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
The above sets up a cluster with two t2.medium nodes and one master node. Our cluster consists of many more nodes which you can see in [instancegroups.yaml](instancegroups.yaml). For most use cases you probably won't need as many nodes as we do, since the amount of traffic is much lower. See here for hardware recommendations: https://docs.cbioportal.org/2.1-deployment/hardware-requirements.


## Add new nodes
Add new nodes with the label `genome-nexus` to the cluster configuration, which is stored in an S3 bucket:
```
kops create ig genome-nexus --subnet=us-east-1a --node-count=2 --node-size=t2.large
```

Then apply that configuation to the cluster:

```
kops update cluster --yes
```

Then you can check in the EC2 dashboard if the nodes show up and you can see when they are ready using the kubectl:
```
kubectl get nodes --show-labels -o=wide
```

Once the nodes are ready you can use `nodeSelector` in kubernetes config to always run certain pods on those nodes, e.g.:
```
      # run on genome nexus machines
      nodeSelector:
         kops.k8s.io/instancegroup: genome-nexus
```
From: https://github.com/knowledgesystems/knowledgesystems-k8s-deployment/blob/550f6c813029717bfbdf7ff40385ddd2f4944952/genome-nexus/gn_spring_boot.yaml#L70-L71

## Edit existing nodes
For example to edit the existing `genie` nodes configuration in the S3 bucket:
```
kops edit instancegroups genie
```

Then run:

```
kops update cluster ${NAME} --yes
```

Occasionally you will need to do a rolling update, e.g. if you are changing the instance size:

```
kops rolling-update cluster  --yes -v10
```
The `-v10` gives verbose logging which is useful to see certain problems that show up with the rolling update. Occasionally there are issues where one has to manually delete certain pods forcefully. For instance a deployment configuration could incorrectly say there should always be one replica available for a deployment, but also states that there can only be max one replica. So when kops tries to move the deployment to a new node it can't delete the pod and one needs to manually delete that causing temporary outage. Ideally our deployment configuration would be correct and allow multiple pods for a deployment, but this is not always the case.

## Store the cluster configuration
Currently we're only storing all instancegroups of our cluster in this repo, so it's transparent to external folks what our cluster looks like. This is the command to update that file
```
kops get instancegroups -o=yaml > kops/instancegroups.yaml
```
TODO: one should be able to create a cluster using that instancegroups file as well. We should provide that command in the documentation.

## Notes
- using existing VPC gave DNS problems: https://github.com/kubernetes/kops/issues/5236
