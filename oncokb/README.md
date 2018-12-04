# OncoKB

We use an external AWS MySQL db for OncoKB. Credentials are in
`portal-configuration/k8s-config-vars/oncokb/config_map.yaml`. To store the configmap in the cluster:

```bash
kubectl apply -f portal-configuration/k8s-config-vars/oncokb/config_map.yaml
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
