#!/bin/bash

# set env variables
export KOPS_STATE_STORE=s3://knowledgesystems-dev-k8s-store
export NAME=knowledgesystems.dev.k8s.local

kops delete cluster --state ${KOPS_STATE_STORE} --name ${NAME} --yes
aws s3api delete-bucket --bucket ${KOPS_STATE_STORE:5}

exit 0
