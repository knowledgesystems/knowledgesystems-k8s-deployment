#!/usr/bin/env bash

set -euo pipefail

BASE_URL="${CBIOPORTAL_URL:-https://cbioportal.mskcc.org}"
BASE_URL="${BASE_URL%/}"
HOSTNAME="$(printf '%s' "$BASE_URL" | sed -E 's#^[^:]+://([^/]+).*#\1#')"
READY_PATH="${WSI_READY_PATH:-/wsi/ready}"
UNAUTH_PATH="${WSI_UNAUTH_PATH:-/wsi/tiles/nonexistent/metadata}"
AUTH_PATH="${WSI_AUTH_PATH:-}"
BEARER_TOKEN="${WSI_BEARER_TOKEN:-}"

if [[ "$HOSTNAME" != "cbioportal.mskcc.org" && "$HOSTNAME" != "triage-beta.cbioportal.aws.mskcc.org" ]]; then
    echo "Refusing to test unexpected host: $HOSTNAME" >&2
    exit 2
fi

if [[ "$READY_PATH" != "/wsi/ready" ]]; then
    echo "Refusing unexpected readiness path: $READY_PATH" >&2
    exit 2
fi

case "$UNAUTH_PATH" in
    /wsi/tiles/*|/wsi/thumbnails/*|/wsi/slides/*|/wsi/search*)
        ;;
    *)
        echo "Refusing unexpected protected path: $UNAUTH_PATH" >&2
        exit 2
        ;;
esac

unauth_args=(
    --silent
    --show-error
    --location
    --max-redirs 0
    --connect-timeout 10
    --max-time 60
    --output /dev/null
    --write-out '%{http_code}\n'
)

ready_status="$(curl "${unauth_args[@]}" "${BASE_URL}${READY_PATH}")"
if [[ "$ready_status" != "200" ]]; then
    echo "Readiness probe failed: ${READY_PATH} (${ready_status})" >&2
    exit 1
fi
echo "Readiness probe passed: ${READY_PATH} (${ready_status})"

unauth_status="$(curl "${unauth_args[@]}" "${BASE_URL}${UNAUTH_PATH}")"
if [[ "$unauth_status" != "401" && "$unauth_status" != "403" ]]; then
    echo "Unauthenticated WSI route was not rejected: ${UNAUTH_PATH} (${unauth_status})" >&2
    exit 1
fi
echo "Protected route rejected anonymous access: ${UNAUTH_PATH} (${unauth_status})"

if [[ -n "$AUTH_PATH" || -n "$BEARER_TOKEN" ]]; then
    : "${WSI_AUTH_PATH:?Set WSI_AUTH_PATH when WSI_BEARER_TOKEN is provided}"
    : "${WSI_BEARER_TOKEN:?Set WSI_BEARER_TOKEN when WSI_AUTH_PATH is provided}"

    case "$AUTH_PATH" in
        /wsi/tiles/*|/wsi/thumbnails/*|/wsi/slides/*|/wsi/search*)
            ;;
        *)
            echo "Refusing unexpected authenticated path: $AUTH_PATH" >&2
            exit 2
            ;;
    esac

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
        --header "Authorization: Bearer ${BEARER_TOKEN}"
    )

    response="$(curl "${curl_args[@]}" "${BASE_URL}${AUTH_PATH}")"
    status="${response%% *}"
    if [[ "$status" != 2* ]]; then
        echo "Authenticated WSI route failed: $response" >&2
        exit 2
    fi
    echo "Authenticated WSI route passed: $response"
fi
