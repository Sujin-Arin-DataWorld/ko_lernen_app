# Plan — P2-b (continuous Hanok growth) + P2-c (milestone bojagi)

Date: 2026-08-06
Spec: `docs/superpowers/specs/2026-08-05-study-reward-loop-repair-design.md` (Phase 2)
Predecessor: `docs/superpowers/plans/2026-08-05-pack-clear-bojagi-P2a.md`

## Goal

Studying should visibly grow the Hanok on Home **between** milestone jumps
(P2-b), and reaching a milestone should both celebrate **and** drop a reward
bojagi (P2-c). Both reuse existing seams — no new architecture, no event system.

## P2-b — continuous fractional Hanok growth (Home)

**Problem.** Home's preview showed `PersonalHanokProjection.constructionFraction`
— discrete, stepping only as one of the seven construction milestones unlocks.
Clearing a single pack within a level moved nothing, so study felt inert.

**Change.**
- `PersonalHanokProjection` gains a continuous read-only field
  `studyFraction = clamp01((a1+a2+b1+b2)/4)`, derived in the existing `.from`
  factory from the same `LevelRatios`. It advances as soon as any pack clears
  and reaches 1.0 exactly when construction is complete. `constructionFraction`
  is untouched (still available for milestone-count needs).
- `_HomeHanokPreview` reads `studyFraction` and renders it with the existing
  design-system `SoriProgressBar(animated: true)` (a hanji-toned bar, not an
  iOS-style badge/pill) plus the existing `homeHanokPreviewProgress` %. The bar
  tweens up when the user returns from studying (the preview rebuilds with the
  new projection).

**Invariants.** Pure/zero-write derivation. Monotonic with the milestone
cascade. No l10n change (reuses `homeHanokPreviewProgress(int)`).

## P2-c — milestone bojagi (wire into the EXISTING celebration)

**Discovery.** A full level (and streak/vocab) milestone celebration already
exists: `milestoneThresholds` (`level:[5,10]`), `newlyReachedMilestones`,
`Storage.celebratedMilestones` dedup, and `showMilestoneCelebration` (burst +
character clip sheet). So P2-c is **not** a new celebration — only the *reward*
was missing.

**Change.**
- `DecorationRewardService`: `isRewardSource` now also accepts a
  `milestone:<id>` token (new `kMilestoneSourcePrefix`), mirroring `pack:`.
  Candidates stay `_stableStartIndex` hash-derived, so the source is fully
  source-agnostic through the serial queue / claim journal.
- `home_screen._maybeCelebrateMilestone`: when a milestone is celebrated it
  first `ensurePendingBox('milestone:<top.id>')` (idempotent per source, done
  **before** `markMilestonesCelebrated` so a crash can't mark-without-reward),
  then refreshes `_openableBoxes` so the P1 bojagi banner surfaces immediately
  on Home/Sarangbang.

**Scope note (flagged to Jin).** The celebration path is uniform across
streak/level/vocab, so the bojagi drops for **every** milestone, not level-only.
One code path, trivially narrowable to `top.type == MilestoneType.level` if Jin
prefers level-only.

**Crash-safety.** `ensurePendingBox` dedups by source (pending + claimed
journal), so re-celebration or enqueue-before-mark never double-grants.

## Tests

- `test/personal_hanok_study_fraction_test.dart` (new): mean, 0/1 bounds,
  monotonicity, clamp, and the key property — `studyFraction` grows while
  `constructionFraction` stays flat within a level.
- `test/decoration_reward_service_test.dart`: `milestone:level_5` is claimable;
  re-enqueue is a no-op; bare `milestone:` is rejected.
- `test/decoration_reward_openable_count_test.dart`: valid `milestone:` counts,
  bare prefix / unprefixed do not.
- `test/milestone_test.dart`: wiring contract — every `milestoneThresholds`
  entry forms a valid `milestone:<id>` reward source.

## Pool caveat (carried from P2-a)

Only 11 decorations exist. Milestone sources add up to 7 more distinct sources;
once the collection is complete, extra boxes resolve to
`collectionComplete → archive`. Accepted for v1; the pool is append-only.

## Out of scope

- Per-milestone-type bojagi tuning / distinct decoration pools per source kind.
- Widget-level test of the full Home celebration→drop flow (covered at the
  service + contract level; the Home call site is one line verified by analyze).

## Unverified (needs Jin's device)

- Clear a pack / cross level 5 → return to Home: growth bar animates up, and the
  milestone celebration shows with the bojagi banner appearing right after.
