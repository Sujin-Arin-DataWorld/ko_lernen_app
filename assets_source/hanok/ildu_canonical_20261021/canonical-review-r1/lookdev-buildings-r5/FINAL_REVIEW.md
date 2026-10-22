# Final review — building-specific R5 candidates

2026-10-22. Fresh reviewer, read-only inspection; no Blender execution or implementation changes. Reviewed after `finish.log` reached `PIPELINE AND CAMERAS COMPLETE` and both final status files existed.

## Assessment

**Ready for user review of the native material candidates.** No Critical, Important, or Minor implementation finding requiring a fix was identified in this pass. This is a technical/visual review, not new user visual approval, canonical promotion, runtime completion, or merge/release approval.

## Evidence checked

- Read `WORK.md`, `STYLE_AUTHORITY.json`, `source-audit.json`, `material_rules.py`, `restyle_building.py`, camera correction/finalization/gallery code, and every candidate's verification and render manifest. Inspected the inherited geometry/material/attribute snapshot helpers.
- Independently recomputed current SHA-256 values for all four source natives, 14 candidate natives, recorded producer files, 56 renders, and the accepted Sarang native. No mismatch. Sarang remains `cab144f08a7836dc0eafc074456104cdbfe21eecd46eadf2c13b882d52efd4c8`.
- Counts reconcile: **14 new buildings, 4,396 meshes, 56 renders**. Gallery has **15 entries**, including the unchanged approved Sarang reference. Every native/receipt/image link exists; each image URL's cache hash matches its file.
- All 14 receipts report save/reopen success and unchanged geometry/UVs/transforms/modifiers, attributes/stages/properties, original material graphs and source image bytes. Producer code asserts those comparisons before and after reopen. This reviewer inspected these checks and receipts rather than independently reopening Blender.
- Final anchae/sadang receipts include camera-only correction and material/geometry equality. Their final PNGs were inspected after completion.

## Actual PNG review

Matched before/after inspected: ansarang detail; anchae hero; sadang detail; changgo hero; main_gate detail; left_changgo hero; sadangmun detail; toilet detail; toilet1 hero. Also inspected final candidate views for anchae detail, sadang hero, jung detail, arae hero, gokgan detail, angotgan hero, right_ansarang detail, and approved Sarang numaru. Thus at least one candidate view of every new building was visually inspected.

- Ordinary timber shows the accepted broad value/brush language with retained original palette signals. The code derives timber tones from each source material, including the existing shared source ramps; it does not impose one new Sarang brown.
- Lattice remains legible; paper and plaster are quieter than structural timber. Stone, clay tiles and timber retain separate material responses. No introduced global hue wash, chalk coating, extreme noise, or silhouette change was evident in inspected views.
- Shrine red columns, green framing and detailed dancheong remain recognizable in the final facade comparison. Sadangmun retains its red/green/taegeuk pigment; main_gate plaques and inscriptions remain visually unchanged. Protected plaque/anonymous-pattern bindings are explicitly retained.
- Rebuilt gates use object-attached projection without new UV layers. Existing source roof openings visible in changgo/toilet1 comparisons remain in the same places before and after.
- HTML and status files identify these as candidates and explicitly say the 360-degree viewer/construction/Flutter stages are pending. New-candidate approval remains false.

## Limits and declined judgments

- Browser interaction/mobile/desktop behavior is being verified by the implementing session. This review verified HTML logic and local link coverage; its ECC endpoint could not attach because the browser profile was already in use, so it did not disturb the active browser.
- Repairing inherited roof gaps was set aside: architecture is frozen and the matched source images already contain them.
- GLB performance, construction/runtime behavior and Flutter/device QA were set aside: none is produced by this candidate-only scope.
- Final aesthetic acceptance of individual buildings is reserved for the user; Sarang's existing approval does not approve these 14 extensions.

No implementation edits, source fixes, new renders, exports, or promotions were performed by this reviewer. Only this report was written.
