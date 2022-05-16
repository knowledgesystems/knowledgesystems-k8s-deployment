# OncoKB Keycloak

### Keycloak service

Since our Kubernetes server version is not compatible with codecentric keycloak helm chart, we modified their keycloak chart and the chart is located at: https://github.com/oncokb/oncokb-helm-charts.

Add oncokb helm chart repo.

```
helm repo add oncokb https://oncokb.github.io/oncokb-helm-charts/releases
```

In `keycloak.config.yaml` adjust the DB env variables to connect to an existing database. 

One way to start a MySQL database is with helm


```
helm install keycloak-mysql --set auth.rootPassword=root,auth.database=keycloak bitnami/mysql
```

Create a keycloak service with `keycloak-config.yaml` configuration file.

```
helm install keycloak -f ./keycloak-config.yaml oncokb/keycloak
```

#### Custom themes

Keycloak allows you to add your own themes. [[Documentation]](https://www.keycloak.org/docs/latest/server_development/#_themes)

**Applying the custom theme**

- Our custom theme images can be found on [Dockerhub](https://hub.docker.com/r/oncokb/keycloak). You can change the image version in `extraInitContainers`.
- To apply the theme go to **keycloak admin console** > **themes tab** > **change login theme to `keycloak-oncokb`**

**Steps for creating a new theme**

- [Tutorial](https://www.baeldung.com/spring-keycloak-custom-themes) for creating custom theme.
- Follow the steps from codecentric's [README](https://github.com/codecentric/helm-charts/tree/master/charts/keycloak#providing-a-custom-theme) for creating a custom theme.
