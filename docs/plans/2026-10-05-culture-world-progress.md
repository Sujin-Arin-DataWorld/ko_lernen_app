# Culture-world rollout progress — 2026-10-05

> Branch: `session/culture-links-20261005-2026-10-05`
> Scope: 11-person persona world + Korean cultural context + existing guardian/practice systems.
> Important: implementation progress and live learner exposure are tracked separately.

## Current position against the original roadmap

| Phase | Original goal | Implementation status | Live learner status | Key evidence |
|---|---|---|---|---|
| 1 | Scenario ↔ culture registry | **Complete** | Not merged to main yet | `ScenarioCultureLinkCatalog`, fail-safe repository, reference validation |
| 2 | CulturalGlossary expansion | **Complete** | Not merged to main yet | glossary 23 → 33 entries, KO/DE/EN + authoritative sources |
| 3 | Persona culture scenes | **Draft complete / review-only** | **Not live**; runtime corpus remains 186 scenarios | Batch 38: 5 scenarios, 5 listening lessons, 20 listening questions, 5 culture links |
| 4 | Scenario result culture card | **Complete** | Not merged to main yet; live registry may still be empty | optional result card backed only by live `scenario_culture_links.json` |
| 5 | Hanok “Culture stories” collection | **Complete** | Not merged to main yet | read-only discovery projection from existing scenario-completion evidence; no new culture ledger |
| 6 | Tiger/Magpie presentation reactions | **Complete** | Not merged to main yet | canonical companion preference changes framing/motion only; cultural availability is identical |
| 7 | Hahoe/Dokkaebi bridges | **Next implementation target** | Existing Hahoe/Dokkaebi practice already live; new bridge not live | reuse Smalltalk context + staged Dokkaebi help |
| 8 | Culture items / reward reuse | Not started | Not started | must preserve reward determinism |
| 9 | Culture story arcs | Not started | Not started | later grouping layer, not mastery |

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

## Phase 3 — Batch 38 review-only culture scenes

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

No Batch 38 scenario is live yet.

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

Batch 38 result:
- 30 key items
- 5 culture anchors
- 15 at/below target
- 10 above-target review items
- 0 unmapped
- 5 phrase candidates

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

`--write-derived` regenerates review-only artifacts only. It does not promote live content.

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

The live registry can remain empty safely, so this UI does not promote Batch 38.

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

## Validation baseline

Latest focused validation at the Phase 6 checkpoint:
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
  - 320dp phone at 200% text scale has no layout exception
- targeted Dart analysis: **0 issues**
- non-generated `git diff --check`: **passed**
- live learner corpus remains **186** because Batch 38 is still review-only.

## Next implementation target — Phase 7

Bridge existing Hahoe and Dokkaebi practice systems back to the culture/scenario world without creating parallel learning state.

Constraints:
- reuse the existing Smalltalk/pragmatics context for Hahoe-style register transfer
- reuse the existing staged Dokkaebi help/practice path rather than inventing a culture-specific hint engine
- bridges are contextual/navigation/presentation only unless an existing practice system already owns evidence
- no new mastery, reward, culture-discovery, or companion ledger
- failures in optional culture metadata must not block the underlying practice route
- Batch 38 remains review-only until separate human approval/promotion
