# Personal Hanok Compound Growth — Design

**Status:** visual direction approved; implementation awaits this revised written-spec review
**Owner:** Codex
**Scope:** personal hanok P2 foundation, with explicit P3/P4 follow-on boundaries

## 1. Product intent

Hangul Sori's hanok is not a passive progress illustration. It is the user's
long-lived home: they first see construction progress, then build a traditional
compound one structure at a time, enter completed buildings, and eventually
decorate private rooms. The compound follows the supplied, asymmetrical
traditional-plan reference: front `sotdaeulmun` gate, `haengrangchae`, long
`sarangchae`, inner `anchae`, open `daecheongmaru`, a separated `sadang`, and a
rear garden (`huwon`) with pond and bridge.

The dedicated **My Hanok** screen is the canonical interactive surface. The
learning path keeps a compact preview and CTA; it does not become a second,
competing interactive map.

## 2. Verified current state

- `HanokStageService` deterministically derives twelve legacy construction
  stages from A1--B2 pack-clear ratios. It persists no stage ownership.
- `LearningPathScreen` shows one full-stage PNG plus courtyard decorations.
- `GyeHanok` already stacks transparent `gye_*` PNGs at fractional coordinates
  and independently unlocks them from group lifetime goals. Its eight-element
  list includes a matching large pond and stone bridge.
- P1 is complete: `SarangbangScreen`, reward bojagi, room placements, and its
  six real interior decorations are already functional.
- `gye_pond_large.png` and `gye_bridge.png` are verified 32-bit transparent
  components and compose cleanly as a pair. They can be shared as artwork by
  the personal rear garden without sharing Gye state.
- The earlier `decoration_pond`, `decoration_jangdokdae`, `decoration_sonamu`,
  and `decoration_maehwa` contain a visible near-opaque white canvas through
  their central area. They are not eligible compound overlays until normalized.

## 3. Chosen architecture

### 3.1 Separate personal and Gye domains; share only artwork and future-safe rendering primitives

`PersonalHanokProgress` owns personal unlock derivation from course ratios.
`GyeHanok` continues to own its group-goal rules, opacity pulse, and social
state. Neither reads the other's storage or service APIs.

Both may eventually use a shared, data-only compound layer:

```dart
typedef CompoundElement = ({
  String id,
  String assetPath,
  double leftFrac,
  double bottomFrac,
  double widthFrac,
  int zIndex,
});
```

`HanokCompoundLayer` receives element definitions, unlocked ids, optional
progress opacity, and semantic tap handlers. It does not decide what unlocks
or mutate storage. P2 initially introduces it for the personal map only;
`GyeHanok` remains byte-for-byte behaviorally stable until an explicit visual
parity test proves an adapter refactor safe.

### 3.2 Personal structures and deterministic unlocks

`PersonalHanokStructure` has six stable ids:

| Structure | First visible when | Map-aligned visual | Interactive destination |
|---|---:|---|---|
| `sotdaeulmun` | B1 >= 25% | new transparent, plan-perspective gate | none |
| `haengrangchae` | B1 >= 50% | new transparent, plan-perspective wing | none |
| `sarangchae` | B1 complete | new transparent long front wing | `/sarangbang` |
| `anchae` | B2 >= 25% | new transparent U-shaped inner residence | locked until P3 |
| `daecheongmaru` | B2 >= 50% | new transparent open hall | locked until P3 |
| `sadang` | B2 >= 75% | new transparent, separately enclosed shrine | cultural archive, never a decor room |

All six required structures are visible by B2 = 75%; the **Hanok complete**
milestone is B2 = 100%, when the full site is presented as a complete jongga.
Exterior collecting and room decoration remain meaningful after that milestone.
This deliberately uses raw B2 ratio for post-`sideBuilding` detail while
leaving `HanokStage` and its twelve legacy thresholds unchanged. Existing users
therefore see the compound that their already-earned ratios imply; no manual
migration write, reward replay, or loss of existing progress occurs.

Before the gate milestone, **My Hanok** renders the existing legacy stage PNG
and construction copy. From the gate milestone onward it renders the compound
canvas. Legacy stage cinematics remain stage-driven and untouched in P2.

### 3.3 Dedicated screen and responsive interaction

Route: `/hanok` → `HanokScreen`.

- The compound viewport is a 4:3, full-bleed visual canvas inside a responsive
  content clamp. It preserves the supplied plan's spatial relationships on
  phones and tablets.
- Completed structure hit regions are semantic buttons with at least 44dp tap
  targets. The completed `sarangchae` opens the existing room; later interiors
  show a localized, non-actionable "coming next" explanation rather than a
  dead tap.
- Locked structures are visible as quiet ghost previews only after the
  compound begins. They do not advertise unavailable actions.
- `sadang` is an achievement and cultural-record destination (for example,
  stamps/mastery), never a random furniture-placement surface. Its content is
  explicitly deferred, so P2 gives it no misleading tap action.
- The rear garden is a permanent spatial zone, not a free-floating quest
  decoration. Its pond and bridge appear as a paired landscape milestone;
  optional trees, jars, lamps, and walls enrich it without changing completion.
- The learning-path header becomes a compact preview plus **My Hanok** CTA;
  it never duplicates compound interaction. A home entry may be added only if
  it can reuse this same route and wording.
- Layout tests cover 308, 360, 600, 720, 800, and 1280dp plus 1.3x system text.

## 4. Master-map asset contract

The user-facing 4:3 map needs a single ground plane plus separately tappable
building and landscape pieces. A cinematic final-stage PNG remains useful for
celebration, but can never be the interactive map's source of truth.

The compound must feel like a broad, growing **jongga estate**, not a small
sketchbook board. Its opaque base reserves visibly breathable courts and a
large rear-garden zone around the six completion structures. The buildings do
not consume every clearing: future exterior collection (jars, lamps, planting,
garden structures, and Gye-related goals) needs real unoccupied terrain.

### 4.1 New map-aligned art package

P2 needs seven new production assets under
`assets/illustrations/hanok_compound/`:

1. `site_base.png` — opaque 4:3 compound ground plane: walls, paths, terrain,
   foundation context, and the empty rear-garden basin; no completed buildings,
   colored markers, or placeholder pads.
2. `sotdaeulmun.png` — transparent raised gate at the south/front edge.
3. `haengrangchae.png` — transparent outer/service wing.
4. `sarangchae.png` — transparent long front wing, spatially aligned with the
   existing `/sarangbang` destination.
5. `anchae.png` — transparent U-shaped inner residence.
6. `daecheongmaru.png` — transparent open hall.
7. `sadang.png` — transparent enclosed shrine building.

Every structure uses one **north-up, plan-locked oblique camera**: south is the
lower edge of the map, main east--west ridges run horizontally, and entrances
face the lower/south side unless the historical plan calls for a side wing.
The assets may have a small, shared oblique elevation for roof depth, but no
asset may choose its own yaw, front-facade camera, or vanishing point. They
share upper-left light, ground-anchor, Faceted Minhwa palette, restrained hanji
grain, and no text. They are structures, not room objects, so none belongs in
`decorations/`.

### 4.2 Existing-art reuse matrix

| Existing artwork | Personal compound role | Decision |
|---|---|---|
| `gye_pond_large.png` + `gye_bridge.png` | rear-garden pond and crossing | **Direct reuse as one paired milestone.** They are verified transparent, share a camera, and must retain separate personal unlock state. |
| `gye_jangmyeongdeung_pair.png` | gate approach or rear-garden path | Direct reuse after map-scale visual QA; cosmetic, not required for completion. |
| `gye_garden.png` | optional mature rear-garden planting | Candidate reuse after scale/camera QA. It is intentionally not a substitute for the pond. |
| `gye_gate_grand`, `gye_haenglangchae`, `gye_byeoldang`, `gye_jeongja` | Gye screen / milestone art reference | Keep in Gye. Their front/three-quarter camera and footprints do not match the master plan, so they are not dropped into the personal map as buildings. |
| `decoration_doldam.png`, `decoration_seokdeung.png` | optional exterior accents | Reuse only through a personal exterior catalog after map QA; do not alter the old quest layer. |
| `decoration_pond.png`, `decoration_jangdokdae.png`, `decoration_sonamu.png`, `decoration_maehwa.png` | future exterior collection | **Blocked pending alpha/canvas normalization.** Their central white canvas is visible over another scene. |

Artwork reuse never means shared ownership: a personal `rear_pond` unlock is
derived from personal course progress, while the same file in `GyeHanok` stays
governed by Gye lifetime goals.

## 5. Personal completion and landscape rules

- Required completion is the six-structure map sequence. At B2 = 100%, the
  player reaches the explicit **complete jongga** milestone.
- The rear pond/bridge, lamps, mature planting, jars, walls, and future room
  decoration are optional collection depth after completion, not progress
  blockers.
- The paired bridge is not a foreground ornament: it renders above and crosses
  the pond water along its centre line, so both sides of the rear garden remain
  visually connected.
- The exterior catalog is map-specific. It must not mutate the current
  `DecorationLayer` contract on `LearningPathScreen` in P2.
- A map feature has at most one semantic owner: completed building, landscape
  milestone, or later room surface. This prevents a single pond or decoration
  from rendering twice across unrelated systems.

## 6. P3 room expansion boundary

P3 generalizes the existing room placement model without changing P1 behavior:

```text
surfaceId + slotId -> decorationSlug
```

The current `roomPlacement` becomes the `sarangbang` surface during a safe
read migration. New `anbang` and `daecheong` surfaces receive their own
backgrounds, slot definitions, and entry routes. Owned decorations remain a
single personal collection; placement validation continues to prevent the same
item appearing in two slots simultaneously.

P3 is intentionally out of the P2 implementation commit series except for the
stable `surfaceId` design constraint above.

## 7. P4 Gye boundary

Gye continues to show its existing shared compound. Donation of a personal
decoration into a Gye is deferred until P3 creates multiple personal surfaces.
That feature requires a separate ownership-transfer/revocation contract,
member-visible placement policy, Firestore rules review, and service-level
journaling; it is not inferred from P2's renderer sharing.

## 8. Rejected alternatives

1. **Keep the compound inside the learning-path header.** Rejected: there is
   no room for understandable building taps, interior entry, or tablet-scale
   composition.
2. **Replace every legacy stage PNG immediately.** Rejected: it discards the
   satisfying construction sequence and changes a tested twelve-stage contract
   without a user benefit.
3. **Share personal and Gye progress/storage models.** Rejected: private
   course progress and group weekly goals have incompatible ownership,
   persistence, and failure semantics.
4. **Drop the current Gye buildings straight onto the master map.** Rejected:
   their camera and footprint create a collage rather than a coherent
   traditional plan. The pond/bridge pair is the proven direct-reuse exception.

## 9. Verification contract

- Pure threshold tests cover every exact boundary and prove monotonic personal
  structure ownership.
- Migration tests prove an existing P1 `roomPlacement` stays untouched and no
  personal structure requires a write to appear.
- Asset tests verify all catalog paths exist, all map components have true
  transparent alpha where required, and no structure asset can appear in the
  decoration whitelist.
- Map tests prove the pond and bridge share one personal landscape milestone,
  never read Gye state, and do not alter Gye rendering.
- Widget tests prove the early construction view, compound view, only valid
  `sarangchae` navigation, locked-structure feedback, and no overflow across
  the supported device matrix.
- Existing Gye visual/unlock tests must preserve their current behavior.

## 10. Delivery sequence

1. P2a: produce and approve the coherent seven-piece master-map art package;
   prove direct pond/bridge reuse and normalize any optional exterior asset
   before it enters the catalog.
2. P2b: pure personal structure/landscape catalog, progress service, and
   `HanokCompoundLayer`, covered by threshold, ownership-boundary, and
   Gye-regression tests.
3. P2c: `/hanok` screen, route, learning-path preview/CTA, and interaction
   behavior using only approved asset paths.
4. P2d: responsive and interaction hardening; complete P2 only when targeted
   guards, `dart analyze`, and the full Flutter suite pass.
5. P3: add `anbang` and `daecheong` interiors using the surface-aware placement
   migration.
6. P4: separately design and implement Gye decoration donation.
