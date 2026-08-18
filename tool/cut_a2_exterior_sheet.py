#!/usr/bin/env python3
"""Cut the A2 exterior-trace sprite sheet into four named sprites.

Reuses `cut_prop_sheet`'s keying core (`chroma_to_alpha`, `label_objects`,
`reading_order`, `_export`) instead of editing that module — its `PROPS`
constant is the canonical, tested 15-object A1 sheet contract and must not
be touched for a different, 4-object sheet.

Usage:
    /usr/local/bin/python3.12 tool/cut_a2_exterior_sheet.py SHEET.png OUT_DIR \\
        [--report report.json]
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image

from cut_prop_sheet import chroma_to_alpha, label_objects, _export

# The model rendered the two jangdok jars as two non-touching blobs instead of
# one group, so the sheet has 5 objects, not the requested 4. `reading_order`'s
# row-grouping breaks on this layout (the tall smoke plume's bbox spans past
# every other object's top edge, so ROW_GAP folds everything into one "row"
# and the final sort is by x only — that puts the bottom-row lantern between
# the magpie and the jars). Sorting by raw top-edge instead reproduces the
# visual order exactly, confirmed against the rendered sheet:
#   top=188 smoke, top=310 big jar, top=363 magpie, top=399 small jar,
#   top=933 lantern (the one object in a visually lower row).
# (name, final sprite width in px), in ascending-top order.
SPRITES: tuple[tuple[str, int], ...] = (
    ("a2_chimney_smoke", 40),
    ("a2_jangdok_big", 44),
    ("a2_ridge_magpie", 42),
    ("a2_jangdok_small", 36),
    ("a2_lantern_lit", 20),
)


def cut(sheet_path: Path, out_dir: Path) -> dict:
    with Image.open(sheet_path) as source:
        rgb = np.array(source.convert("RGB"))
    despilled, alpha = chroma_to_alpha(rgb)
    boxes = sorted(label_objects(alpha > 128), key=lambda b: b[1])
    if len(boxes) != len(SPRITES):
        raise SystemExit(
            f"[fail] sheet has {len(boxes)} objects, expected {len(SPRITES)}: {boxes}"
        )
    rgba = np.dstack([despilled, alpha])
    out_dir.mkdir(parents=True, exist_ok=True)
    sprites = [
        _export(rgba, box, name, width, out_dir)
        for (name, width), box in zip(SPRITES, boxes)
    ]
    return {"sheet": str(sheet_path), "sprites": sprites}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sheet", type=Path)
    parser.add_argument("out_dir", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args(argv)
    report = cut(args.sheet, args.out_dir)
    text = json.dumps(report, indent=2, sort_keys=True)
    if args.report:
        args.report.write_text(text + "\n", encoding="utf-8")
    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
