# W3.5 잔여 하드닝 Implementation Plan

> **REQUIRED SUB-SKILL:** Use `superpowers:executing-plans` to execute this plan task by task in the current Codex thread.

**Goal:** W4가 병합된 최신 `origin/main`에서 단어팩 완료 원자성·복습 오류 상태·문화 노트 실패 격리·grammar sheet 수명·지연 timer 취소의 다섯 회귀를 TDD로 닫는다.

**Architecture:** 화면에 테스트 가능한 loader/operation seam을 주입하고 기본값은 기존 서비스에 연결한다. 권위 저장은 재시도 가능한 단계형 coordinator가 완료를 기억해 부분 성공 뒤 XP·도장·기록을 중복 적용하지 않는다. 보조 콘텐츠와 analytics는 실패를 격리하지만 저장·course progression 실패는 성공 화면으로 강등하지 않는다.

**Tech Stack:** Flutter, Dart async/Timer, flutter_test, fake_async where already available, generated l10n.

**Spec:** `docs/superpowers/specs/2026-08-28-w4-w6-completion-design.md` §6 and §9. This plan supersedes Tasks 3–7 of `docs/superpowers/plans/2026-08-27-w35-hardening.md` wherever the older plan allowed success navigation after authoritative persistence failure.

## Global Constraints

- Start from a fresh W3.5 worktree after the W4 PR head is merged into `origin/main`.
- Success navigation occurs only after every authoritative step succeeds.
- A retry resumes incomplete steps and never awards XP, stamps, boss clear, or course progress twice.
- Raw exceptions never reach localized UI. Optional culture notes fail soft without unhandled futures.
- All callbacks check the lifecycle owner they update; parent `mounted` does not prove a modal sheet is mounted.
- Add only DE/EN localization keys and regenerate generated l10n from ARB sources.

### Task 1: resumable vocab-pack finish coordinator

**Files:**

- Create: `lib/services/vocab_pack_finish_coordinator.dart`
- Modify: `lib/screens/vocab_pack_screen.dart`
- Modify: `lib/l10n/app_de.arb`
- Modify: `lib/l10n/app_en.arb`
- Regenerate: `lib/l10n/generated/app_localizations*.dart`
- Create: `test/vocab_pack_finish_coordinator_test.dart`
- Modify: the existing vocab-pack screen widget test

**Interface:**

```dart
abstract interface class VocabPackFinishOperations {
  Future<void> recordBossAttempt(VocabPackFinishRequest request);
  Future<void> recordCourseAttempt(VocabPackFinishRequest request);
  Future<void> awardXp(VocabPackFinishRequest request);
  Future<void> recordCompletionStamp(VocabPackFinishRequest request);
  Future<void> persistPendingState(VocabPackFinishRequest request);
}

final class VocabPackFinishCoordinator {
  Future<void> finish(VocabPackFinishRequest request);
}
```

The coordinator keeps a completed-step set for one immutable request. Repeating `finish` skips completed steps. Analytics remains outside the authoritative set and catches/reports its own error.

**TDD steps:**

1. Write unit tests for failure at each of the five steps, retry, and exact-once invocation of prior successful steps.
2. Run `flutter test --no-pub test/vocab_pack_finish_coordinator_test.dart` and confirm the new tests fail because the type is absent.
3. Implement the request, operations adapter, and coordinator with sequential awaited steps.
4. Add widget tests: duplicate finish tap calls one in-flight future; failure stays on the pack screen with localized error and Retry; retry success navigates exactly once.
5. In `_VocabPackScreenState`, add `_finishing`, `_finishError`, one coordinator/request, and `Future<void> _finish(...)`. Disable all answer/finish actions while running.
6. Add `vocabPackFinishSaveError` and retry action strings to DE/EN, run `flutter gen-l10n`, format, and rerun focused tests.

**Commit:** `fix(vocab): make pack completion resumable and atomic`

### Task 2: explicit review loading states

**Files:**

- Modify: `lib/screens/review_session_screen.dart`
- Modify: `test/review_session_screen_test.dart` or the existing review loading test

**Interface:**

```dart
typedef ReviewableLoader = Future<List<SrsWord>> Function();

enum ReviewLoadState { loading, ready, empty, error }
```

`ReviewSessionScreen` accepts an optional loader and defaults to the existing SRS service call.

**TDD steps:**

1. Add tests for delayed loading, true empty deck, thrown loader, retry from error, and no raw exception text.
2. Confirm the thrown-loader test currently renders the empty celebration and therefore fails.
3. Replace `_loading`/implicit empty fallback with `ReviewLoadState`; `_load` catches into `error`, and retry returns to `loading`.
4. Reuse existing localized `loadErrorTryAgain` and `btnRetry`; do not add duplicate copy.
5. Run focused review tests plus route tests for `/review` and `/review/hub`.

**Commit:** `fix(review): separate empty deck from recoverable load error`

### Task 3: culture-note failure containment

**Files:**

- Modify: `lib/screens/vocab_pack_screen.dart` only if it loads culture notes after W4 integration
- Modify: `lib/screens/legacy_vocab_screen.dart`
- Modify: `lib/screens/review_session_screen.dart`
- Modify: existing widget tests for the affected screens

**Interface:**

```dart
typedef CultureNotesLoader = Future<CultureNotesData> Function();
```

Each screen accepts an optional loader, defaults to `CultureNotesService.load`, and owns `Future<void> _loadCultureNotes()` with `try/catch`; success calls `setState` only when mounted, failure leaves the optional note absent.

**TDD steps:**

1. Add per-screen tests with a completer that resolves after disposal and a loader that throws.
2. Capture `FlutterError.onError`/zone errors using the repository's existing test helper and assert no unhandled async error.
3. Replace unobserved `.then(...)` calls with awaited owner methods.
4. Run the affected widget tests twice to catch late completion leakage.

**Commit:** `fix(content): contain optional culture-note load failures`

### Task 4: grammar checkpoint modal lifecycle

**Files:**

- Modify: `lib/screens/grammar_screen.dart`
- Modify: the existing grammar checkpoint widget test

**Interface:**

```dart
typedef GrammarCheckpointRecorder = Future<void> Function(
  GrammarCheckpointAttempt attempt,
);
```

`GrammarScreen` accepts an optional recorder defaulting to `CourseActivityReporter.recordContentAttempt`.

**TDD steps:**

1. Add a test that starts submission, dismisses the bottom sheet, completes the recorder, and asserts no `setState() called after dispose`/modal error.
2. Add a double-tap test proving one recorder call while `isSaving` is true.
3. In the sheet closure, check `sheetContext.mounted` before every `setLocal`. Parent-owned `_submittedAnswers` may update only when the parent is mounted.
4. Catch recorder errors; show a localized parent snackbar only while parent is mounted and leave the answer retryable.
5. Run grammar screen, grammar plan, and `/grammar_choice_quiz` route tests.

**Commit:** `fix(grammar): bind checkpoint updates to sheet lifetime`

### Task 5: cancelable vocab-pack advance timer

**Files:**

- Modify: `lib/screens/vocab_pack_screen.dart`
- Modify: existing vocab-pack timing widget tests

**Implementation:** add `Timer? _advanceTimer`; cancel before scheduling, on question/stage reset, before finish, and in `dispose`. Make `_advanceQuiz` async, and have the timer callback call `unawaited(_advanceQuiz())` only after checking `mounted` and `_finishing`.

**TDD steps:**

1. Add tests for dispose before 850 ms, rapid reschedule, and finish before timer fires.
2. Confirm at least the dispose test fails with the current `Future.delayed` implementation.
3. Implement the timer lifecycle and import `dart:async`.
4. Run timing tests with fake time, then all vocab-pack tests.

**Commit:** `fix(vocab): cancel delayed quiz advancement with screen lifetime`

### Task 6: W3.5 wave proof

Run serially:

```powershell
dart format lib/services/vocab_pack_finish_coordinator.dart lib/screens/vocab_pack_screen.dart lib/screens/review_session_screen.dart lib/screens/legacy_vocab_screen.dart lib/screens/grammar_screen.dart test/vocab_pack_finish_coordinator_test.dart
git diff --check
flutter analyze --no-pub
flutter test --no-pub --reporter failures-only
graphify update .
```

Inspect Graphify churn, commit only intentional output, push the W3.5 branch, and prove required CI against the current PR head. Merge only after CI succeeds, then prove the head is in `origin/main` and the main-push suite/build are green.
