# Modern Korean Textbook Project — KR/EN/DE

Research snapshot: 2026-10-06
Status: **Phase 1 integrated research system**
Publishing scope: Korean 1–6, split editorially into 1A–6B, with independent English- and German-speaker pedagogy.

## North star

Build a publication-grade Korean curriculum for adults living in the 2020s:
- real contemporary Korean;
- explicit pragmatics and relationship/register logic;
- evidence-based level control;
- modern and globally relevant themes;
- independent EN and DE localization;
- print, app, audio and future reverse-direction language learning from one semantic graph.

The target is not to imitate another publisher's sequence. The target is institutional-grade curriculum, evidence, provenance, assessment and review quality with original content.

## Non-negotiable principles

1. Situation/function first; grammar supports communicative goals.
2. Korean semantic meaning is the master; EN and DE are independent native-pedagogy lanes.
3. Relationship and chronology are checked before dialogue wording.
4. Natural dialogue is written before grammar/vocabulary mining.
5. If human review changes Korean dialogue, stale mining is discarded and regenerated.
6. Core vocabulary is durable; slang/trends live in dated, reviewable capsules.
7. Research coverage never equals publication approval.
8. Display text, spoken text and performance/TTS cues are separate surfaces.
9. TTS remains Jin-owned; the content project prepares reviewed spoken surfaces only.
10. Romanization is temporary scaffolding, not the reading system.
11. Recognition must lead to retrieval, production, interaction, mediation and feedback.
12. Culture is social meaning and context, not trivia.
13. CEFR is a comparison lens, not asserted as an exact equivalence.
14. Third-party textbook structures are never copied; source/rights policy is mandatory.
15. Nothing becomes publishable before language, pedagogy, provenance and learner-pilot gates pass.

## Current canonical sources

See `SOURCE_OF_TRUTH_MAP.md`.

Most important:
- `docs/CONTENT_LEVEL_BIBLE.md` — canonical A1–C2 level authority.
- `tools/content_factory/cefr_matrix/taxonomy.json` — canonical 32-topic axis.
- `tools/content_factory/canonical_scenarios/dialogue_authoring_contract_20261006.json` — relationship-first dialogue + TTS surface contract.
- `tools/content_factory/canonical_scenarios/trilingual_native_usage_registry_20261006.json` — KO/EN/DE native-usage research registry.
- `docs/plans/2026-10-06-trilingual-native-usage-corpus.md` — 32-topic research completion protocol.
- `docs/CONTENT_SOURCE_POLICY.md` — rights / clean-room policy.

## Living Korea corpus checkpoint inherited

The textbook branch includes the 2026-10-06 Living Korea checkpoint:
- 23 scenes;
- 138 Korean dialogue turns;
- user-reviewed relationship/register direction;
- relationship-first / human-beat authoring contract;
- KO reviewed checkpoint is not automatically live;
- DE/EN are not assumed complete;
- display-only chat markers such as ㅋㅋ/ㅎㅎ are not automatically spoken;
- TTS generation remains outside content-factory ownership.

## Executable content audit

The textbook project now inventories real app/canonical learning surfaces.

Tracked total: **5,961 items**
- live scenarios: 191
- canonical authored scenarios: 120
- smalltalk lessons: 209
- listening lessons: 191
- cloze items: 2,365
- sentence-building items: 2,885

Current automatic 32-topic mapping:
- mapped: **5,634**
- unresolved/ambiguous: **327**
- sentence-building: **100% mapped**
- deduplicated manual review queue: **193 decisions**

Generated outputs:
- `data/APP_CONTENT_INVENTORY.csv`
- `data/APP_CONTENT_INVENTORY_SUMMARY.json`
- `data/MANUAL_TOPIC_REVIEW_QUEUE.csv`
- `APP_CONTENT_INVENTORY_REPORT.md`

Tooling:
- `tools/textbook_project/build_content_inventory.py`
- `tools/textbook_project/topic_alias_overrides.json`
- `tools/textbook_project/build_manual_topic_review_queue.py`
- `tools/textbook_project/test_textbook_inventory.py`

## Core project documents

- `KOREAN_CURRICULUM_1-6.md`
- `GRAMMAR_SYLLABUS.md`
- `VOCABULARY_SYLLABUS.md`
- `CURRICULUM_ALIGNMENT_1A_6B.md`
- `TRILINGUAL_NATIVE_USAGE_INTEGRATION.md`
- `SPOKEN_DISPLAY_TTS_POLICY.md`
- `TEXTBOOK_DATA_MODEL.md`
- `APP_TO_TEXTBOOK_MAPPING_PLAN.md`
- `QUALITY_GATES.md`
- `SOURCE_OF_TRUTH_MAP.md`
- `PROJECT_STATE.md`

## Next quality milestone

Do **not** jump straight to mass-writing 1A.

Next:
1. resolve the 193 deduplicated manual topic decisions;
2. run textbook KEEP / REWRITE / RELEVEL / REJECT audit;
3. split the canonical six levels into stable 1A–6B book matrices;
4. complete Tier-1 KO/EN/DE native-usage deep passes;
5. build English-L1 and German-L1 error-evidence tables;
6. then pilot one complete 1A unit family with print + audio-script + app reuse.

A pilot passes only if a learner can understand, notice, retrieve, produce, interact and transfer the target language naturally.
