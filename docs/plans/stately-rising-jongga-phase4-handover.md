# Phase 4 Handover — stately-rising-jongga

> **세션**: 2026-05-31 (Phase 4, 같은 날 Phase 3 직후) · Claude
> **상위 plan**: `docs/plans/stately-rising-jongga.md` §6
> **상태**: 코드 작성 완료 — Jin 로컬 검증 대기

---

## 1. 변경 요약 (TL;DR)

Phase 4 는 마당을 꾸미는 **17 특별 퀘스트** 시스템 + 진행 화면 + 데코 layer.

| 영역 | 파일 | 변경 |
|---|---|---|
| 모델 | `lib/models/quest.dart` | 신규 — QuestType / QuestSource enum, SeasonWindow, QuestDefinition, QuestProgress |
| 데이터 | `lib/data/quest_catalog.dart` | 신규 — 17 퀘스트 const 정의 (13 상시 + 4 계절) |
| 서비스 | `lib/services/quest_tracker.dart` | 신규 — passive `computeAll()` + `persistNewCompletions()` |
| 서비스 | `lib/services/storage_service.dart` | + `kkeunmariWins / incKkeunmariWins`, `questCompletions / hasQuestCompleted / markQuestCompleted` (2 신규 키) |
| 화면 | `lib/screens/quests_screen.dart` | 신규 — 4 섹션 (in-progress / available / completed / seasonal locked) |
| 화면 | `lib/screens/kkeunmari_screen.dart` | +3줄 — 승리 시 `Storage.incKkeunmariWins()` 호출 (q_punggyeong 트리거) |
| 위젯 | `lib/widgets/sori/decoration_layer.dart` | 신규 — 완료 퀘스트 장식을 마당에 stack (PNG fallback → 동그란 placeholder) |
| 라우트 | `lib/main.dart` | + `/quests` → `QuestsScreen` |
| 자산 | `assets/illustrations/decorations/` | 신규 폴더 + .gitkeep + pubspec 등록 |
| l10n | DE/EN ARB + generated | + 8 키 (questsTitle, 섹션 헤더 등) |
| 테스트 | `test/quest_catalog_test.dart` | 신규 — 카탈로그 무결성 (17개, id unique, season window) 17 케이스 |
| 테스트 | `test/quest_tracker_test.dart` | 신규 — empty 상태, kkeunmari wins 진행, 완료 persist 9 케이스 |

---

## 2. 17 퀘스트 카탈로그 (사실 — 카탈로그 무결성 테스트로 lock)

### 2.1 상시 (13개)

| ID | 조건 | Target | Source |
|---|---|---|---|
| q_jangdokdae | 음식 단어 마스터 | 50 | foodWordsMastered |
| q_maehwa | 형용사 + 감정 단어 | 30 | adjectiveFeelingWordsMastered |
| q_sonamu | 시나리오 완료 | 10 | scenariosCompleted |
| q_pond | 자연·날씨 단어 | 20 | natureWordsMastered |
| q_seokdeung | 발음 평가 80%+ | 100 | pronunciationGood ⚠️ Phase 5 ETA |
| q_punggyeong | 끝말잇기 승 | 10 | kkeunmariWins ✅ wired |
| q_pyeonaek | 한글 자모 마스터 | 100% | hangulMastery (calligraphy/28) |
| q_doldam | 친구·계원 | 5 | friendsCount ⚠️ Phase 6 ETA |
| q_kkachi_nest | Streak | 30일 | streakDays |
| q_sagunja_maehwa | 한자어 단어 (봄) | 20 | hanjaWordsMastered |
| q_sagunja_nan | 한자어 단어 (여름) | 40 | hanjaWordsMastered |
| q_sagunja_guk | 한자어 단어 (가을) | 60 | hanjaWordsMastered |
| q_sagunja_juk | 한자어 단어 (겨울) | 80 | hanjaWordsMastered |

### 2.2 계절 (4개)

| ID | 시즌 (양력) | 조건 |
|---|---|---|
| q_seollal | 1/15 ~ 2/20 | 시즌 중 chosung 정답 5 |
| q_chuseok | 9/1 ~ 10/15 | 시즌 중 송편/한국 명절 음식 12 단어 |
| q_hangeulday | 10/2 ~ 10/16 | 시즌 중 calligraphy 7일 |
| q_kite | 4/28 ~ 5/8 | 시즌 중 calligraphy 5일 연속 |

`SeasonWindow.contains()` 가 year-wrap (12→1) 도 지원. 테스트 lock.

---

## 3. 진행도 계산 — 사실 vs 가정

### 3.1 즉시 동작 (사실)

- **q_punggyeong**: `Storage.kkeunmariWins` 카운터. `kkeunmari_screen._endGame()` 의
  `didWin` 분기에 `Storage.incKkeunmariWins()` wired. **새 게임에서 즉시 적용**.
- **q_kkachi_nest**: `Storage.streakDays` 기존 키 — 매일 앱 진입 시
  `Storage.touchStreak()` 가 갱신.
- **q_sonamu**: `Storage.completedScenarios.length` 기존.
- **q_pyeonaek**: `Storage.calligraphyTotalDays / 28 × 100`.
- **음식·형용사·자연·직업·한자 단어 카운트**: `Storage.vokSeenIds` ∩ vocab CSV
  의 토픽 필터.

### 3.2 작동 하지만 의미 약함 (Phase 5/6 ETA)

- **q_seokdeung** (발음 평가) — 현재 source 가 **항상 0** (`pronunciationGood`).
  발음 평가 시스템이 없어서. Phase 5 (책 한 컷)에서 도입 후 hookup.
- **q_doldam** (친구) — 항상 0. Phase 6 (계) 도입 후.

화면은 표시하되 "Phase-5 ETA" 라고 설명에 명시 (descriptions 안에).

### 3.3 한자어 마스터 — 휴리스틱 (가정)

`v.korean.replaceAll(' ', '').length >= 2` 로 추정. 정확한 POS 데이터가 없어
2글자 이상 단어를 한자어로 간주. CSV 전체 단어 ~80% 가 2+ 글자라 매우 관대.
Phase 5의 책 한 컷에서 OKT POS 정보가 들어오면 정확화 가능.

---

## 4. 데이터 모델

### 4.1 Storage 신규 키 (2개)

- `kl_kkeunmari_wins`: `int` — 끝말잇기 누적 승수
- `kl_quests_completed_v1`: JSON `Map<questId, ISO timestamp>` — 한 번
  완료된 퀘스트는 영구 기록 (카운터 떨어져도 decoration 유지)

### 4.2 Firestore 영향

**없음**. 퀘스트 완료는 로컬에만 저장. Phase 6 의 계가 들어오면 피드 이벤트로
공유될 수 있음 — 그 때 sync hook 추가.

---

## 5. UI 통합 상태

### 5.1 라우트

- `/quests` → `QuestsScreen` 추가
- 홈 화면에서의 진입점 미연결 (Plan §4.2 에 "팩 grid 하단 특별 퀘스트 진행 카드"
  자리만 잡힘) — Phase 4 v1 에서는 라우트만. 홈 모듈 그리드에 카드 추가는
  Phase 4.1 후보. (`/quests` 로 직접 push 하면 접근 가능)

### 5.2 마당 데코 합성

`DecorationLayer` 위젯 준비 완료. 사용처:
- 향후 홈 (또는 `/vocab` grid) 배경 위 stack
- 현재 코드에서는 import 만, 호출 site 없음 — Phase 4.1 에서 home 통합

PNG fallback: `assets/illustrations/decorations/{slug}.png` 없으면 동그란
placeholder + 슬러그 첫 2글자 표시. **빌드 정상**.

---

## 6. Jin 로컬 검증 명령어

```bash
flutter gen-l10n
flutter analyze
# 기대: 0 errors (1 info chosung known issue 그대로)

flutter test test/quest_catalog_test.dart   # 17 케이스
flutter test test/quest_tracker_test.dart   # 9 케이스
flutter test   # 전체 (~170 케이스 기대)
```

실기기 (SIM unlock 후):
```bash
flutter run -d 9053622f
# 시나리오:
#   a) 홈 → URL bar 또는 임시 진입로로 /quests 입력 (또는 settings 에서 디버그 라우트)
#      — 17 퀘스트 리스트 보임. 첫 진입엔 모두 0/target 또는 시즌 잠금.
#   b) 끝말잇기 게임 1판 승리 → /quests 새로고침 → q_punggyeong: 1/10
#   c) 단어팩 1개 클리어 (음식 토픽 포함) → /quests → q_jangdokdae 증가
#   d) 음력 1월 시점이면 → q_seollal "Saison" 배지 + active=true 확인
```

---

## 7. 알려진 한계 & 향후 작업

### 7.1 Phase 4 범위 — 했음 / 안했음

**했음**:
- 17 quest 정의 + 카탈로그 무결성 테스트
- Passive QuestTracker (12 source 라우팅)
- Storage 완료 persist + 끝말잇기 wins counter wire
- QuestsScreen 4-섹션 + 진행 바
- DecorationLayer 위젯 (홈 통합 미연결)
- 26 단위 테스트

**안했음** (Phase 4.1 / 후속):
- 홈 진입로 — `/quests` 직접 URL 만 가능 (UI 카드 추가는 후속)
- 마당 데코 실제 표시 — `DecorationLayer` 위젯만 준비, home 통합 deferred
- q_seokdeung (발음) — Phase 5 의 책 한 컷 + 발음 평가 도입 후
- q_doldam (친구) — Phase 6 의 계 도입 후
- 시즌 이벤트 push 알림 (RemoteConfig + FCM) — v1.1 후보

### 7.2 PNG 없이도 동작 — fallback 패턴 유지

- QuestsScreen: 텍스트 + 아이콘만, PNG 불필요
- DecorationLayer: 작은 동그란 placeholder + 슬러그 첫 두 글자
- HanokHeader: 단청 그라데이션 fallback (Phase 2 이미 그렇게)

Jin이 양산할 PNG (`docs/plans/stately-rising-jongga-assets.md` §3 참조):
- 17 장 + light/dark 옵션 (대부분 transparent overlay)
- `assets/illustrations/decorations/{slug}.png` 경로

### 7.3 카운터 정확도

**음식 토픽 단어 카운트** (`foodWordsMastered`):
- vocab CSV 의 `topic = 'Essen & Trinken'` 인 단어 중 `Storage.vokSeenIds`
  에 포함된 것 카운트
- A1 (10) + A2 (14) = 24 단어 → q_jangdokdae 목표 50 은 사실상 도달 불가능
- → **Phase 5 의 책 한 컷에서 추가 음식 단어가 들어와야 의미 있음**

수치 조정 후보:
- q_jangdokdae 50 → 20 또는 24
- q_pond 20 → 16 (자연·날씨 단어 총합 ~16)
- q_maehwa 30 → 25 (형용사+감정 ~25)

이는 plan 명세이므로 임의 조정 X. Jin 결정 후 catalog 수정.

### 7.4 발음·친구 placeholder UX

Description 에 "(Phase-5 ETA)" / "(Phase-6 ETA)" 명시 — 사용자가 왜 안 되는지
알 수 있음. 완전 숨김도 옵션이지만, 진행 미리보기 우선.

---

## 8. 신뢰 가능한 사실 vs 가정

### 검증됨 (사실)
- 17 퀘스트 카탈로그 무결성 (id unique, target > 0, season window 적절)
- SeasonWindow.contains 의 year-wrap 동작 — 12→1 테스트로 lock
- Storage.kkeunmariWins 카운터 wire — `kkeunmari_screen._endGame()` 의
  `didWin` 분기에 명시적 호출
- QuestTracker.computeAll 의 토픽 필터링 (Set 비교)

### 가정 (Jin 검증 필요)
- `flutter analyze` 0 errors
- `flutter test` ~170 통과
- 시즌 윈도우 양력 매핑 적절 (음력 변동에 대해 너무 좁거나 너무 넓진 않은지)
- q_jangdokdae 50 목표가 현재 vocab 으로 달성 가능한지 — 불가능 추정
- DecorationLayer placeholder 가 디버그적으로 충분히 식별 가능한지

### 의도적으로 미수행
- Phase 5 (책 한 컷 OCR + 발음 평가)
- Phase 6 (계 + 친구)
- 시즌 push 알림
- 데코 자동 home 통합 (Plan §6 deliverables 의 home 미언급)

---

## 9. 변경 파일 목록

```
신규:
  assets/illustrations/decorations/.gitkeep
  docs/plans/stately-rising-jongga-phase4-handover.md
  lib/data/quest_catalog.dart
  lib/models/quest.dart
  lib/screens/quests_screen.dart
  lib/services/quest_tracker.dart
  lib/widgets/sori/decoration_layer.dart
  test/quest_catalog_test.dart
  test/quest_tracker_test.dart

수정:
  lib/main.dart                                   (+ /quests route)
  lib/screens/kkeunmari_screen.dart               (+ Storage.incKkeunmariWins)
  lib/services/storage_service.dart               (+ kkeunmariWins + questCompletions)
  lib/l10n/app_de.arb                             (+8 키)
  lib/l10n/app_en.arb                             (+8 키)
  lib/l10n/generated/app_localizations.dart       (+ method signatures)
  lib/l10n/generated/app_localizations_de.dart    (+ DE impl)
  lib/l10n/generated/app_localizations_en.dart    (+ EN impl)
  pubspec.yaml                                    (+ decorations asset dir)
```

---

## 10. 다음 단계 (Phase 5 — 책 한 컷)

Phase 4 검증 끝나면 Phase 5 시작. 본 plan 의 가장 큰 작업 (책 사진 OCR +
한국어 NLP + DE 번역 + bookshelf + custom packs).

전체 명세는 `docs/plans/stately-rising-jongga.md` §6.5 참조.

병행 (Jin):
- Sprint 2 PNG (장식 17 + 한옥 stage 7-11 = 22장)

---

**작성**: Claude
**검토 대기**: Jin
**커밋 권한**: Jin 명시 요청 시
