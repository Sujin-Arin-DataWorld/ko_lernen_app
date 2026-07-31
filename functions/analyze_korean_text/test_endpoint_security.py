"""HTTP-boundary tests for the authentication and quota integration."""

from __future__ import annotations

import pathlib
import sys
import unittest
from unittest import mock

from flask import Flask, request

sys.path.insert(0, str(pathlib.Path(__file__).parent))

import main as endpoint  # noqa: E402
from security import (  # noqa: E402
    AuthenticationFailed,
    Caller,
    QuotaExceeded,
    QuotaStoreUnavailable,
)


class _QuotaGate:
    def __init__(self, error: Exception):
        self.error = error
        self.uids: list[str] = []

    def consume(self, uid: str) -> None:
        self.uids.append(uid)
        raise self.error


class EndpointSecurityTest(unittest.TestCase):
    def setUp(self):
        self.app = Flask(__name__)

    def test_rejects_unverified_call_before_parsing_or_analyzing_text(self):
        with self.app.test_request_context(
            "/", method="POST", json={"text": "private text", "lang": "de"}
        ):
            with mock.patch.object(
                endpoint, "verify_caller", side_effect=AuthenticationFailed()
            ), mock.patch.object(endpoint, "detect_grammar") as analyze:
                response = endpoint.analyze_korean_text(request)

        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.get_json(), {"warnings": ["unauthenticated"]})
        analyze.assert_not_called()

    def test_rate_limited_call_never_reaches_the_language_engines(self):
        gate = _QuotaGate(QuotaExceeded(37))
        with self.app.test_request_context(
            "/", method="POST", json={"text": "학생이에요.", "lang": "de"}
        ):
            with mock.patch.object(
                endpoint,
                "verify_caller",
                return_value=Caller(uid="verified-user", app_id="approved-app"),
            ), mock.patch.object(endpoint, "_quota_gate", return_value=gate), mock.patch.object(
                endpoint, "detect_grammar"
            ) as analyze:
                response = endpoint.analyze_korean_text(request)

        self.assertEqual(response.status_code, 429)
        self.assertEqual(response.headers["Retry-After"], "37")
        self.assertEqual(response.get_json(), {"warnings": ["rate_limited"]})
        self.assertEqual(gate.uids, ["verified-user"])
        analyze.assert_not_called()

    def test_quota_store_failure_fails_closed_before_the_language_engines(self):
        gate = _QuotaGate(QuotaStoreUnavailable())
        with self.app.test_request_context(
            "/", method="POST", json={"text": "학생이에요.", "lang": "de"}
        ):
            with mock.patch.object(
                endpoint,
                "verify_caller",
                return_value=Caller(uid="verified-user", app_id="approved-app"),
            ), mock.patch.object(endpoint, "_quota_gate", return_value=gate), mock.patch.object(
                endpoint, "detect_grammar"
            ) as analyze:
                response = endpoint.analyze_korean_text(request)

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.get_json(), {"warnings": ["service_unavailable"]})
        analyze.assert_not_called()


if __name__ == "__main__":
    unittest.main()
