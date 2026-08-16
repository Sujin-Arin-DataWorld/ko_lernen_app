#!/usr/bin/env python3
"""Fail-closed image contract for the canonical personal Hanok map family."""

from pathlib import Path
import sys

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parent.parent
ASSET_ROOT = ROOT / "assets" / "illustrations" / "personal_hanok_v2" / "map"
QA_ROOT = ROOT / "assets_unused" / "pending_review"
CANVAS = (1536, 1152)

SPECS = {
    "site_base_light.png": {"opaque": True},
    "structures/sotdaeulmun.png": {"opaque": False},
    "structures/haengrangchae.png": {"opaque": False},
    "structures/sarangchae.png": {"opaque": False},
    "structures/anchae.png": {"opaque": False},
    "structures/daecheongmaru.png": {"opaque": False},
    "structures/sadang.png": {"opaque": False},
    "landscape/rear_garden.png": {"opaque": False},
}

# This is the exact paint order in `kPersonalHanokLayers`.  The reference
# image is not another, loosely similar illustration: it is the visible
# completed estate after these runtime layers have been alpha-composited.
RUNTIME_LAYER_ORDER = (
    "site_base_light.png",
    "landscape/rear_garden.png",
    "structures/sotdaeulmun.png",
    "structures/haengrangchae.png",
    "structures/sarangchae.png",
    "structures/anchae.png",
    "structures/daecheongmaru.png",
    "structures/sadang.png",
)
REFERENCE_NAME = "reference_full_estate.png"
REFERENCE_PATH = QA_ROOT / REFERENCE_NAME
FORBIDDEN_RUNTIME_REFERENCE_PATH = ASSET_ROOT / REFERENCE_NAME


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


def _compose_runtime_estate() -> Image.Image:
    """Returns the same complete image the Flutter map paints at B2 100%."""
    base_path = ASSET_ROOT / RUNTIME_LAYER_ORDER[0]
    with Image.open(base_path) as source:
        composed = source.convert("RGBA")
    for relative in RUNTIME_LAYER_ORDER[1:]:
        with Image.open(ASSET_ROOT / relative) as source:
            composed.alpha_composite(source.convert("RGBA"))
    return composed


def _check_reference() -> list[str]:
    with Image.open(REFERENCE_PATH) as source:
        reference = source.convert("RGB")
    composed = _compose_runtime_estate().convert("RGB")
    difference = ImageChops.difference(reference, composed)
    if difference.getbbox() is not None:
        return [
            "[fail] "
            f"{REFERENCE_PATH.relative_to(ROOT)} does not exactly match "
            "the complete runtime layer composition"
        ]
    return [
        "[pass] "
        f"{REFERENCE_PATH.relative_to(ROOT)} matches runtime composition"
    ]


def _write_reference() -> None:
    """Intentionally refreshes the QA reference from the approved layers."""
    QA_ROOT.mkdir(parents=True, exist_ok=True)
    _compose_runtime_estate().convert("RGB").save(REFERENCE_PATH)
    print(f"[write] {REFERENCE_PATH.relative_to(ROOT)} from runtime composition")


def main() -> int:
    if "--write-reference" in sys.argv[1:]:
        _write_reference()
        return 0
    problems = 0
    if FORBIDDEN_RUNTIME_REFERENCE_PATH.exists():
        print(
            "[fail] "
            f"{FORBIDDEN_RUNTIME_REFERENCE_PATH.relative_to(ROOT)} must stay "
            "outside the Flutter runtime asset root"
        )
        problems += 1
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
    if not REFERENCE_PATH.is_file():
        print(f"[missing] {REFERENCE_PATH.relative_to(ROOT)}")
        problems += 1
    else:
        for line in _check(REFERENCE_PATH, True):
            print(line)
            if line.startswith("[fail]"):
                problems += 1
    if problems == 0 and all(
        (ASSET_ROOT / relative).is_file() for relative in RUNTIME_LAYER_ORDER
    ):
        for line in _check_reference():
            print(line)
            if line.startswith("[fail]"):
                problems += 1
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
