"""Read-only source-preservation and local-resource checks for the review."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
from collections import Counter
import hashlib, json
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
failures=[]
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
original=json.loads((ROOT/'qa/source_copies.json').read_text(encoding='utf-8'))
catalog=json.loads((ROOT/'qa/catalog-source-copies.json').read_text(encoding='utf-8'))['copies']
reward_contract=json.loads((ROOT/'qa/reward-sources.json').read_text(encoding='utf-8'))
reward=[{'source':i['source'],'copy':Path(i['review']).relative_to(ROOT).as_posix(),'sha256':i['sha256']} for i in reward_contract['copies']]
native=json.loads((ROOT/'qa/reward-generation.json').read_text(encoding='utf-8'))
reward.append({'source':native['source'],'copy':native['copy'],'sha256':native['sha256']})
dimensions=[]
for item in original+catalog+reward:
    path=ROOT/item.get('path',item.get('copy'))
    if not path.is_file() or digest(path)!=item['sha256'] or digest(Path(item['source']))!=item['sha256']:
        failures.append(str(path))
    if path.suffix.lower() in ('.png','.webp','.jpg'):
        with Image.open(path) as im:
            dimensions.append({'path':path.relative_to(ROOT).as_posix(),'size':list(im.size),'format':im.format,'mode':im.mode})

inventory=json.loads((ROOT/'catalog-data.json').read_text(encoding='utf-8'))
assert len(inventory['packs'])==252 and len(inventory['activities'])==21
for item in inventory['activities']:
    assert item['title']['de'] and item['title']['en'] and item['description']['de'] and item['description']['en']
for relative, expected in inventory['sourceHashes'].items():
    if digest(Path(inventory['sourceCheckout'])/relative)!=expected:
        failures.append('current source changed: '+relative)
for relative,expected in reward_contract['sourceHashes'].items():
    if digest(Path(inventory['sourceCheckout'])/relative)!=expected:
        failures.append('reward source changed: '+relative)
for item in catalog:
    found=next(d for d in dimensions if d['path']==item['copy'])
    assert found['size']==[800,600], found

content=json.loads((ROOT/'content.json').read_text(encoding='utf-8'))
keys={lang:set(values) for lang,values in content['ui'].items()}
assert keys['de']==keys['en']==keys['ko']
class ResourceCheck(HTMLParser):
    def __init__(self,file): super().__init__();self.file=file
    def handle_starttag(self,tag,attrs):
        for key,value in attrs:
            if key not in ('src','href') or not value: continue
            url=urlsplit(value)
            if url.scheme or not url.path or url.path.startswith('data:'): continue
            path=(self.file.parent/unquote(url.path)).resolve()
            if not path.exists(): failures.append('missing resource: '+str(path))
for file in ROOT.glob('*.html'):ResourceCheck(file).feed(file.read_text(encoding='utf-8-sig'))
report={'scope':'Review only. No raster edits or runtime promotion.', 'sourceHead':inventory['head'], 'sourceCopies':len(original)+len(catalog)+len(reward),'unchangedSourceAndCopyBytes':not failures,'uiKeysPerLocale':{lang:len(values) for lang,values in keys.items()},'catalogCounts':inventory['stats'],'catalogRasterSizes':dict(Counter(str(d['size']) for d in dimensions if '/catalog/' in d['path'])),'rewardRules':reward_contract['rules'],'images':dimensions,'failures':failures}
(ROOT/'qa/asset-audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k!='images'},ensure_ascii=False))
assert not failures, failures
