#!/usr/bin/env python3
"""A1 construction kit: manifest rendering, rear-row transform and kit gates.

`compose_hanok_a1_state.py --kit-manifest` uses this module. A stage manifest
lists parts (derived crops of the allowlisted finished house, or approved
generated sprites) in z order; this module renders them deterministically into
the 854x309 socket layer and enforces the kit rules that replace the raw-layer
rules of the generative pipeline:

* exact socket size, resize path disabled;
* kit anchor: the alpha bbox contains the anchor column and reaches the ground
  row for the stage (platform bottom for 01-02, last steps row for 03+);
* containment: every visible pixel lies inside the finished silhouette
  (dilated by 1px) or inside a declared props zone;
* structural continuity: every non-transient pixel of the previous stage must
  survive in footprint (recall == 1.0) with <= 2px edge drift;
* lineage: derived parts are re-derived from the allowlisted source at compose
  time and their RGBA digest must equal `parts.json`; generated parts must be
  approved ledger outputs.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image

from derive_hanok_a1_kit import (
    ALPHA_THRESHOLD,
    PARTS_REGISTRY_PATH,
    build_geometry,
    derive_parts,
    load_geometry,
    load_overrides,
    load_socket_crop,
    rgba_digest,
)
from hanok_v1_asset_contract import ROOT, allowed_input_digests, sha256_file

MANIFEST_SCHEMA_VERSION = 1
PARTS_SCHEMA_VERSION = 1
GENERATED_PREFIX = "generated:"


class KitError(ValueError):
    """Fail-closed A1 kit contract violation."""


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise KitError(message)


def load_manifest(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    _require(isinstance(payload, dict), f"{path} must be a JSON object")
    _require(
        payload.get("schemaVersion") == MANIFEST_SCHEMA_VERSION,
        f"{path}: unsupported stage manifest schema",
    )
    stage = payload.get("stage")
    _require(isinstance(stage, int) and 1 <= stage <= 16, f"{path}: stage must be 1..16")
    layers = payload.get("layers")
    _require(isinstance(layers, list) and layers, f"{path}: layers must be a non-empty list")
    seen_z: set[int] = set()
    for index, layer in enumerate(layers):
        _require(isinstance(layer, dict), f"{path}: layers[{index}] must be an object")
        _require(
            isinstance(layer.get("part"), str) and layer["part"],
            f"{path}: layers[{index}].part must be a non-empty string",
        )
        z = layer.get("z")
        _require(isinstance(z, int), f"{path}: layers[{index}].z must be an integer")
        _require(z not in seen_z, f"{path}: duplicate z {z}")
        seen_z.add(z)
        for key in ("transient", "rear", "prop"):
            _require(
                isinstance(layer.get(key, False), bool),
                f"{path}: layers[{index}].{key} must be a bool",
            )
        if layer["part"].startswith(GENERATED_PREFIX):
            at = layer.get("at")
            _require(
                isinstance(at, list) and len(at) == 2 and all(isinstance(v, int) for v in at),
                f"{path}: generated layer {layer['part']} needs integer at:[x, y]",
            )
    return payload


def load_parts_registry(path: Path | None = None) -> dict[str, Any]:
    source = path or PARTS_REGISTRY_PATH
    _require(source.exists(), f"parts registry missing: {source}")
    payload = json.loads(source.read_text(encoding="utf-8"))
    _require(
        payload.get("schemaVersion") == PARTS_SCHEMA_VERSION,
        "unsupported parts registry schema",
    )
    _require(isinstance(payload.get("derived"), dict), "parts.derived must be an object")
    _require(isinstance(payload.get("generated"), dict), "parts.generated must be an object")
    return payload


def rederive_parts(
    provenance: dict[str, Any] | None = None,
) -> tuple[Image.Image, dict[str, Any], dict[str, Image.Image]]:
    """Re-derive parts from the allowlisted source and cross-check the committed geometry."""
    socket, record = load_socket_crop(provenance)
    geometry = build_geometry(socket, record, load_overrides())
    committed = load_geometry()
    _require(
        committed == geometry,
        "committed a1_kit_geometry.json differs from a fresh derivation",
    )
    return socket, geometry, derive_parts(socket, geometry)


def verify_derived_digests(
    parts: dict[str, Image.Image],
    registry: dict[str, Any],
) -> dict[str, str]:
    digests: dict[str, str] = {}
    for name, image in parts.items():
        entry = registry["derived"].get(name)
        _require(isinstance(entry, dict), f"parts.json has no derived entry for {name}")
        digest = rgba_digest(image)
        _require(
            entry.get("rgbaSha256") == digest,
            f"derived part {name} digest {digest[:12]}… differs from parts.json; "
            "re-run derive and review before composing",
        )
        digests[name] = digest
    return digests


def load_generated_part(
    name: str,
    registry: dict[str, Any],
    provenance: dict[str, Any] | None,
    *,
    allow_unapproved: bool = False,
) -> Image.Image:
    entry = registry["generated"].get(name)
    _require(isinstance(entry, dict), f"parts.json has no generated entry for {name}")
    rel = entry.get("file")
    _require(isinstance(rel, str) and rel, f"generated part {name} has no file")
    path = ROOT / rel
    _require(path.exists(), f"generated part file missing: {rel}")
    digest = sha256_file(path)
    _require(entry.get("sha256") == digest, f"generated part {name} SHA differs from parts.json")
    if not allow_unapproved:
        allowed = allowed_input_digests(provenance)
        _require(
            allowed.get(rel.replace("\\", "/")) == digest,
            f"generated part {name} is not an approved ledger output ({rel})",
        )
    with Image.open(path) as source:
        image = source.copy()
    _require(image.mode == "RGBA", f"generated part {name} must be RGBA")
    return image


def rear_row_transform(layer: Image.Image, geometry: dict[str, Any]) -> Image.Image:
    """Move a derived part to the rear column row along the measured perspective.

    Every column x shifts by (-round(k*d*(x - vanishingX)), -d) and is darkened;
    the front copy drawn later occludes most of it, exactly as the camera would.
    """
    perspective = geometry["perspective"]
    d = int(perspective["d"])
    k = float(perspective["k"])
    vanishing = int(perspective["vanishingX"])
    darken = float(perspective["rearRowDarken"])
    source = np.array(layer.convert("RGBA"), dtype=np.uint8)
    height, width = source.shape[:2]
    target = np.zeros_like(source)
    for x in range(width):
        column = source[:, x]
        if not (column[:, 3] > ALPHA_THRESHOLD).any():
            continue
        dx = -int(round(k * d * (x - vanishing)))
        nx = x + dx
        if not 0 <= nx < width:
            continue
        shifted = np.zeros_like(column)
        shifted[: height - d] = column[d:]
        rgb = shifted[:, :3].astype(np.float32) * darken
        shifted[:, :3] = np.clip(np.round(rgb), 0, 255).astype(np.uint8)
        # later columns win where two source columns land on the same target
        keep = shifted[:, 3] > ALPHA_THRESHOLD
        target[keep, nx] = shifted[keep]
    return Image.fromarray(target)


def render_manifest(
    manifest: dict[str, Any],
    *,
    parts: dict[str, Image.Image],
    geometry: dict[str, Any],
    registry: dict[str, Any],
    provenance: dict[str, Any] | None,
    include_transient: bool = True,
    only_transient: bool = False,
    include_props: bool = True,
    allow_unapproved_parts: bool = False,
) -> Image.Image:
    width = int(geometry["socket"]["width"])
    height = int(geometry["socket"]["height"])
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    for layer in sorted(manifest["layers"], key=lambda item: item["z"]):
        transient = bool(layer.get("transient", False))
        if only_transient and not transient:
            continue
        if not include_transient and transient:
            continue
        # `prop` marks the movable furnishings (chimney, shoes, lantern, blind,
        # pots) that stay for good but are NOT part of the finished sarangchae
        # asset: rendering without them must reproduce sarangchae.png exactly.
        if not include_props and bool(layer.get("prop", False)):
            continue
        name = layer["part"]
        if name.startswith(GENERATED_PREFIX):
            sprite = load_generated_part(
                name[len(GENERATED_PREFIX) :],
                registry,
                provenance,
                allow_unapproved=allow_unapproved_parts,
            )
            x, y = layer["at"]
            placed = Image.new("RGBA", (width, height), (0, 0, 0, 0))
            placed.alpha_composite(sprite, dest=(x, y))
            image = placed
        else:
            _require(name in parts, f"unknown derived part {name}")
            image = parts[name]
            if layer.get("rear", False):
                image = rear_row_transform(image, geometry)
        _require(image.size == (width, height), f"layer {name} is not the socket size")
        canvas.alpha_composite(image)
    return canvas


def alpha_mask(image: Image.Image, threshold: int = ALPHA_THRESHOLD) -> np.ndarray:
    return np.array(image.getchannel("A")) > threshold


def dilate(mask: np.ndarray, px: int) -> np.ndarray:
    result = mask.copy()
    for _ in range(px):
        padded = np.pad(result, 1, mode="constant", constant_values=False)
        result = (
            padded[1:-1, 1:-1]
            | padded[:-2, 1:-1]
            | padded[2:, 1:-1]
            | padded[1:-1, :-2]
            | padded[1:-1, 2:]
            | padded[:-2, :-2]
            | padded[:-2, 2:]
            | padded[2:, :-2]
            | padded[2:, 2:]
        )
    return result


def props_zone_mask(geometry: dict[str, Any]) -> np.ndarray:
    width = int(geometry["socket"]["width"])
    height = int(geometry["socket"]["height"])
    mask = np.zeros((height, width), dtype=bool)
    for left, top, right, bottom in geometry["propsZoneRects"]:
        mask[top:bottom, left:right] = True
    return mask


def assert_kit_anchor(
    layer: Image.Image,
    geometry: dict[str, Any],
    stage: int,
) -> dict[str, int]:
    mask = alpha_mask(layer)
    _require(bool(mask.any()), "kit layer is fully transparent")
    ys, xs = np.nonzero(mask)
    left, right = int(xs.min()), int(xs.max()) + 1
    bottom = int(ys.max()) + 1
    anchor_x = int(geometry["perspective"]["vanishingX"])
    ground = geometry["groundRowExclusive"]
    required = int(ground["stagesUpTo02"] if stage <= 2 else ground["stagesFrom03"])
    _require(left <= anchor_x < right, "kit layer bbox does not span the anchor column")
    _require(
        bottom >= required,
        f"kit layer bottom {bottom} does not reach the stage ground row {required}",
    )
    return {"left": left, "right": right, "bottom": bottom, "requiredGroundRow": required}


def assert_containment(
    layer: Image.Image,
    finished_alpha: np.ndarray,
    geometry: dict[str, Any],
    *,
    dilate_px: int,
) -> int:
    allowed = dilate(finished_alpha, dilate_px) | props_zone_mask(geometry)
    violations = int((alpha_mask(layer) & ~allowed).sum())
    _require(
        violations == 0,
        f"{violations} visible pixels lie outside the finished silhouette and the props zone",
    )
    return violations


def assert_structural_continuity(
    previous_layer: Image.Image,
    previous_transient: Image.Image,
    current_layer: Image.Image,
    *,
    max_edge_drift_px: float,
) -> dict[str, float]:
    previous = alpha_mask(previous_layer)
    transient = dilate(alpha_mask(previous_transient), 1)
    structural = previous & ~transient
    current = alpha_mask(current_layer)
    _require(bool(previous.any()), "previous stage layer is empty")
    if not structural.any():
        # Stages 01-02 are setout marks and ink lines only: every pixel of them is
        # transient, so the next stage inherits nothing and there is no footprint
        # to keep. An empty *layer* is still rejected above.
        return {"structuralRecall": 1.0, "structuralPixels": 0.0, "edgeDriftPx": 0.0}
    missing = int((structural & ~current).sum())
    _require(
        missing == 0,
        f"current stage dropped {missing} structural pixels of the previous stage",
    )
    ys, xs = np.nonzero(structural)
    cys, cxs = np.nonzero(structural & current)
    drift = max(
        abs(int(xs.min()) - int(cxs.min())),
        abs(int(xs.max()) - int(cxs.max())),
        abs(int(ys.max()) - int(cys.max())),
    )
    _require(drift <= max_edge_drift_px, f"structural footprint drifted {drift}px")
    return {
        "structuralRecall": 1.0,
        "structuralPixels": float(structural.sum()),
        "edgeDriftPx": float(drift),
    }
