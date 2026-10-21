"""Assemble a self-contained building/stage review from exact existing source bytes."""
import hashlib,json,shutil,struct
from pathlib import Path
OUT=Path(__file__).resolve().parent
ROOT=OUT.parent
ART=ROOT.parents[2]
WB=ART/'building-workbench-20261017'
def sha(p):
 with Path(p).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def copy(src,rel):
 dst=OUT/rel;dst.parent.mkdir(parents=True,exist_ok=True)
 if not dst.exists() or sha(src)!=sha(dst):shutil.copyfile(src,dst)
 return rel
def write(name,data):(OUT/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
catalog=json.loads((WB/'catalog.json').read_text(encoding='utf-8'))
new=json.loads((ROOT/'construction/manifest.json').read_text(encoding='utf-8'))
keys={'left_changgo':'left','right_ansarang':'right','sadangmun':'shrine'}
gateManifest={g['gate']:g for g in new['gates']}
for b in catalog['buildings']:
 key=b['key'];b['newGate']=key in keys;b['historicalApproval']={'status':'기존 R12 기준 유지','scope':'현재 대화에서 본체 외관·디테일·형상 유지 지시. 건물별 숨은 면과 모든 공정의 과거 개별 승인 기록은 확인되지 않았습니다.','quote':'지금 디테일이랑 건물자체 모양은 아주 마음에 들어','source':'이 대화 · 사용자 직접 발언','allStageApproval':False}
 b['canonicalDesignation']={'requested':True,'date':'2026-10-21','scope':'원본 3D·기존 공정 자료 정본 승격 요청. 실기기·앱 출시 승인과 별도.','quote':'일두고택 3D 완성본 그리고 각 건물별 건설공정과정 전부 다 커밋, 정본으로 승격시키고'}
 b['structureOnly']=True
 if key in keys:
  gate=keys[key];g=gateManifest[gate]
  b['name']={'left':'사랑채 왼쪽 협문','right':'안채 연결 협문','shrine':'사당문'}[gate]
  b['model']='models/'+key+'.glb';b['native']='../'+gate+'-new.blend';b['nativeSha256']=g['sourceNativeSha256']
  b['memberCount']=g['objectCount'];b['unassignedCount']=0
  b['steps']=[dict(id=s['processId'],sequence=s['sequence'],label=s['label'],memberCount=s['deltaCount'],isFinal=s['isFinal'],description=s.get('displayDescription',''),image=copy(ROOT/'construction'/s['image'],'images/'+gate+'-stage-'+str(s['sequence'])+'.png'),noNewGeometry=s['noNewGeometry']) for s in g['steps']]
  b['views']=[dict(id=v,label=lab,image=copy(ROOT/(gate+'-'+v+'.png'),'images/'+gate+'-'+v+'.png'),sourceVersion='최신 R6c · 도면 재제작') for v,lab in [('hero','전체'),('front','정면'),('back','배면'),('side','측면'),('plan','평면'),('eaves','처마'),('underside','처마 아래')]]
  b['historicalApproval']={'status':'이 세션 제작본 · 정본 승격 확정','scope':'2026-10-21 사용자가 이 세션의 협문 두 개와 사당문을 직접 정본 지정했습니다. R6c 원본과 그 부재로 만든 공정을 연결합니다. 앱·실기기·출시 승인은 별도입니다.','quote':'협문두개랑 사당문은 이 세션에서 너가 작업한걸로 정본승격이야.','source':'이 대화 · 사용자 직접 발언','allStageApproval':False}
  if gate=='shrine':b['historicalApproval']['scope']+=' 사당문 색상은 별도 통과 발언이 있습니다.'
 else:
  copy(WB/b['model'],b['model'])
  if b.get('standaloneModel'):copy(WB/b['standaloneModel'],b['standaloneModel'])
  for v in b.get('views',[]):copy(WB/v['image'],v['image'])
  for v in b.get('standaloneViews') or []:copy(WB/v['image'],v['image'])
  for s in b['steps']:
   if s.get('legacyImage'):copy(WB/s['legacyImage'],s['legacyImage'])
  b['native']='../estate-yard-wall-r1/ildu-estate-yard-wall-r1.blend'
  b['nativeSha256']='586b8a5328e7c0deaeff5f340639708c927ea224a429aca70dc313adadddff68'
  for s in b['steps']:s['description']='기존 원본 부재의 누적 조립 보기입니다. 새 부재가 없는 단계도 기존 학습 공정에 남아 있습니다.'
  if key=='estate-context':
   b['views']=[dict(id=v,label=lab,image=copy(ROOT/'estate-yard-wall-r1/living-r5'/(v+'-B.png'),'images/yard-'+v+'.png'),sourceVersion='마당 R5 · 담장 R3') for v,lab in [('full','전체'),('overview','사랑채 앞'),('detail','흙 확대')]]
   b['historicalApproval']={'status':'마당 경계 수정 승인','scope':'R5 절단선 수정에 “잘했어” 발언. 담장 전체 품질이나 새 문 결합 장면 전체 승인으로 확대하지 않습니다.','quote':'잘했어. 이제는 이 완성 화면을.. 아이폰 16프로 기준으로','source':'이 대화 · 사용자 직접 발언','allStageApproval':False}
   b['structureOnly']=True
for p in (ART/'qa/viewer/vendor').rglob('*.js'):
 copy(p,'vendor/'+p.relative_to(ART/'qa/viewer/vendor').as_posix())
catalog.update(kind='사용자 정본 지정에 따른 실제 3D 검토판',instanceStageCount=sum(len(b['steps']) for b in catalog['buildings']),processCount=len({s['id'] for b in catalog['buildings'] for s in b['steps']}),sourceVersion='R12 건축 + 최신 R6c 세 문 + 마당 R5·담장 R3',modelMaterialMode='구조 검토용 GLB; 재질 정본은 Blender 원본과 해당 렌더',approvalPolicy='과거 개별 승인 근거와 현재 정본 지정을 구분. 앱·출시 승인을 추론하지 않음.')
write('catalog.json',catalog)
print('REVIEW PACKAGE',len(catalog['buildings']),'groups',catalog['processCount'],'stages',flush=True)

