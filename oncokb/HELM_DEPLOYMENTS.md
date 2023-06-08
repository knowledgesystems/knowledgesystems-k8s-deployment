# OncoKB Helm Deployment

This documentation contains all information related to OncoKB Helm usage

## Helm tool version

OncoKB uses helm v3 to deploy all charts. Follow the [instructions](https://helm.sh/docs/intro/install/) to install helm v3.

## Helm chart versions

Below is a list of all charts with chart versions that OncoKB uses.

| Release name          | Chart name                               | Chart version |
| --------------------- | ---------------------------------------- | ------------- |
| oncokb-airflow        | [bitnami/airflow]                        | 14.0.17       |
| oncokb-redis-cluster  | [bitnami/redis-cluster]                  | 8.4.0         |
| oncokb-sentinel-redis | [bitnami/redis]                          | 14.8.4        |
| oncokb-grafana        | [grafana/grafana]                        | 6.12.1        |
| oncokb-keycloak       | [oncokb/keycloak]                        | 14.0.0        |
| oncokb-elasticsearch  | [oncokb/elasticsearch]                   | 7.13.3        |
| redisinsight          | [See here](#how-to-install-redisinsight) | 0.1.0         |

## FAQs

### How to install RedisInsight?

Please follow instructions [HERE](https://developer.redis.com/explore/redisinsight/usinghelm/#getting-started) to setup RedisInsight chart

### Why is there an oncokb chart repo?

The oncokb chart repo is located [HERE](https://github.com/oncokb/oncokb-helm-charts/tree/main) and contains two charts: `keycloak` and `elasticsearch`.

These charts were originally customized to work with our older k8 server version (v1.11).

However, since 6/2/2023, we have upgraded our k8 server version to v1.19. We should retire the oncokb helm charts and just use the original charts.

- `oncokb/keycloak` was customized based off [codecentric/keycloak]
- `oncokb/elasticsearch` was customized based off [elastic/elasticsearch]

[bitnami/airflow]: https://github.com/bitnami/charts/tree/main/bitnami/airflow
[bitnami/redis-cluster]: https://github.com/bitnami/charts/tree/main/bitnami/redis-cluster
[bitnami/redis]: https://github.com/bitnami/charts/tree/main/bitnami/redis
[grafana/grafana]: https://github.com/grafana/helm-charts/tree/main/charts/grafana
[oncokb/keycloak]: https://github.com/oncokb/oncokb-helm-charts/tree/main/charts/keycloak
[oncokb/elasticsearch]: https://github.com/oncokb/oncokb-helm-charts/tree/main/charts/keycloak
[codecentric/keycloak]: https://github.com/codecentric/helm-charts/tree/master/charts/keycloak
[elastic/elasticsearch]: https://github.com/codecentric/helm-charts/tree/master/charts/elasticsearch
