"""Bind explicit user canonical designations to source hashes and verify review dependencies."""
import hashlib,json,struct
from pathlib import Path
OUT=Path(__file__).resolve().parent;ROOT=OUT.parent
def sha(p):
 with Path(p).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def write(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
cat=json.loads((OUT/'catalog.json').read_text(encoding='utf-8'))
for b in cat['buildings']:
 if not b.get('newGate') and b['key']!='estate-context':
  b['historicalApproval']={'status':'기존 R12 정본 유지 · 이번 정본 지정에 포함','scope':'기존 canonical/manifest.json의 R12 정본 기록과 이번 전체 정본 지정 지시를 연결했습니다. 과거 건물별 모든 면·공정의 개별 승인 발언이 확인됐다는 뜻은 아닙니다.','quote':'일두고택 3D 완성본 그리고 각 건물별 건설공정과정 전부 다 커밋, 정본으로 승격시키고','source':'이 대화 · 현재 사용자 정본 지정 + 기존 R12 canonical/manifest.json','allStageApproval':False}
write(OUT/'catalog.json',cat)
html=(OUT/'index.html').read_text(encoding='utf-8').replace('class="angles" aria-label','class="angles" role="group" aria-label').replace('class="steps" aria-label','class="steps" role="group" aria-label')
(OUT/'index.html').write_text(html,encoding='utf-8')
manifest=json.loads((ROOT/'construction/manifest.json').read_text(encoding='utf-8'))
gates=[]
for g in manifest['gates']:
 p=ROOT/(g['gate']+'-new.blend');h=sha(p);assert h==g['sourceNativeSha256']
 key={'left':'left_changgo','right':'right_ansarang','shrine':'sadangmun'}[g['gate']]
 building=next(b for b in cat['buildings'] if b['key']==key)
 assert building.get('materialMode')=='approved-native-shader-baked-PBR'
 model=OUT/building['model']
 data=model.read_bytes();size=struct.unpack_from('<I',data,12)[0];j=json.loads(data[20:20+size])
 nodes=[n for n in j['nodes'] if 'reviewStage' in n.get('extras',{})]
 assert j.get('materials') and len(j.get('images',[]))>=4
 assert len(nodes)==g['objectCount']
 assigned={n['extras']['sourceObject']:n['extras']['reviewStage'] for n in nodes}
 expected=json.loads((ROOT/'construction'/(g['gate']+'-object-stage-map.json')).read_text(encoding='utf-8'))['assignments'];assert assigned==expected
 gates.append(dict(key=g['gate'],name=g['name'],status='user_designated_canonical',native=p.name,nativeSha256=h,stageCount=g['stageCount'],stageManifest='construction/manifest.json',memberCount=g['objectCount'],reviewModel='canonical-review-r1/models/'+model.name,reviewModelSha256=sha(model),reviewModelHasNativeMaterialBake=True,embeddedTextureCount=len(j['images']),reviewModelIsNativeRenderPixelParity=False,previousModelsSuperseded=True))
assembly=OUT/'assembly-verification.json'
d=dict(schemaVersion=1,date='2026-10-21',designation='user-designated Ildu source and construction canonical',authority={'source':'direct user messages in current conversation','gateQuote':'협문두개랑 사당문은 이 세션에서 너가 작업한걸로 정본승격이야.','allQuote':'일두고택 3D 완성본 그리고 각 건물별 건설공정과정 전부 다 커밋, 정본으로 승격시키고'},canonicalGates=gates,construction=dict(uniqueProcessIds=cat['processCount'],instanceStages=cat['instanceStageCount'],groups=16,scope='11 buildings, four gate instances, shared wall/yard; process assembly interpretation, not proof of historical construction chronology'),immutable=['building exterior','silhouette and shape','structural geometry and details','roofs/eaves','doors/windows/gates','footprints and layout'],permittedFutureStyleChanges=['materials','color','illustrative surface rendering'],review='canonical-review-r1/index.html',appIntegrated=False,deviceValidated=False,releaseApproved=False,generatedMockupsAreCanonical=False,oldGateModelsAreCurrentCanonical=False)
if assembly.exists():
 a=json.loads(assembly.read_text(encoding='utf-8'));assert a['passed'];d['assembledEstate']=dict(native='canonical-review-r1/'+a['native'],sha256=a['nativeSha256'],verification='canonical-review-r1/assembly-verification.json',placementReview=a['assemblyVisualReview'])
else:d['assembledEstate']={'status':'assembly_in_progress; not yet designated as verified combined output'}
write(ROOT/'CANONICAL_PROMOTION.json',d)
local=dict(d);local['review']='index.html';write(OUT/'CANONICAL_PROMOTION.json',local)
# Verify every UI source exists and decode every GLB header, including the old preserved geometry models.
models=[];images=set()
for b in cat['buildings']:
 p=OUT/b['model'];h=p.open('rb').read(20);magic,version,length=struct.unpack_from('<III',h)
 assert magic==0x46546c67 and version==2 and length==p.stat().st_size
 models.append(dict(key=b['key'],path=b['model'],sha256=sha(p),bytes=p.stat().st_size))
 for v in b['views']:images.add(v['image'])
 for s in b['steps']:
  if s.get('image'):images.add(s['image'])
  if s.get('legacyImage'):images.add(s['legacyImage'])
for name in images:assert (OUT/name).is_file(),name
report=dict(passed=True,models=models,groups=len(models),uniqueProcessIds=cat['processCount'],instanceStages=cat['instanceStageCount'],images=len(images),exactGateStageAssignments=True,canonicalGatesMatchCurrentNativeHashes=True,appIntegrated=False)
write(OUT/'package-verification.json',report)
print('VERIFIED',len(models),'groups',cat['processCount'],'unique processes',cat['instanceStageCount'],'instance stages',len(images),'images')

