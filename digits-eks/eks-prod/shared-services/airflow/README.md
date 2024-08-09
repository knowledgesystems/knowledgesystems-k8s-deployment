# CDSI Airflow

This folder contains the deployment files for the CDSI Airflow server. For more information, please see this Confluence document: https://mskconfluence.mskcc.org/display/CDSI/Airflow

Ingress files live separately at [`../ingress`](../ingress).

## Deployment
Follow the steps below to set up your own Airflow deployment for production or development purposes. Note that this deployment depends on AWS, Kubernetes, and Helm. 

1. Create a node group for your Airflow deployment. Our current deployment uses one `r5.xlarge` node.

2. Install Amazon EFS driver.  
This deployment requires a filesystem with ReadWriteMany access. If you already have the EFS driver installed, skip this step. Follow the user guide [here](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html) for installation. There are four steps involved: (1) [creating a role](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html#efs-create-iam-resources), (2) [installing the EFS plugin](https://docs.aws.amazon.com/eks/latest/userguide/creating-an-add-on.html), (3) [creating the EFS filesystem](https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/docs/efs-create-filesystem.md), and (4) [creating a storage class for EFS](https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/examples/kubernetes/dynamic_provisioning/README.md).  
creating IAM Role you need to have it prefixed with `userServiceRole` and point to permission boundary of `AutomationOrUserServiceRolePermissions`.
For the AWS CLI commands, add –-profile saml so it can locate the correct credentials.  
Update the spec.csi.volumeHandle  setting in pv.yaml  to the new filesystem ID. Re-mount the filesystem.  

	kubectl apply -f storage/pv.yaml -n airflow

3. Create Airflow namespace.
    ```
	export NAMESPACE=<airflow-namespace>
	kubectl create namespace $NAMESPACE
    ```

4. Route 53  
	Create entry under hosted zone cbioportal.aws.mskcc.org
	Create ingress and apply - modify to have correct URL

	kubectl apply -f $AIRFLOW_DEPLOYMENT/../ingress/airflow-ingress.yaml -n $NAMESPACE
	
5. Create secrets
	```
    # For NCI project
    kubectl create secret generic airflow-gcp-keyfile --from-file=gcp_key.json=$AIRFLOW_DEPLOYMENT/secrets/gcp_key.json -n $NAMESPACE

    # For DAGs that clone/commit/push to CDSI git repos (NCI)
	kubectl create secret generic airflow-git-secret --from-file=id_ed25519=$AIRFLOW_DEPLOYMENT/secrets/id_ed25519 --from-file=known_hosts=$AIRFLOW_DEPLOYMENT/secrets/known_hosts -n $NAMESPACE

    # For CDM project
	kubectl create secret generic airflow-hpc3-ssh-keyfile --from-file=id_rsa=$AIRFLOW_DEPLOYMENT/secrets/id_rsa -n $NAMESPACE
    ```

6. Modify `override-values.yaml`
    ```
    webserver:
        base_url: <airflow-server-url>
    ```

    ```
    nodeSelector:
        eks.amazonaws.com/nodegroup: <airflow-nodegroup>
    ```

7. Install Airflow Helm chart
	```
    helm repo add apache-airflow https://airflow.apache.org
	helm repo update
    helm install -f $AIRFLOW_DEPLOYMENT/values.yaml -f $AIRFLOW_DEPLOYMENT/override-values.yaml airflow apache-airflow/airflow --namespace $NAMESPACE --debug --timeout 10m
    ```

8. Setup the DataDog agent.
	https://docs.datadoghq.com/containers/kubernetes/installation/?tab=datadogoperator
	https://docs.datadoghq.com/integrations/airflow/?tab=containerized
    Modify datadog-agent.yaml to point to correct url
	
    ```
	# Create namespace to separate datadog pods from other deployments
    export MONITORING_NS=<monitoring_namespace>

    helm repo add datadog https://helm.datadoghq.com
	helm install datadog-operator datadog/datadog-operator -n $MONITORING_NS --create-namespace
	kubectl create secret generic datadog-secret -n $MONITORING_NS --from-literal api-key=<api-key>

	kubectl apply -n $MONITORING_NS -f datadog-agent.yaml
    ```
	
	
