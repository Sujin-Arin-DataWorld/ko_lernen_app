# 일두 시즌 1 · 최종 결정과 상세 집필 기록

정리일: **2026-10-31, Europe/Berlin**. 대상 채팅: **초보자 커리큘럼 진행 상황 확인** (`01a18406-245e-7570-9379-62120de745d6`).

이 폴더는 이 채팅에서 만든 세계관·시나리오·교육 원고·RPG 대화·미술/영상 지침을 함께 읽는 시작점이다. 상세 원고를 요약으로 대체하지 않는다. 기존 `manuscripts/`, `reference/`, `production/`의 전문을 보존하고, 후속 Markdown과 제작 데이터도 [sources/](sources/)에 바이트 그대로 수록한다.

## 먼저 읽을 순서

| 문서 | 담긴 내용 |
|---|---|
| [최종 결정·수정 우선순위](FINAL_DECISIONS.md) | 사용자 확정 방향, v3.5 정본, 집필 제안, 거절/대체 이력의 구분 |
| [세계관과 이야기 바이블](WORLD_AND_STORY_BIBLE.md) | 인물·존재론·500년 연대기·세 공간·12단서·4막/10화·두 번의 대답 |
| [커리큘럼과 NPC 대화 진행](CURRICULUM_AND_NPC_FLOW.md) | 입문 28단원/A1.1 6단원, 100단원/16구간, 도움·오답·다음 날 복습, 이름에서 첫 재회까지 |
| [이미지·에셋·영상 제작 지침](ART_AND_MEDIA_DIRECTIVE.md) | C안, EN/DE, 실제 폰트와 생성 글씨의 구분, R16, 고정 인물, 이미지 우선, 모션/에필로그 |
| [상세 원고·출처 색인](DETAIL_INDEX.md) | 각 단원 전문과 후속 문서/JSON의 저장 위치·상태·해시 목록 |
| [보존 manifest](SOURCE_MANIFEST.json) | 후속 자료 원본 경로·SHA-256·저장 경로·문서 지위 |

## 이번 정리에서 확정하는 범위

- **세계관 정본:** [v3.5 전문](../reference/STORY_V3_5.md). 11동·128공정, 프롤로그 7장면+본편 10화, 핵심 단서 12개, 세 번의 귀환과 두 번의 대답을 보존한다.
- **사용자가 고른 제작 방향:** 내 이름의 주인공, 이어지는 NPC 대화, 학습 행동에 따른 반응, 짧은 연출, EN/DE 안내, 승인 C안과 고정 에셋, **이미지 생성 도구로 완성 앱 목업 이미지를 먼저 제작**한다. 외형 생성은 뒤로 미룬다.
- **상세 집필:** 입문 1~4의 28단원과 A1.1 6단원의 대사·문항·도움·오답·다음 날 복습을 전문으로 보존한다. 전체 100단원·128공정의 서사 연결은 별도 상세표를 보존한다.
- **수정 이력:** HTML 탐색본과 낮은 품질의 조합식 시안은 승인 기준에서 제외한다. 예전 계획의 제작 방법·수량·금지 조건 중 최신 요청과 충돌하는 부분은 [결정표](FINAL_DECISIONS.md)가 정정한다.

## 문서의 지위를 읽는 방법

**정본**은 v3.5가 정한 사실이다. **사용자 확정 방향**은 이 채팅에서 직접 요청하거나 수정한 제작 조건이다. **집필/편집 제안**은 그 조건에 맞춰 작성한 대사·컷·상태·번역 후보다. **거절/대체 기록**은 보존하되 구현 기준으로 쓰지 않는다.

문서를 main에 보관하는 것은 제안 전체의 사용자 승인, 이미지 품질 승인, 실제 앱 기능·미디어·학습 효과·기기·배포 완료를 뜻하지 않는다. 정지 목업은 실제 조작 증거가 아니다. 이 패키지의 JSON은 편집/집필 자료이며 런타임 카탈로그에 등록한 데이터가 아니다.

## 기존 전문으로 바로 이동

- [입문 1](../manuscripts/foundation-1-v35/README.md) · [입문 2](../manuscripts/foundation-2-v35/README.md) · [입문 3](../manuscripts/foundation-3-v35/README.md) · [입문 4](../manuscripts/foundation-4-v35/README.md)
- [A1.1 상세 원고](../manuscripts/a1-1-v35/README.md) · [중문 문지기](../manuscripts/a1-1-v35/LQ05_GATEKEEPER.md)
- [스토리텔러 마스터](../manuscripts/season1-rpg-v35/STORY_MANAGER_GUIDE.md) · [100단원 서사 전문](../manuscripts/season1-rpg-v35/LEVEL_STORY_100.md) · [128공정 서사 전문](../manuscripts/season1-rpg-v35/STAGE_STORY_128.md)
- [에필로그 A/B 전문·EN/DE·원문 부록](../manuscripts/season1-rpg-v35/EPILOGUES_10S.md)
- [챕터·NPC 이벤트 상세](../production/CHAPTER_EVENT_DESIGN.md) · [영상 상세](../production/VIDEO_PRODUCTION_PLAN.md) · [고정 에셋 목록](../production/asset-lock/ASSET_LOCK_LIST.md)

과거 문서의 절대 경로·시각·SHA·“현재” 표현은 **작성 당시의 관측**이다. 휴대 가능한 본문은 이 폴더의 상대 링크와 manifest로 찾는다. 다른 채팅의 CI·병합·배포 상태를 이 문서에서 대신 확정하지 않는다.
