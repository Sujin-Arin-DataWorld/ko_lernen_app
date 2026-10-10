"""Export the approved alpha movie frames for Flutter's portable image codec.

Alpha-only RGBA is read directly from the original MP4, avoiding a lossy WebM
round trip. Animated WebP keeps all 121 frames; original audio is exported
separately for opt-in playback. No source asset is overwritten.
"""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import cv2
import numpy as np
from PIL import Image
from transparent_video import matte

PACKAGE = Path(__file__).resolve().parent
REPO = PACKAGE.parent.parent
OUT = REPO / 'assets/animations/rewards'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    ffmpeg = shutil.which('ffmpeg')
    if not ffmpeg:
        raise RuntimeError('ffmpeg is required')
    OUT.mkdir(parents=True, exist_ok=True)
    source = PACKAGE / 'assets/making_money_alpha.webm'
    original = PACKAGE / 'assets/making_money.mp4'
    inputs = {str(p): sha(p) for p in [source, original]}
    movie = OUT / 'making_money.webp'
    capture = cv2.VideoCapture(str(original))
    encoder = subprocess.Popen([ffmpeg, '-y', '-v', 'error', '-f', 'rawvideo',
                    '-pix_fmt', 'rgba', '-s', '960x960', '-r', '24', '-i', 'pipe:0',
                    '-an', '-c:v', 'libwebp_anim', '-lossless', '1',
                    '-compression_level', '6', '-loop', '1', str(movie)], stdin=subprocess.PIPE)
    while True:
        ok, frame = capture.read()
        if not ok:
            break
        rgba, _ = matte(frame)
        encoder.stdin.write(rgba.tobytes())
    capture.release()
    encoder.stdin.close()
    if encoder.wait() != 0:
        raise RuntimeError('lossless source RGBA encoding failed')
    subprocess.run([ffmpeg, '-y', '-v', 'error', '-i', str(original),
                    '-vn', '-c:a', 'libmp3lame', '-b:a', '128k',
                    str(OUT / 'making_money.mp3')], check=True)
    for source_name, target in [('money_alpha_start.png', 'making_money_start.png'),
                                ('money_alpha_end.png', 'making_money_end.png'),
                                ('coin.png', 'coin.png'), ('cloud.png', 'cloud.png'),
                                ('yupjeon.png', 'yupjeon.png'),
                                ('material_atlas.png', 'material_atlas.png'),
                                ('coin_face.png', 'coin_face.png'),
                                ('brand_seal.png', 'brand_seal.png'),
                                ('cta_atlas.png', 'cta_atlas.png'),
                                ('paper_texture.png', 'paper_texture.png'),
                                ('jade_texture.png', 'jade_texture.png'),
                                ('arrow.png', 'arrow.png')]:
        shutil.copyfile(PACKAGE / 'assets' / source_name, OUT / target)
    image = Image.open(movie)
    assert image.size == (960, 960) and image.n_frames == 121
    durations = []
    corners = []
    capture = cv2.VideoCapture(str(original))
    visible_rgb_delta = 0
    for frame in range(image.n_frames):
        image.seek(frame)
        rgba = image.convert('RGBA')
        ok, source_frame = capture.read()
        assert ok
        expected, _ = matte(source_frame)
        actual = np.asarray(rgba)
        visible = expected[..., 3] > 0
        visible_rgb_delta = max(visible_rgb_delta, int(np.abs(
            actual[..., :3].astype(np.int16)[visible] -
            expected[..., :3].astype(np.int16)[visible]).max()))
        durations.append(image.info.get('duration', 0))
        corners.append(max(rgba.getpixel(p)[3] for p in [(0, 0), (959, 0), (0, 959), (959, 959)]))
    capture.release()
    assert max(corners) == 0
    assert visible_rgb_delta == 0, f'visible RGB changed by {visible_rgb_delta}'
    assert all(sha(Path(path)) == value for path, value in inputs.items())
    report = {'schemaVersion': 1, 'width': 960, 'height': 960, 'frames': 121,
              'fps': 24, 'durationMs': sum(durations), 'frameDurationsMs': durations,
              'allFrameCornerAlphaMax': max(corners), 'lossless': True,
              'crop': False, 'sourceUnchanged': True, 'sourceHashes': inputs,
              'inputAuthority': 'original MP4 decoded RGB + alpha-only matte',
              'visibleRgbMaxDeltaAll121Frames': visible_rgb_delta,
              'files': [{'file': p.relative_to(REPO).as_posix(), 'bytes': p.stat().st_size,
                         'sha256': sha(p)} for p in sorted(OUT.iterdir()) if p.is_file()]}
    (PACKAGE / 'media-review/flutter-media-report.json').write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: v for k, v in report.items() if k not in ['files', 'frameDurationsMs']}, ensure_ascii=False))

if __name__ == '__main__':
    main()
