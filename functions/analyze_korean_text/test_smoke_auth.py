import os
import unittest
from unittest import mock

import smoke_test


class SmokeAuthenticationContractTest(unittest.TestCase):
    def test_request_headers_include_both_verified_credential_types(self):
        headers = smoke_test.request_headers("firebase-id-token", "app-check-token")

        self.assertEqual(headers["Content-Type"], "application/json")
        self.assertEqual(headers["Authorization"], "Bearer firebase-id-token")
        self.assertEqual(headers["X-Firebase-AppCheck"], "app-check-token")

    def test_environment_credentials_fail_closed_when_either_token_is_missing(self):
        with mock.patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(RuntimeError):
                smoke_test.credentials_from_environment()
