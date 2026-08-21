# Handoff: Batch 1 content-text humanization and exact-level selection

## Session Metadata
- Created: 2026-08-21 21:29:59
- Project: C:\dev\hangulsori\ko_lernen_app_worktrees\content-humanization-20260821
- Branch: `codex/content-humanization-20260821`
- Session duration: current Codex session

## Recent Commits (for context)
  - 3d9ad720 Merge pull request #175 from Sujin-Arin-DataWorld/session/uiux-bible-4a-profile-2026-08-21
  - 9d43621a feat(profile): expose accessible settings action
  - 70df05a5 Merge pull request #174 from Sujin-Arin-DataWorld/session/uiux-bible-4a-stats-2026-08-21
  - 56be6108 feat(stats): localize weekly progress semantics
  - 031a52ff Merge pull request #173 from Sujin-Arin-DataWorld/session/uiux-bible-learning-3d-sarangbang-closeout-2026-08-21

## Handoff Chain

- **Continues from**: [2026-08-20-130642-uiux-bible-reconciliation.md](./2026-08-20-130642-uiux-bible-reconciliation.md)
  - Previous title: 2026-08-20-130642-uiux-bible-reconciliation
- **Supersedes**: None

## Current State Summary

This isolated worktree contains the complete A1-C2 content-humanization change before Git integration. It audits all 22 learner-data surfaces, humanizes 174 Batch 10 scenarios and 60 Smalltalk records, preserves can-do semantic review while marking copy changes `nativeReviewRequired`, corrects seven advanced C1/C2 scenario PIVOTs, and prevents C-level today/review/personalized decks from filling with lower-level words such as `안녕하세요`. Local scoped gates pass. No TTS synthesis, upload, Firebase deployment, native-speaker review, or educator approval has occurred.

## Codebase Understanding

## Architecture Overview

`assets/data` is the shipped learner-content layer; `tools/content_factory/data` is the generated source layer; `tools/content_factory/drafts` and `review` preserve the authoring/review trail. Scenario source builders generate the drafts, and runtime JSON must retain stable IDs, grammar forms, and loader-compatible schemas. Daily practice chooses candidates through `DailyChallengeScreen`, `ReviewDeckService`, `PersonalizedLessonService`, and `StorageService`; allowing lower-level fallback at these points leaks A1 cards into C-level practice.

## Critical Files

| File | Purpose | Relevance |
|------|---------|-----------|
| `docs/CONTENT_TEXT_HUMANIZATION_WORKLIST_2026-08-21.md` | Scope, counts, checklist, test baseline | Resume from this worklist rather than recounting surfaces |
| `tools/content_factory/audit_content_text.py` | Classifies all 22 shipped data files and scans learner copy | Run with `--check` before further content work |
| `lib/screens/daily_challenge_screen.dart` | Daily challenge pool selection | Must remain exact-level, never cumulative fallback |
| `lib/services/review_deck_service.dart` | New and due review card selection | Passes exact candidate IDs to today-goal selection |
| `assets/data/scenarios_c1.json` and `assets/data/scenarios_c2.json` | Shipped scenario runtime data | Seven PIVOT title/intro edits are here |
| `tools/content_factory/data/batch_11_scene_scripts.py`, `batch_15_c1*.py`, `batch_16_c2_*.py` | Scenario source of truth | Keep source, draft, review, and runtime synchronized |

## Key Patterns Discovered

- Treat one content unit as source -> draft -> review -> runtime; preserve IDs and target forms.
- Keep source PDFs clean-room: store only generalized instructional signals, never wording, page identifiers, or OCR text.
- DE and EN text must be independently natural, not mechanically shaped like the Korean source.
- Scheduled review selection needs the same level guard as new-card selection, otherwise overdue A1 cards contaminate C-level decks.
- Existing `build_can_do_segments` approval fingerprints are a review gate, not values to rewrite merely to silence failing tests.

## Work Completed

## Tasks Finished

- [x] Classified all 22 shipped content data files: 15,189 records and 73,880 learner-text values.
- [x] Added a worklist with loader-aware B1-C2 scenario/smalltalk/cloze/Satz counts and a next-batch checklist.
- [x] Updated seven C1/C2 scenario PIVOT translations across source, draft, review, and runtime layers.
- [x] Made daily challenge, review deck, and personalized lesson selection exact-level when a level is selected.
- [x] Added regression tests for a C-level overdue `안녕하세요` card and content-audit classification/marker checks.
- [x] Replaced generic grammar explanations and global filler distractors in 174 Batch 10 scenarios with level- and scene-specific copy while preserving shelf/backdrop routing.
- [x] Revised 104 DE/EN fields across 60 A1-C2 Smalltalk records through an append-only before/after ledger.
- [x] Updated 42 A1-B2 can-do phrase fingerprints without rewriting semantic approval history; every changed copy record carries a native-review gate.
- [x] Recorded the full content-factory-suite failures against a clean `origin/main` baseline; the task tree has 3 failures / 20 errors versus baseline 4 / 20.

## Files Modified

| File group | Changes | Rationale |
|------|---------|-----------|
| `docs/CONTENT_TEXT_HUMANIZATION_WORKLIST_2026-08-21.md` | New worklist, counts, scope, baseline failures | Makes later content work measurable and repeatable |
| `tools/content_factory/audit_content_text.py`, `test_audit_content_text.py` | New all-surface classifier and tests | Prevents unnoticed learner-data files or placeholder copy |
| `lib/screens/daily_challenge_screen.dart`, `lib/services/storage_service.dart`, `lib/services/review_deck_service.dart`, `lib/services/personalized_lesson_service.dart` | Exact-level candidate filtering including due reviews | Stops A1 filler from appearing in C-level daily content |
| `test/daily_challenge_test.dart`, `test/today_goal_test.dart`, `test/review_deck_order_test.dart`, `test/personalized_lesson_test.dart` | Updated/additional level-contamination regressions | Proves the selection contract locally |
| `assets/data/scenarios_c1.json`, `assets/data/scenarios_c2.json` | Seven C1/C2 PIVOT copy edits | Ships naturalized scenario titles and introductions |
| `assets/data/scenarios_a1.json` through `scenarios_c2.json`, `build_level_content_4x.py` | 174 scene-specific grammar and distractor rewrites | Removes repeated placeholder game copy without changing IDs or answers |
| `assets/data/smalltalk.json`, `tools/content_factory/review/content_humanization_20260821.json`, `tools/content_factory/apply_content_humanization.py` | 60 records / 104 DE-EN field revisions | Makes current copy reproducible without altering historical approval files |
| `assets/data/can_do_content_authorities.json`, `build_can_do_segments.py` | 42 copy fingerprints plus explicit native-review gates | Separates semantic-route approval from copy-quality approval |
| `tools/content_factory/data/batch_11_scene_scripts.py`, `batch_15_c1a.py`, `batch_15_c1b.py`, `batch_15_c1c.py`, `batch_16_c2_aesthetic.py`, `batch_16_c2_history.py`, `batch_16_c2_representation.py` | Matching scenario source edits | Preserves source-to-runtime traceability |
| `tools/content_factory/drafts/c1_batch11_scenarios_a1_c2.json`, `c1_batch15_scenarios_c1.json`, `c1_batch16_scenarios_c2.json`, `tools/content_factory/review/c1_batch15_scenarios.csv` | Matching draft/review edits | Keeps review artifacts aligned with runtime data |

## Decisions Made

| Decision | Options Considered | Rationale |
|----------|-------------------|-----------|
| Use exact level rather than cumulative lower-level fallback | Fill a full round with easy lower-level cards; return a shorter exact-level round | C-level `안녕하세요` is a product-quality failure, not a useful fallback |
| Revise diagnosed scenario and Smalltalk copy only | Rewrite every leaf cosmetically; preserve already-natural text | Full coverage means every leaf is dispositioned, not that correct copy must churn |
| Promote only ledgered Smalltalk copy revisions | Rewrite historical approval files; leave machine-like copy live | The append-only ledger preserves before/after evidence and requires native review before a native-quality claim |
| Keep global factory failures as baseline debt | Update fixtures/hashes until the suite is green | The task tree has 3 failures / 20 errors versus 4 / 20 on clean `origin/main` |

## Pending Work

## Immediate Next Steps

1. Obtain DE/EN native-speaker and Korean-education review before claiming native-reviewed quality; the runtime copy is already updated but explicitly gated.
2. Repair historical content-factory fixture/overlay/reference-intake failures in a separate scoped change; rerun the full suite after each repair.
3. If desired, design an explicit cumulative review mode rather than silently reintroducing lower-level cards into exact-level daily content.

## Blockers/Open Questions

- [ ] The revised Smalltalk copy cannot be represented as native-reviewed until an actual qualified reviewer approves it.
- [ ] The application needs a product decision if a selected level has fewer candidates than a desired daily round: current behavior deliberately shows fewer rather than lower-level cards.

## Deferred Items

- TTS synthesis and upload: not authorized. Dry-run enumerated 11,439 deduplicated utterances and confirmed no authentication, synthesis, write, or upload; changed audio paths are 0.
- Device, Firebase, and production verification: not run. GitHub Actions and exact integrated-main evidence must be appended after push.
- Historical content-factory debt: 199 tests currently end with 3 failures and 20 errors, compared with 4 failures and 20 errors on the clean baseline.

## Context for Resuming Agent

## Important Context

The user explicitly noticed that a C-level today view could show `안녕하세요`. The original UI candidate list was level-correct, but due-review IDs were later pooled without a level filter. The implementation now makes candidate sets exact-level in the daily challenge, review deck, and personalized lesson paths. Do not undo that behavior to force a fixed question count. The audit confirms B1-C2 game assets are not empty in total: B1 has 73 scenarios/72 smalltalk/275 cloze/468 Satz; B2 68/100/361/519; C1 45/32/220/222; C2 41/32/220/222. A blank game screen is therefore likely route/filter/selection behavior and needs UI-path diagnosis, not a claim that content does not exist. The seven scenario edits are source/draft/runtime synchronized. No human reviewer has signed off on the broader corpus or new Smalltalk copy.

## Assumptions Made

- A selected course level should only receive same-level practice cards, including overdue reviews.
- The user requested text-quality upgrades but did not authorize TTS, deployment, or bypassing review gates.
- Existing stable IDs, answer forms, and scenario quest schemas must be preserved.

## Potential Gotchas

- `DailyCharService` rotates Hangul characters, not vocabulary; do not confuse it with the today-word issue.
- `python -m unittest discover -s tools/content_factory -p 'test_*.py'` currently has 3 failures and 20 errors on this branch; clean `origin/main` had 4 failures and 20 errors. It is baseline-qualified, not green.
- Builders can rewrite unrelated batch artifacts during the full test suite. Inspect and restore non-task generated output before staging.
- Windows Git emits CRLF normalization warnings for some edited Python/JSON files; `git diff --check` has no whitespace errors.
- Never update content-approval hashes only to make tests pass.

## Environment State

## Tools/Services Used

- Beyond Humanizer skill validation scripts: Unicode and rejected-phrase checks.
- Python content validators and `tools/content_factory/audit_content_text.py --check`.
- Focused Flutter analysis and regression tests.
- Temporary detached clean `origin/main` worktree for failure baseline; it was removed after comparison.

## Active Processes

- None started by this work.

## Verification Snapshot

- Full `flutter analyze`: passed with no issues.
- Focused exact-level and content-loader Flutter tests: 100 passed.
- Full Flutter run: the first pass had 4,430 passed, 14 skipped, and 3 failed. All three task-induced causes (dash, Smalltalk fingerprint, and Batch 10 routing overwrite) were fixed; 13 related focused tests now pass, including `course_unit_balance_test`.
- Beyond Humanizer Unicode and rejected-phrase validators: passed.
- TTS dry-run: 11,439 deduplicated utterances, 149,257 Korean characters, no authentication/synthesis/write/upload.

## Environment Variables

- No task-specific environment variables were set.

## Related Resources

- `AGENTS.md`
- `docs/CONTENT_AUTHORING_GUIDE.md`
- `docs/CONTENT_SOURCE_POLICY.md`
- `docs/CONTENT_TEXT_HUMANIZATION_WORKLIST_2026-08-21.md`
- `docs/REFERENCE_ABSTRACTION_AUDIT_2026-08-15.md`
- `tools/content_factory/validate_content.py`

---

**Security Reminder**: `validate_handoff.py` must be run after any update to this document.
