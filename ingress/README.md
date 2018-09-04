# Attach a domain name to a service
We use the nginx-ingress controller:
```
helm install -f ingress_values.yml  --name eating-dingo   stable/nginx-ingress
```
Then for ssl certificates use [cert-manager](https://github.com/kubernetes/charts/tree/master/stable/cert-manager):
```
helm install --name cert-manager-release -f cert-manager-values.yaml stable/cert-manager --namespace kube-system
```
Once that's up create the certificate issuer:
```
kubectl apply -f letsencrypt-clusterissuer-production.yaml
```
Then get the certificates
```
kubectl apply -f certificate.yml
```
If all the output looks correct in the pods. One can run the following ingress:
```
kubectl apply -f ingress.yml
```
# Forward to apps running internally
For some of our private cbioportal instances we were using URLs such as
www.cbioportal.org/name. To forward all those to e.g. name.cbioportal.org there
are a bunch of ingress files available in portal-configuration:
```
kubectl apply -f ../portal-configuration/k8s-private-portal-forwarding
```
