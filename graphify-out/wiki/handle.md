# handle

> 33 nodes · cohesion 0.09

## Key Concepts

- **handle()** (102 connections) — `tool/polish_tts.py`
- **TtsGeneratorContractTest** (17 connections) — `tool/test_generate_tts.py`
- **build()** (6 connections) — `tools/content_factory/build_batch_16_scenarios.py`
- **build_batch_16_scenarios.py** (5 connections) — `tools/content_factory/build_batch_16_scenarios.py`
- **polish_tts.py** (4 connections) — `tool/polish_tts.py`
- **probe()** (3 connections) — `tool/polish_tts.py`
- **trim()** (3 connections) — `tool/polish_tts.py`
- **_sort_key()** (3 connections) — `tools/content_factory/build_batch_16_scenarios.py`
- **_to_record()** (3 connections) — `tools/content_factory/build_batch_16_scenarios.py`
- **main()** (2 connections) — `tool/polish_tts.py`
- **test_generate_tts.py** (2 connections) — `tool/test_generate_tts.py`
- **.test_checked_first_line_manifest_matches_current_canonical_sources()** (2 connections) — `tool/test_generate_tts.py`
- **.test_collect_covers_every_fixed_tts_source()** (2 connections) — `tool/test_generate_tts.py`
- **.test_first_line_manifest_cli_never_uses_auth_synthesis_or_network()** (2 connections) — `tool/test_generate_tts.py`
- **.test_first_line_manifest_rejects_duplicate_id_and_missing_first_dialog()** (2 connections) — `tool/test_generate_tts.py`
- **.test_first_line_manifest_selects_first_dialog_and_legacy_voice_rule()** (2 connections) — `tool/test_generate_tts.py`
- **.test_manifest_upload_uses_only_the_exact_selected_object()** (2 connections) — `tool/test_generate_tts.py`
- **.test_pending_manifest_dry_run_does_not_collect_runtime_or_use_network()** (2 connections) — `tool/test_generate_tts.py`
- **.test_scenario_pending_manifest_is_an_exact_validated_scope()** (2 connections) — `tool/test_generate_tts.py`
- **main()** (2 connections) — `tools/content_factory/build_batch_16_scenarios.py`
- **Any** (2 connections)
- **(전체 길이, 앞 묵음, 뒤 묵음) 초. 실패하면 None.** (1 connections) — `tool/polish_tts.py`
- **프레임 경계에서 무손실 절단. 성공하면 True.** (1 connections) — `tool/polish_tts.py`
- **고정 콘텐츠가 수집에 빠지면 런타임에 OS 폴백(옛 음성)으로 샌다. 2026-08-12: satz 목표문장 55/191 이 수집에 없어…** (1 connections) — `tool/test_generate_tts.py`
- **.test_auto_voice_matches_dart_contract_vectors()** (1 connections) — `tool/test_generate_tts.py`
- *... and 8 more nodes in this community*

## Relationships

- [SceneContractTest](SceneContractTest.md) (9 shared connections)
- [promote_batch_19_loader_coverage.py](promote_batch_19_loader_coverage.py.md) (6 shared connections)
- [Counter](Counter.md) (5 shared connections)
- [audit_game_loader_coverage.py](audit_game_loader_coverage.py.md) (4 shared connections)
- [quest](quest.md) (4 shared connections)
- [build_batch_18_social_language.py](build_batch_18_social_language.py.md) (4 shared connections)
- [scenario_store.py](scenario_store.py.md) (4 shared connections)
- [integrate_scenario_batch.py](integrate_scenario_batch.py.md) (4 shared connections)
- [generate_tts.py](generate_tts.py.md) (3 shared connections)
- [apply_review.py](apply_review.py.md) (3 shared connections)
- [build_batch_17_social_topics.py](build_batch_17_social_topics.py.md) (3 shared connections)
- [build_level_content_4x.py](build_level_content_4x.py.md) (3 shared connections)

## Source Files

- `tool/polish_tts.py`
- `tool/test_generate_tts.py`
- `tools/content_factory/build_batch_16_scenarios.py`

## Audit Trail

- EXTRACTED: 38 (28%)
- INFERRED: 99 (72%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*