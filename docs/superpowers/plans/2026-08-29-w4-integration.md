# W4 통합 Implementation Plan

> **REQUIRED SUB-SKILL:** Use `superpowers:executing-plans` to execute this plan task by task in the current Codex thread.

**Goal:** 검증된 `feat/w4-progress-review`의 전체 커밋 역사를 현재 `origin/main`에 보존해 통합하고, 책장 중복 계산 한 건을 고친 뒤 현재 head의 로컬·CI 증거로 W4를 병합한다.

**Architecture:** 기존 W4 브랜치는 출처 증명 후 원격에 정확히 동기화한다. `feat/w4-integration-20260828`에서 `--no-ff` merge하고, 공통 파일은 양쪽 런타임 계약을 의미 기준으로 보존한다. 구현·테스트·문서 변경은 한 통합 PR에 두되 W4의 42개 기존 커밋 경계는 squash/rebase로 지우지 않는다.

**Tech Stack:** Flutter, Dart, flutter_test, Git worktree, GitHub Actions, Graphify.

**Spec:** `docs/superpowers/specs/2026-08-28-w4-w6-completion-design.md` §§4–5, 9–13.

## Global Constraints

- 작업 위치는 `C:\dev\hangulsori\ko_lernen_app_worktrees\w4-integration-20260828`이고 사용자 main checkout은 수정하지 않는다.
- W4 원본 `C:\dev\hangulsori\ko_lernen_app_w4`의 무시된 `.superpowers/sdd/**`와 Graphify 산출물을 삭제·이동·stage하지 않는다.
- 통합 워크트리의 `graphify-out/cache/last_query_stamp`도 stage하지 않는다.
- `LearnSessionQueue.servedPosition`, `recordScenarioCheckpoint`의 course-context 비유도, `/review`와 `/review/hub` 분리, 신규 저장 키의 backup/restore/export 화이트리스트를 변경하지 않는다.
- ARB 충돌은 `app_de.arb`와 `app_en.arb`를 먼저 해결한 뒤 저장소 표준 l10n 생성 명령으로 generated 파일을 재생성한다.
- 테스트 실행 중에는 파일을 수정하지 않는다. 실패가 생기면 실행이 끝난 뒤 원인을 분류한다.
- 커밋·push·PR·CI·merge 권한은 이 작업에 대해 사용자가 명시적으로 승인했다.

### Task 1: W4 원본 head 동결과 원격 증명

**Files:**

- Inspect only: `C:\dev\hangulsori\ko_lernen_app_w4`

**Step 1: 원본 상태와 그래프 기록**

Run:

```powershell
git status --short --untracked-files=all
git rev-parse HEAD
git merge-base origin/main HEAD
git rev-list --left-right --count origin/main...HEAD
git rev-list --left-right --count origin/feat/w4-progress-review...HEAD
```

Expected: head `b6b3150b3bac41b2accc5adc73bac9260c47c72b`; source-code 변경은 없고 Graphify 전용 변경만 존재한다. 기대값과 다르면 계획을 멈추고 새 상태를 증거로 재분류한다.

**Step 2: 원본 branch를 정확히 push**

Run:

```powershell
git push origin feat/w4-progress-review:feat/w4-progress-review
git ls-remote origin refs/heads/feat/w4-progress-review
```

Expected: 원격 SHA와 로컬 `HEAD`가 동일하다.

**Step 3: 통합 브랜치 기준 확인**

Run in the integration worktree:

```powershell
git fetch origin --prune
git rev-parse HEAD
git rev-list --left-right --count origin/main...HEAD
git status --short
```

Expected: design commit `6f2714ba...`가 `origin/main`보다 정확히 한 커밋 앞서고, 의도하지 않은 변경은 Graphify stamp 하나뿐이다.

### Task 2: W4 역사를 `--no-ff`로 통합

**Files:**

- Modify on conflict: `docs/UIUX_BIBLE_APPLICATION_EXECUTION_LOCK.md`
- Modify on conflict: `lib/l10n/app_de.arb`
- Modify on conflict: `lib/l10n/app_en.arb`
- Regenerate on conflict: `lib/l10n/generated/app_localizations.dart`
- Regenerate on conflict: `lib/l10n/generated/app_localizations_de.dart`
- Regenerate on conflict: `lib/l10n/generated/app_localizations_en.dart`
- Modify on conflict: `lib/main.dart`
- Modify on conflict: `test/uiux_bible_closeout_inventory_test.dart`

**Step 1: 병합 시작**

Run:

```powershell
git merge --no-ff feat/w4-progress-review
```

Expected: 자동 병합 또는 위 공통 파일에 한정된 충돌. merge commit은 모든 충돌·검증이 끝날 때까지 확정하지 않는다.

**Step 2: 의미 기준으로 충돌 해결**

- `main.dart`: 현재 main의 온보딩·미디어 라우트와 W4의 `/review/hub`, grammar plan, `/grammar_choice_quiz`를 모두 유지한다.
- ARB: 동일 key의 의미와 interpolation metadata를 비교하고 DE/EN parity를 유지한다.
- generated l10n: 충돌 표식을 수동 조립하지 않고 `flutter gen-l10n`으로 재생성한다.
- UIUX 문서·inventory test: 현재 main의 완료 항목과 W4 Task 1–18 항목을 합집합으로 유지한다.

Run:

```powershell
rg -n "^(<<<<<<<|=======|>>>>>>>)" . -g "!graphify-out/**"
flutter gen-l10n
dart format lib/main.dart test/uiux_bible_closeout_inventory_test.dart
git diff --check
```

Expected: 충돌 표식 0, l10n 생성 성공, whitespace 오류 0.

**Step 3: 불변 계약 집중 테스트**

Run the exact tests discovered by symbol search:

```powershell
rg -l "servedPosition|recordScenarioCheckpoint|/review/hub|grammar_choice_quiz|backup|restore|export" test
```

Run:

```powershell
flutter test --no-pub test/learn_session_queue_test.dart test/course_activity_reporter_test.dart test/course_mission_navigation_test.dart test/review_hub_screen_test.dart test/grammar_choice_quiz_route_test.dart test/grammar_plan_screen_test.dart
```

Expected: all pass without weakening assertions.

### Task 3: 책장 계산 중복 제거와 `+2` 계약 재확인

**Files:**

- Modify: `lib/screens/bookshelf_screen.dart`
- Test: existing bookshelf/custom-pack progress test discovered below

**Step 1: existing regression coverage 확인**

Run:

```powershell
rg -n "learnedWordCount|\+2|requeue|재출제" test lib/screens/bookshelf_screen.dart
```

Expected: 재출제 뒤 UI가 `· +2`를 표시한다는 기존 test가 있으면 그 test를 재사용한다. 정확한 단언이 없을 때만 같은 test file에 한 건을 추가한다.

**Step 2: 실패 증거 또는 중복 호출 증거 고정**

Run the focused test before the code change. If it already passes, retain that result as contract evidence and use the source-level duplicate call as the refactor trigger.

**Step 3: 한 번 계산해 재사용**

In `_CustomPackTile.build`, add one local:

```dart
final learnedCount = CustomPackService.learnedWordCount(pack);
```

Use `learnedCount` at both display/branch sites. Do not change the service or learned-word semantics.

**Step 4: focused verification**

Run:

```powershell
dart format lib/screens/bookshelf_screen.dart
flutter test --no-pub test/custom_pack_service_test.dart test/vocab_pack_screen_repeat_counter_test.dart
git diff --check
```

Expected: focused test passes and the build path contains one service call.

### Task 4: W4 integration verification, PR, CI, merge

**Files:**

- Verify: all merged W4 source and tests
- Update structurally: `graphify-out/**` only through the required command; exclude cache-only churn from staging

**Step 1: static and full local verification**

Run serially with no edits during execution:

```powershell
flutter analyze --no-pub
flutter test --no-pub --reporter failures-only
```

Expected: analyze clean; failures 0; skip count no greater than the known 14 unless a newly documented platform-only reason is proven.

**Step 2: architecture update and final diff audit**

Run:

```powershell
graphify update .
git status --short
git diff --check
git diff --stat origin/main...HEAD
```

Inspect Graphify output before staging. Stage only intentional source, test, doc, and stable graph changes.

**Step 3: commit and push**

Complete the pending merge with a message that preserves W4 history, then commit the bookshelf refactor separately if it was not part of the merge resolution:

```powershell
git commit
git push -u origin feat/w4-integration-20260828
```

Expected: remote branch SHA equals local HEAD.

**Step 4: PR and current-head CI proof**

Create/update the W4 integration PR. Record the exact PR head SHA, wait for Analyze/Test/Build and changed-area jobs on that SHA, and dispatch `ci.yml` only if no automatic run exists. A green run for an older SHA is not evidence.

**Step 5: merge and post-merge proof**

Merge only after required checks succeed. Fetch `origin/main`, prove the PR head is an ancestor, and wait for the main-push full suite and web build. Keep the W4 source worktree until these proofs are recorded.
