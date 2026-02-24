# Traefik
We recently experienced issues with our nginx ingress controller that impacted service availability. See [incident report](../incidents-log/nginx-ingress-timeout-failure.md). As a result, we are in the process of migrating to Traefik as our ingress controller.

## Traefik Dashboard

Traefik provides a built-in dashboard for inspecting routers, middlewares, services, and plugins. It is not publicly exposed due to security concerns and must be accessed via port forwarding:

**Step 1:** Start the port-forward
```shell
kubectl port-forward -n traefik $(kubectl get pods -n traefik -l app.kubernetes.io/name=traefik -o name | head -1) 8080:8080
```

**Step 2:** Open your browser and navigate to:

```shell
# Note: The trailing slash is required.
http://localhost:8080/dashboard/
```
## Migrating an Ingress

When migrating an ingress from nginx to Traefik, remove the nginx-specific annotations and update the ingress class:

### Remove These Annotations

```yaml
# Remove all of these - they are nginx-specific and ignored by Traefik
nginx.ingress.kubernetes.io/proxy-body-size: 512m
nginx.ingress.kubernetes.io/proxy-connect-timeout: "300"
nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
nginx.ingress.kubernetes.io/proxy-send-timeout: "300"
nginx.ingress.kubernetes.io/ssl-redirect: "false"
ingress.kubernetes.io/proxy-body-size: 512m
ingress.kubernetes.io/proxy-connect-timeout: "300"
ingress.kubernetes.io/proxy-read-timeout: "300"
ingress.kubernetes.io/proxy-send-timeout: "300"
service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: '*'  # wrong resource
```

### Keep These Annotations

```yaml
# These are ingress-controller agnostic and still required
cert-manager.io/cluster-issuer: letsencrypt-prod
kubernetes.io/tls-acme: "true"
```

### Update the Ingress Class

```yaml
# Change from:
kubernetes.io/ingress.class: nginx

# To:
kubernetes.io/ingress.class: traefik
```

### Add cert-manager Solver Override

When switching an ingress to Traefik, add this annotation so cert-manager uses the correct solver for HTTP-01 challenges:

```yaml
acme.cert-manager.io/http01-ingress-class: traefik
```