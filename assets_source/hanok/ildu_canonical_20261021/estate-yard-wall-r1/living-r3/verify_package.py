"""Verify the delivered render/library linkage; does not judge visual quality."""
import ast
import hashlib
import json
import re
from pathlib import Path

from PIL import Image
import numpy as np

ROOT = Path(__file__).resolve().parent


def sha(path):
    with Path(path).open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


for script in ROOT.glob('*.py'):
    ast.parse(script.read_text(encoding='utf-8'))
verification = json.loads((ROOT / 'verification.json').read_text(encoding='utf-8'))
manifest = json.loads((ROOT / 'render-manifest.json').read_text(encoding='utf-8'))
assert verification['passed']
assert sha(ROOT / verification['library']) == verification['library_sha256'] == manifest['library_sha256']
assert manifest['source_sha256'] == verification['source_sha256']
assert len(verification['bindings']) == 209
comparisons = []
for view in ('detail', 'overview', 'wall', 'full'):
    pair = [next(r for r in manifest['renders'] if r['view'] == view and r['variant'] == v) for v in ('A', 'B')]
    assert pair[0]['camera'] == pair[1]['camera'], view
    arrays = []
    for rec in pair:
        assert sha(ROOT / rec['file']) == rec['sha256'], rec['file']
        image = Image.open(ROOT / rec['file']).convert('RGB')
        assert image.size == (1280, 960)
        assert rec['samples'] == 24 and rec['seed'] == 15
        arrays.append(np.asarray(image).astype(float))
    assert pair[1]['material_library_sha256'] == verification['library_sha256']
    diff = np.abs(arrays[0]-arrays[1])
    metric = {'view': view, 'whole_frame_mean_abs_RGB8': float(diff.mean()),
              'pixels_with_channel_difference_at_least_3_percent': float((diff.max(2) >= 3).mean()*100)}
    if view == 'detail':
        regions = {'clear_middle_soil': (450, 350, 680, 480), 'clear_right_soil': (1010, 710, 1210, 850)}
        metric['diagnostic_soil_regions'] = {}
        for name, (x1, y1, x2, y2) in regions.items():
            metric['diagnostic_soil_regions'][name] = {
                'rectangle_pixels': [x1, y1, x2, y2],
                'mean_abs_RGB8': float(diff[y1:y2, x1:x2].mean())}
    comparisons.append(metric)

html = (ROOT / 'index.html').read_text(encoding='utf-8')
links = re.findall(r'href="([^"#]+)"', html)
for target in links:
    if '://' not in target:
        assert (ROOT / target).is_file(), target
report = {'passed': True, 'source_sha256': manifest['source_sha256'],
          'library_sha256': verification['library_sha256'], 'verified_render_files': 8,
          'same_camera_samples_seed_resolution': True, 'local_static_links_resolve': True,
          'metric_limit': 'Gamma-encoded RGB8 absolute difference. Diagnostic only, not a perceptual or visual quality pass.',
          'comparisons': comparisons, 'visual_review': 'See VISUAL_REVIEW.md; separate from this technical gate.'}
(ROOT / 'package-verification.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(report, ensure_ascii=False, indent=2))
