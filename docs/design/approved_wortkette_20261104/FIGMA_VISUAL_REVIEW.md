# Wortkette final Figma visual review

Initial A/B/C review: 2026-11-04T06:32:37.018164+00:00
Updated C re-review: 2026-11-04T06:43:43.810495+00:00; A/B hashes reconfirmed unchanged.
Reviewer: independent design QA subagent; read-only image comparison.
Scope: only the latest repository `figma-a.png`, `figma-b.png`, and `figma-c.png` listed below. Earlier first/refined artifact exports were excluded.
Repository HEAD at review: `b11c7ef838e6f18be72d7bed5404589c158d2b8f`; the parent agent has active uncommitted Wortkette implementation work. This review did not modify application code or Figma.

## Verdict

**No clear P0/P1 defect was observed in these three static captures.** Learning text is readable and complete; the current syllable tiles, highlighted final syllable, listening/speed controls, input, Senden CTA, back control, and all five navigation icons remain visible. No text clipping or CTA/navigation overlap is visible.

This is a bounded static visual pass, not a claim of 100% fidelity, functional correctness, accessibility conformance, or native/device approval. The residual differences below remain visible.

## Evidence and normalization

Approved image dimensions are A 851×1848 and B/C 851×1847. Figma exports are 402×874. Composition was compared at equivalent phone proportions; this was not an automated pixel-identity test. No raster edits were created for this review.

### Approved

- A: `C:/dev/hangulsori/ko_lernen_app_worktrees/quiz-matching-figma-20261104/docs/design/wortkette_content_length_20261104/images/wortkette-a.png`
  - SHA-256: `cb6b67787c317d4442f2b908a2133d56f18177bdd86299ed0ab363a5c938b2fc`
  - File modified UTC: `2026-11-04T04:52:08.281492+00:00`
- B: `C:/dev/hangulsori/ko_lernen_app_worktrees/quiz-matching-figma-20261104/docs/design/wortkette_content_length_20261104/images/wortkette-b.png`
  - SHA-256: `884b363ff5d692685d2e9ec0d3e5c95c6556a55245277fb31b8c1448c396393f`
  - File modified UTC: `2026-11-04T04:52:56.403688+00:00`
- C: `C:/dev/hangulsori/ko_lernen_app_worktrees/quiz-matching-figma-20261104/docs/design/wortkette_content_length_20261104/images/wortkette-c.png`
  - SHA-256: `81760b8e467e326cdb25ed2381e7337bc07f9418852905736a5971d13e66d884`
  - File modified UTC: `2026-11-04T04:53:26.897784+00:00`

### Latest Figma

- A: `C:/dev/hangulsori/ko_lernen_app_worktrees/quiz-matching-figma-20261104/docs/design/approved_wortkette_20261104/captures/figma-a.png`
  - SHA-256: `30fb9b066fa9c3ee32c999b5e41366839bdd95bfeebe22b5c1499a795776f3c2`
  - File modified UTC: `2026-11-04T06:25:51.093510+00:00`
- B: `C:/dev/hangulsori/ko_lernen_app_worktrees/quiz-matching-figma-20261104/docs/design/approved_wortkette_20261104/captures/figma-b.png`
  - SHA-256: `7c3db2cccdcdabd7f72ab89b2c4e0107b795061b063e776274d6515c6614d579`
  - File modified UTC: `2026-11-04T06:25:50.212149+00:00`
- C: `C:/dev/hangulsori/ko_lernen_app_worktrees/quiz-matching-figma-20261104/docs/design/approved_wortkette_20261104/captures/figma-c.png`
  - SHA-256: `c8216d81c4b3ed0f9ef9dd9c4b425f50271ab477370fa214a7f58a796b55f07d`
  - File modified UTC: `2026-11-04T06:41:30.649706+00:00`

## Visible content and controls

| Variant | Exact content checked | Visible state |
| --- | --- | --- |
| A | 가방; 가 / 방; Tasche; Beginne mit »방«; Wort auf Koreanisch … | 30s; Kette: 1; only 방 is jade; input is empty with placeholder. |
| B | 커피 – 피자 – 자전거; 자 / 전 / 거; Fahrrad; Beginne mit »거«; 거울 | 24s; Kette: 3; only 거 is jade; input contains 거울. |
| C | 운동 – 동의 – 의사결정권; 의 / 사 / 결 / 정 / 권; Entscheidungsrecht; Beginne mit »권«; 권리 | 18s; Kette: 3; only 권 is jade; all five syllables and the long German word fit. |

All three retain Wortkette, Letzte Silbe → nächstes Wort, Du bist dran, Anhören, 1×, Senden with its send icon, a left-pointing back control, and five image-only bottom tabs in calendar / open book / controller / Hanok / group order, with Games selected. These timers, chain counts and entered words are fixture states, not claims about a real learner session.

## Closure of previously flagged areas

- Updated C: the five small, widely separated syllable tiles have been enlarged into a fuller row. The prior C occupancy finding is closed after reviewing the replaced repository capture against approved C. No new clipping or control overlap was introduced.
- History chip endcaps no longer collide with their text. B 자전거 and C 의사결정권 are fully visible.
- The back control points left. The speaker is visibly gold and readable against jade.
- Header/footer backgrounds have no stray gold vertical side edges or streaks.
- Header brand and small cloud are separated. The A placeholder is warm brown and visibly heavier than the earlier thin black version.
- The Senden face, lower edge and shadow end above the navigation dock with clear paper space. No visible overlap occurs in any of the three 402×874 exports. Screenshot pixels do not establish the full interactive hit rectangle.

## Residual fidelity differences (P2 visual polish, not observed functional blockers)

1. **Material depth is reduced.** The jade listening, speed and Senden faces are flatter and slightly shallower than the approved images. Their highlights, bottom thickness and contact shadows are less substantial. The input and wooden tray also have a cleaner, more uniform finish. Preserve the approved raised-face/contact-shadow character when refining these materials; do not change the game hierarchy.
2. **Tile and glyph styling still differs.** The updated C tiles now fill the tray with a close, continuous row comparable to the approved composition; the previous small-tile/wide-gap finding is closed. Their faces sit a little higher and are slightly taller in appearance than the reference, and the Korean glyph silhouettes remain different. All five glyphs, their individual tile faces and the final jade 권 remain clear, with no new clipping. B tiles remain slightly more compact than its approved image.
3. **B/C history is compressed horizontally.** The current chip group ends earlier than the corresponding approved group; C in particular has less generous interior breathing room. No glyph is clipped. Retain complete words and avoid reverting to the earlier cap collision if widths are refined.
4. **Typography is close in hierarchy but not in shape or weight.** Du bist dran is wider/heavier, while the Korean tray lettering has different silhouettes and stroke proportions. The title, instruction, input and translation preserve their roles but are not pixel-identical to the generated reference lettering. The German long-word fit in C passes this static case; it does not prove the full corpus fits.
5. **Spacing is slightly different.** The tray-to-translation area has more apparent breathing room, and the vertical balance of the control stack differs modestly from the approved images. The CTA-to-dock separation remains visibly clear.

The exact shared cloud and navigation PNG requirement takes precedence over copying image-generated glyph silhouettes. This review confirms visible icon presence/order/selection only; it does not authenticate source bytes from a screenshot. Any canonical-byte claim must cite the asset provenance/hash checks separately.

## Proof boundary and remaining implementation verification

- These captures have the keyboard dismissed, one 402×874 viewport and normal text size. They do not prove keyboard avoidance, small-screen behavior, safe-area handling, large-text adaptation, or the 48dp hit regions.
- Listening, playback speed, submission, back/navigation callbacks, timer lifecycle, validation/errors, success/timeout, focus/semantics and reduced-motion behavior cannot be verified from still images.
- Native implementation/render comparison and interaction tests remain separate evidence. No physical-device QA was performed or requested in this review.
- User approval of the original A/B/C mockups does not automatically approve every residual Figma/material/font difference recorded here.

## Flutter static render comparison

Reviewed: 2026-11-04T07:09:56.596440+00:00

Scope: the final `flutter-a.png`, `flutter-b.png`, and `flutter-c.png` below were visually compared directly with the corresponding latest Figma exports in the same `captures` folder. All six images are 402×874. Figma hashes were reconfirmed unchanged from the preceding review, including the enlarged C tile revision.

**Static verdict: no clear P0/P1 clipping, missing learning content, CTA/navigation overlap, or major material mismatch was observed in these Flutter captures.** This does not mean pixel identity or complete runtime approval.

### Flutter evidence

- A: `C:/dev/hangulsori/ko_lernen_app_worktrees/quiz-matching-figma-20261104/docs/design/approved_wortkette_20261104/captures/flutter-a.png`
  - SHA-256: `2d432ce91283588a213d09afb866daa29d560d084e7e13457fcadf97abac048f`
  - File modified UTC: `2026-11-04T07:15:29.182295+00:00`
- B: `C:/dev/hangulsori/ko_lernen_app_worktrees/quiz-matching-figma-20261104/docs/design/approved_wortkette_20261104/captures/flutter-b.png`
  - SHA-256: `8d1bc7e15c88036728ad23a630b7edf5a95c0d21747ebb05b8562ff55785bbb0`
  - File modified UTC: `2026-11-04T07:06:10.518085+00:00`
- C: `C:/dev/hangulsori/ko_lernen_app_worktrees/quiz-matching-figma-20261104/docs/design/approved_wortkette_20261104/captures/flutter-c.png`
  - SHA-256: `2203c9e0df9c7d2c1ca4e865f1e9f0de7c00aa6639d1d3ec5585fa630ae97ebf`
  - File modified UTC: `2026-11-04T07:06:10.700378+00:00`

### Visible findings

- All A/B/C words, history chips, German translations, timers/counts, start-syllable instructions and fixture inputs match the corresponding Figma content. A retains its empty-input placeholder; B retains 거울; C retains 권리. The final syllable alone is jade in each case.
- C carries the enlarged five-tile row through to Flutter. The individual syllables remain readable; no tile text is cropped or hidden at the adjacent tile edges.
- The back control, gold speaker, Anhören, 1×, Senden/send icon, cloud/brand and all five image-only navigation icons are present. Games remains selected. Their static presence does not verify their callbacks.
- The paper/wood/jade/gold composition, major control footprints and cleared space above the navigation dock are retained. No obvious extra control shadow causes a collision. The implementer reports shadow suppression on the three Wortkette jade controls; this review assessed the resulting pixels, not that code path.

### Minor renderer differences

Placeholder follow-up verified 2026-11-04T07:17:13.677000+00:00: the previous +5px vertical offset is closed. Both Figma and the updated Flutter A have placeholder ink at y=657–674 inclusive; the 1px left-edge raster difference remains. A was visually rechecked and its hash updated; B/C hashes remain unchanged.

1. Wood grain, gold rims and small art edges appear somewhat softer in Flutter than in Figma. The materials remain recognizable and no broken nine-slice seam or large substitute material is visible in these captures.
2. Text rasterization and placement differ slightly. A targeted ink-pixel check found the subtitle 2px lower in Flutter. Brand ink extends approximately 2px farther left. The placeholder vertical offset has been corrected and its ink bounds now share Figma’s top and bottom. These are ink bounding boxes at this raster size, not widget coordinates or tappable bounds:

| A text probe | Figma ink bounds [left, top, right, bottom) | Flutter ink bounds [left, top, right, bottom) |
| --- | --- | --- |
| HANGUL SORI | [145, 16, 265, 27) | [143, 16, 265, 27) |
| Letzte Silbe → nächstes Wort | [41, 136, 362, 153) | [41, 138, 362, 155) |
| Wort auf Koreanisch … | [35, 657, 291, 675) | [36, 657, 291, 675) |

The probes used restricted text regions with simple RGB thresholds (brand: R>170, G>150, B>120; subtitle: R<90, G<90, B<80; placeholder: R<155, G<125, B<95). Antialiasing can affect the outermost ink pixel. The placeholder remains fully visible with interior clearance; these differences are visual polish rather than an observed flow blocker.

### Limits

- The earlier approved-mockup-versus-Figma material/font residuals remain documented above; Flutter matching the Figma composition does not erase those differences.
- This pass is limited to three normal-size, keyboard-dismissed still renders. It does not establish the complete corpus, large-text/small-screen behavior, interactive hit regions, focus/semantics, keyboard avoidance, lifecycle, motion or physical-device behavior.
- The parent separately reports passing view/capture and functional test suites. Those tests were not rerun by this visual reviewer and their results are separate evidence from the screenshot verdict. No physical-device QA was performed.
