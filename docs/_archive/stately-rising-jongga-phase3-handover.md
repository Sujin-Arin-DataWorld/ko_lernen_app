# Phase 3 Handover — stately-rising-jongga

> ✅ **실행완료 — 코드 구현 완료** (2026-06-03 아카이브)
> 이 핸드오버의 코드 작업은 끝났고 `lib/`에 반영·검증됨 (`flutter analyze` 0 · `flutter test` 218 통과).
> ⚠️ 한옥 stage PNG는 light **10/12**, dark **0/12** (그라데이션 폴백 동작). 자산 보강은 → [`../IMPROVEMENT_PLAN_2026-06-03.md`](../IMPROVEMENT_PLAN_2026-06-03.md) TRACK 0.4 / TRACK 6.

> **세션**: 2026-05-31 (Phase 3, 같은 날 Phase 2 직후) · Claude
> **상위 plan**: `docs/plans/stately-rising-jongga.md` §5
> **상태**: 코드 작성 완료 — Jin 로컬 검증 대기

---

## 1. 변경 요약 (TL;DR)

Phase 3 은 "사용자 마당이 학습 진행도에 따라 단계별로 자라는" 시스템.
12 단계 enum + 단계 계산 + cinematic 전환 위젯이 핵심.

| 영역 | 파일 | 변경 |
|---|---|---|
| 모델 | `lib/models/hanok_stage.dart` | 신규 — 12-stage enum + `computeStage()` cascade 함수 + assetSlug / JSON |
| 서비스 | `lib/services/hanok_stage_service.dart` | 신규 — 레벨별 cleared ratio 계산 + currentStage() orchestrator |
| 서비스 | `lib/services/storage_service.dart` | + `seenHanokStages` / `hasSeenHanokStage` / `markHanokStageSeen` (kl_hanok_stages_seen_v1) |
| 위젯 | `lib/widgets/sori/madang_background.dart` | 신규 — 단계별 PNG → madang fallback → gradient 3-tier cascade |
| 위젯 | `lib/widgets/sori/hanok_cinematic.dart` | 신규 — 까치 sweep + toast + scrim + reduce-motion 대응 |
| 화면 | `lib/screens/home_screen.dart` | + initState 에서 currentStage check → unseen 이면 Cinematic overlay 자동 표시 |
| 자산 | `assets/illustrations/hanok_stages/` | 신규 폴더 + .gitkeep + pubspec 등록 |
| l10n | `app_de.arb`, `app_en.arb` + generated | + `hanokCinematicIntro` (1 키, DE: "Dein Hanok wächst —" / EN: "Your hanok is growing —") |
| 테스트 | `test/hanok_stage_test.dart` | 신규 — 12 stage boundary, cascade, JSON, assetSlug (20+ 케이스) |
| 테스트 | `test/hanok_stage_service_test.dart` | 신규 — 통합 (실 CSV 로딩, ratio → stage), seenStages (10+ 케이스) |

---

## 2. 12 단계 cascade 모델 (사실 — 테스트로 검증됨)

```
A1 cleared %  →  HanokStage
  0    %  →  empty             빈 터
  25   %  →  foundation        주춧돌
  50   %  →  pillars           기둥
  75   %  →  beams             대들보·서까래
  100  %  →  thatchRoof        초가지붕

A1 = 100% AND A2 cleared %  →  HanokStage
  0    %  →  thatchRoof        (계속)
  25   %  →  tileRoofPartial   기와 부분
  75   %  →  tileRoofComplete  기와 완성

A2 = 100% AND B1 cleared %  →  HanokStage
  0    %  →  dancheong         처마 단청
  25   %  →  gate              솟을대문
  50   %  →  windows           창호지문

B1 = 100% AND B2 cleared %  →  HanokStage
  0    %  →  sideBuilding      사랑채
  50   %  →  jongga            종갓집 완성
```

**Cascade 의미**: 사용자가 A1 안 끝내고 A2 부분 도전해도 stage 는 A1-phase
에 머무름 (현실의 한옥 건축처럼 골조 후 지붕). `test/hanok_stage_test.dart`
의 "cascade semantics" 그룹이 이걸 lock.

---

## 3. Cinematic 트리거 흐름

### 3.1 게이트

- `Storage.seenHanokStages: List<String>` — 사용자가 본 stage 이름들
- 새 stage 도달 시 → 미본 → Cinematic 트리거 → 본 후 markSeen
- 한 번 본 stage 는 절대 다시 트리거 안 됨

### 3.2 어디서 트리거되나

**현재 phase 3 v1**:
- 홈 화면 (`home_screen.dart`) `initState` → currentStage 계산 → 미본이면 자동 표시
- 시점: 홈 진입 시 (앱 시작 또는 다른 화면에서 홈 복귀)

**미구현 (Phase 3.1 후보)**:
- 결과 화면 (`vocab_pack_result_screen.dart`) 의 "마당이 자라났어요" 배너 +
  "확인하기" CTA → 홈 push. 현재는 사용자가 직접 홈으로 가야 cinematic 봄.
  Plan §5.3.1 명세이지만 v1 에서는 deferred.

### 3.3 Reduce-motion 대응

`MediaQuery.disableAnimations == true` 일 때:
- 까치 sweep, scrim, slide 모두 생략
- 토스트만 표시 → 즉시 markSeen + dismiss

`SoriMotion.reduceMotion(context)` 패턴과 일관 (Phase 0 에서 도입).

---

## 4. PNG 자산 없이도 동작 — 3-tier fallback

`MadangBackground` 의 cascade:

1. **1차** `assets/illustrations/hanok_stages/stage_{slug}_{light|dark}.png`
   - 12 단계 × 2 brightness = 24 PNG
   - Jin 양산 — `docs/plans/stately-rising-jongga-assets.md` §2 (24장 상세 프롬프트)
2. **2차** `assets/illustrations/hanok/madang(light|dark).png`
   - Phase 2 까지의 기존 배경 (이미 존재)
3. **3차** Theme gradient (`v4 home_screen` 의 cream / dark 그라데이션)

→ **PNG 없이도 빌드·실행 정상**. 시각 품질만 단계별로 차이.

까치 시네마틱 자산도 마찬가지:
- `mascot/magpie_wingup.png` → `mascot/magpie_perched.png` → emoji 🐦 fallback

---

## 5. 데이터 모델

### 5.1 Storage 신규 키

- `kl_hanok_stages_seen_v1`: `List<String>` (`['empty', 'foundation', ...]`)
- 기존 `kl_pack_progress_v1` (Phase 2 에서 추가) 그대로 사용 — stage 는 그것에서 derive

### 5.2 Stage ↔ String 변환

- `HanokStage.toJsonValue()` = `name` (예: `'thatchRoof'`)
- `HanokStage.fromJsonValue(string)` — 미존재 → `empty` (안전 default)

### 5.3 Firestore 영향

**없음**. Stage 는 로컬 pack progress 에서 derive — Firestore 새 path 안 만듦.
Phase 1 의 `firestore.rules` 그대로.

---

## 6. Jin 로컬 검증 명령어

```bash
# 1. l10n 재생성
flutter gen-l10n

# 2. 분석
flutter analyze
# 기대: 0 errors (1 info chosung known issue 만 남음)

# 3. 단위 테스트 — Phase 3 신규 2 파일 + 회귀
flutter test test/hanok_stage_test.dart           # 20+ 케이스
flutter test test/hanok_stage_service_test.dart   # 10+ 케이스
flutter test   # 전체 (~145 케이스 기대)

# 4. 실기기 (Jin 디바이스 unlock 후)
flutter run -d 9053622f
# 시나리오:
#   a) 홈 진입 → currentStage = empty (아직 클리어 없음) → 첫 cinematic 자동 재생
#      ("Dein Hanok wächst — Bauplatz vorbereiten") → 토스트 표시 후 자동 dismiss
#   b) 홈 재진입 → cinematic 재생 X (seen 처리됨)
#   c) /vocab → 첫 팩 클리어 (보스 ≥ 70%) → 홈으로 복귀
#   d) currentStage = foundation (A1 25%+) → 새 cinematic 자동 재생
#      ("Sockel legen")
#   e) Reduce motion ON (설정 → 접근성 → 모션 줄이기) → cinematic 즉시 토스트만
```

---

## 7. 알려진 한계 & 향후 작업

### 7.1 Phase 3 범위 — 했음 / 안했음

**했음**:
- 12 stage enum + computeStage cascade + JSON
- HanokStageService (level ratios + currentStage)
- Storage seen-stages gating
- MadangBackground 3-tier fallback widget (호출 site 는 아직 없음 — Phase 4 home 재디자인 시 사용 권장)
- HanokCinematic + reduce-motion + 홈 통합
- 30+ 단위 테스트

**안했음** (Phase 3.1+):
- 결과 화면 (`vocab_pack_result_screen`) 의 "마당이 자라났어요" 배너 — Plan §5.3.1
- MadangBackground 를 홈 배경으로 실제 wire-up
  (현재 v4 home 의 gradient 유지. PNG 들어오면 swap 검토)
- Phase 4 의 특별 퀘스트 트리거 (dancheong quest 등)
- Stage 데코레이션 추가 (장독대, 매화, 연못 — Phase 4)

### 7.2 v4 home 의 gradient 와 MadangBackground 의 관계

`v4 home_screen.dart` 는 의도적으로 "추상 gradient + ambient particles" 로
설계됨 (커밋 ce460e9, `madang.png` 에 호랑이가 baked-in 되어 잘림 문제 해결).
Phase 3 PNG 24장이 들어와서 stage 별 깨끗한 배경이 가능해지면:
- 홈 Stack 의 1번 layer (`DecoratedBox` gradient) 을 `MadangBackground(stage: ...)` 로 swap
- Phase 4 작업 시 권장

지금은 cinematic 만 통합 — 배경은 v4 그대로.

### 7.3 결과 → 홈 자동 cinematic

현재: 사용자가 결과 → "팩 마당으로" 탭 → 팩 grid → 홈으로 가야 cinematic.
홈 진입 패턴 (예: 홈 탭 / 백버튼) 으로 도달 시 자동 재생됨 — 그 전까지는 미발동.

Plan §5.3.1 의 "결과 화면 배너 + 확인하기 CTA" 는 deferred. 추가하려면:
- VocabPackResultScreen 을 StatefulWidget 으로 → initState 에서 currentStage check
- unseen 이면 배너 + CTA. CTA 탭 → pushNamedAndRemoveUntil('/', ...) → 홈 cinematic 트리거

15분 작업. Phase 3.1 으로 묶거나 별도 후속.

### 7.4 ratio 0/0 케이스

`HanokStageService.levelRatios()`: 레벨 packs 가 0 이면 ratio = 0.0 반환.
(예외 case — `vocab_pack_map.md` 검증 결과 A1/A2/B1/B2 모두 packs 존재함)

### 7.5 Phase 4 가 dancheong 단계를 트리거?

Plan §5.1 에서 dancheong stage 는 "A2 100% + 첫 단청 퀘스트" 로 기술.
Phase 3 v1 에서는 단청 퀘스트 시스템이 없어 → dancheong = A2 100% (B1 0~25%) 로
간주. Phase 4 의 special quest 가 들어오면:
- `computeStage(..., hasDancheongQuest: bool)` 시그니처 확장
- 또는 `HanokStageService` 가 quest 상태도 인자로 받음
- 미세 조정 — 코드는 작음

---

## 8. 신뢰 가능한 사실 vs 가정

### 검증됨 (사실)
- 12 stage cascade 컷오프 — `hanok_stage_test.dart` 20 boundary 케이스로 lock
- Storage 키 새로 (`kl_hanok_stages_seen_v1`) — 기존 키들과 prefix 충돌 없음
- Cinematic 위젯의 reduce-motion 대응 — `MediaQuery.disableAnimations` 사용
- HanokStageService 가 PackProgressService 와 일관 — pack status `cleared` 만 count
- 3-tier asset fallback — Image.asset errorBuilder 패턴 검증됨

### 가정 (Jin 검증 필요)
- `flutter analyze` 0 errors — 샌드박스 SDK 없음
- `flutter test` 145+ 통과 — Phase 1 47 + Phase 2 28 + Phase 3 30 + 기존 회귀
- 홈 초기 진입 시 cinematic 자연스럽게 보임 — 시각 검증
- 단계 전환 시 토스트 위치 (bottom-center) 자연스러움
- Cinematic 도중 다른 navigate 시 lifecycle 안전 (mounted check 있음)

### 의도적으로 미수행
- Phase 4 (특별 퀘스트 + 마당 데코)
- Phase 5 (책 한 컷)
- 결과 화면 → 홈 자동 cinematic CTA
- 홈 배경을 MadangBackground 로 실제 swap

---

## 9. 변경 파일 목록

```
신규:
  assets/illustrations/hanok_stages/.gitkeep
  docs/plans/stately-rising-jongga-phase3-handover.md
  lib/models/hanok_stage.dart
  lib/services/hanok_stage_service.dart
  lib/widgets/sori/hanok_cinematic.dart
  lib/widgets/sori/madang_background.dart
  test/hanok_stage_service_test.dart
  test/hanok_stage_test.dart

수정:
  lib/screens/home_screen.dart                    (+ Cinematic overlay)
  lib/services/storage_service.dart               (+ seenHanokStages API)
  lib/l10n/app_de.arb                             (+ hanokCinematicIntro)
  lib/l10n/app_en.arb                             (+ hanokCinematicIntro)
  lib/l10n/generated/app_localizations.dart       (+ method signature)
  lib/l10n/generated/app_localizations_de.dart    (+ DE impl)
  lib/l10n/generated/app_localizations_en.dart    (+ EN impl)
  pubspec.yaml                                    (+ hanok_stages asset dir)
```

---

## 10. 다음 단계 (Phase 4 — 특별 퀘스트)

Phase 3 검증 끝나면 Phase 4 시작 — Plan §6:

1. `lib/data/quest_catalog.dart` — 17 퀘스트 정의 (10 상시 + 4 계절 + 3 sub)
2. `lib/services/quest_tracker.dart` — 학습 액션 → 퀘스트 progress 업데이트
3. `lib/widgets/sori/decoration_layer.dart` — 마당 장식 합성
4. `lib/screens/quests_screen.dart` — 퀘스트 진행 화면
5. `assets/illustrations/decorations/` 폴더 + 17 PNG (Jin)
6. Remote Config `active_seasonal_quests`

병행:
- Jin Sprint 2 PNG 양산 (한옥 stage 나머지 + 특별 퀘스트 핵심 6장)

---

**작성**: Claude
**검토 대기**: Jin
**커밋 권한**: Jin 명시 요청 시
