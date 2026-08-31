# 일두고택 솟을대문·행랑채 2D 8방향 v02 · 조감 시점

상태: `canonical_runtime_v08_promoted_2026-08-31`

## 기준

- 시각 기준: `sotdaeulmun_approved_jin_20260824.png`
- 구조 기준: 행랑채 평면도(약 7.56m × 4.06m), 좌·우측면도, 전체 배치도
- 현장 기준: 외부 정면, 안마당 후면, 측면 진입로, 정려 문패 사진
- 카메라: 약 28도 내려다보는 조감형 게임 시점, 방위각 45도 간격 8방향

## v01에서 바로잡은 구조

- 좌우를 얇은 담장으로 보지 않고 약 4m 깊이의 행랑채 방 몸체로 복원
- 옆면에서 온전한 지붕 경사와 깊은 처마, 돌·흙벽 측면이 보이도록 수정
- 안마당 쪽은 돌벽을 반복하지 않고 목재 창호·회벽·마루가 있는 방 전면으로 구성
- 솟을대문 중앙 통로의 실제 깊이, 외부 `忠孝傳家` 주련, 내부 정려 문패를 반영

## 파일

- `ildu_sotdaeulmun_8view_elevated_sheet_v02_transparent.png`: 실제 알파를 가진 4×2 검토 시트
- `transparent_views/`: 정면부터 시계방향으로 분리한 8개 PNG
- `ildu_sotdaeulmun_00_source_original_exact.png`: V3 원본의 바이트 동일 보존본
- `ildu_sotdaeulmun_8view_elevated_sheet_v02_raw.png`: 배경 제거 전 생성 원본
- `extract_checkerboard_alpha.py`: 밝은 체크무늬를 알파로 바꾸는 비생성 후처리
- `split_turnaround_sheet.py`: 4×2 시트를 8개 방향으로 분할하고 인접 셀 잔여물을 제거하는 후처리

## 검토 주의

`00_source_original_exact`만 원본과 바이트가 동일하다. 생성된 8방향은 원본·도면·현장 사진을 참조한 2D 변형이다. 작은 화면에서는 주련 글자와 정려 문패 글자가 축약되어 보일 수 있으므로, 최종 승격 전 사람의 시각·인게임 배치 승인이 필요하다.

## 자급식 참고 자료

- `references/canonical_source/sotdaeulmun_approved_jin_20260824.png`: 사람이 지정한 V3 시각 정본
- 원본 SHA-256: `161D23A981E8C0533F902933EF79C646A95F8D86C210CBA48FBD954AF7D4D687`
- `references/blueprints/`: 행랑채 정·배면, 평면, 좌우측면, 종횡단면, 앙시도, 와복도와 전체 배치도
- `references/photos/`: 외부 정면, 내부 문패, 문패 근접, 측면 진입로, 전체 마당 등 현장 사진 6장
- `runtime_views/`: 현재 앱에 등록하는 v08 384×512 런타임 8장과 SHA-256 동일
- `revisions/ildu_sotdaeulmun_v08_depth_150_runtime/`: 사용자가 최종 승인한 v08 원시트·투명 시트·검토 시트·개별 8방향
- `revisions/ildu_sotdaeulmun_v02_registered_runtime/`: 교체 전 앱 런타임 8방향 보존본

동일 바이트의 `(1)` 도면 중복본은 한 장만 보존했다. 행랑채 옆면은 얇은 담장이 아니라 평면도상 약 4.06m 깊이를 가진 방 몸체다. 외부 `忠孝傳家` 주련과 내부 정려 문패 5개는 건물 정체성 항목이다.

`transparent_views/`는 v02 시트 분할 당시의 역사적 작업 프레임이다. 현재 정본 런타임은 사용자가 선택한 v08이며, 원시트 SHA-256은 `35ee382980b3c094c07cec3269a4101afe1e1b3949bc11a8235ca4448c8af772`다. v08의 8개 정규화 프레임은 `runtime_views/`, v08 revision, 앱 런타임 세 위치에서 해시가 일치한다. 생성된 8방향을 V3 원본과 픽셀 동일하다고 표현하지 않는다.

상위 제작 계약과 검증 명령은 `../HANDOFF_SARANG_ANSARANG_SOTDAEULMUN.md`를 따른다.
