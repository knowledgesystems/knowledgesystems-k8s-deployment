# Kubernetes deployment of Knowledge Systems Apps
## Create Kubernetes cluster on Amazon using Kops
See: [kops/README.md](kops/README.md)

## Initialize the Kubernetes cluster
### Helm Package Manager
We use [helm](https://github.com/kubernetes/helm) to deploy several services.
Set up helm with Role-based access control:

https://github.com/kubernetes/helm/blob/master/docs/rbac.md#role-based-access-control

## Knowledge Systems Group Apps
- [Genome Nexus](genome-nexus/README.md)

## Routing of Domain Names
We use nginx ingress to handle the routing to the services. See
[ingress/README.md](ingress/README.md).

## Monitoring
We use Prometheus for monitoring our apps. See
[monitoring/README.md](monitoring/README.md).
