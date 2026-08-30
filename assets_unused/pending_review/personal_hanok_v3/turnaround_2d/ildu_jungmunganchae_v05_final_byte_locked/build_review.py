from __future__ import annotations

from hashlib import sha256
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
GENERATED = ROOT / "generated_28deg"
TRANSPARENT = ROOT / "transparent_28deg"

ORDER = [
    ("00_front_000.png", "0°  정면"),
    ("01_front_right_045.png", "45°  앞-오른쪽"),
    ("02_right_090.png", "90°  오른쪽"),
    ("03_rear_right_135.png", "135°  뒤-오른쪽"),
    ("04_rear_180.png", "180°  배면"),
    ("05_rear_left_225.png", "225°  뒤-왼쪽"),
    ("06_left_270.png", "270°  왼쪽"),
    ("07_front_left_315.png", "315°  앞-왼쪽"),
]


def remove_baked_checkerboard(source: Path, destination: Path) -> dict[str, object]:
    rgb_image = Image.open(source).convert("RGB")
    rgb = np.asarray(rgb_image, dtype=np.uint8)
    minimum = rgb.min(axis=2)
    maximum = rgb.max(axis=2)
    spread = maximum.astype(np.int16) - minimum.astype(np.int16)

    # Remove every unmistakable white/gray checker pixel, including checker
    # islands visible through an opening. A broader neutral mask is then
    # flood-filled only from the outer canvas to clean antialiased boundaries.
    checker = (minimum >= 238) & (spread <= 6)
    outer_candidate = (minimum >= 220) & (spread <= 18)
    flood = Image.fromarray(outer_candidate.astype(np.uint8) * 255)
    draw = ImageDraw.Draw(flood)
    seeds = [
        (0, 0),
        (flood.width - 1, 0),
        (0, flood.height - 1),
        (flood.width - 1, flood.height - 1),
    ]
    for seed in seeds:
        if flood.getpixel(seed) == 255:
            ImageDraw.floodfill(flood, seed, 128, thresh=0)
    outer = np.asarray(flood) == 128
    background = checker | outer

    alpha = np.where(background, 0, 255).astype(np.uint8)
    rgba = np.dstack((rgb, alpha))
    result = Image.fromarray(rgba)
    destination.parent.mkdir(parents=True, exist_ok=True)
    result.save(destination, optimize=True)

    alpha_values = np.asarray(result.getchannel("A"))
    return {
        "size": result.size,
        "transparent": int(np.count_nonzero(alpha_values == 0)),
        "opaque": int(np.count_nonzero(alpha_values == 255)),
        "partial": int(np.count_nonzero((alpha_values > 0) & (alpha_values < 255))),
        "sha256": sha256(destination.read_bytes()).hexdigest().upper(),
    }


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        Path("C:/Windows/Fonts/malgunbd.ttf" if bold else "C:/Windows/Fonts/malgun.ttf"),
        Path("C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size=size)
    return ImageFont.load_default()


def contain(image: Image.Image, width: int, height: int) -> Image.Image:
    alpha_bbox = image.getchannel("A").getbbox()
    if alpha_bbox is None:
        raise ValueError("empty transparent image")
    cropped = image.crop(alpha_bbox)
    scale = min(width / cropped.width, height / cropped.height)
    size = (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale)))
    return cropped.resize(size, Image.Resampling.LANCZOS)


def make_review_sheet(paths: list[Path], destination: Path, transparent: bool) -> None:
    canvas_size = (3840, 2160)
    background = (0, 0, 0, 0) if transparent else (224, 221, 214, 255)
    canvas = Image.new("RGBA", canvas_size, background)
    draw = ImageDraw.Draw(canvas)
    title_font = font(54, bold=True)
    label_font = font(34, bold=True)
    note_font = font(26)

    if not transparent:
        draw.text((80, 42), "일두고택 중문채 V05 · 45° 간격 8방향", font=title_font, fill=(39, 35, 31, 255))
        draw.text((80, 112), "수직 하향축 기준 28° 조감 · final 창호 고정 · pending review", font=note_font, fill=(83, 76, 68, 255))

    top = 170 if not transparent else 20
    tile_w = 960
    tile_h = (canvas_size[1] - top) // 2
    for index, ((_, label), path) in enumerate(zip(ORDER, paths, strict=True)):
        row, column = divmod(index, 4)
        x0 = column * tile_w
        y0 = top + row * tile_h
        if not transparent:
            draw.rounded_rectangle(
                (x0 + 14, y0 + 14, x0 + tile_w - 14, y0 + tile_h - 14),
                radius=22,
                fill=(242, 240, 235, 255),
                outline=(150, 143, 134, 255),
                width=3,
            )
        draw.text((x0 + 34, y0 + 28), label, font=label_font, fill=(45, 40, 36, 255))
        source = Image.open(path).convert("RGBA")
        fitted = contain(source, tile_w - 54, tile_h - 105)
        px = x0 + (tile_w - fitted.width) // 2
        py = y0 + 84 + (tile_h - 96 - fitted.height) // 2
        canvas.alpha_composite(fitted, (px, py))

    canvas.save(destination, optimize=True)


def main() -> None:
    TRANSPARENT.mkdir(parents=True, exist_ok=True)
    metrics: dict[str, dict[str, object]] = {}
    paths: list[Path] = []
    for filename, _ in ORDER:
        source = GENERATED / filename
        destination = TRANSPARENT / filename
        metrics[filename] = remove_baked_checkerboard(source, destination)
        paths.append(destination)

    make_review_sheet(paths, ROOT / "ildu_jungmunganchae_v05_8view_review_sheet.png", transparent=False)
    make_review_sheet(paths, ROOT / "ildu_jungmunganchae_v05_8view_transparent_sheet.png", transparent=True)

    for filename, _ in ORDER:
        item = metrics[filename]
        print(
            f"{filename}\t{item['size'][0]}x{item['size'][1]}\t"
            f"transparent={item['transparent']}\topaque={item['opaque']}\t"
            f"partial={item['partial']}\tsha256={item['sha256']}"
        )


if __name__ == "__main__":
    main()
