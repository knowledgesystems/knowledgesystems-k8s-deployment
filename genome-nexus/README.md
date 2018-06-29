# Genome Nexus
Set up mongo database initialized with data from [gn-mongo image](https://hub.docker.com/r/genomenexus/gn-mongo/tags/):
```
helm install --name gn-mongo-v0dot3 --set image.repository=genomenexus/gn-mongo,image.tag=v0.3,persistence.size=20Gi stable/mongodb
```
Deploy genome nexus app:
```
kubectl apply -f gn_spring_boot.yaml
```
Expose as service (actual domain name binding is handled in [../ingress/README.md](../ingress/README.md):
```
kubectl apply -f service_ingress.yml
```

## Sentry support
If you want to enable sentry, you need to provide it as a secret:
```
kubectl create secret generic genome-nexus-sentry-dsn --from-literal=dsn=https://sentry-key
```

## Notes
- alpine docker image doesn't play nice with kubernetes (https://twitter.com/inodb/status/999041628970127360)
