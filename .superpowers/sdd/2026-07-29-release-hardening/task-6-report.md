# Task 6 Report: Restore, English Book Analysis, and TTS Playback Rate

## Outcome

- Cloud restore now handles every field emitted by `buildBackupPayload` without
  blindly treating cursors or current streaks as cumulative counters.
- Book analysis carries the active app language as normalized `de` or `en`
  through `BookResultScreen`, `BookAnalysisService`, the HTTP request, the
  deterministic Python grammar path, and POS labels.
- Listening playback speed is request-local. Cached/cloud audio and OS TTS
  fallback receive the same composed effective rate, and overlapping requests
  never mutate the user's stored TTS preference.

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
  are preserved. Remote SRS must decode to an object; custom packs and bookshelf
  must decode to arrays.
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

- Result: 23 tests passed.

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
- Dart offline grammar output is German for `de` and explicit English fallback
  text for `en`.

`python -m unittest discover -s functions/analyze_korean_text -p "test_*.py"`

- Result: 4 tests passed.
- Covers normalization, German grammar output, English grammar fallback, and
  German/English POS labels.

The Python backend has no production LLM prompt. The brief's prompt wording was
therefore stale; the implemented production equivalent is the actual
deterministic regex grammar-output path. Existing pattern data contains only
German metadata, so English uses an explicit, German-free generic grammar name
and explanation until curated `name_en` / `explanation_en` entries are added.

### TTS RED

`flutter test test/tts_request_rate_test.dart` initially failed to compile
because the request-local playback engine and rate-composition API did not
exist.

### TTS GREEN

`flutter test test/tts_request_rate_test.dart`

- Result: 4 tests passed.
- Covers `base preference * request multiplier`, clamp range `0.1...1.0`,
  equal effective rate for file/fallback playback, rate-independent cache
  resolution, and overlapping `0.75x` / `1.25x` requests.
- The overlap case produced independent effective rates `0.30` and `0.50` from
  base `0.40`, while `Storage.ttsRate` remained `0.40`.

## Final Verification

- `flutter test test/cloud_sync_test.dart test/book_analysis_language_test.dart test/tts_request_rate_test.dart`
  - 30 tests passed.
- `python -m unittest discover -s functions/analyze_korean_text -p "test_*.py"`
  - 4 tests passed.
- `python -m py_compile functions/analyze_korean_text/main.py functions/analyze_korean_text/grammar_analysis.py functions/analyze_korean_text/test_main.py`
  - exit 0.
- `flutter analyze`
  - no issues found.
- `flutter test`
  - 624 tests passed.
- `git diff --check`
  - exit 0.

## Files Changed

- `.superpowers/sdd/2026-07-29-release-hardening/task-6-report.md`
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
- `ListeningScreen` contains no temporary `Storage.ttsRate` writes/restores.
- `BookResultScreen` reads locale in `didChangeDependencies`, not `initState`,
  and discards stale async results after a language change.
- No global UI locale is read inside `BookAnalysisService`; language is an
  explicit service input.
- No credentials or environment values were added.
- The release-hardening plan and ledger were not modified.
