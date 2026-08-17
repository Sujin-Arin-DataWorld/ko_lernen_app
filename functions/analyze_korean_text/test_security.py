"""Security-unit tests that do not require live Firebase credentials."""

from __future__ import annotations

import datetime as dt
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).parent))

from security import (  # noqa: E402
    AuthenticationFailed,
    CircuitBreaker,
    DEFAULT_ALLOWED_APP_IDS,
    DEEPL_CALL_DEADLINE_SECONDS,
    DEEPL_HTTP_MAX_RETRIES,
    DEEPL_HTTP_TIMEOUT_SECONDS,
    DeadlineBudget,
    FirestoreIdempotencyGate,
    QuotaExceeded,
    QuotaState,
    analysis_request_id,
    configure_deepl_http_deadlines,
    consume_quota_state,
    idempotency_payload,
    is_current_idempotency,
    provider_timeout_seconds,
    quota_document_id,
    quota_expires_at,
    release_quota_state,
    run_with_deadline,
    verify_caller,
)


ANDROID_APP_ID = "1:573567222361:android:38d26a50001ee64c356748"
IOS_APP_ID = "1:573567222361:ios:0f8c0734410bb6cc356748"


class _Request:
    def __init__(self, headers: dict[str, str]):
        self.headers = headers


class CallerVerificationTest(unittest.TestCase):
    def test_default_app_check_allowlist_covers_both_mobile_apps(self):
        self.assertEqual(DEFAULT_ALLOWED_APP_IDS, {ANDROID_APP_ID, IOS_APP_ID})

    def test_returns_only_the_uid_from_the_verified_auth_token(self):
        request = _Request(
            {
                "X-Firebase-AppCheck": "valid-app-check",
                "Authorization": "Bearer valid-id-token",
            }
        )
        app_check_tokens: list[str] = []
        auth_calls: list[tuple[str, bool]] = []

        caller = verify_caller(
            request,
            verify_app_check=lambda token: app_check_tokens.append(token)
            or {"sub": ANDROID_APP_ID},
            verify_auth=lambda token, check_revoked: auth_calls.append(
                (token, check_revoked)
            )
            or {"uid": "verified-user"},
            allowed_app_ids={ANDROID_APP_ID},
        )

        self.assertEqual(caller.uid, "verified-user")
        self.assertEqual(caller.app_id, ANDROID_APP_ID)
        self.assertEqual(app_check_tokens, ["valid-app-check"])
        self.assertEqual(auth_calls, [("valid-id-token", True)])

    def test_rejects_missing_or_unapproved_app_check_before_auth(self):
        auth_was_called = False

        def auth_verifier(_token: str, _check_revoked: bool):
            nonlocal auth_was_called
            auth_was_called = True
            return {"uid": "must-not-be-used"}

        with self.assertRaises(AuthenticationFailed):
            verify_caller(
                _Request({"Authorization": "Bearer valid-id-token"}),
                verify_app_check=lambda _token: {"sub": ANDROID_APP_ID},
                verify_auth=auth_verifier,
                allowed_app_ids={ANDROID_APP_ID},
            )

        with self.assertRaises(AuthenticationFailed):
            verify_caller(
                _Request(
                    {
                        "X-Firebase-AppCheck": "wrong-app",
                        "Authorization": "Bearer valid-id-token",
                    }
                ),
                verify_app_check=lambda _token: {"sub": "unapproved-app"},
                verify_auth=auth_verifier,
                allowed_app_ids={ANDROID_APP_ID},
            )

        self.assertFalse(auth_was_called)


class QuotaPolicyTest(unittest.TestCase):
    def test_quota_document_identifier_never_contains_raw_uid(self):
        uid = "firebase-user-123"
        document_id = quota_document_id(uid)

        self.assertNotIn(uid, document_id)
        self.assertEqual(len(document_id), 64)

    def test_daily_limit_rejects_the_twenty_first_request(self):
        now = dt.datetime(2026, 7, 31, 10, 0, tzinfo=dt.timezone.utc)
        state = QuotaState(
            day="2026-07-31",
            daily_count=20,
            burst_window_started_at=now.timestamp(),
            burst_count=1,
        )

        with self.assertRaises(QuotaExceeded) as raised:
            consume_quota_state(state, now)

        self.assertGreater(raised.exception.retry_after_seconds, 0)

    def test_burst_limit_rejects_a_fourth_request_in_one_minute(self):
        now = dt.datetime(2026, 7, 31, 10, 0, tzinfo=dt.timezone.utc)
        state = QuotaState(
            day="2026-07-31",
            daily_count=3,
            burst_window_started_at=now.timestamp() - 12,
            burst_count=3,
        )

        with self.assertRaises(QuotaExceeded) as raised:
            consume_quota_state(state, now)

        self.assertEqual(raised.exception.retry_after_seconds, 48)

    def test_new_utc_day_resets_daily_count(self):
        now = dt.datetime(2026, 8, 1, 0, 1, tzinfo=dt.timezone.utc)
        state = QuotaState(
            day="2026-07-31",
            daily_count=20,
            burst_window_started_at=now.timestamp() - 61,
            burst_count=3,
        )

        updated = consume_quota_state(state, now)

        self.assertEqual(updated.day, "2026-08-01")
        self.assertEqual(updated.daily_count, 1)
        self.assertEqual(updated.burst_count, 1)

    def test_release_undoes_the_same_day_consume(self):
        now = dt.datetime(2026, 7, 31, 10, 0, tzinfo=dt.timezone.utc)
        consumed = consume_quota_state(
            QuotaState(
                day="2026-07-31",
                daily_count=4,
                burst_window_started_at=now.timestamp(),
                burst_count=2,
            ),
            now,
        )

        released = release_quota_state(consumed, now)

        self.assertEqual(released.daily_count, 4)
        self.assertEqual(released.burst_count, 2)

    def test_release_does_not_cross_a_utc_day_boundary(self):
        now = dt.datetime(2026, 8, 1, 0, 1, tzinfo=dt.timezone.utc)
        released = release_quota_state(
            QuotaState(
                day="2026-07-31",
                daily_count=20,
                burst_window_started_at=now.timestamp() - 120,
                burst_count=3,
            ),
            now,
        )

        self.assertEqual(released.day, "2026-07-31")
        self.assertEqual(released.daily_count, 20)

    def test_quota_ledger_expires_two_utc_days_later(self):
        now = dt.datetime(2026, 7, 31, 10, 0, tzinfo=dt.timezone.utc)
        self.assertEqual(
            quota_expires_at(now),
            dt.datetime(2026, 8, 2, tzinfo=dt.timezone.utc),
        )


class CircuitBreakerTest(unittest.TestCase):
    def test_opens_after_threshold_and_allows_a_probe_after_cooldown(self):
        clock = {"now": 1_000.0}
        breaker = CircuitBreaker(
            failure_threshold=3,
            cooldown_seconds=30,
            clock=lambda: clock["now"],
        )

        for _ in range(3):
            breaker.record_failure()

        self.assertFalse(breaker.allow())
        clock["now"] = 1_029.0
        self.assertFalse(breaker.allow())
        clock["now"] = 1_030.0
        self.assertTrue(breaker.allow())
        breaker.record_success()
        self.assertTrue(breaker.allow())


class IdempotencyPolicyTest(unittest.TestCase):
    def test_analysis_request_id_is_stable_and_hides_the_uid(self):
        uid = "firebase-user-123"
        first = analysis_request_id(uid, "de", "학생이에요.", None)
        second = analysis_request_id(uid, "de", "학생이에요.", None)

        self.assertEqual(first, second)
        self.assertEqual(len(first), 64)
        self.assertNotIn(uid, first)
        self.assertNotEqual(
            first,
            analysis_request_id("other-user", "de", "학생이에요.", None),
        )
        self.assertNotEqual(
            first,
            analysis_request_id(uid, "en", "학생이에요.", None),
        )

    def test_idempotency_payload_never_stores_source_text(self):
        now = dt.datetime(2026, 8, 16, 10, 0, tzinfo=dt.timezone.utc)
        payload = idempotency_payload("book_analysis_v1", now)

        self.assertEqual(set(payload), {"kind", "state", "expiresAt"})
        self.assertEqual(payload["kind"], "book_analysis_v1")
        self.assertEqual(payload["state"], "completed")
        self.assertEqual(
            payload["expiresAt"],
            dt.datetime(2026, 8, 16, 10, 15, tzinfo=dt.timezone.utc),
        )
        self.assertTrue(
            is_current_idempotency(payload, now, kind="book_analysis_v1")
        )
        self.assertFalse(
            is_current_idempotency(
                payload,
                now + dt.timedelta(minutes=15),
                kind="book_analysis_v1",
            )
        )

    def test_claim_before_work_skips_a_second_charge_even_while_pending(self):
        store: dict[str, dict[str, object]] = {}
        gate = FirestoreIdempotencyGate(
            firestore_client=_FakeIdempotencyClient(store)
        )
        request_id = analysis_request_id("user-1", "de", "학생이에요.", None)

        self.assertTrue(gate.claim(request_id, kind="book_analysis_v1"))
        self.assertFalse(gate.claim(request_id, kind="book_analysis_v1"))
        self.assertEqual(store[request_id]["state"], "pending")
        gate.complete(request_id, "book_analysis_v1")
        self.assertFalse(gate.claim(request_id, kind="book_analysis_v1"))
        self.assertEqual(set(store[request_id]), {"kind", "state", "expiresAt"})

    def test_abandoned_pending_receipt_lets_a_later_retry_consume(self):
        store: dict[str, dict[str, object]] = {}
        gate = FirestoreIdempotencyGate(
            firestore_client=_FakeIdempotencyClient(store)
        )
        request_id = analysis_request_id("user-1", "de", "학생이에요.", None)

        self.assertTrue(gate.claim(request_id, kind="book_analysis_v1"))
        gate.abandon(request_id, "book_analysis_v1")
        self.assertTrue(gate.claim(request_id, kind="book_analysis_v1"))

    def test_shared_deadline_budget_blocks_a_second_provider_call(self):
        clock = {"now": 0.0}
        budget = DeadlineBudget(
            DEEPL_CALL_DEADLINE_SECONDS,
            clock=lambda: clock["now"],
        )
        self.assertEqual(
            provider_timeout_seconds(budget), DEEPL_CALL_DEADLINE_SECONDS
        )
        clock["now"] = DEEPL_CALL_DEADLINE_SECONDS
        self.assertIsNone(provider_timeout_seconds(budget))

    def test_run_with_deadline_raises_before_a_hung_provider_returns(self):
        def hang() -> str:
            import time

            time.sleep(1)
            return "too-late"

        with self.assertRaises(TimeoutError):
            run_with_deadline(hang, timeout_seconds=0.05)

    def test_deepl_http_client_drops_the_default_retry_loop(self):
        import deepl.http_client as http_client

        configure_deepl_http_deadlines()
        self.assertEqual(
            http_client.min_connection_timeout, DEEPL_HTTP_TIMEOUT_SECONDS
        )
        self.assertEqual(
            http_client.max_network_retries, DEEPL_HTTP_MAX_RETRIES
        )


class _FakeIdempotencyClient:
    def __init__(self, store: dict[str, dict[str, object]]):
        self.store = store

    def collection(self, _name: str) -> "_FakeIdempotencyClient":
        return self

    def document(self, document_id: str) -> "_FakeIdempotencyDocument":
        return _FakeIdempotencyDocument(self.store, document_id)


class _FakeIdempotencyDocument:
    def __init__(self, store: dict[str, dict[str, object]], document_id: str):
        self.store = store
        self.document_id = document_id

    def get(self, **_kwargs: object) -> "_FakeIdempotencySnapshot":
        return _FakeIdempotencySnapshot(self.store.get(self.document_id))

    def set(self, data: dict[str, object]) -> None:
        self.store[self.document_id] = data

    def delete(self) -> None:
        self.store.pop(self.document_id, None)


class _FakeIdempotencySnapshot:
    def __init__(self, data: dict[str, object] | None):
        self._data = data
        self.exists = data is not None

    def to_dict(self) -> dict[str, object] | None:
        return self._data


if __name__ == "__main__":
    unittest.main()
