# Installing Prometheus

1. Add prometheus-community helm chart
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

2. Install kube-prometheus-stack
```
helm install oncokb-prometheus prometheus-community/kube-prometheus-stack -f oncokb/oncokb-eu/monitoring/kube_prometheus_stack_values.yaml
```