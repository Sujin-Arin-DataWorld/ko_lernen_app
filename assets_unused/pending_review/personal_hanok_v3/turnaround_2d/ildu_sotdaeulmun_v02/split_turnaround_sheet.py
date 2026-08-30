"""Split the authored 4x2 turnaround sheet into eight equal RGBA frames."""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image


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


def keep_largest_alpha_component(frame: Image.Image) -> Image.Image:
    """Remove neighboring-cell flecks while preserving the authored sprite."""

    alpha = frame.getchannel("A")
    pixels = alpha.load()
    width, height = frame.size
    visited = bytearray(width * height)
    largest: list[tuple[int, int]] = []

    for y in range(height):
        for x in range(width):
            offset = y * width + x
            if visited[offset] or pixels[x, y] <= 64:
                continue
            visited[offset] = 1
            queue: deque[tuple[int, int]] = deque(((x, y),))
            component: list[tuple[int, int]] = []
            while queue:
                current_x, current_y = queue.popleft()
                component.append((current_x, current_y))
                for next_x, next_y in (
                    (current_x - 1, current_y),
                    (current_x + 1, current_y),
                    (current_x, current_y - 1),
                    (current_x, current_y + 1),
                ):
                    if not (0 <= next_x < width and 0 <= next_y < height):
                        continue
                    next_offset = next_y * width + next_x
                    if visited[next_offset] or pixels[next_x, next_y] <= 64:
                        continue
                    visited[next_offset] = 1
                    queue.append((next_x, next_y))
            if len(component) > len(largest):
                largest = component

    left = max(0, min(x for x, _ in largest) - 2)
    top = max(0, min(y for _, y in largest) - 2)
    right = min(width, max(x for x, _ in largest) + 3)
    bottom = min(height, max(y for _, y in largest) + 3)
    cleaned_alpha = Image.new("L", frame.size, 0)
    cleaned_pixels = cleaned_alpha.load()
    for y in range(top, bottom):
        for x in range(left, right):
            cleaned_pixels[x, y] = pixels[x, y]
    cleaned = frame.copy()
    cleaned.putalpha(cleaned_alpha)
    return cleaned


def split(input_path: Path, output_dir: Path) -> None:
    sheet = Image.open(input_path).convert("RGBA")
    width, height = sheet.size
    x_edges = [round(index * width / 4) for index in range(5)]
    y_edges = [round(index * height / 2) for index in range(3)]
    cell_width = max(x_edges[index + 1] - x_edges[index] for index in range(4))
    cell_height = max(y_edges[index + 1] - y_edges[index] for index in range(2))

    output_dir.mkdir(parents=True, exist_ok=True)
    for index, direction in enumerate(DIRECTIONS):
        column = index % 4
        row = index // 4
        crop = sheet.crop(
            (
                x_edges[column],
                y_edges[row],
                x_edges[column + 1],
                y_edges[row + 1],
            )
        )
        frame = Image.new("RGBA", (cell_width, cell_height), (0, 0, 0, 0))
        frame.alpha_composite(
            crop,
            ((cell_width - crop.width) // 2, (cell_height - crop.height) // 2),
        )
        keep_largest_alpha_component(frame).save(
            output_dir / f"ildu_sotdaeulmun_{direction}.png",
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
