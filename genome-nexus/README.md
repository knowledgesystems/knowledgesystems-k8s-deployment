# Genome Nexus
**Create a namespace specific to genome nexus**
```
kubectl create namespace genome-nexus
```
**Create mongodb**
### Standalone instance
Set up mongo database initialized with data from [gn-mongo image](https://hub.docker.com/r/genomenexus/gn-mongo/tags/) and run specifically on genome nexus nodes.

If you are using helm v2:
```
helm install --name gn-mongo-v0dot25 --version 7.3.1 --set image.repository=genomenexus/gn-mongo,image.tag=0.25,persistence.size=100Gi bitnami/mongodb --namespace genome-nexus
```

If you are using helm v3:
```
helm install gn-mongo-v0dot25 bitnami/mongodb --version 7.3.1 --set image.repository=genomenexus/gn-mongo,image.tag=0.25,persistence.size=100Gi --namespace genome-nexus
```

**Troubleshooting**
If you are on a newer version of Bitnami, you might facing a problem that `mongodb` is not available in `index.yaml`. See https://github.com/bitnami/charts/issues/10539. 

Workaround for previous versions is manually using `helm repo add` to add full index
```
$ helm repo add bitnami-full-index https://raw.githubusercontent.com/bitnami/charts/archive-full-index/bitnami
"bitnami-full-index" has been added to your repositories
```
Then setting up database follow instructions above, remember to change `... bitnami/mongodb ...` to `... bitnami-full-index/mongodb ...`

### Replica set
1. Create a new replica set MongoDB
```
helm install gn-mongo-v0dot25 --version 7.3.1 --values=/path_to/gn_mongo_helm_values.yaml bitnami/mongodb --namespace genome-nexus
```

2. Export the MongoDB root password
```
export MONGODB_ROOT_PASSWORD=$(kubectl get secret --namespace genome-nexus genome-nexus-mongo-secret -o jsonpath="{.data.mongodb-root-password}" | base64 --decode)
```
This command will retrieve the MongoDB root password from the Kubernetes secret and set it as an environment variable.

3. Import data
Define MONGO_URI by running
```
export MONGO_URI="mongodb://root:$MONGODB_ROOT_PASSWORD@127.0.0.1:27017/annotator?authSource=admin"
```
Navigate to genome-nexus-importer
```
sh ./scripts/import_mongo.sh
```

4. Forward port to local
```
kubectl port-forward --namespace genome-nexus svc/gn-mongo-test-replica-mongodb 27017:27017
```
This command will forward the MongoDB port to the local machine, allowing local access to the MongoDB instance.
5. Restore data to the database
First run mongodump from existing database instances to make a copy of collections. 
`vep.annotation` collection is required because VEP limits how many queries you could send, vep.annotation contains VEP cache from previous annotations and reduces number of new variants send to VEP server. 
`index` collection provides quick responses for genome nexus website homepage search box, it doesn't affect other annotation jobs.

```
mongorestore --uri mongodb://root:${MONGODB_ROOT_PASSWORD}@127.0.0.1:27017/annotator?authSource=admin --db=annotator --collection=vep.annotation --writeConcern '{w:0}' --gzip /path_to/vep.annotation.bson.gz
```
6. Unset the environment variable
To unset the environment variable, execute the following command:
```
unset MONGODB_ROOT_PASSWORD
```

**Deploy genome nexus app**
Make sure your currently location is under `./genome_nexue/`
```
kubectl apply -f gn_spring_boot.yaml --namespace=genome-nexus
```

## Sentry support
If you want to enable sentry, you need to provide it as a secret:
```
kubectl create secret generic genome-nexus-sentry-dsn --from-literal=dsn=https://sentry-key --namespace=genome-nexus
```
It is referenced in the spring boot app [here](https://github.com/knowledgesystems/knowledgesystems-k8s-deployment/blob/master/genome-nexus/gn_spring_boot.yaml#L34-L38)

## VEP
Genome Nexus relies heavily on VEP. One can spin up their own version of VEP GRCh37 like this:

```
kubectl apply -f vep/gn_vep.yaml --namespace=genome-nexus
```

It takes quite a while to start (~10m), because it downloads the VEP cache data
from S3 first.

Note: we are currently only using our own VEP for the [GENIE instance of Genome
Nexus](./gn_genie.yaml).

## Genome Nexus GENIE instance
The GENIE Genome Nexus instance includes changes to the default configuration/steps.

### Setting Up Persistent Volume Claims
It uses persistent volume claims to store data (both the VEP cache data and mongo cache) and to ensure data persistence across restarts. These persistent volume claims must be created **before** installing the helm chart/or spinning up VEP. The deployment configurations for mongo/GENIE genome nexus specifically reference these existing persistent volume claims and will crash if they are not available.

To create persistent volumes for:

1. VEP FASTA cache (genie-vep-pvc): `kubectl apply -f vep/gn_vep_pvc.yaml`
2. GENIE Mongo (VEP annotation) cache (genie-gn-mongo-pvc): `kubectl apply -f mongo/genie_gn_mongo_pvc.yaml`
3. Additional backup from mongodump (genie-genome-nexus-mongodump-pvc): `mongo/genie_gn_mongodump_pvc.yaml`

### Spinning Up Mongo Database Cache
We are using the **bitnami/mongodb** helm chart to deploy our own mongodb docker image (**genome-nexus/gn-mongo**).

For more information on the helm chart options, refer to their documentation [here](https://github.com/bitnami/charts/tree/master/bitnami/mongodb).

For more information on our mongo docker image, refer to our documention [here](https://github.com/genome-nexus/genome-nexus-importer/blob/master/README.md).

We are currently using a frozen helm chart version 7.3.1 with mongodb v4.0.12. If upgrading mongodb or the helm chart version, make sure to keep releases in sync. For a list of helm chart and their corresponding app versions, run the following command:
```
helm search -l bitnami/mongodb
```

To spin up the mongo database, run the following command:
```
helm install --name genie-gn-mongo --version 7.3.1  --set image.repository=genomenexus/gn-mongo,image.tag=v0.12,persistence.size=50Gi bitnami/mongodb --namespace genome-nexus --set nodeSelector."kops\\.k8s\\.io/instancegroup"='genie-genome-nexus'
```

### Setting Up GENIE VEP
The primary difference in the GENIE version of VEP is the use of a persistent volume to preserve data across restarts. Initial startup will take ~10 minutes to download the cache from the S3 bucket onto the mounted persistent volume. Subsequent startups (e.g due to restarts) should take ~30 seconds due to the cache being persisted.

VEP cached data has been preloaded into an existing S3 bucket (genome-nexus-vep-data). In the event of a build update that changes the cache, a new version of the cache must be uploaded into the S3 bucket.

To set up a local instance of VEP, run:
```
kubectl apply -f vep/gn_vep.yaml --namespace=genome-nexus
```

For more information on our local VEP deployment, refer to documentation [here](https://github.com/genome-nexus/genome-nexus-vep/blob/master/README.md).

### Setting Up GENIE Genome Nexus
Starting up GENIE Genome Nexus:
```
kubectl apply -f gn_genie.yaml --namespace=genome-nexus
```

For more information on Genome Nexus, refer to documentation [here](https://github.com/genome-nexus/genome-nexus/blob/master/README.md).

### Setting Up Mongo Backups
In addition to storing data in persistent volumes, the GENIE Genome Nexus deployment also dumps and backs up the mongo cache on a weekly basis (once a week on Sunday). The mongo cache is dumped into a persistent volume and then uploaded to an S3 bucket. In the event a persistent volume is deleted, the dump can be used to manually restore the mongo cache.

Make sure the corresponding configmap is deployed (found in mercurial repo):
```
kubectl apply -f portal-configuration/k8s-config-vars/mongodb/genie_config_map.yaml
```

To deploy the mongodump cronjob:
```
kubectl apply -f cronjob/genie_gn_weekly_mongodump.yaml
```

## Upgrading database version

If you want to upgrade the version of the mongo database. First create a new database (same helm command as in the regular setup, but use the new mongo image). Then if you want to keep the VEP cache, one can copy over the cache using `mongodump`. Some example commands that might be helpful are below (note this is moving from version 0.16 to 0.17):

```
# connect to the newly initalized mongo container
kubectl exec  -it gn-mongo-v0dot17-mongodb-7d75667c58-g4flr --namespace=genome-nexus -- /bin/sh
# make a dump from the previous mongo database inside the new db container
mongodump --uri mongodb://gn-mongo-v0dot16-mongodb:27017/annotator?connectTimeoutMS=120000 --collection vep.annotation --gzip --out /tmp/v0d16-dump
# now restore the cache
mongorestore -d annotator -c vep.annotation --gzip /tmp/v0d16-dump/annotator/vep.annotation.bson.gz
# delete the dump
rm -rf /tmp/v0d16-dump
```

After that you can switch the `mongodb.uri` parameter in the genome nexus config. Might want to keep the old database running for a bit in case one needs to revert.

## Delete old database
If you are using helm v2 (e.g. delete `gn-mongo-v0dot15`):
```
helm del --purge gn-mongo-v0dot15
```

If you are using helm v3 (e.g. delete `gn-mongo-v0dot15`):
```
helm delete gn-mongo-v0dot15 --namespace=genome-nexus
```

## Notes
- alpine docker image does not play nice with kubernetes (https://twitter.com/inodb/status/999041628970127360)
- Genome Nexus mongo image doesn't work with chart version 4.0.0 (https://github.com/helm/charts/commit/84fcbc5e6b79111baba54ff9593378cb34cae6b7)

