from __future__ import annotations

import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage


ROOT = Path(__file__).resolve().parent
EXPECTED_DIRECTIONS = (
    "000_front",
    "045_front_right",
    "090_right",
    "135_rear_right",
    "180_rear",
    "225_rear_left",
    "270_left",
    "315_front_left",
)
SUBJECTS = (
    ("ildu_sadang_v03", "ildu_sadang"),
    ("ildu_sadangmun_v02", "ildu_sadangmun"),
    ("ildu_sadang_hyeopmun_v01", "ildu_sadang_hyeopmun"),
)


def _sha256(path: Path) -> str:
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    return digest.upper()


def _assert_tile(path: Path) -> tuple[str, Image.Image]:
    image = Image.open(path)
    assert image.size == (384, 512), f"{path}: wrong size {image.size}"
    assert image.mode == "RGBA", f"{path}: wrong mode {image.mode}"
    alpha = np.asarray(image.getchannel("A"), dtype=np.uint8)
    assert int(alpha.min()) == 0 and int(alpha.max()) == 255, f"{path}: invalid alpha extrema"
    assert not alpha[0, 0] and not alpha[0, -1] and not alpha[-1, 0] and not alpha[-1, -1], (
        f"{path}: a corner is not transparent"
    )
    bbox = image.getchannel("A").getbbox()
    assert bbox is not None, f"{path}: empty image"
    left, top, right, bottom = bbox
    assert left >= 12 and 384 - right >= 12, f"{path}: insufficient horizontal padding {bbox}"
    assert top >= 12 and 512 - bottom >= 20, f"{path}: insufficient vertical padding {bbox}"
    labels, component_count = ndimage.label(alpha > 0, structure=np.ones((3, 3), dtype=bool))
    component_areas = np.bincount(labels.ravel())[1:]
    substantial_areas = component_areas[component_areas >= 16]
    assert len(substantial_areas), f"{path}: no substantial alpha component"
    dominant_ratio = float(substantial_areas.max() / substantial_areas.sum())
    assert dominant_ratio >= 0.99, (
        f"{path}: dominant foreground is only {dominant_ratio:.3%}; possible background residue"
    )

    rgba = np.asarray(image, dtype=np.uint8)
    opaque = rgba[:, :, 3] >= 128
    green_screen = opaque & (rgba[:, :, 1] >= 220) & (rgba[:, :, 0] <= 40) & (rgba[:, :, 2] <= 40)
    assert not np.any(green_screen), f"{path}: green-screen residue detected"
    return _sha256(path), image


def validate_subject(directory_name: str, prefix: str) -> None:
    subject_root = ROOT / directory_name
    metrics_path = subject_root / "qa_metrics.json"
    metrics = json.loads(metrics_path.read_text(encoding="utf-8"))
    assert metrics["status"] == "pending_review_only"
    assert metrics["camera_elevation_degrees"] == 28
    assert metrics["azimuth_interval_degrees"] == 45
    assert all(reference.get("exact_copy", True) for reference in metrics["references"])
    assert all(not item["used_as_model_input"] for item in metrics["references"] if item["role"] == "blueprint_evidence_only")

    expected_paths = [
        subject_root / "transparent_views" / f"{prefix}_{direction}.png"
        for direction in EXPECTED_DIRECTIONS
    ]
    actual_paths = sorted((subject_root / "transparent_views").glob("*.png"))
    assert set(actual_paths) == set(expected_paths), (
        f"{prefix}: expected exactly eight named direction files, got {len(actual_paths)}"
    )

    hashes: list[str] = []
    tiles: list[Image.Image] = []
    for path in expected_paths:
        digest, image = _assert_tile(path)
        hashes.append(digest)
        tiles.append(image)
    assert len(set(hashes)) == 8, f"{prefix}: duplicate direction files"

    sheet_path = subject_root / f"{prefix}_turnaround_sheet.png"
    sheet = Image.open(sheet_path)
    assert sheet.size == (1536, 1024) and sheet.mode == "RGBA"
    reconstructed = Image.new("RGBA", sheet.size, (0, 0, 0, 0))
    for index, tile in enumerate(tiles):
        reconstructed.alpha_composite(tile, ((index % 4) * 384, (index // 4) * 512))
    assert np.array_equal(np.asarray(sheet), np.asarray(reconstructed)), (
        f"{prefix}: review sheet does not exactly match the eight tiles"
    )
    print(f"PASS {prefix}: 8 distinct 384x512 RGBA directions + exact 1536x1024 sheet")


def main() -> None:
    for directory_name, prefix in SUBJECTS:
        validate_subject(directory_name, prefix)
    print("PASS all: 24 transparent direction PNGs verified")


if __name__ == "__main__":
    main()
