from pathlib import Path
import json,hashlib,shutil
P=Path(__file__).resolve().parent;D=P/'sarang-fit-r7'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
v=json.loads((D/'verification.json').read_text(encoding='utf-8'));assert v['renderComplete'] and v['reopenedVerified']
assert sha(D/v['native'])==v['nativeSha256'];assert sha(Path(v['source']))==v['sourceSha256']
art=P/'sarang-guardian-r6/guardian.png';shutil.copy2(art,D/'guardian-art.png')
shutil.copy2(P/'sarang-guardian-r6/ARTWORK.md',D/'GUARDIAN_ARTWORK.md')
character=Path('C:/Users/vjinn/.codex/generated_images/도깨비확정/10푸른 불꽃의 도깨비 전사.png')
provenance=dict(characterSource=str(character),characterSha256=sha(character),guardianArtworkSource=str(art),guardianArtworkSha256=sha(art),stoneArtworkSource=v['stoneTextureSource'],stoneArtworkSha256=v['stoneTextureSha256'],generator='built-in image_gen',nativeApplication='Blender 5.2.2 LTS CPU Cycles',approved=False,runtimeIntegrated=False)
(D/'provenance.json').write_text(json.dumps(provenance,ensure_ascii=False,indent=2),encoding='utf-8')
scope=json.loads((P/'CURRENT_SCOPE.json').read_text(encoding='utf-8'))
scope.update(updated='2026-10-24',phase='sarang-stone-guardian-fit-review',candidate='sarang-fit-r7',reason='사랑채 돌 표면과 도깨비 기와 맞춤 수정. 11동 확장보다 현재 사랑채 검수가 우선.',authorization='User: reference-quality stone and complete Dokkaebi artwork fitted inside actual roof ornament without clipping',latestVisualReview='R7 full native render, stone close-up, complete guardian close-up; user review pending',newRenderingPaused=False,materialEditingPaused=False)
(P/'CURRENT_SCOPE.json').write_text(json.dumps(scope,ensure_ascii=False,indent=2),encoding='utf-8')
report='''# 사랑채 R7 — 돌 표면과 도깨비 기와 맞춤

2026-10-24 · 사용자 검토용 Blender 후보

## 변경

- 돌: 목표 이미지의 미색 바탕, 불규칙한 황토·회갈색 광물 얼룩, 작은 패임을 바탕으로 만든 전용 텍스처를 실제 3D 재질에 연결. 부재별 위치와 색 변주 적용. 돌 재질 내부에서만 광물 대비 조정.
- 도깨비 기와: 원본 이미지의 비율을 유지하며 기존 기와 면의 삼각형 영역 안에 불투명 실루엣이 들어가는 최대 크기를 계산. 아래 둥근 기와 위로 여백을 두어 얼굴·뿔·하단 테두리 전체가 보이도록 매핑. 면과 옆면에 녹청 질감 추가.
- 기존 두 받침돌 보수 유지: 원래 문턱 돌을 움직이지 않고 별도 받침으로 아래 틈을 연결.

## 확인

- 기존 건축 메시 711개 구조·이름·계층·위치·UV·노멀 해시 및 공정 매핑 유지.
- 전체 장면 카메라·조명·노출 유지. 확대 렌더용 카메라 변경은 저장 원본에 반영하지 않음.
- Render 1·2와 R5·R6 원본 보존. 파일을 다시 열어 검증.
- stone.png: 계단·기단·문턱 접촉 확대.
- guardian.png: 상단 도깨비 기와 전체 문양 확인.
- render.png: 같은 전체 시점 렌더.

## 파일

- sarang-fit-r7.blend — 텍스처를 내장한 수정 원본.
- guardian-art.png — 잘리지 않은 도깨비 기와 그림 원본.
- stone-material.png — 돌 재질 원본.
- verification.json — 원본/출력 해시, 구조 보존, 기와 매핑 범위.
- provenance.json / GUARDIAN_ARTWORK.md — 그림 출처와 생성 기록.

도깨비 문양은 표면 이미지와 범프를 사용하는 후보이며 정밀 부조 조각 메시가 아니다. 건축 구조는 보존했고 판타지 기와는 사용자 요청에 따른 이야기 장식이다. 목표 사진과 완전 일치, 사용자 승인, GLB 또는 앱 반영 완료를 뜻하지 않는다.
'''
(D/'REVIEW.md').write_text(report,encoding='utf-8')
print(json.dumps(dict(candidate=str(D),nativeSha256=v['nativeSha256'],renderComplete=v['renderComplete']),indent=2))
