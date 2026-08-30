# 사랑채 구조 모델 참고 규칙

이 자료는 2D 8방향의 후면과 비대칭 ㄱ자 연결 관계를 이해하기 위해 선별 보존했다.

- 허용: 평면 깊이, 후면 가림, 본채와 누마루의 연결, 방향별 실루엣 확인
- 금지: 3D 렌더의 색, 재질, 기와, 조명, 카메라를 V3 2D 정본으로 채택
- 충돌 시: 사랑채 도면이 우선
- 시각 표현 충돌 시: `references/canonical_source/sarangchae_try07_edit.png`가 우선

포함 파일:

- `ildu_sarangchae_final_v03.blend` — 편집 가능한 구조 모델
- `ildu_sarangchae_final_v03.glb` — 교환용 구조 모델
- `ildu_sarangchae_turnaround_sheet.png` — 빠른 방향 확인용
- `final_v03_manifest.json` — 모델 생성 당시 구조·파일 기록
- `build_ildu_sarangchae.py` — 생성 스크립트 스냅샷
- `README.md` — 원래 3D 패키지 설명
