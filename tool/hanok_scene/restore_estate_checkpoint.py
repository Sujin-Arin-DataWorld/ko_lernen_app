"""Reassemble the committed source archive into a separately named output.

Usage: python tool/hanok_scene/restore_estate_checkpoint.py OUTPUT.zip
Never overwrites a file or changes the live Blender scene.
"""
from pathlib import Path
import hashlib
import json
import sys
import zipfile

root = Path(__file__).resolve().parents[2]
checkpoint = root / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court/checkpoint'
report = json.loads((checkpoint / 'source-checkpoint.json').read_text(encoding='utf8'))
if len(sys.argv) != 2:
    raise SystemExit(__doc__)
target = Path(sys.argv[1]).resolve()
assert not target.exists(), 'Choose a new output path; existing files are preserved'
digest = hashlib.sha256()
with target.open('xb') as output:
    for row in report['parts']:
        path = checkpoint / row['file']
        chunk = path.read_bytes()
        assert len(chunk) == row['bytes'] and hashlib.sha256(chunk).hexdigest() == row['sha256']
        digest.update(chunk)
        output.write(chunk)
assert digest.hexdigest() == report['sha256']
with zipfile.ZipFile(target) as archive:
    assert archive.testzip() is None
print('Verified source archive:', target)
