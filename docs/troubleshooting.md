---
icon: tools
---
# Troubleshooting
This list is used to track issues and their remedies.

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
