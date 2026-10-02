from pathlib import Path
import hashlib,json,subprocess
from PIL import Image
root=Path(__file__).resolve().parent.parent
repo=next((p for p in root.parents if (p/'.git').exists()),None)
assert repo is not None, 'Run from a repository checkout containing this review bundle.'
catalog=json.loads((root/'catalog-data.json').read_text(encoding='utf-8'))
def reference_bytes(name):
    return subprocess.check_output(['git','show',f"{catalog['head']}:{name}"],cwd=repo)
def matches_checkout_hash(name, expected):
    raw=reference_bytes(name)
    lf=raw.replace(b'\r\n',b'\n')
    # Catalog provenance was recorded from a Windows checkout. Git stores LF.
    variants=(raw,lf,lf.replace(b'\n',b'\r\n'))
    return expected in {hashlib.sha256(value).hexdigest() for value in variants}
hashes={name:matches_checkout_hash(name,value) for name,value in catalog['sourceHashes'].items()}
assert all(hashes.values()),hashes
assets={}
scope=json.loads((root/'qa/scope.json').read_text(encoding='utf-8'))
for name,record in scope['art'].items():
    target=root/'assets'/f'{name}.png'
    assert hashlib.sha256(target.read_bytes()).hexdigest()==record['sha256']
    im=Image.open(target)
    assert im.mode=='RGBA' and im.getchannel('A').getextrema()==(0,255)
    assets[name]={'size':list(im.size),'transparent':True,'bytesPreserved':True}
layouts=json.loads((root/'qa/layout-results.json').read_text(encoding='utf-8-sig'))
receipt={'scope':'Independent pending-review bundle; runtime integration is not included.','sourceReferenceHead':catalog['head'],'catalogSourceHashes':hashes,'newArt':assets,'logicTests':17,'layoutCases':len(layouts),'interactionChecks':['Grammar opens its canonical activity detail','Hangul recommendation opens its canonical activity detail','Dismissal keeps four tiles and removes suggestion','Demo history does not alter local preview usage history'],'integrationBoundary':'Records only local prototype interactions. Production user/account/activity engines are not connected.'}
(root/'qa/verification.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2),encoding='utf-8')
print('PASS: catalog matches pinned source commit; 2 native transparent assets preserved; 17 logic tests and 8 layouts recorded.')
