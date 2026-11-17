"""Use a safe wind-up excerpt for the introduction, never a hint impact.

Preserve the downloaded original byte for byte. Frames 0..13 show a short
single swing; the later floor contact and malformed poses are excluded.
No retiming, foreground repainting or generated character replacement.
"""
from pathlib import Path
import hashlib
import json
import shutil
import sys
import subprocess
import cv2
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ORIGINAL = ROOT / 'assets_unused/approved_texture_originals/dokkaebi-intro-swing-20261003'
SOURCE = Path(sys.argv[1]) if len(sys.argv) > 1 else ORIGINAL / 'source.mp4'
OUT = ROOT / 'assets/video/practice'
QC = ROOT / 'build/dokkaebi-intro-qc'
for folder in [ORIGINAL, OUT, QC]:
    folder.mkdir(parents=True, exist_ok=True)
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == '48e0709b87fb10b8df595444a6b0ce8cc73c95a2ca573ca233a8dd41ba9235b9'
if SOURCE.resolve() != (ORIGINAL / 'source.mp4').resolve():
    shutil.copyfile(SOURCE, ORIGINAL / 'source.mp4')
assert SOURCE.read_bytes() == (ORIGINAL / 'source.mp4').read_bytes()
cv2.setNumThreads(4)
cap = cv2.VideoCapture(str(SOURCE))
assert cap.get(cv2.CAP_PROP_FPS) == 24 and cap.get(cv2.CAP_PROP_FRAME_COUNT) == 49
bounds, thumbs = [], []
for index in range(14):
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
    assert min(b[:2]) > 20 and max(b[2:]) < 940, b
    assert b[0] > 128 and b[1] > 192 and b[2] < 752 and b[3] < 816, b
    bounds.append(b)
    rgba = cv2.cvtColor(frame, cv2.COLOR_BGR2RGBA)
    rgba[:, :, 3] = (cv2.GaussianBlur(fg.astype(np.float32), (3, 3), .55) * 255).astype(np.uint8)
    canvas = np.zeros((960, 960, 4), np.uint8)
    canvas[38:922, 38:922] = cv2.resize(rgba[192:816, 128:752], (884, 884), interpolation=cv2.INTER_AREA)
    a = canvas[:, :, 3:4].astype(np.float32) / 255
    rgb = (canvas[:, :, :3] * a + np.array([255,253,248]) * (1-a)).round().astype(np.uint8)
    img = Image.fromarray(rgb)
    img.save(QC / f'matte-{index:03}.png')
    thumb = img.resize((180, 180))
    ImageDraw.Draw(thumb).text((4, 4), str(index), fill='black')
    thumbs.append(thumb)
    if index in [0, 13]:
        Image.fromarray(canvas).save(OUT / f'dokkaebi_intro_swing_{"start" if index == 0 else "end"}.png')
cap.release()
montage = Image.new('RGB', (1260, 360), '#FFFDF8')
for i, im in enumerate(thumbs):
    montage.paste(im, (i % 7 * 180, i // 7 * 180))
montage.save(QC / 'all-14-frames.jpg')
output = OUT / 'dokkaebi_intro_swing_hanji.mp4'
subprocess.run(['ffmpeg','-y','-loglevel','error','-framerate','24','-i',str(QC/'matte-%03d.png'),'-an','-c:v','libx264','-crf','14','-pix_fmt','yuv420p','-movflags','+faststart',str(output)],check=True)
report = {'sourceSha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(), 'sourceFile':SOURCE.name, 'sourceFrames':49, 'selectedFrames':[0,13], 'frames':14,'fps':24,'durationSeconds':14/24,'audio':False,'foregroundBounds':bounds,'backgroundCrop':[128,192,624,624],'uniformInset':884/960,'outputSha256':hashlib.sha256(output.read_bytes()).hexdigest(),'purpose':'Introduction wind-up only; no floor contact, hint, result or reward.'}
(ORIGINAL/'manifest.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k!='foregroundBounds'},indent=2))
