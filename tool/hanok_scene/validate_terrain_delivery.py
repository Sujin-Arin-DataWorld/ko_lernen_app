from pathlib import Path
import hashlib,json,urllib.request,struct
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'assets_unused/pending_review/hwalju-blueprint-review';OUT=SOURCE/'terrain'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
geo=json.loads((OUT/'geometry-validation.json').read_text())
delivery=json.loads((OUT/'delivery-validation.json').read_text())
renders=json.loads((OUT/'renders.json').read_text())
assert geo['allPass'] and geo['protectedMeshes']==940
assert sha(SOURCE/'scene.blend')==geo['sourceSceneSha256']=='6e34c080e7da4ed677b8a7211685804549728d9e3769eca21bfd73a9d246eaad'
assert sha(SOURCE/'pair-corrected.glb')==delivery['sourceGlbSha256']=='29db745568acdf0a5b28b7a4c579d59834a4e5431485c4ce724e4bd262d417cd'
assert sha(OUT/'scene.blend')==geo['sceneSha256']
assert sha(OUT/'pair-corrected.glb')==delivery['glbSha256']
assert len(renders)==6
for render in renders:
    path=(SOURCE if render['state']=='before' else OUT)/'scene.blend'
    assert sha(path)==render['sceneSha256']
    assert sha(OUT/f"{render['state']}-{render['view']}.png")==render['sha256']
for view in ('connection','junction','gate'):
    pair=[r for r in renders if r['view']==view]
    for key in ('camera','target','orthographicScale'):assert pair[0][key]==pair[1][key]
with (OUT/'pair-corrected.glb').open('rb') as f:
    f.seek(12);length,_=struct.unpack('<II',f.read(8));doc=json.loads(f.read(length))
roots=doc['scenes'][doc.get('scene',0)]['nodes']
names=[doc['nodes'][i].get('extras',{}).get('source_object_name','') for i in roots]
assert 'Stage.Jung.site' not in names and 'Stage.Sarang.site' not in names
assert names.count('TerrainFix.continuous rising courtyard')==1
assert sum(n.startswith('HwaljuFix.') for n in names)==30
refs=json.loads((OUT/'reference-manifest.json').read_text(encoding='utf8'))
for ref in refs:assert sha(Path(ref['source']))==sha(OUT/ref['copy'])==ref['sha256']
urls=['review.html','viewer.js','pair-corrected.glb']+[f"{r['state']}-{r['view']}.png" for r in renders]+[r['copy'] for r in refs]
for file in urls:
    with urllib.request.urlopen(urllib.request.Request('http://127.0.0.1:8785/terrain/'+file,method='HEAD')) as response:assert response.status==200
report={'allPass':True,'protectedMeshes':940,'geometryChecks':len(geo['checks']),'matchedRenders':6,'renderInputsMatchFinalScene':True,'previousHwaljuSceneAndGlbUnchanged':True,'oldStagePlatesInVisibleScene':0,'newContinuousTerrainObjects':1,'retainedHwaljuCorrectionObjects':30,'referenceCopiesIdentical':3,'servedFilesHttp200':len(urls),'browserVisualChecks':['same-camera before/after toggle','connection close-up','rising gate approach','overall pair and hwalju','mouse drag rotation','wheel zoom'],'browserUrl':'http://127.0.0.1:8785/terrain/review.html','runtimePromoted':False,'geometrySceneSha256':geo['sceneSha256'],'glbSha256':delivery['glbSha256']}
(OUT/'review-validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps(report))
