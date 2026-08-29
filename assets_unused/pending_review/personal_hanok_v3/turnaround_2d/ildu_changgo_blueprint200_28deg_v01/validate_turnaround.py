from __future__ import annotations

import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage


ROOT = Path(__file__).resolve().parent
TRANSPARENT = ROOT / "transparent_28deg"
EXPECTED_FILES = (
    "00_front_000.png",
    "01_front_right_045.png",
    "02_right_090.png",
    "03_rear_right_135.png",
    "04_rear_180.png",
    "05_rear_left_225.png",
    "06_left_270.png",
    "07_front_left_315.png",
)
FRAME_SIZE = (2048, 1536)
SHEET_CELL_SIZE = (1024, 768)
SHEET_SIZE = (4096, 1536)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def resize_premultiplied(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    return (
        image.convert("RGBa")
        .resize(size, Image.Resampling.LANCZOS)
        .convert("RGBA")
    )


def validate_frame(path: Path) -> tuple[str, Image.Image]:
    image = Image.open(path)
    assert image.mode == "RGBA", f"{path}: expected RGBA, got {image.mode}"
    assert image.size == FRAME_SIZE, f"{path}: expected {FRAME_SIZE}, got {image.size}"
    alpha = np.asarray(image.getchannel("A"), dtype=np.uint8)
    assert int(alpha.min()) == 0 and int(alpha.max()) == 255, (
        f"{path}: alpha extrema are {int(alpha.min())}, {int(alpha.max())}"
    )
    assert not alpha[0, 0] and not alpha[0, -1] and not alpha[-1, 0] and not alpha[-1, -1], (
        f"{path}: every corner must be transparent"
    )
    bbox = image.getchannel("A").getbbox()
    assert bbox is not None, f"{path}: empty alpha"
    left, top, right, bottom = bbox
    assert left >= 64 and FRAME_SIZE[0] - right >= 64, (
        f"{path}: insufficient horizontal safe margin {bbox}"
    )
    assert top >= 32 and FRAME_SIZE[1] - bottom >= 48, (
        f"{path}: insufficient vertical safe margin {bbox}"
    )

    labels, _ = ndimage.label(alpha > 0, structure=np.ones((3, 3), dtype=bool))
    sizes = np.bincount(labels.ravel())[1:]
    substantial = sizes[sizes >= 16]
    assert len(substantial), f"{path}: no substantial foreground"
    dominant_ratio = float(substantial.max() / substantial.sum())
    assert dominant_ratio >= 0.999, (
        f"{path}: foreground dominant ratio {dominant_ratio:.5%}"
    )

    rgba = np.asarray(image, dtype=np.uint8)
    opaque = rgba[:, :, 3] >= 128
    green = (
        opaque
        & (rgba[:, :, 1] >= 220)
        & (rgba[:, :, 0] <= 40)
        & (rgba[:, :, 2] <= 40)
    )
    assert not np.any(green), f"{path}: green-screen residue detected"
    return sha256(path), image


def main() -> None:
    metrics_path = ROOT / "qa_metrics.json"
    metrics = json.loads(metrics_path.read_text(encoding="utf-8"))
    assert metrics["status"] == "pending_review_only"
    assert metrics["camera_elevation_degrees"] == 28
    assert metrics["azimuth_interval_degrees"] == 45
    assert metrics["frame_size"] == list(FRAME_SIZE)
    assert len(metrics["blueprints"]) == 7
    assert all(not item["used_as_model_input"] for item in metrics["blueprints"])

    expected = [TRANSPARENT / filename for filename in EXPECTED_FILES]
    actual = sorted(TRANSPARENT.glob("*.png"))
    assert set(actual) == set(expected), (
        f"Expected exactly 8 named frames, got {len(actual)}"
    )

    hashes: list[str] = []
    frames: list[Image.Image] = []
    for path in expected:
        digest, image = validate_frame(path)
        hashes.append(digest)
        frames.append(image)
    assert len(set(hashes)) == 8, "Direction files are not all distinct"

    recorded = {Path(item["output_file"]).name: item for item in metrics["tiles"]}
    assert set(recorded) == set(EXPECTED_FILES)
    for filename, digest in zip(EXPECTED_FILES, hashes, strict=True):
        item = recorded[filename]
        assert item["output_sha256"] == digest
        assert item["green_screen_pixels"] == 0
        assert max(abs(value) for value in item["source_mean_rgb_delta"]) <= 20, (
            f"{filename}: palette mean drift exceeds 20 RGB levels"
        )

    sheet_path = ROOT / "ildu_changgo_8view_transparent_sheet.png"
    sheet = Image.open(sheet_path)
    assert sheet.mode == "RGBA" and sheet.size == SHEET_SIZE
    rebuilt = Image.new("RGBA", SHEET_SIZE, (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        rebuilt.alpha_composite(
            resize_premultiplied(frame, SHEET_CELL_SIZE),
            ((index % 4) * SHEET_CELL_SIZE[0], (index // 4) * SHEET_CELL_SIZE[1]),
        )
    assert np.array_equal(np.asarray(sheet), np.asarray(rebuilt)), (
        "Transparent review sheet does not exactly match the eight frames"
    )

    print(
        "PASS all: 8 distinct RGBA frames, alpha margins, palette gate, "
        "green-residue gate, and exact 4x2 sheet verified"
    )


if __name__ == "__main__":
    main()
