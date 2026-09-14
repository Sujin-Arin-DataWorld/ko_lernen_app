# Lernenweg × 일두고택 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement task-by-task, with separate specification and code review. This document fixes sequencing and acceptance contracts. Product review is not permission to bypass incomplete assessment publication, visual review, or repository commit/push rules.

**Goal:** 검증된 한국어 학습을 149단계 한옥 복원, 태고·조이의 방문, 의미 있는 공간 사용으로 연결한다.

**Architecture:** 기존 학습·계정 저장이 권한의 근거다. 별도 복원 서비스가 안정적인 stage ID로 획득·조립 상태를 관리하고, NPC와 그림은 이를 표시한다. 기존 5탭·소유권·음성·자산 전달 구조에 기능을 연결한다.

**Tech Stack:** 현재 저장소의 Flutter/Dart, 기존 로컬 저장·Firebase 동기화, JSON 카탈로그, 승인 PNG/WebP·캐릭터 클립. Android 자산 전달은 CP S5의 Flutter deferred components를 사용한다.

**Spec:** `../specs/2026-09-15-ildu-lernenweg-final-design.md`

## Global Constraints

- 149 = A1 42 + A2 36 + B1 37 + B2 34. C1/C2 새 공정 0.
- 13챕터·39개 주요 조립 장면·별도 선택 생활 의뢰 26개.
- 정규 평가 묶음 OR 검증된 mapped unit 완료. 같은 stage ID로 중복 지급 방지.
- Placement·XP·출석·NPC·장식·스티커·조립 퍼즐은 학습 권한을 생성하지 않는다.
- 모든 일반 학습과 catch-up 경로는 같은 정규 평가와 버전 검증을 사용한다.
- 기존 진도와 소유권은 보존한다. 과거 그림 공개와 새 수동 조립 증거를 구분한다.
- 원본을 재채색하지 않는다. 필수 한국어에 낯선 전통 사물 이름을 넣지 않는다.
- 현재 5탭 유지. 앱에 연결하며 별도 웹사이트를 만들지 않는다.
- 새 마이크 판정·AI 자유발화 채점 엔진을 이번 공사 연출에 몰래 추가하지 않는다.
- 커밋·push·병합은 현재 사용자 승인 범위를 확인한다. 2026-09-15 사용자가 이 계획·인수인계 문서 묶음의 main 병합을 요청했다. 미래 앱 구현의 출판 게이트는 별도로 유지한다.

## 검토 기준과 정확한 남은 일

기준 SHA: `a185bba83f1696e0f33656d02bb96d1049a55f7f`.

문서 통합 전 재확인: `d8776426f1936df47bed6974eeabde4324771467`의 C7 #323을 반영했다. 해당 diff는 도구·테스트·AGENTS 수정이며 현재 정규 unit/공정 카탈로그는 바뀌지 않았다.

| 항목 | 현재 근거 | 계획에서 할 일 |
|---|---|---|
| 149 원본 | 동봉 CSV 149행, 파일·SHA256 전부 대조 | 안정 ID와 승인 범위를 보존해 통합 |
| 149 unit 배정 | 실제 정규 unit ID로 CSV 작성 | 실제 평가 묶음과 의미 검수 추가 |
| 평가 묶음 | 전체149의 확정 연결은 없음 | 아래 Task 1의 첫 필수 산출물 |
| 사랑채16·4채49·안사랑/사당34 | 기준 main 카탈로그 | 합계99의 기존 runtime 아트 재사용 |
| 터·담·대문·화장실·곳간50 | `toilet-store-wall-plan-20260914`의 혼합 WIP | 필요한 아트·카탈로그만 검토해 통합, UI WIP 일괄 병합 금지 |
| B2 비율34 | #317 이후 main에 투영·영수증 연결 | 새 고정 ID 규칙으로 전환, 소유 보존 |
| S1·운영 B1 | main에 병합됨 | 같은 작업을 중복 구현하지 않음; 운영 실측은 별도 |
| C7 | #323이 d8776426에 병합됨 | 최신 도구의 동작을 사용하며 중복 수정하지 않음 |
| C8 | 별도 브랜치가 존재 | 매 작업 시작 시 최신 상태·파일 소유 확인 |

참고용 원본 정리 commit `bbc0a8d119d864b0a3797574e46e68bd775c1047`는 앞선 작업에서 이미 push됐다. 이 계획을 위해 같은 원본 정리를 다시 push하지 않는다. 실제 구현 시작 때는 최신 remote와 포함 여부를 다시 확인한다.

## 파일 책임과 인터페이스

아래 새 경로는 구현 때 만들 경로다. 지금 존재하는 앱 코드라고 설명하지 않는다.

| 새 파일 | 책임 |
|---|---|
| `assets/data/ildu_restoration_v1.json` | 149개 stable ID·정규 unit/평가 연결·버전·조립 선행조건 |
| `assets/data/ildu_story_v1.json` | 13챕터·39조립 장면·26생활 의뢰·말투·배치 조건 |
| `lib/models/restoration.dart` | 불변 stage·권리·조립·snapshot 형식 |
| `lib/services/restoration_catalog.dart` | 카탈로그 해석·검증 |
| `lib/services/restoration_evidence_adapter.dart` | 기존 검증된 학습 snapshot/정규 평가 증거 해석 |
| `lib/services/restoration_progress_service.dart` | 계정 범위 재계산·멱등 저장·조립 적용 |
| `lib/services/hanok_quest_director.dart` | 방문 선택·의뢰 상태·미루기·재방문 |
| `lib/data/hanok_presentation_catalog.dart` | 기존 그림·클립·소품의 상황별 선택 |
| `lib/services/hanok_asset_resolver.dart` | CP S5 전달 상태와 실제 asset path 연결 |
| `lib/widgets/ildu_assembly_scene.dart` | 권리 있는 부재의 깊이 있는 조립 표시와 대체 조작 |
| `lib/screens/ildu_restoration_screen.dart` | 복원 목록·진행 장면·완성 공간·방문 진입 |

인터페이스에서 고정할 이름과 역할:

```dart
// Planned public seams; exact model serialization is frozen in Task 1/2.
abstract interface class RestorationProgressService {
  Future<RestorationSnapshot> reconcile();
  Future<RestorationSnapshot> assemble({
    required String stageId,
    required String commandId,
  });
}

abstract interface class HanokQuestDirector {
  Future<HanokQuestSnapshot> read();
  Future<HanokQuestSnapshot> accept(String questId);
  Future<HanokQuestSnapshot> postpone(String questId);
  Future<HanokQuestSnapshot> complete(String questId);
}

abstract interface class HanokAssetResolver {
  Future<HanokAssetAvailability> ensureReady(String chapterId);
}
```

`RestorationSnapshot`는 획득 ID·조립 ID·과거 보유 공간·저장 상태를 가진다. `HanokQuestSnapshot`는 수락·미루기·완료·처음 보기/재방문 기록만 가진다. `HanokAssetAvailability`는 ready/downloading/unavailable/error 및 재시도 가능 여부를 표현한다. 세 서비스는 생성 시 기존 계정 경계에 결합되며 계정 변경 후 이전 인스턴스 쓰기를 거부한다. Widget에는 raw ‘award’ API를 노출하지 않는다.

`complete(questId)`는 조건 재검사 요청이다. 호출자에게 완료 불리언·점수를 받지 않는다. 카탈로그의 선언에 따라 기존 정규 평가 또는 조립 snapshot을 재검증하며 이미 충족된 수락 이전 증거도 인정한다. 순수 대화 감상은 ‘이야기를 봄’ 조건으로 별도 기록하고 학습 숙달·건축 지급으로 전환하지 않는다.

## Task 1 — 149 연결표와 출판 게이트

**Files:** 새 `assets/data/ildu_restoration_v1.json`, `tool/validate_ildu_restoration.py`, `tool/test_validate_ildu_restoration.py`, `docs/content/ildu_restoration_assessment_review.csv`. 입력은 동봉 배정 CSV, `curriculum_manifest.json`, `learning_phases.json`, `phase_tasks.json`, 각 공정 카탈로그다.

**Consumes:** 기존 stage ID/hash, 정규 unit ID/canDo, 기존 평가 정의·통과 로직.
**Produces:** 149개 검수된 연결과 결손 목록, 내용 버전별 허용 기준, release publication gate.

- [ ] 배정 CSV의 모든 경로와 hash를 다시 검증하고, 50단계 WIP의 필요한 파일과 승인 이력을 개별 대조한다.
- [ ] 각 stage에 의미가 맞는 정규 평가 묶음을 연결한다. `practiceUnitIds`는 탐색 힌트로만 쓴다. 실제 현재 한국어 목표를 읽는다.
- [ ] 같은 수준의 다른 Phase 평가도 의미가 맞으면 검수 후 명시 연결한다. 안 맞으면 CP에 정확한 결손을 전달한다.
- [ ] `a1_07_contact_address`의 연락 방법, `a1_11_titles_relationships`의 음악·콘텐츠 선호 등 ID 이름과 현재 의미가 다른 사례를 우선 검수한다.
- [ ] 문항별 hash/revision/rubric/evaluator·통과 조건을 저장한다. 기존 미승인 productive catalog를 통째로 승인하지 않는다.
- [ ] 149개 일반 경로와 상급 신규 진입 catch-up 경로를 별도로 계산한다. 한쪽만 완성되면 전체 publish를 거부한다.
- [ ] 아트 승인 상태, 의미 검수 상태, runtime publish 상태를 구분한다. 단순 파일 존재를 의미 검수로 승격하지 않는다.

검증 명령: `python -m unittest tool.test_validate_ildu_restoration` 및 `python tool/validate_ildu_restoration.py --check --require-published`.

검증기는 duplicate stage ID, missing unit, missing assessment, unapproved revision, semantic review 미완료, cycle, unreachable catch-up을 각각 실패로 반환해야 한다. 149개 전부 검수 전에는 마지막 명령이 실패하는 것이 정상이다. 이 실패를 막으려고 예외 목록에 전부 넣지 않는다.

## Task 2 — 기존 보유 보존과 영구 권리

**Files:** 위 새 restoration model/catalog/evidence/progress 서비스. 기존 `course_mastery_service.dart`, `course_progress_service.dart`, `storage_service.dart`, `account/account_reconciliation.dart`, `app_startup_coordinator.dart`, `cloud_sync.dart`는 한 명의 통합 담당자가 변경한다. 테스트는 `test/restoration_progress_service_test.dart`, `test/restoration_migration_test.dart`, `test/restoration_account_sync_test.dart`.

**Consumes:** Task 1의 승인 카탈로그, 기존 정규 완료와 평가 기록, 기존 사랑채/B2 보유 근거.
**Produces:** 계정별 획득·조립 원장, 보존 이행 영수증, 미완료 저장 복구.

- [ ] legacy 세대 전환 전에 기존 보유를 캡처하는 모든 진입점을 테스트로 먼저 고정한다.
- [ ] 동일 stage에 평가 묶음 후 unit 완료, unit 완료 후 평가 묶음, 두 경로 동시 완료를 넣어 최종 권리가 1개인지 확인한다.
- [ ] 학습 완료 직후 강제 종료, 권리 저장 중 실패, 알림 표시 중 종료를 각각 재현하고 저장된 학습 증거에서 복구한다.
- [ ] 새 ID 원장을 추가하되 영수증·화면·그림 선택을 증거로 읽지 않는다. 과거 소유 보존은 별도 provenance로 기록한다.
- [ ] 계정 A 저장 중 B로 전환, 익명→연결, 두 기기 동기화, 복원 충돌, 계정 삭제를 기존 직렬화·generation 계약에 붙인다.
- [ ] 새 내용 버전이 과거에 확정된 권리를 삭제하지 않고, 알 수 없는 출처의 완료 플래그를 합치지 않는지 검증한다.

검증: `flutter test test/restoration_progress_service_test.dart test/restoration_migration_test.dart test/restoration_account_sync_test.dart test/course_mastery_sync_test.dart test/hanok_account_reconciliation_test.dart`.

통과 기준은 진도손실0·중복0·계정 간 누출0·보존 실패의 조용한 초기화0이다. 보존된 완공 공간에는 재조립을 강요하지 않는다.

## Task 3 — Lernenweg·결과·Hanok의 실제 앱 연결

**Files:** `lib/main.dart`, `lib/screens/course_mission_screen.dart`, `lib/screens/sori_stage/sori_stage_today_screen.dart`, `lib/screens/sori_stage/sori_stage_hanok_screen.dart`, `lib/screens/sori_stage/sori_stage_reward_receipt_sheet.dart`, `lib/services/sori_stage_reward_receipt_service.dart`, `lib/services/sori_stage_progression_service.dart`, 새 복원 화면. 테스트 `test/restoration_app_flow_test.dart`와 기존 routing/receipt 테스트.

**Consumes:** Task 2의 snapshot. **Produces:** 현재 의뢰/다음 재료 안내, 지금 만들기/나중에 만들기, 실제 복원 진입.

- [ ] 현재 preview 라우트와 제작 학습 갤러리를 확인하고 실제 복원 진입을 추가한다. 갤러리·리뷰·demo는 읽기 전용으로 유지한다.
- [ ] 첫 미완료 목표·다음에 받을 재료·학습으로 돌아가는 버튼을 연결한다.
- [ ] 지금 만들기와 나중에 만들기의 획득 ID 결과가 동일한지 검증한다.
- [ ] 현재 사랑채16/B2비율34 투영을 새 ID 기반 snapshot으로 대체한다. 두 영수증 경로가 중복 알림을 만들지 않게 한다.
- [ ] 의뢰 수락 전 정규 학습, 앱을 재시작한 뒤 결과 확인, 학습 중 친구 방문을 각각 검증한다.
- [ ] 활성 평가 중 발생한 방문은 새 표식·대화 없이 대기하고 평가 종료 뒤 나타나는지 검증한다.

검증: `flutter test test/restoration_app_flow_test.dart test/hanok_preview_routing_test.dart test/sori_stage_reward_receipt_service_test.dart test/sori_stage_reward_receipt_sheet_test.dart`.

## Task 4 — 39개 조립 장면과 출입 깊이

**Files:** 새 `ildu_assembly_scene.dart`, `ildu_story_v1.json`, `ildu_restoration_screen.dart`; 기존 `ildu_world_screen.dart`, `ildu_world_projection_adapter.dart`, `lib/data/ildu_turntable_catalog.dart`; 해당 아트 카탈로그와 필요한 승인 에셋. 테스트 `test/ildu_assembly_scene_test.dart`, `test/restoration_spatial_flow_test.dart`.

**Consumes:** 획득 ID, authored anchor/occlusion, 실제 단계 그림. **Produces:** 3종 공통 조작·39장면·구조 선행조건·완공 회전과 출입.

- [ ] 먼저 터·담·대문9장면을 각 실제 stage ID와 연결한다. 잔해/돌/기둥/문 부재 위치는 정본 공간에서 지정한다.
- [ ] 잘못 놓은 부재는 권리를 소모하지 않는다. 도움 버튼은 같은 허용 결과를 만든다.
- [ ] 연속된 획득 단계만 묶어 적용하고 단계별 조립 기록을 남긴다. 중간 종료 후 중복 적용을 막는다.
- [ ] 대문 바깥→문턱→마당의 이동·가림·역방향 복귀를 실제 화면으로 검증한다.
- [ ] 사랑채 8면도와 솟을대문 8면도/문 열기 결손만 보완한다. 없는 문 상태를 공정 프레임으로 대체하지 않는다.
- [ ] 나머지10챕터30장면에 같은 조작을 적용하되 실제 방·벽·문 구조를 각각 검수한다.

검증: `flutter test test/ildu_assembly_scene_test.dart test/restoration_spatial_flow_test.dart test/ildu_turntable_catalog_test.dart`; 폰·태블릿에서 문 통로와 앞뒤 기둥을 육안 확인한다. 조작 위치·48dp 대체 버튼·큰 글자·motion off의 완료 경로를 함께 검증한다.

## Task 5 — 친구 방문·의뢰·기존 에셋 다양성

**Files:** 새 quest director/presentation catalog/story JSON; 기존 `lib/data/sticker_catalog.dart`, `lib/widgets/sori/character_clip.dart`, `lib/widgets/sori/mascot.dart`, `placed_decoration.dart`, `decoration_reward_service.dart`, `room_layout_service.dart`, `ildu_decoration_placement_service.dart`는 기존 계약을 재사용한다. 테스트 `test/hanok_quest_director_test.dart`, `test/hanok_presentation_catalog_test.dart`, `test/restoration_optional_quest_test.dart`.

**Consumes:** 조립된 공간·동행 선택·기존 소유·media preference. **Produces:** 26개 선택 의뢰·특별 방문·안정적인 추천·상황별 표현.

- [ ] 스펙의 26의뢰와 4특별 방문을 stable ID로 작성하고 KO→DE/EN을 검수한다. 낯선 전통 물건 이름을 필수 답으로 넣지 않는다.
- [ ] 보지 않은 의뢰 우선, 미루기, 직접 목록, 모두 본 뒤 재방문을 구현한다.
- [ ] 오프라인 재시작·현지 날짜 변경·시계 역행·두 기기에서 의뢰 소실·중복 첫 보상이 없는지 검증한다.
- [ ] 30스티커/36데코 사용표를 작성하고 각 항목의 상황·임시 소품/소유 배치·제외 이유를 기록한다.
- [ ] 같은 의미의 승인 대안이 있을 때 연속 반복을 피하고 대화 중 그림은 고정한다. 각 친구4종·각 챕터 비캐릭터1종 수용 기준을 검사한다.
- [ ] 전체26의뢰를 미루거나 건너뛴 상태에서149완공을 검증한다. 의뢰 director가 권리 API를 호출하지 못하도록 경계를 검사한다.
- [ ] `complete(questId)`를 조건 없이 직접 호출해도 연습 완료가 생기지 않고, 수락 전 유효 증거로는 완료되는지 검사한다. ‘이야기를 봄’ 기록이 학습·건축 권리를 만들지 않는지도 확인한다.
- [ ] 진단·UX 이벤트 payload에서 답변 원문·녹음·자유 입력·평가 객체가 빠지고 허용된 ID·상태·오류 코드만 나가는지 검증한다. 기존 telemetry 동의 철회도 적용한다.

검증: 위 새 테스트와 `test/mascot_asset_lock_test.dart`. 지속적인 NEW 배지, 보지 않은 날의 벌점, 한옥 권리 지급, 임의 장식 소유 부여가 있으면 반려한다.

## Task 6 — CP S5 자산 전달 통합

**Files:** 새 resolver와 CP S5 담당자의 `pubspec.yaml`·Android 모듈·loading unit 설정. 자산 경로·hash 목록은 Task 1에서 공유한다. 테스트 `test/hanok_asset_resolver_test.dart`, `integration_test/ildu_asset_delivery_test.dart`.

**Consumes:** 실제149파일의 크기/hash/앵커·공통소품. **Produces:** 기본 앱/필요시 받는 팩의 한 가지 전달 계약.

- [ ] CP 담당자와 chapter→pack 경계를 정하고 동일 그림 중복 포함을 검사한다.
- [ ] Android profile/release에서 실제 지연 설치를 시험한다. debug의 성공을 팩 설치 증거로 쓰지 않는다.
- [ ] 최초 설치·다운로드 취소·재시도·저장 공간 부족·업데이트·받은 팩의 오프라인 재진입을 검증한다.
- [ ] 그림 준비 실패 중에도 정규 학습과 권리 저장이 계속되고, 나중에 같은 단계로 돌아오는지 검사한다.
- [ ] App Bundle Explorer의 기본 다운로드·기기별 다운로드·설치 크기를 따로 기록한다. CP 기본 모듈150MB 목표를 실제 전달 단위로 측정한다.
- [ ] iOS 번들 resolver와 Web 개발용 resolver도 같은 chapter/asset ID를 반환하게 한다.

공식 근거: https://docs.flutter.dev/perf/deferred-components. Flutter는 Android dynamic feature modules로 전달하며 전체 AAB를 다시 빌드·업로드한다. 이 계획은 별도 OTA 콘텐츠 배포를 도입하지 않는다.

## Task 7 — 전체 검증과 상용화 판정

**Files:** `integration_test/ildu_restoration_journey_test.dart`, 관련 CI 검증 및 기존 CP 평가 기록. 루트 UI가 달라지면 기존 `docs/UIUX_BIBLE_APPLICATION_EXECUTION_LOCK.md`와 screenshot inventory를 같은 작업 범위에서 갱신한다.

- [ ] 신입 A1→B2 일반 학습으로149단계, B2 신규 진입→동일 정규평가 catch-up으로149단계를 각각 완료한다.
- [ ] 첫26단계 체험은 별도 중간 수용 기준으로 기록한다. 최종 completion/RC로 표시하지 않는다.
- [ ] 기존 사용자·오프라인·종료 복구·두 기기·선택의뢰0회·motion off 조합을 검증한다.
- [ ] 외국인 학습자가 별도 설명 없이 학습→재료→조립→다음 목표를 이해하는지 확인한다. 첫 평가에서는 DE/EN·신입/상급 진입 조합을 포함한 최소8명으로 관찰하고, 8명 중6명 이상이 도움 없이 첫 흐름을 완주하는 것을 초기 UX 기준으로 삼는다. 이는 학습 효과의 통계적 증명이 아니다.
- [ ] ‘더 하고 싶다’ 평가는 다음 의뢰를 자발적으로 여는 행동·그 이유·중단 이유로 기록한다. 평균 체류시간만으로 성공을 선언하지 않는다.
- [ ] CP A1/A2 커버리지·B1문법·전레벨 콘텐츠 검수·음성·보안·비용·접근성·스토어 경로를 통과한다.
- [ ] `flutter analyze`, 전체 테스트, 필요한 Linux goldens/실기기 검증을 정확한 PR SHA로 수행하고, 병합했다면 정확한 main SHA로 재확인한다.
- [ ] 동의한 코호트의14일 crash-free≥99.5%, ANR<0.47%, 진도손실0을 후보 빌드 범위·분모와 함께 판정한다. 심각한 수정이 있으면 영향받은 후보의 관찰 근거를 갱신한다.

## 병렬 작업과 일정

임계경로는 `Task1 계약/평가 → Task2 권리 → [Task3 앱·Task4 조립·Task5 의뢰·Task6 전달] → Task7 전체 검증/CP 수렴 → 후보 관찰`이다. Task1의 전체 의미 검수와 추가 아트는 계약이 고정된 뒤 병렬로 진행할 수 있다. 완료하지 않은 평가 연결은 정식 publish에서 제외한다.

첫 작업 묶음에서 의미검수 통과·반려 수정·아트 보완·기기 검증에 걸린 시간을 측정한다. 이 처리량과 실제 가용 담당자로 예상일을 갱신한다. 10주 또는 앞서 추정한7~8주를 확정 약속으로 쓰지 않는다. 콘텐츠 사람 검수와14일 관찰은 단순 코드 병렬화로 제거하지 않는다.

각 작업자는 좁은 인터페이스 단위로 구현하고 별도 에이전트가 스펙 일치와 코드 품질을 각각 검토한다. 전체계를 동시에 리팩터링하지 않는다. 매 웨이브 시작에 최신 main·관련 활성 작업·정확한 변경 파일을 확인한다. 자동 조정 메시지는 사용자의 목표 변경 또는 publish 승인이 아니다.

## Claude에게 전달할 메시지 — 계획에만 포함, 아직 전송하지 않음

> Lernenweg와 일두고택 연결의 최종 제품 방향을 정리했습니다. 의미·아트 검토 기준은 `a185bba83f1696e0f33656d02bb96d1049a55f7f`, 문서 통합 기준은 C7 #323을 포함한 `d8776426f1936df47bed6974eeabde4324771467`입니다. S1 안정성 수정·운영 B1·안사랑채/사당 PR #317도 이미 포함돼 있습니다. 다음 작업 전에 최신 main과 C8 등 활성 작업 상태를 다시 맞춰 주세요.
>
> 한옥은149단계를 A1 42/A2 36/B1 37/B2 34로 배정하고 B2까지 완공합니다. C1/C2는 완성 공간의 심화 언어 활동입니다. 획득은 승인된 정규 평가 묶음 OR 연결된 정규 unit의 검증된 완료이며, 같은 stage ID로 중복을 막습니다. 상급 진입자는 기존 통과 기록을 인정하고 빠진 부분만 같은 정규 평가로 확인합니다. Placement·XP·출석·친구 의뢰·장식은 건축 권리를 지급하지 않습니다.
>
> 149개의 stage→unit 배정은 파일/hash와 함께 작성했지만 전체 평가 연결은 아직 승인되지 않았습니다. 현재 한국어 canDo 의미를 기준으로 평가 ID·hash·revision·rubric·evaluator를 함께 공유해야 합니다. `a1_07_contact_address`, `a1_11_titles_relationships`처럼 옛 ID 이름과 현재 의미가 다른 항목부터 점검하겠습니다. 결손은 일반 학습과 catch-up이 함께 사용하는 정규 평가로 보충하며 한옥 전용의 쉬운 진단으로 대체하지 않겠습니다.
>
> 현재 사랑채16/B2비율34 투영은149고정ID로 전환하되 기존 보유를 보존합니다. `storage_service.dart`, course progress/mastery, 계정 reconciliation·cloud sync·삭제, 보상 영수증은 한 명의 통합 담당자가 변경하고 양쪽 테스트로 검토할 필요가 있습니다. 평가 저장·권리·수동 조립·임시 소품은 구분합니다.
>
> NPC는 선택한 태고/조이가 동행하고 다른 친구가 특별 방문합니다. 기존30스티커·36데코를 상황별로 사용하며 기존 ID·소유·정본 그림을 유지합니다. 일상 한국어를 중심으로 쓰고 반닫이·소반 같은 낯선 단어를 필수 의뢰에 넣지 않습니다.39개 조립 장면과26개 선택 생활 의뢰는 별개이며, 의뢰를 건너뛰어도149완공이 가능합니다.
>
> CP S5의 자산 전달과 합류하겠습니다.149그림은 현재269,109,572bytes이며, 이 수치는 기기 설치 크기와 다릅니다. Flutter deferred components/Android dynamic feature modules를 한 곳에서 구성하고 `pubspec.yaml`·loading units·pack hash·네이티브 설정을 공동 계약으로 맞춰 주세요. 두 번째 다운로더는 만들지 않습니다. 핵심 학습은 오프라인, 받은 한옥 팩은 이후 오프라인이며 팩 실패가 학습 권리를 막지 않아야 합니다.
>
> CP의 A1/A2 커버리지·B1문법67항목·전 레벨 품질·보안·운영·스토어 기준을 유지합니다. 첫26단계는 중간 체험 검증이며 전체 출시 후보가 아닙니다. 고정10주 대신 첫 작업 묶음의 실제 처리량과 임계경로로 일정을 갱신하되14일 안정성 관찰은 유지합니다. 구현 시작 때 정확한 파일 담당과 PR 순서를 합의하고, 각 PR head와 병합 main의 검증을 구분해 공유하겠습니다.

## 최종 문서 검수

- [x] 149개 원본 파일/hash와 unit 배정 수 검증.
- [x] 이미 병합된34단계 및 B2비율 투영 반영.
- [x] 39조립과26선택의뢰가 모순 없이 분리됨.
- [x] 진도·legacy·계정·오프라인·클라우드·재시도 게이트 포함.
- [x] 깊이·출입·8면도·추가 아트 범위 포함.
- [x] 일상 한국어·30스티커/36데코·기존 소유권 계약 포함.
- [x] Claude에게 전할 메시지 포함, 전송하지 않음.
- [ ] 구현 착수 산출물: Task1의 실제149 평가 연결·의미 검수·도달성 증명.

마지막 미완료 항목은 제품 방향에 대한 재질문이 아니라 구현 작업의 첫 산출물이다. 문서 작성 완료와 앱 구현 완료를 구분한다.
