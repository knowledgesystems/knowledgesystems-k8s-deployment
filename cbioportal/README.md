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

## Make a dump of the mongo data base in kubernetes
Port forward the database
```bash
kubectl port-forward  svc/cbioportal-session-service-mongo-mongodb   37017:27017
```
Then connect locally using Docker (this is using docker on Mac):
```bash
docker run -v $PWD:/local --rm -it mongo:3.6 mongodump --out /local/session-service-dump-20190207 --uri mongodb://docker.for.mac.localhost:37017/session_service
```

## cBioPortal backend

### Database

We are running a mysql database inside the cluster:

```bash
helm install -f cbioportal_mysql_db_values.yml --set mysqlRootPassword=picksomerootpasswordhere cbioportal-production-db stable/mysql
```
NOTE: downloading index.do for all studies went down from 2m to 30s by
playing with the mysql configuration, so be sure to use ours. There's an
article about setting the right `innodb_buffer_pool_size`:
https://scalegrid.io/blog/calculating-innodb-buffer-pool-size-for-your-mysql-server/

### Redis

#### session management
Notes:
* the current version of helm which is used at msk for this deployment in our public kubernetes cluster is v2.12.2 - if you are creating or upgrading the public cluster deployment, use this version of the helm client.
* the current version of helm which is used at msk for this deployment in our internal kubernetes cluster is v3.6.0 - if you are creating or upgrading the internal cluster deployment, use this version of the helm client.

To manage user sessions we use one redis instance: 

For the internal cluster:
```bash
helm install  --name cbioportal-redis stable/redis --set master.securityContext.enabled=false --set password=picksomeredispassword --set slave.securityContext.enabled=false --set cluster.enabled=false
```
For the public cluster:
```bash
helm2 install --name cbioportal-redis stable/redis --version 6.1.4 --set master.nodeSelector."kops\.k8s\.io/instancegroup"=mission-critical --set master.tolerations[0].key=dedicated,master.tolerations[0].operator=Equal,master.tolerations[0].value=mission-critical,master.tolerations[0].effect=NoSchedule --set master.securityContext.enabled=false --set password=picksomeredispassword --set slave.securityContext.enabled=false --set cluster.enabled=false
```
Notes:
* the public cluster has a dedicated instance group named 'mission-critical' which is specified in the nodeSelector argument for the public cluster and a taint toleration for 'dedicated: mission-critical' is also specified.

#### persistence cache 

To manage persistence caching of e.g. API responses and database queries in the backend we use another redis instance:

```bash
helm install -f redis_cache_values.yaml cbioportal-persistence-redis --version 12.8.3 bitnami/redis --set password=picksomeredispassword
```

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
