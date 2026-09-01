# main.py

> 51 nodes · cohesion 0.08

## Key Concepts

- **main.py** (50 connections) — `functions/analyze_korean_text/main.py`
- **analyze_korean_text()** (19 connections) — `functions/analyze_korean_text/main.py`
- **DeadlineBudget** (13 connections) — `functions/analyze_korean_text/security.py`
- **_complete_book_analysis()** (13 connections) — `functions/analyze_korean_text/main.py`
- **validate_kkeunmari_word()** (13 connections) — `functions/analyze_korean_text/main.py`
- **translate_words_with_context()** (12 connections) — `functions/analyze_korean_text/main.py`
- **translate_batch()** (10 connections) — `functions/analyze_korean_text/main.py`
- **_translate_with_budget()** (7 connections) — `functions/analyze_korean_text/main.py`
- **provider_timeout_seconds()** (7 connections) — `functions/analyze_korean_text/security.py`
- **_analysis_response()** (6 connections) — `functions/analyze_korean_text/main.py`
- **_cache_payload()** (5 connections) — `functions/analyze_korean_text/main.py`
- **_cached_translation()** (5 connections) — `functions/analyze_korean_text/main.py`
- **_deepl_breaker()** (5 connections) — `functions/analyze_korean_text/main.py`
- **extract_words()** (5 connections) — `functions/analyze_korean_text/main.py`
- **_structured_analysis_units()** (5 connections) — `functions/analyze_korean_text/main.py`
- **Any** (5 connections)
- **Response** (5 connections)
- **_cache_expires_at()** (4 connections) — `functions/analyze_korean_text/main.py`
- **_dictionary_quota_gate()** (4 connections) — `functions/analyze_korean_text/main.py`
- **_get_deepl()** (4 connections) — `functions/analyze_korean_text/main.py`
- **_get_firestore()** (4 connections) — `functions/analyze_korean_text/main.py`
- **_log_analysis_result()** (4 connections) — `functions/analyze_korean_text/main.py`
- **_quota_gate()** (4 connections) — `functions/analyze_korean_text/main.py`
- **split_sentences()** (4 connections) — `functions/analyze_korean_text/main.py`
- **_warning_response()** (4 connections) — `functions/analyze_korean_text/main.py`
- *... and 26 more nodes in this community*

## Relationships

- [security.py](security.py.md) (12 shared connections)
- [EndpointSecurityTest](EndpointSecurityTest.md) (9 shared connections)
- [detect_grammar](detect_grammar.md) (7 shared connections)
- [IdempotencyPolicyTest](IdempotencyPolicyTest.md) (6 shared connections)
- [prepare_korean_analysis_text](prepare_korean_analysis_text.md) (6 shared connections)
- [verify_caller](verify_caller.md) (5 shared connections)
- [dictionary_validation.py](dictionary_validation.py.md) (3 shared connections)
- [CircuitBreaker](CircuitBreaker.md) (2 shared connections)

## Source Files

- `functions/analyze_korean_text/main.py`
- `functions/analyze_korean_text/security.py`
- `functions/analyze_korean_text/test_security.py`

## Audit Trail

- EXTRACTED: 144 (93%)
- INFERRED: 11 (7%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*