# Small Talk and Listening Topic Learning Implementation Plan

> For agentic workers: execute the approved conversation spec with superpowers:subagent-driven-development. Do not commit, push, or delete this workspace.

**Goal:** Topic lessons, relevant exercises, durable resume, and independent per-level daily targets for Small Talk and Listening.

**Architecture:** Authored immutable lesson catalogs feed a common local-first progress service. Dedicated hubs and a lesson player use existing Sori components and speech. Today and settings expose the same progress; cloud/account/reset flows include it.

**Spec:** User-approved plan in this task dated 2026-09-22; decisions below retain its complete product contract.

## Global constraints

- Each content retains its own topic packs. All lessons remain accessible.
- Goals are per content and CEFR level, 1/2/3 lessons or free browse (0); configure on first entry and edit in settings/hub.
- Completion means all practice attempted, regardless of accuracy; misses remain reviewable. Listening alone never completes practice.
- Small Talk authored lessons cap at 6/6/5/5/4/4 expressions by A1..C2, include every expression plus one situation question. Theme park A1 uses 4/4/2 grouping.
- Listening is one scenario per lesson, four exercise skills: situation, meaning, sentence, response. Evidence/explanations stay source-grounded. Extra roleplay/grammar remains optional.
- Daily selection is persisted on explicit start, never changes on read/restart, carries no backlog, counts a lesson's first completion once, and allows extra study without increasing the goal.
- Resume learns at content ID, listening line, practice question. Existing completion/reward history is not fabricated into assessed mastery. No new course/Hanok credit from browsing.
- Preserve Korean meaning and independent DE/EN phrasing; never infer a sole valid audience from relationship metadata. No new TTS recordings are required: reuse source Korean audio.
- Storage errors are retryable. Account reset invalidates outstanding operations. Cloud backup/restore/reconciliation/deletion includes new records.
- Remove old listening vignette fallback and scroll copy, retain current listening card art.
- Finite learning, practice, result and goal-selection screens share a viewport-filling layout: body in the available middle area, actions near the bottom, natural scrolling only when content or enlarged text needs it. Use actual constraints, not device identity; preserve system text scaling.

## Catalog contract (owned independently per content)

Files: `assets/data/smalltalk_lessons.json`, `assets/data/listening_lessons.json`.

```json
{"version":1,"lessons":[{"id":"smalltalk.a1.mood.01","kind":"smalltalk","level":"a1","topicId":"mood","title":{"ko":"","de":"","en":""},"intro":{"ko":"","de":"","en":""},"contentIds":["smalltalk_a1_0003"],"questions":[{"id":"unique-stable-id","type":"choice","skill":"situation","prompt":{"ko":"","de":"","en":""},"options":[{"ko":"","de":"","en":""}],"correctIndex":0,"explanation":{"ko":"","de":"","en":""},"sourceIds":["smalltalk_a1_0003"],"audioKo":"","evidenceKo":""}]}]}
```

All strings in examples above must be authored, not empty placeholders in real files. `type` is `choice` or `order`; order questions use `targetKo` instead of options/correctIndex. `audioKo` and `evidenceKo` are optional exact source utterances. Each question has stable ID, localized prompt/explanation, skill, sourceIds. Listening contentIds/sourceIds reference the scenario ID and topicId is its shelf. Correct choice order may be shuffled in the player while retaining answer identity. Preserve original Korean and IDs. Five verified Small Talk DE/EN meaning corrections may also update the source display, with a QA change log.

## Task boundaries and interfaces

- [x] 1. Small Talk catalog: author all topic lessons and grounded questions, validate IDs/coverage/caps/translations; own its JSON and Python validation/authoring support only.
- [x] 2. Listening catalog: all 178 scenarios, four skills each, exact dialogue evidence and sound options; own its JSON and Python validation/authoring support only.
- [x] 3. Core models/service: `lib/features/content_learning/content_learning_models.dart`, `content_learning_catalog.dart`, `content_learning_service.dart`; root owns Storage/cloud/account integration and service tests.
- [x] 4. UI: `lib/features/content_learning/content_learning_hub.dart`, `content_lesson_screen.dart`, `content_learning_widgets.dart`; UI worker owns routes/settings/Today UI/ARB and widget tests. Coordinate shared snapshot changes with root.
- [x] 5. Independent content and code review, scoped tests, all required guards/analyze/build and phone/tablet DE/EN visual verification; Graphify update last.

### Core API (root supplies)

`enum LearningContentKind { smalltalk, listening }` and `enum ContentLessonPhase { learn, practice, complete }`.
`ContentLesson`: id, kind, level, topicId, title/intro (`LocalizedText`), contentIds (`List<String>`), questions (`List<ContentLessonQuestion>`).
`ContentLessonQuestion`: id, type, skill, prompt/explanation (`LocalizedText`), options (`List<LocalizedText>`), correctIndex, sourceIds, audioKo/evidenceKo/targetKo (`String`).
`ContentLearningCatalog.load(kind)` => `Future<List<ContentLesson>>`; `reset()` for tests.
`ContentLearningService` static API: `changes` ValueNotifier<int>; `goal(kind, level)` => int?; `setGoal(kind,level,int)` => Future<void>; `progress(lessonId)` => `ContentLessonProgress`; `startLesson(lesson, List<ContentLesson> scope)` => Future<void>; `savePosition(lesson, phase, int position)` => Future<void>; `answer(lesson, questionId, bool correct)` => Future<void>; `finish(lesson)` => Future<void>; `daily(kind,level)` => `ContentDailyProgress`; `beginReview(lesson, {bool mistakesOnly=false})` => Future<void>.
`ContentLessonProgress`: phase, position, seenIds, answers (`Map<String,bool>`), missedQuestionIds (`Set<String>`), completed (`bool`), reviewMode (`bool`), practiceQuestionIds (`List<String>`), lastUpdatedAt. `ContentDailyProgress`: target, lessonIds, completedIds, completedCount, isComplete; `activeDaily()` => list of records with kind and level (read only).
All mutation calls serialize and persist before returning; caller awaits before moving. Goal zero is free browse. First learning completion is monotonic, while review answers can clear missedQuestionIds without adding a daily completion. `startLesson` doesn't reset in-progress work and selects same-topic then same-level eligible lessons once. Explicit review resets only the current review queue. Never call finish on an incomplete queue.

### Verification commands

```powershell
flutter test test/content_learning_service_test.dart test/content_learning_catalog_test.dart test/content_learning_ui_test.dart
flutter analyze --no-pub
git diff --check
```

Add focused account/cloud roundtrip/reset failure tests, existing listening/smalltalk/course/Today regression tests, content validation, and rendered phone/tablet checks. No user data, commits, pushes, or remote deployment are part of this task.

Layout regression coverage uses real fonts in DE/EN at 390x844, 1024x768 and 1024x1366. Short learning/practice/result/goal screens must fit a viewport and keep their primary action in its lower area. German at 200% text scale on 320x640 must retain reachable source and goal actions without clipping.
