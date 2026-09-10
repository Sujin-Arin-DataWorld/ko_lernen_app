"""Remove only the generated checkerboard backdrop from Sarangchae candidate 05.

The RGB channels are copied byte-for-byte; this script changes alpha only.
"""
from pathlib import Path
import hashlib
import json

import numpy as np
from PIL import Image
from scipy import ndimage


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "sarangchae-candidate05-signage-corrected-rgb.png"
OUTPUT = ROOT / "sarangchae-candidate05-transparent.png"
MASK_OUTPUT = ROOT / "sarangchae-candidate05-alpha.png"
DARK_PREVIEW = ROOT / "sarangchae-candidate05-dark-preview.png"
LIGHT_PREVIEW = ROOT / "sarangchae-candidate05-light-preview.png"

src = Image.open(SOURCE).convert("RGB")
rgb = np.asarray(src)
h, w, _ = rgb.shape

minimum = rgb.min(axis=2)
maximum = rgb.max(axis=2)
chroma = maximum - minimum

# Imagegen rendered its transparency preview into RGB. Both checker colors and
# their soft decorative variations are bright neutral grays. V3 timber, plaster,
# stone and roof pixels either fall below this luminance or carry more chroma.
checker = (minimum >= 195) & (chroma <= 7)

border_seed = np.zeros((h, w), dtype=bool)
border_seed[0, :] = checker[0, :]
border_seed[-1, :] = checker[-1, :]
border_seed[:, 0] = checker[:, 0]
border_seed[:, -1] = checker[:, -1]
background = ndimage.binary_propagation(border_seed, mask=checker)

# Clear large checker regions enclosed by posts, railings or eaves. Small bright
# neutral details on the architecture remain opaque.
labels, _ = ndimage.label(checker)
component_sizes = np.bincount(labels.ravel())
large_ids = np.flatnonzero(component_sizes >= 700)
large_ids = large_ids[large_ids != 0]
background |= np.isin(labels, large_ids)

alpha = np.full((h, w), 255, dtype=np.uint8)
alpha[background] = 0

# Restore a one-pixel antialiased transition without modifying source RGB.
ring = ndimage.binary_dilation(background, iterations=1) & ~background
edge_strength = np.clip(
    (195 - minimum.astype(np.int16)) * 4 + chroma.astype(np.int16) * 8,
    0,
    255,
).astype(np.uint8)
alpha[ring] = np.minimum(alpha[ring], edge_strength[ring])

# Generated decorative checker highlights can leave isolated specks after the
# neutral-gray removal. The building is one connected component; discard only
# detached alpha components smaller than 100 pixels.
foreground_labels, _ = ndimage.label(alpha > 0)
foreground_sizes = np.bincount(foreground_labels.ravel())
small_foreground_ids = np.flatnonzero(foreground_sizes < 100)
small_foreground_ids = small_foreground_ids[small_foreground_ids != 0]
alpha[np.isin(foreground_labels, small_foreground_ids)] = 0

rgba = np.dstack((rgb, alpha))
Image.fromarray(rgba).save(OUTPUT)
Image.fromarray(alpha).save(MASK_OUTPUT)

sprite = Image.fromarray(rgba)
for color, path in (((38, 43, 47), DARK_PREVIEW), ((225, 220, 208), LIGHT_PREVIEW)):
    bg = Image.new("RGB", (w, h), color)
    bg.paste(sprite, (0, 0), sprite)
    bg.save(path)

saved = np.asarray(Image.open(OUTPUT).convert("RGBA"))
assert np.array_equal(rgb, saved[:, :, :3]), "RGB changed"
assert int(saved[:, :, 3].min()) == 0
assert int(saved[:, :, 3].max()) == 255

report = {
    "operation": "checkerboard background to alpha; source RGB unchanged",
    "source": SOURCE.name,
    "output": OUTPUT.name,
    "size": [w, h],
    "foregroundBounds": list(Image.fromarray(alpha).getbbox()),
    "rgbChangedPixels": int(np.count_nonzero(np.any(rgb != saved[:, :, :3], axis=2))),
    "transparentPixels": int(np.count_nonzero(alpha == 0)),
    "opaquePixels": int(np.count_nonzero(alpha == 255)),
    "partialAlphaPixels": int(np.count_nonzero((alpha > 0) & (alpha < 255))),
    "sourceSha256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    "outputSha256": hashlib.sha256(OUTPUT.read_bytes()).hexdigest(),
    "checks": {
        "realAlphaChannel": True,
        "rgbBytePreserved": True,
        "fullCanvasUnchanged": True,
    },
}
(ROOT / "sarangchae-candidate05-alpha-verification.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n"
)
print(json.dumps(report, ensure_ascii=False))
