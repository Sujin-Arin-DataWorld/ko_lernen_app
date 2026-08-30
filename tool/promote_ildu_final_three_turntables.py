#!/usr/bin/env python3
"""Promote and audit the last three Ildugotaek 2.5D turntables.

The high-resolution image-generation outputs are staging inputs only.  The
committed review sprites and runtime sprites are the same encoded PNG bytes.
The three V3 source originals are copied separately without decoding so their
SHA-256 identity is provable.
"""

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
V3_ROOT = ROOT / "assets_unused" / "pending_review" / "personal_hanok_v3"
REVIEW_ROOT = V3_ROOT / "turnaround_2d"
RUNTIME_ROOT = ROOT / "assets" / "illustrations" / "personal_hanok_v3" / "turnarounds"
RUNTIME_SIZE = (384, 512)
RUNTIME_BASELINE_Y = 472
MAX_CONTENT_WIDTH = 368
FRAME_SUFFIXES = (
    "00_front",
    "01_front_right",
    "02_right",
    "03_rear_right",
    "04_rear",
    "05_rear_left",
    "06_left",
    "07_front_left",
)


class PromotionError(ValueError):
    """Fail-closed final-three turnaround promotion error."""


@dataclass(frozen=True)
class BuildingSpec:
    key: str
    runtime_prefix: str
    source_original: Path
    expected_source_sha256: str
    review_directory_name: str
    target_content_height: int
    blueprint_authority: str

    @property
    def review_root(self) -> Path:
        return REVIEW_ROOT / self.review_directory_name

    @property
    def final_review_root(self) -> Path:
        return self.review_root / "final_384x512"

    @property
    def preserved_original(self) -> Path:
        return self.review_root / "source_original_exact.png"

    @property
    def qa_path(self) -> Path:
        return self.review_root / "qa_metrics.json"

    def filename(self, index: int) -> str:
        return f"{self.runtime_prefix}_{FRAME_SUFFIXES[index]}.png"


BUILDINGS = {
    "anchae_store": BuildingSpec(
        key="anchae_store",
        runtime_prefix="ildu_anchae_store",
        source_original=V3_ROOT / "안채곳간채.png",
        expected_source_sha256="37B3B0B35BC27A07B72190B11A8CECCACEE265EFEA79B1F4C4BC91EC41301D7B",
        review_directory_name="ildu_anchae_store_blueprint100_v01_28deg",
        target_content_height=244,
        blueprint_authority=(
            "recorded drawings: 9360x2700 mm, four bays 2250+2250+2430+2430, "
            "five principal column axes, matbae roof, documented side/rear vents"
        ),
    ),
    "gokgan": BuildingSpec(
        key="gokgan",
        runtime_prefix="ildu_gokgan",
        source_original=V3_ROOT / "gokganchae_try02_5kan.png",
        expected_source_sha256="6E5F7B91EB60A417906F742C695749B50CF9A471EB01C92E8106B18F06CCB709",
        review_directory_name="ildu_gokgan_blueprint100_v01_28deg",
        target_content_height=268,
        blueprint_authority=(
            "recorded drawings: 9750x5460 mm, five 1950 mm front/rear bays, "
            "two 2730 mm side bays, central front door, paljak roof"
        ),
    ),
    "toilet": BuildingSpec(
        key="toilet",
        runtime_prefix="ildu_toilet",
        source_original=V3_ROOT / "화장실.png",
        expected_source_sha256="BDE2AF8FB1CEF2095E2EF897A9DCE4C65FAB2BA7BCFE306A99995F9C0366207D",
        review_directory_name="ildu_toilet_source100_v01_28deg",
        target_content_height=344,
        blueprint_authority=(
            "no dedicated toilet drawing was found; V3 source image is the sole "
            "shape, material, color, and identity authority"
        ),
    ),
}


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def _encode_png(image: Image.Image) -> bytes:
    output = io.BytesIO()
    image.save(output, format="PNG", optimize=True, compress_level=9)
    return output.getvalue()


def _connected_neutral_background(rgb: np.ndarray) -> np.ndarray:
    low = rgb.min(axis=2)
    high = rgb.max(axis=2)
    chroma = high.astype(np.int16) - low.astype(np.int16)
    candidate = (low >= 225) & (chroma <= 22)
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


def _extract_rgba(path: Path) -> Image.Image:
    with Image.open(path) as source:
        source.load()
        if source.format != "PNG":
            raise PromotionError(f"{path.name}: expected PNG")
        if source.mode == "RGBA" and source.getchannel("A").getextrema()[0] == 0:
            rgba = source.copy()
        elif source.mode in {"RGB", "RGBA"}:
            rgb = np.asarray(source.convert("RGB"), dtype=np.uint8)
            foreground = ~_connected_neutral_background(rgb)
            labels, component_count = ndimage.label(
                foreground,
                structure=np.ones((3, 3), dtype=bool),
            )
            if component_count == 0:
                raise PromotionError(f"{path.name}: no foreground found")
            sizes = np.bincount(labels.ravel())
            dominant = labels == (1 + int(np.argmax(sizes[1:])))
            distance = ndimage.distance_transform_edt(dominant)
            alpha = np.where(
                dominant,
                np.clip(distance / 1.5, 0.0, 1.0) * 255.0,
                0.0,
            ).astype(np.uint8)
            clean_rgb = rgb.copy()
            core = distance >= 2.0
            fringe = dominant & (alpha > 0) & (alpha < 255)
            if core.any() and fringe.any():
                _, nearest = ndimage.distance_transform_edt(~core, return_indices=True)
                nearest_rgb = rgb[nearest[0], nearest[1]]
                clean_rgb[fringe] = nearest_rgb[fringe]
            rgba = Image.fromarray(np.dstack((clean_rgb, alpha))).convert("RGBA")
        else:
            raise PromotionError(f"{path.name}: unsupported mode {source.mode}")

    alpha = rgba.getchannel("A")
    if alpha.getextrema() != (0, 255) or alpha.getbbox() is None:
        raise PromotionError(f"{path.name}: invalid alpha extraction")
    return rgba


def _resize_premultiplied(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    return image.convert("RGBa").resize(size, Image.Resampling.LANCZOS).convert("RGBA")


def _build_final_frames(spec: BuildingSpec, staging_root: Path) -> list[bytes]:
    crops: list[Image.Image] = []
    for index in range(8):
        path = staging_root / spec.key / spec.filename(index)
        if not path.is_file():
            raise PromotionError(f"missing staging frame: {path}")
        rgba = _extract_rgba(path)
        bounds = rgba.getchannel("A").getbbox()
        if bounds is None:
            raise PromotionError(f"{path.name}: empty foreground")
        crops.append(rgba.crop(bounds))

    height = spec.target_content_height
    widest = max(round(crop.width * height / crop.height) for crop in crops)
    if widest > MAX_CONTENT_WIDTH:
        height = max(1, int(height * MAX_CONTENT_WIDTH / widest))

    outputs: list[bytes] = []
    for crop in crops:
        width = max(1, round(crop.width * height / crop.height))
        sprite = _resize_premultiplied(crop, (width, height))
        resized_bounds = sprite.getchannel("A").getbbox()
        if resized_bounds is None:
            raise PromotionError(f"{spec.key}: resized sprite is empty")
        sprite = sprite.crop(resized_bounds)
        width, sprite_height = sprite.size
        left = (RUNTIME_SIZE[0] - width) // 2
        top = RUNTIME_BASELINE_Y - sprite_height
        canvas = Image.new("RGBA", RUNTIME_SIZE, (0, 0, 0, 0))
        canvas.alpha_composite(sprite, (left, top))
        bounds = canvas.getchannel("A").getbbox()
        if bounds is None or bounds[3] != RUNTIME_BASELINE_Y:
            raise PromotionError(f"{spec.key}: invalid normalized bounds {bounds}")
        outputs.append(_encode_png(canvas))
    return outputs


def promote(staging_root: Path) -> dict[str, object]:
    summary: dict[str, object] = {}
    RUNTIME_ROOT.mkdir(parents=True, exist_ok=True)
    for key, spec in BUILDINGS.items():
        source_bytes = spec.source_original.read_bytes()
        actual_source_hash = _sha256(source_bytes)
        if actual_source_hash != spec.expected_source_sha256:
            raise PromotionError(
                f"{key}: source hash {actual_source_hash} != locked hash"
            )
        outputs = _build_final_frames(spec, staging_root)
        spec.final_review_root.mkdir(parents=True, exist_ok=True)
        spec.preserved_original.write_bytes(source_bytes)
        frames: list[dict[str, object]] = []
        for index, data in enumerate(outputs):
            filename = spec.filename(index)
            review_path = spec.final_review_root / filename
            runtime_path = RUNTIME_ROOT / filename
            review_path.write_bytes(data)
            runtime_path.write_bytes(data)
            with Image.open(io.BytesIO(data)) as image:
                bbox = image.getchannel("A").getbbox()
            frames.append(
                {
                    "index": index,
                    "azimuth_degrees": index * 45,
                    "file": filename,
                    "sha256": _sha256(data),
                    "bbox": list(bbox) if bbox else None,
                }
            )
        metrics = {
            "status": "runtime_promoted",
            "source_original": spec.source_original.name,
            "preserved_original": spec.preserved_original.name,
            "source_sha256": actual_source_hash,
            "source_bytes_preserved": True,
            "generated_views_are_pixel_identical_to_source": False,
            "authority": spec.blueprint_authority,
            "camera_elevation_degrees": 28,
            "azimuth_interval_degrees": 45,
            "runtime_size": list(RUNTIME_SIZE),
            "runtime_baseline_y": RUNTIME_BASELINE_Y,
            "review_runtime_bytes_identical": True,
            "frames": frames,
        }
        spec.qa_path.write_text(
            json.dumps(metrics, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        summary[key] = metrics
    return summary


def audit_committed_outputs() -> dict[str, object]:
    report: dict[str, object] = {}
    for key, spec in BUILDINGS.items():
        source_bytes = spec.source_original.read_bytes()
        preserved_bytes = spec.preserved_original.read_bytes()
        source_hash = _sha256(source_bytes)
        if source_hash != spec.expected_source_sha256:
            raise PromotionError(f"{key}: source hash drift")
        if preserved_bytes != source_bytes:
            raise PromotionError(f"{key}: preserved original is not byte-identical")

        frames: list[dict[str, object]] = []
        for index in range(8):
            filename = spec.filename(index)
            review_path = spec.final_review_root / filename
            runtime_path = RUNTIME_ROOT / filename
            review_bytes = review_path.read_bytes()
            runtime_bytes = runtime_path.read_bytes()
            if review_bytes != runtime_bytes:
                raise PromotionError(f"{filename}: review/runtime bytes differ")
            with Image.open(io.BytesIO(runtime_bytes)) as image:
                image.load()
                if image.format != "PNG" or image.mode != "RGBA" or image.size != RUNTIME_SIZE:
                    raise PromotionError(f"{filename}: invalid PNG contract")
                if image.getchannel("A").getextrema() != (0, 255):
                    raise PromotionError(f"{filename}: invalid alpha extrema")
                bbox = image.getchannel("A").getbbox()
                if bbox is None or bbox[3] != RUNTIME_BASELINE_Y:
                    raise PromotionError(f"{filename}: invalid baseline {bbox}")
                corners = (
                    image.getpixel((0, 0))[3],
                    image.getpixel((RUNTIME_SIZE[0] - 1, 0))[3],
                    image.getpixel((0, RUNTIME_SIZE[1] - 1))[3],
                    image.getpixel((RUNTIME_SIZE[0] - 1, RUNTIME_SIZE[1] - 1))[3],
                )
                if corners != (0, 0, 0, 0):
                    raise PromotionError(f"{filename}: opaque corner")
            digest = _sha256(runtime_bytes)
            frames.append(
                {
                    "file": filename,
                    "sha256": digest,
                    "review_sha256": _sha256(review_bytes),
                    "runtime_sha256": digest,
                    "bbox": list(bbox),
                    "runtime_path": runtime_path,
                }
            )
        if len({frame["sha256"] for frame in frames}) != 8:
            raise PromotionError(f"{key}: repeated directional frame")
        report[key] = {
            "source_sha256": source_hash,
            "baseline_y": RUNTIME_BASELINE_Y,
            "frames": frames,
        }
    return report


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--staging-root", type=Path)
    parser.add_argument("--audit", action="store_true")
    args = parser.parse_args(argv)
    try:
        if args.staging_root is not None:
            promote(args.staging_root)
        if args.audit or args.staging_root is None:
            report = audit_committed_outputs()
            print(f"[pass] audited {sum(len(v['frames']) for v in report.values())} frames")
    except (OSError, PromotionError) as error:
        print(f"[fail] {error}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
