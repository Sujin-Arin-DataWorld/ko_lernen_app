# EndpointSecurityTest

> 37 nodes · cohesion 0.10

## Key Concepts

- **EndpointSecurityTest** (18 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- **AuthenticationFailed** (15 connections) — `functions/analyze_korean_text/security.py`
- **Caller** (12 connections) — `functions/analyze_korean_text/security.py`
- **QuotaExceeded** (12 connections) — `functions/analyze_korean_text/security.py`
- **QuotaStoreUnavailable** (11 connections) — `functions/analyze_korean_text/security.py`
- **_MemoryIdempotency** (10 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- **test_endpoint_security.py** (10 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- **_RecordingGate** (9 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- **_QuotaGate** (5 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- **.test_identical_analysis_retry_skips_a_second_quota_consume()** (5 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- **.test_quota_store_failure_fails_closed_before_the_language_engines()** (5 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- **.test_rate_limited_call_never_reaches_the_language_engines()** (5 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- **.test_in_flight_analysis_retry_skips_consume_before_success()** (4 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- **.test_unexpected_engine_failure_releases_quota_and_hides_details()** (4 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- **.test_dictionary_exception_also_releases_quota()** (3 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- **.test_dictionary_unavailable_releases_quota()** (3 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- **Exception** (3 connections)
- **.__init__()** (2 connections) — `functions/analyze_korean_text/security.py`
- **.test_dictionary_endpoint_keeps_invalid_shape_off_the_dictionary_api()** (2 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- **.test_dictionary_endpoint_requires_the_same_verified_caller()** (2 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- **.test_rejects_unverified_call_before_parsing_or_analyzing_text()** (2 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- **.test_unauthenticated_responses_are_not_storeable()** (2 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- **.complete()** (2 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- **.__init__()** (2 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- **.setUp()** (1 connections) — `functions/analyze_korean_text/test_endpoint_security.py`
- *... and 12 more nodes in this community*

## Relationships

- [security.py](security.py.md) (12 shared connections)
- [main.py](main.py.md) (9 shared connections)
- [verify_caller](verify_caller.md) (4 shared connections)

## Source Files

- `functions/analyze_korean_text/security.py`
- `functions/analyze_korean_text/test_endpoint_security.py`

## Audit Trail

- EXTRACTED: 80 (86%)
- INFERRED: 13 (14%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*