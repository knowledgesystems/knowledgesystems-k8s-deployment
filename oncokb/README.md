# OncoKB

Create a namespace specific to genome nexus:
```
kubectl create namespace oncokb
```

We use an external AWS MySQL db for OncoKB. Credentials are in
`portal-configuration/k8s-config-vars/oncokb/config_map.yaml`. To store the configmap in the cluster:

```bash
kubectl apply -f portal-configuration/k8s-config-vars/oncokb/config_map.yaml --namespace=oncokb
```

To deploy OncoKB once the database has been initialized (see [Init or Update AWS db](#Init-or-Update-AWS-db)):

```bash
kubectl apply -f oncokb.yaml
```

## Init or Update AWS db

From OncoKB repo run:

```bash
cat ./core/src/main/resources/spring/database/oncokb.sql | \
    mysql -h MYSQL_HOST -u MYSQL_USER  -pMYSQL_PASSWORD ONCOKB_DB
```

## Notes

- The caching on boot takes quite a while which is why we need the long livenessProbe/readinessProbe.

## OncoKB Public Redis
## Sentinel
### Install
```bash
helm install -f oncokb_sentinel_redis_cache_values.yaml --namespace=oncokb oncokb-sentinel-redis bitnami/redis --set auth.password=oncokb-public-redis-password
```

### Delete
```
helm del --purge oncokb-public-redis -n
```

### Grafana Redis Config
Name: OncoKB Sentinel Redis  
Address: redis://oncokb-sentinel-redis-headless:26379  
Master Name: oncokb-master  
Passwords are the same for Redis and Sentinel sections  