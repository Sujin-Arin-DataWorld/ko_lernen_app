"""Promote whole generated scene masters after bounded designer art review."""
import hashlib
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GENERATED = Path('C:/Users/vjinn/.codex/generated_images')
VISUAL = GENERATED / '01a14ebc-f7b4-7661-83ad-0489170ce757'
MATERIAL = GENERATED / '01a14ebd-78e5-7e91-b475-afb8a438d696'
SOURCES = {
    'path-scene': VISUAL / 'exec-2ad0562d-9a91-4ad7-a8ba-fc0fbd4ba4a1.png',
    'sound-scene': VISUAL / 'exec-dd1e7576-1d70-4a29-9aa3-dc3ba51a49f9.png',
    'games-scene': VISUAL / 'exec-5ba0166c-9af9-472a-8ff1-1a9afba3b7d2.png',
    'scholar-scene': MATERIAL / 'exec-3f7646ad-ac49-49a2-a169-daeada34dee5.png',
    'hanok-scene': MATERIAL / 'exec-49e625e0-4fd1-43e7-bd36-bfb5defce134.png',
    'hanok-tools': MATERIAL / 'exec-26c09b49-56ca-4f4e-89df-433b88e7c308.png',
}
manifest_path = ROOT / 'tool/einleitung_generated_assets.json'
manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
for name, source in SOURCES.items():
    destination = ROOT / 'assets/illustrations/einleitung_generated' / f'intro-{name}.png'
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    shutil.copyfile(source, destination)
    assert hashlib.sha256(destination.read_bytes()).hexdigest() == digest
    record = next(x for x in manifest['files'] if x['name'] == f'intro-{name}')
    record.update(source=str(source), sha256=digest,
                  generation='Built-in image_gen; complete independent master; no reference screenshot crop',
                  designReview='Designer scene identity and major prop PASS; final native render review remains separate')
manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'copiedWholeMasters': len(SOURCES), 'exactSha256': True}))
