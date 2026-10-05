# Culture-world rollout progress — 2026-10-05

> Branch: `session/culture-links-20261005-2026-10-05`
> Scope: 11-person persona world + Korean cultural context + existing guardian/practice systems.
> Important: implementation progress and live learner exposure are tracked separately.

## Current position against the original roadmap

| Phase | Original goal | Implementation status | Live learner status | Key evidence |
|---|---|---|---|---|
| 1 | Scenario ↔ culture registry | **Complete** | **Live on this rollout branch** | `ScenarioCultureLinkCatalog`, fail-safe repository, reference validation |
| 2 | CulturalGlossary expansion | **Complete** | **Live on this rollout branch** | glossary 23 → 33 entries, KO/DE/EN + authoritative sources |
| 3 | Persona culture scenes | **Complete + promoted** | **Live; runtime corpus = 191 scenarios** | Batch 38: 5 scenarios, 5 listening lessons, 20 listening questions, 5 culture links |
| 4 | Scenario result culture card | **Complete** | **Live metadata available** | optional result card backed only by live `scenario_culture_links.json` |
| 5 | Hanok “Culture stories” collection | **Complete** | **Live derived discovery surface** | read-only discovery projection from existing scenario-completion evidence; no new culture ledger |
| 6 | Tiger/Magpie presentation reactions | **Complete** | **Live presentation path** | canonical companion preference changes framing/motion only; cultural availability is identical |
| 7 | Hahoe/Dokkaebi bridges | **Complete** | **Live bridge path**; existing Hahoe/Dokkaebi practice remains the authority | scenario result routes into level-matched Smalltalk; staged Dokkaebi help is reused unchanged |
| 8 | Culture items / reward reuse | **Complete by reuse + contract audit** | Existing reward surfaces live; no new reward item added | four glossary-linked decorations stay in deterministic v1 pool; Norigae/Maedeup remain out |
| 9 | Culture story arcs | **Complete + promoted** | **`Found around Nammun` live** | read-only arc model/repository + derived completion projection; no mastery denominator |

## Completed implementation

### Phase 1 — scenario culture-link infrastructure

Added:
- `assets/data/scenario_culture_links.json`
- `lib/models/scenario_culture_link.dart`
- `lib/services/scenario_culture_link_repository.dart`
- parser/duplicate/reference validation tests

Contract:
- only `scenarioId + termIds[]`
- read-only presentation metadata
- malformed/missing culture data never blocks learning
- no XP / mastery / Yeopjeon / Bojagi / Hanok progression authority

Commit:
- `78895f69d feat(culture): add scenario culture link registry`

### Phase 2 — CulturalGlossary expansion

Added 10 reviewed terms:
- `hahoe_mask` — 하회탈
- `norigae` — 노리개
- `maedeup` — 매듭
- `buchae` — 부채
- `hanji` — 한지
- `yeopjeon` — 엽전
- `suwon_hwaseong` — 수원화성
- `talchum` — 탈춤
- `pansori` — 판소리
- `nongak` — 농악

Each entry has KO/DE/EN, romanization, concise meaning/story, HTTPS source.

Commit:
- `8b8d6eebb feat(culture): expand cultural glossary`

## Persona-world refinement

Six personas were deepened to support culture scenes without turning them into “culture exposition NPCs”:

- **Maya**: K-pop → K-pop + cultural-content marketing; representation/reinterpretation responsibility.
- **Hyuna**: urban/culture research → urban memory, local culture, living heritage; memory vs verified evidence.
- **Daniel**: freelance video → documentary/brand video; filming consent vs publication scope.
- **Dongsun**: Suwon Nammun jewelry/repair shop; some norigae/knot items; never auto-cast as a traditional craft master.
- **Byeongcheol**: local field-walk / structure / material perspective; not a historian.
- **Jun**: 16-year-old high-school student; presentations, sources, digital making remain age-appropriate.

Runtime `PersonaPresentation` copy and writer-bible relationships were synchronized.

Commit:
- `6aa3a83e2 feat(personas): deepen culture-focused profiles`

## Phase 3 — Batch 38 persona culture scenes (promoted)

Five authored scenes:

1. `b1_dongsun_norigae_shop_post`
   - Maya × Dongsun
   - norigae + maedeup
   - permission, photo scope, promotional wording, maker attribution

2. `b1_byeongcheol_hwaseong_memory_check`
   - Hyuna × Byeongcheol
   - Suwon Hwaseong
   - personal memory vs verified historical record

3. `a2_jun_hwaseong_school_slide`
   - Jun × Christian
   - Suwon Hwaseong
   - school presentation, photo order, source/date checking

4. `c1_maya_hyuna_daniel_talchum_shortform`
   - Maya × Hyuna × Daniel
   - talchum
   - performance documentation vs modern reinterpretation + consent

5. `b2_daniel_hyuna_hanji_filming_scope`
   - Daniel × Hyuna
   - hanji
   - filming scope, publication scope, caption/description review

Draft bundle includes:
- 5 scenario drafts
- 15 scenario quests
- 5 listening lessons
- 20 listening questions
- 5 culture links
- common review ledger
- complete review packet

The scenario integration transaction was extended so approved promotion can atomically stage:
- scenario shards
- curriculum links
- listening lessons
- culture links
- audit counts

Batch 38 was subsequently approved by the user and promoted atomically; all five scenarios are now live on this rollout branch.

Commit:
- `9d4d2a4e9 feat(culture): draft persona culture scenes`

## Key-vocabulary leveling

Reusable tool:
- `tools/content_factory/extract_scenario_key_vocab.py`

For each authored `vocab[].korean`, records:
- CEFR lexical judgment
- exact live-vocab matches
- culture anchor status
- phrase status
- target-level mismatch flags
- recommended review action

Classifications:
- `culture_anchor`
- `at_or_below_target`
- `above_target`
- `unmapped_candidate`
- `phrase_candidate`

Batch 38 final editorial result after pre-approval refinement:
- 30 key items
- 6 culture anchors
- 24 at/below target
- **0 above-target review items**
- **0 unmapped**
- 5 phrase candidates

The final pass simplified avoidable high-level general vocabulary in the B1/A2/B2 scenes while preserving each real-life task and culture anchor. In particular, the A2 Jun scene now carries `suwon_hwaseong` as an explicit glossary-backed culture anchor instead of treating higher-level editorial terms such as `출처` and `연도` as learner key vocabulary.

Important rule:
- high-frequency/low-frequency lexical grade does not automatically move a scenario level.
- a culture-specific term may stay when it is a direct scene anchor with immediate glossary support.
- no automatic live-vocab mutation.

Commit:
- `480c24d1c feat(content): add scenario vocab leveling review`

## Reusable persona-culture authoring pipeline

Command:

```bash
python tools/content_factory/run_persona_culture_authoring.py \
  --manifest <batch_manifest> --write-derived
```

Pipeline:

```text
persona writer bible
  -> structured authoring brief
  -> scenario + listening draft
  -> key vocab extraction
  -> CEFR/live-vocab audit
  -> CulturalGlossary + culture-link validation
  -> full integration preview
  -> human review packet
```

`--write-derived` regenerates derived audit/review artifacts only. It never promotes live content. The same pipeline now accepts `review_only_draft`, `approved`, and `merged` manifests so a promoted batch can be re-audited reproducibly without touching learner-facing assets.

Batch 38 now has:
- `authoringBrief`
- `listeningDraft`
- `cultureLinksDraft`
- `vocabLevelingReview`
- `reviewPacket`
- `pipelineReport`

The pipeline rejects:
- undeclared persona relationships
- brief/scenario person drift
- brief/culture-link drift
- unknown glossary terms
- listening evidence not grounded in dialogue
- stale derived review artifacts
- failed full scenario integration preview

Commit:
- `47b2ef0fc feat(content): add persona culture authoring pipeline`

## Phase 4 — scenario culture result card

Implemented an optional culture surface in the scenario result flow:
- reads only `ScenarioCultureLinkRepository` + `CulturalGlossaryRepository`
- shows linked cultural terms only when valid live metadata exists
- opens the existing CulturalGlossary story sheet
- missing or malformed optional culture data fails closed by omitting the card
- no score, CanDo, XP, Yeopjeon, Bojagi, Hanok, or navigation authority

The UI still fails closed when optional culture metadata is absent. After Batch 38 promotion, its five live scenario links resolve through this same path without changing score, mastery, or rewards.

Commit:
- `aa7674b03 feat(culture): show scenario culture result card`

## Phase 5 — Hanok Culture Stories

Added one collection entry inside the existing Hanok area and a dedicated Culture Stories screen.

Discovery contract:
- no `discoveredCultureIds` or second culture-progress ledger
- derives terms from current-generation `Storage.completedScenarios`
- unions available course-mastery `scenarioCheckpoints` as cloud-restorable supporting evidence
- intersects only with the live scenario/culture registry and CulturalGlossary
- deduplicates terms and preserves stable glossary order
- missing optional catalogs fail closed
- returning to the long-lived Hanok tab refreshes the derived count

Important recovery limit:
- `scenarioCheckpoints` are capped **attempt history**, not a permanent set of unique completed scenarios.
- heavy replay can evict an older unique scenario from restored checkpoint history even while the live scenario catalog is smaller than the checkpoint cap.
- therefore Culture Stories is a supplementary discovery view, **not** permanent mastery proof and **not** a guaranteed complete cross-device archive.
- the local current-generation completion mirror remains the strongest on-device source; no new persistence field was introduced just to hide this limitation.

Commit:
- `810e37f93 feat(culture): add Hanok culture stories collection`

## Phase 6 — Tiger/Magpie culture presentation

The scenario result culture card now reuses the canonical `MascotPreference.preference` owner through `CompanionBuilder`; it introduces no companion or culture state of its own.

Presentation contract:
- no companion selected => the original plain culture-card header
- Joy / Magpie => discovery/news-delivery framing, one-shot entrance plus the existing reduce-motion-aware magpie idle motion
- Taego / Tiger => calm acknowledgement/protection framing with a slower one-shot settle; the canonical tiger asset remains static
- the same resolved CulturalGlossary entries remain available in all three variants
- companion choice never changes term discovery, score, CanDo evidence, rewards, Hanok progression, access, or persistence
- mascot art is decorative in this card; localized reaction copy carries the meaning for accessibility

Commit:
- `c0c983bf6 feat(culture): personalize culture card companion presentation`

## Phase 7 — Hahoe/Dokkaebi bridges

Added a presentation/navigation bridge from a completed culture-linked scenario into the existing Smalltalk context practice. The result card passes only the scenario CEFR level, so the existing Smalltalk catalog remains the owner of cases, attempts, transfer practice, and persistence.

Hahoe contract:
- the culture card offers a Hahoe-scholar pragmatic-transfer CTA only when the optional culture card itself resolves
- the CTA routes to `/smalltalk/context` with the current scenario level
- no scenario result is rewritten and no Smalltalk attempt is pre-completed
- Smalltalk practice continues to own its own history/evidence

Dokkaebi audit:
- `SilbenHelpState` already provides staged help without mutating the solution or tile pool
- stage 1 = meaning/path/context, stage 2 = crossing structure, stage 3 = one syllable
- the learner still places the tile; help never auto-completes the answer
- existing `PracticeDokkaebiHelp` / `PracticeDokkaebiStage` remain the presentation owner
- no parallel culture-specific hint engine or ledger was added

Commit:
- `9ea81e139 feat(culture): bridge scenario culture into pragmatic practice`

## Validation baseline

Latest focused validation at the Phase 7 checkpoint:
- persona-culture/content Python regressions: **39 passed**
- `validate_content.py`: **passed**
- Batch 38 integration preview: **passed**
  - scenario preview: 186 → 191
  - scenario quests: 579 → 594
- Phase 4/5 culture + Hanok focused Flutter tests: **40 passed**
- Phase 6 culture-card/companion/scenario-player regression suite: **50 passed**
- Phase 6 culture-card focused suite: **8 passed**
  - none / Magpie / Tiger keep identical culture terms
  - canonical companion notifier updates presentation reactively
  - no progress/reward/storage dependency is introduced
- Phase 7 culture-card bridge suite: **9 passed**
  - level-matched Smalltalk request is routed through the existing `/smalltalk/context` owner
  - bridge carries no case completion or transfer state of its own
  - 320dp phone at 200% text scale has no layout exception with the new CTA
- Phase 7 Smalltalk + Dokkaebi-help regressions: **10 passed**
  - staged Silben help does not mutate solution/tile pool
  - Smalltalk interaction, accessibility, retry, and persistence boundaries remain intact
- targeted Dart analysis: **0 issues**
- non-generated `git diff --check`: **passed**
- At this historical Phase 7 checkpoint the live learner corpus was **186**; Batch 38 was promoted later after explicit approval and final editorial/level-fit review.

## Phase 8 — culture items / existing reward reuse

The planned Phase 8 behavior was already present in the existing owners, so no production reward code was added. The phase was completed as an ownership audit plus regression lock.

Verified reuse:
- `gat` -> `decoration_gat_buchae`
- `munbangsau` -> `decoration_munbangsau`
- `soban` -> `decoration_soban`
- `jagae_mungap` -> `decoration_jagae_mungap`

Ownership contract:
- all four slugs remain in the existing ordered `kDecorationRewardPool` v1
- CulturalGlossary remains the only meaning/story/source mapping owner
- `CulturalDecorationHelpButton` reuses those links after Bojagi reveal and on room-decoration surfaces
- culture UI never grants ownership; `DecorationRewardService` remains the only reward owner
- `norigae` and `maedeup` still have no decoration slug and no reward-pool entry
- therefore no pool insertion/reordering/versioning change was introduced

Validation:
- Phase 8 culture/reward regression bundle: **61 passed**
- targeted Dart analysis: **0 issues**
- explicit tests lock both the four existing mappings and the Norigae/Maedeup exclusion

Commit:
- `7c9ba165b test(culture): lock existing reward reuse contract`

## Phase 9 — culture story arcs

Implemented the final roadmap layer as read-only grouping metadata, without introducing a second progress system.

Added:
- `assets/data/culture_story_arcs.json` — live catalog; initially empty during review, now contains promoted `found_around_nammun`
- `lib/models/culture_story_arc.dart`
- `lib/services/culture_story_arc_repository.dart`
- derived arc projection inside `CultureDiscoveryService`
- optional arc cards inside the existing Hanok Culture Stories collection
- review-only `persona_culture_story_arcs_20261005.json` with the first candidate, `Found around Nammun`
- authoring-pipeline validation + review-packet rendering for story arcs

Safety/ownership contract:
- `progressMode` must be `derived_read_only`
- arc completion is calculated only from existing scenario completion evidence
- no story-arc progress key, mastery denominator, XP source, reward grant, inventory, or ledger exists
- an arc is projected only when every referenced scenario and cultural term already exists in the live registry/glossary
- review-only data could not leak into learner UI before explicit promotion
- after user approval, `found_around_nammun` was promoted through the same scenario/listening/culture-link rollback boundary and is now the single live culture-story arc

Validation:
- persona-culture/content Python regressions: **42 passed**
- `validate_content.py`: **passed**
- pre-promotion Batch 38 review-only pipeline: **PASS**
- Phase 9 + culture regressions: **43 passed**
- targeted Dart analysis: **0 issues**
- `git diff --check`: **passed**
- scenario promotion integrator stages culture story arcs in the **same rollback boundary** as scenario shards, curriculum links, listening, culture links, and audit metadata
- arc promotion rejects non-live scenario references, terms not linked to the staged scenario, duplicate/frozen payload drift, and any progress mode other than `derived_read_only`
- integration transaction regressions: **15 passed**
- pre-promotion Batch 38 full promotion preview with arcs: **passed**; the later approved transaction promoted the same frozen payload

Commits:
- `b574050b6 feat(culture): add derived culture story arcs`
- `11afef94f fix(culture): promote story arcs atomically`

## Batch 38 final pre-approval editorial pass

The five review-only persona-culture scenes were re-read as learner-facing conversations rather than accepted merely because the structural pipeline passed.

Editorial adjustments:
- B1 Dongsun/Maya: simplified avoidable high-level general vocabulary around display/account/copy while preserving norigae + maedeup and the permission/attribution task.
- B1 Byeongcheol/Hyuna: simplified note-taking and quietness wording while preserving the personal-memory vs verified-information distinction.
- A2 Jun/Christian: removed the learner-keyword burden of `출처`, `연도`, `발표`, and `슬라이드`; retained the natural school task and made `수원화성` an explicit culture anchor.
- B2 Daniel/Hyuna: learner-facing Korean now uses `작업실` instead of relying on the C2-graded `공방` headword while preserving the hanji filming/publication-consent task.
- C1 talchum scene required no level simplification.

Final pre-approval evidence:
- persona-culture regression bundle: **45 / 45 passed**
- `validate_content.py`: **passed**
- review-only authoring pipeline: **PASS**
- integration promotion preview: **passed**
  - scenarios: 186 → 191
  - scenario quests: 579 → 594
- key vocabulary: **30 total / 6 culture anchors / 24 at-or-below target / 0 above target / 0 unmapped**

Commits:
- `dd523fe5b content(culture): refine batch 38 level fit`
- `9ced4505e fix(culture): sync batch 38 review copy` — aligns grammar/quest copy with the final simplified dialogue before human approval.

## Batch 38 canonical promotion — complete

The user explicitly approved the full Batch 38 bundle for canonical/live promotion after reviewing the dialogue quality and authorizing the remaining scenes as a group. Approval provenance records the authority and date without claiming native-speaker QA.

Promoted in one transaction:
- 5 scenarios and their 15 scenario quests
- 5 listening lessons / 20 listening questions
- 5 scenario-culture links
- curriculum links and content-audit counts
- the `found_around_nammun` read-only culture story arc
- canonical shelf assignments for all five scenes

Live state on this rollout branch:
- scenario corpus: **191**
- scenario quests: **594**
- Batch 38 audit: **5 / 5 `live_verified_modern`**
- all five review-ledger rows: **approved**
- Batch 38 manifest: **merged**
- live culture-story arcs: **1** (`found_around_nammun`)

Final multidimensional level-fit audit:
- evidence: `tools/content_factory/review/persona_culture_level_fit_judgments_20261005.json`
- every scene passed task complexity, register/relationship, distractor difficulty, listening burden, and culture-exception review
- key vocabulary: **30 / 6 culture anchors / 24 at-or-below target / 0 above target / 0 unmapped**
- merged authoring audit: **MERGED_AUDIT_PASS**
- no native-speaker QA claim is made by this approval record

Post-promotion validation:
- Python / content / CEFR regression bundle: **247 / 247 passed**
- `validate_content.py`: **passed**
- all-Batch live-promotion audit: **passed**; Batch 38 = **5 / 5 live**
- targeted Dart analysis: **0 issues**
- culture UI / discovery / arc regressions: **43 / 43 passed**

The global level audit was regenerated for the 191-scenario corpus. One unrelated historical B2 vocabulary ratchet regression surfaced (`회의 정족수`, audited as C2); it was repaired as learner-facing `참석자` with synchronized vocab/cloze/sentence content. The canonical fallback-over2 vocab cap returned to **66** rather than being relaxed.

Commits:
- `080f6b036 feat(culture): promote batch 38 canonically`
- `376b88799 content(levels): align civic meeting vocabulary with B2`

## Roadmap implementation status

The original nine-phase culture-world roadmap is **9 / 9 implemented and the approved Batch 38 content is canonically promoted on this rollout branch**. There is no remaining culture-world implementation or live-exposure gate in this roadmap. Existing cross-project gates such as device QA, broader level-normalization backlog, release operations, or other independently scoped programs remain owned by their own plans.
