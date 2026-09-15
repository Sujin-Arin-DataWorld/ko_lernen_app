# 터·돌담·솟을대문·화장실·곳간채 공정 아트 정본

2026-09-15 Jin이 건물·흙바닥과 돌담을 쌓는 과정을 main에 보존하도록 승인했다. **돌담이 맵 외곽을 만드는 기존 프로토타입은 크기와 형상이 맞지 않아 승인에서 제외됐다.**

정본은 [construction_catalog.json](construction_catalog.json)과 `docs/assets/STYLE_LOCK.json`의 `F-D-ildoo.approvedConstructionSeries`다.

| 공정 | 장수 | 정본 경로 |
|---|---:|---|
| 흙바닥 정리 | 6 | `assets/illustrations/personal_hanok_v3/construction/site/` |
| 돌담 쌓기 | 8 | `assets/illustrations/personal_hanok_v3/construction/wall/` |
| 솟을대문 | 12 | `assets/illustrations/personal_hanok_v3/construction/sotdaeulmun/` |
| 화장실 | 12 | `assets/illustrations/personal_hanok_v3/construction/toilet/` |
| 곳간채 | 12 | `assets/illustrations/personal_hanok_v3/construction/gokgan/` |

새 PNG 38장(76,907,106bytes)과 기존 main 대문 12장(18,180,925bytes)을 연결한다. 원본 바이트·크기·카메라·색을 변경하지 않았다. 같은 PNG를 원본 보관 폴더에 중복 저장하지 않으며, [provenance.json](provenance.json)의 `originalCopies`가 원본 경로와 동일 바이트의 정본 파일을 연결한다.

`prompts/`의 40개 JSON은 수정하지 않은 과거 생성 기록이다. 그 안의 절대경로, 예전 지도 정렬 지시, 교체된 시도는 현재 승인·런타임 의존성·다음 작업 지시가 아니다. 각 단계의 최종 파일은 카탈로그의 SHA256으로 판별한다.

이 패키지는 **누적 공정 이미지**다. 이미지의 방·통로·벽 두께와 앞뒤 부재는 유지한다. 그림 전체가 투명한 맵 부품이나 3D 메시인 것은 아니며, 마지막 단계가 완성 8면도·문 열기 애니메이션의 검증을 대신하지 않는다. 기존 한국어·영어·독일어 캡션은 제작 자료로 보존하며 정규 평가 연결 승인과 구분한다. 방치된 터는 앱의 가상 시작 설정으로, 일두고택의 실제 과거 모습이라는 뜻이 아니다.

현재 카탈로그는 앱 번들 밖에 있으며 새 그림 디렉터리도 `pubspec.yaml`에 등록하지 않는다. 실제 Flutter 소비 화면과 CP 자산 전달을 연결하는 시점에 같은 ID·SHA를 사용한다. 학습·소유·진도 저장은 이 패키지가 수행하지 않는다.

지도 후속 작업은 [돌담 외곽선 인수인계](../../superpowers/plans/2026-09-15-ildu-wall-outline-handoff.md)를 따른다. 기존 프로토타입 `IlDuSettlementWallClipper` 좌표를 정본으로 재사용하지 않는다.

검증: `python -m unittest tool.test_ildu_settlement_art -v`.
