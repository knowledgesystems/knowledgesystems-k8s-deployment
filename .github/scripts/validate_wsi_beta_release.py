#!/usr/bin/env python3
"""Reject mutable or internally inconsistent beta WSI component manifests."""

from __future__ import annotations

import json
import re
from pathlib import Path
from urllib.parse import quote, urlencode, urljoin, urlparse
from urllib.request import Request, urlopen

from ruamel.yaml import YAML


ROOT = Path(__file__).resolve().parents[2]
APP_ROOT = ROOT / "argocd/aws/666628074417/clusters/cbioportal-prod/apps"
PORTAL_ROOT = APP_ROOT / "cbioportal"
BLUE = PORTAL_ROOT / "cbioportal-eks-msk-beta-blue-deployment-service.yaml"
GREEN = PORTAL_ROOT / "cbioportal-eks-msk-beta-green-deployment-service.yaml"
TILE = APP_ROOT / "slide-viewer-triage/deployment.yaml"
POLICY = APP_ROOT / "slide-viewer-triage/wsi-serving-policy.yaml"
INGRESS = APP_ROOT / "slide-viewer-triage/ingress.yaml"
SMOKE_WORKFLOW = ROOT / ".github/workflows/smoke-wsi-triage.yml"
APPROVED_SOURCE_PREFIXES = {
    "s3://pathology/",
    "s3://mskmind-bkt/",
    "s3://ocra/",
}
IMMUTABLE_FRONTEND_HOST = re.compile(
    r"^[0-9a-f]{24}--cbioportalfrontend\.netlify\.app$"
)
BACKEND_IMAGE = re.compile(
    r"^cbioportal/cbioportal-dev:([0-9a-f]{40})-web-shenandoah@(sha256:[0-9a-f]{64})$"
)
TILE_IMAGE = re.compile(
    r"^cbioportal/cbioportal-tile-server:([A-Za-z0-9_.-]+)@(sha256:[0-9a-f]{64})$"
)


def documents(path: Path):
    return list(YAML(typ="safe").load_all(path.read_text(encoding="utf-8")))


def deployment(path: Path) -> dict:
    for document in documents(path):
        if document and document.get("kind") == "Deployment":
            return document
    raise AssertionError(f"{path} has no Deployment")


def container(document: dict, name: str | None = None) -> dict:
    values = document["spec"]["template"]["spec"]["containers"]
    if name is None:
        if len(values) != 1:
            raise AssertionError("expected one portal container")
        return values[0]
    return next(value for value in values if value["name"] == name)


def env_map(value: dict) -> dict[str, str]:
    return {
        item["name"]: item.get("value", "")
        for item in value.get("env", [])
        if isinstance(item, dict) and "name" in item
    }


def comma_separated_values(value: str) -> set[str]:
    return {item.strip() for item in value.split(",") if item.strip()}


def portal_identity(path: Path) -> tuple[str, str, str, str]:
    document = deployment(path)
    pod = document["spec"]["template"]
    annotations = pod.get("metadata", {}).get("annotations", {})
    release_id = annotations.get("wsi.cbioportal.org/release-id", "")
    frontend_git_sha = annotations.get("wsi.cbioportal.org/frontend-git-sha", "")
    if re.fullmatch(r"[0-9a-f]{40}", frontend_git_sha) is None:
        raise AssertionError(f"{path.name} has no immutable frontend Git SHA")
    value = container(document)
    image = value["image"]
    backend_image_match = BACKEND_IMAGE.fullmatch(image)
    if backend_image_match is None:
        raise AssertionError(
            f"{path.name} backend image is not an immutable cBioPortal web image"
        )
    args = value.get("args", [])
    runtime_identity = {
        argument.split("=", 1)[0]: argument.split("=", 1)[1]
        for argument in args
        if isinstance(argument, str)
        and argument.startswith("--wsi.")
        and "=" in argument
    }
    expected_identity = {
        "--wsi.release-id": release_id,
        "--wsi.backend-git-sha": backend_image_match.group(1),
        "--wsi.serving-contract-version": "wsi-serving-v3",
    }
    if any(
        runtime_identity.get(key) != expected
        for key, expected in expected_identity.items()
    ):
        raise AssertionError(
            f"{path.name} backend runtime identity differs from its pod annotation or image"
        )
    tile_server_url = next(
        (
            argument.split("=", 1)[1]
            for argument in args
            if argument.startswith("--msk.wsi.tile_server.url=")
        ),
        "",
    )
    if tile_server_url != "https://beta.cbioportal.mskcc.org/wsi":
        raise AssertionError(
            f"{path.name} does not use the beta same-origin WSI ingress route"
        )
    frontend = next(
        (arg.split("=", 1)[1] for arg in args if arg.startswith("--frontend.url=")), ""
    )
    parsed = urlparse(frontend)
    if (
        parsed.scheme != "https"
        or parsed.path not in ("", "/")
        or parsed.params
        or parsed.query
        or parsed.fragment
        or IMMUTABLE_FRONTEND_HOST.fullmatch(parsed.netloc) is None
    ):
        raise AssertionError(
            f"{path.name} frontend URL is not an immutable Netlify artifact"
        )
    cors = next(
        (
            arg.split("=", 1)[1]
            for arg in args
            if arg.startswith("--security.cors.allowed-origins=")
        ),
        "",
    )
    frontend_origin = f"{parsed.scheme}://{parsed.netloc}"
    cors_origins = comma_separated_values(cors)
    if (
        any("deploy-preview" in origin for origin in cors_origins)
        or frontend_origin not in cors_origins
    ):
        raise AssertionError(f"{path.name} CORS does not match its immutable frontend")
    environment = env_map(value)
    for duplicate in ("WSI_ALLOWED_SOURCE_PREFIXES", "WSI_ALLOWED_THUMBNAIL_PREFIXES"):
        if duplicate in environment:
            raise AssertionError(
                f"{path.name} overrides shared policy variable {duplicate}"
            )
    config_maps = {
        entry.get("configMapRef", {}).get("name")
        for entry in value.get("envFrom", [])
        if isinstance(entry, dict)
    }
    if "wsi-serving-policy" not in config_maps:
        raise AssertionError(f"{path.name} does not consume wsi-serving-policy")
    if not release_id:
        raise AssertionError(f"{path.name} has no release identity")
    return release_id, frontend, frontend_git_sha, image


def assert_frontend_artifact(identity: tuple[str, str, str, str]) -> None:
    _, frontend, frontend_git_sha, _ = identity
    bundle_url = urljoin(frontend, "reactapp/main.app.js")
    request = Request(
        bundle_url, headers={"User-Agent": "cbioportal-release-validator/1"}
    )
    needle = frontend_git_sha.encode("ascii")
    overlap = b""
    with urlopen(request, timeout=60) as response:
        if response.status != 200:
            raise AssertionError(
                f"immutable frontend bundle returned HTTP {response.status}"
            )
        while chunk := response.read(1024 * 1024):
            candidate = overlap + chunk
            if needle in candidate:
                return
            overlap = candidate[-(len(needle) - 1) :]
    raise AssertionError(
        f"immutable frontend artifact does not contain {frontend_git_sha}"
    )


def assert_docker_artifact(repository: str, tag: str, digest: str) -> None:
    tag_url = f"https://hub.docker.com/v2/repositories/{repository}/tags/{quote(tag, safe='')}"
    request = Request(tag_url, headers={"User-Agent": "cbioportal-release-validator/1"})
    with urlopen(request, timeout=60) as response:
        artifact = json.load(response)
    if artifact.get("digest") != digest:
        raise AssertionError(
            f"Docker Hub digest for {repository}:{tag} does not match {digest}"
        )
    platforms = {
        (image.get("os"), image.get("architecture"))
        for image in artifact.get("images", [])
    }
    required_platforms = {("linux", "amd64"), ("linux", "arm64")}
    if not required_platforms.issubset(platforms):
        raise AssertionError(
            f"Docker artifact {repository}:{tag} is missing a required platform"
        )


def assert_docker_digest(repository: str, digest: str) -> None:
    """Validate the immutable manifest without resolving a mutable tag.

    A deployment may retain a human-readable tag next to ``@sha256`` for
    operability, but release validation must never compare that tag with the
    current registry head.  Branch tags move and would make an unchanged
    blue/green release fail on the next run.
    """
    token_request = Request(
        "https://auth.docker.io/token?"
        + urlencode({"service": "registry.docker.io", "scope": f"repository:{repository}:pull"}),
        headers={"User-Agent": "cbioportal-release-validator/1"},
    )
    with urlopen(token_request, timeout=60) as response:
        token_payload = json.load(response)
    token = token_payload.get("token") or token_payload.get("access_token")
    if not isinstance(token, str) or not token:
        raise AssertionError(f"Docker registry did not return a pull token for {repository}")
    manifest_request = Request(
        f"https://registry-1.docker.io/v2/{repository}/manifests/{digest}",
        headers={
            "Accept": (
                "application/vnd.docker.distribution.manifest.list.v2+json,"
                "application/vnd.docker.distribution.manifest.v2+json"
            ),
            "Authorization": f"Bearer {token}",
            "User-Agent": "cbioportal-release-validator/1",
        },
    )
    with urlopen(manifest_request, timeout=60) as response:
        actual_digest = response.headers.get("Docker-Content-Digest", digest)
        if actual_digest != digest:
            raise AssertionError(
                f"Docker registry digest for {repository} does not match {digest}"
            )
        manifest = json.load(response)
    platforms = {
        (item.get("platform", {}).get("os"), item.get("platform", {}).get("architecture"))
        for item in manifest.get("manifests", [])
        if isinstance(item, dict) and isinstance(item.get("platform"), dict)
    }
    required_platforms = {("linux", "amd64"), ("linux", "arm64")}
    if not required_platforms.issubset(platforms):
        raise AssertionError(
            f"Docker digest {repository}@{digest} is missing a required platform"
        )


blue = portal_identity(BLUE)
green = portal_identity(GREEN)
if blue != green:
    raise AssertionError(
        "beta blue and green do not pin the same WSI component release"
    )
assert_frontend_artifact(blue)
backend_match = BACKEND_IMAGE.fullmatch(blue[3])
assert backend_match is not None
assert_docker_artifact(
    "cbioportal/cbioportal-dev",
    f"{backend_match.group(1)}-web-shenandoah",
    backend_match.group(2),
)

tile_document = deployment(TILE)
tile_pod = tile_document["spec"]["template"]
tile_release = (
    tile_pod.get("metadata", {})
    .get("annotations", {})
    .get("wsi.cbioportal.org/release-id", "")
)
tile_container = container(tile_document, "tile-server")
if tile_release != blue[0]:
    raise AssertionError("portal and tile server release identities differ")
tile_match = TILE_IMAGE.fullmatch(tile_container["image"])
if tile_match is None:
    raise AssertionError("tile-server image is not an immutable cBioPortal tile image")
assert_docker_digest("cbioportal/cbioportal-tile-server", tile_match.group(2))
tile_env = env_map(tile_container)
if tile_env.get("WSI_RELEASE_ID") != blue[0]:
    raise AssertionError("tile-server runtime release identity differs")
if tile_env.get("WSI_SERVING_CONTRACT_VERSION") != "wsi-serving-v3":
    raise AssertionError("tile-server does not declare wsi-serving-v3")
if not re.fullmatch(r"[0-9a-f]{40}", tile_env.get("IMAGE_GIT_SHA", "")):
    raise AssertionError("tile-server does not declare a full immutable git SHA")
tile_cors_origins = comma_separated_values(tile_env.get("CORS_ORIGINS", ""))
frontend_origin = blue[1].rstrip("/")
if any("deploy-preview" in origin for origin in tile_cors_origins):
    raise AssertionError("tile-server CORS contains a mutable preview alias")
if frontend_origin not in tile_cors_origins:
    raise AssertionError("tile-server CORS does not allow the pinned frontend origin")

policy = documents(POLICY)[0]["data"]
if set(policy["WSI_ALLOWED_SOURCE_PREFIXES"].split(",")) != APPROVED_SOURCE_PREFIXES:
    raise AssertionError("WSI source policy does not contain the approved bucket roots")
if policy["WSI_ALLOWED_THUMBNAIL_PREFIXES"] != "s3://mskmind-bkt/wsi-thumbnails/":
    raise AssertionError("WSI thumbnail policy is not the approved publication root")

ingress = documents(INGRESS)[0]
ingress_annotations = ingress["metadata"]["annotations"]
if ingress_annotations.get("nginx.ingress.kubernetes.io/use-regex") != "true":
    raise AssertionError("WSI ingress does not enable its prefix-stripping regex")
if ingress_annotations.get("nginx.ingress.kubernetes.io/rewrite-target") != "/$2":
    raise AssertionError("WSI ingress does not strip the public /wsi prefix")
ingress_paths = ingress["spec"]["rules"][0]["http"]["paths"]
expected_ingress_path = "/wsi(/|$)(tiles(/.*)?|thumbnails(/.*)?|health|ready)$"
if len(ingress_paths) != 1 or ingress_paths[0].get("path") != expected_ingress_path:
    raise AssertionError("WSI ingress exposes an unexpected application route set")
if ingress_paths[0].get("pathType") != "ImplementationSpecific":
    raise AssertionError(
        "WSI ingress regex does not use ImplementationSpecific path type"
    )

smoke_inputs = documents(SMOKE_WORKFLOW)[0]["on"]["workflow_dispatch"]["inputs"]
release_input = smoke_inputs.get("release_id")
if release_input is not None and release_input.get("default") != blue[0]:
    raise AssertionError("post-deploy smoke default release differs from the manifests")
tile_input = smoke_inputs.get("tile_git_sha")
if tile_input is not None and tile_input.get("default") != tile_env["IMAGE_GIT_SHA"]:
    raise AssertionError("post-deploy smoke default tile SHA differs from the manifests")

print(f"immutable beta WSI component release validated: {blue[0]}")
