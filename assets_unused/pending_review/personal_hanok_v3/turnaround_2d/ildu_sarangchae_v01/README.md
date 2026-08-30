# 일두고택 사랑채 2D 8방향 v01 · 조감 시점

상태: `canonical_work_package_promoted_2026-08-30`

v01 생성 시트와 원래 분리 프레임은 작업 이력으로 그대로 보존한다. 이 프레임은
프레임별 잘린 크기이며 현재 앱의 384×512 등록본이 아니다. 이후 정렬·등록된 v02
전체 작업본은 `revisions/ildu_sarangchae_v02_runtime/`, 최신 앱 프레임은
`runtime_views/`에 분리해 보존한다.

## 기준

- 시각 기준: `sarangchae_try07_edit.png`
- 구조 기준: 사랑채 지붕평면도, 정면도, 우측면도
- 후면과 회전 구조 참고: 기존 사랑채 3D 턴어라운드. 재질과 렌더 스타일은 사용하지 않았다.
- 카메라: 약 28도 내려다보는 조감형 게임 시점, 방위각 45도 간격 8방향

## 파일

- `ildu_sarangchae_8view_elevated_sheet_v01_transparent.png`: 실제 알파를 가진 4x2 검토 시트
- `transparent_views/`: 정면부터 시계방향으로 분리한 8개 PNG
- `ildu_sarangchae_00_source_original_exact.png`: V3 원본의 바이트 동일 보존본
- `ildu_sarangchae_8view_elevated_sheet_v01_raw.png`: 배경 제거 전 생성 원본
- `extract_checkerboard_alpha.py`: 밝은 체크무늬만 연결 영역으로 판별해 알파로 바꾸는 비생성 후처리

## 고정한 구조

- 14.545 m 길이의 6칸 본채와 우측 돌출 2칸 누마루가 이루는 비대칭 ㄱ자 평면
- 본채 팔작지붕과 누마루 지붕이 만나는 연결 골
- 높은 전면 장대석 기단과 중앙 돌계단, 낮은 배면 기단
- 누마루 난간과 안상 무늬, 상부 원기둥과 하부 팔각기둥
- 조각 석재 주초를 가진 두 활주

## 검토 주의

`00_source_original_exact`만 원본과 바이트가 동일하다. 생성된 8방향은 원본·도면·기존 구조 모델을 참조한 2D 일러스트 변형이므로 세부 창호 수, 기둥 간격, 지붕 골과 후면 개구부는 사람이 최종 승인해야 한다. 런타임 승격 전 검토용이다.

## 자급식 참고 자료

- `references/canonical_source/sarangchae_try07_edit.png`: 사람이 지정한 V3 시각 정본
- 원본 SHA-256: `F2C01142F465B9353E0B9546A00F167891753039D9C910620D83CD924A077212`
- `references/blueprints/`: 사랑채 정면·우측면·지붕평면·천정평면·기둥·난간·가구 상세와 배면 사진
- `references/structural_model/`: 후면과 ㄱ자 연결 확인에 필요한 선별 구조 모델 자료
- `handoff/construction_pilot/`: 다음 건물의 단계별 건설 화면을 위한 승인 문서와 구현 스냅샷
- `runtime_views/`: 패키지 작성 시점 최신 `main`의 384×512 런타임 8장과 SHA-256 동일
- `revisions/ildu_sarangchae_v02_runtime/`: 현재 런타임의 등록 작업 계보

사랑채 3D 자료는 구조 참고만 허용한다. 색감·재질·기와·선화는 반드시 canonical source를 따른다. 도면과 3D가 충돌하면 도면이 우선이다.

상위 제작 계약과 검증 명령은 `../HANDOFF_SARANG_ANSARANG_SOTDAEULMUN.md`를 따른다.
