from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage


ROOT = Path(__file__).resolve().parent
GENERATED = ROOT / "generated_28deg"
TRANSPARENT = ROOT / "transparent_28deg"
SOURCE = ROOT.parent.parent / "changgo_final.png"
BLUEPRINT_DIR = ROOT.parent.parent / "ildu_Blueprint"

FRAME_SIZE = (2048, 1536)
SAFE_CONTENT_SIZE = (1856, 1376)
BASELINE_Y = 1472
SHEET_CELL_SIZE = (1024, 768)
SHEET_SIZE = (4096, 1536)

DIRECTIONS = (
    ("00_front_000.png", 0, "front", "0° 정면"),
    ("01_front_right_045.png", 45, "front_right", "45° 정면-우측"),
    ("02_right_090.png", 90, "right", "90° 우측"),
    ("03_rear_right_135.png", 135, "rear_right", "135° 후면-우측"),
    ("04_rear_180.png", 180, "rear", "180° 후면"),
    ("05_rear_left_225.png", 225, "rear_left", "225° 후면-좌측"),
    ("06_left_270.png", 270, "left", "270° 좌측"),
    ("07_front_left_315.png", 315, "front_left", "315° 정면-좌측"),
)

SCALE_GROUPS = {
    "long_axis": (0, 4),
    "diagonal": (1, 3, 5, 7),
    "end_axis": (2, 6),
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def source_palette_mean() -> list[int]:
    rgba = np.asarray(Image.open(SOURCE).convert("RGBA"), dtype=np.uint8)
    visible = rgba[:, :, 3] >= 128
    green_residue = (
        visible
        & (rgba[:, :, 1].astype(np.int16) - rgba[:, :, 0].astype(np.int16) > 55)
        & (rgba[:, :, 1].astype(np.int16) - rgba[:, :, 2].astype(np.int16) > 55)
        & (rgba[:, :, 1] > 90)
    )
    pixels = rgba[:, :, :3][visible & ~green_residue]
    return np.rint(pixels.mean(axis=0)).astype(int).tolist()


def connected_checker_background(rgb: np.ndarray) -> np.ndarray:
    """Return neutral checker pixels connected to the outer canvas.

    This follows the successful current 2.5D turnaround workflow: only a
    bright, low-chroma field reachable from the image boundary is background.
    Enclosed pale roof ends, plaster, and stone therefore remain architecture.
    """

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


def dominant_foreground(rgb: np.ndarray) -> tuple[np.ndarray, dict[str, object]]:
    foreground = ~connected_checker_background(rgb)
    labels, count = ndimage.label(
        foreground,
        structure=np.ones((3, 3), dtype=bool),
    )
    if count == 0:
        raise ValueError("No foreground component found")
    sizes = np.bincount(labels.ravel())
    largest_label = 1 + int(np.argmax(sizes[1:]))
    dominant = labels == largest_label
    component_sizes = sizes[1:]
    substantial = component_sizes[component_sizes >= 16]
    dominant_ratio = float(substantial.max() / substantial.sum())
    if dominant_ratio < 0.99:
        raise ValueError(
            f"Dominant foreground ratio {dominant_ratio:.4%} is below 99%"
        )
    return dominant, {
        "component_count": int(count),
        "substantial_component_count": int(len(substantial)),
        "dominant_ratio": dominant_ratio,
    }


def rgba_from_rgb(path: Path) -> tuple[Image.Image, dict[str, object]]:
    raw = Image.open(path)
    rgb = np.asarray(raw.convert("RGB"), dtype=np.uint8)
    foreground, component_metrics = dominant_foreground(rgb)
    distance_inside = ndimage.distance_transform_edt(foreground)
    alpha = np.where(
        foreground,
        np.clip(distance_inside / 1.5, 0.0, 1.0) * 255.0,
        0.0,
    ).astype(np.uint8)

    # Replace only the semi-transparent matte fringe with the nearest
    # two-pixel-deep building color. Opaque architecture pixels are untouched.
    core = distance_inside >= 2.0
    fringe_changed_pixels = 0
    clean_rgb = rgb.copy()
    if core.any():
        _, nearest = ndimage.distance_transform_edt(~core, return_indices=True)
        fringe = foreground & (alpha < 255)
        fringe_changed_pixels = int(np.count_nonzero(fringe))
        nearest_rgb = rgb[nearest[0], nearest[1]]
        clean_rgb[fringe] = nearest_rgb[fringe]

    rgba = Image.fromarray(np.dstack((clean_rgb, alpha)))
    bbox = rgba.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError(f"{path}: extracted image is empty")
    opaque_pixels = rgb[alpha >= 128]
    metrics: dict[str, object] = {
        "raw_file": path.relative_to(ROOT).as_posix(),
        "raw_sha256": sha256(path),
        "raw_mode": raw.mode,
        "raw_size": list(raw.size),
        "native_content_bbox": list(bbox),
        "native_visible_pixels": int(np.count_nonzero(alpha)),
        "native_transparent_pixels": int(np.count_nonzero(alpha == 0)),
        "native_partial_alpha_pixels": int(
            np.count_nonzero((alpha > 0) & (alpha < 255))
        ),
        "fringe_rgb_changed_pixels": fringe_changed_pixels,
        "building_mean_rgb": np.rint(opaque_pixels.mean(axis=0))
        .astype(int)
        .tolist(),
        **component_metrics,
    }
    return rgba, metrics


def crop_alpha(image: Image.Image, padding: int = 4) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("Cannot crop an empty alpha image")
    left, top, right, bottom = bbox
    return image.crop(
        (
            max(0, left - padding),
            max(0, top - padding),
            min(image.width, right + padding),
            min(image.height, bottom + padding),
        )
    )


def resize_premultiplied(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    if image.size == size:
        return image
    return (
        image.convert("RGBa")
        .resize(size, Image.Resampling.LANCZOS)
        .convert("RGBA")
    )


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = (
        Path("C:/Windows/Fonts/malgunbd.ttf" if bold else "C:/Windows/Fonts/malgun.ttf"),
        Path("C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf"),
    )
    for candidate in candidates:
        if candidate.is_file():
            return ImageFont.truetype(str(candidate), size=size)
    return ImageFont.load_default()


def build_sheets(frames: list[Image.Image]) -> tuple[Path, Path]:
    transparent_path = ROOT / "ildu_changgo_8view_transparent_sheet.png"
    review_path = ROOT / "ildu_changgo_8view_review_sheet.png"
    transparent_sheet = Image.new("RGBA", SHEET_SIZE, (0, 0, 0, 0))
    review_sheet = Image.new("RGBA", SHEET_SIZE, (224, 221, 214, 255))
    draw = ImageDraw.Draw(review_sheet)
    label_font = font(30, bold=True)
    note_font = font(22)

    for index, (frame, (_, degrees, _, label)) in enumerate(
        zip(frames, DIRECTIONS, strict=True)
    ):
        column = index % 4
        row = index // 4
        origin = (column * SHEET_CELL_SIZE[0], row * SHEET_CELL_SIZE[1])
        reduced = resize_premultiplied(frame, SHEET_CELL_SIZE)
        transparent_sheet.alpha_composite(reduced, origin)
        review_sheet.alpha_composite(reduced, origin)
        draw.rounded_rectangle(
            (
                origin[0] + 18,
                origin[1] + 18,
                origin[0] + 332,
                origin[1] + 92,
            ),
            radius=14,
            fill=(244, 241, 234, 226),
            outline=(131, 121, 109, 255),
            width=2,
        )
        draw.text(
            (origin[0] + 38, origin[1] + 28),
            label,
            font=label_font,
            fill=(41, 36, 31, 255),
        )
        draw.text(
            (origin[0] + 40, origin[1] + 64),
            f"yaw {degrees:03d}° · elevation 28°",
            font=note_font,
            fill=(78, 70, 62, 255),
        )

    transparent_sheet.save(transparent_path, format="PNG", optimize=True)
    review_sheet.save(review_path, format="PNG", optimize=True)
    return transparent_path, review_path


def main() -> None:
    if not SOURCE.is_file():
        raise FileNotFoundError(SOURCE)
    blueprint_paths = sorted(BLUEPRINT_DIR.glob("*창고*.jpg"))
    if len(blueprint_paths) != 7:
        raise ValueError(f"Expected exactly 7 warehouse blueprints, got {len(blueprint_paths)}")

    TRANSPARENT.mkdir(parents=True, exist_ok=True)
    extracted: list[Image.Image] = []
    crops: list[Image.Image] = []
    tile_metrics: list[dict[str, object]] = []
    for filename, degrees, direction, _ in DIRECTIONS:
        raw_path = GENERATED / filename
        if not raw_path.is_file():
            raise FileNotFoundError(raw_path)
        rgba, metrics = rgba_from_rgb(raw_path)
        extracted.append(rgba)
        crops.append(crop_alpha(rgba))
        metrics.update({"degrees": degrees, "direction": direction})
        tile_metrics.append(metrics)

    diagonals = [math.hypot(image.width, image.height) for image in crops]
    correction_factors = [1.0] * len(crops)
    group_targets: dict[str, float] = {}
    for group_name, indices in SCALE_GROUPS.items():
        target = float(np.median([diagonals[index] for index in indices]))
        group_targets[group_name] = target
        for index in indices:
            correction_factors[index] = target / diagonals[index]

    corrected_widths = [
        crop.width * correction_factors[index] for index, crop in enumerate(crops)
    ]
    corrected_heights = [
        crop.height * correction_factors[index] for index, crop in enumerate(crops)
    ]
    global_scale = min(
        SAFE_CONTENT_SIZE[0] / max(corrected_widths),
        SAFE_CONTENT_SIZE[1] / max(corrected_heights),
    )

    source_mean = source_palette_mean()
    frames: list[Image.Image] = []
    for index, ((filename, _, _, _), crop, metrics) in enumerate(
        zip(DIRECTIONS, crops, tile_metrics, strict=True)
    ):
        scale = correction_factors[index] * global_scale
        target_size = (
            max(1, round(crop.width * scale)),
            max(1, round(crop.height * scale)),
        )
        sprite = resize_premultiplied(crop, target_size)
        frame = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
        paste_x = (FRAME_SIZE[0] - sprite.width) // 2
        paste_y = BASELINE_Y - sprite.height
        if paste_x < 0 or paste_y < 0:
            raise ValueError(f"{filename}: normalized sprite {sprite.size} does not fit")
        frame.alpha_composite(sprite, (paste_x, paste_y))
        output_path = TRANSPARENT / filename
        frame.save(output_path, format="PNG", optimize=True)
        frames.append(frame)

        rgba = np.asarray(frame, dtype=np.uint8)
        alpha = rgba[:, :, 3]
        opaque = alpha >= 128
        mean_rgb = np.rint(rgba[:, :, :3][opaque].mean(axis=0)).astype(int)
        green = (
            opaque
            & (rgba[:, :, 1] >= 220)
            & (rgba[:, :, 0] <= 40)
            & (rgba[:, :, 2] <= 40)
        )
        metrics.update(
            {
                "output_file": output_path.relative_to(ROOT).as_posix(),
                "output_sha256": sha256(output_path),
                "output_mode": frame.mode,
                "output_size": list(frame.size),
                "content_bbox": list(frame.getchannel("A").getbbox() or ()),
                "alpha_extrema": list(frame.getchannel("A").getextrema()),
                "transparent_pixels": int(np.count_nonzero(alpha == 0)),
                "partial_alpha_pixels": int(
                    np.count_nonzero((alpha > 0) & (alpha < 255))
                ),
                "opaque_pixels": int(np.count_nonzero(alpha == 255)),
                "green_screen_pixels": int(np.count_nonzero(green)),
                "scale_correction_factor": correction_factors[index],
                "global_scale": global_scale,
                "final_scale": scale,
                "output_mean_rgb": mean_rgb.tolist(),
                "source_mean_rgb_delta": [
                    int(mean_rgb[channel] - source_mean[channel])
                    for channel in range(3)
                ],
            }
        )

    transparent_sheet, review_sheet = build_sheets(frames)
    metrics = {
        "status": "pending_review_only",
        "generator": "built_in_imagegen_one_call_per_direction",
        "postprocess": "boundary_connected_checker_extraction_and_premultiplied_normalization",
        "camera_elevation_degrees": 28,
        "azimuth_interval_degrees": 45,
        "frame_size": list(FRAME_SIZE),
        "safe_content_size": list(SAFE_CONTENT_SIZE),
        "baseline_y": BASELINE_Y,
        "source": {
            "file": SOURCE.relative_to(ROOT.parent.parent).as_posix(),
            "sha256": sha256(SOURCE),
            "mode": Image.open(SOURCE).mode,
            "size": list(Image.open(SOURCE).size),
            "palette_mean_rgb_without_green_residue": source_mean,
        },
        "blueprints": [
            {
                "file": path.relative_to(ROOT.parent.parent).as_posix(),
                "sha256": sha256(path),
                "role": "blueprint_evidence_only",
                "used_as_model_input": False,
            }
            for path in blueprint_paths
        ],
        "scale_groups": SCALE_GROUPS,
        "group_target_diagonals": group_targets,
        "global_scale": global_scale,
        "transparent_sheet": {
            "file": transparent_sheet.relative_to(ROOT).as_posix(),
            "sha256": sha256(transparent_sheet),
            "size": list(Image.open(transparent_sheet).size),
            "mode": Image.open(transparent_sheet).mode,
        },
        "review_sheet": {
            "file": review_sheet.relative_to(ROOT).as_posix(),
            "sha256": sha256(review_sheet),
            "size": list(Image.open(review_sheet).size),
            "mode": Image.open(review_sheet).mode,
        },
        "tiles": tile_metrics,
    }
    metrics_path = ROOT / "qa_metrics.json"
    metrics_path.write_text(
        json.dumps(metrics, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        "PASS build: 8 RGBA 2048x1536 frames, common baseline, "
        f"transparent sheet={sha256(transparent_sheet)}"
    )


if __name__ == "__main__":
    main()
