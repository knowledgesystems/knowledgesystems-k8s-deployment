## FAQs
### What if we see rate limit error when pulling docker image
We added docker-registry by following https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#add-imagepullsecrets-to-a-service-account  
We used oncokbbot account for the registry.
```
kubectl create secret docker-registry docker-oncokbbot \
        --docker-username=oncokbbot --docker-password=*** \
        --docker-email=dev.oncokb@gmail.com

kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "docker-oncokbbot"}]}'

```
