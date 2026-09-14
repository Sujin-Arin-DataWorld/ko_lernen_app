# Release consolidation and iOS App Review submission

## Updated user goal
The user explicitly updated the goal during execution: exclude Hanok-image-related PRs, integrate outstanding valid non-Hanok changes, fix remaining release problems, reclaim safely merged worktrees after preservation checks, and complete the iOS build plus real iPad screenshots, German/English release copy and App Review submission. This supersedes the former build/upload-only limit for iOS. Android execution is deferred while this iOS goal is completed. Mixed Hanok/onboarding PR #299 is excluded as a whole; its prepared integration is preserved externally and removed from the release candidate. PR #232 was already closed as superseded under explicit user approval. No iOS review submission has occurred yet.

Current remote main advanced to asset-only commit `3b6d1ca1327d7429b6bf6f244aea8f61f09bc97d`, with successful CI and Playwright. Those already-committed user assets remain untouched and will be included by merging current main; excluding open artwork PRs does not undo existing main.

The user requires outstanding non-Hanok PRs and this task's local optimization to be integrated and reverified before release. Necessary commits, PR updates, verified merges, signed iOS upload, screenshot/metadata updates and App Review submission are authorized. This does not authorize erasing unique work, publishing unfinished artwork or inventing construction progress. Original work must remain recoverable; local cleanup follows the standing safe-worktree audit rules.

## Authoritative inputs
- Stabilized local parent: b5461b3cc3d727a9fe238e5971b5fcce704dae2b (includes Tasks 1-49; do not redispatch them).
- Initial integration main: fecc0a038a2dd0281888a6047128920ab1a6d9b5 (#301 Phase learning evidence plus #303 native audio recovery); current main is3b6d1ca1 as recorded above.
- Open PRs: #294 remote520bc7d1 is superseded by local parent; #285 head24bd00d2; #246 heade599e09c; #299 headc2e6afa1; #232 head89bd112e. Exact metadata is externally archived in C:/dev/hangulsori/_codex_artifacts/release-consolidation-20260913.

## Required behavior
1. Preserve merged Phase assessment, v5 learning evidence, native audio/plugin recovery and all stabilized local privacy, account, migration, reset, course progress and cache durability behavior. Resolve overlapping semantics, never choose a whole parent merely to make tests pass.
2. Review every open PR against current main; integrate valid unique changes and identify superseded or incomplete changes explicitly. Do not revive retired V1 runtime or silently promote unapproved construction artwork or quiz rewards.
3. Preserve the validated Android public-testing workflow and unique versionCode logic, but defer Android execution for this iOS goal. iOS requires a signed build accepted by App Store Connect, current real screenshots and localized metadata, followed by verified App Review submission. Unsigned CI is not upload evidence.
4. Pin final commit, meaningful local tests and independent spec/standards reviews, PR checks and merged-main checks before release. Reuse unchanged tests only with exact input evidence; new combined behavior needs focused regressions and final suite.
5. Preserve original main user asset WIP and both prior local branches; never read or remove local android/key.properties. Keep paid Graph labels/signatures and semantic/wiki records recoverable. No mass dependency upgrades or repeated paid builds.
6. Store actual SHA, build number, bundle checksum/signature, upload and processing outcome separately. Report any remaining device, console or human gate accurately.
