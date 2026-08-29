# W5-C 내 단어 허브와 시나리오 인트로 Implementation Plan

> **REQUIRED SUB-SKILL:** Use `superpowers:executing-plans` to execute this plan task by task in the current Codex thread.

**Goal:** bookshelf/search/difficult-word 진입점을 `/my_words`의 탭 허브로 통합하면서 이전 route 호환성을 보존하고, 시나리오 인트로를 비디오 없이 결정적 정적 아트와 첫 대사 prefetch로 바꾼다.

**Architecture:** 기존 세 화면의 본문을 embeddable public widget으로 추출하고 route wrapper는 새 허브의 initial tab으로 위임한다. activity catalog는 route ownership을 명시해 별칭이 중복 활동으로 집계되지 않게 한다. 인트로 crop seed는 안정적 FNV-1a로 계산하며 `courseUnitId`를 우선 사용한다.

**Tech Stack:** Flutter, Dart, generated l10n, route/catalog contract tests, Sori speech/cache policy.

**Spec:** `docs/superpowers/specs/2026-08-28-w4-w6-completion-design.md` §7.3 plus the route compatibility rules in §§4 and 13.

## Global Constraints

- Start from fresh main after W5-B merge.
- Preserve `/bookshelf`, `/wordbook/search`, and `/hard_words` route names and `RouteSettings.name` behavior.
- The canonical consolidated route is `/my_words`; there is no `/word_search` invention.
- Catalog route ownership is unique; alias launchers do not count as separate canonical activities.
- Scenario intro contains no `SoriPosterLoop` or video branch.
- Crop/focal selection is stable across processes and Dart versions; do not use `String.hashCode`.
- Prefetch is best-effort and must never block entering the scenario.

### Task 1: extract three reusable My Words bodies

**Files:**

- Modify: `lib/screens/bookshelf_screen.dart`
- Modify: `lib/screens/wordbook_search_screen.dart`
- Modify: `lib/screens/hard_words_screen.dart`
- Modify: existing bookshelf, word-search, and hard-word widget tests

**Public widgets:**

```dart
class BookshelfBody extends StatelessWidget { ... }
class WordbookSearchBody extends StatelessWidget { ... }
class HardWordsBody extends StatelessWidget { ... }
```

Each body owns content state but not top-level route chrome. Existing screen classes remain public wrappers and render the corresponding body without changing storage/service behavior.

**TDD steps:**

1. Add tests that each body can render under a supplied Scaffold/TabBarView and retains its current empty/loading/content/error behavior.
2. Add wrapper tests proving the old screen classes still expose the expected route-specific semantics and navigation.
3. Extract without changing internal service calls, then run the three existing screen suites.

**Commit:** `refactor(words): expose embeddable shelf search and difficult bodies`

### Task 2: create `/my_words` tab hub and preserve aliases

**Files:**

- Create: `lib/screens/my_words_screen.dart`
- Modify: `lib/main.dart`
- Modify: `lib/l10n/app_de.arb`
- Modify: `lib/l10n/app_en.arb`
- Regenerate: `lib/l10n/generated/app_localizations*.dart`
- Create: `test/my_words_screen_test.dart`
- Modify: main route contract tests

**Interface:**

```dart
enum MyWordsTab { search, shelf, difficult }

class MyWordsScreen extends StatelessWidget {
  const MyWordsScreen({
    this.initialTab = MyWordsTab.search,
    super.key,
  });
}
```

The three localized tabs are Suchen/Search, Regal/Shelf, and Schwierig/Difficult. The `+ Foto` action opens a sheet with existing `/book` and `/vocab_notebook` destinations.

**Route mapping:** `/my_words` → search; `/wordbook/search` → search; `/bookshelf` → shelf; `/hard_words` → difficult. Every alias returns a `MyWordsScreen` with the matching `initialTab` while retaining the incoming `RouteSettings`.

**TDD steps:**

1. Add tab preselection, keyboard traversal, text-scale 2.0, 360×640, and `+ Foto` destination tests.
2. Add route tests for all four names and back-stack behavior.
3. Confirm `/my_words` is absent before implementation.
4. Implement the hub, localize labels, regenerate l10n, and replace route builders with explicit initial-tab mappings.
5. Run `flutter test --no-pub test/my_words_screen_test.dart` and all main route contract tests.

**Commit:** `feat(words): consolidate vocabulary tools in My Words hub`

### Task 3: unique activity route ownership and launcher migration

**Files:**

- Modify: `lib/data/sori_activity_catalog.dart`
- Modify: `lib/screens/custom_pack_quiz_screen.dart`
- Modify: `lib/screens/custom_pack_matching_screen.dart`
- Modify: `lib/screens/custom_pack_typing_screen.dart`
- Modify: `test/sori_activity_catalog_test.dart`
- Modify: discover/practice hub tests

**Model change:** add `ownsRoute` with default `true` to the activity catalog entry model. `activityForRoute` ignores entries where `ownsRoute == false`. The custom quiz/matching/typing launchers set `ownsRoute: false` and navigate back to `/my_words`; one My Words entry owns `/my_words`.

**Catalog result:** remove canonical entries for `hard_words`, `book_capture`, `bookshelf`, and `word_search`; add one `my_words` entry. Learn activities become exactly 13. Detail aliases remain routable but are not duplicated in canonical discovery.

**TDD steps:**

1. Add tests for exactly 13 learn activities, exactly one owner per owned route, no duplicate owner, aliases excluded from route lookup, and all visible activities launch a registered route.
2. Confirm the current 16-entry catalog fails.
3. Implement `ownsRoute`, update catalog entries, and migrate three custom-pack completion/navigation targets.
4. Run catalog, bookshelf, discovery, practice-hub, and custom-pack route tests.

**Commit:** `refactor(catalog): assign My Words sole canonical route ownership`

### Task 4: deterministic non-video scenario intro art

**Files:**

- Modify: `lib/screens/scenario_player_screen.dart`
- Modify: scenario intro widget tests
- Verify: `test/scenario_srs_persistence_flow_test.dart`
- Verify: `test/scenario_can_do_result_flow_test.dart`

**Stable seed:** use `scenario.courseUnitId` when nonempty, otherwise `scenario.id`. Implement a pure 32-bit FNV-1a function over UTF-8 bytes and derive crop alignment/focal variant from the unsigned result. This keeps `introduce_yourself` and `a1_kpop_my_bias` aligned when they share `a1_02_self_intro_identity`.

**TDD steps:**

1. Add fixed-vector unit tests for FNV-1a and widget tests proving the same scenario produces identical crop across rebuilds.
2. Add a shared-course-unit test proving the two self-introduction variants use the same alignment.
3. Add a source guard proving `_ScenarioIntroArt` has no `SoriPosterLoop`, `loopAsset`, or video controller branch.
4. Confirm current intro violates the guard.
5. Render only the resolved static scene asset/fallback with deterministic alignment and text-safe overlay.
6. Run intro, scenario route, SRS, and can-do tests.

**Commit:** `refactor(scenarios): make intro art static and deterministic`

### Task 5: prefetch the first dialog line during intro dwell

**Files:**

- Modify: `lib/screens/scenario_player_screen.dart`
- Reuse: `lib/widgets/sori/speakable.dart`
- Reuse: current TTS cache/voice policy services
- Modify: scenario intro audio tests

**Contract:** while the intro is mounted, prefetch exactly the first dialog line. Use female voice when the first speaker is the user and male otherwise, matching the existing `TtsVoicePolicy`. Deduplicate by cache key, contain all errors, never autoplay during prefetch, and never delay the Begin action.

**TDD steps:**

1. Inject a prefetch seam and test exact text/voice/cache-key selection, one call across rebuild, cancellation/late completion after dispose, and fail-soft Begin navigation.
2. Confirm current intro does not prefetch.
3. Start prefetch from intro initialization after scenario resolution; do not add a second cache implementation.
4. Run scenario intro and content-audio policy tests.

**Commit:** `perf(scenarios): prefetch first dialog audio during intro`

### Task 6: W5-C wave proof and Spiele journey audit

Run all My Words/catalog/route/scenario intro tests, then `git diff --check`, `flutter analyze --no-pub`, and the full suite with no concurrent edits. Audit Spiele 1–12 through automated route/semantic tests, record only genuinely automated outcomes in the PR, run `graphify update .`, push, prove exact-head CI, and merge after success. Device crop/gesture/audio-feel remain in Jin's final checklist.
