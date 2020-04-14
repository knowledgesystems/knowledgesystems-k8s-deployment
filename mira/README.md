# Mira
Single Cell Visualization demo for HTAN. See also: https://shahcompbio-spectrum.netlify.com/docs/mira/deploy


## Elastic Search backend
Install on cBioPortal large-mem cluster for now
```
helm install --name elasticsearch elastic/elasticsearch --set imageTag=7.1.1 --set replicas=1 --set nodeSelector."kops\\.k8s\\.io/instancegroup"=large-mem --namespace mira
```

## Add other components
Add the other components: graphql, react frontend and ingress.
```
kubectl apply -f ingress_mira.yaml -f mira_graphql.yaml -f mira_react.yaml
```
