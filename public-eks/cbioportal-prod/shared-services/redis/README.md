### Redis

| Dependency          | Version |
|---------------------|---------|
| helm                | 3.5.2   |
| k8s server          | 1.27+   |
| k8s client          | 1.27+   |
| redis chart version | 17.11.6 |
| redis app version   | 7.0.11  |

Notes:
* Please replace **REDIS_APP_NAME** and **REDIS_PASSWORD** before run the commands

#### Session Management

To manage user sessions we use one redis instance:

```bash
helm install REDIS_APP_NAME -f ./cbioportal_redis.yaml --version 17.11.6 --set auth.password=REDIS_PASSWORD bitnami/redis
```

#### Persistence Cache

To manage persistence caching of e.g. API responses and database queries in the backend we use another redis instance:

```bash
helm install REDIS_APP_NAME -f ./cbioportal_redis_replica.yaml --version 17.11.6 --set auth.password=REDIS_PASSWORD bitnami/redis
```
