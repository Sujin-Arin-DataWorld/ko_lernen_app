#!/usr/bin/env python3
"""Normalize one dedicated scenario poster to the canonical runtime format.

The operator supplies an input file, an explicit output directory, and a
scenario ID present in the canonical scene inventory. The tool performs a
focal-point cover crop, writes a deterministic 1536x1024 RGB/RGBA PNG, strips
source metadata, and refuses both in-place and existing-output writes.

Legacy category posters are never scanned or rewritten implicitly.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Collection, Optional

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INVENTORY_PATH = ROOT / "docs" / "data" / "scene_asset_inventory.json"
TARGET_SIZE = (1536, 1024)
SCENARIO_ID_PATTERN = re.compile(r"^[a-z0-9][a-z0-9_]*$")


@dataclass(frozen=True)
class NormalizationResult:
    source_path: Path
    output_path: Path
    source_size: tuple[int, int]
    crop_box: tuple[int, int, int, int]
    output_size: tuple[int, int]
    mode: str
    sha256: str


def load_canonical_ids(
    inventory_path: Path | str = DEFAULT_INVENTORY_PATH,
) -> frozenset[str]:
    path = Path(inventory_path)
    payload = json.loads(path.read_text(encoding="utf-8"))
    rows = payload.get("scenarios")
    if not isinstance(rows, list):
        raise ValueError(f"Canonical inventory has no scenarios list: {path}")
    ids = [row.get("id") for row in rows if isinstance(row, dict)]
    if any(not isinstance(scenario_id, str) or not scenario_id for scenario_id in ids):
        raise ValueError(f"Canonical inventory contains an invalid scenario ID: {path}")
    if len(ids) != len(set(ids)):
        raise ValueError(f"Canonical inventory contains duplicate scenario IDs: {path}")
    if payload.get("scenarioCount") != len(ids):
        raise ValueError(f"Canonical inventory scenarioCount does not match rows: {path}")
    return frozenset(ids)


def _validate_focal(value: float, name: str) -> float:
    if not math.isfinite(value) or not 0.0 <= value <= 1.0:
        raise ValueError(f"{name} must be between 0.0 and 1.0")
    return value


def cover_crop_box(
    source_size: tuple[int, int],
    *,
    focal_x: float = 0.5,
    focal_y: float = 0.5,
    target_size: tuple[int, int] = TARGET_SIZE,
) -> tuple[int, int, int, int]:
    """Return an integer cover-crop box centered on the normalized focal point."""
    width, height = source_size
    target_width, target_height = target_size
    if width <= 0 or height <= 0:
        raise ValueError("Source dimensions must be positive")
    if target_width <= 0 or target_height <= 0:
        raise ValueError("Target dimensions must be positive")
    focal_x = _validate_focal(focal_x, "focal_x")
    focal_y = _validate_focal(focal_y, "focal_y")

    source_ratio = width / height
    target_ratio = target_width / target_height
    if source_ratio > target_ratio:
        crop_width = min(width, max(1, round(height * target_ratio)))
        left = round(focal_x * width - crop_width / 2)
        left = min(max(left, 0), width - crop_width)
        return (left, 0, left + crop_width, height)
    if source_ratio < target_ratio:
        crop_height = min(height, max(1, round(width / target_ratio)))
        top = round(focal_y * height - crop_height / 2)
        top = min(max(top, 0), height - crop_height)
        return (0, top, width, top + crop_height)
    return (0, 0, width, height)


def _has_alpha(image: Image.Image) -> bool:
    return "A" in image.getbands() or "transparency" in image.info


def _strip_metadata(image: Image.Image) -> Image.Image:
    """Create a pixel-identical image with no inherited metadata."""
    return Image.frombytes(image.mode, image.size, image.tobytes())


def normalize_scene_poster(
    input_path: Path | str,
    output_dir: Path | str,
    scenario_id: str,
    *,
    canonical_ids: Optional[Collection[str]] = None,
    inventory_path: Path | str = DEFAULT_INVENTORY_PATH,
    focal_x: float = 0.5,
    focal_y: float = 0.5,
) -> NormalizationResult:
    source = Path(input_path)
    destination_dir = Path(output_dir)
    if not SCENARIO_ID_PATTERN.fullmatch(scenario_id):
        raise ValueError(
            "scenario_id must use the canonical lowercase snake-case filename form"
        )
    authority = (
        frozenset(canonical_ids)
        if canonical_ids is not None
        else load_canonical_ids(inventory_path)
    )
    if scenario_id not in authority:
        raise ValueError(f"scenario_id is not present in the canonical inventory: {scenario_id}")
    focal_x = _validate_focal(focal_x, "focal_x")
    focal_y = _validate_focal(focal_y, "focal_y")

    if not source.is_file():
        raise FileNotFoundError(f"Input image does not exist: {source}")
    if destination_dir.exists() and not destination_dir.is_dir():
        raise NotADirectoryError(f"Output must be a directory: {destination_dir}")
    destination = destination_dir / f"{scenario_id}.png"
    if source.resolve() == destination.resolve():
        raise ValueError("Refusing in-place scene poster overwrite")
    if destination.exists():
        raise FileExistsError(f"Refusing to overwrite existing output: {destination}")

    with Image.open(source) as opened:
        transposed = ImageOps.exif_transpose(opened)
        transposed.load()
        source_size = transposed.size
        mode = "RGBA" if _has_alpha(transposed) else "RGB"
        converted = transposed.convert(mode)
        crop_box = cover_crop_box(
            source_size,
            focal_x=focal_x,
            focal_y=focal_y,
        )
        cropped = converted.crop(crop_box)
        resized = cropped.resize(TARGET_SIZE, Image.Resampling.LANCZOS)
        normalized = _strip_metadata(resized)

    destination_dir.mkdir(parents=True, exist_ok=True)
    created_output = False
    try:
        with destination.open("xb") as handle:
            created_output = True
            normalized.save(
                handle,
                format="PNG",
                optimize=False,
                compress_level=9,
            )
    except BaseException:
        if created_output:
            destination.unlink(missing_ok=True)
        raise

    digest = hashlib.sha256(destination.read_bytes()).hexdigest()
    return NormalizationResult(
        source_path=source,
        output_path=destination,
        source_size=source_size,
        crop_box=crop_box,
        output_size=TARGET_SIZE,
        mode=mode,
        sha256=digest,
    )


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path, help="Source image file")
    parser.add_argument(
        "--output",
        required=True,
        type=Path,
        help="Explicit output directory; <scenario-id>.png is written inside it",
    )
    parser.add_argument("--scenario-id", required=True)
    parser.add_argument("--focal-x", type=float, default=0.5)
    parser.add_argument("--focal-y", type=float, default=0.5)
    parser.add_argument(
        "--inventory",
        type=Path,
        default=DEFAULT_INVENTORY_PATH,
        help="Canonical scene inventory JSON",
    )
    return parser


def main(argv: Optional[list[str]] = None) -> int:
    args = _parser().parse_args(argv)
    try:
        result = normalize_scene_poster(
            args.input,
            args.output,
            args.scenario_id,
            inventory_path=args.inventory,
            focal_x=args.focal_x,
            focal_y=args.focal_y,
        )
    except (OSError, ValueError) as error:
        print(f"[scene_poster_normalize] error: {error}", file=sys.stderr)
        return 1
    print(
        "[scene_poster_normalize] "
        f"{result.source_path} -> {result.output_path} "
        f"{result.output_size[0]}x{result.output_size[1]} {result.mode} "
        f"sha256={result.sha256}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
