"""Close editorial decisions only when all roles passed the exact current text.

Run validate_package.py first. This does not create any reviewer verdict and
does not close unresolved/stale findings merely because an edit was made.
"""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json

HERE=Path(__file__).resolve().parent
BOOK=HERE.parents[1]
def read(p):
    return json.loads(p.read_text(encoding='utf-8'))
evidence=read(HERE/'STRUCTURE_AND_PROGRESS.json')
assert not evidence['problems'],evidence['problems']
journal=read(HERE/'EDITOR_DECISIONS.json')
def proof(key):
    if key=='COMMON':
        combined=[]
        for name in ('README.md','AUTHORING_BRIEF.md','READER_INTRODUCTION.md',
                     'SERIES_EDITORIAL_MAP.md','TERM_AND_TRANSLATION_NOTES.md','CURRICULUM_REUSE_NOTES.md'):
            refs=proof(name)
            if not refs:
                return None
            combined.extend({**ref,'document':name} for ref in refs)
        return combined
    common=key.endswith('.md')
    p=BOOK/key if common else BOOK/'manuscripts'/f'{key}.md'
    h=hashlib.sha256(p.read_bytes()).hexdigest()
    verified=[]
    for role in ('ko-en','ko-de','curriculum'):
        row=evidence['commonReviewCoverage' if common else 'reviewCoverage'][role]['documents' if common else 'units'].get(key)
        if not row or row.get('sha256')!=h or row.get('verdict')!='PASS' or not row.get('fullTextRead') or (not common and not row.get('tasksSolvedAsText')):
            return None
        verified.append({'role':role,'report':row['report'],'sha256':h})
    return verified
closed=[]
pending=[]
for item in journal['findingDecisions']:
    refs=proof(item['unitId'])
    if refs:
        item['state']='closed_after_independent_review'
        item['closureEvidence']=refs
        closed.append(item['id'])
    else:
        item['state']='applied_pending_final_review'
        item.pop('closureEvidence',None)
        pending.append(item['id'])
for item in journal['changedUnits']:
    refs=proof(item['unitId'])
    item['state']='all_three_roles_passed_current_text' if refs else 'awaiting independent final reread'
    if refs:
        assert item['afterSha256']==refs[0]['sha256']
        item['finalReviewEvidence']=refs
    else:
        item.pop('finalReviewEvidence',None)
journal['updatedUtc']=datetime.now(timezone.utc).isoformat()
journal['closureSummary']={'closed':len(closed),'pending':pending,'proofSource':'STRUCTURE_AND_PROGRESS.json'}
p=HERE/'EDITOR_DECISIONS.json'
t=p.with_suffix('.json.tmp')
t.write_text(json.dumps(journal,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='')
assert read(t)==journal
t.replace(p)
print(json.dumps(journal['closureSummary']))
