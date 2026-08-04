# Personal Hanok Compound Growth — Design

**Status:** approved direction; implementation awaits this written-spec review
**Owner:** Codex
**Scope:** personal hanok P2 foundation, with explicit P3/P4 follow-on boundaries

## 1. Product intent

Hangul Sori's hanok is not a passive progress illustration. It is the user's
long-lived home: they first see construction progress, then build a traditional
compound one structure at a time, enter completed buildings, and eventually
decorate private rooms. The compound follows the supplied traditional layout:
front `sotdaeulmun` gate, `haengrangchae`, `sarangchae`, inner `anchae`, open
`daecheongmaru`, and `sadang`.

The dedicated **My Hanok** screen is the canonical interactive surface. The
learning path keeps a compact preview and CTA; it does not become a second,
competing interactive map.

## 2. Verified current state

- `HanokStageService` deterministically derives twelve legacy construction
  stages from A1--B2 pack-clear ratios. It persists no stage ownership.
- `LearningPathScreen` shows one full-stage PNG plus courtyard decorations.
- `GyeHanok` already stacks transparent `gye_*` PNGs at fractional coordinates
  and independently unlocks them from group lifetime goals.
- P1 is complete: `SarangbangScreen`, reward bojagi, room placements, and its
  six real interior decorations are already functional.
- Existing reusable compound visuals are `gye_gate_grand`,
  `gye_haenglangchae`, and `gye_byeoldang`. The last is an acceptable visual
  source for the initial personal `sarangchae`, but its user-facing identity is
  always **sarangchae**, never "byeoldang".

## 3. Chosen architecture

### 3.1 Separate personal and Gye domains; share only rendering primitives

`PersonalHanokProgress` owns personal unlock derivation from course ratios.
`GyeHanok` continues to own its group-goal rules, opacity pulse, and social
state. Neither reads the other's storage or service APIs.

Both use a shared, data-only compound layer:

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
or mutate storage. Existing `GyeHanok` becomes a thin adapter over this layer;
its visual and unlock behavior stay unchanged.

### 3.2 Personal structures and deterministic unlocks

`PersonalHanokStructure` has six stable ids:

| Structure | First visible when | Initial visual | Interactive destination |
|---|---:|---|---|
| `sotdaeulmun` | B1 >= 25% | existing `gye_gate_grand` | none |
| `haengrangchae` | B1 >= 50% | existing `gye_haenglangchae` | none |
| `sarangchae` | B1 complete | existing `gye_byeoldang` | `/sarangbang` |
| `anchae` | B2 >= 25% | new transparent PNG | locked until P3 |
| `daecheongmaru` | B2 >= 50% | new transparent PNG | locked until P3 |
| `sadang` | B2 >= 75% | new transparent PNG | no interior in P3 |

The full compound is complete at B2 = 100%. This deliberately uses raw B2
ratio for post-`sideBuilding` detail while leaving `HanokStage` and its twelve
legacy thresholds unchanged. Existing users therefore see the compound that
their already-earned ratios imply; no manual migration write, reward replay,
or loss of existing progress occurs.

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
- The learning-path header becomes a compact preview plus **My Hanok** CTA;
  it never duplicates compound interaction. A home entry may be added only if
  it can reuse this same route and wording.
- Layout tests cover 308, 360, 600, 720, 800, and 1280dp plus 1.3x system text.

## 4. Asset plan

P2 needs **four**, not three, new production assets:

1. `assets/illustrations/hanok_compound/madang_empty.png` — opaque 4:3
   compound courtyard/base, with perimeter context and no buildings, colored
   markers, or placeholder pads.
2. `.../anchae.png` — transparent Korean inner residence.
3. `.../daecheongmaru.png` — transparent open central wooden hall.
4. `.../sadang.png` — transparent ancestral shrine building.

All use the project Faceted Minhwa contract: angular color planes, restrained
hanji grain, limited dancheong palette, no text, watercolour, pasted white
canvas, or visual slot markers. Existing Gye building PNGs are reused by path,
not copied, for the three first personal structures.

No P2 asset is placed in `decorations/`; structures are not room objects.

## 5. P3 room expansion boundary

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

## 6. P4 Gye boundary

Gye continues to show its existing shared compound. Donation of a personal
decoration into a Gye is deferred until P3 creates multiple personal surfaces.
That feature requires a separate ownership-transfer/revocation contract,
member-visible placement policy, Firestore rules review, and service-level
journaling; it is not inferred from P2's renderer sharing.

## 7. Rejected alternatives

1. **Keep the compound inside the learning-path header.** Rejected: there is
   no room for understandable building taps, interior entry, or tablet-scale
   composition.
2. **Replace every legacy stage PNG immediately.** Rejected: it discards the
   satisfying construction sequence and changes a tested twelve-stage contract
   without a user benefit.
3. **Share personal and Gye progress/storage models.** Rejected: private
   course progress and group weekly goals have incompatible ownership,
   persistence, and failure semantics.

## 8. Verification contract

- Pure threshold tests cover every exact boundary and prove monotonic personal
  structure ownership.
- Migration tests prove an existing P1 `roomPlacement` stays untouched and no
  personal structure requires a write to appear.
- Asset tests verify all catalog paths exist and no structure asset can appear
  in the decoration whitelist.
- Widget tests prove the early construction view, compound view, only valid
  `sarangchae` navigation, locked-structure feedback, and no overflow across
  the supported device matrix.
- Existing Gye visual/unlock tests must preserve their current behavior.

## 9. Delivery sequence

1. P2a: pure personal structure catalog/progress service and shared compound
   layer, covered by threshold and Gye-regression tests.
2. P2b: four approved production assets, `/hanok` screen, route, and
   learning-path preview/CTA.
3. P2c: responsive and interaction hardening; complete P2 only when targeted
   guards, `dart analyze`, and the full Flutter suite pass.
4. P3: add `anbang` and `daecheong` interiors using the surface-aware placement
   migration.
5. P4: separately design and implement Gye decoration donation.
