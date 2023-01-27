# OncoKB Airflow Installation

## Deployment
1. Install helm chart
    ```
    kubectl -n oncokb apply -f airflow/oncokb_airflow_service_account.yaml
    kubectl -n oncokb apply -f airflow/oncokb_airflow_requirements.yaml

    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm -n oncokb install oncokb-airflow bitnami/airflow -f airflow/oncokb_airflow_values.yaml --set auth.password=your-password
    ```

2. Add Airflow connections

    * Option A: Go to  `https://{airflow-host}/connection/list/` and manually add all connections.
    * Option B: Use the airflow cli
        ```
        # Copy connections.json from local to pod
        kubectl -c airflow-web cp ~\local-path-to-credentials {namespace}/{airflow-web-pod}:/tmp/credentials.json

        kubectl -n oncokb -c airflow-web exec -it {airflow-web-pod} -- /bin/sh

        Inside pod:
        $ airflow connections import /tmp/credentials.json
        $ rm /tmp/credentials.json
    
    The connections json file should conform to the following format:
    ```
    {
        "connection_id": {
            "conn_type": "",
            "description": "",
            "login": "",
            "password": "",
            "host": "",
            "port": 9000,
            "schema": "",
            "extra": ""
        }
    }
    ```

3. Add Airflow variables 
    
    * Option A: Go to `https://{airflow-host}/variable/list/` and import your `variables.json` file using the UI.
    * Option B: Use same procedure as import airflow connections. The only difference is that the command is
        ```
        airflow variables import /tmp/variables.json
        ```
    

    The variables json file should comform to the following format:
    ```
    {
        "key1" : "value1",
        "key2": "value2"
    }
    ```

## Upgrade with new values
```
helm upgrade oncokb-airflow bitnami/airflow -f airflow/oncokb_airflow_values.yaml
```

# Additional Information

## Airflow login credentials

Get your Airflow login credentials by running:
```
export AIRFLOW_PASSWORD=$(kubectl get secret --namespace "default" oncokb-airflow -o jsonpath="{.data.airflow-password}" | base64 -d)
echo User:     admin
echo Password: $AIRFLOW_PASSWORD
```

## Authentication
Once this chart is deployed, it is not possible to change the application's access credentials, such as usernames or passwords, using Helm. To change these application credentials after deployment, delete any persistent volumes (PVs) used by the chart and re-deploy it.

## Service Account
Some of our DAGs uses the [Kubernetes Client](https://github.com/kubernetes-client/python) for Python, which requires a ServiceAccount when accessing the K8s api. Modify the `oncokb-airflow-service-account` to give proper permissions.

## Python requirements.txt
To install additional python packages, a configMap containing the requirements.txt should be created and mounted under `web.extraVolumes`, `scheduler.extraVolumes`, `worker.extraVolumes`. The airflow helm chart will run `pip install` automatically.

## Connections
Airflow provides [connections](https://airflow.apache.org/docs/apache-airflow/stable/howto/connection.html) for storing credentials and other information necessary for connecting to external services. However with bitnami/airflow helm chart, we are not able provide a configMap of all our connections on chart installation. The chart contributors have put this [feature](https://github.com/bitnami/charts/issues/5544) on hold, so we have to manually input these connections if we do a fresh chart installation. If the PVC for the database exists, then the connections will be persisted since they are stored in a DB table.

## Variables
Airflow [variables](https://airflow.apache.org/docs/apache-airflow/stable/howto/variable.html) are used to stored global variables and can store sensitive information by [masking](https://airflow.apache.org/docs/apache-airflow/stable/administration-and-deployment/security/secrets/mask-sensitive-values.html).


