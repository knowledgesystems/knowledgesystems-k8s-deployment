#!/usr/bin/env bash

set -euo pipefail

: "${WSI_PATIENT_PATH:?Set WSI_PATIENT_PATH, for example /wsi/patient/P-0000678}"
: "${WSI_TILE_PATH:?Set WSI_TILE_PATH, for example /wsi/tiles/<slide-id>/zxy/4/0/0}"

BASE_URL="${CBIOPORTAL_URL:-https://cbioportal.mskcc.org}"
BASE_URL="${BASE_URL%/}"
HOSTNAME="$(printf '%s' "$BASE_URL" | sed -E 's#^[^:]+://([^/]+).*#\1#')"

if [[ "$HOSTNAME" != "cbioportal.mskcc.org" ]]; then
    echo "Refusing to test unexpected host: $HOSTNAME" >&2
    exit 2
fi

curl_args=(
    --fail
    --silent
    --show-error
    --location
    --max-redirs 0
    --connect-timeout 10
    --max-time 60
    --output /dev/null
    --write-out '%{http_code} %{url_effective}\n'
)

if [[ -n "${WSI_BEARER_TOKEN:-}" ]]; then
    curl_args+=(--header "Authorization: Bearer ${WSI_BEARER_TOKEN}")
fi

for path in "$WSI_PATIENT_PATH" "$WSI_TILE_PATH"; do
    if [[ "$path" != /wsi/patient/* && "$path" != /wsi/tiles/* ]]; then
        echo "Refusing unexpected WSI path: $path" >&2
        exit 2
    fi

    response="$(curl "${curl_args[@]}" "${BASE_URL}${path}")"
    status="${response%% *}"
    if [[ "$status" != 2* ]]; then
        echo "WSI route failed: $response" >&2
        exit 1
    fi
    echo "WSI route passed: $response"
done
