# Handoff: Hanok Phase 0 visual canon and estate contracts

## Session Metadata

- Created: 2026-08-21 00:47:42 +02:00
- Project: `C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-level-phase0`
- Branch: `session/hanok-level-phase0-2026-08-20`
- Base: `origin/main` at `c64fbfa2`
- Implementation commit: `d3fb041f`

## Current State Summary

Phase 0 is implemented and verified on the latest `origin/main`. It defines the
review-only `estate_masterplan_v2`, the six level sockets and cameras, and the
complete 86-grant semantic remapping contract. The approved direction combines
Unjoru-derived spatial grammar with the legacy `hanok_compound` visual DNA. No
image, Firebase, generated runtime asset, or Flutter runtime change is included.
The next delivery action is to commit this handoff, push the branch, create a PR
against `main`, and wait for the final-head CI result without merging.

## Codebase Understanding

## Architecture Overview

`tools/content_factory/build_hanok_grants.py` remains the normalization and
validation boundary for the existing grant catalog. Phase 0 adds two adjacent
review contracts: one for the estate geometry and one for the semantic mapping
of all 86 existing grants. Both contracts are fail-closed and explicitly set
`runtimeEnabled` to `false`; they do not alter the published grant catalog.

## Critical Files

| File | Purpose | Relevance |
|------|---------|-----------|
| `docs/superpowers/specs/2026-08-20-hanok-phase0-estate-masterplan-v2.md` | Approved design, Work prompt, reference hashes, scope gates | Human authority for future image work |
| `docs/superpowers/plans/2026-08-21-hanok-phase0-visual-canon-contract.md` | Executed implementation plan | Records task order and acceptance checks |
| `tools/content_factory/drafts/estate_masterplan_v2.json` | Zones, sockets, cameras, visual and architectural canon | Machine-readable estate contract |
| `tools/content_factory/drafts/hanok_grant_remapping_v2.json` | Six level policies and 86 semantic mappings | Machine-readable reward contract |
| `tools/content_factory/build_hanok_grants.py` | Normalizer and fail-closed validator | Rejects contract drift and forbidden scope |
| `tools/content_factory/test_hanok_phase0_contract.py` | Phase 0 contract and mutation tests | Main regression proof |

## Key Patterns Discovered

- Grant IDs, order, learning authority, and source catalog are immutable in this
  phase; only semantic presentation targets are planned.
- `rear_garden` and independent `daecheongmaru` are retired structures.
- A1 uses `rebuildFromApprovedGoldenMaster`; A2-C2 remain `futureSocketOnly`.
- Concept IDs are semantic labels, not permission to render modern objects or
  readable text literally in the estate overview.
- The first image deliverable is one style keyframe. It is not a Golden Master
  and cannot enable runtime assets.

## Work Completed

## Tasks Finished

- [x] Reconciled the Phase 0 spec with the approved visual canon.
- [x] Locked Unjoru-derived spatial grammar without literal reconstruction.
- [x] Defined nine zones, six sockets, and six 4:3 camera viewports.
- [x] Remapped all 86 grants while preserving identity and order.
- [x] Added fail-closed normalization, schema, scope, and geometry validation.
- [x] Added positive and mutation tests for the full contract.
- [x] Rebased onto the latest `origin/main` and re-ran all relevant checks.

## Files Modified

| File | Changes | Rationale |
|------|---------|-----------|
| `docs/superpowers/specs/2026-08-20-hanok-phase0-estate-masterplan-v2.md` | Replaced obsolete layout/style authority and added final Work prompt | Make future image work reproducible |
| `docs/superpowers/plans/2026-08-21-hanok-phase0-visual-canon-contract.md` | Added executable plan | Preserve implementation intent and gates |
| `tools/content_factory/drafts/estate_masterplan_v2.json` | Added exact estate contract | Prevent geometry and camera ambiguity |
| `tools/content_factory/drafts/hanok_grant_remapping_v2.json` | Added all 86 remaps | Preserve learning identity while changing presentation |
| `tools/content_factory/build_hanok_grants.py` | Added review-contract validation and normalization | Fail closed on drift or scope violations |
| `tools/content_factory/test_build_hanok_grants.py` | Extended builder behavior coverage | Verify all three drafts normalize together |
| `tools/content_factory/test_hanok_phase0_contract.py` | Added 18-test suite | Prove structure, remaps, and rejection behavior |

## Decisions Made

| Decision | Options Considered | Rationale |
|----------|-------------------|-----------|
| Legacy `hanok_compound` is the visual DNA | Current Personal V2, legacy compound, complete restyle | It matches Hangul Sori's established warmth and dimensionality |
| Unjoru supplies spatial grammar only | Literal reconstruction, free fantasy, grammar adaptation | Keeps historical credibility without copying one house |
| One keyframe precedes a Golden Master | Ten-image batch, immediate production assets, one keyframe | Prevents style drift before batch generation |
| Review-only contracts | Runtime integration now, Firebase-backed state, offline contracts | Keeps Phase 0 narrow and reversible |

## Pending Work

## Immediate Next Steps

1. Commit this handoff and push the branch.
2. Create a PR against `main` and wait for CI on the exact final head.
3. In a separately authorized image session, generate only
   `hanok_visual_keyframe_01.png` from the prompt in the approved spec.

## Blockers/Open Questions

- No implementation blocker remains.
- Human approval of the future style keyframe is required before any Golden
  Master or level asset generation.

## Deferred Items

- Image generation and asset promotion: explicitly out of Phase 0.
- Flutter/runtime integration: requires approved Golden Master geometry.
- Firebase changes: explicitly prohibited for this phase.
- PR merge: explicitly prohibited; leave the PR open for review.

## Context for Resuming Agent

## Important Context

The JSON files are contracts, not runtime content. Do not flip
`runtimeEnabled`, add image paths, or treat a generated image as approved based
on file existence alone. The spec's single-reference Work prompt is the next
visual step. Its required reference is
`assets/illustrations/hanok_compound/sarangchae.png`, 1402 by 1122 RGBA, SHA-256
`1da81a60019b341d7581264aebf0a292b72e0951aaaab0c0e97ce25b229137db`.

## Assumptions Made

- The user remains the visual approval authority for the keyframe.
- The stable 86-grant source catalog remains the learning authority.
- `main` is the PR base, as stated in the task and branch history.

## Potential Gotchas

- The normalized ID-order hash includes a final newline. Its expected SHA-256
  is `c42bda92b974dd3867900b1178721aedd4e4add7bc8573f0d8a2e98f12a014ea`.
- The unchanged source grant file SHA-256 is
  `a407c80350f26d54d63bf46ce9babbb910476049ee8014c42adda2b3e6335f7f`.
- `conceptId` values may retain modern learning semantics, but the overview art
  must translate them into period-appropriate materials rather than literal
  modern props or readable labels.
- Keep this worktree after PR creation so review feedback can be addressed on
  the same branch.

## Environment State

## Tools/Services Used

- Python 3.13: builder, unit tests, and handoff validation.
- Git/GitHub CLI: isolated worktree, rebase, push, PR, and CI inspection.

## Active Processes

- None.

## Environment Variables

- No task-specific environment variables are required.

## Verification Evidence

- `build_hanok_grants.py --check --verify-git-history --base-revision origin/main`: passed.
- Unit tests: 18 passed.
- STYLE_LOCK documentation check: passed, all seven banners present.
- Existing `hanok_compound` asset check: seven assets passed.
- Python compile check: passed.
- `git diff --check`: passed.
- 86-grant identity/order and unchanged source-file hashes: passed.

## Related Resources

- `docs/superpowers/specs/2026-08-20-hanok-phase0-estate-masterplan-v2.md`
- `docs/superpowers/plans/2026-08-21-hanok-phase0-visual-canon-contract.md`
- `docs/assets/STYLE_LOCK.json`
