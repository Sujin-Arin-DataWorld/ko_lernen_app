# 한옥 V1 / 2026-08-17 인수인계 (크레딧 저소모 하이재) 

## 1) 현재 기준 고정

- 작업 루트: `C:\Users\vjinn\OneDrive\Desktop\hangulsori\ko_lernen_app`
- 현재 확인된 Git 상태
  - `git rev-parse --short HEAD` = `21c683ae`
  - `git rev-parse --short origin/main` = `21c683ae`
  - 브랜치: `main`
  - `git status --short --branch`: `main...origin/main`
- 현재 working tree는 정리 필요 (다음 항목이 수정/추적되지 않음)
  - 수정: `.github/workflows/ci.yml`, `docs/SESSION_LOG.md`
  - 미추적: `.claude/data/`, `.mvn/`, `.tours/`, `marketing/`, `docs/HANOK_V1_HANDOFF_2026-08-17*.md`
- 핵심 경로
  - 한옥 A1 런타임 카탈로그: `lib/data/a1_hanok_construction_catalog.dart`
  - A1 렌더/상태: `lib/data/a1_hanok_construction_state_renderer.dart`
  - 자산 검사: `tool/check_personal_hanok_assets.py`
  - 계정 재조정: `lib/services/account/account_reconciliation.dart`, `lib/services/cloud_sync.dart`
  - 한옥 통합 테스트: `test/a1_hanok_construction_*_test.dart`, `test/hanok_account_reconciliation_test.dart`, `test/services/account/account_reconciliation_test.dart`

- 사용자 언급 커밋군(`23342c57` + `ff27b1b4`~)은 현재 커밋 트리에서 확인됨 (브랜치 include는 확인됨). 다만 배포/병합 단위로는 **아직 최신 main에 반영되지 않은 asset state 승격 작업**과 일부 통합 마무리만 남아 있음.

## 2) 이 세션 결과(실측)

### 완료/안정된 상태
- PR 계열(생산형 증거, 재조정, A1 렌더 카탈로그) 핵심 계약은 코드에 반영되어 있고, 주요 테스트가 통과하는 구간이 유지됨.
- 계정 동기화 회귀 4개 묶음 시험 항목 중 다수는 pass.
- `flutter test`로 확인한 항목
  - `test/services/account/account_reconciliation_test.dart` ✅
  - `test/hanok_account_reconciliation_test.dart` ✅
  - `test/a1_hanok_construction_map_test.dart` ✅
  - `test/a1_hanok_construction_catalog_test.dart` ✅

### 남은 핵심 blocker(최우선)
1. **A1 런타임 state 자산 승격 미완성 (현재 가장 큰 사용자 체감 이슈)**
   - `assets/illustrations/personal_hanok_v2/a1/states/` 폴더가 아직 없음
   - `assets_unused/pending_review/a1_states/`엔 `05~10`만 존재
   - `tool/check_personal_hanok_assets.py` 출력: `A1 runtime states are absent and were not promoted`
   - 따라서 화면에 16단계 건축체감이 완전 반영되지 않음.
2. **“site-runtime 트랙” 관련 혼선**
   - 브랜치 트랙 불일치라기보다, 런타임 `A1 state`가 `pending_review`에 있고 `assets/illustrations/.../a1/states`로 승격되지 않은 상태가 원인.
3. **운영상 정합성 hardening 소량 잔여**
   - `LocalAccountReconciliationGenerationConflict`/`replay` 경합 경로의 추가 로그·재시도 가드 보강 필요(이미 프레임은 있음).

## 3) 다음 세션 즉시 실행 순서 (실제 실행 순서 고정)

### Step A: 기준 재동기화(첫 2분)
```bash
cd C:\Users\vjinn\OneDrive\Desktop\hangulsori\ko_lernen_app
git fetch --all --prune
git status --short --branch
git rev-parse HEAD
git rev-parse origin/main
```
- 현재처럼 `main==origin/main`이면 추가 pull 불필요.
- 다르면 `git pull --ff-only` 후 작업 브랜치로 이동.

### Step B: A1 자산 누락 보정(실질 완성)
1) 현재 생성 원본이 있는지 확인
```bash
Get-ChildItem assets_unused/pending_review/a1_states -File | Select-Object Name, Length
Get-ChildItem assets_unused/pending_review/a1_layers -File | Select-Object Name, Length
```

2) 누락분 생성 규칙(권장 순서)
- 대상 파일(누적 17):
  - `01_site_setout.webp` ... `16_landscape_move_in.webp`
  - 기본(0단계) `assets/illustrations/personal_hanok_v2/map/site_base_light.png`
- 가능하면 기존 워크플로 스크립트 재활용
  - `tool/compose_hanok_a1_state.py`
  - `tool/promote_hanok_a1_states.py`
- 승인 가드 후 반드시 체크:
```bash
python tool/check_personal_hanok_assets.py
flutter test --no-pub --reporter compact test/a1_hanok_construction_catalog_test.dart test/a1_hanok_construction_map_test.dart
```

### Step C: 통합 가드 회귀 최소 추가(안전성)
- 대상 파일
  - `lib/services/account/account_reconciliation.dart`
  - `lib/services/cloud_sync.dart`
  - `test/services/account/account_reconciliation_test.dart`
  - `test/hanok_account_reconciliation_test.dart`
- 점검 포인트
  - A1 generation load/저장 순서에서 HANOK generation 교차재기록 케이스
  - `LocalReconciliationGenerationConflict` 후 retry loop에서 stale session 감지
  - conflict 시 데이터 덮어쓰기 방지
- 재실행
```bash
cd C:\Users\vjinn\OneDrive\Desktop\hangulsori\ko_lernen_app
flutter test --no-pub --reporter compact test/services/account/account_reconciliation_test.dart test/hanok_account_reconciliation_test.dart
git diff --check
```

### Step D: 전체 게이트(배포 전)
```bash
cd C:\Users\vjinn\OneDrive\Desktop\hangulsori\ko_lernen_app
flutter analyze --no-pub --fatal-infos
flutter test --no-pub --reporter compact
```

## 4) 커밋 전략(크레딧 저소모형)
- 한 번에 한 PR, 한 테스트 묶음으로만 진행.
- 패턴: **변경 → 테스트 1개 묶음 → 통과 시 즉시 커밋**
- 권장 커밋 단위
  1) `feat(hanok): promote A1 runtime states`
  2) `fix(account): tighten Hanok reconciliation generation guard`
  3) `test(...): add regression for Hanok generation conflict`

## 5) 커맨드로 바로 확인 가능한 현재 증빙
- `python tool/check_personal_hanok_assets.py`
  - 결과는 `A1 runtime states are absent and were not promoted` 이어야 현재 blocker
- `git log --oneline --graph --decorate --max-count=12 39dff9df..HEAD`
  - `39dff9df`는 `chore(release): prepare Android build 1121` (현재 HEAD의 조상)
- `git branch --contains 23342c57`
  - 해당 Batch06 커밋군은 현재 local branch 범위에서 확인됨

## 6) Batch06/커밋 반영 계획

요청사항에서 제시한 Batch06 15개 커밋은 대체로 local 히스토리/브랜치에 존재.
다음 방식 권장:
- `39dff9df`를 고정 베이스로 유지해야 한다면:
```bash
git checkout -b codex/batch06-rebase-20260817 39dff9df
git cherry-pick ff27b1b4 db7f9e84 963f6bad 23342c57 857f5fed 59982d55 108e2579 b84c8978 4033cd8e ca8e82d9 e8dada25 e2b647e7 3ff92bab 7c210c2d ffadc8e3
```
- 단, 지금 상태에서는 A1 자산 승격이 선행되어야 체감치가 즉시 나옴.

## 7) “왜 오래 걸렸나” 정리(팀 공유용)
- 단일 기능이 아니라 `PR2 생산형 증거`, `PR3/4 한옥 projection`, `계정 동기화 충돌 hardening`, `A1 자산 파이프라인`, `테스트/CI 게이트`가 함께 얽혀 있음.
- 따라서 실제로는 “코드 작업”이 아니라 “합의-검증-증분 통합”이 메인 임.

## 8) 다음 세션 도착 후 바로 시작 체크리스트(10분 체크)
- `git status --short --branch`
- `python tool/check_personal_hanok_assets.py`
- `Get-ChildItem assets_unused/pending_review/a1_states`
- `flutter test --no-pub --reporter compact test/a1_hanok_construction_catalog_test.dart`
- `flutter analyze --no-pub --fatal-infos`

## 9) 추천 모델/추론량
- 현재 남은 단계는 실패 비용 높음(동기화 race + 자산 계약 + 테스트 게이트)이라
  **5.6 Sol + High** 유지 추천.
- 단순 점검/에셋 파일 존재성 확인은 Terra/Luna로 분기 가능.
