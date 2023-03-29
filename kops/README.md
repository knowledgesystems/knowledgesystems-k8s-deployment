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

## Taint and Toleration
k8s provides details on how Taint and Toleration works [HERE](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/). To design a nodegroup that can only be used with toleration, you can do the following.
### Option 1: Add taint directly to node
If the nodegroup size will not be updated, you could do the following to add the taint.
```
kubectl taint nodes node-name dedicated=large-mem:NoSchedule
```
Then add toleration to your deployment, see an example [HERE](https://github.com/knowledgesystems/knowledgesystems-k8s-deployment/commit/96bdad5af010c5fcff48ab091ba7c7a8040ac2f1).

You can verify the taint has been added succesfully by doing
```
kubectl get nodes -o json | jq '.items[].spec'
```
You will see 
```
{
  "podCIDR": "***",
  "providerID": "aws:///us-east-1c/***",
  "taints": [
    {
      "effect": "NoSchedule",
      "key": "dedicated",
      "value": "large-mem"
    }
  ]
}
```
To remove taint
```
kubectl taint nodes node-name dedicated=large-mem:NoSchedule-
```

### Option 2: Add taint through kops
To persist the taint when upsize/downsize a nodegroup, you would need to modify the cluster instancegroup configuration.

Please follow the instructions here: https://kops.sigs.k8s.io/tutorial/working-with-instancegroups/#adding-taints-or-labels-to-an-instance-group. 

Once modifying the cluster configuration(see example below), you would need to do cluster update: `kops update cluster cbioportal.review.k8s.local`. 
```
apiVersion: kops.k8s.io/v1alpha2
kind: InstanceGroup
spec:
  nodeLabels:
    kops.k8s.io/instancegroup: oncokb
  taints:
  - dedicated=oncokb:NoSchedule
<note: some  fields have been deleted in this example for brevity>
```

If the changes look ok, then do `kops update cluster cbioportal.review.k8s.local --yes`.

Once the cluster is successfully updated, you would want to do a rolling update to make sure all existing nodes will have the taint. kops will spin up new nodes with the taint and remove all previous.

* Note: rolling update with kops is that the old ec2 instance will not be terminated until the new ec2 instance is running. However, the pods running on the old node will be evicted before the new node is available, so you could experience some downtime.

## cBioPortal Production Setup
cBioPortal uses kOps version v1.19.1. It's subject to change. [This file](https://s3.console.aws.amazon.com/s3/object/cbioportal-review-store?region=us-east-1&prefix=cbioportal.review.k8s.local/kops-version.txt) shows the latest version.

1. You can install the specific version by downloading the file from https://github.com/kubernetes/kops/releases/tag/v1.19.1. (https://kops.sigs.k8s.io/getting_started/install/#github-releases Mac option doesn't really work but it provides insights on where you should put the command)

2. You would also need to have aws client installed and login to aws before moving to the next steps.

3. You would need to specify KOPS_STATE_STORE in order for it to work 
```
export KOPS_STATE_STORE=s3://cbioportal-review-store
```

4. You should be able to see the clusters if everything is configured properly using `kops get clusters`


## Notes
- using existing VPC gave DNS problems: https://github.com/kubernetes/kops/issues/5236
