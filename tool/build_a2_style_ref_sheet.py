#!/usr/bin/env python3
"""Compose the A2 style-anchor sheet from four shipped sarangbang cutouts.

The A2 사랑방 가구 12 must look like they belong to the set that already ships in
``assets/illustrations/decorations/`` — Faceted Minhwa low-poly cutouts, matte,
no outlines, warm walnut with muted dancheong accents, three-quarter camera from
slightly above and to the left, top-left light, and **no cast shadow**.

The recovered BBANANA prompts for that set are the *wrong* lineage: they describe
a soft watercolour museum plate on white, which is exactly the look that was
rejected on 2026-08-04 (see docs/superpowers/plans/2026-08-04-sarangbang-
production-assets.md via git, commit f63b5174). So instead of re-using prompt
text, we hand the model the shipped pixels as the single pinned reference.

Background is flat #00FF00 — the same chroma key the output must use, which is
also what the A1 prop sheet used successfully. No palette colour comes close to
the key (the deepest dancheong teal #274A3F has greenness G-max(R,B) = 11, below
``cut_prop_sheet.GREENNESS_OPAQUE`` = 15), so keying never eats the artwork.

Usage:
    /usr/local/bin/python3.12 tool/build_a2_style_ref_sheet.py [--out PATH]
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DECOR = ROOT / "assets" / "illustrations" / "decorations"
DEFAULT_OUT = (
    ROOT
    / "assets_unused"
    / "pending_review"
    / "a2_furnishing"
    / "model_inputs"
    / "a2_style_ref_sheet_v1.png"
)

CHROMA = (0, 255, 0, 255)
SHEET_W, SHEET_H = 2048, 1536
COLS, ROWS = 2, 2
GUTTER = 96

# Four anchors that together carry the whole contract: the full palette (walnut,
# lacquer black, muted teal/red/gold, aged ivory), the clearest facet evidence
# (munbangsau), the shared camera, and both size classes (furniture + desk props).
# chaekgado (front-on wall piece) and gat_buchae (hanging) are deliberately left
# out so they cannot bias the camera.
ANCHORS = (
    "decoration_seoan.png",
    "decoration_soban.png",
    "decoration_munbangsau.png",
    "decoration_jagae_mungap.png",
)


def cell_box(index: int) -> tuple[int, int, int, int]:
    col = index % COLS
    row = index // COLS
    cell_w = (SHEET_W - GUTTER * (COLS + 1)) // COLS
    cell_h = (SHEET_H - GUTTER * (ROWS + 1)) // ROWS
    left = GUTTER + col * (cell_w + GUTTER)
    top = GUTTER + row * (cell_h + GUTTER)
    return left, top, cell_w, cell_h


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()

    sheet = Image.new("RGBA", (SHEET_W, SHEET_H), CHROMA)
    for index, name in enumerate(ANCHORS):
        source = DECOR / name
        if not source.exists():
            raise SystemExit(f"missing anchor: {source}")
        art = Image.open(source).convert("RGBA")
        left, top, cell_w, cell_h = cell_box(index)
        scale = min(cell_w / art.width, cell_h / art.height)
        size = (max(1, round(art.width * scale)), max(1, round(art.height * scale)))
        art = art.resize(size, Image.LANCZOS)
        offset = (left + (cell_w - size[0]) // 2, top + (cell_h - size[1]) // 2)
        sheet.alpha_composite(art, offset)

    # Flatten onto the key so the uploaded file has no transparency at all —
    # a model that sees alpha sometimes returns alpha, and we want it to learn
    # "object on flat green" as the output format.
    flat = Image.new("RGB", sheet.size, CHROMA[:3])
    flat.paste(sheet, mask=sheet.split()[3])

    args.out.parent.mkdir(parents=True, exist_ok=True)
    flat.save(args.out, format="PNG", optimize=True)
    digest = hashlib.sha256(args.out.read_bytes()).hexdigest()
    print(f"wrote {args.out.relative_to(ROOT)}")
    print(f"  size   {flat.width}x{flat.height} RGB")
    print(f"  bytes  {args.out.stat().st_size}")
    print(f"  sha256 {digest}")
    for name in ANCHORS:
        src = DECOR / name
        src_sha = hashlib.sha256(src.read_bytes()).hexdigest()
        print(f"  anchor {name} sha256 {src_sha[:16]}…")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
