"""Extract the eight authored buildings from the 4x2 turnaround sheet."""

from __future__ import annotations

import argparse
from collections import deque
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter


DIRECTIONS = (
    "00_front",
    "01_front_right",
    "02_right",
    "03_rear_right",
    "04_rear",
    "05_rear_left",
    "06_left",
    "07_front_left",
)

FRAME_SIZE = (384, 512)
HORIZONTAL_PADDING = 8
BASELINE_Y = 472
ALPHA_THRESHOLD = 64
MIN_COMPONENT_PIXELS = 10_000

@dataclass(frozen=True)
class AlphaComponent:
    pixels: tuple[tuple[int, int], ...]
    bbox: tuple[int, int, int, int]


def find_building_components(sheet: Image.Image) -> list[AlphaComponent]:
    """Find the eight large, disconnected building silhouettes on the sheet."""

    alpha = sheet.getchannel("A")
    alpha_pixels = alpha.load()
    width, height = sheet.size
    visited = bytearray(width * height)
    components: list[AlphaComponent] = []

    for y in range(height):
        for x in range(width):
            offset = y * width + x
            if visited[offset] or alpha_pixels[x, y] <= ALPHA_THRESHOLD:
                continue
            visited[offset] = 1
            queue: deque[tuple[int, int]] = deque(((x, y),))
            pixels: list[tuple[int, int]] = []
            left = right = x
            top = bottom = y

            while queue:
                current_x, current_y = queue.popleft()
                pixels.append((current_x, current_y))
                left = min(left, current_x)
                right = max(right, current_x)
                top = min(top, current_y)
                bottom = max(bottom, current_y)
                for next_x, next_y in (
                    (current_x - 1, current_y),
                    (current_x + 1, current_y),
                    (current_x, current_y - 1),
                    (current_x, current_y + 1),
                ):
                    if not (0 <= next_x < width and 0 <= next_y < height):
                        continue
                    next_offset = next_y * width + next_x
                    if (
                        visited[next_offset]
                        or alpha_pixels[next_x, next_y] <= ALPHA_THRESHOLD
                    ):
                        continue
                    visited[next_offset] = 1
                    queue.append((next_x, next_y))

            if len(pixels) >= MIN_COMPONENT_PIXELS:
                components.append(
                    AlphaComponent(
                        pixels=tuple(pixels),
                        bbox=(left, top, right + 1, bottom + 1),
                    )
                )

    if len(components) != len(DIRECTIONS):
        raise ValueError(
            f"Expected {len(DIRECTIONS)} building silhouettes, found {len(components)}"
        )

    components.sort(
        key=lambda component: (
            0 if (component.bbox[1] + component.bbox[3]) / 2 < height / 2 else 1,
            (component.bbox[0] + component.bbox[2]) / 2,
        )
    )
    return components


def extract_component(sheet: Image.Image, component: AlphaComponent) -> Image.Image:
    """Keep the selected building plus its antialiased edge, excluding loose artifacts."""

    mask = Image.new("L", sheet.size, 0)
    mask_pixels = mask.load()
    for x, y in component.pixels:
        mask_pixels[x, y] = 255
    # One-pixel dilation restores the antialiased edge.
    mask = mask.filter(ImageFilter.MaxFilter(3))
    mask = ImageChops.multiply(sheet.getchannel("A"), mask)

    padded_bbox = (
        max(0, component.bbox[0] - 3),
        max(0, component.bbox[1] - 3),
        min(sheet.width, component.bbox[2] + 3),
        min(sheet.height, component.bbox[3] + 3),
    )
    sprite = sheet.crop(padded_bbox)
    sprite.putalpha(mask.crop(padded_bbox))
    return sprite


def split(input_path: Path, output_dir: Path) -> None:
    sheet = Image.open(input_path).convert("RGBA")
    components = find_building_components(sheet)
    sprites = [extract_component(sheet, component) for component in components]

    widest = max(sprite.width for sprite in sprites)
    tallest = max(sprite.height for sprite in sprites)
    scale = min(
        (FRAME_SIZE[0] - 2 * HORIZONTAL_PADDING) / widest,
        (BASELINE_Y - HORIZONTAL_PADDING) / tallest,
        1.0,
    )

    output_dir.mkdir(parents=True, exist_ok=True)
    frames: list[Image.Image] = []
    for direction, sprite in zip(DIRECTIONS, sprites, strict=True):
        target_size = (
            max(1, round(sprite.width * scale)),
            max(1, round(sprite.height * scale)),
        )
        sprite = sprite.resize(target_size, Image.Resampling.LANCZOS)
        frame = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
        frame.alpha_composite(
            sprite,
            (
                (FRAME_SIZE[0] - sprite.width) // 2,
                BASELINE_Y - sprite.height,
            ),
        )
        frames.append(frame)
        frame.save(
            output_dir / f"ildu_ansarangchae_{direction}.png",
            optimize=True,
        )

    clean_sheet = Image.new(
        "RGBA",
        (FRAME_SIZE[0] * 4, FRAME_SIZE[1] * 2),
        (0, 0, 0, 0),
    )
    for index, frame in enumerate(frames):
        clean_sheet.alpha_composite(
            frame,
            ((index % 4) * FRAME_SIZE[0], (index // 4) * FRAME_SIZE[1]),
        )
    clean_sheet.save(
        output_dir.parent
        / "ildu_ansarangchae_8view_high_elevated_sheet_v05_clean.png",
        optimize=True,
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()
    split(args.input, args.output_dir)


if __name__ == "__main__":
    main()
