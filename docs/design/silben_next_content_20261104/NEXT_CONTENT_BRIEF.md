# Next Spiele review: Silben-Rätsel

Research date: 2026-11-04. Recommended next game: **Silben-Rätsel**, activity ID `syllable_cross`, production route `/wordle`, screen `SilbenKreuzScreen`.

This is a research recommendation for a **new A/B/C content-and-state review of an existing approved visual direction**. Silben already has a finished reference image and a working game. It is not a newly discovered unimplemented game, and the proposed A/B/C set is not yet approved. No images were generated, no app/Figma files changed, and no device QA was performed for this task.

Current checkout: `C:/dev/hangulsori/ko_lernen_app_worktrees/quiz-matching-figma-20261104`.
Observed starting HEAD: `b11c7ef838e6f18be72d7bed5404589c158d2b8f`; branch `session/quiz-matching-figma-20261104`; clean at the start. The parent is separately implementing the newly approved Wortkette images in this checkout. Do not overwrite that work.

## Why this game next

Silben's defining interaction is **select a crossword cell or clue → tap one syllable from the pool → a correct cell locks immediately → its intersecting word benefits from the same cell**. Requested help progresses from a sentence/path to real crossing cells to one revealed syllable; the learner still places the tile. This supports a distinct board, actor relationship and feedback language after Quiz, Matching, Karten and Wortkette.

Comparison based on current catalogue and existing plans:

| Candidate | What already exists | Decision |
|---|---|---|
| **Silben-Rätsel** | Existing finished C-style image; current crossword, duplicate tile ownership, staged Dokkaebi help and persisted completion | **Next:** fill the gap in compact/long-clue/wide-grid A/B/C evidence, retaining the approved actor/material direction |
| Blitz-Paare | Existing two-column mockups, timed pair replacement, selected/correct/wrong/timeout states and native handoff | Later: useful timer/state expansion, but its pair selection body overlaps the just-completed Matching family |
| Tageschallenge | Existing generated start/after-action previews and native handoff; actual challenge steps use Cloze | Later: preserve daily/first-attempt result ownership; a new layout would overlap existing Lückentext work |
| Satz-Arcade | Existing Satzbauen Figma A/B/C work maps to this actual `/satz_arcade` host | Do not misclassify it as a separate unmocked game because the catalogue label says Arcade |
| Tippen/Schreiben | Existing Schreiben Figma A/B/C maps to `/custom_pack/typing` after pack selection | Do not invent a standalone new Spiele route |

The bounded inventory did **not** establish a wholly unmocked remaining game. The recommendation prioritizes a distinct interaction and missing current content/state evidence, rather than claiming that old artwork does not exist.

## Approval and mockup inventory

1. The historical scope document explicitly says Silben's completed game image exists and should be reused:
   `C:/dev/hangulsori/ko_lernen_app_worktrees/spiele-figma-first-20261018/docs/design/spiele-figma-first-20261018/EINLEITUNG_VORSCHAU_SCOPE_PLAN.md:3`, rows 11–18. It identifies:
   `C:/Users/vjinn/.codex/generated_images/Spiele최종/exec-f7a808e1-5c4c-4eba-a77d-79cbee60ab3a.png`.
   This image was opened and inspected in this research. SHA-256: `db50a1210d422d4e0fa239f01c13d998daf68056032ec863c4aa0b49ee523893`.
2. `C:/dev/hangulsori/_codex_artifacts/lernen-hanok-c-integration-20261010/PLAN.md:10` records the existing approved C Silben/Dokkaebi direction. That is authority to preserve the direction, not approval of a newly generated A/B/C set.
3. The 2026-10-30 handoff JSON lists Silben initial/solved SVG and material PNG, with `nativePng: null` for these two entries. Source:
   `C:/dev/hangulsori/ko_lernen_app_worktrees/spiele-figma-first-20261018/docs/design/spiele-figma-first-20261018/EINLEITUNG_PREVIEW_HANDOFF_20261030.json`, game `syllable_cross`.
   Its `figma-native-20261030/silben-402-{initial,solved}.svg` and `*-material.png` are review references, not proof of today's native parity.
4. The same directory has Satz, Schreiben and Cloze A/B/C context/snapshot files. Its `runtime-behavior-contract.md:11–21,56` maps Satz to `/satz_arcade` and Schreiben to `/custom_pack/typing`.
5. Blitz's material, two-column layout and states are recorded in:
   `C:/dev/hangulsori/ko_lernen_app_worktrees/spiele-dialogue-integration-20261013/docs/verification/spiele-mockups-20261015/README.md`.
   That document distinguishes approval to make the first three mockups from approval of their generated output. The later `EINLEITUNG_PREVIEW_HANDOFF_20261030.md:28–45` also distinguishes preview, native and target-integration gaps.
6. Current checkout `docs/design/` contains the November Quiz/Matching, Karten content-length, Karten navigation and Wortkette content-length records. The latest user message approves Wortkette A/B/C; implementation is the parent's active task. That approval does not cover this Silben proposal.

The Silben reference has a phone surround, old header/cloud presentation, no five-tab footer and older displayed help copy. Reuse its warm paper, wooden crossword arena and canonical Dokkaebi relationship. Do not copy those obsolete framing/state details blindly.

## Current runtime contract and sources

All relative source paths below are beneath the current checkout above.

| Source | Verified behavior that the mockups must preserve |
|---|---|
| `lib/data/sori_activity_catalog.dart:339` | `syllable_cross`, Silben-Rätsel, route `/wordle`; this is a crossword despite the legacy route name |
| `assets/data/silben_puzzles.json` | A1, A2, B1, B2, C1, C2; **20 puzzles per level, 120 total**; each puzzle has 3–4 words and an explicit pool |
| `lib/models/silben_puzzle.dart` | Real row/column occupancy and shared-cell memberships; repeated glyphs remain distinct pool entries |
| `lib/services/silben_puzzle_loader.dart` | Production source loader; do not generate a new content pack for a visual review |
| `lib/screens/silben_kreuz_screen.dart:286` | Level filter, real stored completion count and TTS speed control |
| `:299,386,410,426` | Initial first empty cell, active word, direct cell selection and clue selection |
| `:451` | Correct tile locks the cell, consumes **that pool index**, advances within the active word, and speaks a completed word; wrong tile stays available and current selection remains |
| `:515` | Save viewed/history/result before completion; replay has separate ownership and no added game reward |
| `:588,643` | Per-word help progression; help reveals information only, never auto-places a tile |
| `:770,900` | Actor/grid adaptation and 48dp cell target; entire video canvas stays clear of interactive cells |
| `:1013,1263,1319,1381` | Leave guard, Dokkaebi fire introduction, all 48dp pool tiles, directional/active clues, completed-word audio |
| `:1486` | Persisted success, Next where available, Sarangbang/history transitions and replay-specific result |
| `lib/widgets/practice_dokkaebi_canvas.dart` | One stable PNG/MP4 coordinate system, viewport `(120,56,984,1088)` within 1200-square source; preserve full motion envelope and resting-body scale |
| `lib/widgets/practice_dokkaebi_art.dart` | Existing ready/helping/review/celebrate poses are approved, byte-preserved art; art does not create completion or reward |
| `lib/widgets/practice_impact_frame.dart` | Current source confirms the 100/150/900ms timing, 1→3dp stroke, blue feedback and reduced-motion/lifecycle gating |
| `docs/superpowers/specs/2026-10-03-hahoe-dokkaebi-practice-design.md` | Existing three-place learning scope, free hints, manual placement, help attribution, replay and saved results |
| `docs/superpowers/plans/2026-10-03-hahoe-dokkaebi-practice.md:265–271` | Stable actor scale; final game-card feedback is a slightly thicker **blue outline**, not new flame effects, halos, travelling dots or floor ripples |

Actual flow: open level/puzzle → select clue/cell → choose syllable → correct cell locks or wrong marker returns to open state → completed words become readable/speakable → optionally request staged help → fill all occupied cells → persist history and result → show completion → Next or Sarangbang. Load/empty/recovery/leave states remain reachable.

Do **not** add a timer, Senden/Prüfen, dragging requirement, backspace/undo for locked answers, a six-attempt Wordle grid, whole-word typing field, paid hints or new reward policy. Those would misrepresent this runtime. Old ARB `wordleHow*` strings still describe a six-try game; they are not current Silben gameplay instructions.

## A/B/C fixtures and exact content

A/B/C are review labels, not a universal difficulty algorithm. Here the source levels really are A1/B1/C2, but visual difficulty is separately sampled as compact board / long clue with duplicate tiles / wide board with crossing help. Advanced level does not necessarily mean more syllables or a larger grid.

`SOURCE_FIXTURES.json` stores full original records, source SHA, exact solution coordinates and selected-case checks. Its answer keys are for reviewers only; do not expose them in initial mockups. The three selected puzzles passed bounds, crossing-consistency and pool-multiplicity checks. This does not establish native or whole-corpus visual fit.

### A — compact initial state, A1 `skz_a1_001`

Source locator: `levels.A1[0]`. Grid 3 rows × 2 columns; 3 words; 8 pool tiles.

| Word occurrence | Start (zero-based) | Exact German clue | Answer — reviewer only |
|---|---|---|---|
| `words[0]`, horizontal | (0,0) | gestern | 어제 |
| `words[1]`, vertical | (0,0) | schwierig / schwer | 어렵다 |
| `words[2]`, horizontal | (2,0) | fünf (rein-koreanisch) | 다섯 |

Pool in source order: **제 · 렵 · 자 · 섯 · 어 · 검 · 든 · 다**.

Visible board (`□` open, `·` no cell):

```text
□ □
□ ·
□ □
```

Select (0,0), active horizontal clue gestern. All cells initially blank; all eight pool tiles available. No completed-word audio yet. Main help label: **Satzhinweis ansehen**. If an illustrative within-puzzle count is used, it is 0/3, not a stored user-progress claim. The reference image shortens the third clue to fünf; the new fixture must retain the current source's full **fünf (rein-koreanisch)**.

First sentence help for 어제: **◯◯ 어디 갔어요?** / **Wo bist du gestern hingegangen?**. Do not show `한국어가 어려워요.` as a light Korean hint for 어렵다: current code suppresses unmasked inflected Korean examples before completion because they disclose the answer.

### B — long clue and duplicate tile ownership, B1 `skz_b1_005`

Source locator: `levels.B1[4]`. Grid 4×3; 4 words; 10 pool entries.

| Word occurrence | Start | Exact German clue | Answer — reviewer only |
|---|---|---|---|
| `words[0]`, horizontal | (0,0) | Verantwortung | 책임 |
| `words[1]`, vertical | (0,0) | Verantwortungsbewusstsein | 책임감 |
| `words[2]`, horizontal | (2,0) | Erkältungsmedizin | 감기약 |
| `words[3]`, vertical | (2,1) | Freude | 기쁨 |

Pool: **쁨 · 약 · 책 · 감 · 기 · 좋 · 글 · 임 · 외 · 임**.

Recommended snapshot is after correctly placing source pool index 2 (책) at (0,0), then index 7 (임) at (0,1). The horizontal word 책임 is complete. Active word is now vertical 책임감; selected cell is (1,0).

```text
책 임 ·
□  · ·
□  □ □
·  □ ·
```

Only pool indices 2 and 7 are used/dimmed. **The second 임 at index 9 remains available.** Do not deduplicate it, grey both 임 tiles, or claim the vertical 책임감 is complete. The completed clue may show **책임 · Verantwortung**; its speech indicator is now available. Other answers remain hidden. A within-puzzle count, if shown, is 1/4.

Long-help stress string for 책임감: **그 사람은 ◯◯◯이 정말 강해요.** / **Diese Person hat ein wirklich starkes Verantwortungsbewusstsein.** Preserve the whole compound word; allow measured wrapping rather than truncation or a substituted shorter synonym.

### C — wide board and crossing help, C2 `skz_c2_007`

Source locator: `levels.C2[6]`. Grid 3×5; 3 words; 10 pool entries.

| Word occurrence | Start | Exact German clue | Answer — reviewer only |
|---|---|---|---|
| `words[0]`, horizontal | (2,0) | Plausibilität | 개연성 |
| `words[1]`, vertical | (0,2) | Rekonstruktion | 재구성 |
| `words[2]`, horizontal | (0,2) | Umbenennung | 재명명 |

Pool: **성 · 명 · 세 · 구 · 계 · 통 · 연 · 재 · 명 · 개**. Both 명 entries are required as separate physical tiles.

```text
· · □ □ □
· · □ · ·
□ □ □ · ·
```

Recommended snapshot: no placed cells; select the horizontal Plausibilität clue and cell (2,0), after two help requests for that word. Its real crossing cell is (2,2). Show the crossing cue and the real tappable position label **Zeile 3, Spalte 3** (UI is one-based), plus next help action **Silbe zeigen · direkte Hilfe**. The crossing cell remains blank: **do not expose 성 yet and do not auto-place it**. Source memberships also show the upper (0,2) crossing for the other two words; that is not the active Plausibilität help target.

Separate expanded sentence-help specimen for later review: **이야기의 ◯◯◯과 사실 여부는 다른 문제입니다.** / **Die Plausibilität der Geschichte und ihre Faktenlage sind zweierlei.** This long help panel is a distinct expanded state, not evidence that every panel fits simultaneously above the fold.

## Visual direction and content adaptation

Keep the approved **Dokkaebi crossword arena**: warm wood recessed pockets, tactile ivory syllable tiles, paper clue surfaces, restrained jade selection, warm brass edges and a grounded canonical actor. The central object is an interlocking crossword with genuine voids and shared cells. Do not reuse Wortkette's horizontal reading rail/typing trough, Karten's flip-card holder or Quiz's answer stack.

Shared shell: full five image-only tabs always visible in normal mockup views, in the order Heute/Lernen/Spiele/Hanok/Gye with Spiele selected. Target the approved 402×874 reference geometry and 82dp footer. Preserve at least 16dp under the last interactive face/shadow. There is no OS keyboard in this game's ordinary tile-input flow.

Header/controls: back/leave, Silben-Rätsel title, actual level selector, TTS speed, and existing upper-right Dokkaebi-fire introduction action. Do not replace the fire action with a settings gear or invent a hint currency. Avoid fabricated overall `0/20` progress when no actual storage fixture is defined. For images, show the source level alone or explicitly document a deterministic stored-progress fixture outside the image.

Clues: all 3–4 remain reachable and visible without truncating meanings. Use direction arrows and active-word emphasis. A simple compact list suits A; B can use a measured two-column clue arrangement with wrapping, provided full compounds and 48dp targets fit. This is a proposed layout adaptation, not existing-runtime proof. Never shrink the entire screen or glyphs just to fit a long clue.

Board: minimum 48dp interactive cells; 4–8dp gaps; do not make empty grid coordinates into extra answer slots. Five columns need at least 240dp before gaps (about 264–272dp with 6–8dp gaps). With a 104dp actor region and 16dp separation, they exceed a typical 370dp content width. Therefore C **cannot simply reuse A's actor-left/grid-right geometry**. Preserve the runtime's full motion canvas above/beside the board where it fits, or propose a smaller complete motion canvas in a verified empty region. The latter requires explicit whole-frame bounds review before acceptance; fitting only a still PNG into a void is insufficient. Never crop the actor, cover a cell with the club/video rectangle, or shrink cells below 48dp to preserve decoration.

Pool: retain source order for deterministic review. A has 8, B/C 10 entries; five 48dp controls plus four 8dp gaps occupy 272dp, so two rows fit the nominal width. Current runtime uses 12dp pool gaps (288dp for five tiles); keep that if the material edge/shadow still fits. Repeated glyphs have separate indices. Used tiles remain present but subdued/disabled; unused duplicates remain strong and tappable.

Help: current runtime places the help panel between the board and pool. Keep it closely related to the active word. Initial compact help is one clear action; expanded sentence/crossing/reveal states grow naturally. If the complete help panel cannot fit with board/pool at normal text size, support a deliberate expanded scrolling state rather than clipping content or pretending everything is simultaneously visible. Normal and 200% text-scale reviews remain separate.

The first three images should test A initial / B partial completion / C crossing help, not three decorative reskins. Additional states below can be a later sheet or separate follow-up images; they are not requested for generation in this task.

## State and motion checklist for the next image/spec phase

- Initial empty board: hide answers, no audio for an unfinished answer, no fake success or XP.
- Active clue/cell: direction and active word are visible; shared cell marks represent actual memberships.
- Correct placement: one actual pool index is consumed; cell locks; active-word cursor advances; completed word may speak.
- Wrong placement: selected cell gets the error marker/brief feedback; pool entry remains usable; no persistent wrong-answer letter or leaked solution.
- Help level 1: path + permitted masked Korean example + real localized sentence. Unmasked inflected Korean answer stays hidden until completion.
- Help level 2: only actual crossing cells are marked; position action selects the cell; no auto-fill.
- Help level 3: reveals one selected syllable and says **Lege die passende Silbe selbst ins markierte Feld.** The learner still places a matching tile.
- Dokkaebi interaction: preserve original PNG/MP4, its stable canvas/contact and actual requested play. Latest game-card feedback is blue outline 1→3dp in 100ms, hold 150ms, return 900ms; no new game-card flame textures/halos/ripples. Reduced motion uses the same information/outcome without the animation; offscreen/background work stops.
- Solved: only after persistence succeeds; original Next/Sarangbang/history actions; replay does not create a new reward.
- Load/empty/save failure/retry/leave confirmation: preserve current ownership and input restrictions.

These are source-grounded design requirements, not claims of newly executed Flutter tests or native interaction QA.

## Canonical assets and future imagegen brief

Canonical character runtime files:

- `assets/illustrations/tactile/dokkaebi/dokkaebi_ready.png`, SHA-256 `facaa51a5a420fd57fa07a805607d083592e801cbc6e39ff049a32818f3f04ba`.
- `assets/illustrations/tactile/dokkaebi/dokkaebi_helping.png`, SHA-256 `8161885cd8ce197176763385a503a3a5d89de1de471dd657ee8bc4ca6ad21665`.
- Other state poses come only from `PracticeDokkaebiPose`; no new face, outfit, horns, character, cropped portrait or replacement actor.

Common UI: use `C:/Users/vjinn/.codex/generated_images/공통UI정본/CANONICAL_UI.json`. Cloud/settings/yeopjeon must remain exact separate PNG assets in Figma/runtime. Navigation files are `assets/illustrations/approved_games/nav_heute.png`, `nav_open_book.png`, `nav_spiele.png`, `nav_hanok.png`, `nav_gye.png`. Their original-byte provenance is recorded in current `docs/design/karten_navigation_20261104/PROVENANCE.json`. The reference shared footer is the approved Wörter-Quiz v3 screen, not newly invented glyphs.

Future imagegen reference pack (maximum five paths per call): the inspected approved Silben image, approved Wörter-Quiz full screenshot for the common footer, exact current Dokkaebi pose PNG, exact canonical cloud PNG, and the immediately previous accepted candidate when editing. Never infer exact-asset fidelity from an imagegen output. Imagegen can depict the canonical designs for review; generated character/navigation/cloud pixels must be labelled **visual proposal only**, and actual Figma/runtime must place original files separately. Five tabs must still be shown in the mockup; do not repeat the blank-footer presentation.

Suggested shared prompt, not executed:

> One full mobile Hangul Sori Silben-Rätsel screen, 402:874 portrait, no phone frame. Preserve the supplied approved Dokkaebi crossword arena's wood, ivory hanji, jade and restrained warm gold materials. This is an interlocking syllable crossword, not a word-chain input rail, quiz answer list, flip card or matching columns. Use the supplied canonical Dokkaebi identity and preserve the complete figure and its space; no new character or flames. Show the exact fixture's occupied cells only, the active clue and selected cell, the full source-ordered syllable pool including duplicate glyphs, and the specified help state. Unsolved answers must remain hidden. Keep German meanings readable and preserve every Korean syllable. Use the source level, TTS-speed action and existing Dokkaebi introduction control. No timer, Senden/Prüfen, XP, fake saved progress, paid hint or keyboard. Show all five approved navigation designs in their correct order, Games selected, no labels, with at least 16dp clearance from the last control. Retain 48dp cell/pool/action targets and use content-specific layout adaptation instead of scaling everything down. Output one screen only.

Append the exact A/B/C record/state from this document or `SOURCE_FIXTURES.json`. After generation, independently inspect grid coordinates, duplicate pool ownership, hidden answers, German compounds, original actor identity, footer order and CTA clearance before requesting user review. Do not generate today; the current task ends with research.

## Method and proof boundaries

Applied skills: previously read `uiuxdesigner/mobile-app-ui`, `uiuxdesigner/ux-audit-critique`, `ecc/accessibility`, `critique-typography`, and newly read `superpowers/brainstorming`. These drove the source-first option comparison, exact-state specimens, content-size adaptation and separation of recommendation from approval. `using-superpowers` was inspected and explicitly excludes dispatched subagents. No question/approval loop or implementation plan was added to this research-only assignment.

Official guidance checked in this session on 2026-11-04: [Apple Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility), [Apple Motion](https://developer.apple.com/design/human-interface-guidelines/motion), [Android app accessibility](https://developer.android.com/guide/topics/ui/accessibility/apps), and [Google's official Material 3 Expressive research](https://design.google/library/expressive-material-design-google-research). Applied decisions: readable type and scalable content, proper target size, meaningful rather than decorative motion, full controls and state feedback. No claim is made that these pages were first published in 2026 or that a PNG proves compliance.

Read artifact-union INDEX first, ran its metadata/hash change scan, and used a bounded local Graphify query before scoped source reads. Change scan: 44,875 metadata changes, 10 reviewed-document hash changes, 0 errors, 0 external API calls; report `C:/dev/hangulsori/_codex_artifacts/artifact-union-audit-20261010/changes_after_wortkette_20261104.json`. The old index is a locator, not current approval. No full session archive or full old image corpus was reopened.

Completed here: current catalogue/route audit; historical approval/missing-evidence distinction; current source flow and state ownership; three exact real fixtures with limited data checks; canonical source inspection; future image brief. Still unperformed: new image generation, new design approval, Figma composition, native transfer, screenshot parity, accessibility interaction tests and device QA. The parent owns the current Wortkette implementation and any eventual next-step decision.
