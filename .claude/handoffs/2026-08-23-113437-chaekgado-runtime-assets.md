# Handoff: Wire the approved Chaekgado listening asset pack

## Session Metadata

- Created: 2026-08-23 11:34:37
- Project: `C:\dev\hangulsori\worktrees\chaekgado-runtime-assets`
- Branch: `codex/chaekgado-runtime-assets`
- Base commit: `ead29ce8`
- Session duration: about one hour

## Current State Summary

The supplied `hangul_sori_chaekgado_asset_pack_v1` is now the runtime visual
system for the listening bookshelf and listening player. The implementation is
complete in this isolated worktree and deliberately has not been committed or
pushed.

## Codebase Understanding

### Architecture Overview

`ListeningScreen` creates level-specific shelf slots, `ChaekgadoShelfCase`
renders them, and `showChaekgadoScroll` opens the scenario picker.
`ListeningPlayScreen` renders the active scenario line. Asset paths and the
category-to-vignette mapping live in one new asset-catalog file.

### Critical Files

| File | Purpose | Relevance |
|------|---------|-----------|
| `lib/widgets/sori/chaekgado/chaekgado_assets.dart` | Pack paths and vignette mapping | Single source for all new runtime assets |
| `lib/widgets/sori/chaekgado/shelf_case.dart` | Variable-height bookcase and shelf cells | Uses top/middle/bottom slices; no stretched full bookshelf |
| `lib/widgets/sori/chaekgado/scroll_sheet.dart` | Three-slice scroll and short scroll card | Scenario picker and listening-line frame |
| `lib/screens/listening_screen.dart` | Shelf click flow | Chooses a matching vignette or book cluster for the picker |
| `lib/screens/listening_play_screen.dart` | Active listening line | Uses short scroll and hides the study mascot |

### Key Patterns Discovered

- Flutter asset directories do not recurse; every needed leaf directory is
  listed explicitly in `pubspec.yaml`.
- The approved bookcase has a two-column cell layout but must grow beyond its
  original source height. Repeating only the middle backplate/frame slice keeps
  the wood structure intact.
- Abstract C1/C2 slots with no meaningful supplied vignette intentionally use
  a book cluster alone rather than a misleading icon.

## Work Completed

### Tasks Finished

- [x] Replaced the old synthetic shelf wood, props, and scroll construction.
- [x] Registered the approved bookcase, scroll, book-cluster, and vignette assets.
- [x] Added category vignette mapping and fallback book clusters.
- [x] Reframed active listening text in the supplied short scroll card.
- [x] Added pack-path/mapping coverage and adjusted orphan-asset guarding.

### Files Modified

| File | Changes | Rationale |
|------|---------|-----------|
| `pubspec.yaml` | Registers approved runtime asset leaves | Bundles only assets actually used by the listening experience |
| `lib/widgets/sori/chaekgado/chaekgado_assets.dart` | New pack catalog and mappings | Prevents path/mapping drift |
| `lib/widgets/sori/chaekgado/shelf_case.dart` | Real sliced bookcase rendering | Preserves structure while supporting 15+ slots |
| `lib/widgets/sori/chaekgado/scroll_sheet.dart` | Real three-slice and short scroll frames | Reuses the supplied scroll system |
| `lib/screens/listening_screen.dart` | Uses mapped picker art | Connects shelf selection to the real pack |
| `lib/screens/listening_play_screen.dart` | Uses short scroll with responsive scaling | Keeps active study focused and overflow-free |
| `lib/data/chaekgado_shelf.dart` | Removes retired old-asset constants | Avoids stale runtime references |
| `test/chaekgado_shelf_test.dart` | Adds new pack assertions | Guards slices, clusters, and mapping contract |
| `test/asset_orphan_guard_test.dart` | Removes retired dynamic asset exemptions | Keeps bundle/orphan guard accurate |

### Decisions Made

| Decision | Options Considered | Rationale |
|----------|-------------------|-----------|
| Repeat the middle bookcase slice | Stretch one complete 2-row image, or repeat its middle | The source pack needs 15 slots; slice repetition preserves joinery proportions |
| Use book cluster for unmapped C1/C2 slots | Invent generic abstract icons, use old art, or no art | The supplied pack has no meaningful abstract vignette for these concepts |
| Do not register independent `decor/transparent` props | Add props to shelf cells, use supplied book/vignette pairs only | The supplied listening specification explicitly defines book cluster left and category vignette right |

## Pending Work

## Immediate Next Steps

1. Run the listening shelf and player manually on a device or Flutter web and visually approve crop/scale at phone and tablet sizes.
2. If the independent decoration props, including `01_cg_prop_fruit_soban.png`, should be used, define their target screen and mapping separately; they are intentionally not bundled for this listening-only composition.
3. After visual approval, have Jin review the worktree diff and explicitly request any commit or integration.

### Blockers/Open Questions

- [ ] Browser-driven visual QA could not run because the local `agent-browser` executable is not installed.
- [ ] The destination for independent decor props is not specified by the supplied listening composition.

### Deferred Items

- No device/browser screenshot was captured; targeted widget and responsive tests are the current proof boundary.

## Context for Resuming Agent

## Important Context

Do not edit the shared main checkout. All changes are in
`C:\dev\hangulsori\worktrees\chaekgado-runtime-assets`. Do not commit or push
without Jin's explicit authorization. The prior audit that reported the pack as
unused was valid for the old runtime, but no longer reflects this worktree.

### Assumptions Made

- The supplied asset-pack layout and written listening composition are approved
  as the runtime source of truth.
- The bookcase uses two columns and must support the existing 15-slot level
  layout.

### Potential Gotchas

- On small landscape/tall-text constraints, the short scroll needs its
  proportional inset and `FittedBox`; removing either reintroduces a render
  overflow.
- `flutter analyze` can hang in this Windows shell after orphaned Flutter test
  processes. `dart analyze` completed cleanly for all changed source/test files.
- Use `python -X utf8` for Korean-sensitive project scripts on this machine.

## Environment State

### Tools/Services Used

- `flutter pub get`
- `flutter test --no-pub`
- `dart analyze`
- `git diff --check`

### Active Processes

- No project test, analyzer, server, or device process is intentionally left running.

### Environment Variables

- None required.

## Related Resources

- `C:\Users\vjinn\.codex\attachments\9e84254e-d36a-4762-a8f4-4e8deeda00fb\pasted-text.txt`
- `docs/LISTENING_CARD_ART_SPEC.md`
- `test/listening_shelf_route_test.dart`
- `test/study_activity_responsive_test.dart`

---

Validation command:
`python -X utf8 C:\dev\hangulsori\ko_lernen_app\.agents\skills\session-handoff\scripts\validate_handoff.py .claude\handoffs\2026-08-23-113437-chaekgado-runtime-assets.md`
