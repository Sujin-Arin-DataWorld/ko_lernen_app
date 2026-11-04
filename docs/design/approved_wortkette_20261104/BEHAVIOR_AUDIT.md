# Wortkette behavior preservation audit

Audit date: 2026-11-04. Source checkout: `C:/dev/hangulsori/ko_lernen_app_worktrees/quiz-matching-figma-20261104`, HEAD `b11c7ef838e6f18be72d7bed5404589c158d2b8f`. The checkout was clean before this audit. This is a source/behavior audit for the approved Wortkette mockups; it is not Figma geometry approval, a native design comparison, device QA, or a release claim. Production code has not been changed. The user requires Figma first, then Flutter.

## Entry points and ownership

- The named route `/kkeunmari` in `lib/main.dart:1031` opens `const KkeunmariScreen()`. Discover, the practice hub, activity catalog, quest resolver, and onboarding demo point to this same route.
- The notebook studio also opens `KkeunmariScreen(source: source)` directly (`lib/screens/vocab_notebook_studio_screen.dart:358`). That source captures the selected pack ID and rows. Preserve both entry paths and the existing constructor.
- Public constructor inputs (`lib/screens/kkeunmari_screen.dart:58`): optional `VocabDeckSource source`, `Future<List<KkeunmariWord>> Function() poolLoader`, and `Future<KkeunmariDictionaryResult> Function(String) dictionaryValidator`. The last two are deterministic test seams, not replacement production data.
- The screen owns timers, turn/round generations, editing controller/focus, input admission, word-chain state, dictionary I/O, SRS evidence, result persistence, feedback, and navigation cleanup. A new visual widget should not own any of these operations.
- `SoriStudyFrame` owns close/Home/system-back behavior, safe areas, and route confirmation. The screen supplies `onLeave: _retireStudy`. Do not add a competing PopScope or create another game route solely for presentation.

## Loading, corpus, and selection

1. `_start` loads `KkeunmariEngine.load()` or the injected loader. Injected words become an unmodifiable screen-local list; they do not replace the global engine pool. Late loads are guarded by lifetime and round generation.
2. Engine loading (`lib/services/kkeunmari_engine.dart:81`) decodes `assets/data/kkeunmari_pool.json`, intersects with `KoreanNounLexicon`, requires at least two Hangul syllables, and verifies first/last metadata. It caches success or failure; explicit retry evicts the cached pool asset.
3. A notebook source intersects the curated pool with exact trimmed selected Korean words and removes duplicates. OCR/saved rows alone are not dictionary validation. Source filtering does not mutate the source, global pool, saved notebook, or pack progress.
4. The screen requires a nonempty pool with a live chain. Empty, disconnected, or unverified selections show a localized empty state; they do not start a countdown or award XP. Source-based empty/error/help text differs from full-corpus text.
5. Loading uses an accessible live-region message. A thrown loader or engine `lastError` shows retryable `AppError`. Retry guards the original generation and preserves the same notebook source.
6. `pickStart(source: _pool)` chooses a word with live unused successors, prioritizing two or more successors, then one. The engine supports an optional cumulative learner-level parameter, but this screen does not pass it. The redesign must not invent CEFR selection behavior.
7. On a normal production corpus load only, the screen best-effort loads vocabulary IDs from `DataLoader.loadVocab`. Missing vocabulary does not prevent play. An injected loader or notebook source does not populate `_vocabKeys`.

## Round and input contracts

| State/action | Current behavior to preserve |
| --- | --- |
| New round | One engine-selected opening word is added to chain and used set. User starts; remaining time is 30 seconds. Clear input, validation state, previous result/reward/feedback. Opening word is spoken after 200 ms, guarded by round/lifetime. |
| User turn | Current word, genuine localized gloss, emphasized last syllable, required first-syllable hint, turn label, countdown, editable input, submit action, and chain length are visible. |
| Input field | Actual `SoriTextField`/`TextField`, single line, centered, max 20 characters, autofocus, persistent screen-owned controller/focus node. Keyboard submission and submit button call the same guarded `_submit(roundGeneration, turnGeneration)`. No custom Korean keyboard and no forced composing-text filter exist. |
| Empty submission | Trim whitespace; do nothing. |
| Local validation | Reject non-Hangul or more than 20 characters first; then wrong starting syllable; then any already-used word; then missing pool membership. Preserve this actionable error priority. Invalid entries stay editable and do not add a chain entry, write SRS, or change score. |
| Validation error | Localized live-region text and medium haptic. Error remains until a later validation/acceptance changes it; typing alone does not clear it. |
| Accepted answer | Stop the current clock before persistence. For eligible real vocabulary only, durably save positive SRS evidence before advancing. Then light haptic + correct sound, append once, mark used, replace current word, clear input/error, and speak the accepted word. |
| Live continuation | Compute remaining bot candidates from the live unused pool, never from stored `next_count` or `is_dead_end`. If at least one exists, switch to companion turn and schedule its move in 1,800 ms. |
| Companion turn | Hide user input/submit and show a thinking presentation. The clock is stopped. Pick one fair unused matching word; append it, speak it, switch back to user, reset countdown to 30, and request focus. |
| Winning dead end | If the accepted user's word has no live bot successor, schedule a winning `deadEnd` finish in 1,000 ms. This branch leaves the turn enum as user until completion; generation guards still prevent a retained old submit from consuming a new turn. Do not reinterpret this pause as an extra user turn. |
| Bot cannot reply | `_tigerMove` can end with `tigerStuck`; it is a win. No additional bot words are invented from online results. |
| Timeout | At zero remaining seconds, finish with `timeUp`, a loss. |

The used-word set includes dictionary-only accepted words. The displayed chain length is the whole chain, including the opening and companion words, not a separate answer/correct-count score. The existing chain strip is horizontally scrollable with the most recent entry emphasized. No give-up button or hint-spending behavior exists. `userStuck` remains an enum/result-label variant but no current action calls `_endGame(_End.userStuck)`.

## Dictionary contracts

- Only a correctly formed, correctly prefixed, unused word absent from the full corpus may call the dictionary. Notebook selections reject outside answers with `kkeunmariNotInSelection` and never fall back online.
- While checking, show the checking message, disable input and submit, and stop countdown decrements without changing the displayed remainder. Duplicate submission joins no new request because `_dictionaryChecking` gates it.
- The screen imposes an 8-second timeout. Exceptions/timeouts become `unavailable`, not a learner error. Round, turn, dictionary-generation, lifetime, and finish checks reject stale replies.
- A valid response creates `KkeunmariWord.dictionary(input)` with empty translations; it may be played once, but is not inserted into the curated bot pool or silently promoted into SRS vocabulary.
- `invalid` shows the localized not-a-dictionary-word message and allows the ordinary countdown to continue. `unavailable` keeps this user turn's clock paused until a valid answer advances, so a service outage cannot cost the learner the round. Local recovery answers remain possible.
- `KkeunmariDictionaryService` uses a single bounded 6-second deadline covering offline lookup, credentials, headers and response body. It first checks the bundled noun index. Fallback POST uses only the fixed protected `validate_kkeunmari_word` endpoint, Firebase ID token and App Check token, with redirects disabled. Non-200, malformed JSON, missing credentials, oversize (>4096 bytes), and timeout are `unavailable`; literal valid=false is `invalid`. Late credentials cannot initiate a request after retirement. Do not move credentials/API logic into a presentation widget.

## Persistence, results, and exits

- Positive `SrsReviewAttempt(id: word, gotIt: true)` is created only for an accepted word in `_vocabKeys`. No negative SRS evidence is recorded for invalid input. Notebook play leaves its pack progress unchanged in this screen.
- `StudyEvidenceRecovery` holds one accepted judgment until durable success. It blocks fresh input, presents loading/error/retry, reconciles unknown native write outcomes, and rejects a retired/reset lifetime. Preserve the same pending attempt across retry; do not replay answer sounds or advance before evidence succeeds.
- `_endGame` is single-entry through `_finishing`. It cancels countdown/pending turn work, then calls `saveGameResult(gameId: 'kkeunmari', xp: (chainLength * 10).clamp(20, 500), score: chainLength, kkeunmariWin: won)`.
- XP includes the 20 minimum even for a one-word timeout. `tigerStuck` and `deadEnd` are wins; timeout is not. Do not change reward arithmetic to match mockup numbers.
- `GameResultRecovery` retains one `GameResultAttempt` across failure/retry. The attempt writes idempotent XP/win evidence and best score before exposing `GameOutcome`. The screen displays actual persisted XP and new-best status, with the returned `LearningAttempt` linked to reward presentation. No speculative reward badge.
- A successful saved result then publishes feedback completion, heavy haptic, `Analytics.gameCompleted`, marks the abandon tracker complete, and sends `questFailed(timeout)` for timeout. Winning celebration is post-frame and lifetime/round guarded.
- The result retains chain history, reason, chain length, XP/new best, optional feature-gated `ContentFeedbackCard`, replay, and Back Home. Result Back Home currently pops one route; it differs intentionally from the frame Home action, which returns to the app's home/journey destination.
- Replay resets the existing screen round; stale old replay/result-Home callbacks cannot act on the new round.
- Normal play confirms exit while `_end == none && _remaining > 0`. Loading/empty/error use ordinary exits; save-recovery frames confirm. Confirmed leave retires evidence and result generations, cancels timers, and prevents late acceptance/reward publication. Merely opening/cancelling a confirmation does not retire the round.
- An unsaved abandonment reports `quest_abandon` with bounded marker `chain_N` on disposal. The tracker is screen-scoped and is marked completed after the first saved result; it is not reset by replay. Preserve unless a separate behavior change is explicitly approved.
- Round state is in memory. This screen does not resume a killed process's unfinished round. Durable confirmed evidence/rewards are separate from round resume.

## Keyboard, sound, companion, motion, and accessibility

- Preserve system input and IME submission. The approved artwork must not replace the editable text with a painted string. Preserve focus after the companion answer; consider actual `viewInsets` separately from the 402×874 artwork reference so the keyboard does not cover the input/submit.
- `TtsService.speak` is called for the opening, accepted answer, companion answer, and a 48dp current-word listen action with localized tooltip/semantics. The source gloss is `VocabDeckSource.meaningFor`; otherwise `KkeunmariWord.meaning` selects English for en, German otherwise. Empty or literal `TODO` glosses are hidden. No romanization toggle exists here.
- The existing header `TtsSpeedAction` changes the shared persistent speech multiplier (presets 0.5, 0.75, 0.8, 1, 1.25, 1.5); the next utterance uses it. Do not hard-code the displayed 1× face as a noninteractive decoration.
- The current screen does not await speech success or subscribe to `TtsService.unavailable` for local feedback. Global speech volume/voice policy remain in TtsService.
- Thinking uses reactive `CompanionBuilder` plus `CharacterClips.thinkingFor(kind)`/`CharacterClipPlayer`. Explicit no-companion uses a neutral icon and neutral thinking label. Preserve selected Taego/Joy/none preference rather than always instantiating the mockup character. The current turn label outside that builder still uses the existing tiger-turn string.
- CharacterClipPlayer owns its video lease: route visibility, ticker mode, application lifecycle, explicit app reduced-motion setting, video availability, and static fallback. Do not start a raw repeating controller in the new layout. Looping thinking media does not automatically play one-shot companion sound effects.
- The existing result explicitly requests magpie/celebrate for wins and tiger/worry for losses. Keep the real result/reward/feedback component outside a play-only presentation migration unless approved result geometry is supplied.
- The countdown uses tabular figures, a progress indicator, localized spoken seconds, and live-region urgency at <=10 seconds. Validation/loading/result messages use live regions. Preserve noncolor meaning and actionable accessibility labels.
- Keep coach ID `kkeunmari` and all three anchors: current word, turn/timer, input. Coach visibility is once per session/persistent tutorial flag and waits for loaded content. Do not silently remove tutorials when replacing the body.

## Lifecycle guarantees and gaps to address during integration

Existing guarantees:

- Inactive/hidden/paused/detached stops the countdown timer without resetting its integer remainder. Resume restarts it only for an admitted ongoing user turn.
- Pending 1,000/1,800 ms actions retain a residual delay based on elapsed wall time, pause while backgrounded, and arm once on resume. Retirement cancels them. Timing does not depend on animation completion, so reduced motion still completes the same game flow.
- Retained callbacks use round/turn generations; dictionary callbacks have a separate generation. Popped-but-mounted routes are blocked because the recovery mixins require `ModalRoute.isActive`.

Read-only findings (not yet fixed; no new guarantee should be claimed):

1. `ModalRoute.isActive` is not `isCurrent`. A route covered by a pushed page remains active. The screen has no RouteAware subscription or visibility gate, so its game countdown/delayed turn/input callbacks can continue underneath a new page. If the approved footer introduces temporary tab visits, implement route-aware suspension without retiring already accepted persistence work.
2. Raw TtsService calls are not screen-owned. `_start`'s 200 ms speech callback lacks lifecycle/visible-route checks; `_acceptUserWord` and dictionary completion may speak while backgrounded; dispose/leave/background do not stop this screen's speech. Add an ownership-safe guard during integration, ensuring disposal of an older screen cannot stop a newer screen's utterance.
3. The clock has no special pause for the coach overlay or a speech-speed/leave sheet. Record any intended pause policy explicitly rather than accidentally changing it through layout.
4. During the one-second dead-end delay, the old UI still shows the user field although callbacks are turn-generation guarded. A presentation-only migration should not expose an active callback that bypasses that guard.

## Minimal presentation API for Figma-to-Flutter work

Suggested play-only `ApprovedWordChainView` inputs; exact names can follow the final Figma structure:

```dart
// Data comes from the existing screen, with no asset-specific word maps.
List<String> chain; // oldest -> newest
String word;
String meaning; // already localized; may be empty
String requiredSyllable;
bool userTurn;
int remainingSeconds; // total remains 30
String? selectionHint;
String statusMessage; // checking/validation/outage
bool checkingDictionary;
TextEditingController controller; // screen retains/disposes it
FocusNode focusNode; // screen retains/disposes it
VoidCallback? onSubmit; // exact guarded closure for this turn
VoidCallback? onListen; // screen-owned speech closure
Widget companion; // existing preference-aware leased presentation
Widget speedControl; // real shared control
Widget close; // frame-owned close control
GlobalKey lastWordKey;
GlobalKey timerKey;
GlobalKey inputKey;
```

Use a typed turn enum instead of the bool if more display states are needed, but do not create a duplicate engine state model. The view may derive labels from AppL10n. Pass a `canSubmit`/nullable callback reflecting admission and pending acceptance where needed. Meaning and syllable layout must use real text and measured available space; A/B/C approved images are content-length layouts, not new rules or difficulty choices. Loading/empty/error/recovery/results remain screen-owned. A fixture gallery can build the same presentation widget without engine/network/persistence.

The final approved navigation style can reuse the existing approved frame/footer once geometry is supplied. Route visibility, focus and keyboard behavior must be validated around that actual shared navigation callback, not around a duplicate shell.

## Existing regression evidence and this audit's validation

Source review identified these targeted tests (their presence is not a fresh pass claim):

- `test/custom_pack_kkeunmari_test.dart`: DE/EN 320×640 at 200% selection empty/disconnected/unverified states, outside-answer rejection without dictionary fallback, valid selected play, retry preserving global pool.
- `test/timed_game_srs_recovery_test.dart`: chain SRS unknown/rejected writes, once-only reconciliation, last-second accepted-answer clock suspension, reset/pop/unmount/exit retirement, late dictionary/loader outcomes, outage and timeout clock freeze, stale turn submission/result actions.
- `test/kkeunmari_dictionary_service_test.dart`: protected endpoint, credential/body deadlines, invalid vs outage, offline fallback, duplicate dictionary-word prevention.
- `test/kkeunmari_reward_durability_test.dart`: once-only XP+win reconciliation, concurrent distinct wins, malformed durable counters blocked without destructive overwrite.
- `test/hangul_game_logic_test.dart`: production corpus filters, fair playable start, exact validation, dictionary word construction. `test/kkeunmari_gloss_locale_test.dart`: localized genuine gloss policy.
- New `test/approved_word_chain_lifecycle_test.dart` adds three behavior regressions before visual integration: typed Korean/countdown survives background; IME submission + no-companion/reduced-motion preserves a single delayed bot reply/focus; a winning dead-end cannot award in background and awards exactly once after resume.

Fresh results on the audited HEAD plus the new test only:

- `flutter test test/approved_word_chain_lifecycle_test.dart --reporter expanded`: **3 passed**.
- `dart analyze test/approved_word_chain_lifecycle_test.dart`: **No issues found**.
- `dart format test/approved_word_chain_lifecycle_test.dart`: 0 changes.
- Final Git status: only untracked `test/approved_word_chain_lifecycle_test.dart`; no production changes.

No physical-device QA and no commit in this audit.

### Planned integration checks once Figma is complete

Add RouteAware suspension through the existing shared route observer. Keep fresh visible input admission separate from lifetime validity so a tab visit cannot admit hidden taps but also cannot discard an already accepted durable write. Preserve the countdown remainder and delayed-turn remainder, restore input focus on return, and guard all speech through one screen-owned request generation. A superseded screen must not stop the next screen's speech. The opening pronunciation's 200 ms scheduling must respect visibility.

Focused follow-up regressions should exercise the actual approved footer detour, preserved draft/countdown/chain, a retained submit while covered, covered pending bot/dead-end transitions, accepted SRS completion while covered, opening audio during immediate cover/background, and later disposal after another screen owns audio. These are planned; the three passing audit tests above cover the existing lifecycle baseline, not these currently missing route/audio guarantees.

## Authorized runtime lifecycle preparation after the audit

The parent subsequently authorized the independent route/lifecycle/audio fixes before final Figma visual context. The baseline findings above describe HEAD `b11c7ef83`; findings 1 and 2 are now addressed in the uncommitted `lib/screens/kkeunmari_screen.dart` changes. Visual composition remains unchanged.

- RouteAware, using the existing shared route observer, now pauses the clock and remaining delayed turn when a route covers play. Return resumes the same round and restores user-input focus. Application lifecycle and route visibility are both required for fresh submit/listen/replay/result navigation callbacks.
- Persistence admission remains separate from visible input admission. Already accepted SRS and dictionary work can finish while covered; the chain advances once, and bot/dead-end timers wait for return. No reset, cancellation, or duplicated write is introduced by a temporary visit.
- Opening/accepted/bot/listen speech now passes through the existing `SoriSpeech` facade, which still invokes real TtsService in production. A screen-local ownership/generation guard stops its own pending speech on cover/background and relinquishes ownership before later disposal. Queued current-word pronunciation waits for visibility, including the initial 200 ms request. The presentation child receives an `onListen` callback rather than calling the service directly.
- Winning celebration no longer starts on top of a covering route. The existing actual result, persisted reward, error/retry, companion preference, timings, selection restrictions and dictionary policy remain intact.
- New tests expanded from 3 to 10. Route tests use actual Navigator routes and the shared observer. They prove draft/time/input retention, single resumed bot/dead-end action, deferred opening audio, old-game disposal not stopping destination audio, accepted real-vocabulary SRS persistence under cover, and valid dictionary completion under cover. Actual approved-footer traversal remains a post-view-integration check.

Fresh verification:

- `flutter test --no-pub test/approved_word_chain_lifecycle_test.dart --reporter expanded`: **10 passed**.
- Existing `timed_game_srs_recovery_test.dart` + `custom_pack_kkeunmari_test.dart`: **62 existing cases passed** in the combined run. That run's sole failure was the new SRS-cover test entering text before its real vocabulary asset was loaded; the test harness now preloads that asset through `runAsync`, and the full 10-test rerun above passed. No production fix was needed for that harness failure.
- `dart analyze lib/screens/kkeunmari_screen.dart test/approved_word_chain_lifecycle_test.dart`: **No issues found**.
- `git diff --check`: clean.

No physical-device QA, final approved-view capture, or commit has been performed in this preparation step.

## Approved presentation integration (2026-11-04)

Active KkeunmariScreen now wires its existing controller, focus node, callbacks, source meanings, timer, chain, companion preference and TTS speed into ApprovedWordChainView. Loading, retry, empty selection, result, reward and recovery branches retain their existing contracts. The full-screen frame reuses SoriStudyFrame exit ownership and canonical ApprovedGameNavigation. No app-main route or engine content was replaced by presentation fixtures.

Figma reference: 358:847 / 358:990 / 358:1171, viewport 402x874, zero insets, German, 100% text. A/B/C represent actual content length. C final tile nodes are75x92 at31.5+i*66, y324, Korean52, line70. Runtime also supports ordinary4-syllable entries, real dictionary1/8-syllable entries and the20-character validation boundary. Long meanings and scaled text grow measured layout; no per-word map, ellipsis or whole-screen shrink is used. Short native height spends only header/history/stand decorative slack; all A/B/C full CTA bounds retain16dp above navigation in the392.73dp wide SafeArea test. Keyboard inset signal is preserved after Scaffold resize so the form reveals its input and submit.

Lifecycle ownership: route covers and inactive/hidden/paused states pause remaining countdown and pending turn delay, cancel opening pronunciation and stop only speech owned by this round. Resuming re-arms remaining delay and queued pronunciation once. Accepted SRS/dictionary writes can finish under cover; they retain state and progress but emit no transient sound/haptics. Result-save haptics are similarly visibility-gated. Retired routes cannot stop a destination's speech. Fractional speed labels use measured height alongside the listen label. Visible accepted answers retain their sound feedback.

Verification as of this entry:
- Existing timed_game_srs_recovery_test.dart + custom_pack_kkeunmari_test.dart:62 cases passed after integration.
- approved_word_chain_lifecycle_test.dart:11 passed after sound/lifecycle fixes.
- approved_word_chain_view_test.dart:15 passed (3 exact geometry,3 nativeSafeArea,6 long-content at320px/200%,2 fractional-speed,1 keyboard).
- Three402x874 real-font presentation captures generated by approved_word_chain_capture_test.dart; manifest at flutter-capture/CAPTURE_MANIFEST.json. The initial capture plus13 then-current layout cases passed14/14. Captures prove presentation, not full engine/device behavior. A subsequent small history-chip-width correction and material-depth review require final capture refresh.
- Earlier red layout runs exposed3dp mixed-font prompt leading and keyboard signal loss. Explicit38dp prompt strut and retained inset signal corrected these; final measured cases passed.
- No physical-device QA, deployment or commit performed by this subtask.

Final refresh: submit uses wordChainAction, all three actions avoid duplicate shadow while retaining2dp press. History frames preserve66/81/123 widths using measured expansion. Final15view+capture16/16 passed; final8-target analysis clean. See FLUTTER_VALIDATION_RECEIPT.json and flutter-analyze-final.log. All owned tool processes finished; no commit or device QA.
