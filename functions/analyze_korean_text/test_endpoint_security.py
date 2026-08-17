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
                endpoint, "_idempotency_gate", return_value=_MemoryIdempotency()
            ), mock.patch.object(
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
                endpoint, "_idempotency_gate", return_value=_MemoryIdempotency()
            ), mock.patch.object(
                endpoint, "detect_grammar"
            ) as analyze:
                response = endpoint.analyze_korean_text(request)

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.get_json(), {"warnings": ["service_unavailable"]})
        analyze.assert_not_called()

    def test_dictionary_endpoint_requires_the_same_verified_caller(self):
        with self.app.test_request_context(
            "/", method="POST", json={"word": "\uc81c\uc0ac"}
        ):
            with mock.patch.object(
                endpoint, "verify_caller", side_effect=AuthenticationFailed()
            ), mock.patch.object(endpoint, "validate_exact_noun") as lookup:
                response = endpoint.validate_kkeunmari_word(request)

        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.get_json(), {"warnings": ["unauthenticated"]})
        lookup.assert_not_called()

    def test_dictionary_endpoint_keeps_invalid_shape_off_the_dictionary_api(self):
        with self.app.test_request_context(
            "/", method="POST", json={"word": "not-hangul"}
        ):
            with mock.patch.object(
                endpoint,
                "verify_caller",
                return_value=Caller(uid="verified-user", app_id="approved-app"),
            ), mock.patch.object(endpoint, "validate_exact_noun") as lookup:
                response = endpoint.validate_kkeunmari_word(request)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["valid"], False)
        lookup.assert_not_called()

    def test_dictionary_endpoint_rejects_oversized_bodies_before_auth(self):
        with self.app.test_request_context(
            "/",
            method="POST",
            data="x" * 2001,
            content_type="application/json",
            content_length=2001,
        ):
            with mock.patch.object(endpoint, "verify_caller") as verify:
                response = endpoint.validate_kkeunmari_word(request)

        self.assertEqual(response.status_code, 413)
        self.assertEqual(response.get_json(), {"warnings": ["request_too_large"]})
        verify.assert_not_called()

    def test_unauthenticated_responses_are_not_storeable(self):
        with self.app.test_request_context(
            "/", method="POST", json={"text": "학생이에요.", "lang": "de"}
        ):
            with mock.patch.object(
                endpoint, "verify_caller", side_effect=AuthenticationFailed()
            ):
                response = endpoint.analyze_korean_text(request)

        self.assertEqual(response.headers["Cache-Control"], "no-store")

    def test_unexpected_engine_failure_releases_quota_and_hides_details(self):
        gate = _RecordingGate()
        with self.app.test_request_context(
            "/", method="POST", json={"text": "학생이에요.", "lang": "de"}
        ):
            with mock.patch.object(
                endpoint,
                "verify_caller",
                return_value=Caller(uid="verified-user", app_id="approved-app"),
            ), mock.patch.object(
                endpoint, "_quota_gate", return_value=gate
            ), mock.patch.object(
                endpoint, "_idempotency_gate", return_value=_MemoryIdempotency()
            ), mock.patch.object(
                endpoint,
                "detect_grammar",
                side_effect=RuntimeError("secret kiwi dump"),
            ), mock.patch.object(
                endpoint,
                "_get_kiwi",
                return_value=mock.Mock(tokenize=lambda *args, **kwargs: []),
            ):
                response = endpoint.analyze_korean_text(request)

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.get_json(), {"warnings": ["service_unavailable"]})
        self.assertNotIn("secret", response.get_data(as_text=True))
        self.assertEqual(gate.consumed, ["verified-user"])
        self.assertEqual(gate.released, ["verified-user"])

    def test_dictionary_unavailable_releases_quota(self):
        gate = _RecordingGate()
        with self.app.test_request_context(
            "/", method="POST", json={"word": "제사"}
        ):
            with mock.patch.object(
                endpoint,
                "verify_caller",
                return_value=Caller(uid="verified-user", app_id="approved-app"),
            ), mock.patch.object(
                endpoint, "_dictionary_quota_gate", return_value=gate
            ), mock.patch.object(
                endpoint, "validate_exact_noun", return_value=None
            ):
                response = endpoint.validate_kkeunmari_word(request)

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.get_json(), {"warnings": ["dictionary_unavailable"]})
        self.assertEqual(gate.consumed, ["verified-user"])
        self.assertEqual(gate.released, ["verified-user"])

    def test_identical_analysis_retry_skips_a_second_quota_consume(self):
        gate = _RecordingGate()
        receipts = _MemoryIdempotency()
        payload = {"text": "학생이에요.", "lang": "de"}

        def complete(**_kwargs):
            return endpoint._analysis_response("de")

        for _ in range(2):
            with self.app.test_request_context("/", method="POST", json=payload):
                with mock.patch.object(
                    endpoint,
                    "verify_caller",
                    return_value=Caller(
                        uid="verified-user", app_id="approved-app"
                    ),
                ), mock.patch.object(
                    endpoint, "_quota_gate", return_value=gate
                ), mock.patch.object(
                    endpoint, "_idempotency_gate", return_value=receipts
                ), mock.patch.object(
                    endpoint, "_complete_book_analysis", side_effect=complete
                ):
                    response = endpoint.analyze_korean_text(request)
            self.assertEqual(response.status_code, 200)

        self.assertEqual(gate.consumed, ["verified-user"])
        self.assertEqual(len(receipts.completed), 2)

    def test_in_flight_analysis_retry_skips_consume_before_success(self):
        gate = _RecordingGate()
        receipts = _MemoryIdempotency()
        held: list[object] = []

        def hang(**_kwargs):
            held.append(object())
            raise RuntimeError("first attempt still running")

        with self.app.test_request_context(
            "/", method="POST", json={"text": "학생이에요.", "lang": "de"}
        ):
            with mock.patch.object(
                endpoint,
                "verify_caller",
                return_value=Caller(uid="verified-user", app_id="approved-app"),
            ), mock.patch.object(
                endpoint, "_quota_gate", return_value=gate
            ), mock.patch.object(
                endpoint, "_idempotency_gate", return_value=receipts
            ), mock.patch.object(
                endpoint, "_complete_book_analysis", side_effect=hang
            ):
                first = endpoint.analyze_korean_text(request)

        self.assertEqual(first.status_code, 503)
        self.assertEqual(gate.consumed, ["verified-user"])
        self.assertEqual(gate.released, ["verified-user"])
        self.assertEqual(len(receipts.abandoned), 1)

        with self.app.test_request_context(
            "/", method="POST", json={"text": "학생이에요.", "lang": "de"}
        ):
            with mock.patch.object(
                endpoint,
                "verify_caller",
                return_value=Caller(uid="verified-user", app_id="approved-app"),
            ), mock.patch.object(
                endpoint, "_quota_gate", return_value=gate
            ), mock.patch.object(
                endpoint, "_idempotency_gate", return_value=receipts
            ), mock.patch.object(
                endpoint,
                "_complete_book_analysis",
                return_value=endpoint._analysis_response("de"),
            ):
                second = endpoint.analyze_korean_text(request)

        self.assertEqual(second.status_code, 200)
        self.assertEqual(gate.consumed, ["verified-user", "verified-user"])

    def test_dictionary_exception_also_releases_quota(self):
        gate = _RecordingGate()
        with self.app.test_request_context(
            "/", method="POST", json={"word": "제사"}
        ):
            with mock.patch.object(
                endpoint,
                "verify_caller",
                return_value=Caller(uid="verified-user", app_id="approved-app"),
            ), mock.patch.object(
                endpoint, "_dictionary_quota_gate", return_value=gate
            ), mock.patch.object(
                endpoint,
                "validate_exact_noun",
                side_effect=RuntimeError("krdic down"),
            ):
                response = endpoint.validate_kkeunmari_word(request)

        self.assertEqual(response.status_code, 503)
        self.assertEqual(gate.consumed, ["verified-user"])
        self.assertEqual(gate.released, ["verified-user"])


class _RecordingGate:
    def __init__(self):
        self.consumed: list[str] = []
        self.released: list[str] = []

    def consume(self, uid: str) -> None:
        self.consumed.append(uid)

    def release(self, uid: str) -> None:
        self.released.append(uid)


class _MemoryIdempotency:
    def __init__(self):
        self.keys: set[str] = set()
        self.completed: list[tuple[str, str]] = []
        self.abandoned: list[tuple[str, str]] = []

    def claim(self, document_id: str, *, kind: str) -> bool:
        if document_id in self.keys:
            return False
        self.keys.add(document_id)
        return True

    def complete(self, document_id: str, kind: str) -> None:
        self.keys.add(document_id)
        self.completed.append((document_id, kind))

    def abandon(self, document_id: str, kind: str) -> None:
        self.keys.discard(document_id)
        self.abandoned.append((document_id, kind))


if __name__ == "__main__":
    unittest.main()
