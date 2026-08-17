#!/usr/bin/env python3
"""Shared Living Hanok V1 camera, rights, and A1 delivery contract."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent.parent
PROVENANCE_PATH = ROOT / "docs" / "assets" / "HANOK_V1_ASSET_PROVENANCE.json"
RUNTIME_MAP_ROOT = ROOT / "assets" / "illustrations" / "personal_hanok_v2" / "map"
QA_REVIEW_ROOT = ROOT / "assets_unused" / "pending_review"
A1_RUNTIME_STATES_ROOT = (
    ROOT / "assets" / "illustrations" / "personal_hanok_v2" / "a1" / "states"
)
A1_QA_STATES_ROOT = QA_REVIEW_ROOT / "a1_states"
A1_QA_LAYERS_ROOT = QA_REVIEW_ROOT / "a1_layers"
FORBIDDEN_RUNTIME_FRAGMENTS = (
    "codex-clipboard-",
    "appdata/local/temp/",
    "vivasam",
    "assets/illustrations/hanok_stages/",
    "assets/illustrations/gye/",
    "assets/video/gye/",
    "reference_full_estate.png",
)


def load_provenance(path: Path | None = None) -> dict[str, Any]:
    source = path or PROVENANCE_PATH
    payload = json.loads(source.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{source} must be a JSON object")
    return payload


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def camera_geometry(provenance: dict[str, Any] | None = None) -> dict[str, Any]:
    payload = provenance or load_provenance()
    camera = payload["camera"]
    canvas = camera["canvas"]
    socket = camera["socket"]
    anchor = socket["anchorCanvas"]
    return {
        "camera_id": camera["id"],
        "canvas_width": int(canvas["width"]),
        "canvas_height": int(canvas["height"]),
        "socket_x": int(socket["x"]),
        "socket_y": int(socket["y"]),
        "socket_width": int(socket["width"]),
        "socket_height": int(socket["height"]),
        "anchor_x": int(anchor["x"]),
        "anchor_y": int(anchor["y"]),
        "local_anchor_x": int(anchor["x"]) - int(socket["x"]),
        "local_anchor_y": int(anchor["y"]) - int(socket["y"]),
        "z_group": int(socket["zGroup"]),
    }


def qa_composite_path(provenance: dict[str, Any] | None = None) -> Path:
    payload = provenance or load_provenance()
    relative = payload["qaComposite"]["path"]
    path = ROOT / relative
    if path.resolve() != (QA_REVIEW_ROOT / "reference_full_estate.png").resolve():
        raise ValueError("QA composite must stay under assets_unused/pending_review")
    if "personal_hanok_v2/map" in relative.replace("\\", "/"):
        raise ValueError("QA composite must not live in the runtime map folder")
    return path


def a1_expected_files(provenance: dict[str, Any] | None = None) -> list[str]:
    payload = provenance or load_provenance()
    states = payload["runtimeLimits"]["a1ConstructionStates"]
    return list(states["expectedFiles"])


def a1_hard_max_bytes(provenance: dict[str, Any] | None = None) -> int:
    payload = provenance or load_provenance()
    return int(payload["runtimeLimits"]["a1ConstructionStates"]["hardMaxBytes"])


def layer_contract(provenance: dict[str, Any] | None = None) -> dict[str, Any]:
    payload = provenance or load_provenance()
    contract = payload.get("a1TransparentLayerContract")
    if not isinstance(contract, dict):
        raise ValueError("a1TransparentLayerContract is required")
    return contract


def allowed_input_digests(provenance: dict[str, Any] | None = None) -> dict[str, str]:
    payload = provenance or load_provenance()
    allowed = {
        item["path"]: item["sha256"]
        for item in payload["allowedModelInputs"]
    }
    for record in payload.get("generationLedger", {}).get("records", []):
        for output in record.get("outputAssets", []):
            if output.get("decision") == "approved":
                allowed[output["path"]] = output["sha256"]
    return allowed


def runtime_path_is_forbidden(path: str) -> bool:
    lowered = path.replace("\\", "/").lower()
    return any(fragment in lowered for fragment in FORBIDDEN_RUNTIME_FRAGMENTS)
