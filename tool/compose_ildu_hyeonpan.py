#!/usr/bin/env python3
"""Compose exact Sarangchae signboard sources into review-only overlays.

The supplied board and calligraphy PNGs are hash-pinned. Chroma removal,
calligraphy fitting, perspective placement, and PNG encoding are deterministic.
The V3 Sarangchae base is verified before and after composition and is never
opened for writing.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image

try:
    from tool.register_hanok_construction_stages import (
        alpha_bbox,
        resize_premultiplied,
    )
except ModuleNotFoundError:  # Allow direct execution from the repository root.
    from register_hanok_construction_stages import (
        alpha_bbox,
        resize_premultiplied,
    )


ROOT = Path(__file__).resolve().parents[1]
V3_ROOT = ROOT / "assets_unused" / "pending_review" / "personal_hanok_v3"
REVIEW_DIR = V3_ROOT / "sarangchae_construction_pilot_v3_variable"
CANVAS = (2512, 1680)
MASTER_SHA256 = "f2c01142f465b9353e0b9546a00f167891753039d9c910620d83cd924a077212"

EXPECTED_INPUT_HASHES = {
    "hyeonpan_calligraphy_baekse_cheongpung_v1.png":
        "19a774e1cf7d75e474d9bd83e251b64001ea0bfe655da4645461e38c2e9679c9",
    "hyeonpan_board_baekse_cheongpung_try01.png":
        "49365beadec3f5df359cf62220ea11071eae2425fa3080ad3f14eb7de7de9e3a",
    "hyeonpan_calligraphy_takcheongjae_v1.png":
        "9fe85b208531cd7c95c419c250004465d0101b88ccd72970ecef52a8139f983a",
    "hyeonpan_board_takcheongjae_try01.png":
        "86da5f8f1a88b8653ae4634a1d49a6332fee3ec4d3aa6ad8aa2c5ca57b09d144",
}

BOARD_SPECS = {
    "baekse-cheongpung": {
        "board": "hyeonpan_board_baekse_cheongpung_try01.png",
        "calligraphy": "hyeonpan_calligraphy_baekse_cheongpung_v1.png",
        "output": "hyeonpan_board_baekse_cheongpung_composed.png",
    },
    "takcheongjae": {
        "board": "hyeonpan_board_takcheongjae_try01.png",
        "calligraphy": "hyeonpan_calligraphy_takcheongjae_v1.png",
        "output": "hyeonpan_board_takcheongjae_composed.png",
    },
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify_inputs() -> dict[str, str]:
    verified: dict[str, str] = {}
    for filename, expected in EXPECTED_INPUT_HASHES.items():
        path = V3_ROOT / filename
        if not path.is_file():
            raise ValueError(f"missing pinned hyeonpan input: {path}")
        actual = sha256(path)
        if actual != expected:
            raise ValueError(
                f"pinned hyeonpan input changed: {filename}; "
                f"expected {expected}, got {actual}"
            )
        verified[filename] = actual
    return verified


def remove_green_chroma(rgba: np.ndarray) -> np.ndarray:
    if rgba.ndim != 3 or rgba.shape[2] != 4:
        raise ValueError("remove_green_chroma expects an RGBA array")
    rgb = rgba[:, :, :3].astype(np.int16)
    green = (
        (rgb[:, :, 1] >= 180)
        & (rgb[:, :, 1] - rgb[:, :, 0] >= 70)
        & (rgb[:, :, 1] - rgb[:, :, 2] >= 70)
    )
    result = rgba.copy()
    result[green] = 0
    return result


def load_calligraphy(path: Path) -> np.ndarray:
    expected = EXPECTED_INPUT_HASHES.get(path.name)
    if expected is None or sha256(path) != expected:
        raise ValueError(f"calligraphy input is not hash-pinned: {path}")
    with Image.open(path) as opened:
        return np.asarray(opened.convert("RGBA"), dtype=np.uint8).copy()


def alpha_mask_hash(rgba: np.ndarray) -> str:
    return hashlib.sha256(rgba[:, :, 3].tobytes()).hexdigest()


def _load_board(path: Path) -> Image.Image:
    expected = EXPECTED_INPUT_HASHES.get(path.name)
    if expected is None or sha256(path) != expected:
        raise ValueError(f"board input is not hash-pinned: {path}")
    with Image.open(path) as opened:
        rgba = np.asarray(opened.convert("RGBA"), dtype=np.uint8)
    cleaned = Image.fromarray(remove_green_chroma(rgba))
    bbox = alpha_bbox(cleaned)
    return cleaned.crop(bbox)


def _fit_inside(
    image: Image.Image,
    *,
    max_width: int,
    max_height: int,
) -> Image.Image:
    scale = min(max_width / image.width, max_height / image.height)
    if scale <= 0:
        raise ValueError("invalid calligraphy fit rectangle")
    return resize_premultiplied(
        image,
        (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
    )


def compose_board(board_path: Path, calligraphy_path: Path) -> tuple[Image.Image, str]:
    board = _load_board(board_path)
    calligraphy_rgba = load_calligraphy(calligraphy_path)
    mask_hash = alpha_mask_hash(calligraphy_rgba)
    calligraphy = Image.fromarray(calligraphy_rgba)
    calligraphy = calligraphy.crop(alpha_bbox(calligraphy))

    inset_x = round(board.width * 0.08)
    inset_y = round(board.height * 0.18)
    inner_width = board.width - 2 * inset_x
    inner_height = board.height - 2 * inset_y
    fitted = _fit_inside(
        calligraphy,
        max_width=inner_width,
        max_height=inner_height,
    )
    offset = (
        inset_x + (inner_width - fitted.width) // 2,
        inset_y + (inner_height - fitted.height) // 2,
    )
    result = board.copy()
    result.alpha_composite(fitted, offset)
    return result, mask_hash


def _perspective_coefficients(
    destination: list[tuple[float, float]],
    source: list[tuple[float, float]],
) -> tuple[float, ...]:
    matrix: list[list[float]] = []
    values: list[float] = []
    for (x, y), (u, v) in zip(destination, source, strict=True):
        matrix.append([x, y, 1.0, 0.0, 0.0, 0.0, -u * x, -u * y])
        values.append(u)
        matrix.append([0.0, 0.0, 0.0, x, y, 1.0, -v * x, -v * y])
        values.append(v)
    solved = np.linalg.solve(
        np.asarray(matrix, dtype=np.float64),
        np.asarray(values, dtype=np.float64),
    )
    return tuple(float(value) for value in solved)


def project_to_quad(
    source: Image.Image,
    quad: list[list[int]],
    *,
    canvas_size: tuple[int, int] = CANVAS,
) -> Image.Image:
    if len(quad) != 4 or any(len(point) != 2 for point in quad):
        raise ValueError("quad must contain four [x, y] points")
    points = [(float(x), float(y)) for x, y in quad]
    left = math.floor(min(point[0] for point in points))
    top = math.floor(min(point[1] for point in points))
    right = math.ceil(max(point[0] for point in points)) + 1
    bottom = math.ceil(max(point[1] for point in points)) + 1
    if left < 0 or top < 0 or right > canvas_size[0] or bottom > canvas_size[1]:
        raise ValueError(f"hyeonpan quad exceeds canvas: {quad}")

    local = [(x - left, y - top) for x, y in points]
    source_points = [
        (0.0, 0.0),
        (float(source.width - 1), 0.0),
        (float(source.width - 1), float(source.height - 1)),
        (0.0, float(source.height - 1)),
    ]
    coefficients = _perspective_coefficients(local, source_points)
    projected = source.transform(
        (right - left, bottom - top),
        Image.Transform.PERSPECTIVE,
        coefficients,
        resample=Image.Resampling.BICUBIC,
        fillcolor=(0, 0, 0, 0),
    )
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    canvas.alpha_composite(projected, (left, top))
    return canvas


def _validate_layout(layout: dict[str, object]) -> None:
    if layout.get("schemaVersion") != 1:
        raise ValueError("unsupported hyeonpan layout schema")
    if layout.get("canvas") != list(CANVAS):
        raise ValueError(f"hyeonpan layout canvas must be {list(CANVAS)}")
    for mode in ("work", "installed"):
        placement = layout.get(mode)
        if not isinstance(placement, dict) or set(placement) != set(BOARD_SPECS):
            raise ValueError(f"layout {mode} must place both exact signboards")


def compose(layout: dict[str, object], output_dir: Path) -> dict[str, object]:
    _validate_layout(layout)
    verified = verify_inputs()
    base = REVIEW_DIR / "stage_12_complete_v3_base.png"
    if sha256(base) != MASTER_SHA256:
        raise ValueError("V3 Sarangchae base hash changed before composition")

    output_dir.mkdir(parents=True, exist_ok=True)
    boards: dict[str, Image.Image] = {}
    board_rows: dict[str, object] = {}
    for board_id, spec in BOARD_SPECS.items():
        board, mask_hash = compose_board(
            V3_ROOT / spec["board"],
            V3_ROOT / spec["calligraphy"],
        )
        board_path = output_dir / spec["output"]
        board.save(board_path, format="PNG", optimize=True)
        boards[board_id] = board
        board_rows[board_id] = {
            "boardSource": spec["board"],
            "calligraphySource": spec["calligraphy"],
            "calligraphyAlphaMaskSha256": mask_hash,
            "composedBoard": spec["output"],
            "composedBoardSha256": sha256(board_path),
            "composedBoardSize": list(board.size),
        }

    overlay_names = {
        "work": "stage_11_hyeonpan_work.png",
        "installed": "stage_12_hyeonpan_installed.png",
    }
    overlay_rows: dict[str, object] = {}
    for mode, filename in overlay_names.items():
        overlay = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
        placements = layout[mode]
        for board_id in BOARD_SPECS:
            projected = project_to_quad(boards[board_id], placements[board_id])
            overlay.alpha_composite(projected)
        path = output_dir / filename
        overlay.save(path, format="PNG", optimize=True)
        overlay_rows[filename] = {
            "mode": mode,
            "sha256": sha256(path),
            "size": list(overlay.size),
            "alphaBbox": list(alpha_bbox(overlay)),
        }

    if sha256(base) != MASTER_SHA256:
        raise ValueError("V3 Sarangchae base changed during composition")
    return {
        "schemaVersion": 1,
        "status": "pending_review",
        "inputs": verified,
        "masterSha256": MASTER_SHA256,
        "boards": board_rows,
        "overlays": overlay_rows,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--layout",
        type=Path,
        default=REVIEW_DIR / "hyeonpan_layout_v1.json",
    )
    parser.add_argument("--output-dir", type=Path, default=REVIEW_DIR)
    args = parser.parse_args()
    layout = json.loads(args.layout.read_text(encoding="utf-8"))
    report = compose(layout, args.output_dir)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
