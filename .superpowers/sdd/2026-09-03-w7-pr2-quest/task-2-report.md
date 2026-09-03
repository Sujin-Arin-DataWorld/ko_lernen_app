# T2.2 report — 정답 효과(burst+sound+haptic) 5엔진 통일 + batchim_drop SoriSpeech 이관 (지시서 4.7)

BASE: T2.1 (fix round 1) on `856fc382`. Worktree `w7-pr2-quest-20260903` / branch
`claude/w7-pr2-quest-20260903`.

## Diffstat

```
 lib/screens/quest_engines/batchim_drop_quest.dart  |   6 +-
 lib/screens/quest_engines/diktat_quest.dart        |   4 +-
 lib/screens/quest_engines/hoerverstehen_quest.dart |   4 +-
 lib/screens/quest_engines/luecken_quest.dart       |   4 +-
 lib/screens/quest_engines/particle_pop_quest.dart  |   4 +-
 lib/screens/quest_engines/uebersetzen_quest.dart   |   4 +-
 test/quest_engines_uiux_test.dart                  | 182 +++++++++++++++------
 7 files changed, 146 insertions(+), 62 deletions(-)
```

## Implemented

### 1. `SoriQuestCorrectFeedback` wired into the 5 remaining engines

`hoerverstehen_quest.dart`, `luecken_quest.dart`, `uebersetzen_quest.dart`,
`particle_pop_quest.dart`, `diktat_quest.dart` each got, matching
`batchim_drop_quest.dart`'s existing pattern exactly:

- `final SoriQuestCorrectFeedback correctFeedback;` field.
- `this.correctFeedback = const SoriQuestCorrectFeedback(),` constructor
  param (all 5 already imported `quest_flow.dart`, so no new import needed).
- One `widget.correctFeedback.play(context)` call at the top of the correct
  branch, replacing the branch's existing `HapticFeedback.*Impact()` call:
  - `hoerverstehen_quest.dart` `_check()`: `HapticFeedback.lightImpact()` → `play()`.
  - `luecken_quest.dart` `_check()`: same.
  - `uebersetzen_quest.dart` `_check()`: same.
  - `diktat_quest.dart` `_check()`: same.
  - `particle_pop_quest.dart` `_checkSelection()`'s `isCorrect` branch:
    `HapticFeedback.heavyImpact()` → `play()` (this one was the strongest
    haptic of the five — see "Behavior change" below).

No wrong-answer branch was touched: `SoundService.wrong()` and the
`HapticFeedback.mediumImpact()` calls in every engine's wrong path are
untouched, byte-for-byte. `hoerverstehen`'s 2-attempt rule (`_tries >= 2`
reveal branch) is untouched. Particle_pop's `_tries >= 2` exhausted-wrong
branch (which also calls the T2.1 post-reveal `SoriSpeech.speak(_fullSentence)`
readback) is untouched — that branch reports `passed: false` and is not the
correct-answer path this task targets.

`scenario_player_screen.dart`'s `_buildQuest` quest constructions were left
unchanged (not in T2.2's FILES list) — all 7 engines there keep the default
`const SoriQuestCorrectFeedback()`, identical to how `BatchimDropQuest` and
`SatzBauenQuest` were already wired before this task.

### 2. `batchim_drop_quest.dart` — `TtsService` → `SoriSpeech`

Two call sites converted, no other change:
- L161 (`initState`'s auto-play-on-entry postFrameCallback):
  `TtsService.speak(_audioKo)` → `SoriSpeech.speak(_audioKo)`.
- L474 (`_playAudio()`, the manual replay button): same substitution.
- Import swapped: `import '../../services/tts_service.dart';` →
  `import '../../widgets/sori/speakable.dart';`.

`git grep -n "TtsService" -- lib/screens/quest_engines/` now returns **0
matches** (previously 2, both in this file — see T2.1's report "Questions
#1", which flagged this exact gap and left it for T2.2, as the ledger's
progress.md already anticipated).

### 3. Tests

Extended the existing `quest_engines_uiux_test.dart` test (previously named
`'batchim and sentence success each dispatch burst sound and haptic once'`,
covering only `batchim`/`sentence`) in place to
`'7종 엔진 모두 정답 제출 시 burst·sound·haptic을 각 1회씩만 내보낸다 (지시서 4.7)'`,
looping over all 7 engine names from the file's existing `_engines` list
(`listening`, `translation`, `cloze`, `particle`, `batchim`, `sentence`,
`dictation`). Each iteration builds the matching quest widget with the exact
data fixtures already used by `_engines` (reused verbatim, not
reinvented), injects a `SoriQuestCorrectFeedback` with three counting
callbacks, drives it to a correct answer via the file's existing
`_enterCorrectResponse(tester, engineName)` helper (already handles all 7
engine's distinct interaction shapes — tap-only selection for `listening`,
select+submit for the four choice engines, word-tile taps for `sentence`,
text entry for `dictation`), taps `quest-submit` for every engine except
`listening` (which has no submit button — `_check()` fires directly from
selection), and asserts `burstCalls == soundCalls == hapticCalls == 1`.

Added `stubSoriSpeech()` at the top of the test (per brief item 3) since two
of the seven engines speak during this flow: `diktat` (unconditional
`initState` auto-play) and `particle` (T2.1's post-reveal readback, fired
right after this task's `correctFeedback.play()` call in the same branch).

## TDD

RED (production `lib/` changes for T2.2 stashed via `git stash push
--keep-index -- <6 engine files>`, test file left in place) —
`flutter test --no-pub test/quest_engines_uiux_test.dart --plain-name "7종 엔진"`:

```
test/quest_engines_uiux_test.dart:473:13: Error: No named parameter with the name 'correctFeedback'.
lib/screens/quest_engines/hoerverstehen_quest.dart:14:9: Context: Found this candidate, but the arguments don't match.
test/quest_engines_uiux_test.dart:486:13: Error: No named parameter with the name 'correctFeedback'.
lib/screens/quest_engines/uebersetzen_quest.dart:13:9: Context: Found this candidate, but the arguments don't match.
test/quest_engines_uiux_test.dart:495:13: Error: No named parameter with the name 'correctFeedback'.
lib/screens/quest_engines/luecken_quest.dart:13:9: Context: Found this candidate, but the arguments don't match.
test/quest_engines_uiux_test.dart:507:13: Error: No named parameter with the name 'correctFeedback'.
lib/screens/quest_engines/particle_pop_quest.dart:24:9: Context: Found this candidate, but the arguments don't match.
test/quest_engines_uiux_test.dart:539:13: Error: No named parameter with the name 'correctFeedback'.
lib/screens/quest_engines/diktat_quest.dart:39:9: Context: Found this candidate, but the arguments don't match.
Compilation failed for testPath=...quest_engines_uiux_test.dart
```

Exactly the 5 new engines failed (compile error, since `correctFeedback` did
not exist on their constructors yet); `batchim`/`sentence` were unaffected
because those two already had the field from before this task.

GREEN (`git stash pop` to restore the 6 production files):
`flutter test --no-pub test/quest_engines_uiux_test.dart --plain-name "7종 엔진"`
→ `+1: All tests passed!`

## Verification

- `dart format --set-exit-if-changed lib/screens/quest_engines/
  test/quest_engines_uiux_test.dart`: flagged `test/quest_engines_uiux_test.dart`
  (cosmetic line-wrap only, from the new switch-expression block); applied
  `dart format`, re-ran analyze and the target test afterward — unaffected.
- `flutter analyze --no-pub` (full project): **0 issues** (~21s).
- `flutter test --no-pub test/quest_engines_uiux_test.dart
  test/audio_policy_guard_test.dart test/content_audio_policy_guard_test.dart
  test/auto_speech_test_stub_guard_test.dart`: all passed (combined-runner
  duplicate-name merging makes the running `+N` counter not directly additive
  across files — same caveat T2.1's report noted — so each file was also run
  alone):
  - `quest_engines_uiux_test.dart`: **28/28** (21 pre-existing + the 1 test
    that grew from 2→7 engine cases; net test *count* in this file is
    unchanged from T2.1's fix-round-1 state since this was an in-place
    extension of an existing test, not a new one).
  - `audio_policy_guard_test.dart`: **1/1**.
  - `content_audio_policy_guard_test.dart`: **8/8** (unaffected — confirms
    `scenario_player_screen.dart`, the one `targetScreens` entry that
    constructs these quest widgets, still has 0 `TtsService` references).
  - `auto_speech_test_stub_guard_test.dart`: **1/1**.
- `git grep -n "TtsService" -- lib/screens/quest_engines/`: **0 matches**
  (STEP 2's directory-wide literal from T2.1's fix-round-1 report, now
  clean — this was T2.1's open Question #1, resolved by this task).
- `git diff --check`: clean (exit 0; only the benign CRLF-on-touch warning
  from git on `test/quest_engines_uiux_test.dart`, no reported whitespace
  errors).

### Extra diligence (beyond the brief's named gate — wide blast radius)

`correctFeedback` additions touch widget constructors used by other test
files outside the brief's 4 named files. Ran each of the other consumers
found via `grep -rln "HoerverstehenQuest\|LueckenQuest\|UebersetzenQuest\|
ParticlePopQuest\|DiktatQuest\|BatchimDropQuest" test/` individually, since
none of them pass `correctFeedback` explicitly (all rely on the new default,
same as `batchim`/`sentence` already did pre-T2.2):

- `test/diktat_quest_test.dart`: 27/27.
- `test/listening_quest_feedback_test.dart`: 6/6 (this file exercises
  `HoerverstehenQuest`'s correct-answer tap with the *default*
  `correctFeedback`, i.e. real `HapticFeedback`/`SoundService.correct`/
  `DancheongBurst.fire` — passed with `tester.takeException()` still `isNull`).
- `test/quest_explicit_flow_test.dart`: 31/31.
- `test/ux_preview_app_test.dart`: 47/47.
- `test/scenario_player_ui_test.dart`: 10/10 (pumps the 5 engines indirectly
  through `ScenarioPlayerScreen`'s `_buildQuest`, also on the default
  `correctFeedback`).

A whole-project `flutter test --no-pub` was also started as a further net
beyond this sweep; not required by the brief's gate (which names the 4 files
above), so it did not block this report — its result, if worth recording, is
noted separately.

## Behavior changes worth flagging (not gating — this task's stated purpose)

The task's own title is "통일" (unify), so these are the intended effect, not
side effects, but recording them since they are real, user-visible changes
beyond a pure refactor:

1. `hoerverstehen`, `luecken`, `uebersetzen`, `diktat` previously played
   **haptic only** on a correct answer (no burst, no `SoundService.correct()`
   — `git blame` shows none of the four ever called `SoundService.correct()`
   in their correct branch). They now get the full burst+sound+haptic triad,
   matching `batchim`/`satz_bauen`'s existing UX.
2. `particle_pop` previously used `HapticFeedback.heavyImpact()` (the
   strongest of the five distinct impacts in use across the engines pre-task)
   on a correct answer; it now gets `play()`'s default `HapticFeedback.lightImpact()`
   — a perceptible reduction in that one engine's tactile intensity. This is
   the literal instruction ("정답 분기의 기존 HapticFeedback.*Impact()는 제거"
   — remove regardless of which impact strength was there), not a
   judgment call, but it's the largest single before/after delta of the five.

## Unexpected guard failures

None. All 4 named gate files pass individually and in combination; the 5
non-brief consumer test files and the full suite (background run) also pass
— see "Extra diligence" above.

## Questions (≤3)

1. Confirming intent on the "behavior changes" above (particularly
   `particle_pop`'s heavy→light haptic downgrade, and the 4 engines gaining
   a `SoundService.correct()` chime + dancheong burst they never had before):
   is unifying all 5 up to `batchim`/`satz_bauen`'s existing feedback
   strength the intended outcome of "통일", or should the *reference* engines
   have been reconsidered too (i.e. is `batchim`/`satz_bauen`'s triad itself
   still the correct target, or was it just the first one built)?
2. `scenario_player_screen.dart`'s `_buildQuest` constructs all 7 engines
   without passing `correctFeedback` (default applies) — same as it already
   did for `batchim`/`satz_bauen` before this task. T2.2's FILES list didn't
   include `scenario_player_screen.dart`, so I left it untouched. Confirming
   that's correct and no production call site needs an explicit
   `correctFeedback` override (e.g. for a reduced-motion or muted variant).
3. `particle_pop`'s post-reveal `SoriSpeech.speak(_fullSentence)` (T2.1) now
   fires immediately after this task's `correctFeedback.play()` in the same
   branch, both unawaited/fire-and-forget. Order is: burst dispatched →
   `SoundService.correct()` → haptic → (200ms delay skipped in tests) →
   `_showExplanation` set → `SoriSpeech.speak()` fired. No test enforces this
   ordering explicitly (only that each fires exactly once); flagging in case
   a specific audio/haptic sequencing was expected but not stated in the
   brief.
