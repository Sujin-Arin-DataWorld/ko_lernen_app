"""Copy review sources byte-for-byte. Does not edit or recompress images."""
import hashlib
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parents[3]
PREVIOUS = ROOT.parent
GENERATED = Path('C:/Users/vjinn/.codex/generated_images/01a0fcf4-681f-7c21-8c3a-bd5dff48c05f')
OBJECTS = [
    ('coffee', 'exec-82b468a4-702c-4e11-ac57-a90bdc8a1a17.png', 'exec-7478cfad-6e5e-43c3-b8b6-913fe2843a4d.png'),
    ('speaker', 'exec-784a1bcf-dda0-4ffe-9f38-6263d04f1cc1.png', 'exec-16120da9-7798-4680-b471-e857c21649ac.png'),
    ('book', 'exec-6f28c175-6361-4fad-b2d3-2c520504fb8d.png', 'exec-d6ad6c67-364d-4e91-8fc1-b11ad358ad89.png'),
    ('conversation', 'exec-0eac2606-7366-4ea6-a399-f49e1497c801.png', 'exec-ba48a955-d968-4282-af42-5c83f47f437c.png'),
]

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

copies = []
def copy(source, relative):
    destination = ROOT / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    assert digest(source) == digest(destination)
    copies.append({'source': str(source), 'path': relative, 'bytes': destination.stat().st_size, 'sha256': digest(destination)})

for name, selected, previous in OBJECTS:
    copy(GENERATED / selected, f'assets/{name}.png')
    copy(GENERATED / previous, f'iterations/{name}-initial.png')
for source, target in [
    (REPO / 'assets/fonts/NotoSansKR/NotoSansKR-Variable.ttf', 'assets/NotoSansKR-Variable.ttf'),
    (REPO / 'assets/fonts/NotoSansKR/OFL.txt', 'assets/OFL.txt'),
    (REPO / 'assets/illustrations/mascot/tiger_front.png', 'assets/tiger.png'),
    (REPO / 'assets/illustrations/hanok/estate_overview.webp', 'assets/hanok.webp'),
    (PREVIOUS / 'characters/sujin_v2_short_bob.png', 'assets/sujin.png'),
    (PREVIOUS / 'characters/christian.png', 'assets/christian.png'),
    (PREVIOUS / 'references/current_today_390.png', 'assets/current-today.png'),
    (PREVIOUS / 'originals/a1_greetings_2_original.webp', 'assets/a1_greetings_2-original.webp'),
    (PREVIOUS / 'originals/A1Arrival_original.webp', 'assets/A1Arrival-original.webp'),
    (PREVIOUS / 'cards/a1_greetings_2_3d.png', 'assets/a1_greetings_2-3d.png'),
    (PREVIOUS / 'cards/A1Arrival_3d.png', 'assets/A1Arrival-3d.png'),
]:
    copy(source, target)
(ROOT / 'screens').mkdir(exist_ok=True)
(ROOT / 'qa' / 'source_copies.json').write_text(json.dumps(copies, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'copied': len(copies), 'root': str(ROOT), 'imagesEdited': False}))
