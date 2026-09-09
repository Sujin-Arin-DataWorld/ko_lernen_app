from pathlib import Path
import hashlib
import json

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parent
BASE_PATH = ROOT / "map-transfer-02-map.png"
EMPTY_PATH = ROOT / "sarangchae-empty-courtyard-v1.png"
SPRITE_PATH = ROOT / "sarangchae-candidate05-transparent.png"
LEFT_GATE_PATH = ROOT / "gates-02-left-layer.png"
RIGHT_GATE_PATH = ROOT / "gates-02-right-layer.png"

MAP_SIZE = (1202, 1308)
CROP = (270, 625, 480, 240)
DETAIL_SIZE = (1536, 768)
SPRITE_CANVAS_SIZE = (360, 240)
SPRITE_ORIGIN = (323, 636)

base = Image.open(BASE_PATH).convert("RGBA")
assert base.size == MAP_SIZE
before = np.asarray(base).copy()

# Replace only the old Sarangchae footprint with the generated empty courtyard.
empty_detail = Image.open(EMPTY_PATH).convert("RGBA").resize(DETAIL_SIZE, Image.Resampling.LANCZOS)
empty_small = empty_detail.resize((CROP[2], CROP[3]), Image.Resampling.LANCZOS)

mask_detail = Image.new("L", DETAIL_SIZE, 0)
md = ImageDraw.Draw(mask_detail)
md.polygon([
    (180, 120), (325, 65), (650, 62), (995, 70), (1195, 155),
    (1290, 275), (1270, 535), (1170, 690), (890, 744),
    (510, 735), (210, 640), (155, 500), (160, 260),
], fill=255)
mask_detail = mask_detail.filter(ImageFilter.GaussianBlur(5))
mask_small = mask_detail.resize((CROP[2], CROP[3]), Image.Resampling.LANCZOS)

ground_layer = Image.new("RGBA", MAP_SIZE, (0, 0, 0, 0))
ground_layer.paste(empty_small, (CROP[0], CROP[1]), mask_small)
composed = Image.alpha_composite(base, ground_layer)

# Restore previously approved gate/wall pixels before the building is placed.
for gate_path in (LEFT_GATE_PATH, RIGHT_GATE_PATH):
    composed = Image.alpha_composite(composed, Image.open(gate_path).convert("RGBA"))

# Scale once from the 1536x1024 authoring canvas to the fixed map placement.
sprite = Image.open(SPRITE_PATH).convert("RGBA").resize(SPRITE_CANVAS_SIZE, Image.Resampling.LANCZOS)

# Contact shadow is an independent layer generated from the sprite alpha.
shadow_alpha = sprite.getchannel("A").filter(ImageFilter.GaussianBlur(4))
shadow_alpha = shadow_alpha.point(lambda a: int(a * 0.24))
shadow_tile = Image.new("RGBA", SPRITE_CANVAS_SIZE, (33, 27, 19, 0))
shadow_tile.putalpha(shadow_alpha)
shadow_layer = Image.new("RGBA", MAP_SIZE, (0, 0, 0, 0))
shadow_layer.alpha_composite(shadow_tile, (SPRITE_ORIGIN[0] + 4, SPRITE_ORIGIN[1] + 5))
composed = Image.alpha_composite(composed, shadow_layer)

building_layer = Image.new("RGBA", MAP_SIZE, (0, 0, 0, 0))
building_layer.alpha_composite(sprite, SPRITE_ORIGIN)
composed = Image.alpha_composite(composed, building_layer)

OUT_MAP = ROOT / "map-transfer-05-map.png"
OUT_DETAIL = ROOT / "sarangchae-candidate05-map-detail.png"
OUT_BUILDING_LAYER = ROOT / "sarangchae-candidate05-map-layer.png"
OUT_SHADOW_LAYER = ROOT / "sarangchae-candidate05-shadow-layer.png"
OUT_GROUND_LAYER = ROOT / "sarangchae-empty-ground-layer-v1.png"
composed.save(OUT_MAP)
building_layer.save(OUT_BUILDING_LAYER)
shadow_layer.save(OUT_SHADOW_LAYER)
ground_layer.save(OUT_GROUND_LAYER)
composed.crop((CROP[0], CROP[1], CROP[0] + CROP[2], CROP[1] + CROP[3])).resize(
    DETAIL_SIZE, Image.Resampling.LANCZOS
).save(OUT_DETAIL)

after = np.asarray(composed)
allowed = np.zeros((MAP_SIZE[1], MAP_SIZE[0]), dtype=bool)
allowed[CROP[1]:CROP[1]+CROP[3], CROP[0]:CROP[0]+CROP[2]] |= np.asarray(mask_small) > 0
for layer_img in (building_layer, shadow_layer):
    allowed |= np.asarray(layer_img)[:, :, 3] > 0
for gate_path in (LEFT_GATE_PATH, RIGHT_GATE_PATH):
    allowed |= np.asarray(Image.open(gate_path).convert("RGBA"))[:, :, 3] > 0

changed = np.any(before[:, :, :3] != after[:, :, :3], axis=2)
outside_changed = int(np.count_nonzero(changed & ~allowed))
assert outside_changed == 0

sprite_alpha = np.asarray(sprite)[:, :, 3]
visible_bbox = sprite.getchannel("A").getbbox()
foundation_y = SPRITE_ORIGIN[1] + visible_bbox[3]
report = {
    "operation": "empty local ground, restored gates, separate contact shadow, transparent Sarangchae",
    "base": BASE_PATH.name,
    "output": OUT_MAP.name,
    "mapSize": list(MAP_SIZE),
    "fixedMapCrop": list(CROP),
    "spriteSource": SPRITE_PATH.name,
    "spriteCanvasSizeOnMap": list(SPRITE_CANVAS_SIZE),
    "spriteOriginOnMap": list(SPRITE_ORIGIN),
    "spriteVisibleBoundsWithinCanvas": list(visible_bbox),
    "spriteFoundationReferenceYOnMap": foundation_y,
    "spriteOpaquePixelsOnMap": int(np.count_nonzero(sprite_alpha == 255)),
    "spritePartialAlphaPixelsOnMap": int(np.count_nonzero((sprite_alpha > 0) & (sprite_alpha < 255))),
    "changedRgbPixels": int(np.count_nonzero(changed)),
    "changedRgbPixelsOutsideAuthorizedLayers": outside_changed,
    "layoutPlanSha256": hashlib.sha256((ROOT / "layout-plan.json").read_bytes()).hexdigest(),
    "cameraSelectionSha256": hashlib.sha256((ROOT / "camera-selection.json").read_bytes()).hexdigest(),
    "layoutImageSha256": hashlib.sha256((ROOT / "ildu-layout-plan-v3.png").read_bytes()).hexdigest(),
    "layerFiles": {
        "ground": OUT_GROUND_LAYER.name,
        "shadow": OUT_SHADOW_LAYER.name,
        "building": OUT_BUILDING_LAYER.name,
        "leftGate": LEFT_GATE_PATH.name,
        "rightGate": RIGHT_GATE_PATH.name
    }
}
(ROOT / "sarangchae-candidate05-map-verification.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n"
)
print(json.dumps(report, ensure_ascii=False))
