# 일두고택 안사랑채 2D 8방향 v03 · 조감 시점

상태: `canonical_work_package_promoted_2026-08-30`

v03 생성 작업본은 `transparent_views/`에 그대로 보존한다. 이후 고조감 조정과
바닥 뿔·쐐기 부산물 제거를 거친 v05가 현재 런타임이므로, v05 전체 작업본은
`revisions/ildu_ansarangchae_v05_runtime/`, 최신 앱 프레임은
`runtime_views/`에 분리해 보존한다. v03과 현재 런타임을 같은 해시라고 주장하지 않는다.

- v02의 정면에 가까운 시선을 약 28도 내려다보는 조감형 게임 시점으로 올렸다.
- 방위각은 정면부터 45도 간격의 8방향을 유지한다.
- `ildu_ansarangchae_8view_elevated_sheet_v03_transparent.png`가 실제 알파를 가진 검토 시트다.
- `transparent_views/`에 384x512 크기의 8개 방향 PNG가 있다.
- `ildu_ansarangchae_00_source_original_exact.png`는 V3 원본의 바이트 동일 보존본이다.
- 시각 화풍은 원본, 보이지 않던 지붕과 평면 구조는 별당 도면을 기준으로 했다.
- 3D 모델과 3D 렌더는 사용하지 않았다.

생성된 8방향 이미지는 원본과 도면을 참조한 2D 변형이며, 원본과 픽셀 단위로 동일하지 않다. 창호·기둥·굴뚝 가림 관계는 런타임 승격 전에 사람의 최종 검토가 필요하다.

## 자급식 참고 자료

- `references/canonical_source/byeoldang_ansarang_try01 (2).png`: 사람이 지정한 V3 시각 정본
- `references/blueprints/`: 별당 정·배면, 좌우측면, 평면, 지붕평면, 천정평면, 창호 및 단면 도면 10장
- 원본 SHA-256: `58BDC53622EB0E47F874A11FBF0314BCCC40AA168DC1B480C00ABEE60D01EF39`
- `byeoldang_try02_colonnade.png`는 위 canonical source와 SHA-256이 같은 중복 별칭이므로 패키지에 다시 복사하지 않았다.
- `runtime_views/`: 패키지 작성 시점 최신 `main`의 384×512 런타임 8장과 SHA-256 동일
- `revisions/ildu_ansarangchae_v05_runtime/`: 현재 런타임의 작업 계보를 증명하는 v05 전체 패키지

구조는 도면, 색감·재질·기와·목재·회벽 표현은 canonical source를 따른다. v03 제작에는 3D 모델이나 3D 렌더를 사용하지 않았다.

상위 제작 계약과 검증 명령은 `../HANDOFF_SARANG_ANSARANG_SOTDAEULMUN.md`를 따른다.
