# Batch 38 — persona culture scene design

> Status: authoring design for review-only draft. No live scenario/count/mastery/reward change.

## Why these five

The live corpus already defines the needed relationships:
- Maya ↔ Dongsun: shop promotion advice
- Hyuna ↔ Byeongcheol: local field-walk acquaintance
- Jun ↔ Christian: coding/gaming acquaintance
- Maya ↔ Daniel: video-project coworkers
- Hyuna ↔ Daniel: discuss how to film local places

Therefore Batch 38 adds no new relationship canon.

The batch intentionally strengthens underused personas without mechanically equalizing counts:
- Dongsun: 1 live scenario
- Byeongcheol: 1
- Jun: 1
- Maya/Hyuna/Daniel act as bridges because they already have credible work/research roles.

## Scene set

| ID | Level | Player → counterpart(s) | Real task | Culture terms |
|---|---|---|---|---|
| `b1_dongsun_norigae_shop_post` | B1 | Maya → Dongsun | agree photo/post scope and product wording | `norigae`, `maedeup` |
| `b1_byeongcheol_hwaseong_memory_check` | B1 | Hyuna → Byeongcheol | separate personal memory from verified history | `suwon_hwaseong` |
| `a2_jun_hwaseong_school_slide` | A2 | Jun → Christian | prepare a school presentation and verify sources | `suwon_hwaseong` |
| `c1_maya_hyuna_daniel_talchum_shortform` | C1 | Maya → Hyuna, Daniel | label recorded performance vs modern reinterpretation | `talchum` |
| `b2_daniel_hyuna_hanji_filming_scope` | B2 | Daniel → Hyuna | agree filming/publication boundaries for a workshop visit | `hanji` |

## Scene principles

### Dongsun
- She owns a jewelry shop; she is not rewritten as a traditional-craft master.
- The shop may carry a norigae using decorative knots.
- She explicitly distinguishes "sold here" from "made by me".
- Learning focus: permission, scope, correcting promotional wording.

### Byeongcheol
- He is not a historian.
- He reports what he personally remembers.
- Hyuna marks memory as memory and checks dates/records elsewhere.
- Learning focus: indirect speech and epistemic boundaries.

### Jun
- He remains a 16-year-old high-school student.
- The task is a normal school presentation, not a childish heritage worksheet.
- He checks dates/image sources instead of treating search results as authority.
- Learning focus: purpose and study-work repair language.

### Maya / Hyuna / Daniel
- Culture is not decorative content.
- Maya owns the communication decision, Hyuna the context caution, Daniel the filming execution.
- The trio distinguishes documented performance from newly staged material.
- Consent and attribution remain real choices.

### Daniel / Hyuna
- A workshop visit is planned, not romanticized.
- They do not explain papermaking steps on behalf of a craftsperson.
- Filming consent is not treated as blanket publication consent.
- Learning focus: precise scope and trade-offs.

## Course alignment

| Scene | Unit | Concept | Grammar |
|---|---|---|---|
| Dongsun/Norigae | `b1_03_work_softening` | `concept_b1_softening` | `grammar_b1_soft_request_batch19` |
| Byeongcheol/Hwaseong | `b1_02_indirect_speech` | `concept_b1_indirect_speech` | `grammar_b1_indirect_speech` |
| Jun/Hwaseong | `a2_06_study_work` | `concept_a2_work_study` | `grammar_a2_purpose` |
| Talchum short-form | `c1_03_media_evidence_literacy` | `concept_c1_media_evidence` | `grammar_b2_not_automatic_conclusion` |
| Hanji filming | `b2_03_precise_requests` | `concept_b2_precise_requests` | `grammar_b2_instead_tradeoff` |

## Runtime boundary

Before Jin review:
- create scenario draft
- create listening draft
- create culture-link draft
- create common review CSV with every row `draft`
- create Batch 38 manifest with `review_only_draft`
- validate and render review material
- commit/push draft artifacts

Do not:
- append to `assets/data/scenarios_*.json`
- change the live count of 186 scenarios/listening lessons
- generate or upload TTS
- add mastery/reward effects
- write culture links for non-live scenario IDs into the live registry

## Promotion requirement

When approved later, promotion should atomically stage:
1. scenario shards
2. curriculum contentLinks
3. listening lessons
4. `scenario_culture_links.json`
5. audit counts

If any part fails validation, none of the five scenes should become live.
