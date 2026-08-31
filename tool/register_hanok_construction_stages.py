#!/usr/bin/env python3
"""Register cumulative Hanok stage PNGs to one exact V3 master canvas.

One control stage (normally stage 7) supplies the scale needed to match the
final V3 silhouette.  That same scale is then applied to every earlier stage.
Each stage is translated only far enough to share the final master's horizontal
centre and ground-contact line.  The final V3 file itself is never rewritten.

RGBA resizing is performed in premultiplied-alpha space to avoid dark or white
fringes around roof tiles, rafters, posts, and stonework.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image


ALPHA_THRESHOLD = 8


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = np.asarray(image.convert("RGBA"), dtype=np.uint8)[:, :, 3]
    ys, xs = np.where(alpha > ALPHA_THRESHOLD)
    if not len(xs):
        raise ValueError("image has no visible pixels")
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def resize_premultiplied(
    image: Image.Image,
    size: tuple[int, int],
) -> Image.Image:
    premultiplied = image.convert("RGBA").convert("RGBa")
    resized = premultiplied.resize(size, Image.Resampling.LANCZOS)
    return resized.convert("RGBA")


def register(
    source: Path,
    output: Path,
    *,
    canvas_size: tuple[int, int],
    scale_x: float,
    scale_y: float,
    target_center_x: float,
    target_ground_y: int,
) -> dict[str, object]:
    with Image.open(source) as opened:
        source_image = opened.convert("RGBA")
    source_bbox = alpha_bbox(source_image)
    requested_scaled_size = (
        round(source_image.width * scale_x),
        round(source_image.height * scale_y),
    )
    target_visible_size = (
        round((source_bbox[2] - source_bbox[0]) * scale_x),
        round((source_bbox[3] - source_bbox[1]) * scale_y),
    )
    # Resize the tight visible crop rather than the full generator canvas.
    # Otherwise Lanczos ringing in the large transparent margins can expand the
    # measured alpha extent by several pixels even when the scale is correct.
    source_crop = source_image.crop(source_bbox)
    scaled_size = target_visible_size
    scaled = resize_premultiplied(source_crop, scaled_size)
    scaled_bbox = alpha_bbox(scaled)
    actual_visible_size = (
        scaled_bbox[2] - scaled_bbox[0],
        scaled_bbox[3] - scaled_bbox[1],
    )
    if actual_visible_size != target_visible_size:
        raise ValueError(
            f"tight-crop registration failed: expected {target_visible_size}, "
            f"got {actual_visible_size} for {source}"
        )

    scaled_center_x = (scaled_bbox[0] + scaled_bbox[2]) / 2.0
    offset_x = round(target_center_x - scaled_center_x)
    offset_y = target_ground_y - scaled_bbox[3]
    placed_bbox = tuple(
        value + (offset_x if index % 2 == 0 else offset_y)
        for index, value in enumerate(scaled_bbox)
    )
    if (
        placed_bbox[0] < 0
        or placed_bbox[1] < 0
        or placed_bbox[2] > canvas_size[0]
        or placed_bbox[3] > canvas_size[1]
    ):
        raise ValueError(
            f"registered asset would be cropped: {source} -> {placed_bbox} "
            f"on {canvas_size}"
        )

    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    canvas.alpha_composite(scaled, (offset_x, offset_y))
    # Lanczos can create alpha values 1..8 just outside the intended edge.
    # They are visually negligible but would make the nominal ground contact
    # drift by several pixels.  Clear exactly the same audit-threshold tail.
    pixels = np.asarray(canvas, dtype=np.uint8).copy()
    weak_alpha = pixels[:, :, 3] <= ALPHA_THRESHOLD
    pixels[weak_alpha] = 0
    canvas = Image.fromarray(pixels)
    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output, format="PNG", optimize=True)
    output_bbox = alpha_bbox(canvas)
    if output_bbox[3] != target_ground_y:
        raise ValueError(
            f"ground line drifted: expected {target_ground_y}, got {output_bbox[3]}"
        )

    return {
        "source": str(source),
        "sourceSha256": sha256(source),
        "sourceSize": list(source_image.size),
        "sourceAlphaBbox": list(source_bbox),
        "scale": [scale_x, scale_y],
        "requestedScaledSize": list(requested_scaled_size),
        "targetVisibleSize": list(target_visible_size),
        "scaledSize": list(scaled_size),
        "translation": [offset_x, offset_y],
        "output": str(output),
        "outputSha256": sha256(output),
        "outputSize": list(canvas_size),
        "outputAlphaBbox": list(output_bbox),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reference", type=Path)
    parser.add_argument("control", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("sources", nargs="+", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()

    for path in (args.reference, args.control, *args.sources):
        if not path.is_file():
            raise SystemExit(f"missing input: {path}")

    with Image.open(args.reference) as opened:
        reference = opened.convert("RGBA")
    with Image.open(args.control) as opened:
        control = opened.convert("RGBA")
    reference_bbox = alpha_bbox(reference)
    control_bbox = alpha_bbox(control)
    reference_width = reference_bbox[2] - reference_bbox[0]
    reference_height = reference_bbox[3] - reference_bbox[1]
    control_width = control_bbox[2] - control_bbox[0]
    control_height = control_bbox[3] - control_bbox[1]
    scale_x = reference_width / control_width
    scale_y = reference_height / control_height
    target_center_x = (reference_bbox[0] + reference_bbox[2]) / 2.0
    target_ground_y = reference_bbox[3]

    rows = []
    for source in args.sources:
        rows.append(
            register(
                source,
                args.output_dir / source.name,
                canvas_size=reference.size,
                scale_x=scale_x,
                scale_y=scale_y,
                target_center_x=target_center_x,
                target_ground_y=target_ground_y,
            )
        )

    report = {
        "reference": str(args.reference),
        "referenceSha256": sha256(args.reference),
        "referenceSize": list(reference.size),
        "referenceAlphaBbox": list(reference_bbox),
        "control": str(args.control),
        "controlAlphaBbox": list(control_bbox),
        "sharedScale": [scale_x, scale_y],
        "targetCenterX": target_center_x,
        "targetGroundY": target_ground_y,
        "stages": rows,
        "pillow": Image.__version__,
    }
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
