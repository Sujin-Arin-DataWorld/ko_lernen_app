"""Security-unit tests that do not require live Firebase credentials."""

from __future__ import annotations

import datetime as dt
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).parent))

from security import (  # noqa: E402
    AuthenticationFailed,
    QuotaExceeded,
    QuotaState,
    consume_quota_state,
    quota_document_id,
    verify_caller,
)


ANDROID_APP_ID = "1:573567222361:android:38d26a50001ee64c356748"


class _Request:
    def __init__(self, headers: dict[str, str]):
        self.headers = headers


class CallerVerificationTest(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main()
