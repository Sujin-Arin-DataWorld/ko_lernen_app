# UI/UX Native & Game Phase 2 — Execution Lock

- **Status:** local implementation and verification complete; remote gates await authority
- **Version:** 1.4
- **Updated:** 2026-08-21 00:43 Europe/Berlin
- **Branch:** `session/uiux-native-game-surfaces-2026-08-20`
- **Base:** `origin/main@1136c53891ce3bf1a5d95001914272a6261d0e0a`
- **Latest observed main:** `origin/main@c64fbfa21fb8cfd7ae88b7a76e83e6733de7fc5e`

## Purpose

This file preserves the current Phase 2 contract across long or interrupted
sessions. Read `AGENTS.md` and this file to resume this task. The older handoff
remains historical evidence; it is not required for routine continuation.

This file cannot preserve conversational memory. It preserves the decisions,
scope, evidence, and next action needed to continue without reconstructing the
session from chat history.

## Authority

Apply sources in this order:

1. Jin's latest explicit instruction.
2. `AGENTS.md` for repository rules and live gates.
3. `docs/HANDOFF_UI_OVERHAUL_2_2026-08-14.md` for the UI/UX product contract.
4. This file for the current Phase 2 execution state.
5. `.claude/handoffs/2026-08-20-224633-uiux-native-game-phase2.md` for historical
   detail only.

This is a task execution lock, not a replacement design bible. Do not create a
second component library, token set, or product SSoT from it.

## Objective

Finish Phase 2 on the merged PR #111 baseline:

- unify app-owned dialogs, sheets, and transient notices;
- make the app-owned surfaces before and after OS or SDK UI consistent;
- finish the Sori chrome around game HUDs, states, and result overlays;
- preserve game rules, touch geometry, educational distinctions, and data;
- prove the result with focused tests, full local gates, and current-head CI.

The work solves inconsistent app-owned chrome. It does not imitate system UI.
The simplest acceptable implementation extends the existing Sori components
and themes.

## Fixed Boundaries

### In scope

- App-owned `Dialog`, bottom-sheet, toast, confirmation, progress, and error
  surfaces.
- Camera, microphone, notification, Google/Apple account, subscription, and
  settings handoff surfaces owned by the app.
- Chosung, Wordle and word games, Kkeunmari, Cloze and Daily Challenge, Speed
  Match, Satz Arcade, and stroke canvas chrome.
- DE/EN UI, Korean learning content, keyboard/focus order, dismiss semantics,
  SafeArea, 200% reachability, color-independent feedback, and reduced motion.

### Out of scope

- Styling or cloning Android/iOS permission dialogs, OAuth browsers, App Store
  or Play billing sheets.
- Changing game rules, scoring, board geometry, gesture hitboxes, or curriculum.
- Adding a parallel `hs_ui` package or new visual token system.
- Replacing unapproved Hanok, Dancheong, mascot, icon, or marketing assets.
- Main merge, Play/TestFlight upload, Firebase/Cloudflare deployment, or store
  promotion without a later explicit instruction.
- Reading or updating `docs/SESSION_LOG.md`.

## Design Contract

- Reuse `lib/widgets/sori` and `ThemeData`.
- Use `SoriFonts.sans` (`WantedSans`) for UI and `SoriFonts.culture`
  (`MaruBuri`) only for cultural display headings.
- Use `compact`, `medium`, and `expanded` window classes plus `SoriMaxWidth` and
  `SoriTypeScale`; do not invent breakpoints.
- Treat the constraints inside `SafeArea` as the available viewport.
- Keep important text visible. Reflow and scroll instead of ellipsis.
- Keep touch targets at least 44×44 logical pixels.
- Trap focus within modal surfaces and restore focus when they close.
- Provide accessible names, roles, values, dismiss behavior, and non-color
  correct/error cues.
- Respect `MediaQuery.disableAnimations`.
- Do not add decorative iOS-style pills or badges. True filter controls remain
  valid.

## Ownership Model

| Owner | What may change | What stays external |
|---|---|---|
| `app-owned` | rationale, confirmation, sheet, notice, progress, return/error state | — |
| `platform-owned` | app surface before request and after return | Android/iOS permission dialog and Settings |
| `SDK-owned` | app explanation, loading, cancellation, failure, restore state | OAuth browser and billing sheet |
| `game-canvas` | HUD, controls, labels, pause/status/result overlays, Semantics | mechanic, board geometry, hitbox, scoring |

## Inventory Snapshot

Snapshot taken from `origin/main@1136c538` on 2026-08-20:

- Raw overlay search matched 38 Dart files. The largest concentrations are
  `settings_screen.dart`, account operations, bookshelf/custom-pack screens,
  and Gye screens.
- `showDialog` appears in 14 files; `showModalBottomSheet` appears outside the
  Sori wrapper in 8 files.
- `ScaffoldMessenger` appears in 30 files. Action SnackBars need explicit
  migration because the current `soriToast` contract is action-free.
- Custom paint search matched 20 files. Most are decorative Sori painters. The
  direct input canvas is `lib/widgets/stroke_canvas.dart`.
- OS/SDK boundaries include camera capture, word-image camera, pronunciation
  microphone, local/push notifications, Google/Apple account linking, and
  RevenueCat purchase/restore flows.

Re-run the inventory after each phase. Do not claim completion from this
snapshot.

Phase 2A inventory after migration:

- `showDialog`, `showGeneralDialog`, `showModalBottomSheet`, `showSnackBar`, and
  `SnackBar` construction are owned only by the Sori entry-point files. Other
  search hits are comments.
- 57 Dart files now call a Sori dialog, sheet, or notice entry point.
- `test/overlay_ownership_guard_test.dart` rejects future raw overlay callers.

## Phase State

| Phase | State | Completion evidence |
|---|---|---|
| 0 — isolated baseline | complete | clean Windows-native worktree, branch and HEAD match this file |
| 2A — app-owned overlays | complete | Sori dialog/general-dialog/sheet/notice ownership; source guard; analyze clean; 9 primitive/guard and 116 affected-flow tests passed |
| 2B — OS/SDK boundaries | complete | native/SDK source guard; camera rationale/denial; mic consent/fallback; notification timing/denial; account confirmation/recovery; typed RevenueCat cancel/error/restore; analyze clean; 115 tests passed |
| 2C — game surfaces | complete | shared Sori-frame guard; DE/EN 320×640@200% and short-height matrix; explicit Semantics/non-color cues; reduced-motion canvas; active-time pause/resume; 248 focused tests passed |
| Final verification | local complete; remote pending | full analyze clean; 4,250 tests passed and 14 environment-conditional tests skipped; `git diff --check` clean; Linux goldens/current-head CI await an authorized commit and push |

Final local inventory and review:

- Raw dialogs, general dialogs, bottom sheets, and SnackBars remain owned only
  by `lib/widgets/sori/dialog.dart`, `sheet.dart`, and `toast.dart`; other search
  matches are comments.
- Camera permission access remains confined to the two intentional boundary
  owners; Google OAuth and RevenueCat remain confined to their typed owners.
- The complete task diff contains 66 files, 2,453 insertions, and 726 deletions.
  Added-line TODO/FIXME/credential-pattern review is clean.
- The original base is an ancestor of the latest observed `origin/main`.
  Main advanced in four non-overlapping paths: the iOS Xcode Cloud workflow,
  Hanok asset inventory, an empty audit placeholder, and `pubspec.yaml`'s iOS
  package-manager configuration.

## Verification Matrix

- Viewports: `320×640`, `360×400`, `390×844`, `720×1024`, `1280×900`.
- Locales: DE and EN; retain Korean learning content.
- Text scale: 100%, 130%, 160%, 200%.
- SafeArea regression: top 44dp and bottom 34dp.
- Overlay: full message reachable, correct initial focus, closed-loop traversal,
  predictable back/dismiss behavior, destructive confirmation, Semantics.
- Game: touch targets, board hitboxes, reachable timer/score, non-color feedback,
  reduced motion, pause/resume lifecycle.
- Golden evidence: representative compact/medium/expanded overlay and each game
  family on Linux.

## Required Commands

Run from the worktree in this file:

```powershell
git status --short --branch
git rev-parse HEAD
rg -l "showDialog|showAdaptiveDialog|showGeneralDialog|showModalBottomSheet|ScaffoldMessenger|SnackBar\(" lib
rg -l "CustomPainter|CustomPaint\(" lib/screens lib/widgets
rg -l "permission_handler|Permission\.|GoogleSignIn|purchases_flutter|openAppSettings" lib android ios
flutter analyze
flutter test -r compact
git diff --check
```

Use targeted tests after every system-sized change. Do not update Linux golden
baselines from Windows. Do not duplicate an automatic CI run for the same SHA.

## Restart Protocol

1. Open the worktree named at the top of this file.
2. Read `AGENTS.md` and this file.
3. Confirm the branch, HEAD, status, and `origin/main` ancestry.
4. Read only the files named by the current next action.
5. Continue the first incomplete phase.

Read the old handoff only if this file lacks a disputed historical fact. Never
load `SESSION_LOG` for routine continuation.

## Current Next Action

Finish only the authority-gated delivery steps:

1. After Jin grants commit/push/PR authority, integrate the latest
   `origin/main` without disturbing the task-owned diff, then repeat the
   proportional local gates on the resulting head.
2. Split and create task-owned commits, push this branch, and open a PR.
3. Linux game-family goldens and current-head CI remain remote gates. This
   Windows host has WSL2 but no native Linux Flutter SDK; do not create Linux
   baselines with the Windows engine.
4. Do not commit, push, open a PR, merge, or deploy without Jin's explicit
   authority. Merge and release remain separately gated even after PR creation.

## Update Rule

Replace stale state in this file whenever a phase, blocker, branch SHA, or next
action changes. Keep it short and current. Git history and PRs preserve the
timeline; this file preserves only the live contract.
