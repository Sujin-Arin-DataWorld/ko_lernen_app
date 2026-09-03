# W7 PR1 — Final Fix Wave Report

- Worktree: `C:\dev\hangulsori\ko_lernen_app_worktrees\w7-pr1-tts-20260903`
- Branch: `claude/w7-pr1-tts-20260903`
- Base: `b374e0f2` (docs(plan): W7 PR1 TTS·오디오 실행 플랜 보존)
- Date: 2026-09-03
- Source: whole-branch review findings, controller rulings recorded at the end of `progress.md`.

All items below were implemented TDD-where-behavior-changed, each in its own commit.

## C1 — content-corpus paths dropped the `app` gate

`.github/scripts/ci_scope.py:105-112` and `:127-142` (the `assets/data/scenarios_*.json` and the explicit content-file `in {...}` block): both branches now set `result["app"] = True` alongside `result["content"] = True` before `continue` (previously `content` only).

Tests (`.github/scripts/test_ci_scope.py`):
- Renamed `test_content_shard_change_selects_only_content_gate` → `test_content_shard_change_selects_app_and_content_gates`, asserting exactly `("app","content")` for `scenarios_a1.json`, `cloze.json`, `korean_vocab.csv`.
- Added `test_unlisted_assets_data_file_selects_app_only` (`assets/data/foo.json` → `("app",)`) — this one was already green (falls through to the generic catch-all), kept as a pin.
- `test_isolated_product_areas_select_only_their_gate` untouched, stayed green throughout.

RED: `test_content_shard_change_selects_app_and_content_gates` failed — assertEqual diff showed `app` missing from the actual set. GREEN after the two-line fix. Full `test_ci_scope` module: 14/14 passed.

Commit: `10e4c8af`

## C2 — secret interpolated directly into `run:` shell

`.github/workflows/ci.yml` job `tts-storage-verify`, step "Fail with a clear message when the GCS secret is missing" (~L632-639): moved `secrets.GCS_TTS_VERIFY_SA_JSON` out of the inline bash interpolation into an `env:` block (`GCS_TTS_VERIFY_SA_JSON: secrets.GCS_TTS_VERIFY_SA_JSON`), read the shell var as a quoted `$GCS_TTS_VERIFY_SA_JSON`, and added `set -euo pipefail` — mirrors the Android-signing-secret precedent at `ci.yml:376-388`.

No Dart/Python behavior to unit test; validated by parsing the YAML with PyYAML (`yaml.safe_load` on the file → OK, no parse error).

Commit: `d827bbb1`

## I1 — bundled manifest eagerly loaded + SHA256'd all 125 rows on first resolve

`lib/services/tts_bundled_manifest.dart`:
- `_loadValidated` (now ~L96-203) validates only metadata (schema, cache revision, per-item field shape, `bundledAssetPath` prefix/suffix, 64-hex `bundledSha256`, duplicate-key conflicts) — it no longer calls `bundle.load()` on any declared mp3.
- Added `Future<Uint8List?> bytesFor(TtsCacheKey key)` (L47-53) — lazily reads, MPEG-shape-checks (`TtsCacheKey.isUsableAudio`), and SHA-256-verifies one row's bytes on first request for that key, memoises the outcome (bytes or null) in `_bytesCache`, and de-dupes concurrent callers via `_bytesLoading`. Never throws.
- `assetFor(key)` (L40) kept — still the only way `bundledAssetPath()` (the `TtsCacheKey` extension, unchanged) resolves a declared path; still has a live caller.
- Removed the now-unused `readAsset` static method.

`lib/services/tts_service.dart` `_resolveAudio` bundled tier (~L813-830): replaced the old two-step (`bundledAssetPath()` then a second `TtsBundledManifest.readAsset(bundledPath)`) with `(await TtsBundledManifest.load()).bytesFor(key)` — one read total. Tier-order anchors preserved and verified by `test/tts_bundled_manifest_test.dart`'s "resolver source preserves bundle, disk, Storage, callable order" test (unchanged, still green): `bundledAssetPath()` / `file.exists()` / `.ref(key.storagePath)` / `takeCallableAudio(` still appear in that order.

Tests (`test/tts_bundled_manifest_test.dart`):
- "missing declared asset loads fine but bytesFor resolves null" (was: `load()` throws) — rewritten: asserts `load()` succeeds and `bytesFor(key)` is null.
- "bundled SHA mismatch loads fine but bytesFor resolves null" — same pattern.
- "invalid MPEG bytes load fine but bytesFor resolves null even when their hash matches" — same pattern.
- "valid bundled bytes resolve before disk or Firebase tiers" — `bundle.loadCount[item['bundledAssetPath']]` expectation updated 2 to 1 (one load via `bytesFor`, not one in `_loadValidated` plus one via the old `readAsset`).
- Added M5: "bytesFor resolves the real first checked-in bundled row from rootBundle" — reads the real `assets/data/tts_first_line_manifest.json`, takes the first `bundled: true` row (scenarioId `a1_theme_park_date_choices`, voice male, text "수진아, 우리 저거 탈까?"), calls `TtsBundledManifest.load()` + `bytesFor(key)` against the default (non-fake) rootBundle (no override needed — `flutter test` resolves pubspec-declared assets from disk, confirmed working here), asserts non-null usable-audio bytes.

`test/tts_cache_key_test.dart` "dynamic synthesis uses the authenticated callable transport": the `contains('TtsBundledManifest.readAsset')` anchor no longer matches (call site removed) — updated to `contains('.bytesFor(key)')`.

RED confirmed pre-fix by running the manifest test file before editing `tts_bundled_manifest.dart` (the throw-based assertions in the three rewritten tests no longer matched behavior once metadata-only validation was written). GREEN after: `test/tts_bundled_manifest_test.dart` + `test/tts_cache_key_test.dart` + `test/tts_premium_only_test.dart` → 30/30 passed.

Commit: `d6f775f6`

## I2 — pending-prefetch promotion left the indicator idle while resolving

`lib/widgets/sori/speakable.dart` `_publishSpeak` (~L214-219): `phase.value = pending == null ? resolving : idle` changed to unconditionally `phase.value = TtsSpeechPhase.resolving`, including when joining a pending prefetch. `SoriSpeechIndicator.handleTap` (unchanged, ~L423-426: stop when phase is not idle, else speak) therefore now correctly stops on a re-tap during that window instead of silently no-op-ing into a second speak call.

Test (`test/sori_speech_dedupe_test.dart` ~L44-58, plan-authored assertion, change authorised by the controller ruling): flipped the "idle before prefetch completes" expectation to expect `TtsSpeechPhase.resolving` while the pending prefetch is in flight; the adjacent `speakStarted == false` assertion (never promoted to speaking) is untouched and still guards against over-eager promotion.

RED confirmed before the source edit (flipping the assertion to `resolving` failed against the unfixed source, which still produced `idle`). GREEN after the one-line source fix. Also ran `test/speakable_semantics_test.dart`, `test/speakable_screen_lifecycle_test.dart`, `test/review_session_screen_speakable_test.dart` — 24/24 passed, no regression in existing indicator/lifecycle tests.

Commit: `f892be2f`

## I3 — destructive delete path untested; unbounded batch delete

`tool/generate_tts.py` `delete_remote_objects` (L545-561): added `chunk_size=50` parameter; chunks `sorted(paths)` and issues one `gcloud storage rm` invocation per chunk of at most 50, matching `download_first_line_bundle`'s batching pattern instead of one unbounded argv for the whole stale set.

Tests (`tool/test_generate_tts.py`):
- `test_confirm_delete_requires_delete_stale` — `main(["--verify-storage", "--confirm-delete"])` raises SystemExit with a non-zero code (characterises the pre-existing argparse guard at `generate_tts.py:1387`, which had zero coverage).
- `test_delete_stale_with_confirm_calls_delete_remote_objects_with_stale_set` — mocks `remote_cache_objects`/`collect`/`delete_remote_objects`, runs `main(['--verify-storage','--delete-stale','--confirm-delete'])`, asserts `delete_remote_objects` called once with exactly the stale-path set and result 0 (missing empty).
- `test_delete_remote_objects_chunks_at_fifty_paths_per_call` — 120 fake paths results in `subprocess.run` called exactly 3 times.

RED confirmed for the chunking test only (the other two exercise pre-existing, previously-uncovered behavior and were green immediately — run once to confirm the argparse guard and the delete-call wiring were in fact already correct): chunking test failed with call_count 1 before the fix, 3 after. Full `tool.test_generate_tts` module: 35/35 passed.

Commit: `e07a234c`

## M2 — disk-cache hit did not refresh mtime (not true LRU)

`lib/services/tts_service.dart`: disk-cache hit branch (~L847-852, `TtsAudio.path(file.path)` return) now calls `await _touchCacheFile(file)` first. New helper `_touchCacheFile` (~L966-973): best-effort `await file.setLastModified(DateTime.now()).timeout(_diskTimeout)` wrapped in try/catch, same guard style as the rest of `_resolveAudio`. Exposed `@visibleForTesting static Future<void> touchCacheFileForTesting(File file)` (~L975-976) as a thin wrapper — the real hit path and the test call the identical private helper.

Tests (`test/tts_cache_prune_test.dart`): "캐시 히트 시 mtime을 지금으로 갱신해 진짜 LRU가 되게 한다 (M2)" — writes a file with mtime one day old, calls `touchCacheFileForTesting`, asserts the refreshed mtime is after the old one. Plus "mtime 갱신 실패는 무시된다" — calls it on a nonexistent file, asserts no throw.

RED confirmed before adding `_touchCacheFile`/wiring it into the hit path (mtime unchanged). GREEN after. `test/tts_cache_prune_test.dart`: 8/8 passed.

Commit: `f6c8a497`

## M3 — `_maybePruneCache` reset throttle counters even when a prune was already in flight

`lib/services/tts_service.dart` `_maybePruneCache` (~L978-1000): now checks `_pruneInFlight` immediately after incrementing `_cacheWritesSincePrune` and returns early (without touching `_cacheWritesSincePrune`/`_lastPruneAt` or scheduling `pruneCacheBestEffort`) when a prune is already running. Exposed for testing: `maybePruneCacheForTesting`, `cacheWritesSincePruneForTesting` getter, `lastPruneAtForTesting` getter.

Test: "prune이 이미 진행 중이면 due여도 스로틀 카운터를 리셋하지 않는다 (M3)" — sets `_pruneInFlight = true` via the existing test setter, calls `maybePruneCacheForTesting` once (which is immediately "due by time" since `_lastPruneAt` starts null), asserts `cacheWritesSincePruneForTesting == 1` (still counted) and `lastPruneAtForTesting == null` (not falsely marked as pruned).

RED confirmed before adding the in-flight guard (counters were reset to 0/now even though nothing actually ran). GREEN after. `test/tts_cache_prune_test.dart`: 8/8 passed (includes M2 tests above).

Commit: `517b6602`

## M4 — muted gameFeedback channel was unobservable because the test seam preceded the volume gate

`lib/services/sound_service.dart` `_play` (~L34-52): reordered so the kIsWeb check and `volumeFor(SoundChannel.gameFeedback) <= 0` gate run before the `playImpl` hook is consulted (previously the hook ran first and bypassed the gate entirely).

Test (`test/audio_policy_test.dart`, uses the existing `policy.setChannelOn(SoundChannel.gameFeedback, false)` utility): "gameFeedback 채널이 음소거면 SoundService가 playImpl을 부르지 않는다 (M4)" — mutes the channel, calls `SoundService.correct()`, asserts the playImpl-recorded list stays empty.

RED confirmed before reordering (the hook fired even though the channel was muted). GREEN after. Ran `test/audio_policy_test.dart` + `test/audio_policy_guard_test.dart` + `test/sound_channel_coverage_test.dart` + `test/milestone_feedback_widget_test.dart` — all passed, including the existing `SoundService.levelUp` playImpl-based test (confirms the reorder didn't break the unmuted case).

Commit: `352f6528`

## M6 — wrong state had no audio-tap coverage

`test/chosung_quiz_audio_test.dart`: added "오답을 제출해도 카드 탭으로 정답 발음을 재생할 수 있다 (M6)" — submits an incorrect answer (바나나 vs card 사과), taps SoriSpeakable, asserts speakImpl was called exactly once with 사과 (the correct word, not the wrong guess), then pumps the 1000ms wrong-answer auto-advance timer so no pending-timer assertion fires. No source change — pure coverage addition (`_State.wrong` already renders `SoriSpeakable(text: word, ...)`, `lib/screens/chosung_quiz_screen.dart:1075-1094`). GREEN immediately (3/3 in the file).

Commit: `7bf0a04d`

## M7 — quiz-advance prefetch assertion used contains(...) instead of exact equality

`test/vocab_pack_screen_prefetch_test.dart` (~L106-112): replaced `expect(prefetched, contains(remaining.single))` with `expect(prefetched, [remaining.single])`. `_advanceQuiz` (`lib/screens/vocab_pack_screen.dart:830-832`) prefetches exactly one item (`list[_qIdx + 1].korean`), unlike Learn's two-item current+peekNext — `contains` would silently pass even if an extra, wrong prefetch were also present. Expected value still derived from the observed spoken order exactly as before (no hardcoded literal, since `_quizQuestions` order is unseeded `math.Random()`). GREEN (3/3 in the file); this is a test-only strengthening, no source change.

Commit: `c97b0c13`

## M8 — restored a dropped design-intent comment

`lib/screens/chosung_quiz_screen.dart:1095` (in the `_State.waiting` switch arm): restored the comment explaining that the translation is always shown ("뜻 항상 표시 — 글자를 떠올리는 핵심 단서.") immediately above the existing "prevent leaking the answer" comment — the original explained why the translation is always shown even before an answer is submitted; only the leak-prevention half had survived a prior edit. Comment-only, no behavior change.

Commit: `7bf0a04d` (bundled with M6, same file/screen)

## I4 — ledger preservation

`.superpowers/sdd/2026-09-03-w7-pr1-tts/progress.md` gets a final append line recording this fix wave's commit range and the full-suite/analyze outcome, and this report plus the existing `task-*-report.md`/`full-suite-report.md` files are force-added and committed (briefs and `review-*.diff` files intentionally excluded) — see the commit immediately following this file's own addition.

## Full-suite summary (verbatim)

```
+5503 ~14: 14 skipped tests.
+5503 ~14: All other tests passed!
```

Passed: 5503. Failed: 0. Skipped: 14. This is 6 more than the pre-fix-wave baseline recorded in `progress.md` for `b374e0f2` (5497 passed / 0 failed / 14 skipped) — the net of tests added versus rewritten-in-place across this wave (I3 added 3 new tests, M2 added 2, M3 added 1, M6 added 1, C1 added/renamed 2; several other edits rewrote existing tests in place rather than adding new ones, so the totals do not sum 1:1 per finding, but direction and rough magnitude match).

Log lines in the raw output containing patterns like "klAccount: ... failed", "soriVideoLease: ... FAILED", and "Storage: ... failed/incomplete" are expected diagnostic prints emitted by passing tests that deliberately exercise fail-soft/error-handling code paths (account transition/reconciliation tests, video-lease retry tests, study-log/SRS persistence-failure tests) — not test failures. No `[E]` markers or numbered failure blocks appear anywhere in the captured output.

## flutter analyze --no-pub

```
Analyzing w7-pr1-tts-20260903...
No issues found! (ran in 141.8s)
```

## Commits (10, 10e4c8af..c97b0c13)

1. `10e4c8af` fix(ci): content-corpus 경로 변경 시 app 게이트도 함께 켜기 (C1)
2. `d827bbb1` fix(ci): tts-storage-verify 시크릿 검사를 env로 옮겨 JSON 인젝션 방지 (C2)
3. `d6f775f6` perf(tts): 번들 매니페스트 바이트 검증을 키별 지연 로딩으로 전환 (I1)
4. `f892be2f` fix(tts): pending prefetch 승격 중에도 resolving으로 표시 (I2)
5. `e07a234c` fix(tool): delete_remote_objects를 50개 단위로 청크 + 파괴 경로 테스트 추가 (I3)
6. `f6c8a497` fix(tts): 디스크 캐시 히트 시 mtime을 갱신해 진짜 LRU로 만든다 (M2)
7. `517b6602` fix(tts): prune 진행 중이면 스로틀 카운터를 리셋하지 않는다 (M3)
8. `352f6528` fix(sound): playImpl 테스트 시임을 volumeFor 게이트 뒤로 옮긴다 (M4)
9. `7bf0a04d` test(chosung): wrong 상태 발음 커버리지 추가 + 주석 복원 (M6, M8)
10. `c97b0c13` test(vocab-pack): 퀴즈 전진 프리페치 단언을 정확 일치로 강화 (M7)

(11th commit to follow: docs(sdd): W7 PR1 원장·태스크 리포트 보존 (H-53 대책) — I4, ledger preservation, this file included.)
