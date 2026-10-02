"""Build a review inventory from live CSV/Dart, copying original bytes only."""
from pathlib import Path
import csv, hashlib, json, re, shutil, subprocess, sys
from collections import defaultdict, Counter

ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[5]
OUT = Path(__file__).resolve().parents[1]
SOURCE_HEAD = subprocess.check_output(['git','rev-parse','HEAD'], cwd=ROOT, text=True).strip()

def read(relative):
    return (ROOT / relative).read_text(encoding='utf-8-sig')

def dart_string(value):
    return value.replace("\\'", "'").replace('\\n', '\n')

labels = {k: (dart_string(de), dart_string(en)) for k, de, en in re.findall(
    r"'([^']+)'\s*:\s*\(\s*'((?:\\.|[^'])*)',\s*'((?:\\.|[^'])*)'\s*,?\s*\)",
    read('lib/services/vocab_pack_service.dart'))}
allowed_text = read('lib/data/pack_artwork_catalog.dart').split('dedicatedPackIds = <String>{', 1)[1].split('};', 1)[0]
dedicated = set(re.findall(r"'([^']+)'", allowed_text))
manifest = {p['packId']: p for p in json.loads(read('docs/assets/VOCAB_PACK_CARD_MANIFEST.json'))['packs']}
grouped = defaultdict(list)
for row in csv.DictReader(read('assets/data/korean_vocab.csv').splitlines()):
    if row['pack_id']:
        grouped[row['pack_id']].append(row)

copies = {}
def copy(relative):
    source = ROOT / relative
    if not source.is_file():
        raise FileNotFoundError(relative)
    dest = OUT / 'assets' / 'catalog' / source.parent.name / source.name
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, dest)
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    assert digest == hashlib.sha256(dest.read_bytes()).hexdigest()
    copies[relative] = {'source': str(source), 'copy': dest.relative_to(OUT).as_posix(), 'bytes': source.stat().st_size, 'sha256': digest}
    return dest.relative_to(OUT).as_posix(), digest

packs = []
missing_labels, stale_hashes = [], []
for pack_id, rows in grouped.items():
    m = manifest[pack_id]
    relative = f'assets/illustrations/packs/{pack_id if pack_id in dedicated else m["rewardMotif"]}.webp'
    # The catalog's runtime allowlist is authoritative, not a historical note.
    assert relative == m['primaryAsset'], (pack_id, relative, m['primaryAsset'])
    asset, digest = copy(relative)
    if digest != m['sha256']:
        stale_hashes.append(pack_id)
    base = re.sub(r'_\d+$', '', pack_id)
    suffix = pack_id[len(base):].lstrip('_')
    de, en = labels.get(base, (pack_id, pack_id))
    if base not in labels:
        missing_labels.append(pack_id)
    rows.sort(key=lambda r: int(r['pack_order']))
    samples = [{'ko': r['korean'], 'de': r['german'], 'en': r['english'], 'id': r['id']} for r in rows]
    packs.append({'id': pack_id, 'level': rows[0]['level'], 'title': {'de': de + (f' ({suffix})' if suffix else ''), 'en': en + (f' ({suffix})' if suffix else ''), 'ko': ' · '.join([r['korean'] for r in rows[:2]]) + (f' ({suffix})' if suffix else '')}, 'asset': asset, 'source': relative, 'sha256': digest, 'dedicated': pack_id in dedicated, 'count': len(rows), 'samples': samples, 'subject': m['subjectKo']})

activities = []
catalog = read('lib/data/sori_activity_catalog.dart').split('soriActivityCatalog = List.unmodifiable([', 1)[1]
localized = {lang: json.loads(read(f'lib/l10n/app_{lang}.arb')) for lang in ('de', 'en')}
def actual_copy(lang, key, activity_id, fallback):
    # The live ICU selects contain plain strings for these two activity keys.
    choices = dict(re.findall(r'(\w+)\{([^{}]*)\}', localized[lang][key]))
    return choices.get(activity_id, fallback)
for block in re.split(r'\n  _entry\(', catalog)[1:]:
    def field(key):
        match = re.search(rf"\b{key}:\s*'((?:\\.|[^'])*)'", block)
        return dart_string(match.group(1)) if match else None
    activity_id = field('id')
    if not activity_id:
        continue
    asset, digest = copy(f'assets/illustrations/activities/{activity_id}.webp')
    section = re.search(r'learnSection: SoriLearnSection\.(\w+)', block)
    alias_block = re.search(r'detailRouteAliases: const(?: <String>)?\s*\[([^\]]*)\]', block)
    aliases = re.findall(r"'([^']+)'", alias_block.group(1)) if alias_block else []
    activities.append({'id': activity_id, 'tab': 'learn' if 'tab: SoriStageTab.learn' in block else 'games', 'title': {lang: actual_copy(lang, 'soriStageActivityTitle', activity_id, field(lang)) for lang in ('de','en')}, 'description': {lang: actual_copy(lang, 'soriStageActivityDescription', activity_id, field('description'+lang.title())) for lang in ('de','en')}, 'route': field('route'), 'detailRouteAliases': aliases, 'minutes': int(re.search(r'minutes: (\d+)', block).group(1)), 'section': section.group(1) if section else 'all', 'asset': asset, 'sha256': digest})

assert len(packs) == 252 and len(dedicated) == 184 and len(activities) == 21
assert not missing_labels, missing_labels
order_source = read('lib/services/vocab_pack_service.dart').split('packOrderInLevel =', 1)[1]
order = {k: int(n) for k, n in re.findall(r"'([^']+)'\s*:\s*(\d+)", order_source)}
packs.sort(key=lambda p: (p['level'], order.get(re.sub(r'_\d+$', '', p['id']), 99), int(re.search(r'_(\d+)$', p['id']).group(1)) if re.search(r'_(\d+)$', p['id']) else 0))
assert subprocess.check_output(['git','rev-parse','HEAD'], cwd=ROOT, text=True).strip() == SOURCE_HEAD, 'Main changed during inventory read; run again.'
source_files = ['assets/data/korean_vocab.csv','lib/data/sori_activity_catalog.dart','lib/data/pack_artwork_catalog.dart','lib/services/vocab_pack_service.dart','lib/l10n/app_de.arb','lib/l10n/app_en.arb']
inventory = {'date': '2026-10-02', 'head': SOURCE_HEAD, 'sourceCheckout': str(ROOT), 'sourceHashes': {p: hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in source_files}, 'scope': 'Review only. Original artwork copied byte-for-byte. No account progress or rewards.', 'stats': {'packs': len(packs), 'dedicated': len(dedicated), 'levels': dict(sorted(Counter(p['level'] for p in packs).items())), 'activities': len(activities), 'learn': sum(a['tab']=='learn' for a in activities), 'games': sum(a['tab']=='games' for a in activities), 'uniqueCopiedFiles': len(copies)}, 'packs': packs, 'activities': activities}
(OUT / 'catalog-data.json').write_text(json.dumps(inventory, ensure_ascii=False, indent=2), encoding='utf-8')
(OUT / 'qa' / 'catalog-source-copies.json').write_text(json.dumps({'copies': list(copies.values()), 'historicalManifestHashDifferences': stale_hashes, 'allCopiesMatchLiveSource': True}, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'stats': inventory['stats'], 'missingTitles': missing_labels, 'historicalHashDifferences': stale_hashes, 'copiedBytes': sum(c['bytes'] for c in copies.values())}, ensure_ascii=False))
