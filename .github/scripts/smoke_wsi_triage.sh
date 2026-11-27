#!/usr/bin/env bash
set -euo pipefail

base_url="${CBIOPORTAL_WSI_URL:-https://beta.cbioportal.mskcc.org/wsi}"
source_url="s3://example.invalid/slide.svs"
# A well-formed request for a slide that does not exist: the ingress decides
# 401 vs pass from the session alone, and the tile server cannot open `enc`.
tile_url="${base_url%/}/tiles/zxy/0/0/0?studyId=mskimpact&key=000000000000&enc=AAAA"

ready_payload="$(curl --fail --silent --show-error "${base_url%/}/ready")"
jq --exit-status \
  '.status == "ok"
   and .auth_required == false
   and .auth_contract_version == 5
   and .serving_contract_version == "wsi-serving-v6"' \
  <<<"$ready_payload" >/dev/null || {
    echo "unexpected WSI readiness contract: $ready_payload" >&2
    exit 1
  }

if [[ -n "${EXPECTED_WSI_RELEASE_ID:-}" ]]; then
  jq --exit-status --arg expected "$EXPECTED_WSI_RELEASE_ID" \
    '.release_id == $expected' <<<"$ready_payload" >/dev/null || {
      echo "WSI release ID does not match $EXPECTED_WSI_RELEASE_ID: $ready_payload" >&2
      exit 1
    }
fi

if [[ -n "${EXPECTED_WSI_TILE_GIT_SHA:-}" ]]; then
  jq --exit-status --arg expected "$EXPECTED_WSI_TILE_GIT_SHA" \
    '.image_git_sha == $expected' <<<"$ready_payload" >/dev/null || {
      echo "WSI tile Git SHA does not match $EXPECTED_WSI_TILE_GIT_SHA: $ready_payload" >&2
      exit 1
    }
fi

# Without a portal session the ingress auth subrequest refuses the request.
status="$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' \
  "$tile_url")"
test "$status" = 401 || {
  echo "expected anonymous tile request to return 401, got $status" >&2
  exit 1
}

if [[ -n "${WSI_SESSION_COOKIE:-}" ]]; then
  # The session passes the ingress; the tile server refuses an `enc` that
  # does not open under `key` with 404 (it never answers 401/403).
  status="$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' \
    --cookie "SESSION=${WSI_SESSION_COOKIE}" \
    "$tile_url")"
  test "$status" = 404 || {
    echo "expected an authorized request for an unknown slide to return 404, got $status" >&2
    exit 1
  }

  # The sealed `enc` carries the slide source; a browser-supplied one is refused.
  status="$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' \
    --cookie "SESSION=${WSI_SESSION_COOKIE}" \
    --get --data-urlencode "source=$source_url" \
    "$tile_url")"
  test "$status" = 400 || {
    echo "expected a client-supplied source to return 400, got $status" >&2
    exit 1
  }
fi

printf 'WSI triage routing smoke passed for %s\n' "$base_url"
