#!/bin/bash

set -euo pipefail

IMAGE_NAME=jamesko0/cmo-airflow:2.9.2
TARGET_PLATFORM=linux/amd64
DOCKER_HUB_IMG=jamesko0/cmo-airflow:2.9.2

docker buildx build --platform=$TARGET_PLATFORM -t "$IMAGE_NAME" .
docker login
docker push $DOCKER_HUB_IMG
