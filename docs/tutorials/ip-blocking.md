# IP Blocking
Due to certain regulations, we sometimes have to block access to our services for specific countries. This can be done by modifying the ingress helm values. The steps below shows how it was done for Genie instances of cBioPortal.

## Country-based IP Blocking for Genie cBioPortal
Append the following values to the [values file](https://github.com/knowledgesystems/knowledgesystems-k8s-deployment/blob/master/ingress/ingress_values.yml). Add/remove countries to the `http-snippet` depending on your requirements:
```yaml
controller:
  enableAnnotationValidations: false
  allowSnippetAnnotations: true
  config:
    annotations-risk-level: Critical
  maxmindLicenseKey: "<maxmindLicenseKey>"
  extraArgs:
    maxmind-edition-ids: GeoLite2-Country
config:
  use-geoip: "false"
  use-geoip2: "true"
  http-snippet: |
    map $geoip2_country_code $allowed_country {
      default yes;
      IR no;
      KP no;
      CU no;
      CN no;
      RU no;
      VE no;
    }
```
Apply the new helm values. Make sure you set the `maxMindLicenseKey` with your license key:
```shell
helm upgrade <release-name> ingress-nginx/ingress-nginx -f ingress/ingress_values.yml --set controller.maxmindLicenseKey=<license-key> --version <helm-chart-version>
```
Add `http-snippet` to the ingress rules that you want to block. For Genie portals, this was done by separating the ingress rules in its own file [here](https://github.com/knowledgesystems/knowledgesystems-k8s-deployment/blob/master/public-eks/cbioportal-prod/shared-services/ingress/genie-ingress.yml)