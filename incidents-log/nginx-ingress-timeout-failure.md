# Nginx-Ingress Timeout Failure

**Incident Date: 2026/02/12**

- Issue reported around 1:30 PM when nginx-ingress stopped working in the EKS cluster.
- All services, deployments, and apps were functioning correctly when accessed via port-forwarding.
- Nginx ingress controller logs showed traffic being received.
- DNS nameservers and CNAME records for all domains/subdomains were correct.
- Uptime Robot reported Connection Timeout Errors across all monitored domains/subdomains.
- Manual domain access (e.g., www.cbioportal.org) showed significant delays - some domains eventually resolved after a minute or more, while most timed out.
- No error logs were found at the load balancer, ingress, or application level.
- The issue manifested as a significant delay between DNS resolution to the load balancer and the request being returned to the user.

## Remediation

### Attempted Solutions
- Debugging nginx-ingress: No errors or anomalies found in logs.
- Port-forwarding verification: All services/deployments/apps confirmed working.
- DNS verification: All CNAME records confirmed correct.
- Purging and recreating nginx-ingress deployment including load balancer: Did not resolve the issue.

### Final Solution
- Deployed Traefik as an alternative ingress controller.
- Traffic now served through Traefik proxy layer instead of nginx-ingress.
- All services returned to normal operation.

## Root Cause
The exact cause of the nginx-ingress failure remains unknown. The issue was characterized by:
- No visible errors in logs at any level (load balancer/ingress/application).
- Significant latency between DNS resolution and request completion.
- nginx-ingress helm chart appeared to be the source, but specific failure point was not identified.

## Future Prevention
- Currently investigating disaster recovery options and backup strategies.
- Considering implementing multiple ingress controller options for faster failover.
