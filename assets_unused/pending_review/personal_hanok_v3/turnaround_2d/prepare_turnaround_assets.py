from __future__ import annotations

import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage


ROOT = Path(__file__).resolve().parent
CELL_SIZE = (384, 512)
SHEET_SIZE = (1536, 1024)
SAFE_CONTENT_SIZE = (352, 448)
BASELINE_Y = 488

DIRECTIONS = (
    ("000", "front"),
    ("045", "front_right"),
    ("090", "right"),
    ("135", "rear_right"),
    ("180", "rear"),
    ("225", "rear_left"),
    ("270", "left"),
    ("315", "front_left"),
)

SUBJECTS = (
    ("ildu_sadang_v03", "ildu_sadang"),
    ("ildu_sadangmun_v02", "ildu_sadangmun"),
    ("ildu_sadang_hyeopmun_v01", "ildu_sadang_hyeopmun"),
)


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def _checker_background(rgb: np.ndarray) -> np.ndarray:
    """Find the baked light checker field connected to the sheet boundary.

    The generator's checker field is neutral and brighter than the illustrated
    stone/plaster. Only checker-like pixels connected to a tile edge are treated
    as background, so enclosed pale plaster remains part of the architecture.
    """

    low = rgb.min(axis=2)
    high = rgb.max(axis=2)
    chroma = high.astype(np.int16) - low.astype(np.int16)

    checker_candidate = (low >= 236) & (chroma <= 12)
    seeds = np.zeros(checker_candidate.shape, dtype=bool)
    seeds[0, :] = checker_candidate[0, :]
    seeds[-1, :] = checker_candidate[-1, :]
    seeds[:, 0] = checker_candidate[:, 0]
    seeds[:, -1] = checker_candidate[:, -1]
    return ndimage.binary_propagation(
        seeds,
        structure=np.ones((3, 3), dtype=bool),
        mask=checker_candidate,
    )


def _rgba_for_mask(rgb: np.ndarray, foreground: np.ndarray) -> Image.Image:
    distance_inside = ndimage.distance_transform_edt(foreground)
    alpha = np.where(
        foreground,
        np.clip(distance_inside / 1.5, 0.0, 1.0) * 255.0,
        0.0,
    ).astype(np.uint8)

    # Replace only the semi-transparent silhouette fringe with the nearest
    # two-pixel-deep foreground color. This prevents a pale checker halo while
    # retaining genuine light stone and white tile-end details.
    core = distance_inside >= 2.0
    if core.any():
        _, nearest = ndimage.distance_transform_edt(~core, return_indices=True)
        fringe = foreground & (alpha < 255)
        nearest_rgb = rgb[nearest[0], nearest[1]]
        rgb = rgb.copy()
        rgb[fringe] = nearest_rgb[fringe]

    rgba = np.dstack((rgb, alpha))
    return Image.fromarray(rgba)


def _ordered_component_masks(rgb: np.ndarray) -> list[np.ndarray]:
    foreground = ~_checker_background(rgb)
    labels, count = ndimage.label(
        foreground,
        structure=np.ones((3, 3), dtype=bool),
    )
    if count < 8:
        raise ValueError(f"Expected at least 8 foreground components, got {count}")

    sizes = np.bincount(labels.ravel())
    candidates: list[tuple[int, float, float, int]] = []
    for label_id in range(1, count + 1):
        area = int(sizes[label_id])
        if area < 5_000:
            continue
        center_y, center_x = ndimage.center_of_mass(
            foreground,
            labels,
            label_id,
        )
        candidates.append((label_id, float(center_y), float(center_x), area))

    if len(candidates) != 8:
        summary = ", ".join(str(item[3]) for item in sorted(candidates))
        raise ValueError(
            f"Expected exactly 8 building components, got {len(candidates)} "
            f"(areas: {summary})"
        )

    top = sorted((item for item in candidates if item[1] < 512), key=lambda item: item[2])
    bottom = sorted((item for item in candidates if item[1] >= 512), key=lambda item: item[2])
    if len(top) != 4 or len(bottom) != 4:
        by_vertical_position = sorted(candidates, key=lambda item: item[1])
        top = sorted(by_vertical_position[:4], key=lambda item: item[2])
        bottom = sorted(by_vertical_position[4:], key=lambda item: item[2])
    return [labels == item[0] for item in top + bottom]


def _largest_component_mask(image: Image.Image) -> tuple[np.ndarray, np.ndarray]:
    rgb = np.asarray(image.convert("RGB"), dtype=np.uint8)
    if "A" in image.getbands() and image.getchannel("A").getextrema()[0] == 0:
        foreground = np.asarray(image.getchannel("A"), dtype=np.uint8) > 0
    else:
        foreground = ~_checker_background(rgb)

    labels, count = ndimage.label(
        foreground,
        structure=np.ones((3, 3), dtype=bool),
    )
    if count == 0:
        raise ValueError("No foreground component was found")
    sizes = np.bincount(labels.ravel())
    sizes[0] = 0
    largest_label = int(sizes.argmax())
    if int(sizes[largest_label]) < 5_000:
        raise ValueError("Largest foreground component is unexpectedly small")
    return rgb, labels == largest_label


def _crop_component(rgb: np.ndarray, mask: np.ndarray) -> Image.Image:
    y_values, x_values = np.nonzero(mask)
    if not len(x_values):
        raise ValueError("Foreground component is empty")
    left = max(0, int(x_values.min()) - 3)
    right = min(rgb.shape[1], int(x_values.max()) + 4)
    top = max(0, int(y_values.min()) - 3)
    bottom = min(rgb.shape[0], int(y_values.max()) + 4)
    return _rgba_for_mask(rgb, mask).crop((left, top, right, bottom))


def _resize_premultiplied(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    if image.size == size:
        return image
    return image.convert("RGBa").resize(size, Image.Resampling.LANCZOS).convert("RGBA")


def _content_bbox(image: Image.Image) -> list[int]:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise ValueError("Output tile is fully transparent")
    return list(bbox)


def process_subject(directory_name: str, file_prefix: str) -> dict[str, object]:
    subject_root = ROOT / directory_name
    output_dir = subject_root / "transparent_views"
    sheet_path = subject_root / f"{file_prefix}_turnaround_sheet.png"
    output_dir.mkdir(parents=True, exist_ok=True)

    individual_paths = [
        subject_root
        / "generated_source"
        / "individual"
        / f"{file_prefix}_{degrees}_{direction}_raw.png"
        for degrees, direction in DIRECTIONS
    ]
    use_individual_sources = all(path.is_file() for path in individual_paths)
    raw_source_records: list[dict[str, object]] = []
    if use_individual_sources:
        component_images: list[Image.Image] = []
        for raw_path in individual_paths:
            raw = Image.open(raw_path)
            rgb, component_mask = _largest_component_mask(raw)
            component_images.append(_crop_component(rgb, component_mask))
            raw_source_records.append(
                {
                    "file": raw_path.relative_to(subject_root).as_posix(),
                    "sha256": _sha256(raw_path),
                    "size": list(raw.size),
                    "mode": raw.mode,
                }
            )
        normalized_height = min(
            SAFE_CONTENT_SIZE[1],
            min(
                SAFE_CONTENT_SIZE[0] * image.height / image.width
                for image in component_images
            ),
        )
        scales = [normalized_height / image.height for image in component_images]
        normalization_mode = "equal_content_height_from_individual_high_resolution_sources"
    else:
        raw_path = subject_root / "generated_source" / f"{file_prefix}_turnaround_raw.png"
        raw = Image.open(raw_path)
        if raw.size != SHEET_SIZE:
            raise ValueError(f"{raw_path}: expected {SHEET_SIZE}, got {raw.size}")
        rgb = np.asarray(raw.convert("RGB"), dtype=np.uint8)
        component_masks = _ordered_component_masks(rgb)
        component_images = [_crop_component(rgb, mask) for mask in component_masks]
        maximum_width = max(image.width for image in component_images)
        maximum_height = max(image.height for image in component_images)
        uniform_scale = min(
            1.0,
            SAFE_CONTENT_SIZE[0] / maximum_width,
            SAFE_CONTENT_SIZE[1] / maximum_height,
        )
        scales = [uniform_scale] * len(component_images)
        normalization_mode = "single_uniform_scale_from_contact_sheet"
        raw_source_records.append(
            {
                "file": raw_path.relative_to(subject_root).as_posix(),
                "sha256": _sha256(raw_path),
                "size": list(raw.size),
                "mode": raw.mode,
            }
        )

    sheet = Image.new("RGBA", SHEET_SIZE, (0, 0, 0, 0))
    tiles: list[dict[str, object]] = []
    for index, (degrees, direction) in enumerate(DIRECTIONS):
        column = index % 4
        row = index // 4
        left = column * CELL_SIZE[0]
        top = row * CELL_SIZE[1]
        component = component_images[index]
        scale = scales[index]
        scaled_size = (
            max(1, round(component.width * scale)),
            max(1, round(component.height * scale)),
        )
        component = _resize_premultiplied(component, scaled_size)
        tile = Image.new("RGBA", CELL_SIZE, (0, 0, 0, 0))
        paste_x = (CELL_SIZE[0] - component.width) // 2
        paste_y = BASELINE_Y - component.height
        if paste_x < 0 or paste_y < 0:
            raise ValueError(
                f"{file_prefix} {degrees}: component {component.size} exceeds safe tile"
            )
        tile.alpha_composite(component, (paste_x, paste_y))
        output_path = output_dir / f"{file_prefix}_{degrees}_{direction}.png"
        tile.save(output_path, format="PNG", optimize=True)
        sheet.alpha_composite(tile, (left, top))

        alpha = np.asarray(tile.getchannel("A"), dtype=np.uint8)
        tiles.append(
            {
                "degrees": int(degrees),
                "direction": direction,
                "file": output_path.relative_to(subject_root).as_posix(),
                "size": list(tile.size),
                "mode": tile.mode,
                "alpha_extrema": [int(alpha.min()), int(alpha.max())],
                "nontransparent_pixels": int(np.count_nonzero(alpha)),
                "content_bbox": _content_bbox(tile),
                "sha256": _sha256(output_path),
                "source_scale": scale,
            }
        )

    sheet.save(sheet_path, format="PNG", optimize=True)
    references: list[dict[str, object]] = []
    for path in sorted((subject_root / "references").iterdir()):
        if not path.is_file():
            continue
        is_canonical_sprite = path.name.startswith("source_")
        is_model_input = is_canonical_sprite or path.name.startswith("imagegen_reference_")
        record: dict[str, object] = {
            "file": path.relative_to(subject_root).as_posix(),
            "sha256": _sha256(path),
            "role": "imagegen_reference" if is_model_input else "blueprint_evidence_only",
            "used_as_model_input": is_model_input,
        }
        if is_canonical_sprite:
            original_name = path.name.removeprefix("source_")
            candidates = (ROOT.parent / original_name, ROOT.parent / "qa" / original_name)
            canonical = next((candidate for candidate in candidates if candidate.is_file()), None)
            if canonical is None:
                raise FileNotFoundError(f"Canonical reference not found for {path}")
            record["canonical_file"] = canonical.relative_to(ROOT.parent).as_posix()
            record["canonical_sha256"] = _sha256(canonical)
            record["exact_copy"] = record["sha256"] == record["canonical_sha256"]
            if not record["exact_copy"]:
                raise ValueError(f"Reference copy differs from canonical source: {path}")
        references.append(record)

    return {
        "subject": file_prefix,
        "status": "pending_review_only",
        "camera_elevation_degrees": 28,
        "azimuth_interval_degrees": 45,
        "raw_sources": raw_source_records,
        "raw_source_note": "Image generator returned an RGB audit source with a baked preview background; it is not a runtime-ready deliverable.",
        "sheet": sheet_path.relative_to(subject_root).as_posix(),
        "sheet_size": list(sheet.size),
        "sheet_mode": sheet.mode,
        "sheet_sha256": _sha256(sheet_path),
        "normalization_mode": normalization_mode,
        "safe_content_size": list(SAFE_CONTENT_SIZE),
        "baseline_y": BASELINE_Y,
        "references": references,
        "tiles": tiles,
    }


def main() -> None:
    for directory_name, file_prefix in SUBJECTS:
        metrics = process_subject(directory_name, file_prefix)
        metrics_path = ROOT / directory_name / "qa_metrics.json"
        metrics_path.write_text(
            json.dumps(metrics, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(
            f"{file_prefix}: 8 RGBA tiles at 384x512; "
            f"sheet={metrics['sheet_sha256']}"
        )


if __name__ == "__main__":
    main()
