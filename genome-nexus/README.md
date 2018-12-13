# Genome Nexus
Set up mongo database initialized with data from [gn-mongo image](https://hub.docker.com/r/genomenexus/gn-mongo/tags/):
```
helm install --version 4.9.1 --name gn-mongo-v0dot6 --set securityContext.enabled=false,image.repository=genomenexus/gn-mongo,image.tag=v0.6,persistence.size=20Gi stable/mongodb
```
Deploy genome nexus app:
```
kubectl apply -f gn_spring_boot.yaml
```
Expose as service (actual domain name binding is handled in [../ingress/README.md](../ingress/README.md):
```
kubectl apply -f service.yaml
```

## Sentry support
If you want to enable sentry, you need to provide it as a secret:
```
kubectl create secret generic genome-nexus-sentry-dsn --from-literal=dsn=https://sentry-key
```
It is referenced in the spring boot app [here](https://github.com/knowledgesystems/knowledgesystems-k8s-deployment/blob/master/genome-nexus/gn_spring_boot.yaml#L34-L38)

## VEP
Genome Nexus relies heavily on VEP. One can spin up their own version of VEP GRCh37 like this:

```
kubectl apply -f vep/gn_vep.yaml
```

It takes quite a while to start (~40m), because it downloads the VEP cache data
first.

## Notes
- alpine docker image doesn't play nice with kubernetes (https://twitter.com/inodb/status/999041628970127360)
- genome nexus mongo image doesn't work with chart version 4.0.0 https://github.com/helm/charts/commit/84fcbc5e6b79111baba54ff9593378cb34cae6b7
