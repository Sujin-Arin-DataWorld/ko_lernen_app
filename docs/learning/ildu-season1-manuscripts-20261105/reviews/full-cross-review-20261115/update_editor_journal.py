"""Record explicitly completed editorial batches and current manuscript hashes."""
import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

HERE=Path(__file__).resolve().parent
BOOK=HERE.parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('bands',nargs='*')
args=parser.parse_args()
p=HERE/'EDITOR_DECISIONS.json'
d=json.loads(p.read_text(encoding='utf-8'))
known={f['id'] for f in d['findingDecisions']}
for band in args.bands:
    for role in ('ko-en','ko-de','curriculum'):
        report=HERE/role/(band+'.json')
        assert report.exists(),str(report)
        for f in json.loads(report.read_text(encoding='utf-8')).get('findings',[]):
            if f['id'] in known:
                continue
            decision={'id':f['id'],'unitId':f['unitId'],'severity':f['severity'],
                'decision':'accepted','state':'applied_pending_final_review',
                'reason':f['problem']}
            if f['id']=='EN-A22-01':
                decision['decision']='accepted_with_alternative_fix'
                decision['editorNote']='Use the curriculum reviewer’s first-person Hyuna role switch; do not add unnecessary B1 indirect-quotation support to this A2 production task.'
            d['findingDecisions'].append(decision)
            known.add(f['id'])
baseline=json.loads((HERE/'BASELINE.json').read_text(encoding='utf-8'))['manuscripts']
d['changedUnits']=[]
for path in sorted((BOOK/'manuscripts').glob('*.md')):
    h=hashlib.sha256(path.read_bytes()).hexdigest()
    if h!=baseline[path.stem]:
        d['changedUnits'].append({'unitId':path.stem,'beforeSha256':baseline[path.stem],
            'afterSha256':h,'state':'awaiting independent final reread'})
d['updatedUtc']=datetime.now(timezone.utc).isoformat()
t=p.with_suffix('.json.tmp')
t.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='')
assert json.loads(t.read_text(encoding='utf-8'))==d
t.replace(p)
print(json.dumps({'changedUnits':len(d['changedUnits']),'findingDecisions':len(d['findingDecisions'])}))
