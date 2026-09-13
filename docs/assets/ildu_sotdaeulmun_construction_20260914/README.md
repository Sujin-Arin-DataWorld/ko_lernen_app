# 솟을대문 12단계 공정 아트 정본

Jin이 2026-09-14에 승인한 솟을대문 12단계 이미지다. 정본 원화 3번을 마지막 완성형으로 사용한다. 이전 솟을대문 원화의 정본 지정을 대체한다.

- 정식 PNG: `assets/illustrations/personal_hanok_v3/construction/sotdaeulmun/`
- 순서·한국어 문장·크기·SHA-256: `assets/data/ildu_sotdaeulmun_construction_art_v1.json`
- 스타일 정본 등록: `docs/assets/STYLE_LOCK.json`의 `canonSprites.sotdaeulmun`, `approvedConstructionSeries.sotdaeulmun`
- 미리 보기: 이 폴더의 `index.html`

## 조립과 공간

터와 통로 → 기초·초석 → 앞뒤 기둥 → 보·도리 → 서까래·처마 → 지붕 바탕 → 기와 → 바닥·통로 → 돌벽·회벽 → 창호·대문 → 주련·편액 → 완성.

앞뒤 기둥열과 깊이 방향의 보, 좌우 공간, 바깥에서 마당으로 이어지는 중앙 통로를 유지한다. 문짝 설치 전에는 통로 바닥과 안쪽 벽·문설주의 두께가 드러난다. 11단계의 작은 마감 자재를 정리하면 12단계 원화와 이어진다.

## 보존과 사용 범위

내장 `image_gen.imagegen`으로 생성한 11장과 사용자 원화의 바이트를 그대로 복사한 완성형 1장이다. 9장은 1447×1087, 3장은 1448×1086이며 전부 검정 배경 RGB PNG다. 리사이즈·재인코딩·투명화·색상 수정은 하지 않았다.

이번 등록은 승인된 공정 아트와 앱 번들 자산을 확정한다. 전체 지도 합성용 투명 레이어, 부재별 조립 애니메이션, 한국어 학습 완료에 따른 진행도 연결은 별도 구현 범위다. 완성형의 8방향 회전 자료는 이 12단계와 독립적으로 관리한다.

숨은 구조는 깊이를 고려한 교육용 표현이며 실측 복원 도면이 아니다. 각 단계의 미세한 위치·재질 차이가 있을 수 있으므로 픽셀 정합 레이어로 취급하지 않는다.

## 검증

`flutter test test/ildu_sotdaeulmun_construction_art_test.dart`는 실제 번들에서 12장 전부를 불러와 순서, SHA-256, PNG 크기, 마지막 정본 해시와 STYLE_LOCK 등록 일치를 검사한다.
