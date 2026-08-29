# W5-A 공통 계약 롤아웃 Implementation Plan

> **REQUIRED SUB-SKILL:** Use `superpowers:executing-plans` to execute this plan task by task in the current Codex thread.

**Goal:** W3.5가 병합된 최신 main에서 레벨 필터·학습 오디오·복습 이력·홈 탈출·hero/chrome 가드·feed 후보 manifest를 공통 컴포넌트 계약으로 통일한다.

**Architecture:** 화면별 임시 UI를 새 서비스로 복제하지 않고 `lib/widgets/sori`의 기존 primitives를 확장한다. 상태가 복잡한 복습은 순수 queue model로 분리한다. 가드 allowlist는 이 PR에서 0으로 낮추고, `FeedPhysics.snap`은 후보 데이터만 등록한 채 runtime 기본값을 `legacy`로 유지한다.

**Tech Stack:** Flutter, Dart, flutter_test, semantics/widget tests, source guard tests.

**Spec:** `docs/superpowers/specs/2026-08-28-w4-w6-completion-design.md` §§7.1, 9–11.

## Global Constraints

- W3.5 PR이 main에 병합된 뒤 fresh `origin/main` worktree에서 시작한다.
- 레벨 UI는 browse 화면에서 inline bar, play 화면에서 `SoriChromeRow` + bottom sheet를 사용한다.
- flip 카드의 tap 의미는 flip이고 음성은 indicator/명시적 audio control이다. 비-flip 콘텐츠 tap은 speak가 가능하다.
- review 이전/다음 탐색은 pending queue를 바꾸거나 SRS·XP를 다시 기록하지 않는다.
- 홈 버튼은 화면당 정확히 하나다. 기존 leading을 덮지 않는다.
- `FeedPhysics.snap` 기본값·legacy 삭제는 Jin 실기기 승인 전 금지한다.
- ratchet 상한과 allowlist는 증가시키지 않는다.

### Task 1: 공용 레벨 필터 sheet와 11개 잔여 표면 이관

**Files:**

- Modify: `lib/widgets/sori/level_filter_bar.dart`
- Modify: `lib/screens/chosung_quiz_screen.dart`
- Modify: `lib/screens/cloze_game_screen.dart`
- Modify: `lib/screens/grammar_screen.dart`
- Modify: `lib/screens/legacy_vocab_screen.dart`
- Modify: `lib/screens/satz_arcade_screen.dart`
- Modify: `lib/screens/silben_kreuz_screen.dart`
- Modify: `lib/screens/speed_match_screen.dart`
- Modify: `lib/screens/vocab_packs_screen.dart`
- Create: `test/level_filter_guard_test.dart`
- Modify: `test/study_activity_responsive_test.dart`
- Create or modify: `test/sori_level_filter_bar_test.dart`

**Interface:**

```dart
Future<String?> showSoriLevelFilterSheet({
  required BuildContext context,
  required String selected,
  required List<String> levels,
  required String allLabel,
  required int Function(String level) countFor,
});
```

The sheet uses the same labels/counts/selection semantics as `SoriLevelFilterBar`, returns only a changed selection, and meets 48 dp tap targets.

**TDD steps:**

1. Add component tests for All + A1–C2, `C1 · N` labels, selected semantics, 48 dp target, keyboard activation, and horizontal sweep rather than assuming every chip is simultaneously built.
2. Add `level_filter_guard_test.dart` that scans the eight screens for their exact legacy DropdownButton/PopupMenuButton/duplicated Wrap+ChoiceChip constructs with an empty allowlist.
3. Run both tests and confirm the guard fails on the current source.
4. Implement `showSoriLevelFilterSheet` without changing `SoriLevelFilterBar.resolveStartLevel()`.
5. Migrate `vocab_packs_screen.dart` as inline browse; migrate the seven play screens through `SoriChromeRow` and the sheet. Remove both duplicated grammar selectors and responsive duplicate bars in cloze/satz.
6. Run `flutter test --no-pub test/sori_level_filter_bar_test.dart test/level_filter_guard_test.dart test/study_activity_responsive_test.dart` at 360×640, 390×844, 430×932, and 800×1280 cases already supported by the test harness.

**Commit:** `refactor(filters): unify remaining level selectors`

### Task 2: complete speakable wiring and direct-call ratchet

**Files:**

- Modify: `lib/widgets/sori/speakable.dart`
- Modify: `lib/screens/vocab_pack_screen.dart`
- Modify: `lib/screens/legacy_vocab_screen.dart`
- Modify: `lib/screens/custom_pack_play_screen.dart`
- Modify: `lib/screens/hangul_screen.dart`
- Modify: `lib/screens/grammar_screen.dart`
- Modify: `lib/screens/smalltalk_screen.dart`
- Modify: `lib/screens/quest_engines/quest_flow.dart`
- Modify: `lib/screens/cloze_game_screen.dart`
- Modify: `lib/screens/scenario_player_screen.dart`
- Modify: `test/content_audio_policy_guard_test.dart`
- Create: `test/speakable_screen_lifecycle_test.dart`

**Contract:** target screens do not call the low-level TTS service directly. Low-level service/adapters remain exempt. Flip surfaces expose a `SoriSpeechIndicator` or explicit audio action and keep tap-to-flip. Quest, cloze, and scenario dialog content use non-flip tap-to-speak. New speech cancels the previous utterance; dispose cannot update UI; local-cache and network failure retain the existing fallback order.

**TDD steps:**

1. Strengthen `content_audio_policy_guard_test.dart` to require zero direct TTS calls in the listed target screens.
2. Add lifecycle tests with injected `SoriSpeech`: rapid double request cancels one prior request, dispose during completion produces no exception, and a failed request returns the indicator to idle.
3. Confirm the guard fails against current direct calls.
4. Migrate one screen at a time to `SoriSpeakable`/`ContentSpeechController`; after each screen run its focused widget test and the guard.
5. Preserve the documented self-await protection in `speakable.dart`; do not simplify it into an await cycle.
6. Run `flutter test --no-pub test/content_audio_policy_guard_test.dart test/speakable_screen_lifecycle_test.dart test/quest_engines_uiux_test.dart`.

**Commit:** `refactor(audio): route learning surfaces through speakable contract`

### Task 3: served-history review queue with bounded wrong requeue

**Files:**

- Create: `lib/services/review_session_queue.dart`
- Create: `test/review_session_queue_test.dart`
- Modify: `lib/screens/review_session_screen.dart`
- Modify: existing review session widget tests

**Interface:**

```dart
final class ReviewSessionQueue<T> {
  T? get current;
  bool get isBrowsingHistory;
  int get servedPosition;
  int get originalCount;
  bool get isComplete;
  void recordJudgment({required bool correct});
  bool previous();
  bool nextHistory();
}
```

The queue owns pending items, actual served history, a history cursor, original unique IDs, first-judgment IDs, and a set of originals already requeued. The first wrong judgment for an original appends exactly one repeat. History navigation never mutates pending. Only the live/latest card accepts judgment. SRS/course evidence is recorded once per original per session; every wrong user action may still increment the existing wrong-attempt metric.

**TDD steps:**

1. Unit-test `A wrong → B → A repeat`: previous from repeat returns B; previous again returns A; forward returns B then repeat A; pending order is unchanged.
2. Test one bounded requeue, no requeue while browsing history, first-evidence exact once, progress denominator equal to original unique count, and completion only after pending exhausts.
3. Confirm tests fail because the model is absent.
4. Implement the pure queue with stable item identity supplied by `String Function(T)`.
5. Replace the review screen's array index with the queue; keep W3.5 loading/error states.
6. Add widget tests proving previous/forward do not call SRS/XP again and that the displayed card matches actual served history.
7. Run `flutter test --no-pub test/review_session_queue_test.dart test/review_session_screen_test.dart test/course_mastery_test.dart`.

**Commit:** `feat(review): model previous navigation from served history`

### Task 4: exactly-one home escape in SoriStudyFrame

**Files:**

- Modify: `lib/widgets/sori/study_frame.dart`
- Modify: `lib/widgets/sori/home_action.dart`
- Modify: the 25 screens discovered by `rg -l "SoriStudyFrame" lib/screens`
- Modify: `lib/screens/kkeunmari_screen.dart`
- Modify: `test/sori_study_frame_test.dart`
- Modify: `test/home_action_test.dart`
- Create: `test/study_home_escape_guard_test.dart`

**Interface:**

```dart
final class SoriHomeEscape {
  const SoriHomeEscape({
    this.confirmWhen = false,
    this.confirmTitle,
    this.confirmBody,
  });
}
```

`SoriStudyFrame` injects home as leading when no leading exists. With a custom leading it preserves that widget and prepends one home action. Explicit home actions already owned by a screen are removed so the final rendered count is exactly one.

**Active-confirm matrix:** kkeunmari while live; speed match while `_running`; pronunciation while recording/assessing; scenario after intro and before result; quiz/recall/typing surfaces after the first submitted answer or while a round timer is active. Static browse/study states exit immediately.

**TDD steps:**

1. Add StudyFrame tests for no leading, custom leading, existing action list, semantics label, and exact one home action.
2. Add a source/widget guard for all 25 StudyFrame screens with an empty duplicate allowlist.
3. Add focused confirmation tests for each active-confirm category and cancel/confirm routing.
4. Implement the frame policy, migrate screens, remove kkeunmari's explicit duplicate.
5. Run `flutter test --no-pub test/sori_study_frame_test.dart test/home_action_test.dart test/study_home_escape_guard_test.dart` and the affected route tests.

**Commit:** `feat(navigation): guarantee one home escape on study screens`

### Task 5: hero/chrome debt to zero

**Files:**

- Modify: `lib/screens/chosung_quiz_screen.dart`
- Modify: `lib/screens/hangul_screen.dart`
- Modify: `lib/screens/kkeunmari_screen.dart`
- Modify: `lib/screens/legacy_vocab_screen.dart`
- Modify: `lib/screens/scenario_player_screen.dart`
- Modify: `lib/screens/study_library_screen.dart`
- Modify: `test/hero_placement_guard_test.dart`
- Modify: `test/chrome_stack_guard_test.dart`

**TDD steps:**

1. Set `knownViolators` in `hero_placement_guard_test.dart` to empty and set the chrome multi-row allowlist to empty without raising the raw `InkWell` cap of 19.
2. Run the guards and record exact failing constructs.
3. Remove `HanokHeader` from the four play screens; retain required title/context through `SoriStudyFrame` and `SoriChromeRow`.
4. Consolidate the five multi-Wrap surfaces into the level-filter/chrome components introduced in Task 1.
5. Run both guards, responsive tests, text-scale 2.0 tests, and semantics tests.

**Commit:** `refactor(chrome): close hero and stacked-control allowlists`

### Task 6: FeedPhysics candidate manifest without promotion

**Files:**

- Create: `lib/data/feed_physics_candidates.dart`
- Create: `test/feed_physics_candidates_test.dart`
- Modify only if needed for testability: `lib/widgets/sori/content_feed.dart`

**Manifest entries:** `custom_pack_play_screen`, `grammar_screen`, `hangul_screen`, `legacy_vocab_screen`, `review_session_screen`, `smalltalk_screen`, `vocab_pack_screen`. Each entry stores route/screen ID, axes exercised, nested-scroll risk, active controls, and `approvedForSnap: false`.

**TDD steps:**

1. Test exact seven candidates, unique IDs, all `approvedForSnap == false`, and `SoriContentFeed` default `FeedPhysics.legacy`.
2. Add contract tests for explicit snap opt-in only; no candidate may change runtime behavior merely by appearing in the manifest.
3. Implement the immutable manifest and run `flutter test --no-pub test/feed_physics_candidates_test.dart test/content_feed_test.dart`.

**Commit:** `test(feed): inventory snap candidates behind device gate`

### Task 7: W5-A wave proof

Format all changed Dart files, run `git diff --check`, focused tests above, `flutter analyze --no-pub`, and the full suite serially. Run `graphify update .`, inspect all churn, then push and prove CI on the exact W5-A head before merge. Skip count must not exceed the inherited platform-only set.
