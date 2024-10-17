# OncoKB Airflow Installation

## Deployment

### Step 1 - Setting up MySQL Database

1. `CREATE DATABASE oncokb_airflow CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`

2. Specify `explicit_defaults_for_timestamp=1`. Note: For MySQL8, this is the default

[Reference](https://airflow.apache.org/docs/apache-airflow/stable/howto/set-up-database.html#setting-up-a-mysql-database)

### Step 2 - Add Helm Repository

```
helm repo add airflow-stable https://airflow-helm.github.io/charts

helm repo update
```

### Step 3 - Install Airflow with proper values

We have Airflow running in MSK cluster and also Schultz Lab cluster. Each instance requires a slightly different configuration. Make sure to use the correct values.yaml

List of values to change depending on cluster deployment:

1. `dags.gitSync.repoPath`: Tells Airflow which path in repo to look for DAGs. We have `oncokb-airflow/oncokb/dags` for public cluster and `oncokb-airflow/oncokb/msk_dags` for MSK prod cluster
2. `externalDatabase.host`: AWS RDS host
3. `externalDatabase.userSecret` and `externalDatabase.passwordSecret`: Name of K8s secret containing database connection credentials
4. `airflow.config.AIRFLOW__WEBSERVER__BASE_URL`: Url for Airflow web. For public cluster use `https://airflow.oncokb.org`. If airflow is added to ingress file in other clusters, then change to appropriate URL.
5. `airflow.extraPipPackages`: Should be updated when our requirements.txt changes

Apply service account (if KubernetesPodOperator is used):

```
kubectl -n $AIRFLOW_NAMESPACE apply -f airflow/oncokb_airflow_service_account.yaml
```

After making the neccesary changes, install Helm chart:

```
helm install ${AIRFLOW_NAME} airflow-stable/airflow --version 8.9.0 --values path/to/values
```

To upgrade:

```
helm upgrade ${AIRFLOW_NAME} airflow-stable/airflow --version 8.9.0 --values path/to/values
```

### Step 4 - Access Airflow UI

If Airflow is exposed in Ingress file, skip this step. You can go directly to the URL. The following is useful for local deployments:

```
kubectl port-forward svc/${AIRFLOW_NAME}-web 8080:8080 --namespace $AIRFLOW_NAMESPACE
```

# Additional Information

## Service Account

Some of our DAGs uses the [Kubernetes Client](https://github.com/kubernetes-client/python) for Python, which requires a ServiceAccount when accessing the K8s api. Modify the `oncokb-airflow-service-account` to give proper permissions.

## Connections

Airflow provides [connections](https://airflow.apache.org/docs/apache-airflow/stable/howto/connection.html) for storing credentials and other information necessary for connecting to external services. The airflow-stable/airflow chart provides the `airflow.connections` value to specify a list of connections that will automatically synced into your airflow deployment. [More Information](https://github.com/airflow-helm/charts/blob/main/charts/airflow/docs/faq/dags/airflow-connections.md)

## Variables

Airflow [variables](https://airflow.apache.org/docs/apache-airflow/stable/howto/variable.html) are used to stored global variables and can store sensitive information by [masking](https://airflow.apache.org/docs/apache-airflow/stable/administration-and-deployment/security/secrets/mask-sensitive-values.html).
