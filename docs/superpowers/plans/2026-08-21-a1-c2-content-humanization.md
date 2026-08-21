# A1-C2 Content Humanization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a source-synchronized, loader-safe Beyond Humanizer update for every A1-C2 learner-content surface and integrate the verified result into `main`.

**Architecture:** Extend the existing explicit 22-surface audit into a per-leaf coverage and quality gate, use its findings to make minimal PIVOT-based edits across all authoritative layers, then verify data contracts and Flutter selection behavior. Preserve approval boundaries and record human-only judgments instead of manufacturing approval evidence.

**Tech Stack:** Python 3 content factory, JSON/CSV assets, Flutter/Dart loaders and tests, Git worktrees, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-08-21-a1-c2-content-humanization-design.md`

## Global Constraints

- Preserve existing IDs, levels, course links, target forms, accepted answers, schema, and loader contracts.
- Keep PDF-derived material clean-room and abstract; do not copy source wording, IDs, pages, or unit order.
- Use Beyond Humanizer PIVOT and independent DE/EN reconstruction.
- Do not claim native-speaker or Korean-educator approval.
- Stage only files owned by this task.
- Do not force-push `main` or either work branch.

---

### Task 1: Lock inventory and leaf-level coverage

**Files:**
- Modify: `tools/content_factory/audit_content_text.py`
- Modify: `tools/content_factory/test_audit_content_text.py`

**Interfaces:**
- Consumes: the explicit `SURFACES` registry and `assets/data`.
- Produces: deterministic learner-copy leaf records and per-level/file counts exposed by `build_inventory()` and CLI output.

- [x] Add failing tests for stable leaf identity, language inference, record-level attribution, legitimate optional blanks, and detection of missing required multilingual copy.
- [x] Run `python -m unittest tools.content_factory.test_audit_content_text -v` and confirm the new assertions fail for absent leaf-ledger behavior.
- [x] Implement the smallest audit extension that satisfies the tests without rewriting content.
- [x] Rerun the unit test and `python tools/content_factory/audit_content_text.py --check`.

### Task 2: Generate and inspect A1-C2 quality findings

**Files:**
- Modify: `docs/CONTENT_TEXT_HUMANIZATION_WORKLIST_2026-08-21.md`
- Create: `docs/CONTENT_TEXT_HUMANIZATION_REPORT_2026-08-21.md`

**Interfaces:**
- Consumes: the leaf ledger from Task 1 and Beyond Humanizer error codes.
- Produces: per-file/per-level coverage totals, exact changed IDs, preserved counts, and human-gate disclosures.

- [x] Run Unicode, rejected-phrase, duplicate-ID, unresolved-marker, multilingual completeness, level-count, and repeated-template diagnostics.
- [x] Inspect every emitted finding against source authority and assign a concrete issue class.
- [x] Record the baseline and the intended correction set before editing runtime data.

### Task 3: Humanize vocabulary, grammar, course, culture, pronunciation, and relation copy

**Files:**
- Modify when diagnosed: `assets/data/korean_vocab.csv`, `grammar.csv`, `curriculum_manifest.json`, `can_do_segments.json`, `culture_notes.json`, `grammar_patterns.json`, `pronunciation_phrases.json`, `media_phrases.json`, `word_relations.json`, `kkeunmari_pool.json`, `silben_puzzles.json`
- Modify matching factory source/draft/review files found by exact ID/text search.

**Interfaces:**
- Consumes: Task 2 correction set.
- Produces: synchronized multilingual records with stable data contracts.

- [x] Lock each diagnosed record's learning target and PIVOT; preserve non-diagnosed records.
- [x] Apply only diagnosed corrections through source-synchronized builders or the append-only revision overlay.
- [x] Search changed IDs across source/draft/review/runtime and preserve historical approval artifacts.
- [x] Run focused loaders and `validate_content.py` after each surface group.

### Task 4: Humanize Smalltalk and scenario copy across A1-C2

**Files:**
- Modify when diagnosed: `assets/data/smalltalk.json`, `assets/data/scenarios_a1.json` through `scenarios_c2.json`
- Modify matching `tools/content_factory/data`, `drafts`, and `review` artifacts.

**Interfaces:**
- Consumes: scenario roles/relationship metadata and Smalltalk turn contracts.
- Produces: natural KO/DE/EN turns with preserved speech acts, relationship distance, and target level.

- [x] Inspect high-frequency boilerplate and every diagnostic finding by level.
- [x] Apply PIVOT corrections without altering role, level, quest answer, or dialogue ordering.
- [x] Synchronize active scenario sources and record promoted Smalltalk changes in the revision overlay.
- [x] Run scenario and Smalltalk builder/loader tests.

### Task 5: Humanize Cloze and Satz while preserving item contracts

**Files:**
- Modify when diagnosed: `assets/data/cloze.json`, `assets/data/satz_sentences.json`
- Modify matching factory source/draft/review files.

**Interfaces:**
- Consumes: target grammar/vocabulary and current distractor/token contracts.
- Produces: natural prompts with exactly one Cloze answer and unchanged Satz assembly.

- [x] Test Cloze option and multilingual completeness contracts; no new correction set was diagnosed.
- [x] Verify Satz `targetKo`, `promptDe`, and `promptEn` assembly contracts; no new correction set was diagnosed.
- [x] Preserve already-correct Cloze/Satz copy instead of creating cosmetic diffs.
- [x] Run Cloze, Satz, daily-challenge, and data-integrity tests.

### Task 6: Verify exact-level recommendation behavior

**Files:**
- Verify/modify: `lib/screens/daily_challenge_screen.dart`, `lib/services/storage_service.dart`, `lib/services/review_deck_service.dart`, `lib/services/personalized_lesson_service.dart`
- Verify/modify tests: `test/daily_challenge_test.dart`, `today_goal_test.dart`, `review_deck_order_test.dart`, `personalized_lesson_test.dart`

**Interfaces:**
- Consumes: learner level and due/new candidate IDs.
- Produces: exact-level daily/review/personalized selections.

- [x] Confirm the regression tests fail against the pre-fix behavior and pass against the task tree.
- [x] Run fresh focused analysis and all four regression-test files on the final tree.

### Task 7: Run fresh whole-tree validation and complete the report

**Files:**
- Modify: `docs/CONTENT_TEXT_HUMANIZATION_REPORT_2026-08-21.md`
- Modify: `.claude/handoffs/2026-08-21-212959-content-humanization-batch1.md`

**Interfaces:**
- Consumes: final task diff.
- Produces: command evidence, known baseline failures, TTS impact, and exact open human gates.

- [x] Run Beyond Humanizer Unicode and rejected-phrase validators.
- [x] Run the 22-surface audit, `validate_content.py`, relevant builders, and the complete content-factory unit suite.
- [x] Run relevant Flutter analysis, content/loaders/selection tests, then the full Flutter test suite if the scoped gates are green.
- [x] Run `git diff --check`, inspect `git status`, and reconcile every changed/generated file.
- [x] Update and validate the session handoff with UTF-8 mode.

### Task 8: Commit, push, integrate, verify main, and clean up

**Files:**
- Git metadata only after Task 7 is green or baseline-qualified.

**Interfaces:**
- Consumes: verified task head and current `origin/main`.
- Produces: verified main commit with no surviving task worktree or task branch.

- [ ] Stage only the exact task-owned paths and review `git diff --cached`.
- [ ] Commit and push `codex/content-humanization-20260821` without bypassing hooks.
- [ ] Fetch `origin/main`; build a clean detached merge worktree and integrate the exact pushed task SHA.
- [ ] Rerun final required validation on the integrated head.
- [ ] Push the verified integrated head to `main` only if it is a fast-forward from current `origin/main`.
- [ ] Verify remote `main` ancestry and the current-head GitHub Actions run.
- [ ] Remove the temporary merge worktree and task worktree from outside both paths.
- [ ] Delete the local and remote task branch and verify the worktree/branch lists.
