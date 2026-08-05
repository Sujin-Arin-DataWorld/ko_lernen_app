#!/usr/bin/env python3
"""Fail-closed image contract for the canonical personal Hanok map family."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
ASSET_ROOT = ROOT / "assets" / "illustrations" / "personal_hanok_v2" / "map"
CANVAS = (1536, 1152)

SPECS = {
    "site_base_light.png": {"opaque": True},
    "reference_full_estate.png": {"opaque": True},
    "structures/sotdaeulmun.png": {"opaque": False},
    "structures/haengrangchae.png": {"opaque": False},
    "structures/sarangchae.png": {"opaque": False},
    "structures/anchae.png": {"opaque": False},
    "structures/daecheongmaru.png": {"opaque": False},
    "structures/sadang.png": {"opaque": False},
    "landscape/rear_garden.png": {"opaque": False},
}


def _chroma_key_count(image: Image.Image) -> int:
    return sum(
        1
        for red, green, blue, alpha in image.convert("RGBA").getdata()
        if (red, green, blue) == (0, 255, 0) and alpha > 8
    )


def _coverage(image: Image.Image) -> float:
    rgba = image.convert("RGBA")
    total = rgba.width * rgba.height
    return sum(alpha > 8 for _, _, _, alpha in rgba.getdata()) / total


def _corners(image: Image.Image) -> tuple[int, int, int, int]:
    rgba = image.convert("RGBA")
    return (
        rgba.getpixel((0, 0))[3],
        rgba.getpixel((rgba.width - 1, 0))[3],
        rgba.getpixel((0, rgba.height - 1))[3],
        rgba.getpixel((rgba.width - 1, rgba.height - 1))[3],
    )


def _check(path: Path, opaque: bool) -> list[str]:
    with Image.open(path) as source:
        image = source.copy()

    errors: list[str] = []
    if image.size != CANVAS:
        errors.append(f"size={image.width}x{image.height}, expected=1536x1152")
    corners = _corners(image)
    if opaque:
        if any(alpha != 255 for alpha in corners):
            errors.append(f"corner alpha={corners}, expected opaque")
    else:
        if image.mode != "RGBA":
            errors.append(f"mode={image.mode}, expected RGBA")
        if any(alpha != 0 for alpha in corners):
            errors.append(f"corner alpha={corners}, expected transparent")
        coverage = _coverage(image)
        if not 0.002 <= coverage <= 0.90:
            errors.append(f"alpha coverage={coverage:.2%}, expected 0.2%-90%")
    chroma = _chroma_key_count(image)
    if chroma:
        errors.append(f"contains {chroma} opaque #00ff00 chroma-key pixels")
    detail = f"{image.width}x{image.height} alpha={_coverage(image):.2%} key={chroma}"
    relative = path.relative_to(ROOT)
    if errors:
        return [f"[fail] {relative} {detail}: {'; '.join(errors)}"]
    return [f"[pass] {relative} {detail}"]


def main() -> int:
    problems = 0
    for relative, spec in SPECS.items():
        path = ASSET_ROOT / relative
        if not path.is_file():
            print(f"[missing] {path.relative_to(ROOT)}")
            problems += 1
            continue
        for line in _check(path, bool(spec["opaque"])):
            print(line)
            if line.startswith("[fail]"):
                problems += 1
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
