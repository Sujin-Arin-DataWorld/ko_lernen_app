# Sarangbang Production Assets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Replace every intentional Sarangbang P1 fallback with style-compliant production assets and leave the analyzer plus room asset guards green.

**Architecture:** The existing RoomPlacementService, RoomLayer, BojagiScreen, and slot coordinates remain the source of behavior. This plan only supplies their missing image paths, validates true alpha for overlay assets, and activates the existing whitelist and asset-integrity guards. The quarantined 2026-08-04 downloads remain excluded because their watercolour outlines, white canvases, and room marker dots violate the visual contract.

**Tech Stack:** Flutter/Dart asset bundle, existing Pillow-based decoration normalizer, built-in image generation, imagegen chroma-key removal helper, Flutter widget and integrity tests.

## Global Constraints

- Follow docs/ASSET_GENERATION_BIBLE.md exactly: Faceted Minhwa, angular planes, no outlines, one-or-fewer gradients, subtle hanji grain, restricted palette, no text.
- Do not move or alter the five Sarangbang slot definitions, reward journal, storage, room-placement service, or localization.
- The background is an opaque 3:4 scene. Bojagi and all six decorations are true RGBA cut-outs with transparent corners.
- Use #00FF00 only as an intermediate chroma key; never bundle it.
- Existing quarantined downloads are evidence only and must not be restored to production paths.
- Stage only files changed by this plan. Log every completed implementation commit in AGENTS.md.

---

## File Structure

| Path | Responsibility |
|---|---|
| lib/widgets/sori/mascot.dart | Remove one dead asset constant; preserve all selected poses. |
| assets/illustrations/hanok/sarangbang_empty.png | Opaque empty room that matches existing fractional slot geometry. |
| assets/illustrations/reward/reward_bojagi_closed.png | Transparent, tied reward bundle. |
| assets/illustrations/reward/reward_bojagi_open.png | Transparent, opened empty reward bundle. |
| assets/illustrations/decorations/decoration_*.png | Six normalized transparent interior decorations. |
| lib/widgets/sori/placed_decoration.dart | Whitelist the six supplied decorations. |
| test/data_integrity_test.dart | Remove fulfilled P1 paths from the intentional-missing allowlist. |
| AGENTS.md | Update P1 progress and record verification/commit hashes. |

### Task 1: Remove the dead mascot warning

**Files:**
- Modify: lib/widgets/sori/mascot.dart
- Modify: AGENTS.md

**Interfaces:**
- Consumes: _assetFor(double t, {required bool animating}) current magpie switch.
- Produces: identical emotion-to-path results without the unused _magpiePerched constant.

- [ ] **Step 1: Establish the failing analyzer baseline**

Run:

    flutter analyze --no-pub

Expected: exactly one unused_field warning for _magpiePerched in mascot.dart.

- [ ] **Step 2: Remove only the unreachable constant**

Delete this declaration and leave every _assetFor branch unchanged:

    static const _magpiePerched =
        'assets/illustrations/mascot/magpie_perched.png';

- [ ] **Step 3: Verify behavior and analysis**

Run:

    flutter analyze --no-pub
    flutter test test/mascot_ticker_test.dart test/responsive_test.dart

Expected: no analyzer issue, existing mascot animation coverage passes, and no new asset path is selected.

- [ ] **Step 4: Record and commit**

Update the active P1 log with the analyzer/test results, then commit only:

    git add -- lib/widgets/sori/mascot.dart AGENTS.md
    git commit -m "fix(mascot): remove unused perch asset constant"

### Task 2: Produce the aligned empty-room background

**Files:**
- Create: assets/illustrations/hanok/sarangbang_empty.png
- Modify: AGENTS.md

**Interfaces:**
- Consumes: kSarangbangSlots in placed_decoration.dart.
- Produces: a 3:4 opaque background whose wall, floor, shelf, and peg positions remain behind the current fractional slot anchors.

- [ ] **Step 1: Reject the existing quarantined background explicitly**

Inspect:

    assets/illustrations/.asset_intake_2026-08-04/hanok/raw/sarangbang_empty.png

Expected rejection criteria: eight coloured marker dots, painterly soft shading,
and outline-led detail. Keep the file quarantined; do not copy it.

- [ ] **Step 2: Generate one clean background candidate**

Use the built-in image generator with existing hanok/gate.png as a style
reference and this prompt:

    Use case: illustration-story
    Asset type: empty Sarangbang room background for a Korean learning app
    Primary request: a quiet empty traditional Korean sarangbang interior in a
    vertical 3:4 composition. Exact existing layout: a shallow built-in alcove
    occupies the far left edge with two clear shelf tiers; a short wooden peg
    rail is high on the upper-left wall; the broad centered back wall is empty
    for a bookshelf screen; the lower centre floor is empty for low furniture;
    warm lattice windows are on the right. No people, animals, text, labels,
    coloured dots, placeholders, reward icons, or objects in the five placement
    zones.
    Style/medium: Faceted Minhwa editorial illustration, crisp angular colour
    planes, no drawn outlines, subtle hanji grain.
    Palette: #FAF6EC #F4E8D0 #8E6646 #5C4028 #2A3340 #1A2028 #C24A45 #DFA951 #3D9A7F.
    Constraints: opaque full canvas; soft daylight from right; at most one
    gradient; clear 3:4 architectural perspective; no watercolour wash.
    Avoid: modern furniture, Chinese/Japanese architecture, crane, extra props,
    checkerboard, text, marker dots, watermark.
    IMPORTANT: match the geometric faceted style, color palette, paper grain
    texture, and overall mood of the attached reference images exactly. This
    must look like part of the same illustrated set.

- [ ] **Step 3: Inspect and normalize the chosen candidate**

Use visual inspection at full size and 100 px. Crop or resize without stretching
to a 3:4 opaque PNG, verify the five slot zones remain clear, and save it at:

    assets/illustrations/hanok/sarangbang_empty.png

Expected: no alpha requirement, no marker pixels, no baked UI.

- [ ] **Step 4: Verify the existing fallback path becomes real**

Run:

    flutter test test/data_integrity_test.dart test/room_layer_test.dart

Expected: data_integrity still passes while the background remains pending until
Task 4 removes the allowlist entry.

### Task 3: Produce matching transparent bojagi sprites

**Files:**
- Create: assets/illustrations/reward/reward_bojagi_closed.png
- Create: assets/illustrations/reward/reward_bojagi_open.png
- Modify: AGENTS.md

**Interfaces:**
- Consumes: kBojagiClosed and kBojagiOpen in bojagi_screen.dart.
- Produces: matching one-to-one transparent sprites for empty/reward states and
  the knot-opening interaction.

- [ ] **Step 1: Reject the quarantined pair**

Inspect:

    assets/illustrations/.asset_intake_2026-08-04/reward/raw/reward_bojagi_closed.png
    assets/illustrations/.asset_intake_2026-08-04/reward/raw/reward_bojagi_open.png

Expected rejection criteria: white canvas, watercolour shading, stitched
outlines, and sparkles that imply a selected reward before the picker.

- [ ] **Step 2: Generate the closed sprite**

Use a flat #00FF00 chroma-key background and this prompt:

    Use case: illustration-story
    Asset type: transparent reward-bundle sprite for a Korean learning app
    Primary request: one tied Korean bojagi bundle, compact rounded-square
    silhouette with a clear central knot and folded cloth panels. It is closed;
    show no reward item, no glow, and no loose contents.
    Style/medium: Faceted Minhwa, large angular fabric planes, no drawn
    outlines, subtle hanji grain, premium editorial icon.
    Palette: hanji ivory #F4E8D0, dancheong red #C24A45, gold #DFA951,
    teal #3D9A7F, muted indigo #1F2E5C.
    Scene/backdrop: perfectly flat #00FF00 chroma-key background, no shadow,
    reflection, floor, gradient, texture, text, or watermark.
    Composition/framing: centred 1:1 square with generous empty padding.
    Avoid: watercolour, stitching, black outlines, photorealism, marker dots,
    animals, sparkles, visible gift contents.

- [ ] **Step 3: Generate the opened sprite**

Use the same prompt and palette with this exact primary request replacement:

    one unfolded Korean bojagi cloth in a low open bowl shape, cloth folds
    visible and a loosened knot string resting beside it. The bundle is empty:
    do not show a reward item, floating glow, particle, text, or sparkle.

- [ ] **Step 4: Remove the chroma key and validate alpha**

For each chosen source, run the installed helper:

    python C:/Users/vjinn/.codex/skills/.system/imagegen/scripts/remove_chroma_key.py --input INPUT.png --out OUTPUT.png --auto-key border --soft-matte --transparent-threshold 12 --opaque-threshold 220 --despill

Then inspect on cream, black, and teal backgrounds. Expected: RGBA output,
transparent corners, no green fringe, no white rectangle, and matched closed/
open palette and apparent scale.

- [ ] **Step 5: Commit the room and bojagi art**

Update AGENTS.md with the accepted/rejected asset evidence and commit only:

    git add -- assets/illustrations/hanok/sarangbang_empty.png assets/illustrations/reward/reward_bojagi_closed.png assets/illustrations/reward/reward_bojagi_open.png AGENTS.md
    git commit -m "feat(assets): add Sarangbang background and bojagi sprites"

### Task 4: Produce and activate the six interior decorations

**Files:**
- Create: assets/illustrations/decorations/decoration_munbangsau.png
- Create: assets/illustrations/decorations/decoration_seoan.png
- Create: assets/illustrations/decorations/decoration_chaekgado.png
- Create: assets/illustrations/decorations/decoration_jagae_mungap.png
- Create: assets/illustrations/decorations/decoration_gat_buchae.png
- Create: assets/illustrations/decorations/decoration_soban.png
- Modify: lib/widgets/sori/placed_decoration.dart
- Modify: test/data_integrity_test.dart
- Modify: AGENTS.md

**Interfaces:**
- Consumes: kDecorCategory and kDecorScale unchanged.
- Produces: six disk files matching their existing names and the six whitelist
  entries required by SoriDecorationImage.

- [ ] **Step 1: Generate each cut-out separately**

For every subject below, use the same #00FF00 chroma-key, Faceted Minhwa,
no-outline, subtle-hanji-grain contract and a single object with 3 percent
visible breathing room:

    decoration_munbangsau: brushes, inkstone, ink stick, water dropper, and
    rolled paper arranged as a compact horizontal scholar writing set.
    decoration_seoan: low Korean scholar writing desk with wing-lifted ends,
    warm walnut top, simple legs, low horizontal silhouette.
    decoration_chaekgado: a four-panel Korean books-and-objects folding screen,
    tall vertical wall silhouette; no text on book spines.
    decoration_jagae_mungap: a long low mother-of-pearl chest, black lacquer
    facets with restrained teal/gold shell inlay geometry, no lettering.
    decoration_gat_buchae: one accurate black Korean gat and one folded fan
    hanging together from a simple dark wooden peg; no person.
    decoration_soban: one small round Korean tray table, low slender legs,
    warm walnut and gold facets, compact low silhouette.

- [ ] **Step 2: Remove chroma key and normalize the six files**

Run the chroma-key helper for each source into:

    assets/illustrations/decorations/_raw/

Then run:

    python tool/decoration_normalize.py

Expected: each final PNG preserves its natural aspect ratio, has transparent
corners, no key fringe, and fits the existing scale values without a new scale
or category change.

- [ ] **Step 3: Establish the intended guard failure**

With all six final files present but before whitelist/pending edits, run:

    flutter test test/decoration_slot_test.dart test/data_integrity_test.dart

Expected: decoration_slot_test identifies exactly the six unwhitelisted files;
data_integrity identifies the now-present three P1 paths as stale pending
entries.

- [ ] **Step 4: Activate the files minimally**

Append exactly these values to kAvailableDecorations:

    'decoration_munbangsau',
    'decoration_seoan',
    'decoration_chaekgado',
    'decoration_jagae_mungap',
    'decoration_gat_buchae',
    'decoration_soban',

Delete exactly these pending literals from test/data_integrity_test.dart:

    'assets/illustrations/hanok/sarangbang_empty.png',
    'assets/illustrations/reward/reward_bojagi_closed.png',
    'assets/illustrations/reward/reward_bojagi_open.png',

- [ ] **Step 5: Run the complete focused regression and inspect the results**

Run:

    flutter analyze --no-pub
    flutter test test/dancheong_stamp_test.dart test/decoration_slot_test.dart test/data_integrity_test.dart test/bojagi_screen_test.dart test/sarangbang_picker_test.dart test/room_layer_test.dart

Expected: analyzer has no issue; every focused test passes; all six files and
all three formerly-pending paths are now bundle-backed.

- [ ] **Step 6: Record and commit the activated production assets**

Update AGENTS.md with the visual acceptance results, asset alpha evidence,
focused test count, and the completed P1 checklist state. Commit only:

    git add -- assets/illustrations/decorations/decoration_munbangsau.png assets/illustrations/decorations/decoration_seoan.png assets/illustrations/decorations/decoration_chaekgado.png assets/illustrations/decorations/decoration_jagae_mungap.png assets/illustrations/decorations/decoration_gat_buchae.png assets/illustrations/decorations/decoration_soban.png lib/widgets/sori/placed_decoration.dart test/data_integrity_test.dart AGENTS.md
    git commit -m "feat(sarangbang): activate production room assets"

## Plan Self-Review

- Spec coverage: Task 1 covers the analyzer warning; Task 2 covers the opaque
  room and coordinate-preserving background; Task 3 covers both bojagi
  interaction states and true alpha; Task 4 covers all six categories,
  whitelist activation, pending removal, visual validation, and regression.
- No placeholders: every target path, asset name, category, command, prompt
  constraint, and expected result is explicit.
- Type consistency: no public Dart interface changes; the plan uses the
  existing kAvailableDecorations, kDecorCategory, kDecorScale, kBojagiClosed,
  kBojagiOpen, and kSarangbangSlots names exactly.
