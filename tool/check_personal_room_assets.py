#!/usr/bin/env python3
"""Fail-closed image contract for private Hanok interior room shells."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
ASSET_ROOT = ROOT / "assets" / "illustrations" / "personal_hanok_v2" / "interiors"
CANVAS = (1086, 1448)
ASSETS = ("anbang_empty.png", "daecheong_empty.png")


def _chroma_key_count(image: Image.Image) -> int:
    return sum(
        1
        for red, green, blue, alpha in image.convert("RGBA").getdata()
        if (red, green, blue) == (0, 255, 0) and alpha > 8
    )


def _alpha_bounds(image: Image.Image) -> tuple[int, int]:
    alpha_values = image.convert("RGBA").getchannel("A").getdata()
    return min(alpha_values), max(alpha_values)


def _check(path: Path) -> list[str]:
    with Image.open(path) as source:
        image = source.copy()

    errors: list[str] = []
    if image.size != CANVAS:
        errors.append(f"size={image.width}x{image.height}, expected=1086x1448")
    if image.mode not in {"RGB", "RGBA"}:
        errors.append(f"mode={image.mode}, expected RGB or RGBA")
    alpha_min, alpha_max = _alpha_bounds(image)
    if alpha_min != 255 or alpha_max != 255:
        errors.append(f"alpha range={alpha_min}-{alpha_max}, expected fully opaque")
    chroma = _chroma_key_count(image)
    if chroma:
        errors.append(f"contains {chroma} opaque #00ff00 chroma-key pixels")
    detail = f"{image.width}x{image.height} mode={image.mode} alpha={alpha_min}-{alpha_max} key={chroma}"
    relative = path.relative_to(ROOT)
    if errors:
        return [f"[fail] {relative} {detail}: {'; '.join(errors)}"]
    return [f"[pass] {relative} {detail}"]


def main() -> int:
    problems = 0
    for name in ASSETS:
        path = ASSET_ROOT / name
        if not path.is_file():
            print(f"[missing] {path.relative_to(ROOT)}")
            problems += 1
            continue
        for line in _check(path):
            print(line)
            if line.startswith("[fail]"):
                problems += 1
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
