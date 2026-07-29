# Task 6 Report: Restore, English Book Analysis, and TTS Playback Rate

## Outcome

- Cloud restore now handles every field emitted by `buildBackupPayload` without
  blindly treating cursors or current streaks as cumulative counters.
- Book analysis carries the active app language as normalized `de` or `en`
  through `BookResultScreen`, `BookAnalysisService`, the HTTP request, the
  deterministic Python grammar path, and POS labels.
- Listening playback speed is request-local. OS speech keeps its `0.1...1.0`
  rate scale, while cached/cloud audio maps the stored default `0.42` to
  platform-neutral `1.0x` and clamps to the Apple-supported `0.5...2.0`.
  Overlapping requests never mutate the user's stored TTS preference.

## Restore Field Audit

The backup payload currently emits 23 restore fields:

- `vok`: `correct`, `wrong`, `skipped`, `last_idx`, `seen_ids`
- `chosung`: `correct`, `wrong`
- `wordle`: `wins`, `losses`, `streak`, `best_streak`
- `grammar`: `last_idx`, `seen`
- `app`: `last_open`, `streak_days`, `best_streak`
- `progress`: `xp`, `level`, `earned_stamps`, `quest_completions`
- top level: `srs_json`, `custom_packs_json`, `bookshelf_json`

Policies implemented and tested:

- Max-merge cumulative totals: all vocabulary counters, both Chosung counters,
  Wordle wins/losses, XP, Wordle best streak, and app best streak.
- Vocabulary and grammar cursors restore only when their local domain is
  uninitialized.
- Wordle current streak restores only when the local Wordle domain is
  uninitialized; totals and best streak still max-merge.
- App current streak follows the newer valid `last_open`. A same-date merge
  deterministically keeps the larger current streak. Malformed dates do not
  clobber local state.
- Restoring a current Wordle/app streak also maintains
  `best_streak >= current streak` for partial older backups.
- Lists/maps merge by union or missing-key addition. Nonempty local JSON models
  are preserved. Remote SRS, custom packs, and bookshelf data must decode to
  objects. The latter two are ID-keyed maps in their production services.
- A restored level is trimmed, lowercased, and accepted only when it is one of
  `a1`, `a2`, `b1`, or `b2`.
- Quest completions accept only strict UTC timestamps in the exact ISO form
  emitted by local backup. Overflow dates/times and offset timestamps are
  rejected by component round-trip validation.
- Unsupported legacy types, negative counters, malformed dates/timestamps, and
  invalid structured JSON are ignored without a type crash.

## TDD Evidence

### Restore RED

`flutter test test/cloud_sync_test.dart` initially failed as expected:

- lower remote vocabulary totals overwrote higher local totals;
- Chosung wrong, all Wordle values, and all app streak values were omitted;
- vocabulary/grammar cursors overwrote initialized local cursors;
- fresh-device round-trip failed on omitted fields;
- malformed values threw `type 'String' is not a subtype of type 'int'`;
- later focused RED cases showed `current > best` for partial backups and
  invalid structured JSON being persisted.

### Restore GREEN

`flutter test test/cloud_sync_test.dart`

- Initial result: 23 tests passed before review remediation.

### Language RED

- Dart test compilation showed the missing analyzer/client seams and target
  language normalizer.
- Python tests showed that `detect_grammar` accepted no language and that no
  dependency-free language module existed.
- The POS regression test initially failed because no localized POS helper
  existed.

### Language GREEN

`flutter test test/book_analysis_language_test.dart`

- Result: 3 tests passed.
- An English `BookResultScreen` request was observed at the service boundary as
  `{"text":"공부하고 있어요.","lang":"en"}`.
- Dart offline grammar output is German for `de` and uses curated English
  meanings for `en`.

`python -m unittest discover -s functions/analyze_korean_text -p "test_*.py"`

- Initial result: 4 tests passed before review remediation.
- Covers normalization, German grammar output, English grammar fallback, and
  German/English POS labels.

The Python backend has no production LLM prompt. The implemented production
equivalent is the deterministic regex grammar-output path. Both byte-identical
pattern datasets now contain curated `name_en` and `explanation_en` content for
all 31 rules; generic fallback remains only as defensive handling for genuinely
missing future metadata.

### TTS RED

`flutter test test/tts_request_rate_test.dart` initially failed to compile
because the request-local playback engine and rate-composition API did not
exist.

### TTS GREEN

`flutter test test/tts_request_rate_test.dart`

- Initial result: 4 tests passed before review remediation. That first model
  incorrectly reused the OS rate scale for file playback and was superseded by
  the explicit rate-pair coordinator described below.

## Review Remediation TDD Evidence

### RED

- Production-shaped restore round-trip:
  `flutter test test/cloud_sync_test.dart --plain-name "production custom-pack and bookshelf services round-trip through backup"`
  failed because `CustomPackService.getById(...)` returned `null`.
- Latest-request TTS adapter:
  `flutter test test/tts_request_rate_test.dart --plain-name "older slow resolution performs no mutations after newer starts"`
  failed to compile because the generation-aware platform/session API did not
  yet exist.
- Locale quota race:
  `flutter test test/book_analysis_language_test.dart --plain-name "two successful locale requests both consume quota and only newest renders"`
  reported `Actual: 1`, `Expected: 2`.
- Curated English:
  `python -m unittest functions/analyze_korean_text/test_main.py` failed with
  missing `name_en` and returned `Korean grammar (g_progressive)` instead of
  the rule meaning.
- Independent English review distinctions were added test-first; the targeted
  test failed against the not-yet-synchronized function dataset before the
  corrected asset dataset was copied across.

### GREEN

- Restore validates production map shapes and round-trips objects through
  `CustomPackService` and `BookshelfService`. Supported levels and strict UTC
  quest timestamps have dedicated tests.
- `TtsPlaybackRates` preserves the OS scale and maps default `0.42` to file
  `1.0x`; `0.75` and `1.25` request multipliers have equivalent semantics on
  both paths. File rate is clamped to `0.5...2.0`.
- File playback calls `play` before `setPlaybackRate`. A rate-setting failure
  falls back to OS speech only after cleanup succeeds; cleanup failure returns
  false and never starts a potentially overlapping voice.
- The coordinator serializes shared platform start/stop mutations, invalidates
  pending work on every newer request and on `stop`/`dispose`, and prevents a
  slow older resolution from performing any platform mutation.
- Cache resolution remains keyed only by voice and text, independent of rate.
- Both successful locale requests increment quota before stale UI results are
  discarded; only the latest response is rendered.
- Both grammar JSON files are byte-identical and contain distinct curated
  English content for all 31 rules, including reviewed attributive, indirect
  quotation, `-하고`, `-(으)ㄹ까요`, `-(으)니까`, `너무`, and location
  particle `-에` distinctions.
- Python deployment documentation now points to the supported gcloud Gen2
  source-directory runbook and no longer claims a nonexistent Firebase
  codebase target.

## Async Playback and Lifecycle Remediation

### RED

- The async failure suite reproduced uncaught file-start, rate-cleanup, file
  completion, speech completion, and platform stop/start errors.
- The unsafe cleanup case initially returned `true` through OS fallback even
  though file playback cleanup had failed.
- A resolver exception returned before OS fallback could start.
- Lifecycle tests initially failed to compile because no injectable completion
  timeout existed. The prior request also remained blocked in `resolveFile`
  after `stop`/`dispose`, and a replacement request did not stop audible audio
  until its own resolution completed.

### GREEN

- Production `_startFile` awaits the asynchronous file-start helper, so play
  errors are caught. `TtsFilePlayback` returns `null` only after successful
  cleanup and returns a false session when cleanup is unsafe.
- Only an explicit `null` file-start result permits OS fallback. A thrown start
  returns false because it may represent partially started playback.
- New requests enqueue a serialized stop immediately, before cache/network
  resolution finishes. Request cancellation races the wrapped resolver, so
  replacement, `stop`, and `dispose` settle pending calls promptly while late
  resolver errors remain handled.
- File and speech completion errors resolve false. One engine-owned bounded
  timeout reports an error, resolves false, and serially stops playback only if
  that request is still current; stale timeout cleanup cannot stop newer audio.
- The serialization tail handles early stop errors immediately and remains
  healthy for subsequent requests.

## Final Verification

- `flutter test test/cloud_sync_test.dart test/book_analysis_language_test.dart test/tts_request_rate_test.dart`
  - 51 tests passed.
- `flutter test test/tts_request_rate_test.dart test/account_cleanup_test.dart test/account_hardening_test.dart`
  - 52 tests passed.
- `flutter test test/tts_request_rate_test.dart`
  - 21 tests passed.
- `python -m unittest discover -s functions/analyze_korean_text -p "test_*.py"`
  - 6 tests passed.
- `python -m py_compile functions/analyze_korean_text/main.py functions/analyze_korean_text/grammar_analysis.py functions/analyze_korean_text/test_main.py`
  - exit 0.
- `flutter analyze`
  - no issues found.
- `flutter test`
  - 645 tests passed.
- `git diff --check`
  - exit 0.

## Files Changed

- `.superpowers/sdd/2026-07-29-release-hardening/task-6-report.md`
- `assets/data/grammar_patterns.json`
- `functions/analyze_korean_text/grammar_patterns.json`
- `functions/analyze_korean_text/grammar_analysis.py`
- `functions/analyze_korean_text/main.py`
- `functions/analyze_korean_text/test_main.py`
- `lib/screens/book_result_screen.dart`
- `lib/screens/listening_screen.dart`
- `lib/services/book_analysis_service.dart`
- `lib/services/cloud_sync.dart`
- `lib/services/storage_service.dart`
- `lib/services/tts_service.dart`
- `test/book_analysis_language_test.dart`
- `test/cloud_sync_test.dart`
- `test/tts_request_rate_test.dart`

## Self-Review

- No Task 1-5 behavior was intentionally changed.
- Task 5 `clearCache` / `clearCacheStrict` APIs and failure semantics remain
  intact.
- TTS cache identity remains `sha1("$voice|$text")`; playback rate is not part
  of resolution or generation.
- `audioplayers` file mutation order is `play` then `setPlaybackRate`, with
  explicit cleanup and safe-only fallback on rate failure.
- Public TTS playback methods retain the bool-failure contract for asynchronous
  platform, resolver, completion, and timeout failures.
- `ListeningScreen` contains no temporary `Storage.ttsRate` writes/restores.
- `BookResultScreen` reads locale in `didChangeDependencies`, not `initState`,
  and discards stale async results after a language change.
- No global UI locale is read inside `BookAnalysisService`; language is an
  explicit service input.
- No credentials or environment values were added.
- The release-hardening plan and ledger were not modified.
