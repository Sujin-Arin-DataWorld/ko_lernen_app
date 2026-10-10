"""Preserve the existing reward implementation before independent visual exploration."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[4]
EXPECTED = Path('C:/dev/hangulsori/ko_lernen_app_worktrees/yeopjeon-c-mockups-20261009').resolve()
if ROOT != EXPECTED:
    raise RuntimeError('Unexpected checkout')
HERE = Path(__file__).resolve().parent
FILES = [
    'tool/yeopjeon_c_mockups/refined.html',
    'tool/yeopjeon_c_mockups/refined.css',
    'tool/yeopjeon_c_mockups/refined.js',
    'tool/yeopjeon_c_mockups/native_preview.dart',
    'lib/screens/sori_stage/yeopjeon_reward_screen.dart',
    'lib/screens/sori_stage/yeopjeon_ildu_house_screen.dart',
    'lib/widgets/sori/yeopjeon_reward_style.dart',
    'lib/widgets/sori/yeopjeon_material.dart',
    'lib/widgets/sori/yeopjeon_credit_badge.dart',
    'lib/widgets/sori/dokkaebi_reward_movie.dart',
    'lib/widgets/sori/yeopjeon_coin_scene.dart',
    'tool/yeopjeon_c_mockups/review-proof/proof-kept-20261010-html-de.jpg',
    'tool/yeopjeon_c_mockups/review-proof/proof-final-native-de.jpg',
    'tool/yeopjeon_c_mockups/review-proof/proof-final-native-en.jpg',
]

entries = []
for relative in FILES:
    source = ROOT / relative
    destination = HERE / 'kept' / relative
    original = source.read_bytes()
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.exists():
        if destination.read_bytes() != original:
            raise RuntimeError(f'Kept version differs: {relative}')
    else:
        shutil.copy2(source, destination)
    if destination.read_bytes() != original:
        raise RuntimeError(f'Archive mismatch: {relative}')
    entries.append({'path': relative, 'sha256': hashlib.sha256(original).hexdigest()})

(HERE / 'kept/KEEP.json').write_text(json.dumps({
    'purpose': 'Preserved implementation before fresh ABC image exploration; runtime files remain unchanged',
    'sourceRoot': str(ROOT),
    'head': '44727c1921b4b7f40748ac0d210d0ca62a094028',
    'files': entries,
}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'kept': str(HERE / 'kept'), 'copied': len(entries), 'verified': 'SHA256 exact'}))
