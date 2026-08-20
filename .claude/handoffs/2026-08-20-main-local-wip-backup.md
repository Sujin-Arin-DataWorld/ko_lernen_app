# Main local WIP backup — 2026-08-20

## Purpose

This branch is a preservation snapshot only. It must not be merged into
`main` as a feature branch.

## Snapshot

- Base: `origin/main` at `9ba9af4befd2860da60544153d3d568348ac364a`
- Source checkout: conflicted local `main` at
  `d46eab756e6a99bffd44c344bf37cb6fbf8db677`
- Preserved: 164 files plus 5 tracked deletions, 97,119,843 bytes
- Includes the unapproved Chaekgado source/runtime packs, Hanok asset audit
  documents, the UI/UX audit proposal, and main-only optimized assets.
- The source/runtime packs and audit proposal are backup material only. They
  are not approved runtime assets or an implementation SSoT.

## Deduplication

41 byte-identical mascot, decoration, and sticker binaries were intentionally
excluded here. Their sole preservation branch is
`session/mascot-decoration-assets-2026-08-20`.

## Integrity record

The pre-commit SHA-256 inventory is stored outside all worktrees at:

`C:/Users/vjinn/.codex/visualizations/2026/08/20/01a01e9a-b0f5-7483-818d-c2c4f5f29f35/wip-sha256-manifest-20260820.tsv`

Inventory SHA-256:
`0e9d9e22228f49cd06ccd949f38b80ab50481774029152dde0f5aa0cfc9eb688`

## Verification

- Binary and document preservation is verified by the SHA-256 inventory.
- No Flutter runtime integration is claimed for the unapproved asset packs.
- The backup retains the local CI and SESSION_LOG snapshot exactly for
  recovery; current `main` policy still abolishes per-change SESSION_LOG use.
