"""Publish a local review receipt only; never promote runtime/canonical assets."""
import json,hashlib,datetime
from pathlib import Path
P=Path(__file__).resolve().parent;D=P/'sarang-wood-r15'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
r=read(D/'verification.json')
assert r['renderComplete'] and all(r['finalChecks'].values())
assert (D/'visual-review.json').exists()
ref=Path('C:/Users/vjinn/AppData/Local/Temp/codex-clipboard-5e6b97f2-5bcf-40b9-ac54-cc2e35b83c47.jpg')
assert hashlib.sha256(ref.read_bytes()).hexdigest()=='1bf0f7ff3f5449c2267e320348d600379f012f7a390b264b224d9cb4afd77bdb'
scope=read(P/'CURRENT_SCOPE.json')
scope.update(updated='2026-10-28',phase='sarang-individual-timber-colour-and-grain-review',candidate='sarang-wood-r15',latestVisualReview='R15 native member-specific timber variation; full and two closeups reviewed; user review pending',nativeSha256=r['nativeSha256'],verification='sarang-wood-r15/verification.json',authorization='User: continue individual timber expression; every physical timber must not read as identical colour',userApproved=False,runtimeIntegrated=False,globalLightingAndExposureChanged=False)
write(P/'CURRENT_SCOPE.json',scope)
r.update(reference=str(ref),referenceSha256='1bf0f7ff3f5449c2267e320348d600379f012f7a390b264b224d9cb4afd77bdb',visualReview='visual-review.json',woodMaterialNamesInheritedFrom='R14; current cropped bindings in grain.assignments',verifiedAtUtc=datetime.datetime.now(datetime.timezone.utc).isoformat())
write(D/'verification.json',r)
text='''# 사랑채 목재 개별 표현 R15 — 검토본

목재 502개 오브젝트, 3,254개 연결 조각에 기존 부재 식별자·오브젝트·조각별로 일정한 색 변주를 적용했다. 판재와 기둥은 갈색~황갈색 범위가 보이도록 하고 연결 난간은 작은 차이를 유지한다. 목재 결과 옹이는 기존 원본 텍스처를 사용하며, 498개 오브젝트는 부재마다 샘플 크기와 위치도 달리한다. 원래 절단면 전용 오브젝트 4개는 절단면 텍스처를 유지한다.

R13에서 잘못 발광하던 온돌 바닥 3개를 비발광으로 정정했다. 조명·월드·카메라·노출은 그대로다.

- native: `sarang-wood-r15.blend`
- full: `full.png` (1800×1200, Cycles 64 samples)
- closeups: `numaru-wood.png`, `main-wood.png` (1400×1200, Cycles 48 samples)
- machine receipt: `verification.json`
- independent review: `visual-review.json`

원본 711개 부재의 형상·UV·속성·법선, 이름·부모·트랜스폼, 공정 매핑, 대상 외 재질 및 Render 1·2 해시를 대조했다. 원본 R13과 R14도 보존했다.

목재 재질 검토본이다. 사용자 최종 승인, 목표 이미지 100% 일치, 전체 건물 GLB 베이킹/앱 통합 완료를 뜻하지 않는다. 돌·벽·기와의 남은 품질 차이는 이번 목재 수정으로 완료 처리하지 않는다.
'''
(D/'README.md').write_text(text,encoding='utf-8')
print(json.dumps(dict(native=r['native'],sha256=r['nativeSha256'],renderComplete=r['renderComplete'],checks=r['finalChecks']),ensure_ascii=False,indent=2))
