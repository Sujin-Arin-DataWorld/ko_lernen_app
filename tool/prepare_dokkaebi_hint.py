"""Prepare the approved 60-frame clip without retiming or character replacement.

The raw input is retained byte for byte. Only empty background is removed from
the runtime canvas, with a uniform inset; frame bounds are checked before crop.
"""
import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('C:/Users/vjinn/.codex/generated_images/도깨비/doggabi5.mp4')
SOURCE_SHA256 = 'cd5df882ef472695ad63b4fcb1280e422ca41e5833a527992c6c444d71ebba3e'
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == SOURCE_SHA256, 'The approved doggabi5.mp4 source changed; inspect it before processing.'
ORIGINAL = ROOT / 'assets_unused/approved_texture_originals/dokkaebi-hint-20261003'
OUT = ROOT / 'assets/video/practice'
QC = ROOT / 'build/dokkaebi-hint-qc'
for folder in [ORIGINAL, OUT, QC]:
    folder.mkdir(parents=True, exist_ok=True)
shutil.copyfile(SOURCE, ORIGINAL / 'source.mp4')
assert SOURCE.read_bytes() == (ORIGINAL / 'source.mp4').read_bytes()
cv2.setNumThreads(4)
cap = cv2.VideoCapture(str(SOURCE))
fps = cap.get(cv2.CAP_PROP_FPS)
assert cap.get(cv2.CAP_PROP_FRAME_COUNT) == 60 and fps == 30
bounds = []
thumbs = []
for index in range(60):
    ok, frame = cap.read()
    assert ok and frame.shape[:2] == (1440, 1440)
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
    seed = ((hsv[:, :, 1] > 35) | (hsv[:, :, 2] < 145)).astype(np.uint8)
    seed[:85] = 0
    seed[1290:] = 0
    seed[:, :60] = 0
    seed[:, 1260:] = 0
    outer = cv2.dilate(seed, np.ones((41, 41), np.uint8))
    mask = np.full(seed.shape, cv2.GC_BGD, np.uint8)
    mask[outer > 0] = cv2.GC_PR_FGD
    mask[seed > 0] = cv2.GC_FGD
    cv2.grabCut(frame, mask, None, np.zeros((1, 65)), np.zeros((1, 65)), 2, cv2.GC_INIT_WITH_MASK)
    fg = ((mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD)).astype(np.uint8)
    _, labels, stats, _ = cv2.connectedComponentsWithStats(fg)
    fg = (labels == (1 + np.argmax(stats[1:, cv2.CC_STAT_AREA]))).astype(np.uint8)
    y, x = np.where(fg > 0)
    b = [int(x.min()), int(y.min()), int(x.max()), int(y.max())]
    assert b[0] > 60 and b[1] > 90 and b[2] < 1260 and b[3] < 1290, b
    bounds.append(b)
    rgba = cv2.cvtColor(frame, cv2.COLOR_BGR2RGBA)
    rgba[:, :, 3] = (cv2.GaussianBlur(fg.astype(np.float32), (3, 3), .55) * 255).astype(np.uint8)
    cropped = rgba[90:1290, 60:1260]
    inset = cv2.resize(cropped, (1104, 1104), interpolation=cv2.INTER_AREA)
    canvas = np.zeros((1200, 1200, 4), np.uint8)
    canvas[48:1152, 48:1152] = inset
    a = canvas[:, :, 3:4].astype(np.float32) / 255
    rgb = (canvas[:, :, :3] * a + np.array([255, 253, 248]) * (1 - a)).round().astype(np.uint8)
    img = Image.fromarray(rgb)
    img.save(QC / f'matte-{index:03}.png')
    thumb = img.resize((200, 200))
    ImageDraw.Draw(thumb).text((4, 4), f'{index} / {index / 30:.2f}s', fill='black')
    thumbs.append(thumb)
    if index in [0, 26, 30, 34, 38, 40, 59]:
        Image.fromarray(canvas).save(QC / f'alpha-{index:03}.png')
    if index in [0, 59]:
        Image.fromarray(canvas).save(OUT / f'dokkaebi_hint_{"start" if index == 0 else "end"}.png')
    print(f'frame {index+1}/60', flush=True)
cap.release()
montage = Image.new('RGB', (2000, 1200), '#FFFDF8')
for i, thumb in enumerate(thumbs): montage.paste(thumb, (i % 10 * 200, i // 10 * 200))
montage.save(QC / 'all-60-frames.jpg')
output = OUT / 'dokkaebi_hint_hanji.mp4'
subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-framerate', str(fps), '-i', str(QC / 'matte-%03d.png'), '-an', '-c:v', 'libx264', '-crf', '14', '-preset', 'slow', '-pix_fmt', 'yuv420p', '-vf', 'scale=in_range=full:out_range=limited:out_color_matrix=bt709', '-colorspace', 'bt709', '-color_primaries', 'bt709', '-color_trc', 'bt709', '-color_range', 'tv', '-movflags', '+faststart', str(output)], check=True)
report = {'sourceFile': SOURCE.name, 'sourceSha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(), 'sourceSize': [1440,1440], 'frames':60, 'fps':30, 'audio':False, 'foregroundBounds':bounds, 'backgroundCrop':[60,90,1200,1200], 'uniformInset':.92, 'runtimeSize':[1200,1200], 'bakedMatteRgb':[255,253,248], 'outputSha256':hashlib.sha256(output.read_bytes()).hexdigest(), 'outputBytes':output.stat().st_size}
(ORIGINAL / 'manifest.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
