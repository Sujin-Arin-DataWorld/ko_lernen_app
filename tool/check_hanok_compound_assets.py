#!/usr/bin/env python3
"""Mechanical format guard for the personal Hanok master-map art package.

The map renderer is intentionally not part of P2a yet. This checker exists so
that every generated production image is validated before a future catalog can
refer to it.
"""
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
ASSET_DIR = ROOT / "assets" / "illustrations" / "hanok_compound"

SPECS = {
    "site_base.png": {"size": (1536, 1152), "transparent": False},
    "sotdaeulmun.png": {"transparent": True},
    "haengrangchae.png": {"transparent": True},
    "sarangchae.png": {"transparent": True},
    "anchae.png": {"transparent": True},
    "daecheongmaru.png": {"transparent": True},
    "sadang.png": {"transparent": True},
}


def _chroma_key_count(rgba: Image.Image) -> int:
    return sum(
        1
        for red, green, blue, alpha in rgba.getdata()
        if (red, green, blue) == (0, 255, 0) and alpha > 8
    )


def _alpha_coverage(rgba: Image.Image) -> float:
    total = rgba.width * rgba.height
    if total == 0:
        return 0.0
    return sum(alpha > 8 for _, _, _, alpha in rgba.getdata()) / total


def _has_opaque_bounds(rgba: Image.Image) -> bool:
    return any(alpha >= 220 for _, _, _, alpha in rgba.getdata())


def _check_existing(filename: str, spec: dict[str, object]) -> list[str]:
    path = ASSET_DIR / filename
    with Image.open(path) as source:
        rgba = source.convert("RGBA")

    errors: list[str] = []
    transparent = bool(spec["transparent"])
    corners = (
        rgba.getpixel((0, 0))[3],
        rgba.getpixel((rgba.width - 1, 0))[3],
        rgba.getpixel((0, rgba.height - 1))[3],
        rgba.getpixel((rgba.width - 1, rgba.height - 1))[3],
    )
    chroma = _chroma_key_count(rgba)
    coverage = _alpha_coverage(rgba)

    if transparent:
        if source.mode != "RGBA":
            errors.append(f"mode={source.mode}, expected RGBA")
        if any(alpha != 0 for alpha in corners):
            errors.append(f"corner alpha={corners}, expected all 0")
        if not 0.02 <= coverage <= 0.90:
            errors.append(f"alpha coverage={coverage:.1%}, expected 2%-90%")
        if not _has_opaque_bounds(rgba):
            errors.append("no opaque subject pixels")
    else:
        expected_size = spec["size"]
        if (rgba.width, rgba.height) != expected_size:
            errors.append(
                f"size={rgba.width}x{rgba.height}, expected={expected_size[0]}x{expected_size[1]}"
            )
        if any(alpha != 255 for alpha in corners):
            errors.append(f"corner alpha={corners}, expected all 255")

    if chroma:
        errors.append(f"contains {chroma} opaque #00ff00 chroma-key pixels")

    detail = f"{rgba.width}x{rgba.height} alpha={coverage:.1%} key={chroma}"
    if errors:
        return [f"[fail] {path.relative_to(ROOT)} {detail}: {'; '.join(errors)}"]
    return [f"[pass] {path.relative_to(ROOT)} {detail}"]


def main() -> int:
    problems = 0
    for filename, spec in SPECS.items():
        path = ASSET_DIR / filename
        if not path.is_file():
            print(f"[missing] {path.relative_to(ROOT)}")
            problems += 1
            continue
        for line in _check_existing(filename, spec):
            print(line)
            if line.startswith("[fail]"):
                problems += 1
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
