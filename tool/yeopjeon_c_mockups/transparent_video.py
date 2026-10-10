"""Create an alpha-bearing VIDEO derivative; never overwrite the source MP4.

This is video matting, not a new character render. Border-connected neutral
background is removed. An edge-enclosed body mask protects the white hanbok.
The encoded alpha is decoded again with libvpx and measured, not just tagged.
"""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import cv2
import numpy as np

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / 'assets/making_money.mp4'
OUTPUT = ROOT / 'assets/making_money_alpha.webm'
STAGED = ROOT / 'assets/making_money_alpha.review-tmp.webm'
REVIEW = ROOT / 'media-review'


def border_region(mask):
    """8-connected border flood, using OpenCV labels rather than Python BFS."""
    _, labels = cv2.connectedComponents(mask.astype(np.uint8), connectivity=8)
    ids = np.unique(np.r_[labels[0], labels[-1], labels[:, 0], labels[:, -1]])
    ids = ids[ids != 0]
    return np.isin(labels, ids)


def matte(frame):
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    f = rgb.astype(np.float32)
    low, high = f.min(2), f.max(2)
    saturation = high - low
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    # A spatial edge barrier separates light sleeves from the neutral exterior.
    smooth = cv2.GaussianBlur(gray, (3, 3), .65)
    gx = cv2.Sobel(smooth, cv2.CV_32F, 1, 0, ksize=3) / 8
    gy = cv2.Sobel(smooth, cv2.CV_32F, 0, 1, ksize=3) / 8
    edges = cv2.magnitude(gx, gy) > 4.5
    edges = cv2.morphologyEx(edges.astype(np.uint8), cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8))
    corridor = (low > 218) & (saturation < 24) & (edges == 0)
    exterior = border_region(corridor)
    # Only the large character component is protected as fully opaque; glows,
    # coins and contact shadows use a soft color-distance matte.
    foreground = (~exterior).astype(np.uint8)
    count, labels, stats, _ = cv2.connectedComponentsWithStats(foreground, 8)
    body = np.zeros(low.shape, np.uint8)
    if count > 1:
        largest = 1 + np.argmax(stats[1:, cv2.CC_STAT_AREA])
        body[labels == largest] = 1
        body = cv2.morphologyEx(body, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8))
        body = cv2.erode(body, np.ones((3, 3), np.uint8), iterations=1)
        # The white area BETWEEN the legs is exterior, even if a faint ground
        # shadow joins its outline. Keep the upper hanbok opaque; below the
        # waist only protect paint close to a real colored/dark leg or shoe.
        strong=(saturation>35)|(low<175)
        near_paint=cv2.distanceTransform((~strong).astype(np.uint8),cv2.DIST_L2,3)<=3
        upper=np.arange(low.shape[0])[:,None]<low.shape[0]*.64
        body &= (upper|near_paint).astype(np.uint8)
    border = np.concatenate((f[:8].reshape(-1, 3), f[-8:].reshape(-1, 3), f[:, :8].reshape(-1, 3), f[:, -8:].reshape(-1, 3)))
    background = np.median(border, axis=0)
    delta = np.maximum(background[None, None] - f, 0).max(2)
    chroma = np.clip((saturation - 8) / 38, 0, 1)
    neutral = np.clip((delta - 12) / 75, 0, 1)
    alpha = np.maximum(chroma, neutral)
    alpha[(low > 224) & (saturation < 12)] = 0
    alpha[body != 0] = 1
    # One-pixel antialiasing, without eroding a shirt or changing the character.
    soft_body = cv2.GaussianBlur(body.astype(np.float32), (3, 3), .55)
    alpha = np.maximum(alpha, soft_body)
    alpha[alpha < .035] = 0
    # Alpha only: no grading, desaturation, white-spill RGB correction or crop.
    # Translucent coins and the white hanbok retain decoded source RGB too.
    rgba = np.dstack((rgb, np.round(alpha * 255).astype(np.uint8)))
    return rgba, {'transparentPixels': int((rgba[..., 3] == 0).sum()), 'opaqueBodyPixels': int((body != 0).sum()), 'cornerAlphaMax': int(np.max(np.r_[rgba[:8, :8, 3].ravel(), rgba[:8, -8:, 3].ravel(), rgba[-8:, :8, 3].ravel(), rgba[-8:, -8:, 3].ravel()]))}


def main():
    ffmpeg = shutil.which('ffmpeg')
    if not ffmpeg:
        raise RuntimeError('ffmpeg is required')
    source_hash = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    cap = cv2.VideoCapture(str(SOURCE))
    width, height = int(cap.get(3)), int(cap.get(4))
    fps = cap.get(cv2.CAP_PROP_FPS)
    REVIEW.mkdir(exist_ok=True)
    encoder = subprocess.Popen([ffmpeg, '-y', '-v', 'error', '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', f'{width}x{height}', '-r', str(fps), '-i', 'pipe:0', '-i', str(SOURCE), '-map', '0:v:0', '-map', '1:a:0?', '-c:v', 'libvpx-vp9', '-pix_fmt', 'yuva420p', '-auto-alt-ref', '0', '-crf', '18', '-b:v', '0', '-deadline', 'good', '-cpu-used', '2', '-row-mt', '1', '-c:a', 'libopus', '-b:a', '128k', '-metadata:s:v:0', 'alpha_mode=1', str(STAGED)], stdin=subprocess.PIPE)
    metrics = []
    samples = {0, 24, 48, 72, 90, 100, 120}
    index = 0
    while True:
        ok, frame = cap.read()
        if not ok:
            break
        rgba, measure = matte(frame)
        assert np.array_equal(rgba[..., :3], cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
        metrics.append(measure)
        encoder.stdin.write(rgba.tobytes())
        if index in samples:
            # Video frame evidence, not replacements for existing still assets.
            cv2.imwrite(str(REVIEW / f'frame-{index:03d}.png'), cv2.cvtColor(rgba, cv2.COLOR_RGBA2BGRA))
        if index in (0, 120):
            name = 'money_alpha_start.png' if index == 0 else 'money_alpha_end.png'
            cv2.imwrite(str(ROOT / 'assets' / name), cv2.cvtColor(rgba, cv2.COLOR_RGBA2BGRA))
        index += 1
        if index % 24 == 0:
            print(f'matted {index} frames', flush=True)
    cap.release()
    encoder.stdin.close()
    if encoder.wait() != 0:
        raise RuntimeError('VP9 alpha encoding failed')
    decoded = subprocess.run([ffmpeg, '-v', 'error', '-c:v', 'libvpx-vp9', '-i', str(STAGED), '-frames:v', '1', '-f', 'rawvideo', '-pix_fmt', 'rgba', 'pipe:1'], capture_output=True, check=True).stdout
    first = np.frombuffer(decoded, np.uint8).reshape(height, width, 4)
    STAGED.replace(OUTPUT)
    report = {'source': str(SOURCE), 'sourceSha256': source_hash, 'sourceUnchanged': hashlib.sha256(SOURCE.read_bytes()).hexdigest() == source_hash, 'output': str(OUTPUT), 'outputSha256': hashlib.sha256(OUTPUT.read_bytes()).hexdigest(), 'codec': 'VP9 with encoded alpha, Opus audio', 'frames': index, 'fps': fps, 'duration': index / fps, 'width': width, 'height': height, 'alphaDecodedMinMax': [int(first[..., 3].min()), int(first[..., 3].max())], 'allFrameCornerAlphaMax': max(m['cornerAlphaMax'] for m in metrics), 'transparentFractionMin': min(m['transparentPixels'] for m in metrics) / (width * height), 'frameMetrics': metrics, 'status': 'review derivative; visual QA required, not native Flutter promotion'}
    report.update({'matting': 'alpha only', 'preEncodeRgbMaxDelta': 0,
                   'rgbGrading': False, 'edgeRgbCorrection': False})
    (REVIEW / 'video-alpha-report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({k: v for k, v in report.items() if k != 'frameMetrics'}, ensure_ascii=False), flush=True)


if __name__ == '__main__':
    main()
