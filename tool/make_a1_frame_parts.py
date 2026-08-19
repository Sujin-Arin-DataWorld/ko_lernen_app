#!/usr/bin/env python3
"""Re-cut the A1 07/08 frame parts so the vertical timber lands on the real pillars.

Why this exists
---------------
`HANOK_V1_A1_KIT_GENERATION_PLAYBOOK.md` §4 builds stages 07 and 08 by splitting
ONE generated frame image (`raw/07_frame_v2_p9hh9hpg.png`) horizontally with
`align_model_frame.py --top-row 112`. A horizontal split cannot fix a horizontal
error, and the model drew its posts on an evenly spaced grid while the real
sarangchae bays are 110, 111, 83, 123, 83, 110, 110 units apart (the middle two
bays are pinched by the entrance steps).

Measured on 2026-08-19 against `a1_kit_overrides.json` pillarXRanges: of the eight
vertical members inside `generated/07_frame_beams.png`, only one sits within 5px
of a pillar centre. The median error is ~24px against a pillar that is only 16-20px
wide, and pillars 4 and 5 carry no member at all. Jin caught this by eye; stages 09+
hide it because ~45 rafters cover that band.

What this does
--------------
Keeps the model's long horizontal timbers (they are well drawn and their x error
does not read at that scale) and replaces only the short vertical members:

  frame_headbeam  y112-131  head beam / changbang tier, straight from the model
  frame_upper     y45-111   purlin + ridge tier with its king posts, from the model
  frame_posts     y131-156  NEW: eight capital blocks drawn at the measured pillar
                            x-ranges, colour-sampled from the matching pillar part

Costs 0 credits: every pixel comes from an already-approved ledger output
(`08_frame_purlins.png`) or from a derived pillar crop.

Usage
-----
    python3 tool/make_a1_frame_parts.py            # write parts + print sha256
    python3 tool/make_a1_frame_parts.py --preview OUT.png
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
KIT = ROOT / "assets_unused" / "pending_review" / "a1_kit"
DERIVED = KIT / "derived"
GENERATED = KIT / "generated"
OVERRIDES = ROOT / "docs" / "assets" / "hanok_a1_kit" / "a1_kit_overrides.json"

# The aligned full-frame part every band is cut from. It is an approved ledger
# output of BBANANA task p9hh9hpgk9rmy0d01zb80bs7v0 (playbook §3.1).
SOURCE_FRAME = GENERATED / "08_frame_purlins.png"

SOCKET = (854, 309)

# Row bands measured from SOURCE_FRAME's horizontal coverage profile:
#   y46-72   82.7% -> one long ridge/purlin timber
#   y73-111   7-11% -> king posts only
#   y112-131 80-86% -> the long head beam
#   y132-156 16-19% -> the misaligned short members this script replaces
UPPER_BAND = (45, 111)
HEADBEAM_BAND = (112, 131)
POST_BAND = (131, 157)  # exclusive end: draws rows 131..156 down to the pillar tops

PILLAR_SAMPLE_ROWS = 20  # rows below a pillar's top edge used for colour sampling
CAPITAL_FLARE_PX = 3  # capital block overhang at its top, tapering to 0 at the base


def _load_pillar_x_ranges() -> list[tuple[int, int]]:
    data = json.loads(OVERRIDES.read_text(encoding="utf-8"))
    return [(int(a), int(b)) for a, b in data["pillarXRanges"]]


def _band(frame: np.ndarray, y0: int, y1: int) -> np.ndarray:
    """Copy of `frame` with every row outside [y0, y1] made transparent."""
    out = frame.copy()
    out[:y0, :, 3] = 0
    out[y1 + 1 :, :, 3] = 0
    return out


def _capital_posts(pillar_x_ranges: list[tuple[int, int]]) -> np.ndarray:
    """Eight capital blocks, one centred on each measured pillar."""
    width, height = SOCKET
    posts = np.zeros((height, width, 4), dtype=np.uint8)
    y0, y1 = POST_BAND

    for index, (x0, x1) in enumerate(pillar_x_ranges, start=1):
        pillar = np.array(
            Image.open(DERIVED / f"pillar_{index}.png").convert("RGBA")
        )
        opaque = pillar[..., 3] > 8
        rows = np.where(opaque)[0]
        if rows.size == 0:
            raise SystemExit(f"pillar_{index}.png has no opaque pixels")
        top = int(rows.min())
        sample = pillar[top : top + PILLAR_SAMPLE_ROWS]

        for y in range(y0, y1):
            # 0 at the capital's top row, 1 where it meets the pillar head.
            t = (y - y0) / (y1 - y0)
            flare = int(round(CAPITAL_FLARE_PX * (1 - t)))
            for x in range(max(0, x0 - flare), min(width - 1, x1 + flare) + 1):
                column = sample[:, min(max(x, x0), x1)]
                column = column[column[..., 3] > 8]
                if column.size == 0:
                    continue
                r, g, b = column.mean(axis=0)[:3]
                # Slightly shaded at the top so the block reads as a separate member.
                shade = 0.88 + 0.12 * t
                posts[y, x] = (int(r * shade), int(g * shade), int(b * shade), 255)

    return posts


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path)
    parser.add_argument("--out-dir", type=Path, default=GENERATED)
    args = parser.parse_args(argv)

    frame = np.array(Image.open(SOURCE_FRAME).convert("RGBA"))
    if frame.shape[1::-1] != SOCKET:
        raise SystemExit(f"{SOURCE_FRAME} is {frame.shape[1::-1]}, expected {SOCKET}")

    pillar_x_ranges = _load_pillar_x_ranges()
    parts = {
        "frame_headbeam": _band(frame, *HEADBEAM_BAND),
        "frame_upper": _band(frame, *UPPER_BAND),
        "frame_posts": _capital_posts(pillar_x_ranges),
    }

    args.out_dir.mkdir(parents=True, exist_ok=True)
    for name, array in parts.items():
        path = args.out_dir / f"{name}.png"
        Image.fromarray(array).save(path)
        mask = array[..., 3] > 8
        ys, xs = np.where(mask)
        print(
            f"{name:15} y[{ys.min()},{ys.max()}] x[{xs.min()},{xs.max()}] "
            f"alpha={mask.mean() * 100:.2f}%  sha256={_sha256(path)}"
        )

    if args.preview:
        canvas = Image.new("RGBA", SOCKET, (0, 0, 0, 0))
        for name in ("platform", *[f"choseok_{i}" for i in range(1, 9)],
                     *[f"pillar_{i}" for i in range(1, 9)]):
            canvas.alpha_composite(Image.open(DERIVED / f"{name}.png").convert("RGBA"))
        for name in ("frame_posts", "frame_headbeam", "frame_upper"):
            canvas.alpha_composite(Image.open(args.out_dir / f"{name}.png"))
        backdrop = Image.new("RGBA", SOCKET, (248, 246, 240, 255))
        backdrop.alpha_composite(canvas)
        backdrop.convert("RGB").save(args.preview)
        print(f"preview -> {args.preview}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
