#!/bin/bash

set -euo pipefail

VERSION=$1

IMAGE_NAME=cbioportal/airflow-server:$VERSION
TARGET_PLATFORM=linux/amd64

docker buildx build --platform=$TARGET_PLATFORM -t "$IMAGE_NAME" .
docker login
docker push $IMAGE_NAME
