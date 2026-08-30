# W5-B 학습·게임 표면 Implementation Plan

> **REQUIRED SUB-SKILL:** Use `superpowers:executing-plans` to execute this plan task by task in the current Codex thread.

**Goal:** 공통 W5-A 계약 위에서 Kalligrafie, quest feedback, Diktat, scenario grammar/writing, Anlaut, Silben, Aussprache의 실제 학습 화면을 승인 사양대로 수술한다.

**Architecture:** 획 입력은 재사용 가능한 `TraceCanvas`로 추출하고, quest 판정은 기존 engine ownership을 유지한 채 presentation만 통일한다. scenario grammar는 loader가 `grammarIds`를 해석하고 inline block을 fallback으로 유지한다. 녹음·assessment 서비스 계약은 바꾸지 않고 화면 상태만 명시적으로 모델링한다.

**Tech Stack:** Flutter CustomPainter/GestureDetector, Dart, flutter_test, semantics, Firebase callable client seams.

**Spec:** `docs/superpowers/specs/2026-08-28-w4-w6-completion-design.md` §7.2 and the approved W5 details referenced in §2.

**Live-contract reconciliation (2026-08-30):** W5-A is merged in
`origin/main` at `c2199ad4`. The interfaces and ownership notes below were
rechecked against that tree before W5-B implementation; where this plan used
stale names, the live contracts below are authoritative.

## Global Constraints

- Start after W5-A is merged, from fresh `origin/main`.
- Existing score, SRS, course checkpoint, two-attempt, consent, permission, recording, and assessment contracts remain authoritative.
- Only `hoerverstehen` may judge immediately. Other quest types retain explicit confirmation.
- Korean is semantic source. DE/EN are independent localized support copy.
- No tiger/hero decoration remains in pronunciation studio.
- UI states use semantics/live regions and remain usable at text scale 2.0 and 360×640.

### Task 1: extract reusable TraceCanvas and complete Daily Character tracing

**Files:**

- Create: `lib/widgets/trace_canvas.dart`
- Modify: `lib/screens/hangul_screen.dart`
- Modify: `lib/screens/daily_char_sheet.dart`
- Reuse: `lib/widgets/stroke_canvas.dart`
- Reuse: `lib/services/stroke_matcher.dart`
- Create: `test/trace_canvas_test.dart`
- Modify: `test/stroke_canvas_test.dart`
- Modify: existing Hangul writing and daily-character tests

**Interface:**

```dart
@immutable
final class TraceCanvasSnapshot {
  const TraceCanvasSnapshot({required this.strokes});
  final List<List<Offset>> strokes;
}

final class TraceCanvasController extends ChangeNotifier {
  TraceCanvasSnapshot get snapshot;
  void rejectLastStroke();
  void clearErrorGhost();
  void showNextStrokeHint(List<Offset> points);
  void clearHint();
  void reset();
}

class TraceCanvas extends StatefulWidget {
  const TraceCanvas({
    required this.controller,
    required this.ghost,
    required this.color,
    required this.errorColor,
    required this.enabled,
    required this.onStrokeEnd,
    required this.semanticLabel,
    super.key,
  });

  final String ghost;
  final Color color;
  final Color errorColor;
  final bool enabled;
}
```

The extracted painter preserves current Hangul practice behavior, including its
guide glyph, enabled state, colors, raw pointer ordering, and canvas-size input
needed by `evaluateStroke`. `TraceCanvasSnapshot` must be a deep immutable copy:
callers cannot mutate either the outer stroke list or any inner point list. A
rejected stroke remains briefly as an error ghost. Each consumer owns its
expected-stroke index, per-index failure count, acceptance/advance timer, and
error-ghost timer; after two failures at the same expected index it asks the
controller to display the next-stroke hint. Pointer cancel, controller/widget
replacement, reset, and dispose with an active gesture must leave no orphaned
stroke or timer callback.

**TDD steps:**

1. Add TraceCanvas tests for raw pointer input/cancel, deeply immutable ordered stroke snapshots, reset, rejected-stroke ghost, next-stroke hint, semantics, controller replacement, and dispose with an active gesture.
2. Confirm tests fail because the public widget/controller do not exist.
3. Move the private `_PracticeCanvas` implementation from `hangul_screen.dart` without visual changes and migrate Hangul to the public API.
4. Model Daily Character as `appreciation → tracing → complete`; keep the existing `StrokeCanvas` appreciation animation.
5. Match every finished stroke with `StrokeMatcher`; reject wrong strokes, increment the per-index failure count, reveal the next-stroke hint on the second failure at that index, reset that count after acceptance/reset, and only enable Finish after all strokes match. Cancel all timers in `dispose`.
6. Preserve the existing no-stroke-data fallback as a clearly labeled non-tracing completion path.
7. Run `flutter test --no-pub test/trace_canvas_test.dart test/stroke_canvas_test.dart test/stroke_matcher_test.dart` plus Hangul/Daily Character widget tests.

**Commit:** `feat(writing): share trace canvas with daily character practice`

### Task 2: unify quest word-tile feedback without changing judgment ownership

**Files:**

- Modify: `lib/screens/quest_engines/quest_flow.dart`
- Modify: `lib/screens/quest_engines/batchim_drop_quest.dart`
- Modify: `lib/screens/quest_engines/satz_bauen_quest.dart`
- Modify: `test/quest_engines_uiux_test.dart`
- Verify: `test/dedicated_feedback_route_test.dart`
- Verify: `test/scenario_can_do_result_flow_test.dart`
- Verify: `test/scenario_srs_persistence_flow_test.dart`

**Presentation contract:** remove selected/correct/wrong corner icons; retain fill, border, and semantic state; use 17.5 logical-pixel type; correct answer triggers the existing Dancheong burst, correct SFX, and haptic once; incorrect answer remains eligible for the existing second attempt; the lower duplicate “Richtig” banner is removed while the live-region announcement remains.

**TDD steps:**

1. Update tests to assert no corner status Icon descendants, explicit correct/wrong semantics, 17.5 text style, one burst/SFX/haptic, and no duplicate lower success banner.
2. Add a route matrix proving only `hoerverstehen` invokes immediate judgment; Diktat and other engines require their confirmation action.
3. Run the four fixed contract suites and confirm presentation tests fail before implementation.
4. Refactor `SoriWordTile` presentation and feedback trigger without moving SRS/score calls.
5. Rerun the fixed suites and all quest-engine tests.

**Commit:** `refactor(quests): standardize accessible answer feedback`

### Task 3: Diktat authoritative Korean review and compact audio controls

**Files:**

- Modify: `lib/screens/quest_engines/diktat_quest.dart`
- Modify: `lib/screens/scenario_player_screen.dart`
- Modify: `test/diktat_quest_test.dart`
- Modify: `test/quest_explicit_flow_test.dart`
- Modify: `test/quest_engines_uiux_test.dart`

**Live interface:** do not add a parallel `promptKo` constructor argument.
`DiktatQuest` already receives the canonical Korean source as
`data['targetKo']`; use that existing value for review. A null/empty value hides
the review. Before resolution it is never rendered or included in semantics.
After correct/failed resolution it appears in the review block.

**TDD steps:**

1. Add tests proving canonical `targetKo` is absent before judgment and visible after resolution, including semantics; cover null/empty data.
2. Add layout tests for a 56 dp normal audio control and a 56 dp slow control with visible localized `Langsam` label.
3. Confirm current tests fail because the audio control is 84 dp and Korean review is absent.
4. Implement the post-resolution review from existing `targetKo`; remove the dedicated `QuestLayout(showTtsSpeed: true)` row and use the compact paired controls.
5. Preserve explicit confirmation and two-attempt behavior.
6. Run all three Diktat/quest suites.

**Commit:** `feat(dictation): reveal Korean source only in answer review`

### Task 4: scenario grammar ID resolution and one-sentence writing prompt

**Files:**

- Modify: `lib/screens/scenario_player_screen.dart`
- Modify: `lib/widgets/sori/scenario_write_after_roleplay_card.dart`
- Modify: scenario player tests
- Modify: `test/scenario_write_after_roleplay_card_test.dart`
- Modify: `test/scenario_srs_persistence_flow_test.dart`

**Interface:**

```dart
typedef ScenarioGrammarLoader = Future<List<Grammar>> Function();
```

The live model is `Grammar`, and `DataLoader.loadGrammar()` returns
`Future<List<Grammar>>`. The screen accepts an optional loader defaulting to
that method, builds an internal ID map, resolves `Scenario.grammarIds` in
declared order, skips missing IDs without crashing, and retains `grammarBlock`
as an inline fallback. One resolved entry is enlarged; multiple entries form a
vertical list whose cards open an accessible detail sheet.

`ScenarioWriteAfterRoleplayCard` receives required `promptKo`, derived from the
last non-empty user-authored dialog line. The card shows exactly that one
sentence, offers the existing writing check, and adds Skip that collapses the
optional card without calling the checker or recording score, SRS, or
completion. If no non-empty user-authored line exists, the parent hides the
writing card.

**TDD steps:**

1. Add grammar tests for one ID, multiple ordered IDs, one missing among valid IDs, all missing with inline fallback, and loader failure containment.
2. Add writing tests for exact last-user sentence, no assistant line leakage, Skip collapse, and unchanged checking-service calls.
3. Confirm current stage planning omits ID-only grammar and tests fail.
4. Resolve IDs before the stage plan; include the grammar stage when resolved entries or inline fallback exist.
5. Implement card/list/detail presentation and pass the deterministic one-sentence prompt into writing.
6. Run scenario player, writing card, SRS persistence, and can-do result tests.

**Commit:** `feat(scenarios): resolve grammar references and focus writing prompt`

### Task 5: audit the already-compressed Anlaut chrome (expected no-op)

**Files:**

- Verify: `lib/screens/chosung_quiz_screen.dart`
- Verify: Anlaut/chosung widget and responsive tests
- Verify: `test/chrome_stack_guard_test.dart`
- Verify: `test/hero_placement_guard_test.dart`

**TDD steps:**

1. Confirm the live W5-A screen already exposes exactly one `SoriChromeRow`, one progress rail, the level/mode filter sheet, and no private chip rail.
2. Run narrow-screen and text-scale 2.0 coverage plus both static guards.
3. Add only genuinely missing regression coverage; do not rewrite the live implementation merely to produce a W5-B diff.
4. Keep all quiz state and answer semantics unchanged.

**Commit:** none expected; if and only if a real coverage gap is found, include
the focused regression test with the nearest implementation task.

### Task 6: synchronized Silben grid and clue states

**Files:**

- Modify: `lib/screens/silben_kreuz_screen.dart`
- Modify: `test/silben_puzzle_test.dart`
- Modify: `test/silben_puzzle_spoken_test.dart`
- Create or modify: Silben screen widget test

**Contract:** selected cell uses information tint plus a 2 dp border; the active word lane uses a 0.06 tint; crossing cells show non-color horizontal/vertical corner wedges derived from each `SilbenWord.dir`; tapping a clue selects its first unresolved cell; selecting a grid cell highlights the matching clue; semantics announce row/column, membership, active word, and correctness.

At a crossing, active-word choice is deterministic: retain the current active
word when it contains the selected cell; otherwise choose the first matching
word in the puzzle's declared word order. Existing `_wordThrough` behavior is
the baseline to preserve while adding synchronized clue state and non-color
wedges.

**TDD steps:**

1. Add bidirectional cell→clue and clue→cell tests, crossing-cell wedge tests, and semantics tests without relying on color values alone.
2. Confirm current implementation lacks wedges and active clue synchronization.
3. Derive memberships once from puzzle words/cells and render state with CustomPainter or two positioned triangles that ignore pointer input.
4. Keep puzzle validation and spoken behavior unchanged.
5. Run all Silben tests at narrow and expanded sizes.

**Commit:** `feat(silben): synchronize grid lanes clues and semantics`

### Task 7: rebuild pronunciation studio around five diagnostic outcomes

**Files:**

- Modify: `lib/screens/pronunciation_studio_screen.dart`
- Reuse: `lib/services/pronunciation_assessment_client.dart`
- Modify: `lib/l10n/app_de.arb`
- Modify: `lib/l10n/app_en.arb`
- Regenerate: `lib/l10n/generated/app_localizations*.dart`
- Modify: `test/pronunciation_studio_screen_test.dart`
- Modify: `test/pronunciation_studio_ui_test.dart`
- Create: `docs/runbooks/pronunciation-assessment.md`

**State contract:** map `invalidRequest`, `authenticationRequired`, `unavailable`, `rateLimited`, and `unknown` to five distinct DE/EN explanations and retry affordances. Preserve microphone consent/permission, recorder, gateway, and assessment behavior.

These five categories already exist in
`PronunciationAssessmentFailureCategory`; W5-B changes the screen mapping, not
the callable service contract. Assessment retry preserves the captured PCM or
recording reference and reuses the same `assessmentId` for idempotency. Guard
late async completions with a generation/cancel token so retry, navigation, and
dispose cannot apply stale state. The callable remains in `europe-west3`.

**TDD steps:**

1. Add tests for all five failure categories, permission denial, recorder failure, idempotent assessment retry with the same recording and `assessmentId`, stale-completion suppression, and dispose while recording/assessing.
2. Add presentation tests for `SoriStudyFrame`, no tiger/hero asset, Korean phrase as `koDisplay`, one speech indicator/listen action, one primary record CTA, and vertical diagnostic feed.
3. Confirm the current generic failure/hero assertions fail.
4. Rebuild the screen with existing operations injected; use W5-A home confirm while recording/assessing.
5. Add the five localized messages and regenerate l10n.
6. Write the runbook with App Check debug-token verification, anonymous-auth gate, `AZURE_SPEECH_KEY` presence check without printing the secret, callable region, emulator/production distinction, and expected failure mapping.
7. Run both pronunciation test files and `flutter analyze --no-pub`.

**Commit:** `feat(pronunciation): expose actionable five-state diagnosis`

### Task 8: W5-B wave proof

Run focused suites after each stopped editing phase, then `git diff --check`, `flutter analyze --no-pub`, and the full Flutter suite without concurrent edits. Run `graphify update .`, review independent lifecycle/accessibility and persistence concerns, push, and prove current-head CI before merge.
