# Airflow Custom Docker Image

This directory contains the files needed to build a custom Airflow image that extends the
official `apache/airflow:2.9.2` base image with additional binaries and Python dependencies.

## What's added to the new image

- **saml2aws** — CLI tool for authenticating with AWS via SAML SSO
- **Python deps** — see `requirements.txt`

## Building the image

```bash
docker build -t youruser/airflow-custom:2.9.2 .
```

## Pushing to Docker Hub

```bash
docker login
docker push youruser/airflow-custom:2.9.2
```

## Using the image

Update `values.yaml`:

```yaml
images:
  airflow:
    repository: youruser/airflow-custom
    tag: 2.9.2
    pullPolicy: IfNotPresent
```

## Updating dependencies

Add packages to `requirements.txt`, bump the image tag, rebuild, and push.
