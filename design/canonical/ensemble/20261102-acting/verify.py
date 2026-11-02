"""Validate portable canonical references and byte-preserved PNG delivery."""
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CANONICAL = ROOT.parents[2]


def read(name):
    return json.loads((ROOT / name).read_text(encoding='utf-8'))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify_references(node):
    count = 0
    if isinstance(node, dict):
        if isinstance(node.get('path'), str) and node.get('sha256'):
            path = (ROOT / node['path']).resolve()
            assert path.is_relative_to(CANONICAL), path
            assert path.is_file() and digest(path) == node['sha256'], path
            count += 1
        count += sum(verify_references(value) for value in node.values())
    elif isinstance(node, list):
        count += sum(verify_references(value) for value in node)
    return count


profile = read('CHARACTER_LOCK.json')
approval = read('CANONICAL_APPROVAL.json')
assert digest(ROOT / 'CHARACTER_LOCK.json') == approval['profile_sha256']
assert approval['acting_model_sheets'] == 9 and approval['selected_images'] == 13
assert not approval['runtime_integrated'] and not approval['metric_compliance_verified']
references = verify_references(profile)
images = read('ASSET_MANIFEST.json')['images']
assert len(images) == 13
assert {item['path'] for item in images} == {path.relative_to(ROOT).as_posix() for path in (ROOT/'assets').rglob('*.png')}
for item in images:
    path = ROOT / item['path']
    assert digest(path) == item['sha256'] and path.stat().st_size == item['bytes']
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    width, height, depth, color = struct.unpack('>IIBB', data[16:26])
    assert [width, height] == item['size_px'] and depth == 8
    if item['mode'] == 'RGBA':
        assert color == 6
        assert item['alpha_extrema'][0] == 0 and item['alpha_extrema'][1] >= 254
    else:
        assert item['path'] == 'assets/dokkaebi/source-relaxed-standing.png'
        assert item['mode'] == 'RGB' and color == 2 and item['alpha_extrema'] is None
        assert not item['runtime_registered']
for name, actor in read('ACTING_CANON.json')['characters'].items():
    assert len(actor['expressions']) == 8 and len(actor['poses']) == 6, name
    assert len({v['id'] for v in actor['expressions'] + actor['poses']}) == 14
assert profile['characters']['joy']['fixed_counts'] == {'wings': 2, 'legs': 2, 'tails': 1, 'emblem_curls': 3}
assert profile['characters']['dokkaebi']['fixed_counts']['horns'] == 2
previous = json.loads((ROOT.parent / '20261102/CHARACTER_LOCK.json').read_text(encoding='utf-8'))
for name, old in previous['characters'].items():
    for key in ['body', 'base_body', 'divine_scale', 'fixed_counts', 'fixed_identity']:
        if key in old:
            assert profile['characters'][name][key] == old[key], (name, key)
print(json.dumps({'images': len(images), 'profile_reference_hashes': references,
                  'approved_sheets': 9, 'expressions': 24, 'poses': 18,
                  'prior_identity_and_dimension_targets_preserved': True,
                  'png_header_and_byte_hashes_verified': True,
                  'pixel_metric_or_device_QA': False}, ensure_ascii=False))
