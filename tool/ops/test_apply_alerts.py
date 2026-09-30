"""Offline operator contracts: failures must precede writes; retries must not duplicate."""
import copy
import io
import http.client
import json
import tempfile
import unittest
import urllib.error
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch
from unittest.mock import MagicMock

from tool.ops import apply_alerts as app


CHANNEL = "projects/ko-lernen-app/notificationChannels/123"
POLICIES = Path(__file__).parent / "alert_policies"


class FakeApi:
    def __init__(self):
        self.calls = []
        self.existing = []
        self.channel = {"name": CHANNEL, "enabled": True,
                        "verificationStatus": "VERIFICATION_STATUS_UNSPECIFIED"}
        self.fail_metric = False
        self.worker_points = [{"value": {"int64Value": "1"}}]
        self.fail_create = False
        # Descriptor shapes read from Monitoring, not inferred from policy JSON.
        self.metric_resources = {
            "run.googleapis.com/request_count": ["cloud_run_instance", "cloud_run_revision"],
            "firebaseappcheck.googleapis.com/services/verification_count": ["firebaseappcheck.googleapis.com/Service"],
            "firestore.googleapis.com/document/write_count": ["firestore_instance"],
        }

    def request(self, method, path, params=None, body=None):
        self.calls.append((method, path, params, copy.deepcopy(body)))
        if path.startswith("notificationChannels/"):
            return self.channel
        if path.startswith("metricDescriptors/"):
            if self.fail_metric:
                raise app.OpsError("monitoring_http_404")
            metric = path.removeprefix("metricDescriptors/")
            return {"type": metric, "metricKind": "DELTA", "valueType": "INT64",
                    "monitoredResourceTypes": self.metric_resources[metric]}
        if path == "timeSeries":
            return {"timeSeries": [{"points": self.worker_points}]}
        if path == "alertPolicies" and method == "GET":
            return {"alertPolicies": self.existing}
        if path == "alertPolicies" and method == "POST":
            if self.fail_create:
                raise app.OpsError("monitoring_http_503")
            result = copy.deepcopy(body)
            result["name"] = "projects/ko-lernen-app/alertPolicies/456"
            self.existing.append(result)
            return result
        raise AssertionError((method, path))

    @property
    def posts(self):
        return [c for c in self.calls if c[0] == "POST"]


class ApplyAlertsTest(unittest.TestCase):
    def run_plan(self, api, selected=("01", "02", "04", "05"), dry_run=True):
        with redirect_stdout(io.StringIO()):
            return app.apply(api, app.load_policies(POLICIES, selected, CHANNEL),
                             CHANNEL, dry_run=dry_run)

    def test_dry_run_checks_all_prerequisites_without_any_writes(self):
        api = FakeApi()
        self.run_plan(api)
        self.assertEqual(api.posts, [])
        metrics = {c[1] for c in api.calls if c[1].startswith("metricDescriptors/")}
        self.assertIn("metricDescriptors/run.googleapis.com/request_count", metrics)
        self.assertEqual(len(metrics), 3)
        query = next(c[2] for c in api.calls if c[1] == "timeSeries")
        self.assertIn('resource.label."service_name"="account-deletion-worker"', query["filter"])
        self.assertIn('metric.label."response_code_class"="2xx"', query["filter"])

    def test_unverified_cost_policy_blocks_default_before_api_calls(self):
        with self.assertRaisesRegex(app.OpsError, "unverified_policy_03"):
            app.load_policies(POLICIES, (), CHANNEL)

    def test_over_limit_worker_window_fails_local_preflight(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = POLICIES / "04_deletion_worker_stalled.json"
            policy = json.loads(path.read_text(encoding="utf-8"))
            policy["conditions"][0]["conditionThreshold"]["duration"] = "90000s"
            (root / path.name).write_text(json.dumps(policy), encoding="utf-8")
            with self.assertRaisesRegex(app.OpsError, "evaluation_window_exceeds_limits_04"):
                app.load_policies(root, ("04",), CHANNEL)

    def test_disabled_unverified_and_wrong_channel_each_block_writes(self):
        for change in ({"enabled": False}, {"verificationStatus": "UNVERIFIED"},
                       {"name": "projects/other/notificationChannels/123"}):
            with self.subTest(change=change):
                api = FakeApi()
                api.channel.update(change)
                with self.assertRaises(app.OpsError):
                    self.run_plan(api, dry_run=False)
                self.assertEqual(api.posts, [])

    def test_project_number_channel_response_is_same_resource(self):
        api = FakeApi()
        api.channel["name"] = "projects/573567222361/notificationChannels/123"
        self.run_plan(api)

    def test_missing_metric_blocks_entire_batch(self):
        api = FakeApi()
        api.fail_metric = True
        with self.assertRaisesRegex(app.OpsError, "404"):
            self.run_plan(api, dry_run=False)
        self.assertEqual(api.posts, [])

    def test_actual_firestore_resource_accepts_write_policy(self):
        api = FakeApi()
        policies = app.load_policies(POLICIES, ("05",), CHANNEL)
        block = policies[0][1]["conditions"][0]["conditionThreshold"]
        self.assertIn('resource.type="firestore_instance"', block["filter"])
        with redirect_stdout(io.StringIO()):
            result = app.apply(api, policies, CHANNEL, dry_run=True)
        self.assertEqual(result[0]["status"], "would_create")
        self.assertEqual(api.posts, [])

    def test_incompatible_firestore_resource_blocks_whole_batch_before_write(self):
        api = FakeApi()
        policies = app.load_policies(POLICIES, ("01", "05"), CHANNEL)
        block = policies[1][1]["conditions"][0]["conditionThreshold"]
        block["filter"] = 'resource.type="firestore.googleapis.com/Database" AND metric.type="firestore.googleapis.com/document/write_count"'
        with redirect_stdout(io.StringIO()), self.assertRaisesRegex(app.OpsError, "metric_resource_mismatch"):
            app.apply(api, policies, CHANNEL, dry_run=False)
        self.assertEqual(api.posts, [])

    def test_incompatible_denominator_resource_cannot_pass_numerator_check(self):
        api = FakeApi()
        policies = app.load_policies(POLICIES, ("01",), CHANNEL)
        block = policies[0][1]["conditions"][0]["conditionThreshold"]
        block["denominatorFilter"] = block["denominatorFilter"].replace('"cloud_run_revision"', '"firestore_instance"')
        with redirect_stdout(io.StringIO()), self.assertRaisesRegex(app.OpsError, "metric_resource_mismatch"):
            app.apply(api, policies, CHANNEL, dry_run=False)
        self.assertEqual(api.posts, [])

    def test_unrestricted_descriptor_accepts_missing_or_empty_resource_list(self):
        for omitted in (False, True):
            with self.subTest(omitted=omitted):
                api = FakeApi()
                api.metric_resources["run.googleapis.com/request_count"] = []
                original = api.request

                def unrestricted(method, path, params=None, body=None):
                    result = original(method, path, params, body)
                    if omitted and path.startswith("metricDescriptors/"):
                        result.pop("monitoredResourceTypes", None)
                    return result

                api.request = unrestricted
                result = self.run_plan(api, selected=("01",), dry_run=False)
                self.assertEqual(result[0]["status"], "created")
                self.assertEqual(len(api.posts), 1)

    def test_unrestricted_first_metric_does_not_bypass_later_incompatible_metric(self):
        api = FakeApi()
        # Descriptors are checked in sorted metric order: Firestore before Run.
        api.metric_resources["firestore.googleapis.com/document/write_count"] = []
        api.metric_resources["run.googleapis.com/request_count"] = ["firestore_instance"]
        with self.assertRaisesRegex(app.OpsError, "metric_resource_mismatch"):
            self.run_plan(api, selected=("01", "05"), dry_run=False)
        self.assertEqual(
            [call[1] for call in api.calls if call[1].startswith("metricDescriptors/")],
            ["metricDescriptors/firestore.googleapis.com/document/write_count",
             "metricDescriptors/run.googleapis.com/request_count"],
        )
        self.assertEqual(api.posts, [])

    def test_malformed_resource_contract_blocks_writes(self):
        for resources in (None, "cloud_run_revision", [None], [""], ["cloud_run_revision", 1]):
            api = FakeApi()
            api.metric_resources["run.googleapis.com/request_count"] = resources
            with self.subTest(resources=resources), redirect_stdout(io.StringIO()):
                with self.assertRaisesRegex(app.OpsError, "metric_resource_mismatch"):
                    self.run_plan(api, selected=("01",), dry_run=False)
                self.assertEqual(api.posts, [])

    def test_absent_zero_and_malformed_worker_series_cannot_arm_liveness(self):
        for points in ([], [{"value": {"int64Value": "0"}}],
                       [{"value": {"int64Value": "unknown"}}]):
            api = FakeApi()
            api.worker_points = points
            with self.subTest(points=points), self.assertRaises(app.OpsError):
                self.run_plan(api, dry_run=False)
            self.assertEqual(api.posts, [])

    def test_same_configuration_skips_even_with_server_metadata(self):
        api = FakeApi()
        existing = app.load_policies(POLICIES, ("01",), CHANNEL)[0][1]
        existing["name"] = "projects/573567222361/alertPolicies/456"
        existing["conditions"][0]["name"] = "server-condition-id"
        existing["creationRecord"] = {"mutateTime": "2026-09-01T00:00:00Z"}
        existing["notificationChannels"] = ["projects/573567222361/notificationChannels/123"]
        api.existing = [existing]
        result = self.run_plan(api, selected=("01",), dry_run=False)
        self.assertEqual(result[0]["status"], "unchanged")
        self.assertEqual(api.posts, [])

    def test_changed_threshold_or_disabled_existing_policy_blocks(self):
        for disabled in (False, True):
            api = FakeApi()
            existing = app.load_policies(POLICIES, ("02",), CHANNEL)[0][1]
            existing["name"] = "projects/ko-lernen-app/alertPolicies/456"
            if disabled:
                existing["enabled"] = False
            else:
                existing["conditions"][0]["conditionThreshold"]["thresholdValue"] = 999
            api.existing = [existing]
            with self.subTest(disabled=disabled), self.assertRaisesRegex(app.OpsError, "drift"):
                self.run_plan(api, dry_run=False)
            self.assertEqual(api.posts, [])

    def test_invalid_existing_policy_blocks_entire_batch_without_success_receipt(self):
        for validity in ({"code": 3, "message": "private provider details"},
                         {"code": 5}, {"code": "0"}, {"code": False}, None, []):
            api = FakeApi()
            existing = app.load_policies(POLICIES, ("02",), CHANNEL)[0][1]
            existing["name"] = "projects/ko-lernen-app/alertPolicies/456"
            existing["validity"] = validity
            api.existing = [existing]
            output = io.StringIO()
            with self.subTest(validity=validity), redirect_stdout(output):
                with self.assertRaisesRegex(app.OpsError, "existing_policy_drift_02"):
                    app.apply(api, app.load_policies(POLICIES, ("01", "02"), CHANNEL),
                              CHANNEL, dry_run=False)
                self.assertEqual(output.getvalue(), "")
                self.assertEqual(api.posts, [])

    def test_ok_or_omitted_validity_code_is_unchanged(self):
        for validity in ({}, {"code": 0}):
            api = FakeApi()
            existing = app.load_policies(POLICIES, ("01",), CHANNEL)[0][1]
            existing["name"] = "projects/ko-lernen-app/alertPolicies/456"
            existing["validity"] = validity
            api.existing = [existing]
            with self.subTest(validity=validity):
                self.assertEqual(self.run_plan(api, ("01",), False)[0]["status"], "unchanged")
                self.assertEqual(api.posts, [])

    def test_server_default_opened_prompt_does_not_duplicate_on_second_invocation(self):
        api = FakeApi()
        first = self.run_plan(api, ("01",), False)
        api.existing[0].setdefault("alertStrategy", {})["notificationPrompts"] = ["OPENED"]
        second = self.run_plan(api, ("01",), False)
        self.assertEqual((first[0]["status"], second[0]["status"]), ("created", "unchanged"))
        self.assertEqual(len(api.posts), 1)

    def test_different_or_unknown_notification_prompts_remain_drift(self):
        desired = app.load_policies(POLICIES, ("01",), CHANNEL)[0][1]
        for prompts in (["OPENED", "CLOSED"], ["CLOSED"], ["NOTIFICATION_PROMPT_UNSPECIFIED"]):
            actual = copy.deepcopy(desired)
            actual.setdefault("alertStrategy", {})["notificationPrompts"] = prompts
            with self.subTest(prompts=prompts):
                self.assertFalse(app.same_configuration(desired, actual))

    def test_duplicate_name_blocks_every_write(self):
        api = FakeApi()
        policy = app.load_policies(POLICIES, ("02",), CHANNEL)[0][1]
        api.existing = [policy, copy.deepcopy(policy)]
        with self.assertRaisesRegex(app.OpsError, "duplicate"):
            self.run_plan(api, dry_run=False)
        self.assertEqual(api.posts, [])

    def test_renamed_policy_with_same_ownership_blocks_instead_of_duplicating(self):
        api = FakeApi()
        existing = app.load_policies(POLICIES, ("01",), CHANNEL)[0][1]
        existing["displayName"] = "manually renamed"
        api.existing = [existing]
        with self.assertRaisesRegex(app.OpsError, "drift"):
            self.run_plan(api, dry_run=False)
        self.assertEqual(api.posts, [])

    def test_listing_reads_later_pages_and_rejects_a_repeated_token(self):
        api = FakeApi()
        original = api.request
        policy = app.load_policies(POLICIES, ("01",), CHANNEL)[0][1]
        policy["name"] = "projects/ko-lernen-app/alertPolicies/456"

        def paged(method, path, params=None, body=None):
            if path == "alertPolicies" and method == "GET":
                if "pageToken" not in params:
                    return {"alertPolicies": [], "nextPageToken": "second"}
                return {"alertPolicies": [policy]}
            return original(method, path, params, body)

        api.request = paged
        self.assertEqual(self.run_plan(api, ("01",), False)[0]["status"], "unchanged")
        api.request = lambda *args, **kwargs: {"nextPageToken": "same"}
        with self.assertRaisesRegex(app.OpsError, "pagination"):
            app.all_policies(api)

    def test_server_number_encoding_does_not_change_a_threshold(self):
        policy = app.load_policies(POLICIES, ("04",), CHANNEL)[0][1]
        actual = copy.deepcopy(policy)
        actual["conditions"][0]["conditionThreshold"]["thresholdValue"] = 1.0
        self.assertTrue(app.same_configuration(policy, actual))
        actual["enabled"] = 1
        self.assertFalse(app.same_configuration(policy, actual))

    def test_omitted_protojson_defaults_are_identical_but_extra_behavior_is_drift(self):
        desired = app.load_policies(POLICIES, ("02",), CHANNEL)[0][1]
        omitted = copy.deepcopy(desired)
        del omitted["conditions"][0]["conditionThreshold"]["aggregations"][0]["groupByFields"]
        self.assertTrue(app.same_configuration(desired, omitted))
        for key, value in (("evaluationMissingData", "EVALUATION_MISSING_DATA_ACTIVE"),
                           ("forecastOptions", {"forecastHorizon": "3600s"})):
            actual = copy.deepcopy(omitted)
            actual["conditions"][0]["conditionThreshold"][key] = value
            with self.subTest(key=key):
                self.assertFalse(app.same_configuration(desired, actual))

    def test_empty_user_label_addition_and_removal_remain_visible(self):
        desired = app.load_policies(POLICIES, ("02",), CHANNEL)[0][1]
        extra = copy.deepcopy(desired)
        extra["userLabels"]["manual_marker"] = ""
        self.assertFalse(app.same_configuration(desired, extra))
        self.assertFalse(app.same_configuration(extra, desired))

    def test_successful_create_then_second_invocation_does_not_duplicate(self):
        api = FakeApi()
        first = self.run_plan(api, selected=("01",), dry_run=False)
        second = self.run_plan(api, selected=("01",), dry_run=False)
        self.assertEqual((first[0]["status"], second[0]["status"]), ("created", "unchanged"))
        self.assertEqual(len(api.posts), 1)
        body = api.posts[0][3]
        self.assertTrue(body["enabled"])
        self.assertFalse(any(k.startswith("_") for k in body))

    def test_ambiguous_create_failure_is_not_retried_or_followed_by_next_write(self):
        api = FakeApi()
        api.fail_create = True
        with self.assertRaisesRegex(app.OpsError, "503"):
            self.run_plan(api, dry_run=False)
        self.assertEqual(len(api.posts), 1)

    def test_input_validation_rejects_wrong_project_channel_and_selection(self):
        for value in ("", "projects/other/notificationChannels/123", "123/../../x", "1?secret=x"):
            with self.subTest(value=value), self.assertRaises(app.OpsError):
                app.channel_name(value)
        self.assertEqual(app.channel_name("123"), CHANNEL)
        for selected in (("../01",), ("01", "01"), ("99",)):
            with self.subTest(selected=selected), self.assertRaises(app.OpsError):
                app.load_policies(POLICIES, selected, CHANNEL)

    def test_cli_failure_returns_nonzero_and_redacts_raw_transport_details(self):
        with patch.dict("os.environ", {"GCP_PROJECT": "ko-lernen-app", "NOTIFICATION_CHANNEL_ID": "123"}), \
             patch.object(app, "access_token", return_value="token-never-print"), \
             patch.object(app.Monitoring, "request", side_effect=app.OpsError("monitoring_http_403")), \
             redirect_stdout(io.StringIO()) as out:
            result = app.main(["--policy", "01"])
        self.assertNotEqual(result, 0)
        receipt = json.loads(out.getvalue())
        self.assertEqual(receipt["error"], "monitoring_http_403")
        self.assertNotIn("token-never-print", out.getvalue())


class MonitoringTransportTest(unittest.TestCase):
    def test_malformed_status_line_is_redacted_and_not_retried(self):
        api = app.Monitoring("private-token")
        api.opener = MagicMock()
        api.opener.open.side_effect = http.client.BadStatusLine("private-status-token")
        with self.assertRaisesRegex(app.OpsError, "^monitoring_request_failed$"):
            api.request("GET", "alertPolicies")
        api.opener.open.assert_called_once()

    def test_post_http_failure_is_attempted_once_and_body_not_exposed(self):
        api = app.Monitoring("private-token")
        api.opener = MagicMock()
        api.opener.open.side_effect = urllib.error.HTTPError(
            "https://provider.invalid/private", 503, "private-body", {}, io.BytesIO(b"private-body"))
        with self.assertRaisesRegex(app.OpsError, "^monitoring_http_503$"):
            api.request("POST", "alertPolicies", body={"displayName": "test"})
        api.opener.open.assert_called_once()
        request = api.opener.open.call_args.args[0]
        self.assertEqual(request.full_url, app.ROOT + "alertPolicies")
        self.assertEqual(api.opener.open.call_args.kwargs, {"timeout": 20})

    def test_redirects_are_rejected_without_forwarding_credentials(self):
        with self.assertRaisesRegex(app.OpsError, "redirect"):
            app.NoRedirect().redirect_request(None, None, 302, None, {}, "https://other.invalid")

    def test_response_size_and_json_shape_are_bounded(self):
        for raw in (b"x" * (app.MAX_BYTES + 1), b"[]", b"private invalid JSON"):
            api = app.Monitoring("private-token")
            api.opener = MagicMock()
            api.opener.open.return_value.__enter__.return_value.read.return_value = raw
            with self.subTest(size=len(raw)), self.assertRaises(app.OpsError):
                api.request("GET", "alertPolicies")
            api.opener.open.return_value.__enter__.return_value.read.assert_called_once_with(app.MAX_BYTES + 1)

    def test_arbitrary_hosts_queries_and_other_writes_are_rejected(self):
        for method, path in (("GET", "https://other.invalid"), ("GET", "alertPolicies?token=x"),
                             ("DELETE", "alertPolicies"), ("POST", "notificationChannels/123"),
                             ("GET", "metricDescriptors/../../other")):
            with self.subTest(method=method, path=path), self.assertRaises(app.OpsError):
                app.Monitoring("private-token").request(method, path)


if __name__ == "__main__":
    unittest.main()
