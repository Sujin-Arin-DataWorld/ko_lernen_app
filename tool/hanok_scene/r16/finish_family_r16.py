"""Finish local review package after strict evidence audit; no asset promotion."""
import json,hashlib,datetime
from pathlib import Path
P=Path(__file__).resolve().parent;D=P/'family-r16'
def read(f):return json.loads(f.read_text(encoding='utf-8'))
def write(f,value):f.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
a=read(D/'AUDIT.json');g=read(D/'gallery-data.json');ui=read(D/'gallery-check.json')
assert a['complete'] and a['renderedStages']==128 and g['renderedStages']==128
assert ui['allProcessImagesDecoded']==128 and ui['allProcessLabelsVerified'] and not ui['javascriptErrors']
assert (D/'STAGE_VISUAL_REVIEW.json').exists()
table='\n'.join('| '+r['name']+' | '+str(r['stageCount'])+' | '+str(r['renderedStages'])+' |' for r in a['buildings'])
readme='''# 일두고택 재질·공정 R16 검토 패키지

사랑채의 과한 붉은 주황색을 부재 역할별로 보정하고, 기존 목재 원본의 옹이와 주변 굽은 결을 일부 부재에 드러냈다. 부재마다 고정된 바탕색·결 crop 크기·위치를 사용한다. 연결 난간은 같은 갈색 계열로 이어진다.

동일한 재질 방향을 나머지 10개 건물에 이식했다. 원본 UV/부재 식별 속성이 서로 다른 P18·HS 구성과 packed 목재 atlas를 각각 해석했다. 안채 기둥의 가로결 축 오류, 측간의 좁은 atlas 영역 오류, 마루판과 받침보의 역할 혼동을 실제 렌더 검수 후 수정했다. 사당의 기존 단청 105개 슬롯은 보존했다.

## 검토 방법

- `index.html`: 건물 → 완성본/공정별 → 단계 선택 → 이미지 클릭 확대.
- 로컬 서버: `http://127.0.0.1:8876/family-r16/index.html`
- 각 건물의 `stage.blend`: 프레임 1부터 마지막 프레임까지가 원래 공정 순서다. Blender에서 각 단계의 3D를 회전·확대할 수 있다.
- 사랑채 완성 원본은 `../sarang-wood-r16/sarang-wood-r16.blend`, 나머지는 `<건물 키>/<건물 키>.blend`다.

## 단계 수

| 건물 | 기존 공정 | 렌더 저장 |
|---|---:|---:|
'''+table+'''
| 합계 | 128 | 128 |

공정 ID·순서를 유지하고, 각 공정의 누적 부재 선택에 완성본과 동일한 재질을 사용했다. 같은 건물의 모든 공정은 카메라·조명·월드·노출·재질 연결이 같다. 새 부재가 없는 단계도 원래 공정에 남겨 이전 선택을 재사용했다. 사랑채의 추가 돌기단과 수호기와는 원래 부재의 lineage를 따라 같은 공정에 등장한다. 없는 터 닦기용 말뚝·줄·새 학습 진도를 만들지 않았다.

## 검증 근거

- `AUDIT.json`: 11개 원본/파생 파일·완성 렌더·128개 공정 렌더 해시, 공정 ID·순서, 누적 선택, 동일 카메라·재질 연결 및 proxy lineage 검증.
- 각 `<건물>/verification.json`: 원본 형상·UV·법선·속성·이름·계층·공정 연결 보존, 재질 분류·매핑, 저장 후 재열기 검사.
- 각 `<건물>/stage-selection.json` 및 `stage-renders.json`: 단계별 선택 이름, process ID, 이미지 해시, 재사용 사유.
- `gallery-check.json`: 11개 건물 전환, 128개 단계 이미지·라벨 로딩, 확대창, 작은 화면 가로 넘침 검사.
- `../FAMILY_VISUAL_REVIEW_R16.json`: 다른 10개 건물의 이전·최종 렌더 검수와 수정 근거.
- `STAGE_VISUAL_REVIEW.json`: 공정 contact-scale 육안 검수와 한계.

## 보존과 범위

원본 11개 건물 파일과 기존 Render 1·2는 보존했다. 원래 82개 process 미확정/context 부재의 null ID와 reviewStage도 그대로다. 오래된 R12 curriculum display policy와 현재 canonical GLB 선택이 다른 7개 단계는 별도로 기록했으며, 이전 앱 정책을 덮어쓰지 않았다.

이 패키지는 Blender 3D 재질·공정 검토 결과다. 기존 R12 전용 exporter의 두 허용 SHA를 임의로 바꾸거나, 이 파생 파일을 기존 입력으로 위장하지 않았다. 전체 건물 GLB PBR 베이킹/런타임 적용, 앱 이미지 교체, 사용자 최종 승인과 배포는 수행하지 않았다. 원본 외부 텍스처 의존성인 `hanok-hwalju-20260928`과 R12 도구 출처 `hanok-warm-stone-20260923`는 유지해야 한다.

목표와의 픽셀 단위 완전 일치는 주장하지 않는다. 일부 좁은 판재의 직선 결, 곡간의 유사한 결, 아래채 박공의 짙은 무늬 등은 검수 기록에 남겼다. 공정 contact sheet는 분석용이며, 실제 개별 렌더와 native 파일이 결과물이다.
'''
(D/'README.md').write_text(readme,encoding='utf-8')
scope=read(P/'CURRENT_SCOPE.json');scope.update(updated='2026-10-28',phase='eleven-native-material-derivatives-and-128-process-cuts-review-ready',candidate='family-r16',latestVisualReview='11native buildings and128process cuts saved and verified; localgallery128interaction checks passed; user review pending',verification='family-r16/AUDIT.json',stageCutCount=128,allStageCutsSaved=True,newRenderingPaused=False,materialEditingPaused=False,runtimeIntegrated=False,userApproved=False)
scope.pop('globalLightingAndExposureChanged',None)
scope.update(sarangGlobalLightingAndExposureChanged=False,otherBuildingsReviewStudioRebuilt=True,withinBuildingStageLightingAndCameraFixed=True)
write(P/'CURRENT_SCOPE.json',scope)
manifest=dict(schemaVersion=1,generatedUtc=datetime.datetime.now(datetime.timezone.utc).isoformat(),name='IlduR16native material andprocess review',buildingCount=11,stageCount=128,buildings=a['buildings'],audit='AUDIT.json',gallery='index.html',browserChecks='gallery-check.json',visualReview='STAGE_VISUAL_REVIEW.json',canonicalSourcesChanged=False,runtimeIntegrated=False,userApproved=False)
write(D/'MANIFEST.json',manifest)
print('REVIEW_PACKAGE_VERIFIED',11,128)
