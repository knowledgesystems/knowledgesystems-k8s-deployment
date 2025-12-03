#!/bin/bash

# Start timer
start=$(date +%s)

# Define namespace, master and slave pod prefixes
namespace="default"

# msk portal
msk_deployment_prefix="eks-msk-persistence-redis"
#public_deployment_prefix="cbioportal-public-persistence-redis"
# password here or from env variables
password=""

# Function to clear redis cache
clear_redis_cache() {
  deployment_prefix=$1
  pods=$(kubectl get pods -n $namespace -l "app.kubernetes.io/instance=$deployment_prefix" -o jsonpath="{.items[*].metadata.name}")

  for pod in $pods
  do
    if [[ $pod == *"master"* ]]; then
      echo "Clearing cache for $pod"
      kubectl exec -n $namespace $pod -- redis-cli -a $password FLUSHALL
    fi
  done
}

# Clear cache for master pods
clear_redis_cache $msk_deployment_prefix
#clear_redis_cache $public_deployment_prefix
# End timer
end=$(date +%s)

# Calculate and print time taken
time_taken=$((end-start))
echo "Time taken: $time_taken seconds"

# Print success message
echo "Redis cache cleared successfully!"
