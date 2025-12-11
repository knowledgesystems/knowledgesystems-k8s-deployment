---
icon: tools
---
# Troubleshooting
This list is used to track issues and their remedies.

## EFS Mount Failed - Missing Mount Targets in Availability Zone
When deploying applications that use EFS persistent volumes, you may encounter mount errors like:
```
MountVolume.SetUp failed for volume "pvc-295ec7e4-fe8f-4dc6-b5a9-70cdc6fa05ee" : rpc error: code = Internal desc = Could not mount "fs-017997c6e5521be56:/" at "/var/lib/kubelet/pods/74b06dda-6fe3-4195-9f1a-64a0ce6de954/volumes/kubernetes.io~csi/pvc-295ec7e4-fe8f-4dc6-b5a9-70cdc6fa05ee/mount": mount failed: exit status 1
...
No matching mount target in the az us-east-1a. Please create one mount target in us-east-1a, or try the mount target in another AZ by passing the availability zone name option. Available mount target(s) are in az ['us-east-1b']
```
This happens when your EKS cluster nodes are running in an availability zone that doesn't have an EFS mount target. EFS requires mount targets in each AZ where you want to access the file system.

To resolve this, create mount targets in the missing availability zones. You can do this via the AWS CLI:
```
aws efs create-mount-target \
  --file-system-id fs-xxxxxx \
  --subnet-id subnet-xxxxxx \
  --security-groups sg-xxxxxx
```

## Docker Image Not Found - Bitnami Legacy Images and Helm Charts
When installing helm charts that use legacy Bitnami images, you may encounter errors like:
```
Back-off pulling image "docker.io/bitnami/redis:7.2.2-debian-11-r0":ErrImagePull: rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/bitnami/redis:7.2.2-debian-11-r0": failed to resolve reference "docker.io/bitnami/redis:7.2.2-debian-11-r0": docker.io/bitnami/redis:7.2.2-debian-11-r0: not found
```
This happens because some older Bitnami image versions are now located in the `bitnamilegacy` repository instead of the main `bitnami` repository. To solve the above issue, try providing custom image repository and registry to the helm chart. For example, for redis, you can set helm values like so:
```
image:
    repository: bitnamilegacy/redis
    registry: docker.io
```

## Low Ephemeral Storage Issue
Our new Terraform modules use a default ephemeral storage which might not be enough for certain workloads. This leads to an error similar to the following on deployments:
```
The node was low on resource: ephemeral-storage. Threshold quantity: 123456789, available: 123456Ki.
```
To increase the ephemeral storage capacity for the nodegroup, update the terraform modules to use custom disk sizes. As an example, look at the current nodegroups [here](https://github.com/knowledgesystems/knowledgesystems-k8s-deployment/blob/master/iac/aws/203403084713/clusters/cbioportal-prod/eks/main.tf#L68-L71).

## AWS-CNI Failing to Assign IP Addresses
If a AWS EKS managed nodegroup has too many pods deployed on one of its EC2 nodes, it can run out of IP Addresses with the error:
```
plugin type="aws-cni" name="aws-cni" failed (add): add cmd: failed to assign an IP address to container
```
To resolve this issue, analyze the deployments in the nodegroup and see if a specific deployment group can be separated into its own nodegroup. E.g., For oncokb production workload, redis deployment needed 20 pods. In such cases, the better approach was to deploy redis in its own nodegroup called `oncokb-redis`.

## Datadog Failing to Inject Init-Containers
In an AWS EKS cluster, if datadog is failing to inject init-containers because the deployments are somehow invisible to the Cluster Agent or the Cluster Agent is failing to detect them, then it could be a [networking issue](https://docs.datadoghq.com/containers/troubleshooting/admission-controller/?tab=helm#amazon-elastic-kubernetes-service-eks). To fix it, add the following inbound rule to the security groups attached to EC2 instances in the cluster:
- **Protocol**: TCP
- **Port range**: `8000`, or a range that covers `8000`
- **Source**: The ID of either the cluster security group, or one of your cluster’s additional security groups. You can find these IDs in the EKS console, under the Networking tab for your EKS cluster.

This security group rule allows the control plane to access the node and the downstream Cluster Agent over port `8000`.

If you have multiple managed node groups, each with distinct security groups, add this inbound rule to each security group.

## MongoDB Persistent Volume Claim Error
When installing MongoDB Helm Chart in a new cluster, we sometimes run into an error where the helm chart is unable to create a persistent volume, which leads to the persistent volume claim failing to bind:
```
no persistent volumes available for this claim and no storage class is set
```

This happens because in a new cluster, a default storage class for Kubernetes has not been set. Run the following commands to fix this:
```shell
# Get the name of the storage class
kubectl get storageclasses.storage.k8s.io

# If you get the following output, notice how there is no default tag next to the class name
# NAME  PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
# gp2   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  632d

# Patch the storage class to make it default
kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Now running the following should show default storage class
kubectl get storageclasses.storage.k8s.io
# NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
# gp2 (default)   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  632d
```

## Nginx Ingress Helm Upgrade Errors
For the `666628074417` account, upgrading Ingress controllers through Helm results in various errors due to the custom networking rules. 
### 400 Bad Request - The plain HTTP request was sent to HTTPS port
To fix this issue, apply the correct nginx controller config defined [here](https://github.com/knowledgesystems/knowledgesystems-k8s-deployment/blob/master/digits-eks/eks-prod/shared-services/ingress/eks_ingress_controller.yaml) after updating nginx.

### Keycloak Invalid Requester Error
Keycloak fails to forward headers, which leads to the following error in the network tab when the site is accessed:
```shell
Mixed Content: The page at 'https://keycloak.cbioportal.mskcc.org/auth/admin/master/console/' was loaded over HTTPS, but requested an insecure script 'http://keycloak.cbioportal.mskcc.org/auth/js/keycloak.js?version=4cbzu'. This request has been blocked; the content must be served over HTTPS.
```
The following error is seen in the kubernetes pods for the keycloak instance:
```shell
14:45:56,925 WARN  [org.keycloak.events] (default task-2) type=LOGIN_ERROR, realmId=msk, clientId=null, userId=null, ipAddress=10.1.141.180, error=invalid_authn_request, reason=invalid_destination
14:46:39,551 WARN  [org.keycloak.events] (default task-5) type=LOGIN_ERROR, realmId=msk, clientId=null, userId=null, ipAddress=10.1.140.190, error=invalid_authn_request, reason=invalid_destination
```
To solve this issue, use the correct forwarding rules by applying the configmap defined [here](https://github.com/knowledgesystems/knowledgesystems-k8s-deployment/blob/master/digits-eks/eks-prod/shared-services/ingress/eks_ingress_configmap.yaml) after updating nginx.

## Datadog failed to auto-detect cluster name
When deployed on AWS EC2 nodes using the `BOTTLEROCKET_*` AMI types, Datadog fails to auto-detect the cluster name, resulting in the following errors:
```shell
2025-03-10 17:39:09 UTC | CLUSTER | WARN | (subcommands/start/command.go:235 in start) | Failed to auto-detect a Kubernetes cluster name. We recommend you set it manually via the cluster_name config option
2025-03-10 17:39:10 UTC | CLUSTER | ERROR | (pkg/collector/corechecks/loader.go:64 in Load) | core.loader: could not configure check orchestrator: orchestrator check is configured but the cluster name is empty
2025-03-10 17:39:10 UTC | CLUSTER | ERROR | (pkg/collector/scheduler.go:208 in getChecks) | Unable to load a check from instance of config 'orchestrator': Core Check Loader: Could not configure check orchestrator: orchestrator check is configured but the cluster name is empty
```

To solve this, either use the `AL2_*` AMI type (NOT RECOMMENDED) or manually specify the cluster name in the Datadog helm values:
```yaml
datadog:
  clusterName: <cluster-name>
```

## Datadog always out-of-sync with helm and argocd

By default, Datadog auto-assigns random values to the following on restarts:
1. Token used for authentication between the cluster agent and node agents.
2. Configmap for the APM Instrumentation KPIs.

This leads to Datadog being permanently out-of-sync when deployed with Helm and ArgoCD. To solve this issue, follow the steps below:

1. Provide a cluster agent token as a secret.
   * Generate a random 32-digit hexadecimal number.
        ```shell
        openssl rand -hex 32
        ```
   * Create a secret with the number generated above.
        ```yaml
        apiVersion: v1
        kind: Secret
        metadata:
          name: datadog
        stringData:
          token: <random-hex-32>
        ```
   * Use existing secret in Datadog helm values.
        ```yaml
        clusterAgent:
          tokenExistingSecret: datadog
        ```
2. Disable API Instrumentation KPIs by setting the `datadog.apm.instrumentation.skipKPITelemetry` to `false` in the datadog helm values.
    ```yaml
    datadog:
      apm:
        instrumentation:
          skipKPITelemetry: true
    ```

## EKS addon update stuck/timeout
Terraform apply can time out updating kube-proxy (or other addons) with errors like:
```
Error: waiting for EKS Add-On (cbioportal-prod-a9438edd:kube-proxy) update (...): timeout while waiting for state to become 'Successful' (last state: 'InProgress')
```
and describing the kube-proxy pod shows:
```
FailedScheduling: 0/46 nodes are available: 1 Too many pods, 45 node(s) didn't satisfy plugin(s) [NodeAffinity]
```
During an addon upgrade each addon pod is pinned to its target node. If that node is at its max pod capacity (e.g., small instance type with max 4 pods), the new pod cannot schedule and the add-on never completes.

Choose an instance type that support at least 10 pods so that addons (aws-node, ebs-csi, efs-csi, eks-identity, kube-proxy, ...) can all run without hitting max pods.

Fix:
1. Identify the blocked node from `kubectl -n kube-system describe pod <pod-name>`. The pod will also be in pending state.
2. Check the new node's max pod capacity: `kubectl get node <node> -o jsonpath='{.status.capacity.pods}'`.
3. Raise the nodegroup instance size in terraform configuration
4. Rerun `terraform apply` to let the kube-proxy or other addon finish.
