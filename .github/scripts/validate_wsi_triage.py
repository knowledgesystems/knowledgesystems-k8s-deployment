#!/usr/bin/env python3
"""Reject an inconsistent triage WSI pixel-route and portal-auth contract.

Triage serves pixels from the shared slide-viewer-triage tile server through
its own ingress, authorized per study by the triage portal. The nightly import
flips triage between blue and green, so the auth check reaches the portal
through a Service that selects labels both colors carry and no other pods do.
The check is offline: it reads only the manifests in this repository.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

from ruamel.yaml import YAML


ROOT = Path(__file__).resolve().parents[2]
APP_RELATIVE = Path("argocd/aws/666628074417/clusters/cbioportal-prod/apps")
NGINX = "nginx.ingress.kubernetes.io/"
PIXEL_INGRESS = "slide-viewer-triage-wsi-triage"
PROBE_INGRESS = "slide-viewer-triage-wsi-triage-probes"
PIXEL_PATH = "/wsi(/|$)(tiles(/.*)?|thumbnails(/.*)?)$"
PROBE_PATH = "/wsi(/|$)(health|ready)$"
TILE_SERVICE = "slide-viewer-triage"
AUTH_SERVICE_NAME = "eks-triage-wsi-auth"
AUTH_URL = (
    f"http://{AUTH_SERVICE_NAME}.default.svc.cluster.local/api/studies/$wsi_study"
)
AUTH_SELECTOR = {
    "tags.datadoghq.com/env": "eks-triage",
    "tags.datadoghq.com/service": "cbioportal",
}
PORTAL_INGRESS_NAME = "eks-triage-ingress"
COLORS = ("blue", "green")
POD_TEMPLATE_KINDS = {"Deployment", "StatefulSet", "DaemonSet", "ReplicaSet", "Job"}


def documents(path: Path) -> list:
    return [
        document
        for document in YAML(typ="safe").load_all(path.read_text(encoding="utf-8"))
        if isinstance(document, dict)
    ]


def one(path: Path, kind: str, name: str | None = None) -> dict:
    found = [
        document
        for document in documents(path)
        if document.get("kind") == kind
        and (name is None or document["metadata"]["name"] == name)
    ]
    if len(found) != 1:
        raise AssertionError(f"{path.name} must define exactly one {kind} {name or ''}")
    return found[0]


def pod_template(document: dict) -> dict:
    spec = document.get("spec", {})
    if document.get("kind") == "CronJob":
        spec = spec.get("jobTemplate", {}).get("spec", {})
    return spec.get("template", {}) or {}


def service_ports(service: dict) -> set[tuple]:
    return {
        (port.get("port"), port.get("targetPort"), port.get("protocol", "TCP"))
        for port in service["spec"].get("ports", [])
    }


def hosts_and_paths(ingress: dict) -> dict[str, list[dict]]:
    return {
        rule.get("host"): rule.get("http", {}).get("paths", [])
        for rule in ingress["spec"].get("rules", [])
    }


def validate(root: Path) -> None:
    apps = root / APP_RELATIVE
    portal_root = apps / "cbioportal"
    triage_ingress = apps / "slide-viewer-triage/triage-ingress.yaml"
    auth_service_file = apps / "slide-viewer-triage/triage-portal-auth-service.yaml"
    color_files = {
        color: portal_root / f"cbioportal-eks-triage-{color}-deployment-service.yaml"
        for color in COLORS
    }

    # The triage hosts are the portal ingress's hosts.
    portal_ingress = one(portal_root / "eks-triage-ingress.yaml", "Ingress", PORTAL_INGRESS_NAME)
    portal_hosts = set(hosts_and_paths(portal_ingress))
    if not portal_hosts:
        raise AssertionError(f"{PORTAL_INGRESS_NAME} has no hosts")

    ingresses = {
        document["metadata"]["name"]: document
        for document in documents(triage_ingress)
        if document.get("kind") == "Ingress"
    }
    if set(ingresses) != {PIXEL_INGRESS, PROBE_INGRESS}:
        raise AssertionError(
            f"{triage_ingress.name} must define exactly {PIXEL_INGRESS} and {PROBE_INGRESS}"
        )
    for name, expected_path in ((PIXEL_INGRESS, PIXEL_PATH), (PROBE_INGRESS, PROBE_PATH)):
        ingress = ingresses[name]
        if ingress["metadata"].get("namespace") != "default":
            raise AssertionError(f"{name} must be in the default namespace")
        if ingress["spec"].get("ingressClassName") != "nginx":
            raise AssertionError(f"{name} must use the nginx ingress class")
        rules = ingress["spec"].get("rules", [])
        rule_hosts = [rule.get("host") for rule in rules]
        if len(rule_hosts) != len(set(rule_hosts)) or set(rule_hosts) != portal_hosts:
            raise AssertionError(
                f"{name} hosts {sorted(map(str, rule_hosts))} differ from "
                f"{PORTAL_INGRESS_NAME} hosts {sorted(portal_hosts)}"
            )
        for host, paths in hosts_and_paths(ingress).items():
            if len(paths) != 1:
                raise AssertionError(f"{name} {host} exposes an unexpected route set")
            path = paths[0]
            if path.get("path") != expected_path:
                raise AssertionError(f"{name} {host} path must be {expected_path}")
            if path.get("pathType") != "ImplementationSpecific":
                raise AssertionError(f"{name} {host} regex must use ImplementationSpecific")
            backend = path.get("backend", {}).get("service", {})
            if backend.get("name") != TILE_SERVICE or backend.get("port", {}).get("number") != 80:
                raise AssertionError(f"{name} {host} must route to {TILE_SERVICE}:80")
        annotations = ingress["metadata"].get("annotations", {}) or {}
        if annotations.get(NGINX + "use-regex") != "true":
            raise AssertionError(f"{name} does not enable its prefix-stripping regex")
        if annotations.get(NGINX + "rewrite-target") != "/$2":
            raise AssertionError(f"{name} does not strip the public /wsi prefix")
        if any("snippet" in key for key in annotations):
            raise AssertionError(f"{name} uses a snippet annotation the controller rejects")

    pixel = ingresses[PIXEL_INGRESS]["metadata"]["annotations"]
    if pixel.get(NGINX + "auth-url") != AUTH_URL:
        raise AssertionError(f"{PIXEL_INGRESS} must authorize against {AUTH_URL}")
    if pixel.get(NGINX + "auth-method") != "GET":
        raise AssertionError(f"{PIXEL_INGRESS} auth subrequest must use GET")
    cache_key = pixel.get(NGINX + "auth-cache-key", "")
    for variable in ("$host", "$cookie_SESSION", "$cookie_JSESSIONID", "$wsi_study"):
        # $host must not be read as a prefix of a longer variable name.
        if re.search(re.escape(variable) + r"(?![A-Za-z0-9_])", cache_key) is None:
            raise AssertionError(
                f"{PIXEL_INGRESS} auth cache key must contain {variable}: it must "
                "cover both session cookie names (SESSION, JSESSIONID), and the "
                "cache zone is shared with beta, so it must also name the host"
            )
    if re.fullmatch(r"200 [1-9][0-9]*s", pixel.get(NGINX + "auth-cache-duration", "")) is None:
        raise AssertionError(f"{PIXEL_INGRESS} may cache only successful auth responses")
    if pixel.get(NGINX + "enable-access-log") != "false":
        raise AssertionError(f"{PIXEL_INGRESS} must not access-log the sealed source query")
    if pixel.get(NGINX + "upstream-hash-by") != "$arg_key":
        raise AssertionError(f"{PIXEL_INGRESS} must keep one slide's requests on one pod")

    probe = ingresses[PROBE_INGRESS]["metadata"].get("annotations", {}) or {}
    if any(key.startswith(NGINX + "auth-") for key in probe):
        raise AssertionError(f"{PROBE_INGRESS} must not require portal auth")

    # The auth subrequest cannot see $arg_studyId; the controller derives
    # $wsi_study from the original $request_uri in its global http-snippet.
    controller = documents(apps / "ingress/values.yaml")[0]["controller"]["config"]
    http_snippet = controller.get("http-snippet", "")
    if re.search(r"\bmap\s+\$request_uri\s+\$wsi_study\s*\{", http_snippet) is None:
        raise AssertionError("ingress controller http-snippet does not map $request_uri to $wsi_study")
    if re.search(r'default\s+"!"\s*;', http_snippet) is None:
        raise AssertionError('ingress controller $wsi_study map must default to the refused study "!"')

    # The auth Service selects both colors by labels they share, never one color.
    auth_service = one(auth_service_file, "Service", AUTH_SERVICE_NAME)
    if auth_service["metadata"].get("namespace") != "default":
        raise AssertionError(f"{AUTH_SERVICE_NAME} must be in the default namespace")
    if auth_service["spec"].get("selector") != AUTH_SELECTOR:
        raise AssertionError(f"{AUTH_SERVICE_NAME} selector must be exactly {AUTH_SELECTOR}")
    portal_ports = None
    for color, path in color_files.items():
        labels = pod_template(one(path, "Deployment"))["metadata"].get("labels", {}) or {}
        missing = {key for key, value in AUTH_SELECTOR.items() if labels.get(key) != value}
        if missing:
            raise AssertionError(f"triage {color} pods lack {sorted(missing)}")
        ports = service_ports(one(path, "Service"))
        if portal_ports is not None and ports != portal_ports:
            raise AssertionError("triage blue and green Services expose different ports")
        portal_ports = ports
    if service_ports(auth_service) != portal_ports:
        raise AssertionError(f"{AUTH_SERVICE_NAME} ports differ from the triage portal Service")

    # No other pods may answer the auth check.
    color_paths = {path.resolve() for path in color_files.values()}
    for path in sorted(apps.rglob("*")):
        if path.suffix not in (".yaml", ".yml") or not path.is_file():
            continue
        for document in documents(path):
            if document.get("kind") not in POD_TEMPLATE_KINDS | {"CronJob"}:
                continue
            if path.resolve() in color_paths and document.get("kind") == "Deployment":
                continue
            labels = (pod_template(document).get("metadata", {}) or {}).get("labels", {}) or {}
            if all(labels.get(key) == value for key, value in AUTH_SELECTOR.items()):
                raise AssertionError(
                    f"{path.relative_to(root)} {document.get('kind')} "
                    f"{document['metadata'].get('name')} pods would answer {AUTH_SERVICE_NAME}"
                )


if __name__ == "__main__":
    validate(Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT)
    print("triage WSI pixel route and portal auth validated")
