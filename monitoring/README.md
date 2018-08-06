# Monitoring
We use Prometheus Operator for metrics:

Add the helm repo:
```
helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/
```
Then
```
helm install coreos/prometheus-operator --name prometheus-operator --namespace monitoring
helm install -f kube_prometheus_values.yml coreos/kube-prometheus --name kube-prometheus --namespace monitoring
```
If you want to add new monitors, update the `kube_prometheus_values.yml` file and do:
```
helm upgrade -f kube_prometheus_values.yml coreos/kube-prometheus --name kube-prometheus
```
