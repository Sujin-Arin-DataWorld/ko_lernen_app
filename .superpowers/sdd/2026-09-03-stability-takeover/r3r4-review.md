# R3/R4 release-integrity review -- commit 118b1933

## Verdict: FIX-REQUIRED

Fail-closed logic, subprocess argv hygiene, ELF parsing, YAML alias/merge-key
rejection, credential non-disclosure and receipt integrity are all solid and
behaviorally well tested (70/70 tests pass once dependencies are present).
Blocking on two concrete, verified defects: CI as wired will go red on the
next push (PyYAML never installed for the job that runs
test_release_integrity.py), and release_integrity.py has zero type
annotations, unlike its sibling. Neither is a live security hole.

## Findings

### Important

1. CI will fail 19/27 test_release_integrity.py tests -- PyYAML never
   installed. `.github/workflows/ci.yml:791-795` (job `asset-gates`) runs
   `pip install pillow numpy scipy` then `python -m unittest discover -s
   tool -p "test_*.py" -t .`, never installing PyYAML.
   `release_integrity.py:154-156` turns `ImportError` on `yaml` into
   `IntegrityError("yaml_dependency_missing")`. Verified live: project venv
   (no PyYAML) -> 19/27 fail with that code; throwaway venv + PyYAML 6.0.2 ->
   27/27 pass. This job already runs on any `tool/**` change (`ci.yml:772-774`),
   so it goes red on the very next push. Fix: add `pyyaml==6.0.2` to the
   `asset-gates` pip-install step (version matches the docstring at
   `release_integrity.py:8`). Do not skip these tests -- they are exactly
   what proves the SHA-pin checker rejects tampering.

2. `release_integrity.py` has no type hints anywhere (`load_manifest`,
   `verify_binary`, `verify_action`, `verify_workflow`, `main`, all helpers --
   confirmed by grep, zero annotations in the file). Its sibling
   `android_release_evidence.py` uses `from __future__ import annotations`
   and annotates essentially every function. Fix: annotate to match the
   established sibling style.

### Minor

3. `android_release_evidence.py:376-379` -- `bundle.read(name)` decompresses
   a whole zip member in one call; the 256 MB cap is only checked against the
   central-directory `file_size` metadata (which a crafted zip can misstate),
   not against actual decompressed bytes, unlike `_read_bytes` (line
   155-164) which bounds real bytes read from disk. Low real impact: the AAB
   is already SHA-256-pinned against `expected_aab_sha256` (lines 339-341)
   before the zip is opened, so a substituted payload requires already
   controlling the trusted build. Worth a streaming/bounded read anyway.

4. `android_release_evidence.py:605-607` -- the `except FileExistsError:`
   branch in `archive_release` raises `EvidenceError("archive_mismatch")`
   without `from None`, unlike every other raise-inside-except in this file
   (lines 152,164,183,245,247,333,385,469,490). No live leak today (`main()`
   never prints tracebacks) but breaks the file's own "only fixed reason
   codes cross the boundary" invariant. Fix: add `from None`.

5. `verify_workflow` (`release_integrity.py:152-237`, ruff C901 complexity
   28) and `_artifacts` (`android_release_evidence.py:336-388`, complexity
   16) exceed common length/complexity guidance. Both are the
   security-critical parsing routines; flagging for awareness, not blocking
   -- a line-count-driven split risks scattering fail-closed invariants.

6. Repeated magic size constants: `256 * 1024 * 1024` at
   `android_release_evidence.py:353,376` and `1024 * 1024` chunk sizes at
   `release_integrity.py:109` and `android_release_evidence.py:144,240-241,614`
   are not hoisted to named constants, unlike R3's own
   `MAX_WORKFLOW_BYTES`/`MAX_YAML_DEPTH`/`MAX_YAML_TOKENS` pattern
   (`release_integrity.py:33-35`).

7. Import order nits (ruff I001): `release_integrity.py:17-24` (`from
   pathlib import Path` misplaced among plain imports);
   `android_release_evidence.py:41-42` (`signal` before `shutil`,
   wrong alphabetical order). Cosmetic.

8. `release_integrity.py` -- `load_manifest`, `verify_binary`,
   `verify_action`, `verify_workflow`, `main` have no docstrings, unlike
   `android_release_evidence.py`'s more consistent public-function docstrings.

## Checked and clean (items 1-7)

1. Fail-closed / exit codes: success -> JSON stdout + exit 0; any
   IntegrityError/EvidenceError -> fixed reason code on stderr + exit 1;
   argparse usage errors -> exit 2. Probed edge cases (no-trailing-newline
   scalar, job-level `uses:`, `${{ matrix.* }}`, `docker://`, local `./`
   actions, reusable-workflow `org/repo/.github/workflows/x.yml@sha`) --
   every case fails closed with a clean `IntegrityError`, never an uncaught
   exception. No default-to-success path found.

2. Security: all subprocess calls use list argv, `shell=False`
   (`android_release_evidence.py:221-228,260-264`), no string interpolation.
   No zip-slip -- the AAB is never extracted to disk, only whitelisted
   `base/lib/<abi>/libapp.so` members are read into memory
   (lines 359-383), and the AAB SHA-256 is pinned before the zip is even
   opened (339-341). YAML uses `SafeLoader` only, rejects aliases, `<<`
   merge keys and duplicate mapping keys (`release_integrity.py:171,179,188`
   -- behaviorally confirmed with real PyYAML).
   `GOOGLE_APPLICATION_CREDENTIALS` is checked for presence only, never
   opened for content (`android_release_evidence.py:513-514`);
   `FIREBASE_TOKEN` is explicitly rejected (511). Receipts never carry raw
   tool stdout/stderr, only a regex-validated `cliVersion` and
   enum-constrained `status`/`reason` (434-449). Windows child cleanup
   resolves `taskkill.exe` via `GetSystemDirectoryW`, not PATH (255-264). No
   eval/exec/pickle/shell=True/os.system/MD5/SHA1-for-integrity/hardcoded
   secrets found (grepped both files). TOCTOU on hash-then-exec is
   mitigated as far as practical: `_validate_tool` re-hashes before and
   after each subprocess run (213,236); R3's `verify_binary` re-hashes and
   compares stat identity (dev/inode/mtime/ctime) across open/read/close.

3. ELF/build-ID parsing: correct 32/64-bit header and section-header
   struct formats (`android_release_evidence.py:273-333`); LE-only is
   correct since all 3 Android ABIs in scope are LE. All offsets/sizes go
   through `region()` (279-282), bounds-checked against `len(data)` with
   Python bignums (no overflow risk). Section count capped at 4096,
   string-table index and duplicate names validated, GNU build-id parsed
   per spec with all-zero-ID rejected. Malformed input
   (struct.error/UnicodeError/IndexError) converts cleanly to
   `invalid_elf`, never a raw traceback.

4. YAML `uses:` coverage: walks both `jobs.<id>.uses` (reusable-workflow
   calls) and `jobs.<id>.steps[].uses` (`release_integrity.py:222-234`),
   and rejects a workflow with zero verifiable references (235-236).
   Matrix expressions, `docker://` and local `./` actions all fail closed
   as `mutable_action` rather than being silently skipped.

5. Test quality: all 70 tests (27+43) are behavioral tamper-to-fail tests,
   none tautological; fixtures use `TemporaryDirectory`+`addCleanup`; no
   network access; the "external tool" is a local script run via
   `sys.executable`. Ran both suites live -- R4: 43/43 pass with the
   project venv as-is; R3: 27/27 pass with PyYAML 6.0.2 present, 19/27 fail
   with `yaml_dependency_missing` without it (see Finding 1).

6. Python hygiene otherwise: no mutable default args; `type(value) is int`
   (not `isinstance`) is deliberate and correct in `_positive`
   (`android_release_evidence.py:103-104`) and the manifest schemaVersion
   check (`release_integrity.py:59`), specifically to reject `bool`
   masquerading as `int` -- confirmed by tests passing `True`. UTF-8
   explicit throughout. `print()` used correctly (stdout for the one JSON
   success line, stderr for errors), appropriate for this CLI contract.

7. CI readiness otherwise: R4's 43 tests need no extra dependency and pass
   in `asset-gates` unmodified; `tool/**` changes already route through that
   job (`ci.yml:772-774`), so fixing Finding 1 alone makes both files run
   correctly under the existing invocation.

## Recommended minimal CI/venv change

In `.github/workflows/ci.yml` job `asset-gates` (~line 791-792):
`pip install pillow==10.4.0 numpy==2.0.1 scipy==1.16.1 pyyaml==6.0.2`
No `skipUnless` workaround -- the 19 gated tests are exactly what proves the
SHA-pin/alias/merge-key defenses reject tampering; skipping removes that
coverage instead of restoring it. Verify locally only via a throwaway venv,
never the shared `.venv`: create venv, `pip install pyyaml==6.0.2`, then
`python -X utf8 -m unittest tool.test_release_integrity -v`.
