from pathlib import Path
import hashlib
import json

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parent
BASE_PATH = ROOT / "map-transfer-02-map.png"
EMPTY_PATH = ROOT / "sarangchae-empty-courtyard-v1.png"
SPRITE_PATH = ROOT / "sarangchae-candidate05-transparent.png"
SELECTED_RGB_PATH = ROOT / "sarangchae-user-selected-source.png"
LEFT_GATE_PATH = ROOT / "gates-02-left-layer.png"
RIGHT_GATE_PATH = ROOT / "gates-02-right-layer.png"

MAP_SIZE = (1202, 1308)
CROP = (270, 625, 480, 240)
DETAIL_SIZE = (1536, 768)

# The user-selected candidate 05 remains pixel-identical. Only its map display
# size and origin change so the two approved side gates remain visible.
PREVIOUS_SPRITE_CANVAS_SIZE = (360, 240)
SPRITE_CANVAS_SIZE = (282, 188)
SPRITE_ORIGIN = (358, 686)

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

# Restore the two approved side-gate/wall layers before placing the building.
gate_layers = []
for gate_path in (LEFT_GATE_PATH, RIGHT_GATE_PATH):
    gate_layer = Image.open(gate_path).convert("RGBA")
    gate_layers.append(gate_layer)
    composed = Image.alpha_composite(composed, gate_layer)

# Resize only for map placement. The transparent master file itself is unchanged.
sprite_master = Image.open(SPRITE_PATH).convert("RGBA")
selected_rgb = Image.open(SELECTED_RGB_PATH).convert("RGB")
assert np.array_equal(np.asarray(sprite_master)[:, :, :3], np.asarray(selected_rgb))
sprite = sprite_master.resize(SPRITE_CANVAS_SIZE, Image.Resampling.LANCZOS)

# Contact shadow remains a separate layer and follows only the smaller placement.
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

OUT_MAP = ROOT / "map-transfer-selected-small-map.png"
OUT_DETAIL = ROOT / "sarangchae-selected-small-map-detail.png"
OUT_BUILDING_LAYER = ROOT / "sarangchae-selected-small-map-layer.png"
OUT_SHADOW_LAYER = ROOT / "sarangchae-selected-small-shadow-layer.png"
OUT_GROUND_LAYER = ROOT / "sarangchae-selected-small-ground-layer.png"
OUT_REPORT = ROOT / "sarangchae-selected-small-map-verification.json"
composed.save(OUT_MAP)
building_layer.save(OUT_BUILDING_LAYER)
shadow_layer.save(OUT_SHADOW_LAYER)
ground_layer.save(OUT_GROUND_LAYER)
composed.crop((CROP[0], CROP[1], CROP[0] + CROP[2], CROP[1] + CROP[3])).resize(
    DETAIL_SIZE, Image.Resampling.LANCZOS
).save(OUT_DETAIL)

after = np.asarray(composed)
allowed = np.zeros((MAP_SIZE[1], MAP_SIZE[0]), dtype=bool)
allowed[CROP[1]:CROP[1] + CROP[3], CROP[0]:CROP[0] + CROP[2]] |= np.asarray(mask_small) > 0
for layer_img in (building_layer, shadow_layer):
    allowed |= np.asarray(layer_img)[:, :, 3] > 0
for gate_layer in gate_layers:
    allowed |= np.asarray(gate_layer)[:, :, 3] > 0

changed = np.any(before[:, :, :3] != after[:, :, :3], axis=2)
outside_changed = int(np.count_nonzero(changed & ~allowed))
assert outside_changed == 0

building_mask = np.asarray(building_layer)[:, :, 3] > 0
gate_visibility = {}
for label, gate_layer in zip(("left", "right"), gate_layers):
    gate_mask = np.asarray(gate_layer)[:, :, 3] > 0
    gate_pixels = int(np.count_nonzero(gate_mask))
    overlap_pixels = int(np.count_nonzero(gate_mask & building_mask))
    gate_visibility[label] = {
        "gateAlphaPixels": gate_pixels,
        "coveredByBuildingPixels": overlap_pixels,
        "visibleAfterBuildingPixels": gate_pixels - overlap_pixels,
        "visiblePercent": round((gate_pixels - overlap_pixels) * 100 / gate_pixels, 2),
    }

sprite_alpha = np.asarray(sprite)[:, :, 3]
visible_bbox = sprite.getchannel("A").getbbox()
building_map_bbox = building_layer.getchannel("A").getbbox()
foundation_y = SPRITE_ORIGIN[1] + visible_bbox[3]
report = {
    "operation": "user-selected candidate 05; map display scale and origin only",
    "base": BASE_PATH.name,
    "output": OUT_MAP.name,
    "mapSize": list(MAP_SIZE),
    "fixedMapCrop": list(CROP),
    "spriteSource": SPRITE_PATH.name,
    "selectedRgbSource": SELECTED_RGB_PATH.name,
    "sourceRgbPixelIdentical": True,
    "selectedSourceSha256": hashlib.sha256(SELECTED_RGB_PATH.read_bytes()).hexdigest(),
    "sourceMasterSha256": hashlib.sha256(SPRITE_PATH.read_bytes()).hexdigest(),
    "previousSpriteCanvasSizeOnMap": list(PREVIOUS_SPRITE_CANVAS_SIZE),
    "spriteCanvasSizeOnMap": list(SPRITE_CANVAS_SIZE),
    "linearScaleVersusPreviousPercent": round(SPRITE_CANVAS_SIZE[0] * 100 / PREVIOUS_SPRITE_CANVAS_SIZE[0], 2),
    "spriteOriginOnMap": list(SPRITE_ORIGIN),
    "spriteVisibleBoundsWithinCanvas": list(visible_bbox),
    "spriteVisibleBoundsOnMap": list(building_map_bbox),
    "spriteFoundationReferenceYOnMap": foundation_y,
    "spriteOpaquePixelsOnMap": int(np.count_nonzero(sprite_alpha == 255)),
    "spritePartialAlphaPixelsOnMap": int(np.count_nonzero((sprite_alpha > 0) & (sprite_alpha < 255))),
    "gateVisibilityAfterBuilding": gate_visibility,
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
        "rightGate": RIGHT_GATE_PATH.name,
    },
}
OUT_REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
print(json.dumps(report, ensure_ascii=False))
