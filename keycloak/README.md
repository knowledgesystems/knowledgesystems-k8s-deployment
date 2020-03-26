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

**Launch the Keycloak service via helm (DB credentials and keycloak.image properties should be set properly before running):**
```
$ helm install --name keycloak --set keycloak.image.repository=<IMAGE_REPOS> --set keycloak.image.tag=<IMAGE_TAG> --set keycloak.persistence.dbHost=<DB_HOSTNAME> --set keycloak.persistence.dbName=<DB_NAME> --set keycloak.persistence.dbUser=<DB_USER> --set keycloak.persistence.dbPassword=<DB_PASSWORD> -f keycloak-config.yaml codecentric/keycloak
```
Notes:
* keycloak-config.yaml can be found at [this location](./keycloak-config.yaml) in the repository.  After closer inspection of keycloak-config.yaml, you will find that it contains configuration for Ingress in addition to configuration for Keycloak.  It also makes the truststore available to the Keycloak application for SSL connections to AWS-RDS nodes.

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
