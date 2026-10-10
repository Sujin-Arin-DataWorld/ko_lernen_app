"""Copy authorized design assets unchanged; record SHA256 provenance."""
from pathlib import Path
import hashlib
import json
import shutil

HERE = Path(__file__).resolve().parent
CANDIDATE = Path('C:/dev/hangulsori/ko_lernen_app_worktrees/canonical-reward-onboarding-20261004')
MAIN = Path('C:/dev/hangulsori/ko_lernen_app')
AUDIT = Path('C:/dev/hangulsori/_codex_artifacts/yeopjeon-c-design-20261009')
COPY = {
    'material_atlas.png': CANDIDATE / 'assets/illustrations/concept_c/material_atlas.png',
    'garden_frame.png': CANDIDATE / 'assets/illustrations/concept_c/garden_frame.png',
    'dokkaebi_ready.png': CANDIDATE / 'assets/illustrations/tactile/dokkaebi/dokkaebi_ready.png',
    'dokkaebi_celebrate.png': CANDIDATE / 'assets/illustrations/tactile/dokkaebi/dokkaebi_celebrate.png',
    'dokkaebi_inviting.png': CANDIDATE / 'assets/illustrations/tactile/dokkaebi/dokkaebi_inviting.png',
    'yupjeon.png': MAIN / 'assets/illustrations/mascot/yupjeon.png',
    'bok.png': MAIN / 'assets/illustrations/mascot/bok.png',
    'coin.png': CANDIDATE / 'assets/illustrations/concept_c/coin_v2.png',
    'book.png': CANDIDATE / 'assets/illustrations/concept_c/book_v2.png',
    'arrow.png': CANDIDATE / 'assets/illustrations/concept_c/arrow_v2.png',
    'cloud.png': CANDIDATE / 'assets/illustrations/concept_c/cloud_v2.png',
    'stage_07.png': CANDIDATE / 'assets/illustrations/personal_hanok_v3/sarangchae/stage_07_purlins.png',
    'stage_08.png': CANDIDATE / 'assets/illustrations/personal_hanok_v3/sarangchae/stage_08_rafters.png',
    'stage_16.png': CANDIDATE / 'assets/illustrations/personal_hanok_v3/sarangchae/stage_16_complete.png',
    'making_money.mp4': Path('C:/Users/vjinn/.codex/generated_images/도깨비/making_money.mp4'),
    'money_start.png': AUDIT / 'inspection/videos/src-407-0.png',
    'money_end.png': AUDIT / 'inspection/videos/src-407-7.png',
    'Paperlogy-Regular.ttf': CANDIDATE / 'assets/fonts/Paperlogy/Paperlogy-Regular.ttf',
    'Paperlogy-SemiBold.ttf': CANDIDATE / 'assets/fonts/Paperlogy/Paperlogy-SemiBold.ttf',
    'Paperlogy-Bold.ttf': CANDIDATE / 'assets/fonts/Paperlogy/Paperlogy-Bold.ttf',
    'NotoSansKR.ttf': CANDIDATE / 'assets/fonts/NotoSansKR/NotoSansKR-Variable.ttf',
    'Paperlogy-OFL.txt': CANDIDATE / 'assets/fonts/Paperlogy/OFL.txt',
    'NotoSansKR-OFL.txt': CANDIDATE / 'assets/fonts/NotoSansKR/OFL.txt',
    'brass_cta.png': Path('C:/Users/vjinn/.codex/generated_images/01a10981-52b8-7171-9152-7c911290e994/exec-432d8b55-1b63-49d7-9dc8-1d80ced6f272.png'),
    'cta_atlas.png': Path('C:/Users/vjinn/.codex/generated_images/01a120e1-8621-77f1-b07c-f6499ac0829e/exec-13f11698-1207-48f1-a3fe-04e6253e57cb.png'),
}

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

if __name__ == '__main__':
    target = HERE / 'assets'
    target.mkdir(parents=True, exist_ok=True)
    records = []
    for name, source in COPY.items():
        dest = (HERE / 'legacy-reference' / name) if name.startswith('stage_') else target / name
        dest.parent.mkdir(exist_ok=True)
        shutil.copy2(source, dest)
        records.append({'file': str(dest.relative_to(HERE)).replace('\\','/'), 'source': str(source), 'sha256': sha(source), 'unchanged': sha(source) == sha(dest), 'use': 'reference_only_do_not_connect' if name.startswith('stage_') else 'active_or_source_reference'})
    previous = HERE / 'asset-provenance.json'
    if previous.exists():
        original = json.loads(previous.read_text(encoding='utf-8'))
        updated = {r['file'] for r in records}
        records.extend(r for r in original if r['file'] not in updated and not r['file'].startswith('assets/stage_'))
    previous.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding='utf-8')
    catalog = CANDIDATE / 'assets/data/smalltalk_lessons.json'
    lesson = next(x for x in json.loads(catalog.read_text(encoding='utf-8'))['lessons'] if x['id'] == 'smalltalk.a1.weather.outside')
    (HERE / 'content-demo.json').write_text(json.dumps({'id': lesson['id'], 'title': lesson['title'], 'questions': len(lesson['questions']), 'source': str(catalog), 'sourceSha256': sha(catalog)}, ensure_ascii=False, indent=2), encoding='utf-8')
    audit_target = HERE / 'audit'
    audit_target.mkdir(exist_ok=True)
    for name in ['source-image-inventory.json', 'source-video-inventory.json', 'skill-inventory.json', 'installed-plugin-list.json', 'referenced-audit-items.json']:
        if not (audit_target / name).exists():
            shutil.copy2(AUDIT / name, audit_target / name)
    inspection = audit_target / 'inspection'
    inspection.mkdir(exist_ok=True)
    for source in (AUDIT / 'inspection').glob('*.jpg'):
        shutil.copy2(source, inspection / source.name)
    for source in (AUDIT / 'inspection/videos').glob('*-sheet.jpg'):
        shutil.copy2(source, inspection / source.name)
    print(json.dumps({'assets': len(records), 'byte_identical': all(r['unchanged'] for r in records), 'output': str(HERE)}, ensure_ascii=False))
