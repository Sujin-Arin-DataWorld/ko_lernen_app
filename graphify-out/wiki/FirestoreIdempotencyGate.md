# FirestoreIdempotencyGate

> 21 nodes · cohesion 0.15

## Key Concepts

- **FirestoreIdempotencyGate** (17 connections) — `functions/analyze_korean_text/security.py`
- **IdempotencyPolicyTest** (10 connections) — `functions/analyze_korean_text/test_security.py`
- **analysis_request_id()** (8 connections) — `functions/analyze_korean_text/security.py`
- **._client()** (7 connections) — `functions/analyze_korean_text/security.py`
- **._reference()** (7 connections) — `functions/analyze_korean_text/security.py`
- **_FakeIdempotencyClient** (6 connections) — `functions/analyze_korean_text/test_security.py`
- **.claim()** (5 connections) — `functions/analyze_korean_text/security.py`
- **.complete()** (4 connections) — `functions/analyze_korean_text/security.py`
- **.test_abandoned_pending_receipt_lets_a_later_retry_consume()** (4 connections) — `functions/analyze_korean_text/test_security.py`
- **.test_claim_before_work_skips_a_second_charge_even_while_pending()** (4 connections) — `functions/analyze_korean_text/test_security.py`
- **.abandon()** (3 connections) — `functions/analyze_korean_text/security.py`
- **.seen()** (3 connections) — `functions/analyze_korean_text/security.py`
- **.remember()** (2 connections) — `functions/analyze_korean_text/security.py`
- **.test_analysis_request_id_is_stable_and_hides_the_uid()** (2 connections) — `functions/analyze_korean_text/test_security.py`
- **.test_run_with_deadline_raises_before_a_hung_provider_returns()** (2 connections) — `functions/analyze_korean_text/test_security.py`
- **.collection()** (1 connections) — `functions/analyze_korean_text/test_security.py`
- **.__init__()** (1 connections) — `functions/analyze_korean_text/test_security.py`
- **Hash a retryable book-analysis request without using the raw uid as an id.** (1 connections) — `functions/analyze_korean_text/security.py`
- **Short-lived server-only receipts so identical retries skip a second charge.** (1 connections) — `functions/analyze_korean_text/security.py`
- **Reserve the receipt before quota. True means this caller must consume.** (1 connections) — `functions/analyze_korean_text/security.py`
- **Drop an in-flight pending receipt so a later retry can be charged.** (1 connections) — `functions/analyze_korean_text/security.py`

## Relationships

- [security.py](security.py.md) (18 shared connections)
- [main.py](main.py.md) (7 shared connections)
- [_FakeIdempotencyDocument](_FakeIdempotencyDocument.md) (1 shared connections)

## Source Files

- `functions/analyze_korean_text/security.py`
- `functions/analyze_korean_text/test_security.py`

## Audit Trail

- EXTRACTED: 56 (97%)
- INFERRED: 2 (3%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*
