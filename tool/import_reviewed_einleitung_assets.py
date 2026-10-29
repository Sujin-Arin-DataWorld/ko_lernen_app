"""Copy whole designer-reviewed masters; retain originals and verify exact bytes."""
import hashlib
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MASTERS = Path('C:/Users/vjinn/.codex/generated_images/01a14d68-68e9-78c3-8e50-146dae12bb6f')
DEST = ROOT / 'assets/illustrations/einleitung_generated'
review = json.loads((ROOT / 'tool/einleitung_material_review.json').read_text(encoding='utf-8'))
files = {
    'jade-surface': 'exec-547d1ef6-e713-451e-934f-06ce5810448a.png',
    'gold-button': 'exec-4ff42b89-6503-4479-a5c6-5b0de7247464.png',
    'taego-header': 'exec-8bf63e01-845b-4c8c-ac40-7a466231d852.png',
    'plum-branch': 'exec-cbf6f8de-50ae-4911-b22e-7163f34a4c76.png',
    'header-right-leaves': 'exec-d4d18c6f-e3df-4eac-90ee-5ac093291aba.png',
    'interest-travel': 'exec-3af92f12-22ce-41c1-9ec9-b3912158cd0d.png',
    'interest-culture': 'exec-006956a7-b66a-4b10-893e-2991f5146358.png',
    'interest-study': 'exec-4c84be44-3b74-421e-9f70-a949abd3b11f.png',
    'interest-kcontent': 'exec-4cb45d7f-3958-4b29-9d64-2ddaf5c2eb3c.png',
    'paper-footer': 'exec-64f751ec-661c-4460-8154-5c7314cc537b.png',
}
mapping = review['badgeFamilyReview']['mapping']
sources = {name: MASTERS / filename for name, filename in files.items()}
sources.update({'level-' + level.lower(): Path(info['file']) for level, info in mapping.items()})
temp = Path('C:/Users/vjinn/AppData/Local/Temp')
sources['check'] = temp / 'codex-clipboard-6a0e5bf7-f658-4f31-9d59-a59231d7a927.png'
sources['level-blank'] = temp / 'codex-clipboard-ea7d2a36-4041-48dc-8792-d0ead0f1eb88.png'
for source in sources.values():
    if not source.is_file():
        raise FileNotFoundError(source)
records = []
for name, source in sources.items():
    target = DEST / ('intro-' + name + '.png')
    source_hash = hashlib.sha256(source.read_bytes()).hexdigest()
    shutil.copyfile(source, target)
    assert hashlib.sha256(target.read_bytes()).hexdigest() == source_hash
    records.append({'name': 'intro-' + name, 'source': str(source), 'asset': target.relative_to(ROOT).as_posix(), 'sha256': source_hash, 'generation': 'User-provided original PNG' if name in ['check', 'level-blank'] else 'Built-in image_gen; independent whole asset; no source screenshot crop', 'designReview': 'First-unit designer PASS v7; runtime verification pending'})
manifest_path = ROOT / 'tool/einleitung_generated_assets.json'
manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
replacements = {record['name']: record for record in records}
manifest['files'] = [replacements.pop(record['name'], record) for record in manifest['files']]
manifest['files'].extend(replacements.values())
manifest['status'] = 'First-unit v7 assets staged as identical whole bytes after visual/material/UX review; remaining scenes and Flutter verification pending'
manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
(ROOT / 'tool/einleitung_reviewed_asset_geometry.json').write_text(json.dumps({'medals': mapping, 'check': {'canvas': [1254,1254], 'body': [171,169,1079,1071], 'visibleWidth': 34}, 'gold': {'canvas': [2170,725], 'body': [73,205,2102,491], 'visibleWidth': 370, 'visibleHeight': 52.15377033021193}, 'jadeGlaze': {'color': '#094838', 'opacity': 0.60}}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'copied': len(records), 'verifiedExactSha256': True, 'sourcesPreserved': True}))
