# Attach a domain name to a service

This setup made using the following:

| Dependency    | Version |
| ------------- |---------|
| aws-cli       | 2.11.25 |
| helm          | 3.5.2   |
| k8s server    | 1.27+   |
| k8s client    | 1.27+   |
| ingress-nginx | 4.7.0   |
| cert-manager  | v1.12.0 |

For ingress to work, subnets must be tagged with the following: 

| Key                             | Value     |
| ------------------------------- | --------- |
| kubernetes.io/cluster/<name>    | shared    |
| kubernetes.io/role/elb          | 1         |
| kubernetes.io/role/internal-elb | 1         |


# Create a new domain
To create a new domain apart from the main one(cbioportal.org) is completely doable, and you would need the following components for it to work
- Certificate
- Ingress

## Certificate
See [oncokb_cert.yaml](oncokb_cert.yaml) for an example. We use ClusterIssuer, that's the main difference from the recommended yaml https://cert-manager.io/docs/usage/certificate/#creating-certificate-resources

Note:
- In order to have the cert to be validated by Let's Encrypt. You need to make sure the domain has been pointed to the new load balancer.

## Ingress
See [oncokb-ingress.yml](oncokb-ingress.yml) for an example.
