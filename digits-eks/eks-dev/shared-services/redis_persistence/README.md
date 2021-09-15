# Installing redis persistence cache on the production eks cluster

A command of this form can be used to install redis on the eks production cluster. (Note : valid kubectl session/context is needed with saml login)

```helm install cbioportal-persistence-redis bitnami/redis --version 14.4.0 -f /data/portal-cron/git-repos/knowledgesystems-k8s-deployment/digits-eks/eks-prod/shared-services/redis_persistence/redis_persistence_helm_install_values.yaml --set auth.password="YOUR_PASSWORD_FOR_REDIS_GOES_HERE" --set replica.replicaCount=1```
