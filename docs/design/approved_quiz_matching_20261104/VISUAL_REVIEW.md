# Final Quiz / Matching Flutter visual review

Reviewed 2026-11-04. All six Flutter presentation fixture PNGs from `C:/dev/hangulsori/_codex_artifacts/spiele-quiz-matching-figma-20261103/flutter-capture-20261104` were opened individually and compared against Quiz A/B/C v3 and Matching A/B/C v5 in the parent folder. Initial reviewed capture manifest timestamp: `2026-11-04T00:49:41.637168Z`, 402×874, DPR1, German, 100% text, normalized zero safe insets.

Final verdict after the00:59:40.611941 UTC re-render: **static fidelity, content containment and displayed-state review pass, with no unresolved P1 defect**. The six body compositions, learning text, four answers or twelve pair tiles, selected/matched states and retained slots are reproduced closely. The three bounded P2 corrections and intermediate slice protrusion are closed below. Thin internal slice seams and small text-raster differences remain. This is not a100% pixel-identity or real-device acceptance claim.

## Findings sent to implementers

| Priority | Finding | Evidence and minimal correction | Status |
|---|---|---|---|
| P2 | Quiz navigation uses the wrong background family | In all three approved Quiz PNGs, the footer has the organic jade texture and thin gold vertical edges. The initial Flutter footer used `jade_geometric_legacy` for every screen, losing both. Parameterize the navigation surface: Quiz uses `jade_organic_final`; Matching keeps the darker geometric result observed in its approved v5 captures. Source asset and isolated image-patch comparison confirm this difference. | Closed in00:59:40 render |
| P2 | Matching selection dot is too small and shifted right | Component274:35 is10×10, right11/top8 (component180×72, x159/y8). Initial shared button was7×7, right10/top10. On the B158px tile at x12/y335, approved dot bounds are `(149,343,10,10)`; initial bounds `(153,345,7,7)`. | Closed in00:59:40 render |
| P2 | Quiz topic and score are top aligned within their Figma text boxes | Figma topic/score have `vertical:CENTER`. Initial Flutter used raw Text within24/22dp slots. A topic was2px high and score2px high. Align.centerLeft now restores the score bounds exactly; topic retains only a1px font-raster residual. | Closed in00:59:40 render |
| P2 | Oversharp material minification | Initial render showed jagged rim highlights, paper/nav texture noise and harsher small icon detail. Root corrected sampling and subsequently clipped destination rectangles to eliminate the exposed bleed. | Closed; minor seams remain below |

Navigation evidence nuance: final geometry JSON reports the organic image hash in shared navigation nodes, while the approved Matching v5 pixels visibly preserve the geometric footer. The approved six PNGs are the current visual comparison target. This review explicitly preserves the observed per-family difference rather than silently expanding the shared-header approval to the footer.

## Checks that already match

- All six headers use the approved composition, ivory small left chevron, exact cloud family, gear, centered36px title and brass seam. Figma title ink and Flutter title ink differ by approximately1px vertically, within the remaining renderer/font-raster difference; no title re-layout is requested.
- Quiz A/B/C headwords preserve distinct sizes80/61/34 and plaque heights148/120/148. C's Korean phrase remains two lines. B's long third option and all four C meanings retain the intended line breaks in these review fixtures. `Erklärbarkeit sicherstellen` is two lines and contained.
- Matching A retains all-neutral six pairs; B only Korean row2 is selected; C only Korean row1/German row6 are matched. Disabled pair slots stay fixed. No erroneous connector, reshuffle, lost tile, or fake progress was observed.
- All twelve Matching tiles have the approved column widths/row starts. The long German third/fourth rows are contained. Matching C final row ends before the status and footer.
- Ivory paper and jade selected materials, corner waves, brass rims, five original navigation icons and selected Spiele control remain independent art/text. No full-screen raster substitute is apparent in these fixture screenshots.

## Typography limits

White Latin text is perceptually heavier in the initial Flutter raster, although the inspected source uses the specified Lora weight600 and matching glyph widths. Example Matching B instruction: same bright-ink bbox `(46,179)..(356,197)`, but high-threshold bright-pixel counts are991 Figma versus1255 Flutter. This is not proof that the font weight is incorrectly selected. Do not compensate by lowering weights below the approved spec before checking renderer/sampling and font realization. Black option labels and Korean word shapes remain close, with no clipping. Text raster differences remain a limitation to report honestly.

## Initial reviewed SHA-256

| Capture | SHA-256 |
|---|---|
| quiz-a-flutter.png |1345f98eaddc368d1896fd7177f8a1fde5facb0deebf537dce4189af4661e5f6|
| quiz-b-flutter.png |62f108dbf6cba0ed9dd4ab171a5cdff5d94d36e3b1ae1425101b90b41728f142|
| quiz-c-flutter.png |f2e4b7a44cafd1fa624d003c7f9c66141ed1cead60b89144fb3a4b72be128913|
| matching-a-flutter.png |3a3efe4b4773b8fc7ce7f171df1c9d6bb7f112bd2935af929feab03e0d6bd296|
| matching-b-flutter.png |8f7eb25850610240f19f053d1f3c9b5930a2a887226c091535c3559e6894228a|
| matching-c-flutter.png |a6854052b45056016cb39fe30c4aeaf82bfc1a4640f67b0936dc453bc60d1b1c|

Images establish presentation-fixture behavior only. Gallery-specific approved line breaks do not prove generic runtime word wrapping or all-corpus fit. Real grading, persistence recovery, TTS, tab return, device SafeArea, screen-reader behavior and motion require their separately recorded tests/device evidence.

## Intermediate re-render — 00:54:25 UTC

Quiz A, Matching B and C replacement captures were opened. Medium sampling improves small-asset smoothness but exposes a **P1 slice bleed**: the jade control's central vertical rectangle extends beyond the brass bottom edge. Visible examples: Quiz A speed center around x284..326 extends to approximatelyy435; selected navigation's center strip extends below its rim to approximatelyy868. Matching speed shows the same defect. This is a new open blocker in the intermediate render, not present at this severity in the initial set. Root was notified. Inspect and constrain each slice painter to its own destination bounds; `canvas.clipRect(Offset.zero & size)` is a plausible bounded correction to test, not an asserted verified cause.

## Final closure — 00:59:40.611941 UTC

All six replacement PNGs were opened individually. **Static fidelity, content containment and displayed-state review pass; no unresolved P1 defect was observed.** The intermediate slice protrusions are gone from speed/audio/navigation controls. Quiz's organic footer and gold side borders are restored, Matching's geometric footer is retained, the selected dot matches the approved size/position, and Quiz score bright-ink bounds now equal Figma `(33,136)..(97,152)`.

Remaining bounded renderer differences: faint internal nine-slice grid lines on jade controls and occasional thin edge discontinuities on ivory tiles; white Lora looks slightly heavier than Figma; some glyph positioning differs by1px (Quiz A topic now y114..127 versus Figma113..126). These do not obscure text or change state/flow, but prevent a100% pixel-parity claim. No further broad re-layout is requested. Keep these differences explicit when handing off the result.

| Final capture | SHA-256 |
|---|---|
| quiz-a-flutter.png |c8f0b96ac4df08c8e4347603c5276fcd6697fc5871be374cc411db4273352f41|
| quiz-b-flutter.png |57d687fd8b34120bed6a3be7401a8a3cfc0d9f524f0b26aeb47e132ecc52c636|
| quiz-c-flutter.png |cd8880f7e8307fbba6e12bff455772b3c69bfc8d71956d42229675f8d5506a19|
| matching-a-flutter.png |f5c81ac0f288edfe7f078582279fb40ad83ee6e5782fcb28d0cd1aa97f2f0d68|
| matching-b-flutter.png |79d7c00189dc02fde444c9d9a106fd61663ff4d3eb38db98f0181abb3d3764a8|
| matching-c-flutter.png |5228b7db35a690c7adf5b409e7fb4328e84ff1eb322dba3fcb8b5bf1ab29aeb1|

## Superseding final render closure — 2026-11-04

The final capture manifest timestamp is 2026-11-04T02:03:34.146282Z. All six reference captures were regenerated after the destination-image antialiasing fix and inspected by the rendering reviewer. Six additional 1080×2400 / DPR2.75 SafeArea captures were inspected independently; their current hashes and layout measurements are in SAFE_AREA_CAPTURE_MANIFEST.json and SAFE_AREA_REVIEW.md. Root also opened the final Quiz C reference and Matching B SafeArea renders. The previously reported internal grid seams are now resolved. Approved geometry and Quiz text-ink positions did not drift; font-renderer weight/edge differences remain explicit. This supersedes the earlier seam limitation and old final hashes above.

Two production material-rendering regression tests passed at DPR1 and2.75. A separate diagnostic using the same source crops on one canvas demonstrated that image-destination antialiasing, not source artwork or component layout, caused the gaps. Source alpha is preserved; no gutter, source-image edit or layout compensation was introduced.
