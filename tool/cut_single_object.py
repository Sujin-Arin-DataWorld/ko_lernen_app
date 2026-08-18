#!/usr/bin/env python3
"""Cut ONE generated object off its #00FF00 field into a clean RGBA cutout.

`cut_prop_sheet.py` does this for a 15-object sheet. The A2 사랑방 가구 are
generated one per call, so this is the single-object sibling: same keying core
(imported, not copied), plus the two checks that catch a bad generation before a
human is asked to look at it.

Rejects (SystemExit, nothing written):
  * the four corners are not the chroma key   → the model ignored "flat green
    background" and returned a scene; no amount of keying saves that.
  * blob count outside --expect-parts         → stray specks, or the model drew
    the object twice / added props we did not ask for.

Usage:
    /usr/local/bin/python3.12 tool/cut_single_object.py RAW.png OUT.png \\
        [--expect-parts 1] [--min-area 2000] [--report qa/<slug>_cut.json]

The output keeps the object's native pixels (no resize) — `decoration_normalize.py`
owns trimming, the 1254 long-edge cap and the 3% pad.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

from cut_prop_sheet import GREENNESS_CLEAR, chroma_to_alpha, label_objects

ROOT = Path(__file__).resolve().parents[1]

# The corner test asks the only question that matters: will the keyer turn this
# corner fully transparent? That is `greenness = G - max(R,B) >= GREENNESS_CLEAR`.
# Measuring distance to exact #00FF00 instead was wrong — a real, perfectly
# keyable return from GPT Image 2 has corners around (10, 234, 8), which is 20
# off per channel but greenness 224, i.e. clear green with room to spare.
CORNER_PATCH = 32
CORNER_MIN_GREENNESS = GREENNESS_CLEAR
SOLID_ALPHA = 128
RIM_CLEAR_BELOW = 8


def corner_report(rgb: np.ndarray) -> tuple[bool, list[dict]]:
    height, width = rgb.shape[:2]
    patches = {
        "topLeft": rgb[0:CORNER_PATCH, 0:CORNER_PATCH],
        "topRight": rgb[0:CORNER_PATCH, width - CORNER_PATCH : width],
        "bottomLeft": rgb[height - CORNER_PATCH : height, 0:CORNER_PATCH],
        "bottomRight": rgb[height - CORNER_PATCH : height, width - CORNER_PATCH : width],
    }
    rows: list[dict] = []
    ok = True
    for name, patch in patches.items():
        mean = patch.reshape(-1, 3).mean(axis=0)
        greenness = float(mean[1]) - max(float(mean[0]), float(mean[2]))
        rows.append(
            {
                "corner": name,
                "meanRgb": [round(float(v), 1) for v in mean],
                "greenness": round(greenness, 1),
            }
        )
        if greenness < CORNER_MIN_GREENNESS:
            ok = False
    return ok, rows


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("out", type=Path)
    parser.add_argument("--expect-parts", type=int, default=1)
    parser.add_argument("--min-area", type=int, default=2000)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()

    if not args.source.exists():
        raise SystemExit(f"missing source: {args.source}")

    with Image.open(args.source) as im:
        rgb = np.array(im.convert("RGB"))

    corners_ok, corners = corner_report(rgb)
    if not corners_ok:
        raise SystemExit(
            "background is not flat #00FF00 — the model returned a scene, not a "
            f"cutout. corners: {json.dumps(corners, ensure_ascii=False)}"
        )

    despilled, alpha = chroma_to_alpha(rgb)
    boxes = label_objects(alpha > SOLID_ALPHA, min_area=args.min_area)
    if not boxes:
        raise SystemExit(
            f"no object above --min-area {args.min_area}; the frame is empty green"
        )
    if len(boxes) > args.expect_parts:
        raise SystemExit(
            f"found {len(boxes)} parts but --expect-parts {args.expect_parts}: "
            f"{boxes}. Extra props or a duplicated object — regenerate, do not cut."
        )

    rgba = np.dstack([despilled, alpha])
    rgba[alpha < RIM_CLEAR_BELOW, 3] = 0
    rgba[alpha < RIM_CLEAR_BELOW, :3] = 0

    left = min(b[0] for b in boxes)
    top = min(b[1] for b in boxes)
    right = max(b[2] for b in boxes)
    bottom = max(b[3] for b in boxes)
    cropped = rgba[top:bottom, left:right]

    args.out.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(cropped, mode="RGBA").save(args.out, format="PNG", optimize=True)

    visible = int((cropped[:, :, 3] > 8).sum())
    report = {
        "source": str(args.source),
        "sourceSha256": hashlib.sha256(args.source.read_bytes()).hexdigest(),
        "out": str(args.out),
        "outSha256": hashlib.sha256(args.out.read_bytes()).hexdigest(),
        "sourceSize": [int(rgb.shape[1]), int(rgb.shape[0])],
        "outSize": [int(cropped.shape[1]), int(cropped.shape[0])],
        "parts": len(boxes),
        "partBoxes": [list(map(int, b)) for b in boxes],
        "visiblePixels": visible,
        "coveragePct": round(100.0 * visible / max(1, cropped.shape[0] * cropped.shape[1]), 2),
        "corners": corners,
        "pillow": Image.__version__,
    }
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, ensure_ascii=False, indent=1), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
