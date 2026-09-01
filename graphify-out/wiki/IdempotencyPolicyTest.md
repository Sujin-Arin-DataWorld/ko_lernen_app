# IdempotencyPolicyTest

> 22 nodes · cohesion 0.10

## Key Concepts

- **IdempotencyPolicyTest** (10 connections) — `functions/analyze_korean_text/test_security.py`
- **analysis_request_id()** (8 connections) — `functions/analyze_korean_text/security.py`
- **_FakeIdempotencyClient** (6 connections) — `functions/analyze_korean_text/test_security.py`
- **_FakeIdempotencyDocument** (6 connections) — `functions/analyze_korean_text/test_security.py`
- **configure_deepl_http_deadlines()** (6 connections) — `functions/analyze_korean_text/security.py`
- **_FakeIdempotencySnapshot** (4 connections) — `functions/analyze_korean_text/test_security.py`
- **.test_abandoned_pending_receipt_lets_a_later_retry_consume()** (4 connections) — `functions/analyze_korean_text/test_security.py`
- **.test_claim_before_work_skips_a_second_charge_even_while_pending()** (4 connections) — `functions/analyze_korean_text/test_security.py`
- **.document()** (2 connections) — `functions/analyze_korean_text/test_security.py`
- **.get()** (2 connections) — `functions/analyze_korean_text/test_security.py`
- **.test_analysis_request_id_is_stable_and_hides_the_uid()** (2 connections) — `functions/analyze_korean_text/test_security.py`
- **.test_deepl_http_client_drops_the_default_retry_loop()** (2 connections) — `functions/analyze_korean_text/test_security.py`
- **.test_run_with_deadline_raises_before_a_hung_provider_returns()** (2 connections) — `functions/analyze_korean_text/test_security.py`
- **.collection()** (1 connections) — `functions/analyze_korean_text/test_security.py`
- **.__init__()** (1 connections) — `functions/analyze_korean_text/test_security.py`
- **.delete()** (1 connections) — `functions/analyze_korean_text/test_security.py`
- **.__init__()** (1 connections) — `functions/analyze_korean_text/test_security.py`
- **.set()** (1 connections) — `functions/analyze_korean_text/test_security.py`
- **.__init__()** (1 connections) — `functions/analyze_korean_text/test_security.py`
- **.to_dict()** (1 connections) — `functions/analyze_korean_text/test_security.py`
- **Hash a retryable book-analysis request without using the raw uid as an id.** (1 connections) — `functions/analyze_korean_text/security.py`
- **Stop DeepL's 10s×5 retry loop from outliving the client timeout.** (1 connections) — `functions/analyze_korean_text/security.py`

## Relationships

- [security.py](security.py.md) (13 shared connections)
- [main.py](main.py.md) (6 shared connections)

## Source Files

- `functions/analyze_korean_text/security.py`
- `functions/analyze_korean_text/test_security.py`

## Audit Trail

- EXTRACTED: 41 (95%)
- INFERRED: 2 (5%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*