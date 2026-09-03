# T2.1 report — 스테이지 진입 대표 문장 자동재생 (지시서 4.5)

BASE origin/main d120af87. Worktree `w7-pr2-quest-20260903` / branch `claude/w7-pr2-quest-20260903`.

## Diffstat

```
 lib/screens/quest_engines/diktat_quest.dart        |   6 +-
 lib/screens/quest_engines/hoerverstehen_quest.dart |   6 +-
 lib/screens/quest_engines/luecken_quest.dart       |  13 +++
 lib/screens/quest_engines/particle_pop_quest.dart  |  11 ++-
 lib/screens/scenario_player_screen.dart            |  40 ++++++++
 test/quest_engines_uiux_test.dart                  | 101 +++++++++++++++++++++
 test/scenario_player_ui_test.dart                  |  51 ++++++++++-
 7 files changed, 219 insertions(+), 9 deletions(-)
```

## Implemented

- `scenario_player_screen.dart`: added `final _speech = ContentSpeechController();`,
  `didChangeDependencies()` (subscribe to `ModalRoute.of(context)`), `deactivate()`
  (`_speech.deactivate()`), `dispose()` extended with `_speech.dispose()` — wiring
  copied from `review_session_screen.dart`'s existing precedent. New private
  `_autoPlayDialogEntry(Scenario)` plays `scenario.dialog.first.ko` via
  `_speech.playOnEnter(..., voice: scenario.voiceForSpeaker(first.speaker))`,
  guarded by `dialog.isEmpty`. Called from two sites only: (a) `initState()`'s
  previewFixture branch, right after `_pageCtrl = PageController(initialPage:
  _stage)`, when `_plan[_stage] == ScenarioStage.dialog` (the only place a
  scenario can *start* on the dialog stage); (b) `_next()`, when
  `nextKind == ScenarioStage.dialog`. The normal (non-preview) load path never
  starts on `dialog` (`scenarioInitialStageIndex` only returns 0 or the first
  quest index), so no third call site exists. Tap-to-speak on the dialog bubble
  (L1403, unchanged) and `_buildDialog`'s tap handler are untouched.
- `luecken_quest.dart`: new `audioEnabled` field (default `true`, mirrors
  `HoerverstehenQuest`'s existing pattern — see "Question 1" below), new
  `initState()` with `WidgetsBinding.instance.addPostFrameCallback` calling
  `SoriSpeech.speak(_sentence)` when `mounted && widget.audioEnabled`. Added
  `import '../../widgets/sori/speakable.dart';`.
- `particle_pop_quest.dart`: same `audioEnabled` field/initState pattern,
  speaking `_fullSentence` (the existing getter already used by the manual
  "replay" button). Converted the manual button's `TtsService.speak(_fullSentence)`
  → `SoriSpeech.speak(_fullSentence)`. Swapped `import '../../services/tts_service.dart'`
  for `import '../../widgets/sori/speakable.dart'`.
- `hoerverstehen_quest.dart`: both `TtsService.speak(_audioKo)` call sites
  (initState auto-play, manual `_playTts()`) → `SoriSpeech.speak(_audioKo)`.
  Swapped the `tts_service.dart` import for `speakable.dart`. No behavior change
  to the existing `audioEnabled` gating.
- `diktat_quest.dart`: `_playTts()`/`_playSlow()` bodies
  `TtsService.speak`/`speakSlow` → `SoriSpeech.speak`/`speakSlow`. Swapped
  import. `initState()`'s unconditional postFrame call to `_playTts()` is
  unchanged (pre-existing behavior, outside T2.1's FILES list for this file).
- `scenario_player_screen.dart`'s `_buildQuest`: added
  `audioEnabled: widget.previewFixture == null` to the `LueckenQuest(...)` and
  `ParticlePopQuest(...)` constructions, matching the existing
  `HoerverstehenQuest(...)` call.
- **`uebersetzen_quest.dart` — NOT changed.** See "Brief defect" below.

`git grep -n "TtsService"` over the five FILES-listed engine sources returns
empty (comments included).

## Route-observer wiring check (per brief ask)

`lib/main.dart:593-597` — `MaterialApp.navigatorObservers: [soriRouteObserver,
DiagnosticsRouteObserver(), analyticsRouteObserver]`. All production pushes of
`ScenarioPlayerScreen` go through that single ambient Navigator: `main.dart:1185`
and `onboarding_journey.dart:32` (`Navigator.push`-style `MaterialPageRoute`),
`scenarios_list_screen.dart:783` (`MaterialPageRoute`), and
`scenarios_list_screen.dart:420` (`OpenContainer.openBuilder` from the
`animations` package — its container-transform push defaults to
`useRootNavigator: true`, i.e. the same root Navigator, so it is observed too).
So `didPushNext`/`deactivate` fire for every real entry point, matching
`review_session_screen.dart`'s already-shipped contract.

## TDD

RED (production code stashed, tests present) — `scenario_player_ui_test.dart`:
```
00:03 +5 -1: canonical player profile renders its name and supplies its voice [E]
  Expected: [(text: 네, 여기 있어요., voice: male), (text: 네, 여기 있어요., voice: male)]
  Actual:   [(text: 네, 여기 있어요., voice: male)]
00:03 +5 -2: 스테이지 전환마다 대표 문장 1회 자동재생, 뒤로 전환 시 정지 [E]
  Expected: ['여권 보여주세요.']
  Actual:   []
```
(6 other pre-existing tests in the file unaffected.)

RED — `quest_engines_uiux_test.dart` (compile error, expected — `audioEnabled`
doesn't exist on the pre-implementation widgets yet):
```
test/quest_engines_uiux_test.dart:852:11: Error: No named parameter with the name 'audioEnabled'.
lib/screens/quest_engines/luecken_quest.dart:13:9: Context: Found this candidate...
test/quest_engines_uiux_test.dart:899:11: Error: No named parameter with the name 'audioEnabled'.
lib/screens/quest_engines/particle_pop_quest.dart:23:9: Context: Found this candidate...
```

GREEN (production code restored):
- `scenario_player_ui_test.dart`: 10/10 passed.
- `quest_engines_uiux_test.dart`: 25/25 passed (21 pre-existing + 4 new).

## Verification counts

- `flutter analyze --no-pub`: **0 issues** (33–35s).
- `dart format --set-exit-if-changed` flagged `scenario_player_screen.dart` and
  `scenario_player_ui_test.dart` (cosmetic wrapping only); applied `dart format`
  and re-ran analyze → still 0.
- `flutter test --no-pub test/content_audio_policy_guard_test.dart
  test/auto_speech_test_stub_guard_test.dart test/scenario_player_ui_test.dart
  test/quest_engines_uiux_test.dart test/speakable_screen_lifecycle_test.dart`:
  **52/52 passed**, 0 failed.
- Each file run alone (avoiding the combined runner's duplicate-name merging):
  `content_audio_policy_guard_test.dart` 8/8, `auto_speech_test_stub_guard_test.dart`
  1/1, `scenario_player_ui_test.dart` 10/10, `quest_engines_uiux_test.dart` 25/25,
  `speakable_screen_lifecycle_test.dart` 8/8.
- `git grep -n "TtsService"` over the 5 engine files: **0 matches**.
- `git diff --check`: **clean** (exit 0, no whitespace errors).

## Brief defect — uebersetzen_quest.dart excluded (STOP that item, per 상시 규칙 #12)

FILES groups `uebersetzen_quest.dart` with luecken/particlePop under one
instruction: "각 initState 포스트프레임에서 ... SoriSpeech.speak(문제 문장)". I
checked `uebersetzen`'s actual data schema before implementing
(`tools/content_factory/validate_content.py:1713-1715`: requires only
`promptDe`/`promptEn` + Korean `options`, verified against a real content
sample in `assets/data/scenarios_a1.json`) and the widget's current build
(`SoriPromptCard(sentence: _prompt(langCode))`, no `speakText`, currently
plays no audio at all). There is no Korean sentence in this quest's data that
isn't the answer itself — the only Korean text is `options[i].ko`, and
`options[correctIndex].ko` *is* the correct choice among the 4 shown. Auto-
playing it on stage entry, before the learner has picked anything, would read
the correct multiple-choice answer aloud. `luecken`'s `_sentence` (cloze
template, blank unfilled) and `particlePop`'s `_fullSentence` (already exposed
via an existing pre-T2.1 manual "replay" button, so hearing the assembled
correct sentence is already an established, accepted affordance for that
engine) don't have this problem. I did not improvise a fix (skip audio
silently, or play the answer anyway) — I left `uebersetzen_quest.dart`
untouched and excluded it from the new `quest_engines_uiux_test.dart` group
(named accordingly: "선택형 퀘스트(luecken·particlePop)는 진입 시 문제 문장을
1회 자동재생한다", 4 tests, not the 3-engine group the brief describes).
`uebersetzen_quest.dart` already has zero `TtsService` literals, so T2.1's
"5개 엔진 소스에 TtsService 리터럴 0" DONE gate is unaffected either way.

## `audioEnabled` flag — no existing flag to reuse (INTERFACE clause, "없으면 보고")

`quest_flow.dart` (the shared quest-engine wrapper) has no audio-related flag
of any kind. The only existing precedent is `HoerverstehenQuest.audioEnabled`
(default `true`), wired at its one call site as
`audioEnabled: widget.previewFixture == null`. I replicated that exact
pattern — field name, default, and call-site wiring — on `LueckenQuest` and
`ParticlePopQuest` rather than inventing a new mechanism. Flagging this per
the brief's "없으면 보고" clause rather than treating it as self-evidently
correct.

## Unexpected observations (not gating, informational)

- `test/scenario_player_ui_test.dart`'s pre-existing test `'vocabulary and
  dialogue audio controls are labeled buttons'` pumps
  `ScenarioPlayerPreviewFixture.action(stage: ScenarioStage.dialog)` directly
  (line ~196) without its own `stubSoriSpeech()`/`speakImpl =`. With T2.1 this
  now triggers a real (unstubbed) `_autoPlayDialogEntry` → `SoriSpeech.speak`
  → default `TtsService.speak` call during that pump. It still passes (verified
  individually and in the combined run) — evidently no network hang in this
  file's environment even with `Storage.init()` called in `setUp`. Only the
  five named test files were in scope for this task, so I did not touch this
  test, but flagging it since it's a new, previously-inert code path now
  firing there.
- Other test files that pump `ScenarioPlayerScreen` and are in
  `auto_speech_test_stub_guard_test.dart`'s frozen `knownUnstubbedTestFiles`
  allowlist (e.g. `scenario_can_do_result_flow_test.dart`,
  `scenario_grammar_resolution_test.dart`) were out of this task's run list.
  I didn't audit whether any of them tap through the dialog stage via `_next()`
  taps; the guard test itself is unaffected (it's a static per-file string
  check, not a runtime one), but a real unstubbed `SoriSpeech.speak` could now
  fire in any of them if they do. Worth a sweep before the PR2 exit gate.

## Questions (≤3)

1. Is the `HoerverstehenQuest`-pattern `audioEnabled` field (added fresh to
   `LueckenQuest`/`ParticlePopQuest`) the intended design, or did you have a
   different "existing flag" in mind that I missed?
2. For `uebersetzen_quest.dart`: is there a different field I should treat as
   the non-spoiling "문제 문장" (e.g. should a future content-schema change add
   one), or is silence (no auto-play) the intended outcome for this engine?
3. `scenario_player_ui_test.dart`'s `'vocabulary and dialogue audio controls
   are labeled buttons'` test now exercises an unstubbed real `SoriSpeech.speak`
   path (see Unexpected observations) — acceptable as-is, or should a follow-up
   task stub it?
