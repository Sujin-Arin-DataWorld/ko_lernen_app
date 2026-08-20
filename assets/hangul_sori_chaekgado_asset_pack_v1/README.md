# Hangul Sori Chaekgado Asset Pack V1

## Included
- 1 complete chaekgado bookcase, plus separate backplate and foreground-frame layers.
- Repeatable top, middle, and bottom slices for variable category counts.
- 6 transparent book clusters.
- 15 transparent category vignettes covering the A1/A2 domains already defined in the design work.
- 14 newly completed standalone chaekgado decorations and scholar/life props.
- Existing 3-slice scroll UI assets.
- Slot layout JSON, slot mask, contact sheets, and layer-composition QA image.

## Runtime order
1. `bookcase/chaekgado_bookcase_backplate.png`
2. Books and category vignette assets placed using `bookcase/layout.json`
3. `bookcase/chaekgado_bookcase_foreground_frame.png`
4. Flutter text, progress indicators, lock state, and interaction feedback

## Variable rows
Use the matching slices in this order:
- top
- middle repeated as required
- bottom

Keep the same slice family for backplate and frame. Render the backplate slices first, place content, then render the frame slices above.

## Important
- All files under `transparent/` and the bookcase layer files use true RGBA transparency.
- Files under `raw_green/` retain a pure-green source background for provenance and reprocessing.
- Text, progress, selection, locks, and shadows should remain Flutter/runtime effects.
- Official Hangul Sori tiger and magpie artwork is intentionally not regenerated here. Use the official project-owned mascot files for any peek animation.
