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
)


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


if __name__ == "__main__":
    unittest.main()
