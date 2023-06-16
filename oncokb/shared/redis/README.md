## oncokb_redis_cluster_values.yaml
Install redis cluster through helm  
`helm install oncokb-redis-cluster bitnami/redis-cluster --version 8.4.0 --set password=pwd -f oncokb_redis_cluster_values.yaml -n [default|namespace]`
## redis insight
https://docs.redis.com/latest/ri/installing/install-k8s/#helm-chart-experimental

### Redis database configuration usually looks like
Host: oncokb-redis-cluster  
Port: 6379  
Name: oncokb-redis-cluster  
Username: (default, leave it empty)  
Password:   
