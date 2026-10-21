"""Snapshot the existing exact-surface exporter; preserve a node for every gate part."""
from pathlib import Path
import hashlib,json
OUT=Path(__file__).resolve().parent
SOURCE=Path(r'C:/dev/hangulsori/ko_lernen_app_worktrees/ildu-r12-app-integration-20261015/tool/hanok_scene')
DEST=OUT/'pbr-pipeline';DEST.mkdir(exist_ok=True)
records=[]
for p in SOURCE.glob('*.py'):
 if p.name.startswith('test_'):continue
 data=p.read_bytes()
 if p.name=='r12_pbr_delivery.py':
  s=data.decode('utf-8')
  old="movable=bool(re.search(r'\\.leaf\\d+(?:\\.|$)',original.name)) or original.parent is not None"
  assert old in s
  s=s.replace(old,"movable=True  # retain each original member for reviewed construction-stage filtering")
  data=s.encode('utf-8')
 dst=DEST/p.name;dst.write_bytes(data)
 records.append(dict(file=p.name,sourceSha256=hashlib.sha256(p.read_bytes()).hexdigest(),snapshotSha256=hashlib.sha256(data).hexdigest(),adaptation='all source members exported separately' if p.name=='r12_pbr_delivery.py' else None))
(DEST/'SOURCE_RECEIPT.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
print('Exact-surface pipeline snapshot',len(records),'modules; app sources unchanged')

