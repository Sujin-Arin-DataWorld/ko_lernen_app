# SimpleNamespace

> 38 nodes · cohesion 0.08

## Key Concepts

- **SimpleNamespace** (13 connections)
- **_Firestore** (10 connections) — `functions/analyze_korean_text/test_cache_privacy.py`
- **KoreanAnalysisEndpointQualityTest** (10 connections) — `functions/analyze_korean_text/test_text_quality.py`
- **TranslationCachePrivacyTest** (9 connections) — `functions/analyze_korean_text/test_cache_privacy.py`
- **test_cache_privacy.py** (7 connections) — `functions/analyze_korean_text/test_cache_privacy.py`
- **_Batch** (5 connections) — `functions/analyze_korean_text/test_cache_privacy.py`
- **_DocumentReference** (5 connections) — `functions/analyze_korean_text/test_cache_privacy.py`
- **_Snapshot** (4 connections) — `functions/analyze_korean_text/test_cache_privacy.py`
- **.test_sentence_cache_write_contains_no_source_and_expires_in_30_days()** (4 connections) — `functions/analyze_korean_text/test_cache_privacy.py`
- **.test_word_cache_write_also_contains_no_source_text()** (4 connections) — `functions/analyze_korean_text/test_cache_privacy.py`
- **_CollectionReference** (3 connections) — `functions/analyze_korean_text/test_cache_privacy.py`
- **.batch()** (3 connections) — `functions/analyze_korean_text/test_cache_privacy.py`
- **.get_all()** (3 connections) — `functions/analyze_korean_text/test_cache_privacy.py`
- **._assert_source_free_ttl_payload()** (3 connections) — `functions/analyze_korean_text/test_cache_privacy.py`
- **.test_expired_or_legacy_cache_entries_are_misses()** (3 connections) — `functions/analyze_korean_text/test_cache_privacy.py`
- **.set()** (2 connections) — `functions/analyze_korean_text/test_cache_privacy.py`
- **.document()** (2 connections) — `functions/analyze_korean_text/test_cache_privacy.py`
- **.collection()** (2 connections) — `functions/analyze_korean_text/test_cache_privacy.py`
- **.test_current_cache_entry_skips_deepl()** (2 connections) — `functions/analyze_korean_text/test_cache_privacy.py`
- **.test_open_deepl_circuit_skips_provider_and_keeps_cache_hits()** (2 connections) — `functions/analyze_korean_text/test_cache_privacy.py`
- **.test_deepl_calls_pin_korean_as_the_source_language()** (2 connections) — `functions/analyze_korean_text/test_text_quality.py`
- **.test_no_korean_returns_before_quota_and_language_engines()** (2 connections) — `functions/analyze_korean_text/test_text_quality.py`
- **.test_only_prepared_korean_reaches_analysis_and_response()** (2 connections) — `functions/analyze_korean_text/test_text_quality.py`
- **.test_operational_log_never_contains_the_ocr_text_or_user_id()** (2 connections) — `functions/analyze_korean_text/test_text_quality.py`
- **.test_structured_units_keep_sentences_and_expressions_separate()** (2 connections) — `functions/analyze_korean_text/test_text_quality.py`
- *... and 13 more nodes in this community*

## Relationships

- [detect_grammar](detect_grammar.md) (2 shared connections)
- [Batch01PreReviewValidationTest](Batch01PreReviewValidationTest.md) (1 shared connections)
- [prepare_korean_analysis_text](prepare_korean_analysis_text.md) (1 shared connections)
- [integrate_scenario_batch.py](integrate_scenario_batch.py.md) (1 shared connections)

## Source Files

- `functions/analyze_korean_text/test_cache_privacy.py`
- `functions/analyze_korean_text/test_text_quality.py`

## Audit Trail

- EXTRACTED: 51 (81%)
- INFERRED: 12 (19%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*