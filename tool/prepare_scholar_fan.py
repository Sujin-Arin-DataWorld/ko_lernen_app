"""Composite the approved silent clip for Sori; retain every source frame.

The reference alpha provides foreground/background seeds, not replacement art.
GrabCut refines each source frame inside a narrow boundary band. Interior RGB
pixels, motion, frame rate and canvas are retained; only the backdrop changes.
"""
import hashlib
import json
import subprocess
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets_unused/approved_texture_originals/hahoe-scholar-fan-20261003/source.mp4'
END = SOURCE.parent / 'end-reference.png'
START = ROOT / 'assets/illustrations/tactile/hahoe_scholar.png'
OUT = ROOT / 'assets/video/practice'
QC = ROOT / 'build/scholar-fan-qc'
OUT.mkdir(parents=True, exist_ok=True)
QC.mkdir(parents=True, exist_ok=True)
cv2.setNumThreads(4)
capture = cv2.VideoCapture(str(SOURCE))
w, h = int(capture.get(3)), int(capture.get(4))
fps = capture.get(cv2.CAP_PROP_FPS)

def reference_alpha(path):
    rgba = np.array(Image.open(path).convert('RGBA'))
    scale = h / rgba.shape[0]
    alpha = cv2.resize(rgba[:, :, 3], (round(rgba.shape[1] * scale), h))
    left = (alpha.shape[1] - w) // 2
    return alpha[:, left:left + w] > 128

refs = reference_alpha(START) | reference_alpha(END)
kernel = np.ones((19, 19), np.uint8)
outer = cv2.dilate(refs.astype(np.uint8), kernel)
inner = cv2.erode((reference_alpha(START) & reference_alpha(END)).astype(np.uint8), kernel)
frames = []
bounds = []
for index in range(60):
    ok, frame = capture.read()
    if not ok:
        raise RuntimeError('Approved source must contain all 60 frames')
    mask = np.full((h, w), cv2.GC_BGD, np.uint8)
    mask[outer > 0] = cv2.GC_PR_BGD
    mask[refs] = cv2.GC_PR_FGD
    mask[inner > 0] = cv2.GC_FGD
    cv2.grabCut(frame, mask, None, np.zeros((1, 65)), np.zeros((1, 65)), 2, cv2.GC_INIT_WITH_MASK)
    foreground = ((mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD)).astype(np.uint8)
    # Keep the largest connected silhouette, retaining hands, hat and fan.
    count, labels, stats, _ = cv2.connectedComponentsWithStats(foreground)
    foreground = (labels == (1 + np.argmax(stats[1:, cv2.CC_STAT_AREA]))).astype(np.uint8)
    alpha = cv2.GaussianBlur(foreground.astype(np.float32), (3, 3), 0.55)
    y, x = np.where(foreground > 0)
    bounds.append([int(x.min()), int(y.min()), int(x.max()), int(y.max())])
    # Add a canvas margin by uniformly shrinking, never clipping the character.
    rgba = cv2.cvtColor(frame, cv2.COLOR_BGR2RGBA)
    rgba[:, :, 3] = (alpha * 255).astype(np.uint8)
    inset = cv2.resize(rgba, (round(w * .92), round(h * .92)), interpolation=cv2.INTER_AREA)
    canvas = np.zeros((h, w, 4), np.uint8)
    x0, y0 = (w-inset.shape[1])//2, (h-inset.shape[0])//2
    canvas[y0:y0+inset.shape[0], x0:x0+inset.shape[1]] = inset
    a = canvas[:, :, 3:4].astype(np.float32) / 255
    bg = np.array([255, 253, 248], np.float32)
    rgb = (canvas[:, :, :3] * a + bg * (1-a)).round().astype(np.uint8)
    Image.fromarray(rgb).save(QC / f'matte-{index:03}.png')
    if index in [0, 14, 25, 27, 29, 59]:
        Image.fromarray(canvas).save(QC / f'alpha-{index:03}.png')
    if index == 0:
        Image.fromarray(canvas).save(OUT / 'hahoe_scholar_fan_start.png')
    if index == 59:
        Image.fromarray(canvas).save(OUT / 'hahoe_scholar_fan_end.png')
    print(f'frame {index+1}/60', flush=True)
capture.release()
output = OUT / 'hahoe_scholar_fan_hanji.mp4'
subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-framerate', str(fps), '-i', str(QC / 'matte-%03d.png'), '-an', '-c:v', 'libx264', '-crf', '14', '-preset', 'slow', '-pix_fmt', 'yuv420p', '-vf', 'scale=in_range=full:out_range=limited:out_color_matrix=bt709', '-colorspace', 'bt709', '-color_primaries', 'bt709', '-color_trc', 'bt709', '-color_range', 'tv', '-movflags', '+faststart', str(output)], check=True)
report = {'sourceSha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(), 'frames': 60, 'fps': fps, 'size': [w,h], 'audio': False, 'referenceSeedBounds': bounds, 'uniformCanvasInset': .92, 'bakedMatteRgb': [255,253,248], 'outputSha256': hashlib.sha256(output.read_bytes()).hexdigest(), 'outputBytes': output.stat().st_size}
(SOURCE.parent / 'manifest.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps(report | {'referenceSeedBounds': 'all 60 stored'}))
