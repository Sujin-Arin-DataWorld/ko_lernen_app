"""Record the completed native render and check the two preserved originals."""
from pathlib import Path
import json,hashlib
P=Path(__file__).resolve().parent;D=P/'sarang-reference-colour-r3'
def read(q):return json.loads(q.read_text(encoding='utf-8'))
def write(q,v):q.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(q):
 with q.open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()
kept=read(P/'RENDER_1_2_PRESERVATION.json')
for folder,items in kept['files'].items():
 for item in items:
  q=P/folder/item['file'];assert q.stat().st_size==item['bytes'] and sha(q)==item['sha256'],str(q)
v=read(D/'verification.json');assert sha(D/v['native'])==v['nativeSha256']
r=read(D/'render.json');assert sha(D/r['file'])==r['sha256']
assert r['resolution']==[1800,1200] and v['geometry']['meshCount']==711
v['render1And2PreservedAfterFinalRender']=True;v['finalRender']=r;write(D/'verification.json',v)
scope=read(P/'CURRENT_SCOPE.json')
scope.update(phase='sarang-reference-colour-review',candidate='sarang-reference-colour-r3',
 authorization='User: render 1/2 original preservation; clear old colour and place reference colours',
 latestVisualReview='Reference colour candidate 3; native Cycles render; user review pending',
 preserveRender1And2=True,globalLightingAndExposureChanged=False,
 newRenderingPaused=True,materialEditingPaused=True)
write(P/'CURRENT_SCOPE.json',scope)
write(P/'PROGRESS.json',dict(key='sarang',event='reference_colour_candidate_3_ready',
 render=str(D/r['file']),native=str(D/v['native']),geometryVerified=True,preservedRender1And2=True,
 lightingAndExposureFixed=True,userApproved=False,runtimeIntegrated=False))
(D/'README.md').write_text('''# 사랑채 · 색상 초기화 시안 3

사용자 지시: render 1·2 원본 보존, 기존 색상 연결 제거, 첨부 목표 이미지의 색상 적용.

- 결과: `render.png` — Blender Cycles, 1800 × 1200, 96 samples.
- 원본: `sarang-reference-colour.blend` — 수정 가능한 실제 Blender 파일.
- 건축 메시 711개, 이름·계층·형상·UV·법선·속성·공정 매핑 보존 확인.
- 2번의 카메라·광원·월드·바닥·노출·톤 매핑 고정.
- 기존 Base Color 연결을 제거한 뒤 목표 이미지에서 재료별 색을 추출. 원래 목재 이미지는 회색조 결 마스크로만 사용.
- 기둥·보·박공·서까래·마구리·마루·난간·판벽·하부 판벽·문·문틀·창살에 각각 별도 색 범위 적용.
- 목표 픽셀색은 빛이 포함된 색이므로, 실제 렌더와 부위별 비교한 오차를 각 재질 색에만 반영. 한지 발광 강도 유지, 색만 변경.
- 기와·돌·백토·회벽·한지 별도 색상 적용.
- 1·2번 전체 파일 크기와 SHA-256은 상위 `RENDER_1_2_PRESERVATION.json`과 재대조 완료.

이 파일은 사용자 검토용 시안이다. 목표 이미지와 100% 일치, 정본 승격, GLB 또는 앱 반영을 의미하지 않는다.
''',encoding='utf-8')
print(json.dumps(dict(render=r,nativeSha256=v['nativeSha256'],preserved=True,geometry=v['geometry']),indent=2))
