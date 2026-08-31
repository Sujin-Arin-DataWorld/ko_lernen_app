#!/usr/bin/env python3
"""Deterministically recover alpha from a baked neutral image-generator matte.

The Hanok construction pilot images were returned as RGB PNG files with the
editor-style white/grey checkerboard or a black neutral field rendered into the
pixels.  This tool detects which matte touches the border and removes matching
neutral pixels, including sufficiently large enclosed views through the timber
frame.  Small isolated highlights in pale plaster and stone are preserved.

The two-pixel antialias band is reconstructed with a soft alpha.  Its RGB bleed
uses the nearest fully opaque source pixel so the baked white matte cannot form
a halo on dark app backgrounds.  No denoising, repainting, recolouring, or
geometry edits are performed.

Usage:
    python tool/extract_checkerboard_alpha.py INPUT.png OUTPUT.png \
        --report OUTPUT.qa.json
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def border_connected(mask: np.ndarray) -> np.ndarray:
    """Return the 8-connected components in ``mask`` that touch the border."""

    structure = np.ones((3, 3), dtype=np.uint8)
    labels, _ = ndimage.label(mask, structure=structure)
    edge_labels = np.unique(
        np.concatenate((labels[0], labels[-1], labels[:, 0], labels[:, -1]))
    )
    edge_labels = edge_labels[edge_labels != 0]
    return np.isin(labels, edge_labels)


def recover_alpha(
    rgb: np.ndarray,
    *,
    background_floor: int,
    background_chroma: int,
    island_min_area: int,
    feather_px: float,
) -> tuple[np.ndarray, dict[str, object]]:
    """Return RGBA and audit measurements for one neutral-matte RGB image."""

    values = rgb.astype(np.int16)
    minimum = values.min(axis=2)
    maximum = values.max(axis=2)
    chroma = maximum - minimum

    border_pixels = np.concatenate(
        (values[0], values[-1], values[:, 0], values[:, -1]),
        axis=0,
    )
    border_value = float(np.median(border_pixels.max(axis=1)))
    matte_mode = "dark" if border_value < 64.0 else "bright"
    dark_ceiling = 16

    # Only pixels close to the detected neutral matte may be background.
    if matte_mode == "dark":
        background_candidate = (
            (maximum <= dark_ceiling) & (chroma <= background_chroma)
        )
    else:
        background_candidate = (
            (minimum >= background_floor) & (chroma <= background_chroma)
        )
    background = border_connected(background_candidate)

    # Timber frames enclose many views of the same checkerboard, so border-only
    # flood fill cannot reach them.  Add only sizeable connected regions from
    # the exact same narrow palette.  Tiny neutral highlights in stone/plaster
    # remain opaque instead of becoming pinholes.
    structure = np.ones((3, 3), dtype=np.uint8)
    candidate_labels, _ = ndimage.label(background_candidate, structure=structure)
    component_sizes = np.bincount(candidate_labels.ravel())
    sizeable = component_sizes >= island_min_area
    sizeable[0] = False
    enclosed_background = sizeable[candidate_labels]
    background |= enclosed_background
    if not np.any(background):
        raise ValueError("no border-connected neutral matte was detected")

    alpha = np.full(rgb.shape[:2], 255.0, dtype=np.float32)
    alpha[background] = 0.0

    # Distance to confirmed background.  This is used only in a narrow
    # antialias band.
    distance = ndimage.distance_transform_edt(
        ~background,
        return_distances=True,
        return_indices=False,
    )
    band = (~background) & (distance <= feather_px)

    # Estimate edge opacity from how far a pixel departs from the neutral matte.
    # Warm/brown Hanok pixels become opaque quickly; pale neutral fringe pixels
    # remain translucent.  Spatial distance prevents this from affecting the
    # asset interior.
    if matte_mode == "dark":
        value_opacity = np.clip((maximum - dark_ceiling + 8) / 72.0, 0.0, 1.0)
    else:
        value_opacity = np.clip(
            (background_floor + 8 - minimum) / 78.0,
            0.0,
            1.0,
        )
    chroma_opacity = np.clip(chroma / 42.0, 0.0, 1.0)
    edge_opacity = np.maximum(value_opacity, chroma_opacity)
    alpha[band] = np.clip(edge_opacity[band] * 255.0, 1.0, 254.0)

    # Replace only the RGB bleed of translucent pixels with the nearest fully
    # opaque source colour.  Alpha still supplies the actual antialias profile.
    # This is the standard deterministic cure for a baked white matte halo.
    out_rgb = values.astype(np.float32)
    if np.any(band):
        solid = alpha >= 254.5
        _, nearest_solid = ndimage.distance_transform_edt(
            ~solid,
            return_distances=True,
            return_indices=True,
        )
        bleed = values[nearest_solid[0], nearest_solid[1]].astype(np.float32)
        out_rgb[band] = bleed[band]

    out = np.dstack(
        (
            np.rint(out_rgb).astype(np.uint8),
            np.rint(alpha).astype(np.uint8),
        )
    )
    out[background, :3] = 0

    visible = out[:, :, 3] > 0
    solid = out[:, :, 3] == 255
    if not np.any(visible):
        raise ValueError("alpha extraction removed the entire image")
    ys, xs = np.where(visible)
    report = {
        "sourceSize": [int(rgb.shape[1]), int(rgb.shape[0])],
        "matteMode": matte_mode,
        "borderMedianValue": border_value,
        "backgroundFloor": background_floor,
        "darkCeiling": dark_ceiling,
        "backgroundChroma": background_chroma,
        "islandMinArea": island_min_area,
        "featherPx": feather_px,
        "transparentPixels": int(background.sum()),
        "softPixels": int(((out[:, :, 3] > 0) & (out[:, :, 3] < 255)).sum()),
        "solidPixels": int(solid.sum()),
        "visibleCoveragePct": round(100.0 * visible.mean(), 3),
        "alphaBbox": [
            int(xs.min()),
            int(ys.min()),
            int(xs.max()) + 1,
            int(ys.max()) + 1,
        ],
        "cornerAlpha": [
            int(out[0, 0, 3]),
            int(out[0, -1, 3]),
            int(out[-1, 0, 3]),
            int(out[-1, -1, 3]),
        ],
    }
    return out, report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--background-floor", type=int, default=232)
    parser.add_argument("--background-chroma", type=int, default=14)
    parser.add_argument("--island-min-area", type=int, default=8)
    parser.add_argument("--feather-px", type=float, default=2.25)
    args = parser.parse_args()

    if not args.source.is_file():
        raise SystemExit(f"missing source: {args.source}")
    if not 0 <= args.background_floor <= 255:
        raise SystemExit("--background-floor must be between 0 and 255")
    if not 0 <= args.background_chroma <= 255:
        raise SystemExit("--background-chroma must be between 0 and 255")
    if args.island_min_area < 1:
        raise SystemExit("--island-min-area must be positive")
    if not 0.0 <= args.feather_px <= 8.0:
        raise SystemExit("--feather-px must be between 0 and 8")

    with Image.open(args.source) as image:
        rgb = np.asarray(image.convert("RGB"), dtype=np.uint8)

    rgba, report = recover_alpha(
        rgb,
        background_floor=args.background_floor,
        background_chroma=args.background_chroma,
        island_min_area=args.island_min_area,
        feather_px=args.feather_px,
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(rgba).save(args.output, format="PNG", optimize=True)

    report.update(
        {
            "source": str(args.source),
            "sourceSha256": sha256(args.source),
            "output": str(args.output),
            "outputSha256": sha256(args.output),
            "pillow": Image.__version__,
        }
    )
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(
            json.dumps(report, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
