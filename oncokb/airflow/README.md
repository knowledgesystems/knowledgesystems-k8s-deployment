# OncoKB Airflow installation

### Install
```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install oncokb-airflow bitnami/airflow -f airflow/oncokb_airflow_values.yaml
```

### Upgrade with new values
```
helm upgrade oncokb-airflow bitnami/airflow -f airflow/oncokb_airflow_values.yaml
```

### Service Account
Some of our DAGs uses the [Kubernetes Client](https://github.com/kubernetes-client/python) for Python, which requires a ServiceAccount when accessing the K8s api. Modify the `oncokb-airflow-service-account` to give proper permissions.


