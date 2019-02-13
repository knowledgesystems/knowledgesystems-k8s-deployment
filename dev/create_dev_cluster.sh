#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR=${DIR}/..

# set env variables
export KOPS_STATE_STORE=s3://knowledgesystems-dev-k8s-store
export NAME=knowledgesystems.dev.k8s.local

# AWS s3 bucket
aws s3api create-bucket --bucket ${KOPS_STATE_STORE:5}

# create cluster with kops
kops create cluster --state=${KOPS_STATE_STORE} --cloud=aws --zones=us-east-1d --node-count=2  --node-size=t3.large --master-size=t3.medium ${NAME}

# check whether cluster is ready
kops update cluster ${NAME} --yes
while true; do
    kops validate cluster
    exit_code=$?
    if [ "$exit_code" -eq 0 ]; then
        break
    else
        echo "Cluster not ready, retrying kops validate cluster in 30s"
        sleep 30s
    fi
done

kubectl apply -f $ROOT_DIR/helm/rbac-config.yaml
helm init --service-account tiller --wait
helm install -f $ROOT_DIR/ingress/ingress_values.yml --name dev-ingress stable/nginx-ingress

# if u want to use the ingress controller need to manually point the route53
# record domain name to the load balancer of the ingress

exit 0
