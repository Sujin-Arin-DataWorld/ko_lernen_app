from __future__ import annotations

from pathlib import Path
import hashlib
import json

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[4]
BASE_PATH = ROOT / "map-transfer-selected-small-map.png"
REG_PATH = ROOT / "natural-map-registration-v1.json"
SARANGCHAE_REG_PATH = ROOT / "sarangchae-selection-registration-v1.json"
OUT_JSON = ROOT / "next-batch-target-guides-v1.json"


def font(size: int, bold: bool = False):
    filename = "Paperlogy-Bold.ttf" if bold else "Paperlogy-Regular.ttf"
    path = REPO / "assets" / "fonts" / "Paperlogy" / filename
    if not path.is_file():
        raise FileNotFoundError(f"required repository font is missing: {path}")
    return ImageFont.truetype(str(path), size)


def expanded_bbox(points, margin, image_size):
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    left = max(0, int(min(xs) - margin))
    top = max(0, int(min(ys) - margin))
    right = min(image_size[0], int(max(xs) + margin + 1))
    bottom = min(image_size[1], int(max(ys) + margin + 1))
    return left, top, right, bottom


def build_guide(base, item_id, name, points, margin, color):
    crop_box = expanded_bbox(points, margin, base.size)
    crop = base.crop(crop_box).convert("RGBA")
    local = [(x - crop_box[0], y - crop_box[1]) for x, y in points]
    overlay = Image.new("RGBA", crop.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    fill = tuple(color) + (64,)
    stroke = tuple(color) + (255,)
    draw.polygon(local, fill=fill, outline=stroke, width=4)
    for x, y in local:
        draw.ellipse((x - 5, y - 5, x + 5, y + 5), fill=(255, 252, 241, 255), outline=stroke, width=3)
    baseline_y = max(y for _, y in local)
    draw.line((0, baseline_y, crop.width, baseline_y), fill=stroke, width=3)
    composed = Image.alpha_composite(crop, overlay)
    scale = min(1024 / composed.width, 900 / composed.height)
    display_size = (round(composed.width * scale), round(composed.height * scale))
    display = composed.resize(display_size, Image.Resampling.LANCZOS)
    out = Image.new("RGB", (1024, 1024), "#f1eee4")
    out.paste(display.convert("RGB"), ((1024 - display.width) // 2, (900 - display.height) // 2))
    footer = ImageDraw.Draw(out)
    footer.rectangle((0, 900, 1024, 1024), fill="#fffaf0")
    footer.line((0, 900, 1024, 900), fill=stroke, width=3)
    footer.text((28, 922), f"{name} · 목표 자리", font=font(28, True), fill=stroke)
    footer.text((28, 966), "색 면은 배치 범위, 가로선은 기단 접지 기준", font=font(18), fill="#534a3f")
    output_path = ROOT / f"{item_id}-target-context-v1.png"
    out.save(output_path)
    return {
        "file": output_path.name,
        "mapCrop": list(crop_box),
        "targetPolygonMap": [[round(x, 2), round(y, 2)] for x, y in points],
        "foundationReferenceYMap": round(max(y for _, y in points), 2),
        "guideScale": scale,
        "role": "Placement, facing and local occlusion guide only; surrounding buildings are not style references.",
    }


base = Image.open(BASE_PATH).convert("RGBA")
registration = json.loads(REG_PATH.read_text(encoding="utf-8"))
building_polygons = registration["transformedBuildingPolygons"]
gate_polygons = registration["transformedGatePolygons"]

guides = {
    "jungmunchae": build_guide(base, "jungmunchae", "중문채", building_polygons["jungmunchae"], 70, (43, 106, 180)),
    "changgo": build_guide(base, "changgo", "창고", building_polygons["changgo"], 70, (173, 68, 41)),
    "G02": build_guide(base, "G02-hyeopmun-left", "사랑채 왼쪽 협문", gate_polygons["G02"], 50, (194, 101, 24)),
    "G04": build_guide(base, "G04-hyeopmun-right", "사랑채 오른쪽 협문", gate_polygons["G04"], 50, (194, 101, 24)),
}

report = {
    "status": "guides_ready_generation_not_started",
    "base": BASE_PATH.name,
    "baseSha256": hashlib.sha256(BASE_PATH.read_bytes()).hexdigest(),
    "registration": REG_PATH.name,
    "sarangchaeRegistration": SARANGCHAE_REG_PATH.name,
    "sarangchaeRegistrationSha256": hashlib.sha256(SARANGCHAE_REG_PATH.read_bytes()).hexdigest(),
    "guides": guides,
    "constraints": [
        "Keep the user-selected Sarangchae candidate 05 at its reviewed 78.33% registration and preserve all current wall pixels.",
        "The colored polygon is a placement envelope, not a drawable part of the building.",
        "Use each item's V3 canonical source and adjacent direction views for appearance.",
        "Generate isolated artwork only after the Sarangchae map-scale registration is approved.",
    ],
}
OUT_JSON.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
print(json.dumps({"status": report["status"], "guides": {k: v["file"] for k, v in guides.items()}}, ensure_ascii=False))
