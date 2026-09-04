# Slide viewer tile-server operations

The tile server is a source-bound pixel service. cBioPortal remains the owner
of WSI hierarchy and slide-access metadata; the tile server receives an exact
source URL and short-lived capability from the backend.

## Development capacity controls

- Beta runs two warm replicas with a disruption budget that keeps one pod
  available during voluntary maintenance. The dedicated node group keeps a
  two-node steady-state floor and a four-node ceiling; scale to the ceiling
  manually for an announced load event until workload autoscaling is added.
  Gunicorn worker count and the remaining runtime settings come from the
  private ConfigMap/environment.
- The checked-in container manifest reserves 8Gi and caps memory at 16Gi per
  pod. CPU and ephemeral-storage requests/limits remain unset until sustained
  production load establishes realistic values.
- Pods select and tolerate `workload=tile-viewer`. That node group is managed
  outside this repository and must exist before the Argo Application is synced.
- `MAX_IMAGE_OPERATIONS=2` bounds blocking tile/thumbnail work per worker;
  two replicas and two Gunicorn workers provide eight bounded image
  operation slots across beta.
- `CACHE_MISS_RATE_LIMIT_PER_MINUTE` is a shared Redis sliding-window limit
  for extraction leaders per capability subject and source. Redis cache hits
  are not application-rate-limited.
- Redis locks coalesce identical cache misses across workers and replicas.
- Cold-read guardrails use a renewable 120-second distributed lock lease, a
  30-second follower wait, a 2-second image-operation queue bound, and a
  60-second Gunicorn worker timeout. ECS slide opens use bounded client
  connect/read timeouts and retries. These values do not increase worker,
  image-operation, or open-slide concurrency.
- Ingress retains a 100 requests/second limit, burst multiplier 5, and a
  50-connection limit per client. Requests carrying `X-WSI-Source` are hashed
  to keep a slide's cold-open cache on one pod.

The Redis instance used by `REDIS_URL` must have bounded memory, an LRU/LFU
eviction policy, and alerts for evictions, memory pressure, and unavailable
connections. Redis is an optimization; a Redis outage must leave the service
authorized and bounded by the ingress and image-operation controls.

Before promotion, record the live Redis service/CIDR, ECS endpoint/CIDR, and
cluster DNS labels. The current policy intentionally remains ingress-only
until those destinations are verified; the promotion gate is to add
default-deny egress with only DNS, Redis port 6379, and ECS port 9020 allowed.
Do not broaden the policy to `0.0.0.0/0` as a substitute for that inventory.

## Monitoring

Datadog scrapes `/metrics` through the pod IP using OpenMetrics. The public
ingress intentionally routes only `/wsi/tiles`, `/wsi/thumbnails`,
`/wsi/health`, and `/wsi/ready`; `/metrics` is not externally exposed. The
network policy permits the monitoring namespace to scrape the metrics route.

Alert on tile/thumbnail p95 and p99 latency, hierarchy/access latency from the
backend, cache hit rate, distributed lock outcomes, Redis errors, image queue
time, 429/503 rates, pod restarts, memory, and block-cache volume usage.

## Release procedure

1. Build and publish the tile-server image, then replace the tag in the
   deployment with the exact immutable `image@sha256:<digest>` reference
   before promotion. The deployment is not promotion-ready while it contains
   only a tag.
2. Build the green ClickHouse database with the WSI access projection and
   import the complete `meta_wsi.txt`/`data_wsi.txt` snapshots.
3. Verify WSI row counts, `can_serve_tiles`, projection materialization, and
   ClickHouse query plans before switching cBioPortal to the green database.
4. Ensure the external `tile-viewer` node group and private configuration are
   available, deploy the tile server, warm representative slides, and monitor
   memory, Redis, and latency dashboards during the canary.

Rollback is the previous backend/tile image pair plus the previous green
ClickHouse database. The projection is additive and does not require a live
mutation of the active database.
