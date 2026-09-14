# Release Consolidation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Consolidate outstanding non-Hanok PR changes and local optimization, verify main, submit the new iOS version with genuine DE/EN iPhone/iPad screenshots, and reclaim disk space from proven-safe merged worktrees. Android upload is deferred.
**Architecture:** Preserve the proven local parent and merge current main in an isolated worktree, integrate remaining changes by ownership and contract, then run exact-source verification before release.
**Tech Stack:** Flutter/Dart, Node22, Python, GitHub Actions, Google Play, Xcode Cloud/App Store Connect.
**Spec:** docs/superpowers/specs/2026-09-13-release-consolidation-design.md

**Updated goal takes precedence:** Exclude open Hanok-image PRs, including mixed #299 (preserved externally); complete non-Hanok integration, safe merged-worktree cleanup and iOS App Review submission. Android build/upload is deferred. Task 3 integration is superseded; retain the #232 disposition and #299 exclusion evidence. Task 5 now includes native screenshots and review submission as detailed below.

## Global Constraints
- Main fecc0a03 and local b5461b3c behavior must both survive.
- No V1 revival, unapproved artwork promotion, invented learning rewards or destructive workspace cleanup.
- Public testing is the Android target. Signed App Store Connect acceptance is the iOS build target.
- Current main asset commit 3b6d1ca1 and paid Graph records remain preserved.
- Only root mutates Git refs/index, Graph outputs and release controls. Workers own explicitly assigned source paths.

### Task 1: Combine stabilized local behavior with merged Phase learning/audio
**Files:** lib/main.dart; lib/services/course_mastery_service.dart; lib/services/tts_service.dart; lib/l10n/app_{de,en}.arb and generated Dart; automatically merged account/course/phase services and their relevant tests.
**Consumes:** exact b5461b3c and fecc0a03 contracts.
**Produces:** coherent combined candidate, focused regressions and static analysis proof.
- [x] Resolve conflict hunks semantically; preserve startup ordering, privacy closure/reset durability, Phase v5 evidence and native audio recovery.
- [x] Inspect automatically merged interfaces and add only meaningful integration regressions.
- [x] Run focused affected tests and analyzer; record exact changed sources and commands.
- [x] Independent spec and standards review; resolve actionable findings.

### Task 2: Integrate unique release/update and content-review tooling
**Files:** PR #285 release workflows, versionCode logic, app_update_service/settings and tests; PR #246 tools/content_factory/scenario_revision_review.py and review fixtures/tests.
**Consumes:** audited PR heads and Task1 candidate.
**Produces:** current release/update logic and readonly reviewed tooling without runtime content promotion.
- [x] Apply validated unique changes; resolve settings/l10n/CI overlap with Task1.
- [x] Validate public-track version uniqueness, release guards and app-update fallback; run relevant Flutter/Python contracts.
- [x] Verify canonical corpus/index binding on current sources and separate merge of tooling from approval/application of generated content.
- [x] Independent reviews and fixes.

### Task 3: Preserve current V3 and excluded Hanok PRs
- [x] Close #232 as superseded under the user's explicit decision; do not merge it or delete its branch.
- [x] Exclude the entire mixed Hanok-image PR #299 under the updated goal. Preserve the attempted UI port externally and restore the original candidate UI. Keep #299 open as draft.

### Task 4: Verify and merge consolidated source
- [ ] Refresh Graph once after source settles, preserve paid records; validate sources/assets and package locks.
- [ ] Run full relevant suite, strict analysis and final independent two-axis review.
- [ ] Commit/push reviewable changes, update PR descriptions around final behavior, verify exact PR-head checks.
- [ ] Merge verified PRs and verify exact merged-main required checks; preserve cleanup evidence before removing any eligible worktree.

### Task 5: Build and upload requested candidates
- [ ] Inspect live Play tracks and App Store Connect/Xcode Cloud to avoid duplicate runs.
- Android public-testing upload is deferred by the updated iOS-only goal; preserve the verified pipeline code.
- [ ] Produce signed exact-main iOS build and verify App Store Connect acceptance/processing.
- [ ] Report exact IDs, SHA, outcome and remaining actual-device gates.

### Updated iOS completion and cleanup
- [ ] Re-audit all current open PRs; account for valid integration and explicitly excluded Hanok-image work.
- [ ] Capture real final-source iPad 13-inch and iPhone screenshots in DE/EN on iOS simulator/device; validate PNG dimensions/alpha and visually inspect all selected images. Never substitute web captures or generated mockups.
- [ ] Verify current store metadata, update DE/EN descriptions/release notes and screenshot sets to actual current behavior, attach the processed new signed build, add to review and submit App Review under the user's updated explicit authorization.
- [ ] Verify the resulting submission status and record build/version/source identity. Apple approval is external; submission is not approval.
- [ ] After exact merged-main required checks pass, freshly audit each eligible worktree including ignored files, paid Graph and unique artifacts, active processes, nested repos and preservation hashes. Remove only proven safe paths with git worktree remove; keep user main and active/unique work. Report reclaimed disk space separately from RAM.
