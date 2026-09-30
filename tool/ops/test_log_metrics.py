"""Regression coverage for ambiguous reads/writes and counter configuration drift."""
import contextlib
import copy
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import Mock, patch
import urllib.error

from tool.ops import log_metrics as ops


class FakeAPI:
    def __init__(self, existing=None):
        self.metrics = copy.deepcopy(existing or {})
        self.calls = []
        self.read_failures = {}
        self.write_error = None

    def request(self, method, name="", body=None):
        self.calls.append((method, name or body["name"]))
        if method == "GET":
            if name in self.read_failures:
                raise ops.OpsError(self.read_failures[name])
            return copy.deepcopy(self.metrics.get(name))
        if self.write_error:
            raise ops.OpsError(self.write_error)
        self.metrics[body["name"]] = copy.deepcopy(body)
        return copy.deepcopy(body)


class MetricApplyTests(unittest.TestCase):
    def setUp(self):
        self.metrics = ops.selected_metrics(None)
        self.output = io.StringIO()
        self.redirect = contextlib.redirect_stdout(self.output)
        self.redirect.__enter__()
        self.addCleanup(self.redirect.__exit__, None, None, None)

    def receipts(self):
        return [json.loads(line) for line in self.output.getvalue().splitlines()]

    def test_all_reads_precede_first_write_and_creation_is_verified(self):
        api = FakeAPI()
        ops.apply(api, self.metrics)
        self.assertEqual([c[0] for c in api.calls], ["GET"] * 3 + ["POST", "GET"] * 3)
        self.assertEqual([r["status"] for r in self.receipts()], ["create_requested", "created"] * 3)
        self.assertTrue(all(r["eventDeliveryVerified"] is False for r in self.receipts() if r["status"] == "created"))

    def test_dry_run_reads_all_without_writes(self):
        api = FakeAPI()
        ops.apply(api, self.metrics, dry_run=True)
        self.assertEqual([c[0] for c in api.calls], ["GET"] * 3)
        self.assertEqual([r["status"] for r in self.receipts()], ["would_create"] * 3)

    def test_matching_existing_counter_is_not_recreated(self):
        api = FakeAPI({m["name"]: m for m in self.metrics})
        ops.apply(api, self.metrics)
        self.assertEqual([c[0] for c in api.calls], ["GET"] * 3)
        self.assertEqual([r["status"] for r in self.receipts()], ["unchanged"] * 3)

    def test_api_resource_metadata_matches_on_get_and_post(self):
        api = FakeAPI()
        original = api.request

        def add_metadata(method, name="", body=None):
            response = original(method, name, body)
            if response is not None:
                response["resourceName"] = f"projects/{ops.PROJECT}/metrics/{response['name']}"
                response["metricDescriptor"]["monitoredResourceTypes"] = ["cloud_run_revision"]
            return response

        api.request = add_metadata
        ops.apply(api, self.metrics)
        ops.apply(api, self.metrics)
        self.assertEqual([r["status"] for r in self.receipts()], ["create_requested", "created"] * 3 + ["unchanged"] * 3)

    def test_late_read_failure_prevents_earlier_missing_metric_creation(self):
        for error in ("logging_http_403", "logging_http_429", "logging_request_failed"):
            with self.subTest(error=error):
                api = FakeAPI()
                api.read_failures[self.metrics[-1]["name"]] = error
                with self.assertRaisesRegex(ops.OpsError, error):
                    ops.apply(api, self.metrics)
                self.assertFalse(any(c[0] == "POST" for c in api.calls))

    def test_late_configuration_drift_prevents_all_writes(self):
        metric = copy.deepcopy(self.metrics[-1])
        metric["filter"] += ' AND jsonPayload.uid="private"'
        api = FakeAPI({metric["name"]: metric})
        with self.assertRaisesRegex(ops.OpsError, "metric_configuration_drift"):
            ops.apply(api, self.metrics)
        self.assertFalse(any(c[0] == "POST" for c in api.calls))
        self.assertNotIn("private", self.output.getvalue())

    def test_uncertain_write_is_not_retried(self):
        api = FakeAPI()
        api.write_error = "logging_request_failed"
        with self.assertRaisesRegex(ops.OpsError, "logging_request_failed"):
            ops.apply(api, self.metrics)
        self.assertEqual(sum(c[0] == "POST" for c in api.calls), 1)
        self.assertEqual([r["status"] for r in self.receipts()], ["create_requested"])

    def test_successful_first_receipt_survives_second_write_failure(self):
        api = FakeAPI()
        original = api.request

        def fail_second(method, name="", body=None):
            if method == "POST" and body["name"] == self.metrics[1]["name"]:
                api.write_error = "logging_http_409"
            return original(method, name, body)

        api.request = fail_second
        with self.assertRaisesRegex(ops.OpsError, "logging_http_409"):
            ops.apply(api, self.metrics)
        self.assertEqual([r["status"] for r in self.receipts()], ["create_requested", "created", "create_requested"])

    def test_post_create_read_mismatch_blocks_next_write(self):
        api = Mock()
        api.request.side_effect = [None, None, None, self.metrics[0], None]
        with self.assertRaisesRegex(ops.OpsError, "metric_post_create_mismatch"):
            ops.apply(api, self.metrics)
        self.assertEqual(api.request.call_count, 5)
        self.assertNotIn('"status": "created"', self.output.getvalue())

    def test_post_response_mismatch_blocks_next_write(self):
        api = Mock()
        api.request.side_effect = [None, None, None, {}]
        with self.assertRaisesRegex(ops.OpsError, "metric_create_response_mismatch"):
            ops.apply(api, self.metrics)
        self.assertEqual(api.request.call_count, 4)

    def test_cli_project_and_duplicate_selection_fail_before_auth(self):
        name = self.metrics[0]["name"]
        for env, args in (({}, []), ({"GCP_PROJECT": "other"}, []), ({"GCP_PROJECT": ops.PROJECT}, ["--metric", name, "--metric", name])):
            with self.subTest(env=env, args=args), patch.dict(os.environ, env, clear=True), patch.object(ops, "access_token") as token:
                self.assertEqual(ops.main(args), 1)
                token.assert_not_called()

    def test_selection_limits_requests(self):
        metrics = ops.selected_metrics([self.metrics[2]["name"]])
        api = FakeAPI()
        ops.apply(api, metrics, True)
        self.assertEqual(api.calls, [("GET", self.metrics[2]["name"])])


class ConfigurationTests(unittest.TestCase):
    def setUp(self):
        self.desired = ops.selected_metrics(None)[0]

    def test_documented_metadata_and_empty_defaults_match(self):
        actual = copy.deepcopy(self.desired)
        actual.update(createTime="timestamp", updateTime="timestamp", version="V2", disabled=False,
                      bucketName="", valueExtractor="", labelExtractors={}, bucketOptions={})
        actual["metricDescriptor"].update(name="derived", type="derived", description="derived", labels=[])
        before = copy.deepcopy(actual)
        self.assertTrue(ops.same_configuration(self.desired, actual))
        self.assertEqual(actual, before)

    def test_drift_and_malformed_configuration_fail_closed(self):
        changes = [
            ("filter", "different"), ("name", "different"), ("description", "different"),
            ("disabled", True), ("disabled", 0), ("disabled", None), ("version", "V1"),
            ("bucketName", "projects/other/locations/global/buckets/private"),
            ("labelExtractors", {"uid": "EXTRACT(jsonPayload.uid)"}),
            ("valueExtractor", "EXTRACT(jsonPayload.value)"),
            ("bucketOptions", {"linearBuckets": {"numFiniteBuckets": 5}}),
            ("unknownConfiguration", True), ("metricDescriptor", None), ("metricDescriptor", []),
            ("resourceName", "projects/other/metrics/ai_cost_breaker_unavailable"),
            ("resourceName", f"projects/{ops.PROJECT}/metrics/other"), ("resourceName", None),
        ]
        for key, value in changes:
            with self.subTest(key=key, value=value):
                actual = copy.deepcopy(self.desired)
                actual[key] = value
                self.assertFalse(ops.same_configuration(self.desired, actual))
        for key, value in (("metricKind", "GAUGE"), ("valueType", "DISTRIBUTION"), ("unit", "ms"), ("labels", [{"key": "uid"}]), ("displayName", "custom"), ("monitoredResourceTypes", "malformed"), ("monitoredResourceTypes", [3])):
            with self.subTest(descriptor=key):
                actual = copy.deepcopy(self.desired)
                actual["metricDescriptor"][key] = value
                self.assertFalse(ops.same_configuration(self.desired, actual))
        for actual in (None, [], {}, {"metricDescriptor": {}}, "private"):
            self.assertFalse(ops.same_configuration(self.desired, actual))


class TransportTests(unittest.TestCase):
    def setUp(self):
        self.api = ops.Logging("credential-must-not-escape")
        self.api.opener = Mock()
        self.metric = ops.selected_metrics(None)[0]

    def test_only_get_404_means_missing(self):
        for method in ("GET", "POST"):
            for code in (401, 403, 404, 409, 429, 500):
                with self.subTest(method=method, code=code):
                    self.api.opener.open.side_effect = urllib.error.HTTPError("private-url", code, "private-body", {}, None)
                    kwargs = {"name": self.metric["name"]} if method == "GET" else {"body": self.metric}
                    if method == "GET" and code == 404:
                        self.assertIsNone(self.api.request(method, **kwargs))
                    else:
                        with self.assertRaisesRegex(ops.OpsError, f"^logging_http_{code}$"):
                            self.api.request(method, **kwargs)
        self.assertEqual(self.api.opener.open.call_count, 12)

    def test_timeout_has_redacted_error_and_no_retry(self):
        self.api.opener.open.side_effect = TimeoutError("private token response")
        with self.assertRaisesRegex(ops.OpsError, "^logging_request_failed$"):
            self.api.request("POST", body=self.metric)
        self.api.opener.open.assert_called_once()

    def test_response_must_be_bounded_json_object(self):
        for raw in (b'[]', b'null', b'invalid private response', b'\xff', b'x' * (ops.MAX_BYTES + 1)):
            with self.subTest(raw_size=len(raw)):
                response = Mock()
                response.read.return_value = raw
                self.api.opener.open.return_value.__enter__ = Mock(return_value=response)
                self.api.opener.open.return_value.__exit__ = Mock(return_value=False)
                with self.assertRaises(ops.OpsError) as caught:
                    self.api.request("GET", self.metric["name"])
                self.assertNotIn("private", str(caught.exception))

    def test_host_project_and_operation_scope(self):
        invalid = [("DELETE", self.metric["name"], None), ("PUT", "", self.metric),
                   ("GET", "../other", None), ("GET", "https://attacker.test", None),
                   ("GET", self.metric["name"], {}), ("POST", "", {**self.metric, "filter": "other"})]
        for method, name, body in invalid:
            with self.subTest(method=method, name=name), self.assertRaises(ops.OpsError):
                self.api.request(method, name, body)
        self.api.opener.open.assert_not_called()
        self.api.opener.open.side_effect = TimeoutError()
        with self.assertRaises(ops.OpsError):
            self.api.request("GET", self.metric["name"])
        request = self.api.opener.open.call_args[0][0]
        self.assertEqual(request.full_url, ops.ROOT + "/" + self.metric["name"])
        self.assertEqual(request.get_header("Authorization"), "Bearer credential-must-not-escape")

    def test_redirect_rejected(self):
        with self.assertRaisesRegex(ops.OpsError, "logging_redirect_rejected"):
            ops.NoRedirect().redirect_request(None, None, 302, "", {}, "https://attacker.test")


class EntrypointTests(unittest.TestCase):
    def test_direct_python_entrypoint_requires_project(self):
        env = {k: v for k, v in os.environ.items() if k != "GCP_PROJECT"}
        result = subprocess.run([sys.executable, str(Path(ops.__file__)), "--dry-run"],
                                capture_output=True, text=True, env=env, check=False)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(json.loads(result.stdout)["error"], "expected_GCP_PROJECT_ko-lernen-app")


if __name__ == "__main__":
    unittest.main()
