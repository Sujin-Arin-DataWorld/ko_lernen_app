"""Remove the generated light checkerboard without regenerating the artwork."""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image, ImageFilter


def is_background_candidate(pixel: tuple[int, int, int]) -> bool:
    low = min(pixel)
    high = max(pixel)
    return low >= 210 and high - low <= 18


def extract(input_path: Path, output_path: Path) -> None:
    source = Image.open(input_path).convert("RGB")
    width, height = source.size
    pixels = source.load()
    seen = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def enqueue(x: int, y: int) -> None:
        offset = y * width + x
        if seen[offset] or not is_background_candidate(pixels[x, y]):
            return
        seen[offset] = 1
        queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)

    while queue:
        x, y = queue.popleft()
        if x > 0:
            enqueue(x - 1, y)
        if x + 1 < width:
            enqueue(x + 1, y)
        if y > 0:
            enqueue(x, y - 1)
        if y + 1 < height:
            enqueue(x, y + 1)

    alpha = Image.new("L", source.size, 255)
    alpha_pixels = alpha.load()
    for y in range(height):
        row = y * width
        for x in range(width):
            if seen[row + x]:
                alpha_pixels[x, y] = 0

    # A subpixel feather removes the baked checker fringe while preserving the
    # ink contour and fine roof tips.
    alpha = alpha.filter(ImageFilter.GaussianBlur(radius=0.55))
    output = source.convert("RGBA")
    output.putalpha(alpha)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output.save(output_path, optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    extract(args.input, args.output)


if __name__ == "__main__":
    main()
