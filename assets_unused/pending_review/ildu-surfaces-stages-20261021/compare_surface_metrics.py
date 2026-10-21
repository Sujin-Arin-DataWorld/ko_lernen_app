"""Same-camera R5/R6 raster checks. These are image measurements, not material approval."""

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parent


def load(gate):
    old = Image.open(ROOT / "surface-r5" / f"{gate}-eaves.png").convert("RGBA")
    new = Image.open(ROOT / f"{gate}-eaves.png").convert("RGBA")
    assert old.size == new.size == (1600, 900)
    return old, new


def measure_roof(old, new):
    x0, y0, x1, y1 = 320, 85, 1280, 390
    old_rgb = np.asarray(old.crop((x0, y0, x1, y1)), dtype=np.float32)
    new_rgb = np.asarray(new.crop((x0, y0, x1, y1)), dtype=np.float32)
    # Both views use the same camera and geometry. Opaque neutral pixels remove
    # the transparent studio background and painted eaves from this roof ROI.
    neutral = lambda a: (a[..., 3] > 250) & ((a[..., :3].max(axis=2) - a[..., :3].min(axis=2)) < 30)
    mask = neutral(old_rgb) & neutral(new_rgb)
    assert mask.sum() > 10000
    luma = lambda a: .2126*a[..., 0] + .7152*a[..., 1] + .0722*a[..., 2]
    old_y, new_y = luma(old_rgb), luma(new_rgb)
    old_blur = np.asarray(old.crop((x0, y0, x1, y1)).convert("L").filter(ImageFilter.GaussianBlur(5)), dtype=np.float32)
    new_blur = np.asarray(new.crop((x0, y0, x1, y1)).convert("L").filter(ImageFilter.GaussianBlur(5)), dtype=np.float32)
    old_detail = np.abs(np.asarray(old.crop((x0, y0, x1, y1)).convert("L"), dtype=np.float32) - old_blur)
    new_detail = np.abs(np.asarray(new.crop((x0, y0, x1, y1)).convert("L"), dtype=np.float32) - new_blur)
    return {
        "regionPx": [x0, y0, x1, y1],
        "validPx": int(mask.sum()),
        "medianLumaR5": round(float(np.median(old_y[mask])), 2),
        "medianLumaR6": round(float(np.median(new_y[mask])), 2),
        "medianLumaChangePercent": round(float((np.median(new_y[mask]) / np.median(old_y[mask]) - 1) * 100), 1),
        "meanFineContrastR5": round(float(np.mean(old_detail[mask])), 3),
        "meanFineContrastR6": round(float(np.mean(new_detail[mask])), 3),
        "fineContrastChangePercent": round(float((np.mean(new_detail[mask]) / np.mean(old_detail[mask]) - 1) * 100), 1),
    }


def measure_shrine_paint(old, new):
    """Compare representative painted pixels under the same eaves lighting."""
    result = {}
    for label, box in (("red", (300, 470, 1250, 550)), ("green", (300, 520, 1250, 680))):
        samples = {}
        for revision, image in (("R5", old), ("R6", new)):
            pixels = np.asarray(image.crop(box).convert("RGB"), dtype=np.float32)
            r, g, b = pixels[..., 0], pixels[..., 1], pixels[..., 2]
            mask = ((r > g * 1.25) & (r > b * 1.2) & (r > 35)) if label == "red" else ((g > r * 1.25) & (g > b * 1.1) & (g > 25))
            assert mask.sum() > 10000
            samples[revision] = {"pixelCount": int(mask.sum()), "medianRgb": [round(float(v), 1) for v in np.median(pixels[mask], axis=0)]}
        result[label] = {"regionPx": list(box), **samples}
    return result


def main():
    report = {gate: measure_roof(*load(gate)) for gate in ("left", "right", "shrine")}
    report["shrinePaintSamples"] = measure_shrine_paint(*load("shrine"))
    (ROOT / "surface-r6-comparison.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
