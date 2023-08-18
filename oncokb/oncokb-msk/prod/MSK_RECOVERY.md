# MSK Recovery Steps

This document provides detailed steps to recreate a new EKS cluster with all required apps running properly.

Before running the following steps, you need to have a EKS running with proper IAM assigned.
The following steps are based on MacOS. They will need to be adjusted in different OSs.

## Notes

- The kubernets should be v1.27

## Install Tools

- Install kubectl.
- Install eksctl. We use [eksctl](https://eksctl.io/) to create nodegroups.
- Install helm. We use [helm](https://helm.sh/) to install charts that have been prepackaged. Version: v3.5.2
- Install amazon ebs csi
  driver. https://github.com/knowledgesystems/knowledgesystems-k8s-deployment/tree/master/oncokb#install-amazon-ebs-csi-driver
- Create EKS
  nodegroup `eksctl create nodegroup --config-file=./infrastructure/eks-prod-cluster.yaml --include=large-general --profile saml`

## Include all credentials/configmaps

See required configmaps that included in the service config file. All configmaps are located
under https://github.com/knowledgesystems/oncokb-deployment/tree/master/credentails/configmaps/oncokb-msk/prod.

## Install Services

The following services are sorted by priority

### Ingress/Nginx

`helm install oncokb-ingress-nginx ingress-nginx/ingress-nginx`

### Redis

`helm install oncokb-redis-cluster -f redis/oncokb_redis_cluster_values.yaml bitnami/redis-cluster --version 8.4.0 --set password=<password>`

### oncokb-core-cbx

`kubectl apply -f ./oncokb_core_cbx.yaml`

### oncokb-core

`kubectl apply -f ./oncokb_core.yaml`

### oncokb-public

`kubectl apply -f ./oncokb_public.yaml`

### oncokb-curation

`kubectl apply -f ./oncokb_curation.yaml`

### Airflow

- Apply configmap `oncokb-airflow-requirements`: `kubectl apply -f ./airflow/oncokb_airflow_requirements.yaml`
- Apply service account `oncokb-airflow-requirements`: `kubectl apply -f ./airflow/oncokb_airflow_service_account.yaml`
- `helm install oncokb-airflow bitnami/airflow -f oncokb_airflow_values.yaml --set auth.password=<password> --version 14.0.17`
- Follow [INSTRUCTION](https://github.com/knowledgesystems/knowledgesystems-k8s-deployment/tree/master/oncokb/shared/airflow#oncokb-airflow-installation) to import connections.json and variables.json which located [HERE](https://github.com/knowledgesystems/oncokb-deployment/tree/master/credentails/configmaps/oncokb-prod/airflow) 

### Prometheus/Grafana

`helm install prometheus prometheus-community/kube-prometheus-stack --namespace=monitoring --set grafana.adminPassword=<password> --version 46.8.0`
