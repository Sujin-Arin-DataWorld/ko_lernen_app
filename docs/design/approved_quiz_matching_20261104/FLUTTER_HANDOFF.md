# Quiz · Matching — Figma reconstruction handoff

2026-11-03 reconstruction; user approval recorded on 2026-11-04 in `APPROVAL_20261104.json`. The six Figma designs, including the shared Wörter-Quiz header, are approved as the implementation visual baseline. Approval does not establish pixel identity or Flutter/device completion. The user's shared-header change supersedes the original Matching header.

## Open the editable design

File: `7IHizFZMk5G3ahsuVKiYwb`. Page: `271:2`, **05 · Quiz & Matching · approved reconstruction · 2026-11-03**.

| Source family | Figma | Final actual Figma render | Representative state |
|---|---|---|---|
| Quiz A | [278:14](https://www.figma.com/design/7IHizFZMk5G3ahsuVKiYwb/?node-id=278-14) | quiz-a-figma-v3.png | Unanswered, 커피 |
| Quiz B | [278:137](https://www.figma.com/design/7IHizFZMk5G3ahsuVKiYwb/?node-id=278-137) | quiz-b-figma-v3.png | Unanswered, 원상복구 |
| Quiz C | [278:260](https://www.figma.com/design/7IHizFZMk5G3ahsuVKiYwb/?node-id=278-260) | quiz-c-figma-v3.png | Unanswered, long phrase |
| Matching A | [278:383](https://www.figma.com/design/7IHizFZMk5G3ahsuVKiYwb/?node-id=278-383) | matching-a-figma-v5.png | All neutral, 0 of 6 |
| Matching B | [278:580](https://www.figma.com/design/7IHizFZMk5G3ahsuVKiYwb/?node-id=278-580) | matching-b-figma-v5.png | Korean row 2 selected, 0 of 6 |
| Matching C | [278:779](https://www.figma.com/design/7IHizFZMk5G3ahsuVKiYwb/?node-id=278-779) | matching-c-figma-v5.png | Left row 1 / right row 6 matched, 1 of 6 |

All frame coordinates use **402×874, German UI, 100% type**. A/B/C are content-length review families for custom packs, **not new CEFR selector controls**. The six-item example pack is a review fixture; real denominators come from the active pack.

## What is editable and reusable

- Lora and MaruBuriOTF text is real Figma text, not baked into screen art.
- Material art is independent and textless: hanji, jade plaque, ivory choices, selected jade, cloth, counters and control faces. No approved full-screen screenshot was installed as a screen background.
- Cards and counters are reusable components with actual Label properties. Their corners/edges are separate slices; text remains independent.
- The exact supplied cloud is used next to HANGUL SORI in all six screens. SHA-256 `c728baced6dd3bff2729bf2a28dbf62e3954ad91a04594e04dc923fbd530f6a5`.
- Five canonical image navigation icons remain. The Lernen icon is the open book; no tab-label text was added.

| Figma component | Main node | Flutter responsibility |
|---|---|---|
| Quiz / Choice | 274:2 | Four immediate-answer meaning options; engine controls selection/answer state |
| Pair / Neutral | 274:13 | One stable Korean or meaning slot |
| Pair / Selected | 274:24 | Selected Korean, ivory dot; not success |
| Pair / Matched | 274:36 | Matched, disabled, check and muted material, original slot retained |
| Control / Jade | 274:49 | Small speed/control face with separate >=48dp hit target |
| Control / Audio | 278:2 | TTS action; existing speaker silhouette as ivory alpha mask |
| Counter / Folio | 274:60 | Passive Quiz numerator / real pack denominator |
| Counter / Matching | 286:723 | Passive confirmed-pair counter |
| Existing jade control material | 83:66 | Shared approved bevel art; nine slices |
| Games / Shared Quiz Header | 300:766 | All six screens; editable Title property only, 402×104 |

**Latest user-directed override:** Matching A/B/C now share the exact Wörter-Quiz header composition: jade art crop, cloud/wordmark, standalone ivory back chevron, gear, Lora Bold36 title at x32/y42, brass divider at y94. Their title is Paare finden. This intentionally replaces the prior thin Matching bar and its different title sizes. Quiz uses the same component; Quiz A's before/after raster comparison was pixel-identical. Do not restore the old Matching header from the original raster during implementation.

Matching C metadata was repositioned to keep long content in one view: topic y104/h24, counter and speed y132/h31, instruction y169/h27, column labels y201/h28, every pair tile +6dp from the prior snapshot. Last row bottom736; five-tab navigation remains y792. A/B learning content coordinates are unchanged. Exact updated values are in the final geometry JSON. See HEADER_REVIEW.md for this focused validation.

Exact dimensions, per-screen font overrides, crop transforms, text and nodes are in `FIGMA_GEOMETRY_FINAL.json` and `FIGMA_COMPONENTS_FINAL.json`. They take precedence over illustrative implementation names above. Asset hashes and source paths are in `DELIVERY_MANIFEST.json`.

## Reproduce material, not a generic card

1. Keep the actual PNGs and alpha. Do not replace paper, cloth or brass with flat `Container` fills.
2. Card source regions and nine crop transforms are recorded in the component JSON. For a normalized crop matrix `[sx,0,tx;0,sy,ty]`, source pixels are `Rect.fromLTWH(tx*imageWidth, ty*imageHeight, sx*imageWidth, sy*imageHeight)`.
3. Quiz choice fixed visual caps are 28×22dp; matching caps 30×24dp. Stretch the middle/edge regions, preserving corners and decoration. Use a nine-region painter or equivalent; one `BoxFit.fill` over the entire PNG is incorrect.
4. Control face artwork is offset (-2,-1) and sized (control width+4, height+8) inside its component. This compensates for transparent art margins; do not squeeze the full padded PNG into the target button rectangle.
5. The exact cloud's useful visible alpha bounds are x129..1182/y348..885 in a 1254×1254 PNG. Preserve its aspect ratio and size by the visible cloud, not the square padded file.
6. Speaker coloration is an ivory gradient through the existing speaker alpha mask; the dark-green source bitmap alone is not the final look.
7. Use Lora for German and MaruBuriOTF for Korean. Never substitute a condensed font or outline the learning text to conceal wrapping differences.
8. Keep node order, artwork front/back relationships, shadows and label alignment. Artwork can extend beyond a visible face; hit testing must remain independent and non-overlapping.

The Figma design-to-code connector was called for Quiz A and Matching C with Flutter/Dart context. Its response is React/Tailwind reference output; it is **not** Flutter application code. Translate its geometry/assets into the existing Dart widget system, not a WebView or pasted React screen.

## Preserve the actual game contracts

Read-only runtime baseline: `C:/dev/hangulsori/ko_lernen_app_worktrees/spiele-figma-first-20261018`, branch `session/spiele-figma-first-20261018`, HEAD `091b5857d3613832ec93a2a07d097424efca8867`. Recheck before coding; this checkout has unrelated WIP.

`lib/screens/custom_pack_quiz_screen.dart`:

- Korean headword -> four meanings; preserve real IDs and distractor rules.
- Tap grades/saves immediately. No new submit CTA or same-item retry.
- Wrong answer shows selected wrong and actual correct answer under existing rules.
- Ordinary transition uses the existing 900ms interval; reduced motion exposes Weiter.
- Preserve TTS, speed, duplicate-tap guard, failure state and existing SRS/save ownership.

`lib/screens/custom_pack_matching_screen.dart`:

- Up to six pairs, at least two distinct eligible meanings. Shuffle columns independently.
- Select Korean first, then meaning; selecting Korean follows existing TTS behavior.
- Correct: both tiles stay at the same coordinates and become disabled. Never collapse rows or draw revealing pair connections.
- Wrong: keep the Korean selection; existing right-side feedback lasts 450ms, then retry. Do not overwrite the first negative SRS evidence.
- Storage failure is not an incorrect answer. No countdown or submit button is added.

Do not change route names, pack data, scoring, rewards, persistence, TTS ownership or tab-return contracts during the visual replacement.

## Motion and additional states — implementation requirements, not completed evidence

The six delivered frames represent the three Quiz unanswered examples and Matching neutral/selected/matched examples. They are **not a complete interactive prototype or a full error-state design set**.

- Press: visual face descends about 2dp; shadow shortens, approximately 100–140ms.
- Quiz selection: local edge/face emphasis, about 160ms. Correct answer may receive one brief brass highlight; preserve the sentence baseline and existing 900ms progression. Wrong feedback is localized, with explicit icon/text; no punishment vibration or page shake.
- Matching selection: stable jade face and dot. Correct: paired checks/material settling, about 180–220ms, with no layout shift. Wrong: quiet local feedback, maintain the selected Korean and original slots.
- Reduced motion: immediate state changes with the same text/icon information. No timing callback may grade, save, grant credit or trigger reward ownership.
- Background/tab exit: stop sound and animation according to the existing lifecycle, then restore state without regrading/rewarding.
- Before runtime completion, cover saving, failure/retry, TTS loading/failure, speed menu, insufficient pack, completed round, return navigation and reduced-motion Weiter. These are pending, not implied by the static frames.

## Responsive and accessibility boundaries

- Preserve the shown 402×874 composition at normal type. All representative text, four options/six pairs and five tabs fit in these static frames.
- These are normalized reference-comparison frames, not proof of device SafeArea, keyboard, native text shaping or screen-reader behavior.
- For 320px/200% type, reflow and content scrolling may be necessary; do not shrink the entire UI, clip text or hide choices to force one screen.
- Actual text measurement must determine line breaks and height; the explicit line breaks in these six fixtures are comparison evidence, not a production per-word lookup table.
- Main controls/pair targets >=48dp. Small speed/back/gear artwork needs independent 48dp semantic targets without overlap. Passive progress counters are not buttons.
- Expose full text, selected/matched status and disabled state to accessibility. Announce result without reading decor; cloud/material/ornaments are decorative. Supply labels for the five image tabs.

## Evidence and remaining parity limits

`REFERENCE_REVIEW.md` contains approved source hashes and landmark estimates. `DESIGN_COMPARISON_V3.md` contains independent final review and the Matching A v4 closure. Six final captures were exported from the actual Figma nodes, not synthesized screen composites.

Static text/geometry/state review: pass, no observed remaining P1 defect. Matching A title ink was corrected to (65,74)..(337,107), near source (64.2,73.3)..(339.2,108.3). Quiz C Korean ink was corrected to approximately (100,236)..(304,310), near source (102,237)..(304,311).

Remaining differences from the earlier image mockups are explicit: independently generated textures, highlight/shadow shapes and real-font glyph outlines differ from generated source pixels. The user approved the current Figma designs on 2026-11-04. The exact user cloud and canonical navigation art are intended asset changes. No numeric whole-screen similarity score or 1dp-all-edges guarantee was established. **Do not label this delivery “100% pixel-identical,” native-complete or deployed.**

Official design references checked on 2026-11-03 informed local, state-driven feedback and content priority; they did not authorize replacing the approved Hangul Sori materials:

- https://m3.material.io/
- https://io.google/2026/explore/technical-session-30
- https://design.google/library/expressive-material-design-google-research

Relevant skills applied: Figma use/design generation/library for editable native nodes and reusable components; Figma design-to-code for target-stack context; imagegen for independent textless material assets; design handoff for explicit states, geometry, assets and validation boundaries. Existing components were reused before generating missing material.

## Next implementation gate

Use the final Figma nodes and exact material manifest in the existing Flutter screens, then compare same content/language/viewport/type at normal scale. Validate real save, TTS, wrong/correct, reduced motion, tab return and device SafeArea separately. Commit only the explicitly scoped implementation and evidence; this artifact-only delivery has not staged, committed or changed the Flutter checkout.
