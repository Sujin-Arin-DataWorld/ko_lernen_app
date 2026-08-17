#!/usr/bin/env python3
"""Derive the A1 construction kit geometry and crop parts from the finished house.

The Living Hanok V1 A1 states are no longer drawn by a generative model. The
approved, allowlisted completed sarangchae (`completed_house_source`) is the
single geometric truth: this tool measures it, writes `a1_kit_geometry.json`
(pillar spans, bands, choseok polygons, eave line, props zone, perspective) and
partitions every visible socket pixel into named parts (roof, rafter ends,
changbang band, 8 pillars, 7 bay panels, habang band, wall shadow, 8 choseok,
platform). `compose_hanok_a1_state.py --kit-manifest` re-derives those parts at
compose time and compares their SHA-256 with `parts.json`, so a derived crop can
never drift from the allowlisted source.

Nothing here touches the runtime tree: derived PNGs go under
`assets_unused/pending_review/a1_kit/derived/`.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import sys
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from hanok_v1_asset_contract import (  # noqa: E402
    ROOT,
    QA_REVIEW_ROOT,
    camera_geometry,
    load_provenance,
    sha256_file,
)

KIT_DOC_ROOT = ROOT / "docs" / "assets" / "hanok_a1_kit"
GEOMETRY_PATH = KIT_DOC_ROOT / "a1_kit_geometry.json"
# Human-confirmed measurements that the automatic proposal must agree with.
# The tool proposes; Jin confirms; the override is the value that ships.
OVERRIDES_PATH = KIT_DOC_ROOT / "a1_kit_overrides.json"
PARTS_REGISTRY_PATH = KIT_DOC_ROOT / "parts.json"
DERIVED_ROOT = QA_REVIEW_ROOT / "a1_kit" / "derived"

ALPHA_THRESHOLD = 8
GEOMETRY_SCHEMA_VERSION = 1

# Pixel-class thresholds. They were tuned on the approved sarangchae and are
# only used to *measure*; the measured values are then locked in the geometry
# JSON and guarded by tests, so a threshold tweak cannot silently move a crop.
WOOD_MIN_RB_DELTA = 30
WOOD_MIN_RED = 80
WOOD_MAX_RED = 210
TILE_MAX_LUM = 95
TILE_MAX_SPREAD = 40
LIGHT_MIN_LUM = 150
STRICT_ALPHA = 200

# Measurement windows (socket-local rows) that are stable for this camera.
PILLAR_SCAN_ROWS = (160, 242)
PILLAR_MIN_WOOD_FRACTION = 0.85
PILLAR_MIN_WIDTH = 9
PILLAR_EXPECTED_COUNT = 8
# The two pillars flanking the centre bay merge with the door jambs in any
# colour mask; the house is mirror-symmetric about the vanishing column, so a
# missing pillar is proposed by mirroring its twin. Proposals must then land
# within this many pixels of the human-confirmed centre in the overrides file.
PILLAR_PROPOSAL_TOLERANCE_PX = 12
PILLAR_TOP_ROW = 157
PILLAR_BOTTOM_ROW = 243
EAVE_SCAN_MAX_ROW = 160
RAFTER_END_LAST_ROW = 144
CHANGBANG_ROWS = (145, 156)
WALL_ROWS = (157, 228)
HABANG_ROWS = (229, 238)
SHADOW_ROWS = (239, 251)
PLATFORM_TOP_ROWS = (252, 263)
PLATFORM_FACE_ROWS = (264, 292)
STEPS_ROWS = (293, 306)
PLATFORM_BACK_ROW = 228
CHOSEOK_TOP_ROW = 244
CHOSEOK_BOTTOM_ROW = 253
CHOSEOK_LEFT_PAD = 4
CHOSEOK_RIGHT_PAD = 5
PILLAR_FOOT_ROW = 244
VANISHING_X = 427
REAR_ROW_DARKEN = 0.86

# Where free-standing props (stakes, timber piles, chimney, shoes, pots) may
# stand: the socket margins beside/below the finished house and the two
# platform-top corner wedges. Everything else must stay inside the finished
# silhouette. Rectangles are [left, top, right, bottom] in socket pixels,
# right/bottom exclusive.
PROPS_ZONE_RECTS = (
    (0, 200, 18, 309),
    (836, 200, 854, 309),
    (0, 293, 349, 309),
    (501, 293, 854, 309),
    (18, 228, 52, 264),
    (800, 228, 836, 264),
)


class DeriveError(ValueError):
    """Fail-closed A1 kit derivation contract violation."""


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise DeriveError(message)


def completed_house_input(provenance: dict[str, Any]) -> dict[str, Any]:
    matches = [
        item
        for item in provenance["allowedModelInputs"]
        if item.get("role") == "completed_house_source"
    ]
    _require(
        len(matches) == 1,
        "provenance must declare exactly one role=completed_house_source input",
    )
    return matches[0]


def load_socket_crop(
    provenance: dict[str, Any] | None = None,
) -> tuple[Image.Image, dict[str, Any]]:
    """Return the allowlisted finished house cropped to the socket, plus its record."""
    payload = provenance or load_provenance()
    record = completed_house_input(payload)
    path = ROOT / record["path"]
    _require(path.exists(), f"completed house source missing: {path}")
    _require(
        sha256_file(path) == str(record["sha256"]),
        "completed house SHA-256 no longer matches the provenance allowlist",
    )
    geometry = camera_geometry(payload)
    with Image.open(path) as source:
        image = source.convert("RGBA")
    _require(
        image.size == (geometry["canvas_width"], geometry["canvas_height"]),
        "completed house canvas does not match the provenance camera",
    )
    box = (
        geometry["socket_x"],
        geometry["socket_y"],
        geometry["socket_x"] + geometry["socket_width"],
        geometry["socket_y"] + geometry["socket_height"],
    )
    return image.crop(box), record


def classify(pixels: np.ndarray) -> dict[str, np.ndarray]:
    """Boolean pixel classes over an RGBA uint8 array (H, W, 4)."""
    rgb = pixels[:, :, :3].astype(np.int32)
    red, green, blue = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    alpha = pixels[:, :, 3].astype(np.int32)
    lum = 0.299 * red + 0.587 * green + 0.114 * blue
    spread = rgb.max(axis=2) - rgb.min(axis=2)
    opaque = alpha > ALPHA_THRESHOLD
    strict = alpha > STRICT_ALPHA
    wood = (
        ((red - blue) >= WOOD_MIN_RB_DELTA)
        & (red >= WOOD_MIN_RED)
        & (red <= WOOD_MAX_RED)
        & strict
    )
    tile = (lum < TILE_MAX_LUM) & (spread < TILE_MAX_SPREAD) & strict
    light = (lum >= LIGHT_MIN_LUM) & strict & ~wood
    return {"opaque": opaque, "strict": strict, "wood": wood, "tile": tile, "light": light}


def _runs(flags: np.ndarray, min_width: int) -> list[tuple[int, int]]:
    runs: list[tuple[int, int]] = []
    start: int | None = None
    for index, value in enumerate(flags.tolist() + [False]):
        if value and start is None:
            start = index
        elif not value and start is not None:
            if index - start >= min_width:
                runs.append((start, index - 1))
            start = None
    return runs


def propose_pillars(masks: dict[str, np.ndarray]) -> list[tuple[int, int]]:
    """Automatic pillar proposal: wood-continuity runs + mirror fill for jamb-merged pillars."""
    top, bottom = PILLAR_SCAN_ROWS
    band = masks["wood"][top : bottom + 1]
    fraction = band.mean(axis=0)
    runs = _runs(fraction >= PILLAR_MIN_WOOD_FRACTION, PILLAR_MIN_WIDTH)
    centers = [(x0 + x1) / 2 for x0, x1 in runs]
    filled = list(runs)
    for x0, x1 in runs:
        mirrored = (2 * VANISHING_X - x1, 2 * VANISHING_X - x0)
        center = (mirrored[0] + mirrored[1]) / 2
        if not any(abs(center - other) < 30 for other in centers):
            filled.append(mirrored)
            centers.append(center)
    filled.sort()
    _require(
        len(filled) == PILLAR_EXPECTED_COUNT,
        f"expected {PILLAR_EXPECTED_COUNT} front pillars, proposed {len(filled)}: {filled}",
    )
    return filled


def load_overrides(path: Path | None = None) -> dict[str, Any]:
    source = path or OVERRIDES_PATH
    _require(source.exists(), f"human-confirmed overrides missing: {source}")
    payload = json.loads(source.read_text(encoding="utf-8"))
    _require(isinstance(payload, dict), "overrides must be a JSON object")
    return payload


def measure_pillars(
    masks: dict[str, np.ndarray],
    overrides: dict[str, Any],
) -> list[tuple[int, int]]:
    """Confirmed pillar spans: overrides win, but the automatic proposal must agree."""
    proposal = propose_pillars(masks)
    confirmed_raw = overrides.get("pillarXRanges")
    _require(
        isinstance(confirmed_raw, list) and len(confirmed_raw) == PILLAR_EXPECTED_COUNT,
        "overrides.pillarXRanges must list exactly 8 [x0, x1] spans",
    )
    confirmed = [(int(x0), int(x1)) for x0, x1 in confirmed_raw]
    for index, ((p0, p1), (c0, c1)) in enumerate(zip(proposal, confirmed, strict=True), start=1):
        _require(c0 < c1, f"pillar {index} override span is empty")
        drift = abs((p0 + p1) / 2 - (c0 + c1) / 2)
        _require(
            drift <= PILLAR_PROPOSAL_TOLERANCE_PX,
            f"pillar {index}: automatic proposal {p0}-{p1} drifted {drift:.1f}px from "
            f"the confirmed span {c0}-{c1}; re-measure before trusting the overrides",
        )
    return confirmed


def measure_eave_line(masks: dict[str, np.ndarray]) -> list[int]:
    """Per column, the last tile-classified row (<= EAVE_SCAN_MAX_ROW), or -1."""
    tile = masks["tile"][: EAVE_SCAN_MAX_ROW + 1]
    width = tile.shape[1]
    eave = [-1] * width
    for x in range(width):
        rows = np.flatnonzero(tile[:, x])
        if rows.size:
            eave[x] = int(rows.max())
    return eave


def _alpha_extent(masks: dict[str, np.ndarray], row: int) -> tuple[int, int]:
    xs = np.flatnonzero(masks["opaque"][row])
    _require(xs.size > 0, f"row {row} has no visible pixels")
    return int(xs.min()), int(xs.max())


def measure_platform(masks: dict[str, np.ndarray]) -> dict[str, Any]:
    back_left, back_right = _alpha_extent(masks, PLATFORM_BACK_ROW)
    face_left, face_right = _alpha_extent(masks, PLATFORM_FACE_ROWS[0])
    steps_left, steps_right = _alpha_extent(masks, STEPS_ROWS[1])
    opaque = masks["opaque"]
    _require(
        not opaque[STEPS_ROWS[1] + 1 :].any(),
        "finished house has visible pixels below the last steps row",
    )
    polygon = [
        [face_left, PLATFORM_FACE_ROWS[0]],
        [face_right, PLATFORM_FACE_ROWS[0]],
        [back_right, PLATFORM_BACK_ROW],
        [back_left, PLATFORM_BACK_ROW],
    ]
    depth = PILLAR_FOOT_ROW - PLATFORM_BACK_ROW
    convergence = (back_left - face_left) / (PLATFORM_FACE_ROWS[0] - PLATFORM_BACK_ROW)
    k = convergence / (VANISHING_X - face_left)
    return {
        "gidanPolygon": polygon,
        "platformBackSpan": [back_left, back_right],
        "platformFaceSpan": [face_left, face_right],
        "stepsBox": [steps_left, STEPS_ROWS[0], steps_right, STEPS_ROWS[1]],
        "perspective": {
            "vanishingX": VANISHING_X,
            "d": depth,
            "k": round(k, 6),
            "rearRowDarken": REAR_ROW_DARKEN,
        },
    }


def part_order(pillar_count: int = PILLAR_EXPECTED_COUNT) -> list[str]:
    """Bottom-to-top z order used by the compositor for the derived parts."""
    order = ["platform"]
    order += [f"choseok_{i}" for i in range(1, pillar_count + 1)]
    order += [f"pillar_{i}" for i in range(1, pillar_count + 1)]
    order += ["band_changbang", "band_rafter_ends", "roof", "band_habang", "wall_shadow"]
    order += [f"panel_{i}" for i in range(1, pillar_count)]
    return order


def build_geometry(
    socket: Image.Image,
    record: dict[str, Any],
    overrides: dict[str, Any] | None = None,
) -> dict[str, Any]:
    confirmed = overrides if overrides is not None else load_overrides()
    pixels = np.array(socket.convert("RGBA"), dtype=np.uint8)
    masks = classify(pixels)
    pillars = measure_pillars(masks, confirmed)
    eave = measure_eave_line(masks)
    platform = measure_platform(masks)
    wall_left, wall_right = _alpha_extent(masks, WALL_ROWS[0])
    height, width = masks["opaque"].shape
    bays = [
        {"index": i + 1, "xRange": [pillars[i][1] + 1, pillars[i + 1][0] - 1]}
        for i in range(len(pillars) - 1)
    ]
    choseok = []
    for index, (x0, x1) in enumerate(pillars, start=1):
        left = x0 - CHOSEOK_LEFT_PAD
        right = x1 + CHOSEOK_RIGHT_PAD
        choseok.append(
            {
                "index": index,
                "polygon": [
                    [left, CHOSEOK_TOP_ROW],
                    [right, CHOSEOK_TOP_ROW],
                    [right + 2, CHOSEOK_BOTTOM_ROW],
                    [left - 2, CHOSEOK_BOTTOM_ROW],
                ],
            }
        )
    tile_rows = [value for value in eave if value >= 0]
    return {
        "schemaVersion": GEOMETRY_SCHEMA_VERSION,
        "source": {"path": record["path"], "sha256": record["sha256"]},
        "overrides": {"path": str(OVERRIDES_PATH.relative_to(ROOT)).replace("\\", "/")},
        "socket": {"width": width, "height": height},
        "alphaThreshold": ALPHA_THRESHOLD,
        "bands": {
            "tileMaxRow": max(tile_rows),
            "eaveRowMin": min(tile_rows),
            "rafterEnds": [min(tile_rows) + 1, RAFTER_END_LAST_ROW],
            "changbang": list(CHANGBANG_ROWS),
            "wall": list(WALL_ROWS),
            "habang": list(HABANG_ROWS),
            "wallShadow": list(SHADOW_ROWS),
            "platformTop": list(PLATFORM_TOP_ROWS),
            "platformFace": list(PLATFORM_FACE_ROWS),
            "steps": list(STEPS_ROWS),
        },
        "wallSpan": [wall_left, wall_right],
        "pillars": [
            {
                "index": index,
                "xRange": [x0, x1],
                "yRange": [PILLAR_TOP_ROW, PILLAR_BOTTOM_ROW],
                # Outer pillars own the anti-aliased fringe out to the wall edge.
                "cropXRange": [
                    wall_left if index == 1 else x0,
                    wall_right if index == len(pillars) else x1,
                ],
            }
            for index, (x0, x1) in enumerate(pillars, start=1)
        ],
        "bays": bays,
        "choseok": choseok,
        "eaveRowByColumn": eave,
        **platform,
        "propsZoneRects": [list(rect) for rect in PROPS_ZONE_RECTS],
        "groundRowExclusive": {
            "stagesUpTo02": PLATFORM_FACE_ROWS[1] + 1,
            "stagesFrom03": STEPS_ROWS[1] + 1,
        },
        "partOrder": part_order(len(pillars)),
    }


def _polygon_mask(shape: tuple[int, int], polygon: list[list[int]]) -> np.ndarray:
    canvas = Image.new("L", (shape[1], shape[0]), 0)
    ImageDraw.Draw(canvas).polygon([tuple(point) for point in polygon], fill=255)
    return np.array(canvas) > 0


def partition_masks(geometry: dict[str, Any], opaque: np.ndarray) -> dict[str, np.ndarray]:
    """Assign every visible socket pixel to exactly one derived part."""
    height, width = opaque.shape
    rows = np.arange(height)[:, None]
    cols = np.arange(width)[None, :]
    assigned = np.zeros_like(opaque)
    parts: dict[str, np.ndarray] = {}

    def take(name: str, mask: np.ndarray) -> None:
        cell = mask & opaque & ~assigned
        parts[name] = cell
        assigned[cell] = True

    eave = np.array(geometry["eaveRowByColumn"])[None, :]
    bands = geometry["bands"]
    take("roof", (rows <= eave) | ((eave < 0) & (rows <= bands["tileMaxRow"])))
    take("band_rafter_ends", rows <= bands["rafterEnds"][1])
    take(
        "band_changbang",
        (rows >= bands["changbang"][0]) & (rows <= bands["changbang"][1]),
    )
    for pillar in geometry["pillars"]:
        x0, x1 = pillar["cropXRange"]
        y0, y1 = pillar["yRange"]
        take(
            f"pillar_{pillar['index']}",
            (rows >= y0) & (rows <= y1) & (cols >= x0) & (cols <= x1),
        )
    for bay in geometry["bays"]:
        x0, x1 = bay["xRange"]
        take(
            f"panel_{bay['index']}",
            (rows >= bands["wall"][0])
            & (rows <= bands["wall"][1])
            & (cols >= x0)
            & (cols <= x1),
        )
    take("band_habang", (rows >= bands["habang"][0]) & (rows <= bands["habang"][1]))
    for stone in geometry["choseok"]:
        take(f"choseok_{stone['index']}", _polygon_mask((height, width), stone["polygon"]))
    back_left, back_right = geometry["platformBackSpan"]
    take(
        "wall_shadow",
        (rows >= bands["wallShadow"][0])
        & (rows <= bands["wallShadow"][1])
        & (cols >= back_left)
        & (cols <= back_right),
    )
    take("platform", np.ones_like(opaque))
    _require(bool((assigned == opaque).all()), "partition did not cover every visible pixel")
    return parts


def synthesize_platform_fill(
    pixels: np.ndarray,
    geometry: dict[str, Any],
    platform_mask: np.ndarray,
) -> np.ndarray:
    """Platform layer for stage 03: real platform pixels plus a deterministic fill
    of the platform-top rows that walls, habang, shadow and choseok hide at 15.

    The fill mirrors each column's own clean top-face strip (platformTop rows)
    upward, so it stays stone-textured and needs no generated art.
    """
    top0, top1 = geometry["bands"]["platformTop"]
    back_row = geometry["gidanPolygon"][2][1]
    back_left, back_right = geometry["platformBackSpan"]
    layer = np.zeros_like(pixels)
    layer[platform_mask] = pixels[platform_mask]
    strip_len = top1 - top0 + 1
    for x in range(back_left, back_right + 1):
        strip = pixels[top0 : top1 + 1, x]
        mirrored = np.concatenate([strip[::-1], strip], axis=0)
        for y in range(back_row, top1 + 1):
            if platform_mask[y, x]:
                continue
            # Only fill under fully opaque finished pixels. Under an anti-aliased
            # rim pixel a fill would blend through and break the stage-15
            # identity with the finished house.
            if pixels[y, x, 3] != 255:
                continue
            offset = (top1 - y) % (2 * strip_len)
            layer[y, x] = mirrored[(2 * strip_len - 1) - offset]
    return layer


def derive_parts(socket: Image.Image, geometry: dict[str, Any]) -> dict[str, Image.Image]:
    pixels = np.array(socket.convert("RGBA"), dtype=np.uint8)
    # Partition every pixel with any alpha at all (not just > alphaThreshold):
    # faint anti-aliasing must land in some part or the stage-15 composite
    # would no longer equal base + finished house pixel for pixel.
    opaque = pixels[:, :, 3] > 0
    masks = partition_masks(geometry, opaque)
    parts: dict[str, Image.Image] = {}
    for name, mask in masks.items():
        if name == "platform":
            layer = synthesize_platform_fill(pixels, geometry, mask)
        else:
            layer = np.zeros_like(pixels)
            layer[mask] = pixels[mask]
        parts[name] = Image.fromarray(layer)
    return parts


def finished_alpha_mask(socket: Image.Image, threshold: int = ALPHA_THRESHOLD) -> Image.Image:
    return socket.getchannel("A").point(lambda value: 255 if value > threshold else 0)


def png_sha256(image: Image.Image) -> str:
    buffer = io.BytesIO()
    image.save(buffer, "PNG")
    return hashlib.sha256(buffer.getvalue()).hexdigest()


def rgba_digest(image: Image.Image) -> str:
    """Encoder-independent digest of an RGBA image (raw bytes, size-prefixed)."""
    rgba = image.convert("RGBA")
    header = f"{rgba.width}x{rgba.height}:".encode()
    return hashlib.sha256(header + rgba.tobytes()).hexdigest()


def update_parts_registry(
    parts: dict[str, Image.Image],
    path: Path | None = None,
) -> dict[str, Any]:
    """Write derived rgbaSha256 digests into parts.json, keeping generated entries."""
    target = path or PARTS_REGISTRY_PATH
    if target.exists():
        registry = json.loads(target.read_text(encoding="utf-8"))
        _require(registry.get("schemaVersion") == 1, "unsupported parts registry schema")
    else:
        registry = {"schemaVersion": 1, "derived": {}, "generated": {}}
    registry["derived"] = {
        name: {"rgbaSha256": rgba_digest(image), "file": f"{DERIVED_ROOT.relative_to(ROOT).as_posix()}/{name}.png"}
        for name, image in parts.items()
    }
    registry.setdefault("generated", {})
    target.write_text(json.dumps(registry, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return registry


def write_outputs(geometry: dict[str, Any], parts: dict[str, Image.Image]) -> dict[str, str]:
    KIT_DOC_ROOT.mkdir(parents=True, exist_ok=True)
    DERIVED_ROOT.mkdir(parents=True, exist_ok=True)
    GEOMETRY_PATH.write_text(
        json.dumps(geometry, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    digests: dict[str, str] = {}
    for name, image in parts.items():
        target = DERIVED_ROOT / f"{name}.png"
        image.save(target, "PNG")
        digests[name] = sha256_file(target)
    update_parts_registry(parts)
    return digests


def load_geometry(path: Path | None = None) -> dict[str, Any]:
    source = path or GEOMETRY_PATH
    payload = json.loads(source.read_text(encoding="utf-8"))
    _require(
        payload.get("schemaVersion") == GEOMETRY_SCHEMA_VERSION,
        "unsupported a1_kit_geometry schema",
    )
    return payload


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="re-derive and compare with the committed geometry JSON; write nothing",
    )
    args = parser.parse_args(argv)
    socket, record = load_socket_crop()
    geometry = build_geometry(socket, record)
    parts = derive_parts(socket, geometry)
    if args.check:
        committed = load_geometry()
        _require(
            committed == geometry,
            "committed a1_kit_geometry.json differs from a fresh derivation",
        )
        print(json.dumps({"status": "ok", "parts": sorted(parts)}, indent=2))
        return 0
    digests = write_outputs(geometry, parts)
    print(
        json.dumps(
            {"geometry": str(GEOMETRY_PATH.relative_to(ROOT)), "parts": digests},
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except DeriveError as error:
        print(f"[fail] {error}")
        raise SystemExit(1)
