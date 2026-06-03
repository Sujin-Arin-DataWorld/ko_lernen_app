# Phase 2 Handover — stately-rising-jongga

> ✅ **실행완료 — 코드 구현 완료** (2026-06-03 아카이브)
> 이 핸드오버의 코드 작업은 끝났고 `lib/`에 반영·검증됨 (`flutter analyze` 0 · `flutter test` 218 통과).
> 남은 운영/배포(Cloud Function·Firestore rules, 실기기 QA, 스토어 등록)는 → [`../IMPROVEMENT_PLAN_2026-06-03.md`](../IMPROVEMENT_PLAN_2026-06-03.md) TRACK 0 으로 이관.

> **세션**: 2026-05-31 (Phase 2, 같은 날 Phase 1 직후) · Claude
> **상위 plan**: `docs/plans/stately-rising-jongga.md` §4
> **상태**: 코드 작성 완료 — Jin 로컬 검증 대기

---

## 1. 변경 요약 (TL;DR)

Phase 2 는 vocab 단일 카드 흐름을 **팩 선택 → 3단계 플레이 → 결과** 흐름으로
전면 재설계. 기존 `vocab_screen.dart` 는 `legacy_vocab_screen.dart` 로 보관
(rollback 용).

| 영역 | 파일 | 변경 |
|---|---|---|
| 라우트 | `lib/main.dart` | `/vocab` → `VocabPacksScreen`, 신규 `/vocab/pack`, `/vocab/result`, `/vocab/legacy` |
| 화면 | `lib/screens/vocab_packs_screen.dart` | 신규 — 팩 grid + 레벨 swap + 진행 바 |
| 화면 | `lib/screens/vocab_pack_screen.dart` | 신규 — 3-stage (learn → quiz → boss) |
| 화면 | `lib/screens/vocab_pack_result_screen.dart` | 신규 — 도장 + 통계 + CTA |
| 화면 | `lib/screens/legacy_vocab_screen.dart` | rename — `VocabScreen` → `LegacyVocabScreen` |
| 서비스 | `lib/services/pack_progress_service.dart` | 신규 — Storage + Firestore orchestrator + Unlock-Logik |
| 서비스 | `lib/services/storage_service.dart` | + `packProgressJson` / `setPackProgressJson` / `setMany...` / `resetPackProgressForTesting` (JSON-Map in SharedPreferences) |
| 위젯 | `lib/widgets/sori/pack_card.dart` | 신규 — locked/available/cleared tile |
| 위젯 | `lib/widgets/sori/dancheong_stamp.dart` | 신규 — 8 motif CustomPainter (lotus·chrysanthemum·plum·bamboo·cloud·octagon·mountain·swastika) + 찍힘 애니메이션 |
| l10n | `lib/l10n/app_de.arb`, `app_en.arb` | +35 신규 키 (팩 / 한옥 단계 / 플레이 / 결과) |
| l10n | `lib/l10n/generated/*.dart` | 동일 메서드 hand-edit (Jin `flutter gen-l10n` 시 자동 재생성) |
| 테스트 | `test/pack_progress_service_test.dart` | 신규 — 17 케이스 (unlock, boss attempt, 캐시 round-trip) |
| 테스트 | `test/dancheong_stamp_test.dart` | 신규 — motif 매핑 9 케이스 + 위젯 smoke 2 |

---

## 2. 아키텍처 한눈에

```
┌──────────────────────────────────────────────────────────┐
│ VocabPacksScreen   (route /vocab)                        │
│  ├─ HanokHeader                                          │
│  ├─ _LevelProgressHeader (cleared/total + StageLabel)    │
│  ├─ 2-Spalten Grid of PackCard                           │
│  │   onTap → /vocab/pack (args: packId)                  │
│  │   onLockedTap → SnackBar                              │
│  └─ AppBar action: 레벨 swap menu                          │
└──────────────────────────────────────────────────────────┘
                          │ Navigator.pushNamed
                          ▼
┌──────────────────────────────────────────────────────────┐
│ VocabPackScreen   (route /vocab/pack)                    │
│  ├─ _StageBar (3 progress segments)                      │
│  ├─ Stage 1 LEARN : FlipCard, 일반 단어, "Gewusst" / "X"  │
│  ├─ Stage 2 QUIZ  : 4지선다 K→DE on 일반 단어              │
│  ├─ Stage 3 BOSS  : 4지선다 + TTS auto-play on 보스 단어   │
│  └─ Finish → pushReplacementNamed /vocab/result          │
└──────────────────────────────────────────────────────────┘
                          │ navigator
                          ▼
┌──────────────────────────────────────────────────────────┐
│ VocabPackResultScreen   (route /vocab/result)            │
│  ├─ DancheongStamp 시네마틱 (cleared 시 animate=true)      │
│  ├─ Mascot.tiger worry (미클리어 시)                       │
│  ├─ Stats card (boss accuracy, quiz, XP)                 │
│  └─ CTAs: 다음 팩 / 다시 도전 / 팩 마당으로                  │
└──────────────────────────────────────────────────────────┘

Data flow:
   UI ─→ PackProgressService ─→ Storage  (local SoT, sync)
                          └─→ FirestoreProgressService (fire-and-forget)
```

---

## 3. 핵심 동작 — Plan 과 대응

### 3.1 Unlock 규칙 (Plan §4.2)

- 레벨의 첫 팩 → 항상 `available`
- 그 외 팩 → 직전 팩이 `cleared` 일 때만 `available`
- 보스 정확도 **≥ 70%** → `cleared` (`PackProgressService.bossClearThreshold = 0.70`)
- Cleared 후 정확도 떨어져도 status 유지 (best-attempt 기록)

테스트: `pack_progress_service_test.dart` 의 `recordBossAttempt` 그룹.

### 3.2 3-단계 플레이 (Plan §4.3)

| Stage | 입력 | 출력 |
|---|---|---|
| **learn** | 일반 단어 N개 (보스 제외) | flip card, "Gewusst" → SRS update + `addVokSeen` |
| **quiz** | 일반 단어 N개 | 4지선다 K→DE, distractors는 같은 level pool |
| **boss** | 보스 단어 M개 | 4지선다 + TTS 자동재생, 보스 정확도 산출 |

거짓 정보가 없도록 — distractor pool 은 같은 level의 모든 단어에서 뽑힘
(`_distractorPool`). 같은 한국어 또는 같은 독일어는 자동 제외.

### 3.3 XP 보상 (Plan §4.4)

```dart
xp = wordsTotal * 5 + bossCorrect * 10
```

`vocab_pack_screen.dart::_finish()` 에서 `Storage.addXp()` 호출.

### 3.4 결과 화면 도장 (Plan §4.4)

- `DancheongStamp(motif: motifForPackId(packId), animate: justCleared, stamped: true)`
- 모티프는 토픽군에 따라 다름 — 8 종:

| 토픽군 | 모티프 |
|---|---|
| 인사/자기소개/가족 | 연꽃 (lotus) |
| 시간/숫자 | 국화 (chrysanthemum) |
| 감정/형용사 | 매화 (plum) |
| 직장/교육 | 대나무 (bamboo) |
| 날씨/건강/기타 | 구름 (cloud) |
| 음식/쇼핑 | 팔각 (octagon) |
| 교통 | 산봉우리 (mountain) |
| 신체/색/위치 | 만자 변형 (swastika — 풍차 형태로 그림) |

`pack_id` → motif 매핑은 `dancheong_stamp.dart::motifForPackId()` (단일 함수).

⚠️ "swastika" 라는 enum 이름은 한국 전통 卍자 무늬에서 왔으나 **나치 상징과의
혼동을 피하기 위해 실제 그리는 모양은 4-잎 풍차 (pinwheel)** 다. 코드 주석에
명시되어 있음.

---

## 4. 데이터 모델 변경 사항

### 4.1 Storage 신규 키

- `kl_pack_progress_v1` — JSON-encoded `Map<packId, PackProgress.toJson()>`
- 기존 `kl_vok_seen_ids` 는 그대로 — `wordsLearned` 계산에 활용
  (`PackProgressService.wordsLearnedIn()`)

### 4.2 Firestore 신규 path

- `users/{uid}/packs/{packId}` — `FirestoreProgressService` 가 best-effort
  write. **Phase 1 의 firestore.rules 가 이미 cover 함** — 추가 변경 없음.

### 4.3 PackProgress 모델 (Phase 1 에 이미 정의)

JSON 포맷 (변경 없음):
```json
{
  "level": "A1",
  "status": "available" | "locked" | "inProgress" | "cleared",
  "wordsLearned": 5,
  "wordsTotal": 9,
  "bossAccuracy": 0.83,
  "attempts": 1,
  "clearedAt": "2026-05-31T12:00:00Z" | null
}
```

---

## 5. Jin 로컬 검증 명령어

```bash
# 1. l10n 재생성 (ARB 35키 추가됨 → hand-edit 한 generated 파일이 동일하게 재생성됨)
flutter gen-l10n

# 2. 정적 분석 — 0 issues 기대
flutter analyze

# 3. 단위 테스트 — Phase 2 신규 2 파일 + 회귀
flutter test test/pack_progress_service_test.dart
flutter test test/dancheong_stamp_test.dart
flutter test   # 전체 (Phase 1 47 + Phase 2 ~28 + 회귀 = ~115 케이스 기대)

# 4. 실기기 (Jin 디바이스 unlock 후)
flutter run -d 9053622f
# 시나리오:
#   a) 홈 → "단어장" or /vocab 진입 → 팩 grid 보임
#   b) 첫 팩 (a1_greetings_1) 만 available, 나머지 locked 확인
#   c) 잠긴 팩 탭 → SnackBar "Schaffe zuerst ... mit ≥ 70%" 표시
#   d) 첫 팩 탭 → Stage bar 3 분할 표시
#   e) learn 6단어 → quiz 6단어 → boss 2-3단어 → result 화면
#   f) 보스 ≥70% → 도장 시네마틱 + "Continue to <next>" CTA
#   g) result 에서 다음 팩 CTA 탭 → 다음 팩 자동 unlock 확인
#   h) 백 버튼으로 /vocab → grid 에 클리어 도장 overlay 보임
#   i) AppBar 메뉴로 A1 → A2 swap 시 A2 grid 로드 확인

# 5. (선택) 레거시 화면 — rollback 검증
# 홈에는 더 이상 링크 없음. Direct URL only:
flutter run -d ... && /vocab/legacy
```

---

## 6. 알려진 한계 & 향후 작업

### 6.1 Phase 2 범위 — 했음 / 안했음

**했음** (이 세션):
- 3 화면 + 2 위젯 + 1 서비스 (PackProgressService)
- 35 신규 l10n 키 (DE/EN)
- Storage local pack progress (SharedPreferences)
- Firestore best-effort sync (build 1 부터)
- 27 단위 테스트 (unlock, boss attempt, motif 매핑, smoke)

**안했음 (Phase 3+)**:
- 한옥 시각화 (마당 배경 단계 변화) — Phase 3 작업
- 한옥 단계 시네마틱 ("기둥이 세워졌어요" 토스트)
- 특별 퀘스트 진행 카드 (팩 grid 하단에 자리만 잡힘)
- 단청 도장첩 모음 화면 (cleared 도장 갤러리)
- 보스 단어 발음 정확도 측정 (현재는 4지선다 객관식만)

### 6.2 PNG 자산 — 코드는 fallback 동작

Phase 2 가 의존하는 PNG:
- `assets/illustrations/hanok/study_classroom.png` — HanokHeader fallback
  (이미 `HanokHeader.fallbackIcon: Icons.collections_bookmark_outlined` 로
  자동 단청 그라데이션 대체)
- 단청 도장 — **PNG 없음** — `dancheong_stamp.dart` 가 CustomPainter 로
  완전히 SVG-fallback. PNG 자산이 들어오면 `DancheongStamp(asset: ...)`
  추가하면 됨 (TODO marker — `docs/plans/stately-rising-jongga-assets.md` §4 참조).
- 마스코트 — 기존 `assets/illustrations/mascot/tiger_sad.png` 사용
  (Mascot 위젯이 이미 errorBuilder fallback 처리).

⇒ **PNG 없이도 빌드·실행 정상**. Jin이 PNG 작업하는 동안 코드는 작동.

### 6.3 Phase 1 SRS-UX-Patch 와 공존

`/vocab/legacy` (= 옛 단일 카드 화면) 는 그대로 작동.
"오늘 N neu · M Wdh." chip 라벨 (Phase 1 패치) 그대로 살아있음.
Jin이 신/구 비교 가능. **Phase 3 시작 시 legacy 제거 권장**.

### 6.4 Storage 키 마이그레이션 없음

기존 사용자의 `vokSeenIds` 는 자동으로 `wordsLearnedIn(pack)` 계산에 반영됨.
별도 마이그레이션 코드 X — 기존 사용자가 신 vocab 진입 시:
- 이미 본 단어가 있으면 → 해당 팩이 `inProgress` 로 보임
- 보스 한 번 도전해서 클리어 → cleared

회귀 위험 0 (기존 데이터 read-only).

### 6.5 한옥 단계 라벨 — Phase 3 시각화 대응 준비

`_LevelProgressHeader::_StageLabel` 이 현재 진행도 % 에 따라 단계 텍스트 출력:
- A1 0-25% → "Bauplatz vorbereiten"
- A1 25-50% → "Sockel legen"
- ... B2 100% → "Jongga vollendet"

Phase 3 의 한옥 PNG 배경 변화는 같은 % 임계점 사용 → 텍스트와 시각이 일관됨.

---

## 7. 신뢰 가능한 사실 vs 가정

### 검증됨 (사실)
- 위젯 API 매칭 (SoriButton.onTap, SoriCard.tinted, SoriChip.accent,
  Mascot named ctor) — `lib/widgets/sori/` 코드 직접 grep 확인
- ARB ↔ generated _de/_en 키 1:1 (스펠링 일치)
- `flutter_test` 패턴 — 기존 테스트 (`vocab_pack_test.dart` 등) 와 동일 구조
- Storage 패턴 — 기존 SRS 캐시 (`_srsCache`) 와 동일하게 lazy load + persist
- VocabPackService.findById / packsForLevel — Phase 1 에서 이미 사용 검증

### 가정 (Jin 검증 필요)
- `flutter analyze` 0 issues — 샌드박스에 Flutter 없어서 실행 못 함
- `flutter test` 전체 통과 — 동일. Phase 2 만 ~28 신규 케이스
- 실기기에서 3단계 흐름 깨끗하게 진행 — 시각·터치 검증 필요
- Firestore 진행도 sync — Firebase 권한 있는 환경에서만 검증 가능
- TTS auto-play (boss stage 진입 시) — 기기 사운드 검증 필요

### 의도적으로 미수행
- 한옥 시각화 (Phase 3 작업)
- 특별 퀘스트 시스템 (Phase 4)
- 책 한 컷 (Phase 5)
- 계 (Phase 6+)

---

## 8. 변경 파일 목록 (커밋 시 참고)

```
신규:
  docs/plans/stately-rising-jongga-phase2-handover.md
  lib/screens/vocab_packs_screen.dart
  lib/screens/vocab_pack_screen.dart
  lib/screens/vocab_pack_result_screen.dart
  lib/services/pack_progress_service.dart
  lib/widgets/sori/pack_card.dart
  lib/widgets/sori/dancheong_stamp.dart
  test/pack_progress_service_test.dart
  test/dancheong_stamp_test.dart

수정:
  lib/main.dart                        (4 신규 routes + 2 imports)
  lib/services/storage_service.dart    (+ packProgressJson API)
  lib/l10n/app_de.arb                  (+35 키)
  lib/l10n/app_en.arb                  (+35 키)
  lib/l10n/generated/app_localizations.dart       (+ method signatures)
  lib/l10n/generated/app_localizations_de.dart    (+ DE impl)
  lib/l10n/generated/app_localizations_en.dart    (+ EN impl)

이름 변경:
  lib/screens/vocab_screen.dart → lib/screens/legacy_vocab_screen.dart
    class VocabScreen → class LegacyVocabScreen
```

---

## 9. 다음 단계 (Phase 3 — 한옥 시각화)

Phase 2 검증 완료 후:

1. `lib/models/hanok_stage.dart` — 12 단계 enum + `computeStage(progress)`
2. `lib/widgets/sori/madang_background.dart` — 단계별 PNG cross-fade
3. `lib/widgets/sori/hanok_cinematic.dart` — 까치 비행 + 새 부분 등장
4. `assets/illustrations/hanok_stages/` 폴더 + pubspec
5. 홈 화면 통합 (`home_screen.dart` 배경 교체)
6. PNG 자산 양산 시작 (Sprint 1: stage_0/4/6/8/11 × light+dark = 10장)

병행:
- Jin이 Sprint 1 PNG 10장 양산 시작 (`docs/plans/stately-rising-jongga-assets.md` §11 참조)
- Phase 3 코드는 placeholder/단색 graident fallback 으로 빌드 가능

---

**작성**: Claude
**검토 대기**: Jin
**커밋 권한**: Jin 명시 요청 시
