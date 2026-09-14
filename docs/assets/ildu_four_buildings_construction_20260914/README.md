# 네 건물 공정 이미지 승인 정본

2026-09-14 Jin의 “너무 잘햇어ㅎㅎ 커밋푸시 메인에 병합하고 이걸로 라이브 되게해줘.”
승인에 따라 중문채 12장, 아래채 12장, 안채 14장, 안채 창고 11장을 채택했습니다.
`promotion_manifest.json`의 49개 행이 승인 원본, 앱 PNG, 공개 웹 PNG를 같은 SHA-256으로 연결합니다.
원화는 리사이즈, 배경 제거, 색 보정, 재생성 없이 그대로 사용합니다.

- 앱 목록: `assets/data/ildu_construction_art_v1.json`
- 앱 화면: 한옥 탭 → 한옥 짓기 (`/hanok/construction`)
- 공개 보기: `https://hangul-sori.com/hanok/construction/`
- 형태·재질 승인 등록: `docs/assets/STYLE_LOCK.json`의 `F-D-ildoo.approvedConstructionSeries`
- 입력 원화와 제작 프롬프트: `assets_unused/pending_review/personal_hanok_v3/four_buildings_construction_29deg_v1/`

완성 8면도와 지도 배치는 교체하지 않습니다. 공정을 넘기거나 문장을 연습해도
XP, 한옥 건설 진행도, 다음 건물 권한을 부여하지 않습니다.
기존 협문·창고 14장과 해당 원본·알파·24 MiB 검사는 유지합니다.
이번 네 건물의 49장은 1536×1024 RGB PNG, 합계 98,686,598바이트이며 별도의 96 MiB 상한을 둡니다.

승인은 현재 생성 원화의 채택입니다. 29°는 제작 목표 시점이고 실측한 3D 카메라 값은 아닙니다.
중문채 초기 기둥·마루 기둥축과 일부 터 외곽의 미세한 단계 차이를 포함하며,
공통 3D 부재 좌표로 무변형을 증명했다는 뜻이 아닙니다.
이전 제작 폴더의 `art_review.json`, `asset_audit.json`, README는 채택 전 검수 이력입니다.
도면의 미확인 내부 상세는 교육용 재구성으로 유지합니다.
