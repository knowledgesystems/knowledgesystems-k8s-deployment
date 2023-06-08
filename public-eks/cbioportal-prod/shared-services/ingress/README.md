# Attach a domain name to a service

This setup made using the following:

| Dependency    | Version     |
| ------------- | ----------- |
| aws-cli       | 2.11.25     |
| helm          | 2.5.2       |
| k8s server    | 1.27+       |
| k8s client    | 1.27+       |
| ingress-nginx | 4.7.0       |
| cert-manager  | v1.12.0     |

For ingress to work, subnets must be tagged with the following: 

| Key                             | Value     |
| ------------------------------- | --------- |
| kubernetes.io/cluster/<name>    | shared    |
| kubernetes.io/role/elb          | 1         |
| kubernetes.io/role/internal-elb | 1         |
