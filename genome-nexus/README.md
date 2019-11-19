# Genome Nexus
Create a namespace specific to genome nexus:
```
kubectl create namespace genome-nexus
```

Set up mongo database initialized with data from [gn-mongo image](https://hub.docker.com/r/genomenexus/gn-mongo/tags/) and run specifically on genome nexus nodes:
```
helm install --name gn-mongo-v0dot9 --version 3.0.4 --set image.repository=genomenexus/gn-mongo,image.tag=v0.9,persistence.size=50Gi stable/mongodb --n
amespace genome-nexus --set nodeSelector."kops\\.k8s\\.io/instancegroup"=genome-nexus
```
Deploy genome nexus app:
```
kubectl apply -f gn_spring_boot.yaml --namespace=genome-nexus
```

## Sentry support
If you want to enable sentry, you need to provide it as a secret:
```
kubectl create secret generic genome-nexus-sentry-dsn --from-literal=dsn=https://sentry-key --namespace=genome-nexus
```
It is referenced in the spring boot app [here](https://github.com/knowledgesystems/knowledgesystems-k8s-deployment/blob/master/genome-nexus/gn_spring_boot.yaml#L34-L38)

## VEP
Genome Nexus relies heavily on VEP. One can spin up their own version of VEP GRCh37 like this:

```
kubectl apply -f vep/gn_vep.yaml
```

It takes quite a while to start (~10m), because it downloads the VEP cache data
from S3 first.

## Notes
- alpine docker image doesn't play nice with kubernetes (https://twitter.com/inodb/status/999041628970127360)
- genome nexus mongo image doesn't work with chart version 4.0.0 https://github.com/helm/charts/commit/84fcbc5e6b79111baba54ff9593378cb34cae6b7
