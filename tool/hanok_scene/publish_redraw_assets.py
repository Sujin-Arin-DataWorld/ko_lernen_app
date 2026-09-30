"""Assemble the existing private review site's visual comparison assets."""
from pathlib import Path
import json,shutil,hashlib
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'assets_unused/pending_review/hwalju-blueprint-review';N=BASE/'northern-court';S=BASE/'side-connections'
DIST=Path('C:/dev/hangulsori/sites/ildu-survey-review-20260929/dist');A=DIST/'redraw';A.mkdir(exist_ok=True)
def copy(p,name=None):
 name=name or p.name;shutil.copy2(p,A/name);return 'redraw/'+name
entries=[
 {'id':'jar-gate','title':'장독대 협문','canonical':S/'canonical-gate.png','photo':'rear-yard-and-shrine-gates.png','drawing':'gate085-preview.png','renders':['jar-gate','jar-gate-front','jar-gate-back','jar-gate-context'],'labels':['열린 측면','닫힌 정면','뒤쪽','담장 연결'],'states':['open','closed'],'note':'빠졌던 45mm 풍지판과 처마 밑 마감을 복구했습니다. 문짝은 30mm 판재이며, 내부 가새와 마감판을 구분했습니다.','caution':'협문 정본은 목재와 기와 표현의 기준입니다. 장독대 협문의 크기와 형상은 084·085 도면을 따릅니다.'},
 {'id':'sadangmun','title':'사당문','canonical':N/'references/sadangmun/canonical.png','photo':'sadangmun-gate.png','drawing':'sadang-gate-section-preview.png','renders':['sadangmun'],'labels':['열린 측면'],'states':['open','closed'],'note':'170mm 원기둥, 깊이 있는 문선·인방과 30mm 문짝을 분리했습니다. 정본의 붉은 목재와 기와를 실제 입체 부재에 연결했습니다.','caution':'작은 철물과 곡선은 실사 해석이 포함됩니다.'},
 {'id':'anchae','title':'안채','canonical':N/'references/anchae/canonical.png','photo':'anchae-front.jpg','drawing':'anchae-plan-preview.png','renders':['anchae','anchae-corner','anchae-hall','anchae-kitchen'],'labels':['전체','오른쪽 퇴칸','대청·뒷문','부엌'],'states':['open'],'note':'대청의 앞뒤 통로와 오른쪽 퇴칸을 열고, 부엌의 낮은 바닥과 출입구를 복구했습니다. 방3에는 창호표의 네 짝 문과 교살창을 반영했습니다.','caution':'방3의 창호 번호별 위치는 평면과 창호표에 맞춘 해석이 남아 있습니다.'},
 {'id':'ansarang','title':'안사랑채','canonical':S/'ansarang-canonical.png','photo':'ansarang-porch-latest.png','drawing':'ansarang-plan-preview.png','renders':['ansarang'],'labels':['전체·접힌 대청문'],'states':['open'],'note':'안사랑채 자체의 정본을 재료 기준으로 사용했습니다. 도면의 200mm 기둥과 45mm 마루판, 퇴칸의 하부 결구를 반영했습니다.','caution':'문을 열어 방 안과 마루 깊이를 확인할 수 있는 검토용 상태입니다.'},
 {'id':'sadang','title':'사당','canonical':N/'references/sadang/canonical.png','photo':'sadang-side-depth.png','drawing':'sadang-front-preview.png','renders':['sadang','sadang-front','sadang-right','sadang-joinery'],'labels':['전체','정면 비례','오른쪽 비례','기둥·공포·퇴칸'],'states':['closed'],'note':'지붕과 기단 치수를 혼동한 오류, 기와가 세로로 늘어난 오류를 수정했습니다. 066 지붕평면도의 처마 기준선 8,560×7,100mm, 용마루 5단·내림마루 3단을 반영했습니다.','caution':'수직 높이는 059·061 입면의 선을 기둥 간격에 맞춰 읽은 값입니다. 기와 한 장의 치수는 도면에 없어 실측 확정값으로 표시하지 않습니다. 단청·공포의 세부 조형 대조는 남아 있습니다.'},
]
renders=json.loads((N/'redraw-renders.json').read_text());scene_hash=hashlib.sha256((N/'detail-redraw.blend').read_bytes()).hexdigest();models=json.loads((N/'redraw-3d-manifest.json').read_text())
for e in entries:
 if e['id']=='sadangmun':
  e.update(renders=['sadangmun','sadangmun-front','sadangmun-hardware','sadangmun-context'],labels=['열린 측면','닫힌 정면','문고리·못머리','꽃담과 문 앞'],photo='sadangmun-front-sep29.png',note='도면의 기둥·문짝 두께를 유지하고, 문고리 받침·돌출 못머리·판재 이음과 풍판을 보완했습니다. 닫힌 문과 꽃담 연결도 함께 확인할 수 있습니다.',caution='작은 철물과 빛바랜 색감은 실사 해석입니다. 꽃담은 회반죽·흙·돌·기와 조각으로 표현합니다.')
 if e['id']=='ansarang':
  e.update(title='안사랑채·별당',renders=['ansarang','ansarang-left','ansarang-kitchen'],labels=['전체·접힌 대청문','왼쪽 전체','왼쪽 부엌·다락'],photo='ansarang-left-sep29.png',note='048 평면도와 050 좌측면도에 맞춰 왼쪽을 위 다락·아래 열린 부엌으로 구분했습니다. 2,210×2,610mm 부엌, 높은 창과 다락 하부 목구조, 방3과의 단차를 확인할 수 있습니다.',caution='다락 높이는 입면과 실사에 맞춘 해석입니다. 가마솥과 부뚜막 세부는 평면 기호와 사진을 참고했습니다.')
 if e['id']=='sadang':
  e.update(renders=['sadang','sadang-front','sadang-right','sadang-joinery','sadang-porch','sadang-interior'],labels=['전체','정면 비례','오른쪽 비례','기둥·공포·퇴칸','퇴칸에서 본 깊이','내부 제단 단면'],states=['closed','open'],photo='sadang-side-sep29.png',note='기존에 바로잡은 지붕 치수는 유지했습니다. 기둥 위 공포·둘레 단청·측면 목구조·풍판을 보완하고, 사진에 보이는 신주장·제상·촛대·향로·돗자리를 내부에 추가했습니다.',caution='내부 화면은 제단을 보기 위해 앞벽을 숨긴 단면입니다. 가구 치수와 단청 곡선은 실사 해석이며, 영정 설치 위치는 확인되지 않아 배치하지 않았습니다.')
contract=json.loads((N/'detail-redraw-contract.json').read_text(encoding='utf8'));correction=contract.get('wallFinishCorrection',{})
def same_visual_scene(recorded,view,kind):
 if recorded==scene_hash:return True
 target=scene_hash;post=contract.get('postSurfaceCorrection',{})
 detail=contract.get('photoDetailCorrection',{})
 if detail.get('correctedSceneSha256')==target:
  if any(view==v or view.startswith(v+'-') for v in detail.get('changedBuildings',[])):return False
  target=detail['previousSceneSha256']
  if recorded==target:return True
 roof=contract.get('shrineRoofCorrection',{})
 if roof.get('correctedSceneSha256')==target:
  if view in ('sadang','sadang-front','sadang-right','sadang-joinery'):return False
  target=roof['previousSceneSha256']
  if recorded==target:return True
 if post.get('correctedSceneSha256')==target:
  if view.startswith('anchae'):return False
  target=post['previousSceneSha256']
  if recorded==target:return True
 return correction.get('correctedSceneSha256')==target and recorded==correction.get('previousSceneSha256') and view in correction.get('equivalentUnchanged'+kind,[])
for e in entries:
 e['canonical']=copy(e['canonical'],e['id']+'-canonical.png');e['photo']=copy(N/'references/photos'/e['photo']);e['drawing']='references/survey-audit/'+e['drawing']
 photo_sets={'sadang':[('sadang-side-sep29','퇴칸·풍판'),('sadang-front-sep29','정면 기둥·공포'),('sadang-altar-sep29','내부 제단'),('jeong-yeochang-portrait-reference','영정 참고 · 설치 위치 미확정')],'ansarang':[('ansarang-left-sep29','왼쪽 부엌·다락'),('ansarang-porch-latest','앞쪽 퇴칸')],'sadangmun':[('sadangmun-front-sep29','문틀·철물·꽃담')]}
 if e['id'] in photo_sets:e['photos']=[{'src':copy(N/'references/photos'/(name+'.png')),'label':label} for name,label in photo_sets[e['id']]]
 if e['id']=='ansarang':e['drawings']=[{'src':copy(S/'ansarang048.jpg','ansarang-survey048.jpg'),'label':'048 평면도'},{'src':copy(N/'references/survey-audit/ansarang-survey050.jpg'),'label':'050 좌·우측면도'}]
 if e['id']=='sadang':
  e['drawings']=[]
  for suffix,label,filename in [('정면도','059 정면도','sadang-survey059.jpg'),('우측면도','061 우측면도','sadang-survey061.jpg'),('지붕평면도','066 지붕평면도','sadang-survey066.jpg')]:
   source=next((N/'references/sadang').glob('*사당_'+suffix+'.jpg'))
   e['drawings'].append({'src':copy(source,filename),'label':label})
 gallery=[]
 for v,label in zip(e['renders'],e['labels']):
  file=v+'-redraw.png';r=next(r for r in renders if r['file']==file)
  assert same_visual_scene(r['sourceSceneSha256'],v,'Views'),(file,'stale render');assert hashlib.sha256((N/file).read_bytes()).hexdigest()==r['sha256']
  gallery.append({'src':copy(N/file),'label':label})
 e['renders']=gallery;e.pop('labels');e['models']={}
 for state in e['states']:
  m=next(m for m in models if m['building']==e['id'] and m['state']==state);p=N/'review3d'/m['file']
  assert same_visual_scene(m['candidateSceneSha256'],e['id'],'Models') and hashlib.sha256(p.read_bytes()).hexdigest()==m['sha256'];assert p.stat().st_size<25*1024**2
  e['models'][state]={'src':copy(p),'mb':round(p.stat().st_size/1024**2,1)}
 e.pop('states')
report=json.loads((N/'detail-redraw-validation.json').read_text());assert report['allPassed']
assert report['sceneSha256']==scene_hash
copy(N/'detail-redraw-validation.json');copy(N/'redraw-3d-manifest.json');copy(N/'atlas-part-map.json')
copy(N/'wall-material-audit.json');(A/'wall-finish-correction.json').write_text(json.dumps(correction,ensure_ascii=False,indent=2),encoding='utf8')
copy(N/'sadang-roof-audit.json')
copy(N/'photo-detail-audit.json');copy(N/'photo-detail-sources.json')
(A/'post-surface-correction.json').write_text(json.dumps(contract.get('postSurfaceCorrection',{}),ensure_ascii=False,indent=2),encoding='utf8')
(DIST/'redraw-data.json').write_text(json.dumps({'sceneSha256':scene_hash,'buildings':entries,'checks':{'passed':report['passed'],'total':report['total']}},ensure_ascii=False,indent=2),encoding='utf8')
print('SITE VISUAL ASSETS READY',len(entries),scene_hash)
