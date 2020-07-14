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

### Install
```bash
helm install --namespace=oncokb --name oncokb-public-redis stable/redis --set password=oncokb-public-redis-password --set cluster.enabled=true --set cluster.slaveCount=2 --set master.securityContext.enabled=false
```

### Delete
```
helm del --purge oncokb-public-redis -n
```
