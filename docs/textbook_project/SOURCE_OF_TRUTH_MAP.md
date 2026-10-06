# Textbook Project — Source of Truth Map

Date: 2026-10-06

The textbook layer must reuse Hangul Sori canonical research instead of creating parallel copies that drift.

## Curriculum / level SSoT
- `docs/CONTENT_LEVEL_BIBLE.md` — canonical A1–C2 level profiles, grammar ceilings, sentence limits, register, pronunciation and culture.
- `docs/data/korean_learning_phases_part8_master_matrix.md` — learning-phase master cross-map.
- `docs/data/cefr_curriculum_matrix.md` — current app curriculum matrix.
- `docs/B2_C2_2026_HOT_TOPICS_CONTENT_TRACK.md` — contemporary advanced-topic track.

## Language / dialogue SSoT
- `tools/content_factory/canonical_scenarios/dialogue_authoring_contract_20261006.json` — relationship-first dialogue and display/spoken surface contract.
- `tools/content_factory/canonical_scenarios/trilingual_native_usage_registry_20261006.json` — 32-topic KO/EN/DE native-usage research registry.
- `docs/plans/2026-10-06-trilingual-native-usage-corpus.md` — corpus completion protocol.
- `docs/review/2026-10-06-living-korea-dialogue-tts-checkpoint.md` — user-reviewed Living Korea/TTS checkpoint.
- `tools/content_factory/review/living_korea_program_manifest_20261005.json` — program review state.

## Culture / provenance SSoT
- `docs/data/cultural_glossary.json` — sourced culture glossary.
- `docs/CONTENT_SOURCE_POLICY.md` — copyright / clean-room source policy.
- `tools/content_factory/reference_intake/source_inventory.csv` — licensed/restricted source ledger.

## Localization SSoT
- `docs/LOCALIZATION_DEEP_DIVE_2026-06-09.md`
- 32-topic native-usage registry above.
- This textbook project's future EN/DE explanations must reference those sources but remain independently authored from the Korean semantic master.

## Mapping rule
Textbook files may summarize or index canonical sources, but must not silently fork them.
If a canonical app source changes, the textbook bridge must be re-audited before publication.
