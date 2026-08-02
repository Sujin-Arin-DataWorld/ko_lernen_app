# Feedback Completion Coverage Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep feedback available after every intended learning completion while ensuring its metadata is privacy-safe, truthful about learner activity, and protected by real terminal-route regressions.

**Architecture:** Feedback contexts remain immutable values allocated by `FeedbackCompletionSlot`. Custom wordbook contexts will use an opaque pack ID plus a fixed safe machine label rather than any user-entered pack name. Daily Hangul will be modeled as a viewed guided-stroke animation, not handwriting: the UI waits for its guide to finish and emits an explicitly named guide-stroke aggregate. Route tests will drive real terminal paths rather than merely exercise context factories.

**Tech Stack:** Flutter/Dart, `flutter_test`, ARB localization generation, existing Sori widgets and `FeedbackCompletion` model.

## Global Constraints

- User-facing app copy is German and English only; do not add Korean UI strings.
- Do not place user-authored wordbook names, extracted words, OCR text, answers, or raw user gestures in feedback metadata.
- Preserve opaque custom pack IDs and existing feedback content types/missions.
- `ContentFeedbackContext` remains valid for every newly supported completion; do not silently rely on server rejection.
- Daily Hangul is a guided visual activity, not handwriting recognition; its score summary must not claim user-performed strokes.
- Treat non-learning/meta/browsing surfaces as intentional exclusions; do not add feedback to them.
- Work only on the isolated feature branch; no merge, push, deployment, AAB creation, rebase, or fetch.

---

### Task 1: Make custom-wordbook feedback metadata private and always valid

**Files:**
- Modify: `lib/models/feedback_completion.dart:234-297,358-370,440-452`
- Modify: `lib/screens/custom_pack_quiz_screen.dart:137-143`
- Modify: `lib/screens/custom_pack_matching_screen.dart:149-155`
- Modify: `lib/screens/custom_pack_typing_screen.dart:124-130`
- Modify: `lib/screens/custom_pack_play_screen.dart:110-117`
- Modify: `test/feedback_completion_test.dart:81-135`
- Modify: `test/dedicated_feedback_completion_test.dart:189-218`

**Interfaces:**
- Consumes: `FeedbackCompletion.customPackQuiz`, `.customPackMatching`, `.customPackTyping`, and `.customPackPlay` currently receive `packId`, user-derived `contentLabel`, and aggregates.
- Produces: the same four factories take `packId` and their aggregate fields, set `contentLabel` to exact stable value `custom_wordbook`, and retain `contentId` format `custom_pack:<packId>:<mode>`.

- [ ] **Step 1: Write failing factory regressions**

Add tests that pass a 121+ character name containing an email-like value to each custom-pack factory's prior label input (or construct the requested desired API without a label). Assert the produced context has exactly `contentLabel: 'custom_wordbook'`, contains the opaque pack ID only in `contentId`, validates successfully, and the serialized wire map does not contain the supplied user text.

- [ ] **Step 2: Run the focused tests to verify RED**

Run: `flutter test --no-pub test/feedback_completion_test.dart test/dedicated_feedback_completion_test.dart`

Expected: FAIL because production factories still retain the user-provided label or still require it in their API.

- [ ] **Step 3: Implement the minimal safe factory API**

Remove `contentLabel` from all four public custom-pack factory signatures and from `_customPackContext`. Set the exact fixed label in `_customPackContext`:

```dart
contentLabel: 'custom_wordbook',
```

Update all four screen call sites to stop reading `CustomPack.displayName()` for feedback. Do not modify screen titles or normal custom-pack display behavior.

- [ ] **Step 4: Run focused tests to verify GREEN**

Run: `flutter test --no-pub test/feedback_completion_test.dart test/dedicated_feedback_completion_test.dart`

Expected: PASS; the context remains valid for a long user pack name and no user text appears in its feedback wire data.

- [ ] **Step 5: Commit the scoped change**

```bash
git add lib/models/feedback_completion.dart lib/screens/custom_pack_quiz_screen.dart lib/screens/custom_pack_matching_screen.dart lib/screens/custom_pack_typing_screen.dart lib/screens/custom_pack_play_screen.dart test/feedback_completion_test.dart test/dedicated_feedback_completion_test.dart
git commit -m "fix(feedback): redact custom wordbook labels"
```

### Task 2: Make Daily Hangul completion truthful guided-study feedback

**Files:**
- Modify: `lib/widgets/stroke_canvas.dart:10-93`
- Modify: `lib/screens/daily_char_sheet.dart:35-229`
- Modify: `lib/models/feedback_completion.dart:89-99`
- Modify: `lib/l10n/app_en.arb:747-753`
- Modify: `lib/l10n/app_de.arb:748-754`
- Modify: `test/circular_feedback_completion_test.dart:8-29`
- Modify: `test/circular_feedback_widget_test.dart:42-91`

**Interfaces:**
- Consumes: `StrokeCanvas` begins its existing guide animation on mount and supports tap-to-replay.
- Produces: optional `VoidCallback? onCompleted` that is invoked when an animation run reaches `AnimationStatus.completed`; it must not be required by existing callers.
- Produces: `FeedbackCompletion.dailyHangul` takes `guidedStrokeCount`, serializes `scoreSummary` as exact `guide_strokes:<count>`, and never implies a user-drawn stroke count.

- [ ] **Step 1: Write failing Daily Hangul tests**

Add a model test expecting `guide_strokes:2`, not `strokes:2`. Add a widget test that opens the daily character sheet, verifies its `Done` button has a null `onTap` while the guide is running, pumps through the guide duration, then verifies the button is enabled, completion feedback appears after tapping it, and its score summary is `guide_strokes:<reference count>`.

- [ ] **Step 2: Run the focused tests to verify RED**

Run: `flutter test --no-pub test/circular_feedback_completion_test.dart test/circular_feedback_widget_test.dart`

Expected: FAIL because the current button is enabled immediately and the current summary is `strokes:<count>`.

- [ ] **Step 3: Implement a minimal guided-study state**

Add the nullable `onCompleted` callback to `StrokeCanvas` and invoke it from its controller status listener when a run completes. In `_DailyCharSheetState`, track whether the current glyph's guide has completed; for a glyph without stroke data, treat the guide as already complete. Pass the callback to `StrokeCanvas`, disable the Finish button until the guide is complete, and guard `_finish()` with the same condition. Rename the factory parameter to `guidedStrokeCount` and emit `guide_strokes:<count>`. Replace the inaccurate `1-min trace` / `1 Minute nachzeichnen` subtitle with guide-viewing copy in English and German, and add a short DE/EN hint explaining that the guide must finish before Done unlocks.

- [ ] **Step 4: Generate localization and run focused tests to verify GREEN**

Run:

```bash
flutter gen-l10n
flutter test --no-pub test/circular_feedback_completion_test.dart test/circular_feedback_widget_test.dart
```

Expected: PASS; the UI copy is DE/EN only, Finish cannot create a completion before the guide completes, and feedback reports guide—not learner—strokes.

- [ ] **Step 5: Commit the scoped change**

```bash
git add lib/widgets/stroke_canvas.dart lib/screens/daily_char_sheet.dart lib/models/feedback_completion.dart lib/l10n/app_en.arb lib/l10n/app_de.arb test/circular_feedback_completion_test.dart test/circular_feedback_widget_test.dart
git commit -m "fix(feedback): require guided Hangul completion"
```

### Task 3: Exercise real shared-game terminal routes

**Files:**
- Modify or create: `test/shared_game_feedback_route_test.dart`
- Read: `lib/screens/cloze_game_screen.dart`, `lib/screens/daily_challenge_screen.dart`, `lib/screens/satz_arcade_screen.dart`, `lib/screens/speed_match_screen.dart`, `lib/screens/custom_pack_quiz_screen.dart`, `lib/screens/custom_pack_matching_screen.dart`, `lib/screens/custom_pack_typing_screen.dart`

**Interfaces:**
- Consumes: each terminal screen already allocates `FeedbackCompletionSlot` and passes `current?.context` to `GameOverCard`.
- Produces: seven deterministic widget-level terminal route assertions; each route reaches a real `GameOverCard` carrying non-null feedback context after the game's actual end transition.

- [ ] **Step 1: Write a failing terminal-route test for each shared screen**

For each of Cloze, Daily Challenge, Satz Arcade, Speed Match, custom quiz, custom matching, and custom typing, build the actual screen with its real minimal data/setup, use the existing test-visible terminal controls or deterministic injected seed, drive its final answer/time/round transition, and assert:

```dart
expect(find.byType(GameOverCard), findsOneWidget);
expect(
  tester.widget<GameOverCard>(find.byType(GameOverCard)).feedbackContext,
  isNotNull,
);
```

Use existing data loader and storage test initialization rather than faking a `GameOverCard` host. For custom packs, give the pack a long personal-looking name and additionally assert the context has `contentLabel == 'custom_wordbook'`.

- [ ] **Step 2: Run the new route suite to verify it protects real routes**

Run: `flutter test --no-pub test/shared_game_feedback_route_test.dart`

Expected: initial failures reveal any route/setup where the real terminal transition is not exercised; do not replace failures with direct `GameOverCard` construction.

- [ ] **Step 3: Repair only terminal wiring or test seams required by the failing routes**

Preserve game behavior and score calculations. If a screen needs a deterministic constructor seam solely for its existing data/clock/RNG dependency, make it optional, production-defaulted, and use it to drive the actual terminal transition—not to inject feedback or bypass completion.

- [ ] **Step 4: Re-run the shared route suite**

Run: `flutter test --no-pub test/shared_game_feedback_route_test.dart`

Expected: seven terminal routes each expose a non-null feedback context after their real end transition.

- [ ] **Step 5: Commit the scoped route coverage**

```bash
git add test/shared_game_feedback_route_test.dart lib/screens/cloze_game_screen.dart lib/screens/daily_challenge_screen.dart lib/screens/satz_arcade_screen.dart lib/screens/speed_match_screen.dart lib/screens/custom_pack_quiz_screen.dart lib/screens/custom_pack_matching_screen.dart lib/screens/custom_pack_typing_screen.dart
git commit -m "test(feedback): cover shared game terminal routes"
```

### Task 4: Exercise real dedicated-content terminal routes

**Files:**
- Modify or create: `test/dedicated_feedback_route_test.dart`
- Read: `lib/screens/scenario_player_screen.dart`, `lib/screens/vocab_pack_screen.dart`, `lib/screens/vocab_pack_result_screen.dart`, `lib/screens/listening_screen.dart`, `lib/screens/review_session_screen.dart`, `lib/screens/custom_pack_play_screen.dart`, `lib/screens/legacy_vocab_screen.dart`

**Interfaces:**
- Consumes: final-result routes already use `ContentFeedbackCard` and existing loader/storage seams.
- Produces: actual terminal route assertions for scenario, vocab pack, listening, review, custom-pack play, and legacy due review; each obtains its context from the real screen lifecycle.

- [ ] **Step 1: Write failing real-terminal tests**

Drive each of the six actual completion routes to its final screen with minimal real fixture data. Assert exactly one `ContentFeedbackCard` is rendered and inspect its `feedbackContext` for the expected type and nonblank completion ID. For legacy vocabulary, begin due review with at least one processed card; retain an explicit negative assertion that empty/non-due paths show no card. For scenario, assert feedback occurs only after its final result—not an intermediate quest/role-play step.

- [ ] **Step 2: Run the route suite to verify RED/coverage quality**

Run: `flutter test --no-pub test/dedicated_feedback_route_test.dart`

Expected: tests fail until their real terminal paths are correctly modeled; do not replace them with factory-only tests.

- [ ] **Step 3: Repair only lifecycle/wiring gaps exposed by terminal paths**

Keep sensitive words, answers, raw listening text, and custom-pack names out of feedback context. Preserve the existing listening stale-finish guard and session reset behavior.

- [ ] **Step 4: Run the dedicated terminal route suite**

Run: `flutter test --no-pub test/dedicated_feedback_route_test.dart`

Expected: six real final routes show their feedback card; excluded empty/intermediate routes do not.

- [ ] **Step 5: Commit the scoped route coverage**

```bash
git add test/dedicated_feedback_route_test.dart lib/screens/scenario_player_screen.dart lib/screens/vocab_pack_screen.dart lib/screens/vocab_pack_result_screen.dart lib/screens/listening_screen.dart lib/screens/review_session_screen.dart lib/screens/custom_pack_play_screen.dart lib/screens/legacy_vocab_screen.dart
git commit -m "test(feedback): cover dedicated terminal routes"
```

### Task 5: Verify coverage hardening without external release actions

**Files:**
- Modify: `docs/superpowers/sdd` artifacts only (ignored task reports and review packages)

- [ ] **Step 1: Run generation and focused feedback suites**

Run:

```bash
flutter gen-l10n
flutter test --no-pub test/feedback_completion_test.dart test/dedicated_feedback_completion_test.dart test/circular_feedback_completion_test.dart test/circular_feedback_widget_test.dart test/shared_game_feedback_route_test.dart test/dedicated_feedback_route_test.dart
```

- [ ] **Step 2: Run full Flutter and static verification**

Run:

```bash
flutter test --no-pub
flutter analyze --no-pub
git diff --check
```

- [ ] **Step 3: Verify localization and release boundaries**

Confirm `git diff --name-only <base>..HEAD` changes only `lib/l10n/app_de.arb` and `lib/l10n/app_en.arb` among ARB files. Do not deploy Firebase, create a signed AAB, push, merge, rebase, or fetch.

- [ ] **Step 4: Commit only any verification-only source correction**

If no source correction was needed, do not create an empty commit. Record the exact commands and results in the task report.

## Self-Review

- Task 1 prevents user-authored labels from entering every custom-wordbook feedback route and keeps feedback valid.
- Task 2 makes the daily guided visual completion truthful, testable, and localized only for DE/EN.
- Tasks 3 and 4 turn all 13 previously indirect terminal routes into actual end-flow regressions while retaining intentional exclusions.
- Task 5 checks the complete branch without claiming deployment or signed-package validation.
