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


