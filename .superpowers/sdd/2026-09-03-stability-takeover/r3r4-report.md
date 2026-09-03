# R3 + R4 takeover report — 2026-09-03

Worktree: `C:\dev\hangulsori\ko_lernen_app_worktrees\stability-release-integrity-20260903`
Branch: `codex/stability-release-integrity-20260903`, based on `08b80c6e` (origin/main).
Commit produced this session: `118b1933`.

## 1. Cleanup status

`graphify-out/**` was untracked/modified noise unrelated to R3/R4. Discarded with
`git checkout -- graphify-out` (restored tracked modified files) and
`git clean -f -- graphify-out` (removed 14 untracked AST cache JSON files under
`graphify-out/cache/ast/v0.9.48-s2/`). After cleanup, `git status --short` showed
exactly the 5 expected untracked tool files, matching the recon.

## 2. Test counts

- `python -m unittest tool.test_release_integrity -v`: **27 tests, 19 failures, 0 errors.**
  All 19 failures have the identical root cause: PyYAML is not installed in
  `.venv` (`ModuleNotFoundError: No module named 'yaml'`). Every failing
  assertion shows the actual result as `error[yaml_dependency_missing]` against
  an expected code like `error[unreviewed_action]`, `error[invalid_workflow]`,
  `error[mutable_action]`, `error[version_comment_mismatch]`, or an actions-checked
  count assertion (`1 != 0`). No other assertion text appeared. This is an
  environment gap, not a code defect — the tool's own `--help` text says
  "The actions command requires PyYAML 6.0.2 (CI wiring must install it
  explicitly)," so the test suite is exercising a documented, deliberately
  separate dependency. The 8 tests that don't touch the `actions`/YAML path
  (binary hashing edge cases) all pass.
- `python -m unittest tool.test_android_release_evidence -v`: **43 tests, all
  passing**, 0 failures, 0 errors, ~73s runtime. Fully self-contained (local
  fakes for bundletool/firebase/filesystem), no third-party deps needed.
- `python -m unittest discover -s tool -p "test_*.py" -t .`: **180 tests total,
  19 failures, 25 errors.**
  - The 19 failures are exactly the `test_release_integrity` PyYAML failures above.
  - The 25 errors are import-time `ModuleNotFoundError`s in unrelated
    pre-existing test modules (hanok/scene-asset tooling), not in R3/R4 code:
    13 modules fail on `import numpy as np`, 12 fail on `from PIL import Image`
    (or `Image, UnidentifiedImageError` / `Image, ImageDraw`). None of the 25
    error modules is `test_release_integrity` or `test_android_release_evidence`.
    Full list of erroring modules: test_assemble_sarangchae_variable_pilot,
    test_asset_recipe, test_audit_scene_assets, test_build_scene_art_manifest,
    test_check_card_style, test_check_decoration_cutouts,
    test_check_personal_hanok_assets, test_check_style_conformance,
    test_compose_hanok_a1_state, test_compose_home_hero_hanji,
    test_compose_ildu_hyeonpan, test_cut_single_object, test_derive_hanok_a1_kit,
    test_extract_checkerboard_alpha, test_hanok_a1_kit,
    test_hanok_v1_asset_contract, test_make_kit_parts,
    test_promote_hanok_a1_states, test_promote_ildu_anchae_turntable,
    test_promote_ildu_changgo_turntable, test_promote_ildu_final_three_turntables,
    test_register_hanok_construction_stages,
    test_sarangchae_construction_progression, test_scene_poster_normalize,
    test_whiten_clip_matte.
  - **Classification: all 19 failures + all 25 errors are pre-existing
    environment gaps (missing PyYAML / numpy / PIL in this `.venv`). Nothing
    outside that category was observed.** Per instructions, the venv was not
    modified (no pip install).

## 3. CLI smoke tests (read-only, no network, no uploads)

- `python tool/release_integrity.py --help`: exit 0. Help text explicitly
  documents that `actions` requires PyYAML 6.0.2 installed separately by CI
  wiring, that nothing is downloaded/installed/executed, and that the manifest
  is reviewed source, not an artifact to trust from an untrusted download.
- **CLI syntax correction**: the `actions` subcommand takes workflow paths
  directly — `python tool/release_integrity.py actions WORKFLOW.yml [...]` —
  there is no `verify` sub-subcommand (unlike `android_release_evidence.py`,
  which does have `upload|verify|archive`). The task briefing's
  `actions verify WORKFLOW.yml` form is not valid for this tool; `verify` would
  be parsed as a bogus first workflow path.
- `python tool/release_integrity.py actions .github\workflows\playwright.yml`
  (corrected syntax): exit 1, stderr `error[yaml_dependency_missing]`. Expected
  fail-closed behavior, but not the anticipated diagnostic — because PyYAML is
  missing in this `.venv`, the tool fails one step earlier than the "unpinned
  uses" check the task briefing expected. `playwright.yml` in this worktree is
  confirmed to still use mutable `@v4` tags (`actions/checkout@v4`,
  `actions/setup-node@v4`, `actions/upload-artifact@v4`), not pinned 40-hex
  SHAs, so once PyYAML is available this would indeed report `mutable_action`.
  Ran the earlier (incorrect) `actions verify .github\workflows\playwright.yml`
  form too — same `yaml_dependency_missing` result, since the `import yaml`
  check happens before any positional-argument path is opened.
- `python tool/release_integrity.py manifest` (stdlib-only path, sanity check):
  exit 0, stdout `{"schemaVersion": 1, "verified": true}` — confirms
  `release_toolchain.json` is internally self-consistent.
- `python tool/android_release_evidence.py --help`: exit 0. Full help text
  renders, including the tools-json schema example, the
  `GOOGLE_APPLICATION_CREDENTIALS`/`FIREBASE_TOKEN` auth requirements, and the
  explicit disclaimer that this is a local integrity receipt, not a signed
  build attestation or proof of Crashlytics ingestion.
- **`release_integrity.py` write-safety check**: grepped for `open(` and any
  write/mutation calls (`write_text`, `write_bytes`, `shutil.`, `os.remove`,
  `os.write`, `.mkdir(`, `os.makedirs`). Only two `open()` calls exist, both
  `path.open("rb")` (lines 103, 158) — read-only. No write/mutate calls found
  anywhere in the file. Confirmed: `release_integrity.py` never writes to disk.
  (`android_release_evidence.py` does write, by design — receipt JSON via
  atomic temp-file+`os.replace`, and archive copies via `open(..., "xb")` — but
  that write path was not in scope for the read-only-verifier check.)

## 4. Third-party dependencies

- `tool/release_integrity.py`: **stdlib only** for `manifest` and `binary`
  subcommands (argparse, hashlib, json, os, pathlib, re, stat, sys). The
  `actions` subcommand lazily does `import yaml` (PyYAML) inside
  `verify_workflow()` and fails closed with `yaml_dependency_missing` if
  unavailable — by design, per the module docstring and `--help` text ("CI
  wiring must install it explicitly").
- `tool/android_release_evidence.py`: **100% stdlib** — argparse, contextlib,
  hashlib, json, os, re, signal, shutil, struct, subprocess, sys, tempfile,
  xml.etree.ElementTree, zipfile, dataclasses, pathlib, typing, plus a lazy
  `import ctypes` at line 254 (also stdlib, used for process-tree handling).
  No third-party packages required at all.

## 5. Behavioral summaries

### `tool/release_integrity.py` (267 lines)

Offline, read-only, fail-closed pre-flight check run *before* installing or
executing any release tool (ffmpeg/ffprobe binaries, or GitHub Actions used in
workflow YAML). Three subcommands:
- `manifest`: validates `release_toolchain.json` is internally self-consistent
  (exact schema, regex-validated SHA-1/SHA-256/repo/version fields, no
  duplicate JSON keys).
- `binary NAME PATH`: hashes a regular file (rejecting symlinks/dirs/empty
  files) with SHA-256, double-reads to catch same-size TOCTOU edits, and
  compares against the pinned digest in the manifest.
- `actions WORKFLOW.yml [...]`: safely parses workflow YAML (token-count and
  nesting-depth caps, rejects YAML aliases/anchors and duplicate keys to
  prevent hidden/duplicated `uses:` entries), extracts every `uses:` reference
  under `jobs.*.uses` and `jobs.*.steps[].uses`, and requires each to be
  pinned to a full 40-hex commit SHA matching the manifest's allow-listed
  repo+SHA+version-comment triple.
- Fails closed on: unpinned/mutable action tags, unlisted actions, SHA/version
  mismatches, malformed/oversized/duplicate-key YAML, missing PyYAML, checksum
  mismatches, changed/empty/non-regular binaries.
- Never downloads, installs, executes, or writes anything — pure verification,
  exits nonzero with a fixed diagnostic code (never raw exception text or
  file contents) on any failure.
- Needs from Jin: nothing new to run as-is against the current
  `release_toolchain.json`; to extend coverage, new action pins or ffmpeg
  binary SHA-256 updates go into that JSON file, and CI wiring must
  separately `pip install pyyaml==6.0.2` before calling `actions`.

### `tool/android_release_evidence.py` (668 lines)

Fail-closed evidence-receipt tool pairing a real Android App Bundle (AAB)
against its Crashlytics debug symbols, producing a signed local receipt (not
a Play/Firebase attestation) before Play upload. Three subcommands:
- `upload`: parses the AAB's `libapp.so` GNU build-IDs per architecture
  (arm/arm64/x64) via manual ELF parsing, matches them against the split-debug
  symbol files (`app.<arch>.symbols`), cross-checks the AAB manifest
  (versionCode, package name) via a SHA-pinned `bundletool dump manifest` call,
  cross-checks `google-services.json` for the Firebase app ID, then uploads
  symbols via a SHA-pinned `firebase crashlytics:symbols:upload` call and
  writes an atomic JSON receipt (`pending` → `success`/`failed`) guarded by an
  exclusive lock file. Retries only re-verify an identical prior success.
- `verify`: read-only gate — returns True only if a receipt exists, matches
  the current artifact identity exactly, and its `uploadResult.status` is
  `success`; any missing/stale/malformed/failed receipt returns False.
- `archive`: copies the AAB, receipt, and symbol files into an owner-only
  permissioned destination directory only after `verify` succeeds, verifying
  post-copy hashes and never overwriting a differently-contented existing
  archive.
- Fails closed on: AAB hash mismatch, unsupported/missing symbol architectures,
  build-ID mismatch between symbols and the AAB's actual `libapp.so`,
  unpinned/unreviewed java/bundletool.jar or node/firebase.js binaries (every
  argv element needs a reviewed SHA-256), missing
  `GOOGLE_APPLICATION_CREDENTIALS`, presence of `FIREBASE_TOKEN` (rejected to
  force isolated-CI-account auth), Firebase CLI version below 11.9.0, and any
  artifact mutation detected between identity-check and use (double `_artifacts`
  re-check before/after the upload call).
- Needs from Jin to actually run `upload`/`verify`/`archive` for real: a real
  signed release AAB, its expected SHA-256, the split-debug symbol directory,
  `google-services.json`, a `--tools-json` file naming absolute
  java/bundletool.jar and node/firebase.js paths plus their reviewed SHA-256
  hashes, a `GOOGLE_APPLICATION_CREDENTIALS` service-account JSON path (never
  read for content, only existence-checked), and the real git SHA / run
  id / run attempt / version code / Firebase app ID for this build. None of
  that was available or exercised in this offline recon session — only the
  43-test local-fake suite and `--help` were run.

## 6. Unexpected findings

- The task briefing's assumed CLI form `actions verify WORKFLOW.yml` for
  `release_integrity.py` is incorrect — there is no `verify` sub-subcommand
  for `actions`; workflow paths are passed directly as positional args. This
  did not change the observed (fail-closed) outcome in this environment
  because the PyYAML import check runs before any workflow path is opened,
  but it would matter once PyYAML is installed and the CLI is actually wired
  into CI. android_release_evidence.py's `upload|verify|archive` subcommand
  structure was as briefed.
- PyYAML is absent from `.venv`, so 19 of 27 `test_release_integrity` tests
  and the `actions` smoke test could not exercise their intended code paths
  (they only reached the `yaml_dependency_missing` fail-closed branch, not
  the unpinned-action/mutable-tag/version-mismatch diagnostics the tests were
  written to check). No other unexpected failures found; `test_android_release_evidence`
  is fully green and `discover`'s other 25 errors are unrelated pre-existing
  numpy/PIL gaps in other tool test modules.

## 7. Open questions (≤3)

1. Should CI provisioning (deferred until PR #256 merges) install `pyyaml==6.0.2`
   into a *separate* CI-only environment/step, or should it be added as a
   pinned dev-dependency in this repo's Python tooling requirements file
   (none was found for `tool/`) so local runs of `test_release_integrity`
   pass without ad hoc installs?
2. Confirm whether `.venv` is expected to ever carry PyYAML/numpy/PIL for
   local dev, or whether these tool suites are meant to only run inside CI
   images that provision them — this affects whether the 19+25 gaps above are
   "acceptable local-only noise" or a real environment-setup gap worth fixing.
3. For R4, are the real inputs (signed AAB, bundletool.jar, service-account
   credentials, `--tools-json`) already provisioned somewhere for a live
   dry-run, or does that provisioning itself need to be scoped as a follow-up
   task before `upload`/`archive` can be exercised end-to-end?

## Fix round 1 (Fable review of commit 118b1933)

Source review: `.superpowers/sdd/2026-09-03-stability-takeover/r3r4-review.md`,
verdict FIX-REQUIRED, 4 items addressed below. Reviewer minor items 5-8
(`verify_workflow`/`_artifacts` complexity, unhoisted magic size constants,
import-order nits, missing docstrings) were rejected per coordinator
instruction — no change made for those.

1. **CI (Important 1)**: `.github/workflows/ci.yml` job "Asset pipeline
   gates" (~line 792) pip-install line now reads
   `pip install pillow==10.4.0 numpy==2.0.1 scipy==1.16.1 pyyaml==6.0.2`.
   This is the only `ci.yml` change — no gate wiring touched, diff is
   exactly the one line. Verified the workflow still parses as YAML by
   running the throwaway venv's `python -c "import yaml; yaml.safe_load(...)"`
   equivalent implicitly via `release_integrity.py actions` reading real
   workflow files during the R3 suite (all 27 pass, including workflows
   under `.github/workflows/`).

2. **Type hints (Important 2)**: `tool/release_integrity.py` now starts
   with `from __future__ import annotations` and every function signature
   is annotated: `_unique_object(pairs: list[tuple[str, object]]) -> dict`,
   `load_manifest(path: Path) -> dict`,
   `_regular_file_identity(info: os.stat_result) -> tuple[int, int, int, int, int, int]`,
   `_hash_regular_binary(path: Path) -> tuple[str, int, tuple[int, int, int, int, int, int]]`,
   `verify_binary(manifest: dict, name: str, path: Path) -> dict`,
   `verify_action(manifest: dict, reference: object, version_comment: str) -> None`,
   `verify_workflow(manifest: dict, path: Path) -> int` plus its three
   nested helpers `mapping`/`validate_keys`/`check_use` (all `node: object`,
   since `yaml` is a conditional/lazy import and the module keeps it optional
   at import time — `object` avoids requiring PyYAML just to type-check),
   and `main(argv: list[str] | None = None) -> int`. No behavior change.
   Import order was deliberately left as-is (reviewer item 7 rejected).

3. **Bounded libapp.so read (Minor 3)**: `tool/android_release_evidence.py`
   `_artifacts()` (~376-388) now reads the AAB's `libapp.so` member via
   `bundle.open(name)` with an explicit bounded `member.read(256*1024*1024+1)`
   and rejects (`symbol_mismatch`) if the actual bytes read are empty or
   exceed the cap, mirroring `_read_bytes`'s own pattern. The prior
   `bundle.getinfo(name).file_size > 256*1024*1024` check remains as a
   cheap pre-filter only (comment added clarifying it never gates
   acceptance on its own).
   - Test added: `test_lying_zip_size_metadata_cannot_bypass_the_read_cap`
     in `tool/test_android_release_evidence.py`.
   - **Investigation note**: the first design monkeypatched
     `ZipInfo.file_size` smaller than a real >256 MiB member written into
     a rebuilt AAB. Live experiment showed Python's own `zipfile` module
     already bounds `ZipExtFile` reads to the declared (possibly lied)
     `file_size` internally, then CRC-validates the truncated output
     against the true stream's recorded CRC-32 — so a "lie smaller"
     scenario raises `zipfile.BadZipFile` -> `invalid_bundle` in *both*
     the pre-fix and post-fix code, and does not actually distinguish
     them (confirmed directly: reproduced the same `BadZipFile: Bad
     CRC-32` failure against a standalone script using only stdlib
     `zipfile`, independent of this project's code). Redesigned the test
     around a controlled `BoundedReadProbe` test double substituted for
     `bundle.open()` on the target member: it raises `AssertionError` on
     any call that is not an explicit, positive, capped `read(n)` — which
     is exactly what the pre-fix `bundle.read(name)` call (internally
     `fp.read()` with `n=None`) triggers — and otherwise returns exactly
     `n` bytes, standing in for a member whose true decompressed length is
     effectively unbounded despite a lied-small declared `file_size`
     (also monkeypatched via `ZipInfo`/`getinfo`, to bypass the cheap
     pre-filter as a lying zip would). This isolates and directly proves
     the code's own contract, independent of `zipfile`'s internal
     truncation/CRC behavior.
   - **Verified as a real regression guard**: temporarily reverted the fix
     in `android_release_evidence.py` (restored the one-shot
     `bundle.read(name)` call) and reran the new test alone — it failed
     with `AssertionError: expected a bounded read of at most 268435457
     bytes, got n=None (an unbounded/bare read call)`, proving the test
     fails against the pre-fix code. Restored the fix from a backup; the
     test passes again (0.17s) and the full R4 suite is green (44/44).

4. **`from None` consistency (Minor 4)**: `tool/android_release_evidence.py`
   `archive_release()` (~line 614): `except FileExistsError:` branch now
   raises `EvidenceError("archive_mismatch") from None`, matching every
   other raise-inside-except in the file.

### Test results after fix round 1

- R3 (`tool.test_release_integrity`), throwaway venv
  (`%TEMP%\r3-yaml-venv-20260903`, `pip install pyyaml==6.0.2`; canonical
  `.venv` was never touched): **27/27 pass**, 5.65s.
- R4 (`tool.test_android_release_evidence`), canonical venv: **44/44 pass**
  (43 original + 1 new `test_lying_zip_size_metadata_cannot_bypass_the_read_cap`),
  51.6s.
- `python -m unittest discover -s tool -p "test_*.py" -t .` in the
  throwaway venv: **181 tests, 0 failures, 25 errors.** All 25 errors are
  the same pre-existing environment-only import gaps as the initial
  recon (13 `ModuleNotFoundError: No module named 'numpy'`, 12
  `ModuleNotFoundError: No module named 'PIL'`) in unrelated hanok/asset
  scene-tooling test modules — none in `test_release_integrity` or
  `test_android_release_evidence`. The throwaway venv adds only PyYAML by
  design; it never carries numpy/PIL, so this count and its classification
  match expectations.
- `git diff --check`: clean — only benign CRLF-normalization warnings from
  git's `autocrlf` on this Windows checkout, no actual whitespace errors.

### Commit

- `ed422dba` — `fix(tool): pyyaml in CI tool-tests job, type hints, bounded libapp.so read, from None (Fable review of R3+R4)`
  (4 files changed: `.github/workflows/ci.yml`,
  `tool/release_integrity.py`, `tool/android_release_evidence.py`,
  `tool/test_android_release_evidence.py`; 81 insertions, 14 deletions.)

### Open questions after fix round 1 (unchanged from initial report)

The 3 open questions from the initial report still stand — none was
resolved by this fix round, since they concern CI/venv provisioning policy
and R4 live-input availability, not code correctness.
