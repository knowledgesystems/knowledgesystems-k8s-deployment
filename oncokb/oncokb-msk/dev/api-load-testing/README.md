# OncoKB API Benchmarking

## Setup

### Deployment
1. Create a new managed nodegroup for testing purposes.
```
eksctl create nodegroup --config-file=oncokb/oncokb-msk/dev/api-load-testing/eksctl-nodegroup-config.yaml --profile=<AWS_PROFILE>
```
2. Deploy GN MongoDB
```
helm install gn-mongo-v0dot31 bitnami/mongodb --version 7.3.1 -f oncokb/oncokb-msk/dev/api-load-testing/gn_mongo_values.yaml
```
Note: Refer to GN [README.md](https://github.com/knowledgesystems/knowledgesystems-k8s-deployment/blob/master/genome-nexus/README.md) for most up to date deployment steps.
3. Deploy GN Spring Application
```
kubectl apply -f oncokb/oncokb-msk/dev/api-load-testing/gn_spring_boot.yaml
```
4. Deploy OncoKB Redis Cluster 
```
helm install oncokb-redis-cluster bitnami/redis-cluster --version 8.4.0 -f oncokb/oncokb-msk/dev/api-load-testing/oncokb_redis_cluster_values.yaml --set global.redis.password=<REDIS_PASSWORD>
```
5. Deploy OncoKB public and core pods
```
kubectl apply -f oncokb/oncokb-msk/dev/api-load-testing/oncokb_core.yaml
kubectl apply -f oncokb/oncokb-msk/dev/api-load-testing/public.yaml
```

### Redis Cache Configuration
Modify environment variable to enable/disable Redis: `"-Dredis.enable=<true | false>",`
