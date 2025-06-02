## oncokb_redis_cluster_values.yaml
Install redis cluster through helm  
`helm install oncokb-redis-cluster bitnami/redis-cluster --version 8.4.0 --set password=pwd -f oncokb_redis_cluster_values.yaml -n [default|namespace]`
## redis insight
https://docs.redis.com/latest/ri/installing/install-k8s/#helm-chart-experimental

## Note:

The minimum setup is 3 master nodes with 0 replicas. This is the setup we use for beta. If your cluster is failing to create, try the following steps to debug:

1. Obtain the IP of each redis cluster pod using `kubectl get pods -l app.kubernetes.io/instance=<your value here> -o json | jq -r '.items | map(.status.podIP + ":6379") | join(" ")''.
2. Exec into one of the redis cluster pods.
3. Attempt to create the cluster using `redis-cli --create cluster --cluster-replicas <NUM_REPLICAS> 1 <IPS_FROM_STEP_1>.
4. Observe the reason for failure. 

### Redis database configuration usually looks like
Host: oncokb-redis-cluster  
Port: 6379  
Name: oncokb-redis-cluster  
Username: (default, leave it empty)  
Password:   
