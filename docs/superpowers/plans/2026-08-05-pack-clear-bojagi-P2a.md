# Pack clear = one bojagi drop (Phase 2, P2-a) — plan

Date: 2026-08-05
Status: approved (P2-a only this round — Jin chose "P2-a first")
Design source: `docs/superpowers/specs/2026-08-05-study-reward-loop-repair-design.md` §Phase 2 P2-a

## Goal

Clearing a vocab pack for the first time drops exactly one bojagi (reward
bundle), so studying visibly produces a reward without depending on a quest
target. Reuse the existing bojagi claim UI, serial mutation queue, and
crash-safe claim journal unchanged — only broaden what counts as a valid reward
*source*.

## Design — one unified reward source

Today `DecorationRewardService` gates every operation on
`kQuestById.containsKey(id)`. A pack id is not a quest id, so a pack box would be
treated as a corrupted/unknown source and filtered out (or shown as the
`unknownQuest` error state).

Introduce one predicate and route both kinds through it:

```dart
static const String kPackSourcePrefix = 'pack:';

static bool isRewardSource(String id) =>
    kQuestById.containsKey(id) ||
    (id.startsWith(kPackSourcePrefix) && id.length > kPackSourcePrefix.length);
```

Pack sources are `pack:<packId>` (e.g. `pack:food_a1`). They cannot collide with
quest ids (which contain no `:`) and are produced only by the pack-clear path
with a real `pack.id`, so a well-formed pack token is always a valid, claimable
source. Its three decoration candidates come from the existing string-hash
`_stableStartIndex`, which is already source-agnostic and stable (same pack →
same candidates), so no new candidate machinery is needed.

Replace `kQuestById.containsKey(...)` with `isRewardSource(...)` at all seven
sites: `candidatesForQuest`, `openableBoxCount`, `_ensurePendingBox`,
`_loadNextOffer`, `_claimNextBox`, `_archiveCompleteCollectionBox`,
`_isClaimableJournal`.

Rename `_ensurePendingBoxForQuest` → `_ensurePendingBox`; add a public
`ensurePendingBox(String sourceId)`; keep `ensurePendingBoxForQuest` as a thin
alias so `QuestTracker.persistNewCompletions` is untouched.

## Wiring

`vocab_pack_screen._finish`, inside the existing `if (result.justCleared)` block
(which already grants the dojang stamp), also enqueues one box:

```dart
await DecorationRewardService.ensurePendingBox(
  '${DecorationRewardService.kPackSourcePrefix}${pack.id}',
);
```

One box per pack, ever: `justCleared` is only true on the first clear, and
`_ensurePendingBox` dedups against `pendingBoxes.contains`.

## Invariants preserved

- Serial mutation queue + crash-safe claim journal: untouched.
- No double grant: `justCleared` + `pendingBoxes.contains` dedup; the box leaves
  the queue on claim, and re-clearing a pack gives `justCleared == false`.
- `bojagi_screen` renders `offer.candidates` only (never the source id / a quest
  title), so a pack source shows the standard pick UI, not the `unknownQuest`
  error state.
- Pool caveat (documented, accepted for v1): only 11 decorations exist, so after
  ~11 distinct sources (quests + packs combined) extra boxes resolve to
  `collectionComplete` → archive. Pack rewards are front-loaded; the pool is
  append-only for later growth.

## Tests

- `decoration_reward_service`: `ensurePendingBox('pack:food_a1')` → one openable
  box; `loadNextOffer` = `ready` with 3 candidates (not `unknownQuest`); claim
  moves a decoration to owned and consumes the box; a second enqueue of the same
  pack is a no-op (dedup); a non-prefixed corrupted id still filters out.
- Regression: the quest path (`ensurePendingBoxForQuest`) and the
  serial-queue/journal tests are unchanged; `openableBoxCount` now includes pack
  boxes.
- `flutter analyze` 0; existing vocab_pack + bojagi + reward suites green.

## Out of scope (later rounds)

- **P2-b** continuous fractional Hanok growth (animate the Home ring).
- **P2-c** level-up celebration **+ milestone bojagi** (Jin's choice) — reuses
  this same source mechanism with a `level:<n>` token.
