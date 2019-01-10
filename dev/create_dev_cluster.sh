#!/bin/bash

# set env variables
export KOPS_STATE_STORE=s3://knowledgesystems-dev-k8s-store
export NAME=knowledgesystems.dev.k8s.local

# AWS s3 bucket
aws s3api create-bucket --bucket ${KOPS_STATE_STORE:5}

# create cluster with kops
kops create cluster --state=${KOPS_STATE_STORE} --cloud=aws --zones=us-east-1d --node-count=2  --node-size=t2.medium --master-size=t2.medium ${NAME}

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

exit 0
