#!/usr/bin/env python3
"""Cut the A1 prop sheet into individual true-alpha sprites.

The construction props for stages 01/02/05/14/16 all come from ONE generated
sheet (BBANANA task `5baedfcabb9a487981741880369c800e`, 15 objects on a
`#00FF00` field). Cutting them here instead of asking the model for one prop at
a time keeps a single style reference and costs no extra credits.

Steps per sheet:
1. turn the chroma field into alpha (soft edge + green despill so no green rim
   survives the JPEG ringing),
2. label the connected objects and sort them into the sheet's reading order,
3. trim each to its own bbox and resize it to the width the socket needs, so the
   sprite that lands in `parts.json` is already at final scale — the compositor
   never resizes and stays byte-deterministic.

Usage:
    python tool/cut_prop_sheet.py <sheet.jpg> <out_dir> [--report report.json]
"""

from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image

# Soft chroma edge: fully opaque below OPAQUE, fully clear above CLEAR.
GREENNESS_OPAQUE = 15
GREENNESS_CLEAR = 55
DESPILL_HEADROOM = 12
MIN_OBJECT_AREA = 2000
ROW_GAP = 120  # vertical gap that separates two rows of the sheet

# Sheet reading order (row-major), the prompt's object list, and the width each
# sprite needs inside the 854x309 socket. Widths were measured against the kit
# geometry: a bay is 83-123px wide, a column is 87px tall, the platform top band
# is 12 rows deep and the platform face 29, so props stay well under 60px.
PROPS: list[tuple[str, int]] = [
    ("prop_timber_squared", 60),
    ("prop_timber_logs", 58),
    ("prop_sawhorse", 52),
    ("prop_survey_stakes", 150),  # reference only; stage 01 uses prop_stake
    ("prop_drawing_board", 60),
    ("prop_stepping_stone_shoes", 46),
    ("prop_lantern", 16),
    ("prop_bamboo_blind", 40),
    ("prop_flower_pots", 30),
    ("prop_chimney", 24),
    ("prop_firebox", 29),
    ("prop_tile_pile", 34),
    ("prop_capital_block", 22),
    ("prop_king_post", 18),
    ("prop_brace", 40),
]

# Sub-cuts taken straight from the sheet by hand-measured box, for objects the
# sheet only drew as a group: stage 01 needs ONE setout stake (with its rope
# wrap and string stubs), not the whole four-stake bundle.
SUBCUTS: list[tuple[str, tuple[int, int, int, int], int]] = [
    ("prop_stake", (1690, 300, 1765, 510), 10),
]


def chroma_to_alpha(rgb: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Return (despilled RGB, alpha) for a #00FF00 keyed image."""
    rgb = rgb.astype(np.int32)
    other = np.maximum(rgb[:, :, 0], rgb[:, :, 2])
    greenness = rgb[:, :, 1] - other
    alpha = np.clip(
        (GREENNESS_CLEAR - greenness) / (GREENNESS_CLEAR - GREENNESS_OPAQUE),
        0.0,
        1.0,
    )
    out = rgb.copy()
    edge = (alpha > 0) & (greenness > GREENNESS_OPAQUE)
    out[:, :, 1] = np.where(
        edge, np.minimum(rgb[:, :, 1], other + DESPILL_HEADROOM), rgb[:, :, 1]
    )
    return out.astype(np.uint8), (alpha * 255).astype(np.uint8)


def label_objects(
    solid: np.ndarray, min_area: int = MIN_OBJECT_AREA
) -> list[tuple[int, int, int, int]]:
    """Flood-fill `solid` and return the bbox of every blob above `min_area`."""
    height, width = solid.shape
    seen = np.zeros_like(solid, dtype=bool)
    boxes: list[tuple[int, int, int, int]] = []
    for start_y in range(height):
        for start_x in np.flatnonzero(solid[start_y]):
            if seen[start_y, start_x]:
                continue
            queue = deque([(start_y, int(start_x))])
            seen[start_y, start_x] = True
            area = 0
            top = bottom = start_y
            left = right = int(start_x)
            while queue:
                y, x = queue.popleft()
                area += 1
                top, bottom = min(top, y), max(bottom, y)
                left, right = min(left, x), max(right, x)
                for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                    if (
                        0 <= ny < height
                        and 0 <= nx < width
                        and solid[ny, nx]
                        and not seen[ny, nx]
                    ):
                        seen[ny, nx] = True
                        queue.append((ny, nx))
            if area >= min_area:
                boxes.append((left, top, right + 1, bottom + 1))
    return boxes


def reading_order(
    boxes: list[tuple[int, int, int, int]]
) -> list[tuple[int, int, int, int]]:
    """Sort blobs into sheet rows, then left to right inside each row."""
    ordered: list[tuple[int, int, int, int]] = []
    row: list[tuple[int, int, int, int]] = []
    row_bottom: int | None = None
    for box in sorted(boxes, key=lambda b: b[1]):
        if row_bottom is not None and box[1] - row_bottom > ROW_GAP:
            ordered.extend(sorted(row, key=lambda b: b[0]))
            row = []
            row_bottom = None
        row.append(box)
        row_bottom = box[3] if row_bottom is None else max(row_bottom, box[3])
    ordered.extend(sorted(row, key=lambda b: b[0]))
    return ordered


def _export(
    rgba: np.ndarray,
    box: tuple[int, int, int, int],
    name: str,
    target_width: int,
    out_dir: Path,
) -> dict[str, Any]:
    left, top, right, bottom = box
    crop = Image.fromarray(rgba[top:bottom, left:right])
    native = crop.size
    scale = target_width / crop.width
    crop = crop.resize(
        (target_width, max(1, round(crop.height * scale))),
        resample=Image.Resampling.LANCZOS,
    )
    # LANCZOS on a hard alpha edge rings slightly negative; clamp the rim so a
    # sprite never carries semi-transparent green-lit fringe pixels.
    array = np.array(crop, dtype=np.uint8)
    array[array[:, :, 3] < 8, 3] = 0
    crop = Image.fromarray(array)
    path = out_dir / f"{name}.png"
    crop.save(path, "PNG")
    return {
        "name": name,
        "sheetBBox": [left, top, right, bottom],
        "nativeSize": list(native),
        "size": list(crop.size),
        "file": str(path).replace("\\", "/"),
    }


def cut(sheet_path: Path, out_dir: Path) -> dict[str, Any]:
    with Image.open(sheet_path) as source:
        rgb = np.array(source.convert("RGB"))
    despilled, alpha = chroma_to_alpha(rgb)
    boxes = reading_order(label_objects(alpha > 128))
    if len(boxes) != len(PROPS):
        raise SystemExit(
            f"[fail] sheet has {len(boxes)} objects, expected {len(PROPS)}: {boxes}"
        )
    rgba = np.dstack([despilled, alpha])
    out_dir.mkdir(parents=True, exist_ok=True)
    sprites = [
        _export(rgba, box, name, target_width, out_dir)
        for (name, target_width), box in zip(PROPS, boxes)
    ]
    sprites.extend(
        _export(rgba, box, name, target_width, out_dir)
        for name, box, target_width in SUBCUTS
    )
    return {"sheet": str(sheet_path).replace("\\", "/"), "sprites": sprites}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sheet")
    parser.add_argument("out_dir")
    parser.add_argument("--report")
    args = parser.parse_args(argv)
    report = cut(Path(args.sheet), Path(args.out_dir))
    text = json.dumps(report, indent=2, sort_keys=True)
    if args.report:
        Path(args.report).write_text(text + "\n", encoding="utf-8")
    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
