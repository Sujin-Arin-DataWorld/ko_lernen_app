#!/usr/bin/env python3
"""Derive B1/B2 estate-building construction stages from finished PNGs.

Unlike the A1 kit (a single sarangchae socket, hand-measured pillar/platform
geometry), the 6 B1/B2 targets are full-canvas RGBA PNGs that are already
correctly positioned/scaled on the estate map. Their stage geometry is
heterogeneous -- stepped rooflines, three-zone buildings, a non-row landscape
-- and `classify()` from `derive_hanok_a1_kit.py` was confirmed unreliable
across all of them by a dedicated geometry-research pass (see
docs/assets/hanok_estate_kit/*_stages.json "note" fields for the measured
findings this tool's specs are built from). So there is no `--propose` mode
here: each building's spec JSON already encodes hand-measured row/region
boundaries as the source of truth, the same pattern `a1_kit_overrides.json`
uses for the A1 pipeline.

Stage kinds:
  * "reveal"       -- per-window row cut. `rowMin[window]` reveals
                       finished_alpha rows >= rowMin for that window's
                       xRange; the true per-column bottom comes from
                       finished_alpha itself (no synthesized rectangle).
                       An optional `frame[window]` = {band:[lo,hi], rawKey}
                       sources that specific row band from an aligned
                       generated layer instead of the finished PNG (clipped
                       to finished_alpha for containment).
  * "regionUnion"  -- union of named rectangular regions (with optional
                       `subtract` rectangle), intersected with finished_alpha.
                       Used for rear_garden, which is not row-based.
  * "final"        -- byte-identical alias of the existing runtime PNG.

Modes:
  --emit-prompt   print the KEEP/REMOVE/ADD edit_image prompt for a building
                  that needs a generated frame layer (raises if none needed).
  --align RAW     chroma-key-decode a raw BBANANA output, clip it to the
                  finished building's own silhouette (dilate=0), and save it
                  as the aligned frame layer at the expected path.
  --build         build every stage currently possible (crop/regionUnion
                  stages always; composite stages only once their aligned
                  frame layer exists on disk) and run all gates.
  --check         recompute stage masks from the spec and verify the on-disk
                  stage PNGs match (drift check, no writes).

Usage:
    /usr/local/bin/python3.12 tool/derive_estate_building_stages.py sotdaeulmun --build
    /usr/local/bin/python3.12 tool/derive_estate_building_stages.py sotdaeulmun --emit-prompt
    /usr/local/bin/python3.12 tool/derive_estate_building_stages.py sotdaeulmun \\
        --align assets_unused/pending_review/estate_stages/sotdaeulmun/raw/sotdaeulmun_frame_raw.png
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
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from cut_prop_sheet import chroma_to_alpha  # noqa: E402
from hanok_v1_asset_contract import ROOT  # noqa: E402

ALPHA_THRESHOLD = 8
SPEC_ROOT = ROOT / "docs" / "assets" / "hanok_estate_kit"
PENDING_ROOT = ROOT / "assets_unused" / "pending_review" / "estate_stages"

BUILDINGS = (
    "sotdaeulmun",
    "haengrangchae",
    "anchae",
    "daecheongmaru",
    "sadang",
    "rear_garden",
)


class StageError(ValueError):
    """Fail-closed estate-stage contract violation."""


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise StageError(message)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def load_spec(building: str) -> dict[str, Any]:
    _require(building in BUILDINGS, f"unknown building {building!r}, expected one of {BUILDINGS}")
    path = SPEC_ROOT / f"{building}_stages.json"
    _require(path.is_file(), f"missing spec {path}")
    spec = json.loads(path.read_text(encoding="utf-8"))
    _require(spec.get("schemaVersion") == 1, f"unsupported schema in {path}")
    return spec


def load_finished(spec: dict[str, Any]) -> Image.Image:
    source = ROOT / spec["source"]
    _require(source.is_file(), f"missing source {source}")
    actual_sha = sha256_file(source)
    expected_sha = spec["sourceSha256"]
    _require(
        actual_sha == expected_sha,
        f"{source} sha256 {actual_sha} != spec {expected_sha} (source changed since spec was written)",
    )
    image = Image.open(source).convert("RGBA")
    width, height = spec["canvas"]
    _require((image.width, image.height) == (width, height), f"{source} is {image.size}, expected {(width, height)}")
    return image


def alpha_mask(image: Image.Image, threshold: int = ALPHA_THRESHOLD) -> np.ndarray:
    return np.array(image.getchannel("A")) > threshold


def rgba_array(image: Image.Image) -> np.ndarray:
    return np.array(image.convert("RGBA"))


def stage_dir(building: str) -> Path:
    return PENDING_ROOT / building


def frame_layer_path(building: str, raw_key: str) -> Path:
    return stage_dir(building) / f"{raw_key}_aligned.png"


# ---------------------------------------------------------------------------
# Mask builders
# ---------------------------------------------------------------------------


def _window_column_mask(shape: tuple[int, int], x_range: list[int]) -> np.ndarray:
    height, width = shape
    mask = np.zeros((height, width), dtype=bool)
    x0, x1 = x_range
    mask[:, max(0, x0) : min(width, x1)] = True
    return mask


def build_reveal_stage(
    finished: np.ndarray,
    finished_alpha: np.ndarray,
    spec: dict[str, Any],
    stage: dict[str, Any],
    frame_layers: dict[str, np.ndarray],
) -> tuple[np.ndarray, np.ndarray]:
    """Return (rgba, generated_mask) for a "reveal" stage.

    `generated_mask` marks pixels sourced from an aligned generated frame
    layer, as opposed to a plain crop of the finished PNG -- only those
    pixels are meaningful to scan for leftover chroma-key residue; the
    finished PNG is painterly artwork that can legitimately contain
    green-toned pixels (foliage, shadow) with no chroma-key history at all.
    """
    shape = finished_alpha.shape
    out = np.zeros((*shape, 4), dtype=np.uint8)
    generated_mask = np.zeros(shape, dtype=bool)
    row_idx = np.arange(shape[0]).reshape(-1, 1)

    for window in spec["windows"]:
        wid = window["id"]
        row_min = stage["rowMin"].get(wid)
        if row_min is None:
            continue
        col_mask = _window_column_mask(shape, window["xRange"])
        reveal_mask = col_mask & (row_idx >= row_min) & finished_alpha

        frame_spec = stage.get("frame", {}).get(wid)
        if frame_spec is not None:
            lo, hi = frame_spec["band"]
            band_mask = reveal_mask & (row_idx >= lo) & (row_idx <= hi)
            crop_mask = reveal_mask & ~band_mask
            raw_key = frame_spec["rawKey"]
            layer = frame_layers.get(raw_key)
            _require(layer is not None, f"frame layer {raw_key!r} not aligned yet (run --align first)")
            frame_alpha = (layer[..., 3] > ALPHA_THRESHOLD) & band_mask
            out[frame_alpha] = layer[frame_alpha]
            generated_mask |= frame_alpha
            out[crop_mask] = finished[crop_mask]
        else:
            out[reveal_mask] = finished[reveal_mask]

    return out, generated_mask


def build_region_union_stage(
    finished: np.ndarray,
    finished_alpha: np.ndarray,
    spec: dict[str, Any],
    stage: dict[str, Any],
) -> np.ndarray:
    shape = finished_alpha.shape
    mask = np.zeros(shape, dtype=bool)
    for region_id in stage["regions"]:
        region = spec["regions"][region_id]
        x0, y0, x1, y1 = region["box"]
        region_mask = np.zeros(shape, dtype=bool)
        region_mask[y0:y1, x0:x1] = True
        if "subtract" in region:
            sx0, sy0, sx1, sy1 = region["subtract"]
            region_mask[sy0:sy1, sx0:sx1] = False
        mask |= region_mask
    mask &= finished_alpha
    out = np.zeros((*shape, 4), dtype=np.uint8)
    out[mask] = finished[mask]
    return out


# ---------------------------------------------------------------------------
# Gates
# ---------------------------------------------------------------------------


def assert_containment(stage_alpha: np.ndarray, finished_alpha: np.ndarray) -> None:
    violations = int((stage_alpha & ~finished_alpha).sum())
    _require(violations == 0, f"{violations} visible px lie outside the finished silhouette (containment)")


def assert_structural_continuity(previous_alpha: np.ndarray, current_alpha: np.ndarray) -> float:
    previous_count = int(previous_alpha.sum())
    if previous_count == 0:
        return 1.0
    recall = float((previous_alpha & current_alpha).sum()) / previous_count
    _require(recall == 1.0, f"structural continuity recall {recall:.4f} != 1.0 (previous stage pixels vanished)")
    return recall


def assert_chroma_clean(rgb: np.ndarray, alpha: np.ndarray, generated_mask: np.ndarray | None) -> None:
    """Only meaningful for pixels sourced from a generated (chroma-decoded)
    frame layer -- plain crops of the finished painterly PNG are not scanned,
    since they can legitimately contain green-toned foliage/shadow pixels
    that never went through a chroma key at all."""
    if generated_mask is None or not generated_mask.any():
        return
    visible = (alpha > ALPHA_THRESHOLD) & generated_mask
    if not visible.any():
        return
    r = rgb[..., 0].astype(np.int16)
    g = rgb[..., 1].astype(np.int16)
    b = rgb[..., 2].astype(np.int16)
    greenness = g - np.maximum(r, b)
    residue = int(((greenness >= 40) & visible).sum())
    _require(residue == 0, f"{residue} px look like leftover chroma-key green in the generated frame layer (chroma gate)")


def encode_png(rgba: np.ndarray) -> bytes:
    buffer = io.BytesIO()
    Image.fromarray(rgba, "RGBA").save(buffer, "PNG", optimize=True)
    return buffer.getvalue()


def assert_byte_budget(data: bytes, spec: dict[str, Any]) -> None:
    limit = int(spec.get("maxBytesPerStage", 350_000))
    _require(len(data) <= limit, f"{len(data)} bytes exceeds the {limit} byte budget for this building")


# ---------------------------------------------------------------------------
# Frame prompts (KEEP/REMOVE/ADD skeleton, adapted per building from the A1
# lineage prompt `260fb03750d14f34a4c5674d293cc78d` in a1_kit_prompts.json).
# ---------------------------------------------------------------------------

FRAME_PROMPTS: dict[str, str] = {
    "sotdaeulmun": """Edit this illustration of a finished traditional Korean raised gate house (솟을대문, a three-bay gate with a taller central bay and two lower flanking wings), seen straight from the front in a slightly elevated view. Show the SAME building at the timber-frame stage of construction, BEFORE the roof was covered and BEFORE the door leaves were hung. Keep the camera, framing, scale, position and lighting exactly as in the input: do not rotate the view, do not zoom, do not move the building.

KEEP UNCHANGED, pixel for pixel: the stone platform and steps at the base, and every wooden post/column exactly where it is (same thickness, same height, same spacing) in all three bays.

REMOVE completely: all roof tiles on all three roof sections, the ridge beams, the roof boards, both wing walls (the closed panel walls with their small windows), and the central gate's two door leaves -- so every bay's frame is open and you can see through it.

ADD the exposed timber frame each bay needs under its roof, in the same painterly wood-grain style and warm wood colors as the visible posts in the input:
- a head beam along the top of each bay's row of posts,
- for the two lower wing bays: purlins and a ridge beam sized for their own lower roofline,
- for the taller central bay: its own higher purlins and ridge beam, matching the stepped-roof proportions of the input,
- no infill panels between the posts anywhere -- the whole post-and-beam structure must read as open framing.

NO rafters, NO roof boards, NO tiles, NO wall panels, NO door leaves, NO ground, NO cast shadows on the ground, NO people, NO text. The whole frame must stay inside the silhouette the finished building occupies in the input.

Background: replace everything outside the object with flat, pure #00FF00 chroma-key green, no gradient.""",
    "haengrangchae": """Edit this illustration of a finished traditional Korean servants'-quarters row house (행랑채, a long low single-story wing), seen straight from the front in a slightly elevated view. Show the SAME building at the timber-frame stage of construction, BEFORE the roof was covered and BEFORE any wall panels, lattice doors or windows were installed. Keep the camera, framing, scale, position and lighting exactly as in the input: do not rotate the view, do not zoom, do not move the building.

KEEP UNCHANGED, pixel for pixel: the ground line at the base and every wooden post/column along the front exactly where it is (same thickness, same height, same spacing).

REMOVE completely: all roof tiles, the ridge beam and its two small end ornaments, the roof boards, and the entire closed wall (including its lattice-window band) -- so the frame is open and you can see through it.

ADD the exposed timber frame the row house needs under its roof, in the same painterly wood-grain style and warm wood colors as the visible posts in the input: a continuous head beam along the top of the front posts, a matching rear head beam, cross beams running from each front post back to its rear counterpart, purlins resting above the beams, and one ridge beam running the full length at the very top. No infill wall panels anywhere -- the whole post-and-beam structure must read as open framing.

NO rafters, NO roof boards, NO tiles, NO wall panels, NO lattice, NO ground, NO cast shadows on the ground, NO people, NO text. The whole frame must stay inside the silhouette the finished building occupies in the input.

Background: replace everything outside the object with flat, pure #00FF00 chroma-key green, no gradient.""",
    "anchae": """Edit this illustration of a finished traditional Korean ㄷ-shaped main house (안채: a left wing, a set-back open center hall, and a right wing), seen straight from the front in a slightly elevated view. Show the SAME building at the timber-frame stage of construction, BEFORE any of the three sections' roofs were covered and BEFORE any wall panels, lattice doors or windows were installed anywhere. Keep the camera, framing, scale, position and lighting exactly as in the input: do not rotate the view, do not zoom, do not move the building.

KEEP UNCHANGED, pixel for pixel: the stone platforms and steps at the base of all three sections, and every wooden post/column in all three sections exactly where it is (same thickness, same height, same spacing, including the center hall's posts standing further back in the isometric view).

REMOVE completely: all roof tiles on all three sections, all ridge beams, the roof boards, both wings' closed walls (including their small windows and the little chimney-like bulge on each wing's outer wall), and the center hall's own wall/lattice-door band -- so every section's frame is open and you can see through it.

ADD the exposed timber frame each of the three sections needs under its roof, in the same painterly wood-grain style and warm wood colors as the visible posts in the input:
- a head beam along the top of each section's row of posts,
- cross beams and purlins for each section's own roofline (the two wings are lower and closer to the viewer, the center hall is higher and set back -- keep that same depth relationship),
- one ridge beam per section at the very top, matching each section's own proportions from the input.

NO rafters, NO roof boards, NO tiles, NO wall panels, NO lattice, NO chimney bulge, NO ground, NO cast shadows on the ground, NO people, NO text. The whole frame in all three sections must stay inside the silhouette the finished building occupies in the input.

Background: replace everything outside the object with flat, pure #00FF00 chroma-key green, no gradient.""",
    "sadang": """Edit this illustration of a finished traditional Korean ancestral shrine (사당, a single small gabled building with two tiny decorative wall-post fragments flanking it), seen straight from the front in a slightly elevated view. Show the SAME building at the timber-frame stage of construction, BEFORE the roof was covered and BEFORE the wall and door were installed. Keep the camera, framing, scale, position and lighting exactly as in the input: do not rotate the view, do not zoom, do not move the building.

KEEP UNCHANGED, pixel for pixel: the stone platform and front step/threshold at the base, the two small decorative corner wall-post fragments on the far left and right, and every wooden post/column of the shrine itself exactly where it is (same thickness, same height, same spacing).

REMOVE completely: all roof tiles, the ridge beam, the roof boards, and the shrine's closed wall and door -- so the frame is open and you can see through it.

ADD the exposed timber frame the shrine needs under its roof, in the same painterly wood-grain style and warm wood colors as the visible posts in the input: a head beam along the top of the posts, cross beams, purlins resting above them, and one ridge beam at the very top.

NO rafters, NO roof boards, NO tiles, NO wall panel, NO door, NO ground, NO cast shadows on the ground, NO people, NO text. The frame must stay inside the silhouette the finished building occupies in the input; the two corner wall-post fragments must stay exactly as they are in the input, unchanged.

Background: replace everything outside the object with flat, pure #00FF00 chroma-key green, no gradient.""",
}


def emit_prompt(building: str) -> str:
    _require(building in FRAME_PROMPTS, f"{building} needs no generated frame stage (daecheongmaru/rear_garden are pure crops)")
    return FRAME_PROMPTS[building]


# ---------------------------------------------------------------------------
# --align
# ---------------------------------------------------------------------------


def _tight_alpha_bbox(alpha: np.ndarray) -> tuple[int, int, int, int]:
    ys, xs = np.nonzero(alpha > ALPHA_THRESHOLD)
    _require(len(ys) > 0, "raw generation is fully transparent after chroma-keying")
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def align_frame(
    building: str,
    raw_path: Path,
    raw_key: str,
    spec: dict[str, Any],
    *,
    target_bbox: tuple[int, int, int, int] | None = None,
) -> Path:
    """Chroma-decode a raw BBANANA output and clip it to the finished
    building's silhouette. If the raw output isn't already a full 1536x1152
    canvas (e.g. `edit_image` returned a fixed aspect ratio like 2400x1792
    instead of preserving the uploaded crop's own aspect), pass
    `target_bbox` = the canvas rectangle the generated subject should land
    in (typically the finished building's own measured alpha bbox); the raw
    content is cropped to its own tight alpha bbox, rescaled to fill
    `target_bbox` exactly, and pasted onto a blank canvas at that offset
    before clipping. This assumes the model preserved framing (no
    zoom/move), which the prompt explicitly instructs.
    """
    _require(raw_path.is_file(), f"missing raw generation output {raw_path}")
    with Image.open(raw_path) as source:
        rgb = np.array(source.convert("RGB"))
    despilled, alpha = chroma_to_alpha(rgb)
    raw_layer = np.dstack([despilled, alpha])

    finished = load_finished(spec)
    finished_alpha = alpha_mask(finished)
    width, height = spec["canvas"]

    if target_bbox is not None:
        rx0, ry0, rx1, ry1 = _tight_alpha_bbox(raw_layer[..., 3])
        cropped = Image.fromarray(raw_layer[ry0:ry1, rx0:rx1])
        tx0, ty0, tx1, ty1 = target_bbox
        resized = np.array(cropped.resize((tx1 - tx0, ty1 - ty0), Image.LANCZOS))
        # LANCZOS interpolation blends slightly-despilled edge pixels with
        # their neighbours and can reintroduce a faint green tint; a second
        # despill pass on the resized RGB (alpha untouched) cleans most of
        # this up. What survives is exclusively very-low-alpha rim noise
        # (<24/255, confirmed empirically) with no real content -- drop it.
        redespilled, _ = chroma_to_alpha(resized[..., :3])
        resized_alpha = resized[..., 3]
        resized_alpha = np.where(resized_alpha < 24, 0, resized_alpha).astype(np.uint8)
        resized = np.dstack([redespilled, resized_alpha])
        canvas = np.zeros((height, width, 4), dtype=np.uint8)
        canvas[ty0:ty1, tx0:tx1] = resized
        raw_layer = canvas
        print(
            f"[align] {raw_key}: raw bbox {(rx0, ry0, rx1, ry1)} "
            f"({rx1 - rx0}x{ry1 - ry0}) -> target {target_bbox} "
            f"({tx1 - tx0}x{ty1 - ty0})"
        )
    else:
        _require(
            raw_layer.shape[1] == width and raw_layer.shape[0] == height,
            f"raw layer is {raw_layer.shape[1]}x{raw_layer.shape[0]}, expected {width}x{height} "
            "(pass --target-bbox to rescale a cropped generation, or pre-paste it onto a full canvas)",
        )

    clipped_alpha = (raw_layer[..., 3] > ALPHA_THRESHOLD) & finished_alpha
    out = np.zeros_like(raw_layer)
    out[clipped_alpha] = raw_layer[clipped_alpha]
    visible = int(clipped_alpha.sum())
    _require(visible >= 200, f"only {visible} px survived clipping to the finished silhouette -- likely misaligned")

    target = frame_layer_path(building, raw_key)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(encode_png(out.astype(np.uint8)))
    print(f"[ok] aligned {raw_key} -> {target} ({visible} px survived clip, {target.stat().st_size} B)")
    return target


def load_frame_layers(building: str, spec: dict[str, Any]) -> dict[str, np.ndarray]:
    layers: dict[str, np.ndarray] = {}
    raw_keys: set[str] = set()
    for stage in spec["stages"]:
        for frame_spec in stage.get("frame", {}).values():
            raw_keys.add(frame_spec["rawKey"])
    for raw_key in raw_keys:
        path = frame_layer_path(building, raw_key)
        if path.is_file():
            layers[raw_key] = rgba_array(Image.open(path))
    return layers


# ---------------------------------------------------------------------------
# --build / --check
# ---------------------------------------------------------------------------


def build_all_stages(building: str, *, write: bool) -> dict[str, Any]:
    spec = load_spec(building)
    finished_image = load_finished(spec)
    finished = rgba_array(finished_image)
    finished_alpha = alpha_mask(finished_image)
    frame_layers = load_frame_layers(building, spec)

    out_dir = stage_dir(building)
    if write:
        out_dir.mkdir(parents=True, exist_ok=True)

    ledger: dict[str, Any] = {"building": building, "stages": []}
    previous_alpha: np.ndarray | None = None
    skipped: list[str] = []

    for stage in spec["stages"]:
        stage_id = stage["id"]
        kind = stage["kind"]

        if kind == "final":
            data = (ROOT / spec["source"]).read_bytes()
            rgba = rgba_array(Image.open(io.BytesIO(data)).convert("RGBA"))
            stage_alpha = alpha_mask(Image.open(io.BytesIO(data)))
            generated_mask = None
        elif kind == "reveal":
            missing = [
                frame_spec["rawKey"]
                for st in [stage]
                for frame_spec in st.get("frame", {}).values()
                if frame_spec["rawKey"] not in frame_layers
            ]
            if missing:
                skipped.append(f"{stage_id} (waiting on aligned frame layer: {sorted(set(missing))})")
                continue
            rgba, generated_mask = build_reveal_stage(finished, finished_alpha, spec, stage, frame_layers)
            stage_alpha = rgba[..., 3] > ALPHA_THRESHOLD
        elif kind == "regionUnion":
            rgba = build_region_union_stage(finished, finished_alpha, spec, stage)
            stage_alpha = rgba[..., 3] > ALPHA_THRESHOLD
            generated_mask = None
        else:
            raise StageError(f"unknown stage kind {kind!r}")

        assert_containment(stage_alpha, finished_alpha)
        if previous_alpha is not None:
            recall = assert_structural_continuity(previous_alpha, stage_alpha)
        else:
            recall = 1.0
        assert_chroma_clean(rgba[..., :3], rgba[..., 3], generated_mask)
        if kind == "final":
            # `data` is already the raw, untouched bytes of the approved
            # runtime file (read above) -- re-encoding through Pillow would
            # not reliably reproduce the exact same bytes, which would break
            # the "final stage is byte-identical to the existing file" gate.
            expected_sha = spec["sourceSha256"]
            _require(
                sha256_bytes(data) == expected_sha,
                "final stage bytes do not match the source sha256 (should be unreachable, load_finished already checked this)",
            )
        else:
            data = encode_png(rgba)
            assert_byte_budget(data, spec)

        digest = sha256_bytes(data)
        target = out_dir / f"{building}_{stage_id}.png"
        if write:
            target.write_bytes(data)

        visible_px = int(stage_alpha.sum())
        ledger["stages"].append(
            {
                "id": stage_id,
                "label": stage.get("label"),
                "kind": kind,
                "file": str(target.relative_to(ROOT)) if write else None,
                "sha256": digest,
                "bytes": len(data),
                "visiblePx": visible_px,
                "recall": recall,
            }
        )
        print(f"[ok] {building}/{stage_id} visible={visible_px}px bytes={len(data)} recall={recall:.4f} sha={digest[:12]}")
        previous_alpha = stage_alpha

    for message in skipped:
        print(f"[skip] {building}/{message}")

    if write:
        ledger_path = SPEC_ROOT / f"{building}_stages_ledger.json"
        ledger_path.write_text(json.dumps(ledger, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    return ledger


def check_stages(building: str) -> int:
    ledger = build_all_stages(building, write=False)
    ledger_path = SPEC_ROOT / f"{building}_stages_ledger.json"
    if not ledger_path.is_file():
        print(f"[fail] no ledger at {ledger_path} to check against (run --build first)")
        return 1
    on_disk = json.loads(ledger_path.read_text(encoding="utf-8"))
    problems = 0
    fresh_by_id = {s["id"]: s for s in ledger["stages"]}
    for stage in on_disk["stages"]:
        fresh = fresh_by_id.get(stage["id"])
        if fresh is None:
            print(f"[fail] {building}/{stage['id']}: stage no longer produced by the current spec")
            problems += 1
            continue
        if fresh["sha256"] != stage["sha256"]:
            print(f"[fail] {building}/{stage['id']}: sha256 drift {stage['sha256'][:12]} -> {fresh['sha256'][:12]}")
            problems += 1
        else:
            print(f"[pass] {building}/{stage['id']} sha={fresh['sha256'][:12]}")
    return 1 if problems else 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("building", choices=BUILDINGS)
    parser.add_argument("--emit-prompt", action="store_true")
    parser.add_argument("--align", type=Path, help="raw BBANANA output PNG to chroma-decode and clip")
    parser.add_argument("--frame-key", help="rawKey this --align output should be saved as (required with --align)")
    parser.add_argument(
        "--target-bbox",
        help="x0,y0,x1,y1 canvas rect to rescale a cropped raw generation into (see align_frame docstring)",
    )
    parser.add_argument("--build", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args(argv)

    if args.emit_prompt:
        print(emit_prompt(args.building))
        return 0
    if args.align:
        _require(bool(args.frame_key), "--align needs --frame-key")
        spec = load_spec(args.building)
        target_bbox = None
        if args.target_bbox:
            parts = [int(p) for p in args.target_bbox.split(",")]
            _require(len(parts) == 4, "--target-bbox needs exactly 4 comma-separated ints")
            target_bbox = (parts[0], parts[1], parts[2], parts[3])
        align_frame(args.building, args.align, args.frame_key, spec, target_bbox=target_bbox)
        return 0
    if args.check:
        return check_stages(args.building)
    if args.build:
        build_all_stages(args.building, write=True)
        return 0

    parser.print_help()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
