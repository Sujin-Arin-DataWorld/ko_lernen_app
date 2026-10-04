"""Prepare the second user-selected MP4, preserving all 49 motion frames.

doccabi6.mp4 and 도깨비.mp4 are byte-identical aliases. Archive the raw source
once; do not manufacture a third video or retime the supplied performance.
Only the empty backdrop is replaced with the existing Sori hanji matte. The
uniform canvas placement aligns its first club/floor contact with the existing
puzzle ledge. Every decoded foreground frame is checked before composition.
"""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess

import cv2
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = Path('C:/Users/vjinn/.codex/generated_images/도깨비')
SOURCES = [SOURCE_DIR / name for name in ['doccabi6.mp4', '도깨비.mp4']]
SOURCE_SHA256 = '48e0709b87fb10b8df595444a6b0ce8cc73c95a2ca573ca233a8dd41ba9235b9'
for source in SOURCES:
    assert hashlib.sha256(source.read_bytes()).hexdigest() == SOURCE_SHA256, source

ORIGINAL = ROOT / 'assets_unused/approved_texture_originals/dokkaebi-hint-swing-20261003'
OUT = ROOT / 'assets/video/practice'
QC = ROOT / 'build/dokkaebi-hint-swing-qc'
for folder in [ORIGINAL, OUT, QC]:
    folder.mkdir(parents=True, exist_ok=True)
archived = ORIGINAL / 'source.mp4'
if archived.exists():
    assert hashlib.sha256(archived.read_bytes()).hexdigest() == SOURCE_SHA256
else:
    shutil.copyfile(SOURCES[0], archived)
assert all(source.read_bytes() == archived.read_bytes() for source in SOURCES)

cv2.setNumThreads(4)
cap = cv2.VideoCapture(str(archived))
assert cap.get(cv2.CAP_PROP_FRAME_COUNT) == 49
assert cap.get(cv2.CAP_PROP_FPS) == 24
bounds, placed_bounds, thumbs = [], [], []
offset_x, offset_y = 83, 194
for index in range(49):
    ok, frame = cap.read()
    assert ok and frame.shape[:2] == (960, 960)
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
    seed = ((hsv[:, :, 1] > 35) | (hsv[:, :, 2] < 145)).astype(np.uint8)
    outer = cv2.dilate(seed, np.ones((31, 31), np.uint8))
    mask = np.full(seed.shape, cv2.GC_BGD, np.uint8)
    mask[outer > 0] = cv2.GC_PR_FGD
    mask[seed > 0] = cv2.GC_FGD
    cv2.grabCut(frame, mask, None, np.zeros((1, 65)), np.zeros((1, 65)), 2, cv2.GC_INIT_WITH_MASK)
    fg = ((mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD)).astype(np.uint8)
    y, x = np.where(fg > 0)
    b = [int(x.min()), int(y.min()), int(x.max()), int(y.max())]
    assert min(b[:2]) > 20 and max(b[2:]) < 940, (index, b)
    bounds.append(b)
    rgba = cv2.cvtColor(frame, cv2.COLOR_BGR2RGBA)
    rgba[:, :, 3] = (cv2.GaussianBlur(fg.astype(np.float32), (3, 3), .55) * 255).astype(np.uint8)
    resized = cv2.resize(rgba, (1104, 1104), interpolation=cv2.INTER_AREA)
    # Only transparent background extends below the final square canvas.
    assert not np.any(resized[1200 - offset_y:, :, 3]), index
    canvas = np.zeros((1200, 1200, 4), np.uint8)
    canvas[offset_y:, offset_x:offset_x + 1104] = resized[:1200 - offset_y]
    y, x = np.where(canvas[:, :, 3] > 0)
    placed = [int(x.min()), int(y.min()), int(x.max()), int(y.max())]
    assert min(placed[:2]) > 40 and max(placed[2:]) < 1160, (index, placed)
    placed_bounds.append(placed)
    alpha = canvas[:, :, 3:4].astype(np.float32) / 255
    rgb = (canvas[:, :, :3] * alpha + np.array([255, 253, 248]) * (1 - alpha)).round().astype(np.uint8)
    img = Image.fromarray(rgb)
    img.save(QC / f'matte-{index:03}.png')
    thumb = img.resize((180, 180))
    ImageDraw.Draw(thumb).text((4, 4), f'{index} / {index / 24:.3f}s', fill='black')
    thumbs.append(thumb)
    if index in [0, 48]:
        Image.fromarray(canvas).save(OUT / f'dokkaebi_hint_swing_{"start" if index == 0 else "end"}.png')
    print(f'frame {index + 1}/49', flush=True)
cap.release()
montage = Image.new('RGB', (1260, 1260), '#FFFDF8')
for index, thumb in enumerate(thumbs):
    montage.paste(thumb, (index % 7 * 180, index // 7 * 180))
montage.save(QC / 'all-49-frames.jpg')
output = OUT / 'dokkaebi_hint_swing_hanji.mp4'
subprocess.run([
    'ffmpeg', '-y', '-loglevel', 'error', '-framerate', '24', '-i', str(QC / 'matte-%03d.png'),
    '-an', '-c:v', 'libx264', '-crf', '14', '-preset', 'slow', '-pix_fmt', 'yuv420p',
    '-vf', 'scale=in_range=full:out_range=limited:out_color_matrix=bt709',
    '-colorspace', 'bt709', '-color_primaries', 'bt709', '-color_trc', 'bt709',
    '-color_range', 'tv', '-movflags', '+faststart', str(output),
], check=True)
report = {
    'sourceFiles': [source.name for source in SOURCES], 'sourceSha256': SOURCE_SHA256,
    'identicalAliases': True, 'sourceSize': [960, 960], 'frames': 49, 'fps': 24,
    'durationSeconds': 49 / 24, 'audio': False, 'selectedFrames': [0, 48],
    'foregroundBounds': bounds, 'runtimeForegroundBounds': placed_bounds,
    'foregroundCrop': None, 'uniformScale': 1104 / 960, 'canvasOffset': [offset_x, offset_y],
    'runtimeSize': [1200, 1200], 'bakedMatteRgb': [255, 253, 248],
    'contactFrame': 16, 'impactSeconds': 16 / 24, 'sourceContactPx': [802, 792],
    'runtimeContactNormalized': [(83 + 802 * 1.15) / 1200, (194 + 792 * 1.15) / 1200],
    'outputSha256': hashlib.sha256(output.read_bytes()).hexdigest(), 'outputBytes': output.stat().st_size,
    'purpose': 'Alternate requested hint gesture; source appearance is not regenerated or repaired.',
}
(ORIGINAL / 'manifest.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({key: value for key, value in report.items() if 'Bounds' not in key}, ensure_ascii=False, indent=2))
