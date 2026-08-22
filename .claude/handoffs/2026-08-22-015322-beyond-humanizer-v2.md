# Handoff: Beyond Humanizer v2

## Session Metadata

- Created: 2026-08-22 01:53:22 Europe/Berlin
- Project: `C:\\dev\\hangulsori\\ko_lernen_app_worktrees\\beyond-humanizer-v5`
- Branch: `session/beyond-humanizer-v5-2026-08-21`
- Implementation commit: `2dde092f6d7ced3e61307e4c619bc439b43ceef8`
- Remote state: `origin/main` matched the implementation commit after direct push

## Current State Summary

`beyond-humanizer` now covers direction-aware KO↔EN/DE translation and simultaneous, consecutive, and dialogue interpreting. The repository skill and the global installation at `C:\\Users\\vjinn\\.agents\\skills\\beyond-humanizer` are identical for all 12 skill files. No app content, ARB data, Firebase state, or production service changed.

## Architecture Overview

The short canonical `SKILL.md` routes conditional work into focused references. Platform-specific Claude and Cursor files point back to the canonical skill, while `evals.json` retains demonstrated failures and non-regression cases.

## Critical Files

| File | Purpose |
|---|---|
| `.agents/skills/beyond-humanizer/SKILL.md` | Canonical router and preservation contract |
| `.agents/skills/beyond-humanizer/references/directionality-and-underspecification.md` | Four direction modes, missing-information ledger, deixis/TAM/reference rules |
| `.agents/skills/beyond-humanizer/references/interpreting-mode.md` | Spoken-mode buffering, omission, prediction, and repair rules |
| `.agents/skills/beyond-humanizer/references/evidence-and-corpus.md` | Corpus evidence ladder, licensing, reviewer roles, evaluation matrix |
| `.agents/skills/beyond-humanizer/evals/evals.json` | RED/GREEN behavior and forward evaluations |

## Work Completed

- [x] Researched Korean–English and Korean–German pragmatics, honorifics, deixis, tense/aspect, modal particles, and interpreting directionality.
- [x] Used `find-skills`; no third-party candidate covered the combined Hangul Sori contract.
- [x] Added `REF`, `INDEX`, `DEIX`, `TAM`, and `INT` review dimensions.
- [x] Preserved English and German as independent reconstructions from the same semantic-pragmatic PIVOT.
- [x] Separated natural translation output from learner-facing cultural and linguistic notes.
- [x] Updated Claude and Cursor discovery wrappers.
- [x] Synchronized and hash-compared the global installed skill.

## Files Modified

- Canonical skill router, behavior evaluations, examples rubric, and research basis
- Three new references for directionality, interpreting, and evidence/corpus use
- Claude and Cursor discovery-wrapper descriptions

## Behavioral Evidence

- RED zero-anaphora test invented Minji as reviewer and Hyunwoo as callback target; GREEN retained unresolved reference and gender.
- RED `come/kommen` test correctly chose `가다` but invented `네` and banmal; GREEN retained `가다`, continuing residence, and safe relationship-neutral wording.
- Explicit team-lead honorific translation and late-predicate simultaneous interpreting remained green.
- A forward `doch` test produced different Korean resources for invitation softening and shared-ground reminder.

## Verification

- `quick_validate.py`: canonical, Claude wrapper, and Cursor wrapper valid
- Canonical `SKILL.md`: 499 whitespace-delimited units; 8 references; 0 missing
- `evals.json`: valid JSON
- `validate-unicode.py`: no U+FFFD in scanned product data
- `validate-rejected-phrases.py`: clean
- `git diff --check`: clean before commit
- Global sync: 12 files SHA-256 identical

## Decisions Made

| Decision | Rationale |
|---|---|
| Add a missing-information ledger before translation | Target-language grammar must not turn unresolved source information into invented facts |
| Keep written translation and interpreting as separate routed modes | Spoken work has time-axis, prediction, omission, and repair constraints |
| Do not install a generic third-party skill | Available candidates were spelling, framework localization, broad pragmatics, or generic tutoring tools |
| Keep human review as a gate | Linguistic research and behavior tests do not prove native-speaker or professional-interpreter acceptance |

## Pending Work

## Immediate Next Steps

1. No implementation action is required for this change.
2. For future content batches, invoke the global `beyond-humanizer` skill and preserve its RED/GREEN eval cases.
3. Expand the four-direction evaluation matrix only when real learner or reviewer failures justify new cases.

### Blockers/Open Questions

- None for the skill update.

### Deferred Items

- Native EN/DE, Korean-language educator, and professional interpreter review remains a human quality gate.
- No app dataset was rewritten or promoted during this task.

## Important Context

The implementation is already on `origin/main` at `2dde092f6d7ced3e61307e4c619bc439b43ceef8`; this handoff is the only post-implementation file. The original main checkout remains dirty with unrelated user assets and was not edited.

## Assumptions Made

- General learner content without a specified Korean relationship may use safe 해요체 only when the uncertainty is acknowledged.
- Research-backed rules remain hypotheses until pair-specific behavior tests and the relevant human reviewer confirm them.

## Potential Gotchas

- The main checkout contains unrelated user work; continue using isolated worktrees.
- Direct KO↔DE and Korean–German interpreting research is thinner than KO↔EN evidence. Do not promote narrow studies to universal rules.
- Corpus frequency validates candidates; it does not prove meaning or pragmatic fit, and licensed corpus sentences must not be copied into app data.

## Environment State

- Active processes: none
- Persistent environment variables added: none
- External mutation: implementation commit pushed directly to `origin/main` with explicit user authority

---

**Security Reminder**: This handoff contains no credentials or secret values.
