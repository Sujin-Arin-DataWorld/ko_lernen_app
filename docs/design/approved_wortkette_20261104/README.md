# Wortkette: approved image → editable Figma → native Flutter

Date: 2026-11-04. Scope: the existing `KkeunmariScreen` word-chain game. This is not a new CEFR-filtered game, and does not replace the learning engine.

## Authority and implementation

The user approved the three images in [the content-length mockup package](../wortkette_content_length_20261104/README.md). A/B/C identify short, medium and long content fixtures; they do not invent CEFR choices or progress in the live game. The full-screen images are comparison references only. They are not embedded behind clickable hotspots.

Editable Figma frames, each 402×874:

- [A / 가방](https://www.figma.com/design/7IHizFZMk5G3ahsuVKiYwb?node-id=358-847)
- [B / 자전거](https://www.figma.com/design/7IHizFZMk5G3ahsuVKiYwb?node-id=358-990)
- [C / 의사결정권](https://www.figma.com/design/7IHizFZMk5G3ahsuVKiYwb?node-id=358-1171)

These frames contain independent artwork, actual Lora/MaruBuriOTF text, and reusable material instances. Shared navigation is reused from the approved Wörter-Quiz. The canonical cloud and five navigation icons retain their original bytes and have no visible text labels.

`FIGMA_GEOMETRY_FINAL.json` is the measured implementation contract. It supersedes provisional slice recommendations in the generation manifests. The C tile refinement accounts for the asset's transparent gutters: 75×92 nodes at a 66px horizontal step produce adjacent visible faces, rather than shrinking the faces to the node bounds. This is not overlapping Korean text.

Flutter uses `ApprovedWordChainFrame` and `ApprovedWordChainView`, with shared `ApprovedMaterial`, `GameArtwork`, `ApprovedArtButton` and `ApprovedGameNavigation`. Only the view owns visual geometry; the existing screen retains learning state, validation, persistence and rewards. Input remains a real Korean IME-backed text field.

## Independent materials

Six independently generated, text-free materials are registered under `assets/illustrations/approved_games/word_chain_*`: walnut stand, ivory syllable face, jade syllable face, wooden input surround, borderless jade texture, and gold speaker. No material is a crop of a complete approved screen.

- `ASSET_MANIFEST.json`: original files, hashes and image bounds.
- `GENERATION_PROMPTS.json` and `FOLLOWUP_GENERATION_PROMPTS.json`: reproducible art direction, including rejected/superseded candidates.
- `RUNTIME_ASSETS.json`: the six exact runtime copies and SHA-256 values.
- `FIGMA_GEOMETRY_FINAL.json`: actual Figma nine-slice geometry and crop matrices; corners keep their shape while interior areas stretch.

## Learning and lifecycle preservation

See `BEHAVIOR_AUDIT.md` for the source-level inventory. Existing contracts are retained: 30-second user turn; 1.8-second opponent response; 1-second dead-end completion delay; dictionary fallback for the full pool only; custom selection limits; accepted-word SRS writes; original completion/reward rules; companion and coach anchors.

Route cover and app background pause the turn/opponent delay and stop only this screen's speech. A generation guard prevents stale speech or asynchronous work from taking control of a later session. Returning does not award XP or replay a completed save. Navigation uses the shared five-tab route behavior.

## Content fit and accessibility

`CONTENT_FIT_AUDIT.json` records current source hashes and exact boundary cases: 2,662 raw entries, 1,843 entries after the pre-existing noun whitelist, one-to-eight-syllable dictionary nouns, and the existing one-to-twenty-Hangul-character input contract. The UI does not change these filters.

Long Korean words wrap into measured syllable rows. Long DE/EN meanings wrap in live text. Missing English meanings remain empty instead of silently falling back to German. Safe-area accommodation spends decorative vertical slack; larger text and the keyboard may use scrolling to preserve readable content and reachable controls. No whole-screen downscale or sentence truncation is used to claim a fit.

The reference Senden target ends at y769 and the navigation begins at y792, leaving 23dp. Native compact layouts retain at least 16dp. Interactive controls retain 48dp minimum targets, with material-image bounds independent of hit bounds.

## Motion direction and official sources

Checked 2026-11-04: [Apple Motion](https://developer.apple.com/design/human-interface-guidelines/motion), [Material motion](https://m3.material.io/styles/motion), and [Material expressive design research](https://design.google/library/expressive-material-design-google-research).

Applied judgment: tactile material response should explain a press or state change without distracting from the Korean word. The shared art button has a short 2dp press-depth response; reduced motion keeps the same interaction without travel. Timer, validation, saves and rewards are not executed by animation-completion callbacks. No endless shaking, fake progress or invented rewards were added to imitate a trend.

## Evidence boundaries

- Original A/B/C image approval: supplied by the user in this task.
- Figma reconstruction: `captures/figma-a.png`, `figma-b.png`, `figma-c.png`; independent review in `FIGMA_VISUAL_REVIEW.md`.
- Flutter render/functional validation: recorded separately in `VALIDATION.md` after the final run.
- Physical-device validation: explicitly deferred by the user. No installation or store release is claimed.

The static review found no obvious clipping or missing visible controls. Generated reference lettering and regenerated material highlights are not pixel-identical; residual typography/material differences are recorded rather than described as 100% fidelity. Original-image approval does not automatically approve those differences.

## Next content

[Silben-Rätsel research](../silben_next_content_20261104/NEXT_CONTENT_BRIEF.md) identifies the existing `syllable_cross` / `/wordle` game and real A/B/C content fixtures. It proposes a crossword-specific arena with the canonical Dokkaebi help flow. This is research for the next mockup task, not a generated image, Figma approval or implemented feature.
