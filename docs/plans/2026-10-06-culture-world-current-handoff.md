# Culture world current handoff — 2026-10-06

> Branch: `session/culture-links-20261005-2026-10-05`
> Current canonical promotion commit when this handoff was updated: `af9aa295b`
> Read this file first for current culture-world status. Historical detail remains in the linked plans.

## Current verdict

The original culture-world rollout is **complete: 9/9 phases**.

Post-rollout quality work is also complete:
- Stage A — derived culture-story arc expansion: **complete**
- Stage B — durable cross-device culture discovery: **complete**
- Stage C — app-wide Level Canonicalization Program: **complete**

The culture system is no longer a prototype/review-only architecture. Batch 38 and Batch 39 were both explicitly reviewed, approved, and canonically promoted.

## Live/canonical state

- live scenarios: **196**
- live scenario quests: **609**
- Batch 38 persona-culture scenarios: **5/5 promoted**
- Batch 39 persona-culture scenarios: **5/5 promoted**
- persona-culture listening added across Batch 38+39: **10 lessons / 40 listening questions**
- live scenario-culture links: **10**
- CulturalGlossary: **33 reviewed entries**
- live culture-story arcs: **5**
  - `found_around_nammun`
  - `made_by_hand_in_korea`
  - `memory_to_record`
  - `culture_in_everyday_use`
  - `performance_first_encounter`
- culture discovery stays **derived read-only**
- no culture-owned mastery, XP, Yeopjeon, Bojagi, Hanok progression, or reward ledger exists
- cross-device discovery durability reuses `completedScenarios` + `scenario_corpus_generation`
- Tiger/Magpie remain presentation-only companions
- Hahoe scholar reuses Smalltalk pragmatic transfer
- Dokkaebi reuses staged help; it never auto-solves
- existing reward items are reused; Norigae/Maedeup were not inserted into the deterministic reward pool

## Original roadmap status

| Phase | Result |
| --- | --- |
| 1. Scenario ↔ culture registry | ✅ complete/live |
| 2. CulturalGlossary expansion | ✅ complete/live |
| 3. Persona culture scenes | ✅ complete/promoted |
| 4. Scenario-result culture card | ✅ complete/live |
| 5. Hanok Culture Stories | ✅ complete/live |
| 6. Tiger/Magpie culture presentation | ✅ complete/live |
| 7. Hahoe/Dokkaebi bridges | ✅ complete/live |
| 8. Existing reward/item reuse contract | ✅ complete/locked |
| 9. Culture story arcs | ✅ complete/live |

## Persona/culture authoring contract

New culture content must continue through the existing pipeline:

```text
persona writer bible
  -> culture situation / authoring brief
  -> natural scenario dialogue + listening
  -> key-vocab extraction
  -> CEFR/live-vocab audit
  -> CulturalGlossary support
  -> scenario-culture links
  -> full integration preview
  -> human review / promotion
```

Primary command:

```bash
python tools/content_factory/run_persona_culture_authoring.py \
  --manifest <batch_manifest> --write-derived
```

Key rules:
- write natural dialogue first; do not write to a vocabulary quota
- extract only genuinely important learner words/phrases after the dialogue exists
- high raw lexical grade does not automatically promote a scenario
- culture-specific anchor terms may remain with immediate glossary support
- ordinary above-target vocabulary must be simplified, relevelled, or explicitly reviewed
- no automatic live-vocab mutation
- persona relationships in a scene must already exist in the writer bible
- culture links must point only to reviewed glossary terms
- TTS remains Jin-owned in VS Code; do not auto-generate/overwrite it

## Batch 38 reference set

Promoted scenes:
- `b1_dongsun_norigae_shop_post`
- `b1_byeongcheol_hwaseong_memory_check`
- `a2_jun_hwaseong_school_slide`
- `c1_maya_hyuna_daniel_talchum_shortform`
- `b2_daniel_hyuna_hanji_filming_scope`

Primary files:
- `tools/content_factory/drafts/batch_38_persona_culture_manifest.json`
- `tools/content_factory/drafts/persona_culture_authoring_brief_20261005.json`
- `tools/content_factory/review/batch_38_persona_culture_review_packet.md`
- `tools/content_factory/review/persona_culture_level_fit_judgments_20261005.json`
- `tools/content_factory/review/persona_culture_authoring_pipeline_20261005.json`

## Quality-program closure

Stage A:
- expanded read-only arcs to 3 live arcs

Stage B:
- no culture-specific persistence ledger
- cross-device durability fixed at the canonical scenario-completion owner

Stage C:
- six-grade coverage ratchets active
- high-confidence +2-or-more debt: **0**
- low-confidence fallback +2-or-more debt: **0**
- historical replacement backlog: **0**
- audit-level unknown: **0** for audited content kinds
- residual sentence-token unknown is below the program's 2% exit threshold and is optional morphology/segmentation quality work, not open canonicalization debt

Detailed source:
- `docs/plans/2026-10-05-culture-quality-followups.md`

## What is not part of the canonical branch yet

Other branches/PR history contains additional **Living Korea / contemporary-culture** experiments and review sets. Do not assume those are current-branch canon merely because they appear in `git log --all`.

Before using them:
1. identify the exact branch/PR,
2. compare its base with this branch,
3. re-run the persona-culture authoring/level contracts,
4. promote only through an explicit reviewed integration.

## Recommended next content work

The infrastructure and quality program are closed. Next work should be **content expansion**, not another culture subsystem.

Preferred next batch:
1. activate remaining underused relationship/culture routes without forcing every persona into traditional heritage;
2. author 4–6 new scene-first episodes;
3. prioritize:
   - Minho: workplace/family social-language culture and pragmatic transfer
   - Andrea: formality, responsibility, family/work boundaries
   - Lena: everyday market/craft/exhibition use and gift/social-context questions
   - Dongsun/Byeongcheol/Jun: second episodes only where they add a different task, not repetition
4. reuse existing glossary terms first; add a new cultural term only when the scene genuinely needs it;
5. extract key vocabulary after dialogue and run the CEFR sidecar before promotion.

Do **not** reopen the completed 9-phase architecture unless a concrete defect is found.

## Batch 39 expansion — promoted/live

Batch 39 was fully reviewed in chat and then canonically promoted.

Draft commit:
- `91ab4eda8 feat(culture): draft batch 39 persona scenes`

Promotion commit:
- `af9aa295b feat(culture): promote batch 39 canonically`

Final status:
- manifest: `merged`
- review ledger: **5/5 approved**
- live corpus: **196 scenarios / 609 scenario quests**
- 5 Batch 39 listening lessons / 20 listening questions
- 5 additional scenario-culture links
- 2 additional live derived story arcs
- key vocab: **30 total / 6 culture anchors / 24 at-or-below target / 0 above-target / 0 unmapped**
- Python/content regression bundle: **51/51 passed**
- Flutter culture/story/scenario regression bundle: **37/37 passed**
- `validate_content.py`: **passed**
- TTS: not generated; Jin remains the owner of TTS work

Promoted scenes:
- `a2_andrea_minho_bojagi_housewarming` — Andrea × Minho — `bojagi`
  - natural housewarming-gift reaction; bojagi is wrapping, not a forced exposition object
- `b1_minho_christian_hanok_cafe_meeting` — Christian × Minho + existing `server` support role — `hanok`, `madang`
  - learner directly asks: `혹시 여기 콘센트 쓸 수 있는 자리 있을까요?`
- `a2_lena_maya_buchae_gift_choice` — Lena × Maya — `buchae`
  - practical gift choice and personal preference
- `b2_maya_daniel_pansori_promo_clip` — Maya × Daniel — `pansori`
  - final copy is a fun post-performance reaction: voice power, gosu, chueimsae, audience participation, plot, and another-performance plan
- `b2_hyuna_daniel_nongak_festival_filming` — Daniel × Hyuna — `nongak`
  - final copy is relationship-driven: Daniel knows nongak, wants to learn janggu, Hyuna uses `-대요` for regional variation, and they plan another outing

New live derived arcs:
- `culture_in_everyday_use`
- `performance_first_encounter`

Editorial lesson from Batch 39:
- **natural Korean comes first; CEFR auditing follows**
- do not distort a normal learner sentence merely to lower a lexical estimate
- a natural but non-key word such as `콘센트` may remain in dialogue without becoming an explicit key-vocab target
- culture scenes should start from experience/task/curiosity, not exposition
- performance culture works especially well as: `see/watch -> react -> ask -> brief explanation -> next action`

Authoring-pipeline follow-up:
- review briefs may declare existing generic `supportRoleIds` such as `server` in addition to recurring `personaIds`
- support roles must already exist in the live scenario corpus and do not create persona relationships
- Windows promotion has a staged/validated fsync fallback when an editor watcher blocks `os.replace` with WinError 5; exact originals remain available for rollback and final content validation still runs

## Required reading for the next session

1. `AGENTS.md`
2. this file
3. `docs/plans/2026-10-05-culture-world-progress.md`
4. `docs/plans/2026-10-05-culture-quality-followups.md`
5. `docs/plans/2026-10-05-culture-world-roadmap.md`
6. Graphify query for the concrete task

## Graphify handoff rule

After meaningful changes:
- run `graphify update .`
- commit the small tracked Graphify outputs required by repository policy
- do not commit `graph.json`, `graph.html`, dated snapshots, or disposable AST cache
- use commit/PR history for chronology; Graphify represents current structure
