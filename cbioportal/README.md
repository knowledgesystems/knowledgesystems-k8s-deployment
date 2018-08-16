# cBioPortal

## Session service

Set up mongo database:

```bash
helm install --name cbioportal-session-service-mongo --set persistence.size=10Gi stable/mongodb
```

Deploy session service app:

```bash
kubectl apply -f session-service/session_service.yaml
```

### How to migrate one mongo database to mongo db in kubernetes

Run on the database you'd like to copy (change `${}` variables accordingly):

```bash
mongodump \
    --db ${DB_NAME} \
    -u ${ADMIN_USER} \
    -p ${ADMIN_PASSWORD} \
    --authenticationDatabase ${AUTH_DATABASE_IF_DIFF_THEN_DEFAULT} \
    --out ${OUTPUT_FOLDER}
```

Then copy the output folder to the contaier

```bash
kubectl cp  \
    ${OUTPUT_FOLDER} \
    ${MONGO_CONTAINER_NAME}:/bitnami/mongodb/mongo-session-service-dump
```

NOTE: you can get the ${MONGO_CONTAINER_NAME} by looking
at the output from `kubectl get po`.

Then import the database

```bash
# start bash shell in the container
kubectl exec -it  ${MONGO_CONTAINER_NAME} /bin/bash
# inside the container
mongorestore \
    --authenticationDatabase admin \
    -u root \
    -p ${MONGODB_ROOT_PASSWORD} \
    --db ${DB_NAME} \
    --drop \
    /bitnami/mongodb/mongo-session-service-dump/${DB_NAME}
# you can get the mongodb root password from the helm chart
# helm status cbioportal-session-service-mongo
```

Once completed you can delete the dump again:

```bash
rm -rf /bitnami/mongodb/mongo-session-service-dump
```

## cBioPortal backend

### Database

We are running a mysql database inside the cluster:

```bash
helm upgrade --install -f cbioportal_mysql_db_values.yml cbioportal-prod-db   stable/mysql
```
NOTE: downloading index.do for all studies went down from 2m to 30s by
playing with the mysql configuration, so be sure to use ours. There's an
article about setting the right `innodb_buffer_pool_size`:
https://scalegrid.io/blog/calculating-innodb-buffer-pool-size-for-your-mysql-server/

### Configuration

To set up the configuration values one needs access to the
portal-configuration portal (this only needs to be done when configuration
changes). Then one can create the config maps:

```bash
kubectl apply -f portal-configuration/k8s-config-vars/public/config_map.yaml
```

For now we only allow changing a few runtime properties that aren't in the
default `portal.properties.EXAMPLE` file of the repo.

```bash
kubectl apply -f cbioportal_spring_boot.yaml
kubectl apply -f service.yaml
```