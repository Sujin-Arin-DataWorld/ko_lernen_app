#!/usr/bin/env python3
"""Build verified transparent and runtime Anchae turnaround sprites."""

from __future__ import annotations

import argparse
import hashlib
import io
import json
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage


ROOT = Path(__file__).resolve().parents[1]
REVIEW_ROOT = (
    ROOT
    / "assets_unused"
    / "pending_review"
    / "personal_hanok_v3"
    / "turnaround_2d"
    / "ildu_anchae_blueprint100_v03_28deg_2p5d"
)
TRANSPARENT_ROOT = REVIEW_ROOT / "transparent_28deg"
RUNTIME_ROOT = (
    ROOT / "assets" / "illustrations" / "personal_hanok_v3" / "turnarounds"
)
METRICS_PATH = REVIEW_ROOT / "qa_metrics.json"
SHEET_PATH = REVIEW_ROOT / "ildu_anchae_8view_transparent_sheet.png"

SOURCE_SIZE = (1672, 941)
RUNTIME_SIZE = (384, 512)
MAX_RUNTIME_CONTENT_SIZE = (368, 440)
RUNTIME_BASELINE_Y = 472
SHEET_CELL_SIZE = (418, 235)
SHEET_SIZE = (1672, 470)
MIN_HORIZONTAL_MARGIN = 32
MIN_VERTICAL_MARGIN = 16

FRAME_NAMES = (
    ("00_front_000_28deg.png", "ildu_anchae_00_front.png", 0, "front"),
    (
        "01_front_right_045_28deg.png",
        "ildu_anchae_01_front_right.png",
        45,
        "front_right",
    ),
    ("02_right_090_28deg.png", "ildu_anchae_02_right.png", 90, "right"),
    (
        "03_rear_right_135_28deg.png",
        "ildu_anchae_03_rear_right.png",
        135,
        "rear_right",
    ),
    ("04_rear_180_28deg.png", "ildu_anchae_04_rear.png", 180, "rear"),
    (
        "05_rear_left_225_28deg.png",
        "ildu_anchae_05_rear_left.png",
        225,
        "rear_left",
    ),
    ("06_left_270_28deg.png", "ildu_anchae_06_left.png", 270, "left"),
    (
        "07_front_left_315_28deg.png",
        "ildu_anchae_07_front_left.png",
        315,
        "front_left",
    ),
)


class PromotionError(ValueError):
    """Fail-closed Anchae runtime promotion."""


@dataclass(frozen=True)
class EncodedFrame:
    source_name: str
    output_name: str
    png_bytes: bytes
    content_bounds: tuple[int, int, int, int]

    @property
    def sha256(self) -> str:
        return hashlib.sha256(self.png_bytes).hexdigest().upper()


@dataclass(frozen=True)
class PromotionBundle:
    transparent_frames: tuple[EncodedFrame, ...]
    runtime_frames: tuple[EncodedFrame, ...]
    sheet_bytes: bytes
    metrics: dict[str, object]


def _sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def _encode_png(image: Image.Image) -> bytes:
    encoded = io.BytesIO()
    image.save(encoded, format="PNG", optimize=True, compress_level=9)
    return encoded.getvalue()


def _connected_neutral_background(rgb: np.ndarray) -> np.ndarray:
    """Find only the bright neutral background reachable from the canvas edge."""

    low = rgb.min(axis=2)
    high = rgb.max(axis=2)
    chroma = high.astype(np.int16) - low.astype(np.int16)
    candidate = (low >= 230) & (chroma <= 18)
    seeds = np.zeros(candidate.shape, dtype=bool)
    seeds[0, :] = candidate[0, :]
    seeds[-1, :] = candidate[-1, :]
    seeds[:, 0] = candidate[:, 0]
    seeds[:, -1] = candidate[:, -1]
    return ndimage.binary_propagation(
        seeds,
        structure=np.ones((3, 3), dtype=bool),
        mask=candidate,
    )


def _dominant_foreground(rgb: np.ndarray) -> tuple[np.ndarray, dict[str, object]]:
    foreground = ~_connected_neutral_background(rgb)
    labels, component_count = ndimage.label(
        foreground,
        structure=np.ones((3, 3), dtype=bool),
    )
    if component_count == 0:
        raise PromotionError("no foreground component found")
    sizes = np.bincount(labels.ravel())
    largest_label = 1 + int(np.argmax(sizes[1:]))
    dominant = labels == largest_label
    substantial = sizes[1:][sizes[1:] >= 16]
    dominant_ratio = float(substantial.max() / substantial.sum())
    if dominant_ratio < 0.999:
        raise PromotionError(
            f"foreground dominant ratio {dominant_ratio:.5%} is below 99.9%"
        )
    return dominant, {
        "component_count": int(component_count),
        "substantial_component_count": int(len(substantial)),
        "dominant_ratio": dominant_ratio,
    }


def _extract_transparent(
    source_path: Path,
) -> tuple[Image.Image, dict[str, object]]:
    with Image.open(source_path) as source:
        if source.format != "PNG" or source.mode != "RGB":
            raise PromotionError(
                f"{source_path.name} must be an RGB PNG, got "
                f"{source.format}/{source.mode}"
            )
        if source.size != SOURCE_SIZE:
            raise PromotionError(
                f"{source_path.name} must be {SOURCE_SIZE}, got {source.size}"
            )
        rgb = np.asarray(source, dtype=np.uint8)

    foreground, component_metrics = _dominant_foreground(rgb)
    distance_inside = ndimage.distance_transform_edt(foreground)
    alpha = np.where(
        foreground,
        np.clip(distance_inside / 1.5, 0.0, 1.0) * 255.0,
        0.0,
    ).astype(np.uint8)

    clean_rgb = rgb.copy()
    core = distance_inside >= 2.0
    fringe = foreground & (alpha > 0) & (alpha < 255)
    max_fringe_core_rgb_delta = 0
    if core.any() and fringe.any():
        _, nearest = ndimage.distance_transform_edt(~core, return_indices=True)
        nearest_rgb = rgb[nearest[0], nearest[1]]
        clean_rgb[fringe] = nearest_rgb[fringe]
        max_fringe_core_rgb_delta = int(
            np.abs(
                clean_rgb[fringe].astype(np.int16)
                - nearest_rgb[fringe].astype(np.int16)
            ).max()
        )

    rgba = Image.fromarray(np.dstack((clean_rgb, alpha)))
    bounds = rgba.getchannel("A").getbbox()
    if bounds is None:
        raise PromotionError(f"{source_path.name}: extracted image is empty")
    left, top, right, bottom = bounds
    if left < MIN_HORIZONTAL_MARGIN or SOURCE_SIZE[0] - right < MIN_HORIZONTAL_MARGIN:
        raise PromotionError(f"{source_path.name}: horizontal safe margin failed {bounds}")
    if top < MIN_VERTICAL_MARGIN or SOURCE_SIZE[1] - bottom < MIN_VERTICAL_MARGIN:
        raise PromotionError(f"{source_path.name}: vertical safe margin failed {bounds}")
    corners = (
        int(alpha[0, 0]),
        int(alpha[0, -1]),
        int(alpha[-1, 0]),
        int(alpha[-1, -1]),
    )
    if corners != (0, 0, 0, 0):
        raise PromotionError(f"{source_path.name}: corners are not transparent")
    if int(alpha.min()) != 0 or int(alpha.max()) != 255:
        raise PromotionError(f"{source_path.name}: alpha extrema are invalid")
    if max_fringe_core_rgb_delta != 0:
        raise PromotionError(f"{source_path.name}: matte fringe cleaning drifted")

    metrics: dict[str, object] = {
        "source_file": source_path.relative_to(REVIEW_ROOT).as_posix(),
        "source_sha256": _sha256_file(source_path),
        "source_mode": "RGB",
        "source_size": list(SOURCE_SIZE),
        "content_bbox": list(bounds),
        "alpha_extrema": [int(alpha.min()), int(alpha.max())],
        "transparent_pixels": int(np.count_nonzero(alpha == 0)),
        "partial_alpha_pixels": int(
            np.count_nonzero((alpha > 0) & (alpha < 255))
        ),
        "opaque_pixels": int(np.count_nonzero(alpha == 255)),
        "corner_alpha": list(corners),
        "fringe_rgb_changed_pixels": int(np.count_nonzero(fringe)),
        "max_fringe_core_rgb_delta": max_fringe_core_rgb_delta,
        **component_metrics,
    }
    return rgba, metrics


def _resize_premultiplied(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    return image.convert("RGBa").resize(size, Image.Resampling.LANCZOS).convert("RGBA")


def _build_runtime_frames(
    transparent_images: list[Image.Image],
) -> tuple[EncodedFrame, ...]:
    bounds = [image.getchannel("A").getbbox() for image in transparent_images]
    if any(bound is None for bound in bounds):
        raise PromotionError("transparent frame set contains an empty frame")
    typed_bounds = [bound for bound in bounds if bound is not None]
    max_width = max(right - left for left, _, right, _ in typed_bounds)
    max_height = max(bottom - top for _, top, _, bottom in typed_bounds)
    scale = min(
        MAX_RUNTIME_CONTENT_SIZE[0] / max_width,
        MAX_RUNTIME_CONTENT_SIZE[1] / max_height,
    )

    runtime_frames: list[EncodedFrame] = []
    for (_, runtime_name, _, _), image, bound in zip(
        FRAME_NAMES,
        transparent_images,
        typed_bounds,
        strict=True,
    ):
        crop = image.crop(bound)
        target_size = (
            max(1, round(crop.width * scale)),
            max(1, round(crop.height * scale)),
        )
        sprite = _resize_premultiplied(crop, target_size)
        left = (RUNTIME_SIZE[0] - sprite.width) // 2
        top = RUNTIME_BASELINE_Y - sprite.height
        right = left + sprite.width
        bottom = top + sprite.height
        if left < 0 or top < 0 or right > RUNTIME_SIZE[0] or bottom > RUNTIME_SIZE[1]:
            raise PromotionError(f"{runtime_name}: runtime frame does not fit")
        canvas = Image.new("RGBA", RUNTIME_SIZE, (0, 0, 0, 0))
        canvas.alpha_composite(sprite, (left, top))
        actual_bounds = canvas.getchannel("A").getbbox()
        expected_bounds = (left, top, right, bottom)
        if actual_bounds != expected_bounds:
            raise PromotionError(
                f"{runtime_name}: alpha bounds {actual_bounds} != {expected_bounds}"
            )
        runtime_frames.append(
            EncodedFrame(
                source_name=runtime_name,
                output_name=runtime_name,
                png_bytes=_encode_png(canvas),
                content_bounds=expected_bounds,
            )
        )
    return tuple(runtime_frames)


def _build_sheet(images: list[Image.Image]) -> bytes:
    sheet = Image.new("RGBA", SHEET_SIZE, (0, 0, 0, 0))
    for index, image in enumerate(images):
        reduced = _resize_premultiplied(image, SHEET_CELL_SIZE)
        sheet.alpha_composite(
            reduced,
            ((index % 4) * SHEET_CELL_SIZE[0], (index // 4) * SHEET_CELL_SIZE[1]),
        )
    return _encode_png(sheet)


def build_bundle() -> PromotionBundle:
    transparent_frames: list[EncodedFrame] = []
    transparent_images: list[Image.Image] = []
    frame_metrics: list[dict[str, object]] = []
    for source_name, _, degrees, direction in FRAME_NAMES:
        source_path = REVIEW_ROOT / source_name
        if not source_path.is_file():
            raise PromotionError(f"missing approved source frame: {source_path}")
        image, metrics = _extract_transparent(source_path)
        png_bytes = _encode_png(image)
        bounds = image.getchannel("A").getbbox()
        if bounds is None:
            raise PromotionError(f"{source_name}: extracted image is empty")
        transparent_frames.append(
            EncodedFrame(
                source_name=source_name,
                output_name=source_name,
                png_bytes=png_bytes,
                content_bounds=bounds,
            )
        )
        transparent_images.append(image)
        metrics.update(
            {
                "degrees": degrees,
                "direction": direction,
                "transparent_file": f"transparent_28deg/{source_name}",
                "transparent_sha256": hashlib.sha256(png_bytes).hexdigest().upper(),
            }
        )
        frame_metrics.append(metrics)

    runtime_frames = _build_runtime_frames(transparent_images)
    sheet_bytes = _build_sheet(transparent_images)
    runtime_metrics = [
        {
            "file": frame.output_name,
            "sha256": frame.sha256,
            "content_bbox": list(frame.content_bounds),
        }
        for frame in runtime_frames
    ]
    metrics: dict[str, object] = {
        "status": "runtime_approved",
        "generator": "approved_v03_eight_direction_source_set",
        "postprocess": (
            "boundary_connected_neutral_extraction_and_premultiplied_rgba_normalization"
        ),
        "camera_elevation_degrees": 28,
        "azimuth_interval_degrees": 45,
        "source_size": list(SOURCE_SIZE),
        "runtime_size": list(RUNTIME_SIZE),
        "runtime_baseline_y": RUNTIME_BASELINE_Y,
        "sheet": {
            "file": SHEET_PATH.name,
            "sha256": hashlib.sha256(sheet_bytes).hexdigest().upper(),
            "size": list(SHEET_SIZE),
            "mode": "RGBA",
        },
        "frames": frame_metrics,
        "runtime_frames": runtime_metrics,
    }
    return PromotionBundle(
        transparent_frames=tuple(transparent_frames),
        runtime_frames=runtime_frames,
        sheet_bytes=sheet_bytes,
        metrics=metrics,
    )


def promote(*, apply: bool) -> PromotionBundle:
    bundle = build_bundle()
    if apply:
        TRANSPARENT_ROOT.mkdir(parents=True, exist_ok=True)
        RUNTIME_ROOT.mkdir(parents=True, exist_ok=True)
        for frame in bundle.transparent_frames:
            (TRANSPARENT_ROOT / frame.output_name).write_bytes(frame.png_bytes)
        for frame in bundle.runtime_frames:
            (RUNTIME_ROOT / frame.output_name).write_bytes(frame.png_bytes)
        SHEET_PATH.write_bytes(bundle.sheet_bytes)
        METRICS_PATH.write_text(
            json.dumps(bundle.metrics, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    return bundle


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply",
        action="store_true",
        help="write the verified transparent review and runtime PNGs",
    )
    args = parser.parse_args(argv)
    try:
        bundle = promote(apply=args.apply)
    except (OSError, PromotionError) as error:
        print(f"[fail] {error}")
        return 1
    mode = "promoted" if args.apply else "ready"
    print(
        f"[pass] {mode}: {len(bundle.transparent_frames)} RGBA review frames, "
        f"{len(bundle.runtime_frames)} runtime frames"
    )
    for frame in bundle.runtime_frames:
        print(
            f"  {frame.output_name}: bounds={frame.content_bounds} "
            f"sha256={frame.sha256}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
