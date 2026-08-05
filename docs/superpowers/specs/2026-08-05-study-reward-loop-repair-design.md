# Study → Sarangbang/Hanok → Reward loop repair (design)

Date: 2026-08-05
Status: approved (Phase 1 for implementation; Phase 2 roadmap)
Author: session with Jin

## Problem

A learner studies (e.g. clears vocab packs from the Sarangbang) but the
"living Hanok learning world" does not respond: the Home "Heute im Sarangbang"
ring does not visibly move, the Sarangbang/Hanok does not grow, and no reward
bundle (bojagi) appears. Leveling up produces nothing. XP and the weekly day
row work correctly (they derive from XP).

## Root cause (verified in code)

The progression is a set of passive-pull fragments that each recompute only when
a specific screen is opened. Nothing binds "study finished" to the growth or
reward machinery.

1. **Reward bundles are never produced by studying.**
   `DecorationRewardService.ensurePendingBoxForQuest()` is the only producer of a
   pending bojagi, and its only caller is `QuestTracker.persistNewCompletions()`,
   which is itself only called from `QuestsScreen` (`quests_screen.dart:92`).
   A learner who never opens `/quests` never produces a bundle, even after
   crossing a quest target. Quest targets are also topic/seasonal
   ("master N food words", "N scenarios"), not "clear a pack".

2. **Reward bundles are almost undiscoverable.**
   `/bojagi` is reachable only from `PersonalRoomFurnishScreen._openBojagi`
   (`personal_room_furnish_screen.dart:129`), i.e. Sarangbang → furnish → open.
   `home_screen.dart` has zero references to bojagi/pendingBoxes. So even a
   produced bundle is not surfaced where the learner studies.

3. **Hanok growth is coarse and clear-gated.**
   `HanokStageService` derives the stage purely from cleared-pack ratio across all
   levels. Partial study (Learn only, not Learn→Quiz→Boss) moves nothing, and the
   discrete stage crosses a threshold only after several packs, so one or two
   cleared packs produce no visible change. The Home ring DOES recompute when the
   learner returns to Home (Sarangbang is a pushed route from the Home mission CTA,
   `home_screen.dart:453`, followed by `await _refreshHome()`), so the felt
   "no trigger" is the coarse/clear-gated growth, not tab staleness.

4. **Level-up is not wired to the world.** `Storage.addXp` bumps XP and today XP
   only; nothing in the Hanok/reward world reacts to a level threshold.

## Scope decision

Two phases. Phase 1 repairs the plumbing so genuinely-earned rewards are produced
and surfaced from studying, and refresh is reliable. Phase 2 adds the immediate
"study now visibly moves something" reward layer. Only Phase 1 is implemented in
this round. Phase 2 is documented here as an approved roadmap and gets its own
spec/plan before implementation.

Non-goals for Phase 1: changing quest targets, changing the cleared-ratio growth
model, adding new reward sources, or any level-up reward. Those are Phase 2.

## Phase 1 — plumbing repair (this round)

### P1-a. Produce earned reward bundles after studying, not only on /quests

Add one thin, idempotent seam that recomputes quests and persists new completions,
callable outside the Quests screen.

- New static: `QuestTracker.syncEarnedRewards()` =
  `final list = await computeAll(); await persistNewCompletions(list);`
  wrapped best-effort (its own try/catch so a failure never surfaces to UI).
- `QuestsScreen` keeps its current explicit flow (it needs the progress list to
  render); it does not call the new seam.
- Callers of the new seam (the "a learning route returned / app resumed" moments):
  - `home_screen._refreshHome()` (already runs on init, pull-to-refresh, and after
    the Sarangbang CTA returns).
  - `sarangbang_screen._load()` (already runs after a study route returns).

Idempotency is preserved by the existing guards: `persistNewCompletions` acts only
on `completed && completedAtIso == null` (newly reached), `ensurePendingBoxForQuest`
skips known duplicates, and `markQuestCompleted`/`pendingBoxes.contains` prevent
double rewards. Running the seam from both Home and Sarangbang, plus the Quests
screen, cannot double-grant. `GyeService.broadcastFeed` fires once per new
completion; `syncLevelUp` is idempotent via `Storage.lastGyeLevel`.

### P1-b. Surface waiting bundles on Home and Sarangbang

A learner must see "you have a bundle" where they study.

- New widget `PendingRewardCard` (in `lib/widgets/sori/`): renders only when
  `Storage.pendingBoxes.isNotEmpty`; a `SoriCard` with the closed-bojagi motif,
  a "N개 받을 보상" line, and an open action; tap pushes `/bojagi`, then refreshes.
- This is a **content card, not an icon badge** (per Jin's preference for inline
  content over iOS-style numeric badges).
- Placement: Home, directly under the mission hero; Sarangbang, in/under the
  welcome card. Both read `Storage.pendingBoxes` synchronously.
- New DE/EN ARB keys (then `flutter gen-l10n`): title, body-with-count, open CTA.
  Count uses ICU plural.

### P1-c. Refresh reliability

Close the residual staleness so a produced bundle and any growth appear without a
manual pull-to-refresh.

- Home becomes a `WidgetsBindingObserver`; on `AppLifecycleState.resumed` it calls
  `_refreshHome()` (which now also runs `syncEarnedRewards` and re-reads
  `pendingBoxes`). This catches "studied, backgrounded, reopened".
- After returning from `/bojagi`, the opener refreshes its pending-box state.
- No AppShell tab-signaling is introduced in Phase 1 (Sarangbang is a pushed route,
  so the Home mission CTA path already refreshes on return).

### Phase 1 data flow

```
study surface writes progress (seen ids / pack cleared / scenario done)
        │
        ▼  (route pops back to Home or Sarangbang, or app resumes)
QuestTracker.syncEarnedRewards()
   = computeAll()  →  persistNewCompletions()
        │                     │
        │                     ├─ ensurePendingBoxForQuest(questId)  (serial journal queue)
        │                     └─ markQuestCompleted(questId)
        ▼
Storage.pendingBoxes  ──►  PendingRewardCard (Home + Sarangbang)  ──►  /bojagi (claim)
```

### Error handling

Every new call site is best-effort and non-blocking: `syncEarnedRewards` swallows
its own errors, the reward card hides itself on any read failure, and no path
throws into the widget tree. The existing serial mutation queue and claim journal
in `DecorationRewardService` are untouched, so the crash-safety and
no-double-grant invariants are preserved.

### Testing (Phase 1)

- `quest_tracker_test`: seeding `vokSeenIds` so a quest counter crosses its target,
  then calling `syncEarnedRewards()`, enqueues exactly one pending box for that
  quest and marks it completed, with no Quests screen involved; a second call is a
  no-op (no double box).
- Home widget test: `pendingBoxes` non-empty shows `PendingRewardCard` and tapping
  navigates to `/bojagi`; empty hides it.
- Sarangbang widget test: same visibility/navigation contract.
- Regression: `quests_screen` flow and `decoration_reward_service` invariants
  unchanged; running sync from Home and from Quests does not double-grant.
- Responsive/typography: `PendingRewardCard` in the 308–1280dp and 1.3× matrix,
  no overflow; DE/EN ARB parity; `flutter gen-l10n` clean.

## Phase 2 — immediate reward layer (roadmap, separate spec/plan)

- **P2-a. Pack clear = one bojagi drop.** Introduce a non-quest reward source in
  `DecorationRewardService` (relax the `kQuestById` guard behind a distinct
  source-kind with its own stable candidate index), enqueued at the pack-clear
  moment in `vocab_pack_screen._finish` when `justCleared`. Must keep the serial
  journal/queue and no-double-grant invariants.
- **P2-b. Continuous Hanok growth.** Make the Home ring / `PersonalHanokProjection`
  read the fractional cleared ratio and animate, so a single cleared pack is
  visible rather than waiting for a coarse stage threshold.
- **P2-c. Level-up celebration.** A celebration moment on XP level-up, optionally a
  bojagi at level thresholds.

## Acceptance criteria (Phase 1)

1. Clearing packs from the Sarangbang produces the correct earned bojagi(s) without
   ever opening `/quests`.
2. A waiting bojagi is visible as a content card on both Home and Sarangbang and
   opens `/bojagi`; the card disappears once the queue is empty.
3. Reopening the app after studying surfaces any newly earned bojagi.
4. No double grants across Home, Sarangbang, and Quests; the reward journal and
   serial-queue invariants are unchanged.
5. New card passes the 308–1280dp and 1.3× text matrix with DE/EN parity.
