# Slide viewer tile-server operations

The tile server is a source-bound pixel service. cBioPortal remains the owner
of WSI hierarchy and slide-access metadata; the tile server receives an exact
source URL and short-lived capability from the backend.

## Capacity controls

- The deployment starts with two replicas and two Gunicorn workers per pod.
- `MAX_IMAGE_OPERATIONS=1` bounds blocking tile/thumbnail work per worker.
- `CACHE_MISS_RATE_LIMIT_PER_MINUTE` is a shared Redis sliding-window limit
  for extraction leaders only. Redis cache hits are not application-rate-
  limited.
- Redis locks coalesce identical cache misses across workers and replicas.
- Ingress retains a 100 requests/second limit, burst multiplier 5, and a
  50-connection limit per client.
- The HPA scales from 2 to 6 pods at 70% average CPU; scale-down is delayed
  five minutes. The PDB keeps one pod available during voluntary disruption.

The Redis instance used by `REDIS_URL` must have bounded memory, an LRU/LFU
eviction policy, and alerts for evictions, memory pressure, and unavailable
connections. Redis is an optimization; a Redis outage must leave the service
authorized and bounded by the ingress and image-operation controls.

## Monitoring

Datadog scrapes `/metrics` through the pod IP using OpenMetrics. The public
ingress intentionally routes only `/wsi/tiles`, `/wsi/thumbnails`,
`/wsi/health`, and `/wsi/ready`; `/metrics` is not externally exposed. The
network policy permits the monitoring namespace to scrape the metrics route.

Alert on tile/thumbnail p95 and p99 latency, hierarchy/access latency from the
backend, cache hit rate, distributed lock outcomes, Redis errors, image queue
time, 429/503 rates, pod restarts, memory, and block-cache volume usage.

## Release procedure

1. Build and publish the tile-server image from the coordinated tile-server
   change set, then update the immutable image digest in `deployment.yaml`.
2. Build the green ClickHouse database with the WSI access projection and
   import the complete `meta_wsi.txt`/`data_wsi.txt` snapshots.
3. Verify WSI row counts, `can_serve_tiles`, projection materialization, and
   ClickHouse query plans before switching cBioPortal to the green database.
4. Deploy the tile server, warm representative slides, and monitor the HPA,
   Redis, and latency dashboards during the canary.

Rollback is the previous backend/tile image pair plus the previous green
ClickHouse database. The projection is additive and does not require a live
mutation of the active database.
