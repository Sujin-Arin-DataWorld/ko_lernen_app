"""Check actual delivered renders against source, material and camera receipts."""
import hashlib
import json
from pathlib import Path
from PIL import Image

OUT = Path(__file__).resolve().parent


def sha(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream,'sha256').hexdigest()


report = json.loads((OUT/'verification.json').read_text(encoding='utf-8'))
manifest = json.loads((OUT/'render-manifest.json').read_text(encoding='utf-8'))
assert report['passed'] and report['non_target_bindings_equal']
assert report['geometry_uv_transforms_equal'] and report['r3_wall_and_garden_shaders_unchanged']
assert len(report['bindings']) == 2
assert sha(OUT/report['library']) == report['library_sha256'] == manifest['library_sha256']
assert sha(OUT/'ground-scope.json') == report['ground_scope_sha256']
assert sha(OUT/'soil_patch.py') == report['soil_code_sha256']
images = []
for view in ('full','overview','detail'):
    pair = [next(r for r in manifest['renders'] if r['view']==view and r['variant']==v) for v in ('A','B')]
    assert all(pair[0][key] == pair[1][key] for key in ('camera','samples','seed','resolution'))
    for rec in pair:
        path = OUT/rec['file']
        assert sha(path) == rec['sha256']
        with Image.open(path) as im:
            assert im.size == tuple(rec['resolution']) == (1280,960)
            if view == 'full':
                im.resize((477,358),Image.Resampling.LANCZOS).save(OUT/('full-'+rec['variant']+'-477.png'))
        images.append(rec['file'])
result = dict(passed=True,images=images,same_camera_samples_seed_resolution=True,
    render_library_sha256=report['library_sha256'],only_two_soil_slots_changed=True,
    geometry_uv_transforms_equal=True,r3_wall_garden_shaders_unchanged=True,
    visual_acceptance='See VISUAL_REVIEW.md; integrity checks alone do not establish naturalness',
    app_integrated=False)
(OUT/'package-verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print('PACKAGE PASS',len(images),'images')
