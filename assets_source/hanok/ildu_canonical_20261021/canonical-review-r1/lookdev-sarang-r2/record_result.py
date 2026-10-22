from pathlib import Path
from PIL import Image
import hashlib,json
p=Path(__file__).resolve().parent
v=json.loads((p/'verification.json').read_text(encoding='utf-8'))
m=json.loads((p/'render-manifest.json').read_text(encoding='utf-8'))
c=json.loads((p/'material-coverage.json').read_text(encoding='utf-8'))
a=json.loads((p/'surface-mapping-audit.json').read_text(encoding='utf-8'))
sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
assert v['passed'] and v['savedNativeReopened'] and v['sourceImagePackedBytesEqual']
assert len(m['renders'])==14 and all(sha(p/x['file'])==x['sha256'] for x in m['renders'])
assert sha(p/m['nativeFile'])==m['candidateNativeSha256']==v['candidateSha256']
assert len({x['object'] for x in a})==706 and not c['unclassifiedSlots']
textures=[]
for name,original in [('handpainted-pine-r1.png','exec-bfe48a4e-f05d-464f-baf9-d92631404b48.png'),('handpainted-mineral-paper-atlas-r1.png','exec-8a391cd5-20f9-404e-972f-1249e7e32057.png')]:
    file=p/'textures'/name
    textures.append(dict(file='textures/'+name,pixels=list(Image.open(file).size),sha256=sha(file),generatedOriginal=original))
(p/'textures/PROVENANCE.json').write_text(json.dumps(dict(tool='built-in imagegen',purpose='generated painterly material textures, not architectural image replacements',promptFile='../PROMPTS.md',files=textures),indent=2)+'\n',encoding='utf-8')
result=f'''# 사랑채 손그림 재질 R2 · 2026-10-22

- 새 native 후보: `sarang-handpaint-candidate.blend`
- SHA-256: `{v['candidateSha256']}`
- 보존 원본 native SHA-256: `{v['sourceNativeSha256']}`
- 710개 원본 메시의 형상·UV·변환·수정자·기록된 속성 보존. 저장 파일 재개방 검사 통과.
- 현판/보드 4개는 원본 재질·이미지·UV를 보존. 나머지 706개 부재의 모든 재질 슬롯을 처리.
- 재질 복사본 {v['changedMaterials']}개. 목재/얇은 창살과 몰딩/서까래 끝면/기와/돌/회벽/종이/지붕 장식 표면을 구분.
- 끝면 전용 `Craft end grain` UV 4개 객체를 별도로 연결. UV 없는 온돌 바닥 3개는 object 좌표로 샘플.
- 7시점, 전후 14개 PNG. Cycles 40 samples, 동일 조명·카메라. PNG와 native의 현재 해시가 렌더 기록과 일치.
- 비교: `index.html?rev=handpaint-detail-v6#eaves`
- 새 스타일은 사용자 승인 전 후보. GLB/360도 공정 화면/Flutter 반영 및 정본 승격/커밋/푸시는 하지 않음.

## 실제 브라우저 확인

- ECC Chrome DevTools 연결로 7개 시점 버튼을 각각 조작. 모든 전후 이미지 decode 성공, 짝의 원본 해상도 일치, 이미지 오류 표시 없음.
- 비교 range에 실제 ArrowRight 키 입력: 50 → 51, 경계 CSS와 output도 51%로 변경.
- CSS 폭 320/402 및 desktop 실제 CSS 폭 1152에서 가로 overflow 없음. 시점 버튼 최소 높이 48px.
- 모바일에서 7개 버튼이 180px 높이로 세로 줄바꿈되던 문제를 가로 스크롤 56px 영역으로 수정.
- 갱신 전 브라우저가 이전 5개 버튼/770px 시험 이미지를 표시한 상태를 확인. HTML과 이미지에 버전을 부여해 7개 버튼과 현재 원본 해상도를 확인.
- 브라우저 화면의 끝면 전후 비교와 native 렌더의 나이테·창살·벽면을 직접 확인. 브라우저 스크린샷 파일 저장은 커넥터 경로 제한으로 실패했으므로 저장된 브라우저 캡처가 있다고 보고하지 않음.

## 디자인 상담

- 기존 디자이너의 실제 이미지 검수: 첫 시험의 전후 차이가 약하고 반복 옹이/균일한 기와가 남음 → 전용 손그림 재질 비트맵과 부재별 칠의 농담 추가.
- 710개 부재 목록 재검수: UV 없는 바닥 3개와 얇은 창호 세부 그룹 누락 위험 → 좌표 fallback과 작은 부재용 스케일 추가.
- 독립 금속/철물 객체 또는 재질명은 확인되지 않음. 목재 lock rail을 금속으로 재분류하지 않음.

활성 Blender 렌더는 모두 종료됨. 원본/실패 시안/생성 텍스처 원본은 보존.
'''
(p/'RESULT.md').write_text(result,encoding='utf-8')
marker='## 2026-10-22 · 사랑채 손그림 재질 R2 완료 후보'
note='\n\n'+marker+'\n\n'+result.split('## 실제 브라우저 확인')[0]+'\n상세: canonical-review-r1/lookdev-sarang-r2/RESULT.md. 승인/공정 GLB 변환 전.\n'
for name in ['WORK.md','CONTINUATION.md']:
    path=p.parent.parent/name
    if marker not in path.read_text(encoding='utf-8'):
        with path.open('a',encoding='utf-8') as stream:stream.write(note)
print(json.dumps(dict(native=v['candidateSha256'],renders=len(m['renders']),treatedObjects=706,preservedPlaques=4,changedMaterials=v['changedMaterials'],passed=True),indent=2))
