# Hangul Sori culture-world roadmap

> Status: **9/9 implementation complete and approved Batch 38 canonically promoted on `session/culture-links-20261005-2026-10-05`**. The rollout preserves the existing mastery, reward, and progression authorities; this document grants none of those responsibilities.

## Goal

Connect the existing 11-person real-life dialogue world to Korean cultural material without creating a second progression system.

Core flow:

```text
human dialogue
  -> cultural context/discovery
  -> optional cultural story
  -> existing Hahoe/Dokkaebi practice where relevant
  -> existing Hanok/collection surfaces
  -> companion presentation only
```

## Non-negotiable boundaries

- Human personas remain the real-life conversation cast.
- Tiger/Magpie remain optional learning companions.
- Hahoe scholar and Dokkaebi remain cultural/practice figures, not human TTS personas.
- Culture metadata never proves CanDo mastery.
- Culture metadata never grants XP, Yeopjeon, Hanok progress, stamps, or Bojagi by itself.
- Do not create a new top-level Culture tab.
- Reuse CulturalGlossary, Scenario, Hanok, Bojagi, PracticeHistory, Smalltalk context, and Silben systems.
- Do not assign one guardian to each persona.
- Do not add new reward-pool items until reward determinism is explicitly redesigned.

## Phase 1 — scenario/culture registry ✅

Implemented:
- `assets/data/scenario_culture_links.json`
- `ScenarioCultureLinkCatalog`
- optional fail-safe repository
- scenario/term reference validation

Wire format:

```json
{
  "scenarioId": "scene_id",
  "termIds": ["term_a", "term_b"]
}
```

No copy, reward, animation, or persona logic belongs in this file.

## Phase 2 — cultural glossary expansion ✅

Add a small reviewed set before any new UI.

Priority candidates:

### Tangible
- `hahoe_mask` — 하회탈
- `norigae` — 노리개
- `maedeup` — 전통 매듭
- `buchae` — 부채
- `hanji` — 한지
- `yeopjeon` — 엽전
- `suwon_hwaseong` — 수원화성

### Intangible / practice
- `talchum` — 탈춤
- `pansori` — 판소리
- `nongak` — 농악

Requirements per term:
- KO/DE/EN
- current CulturalGlossary length limits
- at least one authoritative HTTPS source
- neutral wording; distinguish historical practice from Hangul Sori reinterpretation
- no gameplay/reward fields

## Persona-culture authoring pipeline

Use one review-only pipeline for new persona-led culture scenes:

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

Command:

```bash
python tools/content_factory/run_persona_culture_authoring.py \
  --manifest <batch_manifest> --write-derived
```

`--write-derived` may regenerate review-only sidecars/packets/reports only. It never promotes live scenarios, mastery, rewards, or vocabulary.

Required manifest links for this pipeline:
- `authoringBrief`
- `listeningDraft`
- `cultureLinksDraft`
- `vocabLevelingReview`
- `reviewPacket`
- `pipelineReport`

Promotion remains a separate explicit step through `integrate_scenario_batch.py --apply` after human review.

## Phase 3 — persona culture scenes ✅ (review-only draft; live promotion gated)

Do not equalize scene counts mechanically. Add scenes where each persona has a credible reason to be present.

Priority underused live personas:
- Minho: 1 scenario
- Dongsun: 1 scenario
- Byeongcheol: 1 scenario
- Jun: 1 scenario

Recommended first cluster:

### Dongsun × Maya
Jewelry shop / social-media task.
- norigae
- maedeup
- photo permission
- repair, wrapping, product-description language

### Byeongcheol × Hyuna
Suwon field walk.
- Suwon Hwaseong
- personal memory vs verified historical fact
- asking, qualifying, checking information

### Jun × Byeongcheol or Christian
School culture-search assignment.
- photographing/choosing/explaining one local cultural object
- youth language, planning, digital research

### Maya × Hyuna × Daniel
Living-culture production.
- performance / filming / reinterpretation
- consent, representation, original form vs modern adaptation

Minho stays primarily in social-language culture:
- work/family register
- requests, explanation vs control
- boundaries and honorific choices

## Phase 4 — scenario culture card ✅

Consume Phase 1 registry after a scenario.

Surface:
- small "Culture in this scene" card
- term title + short meaning
- opens existing CulturalGlossary sheet

Must not:
- change score
- change CanDo evidence
- grant reward
- block result navigation

Missing/malformed culture data -> omit card.

## Phase 5 — Hanok "Culture stories" ✅

Add one collection entry inside the existing Hanok area, not a new main tab.

Preferred discovery source:
- derive from already-owned/completed learning evidence + scenario culture links when possible
- avoid a new `discoveredCultureIds` storage field unless derivation is impossible or too expensive

Before implementation, audit:
- canonical scenario completion evidence
- replay semantics
- cloud restore/account switching
- retired/replaced assessment evidence

## Phase 6 — Tiger/Magpie presentation ✅

Same learning state, different presentation.

Magpie:
- discovery/news delivery motion

Tiger:
- calm acknowledgement/protection motion

None:
- plain culture card

Companion choice must never alter:
- reward
- access
- mastery
- cultural availability

## Phase 7 — Hahoe/Dokkaebi bridges ✅

Reuse current practice systems.

### Hahoe scholar
Human scenario -> pragmatic transfer.
Example:
- "How would you say the same request to a friend / parent / coworker?"

Route into existing Smalltalk context practice.

### Dokkaebi
Keep staged help:
- meaning/context
- direction/scope
- crossing/structure
- one syllable/token

Never auto-complete the answer.

Expand only after checking the current implementation for:
- Chosung
- Blitz pairs
- Satz Arcade
- Daily Challenge

## Phase 8 — culture items and existing rewards ✅

Do not immediately add new reward items.

First reuse existing glossary-linked decorations:
- gat -> `decoration_gat_buchae`
- munbangsau -> `decoration_munbangsau`
- soban -> `decoration_soban`
- jagae_mungap -> `decoration_jagae_mungap`

New Norigae/Maedeup decorations require a separate reward-pool versioning/determinism design before entering Bojagi.

## Phase 9 — culture story arcs ✅

Only after Phases 2–7 are stable.

Example mini-arc: "Found around Nammun"
- Dongsun: norigae/maedeup
- Byeongcheol: local built heritage
- Hyuna: documentation/context
- Jun: school assignment
- Maya: modern presentation

A story arc groups existing scenario/practice/culture surfaces. It is not a new mastery denominator.

## PR order

1. Scenario culture-link infrastructure ✅
2. CulturalGlossary expansion ✅
3. Persona culture scenes ✅
4. Scenario culture card ✅
5. Hanok culture-stories collection ✅
6. Companion presentation reactions ✅
7. Hahoe/Dokkaebi bridges ✅
8. Reward/item reuse + contract audit ✅
9. Culture story arcs ✅

All nine planned rollout stages are complete on the rollout branch. Batch 38 is approved and promoted; no culture-world implementation gate remains in this plan.

## Implementation rule

Prefer the smallest existing owner:
- meaning/story/source -> CulturalGlossary
- scenario relation -> ScenarioCultureLinkCatalog
- dialogue -> Scenario
- pragmatic transfer -> Smalltalk context
- hint behavior -> existing game/practice layer
- practice history -> PracticeHistory
- permanent learning proof -> CanDoSegment authority only
- decoration ownership -> DecorationRewardService
- companion identity/visibility -> MascotPreference

Do not duplicate these responsibilities in a new "culture system".
