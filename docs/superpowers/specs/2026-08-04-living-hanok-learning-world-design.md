# Living Hanok Learning World — Design Contract

**Status:** approved for implementation on 2026-08-04
**Scope:** P2 personal Hanok world + Sarangbang learning-context entry. P3 interiors and P4 Gye donation remain explicitly out of scope.

## Product decision

Hangul Sori's long-term game is completing one traditional hanok estate. The estate is a learning world, not a decorative end screen:

- Home is the arrival courtyard. Its primary study action enters the Sarangbang.
- Sarangbang resolves the existing `recommendMission` priority and opens the selected original learning surface from a desk context.
- `/sarangbang/furnish` retains the existing P1 room-placement and bojagi collection flow.
- `/hanok` is the canonical personal estate map. Tapping a finished place opens an existing learning destination or a locally composed venue sheet.
- The separate Gye road is visible but has no personal-state dependency or direct Gye asset reuse.

## Progress authority and construction sequence

`HanokStageService.levelRatios()` remains the only P2 construction input. The projection is pure, zero-write, and immediately preserves progress for existing users.

| Unlock | Condition | Map result |
|---|---:|---|
| Legacy courtyard | before B1 25% | existing 12-stage art remains visible |
| Sotdaeulmun | B1 25% | southern entrance |
| Haengrangchae | B1 50% | service wing |
| Sarangchae | B1 100% | learning venue |
| Anchae | B2 25% | personal archive venue |
| Daecheongmaru | B2 50% | learning path venue |
| Sadang | B2 75% | achievements venue |
| Rear garden | B2 100% | finished estate + pond/bridge landscape |

Sarangbang study stays reachable from Home before the physical Sarangchae is constructed. The world map becomes the visual proof of the same progress; it never gates existing study content.

## Completion definition

1. **Construction complete:** all seven derived map structures/landscape milestones, at B2 100%.
2. **Jongga 100%:** a later collection layer on top of construction—exterior landscape, three interiors, and eventually Gye donation. It must not be falsely declared by P2.

## Personal map asset contract

All new files live under `assets/illustrations/personal_hanok_v2/`. Existing dirty `hanok_compound/` prototypes are frozen and never referenced.

- `map/site_base_light.png`: opaque 4:3 terrain, walls, paths, empty footprints, no buildings or pond water.
- `map/reference_full_estate.png`: opaque visual-review reference only; never selected by runtime progress.
- `map/structures/*.png`: six full-canvas RGBA overlays.
- `map/landscape/*.png`: full-canvas RGBA pond, bridge, garden, pavilion, jars, and lantern overlays.
- All overlays use exactly the base camera: north up, south down, east-west roof ridges horizontal, one shallow aerial 3/4 angle, upper-left light, Faceted Minhwa paint treatment.
- The bridge is above pond water in z-order and physically spans its middle. No direct references to `assets/illustrations/gye/` are allowed.

## Routing contract

| Place | Action |
|---|---|
| Sarangchae | `/sarangbang` (today's existing recommendation) |
| Sarangbang furnishing | `/sarangbang/furnish` only |
| Daecheongmaru | `/path` |
| Haengrangchae | `/practice` |
| Anchae | local sheet to bookshelf, wordbook, book capture |
| Huwon | daily character / quests |
| Sadang | dojangcheop / stats |
| Gye road | visual-only in P2 |

## Non-negotiable boundaries

- Do not change `HanokStageService`, CourseMastery 70% evidence semantics, `ownedDecor`, `pendingBoxes`, reward journal, or room placement data.
- Do not create a P2 storage key, migration, reward, or cloud-sync field.
- Do not reinterpret pack ratios as CourseMastery completion. CourseMastery is read only to choose the existing mission CTA.
- Use DE/EN ARB keys and regenerated l10n output for all UI text.
- Use Sori text/surface components; do not add raw typography, new pill/badge chrome, or Gye shared state.

## Acceptance gates

- Pure threshold/catalog tests prove monotonic construction and no Gye/prototype path reference.
- Widget tests prove Sarangbang recommendation routing, furnishing separation, map-zone navigation, 44dp targets, and reduced-motion-safe rendering.
- Responsive coverage includes 308/360/600/720/800/1280dp and 1.3x text.
- Composite asset checker validates dimensions, alpha/corners, chroma-key absence, and map-family path isolation.
