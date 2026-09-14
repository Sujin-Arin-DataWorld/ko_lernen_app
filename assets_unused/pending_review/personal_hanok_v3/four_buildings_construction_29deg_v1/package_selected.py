"""Package selected original PNG bytes; never edit or recompress image pixels."""
from pathlib import Path
import json, hashlib, zipfile

ROOT=Path(__file__).resolve().parent
VIEWER=ROOT.parents[3]/'docs/mockups/four-buildings-construction-29'
catalog=json.loads((ROOT/'construction_catalog.json').read_text(encoding='utf-8'))
members=[]
for building in catalog['buildings']:
    for stage in building['steps']:
        p=ROOT/stage['file']
        members.extend([p,p.with_suffix('.prompt.txt')])
members += [ROOT/name for name in ['README.md','construction_catalog.json','asset_audit.json','art_review.json','reference_manifest.json','generation_manifest.json']]
members += sorted((ROOT/'references').glob('*.png'))
output=VIEWER/'four-buildings-49-png.zip'
with zipfile.ZipFile(output,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
    for p in members: archive.write(p,p.relative_to(ROOT).as_posix())
    archive.write(VIEWER/'browser_qa.json','browser_qa.json')
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
    stage_names=[n for n in archive.namelist() if n.endswith('.png') and not n.startswith('references/')]
    assert len(stage_names)==49
    for n in stage_names:
        assert archive.read(n)==(ROOT/n).read_bytes()
receipt={'path':str(output),'bytes':output.stat().st_size,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'selectedPngCount':49,'crcPass':True,'allSelectedPngBytesMatchSource':True}
(VIEWER/'package_manifest.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(receipt,ensure_ascii=False))
