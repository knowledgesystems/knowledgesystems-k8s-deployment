# CDSI Airflow

This folder contains the deployment files for the CDSI Airflow server. For more detailed information, please see this Confluence document: https://mskconfluence.mskcc.org/display/CDSI/Airflow.

## Deployment
Follow the steps below to set up your own Airflow deployment for production or development purposes. Note that this deployment depends on AWS, Kubernetes, and Helm. 

1. Create a node group for your Airflow deployment. Our current deployment uses one `r5.xlarge` node. Modify `override-values.yaml` to point to the correct node group:
    ```
    nodeSelector:
        eks.amazonaws.com/nodegroup: <airflow-nodegroup>
    ```

2. Create an Airflow namespace.
    ```
	export NAMESPACE=<airflow-namespace>
	kubectl create namespace $NAMESPACE
    ```

3. Set up EFS storage.   
This deployment requires a filesystem with ReadWriteMany access for log persistence, DAG persistence, and use of shared volumes. If you already have the EFS driver installed or do not require ReadWriteMany filesystem access, skip this step and remove references to EFS storage from `override-values.yaml`.  
Follow the user guide [here](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html) for EFS driver installation. There are four steps involved:  
    1.  [Create a role](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html#efs-create-iam-resources). Note that when creating an IAM role on a DigITs-provisioned AWS account, you must prefix the role name with `userServiceRole` and point to the permission boundary of `AutomationOrUserServiceRolePermissions`.  
    2. [Install the EFS plugin](https://docs.aws.amazon.com/eks/latest/userguide/creating-an-add-on.html). Add `–-profile <your-aws-profile>` to the AWS commands to locate the correct credentials.    
    3. [Create the EFS filesystem](https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/docs/efs-create-filesystem.md). Add `–-profile <your-aws-profile>` to the AWS commands to locate the correct credentials. Store the filesystem ID for use in the next step.  
    4. [Create a storage class for EFS](https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/examples/kubernetes/dynamic_provisioning/README.md). You can use our `storage/storageclass.yaml` as a template, but you must update `parameters.fileSystemId` to the filesystem ID you created in the previous step.

4. Allocate persistent volume storage.  
This deployment requires persistent storage for GitHub repo access. If your deployment does not require persistent volume storage, skip this step and remove references to persistent volumes in `override-values.yaml`.  
Before running the below commands, update the `spec.csi.volumeHandle` setting in `pv.yaml` to the filesystem ID from the previous step.  
    ```
    kubectl apply -f storage/pv.yaml -n $NAMESPACE
    kubectl apply -f storage/pvc.yaml -n $NAMESPACE
    ```
	
5. Create secrets.  
The below secrets are required for running the NCI and CDM DAGs. The referenced secrets file is located in the portal-configuration repository.
	```
    kubectl apply -f portal-configuration/k8s-config-vars/digits-eks/eks-prod/airflow-secrets.yaml
    ```

6. Set up networking.  
In the AWS Route 53 Dashboard, create an entry under the desired hosted zone (For production, `cbioportal.aws.mskcc.org`):
    - For `Record Name`, enter the desired URL.
    - For `Record Type`, choose `CNAME`. 
    - For `Value`, enter the URL of the desired load balancer.  

7. Apply the ingress.  
The production ingress file is located at `../ingress/eks-airflow-ingress.yaml`. If you are deploying an Airflow server on the development AWS cluster, use the `digits-eks/eks-dev/shared-services/ingress/airflow-ingress.yaml` file instead. Before running the below command, modify the relevant ingress file to point to the correct URL for your Airflow server.
    ```
	kubectl apply -f ../ingress/eks-airflow-ingress.yaml -n $NAMESPACE
    ```

8. Modify `webserver.base_url` in `override-values.yaml` to reflect the desired URL of the Airflow server. This is required for email notifications to work correctly.
    ```
    webserver:
        base_url: <airflow-server-url>
    ```

9. Install the Airflow Helm chart.
	```
    helm repo add apache-airflow https://airflow.apache.org
    helm repo update
    helm install -f override-values.yaml airflow apache-airflow/airflow --namespace $NAMESPACE --debug --timeout 10m
    ```

10. Setup the DataDog agent.  
We monitor our Airflow deployment using MSK's [DataDog instance](https://app.datadoghq.com/apm/home). Refer to the DataDog documentation for more information on [installation](https://docs.datadoghq.com/containers/kubernetes/installation/?tab=datadogoperator) and [Airflow integration](https://docs.datadoghq.com/integrations/airflow/?tab=containerized).
Before running the below steps, modify `datadog-agent.yaml` to point to the correct URL for your Airflow server.
	
    ```
	# Create namespace to separate DataDog pods from other deployments
    export MONITORING_NS=<monitoring_namespace>

    helm repo add datadog https://helm.datadoghq.com

    # Deploy datadog-operator
	helm install datadog-operator datadog/datadog-operator -n $MONITORING_NS --create-namespace

    # Deploy DataDog agents
    kubectl create secret generic datadog-secret -n $MONITORING_NS --from-literal api-key=<api-key>
	kubectl apply -n $MONITORING_NS -f datadog-agent.yaml
    ```
	
	
