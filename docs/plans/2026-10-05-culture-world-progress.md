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
| 4 | Scenario result culture card | **Next implementation target** | Not started | consume live `scenario_culture_links.json` after scenario completion |
| 5 | Hanok “Culture stories” collection | Not started | Not started | derive discovery from existing completion evidence if possible |
| 6 | Tiger/Magpie presentation reactions | Not started | Not started | same state/reward; presentation only |
| 7 | Hahoe/Dokkaebi bridges | Existing systems audited; new bridge work not started | Existing Hahoe/Dokkaebi practice already live | reuse Smalltalk context + staged Dokkaebi help |
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

## Validation baseline

Latest focused validation before this handoff:
- persona-culture/content Python regressions: **39 passed**
- earlier persona/catalog Flutter regressions: **13 passed**
- `validate_content.py`: **passed**
- Batch 38 integration preview: **passed**
  - scenario preview: 186 → 191
  - scenario quests: 579 → 594
- live learner corpus remains **186** because Batch 38 is review-only.

## Next implementation target — Phase 4

Implement the optional “이 장면에서 만난 문화 / Culture in this scene” surface after scenario completion.

Constraints:
- consume only the live `ScenarioCultureLinkRepository`
- open the existing CulturalGlossary presentation/sheet
- missing/malformed culture data => omit UI
- no score change
- no CanDo evidence change
- no XP / Yeopjeon / Bojagi / Hanok progression
- no new top-level Culture tab
- must work even while the live registry is empty
- Batch 38 remains review-only until separate human approval/promotion

After Phase 4:
1. audit completion evidence for Phase 5 Hanok Culture Stories
2. derive discovery from existing completion evidence if safe
3. then add Tiger/Magpie presentation-only reactions
