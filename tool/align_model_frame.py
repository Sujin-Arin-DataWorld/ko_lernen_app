#!/usr/bin/env python3
"""Align a generated hanok frame image onto the A1 kit geometry.

A generative model never returns our exact camera: it re-frames, rescales and
redraws its own platform. Instead of asking it to be pixel-exact, we let it draw
the *timber frame* freely and then fit it onto the kit geometry here:

1. drop the chroma-key background,
2. measure the model's stone platform top row and its front column runs,
3. solve the affine map (x' = ax + b, y' = cy + d) that puts the model's front
   column centres on the kit's eight measured centres, its column feet on the
   kit foot row and its column heads on the kit head row,
4. warp, then keep only the pixels the stage needs (above the column heads,
   i.e. the frame the kit has no derived part for).

The result is a socket-sized RGBA part; `compose_hanok_a1_state.py --kit-manifest`
then applies the usual containment / continuity / size gates.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from derive_hanok_a1_kit import (  # noqa: E402
    finished_alpha_mask,
    load_geometry,
    load_socket_crop,
)

CHROMA_GREEN_MIN = 140
CHROMA_OTHER_MAX = 130
STONE_MIN_LUM = 150
STONE_MAX_SPREAD = 45
WOOD_MIN_RB_DELTA = 40
COLUMN_MIN_FRACTION = 0.8
COLUMN_MIN_WIDTH_RATIO = 0.006  # of image width


class AlignError(ValueError):
    """Fail-closed alignment contract violation."""


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise AlignError(message)


def load_object(path: Path) -> tuple[np.ndarray, np.ndarray]:
    """Return (RGB array, object mask) with the chroma-key background removed."""
    with Image.open(path) as source:
        rgb = np.array(source.convert("RGB"), dtype=np.int32)
    green = (
        (rgb[:, :, 1] >= CHROMA_GREEN_MIN)
        & (rgb[:, :, 0] <= CHROMA_OTHER_MAX)
        & (rgb[:, :, 2] <= CHROMA_OTHER_MAX)
    )
    obj = ~green
    _require(obj.any(), f"{path} has no object outside the chroma-key background")
    return rgb, obj


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


def measure_model(rgb: np.ndarray, obj: np.ndarray) -> dict[str, Any]:
    height, width = obj.shape
    lum = 0.299 * rgb[:, :, 0] + 0.587 * rgb[:, :, 1] + 0.114 * rgb[:, :, 2]
    spread = rgb.max(axis=2) - rgb.min(axis=2)
    stone = obj & (lum > STONE_MIN_LUM) & (spread < STONE_MAX_SPREAD)
    stone_rows = np.flatnonzero(stone.any(axis=1))
    _require(stone_rows.size > 0, "no stone platform found in the model image")
    platform_top = int(stone_rows.min())
    wood = obj & ((rgb[:, :, 0] - rgb[:, :, 2]) >= WOOD_MIN_RB_DELTA)
    # scan a band that sits above the platform: the free column shafts
    band_bottom = max(1, platform_top - int(0.02 * height))
    band_top = max(0, band_bottom - int(0.14 * height))
    fraction = wood[band_top:band_bottom].mean(axis=0)
    runs = _runs(
        fraction >= COLUMN_MIN_FRACTION,
        max(4, int(COLUMN_MIN_WIDTH_RATIO * width)),
    )
    _require(len(runs) >= 4, f"found only {len(runs)} column runs in the model image")
    centres = [(a + b) / 2 for a, b in runs]
    # Column head row: walk UP each detected shaft from just above the platform
    # while it stays wood (small gaps allowed) and take the median stop row. The
    # topmost row that crosses every column would be the ridge, not the head.
    columns = [int(round(c)) for c in centres]
    gap_allowance = max(2, int(0.004 * height))
    heads: list[int] = []
    for x in columns:
        y = platform_top - 2
        gap = 0
        while y > 0:
            if wood[y, x]:
                gap = 0
            else:
                gap += 1
                if gap > gap_allowance:
                    break
            y -= 1
        heads.append(y + gap)
    head_row = int(np.median(heads))
    wood_rows = np.flatnonzero(wood.any(axis=1))
    return {
        "platformTop": platform_top,
        "columnHeadRows": heads,
        "columnRuns": runs,
        "columnCentres": centres,
        "headRow": head_row,
        "woodTop": int(wood_rows.min()),
        "size": [width, height],
    }


def fit_affine(
    model: dict[str, Any],
    geometry: dict[str, Any],
    *,
    ridge_row: int | None = None,
) -> dict[str, float]:
    """Horizontal fit on the outermost column centres + two-point vertical fit.

    Vertically we anchor the model's column head row on the kit head row. The
    second anchor is either the kit column foot row (faithful column height, used
    when checking a model's own proportions) or, for a frame part, `ridge_row`:
    the frame band (model head .. model ridge) is then stretched onto the kit band
    (head row .. ridge_row) so the timber frame fills the volume the finished roof
    occupies. Members stay horizontal, only their spacing changes.
    """
    kit_centres = [(p["xRange"][0] + p["xRange"][1]) / 2 for p in geometry["pillars"]]
    found = sorted(model["columnCentres"])
    _require(len(found) >= 2, "need at least two column centres to fit")
    model_span = found[-1] - found[0]
    kit_span = kit_centres[-1] - kit_centres[0]
    _require(model_span > 0 and kit_span > 0, "degenerate column span")
    a = kit_span / model_span
    b = kit_centres[0] - a * found[0]
    head_row = float(geometry["pillars"][0]["yRange"][0])
    model_head = float(model["headRow"])
    if ridge_row is None:
        second_kit = float(geometry["choseok"][0]["polygon"][0][1])
        second_model = float(model["platformTop"])
        _require(second_model > model_head, "model head row is not above its platform")
    else:
        second_kit = float(ridge_row)
        second_model = float(model["woodTop"])
        _require(second_model < model_head, "model ridge is not above its column heads")
    c = (second_kit - head_row) / (second_model - model_head)
    d = head_row - c * model_head
    return {"a": a, "b": b, "c": c, "d": d}


def warp(
    rgb: np.ndarray,
    obj: np.ndarray,
    fit: dict[str, float],
    geometry: dict[str, Any],
) -> Image.Image:
    width = int(geometry["socket"]["width"])
    height = int(geometry["socket"]["height"])
    rgba = np.dstack([rgb.astype(np.uint8), (obj * 255).astype(np.uint8)])
    source = Image.fromarray(rgba, "RGBA")
    # PIL's AFFINE maps output -> input, so invert our forward map
    a, b, c, d = fit["a"], fit["b"], fit["c"], fit["d"]
    matrix = (1 / a, 0, -b / a, 0, 1 / c, -d / c)
    return source.transform(
        (width, height),
        Image.Transform.AFFINE,
        matrix,
        resample=Image.Resampling.BICUBIC,
    )


def frame_only(
    layer: Image.Image,
    geometry: dict[str, Any],
    keep_below_head: int,
) -> Image.Image:
    """Keep the frame above the kit column heads (plus an optional overlap band)."""
    array = np.array(layer, dtype=np.uint8)
    head_row = int(geometry["pillars"][0]["yRange"][0])
    cut = head_row + max(0, keep_below_head)
    array[cut:, :, 3] = 0
    return Image.fromarray(array)


def align(
    image_path: Path,
    output_path: Path,
    *,
    keep_below_head: int = 0,
    ridge_row: int | None = None,
    top_row: int = 0,
    fit_from: Path | None = None,
    clip_dilate_px: int = 1,
    geometry: dict[str, Any] | None = None,
) -> dict[str, Any]:
    kit = geometry or load_geometry()
    rgb, obj = load_object(image_path)
    if fit_from is None:
        model = measure_model(rgb, obj)
    else:
        # Later construction stages are edits of an earlier frame image: the model
        # keeps that camera, so measure the clean frame and reuse its transform.
        # Measuring a rafter/roof image directly would mistake rafters for columns.
        reference_rgb, reference_obj = load_object(fit_from)
        model = measure_model(reference_rgb, reference_obj)
    fit = fit_affine(model, kit, ridge_row=ridge_row)
    if fit_from is not None and reference_obj.shape != obj.shape:
        # Same framing at a different output size: rescale the fit by the ratio.
        ratio_y = reference_obj.shape[0] / obj.shape[0]
        ratio_x = reference_obj.shape[1] / obj.shape[1]
        fit = {
            "a": fit["a"] * ratio_x,
            "b": fit["b"],
            "c": fit["c"] * ratio_y,
            "d": fit["d"],
        }
    warped = warp(rgb, obj, fit, kit)
    part = frame_only(warped, kit, keep_below_head)
    # The finished roof volume is the hard bound: clip the aligned frame to it so
    # eave and hip overhangs cannot leave the silhouette the compositor allows.
    socket, _ = load_socket_crop()
    allowed = np.array(finished_alpha_mask(socket)) > 0
    for _ in range(int(clip_dilate_px)):
        padded = np.pad(allowed, 1, mode="constant", constant_values=False)
        allowed = (
            padded[1:-1, 1:-1]
            | padded[:-2, 1:-1]
            | padded[2:, 1:-1]
            | padded[1:-1, :-2]
            | padded[1:-1, 2:]
        )
    array = np.array(part, dtype=np.uint8)
    array[~allowed, 3] = 0
    part = Image.fromarray(array)
    if top_row > 0:
        array = np.array(part, dtype=np.uint8)
        array[:top_row, :, 3] = 0
        part = Image.fromarray(array)
    mask = np.array(part.getchannel("A")) > 8
    _require(mask.any(), "aligned frame is empty above the column heads")
    ys, xs = np.nonzero(mask)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    part.save(output_path, "PNG")
    return {
        "model": model,
        "fit": fit,
        "alignedBBox": [
            int(xs.min()),
            int(ys.min()),
            int(xs.max()) + 1,
            int(ys.max()) + 1,
        ],
        "alignedPixels": int(mask.sum()),
        "output": str(output_path),
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("model_image")
    parser.add_argument("output_png")
    parser.add_argument(
        "--keep-below-head",
        type=int,
        default=0,
        help="rows of the model frame to keep below the kit column head row",
    )
    parser.add_argument(
        "--ridge-row",
        type=int,
        help="kit row the model ridge maps onto; stretches the frame band to fill the roof volume",
    )
    parser.add_argument(
        "--top-row",
        type=int,
        default=0,
        help="drop everything above this kit row (to split one frame into stage parts)",
    )
    parser.add_argument(
        "--fit-from",
        help="measure the affine fit on this image instead of the target (same camera)",
    )
    parser.add_argument(
        "--clip-dilate-px",
        type=int,
        default=0,
        help=(
            "grow the finished silhouette by this many px before clipping; 0 keeps the "
            "frame strictly inside it so the finished roof crop can cover it at stage 11"
        ),
    )
    args = parser.parse_args(argv)
    report = align(
        Path(args.model_image),
        Path(args.output_png),
        keep_below_head=args.keep_below_head,
        ridge_row=args.ridge_row,
        top_row=args.top_row,
        fit_from=Path(args.fit_from) if args.fit_from else None,
        clip_dilate_px=args.clip_dilate_px,
    )
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AlignError as error:
        print(f"[fail] {error}")
        raise SystemExit(1)
