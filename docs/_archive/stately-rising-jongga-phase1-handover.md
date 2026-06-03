# Phase 1 Handover — stately-rising-jongga

> ✅ **실행완료 — 코드 구현 완료** (2026-06-03 아카이브)
> 이 핸드오버의 코드 작업은 끝났고 `lib/`에 반영·검증됨 (`flutter analyze` 0 · `flutter test` 218 통과).
> 남은 운영/배포(Cloud Function·Firestore rules, 실기기 QA, 스토어 등록)는 → [`../IMPROVEMENT_PLAN_2026-06-03.md`](../IMPROVEMENT_PLAN_2026-06-03.md) TRACK 0 으로 이관.

> **세션**: 2026-05-31 · Claude
> **상위 plan**: `docs/plans/stately-rising-jongga.md` §3
> **상태**: 코드 작성 완료 — Jin 로컬 검증 대기

---

## 1. 변경 요약 (TL;DR)

| 영역 | 파일 | 변경 |
|---|---|---|
| 데이터 | `assets/data/korean_vocab.csv` | 11 컬럼으로 확장 (+ pack_id, pack_order, is_review_boss). **백업**: `korean_vocab.csv.bak` |
| 데이터 | `docs/data/vocab_pack_map.md` | 신규 — 사람 검토용 팩별 단어 리스트 |
| 마이그레이션 | `scripts/build_vocab_packs.py` | 신규 — 멱등 CSV 마이그레이션 스크립트 |
| 모델 | `lib/models/vocab.dart` | pack 필드 3개 추가, `fromRow` 방어적으로 |
| 모델 | `lib/models/vocab_pack.dart` | 신규 — VocabPack |
| 모델 | `lib/models/pack_progress.dart` | 신규 — PackStatus enum + PackProgress |
| 서비스 | `lib/services/vocab_pack_service.dart` | 신규 — 팩 로딩·그룹화·디스플레이 |
| 서비스 | `lib/services/firestore_progress_service.dart` | 신규 — Firestore CRUD (`users/{uid}/packs/`) |
| 서비스 | `lib/services/storage_service.dart` | `todayNewIds`, `todayReviewIds`, `todayGoalIds` 추가. 기존 `dueIds` 유지 |
| 화면 | `lib/screens/vocab_screen.dart` | SRS UX 임시 패치 — "🔥 522 fällig" → "🔥 Heute (10 neu · 5 Wdh.)" |
| l10n | `lib/l10n/app_de.arb`, `app_en.arb` | `vocabTodayBadge(newCount, reviewCount)` 신규 키 |
| l10n | `lib/l10n/generated/*.dart` | 동일 메서드 hand-edit (Jin이 `flutter gen-l10n` 실행 시 자동 재생성) |
| Firebase | `firestore.rules`, `firestore.indexes.json` | 신규 — `users/{uid}` 격리 + 미래 path 예약 |
| Firebase | `firebase.json` | firestore 설정 추가 |
| 테스트 | `test/today_goal_test.dart` | 신규 — SRS Tagesziel 캡 검증 |
| 테스트 | `test/vocab_pack_test.dart` | 신규 — Vocab.fromRow 호환성 + VocabPack 분할/디스플레이 |
| 테스트 | `test/pack_progress_test.dart` | 신규 — PackProgress JSON round-trip |

---

## 2. 데이터 마이그레이션 결과 (사실 검증)

스크립트 실행 결과 (Python 3, sandbox):
```
[1/4] Loaded 526 rows
[2/4] Assigned base pack_ids
[3/4] Split oversized packs → 61 total packs
[4/4] Assigned order + marked 127 boss words
```

검증 (Python assertions, 모두 통과):
- 526 rows 보존
- 11 컬럼 정확
- 모든 row pack_id 비어있지 않음
- pack_order 1..N 연속 (모든 팩)
- A1: 211 단어 / 24 팩 (평균 8.8)
- A2: 140 단어 / 17 팩 (평균 8.2)
- B1: 103 단어 / 12 팩 (평균 8.6)
- B2: 72 단어 / 8 팩 (평균 9.0)

팩 크기 분포: 4~13 단어 (목표 범위 안). 너무 작은 팩 1개 (`a2_education` 4개 — A2 교육이 적어서 그래, Jin 콘텐츠 백로그로 채우면 자동 ≥7).

분할 예시:
- A1 `Alltag` 36개 → `a1_daily_1/2/3/4` 각 9개
- A1 `Zahlen+Menge` 26개 → `a1_numbers_1/2/3` (9/9/8)

플랜과의 차이:
- 플랜 §12 초안: A1 21팩 → 실제 24팩 (Goethe 토픽 그룹화가 살짝 다름. 차이는 검수 후 `scripts/build_vocab_packs.py::TOPIC_TO_PACK` 만 수정해서 재실행하면 됨)
- 플랜 §1.2: 총 ~56팩 → 실제 61팩

---

## 3. Jin이 로컬에서 실행해야 하는 검증

```bash
# 0. 백업 정리 (확인 후)
rm assets/data/korean_vocab.csv.bak

# 1. 의존성 갱신 (이번 phase 는 신규 패키지 X — 변경 없을 거지만 안전상)
flutter pub get

# 2. l10n 재생성 (hand-edit 한 generated 파일과 일치 확인)
flutter gen-l10n

# 3. 정적 분석
flutter analyze
# 기대: 0 issues. 새로 추가한 코드 + 기존 화면 모두 통과해야 함.

# 4. 단위 테스트 — 신규 3개 + 기존 회귀
flutter test test/today_goal_test.dart
flutter test test/vocab_pack_test.dart
flutter test test/pack_progress_test.dart
flutter test  # 전체 — 기존 vocab_mastery_test, srs 회귀 확인

# 5. 실기기 (Android 권장) 시각 검증
flutter run -d <android-id>
# - /vocab 진입 → 헤더에 "🔥 Heute (N neu · M Wdh.)" 표시 확인 (이전 "522 fällig" X)
# - 카드 한두장 학습 → 카운터 감소 확인
# - 모두 학습 후 → "🎉 Heute alles erledigt!" empty state 확인
# - 모드 chip 토글 (Heute / Favoriten / Alle) 동작 확인

# 6. Firebase 보안 규칙 배포 (선택 — Phase 2 본격 사용 전까지 미루어도 됨)
firebase deploy --only firestore:rules
# 기대: "✔ Deploy complete!"
```

---

## 4. 알려진 한계 & 향후 작업

### 4.1 Phase 1 범위 — 했음 / 안했음

**했음** (이 세션):
- 데이터 구조 (CSV + 모델)
- 팩 서비스 (로딩·그룹화·디스플레이)
- Firestore 진행도 서비스 (CRUD)
- Firestore 보안 규칙
- SRS UX 임시 패치 (오늘의 목표 표시)
- 단위 테스트 (3 파일, ~25 케이스)

**안했음** (Phase 2+):
- 팩 선택 화면 (`/vocab/packs`)
- 팩 플레이 화면 (`/vocab/pack`)
- 보스 단어 클리어 로직 (Firestore status 업데이트)
- 한옥 단계 진행도 시스템 (Phase 3)
- 단청 도장 시각화

### 4.2 SRS UX 패치는 임시

현재 vocab_screen 은 여전히 단일 카드 흐름. 일일 cap 만 적용됨. Phase 2 에서 vocab_screen 전체가 팩 선택 → 팩 플레이로 재설계될 예정.

`Storage.dueIds()` 는 유지 — Phase 2 까지 외부에서 쓸 수 있어서 (legacy compat).

### 4.3 generated l10n hand-edit

`flutter gen-l10n` 실행 시 ARB 에서 자동 재생성 — 내가 hand-edit 한 코드는 같은 형태로 다시 생성됨 (idempotent). Jin 환경에서 gen-l10n 실행이 안전.

### 4.4 Firestore 데이터 모델 — Phase 2 시 활용

`FirestoreProgressService.savePack(PackProgress)` 호출 시점:
- Phase 2 의 `VocabPackResultScreen` 에서 보스 정답률 계산 후 저장
- 클리어 시 status: cleared + clearedAt 갱신

지금은 호출되는 곳 없음 (서비스만 준비). Phase 2 에서 wire-up.

### 4.5 displayLabel 다국어

현재 `VocabPackService.displayLabel()` 는 빌드 타임 상수 Map 에서 DE/EN 라벨 lookup.
ARB 키 (`pack_a1_greetings`) 로 옮기지 않은 이유: 61개 팩 × 다국어 키 = ARB 폭증. Phase 2 UI 의 사용자 피드백 보고 ARB 이관 결정.

---

## 5. 다음 단계 (Phase 2 — 팩 화면)

Phase 1 검증 끝나면 Phase 2 시작:

1. `lib/screens/vocab_packs_screen.dart` (팩 선택 화면)
2. `lib/screens/vocab_pack_screen.dart` (3단계 플레이: 신규 → 미니퀴즈 → 보스)
3. `lib/screens/vocab_pack_result_screen.dart` (결과 + 도장)
4. `lib/widgets/sori/pack_card.dart` + `dancheong_stamp.dart`
5. `main.dart` 라우트 추가 (`/vocab/packs`, `/vocab/pack`, `/vocab/result`)
6. 보스 단어 정답률 ≥ 70% → 다음 팩 unlock 로직
7. `FirestoreProgressService.savePack()` wire-up

병행 (Jin):
- PNG 자산 양산 시작 — Sprint 1 (한옥 stage 0·4·6·8·11 light+dark + 단청 도장 8종 = 18장)
  → `docs/plans/stately-rising-jongga-assets.md` 참조

---

## 6. 변경 파일 목록 (커밋 시 참고)

```
신규:
  assets/data/korean_vocab.csv.bak     (백업 — 검수 후 삭제)
  docs/data/vocab_pack_map.md
  docs/plans/stately-rising-jongga-phase1-handover.md
  firestore.indexes.json
  firestore.rules
  lib/models/pack_progress.dart
  lib/models/vocab_pack.dart
  lib/services/firestore_progress_service.dart
  lib/services/vocab_pack_service.dart
  scripts/build_vocab_packs.py
  test/pack_progress_test.dart
  test/today_goal_test.dart
  test/vocab_pack_test.dart

수정:
  assets/data/korean_vocab.csv         (8 → 11 컬럼)
  firebase.json                         (firestore 설정 추가)
  lib/l10n/app_de.arb                   (+ vocabTodayBadge)
  lib/l10n/app_en.arb                   (+ vocabTodayBadge)
  lib/l10n/generated/app_localizations.dart       (+ method signature)
  lib/l10n/generated/app_localizations_de.dart    (+ method impl)
  lib/l10n/generated/app_localizations_en.dart    (+ method impl)
  lib/models/vocab.dart                 (+ pack 필드 3개, fromRow 방어적)
  lib/screens/vocab_screen.dart         (SRS UX 패치)
  lib/services/storage_service.dart     (+ todayNew/Review/GoalIds)
```

---

## 7. 신뢰 가능한 사실 vs 가정

### 검증됨 (사실)
- CSV 526 rows / 11 cols / pack 분포 (Python 3 실행 결과)
- 기존 코드 패턴 (storage_service.dart SM-2, cloud_sync.dart 사용 path)
- Vocab.fromRow 방어 인덱싱 — 8-col / 11-col 둘 다 처리 (테스트 작성)
- Firestore rules 문법 — `cloud_sync.dart` 가 이미 `users/{uid}` 쓰니까 호환

### 가정 (Jin 검증 필요)
- `flutter analyze` 0 issues — 샌드박스에 Flutter 없어 실행 못 함
- `flutter test` 통과 — 동일
- 실기기에서 vocab_screen 진입 시 의도대로 보임 — 시각 검증 필요
- Firebase 보안 규칙 배포 시 기존 `cloud_sync.dart` 백업 동작 유지 — `users/{uid}` 직접 write 가 `isOwner` 만족하므로 OK 추정. 그래도 한 번 backup→restore 사이클 테스트 권장.

### 의도적으로 미수행
- 한옥 마당 시각화 (Phase 3 작업)
- 팩 선택 UI (Phase 2 작업)
- Cloud Function (Phase 5 작업)

---

**작성**: Claude
**검토 대기**: Jin
**커밋 권한**: Jin 명시 요청 시
