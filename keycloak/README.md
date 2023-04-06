# Keycloak

**Install the truststore as a secret into the k8s cluster.  The truststore contains required certificates for proper SSL connections to AWS-RDS nodes:**
```
kubectl create secret generic aws-rds-tls-jks --from-file=<TRUSTSTORE_FILE>
```
Notes:
* aws-rds-tls-jks can be found at [this location](./aws-rds-tls.jks) in the repository.

* AWS certificates within the truststore can be found at [this location](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html) in the AWS web site.

* Keycloak stores all configurations (except for custom login pages) within MySQL running on the AWS-RDS node.  Thus Keycloak configurations are persisted across pod deployments.

**Install the codecentric helm repos as described in [README.md](https://github.com/codecentric/helm-charts) on codecentric github:**
```
$ helm repo add codecentric https://codecentric.github.io/helm-charts
```
Notes:
* the current version of helm which is used at msk for this deployment in our public kubernetes cluster is v2.12.2 - if you are creating or upgrading the public cluster deployment, use this version of the helm client.
* the current version of helm which is used at msk for this deployment in our internal kubernetes cluster is v3.6.0 - if you are creating or upgrading the internal cluster deployment, use this version of the helm client.

**Launch the Keycloak service via helm (DB credentials and keycloak.image properties should be set properly before running):**
For the internal cluster (see note below about adjusting keycloak-config.yaml):
```
$ helm install --name keycloak --set keycloak.image.repository=<IMAGE_REPOS> --set keycloak.image.tag=<IMAGE_TAG> --set keycloak.persistence.dbHost=<DB_HOSTNAME> --set keycloak.persistence.dbName=<DB_DATABASE_NAME> --set keycloak.persistence.dbUser=<DB_USER> --set keycloak.persistence.dbPassword=<DB_PASSWORD> -f keycloak-config.yaml codecentric/keycloak
```
For the public cluster (see the note above about using keycloak v2.12.2):
```
helm install --name test-keycloak --version 9.0.1 --set DB_ADDR=<DB_HOSTNAME> --set DB_DATABASE=keycloak --set DB_USER=keycloak_user --set DB_PASSWORD=<DB_PASSWORD> --set KEYCLOAK_USER=keycloak --set KEYCLOAK_PASSWORD=<KEYCLOAK_PASSWORD> -f keycloak-config.yaml codecentric/keycloak
```

Notes:
* keycloak-config.yaml can be found at [this location](./keycloak-config.yaml) in the repository.  After closer inspection of keycloak-config.yaml, you will find that it contains configuration for Ingress in addition to configuration for Keycloak.  It also makes the truststore available to the Keycloak application for SSL connections to AWS-RDS nodes. This file also contains a nodeSelector setting and a taint tolerations setting which constrain the deployment to an instancegroup created using kops with the name 'mission-critical'. The cluster must contain an appropriate instance group of that name or you must modify or delete these settings from keycloak-config.yaml. Installations into the internal cluster should delete these settngs, or adjust them - look for node group 'essential-services' for example.

* The image referenced by the helm keycloak chart had to be modified to allow for a proper SSL channel between Keycloak and the AWS-RDS node (more information can be found in the [cbioportal-keycloak-dockerfile](./cbioportal-keycloak-dockerfile) in this repository).  Please use the following keycloak.image property values:
```
keycloak.image.repository=cbioportal/keycloak
keycloak.image.tag=cbioportal-keycloak-v1.0
```
* Custom login pages are packaged as Keycloak "themes" and made available via the use of extraInitContainers (see "Providing a Custom Theme" in [README.md](https://github.com/codecentric/helm-charts/tree/master/charts/keycloak) on codecentric github).  After cloning the repos and navigating to [this location](./) in the repos, the custom theme container image was made via the following docker commands:
```
docker build -f ./cbioportal-keycloak-custom-themes-dockerfile ./themes
docker tag <IMAGE_ID> cbioportal/keycloak:cbioportal-keycloak-custom-themes-v1.0
docker push cbioportal/keycloak:cbioportal-keycloak-custom-themes-v1.0 
```

* Custom login pages are created differently between Keycloak releases. We are currently using Keycloak 11 in the public cluster and Keycloak 12 in the eks cluster. Only the keycloak12-cbioportal theme is compatible with Keycloak 12. The other themes are only compatible with Keycloak 11. 
