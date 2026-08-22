# Handoff: Beyond Humanizer v3

## Session Metadata

- Created: 2026-08-22 12:06 Europe/Berlin
- Project: C:\dev\hangulsori\ko_lernen_app
- Working branch: codex/beyond-humanizer-v3
- Delivery target: origin/main

## Current State Summary

Beyond Humanizer v3 is implemented and locally validated in an isolated worktree. The update adds explicit evidential-source, modal-force, and presupposition safeguards; expands the evaluation matrix from 8 to 20 cases across all four KO/EN/DE directions; and records reproducible RED and GREEN pressure tests. The repository version has been copied to the global skill installation with 17/17 SHA-256 matches. This handoff is included in the delivery commit; verify the final origin/main commit and CI in Git history before any later release claim.

## Codebase Understanding

## Architecture Overview

The skill entrypoint stays concise and routes work to focused reference documents. Evaluation data and its schema live under the skill's `evals` directory, while small Python validators enforce structure, Unicode safety, and known semantic regressions. Model-based audits are evidence for failure discovery and regression checking, but the skill deliberately leaves native-speaker, linguist, educator, and professional-interpreter review as an external human gate.

## Critical Files

| File | Purpose | Relevance |
|---|---|---|
| `.agents/skills/beyond-humanizer/SKILL.md` | Runtime workflow and critical gates | Adds EVID, FORCE, and PRESUP to the core PIVOT and audit |
| `.agents/skills/beyond-humanizer/references/evidentiality-modal-force-presupposition.md` | Operational linguistic rules | Prevents report-chain, request-force, and background-assumption drift |
| `.agents/skills/beyond-humanizer/evals/evals.json` | Four-direction regression matrix | Holds 20 cases with expected and forbidden implications |
| `.agents/skills/beyond-humanizer/evals/v3-results.json` | RED/GREEN evidence ledger | Records exact outputs, limits, and aggregate results |
| `.agents/skills/beyond-humanizer/scripts/validate-evals.py` | Evaluation-contract validator | Rejects missing fields, duplicate IDs, malformed values, and direction gaps |

## Key Patterns Discovered

- Fluency can hide semantic drift: v2 repeatedly converted Korean reportative layers into `apparently`, `offenbar`, or `wohl`, and sometimes reattached `팀에서` as schedule ownership.
- German optional suggestions containing `ja` were repeatedly turned into Korean permission constructions such as `-아도 돼요`.
- A Korean `-요` ending alone does not make a request relationship-neutral; endings inside 해요체 still index familiarity and honorification.
- On Windows, run Korean validators with `python -X utf8`.

## Work Completed

## Tasks Finished

- [x] Captured six fresh-context v2 RED baseline runs and exact self-audit misses.
- [x] Added the EVID/FORCE/PRESUP operational reference and direction-specific safeguards.
- [x] Expanded the matrix to 20 cases and all four translation directions.
- [x] Added schema validation with six unit tests, including malformed-input handling.
- [x] Completed five sentinel GREEN runs, five post-refinement targeted runs, and a 20/20 independent matrix audit with legacy 8/8 non-regression.
- [x] Synchronized 17 skill files to the global installation with zero SHA-256 mismatches.

## Files Modified

| Area | Changes | Rationale |
|---|---|---|
| `.agents/skills/beyond-humanizer/SKILL.md` | Compressed entrypoint with three new semantic-pragmatic axes | Keep runtime instructions below 500 words while making critical gates explicit |
| `.agents/skills/beyond-humanizer/references/` | Direction, language, culture, rubric, evidence, research, and Unicode guidance | Put detailed linguistic rules in routed references |
| `.agents/skills/beyond-humanizer/evals/` | Schema, 20 cases, tests, and v3 evidence ledger | Make regressions reproducible and auditable |
| `.agents/skills/beyond-humanizer/scripts/` | Evaluation validator and broader Unicode scan | Fail closed on malformed contracts and replacement characters |

## Decisions Made

| Decision | Options Considered | Rationale |
|---|---|---|
| Track source chain, commitment, force, and presupposition separately | A single broad pragmatics label | The v2 failures were fluent and escaped a broad self-audit |
| Treat suspect phrases as context-dependent, not globally banned | Add `apparently`, `offenbar`, `예정대로`, and `괜찮아요` to a rejection list | Those forms are valid in licensed scenes; the forbidden object is the implication shift |
| Use a v2 control instead of claiming a no-skill control | Disable the matching installed skill | The environment requires matching skills, so a true no-skill Codex control would be dishonest |
| Keep human review external | Claim model consensus as linguist validation | Five-run and 20-case model audits do not replace independent human expertise |

## Pending Work

## Immediate Next Steps

1. For future production translations, apply v3 and add real learner or reviewer feedback as new evaluation cases.
2. Arrange blind KO authority, EN native, DE native, Korean educator, and interpreter review before claiming expert validation.
3. Run all skill validators whenever the evaluation contract or reference rules change.

## Blockers/Open Questions

There is no implementation blocker. The only intentionally open gate is external human review; it is not required for this code delivery and must not be represented as already completed.

## Deferred Items

- Production app-content rewrites are deferred because this delivery changes only the globally installable skill and its evaluation evidence.
- Corpus-derived learner examples are deferred until licensing, redistribution terms, and target genre are confirmed.

## Context for Resuming Agent

## Important Context

Do not weaken `SOURCE-SPECIFIED | TARGET-REQUIRED | CONTEXT-SUPPORTED | UNRESOLVED`. For the sentinel report sentence, `팀에서` is a source or setting unless ownership is separately supported; the second `-래요` layer must remain reported. For `still coming`, preserve the prior plan without inventing motion, `예정대로`, gender, or a closer relationship. For `Du kannst ja ... wenn du willst`, preserve an optional suggestion rather than permission.

## Assumptions Made

- The app's general learner-content fallback remains a minimally committed 해요체 when Korean relationship metadata is absent.
- `de-DE` and natural international English remain the default target varieties unless a task supplies another locale.
- Global installation target is `C:\Users\vjinn\.agents\skills\beyond-humanizer`.

## Potential Gotchas

- Do not add context-sensitive words to the rejected-phrase list merely because one isolated use failed.
- Model self-audit is not independent human validation, even when several model families agree.
- The shared main checkout contains unrelated untracked visual assets; never stage or delete them during skill work.
- CRLF conversion warnings are expected on Windows; `git diff --check` is the whitespace gate.

## Environment State

## Tools/Services Used

- Python with UTF-8 mode for evaluation, Unicode, and skill validation.
- Git isolated worktree based on the then-current origin/main.
- Fresh-context Luna, Terra, and Sol agents for RED/GREEN pressure testing.

## Active Processes

No development server, watcher, or long-running validator is required.

## Environment Variables

No task-specific environment variables are required and no secret values are stored here.

## Related Resources

- `.agents/skills/beyond-humanizer/references/research-basis.md`
- `.agents/skills/beyond-humanizer/references/evidence-and-corpus.md`
- `.agents/skills/beyond-humanizer/evals/schema.json`
- `.agents/skills/beyond-humanizer/evals/test_validate_evals.py`
