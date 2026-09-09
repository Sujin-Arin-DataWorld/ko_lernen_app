# 일두고택 V3 지도 카메라 체크포인트

이 폴더는 **검토용 제작 자료**다. 앱 런타임 에셋이나 `pubspec.yaml`에는 등록하지 않는다.

## 현재 확정된 내용

- 배치 기준: `ildu-layout-plan-v3.png`, `layout-plan.json`
- 카메라 기준: 오른쪽 앞 15도, 지면 기준 34도, 확대 125%
- 사랑채 디자인: 사용자가 선택한 candidate 05
- 투명 정본: `sarangchae-candidate05-transparent.png`
- 지도 검토본: `map-transfer-selected-small-map.png`
- 지도 등록: 이전 표시 크기의 78.33%, 원점 `(358, 686)`
- 사랑채 좌우 협문: 두 곳 모두 최종 검토본에서 100% 노출
- 변경 격리: 승인 범위 밖 RGB 변경 0픽셀

사랑채의 **디자인 선택은 기록됐지만 78.33% 지도 크기는 아직 승인 전**이다. 따라서 중문채·창고·협문 신규 생성은 시작하지 않는다. 이 상태는 `sarangchae-selection-registration-v1.json`과 `next-batch-generation-spec-v1.json`에 고정돼 있다.

## 핵심 파일

- `sarangchae-user-selected-source.png`: 사용자가 직접 고른 불투명 원본
- `sarangchae-candidate05-transparent.png`: RGB를 유지하고 배경만 투명화한 정본
- `sarangchae-candidate05-alpha-verification.json`: 알파 분리 검사
- `map-transfer-selected-small-map.png`: 현재 전체 지도 검토본
- `sarangchae-selected-small-map-detail.png`: 사랑채 구역 확대
- `sarangchae-selection-registration-v1.json`: 선택·크기·게이트 상태
- `map-transfer-review.html`: 이전/현재 배치 비교 화면
- `next-batch-generation-spec-v1.json`: 다음 제작 순서와 입력 제한
- `building_identifications.json`: 사용자가 확정한 12개 건물 이름과 위치 식별
- `map1_landuse_corrected_review_v1.png`: 배치도의 밭·나무 구역 수정 원본
- `SOURCE_WORKING_SET_MANIFEST.json`: 외부 작업 폴더 337개 파일의 크기·SHA-256 목록
- `CHECKPOINT_MANIFEST.json`: 체크포인트 파일별 SHA-256과 외부 작업본 목록의 해시

## 재현 및 검사

저장소 루트에서 아래 순서로 실행한다.

```powershell
python assets_unused/pending_review/personal_hanok_v3/map_camera_reconstruction/ildu-layout-plan-20260905/compose-sarangchae-selected-small.py
python assets_unused/pending_review/personal_hanok_v3/map_camera_reconstruction/ildu-layout-plan-20260905/build-next-batch-target-guides.py
python assets_unused/pending_review/personal_hanok_v3/map_camera_reconstruction/ildu-layout-plan-20260905/preflight-next-batch.py
python assets_unused/pending_review/personal_hanok_v3/map_camera_reconstruction/ildu-layout-plan-20260905/make-checkpoint-manifest.py --source "C:\dev\hangulsori\_codex_artifacts\ildu-layout-plan-20260905"
python assets_unused/pending_review/personal_hanok_v3/map_camera_reconstruction/ildu-layout-plan-20260905/verify_checkpoint.py
python assets_unused/pending_review/personal_hanok_v3/map_camera_reconstruction/ildu-layout-plan-20260905/verify_checkpoint.py --source "C:\dev\hangulsori\_codex_artifacts\ildu-layout-plan-20260905"
```

첫 번째 검사는 Git 체크포인트만으로 재현 가능하다. `--source`를 사용한 두 번째 검사는 보존 중인 외부 작업 폴더 337개 파일까지 크기와 SHA-256을 대조한다. 두 검사 모두 선택 원본과 투명 정본의 RGB 동일성, 알파 채널, 지도 크기·위치·협문 노출, 승인 범위 밖 변경, HTML 로컬 참조, 배치 출처, 다음 작업 입력 수와 원본 경로를 확인한다.

전체 시도·폐기 후보를 포함한 작업 폴더 `C:/dev/hangulsori/_codex_artifacts/ildu-layout-plan-20260905`는 이 체크포인트 작성 시 삭제하거나 변경하지 않았다. Git에는 다음 작업을 재개하는 데 필요한 승인 기준과 재현 파일만 보존한다.
