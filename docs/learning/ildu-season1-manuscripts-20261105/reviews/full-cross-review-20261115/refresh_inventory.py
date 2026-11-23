"""Refresh exact manuscript hashes; do not infer editorial approval."""
import hashlib,json
from pathlib import Path
from datetime import datetime,timezone
B=Path(__file__).resolve().parents[2]
p=B/'DRAFT_INVENTORY.json'
d=json.loads(p.read_text(encoding='utf-8'))
for row in d['units']:
    row['draftSha256']=hashlib.sha256((B/'manuscripts'/(row['id']+'.md')).read_bytes()).hexdigest()
d['updatedAt']=datetime.now(timezone.utc).date().isoformat()
content=json.dumps(d,ensure_ascii=False,indent=2)+'\n'
previous=p.read_bytes()
if previous.count(b'\r\n') and previous.count(b'\r\n')==previous.count(b'\n'):
    content=content.replace('\n','\r\n')
t=p.with_suffix('.json.tmp');t.write_bytes(content.encode('utf-8'))
assert json.loads(t.read_text(encoding='utf-8'))==d
t.replace(p)
print('Updated',len(d['units']),'manuscript hashes')
