import base64
import io
import json
import os
import sys
import unittest
from contextlib import redirect_stderr
from unittest import mock

import smoke_test


class SmokeAuthenticationContractTest(unittest.TestCase):
    @staticmethod
    def _app_check_token(app_id):
        payload = base64.urlsafe_b64encode(
            json.dumps({"sub": app_id}).encode("utf-8")
        ).decode("ascii").rstrip("=")
        return f"header.{payload}.signature"

    def test_request_headers_include_both_verified_credential_types(self):
        headers = smoke_test.request_headers("firebase-id-token", "app-check-token")

        self.assertEqual(headers["Content-Type"], "application/json")
        self.assertEqual(headers["Authorization"], "Bearer firebase-id-token")
        self.assertEqual(headers["X-Firebase-AppCheck"], "app-check-token")

    def test_environment_credentials_fail_closed_when_either_token_is_missing(self):
        with mock.patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(RuntimeError):
                smoke_test.credentials_from_environment()

    def test_tampered_app_check_token_changes_the_value(self):
        token = "header.payload.signature"

        tampered = smoke_test.tampered_app_check_token(token)

        self.assertNotEqual(tampered, token)
        self.assertEqual(len(tampered), len(token))
        self.assertEqual(tampered.split(".")[:2], token.split(".")[:2])
        self.assertNotEqual(tampered.split(".")[2], token.split(".")[2])

    def test_app_check_subject_identifies_the_smoke_platform(self):
        token = self._app_check_token("1:123:ios:expected")

        self.assertEqual(
            smoke_test.app_id_from_app_check_token(token),
            "1:123:ios:expected",
        )

    def test_smoke_stops_before_network_when_platform_token_is_wrong(self):
        token = self._app_check_token("1:123:android:actual")
        credentials = {
            "BOOK_ANALYSIS_ID_TOKEN": "firebase-id-token",
            "BOOK_ANALYSIS_APP_CHECK_TOKEN": token,
        }
        stderr = io.StringIO()

        with mock.patch.dict(os.environ, credentials, clear=True), mock.patch.object(
            smoke_test, "post"
        ) as post, redirect_stderr(stderr):
            exit_code = smoke_test.main(
                [
                    "https://example.invalid/function",
                    "en",
                    "--expected-app-id",
                    "1:123:ios:expected",
                ]
            )

        self.assertEqual(exit_code, 2)
        post.assert_not_called()
        self.assertNotIn(token, stderr.getvalue())
        self.assertNotIn("1:123:android:actual", stderr.getvalue())
        self.assertNotIn("1:123:ios:expected", stderr.getvalue())

    def test_smoke_selects_one_translation_language_and_keeps_quota_calls_low(self):
        successful = {
            "words": [
                {
                    "korean": "학교",
                    "pos": "Noun",
                    "translation": "school",
                    "example": "오늘은 학교에 가요.",
                }
            ],
            "expressions": [],
            "grammar": [],
            "sentences": [
                {"korean": "저는 Berlin에 살아요.", "translation": "I live in Berlin."},
                {"korean": "오늘은 학교에 가요.", "translation": "I go to school today."},
            ],
            "warnings": [
                "non_korean_segments_ignored",
                "unexpected_script_filtered",
            ],
            "analysisLanguage": "en",
        }
        responses = [
            (200, successful),
            (200, {"warnings": ["empty_text"]}),
            (400, {"warnings": ["text_too_long"]}),
            (200, {"warnings": ["no_korean_text"]}),
            (401, {"warnings": ["unauthenticated"]}),
            (401, {"warnings": ["unauthenticated"]}),
            (401, {"warnings": ["unauthenticated"]}),
        ]
        expected_app_id = "1:123:ios:expected"
        credentials = {
            "BOOK_ANALYSIS_ID_TOKEN": "firebase-id-token",
            "BOOK_ANALYSIS_APP_CHECK_TOKEN": self._app_check_token(
                expected_app_id
            ),
        }

        smoke_test._results.clear()
        with mock.patch.dict(os.environ, credentials, clear=True), mock.patch.object(
            sys,
            "argv",
            [
                "smoke_test.py",
                "https://example.invalid/function",
                "en",
                "--expected-app-id",
                expected_app_id,
            ],
        ), mock.patch.object(smoke_test, "post", side_effect=responses) as post:
            exit_code = smoke_test.main()

        self.assertEqual(exit_code, 0)
        self.assertEqual(post.call_count, 7)
        self.assertEqual(post.call_args_list[0].args[1]["lang"], "en")
        self.assertIn("Berlin에", post.call_args_list[0].args[1]["text"])
        signed_headers = post.call_args_list[0].kwargs["headers"]
        auth_only = post.call_args_list[4].kwargs["headers"]
        app_check_only = post.call_args_list[5].kwargs["headers"]
        tampered = post.call_args_list[6].kwargs["headers"]
        self.assertIn("Authorization", signed_headers)
        self.assertIn("X-Firebase-AppCheck", signed_headers)
        self.assertIn("Authorization", auth_only)
        self.assertNotIn("X-Firebase-AppCheck", auth_only)
        self.assertNotIn("Authorization", app_check_only)
        self.assertIn("X-Firebase-AppCheck", app_check_only)
        self.assertEqual(tampered["Authorization"], signed_headers["Authorization"])
        self.assertNotEqual(
            tampered["X-Firebase-AppCheck"], signed_headers["X-Firebase-AppCheck"]
        )
