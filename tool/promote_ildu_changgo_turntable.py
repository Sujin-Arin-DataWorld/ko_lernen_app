#!/usr/bin/env python3
"""Promote the approved Ildu Changgo turnaround into runtime-sized PNGs."""

from __future__ import annotations

import argparse
import hashlib
import io
import json
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
REVIEW_ROOT = (
    ROOT
    / "assets_unused"
    / "pending_review"
    / "personal_hanok_v3"
    / "turnaround_2d"
    / "ildu_changgo_blueprint200_28deg_v01"
)
SOURCE_ROOT = REVIEW_ROOT / "transparent_28deg"
METRICS_PATH = REVIEW_ROOT / "qa_metrics.json"
RUNTIME_ROOT = (
    ROOT / "assets" / "illustrations" / "personal_hanok_v3" / "turnarounds"
)

CANVAS_SIZE = (384, 512)
MAX_CONTENT_SIZE = (368, 440)
BASELINE_Y = 472

FRAME_NAMES = (
    ("00_front_000.png", "ildu_changgo_00_front.png"),
    ("01_front_right_045.png", "ildu_changgo_01_front_right.png"),
    ("02_right_090.png", "ildu_changgo_02_right.png"),
    ("03_rear_right_135.png", "ildu_changgo_03_rear_right.png"),
    ("04_rear_180.png", "ildu_changgo_04_rear.png"),
    ("05_rear_left_225.png", "ildu_changgo_05_rear_left.png"),
    ("06_left_270.png", "ildu_changgo_06_left.png"),
    ("07_front_left_315.png", "ildu_changgo_07_front_left.png"),
)


class PromotionError(ValueError):
    """Fail-closed Changgo runtime promotion."""


@dataclass(frozen=True)
class RuntimeFrame:
    source_name: str
    runtime_name: str
    png_bytes: bytes
    content_bounds: tuple[int, int, int, int]

    @property
    def sha256(self) -> str:
        return hashlib.sha256(self.png_bytes).hexdigest().upper()


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def _approved_inputs() -> tuple[tuple[Path, str, tuple[int, int, int, int]], ...]:
    metrics = json.loads(METRICS_PATH.read_text(encoding="utf-8"))
    expected_size = tuple(metrics["frame_size"])
    approved = {
        tile["output_file"]: (tile["output_sha256"], tuple(tile["content_bbox"]))
        for tile in metrics["tiles"]
    }
    inputs = []
    for source_name, _ in FRAME_NAMES:
        relative_name = f"transparent_28deg/{source_name}"
        source_path = SOURCE_ROOT / source_name
        if not source_path.is_file():
            raise PromotionError(f"missing approved frame: {source_path}")
        if relative_name not in approved:
            raise PromotionError(f"missing QA ledger entry: {relative_name}")
        expected_hash, expected_bounds = approved[relative_name]
        actual_hash = _sha256_file(source_path)
        if actual_hash != expected_hash.upper():
            raise PromotionError(
                f"approved frame SHA-256 drifted: {source_name} "
                f"({actual_hash} != {expected_hash})"
            )
        with Image.open(source_path) as source:
            if source.format != "PNG" or source.mode != "RGBA":
                raise PromotionError(
                    f"{source_name} must be an RGBA PNG, got {source.format}/{source.mode}"
                )
            if source.size != expected_size:
                raise PromotionError(
                    f"{source_name} must be {expected_size}, got {source.size}"
                )
            actual_bounds = source.getchannel("A").getbbox()
        if actual_bounds != expected_bounds:
            raise PromotionError(
                f"approved alpha bounds drifted: {source_name} "
                f"({actual_bounds} != {expected_bounds})"
            )
        inputs.append((source_path, actual_hash, actual_bounds))
    return tuple(inputs)


def build_runtime_frames() -> tuple[RuntimeFrame, ...]:
    approved = _approved_inputs()
    max_width = max(bounds[2] - bounds[0] for _, _, bounds in approved)
    max_height = max(bounds[3] - bounds[1] for _, _, bounds in approved)
    scale = min(
        MAX_CONTENT_SIZE[0] / max_width,
        MAX_CONTENT_SIZE[1] / max_height,
    )

    frames = []
    for (source_name, runtime_name), (source_path, _, bounds) in zip(
        FRAME_NAMES, approved, strict=True
    ):
        source_width = bounds[2] - bounds[0]
        source_height = bounds[3] - bounds[1]
        runtime_width = max(1, round(source_width * scale))
        runtime_height = max(1, round(source_height * scale))
        left = (CANVAS_SIZE[0] - runtime_width) // 2
        top = BASELINE_Y - runtime_height
        right = left + runtime_width
        bottom = top + runtime_height
        if left < 0 or top < 0 or right > CANVAS_SIZE[0] or bottom > CANVAS_SIZE[1]:
            raise PromotionError(f"{source_name} does not fit the runtime canvas")

        with Image.open(source_path) as source:
            crop = source.crop(bounds)
            # Resize premultiplied RGBA so transparent-edge RGB cannot introduce
            # a matte. This changes scale only; it does not recolor the artwork.
            resized = (
                crop.convert("RGBa")
                .resize((runtime_width, runtime_height), Image.Resampling.LANCZOS)
                .convert("RGBA")
            )
        canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
        canvas.alpha_composite(resized, (left, top))
        actual_bounds = canvas.getchannel("A").getbbox()
        expected_bounds = (left, top, right, bottom)
        if actual_bounds != expected_bounds:
            raise PromotionError(
                f"runtime alpha bounds drifted: {runtime_name} "
                f"({actual_bounds} != {expected_bounds})"
            )
        encoded = io.BytesIO()
        canvas.save(encoded, format="PNG", optimize=True, compress_level=9)
        frames.append(
            RuntimeFrame(
                source_name=source_name,
                runtime_name=runtime_name,
                png_bytes=encoded.getvalue(),
                content_bounds=expected_bounds,
            )
        )
    return tuple(frames)


def promote(*, apply: bool) -> tuple[RuntimeFrame, ...]:
    frames = build_runtime_frames()
    if apply:
        RUNTIME_ROOT.mkdir(parents=True, exist_ok=True)
        for frame in frames:
            target = RUNTIME_ROOT / frame.runtime_name
            temporary = target.with_suffix(".tmp.png")
            temporary.write_bytes(frame.png_bytes)
            temporary.replace(target)
    return frames


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply",
        action="store_true",
        help="write all eight verified runtime PNGs",
    )
    args = parser.parse_args(argv)
    try:
        frames = promote(apply=args.apply)
    except (OSError, KeyError, json.JSONDecodeError, PromotionError) as error:
        print(f"[fail] {error}")
        return 1
    mode = "promoted" if args.apply else "ready"
    print(f"[pass] {mode} {len(frames)} Changgo runtime frames")
    for frame in frames:
        print(
            f"  {frame.runtime_name}: bounds={frame.content_bounds} "
            f"sha256={frame.sha256}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
