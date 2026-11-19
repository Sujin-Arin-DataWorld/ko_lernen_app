# Wortkette A/B/C image-candidate review

Reviewed 2026-11-04. Result: **three coherent image proposals suitable for user design review, with no observed critical content error.** This is not Figma approval, native implementation, whole-corpus fit or device evidence. No physical-device QA was performed or requested.

**Latest presentation files are the `wortkette-*-five-tabs-candidate.png` revision.** The earlier blank-dock files below are retained as generation history and are superseded for user review. Final five-tab review appears at the end of this document; `FIVE_TAB_MANIFEST.json` identifies the current originals, copies and hashes.

## Initial blank-dock candidate files (retained history)

| File | Exact raster size | Current word | Input | Empty dock height, normalized to 874 |
|---|---:|---|---|---:|
| `wortkette-a-candidate.png` | 851×1848 | 가방 / Tasche | empty | about 81.4 |
| `wortkette-b-candidate.png` | 851×1847 | 자전거 / Fahrrad | 거울 | about 82.3 |
| `wortkette-c-candidate.png` | 851×1847 | 의사결정권 / Entscheidungsrecht | 권리 | about 84.7 |

Original generated files and byte-identical copies are recorded with SHA-256 in `MANIFEST.json`. All earlier outputs remain preserved in the generation directory. Seven image-generation calls total: A generation, A cleanup, B/C variants, and three bottom-dock geometry revisions. There were no programmatic image edits.

## Verified content and visual behavior

- A: 가/방 are correctly ordered, only 방 is emerald; Tasche and Beginne mit »방« are exact. Initial history contains 가방 only; Kette: 1 is separate and no longer connected as if it were another word. Empty input has Wort auf Koreanisch …; 30s is the source-backed initial-turn fixture.
- B: history 커피 → 피자 → 자전거 is valid; the main rail reads 자/전/거, only 거 is emerald. Fahrrad, Beginne mit »거«, draft 거울, Kette: 3 and 24s are exact. The unsubmitted draft is not counted in the chain.
- C: history 운동 → 동의 → 의사결정권 is valid; the main rail contains all five syllables 의/사/결/정/권 once and in order, only 권 is emerald. The full German word Entscheidungsrecht is readable on one line. Instruction Beginne mit »권«, draft 권리, Kette: 3 and 18s are exact.
- All three retain back, readable current-turn status, timer, current-word meaning, Anhören, 1×, one Korean typing field and one Senden action. They contain no invented XP, streak, result, correctness judgment or answer choices. Timers/counts are controlled review snapshots, not actual learner progress.
- Fixed history blocks and syllable rail express a word chain; the input and submit are grouped as one action area. They do not reproduce the Quiz answer stack, Matching columns or Karten flip-card interaction.
- In this initial revision, shared emerald/hanji/walnut/gold material identity was coherent. No cloud, gear, coin, character, nav icon or header logo ornament appeared. The bottom region was intentionally blank. This presentation was superseded by the full five-tab revision below.
- Final dock revisions recovered approximately the planned 82dp region. Visual shadow-to-dock space is about 18–24 logical units across the candidates. Exact 402×874 geometry is a future Figma task; the source images differ by one raster row and their footer placement varies by a few logical units.
- The fixture verifier passed unique chain words, valid adjacent last/first syllables, Hangul-only source records, exact current-word gloss, correct chain count and valid unsubmitted B/C drafts. This is a narrow source-data check, not a runtime test.

## Remaining design gates

1. In exact Figma/runtime composition, use original approved Wörter-Quiz five image icons in the canonical order, with Spiele selected. Normalize dock geometry to 82dp. The final proposal shows five visual mockup glyphs; do not treat them or the generated emerald shelf as canonical asset bytes.
2. Preserve at least 48dp actual touch regions and at least 16dp from the lowest CTA/shadow to the dock after exact composition. Pixels suggest appropriate control scale but cannot prove hit regions, semantics or contrast ratios.
3. The keyboard is dismissed in these snapshots. A later keyboard-open design must preserve current word/required syllable, input and submit, with proper keyboard insets and viewport adaptation. Do not use these images as proof of simultaneous keyboard/full-screen fit.
4. Later state design must cover dictionary checking/unavailable, invalid or duplicate input, opponent turn with actual selected companion media, timeout/dead end and persisted result/recovery. Read-only blocks must not acquire fake drag/select behavior.
5. Header/material textures and lower control geometry vary slightly between generated files; the accepted design must use shared native components and exact Figma constraints. No full-corpus or 20-character input fit is claimed from three examples.

Current review stops at image proposals. Root may copy/commit these artifacts for the requested review stage; that does not approve the design or implement the game.

## Final five-tab revision, 2026-11-04

Current files:

- `wortkette-a-five-tabs-candidate.png` — 851×1848; SHA-256 `cb6b67787c317d4442f2b908a2133d56f18177bdd86299ed0ab363a5c938b2fc`.
- `wortkette-b-five-tabs-candidate.png` — 851×1847; SHA-256 `884b363ff5d692685d2e9ec0d3e5c95c6556a55245277fb31b8c1448c396393f`.
- `wortkette-c-five-tabs-candidate.png` — 851×1847; SHA-256 `81760b8e467e326cdb25ed2381e7337bc07f9418852905736a5971d13e66d884`.

All three show exactly five image-only tabs, in the approved order: calendar, open book, game controller, hanok, group. Only the third Games tab has the emerald/gold selected face. No labels, extra badges, sixth icon, generated cloud or gear were added. The entire icons fit in the existing dock and retain visible clearance from Senden. All learning strings, Korean syllable sequences, meanings, drafts, chain counts and timers remain visually correct. No observed critical content defect was introduced.

The edits were requested only for the bottom dock. Imagegen can rerender textures elsewhere; this is a visual content/layout preservation result, **not pixel-identity proof of the body**. Subtle per-image icon scale, material and selected-border differences remain. Final Figma/native work must use shared exact components and original assets rather than extracting these generated glyphs.

`FIVE_TAB_EDIT_PROMPTS_v2.json` records the successful requests. All five original navigation PNGs were inspected; each request used the target screen, approved Wörter-Quiz screenshot containing all five tabs, and three detailed original icon references within the tool's five-reference limit. One initial seven-reference request was rejected before generation; three successful final edit calls followed. `package_five_tab_revision.py` copies bytes and verifies hashes only. No Python or other programmatic image editing was performed.

Runtime distinction was checked live: `CustomPackPlayScreen` at `/custom_pack/play` uses shared `ApprovedGameNavigation`; the previous “Meine Wörter Karten” label must not be confused with `/my_words` search/shelf screen. Canonical source/runtime PNG SHA equality and retained book SHA were independently checked against `docs/design/karten_navigation_20261104/PROVENANCE.json`. That runtime's verified original bytes remain separate from these visual mockup glyphs. No additional runtime or device claim follows from the new images.
