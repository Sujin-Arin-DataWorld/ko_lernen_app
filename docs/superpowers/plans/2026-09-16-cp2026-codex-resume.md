# CP-2026 Codex continuation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Recover the two interrupted content deliverables, repair the inherited C9 review defects, and establish a source-backed continuation queue for the entire inherited program.

**Architecture:** Keep grammar, vocabulary drafts and program coordination in distinct existing or new worktrees. Execute one implementation subagent at a time with independent review. The coordinator concurrently inspects existing PRs and reconstructs the program's current dependency order.

**Tech Stack:** Flutter/Dart, Python content tooling, GitHub Actions, Git worktrees, local NIKL/Sejong references.

**Spec:** `docs/superpowers/specs/2026-09-16-cp2026-codex-resume-design.md`

**Execution status:** Tasks 1–4 are locally complete and independently reviewed. C4 grammar, Batch34 draft and C9 repairs passed final scoped review; program adoption review passed and the final unified packet is current. Human content approval, commit/PR authorization, ordered integration checks and missing audio remain pending. This completes the immediate takeover plan, not the full commercialization program.

## Global Constraints

- Work only in the assigned worktree; primary main and unrelated sessions are untouched.
- Python: `C:/dev/hangulsori/ko_lernen_app/.venv/Scripts/python.exe`; set `PYTHONIOENCODING=utf-8` and `PYTHONUTF8=1`.
- Current baseline: origin/main `61f5c819dcd51357617f731ce0b4694ad3d8be49`; verify before changing a branch.
- No commit, push, merge, deletion, deployment, human-approval fields, or false Claude attribution from an implementer. Return the complete tested working diff for controller review.
- No additional subagents from implementers or reviewers. One implementation subagent at a time.
- Freeze existing content IDs and levels; do not raise ratchet caps or weaken a gate to accommodate bad content.
- Korean is the semantic source. DE/EN preserve meaning and register; no invented facts or nuance. Read the beyond-humanizer skill for linguistic work.
- Keep draft status distinct from runtime promotion; Batch 32/33/C9-1 approval remains pending until Jin supplies a content decision.
- New content must pass source-level, language, game, persona, and derived-artifact checks applicable to its surface.

## Task 1: Recover C4-G1 grammar priorities 1-4

**Worktree:** `C:/dev/hangulsori/ko_lernen_app_worktrees/c4-grammar-g1-20260917`

**Requirements:** Read `.superpowers/sdd/2026-09-16-cp2026-codex-resume/source-c4-brief.md` in the coordinator worktree and the task-specific corrections below. The source brief supplies concrete source files, row schema, registrations and validation commands. Recover useful drafting from `C:/Users/vjinn/.codex/attachments/093acc39-24aa-4642-9188-e89a19ade7dc/pasted-text.txt`. Its deliberations are candidate content, not correctness evidence.

**Files:** Modify `assets/data/grammar.csv`, `assets/data/curriculum_manifest.json`, required generated can-do/phase/matrix/TTS assets and reports, and `docs/data/level_bible/V2_grammar_authoring_queue.md`. Add `tool/test_c4_g1_grammar.py` and `docs/data/review_packets/c4_g1_grammar_jin_sample.md`. Existing mapping code may receive a narrow semantics-backed fix if its normalization falsely reports an already-taught item missing. Do not change vocab, scenarios, cloze/satz, usage notes or level ledgers.

**Interfaces:** Consumes existing grammar CSV schema, grammarRuleMap and current source references; produces registered grammar cards, explicit coverage credit, two aligned examples and test evidence. No CSV column or loader interface change.

**Corrections:** `-거든1` connective must be checked against its conditional use, not blindly authored as the queue's reason-ending description. Check whether existing indirect-speech and interrupted-action cards already cover requested meanings; reuse rather than duplicate them. Verify the precise sense of `-을 것1`; do not equate all future nominalization and written instructions. Do not falsify pattern text to game F1 matching. Same-level quiz distractors are required and must remain distinct. If two examples need an existing separator convention, verify loader/TTS consumption before using it.

- [x] Inspect source references, existing cards and their consumers; record intended IDs and mapping decisions in the report before authoring.
- [x] Add focused failing tests for the requested semantic distinctions, registration, same-level distractors, example count/alignment, and preservation of existing IDs/levels. Include a duplicate-card/matcher regression when applicable.

```powershell
& 'C:/dev/hangulsori/ko_lernen_app/.venv/Scripts/python.exe' -m unittest tool.test_c4_g1_grammar -v
```

- [x] Author the missing cards and minimally repair evidenced mapping defects. Write a full review packet listing patterns, meanings, both examples, translations, distractors and unit mapping. Cite only verified local source evidence or newly verified official dictionary evidence, labeled accurately.
- [x] Run the source brief's complete generated-artifact `--check` chain, the focused grammar test, existing curriculum/level-bible tests, targeted Flutter tests and analyze. Preserve unrelated file bytes if tools produce unrelated drift.
- [x] Rebuild canonical TTS manifests and run storage verification. Report missing clips; controller reviews before any synthesis/upload. Do not claim zero missing without an actual storage result.
- [x] Self-review all new examples and the full diff; write task-1-report.md with counts before/after, exact commands/results, preserved surfaces, changed file list, and any concerns. No commit.

## Task 2: Recover Batch 34 A2 draft

**Worktree:** `C:/dev/hangulsori/ko_lernen_app_worktrees/c3-batch34-a2-20260917`

**Requirements:** Read `.superpowers/sdd/2026-09-16-cp2026-codex-resume/source-batch34-brief.md` in the coordinator worktree. Recover the 64-word planning work from `C:/Users/vjinn/.codex/attachments/746debcb-6724-46f7-b745-5c83be6958e9/pasted-text.txt`; validate all candidates independently against current source.

**Files:** Create `tools/content_factory/drafts/batch_34_a2_rows.csv`, `batch_34_a2_cloze.json`, `batch_34_a2_satz.json`, `batch_34_a2_reinforcement_manifest.json`, three `tools/content_factory/review/batch_34_a2_*_review.csv` ledgers, `tools/content_factory/test_batch_34_draft.py`, and `docs/data/review_packets/batch_34_a2_jin_sample.md`. Prefer a reproducible, focused generator beside the draft tools instead of an untracked-only authoring script. No `assets/data/**` edits or TTS.

**Interfaces:** Existing Batch 33 schemas and shared A2 rules. Manifest `status=draft`, review status pending, no fabricated approval. IDs follow maximum live plus all relevant drafts. Raw NIKL grade-2 headword-set arithmetic is reported separately from normalized F2 coverage.

**Review-derived addition:** Repair the four localized Batch 32/33 sample defects documented in coordinator `batch32-33-review-report.md`, keeping their draft copies, fingerprints, persona evidence and sample packets synchronized. Preserve IDs, words, gap counts and pending status. No live asset edits. Scope historical gap tests to their batch boundary so later batches do not invalidate an earlier receipt.

- [x] Fast-forward the clean adopted worktree to fetched origin/main before writing; record source hashes.
- [x] Recompute gaps and partial packs. Complete `a2_events_1` first and `a2_messenger_phone_1` only with on-theme remaining words. Draft 64 original examples with required persona, source and game contracts.
- [x] Adapt precedent checks without weakening them. Confirm tests fail while artifacts are absent.

```powershell
& 'C:/dev/hangulsori/ko_lernen_app/.venv/Scripts/python.exe' -m unittest tools.content_factory.test_batch_34_draft -v
```

- [x] Generate all artifacts. Write all 192 distractor-substituted sentences for manual review. Check alternative meanings and collocations; grammar errors alone are insufficient when the same form has a valid reading.
- [x] Run the draft tests, A2 scanner to scratch output, validator and promotion audit. Interpret expected draft `not_live` separately from structural failures. Confirm `git diff -- assets/data` is empty.
- [x] Read the seven sample rows at indices 0/9/18/27/36/45/54 with translations and every distractor sentence, then self-review the full corpus. Write task-2-report.md; no commit or promotion.

## Task 3: Reconcile program ownership and existing review gates

**Worktree:** `C:/dev/hangulsori/ko_lernen_app_worktrees/cp2026-codex-resume-20260916`

**Files:** Create `docs/CP2026_CONTINUATION.md` and `docs/data/review_packets/cp2026_pending_jin_review.md`. Read the CP-2026, LCP and W7-W10 source plans plus current Git/PR evidence. Preserve source-plan hashes in the program document. Do not update Codex or Claude memory files.

**Interfaces:** Consumes exact main/PR SHAs, existing manifests, F2 coverage and the original task queue; produces an actionable queue with dependencies, evidence and completion criteria. Links remain usable after Claude subscription expiry.

- [x] Record current counts by parsing CSV/JSON and recompute A1/A2 coverage using the existing audit API. Give at-level and any-level counts separately.
- [x] Match each S/B/C/O/Q program task to main implementation evidence, merged PRs, pending work or human/service observation; do not infer deployed state from merged code.
- [x] Review PR #362 against its exact head and latest content; package the existing Batch 32/33 and C9-1 samples together, preserving existing pending approval.
- [x] Include dependencies for grammar continuation, relevel 2, A1 sentence refinement, C9-2, Batch 35+, C2e, C7-2 ledger hygiene, C6 generator repair, Q-S3 and remaining backend/operations gates.
- [x] Verify links, counts and source hashes; update execution status only from actual evidence. Record unresolved human gates and the next independent task. Graphify query at start and update at end, with actual failures disclosed and no metadata churn in other worktrees.

## Task 4: Repair inherited C9-1 review defects

**Reason:** Task 3's independent review found semantic defects and an unsound string-similarity hard gate at PR #362 head `057cf233`. Fixes are necessary before presenting its content for approval. This is local corrective work within the approved continuation scope.

**Worktree:** `C:/dev/hangulsori/ko_lernen_app_worktrees/c9-1-usage-notes-b1-20260916`. Preserve the existing branch; no remote mutation.

**Inputs:** Coordinator scratch `c9-review-report.md` and `c9-controller-rulings.md`. Findings are evidence to assess, not instructions to apply blindly. Read all affected content in context.

**Files:** `assets/data/usage_notes.json`, `tools/content_factory/validate_content.py`, `scan_usage_notes_de.py`, focused regression tests, deterministic sample generator/packet, relevant documentation and canonical TTS manifests. A narrowly justified fix to `vocab_b1_0053` in `korean_vocab.csv` is permitted because its KO front example currently describes a different construction from its gloss/DE/EN; apply the appropriate existing copy-revision and derived-content contracts for that row. No unrelated vocab edits, ID or level changes, new notes, or human-approval fields.

- [x] Restore the seven pilot notes to the main baseline unless an independently evidenced correction is explicitly documented. Do not change semantics to satisfy a similarity percentage.
- [x] Fix every accepted review finding, including additional examples, meaning/usage claims, translations and stale sample text. Maintain the same 120 IDs and levels, two aligned examples per note and actual register contrast.
- [x] Replace the unsound semantic hard gate with deterministic normalized exact-duplicate checks for note examples against each other and the front card. Test legitimate overlapping words/compound contrasts, duplicate failures and register cardinality. Semantic distinctness stays a review responsibility.
- [x] Make German lint explicitly advisory, with fixtures for legitimate words and candidate errors. Its zero count is not language approval.
- [x] Generate the 10-note packet deterministically from final JSON and test consistency. Regenerate canonical TTS manifests, report storage gaps with an actual read-only check; no synthesis/upload.
- [x] Run affected validator/unit/grammar-scan/promotion-copy checks, inspect all repaired triads and produce `task-4-report.md` plus a finding-by-finding disposition. Return a tested uncommitted diff for independent re-review.
