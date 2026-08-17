#!/usr/bin/env python3
"""Fail-closed image contract for the canonical personal Hanok map family."""

from __future__ import annotations

from pathlib import Path
import sys

from PIL import Image, ImageChops

sys.path.insert(0, str(Path(__file__).resolve().parent))
from hanok_v1_asset_contract import (
    A1_RUNTIME_STATES_ROOT,
    ROOT,
    RUNTIME_MAP_ROOT,
    a1_expected_files,
    a1_hard_max_bytes,
    camera_geometry,
    load_provenance,
    qa_composite_path,
)


ASSET_ROOT = RUNTIME_MAP_ROOT
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
    reference_path = qa_composite_path()
    runtime_alias = ASSET_ROOT / "reference_full_estate.png"
    if runtime_alias.is_file():
        alias = (
            runtime_alias.relative_to(ROOT)
            if ROOT in runtime_alias.parents
            else runtime_alias
        )
        return [
            "[fail] "
            f"{alias} is a QA composite inside the "
            "runtime map folder and would ship in the Flutter bundle"
        ]
    with Image.open(reference_path) as source:
        reference = source.convert("RGB")
    composed = _compose_runtime_estate().convert("RGB")
    difference = ImageChops.difference(reference, composed)
    if difference.getbbox() is not None:
        return [
            "[fail] "
            f"{reference_path.relative_to(ROOT)} does not exactly match "
            "the complete runtime layer composition"
        ]
    return [
        "[pass] "
        f"{reference_path.relative_to(ROOT)} matches runtime composition"
    ]


def _write_reference() -> None:
    """Intentionally refreshes the QA-only reference from the approved layers."""
    output = qa_composite_path()
    if output.parent != (ROOT / "assets_unused" / "pending_review"):
        raise SystemExit("refusing to write the QA composite outside pending_review")
    if ASSET_ROOT in output.parents or output.parent == ASSET_ROOT:
        raise SystemExit("refusing to write the QA composite into the runtime map")
    output.parent.mkdir(parents=True, exist_ok=True)
    _compose_runtime_estate().convert("RGB").save(output)
    print(f"[write] {output.relative_to(ROOT)} from runtime composition")


def _a1_runtime_leftovers(expected: list[str]) -> list[str]:
    if not A1_RUNTIME_STATES_ROOT.is_dir():
        return []
    expected_names = set(expected)
    return sorted(
        child.name
        for child in A1_RUNTIME_STATES_ROOT.iterdir()
        if child.is_file() and child.name not in expected_names
    )


def _check_a1_runtime_states(*, required: bool) -> list[str]:
    provenance = load_provenance()
    expected = a1_expected_files(provenance)
    hard_max = a1_hard_max_bytes(provenance)
    geometry = camera_geometry(provenance)
    present = [name for name in expected if (A1_RUNTIME_STATES_ROOT / name).is_file()]
    leftovers = _a1_runtime_leftovers(expected)
    lines: list[str] = []
    if leftovers:
        lines.append(
            "[fail] runtime A1 directory has leftover files: " + ", ".join(leftovers)
        )
    if not present and not required:
        return lines or ["[pass] A1 runtime states are absent and were not promoted"]
    missing = [name for name in expected if name not in present]
    if missing:
        lines.append(
            "[fail] A1 runtime states must be promoted atomically; missing "
            + ", ".join(missing)
        )
        return lines
    for name in expected:
        path = A1_RUNTIME_STATES_ROOT / name
        with Image.open(path) as source:
            image = source.copy()
        errors: list[str] = []
        if source_format(path) != "WEBP":
            errors.append(f"format={source_format(path)}, expected=WEBP")
        if image.mode != "RGB":
            errors.append(f"mode={image.mode}, expected RGB")
        if image.size != (
            geometry["canvas_width"],
            geometry["canvas_height"],
        ):
            errors.append(
                f"size={image.width}x{image.height}, expected="
                f"{geometry['canvas_width']}x{geometry['canvas_height']}"
            )
        size_bytes = path.stat().st_size
        if size_bytes > hard_max:
            errors.append(f"bytes={size_bytes}, hardMax={hard_max}")
        chroma = _chroma_key_count(image)
        if chroma:
            errors.append(f"contains {chroma} opaque #00ff00 chroma-key pixels")
        relative = path.relative_to(ROOT)
        if errors:
            lines.append(f"[fail] {relative}: {'; '.join(errors)}")
        else:
            lines.append(f"[pass] {relative} {image.width}x{image.height} bytes={size_bytes}")
    return lines


def source_format(path: Path) -> str:
    with Image.open(path) as source:
        return (source.format or "").upper()


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    if "--write-reference" in args:
        _write_reference()
        return 0
    require_a1 = "--require-a1-states" in args
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
    if problems == 0 and all((ASSET_ROOT / relative).is_file() for relative in RUNTIME_LAYER_ORDER):
        for line in _check_reference():
            print(line)
            if line.startswith("[fail]"):
                problems += 1
    for line in _check_a1_runtime_states(required=require_a1):
        print(line)
        if line.startswith("[fail]"):
            problems += 1
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
