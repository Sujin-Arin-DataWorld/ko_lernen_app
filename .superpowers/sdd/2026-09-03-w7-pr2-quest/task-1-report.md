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

---

# Fix round 1 (Fable 룰링, 2026-09-04)

Fable verdict on `be0a7062`: FIX-REQUIRED — the original brief's entry-autoplay
design was wrong for the three choice-quiz engines. Approved as-is: dialog-stage
autoplay, `TtsService`→`SoriSpeech` unification in the 5 engines, the
`audioEnabled` field pattern, dialog tests.

## STEP 0 — canonical-corpus facts (read-only)

Read `functions/tts/build_canonical_manifest.py` (41 lines): it writes
`assets/data/tts_canonical_manifest.json` as `{schemaVersion, cacheRevision,
voices: {female: [sha1...], male: [sha1...]}}` by calling
`tool/generate_tts.py`'s `collect()` and hashing every `(voice, text)` pair
with `cache_sha1` — **the manifest stores hashes only, never raw text**.

Read `tool/generate_tts.py:672-900` (`collect()`, section 9 "시나리오 퀘스트
데이터의 오디오 문자열"). The quest-data branch is:

```python
if qtype in ("satzBauen", "batchimDrop", "hoerverstehen"):
    add_auto(data.get("audioKo"))
elif qtype == "diktat":
    add_auto(data.get("audioKo") or data.get("targetKo"))
elif qtype == "particlePop":
    options = data.get("options") or []
    idx = int(data.get("correctIndex") or 0)
    if 0 <= idx < len(options):
        add_auto((data.get("prefix") or "") + options[idx] + (data.get("suffix") or ""))
```

There is no `elif` branch for `luecken` or `uebersetzen` at all. Only
`particlePop` has a dedicated, unconditional collector — every `particlePop`
quest's `_fullSentence` is guaranteed canonical. `luecken` and `uebersetzen`
have zero dedicated collection.

Confirmed empirically (script: computed `cache_sha1(auto_voice(text), text)`
for real quest data pulled from `assets/data/scenarios_*.json`, checked
membership in the actual `voices[...]` hash sets):

| engine | example scenario | text checked | canonical? |
|---|---|---|---|
| particlePop | a1_theme_park_date_choices | fullSentence = "롤러코스터를 타고 싶어." | True |
| (only 1 particlePop quest exists in the whole corpus) | | | |
| luecken | a1_theme_park_date_choices | blanked "롤러코스터를 타___ 싶어." | False |
| luecken | a1_theme_park_date_choices | filled "롤러코스터를 타고 싶어." | True (coincidence — identical string to the particlePop row above, same scenario) |
| luecken | a2_theme_park_date_break | blanked "많이 피곤해 보이___ 것 같아." | False |
| luecken | a2_theme_park_date_break | filled "많이 피곤해 보이는 것 같아." | False |
| luecken | b1_theme_park_date_thrill | blanked "두 번이나 돌 ___ 몰랐어." | False |
| luecken | b1_theme_park_date_thrill | filled "두 번이나 돌 줄은 몰랐어." | False |
| uebersetzen | airport_arrival | answer "네, 여기 있어요." | True (coincidence — same string as that scenario's own dialog line, collected by section 2, not by any uebersetzen-specific rule) |
| uebersetzen | bakery_payment_bag | answer "아니요, 괜찮아요." | False |
| uebersetzen | bakery_queue | answer "이 빵 계산해 주세요." | False |

Conclusion: particlePop is reliably canonical (dedicated collector, every
instance). luecken and uebersetzen are not — the one "True" hit each is
pure coincidence (the string also happens to be collected from a different
source, usually the scenario's own dialogue), and 2 of 3 real samples for both
engines miss. Implementing readback for luecken/uebersetzen as literally
specified would ship a feature that mostly shows the "answer unavailable"
banner.

## STEP 1 — implementation

(a) Removed entry autoplay from `luecken_quest.dart` (deleted the
`initState()` override added in round 1 entirely, and the now-dead
`import '../../widgets/sori/speakable.dart'`) and `particle_pop_quest.dart`
(deleted only the `WidgetsBinding.instance.addPostFrameCallback` block from
`initState()`; kept the `AnimationController` setup). Kept the `audioEnabled`
field on both (now unconsumed inside `LueckenQuest`, per the ruling) and left
particle_pop's existing manual "replay" button (`onTap: () =>
SoriSpeech.speak(_fullSentence)`, already converted from `TtsService` in round
1) untouched.

(b) Post-reveal readback — particlePop only (luecken/uebersetzen blocked
per STEP 0). In `particle_pop_quest.dart`'s `_checkSelection()`, added
`if (widget.audioEnabled) { SoriSpeech.speak(_fullSentence); }` right after
`setState(() => _showExplanation = true)` in both resolution branches: the
`isCorrect` branch and the `_tries >= 2` (wrong, exhausted) branch. Did not
touch `luecken_quest.dart`'s `_check()` or `uebersetzen_quest.dart` — no
readback call added to either, matching "for any engine whose text is not
canonical, do not add readback."

(c) Tests — replaced the round-1 entry-autoplay group in
`test/quest_engines_uiux_test.dart` with a new group,
"선택형 퀘스트는 진입 시 무음이고, particlePop만 답 공개 후 정답 문장을 1회 읽는다"
(7 tests): luecken silent through entry+correct-reveal and through
entry+2-wrong-reveal; uebersetzen the same two cases; particlePop silent at
entry then exactly one `SoriSpeech.speak(_fullSentence)` after a correct
reveal, the same after a 2-wrong reveal, and silent throughout when
`audioEnabled: false`. Also wired `audioEnabled: widget.previewFixture ==
null` for `UebersetzenQuest` in `scenario_player_screen.dart`'s `_buildQuest`
(added the field to the widget — unused internally for now, see below).

(d) Dialog path gap — checked `scenario_player_screen.dart:201`
(`buildScenarioStagePlan`): `ScenarioStage.intro` is the unconditional first
element of the returned list (no guard, no variant), so `_plan.first` can
never be `ScenarioStage.dialog` in the normal (non-preview) load path;
`scenarioInitialStageIndex` (line 214-221) only ever returns 0 or the first
quest index. Cited and left as-is — no code change for (d).

### `uebersetzen_quest.dart` `audioEnabled` field — added but unused

Per (c)'s explicit instruction I added `this.audioEnabled = true,` /
`final bool audioEnabled;` to `UebersetzenQuest`, matching the same
constructor-field pattern as the other two engines, and wired the call site.
Nothing inside `UebersetzenQuest`'s body reads it yet — no `SoriSpeech` call
exists there, by design (STEP 0: blocked on canonical corpus). This is
intentionally dead code for now; a doc comment on the field explains why and
points at W9-C as the unblock path.

## Test-design note: not every new test is a genuine round-1/round-2 discriminator

Of the 7 new tests, the RED capture (production code stashed back to the
round-1 commit) showed 4 fail red and 3 pass unchanged:
- luecken "정답 공개 후에도 무음" and "2회 오답 공개 후에도 무음" — RED (round-1
  code auto-played on entry, so `stub.spoken` wasn't empty).
- particlePop's two readback tests — RED (round-1 code had no readback at
  all, and entry autoplay produced a stray call the "진입 시 무음" pre-check now
  catches).
- uebersetzen's two silence tests — pass under both round-1 and this
  round's code, because `uebersetzen_quest.dart` never had any `SoriSpeech`
  call in either round. These are legitimate regression-locks (they'll catch
  a future accidental readback addition), just not discriminators for this
  specific fix.
- particlePop's `audioEnabled: false` test — pass under both rounds too,
  for the same reason (false disables both round-1's entry autoplay and this
  round's readback, so the assertion holds either way). Also a legitimate
  invariant lock, not a discriminator.

I strengthened the particlePop 2-wrong test with an explicit "무음" check
after the pump and after the first wrong attempt (before the reveal), because
without it the test passed for the wrong reason under round-1 code (entry
autoplay happened to produce the identical single-element list the readback
would also produce) — a coincidence, not a real assertion of when the
speech happened.

## Verification

RED (production `lib/` changes for this round stashed, updated test file
present) — `flutter test --no-pub test/quest_engines_uiux_test.dart
--plain-name "선택형 퀘스트는"`: 4 failed / 3 passed (failures matched
expectations exactly — `Expected: empty / Actual: ['안___']` for luecken,
`Expected: empty / Actual: ['저는 학생이에요.']` for particlePop, twice).

GREEN (production code restored): `test/quest_engines_uiux_test.dart` full
file 28/28 passed (21 pre-existing + 7 new).

- `flutter analyze --no-pub`: 0 issues (full project, ~87s).
- `dart format --set-exit-if-changed`: flagged `test/quest_engines_uiux_test.dart`
  (cosmetic line-wrap only, from the new group); applied `dart format`,
  re-ran analyze -> still 0, re-ran the test file -> still 28/28.
- `flutter test --no-pub test/quest_engines_uiux_test.dart
  test/scenario_player_ui_test.dart test/content_audio_policy_guard_test.dart
  test/auto_speech_test_stub_guard_test.dart`: 47/47 passed, 0 failed.
- Each file run alone: `quest_engines_uiux_test.dart` 28/28,
  `scenario_player_ui_test.dart` 10/10 (unaffected by this round — (d) needed
  no code change so nothing here changed), `content_audio_policy_guard_test.dart`
  8/8, `auto_speech_test_stub_guard_test.dart` 1/1.
- `git grep -n "TtsService" -- lib/screens/quest_engines/luecken_quest.dart
  lib/screens/quest_engines/uebersetzen_quest.dart
  lib/screens/quest_engines/particle_pop_quest.dart
  lib/screens/quest_engines/hoerverstehen_quest.dart
  lib/screens/quest_engines/diktat_quest.dart` (the original T2.1 5-file
  scope): 0 matches.
- `git grep -n "TtsService" -- lib/screens/quest_engines/` (STEP 2's literal,
  directory-wide command): 2 matches, both in `batchim_drop_quest.dart`
  (lines ~161, ~474) — this file was never in T2.1's FILES list in either
  round (Fable's own round-1 approval text names "the 5 engines"), so I did
  not touch it; flagging the discrepancy between STEP 2's literal command and
  T2.1's actual scope rather than silently expanding scope or silently
  reporting a false "clean."
- `git diff --check`: clean (exit 0, only a benign CRLF-on-touch warning
  from git, no reported whitespace errors).

## Diffstat (this round, lib/ + test/)

```
 lib/screens/quest_engines/luecken_quest.dart      |  11 --
 lib/screens/quest_engines/particle_pop_quest.dart |  15 +-
 lib/screens/quest_engines/uebersetzen_quest.dart  |   8 ++
 lib/screens/scenario_player_screen.dart           |   1 +
 test/quest_engines_uiux_test.dart                 | 162 +++++++++++++++++++---
 5 files changed, 165 insertions(+), 32 deletions(-)
```

## Questions (max 3)

1. `batchim_drop_quest.dart` still has 2 `TtsService` literals (never in
   T2.1's scope in either round) — should STEP 2's directory-wide grep be
   read as a signal that batchim should move to `SoriSpeech` too, or is that
   still T2.2/out of this task's scope?
2. Is the `uebersetzen_quest.dart` `audioEnabled` field (declared, wired at
   the call site, but internally unused) the right way to leave it, or would
   you rather it stayed off entirely until W9-C actually unblocks the readback?
3. For particlePop's post-reveal readback, I fire it on both the correct
   branch and the 2-wrong-exhausted branch of `_checkSelection()`, but not
   from `_revealAnswer()` (the separate "don't know yet" escape hatch, which
   also completes the quest). Was that the intended boundary, or should
   "don't know" reveals get the readback too?
