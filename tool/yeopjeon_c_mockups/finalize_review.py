"""Preserve prior experiments and make the new critique proposal the entry page."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parent
archive = ROOT / 'design' / 'rejected'
archive.mkdir(exist_ok=True)
old_index = archive / 'legacy-index.html'
if not old_index.exists():
    shutil.copy2(ROOT / 'index.html', old_index)
for name in ['estate-variants.js', 'estate-variants.css']:
    source = ROOT / name
    target = archive / name
    if source.exists():
        if not source.resolve().is_relative_to(ROOT) or not target.resolve().is_relative_to(ROOT):
            raise ValueError('Archive target escaped the review folder')
        shutil.move(str(source), str(target))
(ROOT / 'index.html').write_text('''<!doctype html><html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="refresh" content="0;url=refined.html"><title>Hangul Sori · 차분한 C안</title></head><body><a href="refined.html">새 정리안 열기</a><script>location.replace('refined.html'+location.search);</script></body></html>''', encoding='utf-8')
manifest = ROOT / 'asset-provenance.json'
rows = json.loads(manifest.read_text(encoding='utf-8'))
for row in rows:
    if row['file'] == 'design/secret-board.png':
        row['use'] = 'user_rejected_cloth_question_mark_do_not_copy'
ab_file = ROOT / 'design/ab-board.png'
if not any(row['file'] == 'design/ab-board.png' for row in rows):
    rows.append({'file':'design/ab-board.png','source':'C:/Users/vjinn/.codex/generated_images/01a12252-a369-74c1-a37d-25e1f0933b5d/exec-07f95974-1ed0-4159-bbad-f77f0acdebaa.png','sha256':hashlib.sha256(ab_file.read_bytes()).hexdigest(),'unchanged':True,'use':'user_rejected_excessive_decoration_do_not_copy'})
manifest.write_text(json.dumps(rows, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print(json.dumps({'entry':'refined.html','priorArtPreserved':True,'rejectedImplementationConnected':False,'provenanceRows':len(rows)}))
