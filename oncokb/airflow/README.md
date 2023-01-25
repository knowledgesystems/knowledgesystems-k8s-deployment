# OncoKB Airflow installation

## Install
```
kubectl apply -f airflow/oncokb_airflow_service_account.yaml

helm repo add bitnami https://charts.bitnami.com/bitnami
helm install oncokb-airflow bitnami/airflow -f airflow/oncokb_airflow_values.yaml --set auth.password=your-password
```

## Upgrade with new values
```
helm upgrade oncokb-airflow bitnami/airflow -f airflow/oncokb_airflow_values.yaml
```

## Authentication
Once this chart is deployed, it is not possible to change the application's access credentials, such as usernames or passwords, using Helm. To change these application credentials after deployment, delete any persistent volumes (PVs) used by the chart and re-deploy it.

### Airflow login credentials

`User:` admin

`Password:` your-password

## Service Account
Some of our DAGs uses the [Kubernetes Client](https://github.com/kubernetes-client/python) for Python, which requires a ServiceAccount when accessing the K8s api. Modify the `oncokb-airflow-service-account` to give proper permissions.

## Python requirements.txt
To install additional python packages, a configMap containing the requirements.txt should be created and mounted under `web.extraVolumes`, `scheduler.extraVolumes`, `worker.extraVolumes`. The airflow helm chart will run `pip install` automatically.


## Connections
Airflow provides [connections](https://airflow.apache.org/docs/apache-airflow/stable/howto/connection.html) to store credentials. However with bitnami/airflow helm chart, we are not able provide a configMap of all our connections on chart installation. The chart contributors have put this [feature](https://github.com/bitnami/charts/issues/5544) on hold, so we have to manually input these connections if we do a fresh chart installation. If the PVC for the database exists, then the connections will be persisted.


