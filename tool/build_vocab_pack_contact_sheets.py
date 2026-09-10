#!/usr/bin/env python3
"""Render hidden-label B2 contact sheets without altering source artwork."""

from __future__ import annotations

import re
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = ROOT / "lib/data/pack_artwork_catalog.dart"
ASSET_DIR = ROOT / "assets/illustrations/packs"
OUTPUT_DIR = ROOT / "docs/review/vocab_packs"
COLS = 7
GAP = 8
BACKGROUND = (241, 235, 218)


def _b2_pack_ids() -> list[str]:
    source = CATALOG_PATH.read_text(encoding="utf-8")
    match = re.search(
        r"dedicatedPackIds\s*=\s*<String>\{(?P<body>.*?)\n\s*\};",
        source,
        re.DOTALL,
    )
    if match is None:
        raise RuntimeError("Could not find PackArtworkCatalog.dedicatedPackIds")
    return sorted(
        pack_id
        for pack_id in re.findall(r"'([^']+)'", match.group("body"))
        if pack_id.startswith("b2_")
    )


def _render(pack_ids: list[str], *, crop_16_10: bool, output: Path) -> None:
    thumb_size = (160, 100) if crop_16_10 else (133, 100)
    rows = (len(pack_ids) + COLS - 1) // COLS
    width = GAP + COLS * (thumb_size[0] + GAP)
    height = GAP + rows * (thumb_size[1] + GAP)
    sheet = Image.new("RGB", (width, height), BACKGROUND)

    for index, pack_id in enumerate(pack_ids):
        path = ASSET_DIR / f"{pack_id}.webp"
        with Image.open(path) as source:
            image = source.convert("RGB")
        if crop_16_10:
            crop_height = image.width * 10 // 16
            top = (image.height - crop_height) // 2
            image = image.crop((0, top, image.width, top + crop_height))
        image.thumbnail(thumb_size, Image.Resampling.LANCZOS)
        x = GAP + (index % COLS) * (thumb_size[0] + GAP)
        y = GAP + (index // COLS) * (thumb_size[1] + GAP)
        sheet.paste(image, (x, y))

    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, optimize=True)
    print(f"wrote {output.relative_to(ROOT)} {sheet.width}x{sheet.height}")


def main() -> None:
    pack_ids = _b2_pack_ids()
    if not pack_ids:
        raise RuntimeError("No dedicated B2 assets found")
    _render(
        pack_ids,
        crop_16_10=False,
        output=OUTPUT_DIR / "b2_contact_sheet_4x3_100px.png",
    )
    _render(
        pack_ids,
        crop_16_10=True,
        output=OUTPUT_DIR / "b2_contact_sheet_16x10_100px.png",
    )


if __name__ == "__main__":
    main()
