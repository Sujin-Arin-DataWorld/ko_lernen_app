# Season 1 independent story recheck — 2026-11-08

Reviewer: `/root/story_completion_review_v2`. This is a new live source review, not a transfer of previous PASS labels. Repository files were read only. Results here cover story copy/state; character design and anatomy have a separate independent reviewer.

## Live baseline

- Design worktree: `C:/dev/hangulsori/ko_lernen_app_worktrees/character-illustration-spec-20261103`; branch `codex/taego-canon-season1-mockups-20261103`; HEAD `0ccabfe290e0f7dad49bde0eb1c51758d13136ea`; `git status --short` empty.
- Content worktree: `C:/dev/hangulsori/ko_lernen_app_worktrees/season1-content-integration-20261102`; branch `codex/season1-content-integration-20261102`; HEAD `e5f77c9440d8d10d74c3ae1780cc0c94897c39d1`; `git status --short` empty.
- Both exact worktrees were present in current `git worktree list --porcelain`. No other matching live process appeared in a command-line process search besides this inspection's pwsh/rtk/powershell processes. This is not an open-handle or other-session absence guarantee.
- Read live `SCOPE.md` and `DESIGN_REVIEW_GATE.md` in full. Gate SHA-256: `d7bd11bb01d3a254d94e81c994652466369492855431226a1899490bc64ee89c`.
- Read `STORY_COPY.json` (SHA-256 `ec74e76a0bad2b185ae6beddc6de83a8cc9f2bcec5c0e756865dba095bd473fe`) and compared its source declarations to live bytes, then read the underlying manuscript lines, not just the JSON summaries.
- Required artifact index was read. `lookup.py changed --verify-reviewed` completed with 46,966 metadata changes, 10 reviewed-source hash changes, zero errors and zero external API calls. Full result: `STORY_ARTIFACT_CHANGES_20261108.json`. These broad historic-index differences do not supersede the exact current source hashing below.

## Source hash recheck

Every hash below matches the expected hash in `STORY_COPY.json` on this date. Source paths are the exact paths in that JSON; ten content files are under `docs/learning/ildu-season1-content-20261030` in the content worktree.

| Source key | Live SHA-256 | Match |
|---|---|---|
| canon | `24ec73c1051da05702aac1d0257339cb10059d6cc4ea05cb5c7fb585deb64bcb` | PASS |
| first_book | `961bc75ab7241e89792f6ed260d7a7c55e17b07d5f6b56ce1502fddf32fe5f02` | PASS |
| common | `f39cf6e56e0115e8095e1057a2485ddecade03e384f9ad0119316cbf0bd1aa74` | PASS |
| storeroom_contract | `e891b83567da7b36efb3ae86f9218d5a11be27223da78a7f0813f27ddee86782` | PASS |
| storeroom | `3c880d1dfed9372866ef4a9768f7a00c0a4c6a5bbf94ef9b738b1af1512923d7` | PASS |
| gate_contract | `fea1bd28b3c21a869016d015aacaae3b80c395d129a5c265bec7c5497ac7a22d` | PASS |
| gate | `10f9d1cf6bd490f6e31d467d4191200e7bfc084e936c9ee4a0e1c701379959c8` | PASS |
| note_contract | `d90d86a5e9e2830c66e62bbb91181926e7837d7048d3fca7ffc5ceb71dbd2f2d` | PASS |
| note | `59ec7e468ccc1af10efef3600c204b0b77072d33c1063cca521a77b3b29e720c` | PASS |
| gatekeeper | `c4aa900747ff925f54643496f16fb94046b40bd1bddee480b32eb3111df5b104` | PASS |
| scope | `02bd3ce7102c0ac475f1fc509e3a0dd8cabbee6c8c3ead4cc7cfd10ffe1b1d60` | PASS |
| final_readme | `538db1700528a4b1732849b1b49f9f94ff39987d0ce192aa5130338b4998809d` | PASS |

## Scene source/state preflight

The 14 new-state entries' exact KO and DE copy were compared with live original rows. All agree with their declared sources, with the explicitly declared R24b DE localization exception below. This is source/copy-plan PASS only; each concrete generation prompt and output needs its own review.

| Image | Original lines read | Speaker, cast and state constraints | Preflight |
|---|---|---|---|
| R21b | first_book:35; canon:379–394; scope:28 | Tal speaks to sample player Mina, not Sujin. Sujin/Taego divine remain companions. Ruined courtyard, existing first-book 아, no completed construction or saved success. Last half of U1-D12; preceding proverb remains in earlier scene. CTA `Zurück in den Hof` is established UI, not a manuscript quote. | PASS source; exact request reviewed below |
| R22 existing | common:39,51,58 | System C-UNCERTAIN and retry C-TRY. Existing 아 result preserved; no cast, new event or success. | PASS live image postflight below |
| R23 | common:46,50,58 | C-SAVE only after actual save confirmation. Required companions Sujin/Tal/Dokkaebi/Taego divine/Joy basic; `Weitermachen`. Returning to court does not establish unrelated building ownership. | PASS source; prompt/image pending |
| R24a | storeroom:80–91; canon:210–215; storeroom_contract:29–34 | Dokkaebi request, Sujin companion, BUILD_STARTED only; label task invitation, no quiz UI. No completed storeroom, discovery bag or old-box touching yet. | PASS source; prompt/image pending |
| R24b | canon:213–215,427–433; storeroom_contract:33 | Sujin says actual canon:430 sentence, Joy basic brings empty fabric bag from nameless old box; Dokkaebi starts surprised reaching reaction, not simultaneous completed protection pose. BUILD_FINISHED/story-ready required independently of lessons. No seeds, letter, sender, Yeoni or ownership claim. DE faithfully newly localized; not called existing canon DE. | PASS source/localization candidate; prompt/image pending |
| R25 | gate:176–187; gate_contract:27–33; canon:217–222,551 | Tal speaks, Sujin accompanies; BUILD_STARTED second inner gate. 문·방·길·마당 only on existing fixed guide/minimap result, no drag/quiz, permanent newly carved sign or actual route unlock without connection. | PASS source; prompt/image pending |
| R26a | note:29,51–55,63; note_contract:25–31 | System N-WAIT; no cast. 집 is practice draft; incomplete Sarangchae, no lit completed-room lamp or official note on desk. | PASS source; prompt/image pending |
| R26b | canon:208; note:53–60 | Dokkaebi N-LAMP before note writing, actual Sarangchae completion/story ready. Supported lamp with old wick; no already-written official 집 note. | PASS source; prompt/image pending |
| R26c | canon:208; note:53–60 | Face-free player POV N-PLAYER; same 집 one-word note under lamp on desk. German dialogue `Haus` does not replace Korean 집 on paper. Brush/hand/paper contact if shown; no score or storage success. | PASS source; prompt/image pending |
| R26d | note:53–55,64; note_contract:29 | System N-PENDING; same single 집 note and completed room retained. Retry, not success, duplicate note, new writing or rollback. | PASS source; prompt/image pending |
| R26e | note:53–62; note_contract:29 | System N-KEPT only after actual storage success. Same single 집 note remains on desk, not book 아, new treasure or duplicate. | PASS source; prompt/image pending |
| R26f | canon:552; note:53–62; note_contract:29–31 | Tal N-BOOKMARK after N-KEPT, looks from same note to player; wooden mask fixed, supported fan. Exact `Hoho` DE retained; bookmark is dialogue function, not new reward object. | PASS source; prompt/image pending |
| R26g | note:55–65; note_contract:29 | System N-SKIP representative branch from N-WAIT; same draft/incomplete environment, no lit completed-room lamp, no reset/penalty/success. Return to same point, not compulsory linear step after R26f. | PASS source; prompt/image pending |
| R27a | gatekeeper:3–21,25–31; canon:221 | Existing Dokkaebi role play with Sujin, middle gate milestone; no new NPC or forgotten identity. Arms spread means club must be stably grounded. Optional practice name; no mandated real name or six-unit pass gate. | PASS source; prompt/image pending |
| R27b | gatekeeper:15–21,27–31; canon:553 | Same Dokkaebi and Sujin; moves aside after actual request/repeated full `이쪽으로 오너라. / Komm hier entlang.` Praise belongs to this branch only; assistance branch stays available and independently unassessed. No E04 storm/30%/completed gate/late latch repair. | PASS source; prompt/image pending |

Required flow: R21b → save response → R22 if unconfirmed, R23 if confirmed. R24a and R24b have separate construction/story gates. R26a → actual completion/ready → b → c → response → d OR e → f; R26a → stop → g → resume existing owner state. R27a → interaction/repair/repeat → b; help route uses its own source line 29, not unearned praise.

## Exact R21b request preflight

Opened `C:/dev/hangulsori/_codex_artifacts/season1-completion-20261106/R21b_REQUEST.json`, SHA-256 `25868812b213440d6b299a2f5ec7545a154bb77a891d4a44c7b8a76138db9daa`.

Story preflight PASS for this exact prompt: Tal addresses outside-screen player and names Mina; Sujin looks at Tal; Taego calm player-facing; old left-page 아/right blank book; no Joy/Dokkaebi in this single-speaker cut (offscreen, not deleted from story); ruined courtyard and no rewards/saved check. Exact KO/DE copy and courtyard CTA match source/UI contract. Named cast/gaze/support/next action are stated. Character scale, four limbs, left emblem and full-body visibility still require the independent visual reviewer; reference attachment alone does not establish them. New prompt revisions must be reread rather than inheriting this SHA's preflight.

## Existing R22 live postflight

Opened the actual `.../final-selection/R22-save-unconfirmed-de.png` using image view, not only its prior review. Live SHA-256 is `841979563167f299c86bc202e65b451b3b520935ff8935f69972fe17ea75f40c`, matching the declared existing output. Read exact `R22_PROMPT_V4.json` too.

Observed: old open study book on worn supported wood desk; left page 아, blank right page; ruined stone/tiles and flowers; no people or characters; header HANGUL SORI / DE; state heading `Noch nicht bestätigt`; exact source body `Es ist noch nicht bestätigt, dass dein Fortschritt gespeichert wurde. Wir prüfen es noch einmal.`; exact retry CTA `Noch einmal versuchen`. No successful-save tick, reward, count, cloud/settings/coin or restored building. Story/state/copy postflight PASS for this exact image. This does not certify retry behavior, actual storage, native geometry, accessibility or user approval.

## Pending postflight

No newly generated R21b/R23–R27 output was supplied to this reviewer at this report's initial write. Those 14 rows remain PENDING image postflight, even when source-plan PASS. Review must open each actual output, record its SHA and rendered words, cast/gaze/support, environment/props/state/CTA, then issue PASS/FAIL/UNVERIFIED by observation. Do not label all 15 images complete from this report. Static AI review, human localization approval, user image approval, Flutter/device behavior and release are distinct gates.

## Addendum: R21b V8 actual output postflight

Opened actual output `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-9cf5ab89-4dee-4969-bac0-9f8d94826f61.png`. SHA-256 `b4ce9c4a42a650cf6ff8e63872f7fb901b66e59e83f671290375e8a2a907fd44`; 853×1843 RGB PNG. Parent states V8 edits V7 scale while preserving exact R21b story copy; this review judges the actual observed result rather than inheriting a V7 verdict.

Story/copy/state postflight **PASS**. Observed exact text: speaker `탈선비`; KO `자, Mina 제자여, 오늘은 첫 글자부터 차근차근 살펴보세.`; DE `Nun, Mina, sehen wir uns das erste Zeichen Schritt für Schritt an.`; CTA `Zurück in den Hof`; header `HANGUL SORI` / `DE`; chapter `Das erste Buch`. Tal's free hand opens toward player, fan is held in the other hand; Sujin turns to Tal and supports a closed red book against her body; Taego faces player. Old wooden table stands below cast and supports open old book with 아 on left page/right blank. Ruined low walls, fallen tiles and wildflowers; no restored building, storage-success mark, reward, question/quiz, cloud, setting or coin. Joy/Dokkaebi absent from this single-speaker crop are not declared absent from the story. Character scale/anatomy/canonical identity remain separate independent visual checks, and this PASS does not override a visual failure.

R21b's earlier pending output status is superseded only for this exact V8 SHA. Other new images remain pending.

## Addendum: exact binding-brief strategy preflight for remaining 13 outputs

Parent supplied strategy before generation: for each image, include **all fields of that exact `STORY_COPY.json.scenes[]` object verbatim as binding scene brief**, then common C-style forest-teal `HANGUL SORI` / `DE` header, ivory hanji panel, gold CTA resolved from `ctas[scene.cta].de`, one 853×1843 scene, one current speaker, exact KO and DE dialogue, no exercises/reward/new state; original cast references only. This is a concrete strategy preflight against the live JSON hash above, not a claim to have read later tool-call text. Any omitted scene fields or changed wording/state require recheck.

Story preflight is **PASS individually** for `R23`, `R24a_request`, `R24b_discovery`, `R25_labels`, `R26a_draft_wait`, `R26b_lamp`, `R26c_write`, `R26d_pending`, `R26e_kept`, `R26f_bookmark`, `R26g_pause`, `R27a_entry`, `R27b_step_aside`, because the full per-scene object preserves copy source, prerequisites, speaker, required cast, gaze/support, props, architecture, storage, omissions and next action already independently verified above. Do not print source/metadata/constraints as UI or add unsourced chapter/state claims. R26c paper text must stay Korean 집 even though its German dialogue is Haus. System-state rows must not assign the system copy to a character. Long bilingual copy is a layout challenge, not permission to paraphrase or delete state qualifiers. Actual save/build/repeat conditions remain prerequisites of the depicted state, not assertions that runtime executed them.

Final output postflight remains mandatory separately for all 13. A successful prompt contract does not establish model compliance.

## Addendum: R24a V1 actual output postflight

Opened `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-cec55e9f-9b2c-4c33-9c9d-5ba9dc8fe5ea.png`; SHA-256 `ee6a767c39ad2247135222034afd316dbea3a1d70aa992dd6589ef9aa112a8eb`. Also opened its actual prompt entry in `REQUESTS_20261108.json`.

Overall story/output verdict **FAIL; retain candidate, do not ship**. Exact KO and DE dialogue, `Weiter` CTA and header are readable and match. However the panel entirely omits required `도깨비` speaker label despite prompt's explicit `Render panel EXACTLY speaker: 도깨비`. This is a concrete compliance failure, not a manuscript disagreement.

Observed story staging: Dokkaebi speaks/gestures to material area; Sujin observes that area, her closed book supported against body. Club held by upper handle and weighted base rests on ground. Foreground contains loose photo of another completed hanok floor, timber bundle and hand tools. No seed bag, E03, old-box opening, save success or rewards. Background timber structure has no roof or enclosing walls: unfinished construction is visible, so **not evidence of a completed-building claim**. The binding brief allows a 미완공 구역 and supplies no exact stage geometry; do not invent a stricter bare-footprint requirement from this image alone.

Props are **UNVERIFIED/partial** against the full binding brief: distinct timber/tool areas or bins are not evident and no loose unplaced 푯말 are visible. Neatly laid tools do not independently prove completed sorting, but this framing weakens the requested pre-activity label-sorting situation. A revision should add exact speaker label and visibly prepare loose unplaced labels around separate rough timber/tool staging; preserve separate completed-floor reference photo and avoid answer captions/quiz UI. Character identity/scale/design are separately reviewed and this report does not confer that PASS.

## Addendum: actual remaining request-file preflight

Read the actual `C:/dev/hangulsori/_codex_artifacts/season1-completion-20261106/REQUESTS_20261108.json`, SHA-256 `7a4574f8631f05a7c151a31644a88c031fd3bdf6c555ccf60bc1c3f5bdfa9a31`. Parsed each embedded `Scene brief (binding)` JSON and compared it structurally with the corresponding live `STORY_COPY.json` scene; all 13 are identical, including every source/state/prop/gaze/next-action field. Checked explicit KO+DE text and resolved German CTA against source JSON: all 13 match exactly. The shared wrapper instructs one current speaker/system state, only required cast, no learning exercises/rewards/new runtime facts, and scene-specific actions overriding general examples. Each actual request passes the story preflight specified above. This replaces strategy-only preflight uncertainty for this exact file hash, while preserving R24a V1's observed output failure.

## Addendum: R24a V2 actual output postflight

Opened `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-b614e8fc-7a7b-4db1-b53e-1821d8346b65.png`; SHA-256 `b61e46fa54ccbbc5e7ba8da833e68b8294fe2a9d3e14312d8196a0d3e3c4e7a4`; actual size **935×1683**.

Story/copy/props **PASS for this candidate**. Exact `도깨비` label now appears, KO/DE and `Weiter` unchanged; separate rough timber/tool areas, loose unplaced blank 푯말 and the loose completed-floor reference photo are visible. Cast observe/gesture toward materials, club base supported. Ruined material yard, no completed building, bag/discovery, save-success or reward. Neatly present materials are not falsely captioned as completed sorting; loose labels preserve the activity-before state. **Packaging FAIL** against 853×1843 request: output remains withheld pending final canvas edit and fresh postflight. Story PASS does not transfer automatically through that edit.

## Addendum: R26a V1 actual output and bounded correction preflight

Opened `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-5992840c-4b07-43c7-b49f-3abe4561c283.png`; SHA-256 `ddafdd32c278884c79c55c729df3f48e237b8267ca6a6ed1997b2125e71a6f51`; actual size 853×1843.

Copy/header/system speaker/CTA **PASS**: full exact KO and DE N-WAIT body and `Zurück in den Hof` are visible. No cast, completed Sarangchae, lamp, official loose note, save success or reward.

Story/prop continuity **FAIL/withhold**. The central object visibly clones the R22 first study book's worn dark cover, stitched center, thick crumbling pages, same desk and framing, but replaces its defining 아 with 집 and a new red underline. The body says practice, yet this actual object is not clearly a separate practice record and visually overwrites the established first-book result. This is not certification that every old-looking book is forbidden; it is an observed continuity ambiguity in this direct R22 clone.

Bounded correction story preflight **PASS**: replace that central old first-book object with a clearly different **thin bound practice ledger**, intact simple cover/pages without the canonical aged first-book cover/stitching/crumbling identity. Show one 집 on the practice page; optional small prop heading `연습 기록` is an editorial practice identifier, not claimed manuscript dialogue/canon text. Merely relabeling the same original first book is insufficient. Remove the red underline/score-like mark; no official loose note, brush/input/exercise UI, lamp, successful storage or new reward. Preserve ruined/unfinished environment and exact existing full bilingual N-WAIT body/system label/CTA. This correction clarifies the source's explicit practice-record/draft status without adding a new story fact. Final output must still be opened independently.

## Addendum: R24a V4 and R26a V2 final-candidate postflight

Both actual images opened afresh; no earlier candidate PASS inherited through the edit.

### R24a V4

- Path: `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-ccab549a-ecdf-47cd-8ac2-71bc63b18d50.png`.
- SHA-256 `592353791c1f68a43e6b9a059181a16da10bb0daf4d33efb441541efb55a0877`; actual 853×1843 RGB PNG.
- **PASS story/copy/props/output size**. Exact speaker 도깨비, full KO/DE and Weiter remain readable; ruined unfinished material yard, two separate material areas, loose unplaced blank labels, and separate finished-floor reference photo all observed. Dokkaebi gestures toward task area, Sujin observes and supports book, club top gripped/base grounded. No bag discovery, old-box intrusion, success/reward or completed building. V1 and V2 failures above remain historical; this exact final SHA remedies those story/size issues. Canonical character identity, tactile layout and native geometry remain separate review scopes.

### R26a V2

- Path: `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-7aa1c9d8-9bca-4613-b3cf-708935382c65.png`.
- SHA-256 `7488735ab99e45f95b62af4c744bc12d26b00fac9771632e3e656ead360bf88b`; actual 853×1843 RGB PNG.
- **PASS story/copy/props/output size**. Central object is now a visibly different thin, intact grey-bound practice ledger, not the thick crumbling stitched first-book identity; page heading 연습 기록 identifies practice and a single 집 is shown. No red grading underline, official loose note, brush/input task, lamp, cast, reward or storage-success. Ruined environment retained; full exact 시스템 label, N-WAIT KO/DE and Zurück in den Hof preserved. The extra 연습 기록 prop identifier is the explicitly preflighted editorial identifier, not passed off as manuscript dialogue. This exact SHA remedies V1 continuity failure without retroactively relabeling V1 as PASS.

## Addendum: R23 V1 story postflight

Opened `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-7edc9a07-d22a-470e-a730-43407401a85c.png`; SHA-256 `53f40cc39735c5e272156bc3a18f36eb143768f84cafb9539c11e69fb6a97e99`; 853×1843 RGB PNG.

**PASS story/copy/state only; overall WITHHOLD for separately flagged Taego hindleg visibility failure.** Exact 시스템 label, full C-SAVE KO/DE and Weitermachen present. All five required companions appear. Sujin/Taego/Dokkaebi attend to existing book/material area, Tal addresses outward; attention is distributed rather than all-camera celebration. Supported old desk/book with left 아 and blank right preserved. Ruined courtyard; no new completed building, reward, extra greeting or ownership event. This depicts the preconditioned confirmed-save scenario, not proof of executed save. Character gate explicitly requires every required companion to pass; this story PASS cannot waive Taego's visible anatomy issue.

## Addendum: R26b V1 story postflight and bounded revision

Opened `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-74a1104e-b9e5-438e-9aa2-f88da101840a.png`; SHA-256 `4aae1591d9e291a67ee5636bc0463872eaac7e20f63e2e09f27218ce881f5b11`; 853×1843 RGB PNG.

**FAIL required speaker label**: actual panel omits 도깨비, although it retains exact KO `드디어 이 집에 다시 불이 켜지는구나!`, DE `Endlich brennt in diesem Haus wieder Licht!` and Weiter. Only Dokkaebi shown, looking toward supported lit lamp. One hand supports base, the other holds handle. No already-written official 집 note or reward. Lit-lamp-before-writing state agrees with canon:208 and note:53–60.

Lamp observation: visible bronze cup with handle/base, braided pale protrusion and charred burning tip. This plausibly reads a thick fibre wick rather than an unambiguous wax candle; exact fuel, age and provenance cannot be established from pixels. Source requires an old wick but specifies no lamp geometry. Therefore do not manufacture a definite manuscript failure from candlelike thickness alone. A short darkened fibre wick at an oil-cup rim would remove ambiguity without changing story state.

Recognizable completed hanok facade appears behind him. The manuscript explicitly permits completed Sarangchae in N-LAMP, so a completed building is not inherently a source-state contradiction. Parent reports the actual framing constraint forbids recognizable architecture; that reported additional framing rule belongs to the design/prompt gate and is not falsely described here as a canon ban. **Bounded revision preflight PASS**: add exact 도깨비 speaker label, replace recognizable facade with dark soft bokeh/no new recognizable geometry, retain supported old lit lamp, exact bilingual dialogue and Weiter, no note-writing/success/reward. Optional wick clarification above is consistent with source. Actual revised output still needs fresh postflight.

## Addendum: R24b V1 postflight

Opened `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-25989422-468a-4832-bfca-57a6ce4b97d9.png`; SHA-256 `66aff39512bbc0adaa01a037a6d4c3d71e722c7be9b4edb4f6f9308f9903c126`; actual 853×1843.

**FAIL required speaker label**: 수진 omitted. Exact KO `어? 조이야, 이게 뭐야? 씨앗 주머니 같은데 안에는 아무것도 없네.`, DE `Oh? Joy, was ist das? Das sieht aus wie ein Samenbeutel, aber es ist nichts darin.` and Weiter retained. Sujin observes bag and addresses Joy; Joy's beak contacts bag rim, open interior visibly empty; Dokkaebi surprised/reaching rather than already clutching bag. Nameless old wooden box beneath bird, completed storeroom discovery area, no seeds/letter/sender/Yeoni or rewards. Main discovery story/props otherwise source-consistent. Bird tail exits right frame, independently failing complete cast/design evidence; this story review cannot waive that. Revision needs exact 수진 label, fully visible correct Joy and same small empty bag/contact/reaction/source copy; preserve failure candidate.

## Addendum: R26c V1 and lamp-source continuity decision

Opened `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-f5b38c4e-47eb-4475-85ec-a207969afd6b.png`; SHA-256 `c85e31a090e3977eba884703885c27c235bd7d9e55b252c4a55f6c437690c0ce`; actual **853×1844**, not requested 1843.

**PASS writing-story/copy/POV/support; lamp continuity UNVERIFIED pending matched preceding N-LAMP.** Exact 플레이어 / 집 / Haus / Weiter. Face-free player POV: left hand holds paper, right hand supports brush and its bristles contact last stroke of 집. One official note, one word 집, no extra phrase/date/signature, no storage success/score/reward. Note and inkstone on supported wooden writing desk. A glowing wood/hanji lantern stands at upper left; internal flame/fuel/wick is hidden. No bronze-cup lamp appears. It cannot inherit continuity from failed R26b V1's different lamp. One-pixel canvas difference is recorded rather than silently described as exact 853×1843.

Re-read live source occurrences of 심지/등불/등잔 across canon, note and note_contract. Canon:204 specifies S1-E02 `오래된 등잔과 심지 흔적`; canon:207 old packaging with wick; canon:208 says Dokkaebi lights Sarangchae lamp using old wick, then player writes 집 beneath that light and leaves it on desk. Note:53–55 and note_contract:23–29 preserve that order. **None mandates bronze cup, wooden lantern shape, or a specific lamp material/geometry.** An enclosed wood/hanji lantern is source-compatible housing if the preceding N-LAMP clearly establishes a supported oil-lamp/aged fibre-wick flame inside it. Closed lantern glow in C alone does not prove old wick; an electric lamp/new wax candle cannot replace the source's old wick fact.

Bounded plan **PASS for source consistency**: treat this C candidate's desk/one-note/wood-lantern arrangement as provisional continuity reference only; generate B with the same lantern/desk before any note exists, show old wick ignition or visible aged fibre-wick flame through an open access panel/simple inner lamp dish, correct 도깨비 speaker, exact lamp dialogue/Weiter, no recognizable invented facade or rewards. Re-open B and compare lamp/desk to C. This is not canon promotion of the new lantern, user approval, or permission to claim the unobserved mechanism already passed. Preserve one same lamp and one same note through C/D/E/F after that baseline passes.

Packaging clarification from parent: 853×1843 is an internal baseline, not a user-mandated exact pixel count. C's 853×1844 is one extra pixel (0.054% height) with near-identical aspect and no observed story/copy defect. **Accepted within explicitly documented 1px internal tolerance**; do not regenerate/crop/stretch solely for that pixel. Initial strict packaging-failure recommendation is withdrawn on this clarified gate; actual dimensions remain recorded and are never called exact 853×1843. The substantial R24a V2 aspect failure remains a different case.

## Addendum: R26d and R26e actual output postflight

Opened both actual images and compared them with the previously opened C image rather than relying on their filenames.

| Scene | Actual output | SHA-256 | Dimensions |
|---|---|---|---|
| R26d | `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-0bff9f3f-8131-4d91-8da1-032d93072dbc.png` | `247c684c6dad9ce84a376e0003d61a3f04faf68e700198f04fda213c4b427f73` | 853×1843 RGB |
| R26e | `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-b55492fb-ecbb-45f3-9825-9b72d44d6add.png` | `549033e86922d0c7484d65e717bf057c2ee24887d339279df881d5da4445e6c5` | 853×1844 RGB; accepted documented 1px tolerance |

R26d **PASS story/copy/state and local prop continuity**. Exact 시스템 label; KO `아직 쪽지 보관을 확인하지 못했어요. 방금 쓴 내용은 그대로 두고 다시 확인할게요.`; DE `Es ist noch nicht bestätigt, dass der Zettel aufbewahrt wurde. Deine Eingabe bleibt erhalten; wir prüfen es noch einmal.`; CTA Noch einmal versuchen. One same 집 note on same carved wood desk with same lit floral lantern/inkstone. Hands/brush naturally absent after writing; no erased content, duplicate note, save-success icon, reward or building rollback. This is retry/unconfirmed, not confirmed storage.

R26e **PASS story/copy/state and local prop continuity**. Exact 시스템; KO `집이라고 적힌 첫 쪽지를 서안에 남겼어요.`; DE `Der erste Zettel mit dem Wort 집 liegt jetzt auf dem Schreibpult.`; CTA Weiter. Same single 집 note/desk/lantern/inkstone, no duplication/new container/reward. Depicted scenario requires actual successful storage response, as source says; image itself is not a runtime storage test. D and E are response branches, not two successive saves.

## Addendum: matched-lantern R26b candidate

Opened `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-9e833d4a-315a-4f6c-96e1-dbeaa12e2e04.png`; SHA-256 `a5402496abc71155721ada7b0fbdbc5faf9d35a9b12dea90afbeb289cb5a6834`; actual **935×1682**.

**Story-state/copy/continuity candidate consistent; overall HOLD for substantial aspect/cropping design failures.** Exact 도깨비 label, source KO/DE and Weiter; no note exists yet on same carved desk. Same floral wood/hanji lantern style as C/D/E, open access door showing a flame atop supported small inner lamp; character looks toward lamp, holds door edge and rests other hand on desk. Dark unfocused background, no recognizable new facade. Flame mechanism is now visibly a small inner lamp rather than an unexplained electric glow; its actual historic age cannot be pixel-certified. No new sender/Yeoni clue/reward. This provides reviewed continuity evidence only; it is not a final passed B and cannot override packaging/crop hold. Re-open final B independently before whole B→C→D/E→F sequence completion is claimed.

## Addendum: R26g V1 and R26f V1 actual output postflight

Both actual images opened. Reviewed against their source rows and the already opened A2/C/D/E, not merely the output names.

| Scene | Actual output | SHA-256 | Dimensions |
|---|---|---|---|
| R26g | `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-bb3250f3-46b0-423e-97b3-f873c973966a.png` | `f5f0180fbe0f3463b95f5a5b93fa01e074ab3ca755c4ba4fb6b32e984418b5a8` | 853×1843 RGB |
| R26f | `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-a68bb969-2d09-49f4-9196-7035020b59d0.png` | `800fcbe4dac3d28b6d8081362dcc8c8210030293f1fc6549ed0e7fe351efec39` | 853×1843 RGB |

R26g **PASS story/copy/state/props**. Exact 시스템; KO `괜찮아요. 같은 자리에서 다시 시작할 수 있어요.`; DE `Das ist in Ordnung. Du kannst an derselben Stelle weitermachen.`; CTA Zurück in den Hof. Same intact thin grey practice ledger, same 연습 기록 heading, 집 left/blank right, same worn practice table and ruined flowers/tiles environment as A2. No lit completed-room lamp, official loose note, reset/penalty/reward or save success. Correct representative N-WAIT→stop branch; it is not subsequent completion after F.

R26f **PASS story/copy/state, narrative prop continuity compatible**. Exact 탈선비; KO `처음 쓴 낱말이 ‘집’이라니, 허허, 좋은 시작일세.`; DE `Dein erstes geschriebenes Wort ist 집. Hoho, ein guter Anfang.`; CTA Zurück in den Hof. Tal faces player with open free hand and supports bamboo-painted fan in other hand. One rough-edged cream paper with one black brush 집 remains on a floral-carved wood desk; same floral wood/hanji lit lantern. No second note, additional words/date/signature, new bookmark object, container, reward or extra save.

Continuity evidence is more than word equality: hand-torn cream sheet material/proportion, single bold brush word, supported tabletop placement, matching floral drawer carving and matching floral lantern all persist. Camera is recomposed, so edges/ink are not directly registered and no exact physical/pixel identity is certified. No replacement/duplication event or contradiction is visible. Treat this as a compatible static depiction of the already-kept note, not proof of stored bytes or every paper fibre. Character mask/identity is a separate design gate; static narrative PASS does not substitute for that check. N-LAMP final candidate still needs the held ratio/crop issues resolved before the whole sequence is marked complete.

## Addendum: R23 V4 and R25 V1 fresh actual output postflight

| Scene | Actual output opened | SHA-256 | Dimensions |
|---|---|---|---|
| R23 V4 | `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-a57dade5-b7ad-45cd-a072-1c0cdd2883ae.png` | `862e06705554751acb99c27ecd48b325e2f2e053cf4cdeba125e11e333fe3957` | 853×1843 RGB |
| R25 V1 | `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-3855b35a-a9e8-4e9b-a59f-c1065734a97d.png` | `fe964c070dbfab3383a3052e7dd4cec710106ac79b4007664edc5ae4b32a7da7` | 853×1843 RGB |

R23 V4 **PASS fresh story/copy/state postflight**. Exact 시스템, `여기까지 했어요. 다음에 이곳부터 이어갈 수 있어요.`, `Bis hierhin bist du gekommen. Hier kannst du nächstes Mal weitermachen.`, Weitermachen. All five companions present, with distributed attention: Sujin toward Tal, Dokkaebi toward study materials, Joy near Dokkaebi; Tal/Taego outward. Not all camera-facing or celebrating. Existing supported old book left 아/right blank, ruined stone court, no new dialogue, completed construction, gift/reward/counter. Confirmed-save scenario remains preconditioned, not proof of runtime. Canonical proportions/anatomy/Joy/entire-cast gate still needs the independent character-design verdict; V1's full-cast hold is not automatically cleared just by this story PASS.

R25 V1 **PASS story/copy/props/state**. Exact 탈선비, KO `문 하나에도 이름이 있으면 길이 되는군.`, DE `Selbst ein Tor wird zu einem Weg, wenn es einen Namen hat.`, Weiter. Four correctly spelled labels 문·방·길·마당 are already fixed on one loose plain paper route schematic held from below. No answer choices, drag prompts, score, question or permanent carved building sign. Tal addresses outward with open free hand; Sujin supports closed red book and looks toward the route direction. Unfinished timber gate work area, not a completed gate panorama or new outer monumental gate. No storm/footsteps/shadow/E04/30%/completed construction/reward. A fixed schematic result does not itself assert actual route-unlock execution, and source fallback of explanatory guide remains available. No book single-character substitution for the route-label event.

## Addendum: R27a V1 actual output postflight

Opened `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-7a2fef7d-3a36-4303-9782-6993548871f7.png`; SHA-256 `c648a6b8f70559753a9f1a859422d9cc5ae8a2f8805635d0112e8e321f14cf6e`; actual 853×1843 RGB.

**PASS story/copy/state/props**. Exact 도깨비 speaker; KO `오늘은 내가 문지기다. 누가 왔는지 들어 볼까?`; DE `Heute bin ich der Torwächter. Mal hören, wer da ist.`; Weiter. Existing Dokkaebi playfully spreads both arms in threshold, with two feet grounded. Sujin smiles toward him and supports closed red book. Club's heavy end on ground, leaning by left post, not floating while both hands are open. Generic unfinished timber threshold with no full newly completed facade. No new guard NPC, forgotten relationship, real-name demand, question/score UI, memory storm/30%, repair/reward or gate-completion mark. Depicted mainline role-play entry is compatible with manuscript's middle milestone; not evidence of actual milestone execution. R27b must preserve this gate/set-down-club continuity and reserve its praise for actual re-question/repeat path, with help path independently available.

## Final four actual postflights

Opened all four actual outputs independently. Earlier pending/hold statuses are superseded only for these exact final hashes, not for their failed predecessors.

| Scene | Actual output opened | SHA-256 | Dimensions |
|---|---|---|---|
| R24b V2 | `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-6306b6ba-7eb0-4f3b-9572-02887b73ed31.png` | `cf139e83e1fe9722a5b4d67916236bc37d6f7bab18d35de0c2bdab7eceb17b36` | 853×1843 RGB |
| R25 V2 | `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-a04133cd-4425-4e9d-b4c1-7d6632728e9a.png` | `5e1e2e55db2bc614c4ba63d5b574e2b7e5e921bdfd3d740b75002a8d08b7150f` | 853×1843 RGB |
| R26b V7 | `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-b8c231f4-8bae-4602-a74b-a6050799db22.png` | `cc6616f5287f813b0a5172b97bf10606238689b100a01cc504fe3294ce2ae5f1` | 853×1843 RGB |
| R27b V1 | `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-9c4f4042-a7bd-4635-b70e-6cf654b4052f.png` | `5c1da8e3f745a2ebf2220079fdd165c26ed2bc735bbf71bc663285a26cbd55a7` | 852×1846 RGB |

R24b V2 **PASS story/copy/state/props**. Exact 수진 label now present with full source KO/DE and Weiter. Sujin observes small empty fabric bag, Joy's beak visibly contacts rim, open interior empty; Dokkaebi surprised/reaches rather than already clutching it. Required three cast present, bird tail now fully within canvas. Same nameless old box/discovery area, no seeds/sender/Yeoni/letter/reward. This is BUILD_FINISHED/story-ready discovery, not a reward for seven completed lessons. Detailed canonical bird anatomy remains separate design gate.

R25 V2 **PASS fresh story/copy/state/props**. Same exact 탈선비/source KO/DE/Weiter, four correctly spelled fixed schematic labels, hand support, unfinished threshold, no new unlock/quiz/permanent sign/history event. Sujin's head/eyes now toward guide, strengthening shared attention; no added story event through that acting edit. Supersedes V1 as final selection without rewriting its prior bounded PASS observations.

R26b V7 **PASS fresh story/copy/state/prop continuity**. Exact 도깨비, `드디어 이 집에 다시 불이 켜지는구나!`, `Endlich brennt in diesem Haus wieder Licht!`, Weiter. One supported floral wood/hanji lantern and same floral-carved desk, open access panel exposing flame in a supported small inner lamp; no official note yet. Character attends to lamp, holds panel, other hand on desk; dark bokeh and no recognizable invented facade. Complete lamp and tabletop framing now visible. The old-wick fact is source-bound rather than pixel-certified age, with visible flame mechanism consistent with it. No reward/success or new sender clue. It supplies the missing preceding lamp-state baseline for C/D/E/F; closed panel thereafter is ordinary state continuity, not a new lamp.

R27b V1 **PASS story/copy/state/props and A→B threshold continuity**. Exact 도깨비; KO `잘 물었다. 모르면 다시 물어도 되는 거다.`; DE `Gut nachgefragt. Wenn du etwas nicht weißt, darfst du noch einmal fragen.`; CTA Zurück in den Hof. Same timber threshold, flowers/stone ground and club stably set down by left post; Dokkaebi moves to left edge with two grounded feet and open arm showing clear passage. Sujin remains familiar/smiling with supported red book. No new guard, attack/defeat/reward, key, E04 storm/30%, building completion or late latch repair. This depicts manuscript mainline after actual re-question and full repeat; image cannot prove those actions occurred, and no-assessment help branch must not reuse unearned praise.

R27b actual 852×1846 differs from internal 853×1843 baseline by about 0.28% in aspect ratio. Parent clarified baseline is not a user-mandated pixel count and accepts this near-identical generated canvas without crop/stretch. No narrative/copy defect from this size was observed; record real dimensions and never label it exact 853×1843. Native touch/spacing is still unverified.

## Aggregate 15-state story flow verdict

**PASS: 15 selected static story-state images have individually observed source/copy/state postflight, subject to independent character/design review and the limits below.** Count is 14 new state images plus 1 existing R22; bilingual KO+DE within new images does not double image counts. This is not 52-unit learning-screen coverage, all-manuscript-dialogue PNG coverage, all Season 1 ending coverage, runtime storage/build validation, user approval, native/device QA or release.

Final selected story versions: R21b V8; existing R22 V4; R23 V4; R24a V4; R24b V2; R25 V2; R26a V2; R26b V7; R26c V1; R26d V1; R26e V1; R26f V1; R26g V1; R27a V1; R27b V1. Exact paths/hashes/dimensions are in their observed postflights and machine-readable companion `STORY_AGGREGATE_20261108.json`.

Flow audit, checked against original manuscript and actual selected outputs:

1. **First-book save branch:** R21b closes name-addressing dialogue; save response owns the branch. Unconfirmed/failure → R22 retry retaining 아; confirmed → R23 C-SAVE/return/resume with companions. R22→R23 is conditional on actual confirmation, not an unconditional next-screen success. No save can reconstruct the ruined buildings.
2. **Storeroom separation:** R24a is the initial unfinished-material/label request; R24b is a later actual BUILD_FINISHED/S1-E03-ready discovery of empty bag. Lesson participation/completion and generic Weiter never manufacture BUILD_FINISHED, E03, memory percentage or rewards.
3. **Gate separation:** R25 is the BUILD_STARTED fixed guide-label result; explanatory guide does not prove real route unlock. R27 is a separately gated middle milestone, with E04/storm/30% reserved for later completion. R25→R27 is not auto-completion or a newly implemented route.
4. **Draft/wait/pause branch:** R26a preserves practice 집 while Sarangchae/story readiness is not met. Choosing stop → R26g, retaining the same separate grey practice record and incomplete environment. Resume returns to existing owner state; G is not forced after F. Neither A nor G depicts official kept note, lamp completion, forfeiture/reset or bonus.
5. **Official note branch:** only actual BUILD_FINISHED/ready permits R26b lamp → R26c same-word official note. Actual storage response selects R26d pending/retry OR R26e kept; retry retains one same note. Only confirmed E leads to R26f Tal bookmark dialogue. No storage claim is inferred from C or D, no second note/reward created, and practice/other words never overwrite the official one-word 집 note. Same floral lantern/desk and single rough cream sheet sustain narrative continuity; exact pixel/fibre identity and real storage are not claimed.
6. **Gatekeeper branch:** R27a introduces familiar Dokkaebi's role play. Mainline request/repaired hearing/full repeated `이쪽으로 오너라. / Komm hier entlang.` precedes R27b praise and stepping aside. Manuscript assistance route remains available, with independent speech unassessed and no mandatory real name/speech score/six-unit-perfect gate. Selected B is not mislabeled as universal help-route outcome.

All selected images preserve one current speaker/system state and one primary story action, with next action represented by source-bound CTA. No exercise UI, invented progress/currency/ownership or regenerated common cloud/settings/coin was observed. Failed candidates remain failed in this report. Static AI story PASS does not waive any independent character/anatomy/design failure and is never promoted to human localization or image approval.

## Final live rehash and session continuity

Final selected 15 images were rehashed from actual files after all postflights; hashes remain exactly those observed above. Machine-readable final inventory was written to `C:/dev/hangulsori/_codex_artifacts/season1-completion-20261106/review/STORY_AGGREGATE_20261108.json`, containing all 15 exact paths/hashes/dimensions, source expected/actual hashes and live Git snapshots.

At final recheck the content worktree remains clean at `e5f77c9440d8d10d74c3ae1780cc0c94897c39d1`. **All ten original manuscript/content hashes and SCOPE still match the initial exact source hashes.** Gate and exact-story manuscript requirements were not replaced with remembered summaries.

Design worktree is now clean at **`ba96c866d2e50b07d22b7de23a62f2f812b6c3eb`**, advanced by concurrent parent work from initial `0ccabfe290e0f7dad49bde0eb1c51758d13136ea`. Exactly one declared ancillary source changed: final-selection README SHA from `538db1700528a4b1732849b1b49f9f94ff39987d0ce192aa5130338b4998809d` to **`97eb8fb3f0c822682399ddf9942f461e09c300870f85465b5f11070743e3f51a`**. Read exact live Git diff: adds ten lines linking the continuation package and reporting its intermediate four-of-fifteen reviewed status; original historical November4 text remains unchanged. This is reviewed progress-document drift, **not manuscript/copy/state drift**, and was not silently claimed as hash match. Parent may subsequently publish newer completion status; that document's intermediate count is not the final observed 15-state verdict here.

This reviewer mutated only the external artifact review report/inventory/change-check outputs, not repository files. Final source and file snapshots reflect this check time; later hash changes need a new limited review rather than automatic PASS inheritance.
