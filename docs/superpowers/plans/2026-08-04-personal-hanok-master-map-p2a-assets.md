# Personal Hanok Master Map P2a Assets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a coherent, production-ready 4:3 personal Hanok master-map art package: one site base and six tappable building components, while directly reusing the proven Gye pond-and-bridge pair without coupling personal and Gye state.

**Architecture:** `site_base.png` is the opaque, unbuilt 4:3 ground plane. Six map-perspective RGBA structures are independent layers with the same camera, north/south orientation, light direction, and ground anchors. The future personal catalog references `gye_pond_large.png` and `gye_bridge.png` by their existing paths as one rear-garden milestone; no Gye model, storage key, or widget changes in P2a.

**Tech Stack:** Flutter bundled PNG assets, built-in image generation, the installed chroma-key removal helper, Pillow asset audit, and Flutter/Dart asset-reference tests in the later P2b integration.

## Global Constraints

- Keep the supplied asymmetric traditional-plan relationship: south gate and long sarangchae; upper inner court with U-shaped anchae; separate east sadang; lower-right rear garden.
- Follow `docs/ASSET_GENERATION_BIBLE.md` exactly: Faceted Minhwa, no black outlines, restricted palette, subtle hanji grain, no text, no markers, no white rectangle, and no gradient except the opaque base sky/atmosphere if used.
- `site_base.png` is exactly 1536×1152 (4:3), opaque RGB/RGBA with fully opaque corners; six structures are RGBA with fully transparent corners and no chroma-key pixels.
- Every transparent structure uses the same elevated-plan camera, upper-left light, and a ground contact at its bottom edge. No baked terrain or neighboring building belongs in a structure asset.
- Reuse only artwork, never personal/Gye progress, storage, unlock, ownership, or UI state. Do not edit `lib/widgets/sori/gye_hanok.dart` in P2a.
- Do not modify the existing `DecorationLayer` or put structures into `assets/illustrations/decorations/`.
- Keep all user-facing runtime text out of P2a. There are no ARB changes until P2c.
- Stage and commit only files created by the current task. Do not push.

### User-directed R1 camera correction (2026-08-04)

The first six transparent layers passed the mechanical alpha guard but were
rejected in composite review: each object used a slightly different freestanding
three-quarter camera, so the result read as pasted models rather than one
traditional plan. Keep `site_base.png`, anchors, the checker, and the direct
pond/bridge reuse decision. Regenerate all six structures in a single
**north-up, plan-locked oblique** system before P2a acceptance:

- Map south is always the lower edge. Long east--west roof ridges are horizontal;
  entrances face down/south unless a U-shaped wing demands the map-aligned
  north--south axis.
- Use a shallow, shared oblique roof depth only. No object may introduce an
  individual yaw, front-facade camera, or distinct vanishing point.
- First calibrate the long `sarangchae` over `site_base`, then regenerate the
  other five against that accepted orientation. Re-run the existing checker,
  inspect 360/600/800/1280 composites, and replace only the six layer files.

### User-directed R2 estate-scale and pond-bridge correction (2026-08-04)

The R1 camera is map-aligned, but the user correctly noted that the underlying
compound still feels like a small sketchbook despite future exterior content.
Before acceptance, redraw the opaque base as a broader 4:3 jongga estate and
reduce the six structural footprints using the revised anchor table in
`docs/P2A_HANOK_COMPOUND_ASSET_SHEET.md`. Reuse the existing pond at the new
anchor and move the existing bridge upward and above the water so it visibly
crosses the pond's centre rather than sitting as a foreground ornament. Keep
the R1 north-up orientation for every structure.

---

## File Structure

| Path | Responsibility |
|---|---|
| `assets/illustrations/hanok_compound/site_base.png` | Opaque 4:3 unbuilt compound terrain, perimeter walls, paths, empty rear-garden basin, and no buildings. |
| `assets/illustrations/hanok_compound/sotdaeulmun.png` | Transparent front/south raised gate layer. |
| `assets/illustrations/hanok_compound/haengrangchae.png` | Transparent outer/service-wing layer. |
| `assets/illustrations/hanok_compound/sarangchae.png` | Transparent long front-wing layer aligned with `/sarangbang`. |
| `assets/illustrations/hanok_compound/anchae.png` | Transparent U-shaped inner-residence layer. |
| `assets/illustrations/hanok_compound/daecheongmaru.png` | Transparent open-hall layer. |
| `assets/illustrations/hanok_compound/sadang.png` | Transparent, separately enclosed shrine layer. |
| `pubspec.yaml` | Bundles the `hanok_compound/` directory into every Flutter target. |
| `tool/check_hanok_compound_assets.py` | Deterministic asset-format guard: required paths, base dimensions/opacity, layer alpha corners, alpha coverage, and chroma-key absence. |
| `docs/P2A_HANOK_COMPOUND_ASSET_SHEET.md` | Production placement sheet: normalized map anchors, exact reuse paths, generation prompts, and visual acceptance criteria. |
| `AGENTS.md` | P2a state and the implementation/verification/commit record. |

## Task 1: Establish the asset contract and deterministic checker

**Files:**
- Create: `tool/check_hanok_compound_assets.py`
- Create: `docs/P2A_HANOK_COMPOUND_ASSET_SHEET.md`
- Modify: `pubspec.yaml`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: `assets/illustrations/hanok_compound/{site_base,sotdaeulmun,haengrangchae,sarangchae,anchae,daecheongmaru,sadang}.png`
- Produces: exit code `0` only when the entire production package is present and mechanically valid; a one-line report per asset.

- [x] **Step 1: Write the missing-package assertion first**

Create `tool/check_hanok_compound_assets.py` with the exact asset map below. A missing file must print `[missing] <path>` and make `main()` return `1`.

```python
SPECS = {
    'site_base.png': {'size': (1536, 1152), 'transparent': False},
    'sotdaeulmun.png': {'transparent': True},
    'haengrangchae.png': {'transparent': True},
    'sarangchae.png': {'transparent': True},
    'anchae.png': {'transparent': True},
    'daecheongmaru.png': {'transparent': True},
    'sadang.png': {'transparent': True},
}
```

- [x] **Step 2: Run the checker before creating assets**

Run: `python tool/check_hanok_compound_assets.py`

Expected: exit `1` and seven `[missing]` lines. This is the asset equivalent of the RED test.

- [x] **Step 3: Implement the full mechanical contract**

Use Pillow `Image.open(...).convert('RGBA')`. For `site_base.png`, require exactly `1536×1152`, alpha `255` at all four corners, and no `#00ff00` pixel. For each structure, require alpha `0` at all four corners, alpha coverage between `2%` and `90%`, a nonempty opaque bounding box, and no pixel whose RGB is `(0, 255, 0)` with alpha above `8`. Print dimensions, alpha coverage, and pass/fail status.

Add `- assets/illustrations/hanok_compound/` immediately after the existing `hanok/` asset directory in `pubspec.yaml` so a later `/hanok` renderer is not silently missing its bundled PNGs.

- [x] **Step 4: Write the placement and generation sheet**

Create `docs/P2A_HANOK_COMPOUND_ASSET_SHEET.md` with this exact anchor table. Fractions use the 1536×1152 base and `bottom` is measured from the lower edge.

| id | left | bottom | width | z | role |
|---|---:|---:|---:|---:|---|
| `anchae` | 0.18 | 0.52 | 0.36 | 20 | upper inner court, U-shaped family residence |
| `sadang` | 0.76 | 0.57 | 0.14 | 21 | east enclosure, cultural archive destination |
| `haengrangchae` | 0.10 | 0.26 | 0.19 | 30 | west/front service wing |
| `sarangchae` | 0.22 | 0.18 | 0.34 | 31 | long south-facing study/guest wing |
| `sotdaeulmun` | 0.46 | 0.02 | 0.14 | 40 | south entrance gate |
| `daecheongmaru` | 0.55 | 0.39 | 0.12 | 41 | open hall between courts |
| `gye_pond_large` | 0.60 | 0.10 | 0.28 | 50 | personal rear pond, direct asset reuse |
| `gye_bridge` | 0.65 | 0.20 | 0.18 | 51 | personal rear-pond crossing, direct asset reuse |

Also record the base prompt, all six layer prompts, and the visual acceptance criteria from this plan.

- [x] **Step 5: Commit the contract only**

```powershell
git add tool/check_hanok_compound_assets.py docs/P2A_HANOK_COMPOUND_ASSET_SHEET.md AGENTS.md
git commit -m "chore(hanok): add master map asset contract"
```

### Task 2: Generate and validate the opaque site base

**Files:**
- Create: `assets/illustrations/hanok_compound/site_base.png`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: `docs/P2A_HANOK_COMPOUND_ASSET_SHEET.md` and the user-approved traditional-plan reference.
- Produces: a 1536×1152 opaque foundation for all building coordinates in Task 1.

- [x] **Step 1: Generate a single 4:3 base candidate**

Use the built-in image generator with the following prompt. Reference the approved traditional-plan mockup only for layout, and `gye_pond_large.png` only for the Faceted Minhwa material/palette.

```text
Use case: historical-scene
Asset type: opaque 4:3 ground layer for an interactive Korean Hanok compound map
Input images: traditional-plan mockup = layout reference; gye_pond_large.png = material and Faceted Minhwa reference
Primary request: an empty, elevated-plan Joseon jongga compound ground plane, asymmetrical traditional layout. South/front outer wall has an open reserved footprint for a raised main gate. Lower-left and lower-center reserve a long sarangchae footprint; a smaller west service-wing footprint sits nearby. Upper inner court reserves a large U-shaped anchae footprint. A separated east shrine enclosure has an empty building footprint. A clear open-hall footprint connects the courts. In the lower-right rear garden leave an empty pond basin and a short curved path for a bridge.
Scene/backdrop: warm hanji cream terrain, pale stone perimeter walls, sandy paths, restrained rocks and low planting only; no sky, no people, no text.
Style/medium: Faceted Minhwa, angular color planes, subtle hanji grain, upper-left light, elevated three-quarter plan camera.
Composition/framing: exactly 4:3 landscape, full compound visible with 4% outer hanji margin; all seven future elements have open, uncluttered ground anchors.
Constraints: no completed building, no roof, no gate, no pond water, no bridge, no colored circles, no labels, no placeholder pads, no white rectangle, no cast object shadow beyond terrain.
Avoid: outlines, isometric game tiles, Chinese/Japanese architecture, random cranes, photorealism, 3D render, watermark, text.
```

- [x] **Step 2: Normalize to the fixed base size**

Select the candidate that keeps all eight anchors unobstructed. Crop or resample with high-quality Lanczos only if required, then save exactly to `assets/illustrations/hanok_compound/site_base.png`. Do not add transparency.

- [x] **Step 3: Run the checker and inspect it at map scale**

Run: `python tool/check_hanok_compound_assets.py`

Expected: `site_base.png` reports `PASS`; six layers remain missing. Inspect the base at 360dp and 1280dp-equivalent scale; reject it if any future footprint is ambiguous.

- [x] **Step 4: Commit the base**

```powershell
git add assets/illustrations/hanok_compound/site_base.png AGENTS.md
git commit -m "feat(hanok): add master map site base"
```

### Task 3: Generate the south-front construction layers

**Files:**
- Create: `assets/illustrations/hanok_compound/sotdaeulmun.png`
- Create: `assets/illustrations/hanok_compound/haengrangchae.png`
- Create: `assets/illustrations/hanok_compound/sarangchae.png`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: the 1536×1152 base, anchor table, `gye_gate_grand.png` and `gye_byeoldang.png` as material references only.
- Produces: three non-overlapping RGBA layers whose finished buildings can be tapped independently.

- [x] **Step 1: Generate `sotdaeulmun` on chroma key**

Prompt for a single raised Korean gate in the exact map camera: south-facing dark tiled roof, warm walnut doors, correct upturned eaves, no surrounding wall or terrain, no text, and a perfectly flat `#00ff00` background. Keep 8% transparent margin after removal and no green in the gate.

- [x] **Step 2: Remove chroma and validate `sotdaeulmun`**

Run:

```powershell
python C:\Users\vjinn\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py --input <generated-source> --out assets/illustrations/hanok_compound/sotdaeulmun.png --auto-key border --soft-matte --transparent-threshold 12 --opaque-threshold 220 --despill
python tool/check_hanok_compound_assets.py
```

Expected: gate is the only nontransparent object; all corners are alpha zero; no green fringe.

- [x] **Step 3: Generate and validate `haengrangchae`**

Prompt for a single low west-facing service wing, shorter than the sarangchae, same elevated-plan camera and upper-left light, with a `#00ff00` chroma-key background. Exclude people, jars, trees, walls, and adjacent buildings. Remove chroma with the exact command in Step 2, then rerun the checker.

- [x] **Step 4: Generate and validate `sarangchae`**

Prompt for one long, south-facing guest/study wing with a visible wooden porch and center `daecheong` threshold, but no furniture, no people, no wall, and no surrounding terrain. Use the same `#00ff00` chroma-key contract, remove it with the Step 2 command, and rerun the checker.

- [x] **Step 5: Composite-review the three layers over `site_base`**

Create a temporary, untracked local mockup using the anchor table. Reject any candidate whose roof overlaps another anchor, faces a different camera direction, or hides the lower-right pond zone.

- [x] **Step 6: Commit south-front layers**

```powershell
git add assets/illustrations/hanok_compound/sotdaeulmun.png assets/illustrations/hanok_compound/haengrangchae.png assets/illustrations/hanok_compound/sarangchae.png AGENTS.md
git commit -m "feat(hanok): add front compound layers"
```

### Task 4: Generate the inner-court construction layers

**Files:**
- Create: `assets/illustrations/hanok_compound/anchae.png`
- Create: `assets/illustrations/hanok_compound/daecheongmaru.png`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: the base and map anchors from Task 1; the visual language established by Task 3.
- Produces: independently tappable inner-living and open-hall layers without modifying the existing Sarangbang surface.

- [x] **Step 1: Generate and validate `anchae`**

Prompt for a single U-shaped Korean inner residence seen from the same elevated-plan camera. Its inner court must open toward the lower/south side, with the high roof line framing an open courtyard. Use a flat `#00ff00` chroma-key background; include no people, furniture, wall, gate, pond, or text. Remove chroma with the Task 3 command and rerun the checker.

- [x] **Step 2: Generate and validate `daecheongmaru`**

Prompt for a compact, roofed but visibly open wooden great hall that reads as a connected open maru, not a closed dwelling. Preserve the map camera and upper-left light. Use the same `#00ff00` chroma-key background and exact removal/validation command.

- [x] **Step 3: Composite-review the inner court**

Place both layers over the base with the Task 1 anchors. Confirm that the U-shaped anchae encloses the inner court without covering the east sadang enclosure or the future sarangchae route.

- [x] **Step 4: Commit inner-court layers**

```powershell
git add assets/illustrations/hanok_compound/anchae.png assets/illustrations/hanok_compound/daecheongmaru.png AGENTS.md
git commit -m "feat(hanok): add inner court layers"
```

### Task 5: Generate the separated shrine layer

**Files:**
- Create: `assets/illustrations/hanok_compound/sadang.png`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: base, map anchors, and Task 3 camera/light contract.
- Produces: an unambiguous shrine building with no furniture/decor placement semantics.

- [x] **Step 1: Generate `sadang` on chroma key**

Prompt for one compact, dignified Korean ancestral shrine in a separate east enclosure: traditional tiled roof, restrained dancheong under eaves, closed lattice doors, stone threshold, and the same elevated-plan camera. The asset is a building only: no ancestor portraits, incense, people, text, shrine tablets, garden, wall, or neighboring roof. Use a perfectly flat `#00ff00` chroma-key background.

- [x] **Step 2: Remove chroma, run the checker, and compose-review**

Use the Task 3 removal command. Then place the layer at `(left: .74, bottom: .52, width: .17)` over the base. Confirm it is visibly separate from the inner court and has no accidental interior-entry visual cue.

- [x] **Step 3: Commit the shrine**

```powershell
git add assets/illustrations/hanok_compound/sadang.png AGENTS.md
git commit -m "feat(hanok): add shrine map layer"
```

### Task 6: Verify direct pond-and-bridge reuse and full asset assembly

**Files:**
- Modify: `docs/P2A_HANOK_COMPOUND_ASSET_SHEET.md`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: seven P2a assets plus existing `assets/illustrations/gye/gye_pond_large.png` and `gye_bridge.png`.
- Produces: one reviewed, untracked visual assembly and an approved list of runtime asset paths for P2b.

- [ ] **Step 1: Make the full visual assembly**

Use the exact anchor table from Task 1 to composite `site_base`, all six structures, `gye_pond_large.png`, and `gye_bridge.png`. The pond/bridge render above terrain but below no building. Do not copy the Gye files into `hanok_compound/`.

- [ ] **Step 2: Inspect four target sizes**

Inspect the assembly at 360×270, 600×450, 800×600, and 1280×960. Confirm: all six structures read as separate targets; pond and bridge remain a pair; gate has a visible south approach; no alpha box/chroma fringe appears; no layer masks another route.

- [ ] **Step 3: Freeze the accepted runtime path list**

Append this exact list to `docs/P2A_HANOK_COMPOUND_ASSET_SHEET.md`:

```text
assets/illustrations/hanok_compound/site_base.png
assets/illustrations/hanok_compound/sotdaeulmun.png
assets/illustrations/hanok_compound/haengrangchae.png
assets/illustrations/hanok_compound/sarangchae.png
assets/illustrations/hanok_compound/anchae.png
assets/illustrations/hanok_compound/daecheongmaru.png
assets/illustrations/hanok_compound/sadang.png
assets/illustrations/gye/gye_pond_large.png
assets/illustrations/gye/gye_bridge.png
```

- [ ] **Step 4: Run final mechanical validation**

Run: `python tool/check_hanok_compound_assets.py`

Expected: seven `PASS` lines, exit `0`. Then run `git diff --check`.

- [ ] **Step 5: Commit P2a acceptance evidence**

```powershell
git add docs/P2A_HANOK_COMPOUND_ASSET_SHEET.md AGENTS.md
git commit -m "docs(hanok): approve master map asset assembly"
```

### Task 7: Correct the map camera coherence (R1)

**Reason:** User composite review rejected the first six structure layers:
their individual three-quarter yaws made the compound read as pasted models,
not one traditional plan. The opaque base, normalized anchors, and existing
pond/bridge reuse remain approved.

**Files:**
- Modify: all six `assets/illustrations/hanok_compound/*.png` structure layers
- Modify: `AGENTS.md`

- [x] **Step 1: Lock the north-up camera contract**

Document that map south is the lower edge, east--west ridges are horizontal,
and no individual asset may use a distinct yaw or vanishing point.

- [x] **Step 2: Calibrate the long `sarangchae` against `site_base`**

Generate and compose a horizontal-ridge, high plan-oblique sarangchae over the
actual base at its production anchor before using it as the shared camera
reference.

- [x] **Step 3: Regenerate the five remaining structure layers**

Replace anchae, haengrangchae, daecheongmaru, sadang, and sotdaeulmun with the
same north-up camera; retain only the real U-shape's vertical side wings.

- [x] **Step 4: Validate the replacement package mechanically**

`python tool/check_hanok_compound_assets.py` passes all seven required files:
the base remains opaque and each replacement has transparent corners, a valid
alpha coverage, and no green chroma residue.

- [x] **Step 5: Reinspect the four responsive assembly scales**

Confirm the R1 360×270, 600×450, 800×600, and 1280×960 assemblies preserve
one plan axis and distinguish every required building and the reused pond /
bridge pair.

- [ ] **Step 6: Commit the camera-corrected replacement layers**

### Task 8: Enlarge the estate and cross the pond with the bridge (R2)

**Reason:** The map needs durable exterior collection capacity. The user asked
for a larger compound ground plane and for the reused stone bridge to cross,
rather than sit in front of, the pond.

**Files:**
- Modify: `assets/illustrations/hanok_compound/site_base.png`
- Modify: `docs/P2A_HANOK_COMPOUND_ASSET_SHEET.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Lock the wider-estate spatial contract and revised anchors**

The base fills about 96% of the 4:3 canvas, six footprints are reduced, and
the bridge is raised above the pond along the shared rear-garden route.

- [ ] **Step 2: Generate and normalize the broader 4:3 base**

Keep the 1536×1152 opaque package contract but create generous building-free
courts, a broader lower-right rear garden, and only a small outer hanji margin.

- [ ] **Step 3: Compose R1 structures and direct Gye reuse at R2 anchors**

Use the same north-up layer assets, directly reference the existing pond and
bridge, and verify the bridge visibly crosses water.

- [ ] **Step 4: Inspect responsive scales and commit the R2 correction**

## Self-Review

- **Spec coverage:** Task 1 locks the asset format, all eight map anchors, and the personal/Gye boundary. Task 2 creates the sole opaque base. Tasks 3–5 create all six required structure layers. Task 6 proves direct pond/bridge reuse, separates completion structures from optional landscape, and records the paths P2b must use.
- **No placeholders:** Every required asset has a path, camera rule, anchor, production technique, validation command, and commit boundary. P3 interiors, Gye donation, runtime catalog, and ARB are explicitly outside this P2a plan.
- **Type/path consistency:** The seven `hanok_compound` filenames match the master-map design; the direct reuse paths exactly match `GyeHanok`'s bundled paths; the Task 1 anchor ids match later task output names.
