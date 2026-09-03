# Task 7 Report — 첫 문장 126개(유니크 125개) 앱 번들 승격

## ① Diffstat

Two commits, matching the brief's split:

- `f4d11c53` feat(tts): 코드/가드 — 6 files changed, 255 insertions(+), 13 deletions(-)
  (`tool/generate_tts.py`, `tool/test_generate_tts.py`, `pubspec.yaml`,
  `test/content_audio_policy_guard_test.dart`, `test/asset_orphan_guard_test.dart`,
  `test/tts_bundled_manifest_test.dart`)
- `784db5a4` chore(tts): 산출물 — 126 files changed (125 new `.mp3` + manifest rewrite),
  379 insertions(+), 379 deletions(-)

mp3 count: **125** (female 60, male 65). Total bytes: **1,862,682** (~1.78 MB) —
well under the 6 MB estimate, nowhere near the 8 MB flag threshold
(`Get-ChildItem assets\tts\v3 -Recurse -File | Measure-Object -Property Length -Sum`
→ Count 125, Sum 1862682).

## ② RED

```
python -X utf8 -m unittest tool.test_generate_tts.TtsGeneratorContractTest.test_download_first_line_bundle_dedupes_shared_storage_paths -v
```
```
AttributeError: module 'generate_tts' has no attribute 'download_first_line_bundle'
FAILED (errors=1)
```
Exactly as predicted by the brief.

## ③ GREEN

**Python** — full suite, 30/30 pass (`python -X utf8 -m unittest tool.test_generate_tts -v`),
including the brief's new test plus two additional tests I added (see "Design
deviation" below) and one pre-existing test I had to update (see §⑦):
`test_download_first_line_bundle_dedupes_shared_storage_paths`,
`test_download_first_line_bundle_batches_multi_item_voice_directories`,
`test_download_first_line_bundle_skips_an_already_valid_local_file`,
`test_first_line_manifest_covers_exact_canonical_scenarios` (updated).
Frozen tests (`test_v3_storage_key_matches_flutter_and_function_contract`,
`test_bare_invocation_is_rejected`, `test_verify_storage_mode_reaches_its_own_read_only_branch`)
unmodified and green.

**Fixture verification (Step 4, network-free)**: created two dummy `ID3`-prefixed
mp3s at the real first two `(voice, cacheHashSha1)` paths (one female, one male),
ran `--write-first-line-manifest` → `bundledCount` went 0→2 with exactly those
two items flipping to `bundled:true` and correct `bundledAssetPath`/`bundledSha256`.
Fixtures deleted and manifest regenerated back to the 0-bundled baseline before
proceeding to the real download.

**Dart** — `flutter test --no-pub test/content_audio_policy_guard_test.dart
test/asset_orphan_guard_test.dart test/tts_bundled_manifest_test.dart
test/tts_cache_key_test.dart --reporter expanded` → **30/30 pass**. (The default
concurrent run's expanded-reporter output looked odd — one slow test's
"currently running" line kept reprinting with an incrementing counter while
other suites finished in the background, making it look like a single test
repeated ~19 times. A sequential `-j 1` re-run showed every individual test
name completing cleanly with the identical final tally of 30, confirming it
was a reporter-interleaving artifact, not a real gap — see §⑦.)

## ④ Analyze

```
flutter analyze --no-pub
No issues found! (ran in 72.5s)
```

## ⑤ Download log summary

Real download ran in this session (gcloud authenticated as vjinny2@gmail.com,
project ko-lernen-app, per controller authorization) via
`python -X utf8 tool/generate_tts.py --download-first-line-bundle`.

- **Count**: 125/125 unique `storagePath`s downloaded (126 manifest items,
  1 duplicate pair collapsed to 1 file — `tts/v3/male/e15ee7dbcb688d....mp3`,
  shared by scenarios `package_wrong_door` and `noisy_neighbor_evening`).
- **Batching**: grouped by voice, chunked at ≤50 sources per `gcloud storage cp`
  invocation (per the controller ruling, to avoid ~125 individual gcloud
  process spawns at ~10-16s each). Female (60 files) → 2 batched calls
  (50 + 10); male (65 files) → 2 batched calls (50 + 15). **4 gcloud
  invocations total**, not 125.
- **Time**: 1m18.68s wall clock for the whole download (`time (...)` in
  PowerShell/bash).
- **Failures**: 0. All 125 files verified MP3-signature-valid and ≥256 bytes
  both by the script's own validation (atomic `.part`/scratch-dir → `os.replace`
  only after validation) and by an independent post-hoc scan I ran over every
  file in `assets/tts/`.
- **Cleanup**: no leftover `.part` files or `.batch-*.part` scratch directories
  anywhere under `assets/tts/` after the run (`find assets/tts -iname
  "*.part*"` → empty).

## ⑥ `--check-first-line-manifest` output

```
python -X utf8 tool/generate_tts.py --check-first-line-manifest assets/data/tts_first_line_manifest.json
first-line manifest: 126 scenarios, 126 bundled -> ...\tts_first_line_manifest.json
exit=0
```
No drift. **This is the final, non-interim state** — bundledCount is not the
"expected local RED" the brief anticipated, because the real download ran in
this same session per controller authorization (the brief was written for a
network-less implementer session; the controller ruling here explicitly
authorized running the download now). See §⑦ for the `bundledCount` value
correction this required.

## ⑦ Unexpected findings / deviations

1. **Fixture byte-size bug in the brief.** The brief's Step 1 test fixture
   (`b"ID3" + bytes(40)` = 43 bytes) is smaller than this codebase's actual
   `MIN_REMOTE_MP3_BYTES = 256`, so the brief's own Step 3 code would raise
   `ValueError` on its own Step 4 fixture instead of passing. Fixed by
   widening the fixture to `bytes(300)` (343 bytes total) — the dedup
   behavior under test is unaffected by the exact byte count.

2. **`bundledCount` semantics: 126, not 125.** `bundledCount` is computed as
   `sum(item["bundled"] for item in items)` over all 126 *scenario items*
   (unchanged, pre-existing code) — not over unique storage paths. Once all
   125 unique files exist, **both** duplicate-storagePath items independently
   resolve `bundled: true`, so the correct value is **126**, and "125" is the
   count of *unique underlying mp3 files*, a different metric not exposed as
   its own manifest field. I corrected the brief's given Dart assertion
   (`content_audio_policy_guard_test.dart`) from `125` to `126` with an
   updated `reason:` string explaining the distinction, and updated one
   *pre-existing* Python test (`test_first_line_manifest_covers_exact_canonical_scenarios`,
   not mentioned in the brief's file list) whose baseline-era assertions
   (`bundledCount == 0`, all items `bundled: false`/null paths) were
   necessarily stale once real files exist on disk — I flipped them to the
   correct post-download invariant (all 126 bundled, all `bundledAssetPath`
   under `assets/tts/v3/`, all `bundledSha256` populated), not weakened them.

3. **Design deviation: batched (not literal per-file) `download_first_line_bundle`.**
   The brief's given Step 3 code does one `gcloud storage cp` subprocess per
   unique file (125 processes, ~10-16s each ≈ 25-30 min serially — risking
   Bash-tool/session timeouts and contradicting the controller's explicit
   batching ruling). I implemented a hybrid: a voice-group chunk of exactly
   1 pending item still issues the brief's original single-source
   `cp <src> <local .part>` call (so the brief's given unit test passes
   byte-for-byte unmodified in its assertions, since with 2 unique paths
   split across 2 voices each chunk is size 1); a chunk with >1 pending item
   uses one multi-source `cp <src1> <src2> ... <scratch-dir>` call
   (chunked at ≤50), with each fetched file individually MP3/size-validated
   and atomically `os.replace`d into place before the scratch dir is removed.
   I also added a "skip if a local file already exists and is already a
   valid MP3" fast path (interpreting the controller's "skip files already
   present with matching size" as "skip an already-valid local file" rather
   than literally comparing against remote size, since getting remote size
   without an extra `storage ls`/stat call would defeat the point of
   skipping). I added two more Python unit tests
   (`test_download_first_line_bundle_batches_multi_item_voice_directories`,
   `test_download_first_line_bundle_skips_an_already_valid_local_file`) to
   cover these paths, since they're correctness-critical for the real
   125-file run and weren't exercised by the brief's single given test.

## ⑧ Open questions (≤3)

1. `chunk_size=50` is a hardcoded default parameter on `download_first_line_bundle`
   (matching the controller ruling's "chunks of ≤50" literally) — not exposed
   as a CLI flag. If a future corpus grows well past ~250-300 first lines per
   voice, worth revisiting whether this should be tunable or a `--workers`-style
   flag; out of scope here.
2. The "skip already-present valid file" fast path re-reads and validates the
   full local file on every invocation rather than trusting a cheap
   size-only check — fine at 125 files / ~1.8 MB, but would be worth
   revisiting if this corpus grows an order of magnitude.
3. CI wiring for `--download-first-line-bundle` (brief's own open question,
   unchanged): this plan assumed one local run + commit, not a CI job: no
   change made here.

## ⑨ Self-review

- **No upload/delete calls anywhere** in the new code path: grepped every
  `"storage"` gcloud invocation in `generate_tts.py` — only `storage ls`
  (pre-existing, `remote_cache_objects`) and `storage cp` (pre-existing
  upload path at the synth/upload tail, untouched; and the two `storage cp`
  call sites inside the new `download_first_line_bundle`, both `gs://` →
  local). No `storage rm`/delete anywhere in the file.
- **`.part`/scratch cleanup confirmed**: `shutil.rmtree(scratch, ...)` runs
  in a `finally` block after each batch chunk regardless of success/failure;
  post-run scan of `assets/tts/` found zero `.part` files and zero
  `.batch-*.part` directories.
- **Dedupe confirmed**: 126 manifest items → 125 unique `storagePath`s →
  125 files on disk (60 female + 65 male); script's own printed summary
  ("다운로드 125개 (유니크 storagePath 125개)") matches.
- **pubspec.yaml exactly two new lines** after `- assets/data/`:
  `- assets/tts/v3/female/` and `- assets/tts/v3/male/` — no bare
  `- assets/tts/` entry added; `_pubspec_declares_tts_assets()` now requires
  both voice-specific lines via two separate regexes (and its Python test
  was updated to match, per controller ruling).
- **Guards flipped, not weakened**: `content_audio_policy_guard_test.dart`'s
  first-line test now asserts `bundledCount == 126` (not a loosened `>= 0` or
  similar) plus both pubspec lines plus the loader-source contains/isNot
  checks; `asset_orphan_guard_test.dart` gained two new `dynamicDirs` entries
  each backed by a real evidence string
  (`bundledPath.startsWith('assets/tts/')` in `tts_bundled_manifest.dart:124`,
  verified present); `tts_bundled_manifest_test.dart`'s frozen resolver-order
  test (`tts_service.dart` bundle→disk→Storage→callable string-position
  contract) and its `bundled:false`⇒null-fields test body are byte-identical,
  only the outer test's *name* changed per brief.
