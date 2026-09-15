#!/usr/bin/env bash
set -euo pipefail

base_url="${CBIOPORTAL_WSI_URL:-https://beta.cbioportal.mskcc.org/wsi}"
origin="${CBIOPORTAL_WSI_ORIGIN:-https://beta.cbioportal.mskcc.org}"
source_url="s3://example.invalid/slide.svs"
tile_path="${base_url%/}/tiles/zxy/0/0/0"

ready_payload="$(curl --fail --silent --show-error "${base_url%/}/ready")"
jq --exit-status \
  '.status == "ok"
   and .auth_required == true
   and .auth_contract_version == 2
   and .serving_contract_version == "wsi-serving-v2"' \
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

status="$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' \
  "$tile_path")"
test "$status" = 401 || {
  echo "expected anonymous tile request to return 401, got $status" >&2
  exit 1
}

curl --silent --show-error --include --request OPTIONS \
  --header "Origin: $origin" \
  --header 'Access-Control-Request-Method: GET' \
  --header 'Access-Control-Request-Headers: authorization, x-wsi-source' \
  "$tile_path" \
  | grep -i "^access-control-allow-origin: $origin" >/dev/null || {
    echo "CORS preflight did not allow $origin" >&2
    exit 1
  }

if [[ -n "${WSI_BEARER_TOKEN:-}" ]]; then
  status="$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' \
    --header "Authorization: Bearer ${WSI_BEARER_TOKEN}" \
    --header "X-WSI-Source: $source_url" \
    "$tile_path")"
  test "$status" != 401 || {
    echo "provided WSI_BEARER_TOKEN was rejected" >&2
    exit 1
  }
fi

printf 'WSI triage routing smoke passed for %s\n' "$base_url"
