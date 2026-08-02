# Tiger Pulse and Literal Completion Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn every actual Hangul Sori completion/result experience into an optional, fun Tiger Pulse that yields structured, actionable tester feedback without blocking learning or leaking private learning data.

**Architecture:** Keep `ContentFeedbackContext` immutable and allocate one context through `FeedbackCompletionSlot` at a real terminal event. Evolve the current additive feedback payload rather than migrate or discard the secure outbox: learning content uses `contentSignal + contentFocus`, while Book Result, Quest, and Milestone use a separate `experienceSignal + experienceFocus` pair. The Flutter UI remains one reusable card/sheet; the callable function remains the sole write boundary and validates every context-specific field combination.

**Tech Stack:** Flutter/Dart, flutter_test, ARB localization generation, Firebase Callable Functions (Node.js), Firestore emulator rules tests, existing Sori widgets, flutter_secure_storage outbox.

## Global Constraints

- Work only in `C:\Users\vjinn\AppData\Local\Temp\hangulsori-content-feedback-design-20260731`; do not edit, merge, rebase, push, deploy, build an AAB, or otherwise mutate `main`.
- User-visible strings are German and English only. Add keys to both `lib/l10n/app_de.arb` and `lib/l10n/app_en.arb`; never hard-code UI strings in Dart.
- Tiger Pulse is always optional. Never gate Continue, Next, retry, premium entitlement, CEFR progress, lessons, XP, or rewards on feedback.
- The Android internal-tester feature gate remains the only enabled rollout. Do not enable iOS in this work.
- Do not transmit OCR text, image paths/leases, extracted words or sentences, answers, user-authored pack names, user activity history, display names, device identifiers, or screenshots.
- Preserve current secure outbox schema version `1`, callable schema version `2`, completion-id idempotency, account-deletion closing semantics, rate limiting, and direct-client Firestore denial.
- A Passport stamp is granted only when the server accepts a learning-content feedback eligible for one of the five existing missions. Book, Quest, and Milestone feedback never earns a stamp.
- Keep all changes uncommitted in this worktree until the user explicitly requests a commit; do not stage unrelated existing changes.

---

## File Structure

| File | Responsibility |
| --- | --- |
| `lib/models/content_feedback.dart` | Additive client payload enums, validation, and wire serialization. |
| `lib/services/content_feedback_outbox.dart` | Backward-compatible parsing of optional new wire keys. |
| `lib/models/feedback_completion.dart` | Safe immutable factories for book analysis, quest reward, and milestone completion contexts. |
| `lib/widgets/sori/content_feedback_sheet.dart` | Two-tap learning/experience Pulse and structured bug flow. |
| `lib/widgets/sori/content_feedback_card.dart` | Compact reusable entry card, meta feedback presentation, and durable retry state. |
| `lib/main.dart` | Inject outbox resume callback into the feedback scope and trigger safe retry after app resume. |
| `lib/screens/book_result_screen.dart` | Allocate and render a safe Book Result context only after a successful visible result. |
| `lib/screens/quests_screen.dart` | Keep completion dialog visible after the animation and render the Quest Pulse before Continue. |
| `lib/widgets/sori/milestone_celebration.dart` | Render the Milestone Pulse before Continue. |
| `lib/screens/home_screen.dart` | Mark only the milestone actually displayed; leave lower-priority newly reached milestones available for later display. |
| `functions/gye/tester_feedback_runtime.js` | Add allowed optional fields, feedback-only content types, and server-side combination validation. |
| `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb` | All new German/English copy. |
| Flutter and Node test files listed in tasks | Prove payload, UI, terminal-route, retry, privacy, and callable behavior. |

---

### Task 1: Define the additive Tiger Pulse payload contract

**Files:**
- Modify: `lib/models/content_feedback.dart`
- Modify: `lib/services/content_feedback_outbox.dart`
- Modify: `test/content_feedback_test.dart`
- Modify: `test/content_feedback_outbox_test.dart`

**Interfaces:**
- Produces `FeedbackBugFrequency { everyTime, sometimes, once }` with wire names `every_time`, `sometimes`, `once`.
- Produces `FeedbackBugImpact { canContinue, slowsLearning, blocksLearning }` with wire names `can_continue`, `slows_learning`, `blocks_learning`.
- Produces `FeedbackExperienceSignal { positive, mixed, negative, unsure }` and `FeedbackExperienceFocus { koreanText, wordMeanings, grammar, translation, resultMissing, goal, difficulty, reward, instructions, length, timing, visuals, message, frequency, other }` with the snake-case wire names in the design spec.
- Extends `ContentFeedbackDraft` with nullable `expectedOutcome`, `actualOutcome`, `bugFrequency`, `bugImpact`, `experienceSignal`, and `experienceFocus`; retains `message`, `issueArea`, `contentSignal`, and `contentFocus`.
- Extends `FeedbackContentFocus` with `audio` and wire name `audio`.

- [ ] **Step 1: Write failing model and outbox regression tests**

Add to `test/content_feedback_test.dart`:

```dart
test('accepts a complete structured bug report', () {
  final draft = ContentFeedbackDraft(
    category: FeedbackCategory.bug,
    issueArea: FeedbackIssueArea.audio,
    expectedOutcome: 'The next line should play.',
    actualOutcome: 'Playback stopped after one line.',
    bugFrequency: FeedbackBugFrequency.everyTime,
    bugImpact: FeedbackBugImpact.slowsLearning,
  );

  expect(draft.validate().isValid, isTrue);
  expect(draft.toWire()['bugFrequency'], 'every_time');
});

test('rejects a partial structured bug report', () {
  final draft = ContentFeedbackDraft(
    category: FeedbackCategory.bug,
    expectedOutcome: 'The next line should play.',
  );

  expect(draft.validate().isValid, isFalse);
});

test('keeps a legacy message-only bug draft valid', () {
  const draft = ContentFeedbackDraft(
    category: FeedbackCategory.bug,
    message: 'The audio stopped.',
  );

  expect(draft.validate().isValid, isTrue);
});
```

Add a Book Result content draft test with `experienceSignal: FeedbackExperienceSignal.mixed` and `experienceFocus: FeedbackExperienceFocus.translation`, asserting it serializes both optional wire keys. Add a learning draft with `contentFocus: FeedbackContentFocus.audio`. In `test/content_feedback_outbox_test.dart`, round-trip one serialized submission containing every new optional field and one legacy serialized submission lacking every new key.

- [ ] **Step 2: Run the focused tests and verify RED**

Run:

```powershell
flutter test --no-pub test/content_feedback_test.dart test/content_feedback_outbox_test.dart
```

Expected: compilation failures for the new enum names and `ContentFeedbackDraft` parameters.

- [ ] **Step 3: Implement the smallest backward-compatible contract**

In `ContentFeedbackDraft.validate()` apply these exact rules:

```dart
final hasStructuredBugField =
    expectedOutcome.isNotEmpty ||
    actualOutcome.isNotEmpty ||
    bugFrequency != null ||
    bugImpact != null;

if (category == FeedbackCategory.bug && hasStructuredBugField) {
  if (issueArea == null ||
      _isBlank(expectedOutcome) ||
      _isBlank(actualOutcome) ||
      bugFrequency == null ||
      bugImpact == null ||
      expectedOutcome.length > 500 ||
      actualOutcome.length > 500) {
    errors.add('structuredBug');
  }
}
```

Keep a bug valid when it has no structured-bug fields and a nonblank legacy `message`. Reject learning fields on a bug; reject bug/experience fields on `other`; reject a content draft that mixes learning and experience fields. A content draft must have either a nonblank message, at least one learning field, or both experience fields. Restrict `experienceSignal` and `experienceFocus` to appearing together. Add each non-null property to `toWire()` under the exact keys `expectedOutcome`, `actualOutcome`, `bugFrequency`, `bugImpact`, `experienceSignal`, and `experienceFocus`.

In `_submissionFromWire`, add those keys to the accepted exact-key set and deserialize absent keys to the draft defaults. Do not change `contentFeedbackSchemaVersion`, `SecureFeedbackOutboxStore.storageKey`, or reject old persisted entries merely because the new keys are absent.

- [ ] **Step 4: Run formatter and focused tests to verify GREEN**

Run:

```powershell
dart format lib/models/content_feedback.dart lib/services/content_feedback_outbox.dart test/content_feedback_test.dart test/content_feedback_outbox_test.dart
flutter test --no-pub test/content_feedback_test.dart test/content_feedback_outbox_test.dart
```

Expected: all payload validation and both old/new outbox round trips pass.

- [ ] **Step 5: Preserve the isolated worktree state**

Run `git diff --check -- lib/models/content_feedback.dart lib/services/content_feedback_outbox.dart test/content_feedback_test.dart test/content_feedback_outbox_test.dart`. Do not stage or commit files because the worktree intentionally contains unrelated uncommitted release-safety changes.

### Task 2: Enforce the same contract at the Callable boundary

**Files:**
- Modify: `functions/gye/tester_feedback_runtime.js`
- Modify: `functions/gye/tester_feedback_runtime.test.js`

**Interfaces:**
- Produces `FEEDBACK_ONLY_CONTENT_TYPES = new Set(['book_analysis', 'quest_reward', 'milestone'])`.
- Expands `ALLOWED_CONTENT_TYPES` with the feedback-only set but leaves `MISSION_CATALOG` unchanged.
- Exports `FEEDBACK_ONLY_CONTENT_TYPES` with existing runtime exports for Node tests.
- Allows only the new optional payload keys from Task 1 and persists them unchanged after validation.

- [ ] **Step 1: Write failing callable boundary tests**

Add a `payload()` test table that covers:

```js
test("accepts Book Result experience feedback without a passport mission", async () => {
  const { handlers, firestore } = createHarness();
  const result = await handlers.submitTesterFeedback(callableRequest(payload({
    completionId: "book-1",
    feedbackId: "book-feedback-1",
    contentType: "book_analysis",
    contentId: "book_analysis",
    contentLabel: "book_analysis",
    scoreSummary: "words:4; grammar:1; source:offline",
    category: "content",
    message: "",
    betaMissionId: undefined,
    experienceSignal: "mixed",
    experienceFocus: "translation",
  })));

  assert.equal(result.stampAccepted, false);
  assert.equal(firestore.value("users/anonymous-user/tester_feedback/book-1").experienceFocus, "translation");
});
```

Also assert rejection for: a Book Result carrying `contentSignal`; a scenario carrying `experienceSignal`; a partial experience pair; a structured bug missing one of issue area/expected/actual/frequency/impact; a new field on `other`; and a feedback-only type paired with a `betaMissionId`.

- [ ] **Step 2: Run the Functions test file and verify RED**

Run:

```powershell
npm.cmd --prefix functions/gye test -- --test-name-pattern="Book Result|structured bug|experience"
```

Expected: failures because the current allow-list rejects the new keys and content types.

- [ ] **Step 3: Implement strict context-aware validation**

Add the six new field names to `ALLOWED_FIELDS`. Add string length checks of 500 for `expectedOutcome` and `actualOutcome`, enum checks for frequency, impact, signal, and focus, and return only validated values from `validatePayload`.

Use exact helper sets:

```js
const LEARNING_CONTENT_TYPES = new Set(
  MISSION_CATALOG.flatMap((mission) => mission.allowedContentTypes),
);
const FEEDBACK_ONLY_CONTENT_TYPES = new Set([
  "book_analysis", "quest_reward", "milestone",
]);
const ALLOWED_CONTENT_TYPES = new Set([
  ...LEARNING_CONTENT_TYPES,
  ...FEEDBACK_ONLY_CONTENT_TYPES,
]);
```

For `category === 'content'`, require exactly one structured family when structured data is used: learning content may use `contentSignal`/`contentFocus` and must not use experience fields; feedback-only content may use `experienceSignal`/`experienceFocus` and must not use learning fields. Permit a message-only legacy content draft for either family. Enforce allowed experience focus sets per content type:

```js
const EXPERIENCE_FOCUSES_BY_TYPE = new Map([
  ["book_analysis", new Set(["korean_text", "word_meanings", "grammar", "translation", "result_missing", "other"])],
  ["quest_reward", new Set(["goal", "difficulty", "reward", "instructions", "length", "other"])],
  ["milestone", new Set(["timing", "visuals", "reward", "message", "frequency", "other"])],
]);
```

For new structured bugs, require all five fields; permit a message-only legacy bug only when every new bug field is absent. Keep `issueArea` optional for a legacy bug. Reject `betaMissionId` unless `contentType` belongs to that mission's existing allowed learning types. Persist only validated optional fields and leave the transaction/passport code unchanged.

- [ ] **Step 4: Run the full Functions unit suite**

Run:

```powershell
npm.cmd --prefix functions/gye test
```

Expected: every existing runtime/trigger test plus the new boundary tests passes.

- [ ] **Step 5: Check only the intended runtime diff**

Run `git diff --check -- functions/gye/tester_feedback_runtime.js functions/gye/tester_feedback_runtime.test.js`. Do not deploy Functions or change Firestore rules in this task.

### Task 3: Build the reusable Tiger Pulse UI and DE/EN copy

**Files:**
- Modify: `lib/widgets/sori/content_feedback_sheet.dart`
- Modify: `lib/widgets/sori/content_feedback_card.dart`
- Modify: `lib/l10n/app_de.arb`
- Modify: `lib/l10n/app_en.arb`
- Generate: `lib/l10n/generated/*`
- Modify: `test/content_feedback_widget_test.dart`

**Interfaces:**
- `ContentFeedbackSheet` derives a prompt kind from `feedbackContext.contentType`: learning, book analysis, quest reward, or milestone.
- `ContentFeedbackCard` continues to accept the same `feedbackContext`, `featureGate`, and `submitFeedback` parameters; Passport UI appears only when `missionFor(feedbackContext) != null`.
- The visible first state for learning, book, quest, and milestone is the Pulse signal picker, with small explicit Bug/Other actions; `FeedbackCategory.content` is selected internally for the normal Pulse path.

- [ ] **Step 1: Write failing widget tests for the exact interaction**

Replace the current assertion that the sheet opens on three category buttons with these cases:

```dart
testWidgets('learning Tiger Pulse needs a signal and focus before send', (tester) async {
  ContentFeedbackDraft? submitted;
  await tester.pumpWidget(_host(submitFeedback: (_, draft) async {
    submitted = draft;
    return const ContentFeedbackSubmitResult(
      status: ContentFeedbackSubmitStatus.accepted,
    );
  }));

  await _openSheet(tester);
  await _tapVisible(tester, const Key('pulse-signal-right'));
  expect(find.byKey(const Key('pulse-focus-fields')), findsOneWidget);
  expect(tester.widget<SoriButton>(find.byKey(const Key('feedback-submit'))).onTap, isNull);
  await _tapVisible(tester, const Key('pulse-focus-examples'));
  expect(tester.widget<SoriButton>(find.byKey(const Key('feedback-submit'))).onTap, isNotNull);
  await _tapVisible(tester, const Key('feedback-submit'));

  expect(submitted?.contentSignal, FeedbackContentSignal.right);
  expect(submitted?.contentFocus, FeedbackContentFocus.examples);
});
```

Add tests proving: Book uses `pulse-experience-*` keys and yields experience fields; a meta context does not render `SoriProgressBar`; Bug exposes expected/actual/frequency/impact and rejects an incomplete form; Other still requires text; Passport celebration happens only for `stampAccepted`; and the compact card never auto-opens.

- [ ] **Step 2: Run the widget suite and verify RED**

Run:

```powershell
flutter test --no-pub test/content_feedback_widget_test.dart
```

Expected: current category-first UI fails the Pulse selector assertions.

- [ ] **Step 3: Implement the adaptive sheet without duplicated forms**

Create private helpers in `content_feedback_sheet.dart` for `_isLearningContext`, `_isBookAnalysisContext`, `_isQuestRewardContext`, `_isMilestoneContext`, `_pulseSignalFields`, `_pulseFocusFields`, and `_bugFields`. Use the context type to map the same `FeedbackExperienceSignal` enum to the correct localised labels rather than adding context-specific wire enums.

Use the following stable keys so tests and accessibility semantics remain deterministic:

```text
pulse-signal-tooEasy, pulse-signal-right, pulse-signal-tooHard, pulse-signal-unclear
pulse-experience-positive, pulse-experience-mixed, pulse-experience-negative, pulse-experience-unsure
pulse-focus-explanation, pulse-focus-examples, pulse-focus-questions, pulse-focus-pace, pulse-focus-audio, pulse-focus-translation
bug-expected-outcome, bug-actual-outcome, bug-frequency-everyTime, bug-frequency-sometimes, bug-frequency-once
bug-impact-canContinue, bug-impact-slowsLearning, bug-impact-blocksLearning
```

Keep text areas at 3--5 lines. Make the normal Pulse Send button disabled until both selectors are chosen, make structured bug fields required by the UI, and retain a visible Cancel/Back action. Do not auto-submit after the second tap; users must see a clear Send action. Provide the privacy reminder in every route.

In `content_feedback_card.dart`, rename visible tester-facing copy to Tiger Pulse/Tiger-Check via ARB, hide the Passport progress bar for `missionFor(context) == null`, and show a neutral accepted message for feedback-only contexts. Keep the mascot state and 18-particle burst only for server-authoritative `stampAccepted`.

Add both ARB keys together for every new label, hint, validation message, and success/pending state. Then run `flutter gen-l10n`; do not edit generated Dart by hand.

- [ ] **Step 4: Format and prove the complete widget behavior**

Run:

```powershell
dart format lib/widgets/sori/content_feedback_sheet.dart lib/widgets/sori/content_feedback_card.dart test/content_feedback_widget_test.dart
flutter gen-l10n
flutter test --no-pub test/content_feedback_widget_test.dart
```

Expected: the sheet has one accessible, optional two-tap path for each context type and all previous card race/idempotency tests remain green.

- [ ] **Step 5: Verify localization parity**

Run the following PowerShell check after generation:

```powershell
$de = Get-Content 'lib/l10n/app_de.arb' -Raw -Encoding utf8 | ConvertFrom-Json
$en = Get-Content 'lib/l10n/app_en.arb' -Raw -Encoding utf8 | ConvertFrom-Json
$deKeys = @($de.psobject.Properties.Name | Where-Object { -not $_.StartsWith('@') } | Sort-Object)
$enKeys = @($en.psobject.Properties.Name | Where-Object { -not $_.StartsWith('@') } | Sort-Object)
Compare-Object $deKeys $enKeys | Format-Table -AutoSize
```

Expected: no output from `Compare-Object`.

### Task 4: Add durable retry on app resume and the pending-card action

**Files:**
- Modify: `lib/services/content_feedback_service.dart`
- Modify: `lib/services/content_feedback_lifecycle.dart` only if its public forwarding API lacks `resumePending`
- Modify: `lib/widgets/sori/content_feedback_card.dart`
- Modify: `lib/main.dart`
- Modify: `test/content_feedback_widget_test.dart`
- Modify: `test/services/content_feedback_service_test.dart`
- Modify or create: `test/content_feedback_lifecycle_resume_test.dart`

**Interfaces:**
- `ContentFeedbackResumeResult` gains `Set<String> deliveredFeedbackIds`, defaulting to an empty set.
- `ContentFeedbackControllerScope` gains a required `Future<ContentFeedbackResumeResult> Function() resumePending` callback.
- The app contains a small stateful lifecycle observer that invokes the existing feedback lifecycle `resumePending()` on `AppLifecycleState.resumed`; it must not create a second service or bypass the service's `_runExclusive` gate.

- [ ] **Step 1: Write failing retry tests**

Add a service test that queues two entries, resumes once, and asserts `deliveredFeedbackIds` contains exactly the feedback ID actually removed from the outbox. Add a widget test where initial submission returns `pending`, the scope resume callback returns that pending feedback ID, the user taps `content-feedback-retry-pending`, and the card changes to delivered without calling `submitFeedback` a second time. Add a lifecycle test that emits `resumed` twice concurrently and asserts the injected resume function is serialized by the existing service gate.

- [ ] **Step 2: Run focused retry tests and verify RED**

Run:

```powershell
flutter test --no-pub test/services/content_feedback_service_test.dart test/content_feedback_widget_test.dart test/content_feedback_lifecycle_resume_test.dart
```

Expected: compilation failures for `deliveredFeedbackIds`, the scope callback, and the lifecycle observer.

- [ ] **Step 3: Implement retry without creating another submission**

In `_resumePending`, collect `attempted.submission.feedbackId` only after `_discardById` succeeds and return it in `deliveredFeedbackIds`. Preserve all existing count fields and failure semantics.

Pass `_contentFeedbackLifecycle.resumePending` through `ContentFeedbackControllerScope` in `main.dart`. Wrap the app child in a small `StatefulWidget` implementing `WidgetsBindingObserver`; call the injected resumer only in `didChangeAppLifecycleState(AppLifecycleState.resumed)` and swallow errors exactly as the current startup coordinator does. Register/remove the observer in `initState`/`dispose`.

In the card, display `content-feedback-retry-pending` only when the last state is `pending`. Disable it while its retry future is running. If its original feedback ID occurs in `deliveredFeedbackIds`, render the neutral delivered state; otherwise retain pending and show the queued copy. Do not emit a Passport burst from this path because the original server acknowledgement was not returned to this widget.

- [ ] **Step 4: Run the retry-focused suite**

Run the command from Step 2 again. Expected: no duplicate `submitFeedback` call, only durable queued work is retried, and the observer is disposed cleanly.

- [ ] **Step 5: Check account-deletion invariants**

Run:

```powershell
flutter test --no-pub test/services/content_feedback_lifecycle_test.dart test/services/completed_deletion_startup_recovery_test.dart test/account_hardening_test.dart
```

Expected: feedback resumption still remains blocked/closed through every deletion state.

### Task 5: Add safe Book Result completion feedback

**Files:**
- Modify: `lib/models/feedback_completion.dart`
- Modify: `lib/screens/book_result_screen.dart`
- Create: `test/book_result_feedback_route_test.dart`
- Modify: `test/feedback_completion_test.dart`

**Interfaces:**
- Produces `FeedbackCompletion.bookAnalysis({ required int words, required int grammar, required int sentences, required BookAnalysisFeedbackSource source, FeedbackCompletionIdFactory? createId })`.
- Produces `BookAnalysisFeedbackSource { online, offline, rateLimited }` and uses only `contentType/contentId/contentLabel == 'book_analysis'` plus bounded aggregate `scoreSummary`.

- [ ] **Step 1: Write failing privacy and real-result route tests**

Add a factory test with a deliberately sensitive OCR string and image-like path in test variables. Assert neither value appears in `completion.context.toWire().values`; assert the exact safe summary such as `words:4; grammar:1; sentences:2; source:offline` validates.

Create `test/book_result_feedback_route_test.dart`. Build `BookResultScreen` with `args` containing sensitive-looking `text` and `imageLease`, inject an analyzer returning a successful offline-stub `BookAnalysisResult`, pump to the real result UI, and assert exactly one `ContentFeedbackCard`. Inspect its `feedbackContext`: it must use `book_analysis`, have a nonblank completion ID, and contain no source text or lease. Retry analysis through the existing retry action and assert the second successful generation gets a different completion ID.

- [ ] **Step 2: Run Book tests and verify RED**

Run:

```powershell
flutter test --no-pub test/feedback_completion_test.dart test/book_result_feedback_route_test.dart
```

Expected: compilation failures for the factory and no card in the current Book Result screen.

- [ ] **Step 3: Implement the one-visible-result lifecycle**

Add a private `FeedbackCompletionSlot _feedbackCompletion` to `_BookResultScreenState`. At the start of `_analyze`, reset the slot before incrementing the generation. Once the same generation successfully sets `_result`, derive source from its warnings (`offline_stub`, then `server_rate_limited`, otherwise `online`) and complete the slot with aggregate list lengths only. Render `ContentFeedbackCard` after the successful result summary and before the save CTA, using the inherited scope values. Do not render it in loading or error states.

- [ ] **Step 4: Format and run Book tests**

Run the command from Step 2 after `dart format lib/models/feedback_completion.dart lib/screens/book_result_screen.dart test/book_result_feedback_route_test.dart test/feedback_completion_test.dart`. Expected: every result-generation, retry, and privacy assertion passes.

- [ ] **Step 5: Inspect the exact feedback wire manually**

Run `flutter test --no-pub test/book_result_feedback_route_test.dart -r expanded` and retain the inspected test assertion; do not log or print sensitive test inputs in production code.

### Task 6: Add Quest and Milestone Pulse without auto-close or hidden events

**Files:**
- Modify: `lib/models/feedback_completion.dart`
- Modify: `lib/screens/quests_screen.dart`
- Modify: `lib/widgets/sori/milestone_celebration.dart`
- Modify: `lib/screens/home_screen.dart`
- Create: `test/quest_completion_feedback_route_test.dart`
- Create: `test/milestone_feedback_widget_test.dart`
- Modify: `test/feedback_completion_test.dart`

**Interfaces:**
- Produces `FeedbackCompletion.questReward({ required String questId, required String questType, required int target, FeedbackCompletionIdFactory? createId })` with fixed `contentType: 'quest_reward'` and no user-specific activity history.
- Produces `FeedbackCompletion.milestone({ required String milestoneId, required String milestoneType, required int value, FeedbackCompletionIdFactory? createId })` with fixed `contentType: 'milestone'` and one displayed milestone only.
- `_QuestCompletionCelebration` receives a required `ContentFeedbackContext feedbackContext` and only pops after explicit Continue.
- `showMilestoneCelebration` receives a required `ContentFeedbackContext feedbackContext`.

- [ ] **Step 1: Write failing Quest and Milestone tests**

For Quest, introduce only the smallest constructor seams needed to inject a deterministic completed `QuestProgress` list and persistence function. Drive `_load()` with a newly completed quest, pump 2.7 seconds, assert the dialog remains visible, contains one `ContentFeedbackCard` with `contentType == 'quest_reward'`, and a visible Continue button closes it. Assert the context wire excludes any user name or history.

For Milestone, call `showMilestoneCelebration` with a deterministic milestone and its factory context. Assert the sheet contains one card with `contentType == 'milestone'` and Continue. Add a Home state test with two newly reached milestones: after the first presentation only the displayed ID is added to `Storage.celebratedMilestones`; after a later eligible invocation the other ID can be presented. Assert neither context includes full streak history or vocabulary IDs.

- [ ] **Step 2: Run the new route/widget tests and verify RED**

Run:

```powershell
flutter test --no-pub test/quest_completion_feedback_route_test.dart test/milestone_feedback_widget_test.dart test/feedback_completion_test.dart
```

Expected: the current quest dialog auto-closes, milestone API lacks a context, and current Home marks all newly reached milestones too early.

- [ ] **Step 3: Implement safe factories and visible completion stages**

Implement the factories with exact score summaries `type:<questType>; target:<target>` and `type:<milestoneType>; value:<value>`; reject unsafe input through existing length validation before it reaches the server.

For Quest, create the completion immediately before calling `_showQuestCompletionCelebration`. Keep phase 0 and phase 1 durations unchanged. In phase 2, stop calling `Navigator.pop`; render the compact feedback card and localized Continue button instead. The card is optional and can be ignored before Continue.

For Milestone, construct `FeedbackCompletion.milestone` just before `showMilestoneCelebration`. Change Home logic to select `top` before marking persistence and call `Storage.markMilestonesCelebrated([top.id])` only for that top ID. Pass its immutable context to the sheet. Do not mark unshown milestones as celebrated.

- [ ] **Step 4: Format and run the complete Quest/Milestone suite**

Run the command from Step 2 after formatting all six touched Dart/test files. Expected: the existing celebration animations remain, every displayed result has a usable optional Pulse, and a lower-priority milestone is not silently lost.

- [ ] **Step 5: Check behavioral exclusions**

Run the existing Home/Quest suites found with:

```powershell
rg -l "Quest|Milestone|celebratedMilestones" test -g '*.dart'
```

Then run every returned test file with `flutter test --no-pub`. Expected: lists, historical quest tiles, and ordinary home visits do not create new feedback completions.

### Task 7: Prove full coverage, security, and release boundaries

**Files:**
- Modify: `docs/SESSION_CHANGES_2026-07-31.md`
- Modify: `docs/superpowers/specs/2026-08-02-tiger-pulse-literal-completion-design.md` only if verification finds a decision mismatch
- Modify or create: `test/literal_completion_feedback_coverage_test.dart`

**Interfaces:**
- Produces one regression inventory that names the 20 existing learning completion variants plus Book Result, Quest completion, and Milestone as required feedback surfaces.
- Produces a Korean operation note that records automated evidence and explicitly says device smoke, deployment, AAB generation, merge, and push were not performed.

- [ ] **Step 1: Write the coverage regression before final verification**

Create `test/literal_completion_feedback_coverage_test.dart` as a static safety-net over the public factories and route hosts. It must enumerate the required `contentType` values:

```dart
const requiredFeedbackTypes = <String>{
  'scenario', 'vocab_pack', 'review', 'custom_wordbook',
  'custom_wordbook_game', 'legacy_vocab', 'listening', 'game',
  'grammar_session', 'hangul_cards', 'hangul_writing', 'daily_hangul',
  'book_analysis', 'quest_reward', 'milestone',
};
```

Assert the three new factory outputs validate, are feedback-only rather than mission-matched, and that `missionFor` remains non-null for every existing mission group. Keep the real terminal widget tests from Tasks 5--6 as the primary proof; this inventory must not replace them.

- [ ] **Step 2: Run generation and all focused Flutter suites**

Run:

```powershell
flutter gen-l10n
flutter test --no-pub test/content_feedback_test.dart test/content_feedback_outbox_test.dart test/content_feedback_widget_test.dart test/feedback_completion_test.dart test/book_result_feedback_route_test.dart test/quest_completion_feedback_route_test.dart test/milestone_feedback_widget_test.dart test/literal_completion_feedback_coverage_test.dart test/services/content_feedback_service_test.dart test/content_feedback_lifecycle_resume_test.dart test/services/content_feedback_lifecycle_test.dart test/services/completed_deletion_startup_recovery_test.dart test/account_hardening_test.dart
```

Expected: all named tests pass. If a pre-existing unrelated test fails, record its full command and failure separately; do not weaken this feature's assertions.

- [ ] **Step 3: Run Functions and rules regression suites**

Run:

```powershell
npm.cmd --prefix functions/gye test
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = 'C:\Program Files\Android\Android Studio\jbr\bin;' + $env:Path
npm.cmd --prefix functions/gye run test:rules
```

Expected: Functions contract tests pass and Firestore rules still deny client feedback read/create/update/delete. Expected `PERMISSION_DENIED` logs in negative emulator tests are not failures.

- [ ] **Step 4: Run full static and Flutter verification**

Run:

```powershell
flutter analyze --no-pub
flutter test --no-pub
git diff --check
```

Expected: zero analyzer issues, passing Flutter suite, and no whitespace errors. Do not claim Android/iOS runtime smoke until a device log and visible UI evidence exist.

- [ ] **Step 5: Record evidence without release actions**

Append a dated Korean entry to `docs/SESSION_CHANGES_2026-07-31.md` with exact passing commands/results, the 23-surface scope wording (`20` learning variations plus Book/Quest/Milestone), the Android-tester-only gate, and remaining manual checks. Do not update build numbers, signing files, store metadata, or release artifacts.

## Self-Review

- **Spec coverage:** Task 1 preserves additive old/new outbox compatibility; Task 2 mirrors it at the trusted server boundary; Task 3 makes the feedback fun and context-sensitive; Task 4 resolves pending retry without duplicate submissions; Tasks 5 and 6 cover every literal missing completion experience; Task 7 proves all functional/security/release constraints.
- **Privacy coverage:** Book, Quest, and Milestone factories use only fixed IDs plus bounded aggregates. No task sends OCR text, photos, answers, names, activity history, or device IDs.
- **Reward coverage:** Tasks 2 and 3 preserve mission matching for learning types only, and Task 7 asserts feedback-only types do not earn Passport stamps.
- **Placeholder scan:** This plan has no deferred or generic steps; every task identifies files, public interfaces, a failing test, a verification command, and exact behavior.
- **Type consistency:** Task 1 defines the payload types consumed by Task 2 and Task 3. Task 4 only forwards the existing service resume operation and reports a set of feedback IDs. Tasks 5 and 6 consume `FeedbackCompletion` factories and `ContentFeedbackCard` without new server APIs.

## Execution Handoff

Plan saved to `docs/superpowers/plans/2026-08-02-tiger-pulse-literal-completion.md`.

Use **Subagent-Driven execution**: implement one task at a time in this isolated worktree, review the task diff and test result before starting the next task, and never touch `main`.
