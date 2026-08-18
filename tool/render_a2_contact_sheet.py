#!/usr/bin/env python3
"""Render the QA sheets a human needs to judge a new 사랑방 decoration.

Three questions, three sheets:

  --sheet compare   Does it belong to the shipped set? New items beside the six
                    approved cutouts on the room's own cream, same height.
  --sheet transform Does it survive the room editor? The room is free-placement
                    (`lib/widgets/sori/free_room_layer.dart`): an item is drawn
                    with BoxFit.contain inside a SQUARE box and rotated about
                    that box's centre, at any width from .08 to .72 of the
                    canvas. So a baked ground shadow rotates with the object and
                    an off-centre silhouette wobbles — this sheet shows both.
  --sheet room      Does it read at the size the app actually spawns it? Items
                    composited over the real 사랑방 background at exactly
                    `RoomLayoutService.defaultWidth` (room_layout_service.dart
                    :534-547) × canvas width.

Usage:
    /usr/local/bin/python3.12 tool/render_a2_contact_sheet.py \
        --new assets_unused/pending_review/a2_furnishing/normalized/decoration_soban_v2.png \
        --out assets_unused/pending_review/a2_furnishing/qa
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
DECOR = ROOT / "assets" / "illustrations" / "decorations"
ROOM = ROOT / "assets" / "illustrations" / "hanok" / "sarangbang_empty.png"
PLACED_DART = ROOT / "lib" / "widgets" / "sori" / "placed_decoration.dart"

CREAM = (250, 246, 236, 255)
INK = (42, 51, 64, 255)

SHIPPED_INTERIOR = (
    "decoration_seoan.png",
    "decoration_soban.png",
    "decoration_munbangsau.png",
    "decoration_jagae_mungap.png",
    "decoration_chaekgado.png",
    "decoration_gat_buchae.png",
)

# RoomLayoutService.defaultWidth (lib/services/room_layout_service.dart:534-547)
CATEGORY_BASE = {
    "wall": (0.38, 0.14, 0.58),
    "floor": (0.34, 0.14, 0.52),
    "shelf": (0.20, 0.12, 0.34),
    "peg": (0.20, 0.12, 0.34),
    "outdoor": (0.28, 0.14, 0.46),
}


def parse_dart_maps() -> tuple[dict[str, str], dict[str, float]]:
    """Read kDecorCategory / kDecorScale out of the Dart source.

    Parsing beats hand-copying: the sheet can never drift from what the app
    actually renders.
    """
    source = PLACED_DART.read_text(encoding="utf-8")
    categories = {
        m.group(1): m.group(2)
        for m in re.finditer(r"'(decoration_[a-z0-9_]+)':\s*DecorCategory\.(\w+)", source)
    }
    scales = {
        m.group(1): float(m.group(2))
        for m in re.finditer(r"'(decoration_[a-z0-9_]+)':\s*([0-9.]+),", source)
    }
    return categories, scales


def default_width(category: str, scale: float) -> float:
    base, low, high = CATEGORY_BASE.get(category, CATEGORY_BASE["outdoor"])
    return min(max(base * scale, low), high)


def fit(image: Image.Image, box: int) -> Image.Image:
    """BoxFit.contain into a square of side `box` — what the room widget does."""
    k = min(box / image.width, box / image.height)
    size = (max(1, round(image.width * k)), max(1, round(image.height * k)))
    return image.resize(size, Image.LANCZOS)


def label(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str) -> None:
    draw.text(xy, text, fill=INK)


def sheet_compare(new_paths: list[Path], out: Path) -> Path:
    cell, pad, top = 320, 24, 28
    items = [(p.stem.replace("decoration_", ""), Image.open(p).convert("RGBA")) for p in new_paths]
    shipped = [
        (n.replace("decoration_", "").replace(".png", ""), Image.open(DECOR / n).convert("RGBA"))
        for n in SHIPPED_INTERIOR
    ]
    columns = max(len(items), len(shipped))
    width = pad + columns * (cell + pad)
    height = 2 * (top + cell + pad) + pad
    canvas = Image.new("RGBA", (width, height), CREAM)
    draw = ImageDraw.Draw(canvas)

    for row, (title, group) in enumerate((("SHIPPED (approved)", shipped), ("NEW", items))):
        y = pad + row * (top + cell + pad)
        label(draw, (pad, y), title)
        for column, (name, art) in enumerate(group):
            x = pad + column * (cell + pad)
            art = fit(art, cell)
            canvas.alpha_composite(art, (x + (cell - art.width) // 2, y + top + (cell - art.height) // 2))
            label(draw, (x, y + top + cell + 4), name)

    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out, format="PNG", optimize=True)
    return out


def sheet_transform(new_path: Path, out: Path) -> Path:
    """Rotation + scale proof, mirroring the room editor's square-box model."""
    art = Image.open(new_path).convert("RGBA")
    angles = (0, -20, 25, 90, 180)
    boxes = (110, 200, 320)
    pad, top = 24, 28
    width = pad + len(angles) * (max(boxes) + pad)
    height = pad + top + sum(b + pad + 18 for b in boxes)
    canvas = Image.new("RGBA", (width, height), CREAM)
    draw = ImageDraw.Draw(canvas)
    label(draw, (pad, pad), f"{new_path.stem} — rotate/scale as the room editor does (square box, contain)")

    y = pad + top
    for box in boxes:
        for column, angle in enumerate(angles):
            x = pad + column * (max(boxes) + pad)
            square = Image.new("RGBA", (box, box), (0, 0, 0, 0))
            scaled = fit(art, box)
            square.alpha_composite(scaled, ((box - scaled.width) // 2, (box - scaled.height) // 2))
            turned = square.rotate(angle, resample=Image.BICUBIC, expand=False)
            canvas.alpha_composite(turned, (x, y))
            if box == boxes[0]:
                label(draw, (x, y - 16), f"{angle}°")
        label(draw, (pad, y + box + 2), f"box {box}px")
        y += box + pad + 18

    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out, format="PNG", optimize=True)
    return out


def sheet_room(new_path: Path, slug_for_size: str, out: Path) -> Path:
    categories, scales = parse_dart_maps()
    room = Image.open(ROOM).convert("RGBA")
    canvas = room.copy()
    draw = ImageDraw.Draw(canvas)

    reference = [("decoration_seoan", 0.42, 0.74), ("decoration_soban", 0.74, 0.72)]
    for slug, cx, cy in reference:
        art = Image.open(DECOR / f"{slug}.png").convert("RGBA")
        box = round(default_width(categories.get(slug, "floor"), scales.get(slug, 1.0)) * room.width)
        art = fit(art, box)
        canvas.alpha_composite(art, (round(cx * room.width) - art.width // 2, round(cy * room.height) - art.height // 2))

    art = Image.open(new_path).convert("RGBA")
    box = round(default_width(categories.get(slug_for_size, "floor"), scales.get(slug_for_size, 1.0)) * room.width)
    art = fit(art, box)
    canvas.alpha_composite(art, (round(0.30 * room.width) - art.width // 2, round(0.86 * room.height) - art.height // 2))
    label(draw, (16, 16), f"NEW {new_path.stem} at defaultWidth({slug_for_size}) = {box}px; seoan/soban for scale")

    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out, format="PNG", optimize=True)
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--new", type=Path, nargs="+", required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--size-slug", default="decoration_soban")
    parser.add_argument(
        "--sheet",
        choices=("compare", "transform", "room", "all"),
        default="all",
    )
    args = parser.parse_args()

    made: list[Path] = []
    if args.sheet in ("compare", "all"):
        made.append(sheet_compare(list(args.new), args.out / "sheet_compare.png"))
    if args.sheet in ("transform", "all"):
        made.append(sheet_transform(args.new[0], args.out / "sheet_transform.png"))
    if args.sheet in ("room", "all"):
        made.append(sheet_room(args.new[0], args.size_slug, args.out / "sheet_room.png"))
    for path in made:
        print(f"wrote {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
