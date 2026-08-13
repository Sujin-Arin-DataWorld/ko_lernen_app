# Implementation Plan: Sori Stage

## Objective

Reorganize Hangul Sori around five clear roots: Today, Learn, Games, Hanok,
and Gye. Learners must know what to do next, what a completed action can earn,
and which progress actually changed. Existing routes, saved progress, character
assets, Hanok stages, quests, games, privacy controls, and bilingual DE/EN UI
remain intact.

## Tech Stack and Commands

- Flutter/Dart application with SharedPreferences, Firebase, and ARB l10n.
- Firebase Functions use Node 22 and the callable protocol.
- Format: `dart format <changed paths>`
- Generate l10n: `flutter gen-l10n`
- Focused tests: `flutter test <test files>`
- Analyze: `flutter analyze`
- Full regression: `flutter test`
- Functions tests: `npm test` in each changed function codebase.

## Architecture Decisions

- Keep `SoriColors` stable and layer `SoriActivityColors` by learning meaning.
- Keep every legacy named route; the new shell is an additive entry point behind
  `ENABLE_SORI_STAGE`, default-on in this branch and rollback-capable.
- Separate expected `RewardContract` from observed `RewardReceipt` so the UI
  never claims an unpaid reward.
- Use one `ActivityCatalogEntry` inventory for Learn and Games discovery.
- Derive Hanok construction from established, verified learning and first-clear
  evidence; repeat games grant XP, personal bests, and quest progress only.
- Record pronunciation only after separate consent, process at most ten seconds
  in `germanywestcentral`, and never persist audio, text, or member identities.

## Code Style

- Immutable Dart models and focused widget classes.
- Existing Pretendard theme, `Spacing`, `SoriRadius`, and responsive helpers.
- No new AI assets or Rive. Tiger is the speaking/challenge guide; Magpie is the
  listening/hint guide where existing assets are already available.
- No generic same-size card wall: one dominant stage plus scan-friendly rows.

## Testing Strategy

- Pure unit tests for catalog uniqueness, score threshold, idempotency, unique
  Gye-member counting, quest routing, and reward receipt deltas.
- Widget tests at phone/tablet/wide widths and high text scaling.
- Existing gallery fixtures remain read-only and detect unintended writes.
- Callable runtime tests validate auth, App Check, size, rate limits, region,
  and no sensitive logging.
- Full Flutter regression and build/analyze gates run before completion.

## Boundaries

- Always: work only in the dedicated worktree; preserve route and storage
  contracts; update `docs/SESSION_LOG.md`; test each slice before committing.
- Ask first: main merge, remote push, Firebase/Azure deployment, production key
  creation, or destructive cleanup.
- Never: edit/build/format the VS Code main checkout; log/store recordings,
  reference sentences, or Gye member identities; invent rewards or assets.

## Success Criteria

- Every existing learning/game/Hanok/Gye entry is reachable once from the new
  information architecture, with duration, state, reward contract, and exact
  unlock guidance.
- Reward receipts contain only observed deltas and remain idempotent after
  replay or restart.
- Pronunciation 79 fails and 80 passes; denial/offline/server failure preserves
  ordinary repeat-after-me learning.
- One user present in multiple Gyes counts once; new completion needs an online
  authoritative refresh while offline shows only the last numeric count.
- DE/EN, 390dp, 600dp, 720dp+, 1280dp, 200% text, light/dark, screen reader,
  48dp targets, and reduced motion are verified.
- The original checkout stays on clean `main` at `45779bf`; no push, merge, or
  deployment occurs.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Existing tests assume legacy navigation | Explicit feature-gate seam and focused shell tests |
| Rewards become misleading | Contract/receipt split and delta tests |
| Voice data leaks | Strict callable validation, transient buffers, no sensitive logs |
| Large UI refactor hides content | Catalog completeness test against the route inventory |
| Concurrent main work is disturbed | Dedicated worktree and final read-only main proof |

## Open Questions

None. The user-approved implementation plan is the governing specification.
