# Personal Hanok V2 Art Direction Lock

- Status: **FINAL SSoT — user-approved continuity contract**
- Version: `1.0.0`
- Locked: `2026-08-20`
- Scope: Personal Hanok V2 master estate and all cumulative construction-state images
- Read policy: For routine generation, read **this file + the immediately preceding approved image + the current stage row only**. Do not reread the long research report or original 366-line prompt unless this lock is genuinely ambiguous.
- Override policy: A new explicit instruction from Jin may revise this lock. Older prompts, layouts, reports, and V1 conventions may not silently override it.

## 1. Approved visual anchors

| Role | File | SHA-256 |
|---|---|---|
| Complete-estate composition/style anchor | `assets_unused/pending_review/personal_hanok_v2/estate_v2_trials/estate_v2_complete_structure_trial_01.png` | `282e08fd15565654b59dd7717da4ee1fbc4ee741068e3c711771a7888412fa1b` |
| Empty-estate camera/ground anchor | `assets_unused/pending_review/personal_hanok_v2/estate_v2_trials/estate_00_empty_site.png` | `08efcc8be9b9735958e64e344e43d151fc9a89cb16ec54d002b869f4a87e3ab7` |
| Current cumulative-state anchor | `assets_unused/pending_review/personal_hanok_v2/estate_v2_trials/boundary_03_sotdaeulmun.png` | `09fc955f96a4623de605d42b2828099b08cfa07c7c9ddeef671ac988192d126e` |

The complete-estate image fixes the final spatial relationships. The current cumulative-state image fixes the pixels, camera, walls, gate, lighting, palette, and empty ground that the next edit must preserve.

## 2. Non-negotiable image contract

- Canvas: `3072 × 2304`, exact `4:3`.
- File: 8-bit `RGB PNG` with embedded `sRGB ICC`.
- Camera: one fixed elevated, north-up-like oblique/isometric camera; no crop, zoom, rotation, tilt, or perspective reset between stages.
- Estate footprint: nearly square, subtly irregular, physical width-to-depth ratio near `1.06`; it must not become a shallow panorama.
- Light: soft upper-left illumination; restrained shallow shadows fall toward the lower-right.
- Rendering: premium **Faceted Minhwa** — hard-edged matte planes, deliberate angular facets, controlled detail, no heavy drawn outlines.
- Surface: warm compacted earth, subtle aged-hanji grain, restrained value variation, no glossy finish.
- Palette: charcoal-gray matte giwa, weathered natural timber, pale warm earth plaster, muted natural stone, quiet olive edge vegetation.
- Visual hierarchy: **space is the hero**. Architecture is secondary to readable courtyards and breathing room.

## 3. Locked spatial grammar

This is an original fictional late-Joseon-inspired jongga. It uses spatial principles associated with elite family compounds such as Unjoru but must never reconstruct or copy a named heritage property.

1. The southern/front boundary is one continuous long low haengrang wing.
2. The sotdaeulmun is the modestly raised central bay of that haengrang, never a detached gatehouse.
3. Immediately inside is the largest open surface: one broad, connected, predominantly empty outer sarang courtyard.
4. Beyond it, slightly off the perfect center, is an asymmetrical `L/T` sarang complex facing the outer courtyard.
5. A narrow offset jungmun/privacy turn leads to the private inner zone; never use a straight palace axis.
6. The anchae is four connected roofed wings enclosing one private inner courtyard.
7. Kitchen, well, gotgan/grain storage, and restrained jangdok service elements attach to one service side of the anchae.
8. One small separately enclosed shrine occupies the highest rear corner.
9. The opposite rear side remains a deliberately empty C2 transmission plot.
10. The estate rises through three restrained elevation bands: front/outer court → sarang/inner threshold → anchae/shrine/C2 rear zone.

## 4. Composition budget

- Architecture and walls: `≤35%` of the complete-estate canvas.
- Intentionally empty courtyards: `≥40%`.
- Paths, thresholds, and reserved future space: approximately `15%`.
- Vegetation and life props combined: `≤10%`.
- Outer sarang courtyard: `≥60%` one connected unobstructed earth plane.
- Inner courtyard: `≥60%` empty.
- Vegetation: edge-only, no more than two restrained clusters.

## 5. Absolute exclusions

Never add or revive:

- `rear_garden` as a structure or reward;
- an independent `daecheongmaru` building;
- ponds, bridges, pavilions, ornamental streams, flower gardens, rock gardens, or central courtyard trees;
- rigid palace symmetry, monumental axes, palace-scale gates, heavy or colorful dancheong;
- photorealism, watercolor wash, soft painterly blur, glossy 3D, anime, or cartoon styling;
- people, animals, vehicles, tools left as decoration, text, labels, arrows, UI, logos, watermarks, or modern objects;
- occupied C2 plot or a placeholder silhouette inside it.

## 6. Cumulative-generation protocol

1. Use exactly **one** image input: the immediately preceding approved stage, as the sole edit target.
2. Change only the named construction event. Preserve every other pixel relationship as aggressively as possible.
3. Never redraw the whole estate from scratch and never use the complete-estate anchor as a second generation reference.
4. Every new permanent geometry must agree with the final complete-estate spatial grammar.
5. Produce one candidate per stage. If a hard gate fails, regenerate that same stage before continuing.
6. Save only to `assets_unused/pending_review/personal_hanok_v2/estate_v2_trials/` until Jin gives separate promotion authority.
7. Do not modify runtime assets, `pubspec.yaml`, catalogs, grants, Firebase, or provenance ledgers; do not commit, push, or open a PR without separate authorization.

## 7. Locked A1 sarang construction socket

The A1 construction socket is the future sarang complex, not a random central building.

- Position: beyond the large outer courtyard on the middle elevation band, slightly off the perfect center and aligned to face the front courtyard.
- Footprint: restrained asymmetrical `L/T` geometry consistent with the complete-estate anchor; never a freestanding centered rectangle.
- Scale: subordinate to the estate and small enough to preserve the large empty courtyard.
- Future circulation: leave a readable offset route behind/alongside it toward the privacy-turn jungmun and future anchae.
- The footprint, step, foundation, and cornerstone positions become immutable after stage `02_plan_layout`.

## 8. Current and next stage definitions

| Order | ID | Visible event | Must remain absent |
|---:|---|---|---|
| 00 | `estate_00_empty_site` | Compacted earth and minimal edge vegetation | All construction |
| B01 | `boundary_01_outer_wall_foundation` | Low perimeter wall foundation | Wall body, buildings |
| B02 | `boundary_02_outer_wall_complete` | Rear/east/west outer wall plus short front returns | Front haengrang/gate until B03 |
| B03 | `boundary_03_sotdaeulmun` | Continuous southern haengrang with integrated raised central sotdaeulmun | All inner construction |
| 01 | `01_site_setout` | Small timber stakes and taut pale hemp string tracing the locked `L/T` sarang footprint | Ink grid, foundation, stones, timber frame |
| 02 | `02_plan_layout` | Same stakes plus restrained lime/earth layout lines marking column/grid positions | Foundation, cornerstones, timber frame |
| 03 | `03_foundation_gidan` | Setout replaced by a low natural-stone `L/T` foundation and one modest courtyard-facing step | Cornerstones and all timber |
| 04 | `04_cornerstones_choseok` | Same foundation plus restrained square/natural-stone column bases at the locked grid positions | Prepared timber, columns, beams, roof, walls |

Later A1 order is fixed by ID: `05_timber_preparation`, `06_columns`, `07_beams_changbang`, `08_purlins_sangnyang`, `09_rafters_roof_frame`, `10_roof_base`, `11_giwa_roof`, `12_wall_frame_sujang`, `13_earth_walls`, `14_ondol_maru`, `15_changho_finish`, `16_landscape_move_in`.

## 9. Per-stage hard gates

Reject the image if any of these occurs:

- camera, crop, wall, haengrang, gate, light, palette, grain, or existing vegetation drifts;
- the gate separates from the front haengrang;
- the A1 socket becomes centered, rectangular, oversized, or blocks the future privacy route;
- the outer courtyard stops reading as the largest clear empty plane;
- construction from a later stage appears early;
- props, vegetation, decoration, or paths are invented;
- Faceted Minhwa drifts toward photorealism, watercolor, soft blur, or glossy 3D;
- the image contains text, people, animals, modern objects, or watermarking.

## 10. Validation and reporting

For every stage:

- inspect the full image, a `25%` preview (`768 × 576`), and a `100 px`-wide thumbnail (`100 × 75`);
- confirm stage-to-stage cumulative readability at 100 px;
- confirm `3072 × 2304`, RGB, embedded sRGB ICC, and record SHA-256;
- run the repository `F-C-estate` style conformance check when available;
- report the sole input image, exact saved path, dimensions/mode/profile/hash, visual hard-gate result, and changed files.

## 11. Design-guide carryover

Hanok order, hierarchy, restraint, and breathing room are the brand system. Hanji is the field; dancheong is only a rare accent and is not used as estate-wide decoration. Do not solve weak composition by adding color or ornament.
