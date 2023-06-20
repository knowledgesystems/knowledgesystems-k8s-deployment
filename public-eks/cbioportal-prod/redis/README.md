### Redis

#### Session Management

| Dependency    | Version |
| ------------- |---------|
| helm          | 3.6.0+  |
| k8s server    | 1.27+   |
| k8s client    | 1.27+   |

Notes:
* the current version of helm which is used at msk for this deployment in our public kubernetes cluster is v3.12.0 - if you are creating or upgrading the public cluster deployment, use this version of the helm client.
* the current version of helm which is used at msk for this deployment in our internal kubernetes cluster is v3.6.0 - if you are creating or upgrading the internal cluster deployment, use this version of the helm client.

To manage user sessions we use one redis instance:

For the internal/public cluster:
```bash
helm install cbioportal-redis -f cbioportal/redis/cbioportal_redis.yaml --version 12.8.3 --set auth.password=picksomeredispassword oci://registry-1.docker.io/bitnamicharts/redis
```
Notes:
* the public cluster has a dedicated instance group named 'mission-critical' which is specified in the nodeSelector argument for the public cluster and a taint toleration for 'dedicated: mission-critical' is also specified.

#### Persistence Cache

To manage persistence caching of e.g. API responses and database queries in the backend we use another redis instance:

```bash
helm install cbioportal-genie-persistence-redis -f public-eks-cluster/redis/cbioportal_redis_replica.yaml --version 17.11.6 --set auth.password=picksomeredispassword oci://registry-1.docker.io/bitnamicharts/redis
```
