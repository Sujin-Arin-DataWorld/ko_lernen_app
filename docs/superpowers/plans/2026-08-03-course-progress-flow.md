# Course Progress Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a course-mission grammar or small-talk checkpoint produce trustworthy concept evidence, while free browsing and passive study actions cannot unlock the next mission.

**Architecture:** Add an immutable route provenance value, `CoursePracticeContext`, created from a graph `ContentLink` when a learner opens practice from a course mission. Thread it through the reporter and mastery service; the service validates its exact graph link and only marks evidence eligible when its unit is still active. Grammar and small-talk screens use the context to scope their corpus to linked IDs, then emit evidence only after a scored checkpoint selection.

**Tech Stack:** Flutter/Dart, existing `CurriculumCatalog`, `CourseProgressService`, SharedPreferences-backed mastery state, Flutter unit/widget tests.

## Global Constraints

- Scope is learning-progress flow only: do not alter snapshot persistence, account/cloud sync, Firebase platform setup, home/practice information architecture, or unrelated localization cleanup.
- Preserve the existing unlock policy: every required concept and every declared scenario checkpoint must reach `CourseUnit.passThreshold` (currently 0.70); one correctly submitted checkpoint remains a valid 100% concept sample by current curriculum policy.
- Passive actions (screen view, flip, TTS, SRS easy/hard, wordbook save, guide/reply reveal) never call the evidence reporter.
- Keep direct library entry available. A null practice context is browse mode and cannot create grammar/small-talk course evidence.
- Keep source IDs stable and make dynamic grammar/small-talk mappings declare their target concepts explicitly; do not silently fan a single checkpoint out to every concept of a multi-concept unit.

---

### Task 1: Make route provenance and graph attribution testable

**Files:**

- Create: `lib/models/course_practice_context.dart`
- Modify: `lib/services/course_mission_navigation.dart`
- Modify: `lib/services/course_progress_service.dart`
- Modify: `lib/services/course_activity_reporter.dart`
- Modify: `lib/services/course_mastery_service.dart`
- Test: `test/course_mission_navigation_test.dart`
- Test: `test/course_mastery_test.dart`

**Interfaces:**

- Produces `CoursePracticeContext.fromLink(ContentLink)` with `courseUnitId`, `contentKind`, `initialContentId`, and `contentLinkId`.
- Adds optional `CoursePracticeContext? courseContext` to `recordContentAttempt` at reporter, serialized progress service, and mastery service boundaries.
- The mastery service validates `kind`, `contentId`, `contentLinkId`, course unit, and requested concept against the catalog. It records history under the context source unit, but sets `courseEligible` only when that unit is still active.

- [x] **Step 1: Write failing provenance tests**

```dart
final context = CoursePracticeContext.fromLink(grammarLink);
expect(destinationForCourseLink(grammarLink)!.arguments, context);

await service.recordContentAttempt(
  CurriculumContentKind.grammar,
  grammarLink.contentId,
  true,
  courseContext: context,
);
expect(service.snapshot.evidence.single.courseEligible, isTrue);
```

Add stale, mismatched-kind/content/link, and null-context cases. A stale or malformed context must never unlock a unit; null context retains legacy service behavior for existing games.

- [x] **Step 2: Run the focused tests and confirm RED**

Run: `flutter test --no-pub --concurrency=1 test/course_mission_navigation_test.dart test/course_mastery_test.dart`

Expected: compilation failure because `CoursePracticeContext` and the named parameter do not exist.

- [x] **Step 3: Implement the smallest trusted context path**

```dart
final activeLink = _contextLinkFor(
  allLinks,
  kind: kind,
  contentId: normalizedContentId,
  courseContext: courseContext,
);
final courseEligible = courseContext != null &&
    currentUnit?.id == courseContext.courseUnitId &&
    activeLink != null;
```

Do not trust a UI-supplied boolean. For a supplied context, reject malformed provenance instead of falling back to `_activeLinkFor`; for an absent context, retain the existing legacy path.

- [x] **Step 4: Run the focused tests and confirm GREEN**

Run: `flutter test --no-pub --concurrency=1 test/course_mission_navigation_test.dart test/course_mastery_test.dart`

Expected: all selected tests pass, including exact 0.69/0.70 boundary and stale-context no-unlock assertions.

### Task 2: Correct dynamic concept attribution before recording new checkpoints

**Files:**

- Modify: `assets/data/curriculum_manifest.json`
- Modify: `lib/services/curriculum_catalog.dart`
- Test: `test/course_graph_test.dart`

**Interfaces:**

- Extends semantic dynamic map parsing from a string unit ID to `{ "courseUnitId": "…", "conceptIds": ["…"] }` for grammar rules and small-talk categories.
- Each production grammar and small-talk dynamic mapping declares nonempty concept IDs that are required by its target unit.

- [x] **Step 1: Write a failing production-manifest attribution test**

```dart
expect(rule, isA<Map<String, dynamic>>());
expect(rule['conceptIds'], isA<List>().having((ids) => ids, isNotEmpty));
expect(link.conceptIds, orderedEquals(rule['conceptIds']));
```

Assert this for every raw `grammarRuleMap` and `smalltalkCategoryUnitMap` entry, and assert each declared concept belongs to the mapped `CourseUnit`.

- [x] **Step 2: Run the focused test and confirm RED**

Run: `flutter test --no-pub --concurrency=1 test/course_graph_test.dart`

Expected: failure because the production maps currently use unit-ID strings and the catalog defaults a missing concept list to all required concepts.

- [x] **Step 3: Implement explicit mappings and parser support**

Use a shared rule parser with an explicit concept list. Convert every production grammar rule and small-talk category mapping to an object. Grammar patterns receive one explicit `assess` concept; category maps remain `practice` scope only, while a separately Korean-reviewed phrase map supplies the few safe relationship `assess` checks. Keep the string parser solely for backward-compatible focused test fixtures.

- [x] **Step 4: Run the focused test and confirm GREEN**

Run: `flutter test --no-pub --concurrency=1 test/course_graph_test.dart`

Expected: catalog validation and the new explicit-attribution test pass without orphaning a required concept.

### Task 3: Add deterministic, scored grammar and small-talk checkpoints

**Files:**

- Create: `lib/services/course_checkpoint_questions.dart`
- Modify: `lib/screens/grammar_screen.dart`
- Modify: `lib/screens/smalltalk_screen.dart`
- Test: `test/course_checkpoint_questions_test.dart`
- Test: `test/course_mission_scope_test.dart`

**Interfaces:**

- `GrammarCheckpointQuestion.forGrammar(Grammar target, Iterable<Grammar> source)` returns a stable example-to-pattern multiple-choice question containing exactly one correct target ID.
- `SmalltalkRelationshipCheckpoint.forPhrase(SmalltalkPhrase phrase)` exposes the phrase's declared safe relationship; user selection is scored against it.
- `contentIdsForCourseContext(CurriculumCatalog catalog, CoursePracticeContext? context, CurriculumContentKind kind)` returns all and only the mission's linked IDs in mission mode, and `null` in library mode.

- [x] **Step 1: Write failing pure behavior tests**

```dart
expect(grammarQuestion.optionIds, contains(grammar.id));
expect(grammarQuestion.isCorrect(grammar.id), isTrue);
expect(smalltalkQuestion.isCorrect(phrase.relationshipContext), isTrue);
expect(scopeIds, containsAll(expectedMissionIds));
expect(scopeIds, isNot(contains(unrelatedId)));
```

Cover all production grammar rows and all small-talk phrases, so a later data edit cannot create a non-checkable card.

- [x] **Step 2: Run the focused test and confirm RED**

Run: `flutter test --no-pub --concurrency=1 test/course_checkpoint_questions_test.dart test/course_mission_scope_test.dart`

Expected: compilation failure because checkpoint generators and scoped-ID lookup do not exist.

- [x] **Step 3: Implement mission-mode rendering and single submission**

In each screen, load the catalog with the source corpus, retain a nullable context, and apply the scoped-ID filter before level/category/difficulty filters. In context mode, hide or constrain controls that could expose non-mission content. A checkpoint option calls the reporter once per card; show the correction/result after submission. Do not add reporter calls to existing passive callbacks.

- [x] **Step 4: Run focused checkpoint and screen tests**

Run: `flutter test --no-pub --concurrency=1 test/course_checkpoint_questions_test.dart test/course_mission_scope_test.dart test/course_mastery_test.dart`

Expected: grammar and small-talk context submissions generate one eligible evidence item; browse/null, stale, and passive flows generate none for these screens.

### Task 4: Wire the typed route and lock-rule regression suite

**Files:**

- Modify: `lib/main.dart`
- Modify: `test/course_mission_navigation_test.dart`
- Modify: `test/course_mastery_test.dart`
- Modify: `AGENTS.md`

**Interfaces:**

- `/grammar` and `/smalltalk` safely cast a `CoursePracticeContext` with the expected content kind; malformed/direct arguments enter browse mode.
- `GrammarScreen` and `SmalltalkScreen` have nullable `courseContext` constructors, preserving existing const library calls.

- [x] **Step 1: Write failing router and end-to-end unlock regression tests**

```dart
expect(courseContextFromRouteArguments(args, CurriculumContentKind.grammar),
       same(args));
expect(courseContextFromRouteArguments('a1_01', CurriculumContentKind.grammar),
       isNull);
```

Use a two-concept fixture with separately attributed grammar/small-talk evidence: 6/10 remains locked, 7/10 plus checkpoint 0.69 remains locked, and 7/10 plus 0.70 advances exactly one mission.

- [x] **Step 2: Run the focused tests and confirm RED**

Run: `flutter test --no-pub --concurrency=1 test/course_mission_navigation_test.dart test/course_mastery_test.dart`

Expected: router/context assertions fail before route wiring.

- [x] **Step 3: Wire `/grammar` and `/smalltalk`, then document the verified boundary**

Keep all direct/library routes backward compatible. Record the scope, trusted-context rule, passive-action rule, tests run, and any remaining Korean-speaker content-QA boundary in the current `AGENTS.md` session log.

- [x] **Step 4: Verify the completed change (focused regression + static analysis)**

Run:

```powershell
dart analyze --fatal-infos
flutter test --no-pub --concurrency=1 test/course_mission_navigation_test.dart test/course_checkpoint_questions_test.dart test/course_graph_test.dart test/course_mastery_test.dart test/course_practice_screen_test.dart
git diff --check
```

The focused regression set passed 48 tests and static analysis had no issues. A later serial whole-repository `flutter test` run was deliberately stopped after the Flutter compiler made no progress after unrelated account tests; it is not claimed as a green result. Re-run that broad gate in a clean, non-concurrent session before release. The focused tests prove linked IDs, passive-study non-advancement, correction state, and the 70% + scenario-checkpoint boundary; debug-device navigation remains a release-smoke follow-up rather than a claimed completion.
