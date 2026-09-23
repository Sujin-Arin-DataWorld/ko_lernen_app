"""Preflight and create CP2026 alert policies; never update/delete or retry writes.

Both platform wrappers use this entrypoint. Dry-run performs the same GET checks
as apply. Credentials stay in memory; stdout contains only minimal JSON receipts.
"""
import argparse
import copy
from datetime import datetime, timedelta, timezone
import http.client
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import urllib.error
import urllib.parse
import urllib.request

PROJECT = "ko-lernen-app"
PROJECT_NUMBER = "573567222361"
ROOT = f"https://monitoring.googleapis.com/v3/projects/{PROJECT}/"
POLICY_DIR = Path(__file__).resolve().parent / "alert_policies"
MAX_BYTES = 2 * 1024 * 1024


class OpsError(Exception):
    """Fixed error codes only: do not expose provider bodies or credentials."""


def channel_name(value):
    if re.fullmatch(r"[0-9]+", value):
        value = f"projects/{PROJECT}/notificationChannels/{value}"
    pattern = rf"projects/({PROJECT}|{PROJECT_NUMBER})/notificationChannels/([0-9]+)"
    match = re.fullmatch(pattern, value)
    if not match:
        raise OpsError("invalid_notification_channel")
    return f"projects/{PROJECT}/notificationChannels/{match[2]}"


def access_token():
    gcloud = shutil.which("gcloud")
    if not gcloud:
        raise OpsError("gcloud_not_found")
    try:
        result = subprocess.run(
            [gcloud, "auth", "print-access-token", f"--project={PROJECT}", "--quiet"],
            capture_output=True, text=True, timeout=30, check=False,
        )
    except (OSError, subprocess.SubprocessError):
        raise OpsError("gcloud_token_failed") from None
    token = result.stdout.strip()
    if result.returncode or not token or any(c.isspace() for c in token):
        raise OpsError("gcloud_token_failed")
    return token


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise OpsError("monitoring_redirect_rejected")


class Monitoring:
    def __init__(self, token):
        self.token = token
        self.opener = urllib.request.build_opener(NoRedirect())

    def request(self, method, path, params=None, body=None):
        # No caller-supplied host, project, query or arbitrary mutation endpoint.
        if method not in ("GET", "POST") or (method == "POST" and path != "alertPolicies"):
            raise OpsError("unsupported_monitoring_operation")
        if not re.fullmatch(r"(?:alertPolicies|timeSeries|notificationChannels/[0-9]+|metricDescriptors/[a-zA-Z0-9_./-]+)", path) or ".." in path:
            raise OpsError("invalid_monitoring_path")
        url = ROOT + path
        if params:
            url += "?" + urllib.parse.urlencode(params)
        data = None if body is None else json.dumps(body).encode("utf-8")
        req = urllib.request.Request(url, data=data, method=method, headers={
            "Authorization": f"Bearer {self.token}", "Content-Type": "application/json",
        })
        try:
            # urllib performs no retry. In particular, an ambiguous POST is not repeated.
            with self.opener.open(req, timeout=20) as response:
                raw = response.read(MAX_BYTES + 1)
            if len(raw) > MAX_BYTES:
                raise OpsError("monitoring_response_too_large")
            value = json.loads(raw)
            if not isinstance(value, dict):
                raise OpsError("monitoring_invalid_response")
            return value
        except urllib.error.HTTPError as error:
            raise OpsError(f"monitoring_http_{error.code}") from None
        except (OSError, ValueError, urllib.error.URLError, http.client.HTTPException):
            raise OpsError("monitoring_request_failed") from None


def load_policies(directory, selected, channel):
    selected = list(selected) if selected else ["01", "02", "03", "04", "05"]
    if len(selected) != len(set(selected)) or any(v not in {"01", "02", "03", "04", "05"} for v in selected):
        raise OpsError("invalid_policy_selection")
    result = []
    for number in sorted(selected):
        paths = list(directory.glob(f"{number}_*.json"))
        if len(paths) != 1:
            raise OpsError(f"missing_policy_{number}")
        policy = json.loads(paths[0].read_text(encoding="utf-8"))
        if policy.get("_unverified") is not False:
            raise OpsError(f"unverified_policy_{number}")
        if policy.get("notificationChannels") != ["${NOTIFICATION_CHANNEL_ID}"]:
            raise OpsError(f"invalid_policy_channel_{number}")
        for condition in policy["conditions"]:
            block = condition["conditionThreshold"]
            intervals = [block["duration"], *(a["alignmentPeriod"] for a in block["aggregations"])]
            if any(not re.fullmatch(r"[0-9]+s", v) for v in intervals):
                raise OpsError(f"invalid_evaluation_window_{number}")
            seconds = [int(v[:-1]) for v in intervals]
            if len(seconds) < 2 or any(v % 60 for v in seconds) or min(seconds[1:]) < 60 or seconds[0] + max(seconds[1:]) > 90000:
                raise OpsError(f"evaluation_window_exceeds_limits_{number}")
        policy = {k: v for k, v in policy.items() if not k.startswith("_")}
        policy["notificationChannels"] = [channel_name(channel)]
        policy["enabled"] = True
        result.append((number, policy))
    return result


def all_policies(api):
    policies, seen = [], set()
    token = ""
    for _ in range(100):
        params = {"pageSize": 100}
        if token:
            params["pageToken"] = token
        response = api.request("GET", "alertPolicies", params=params)
        page = response.get("alertPolicies", [])
        if not isinstance(page, list) or any(not isinstance(p, dict) for p in page):
            raise OpsError("invalid_policy_listing")
        policies.extend(page)
        token = response.get("nextPageToken", "")
        if not token:
            return policies
        if not isinstance(token, str) or token in seen:
            raise OpsError("invalid_policy_pagination")
        seen.add(token)
    raise OpsError("policy_pagination_limit")


def same_configuration(desired, actual):
    """Ignore documented output metadata/default encoding, never extra config."""
    def canonical(policy):
        policy = copy.deepcopy(policy)
        for key in ("name", "creationRecord", "mutationRecord", "validity"):
            policy.pop(key, None)
        # The API may materialize the default on GET after omitting it on POST.
        policy.setdefault("alertStrategy", {}).setdefault("notificationPrompts", ["OPENED"])
        policy["notificationChannels"] = [channel_name(c) for c in policy.get("notificationChannels", [])]
        for condition in policy.get("conditions", []):
            condition.pop("name", None)

        def normalize(value):
            if isinstance(value, dict):
                result = {}
                for key, item in value.items():
                    if key == "userLabels":
                        result[key] = item  # Map entry presence is significant, even "".
                        continue
                    item = normalize(item)
                    # Normalize known protobuf defaults only, not arbitrary map values.
                    if key in {"groupByFields", "denominatorAggregations", "notificationChannelStrategy"} and item == []:
                        continue
                    if key == "thresholdValue" and type(item) in (int, float) and item == 0:
                        continue
                    if (key, str(item)) in {
                        ("severity", "SEVERITY_UNSPECIFIED"),
                        ("evaluationMissingData", "EVALUATION_MISSING_DATA_UNSPECIFIED"),
                    }:
                        continue
                    result[key] = item
                return result
            if isinstance(value, list):
                return [normalize(v) for v in value]
            return value

        return normalize(policy)

    try:
        # enabled is a wrapper boolean, not interchangeable with a numeric value.
        if actual.get("enabled") is not True:
            return False
        validity = actual.get("validity", {})
        if not isinstance(validity, dict):
            return False
        code = validity.get("code", 0)
        # Invalid policies do not generate incidents, even if config is equal.
        if type(code) is not int or code != 0:
            return False
        return canonical(desired) == canonical(actual)
    except (OpsError, TypeError, AttributeError):
        return False


def preflight(api, policies, channel):
    resource = api.request("GET", "notificationChannels/" + channel.rsplit("/", 1)[1],
                           params={"fields": "name,enabled,verificationStatus"})
    if channel_name(resource.get("name", "")) != channel or resource.get("enabled") is not True or resource.get("verificationStatus") == "UNVERIFIED":
        raise OpsError("notification_channel_not_ready")
    metric_resources = {}
    for _, policy in policies:
        for condition in policy["conditions"]:
            block = condition["conditionThreshold"]
            for field in ("filter", "denominatorFilter"):
                if field not in block:
                    continue
                found = re.findall(r'metric\.type\s*=\s*"([a-zA-Z0-9_./-]+)"', block[field])
                if len(found) != 1:
                    raise OpsError("unsupported_policy_metric_filter")
                resources = re.findall(r'resource\.type\s*=\s*"([a-zA-Z0-9_./-]+)"', block[field])
                if len(resources) != 1:
                    raise OpsError("unsupported_policy_resource_filter")
                metric_resources.setdefault(found[0], set()).update(resources)
    for metric, requested_resources in sorted(metric_resources.items()):
        descriptor = api.request("GET", "metricDescriptors/" + metric,
                                 params={"fields": "type,metricKind,valueType,monitoredResourceTypes"})
        if descriptor.get("type") != metric or descriptor.get("metricKind") != "DELTA" or descriptor.get("valueType") != "INT64":
            raise OpsError("metric_descriptor_mismatch")
        supported = descriptor.get("monitoredResourceTypes")
        if (not isinstance(supported, list) or not supported or
                any(not isinstance(value, str) or not value for value in supported) or
                not requested_resources.issubset(supported)):
            raise OpsError("metric_resource_mismatch")
    for number, policy in policies:
        if number != "04":
            continue
        now = datetime.now(timezone.utc)
        response = api.request("GET", "timeSeries", params={
            "filter": policy["conditions"][0]["conditionThreshold"]["filter"],
            "interval.startTime": (now - timedelta(hours=24)).isoformat(),
            "interval.endTime": now.isoformat(), "view": "FULL", "pageSize": 100,
            "aggregation.alignmentPeriod": "86400s",
            "aggregation.perSeriesAligner": "ALIGN_SUM",
            "aggregation.crossSeriesReducer": "REDUCE_SUM",
        })
        try:
            positive = any(int(point["value"]["int64Value"]) > 0
                           for series in response.get("timeSeries", []) for point in series["points"])
        except (KeyError, TypeError, ValueError):
            raise OpsError("worker_series_invalid") from None
        if not positive:
            raise OpsError("worker_success_series_not_observed")
    existing = all_policies(api)
    plan = []
    for number, policy in policies:
        matches = [p for p in existing if p.get("displayName") == policy["displayName"] or
                   (p.get("userLabels", {}).get("pr") == policy["userLabels"]["pr"] and
                    p.get("userLabels", {}).get("component") == policy["userLabels"]["component"])]
        if len(matches) > 1:
            raise OpsError(f"duplicate_existing_policy_{number}")
        if matches and not same_configuration(policy, matches[0]):
            raise OpsError(f"existing_policy_drift_{number}")
        if matches and not re.fullmatch(rf"projects/({PROJECT}|{PROJECT_NUMBER})/alertPolicies/[0-9]+", matches[0].get("name", "")):
            raise OpsError("invalid_existing_policy_name")
        plan.append((number, policy, matches[0].get("name") if matches else None))
    return plan


def emit(value):
    print(json.dumps(value, ensure_ascii=True), flush=True)


def apply(api, policies, channel, *, dry_run):
    plan = preflight(api, policies, channel)  # Entire batch before the first POST.
    receipts = []
    for number, policy, existing in plan:
        if existing:
            status, name = "unchanged", existing
        elif dry_run:
            status, name = "would_create", None
        else:
            response = api.request("POST", "alertPolicies", body=policy)
            name = response.get("name", "")
            if not re.fullmatch(rf"projects/({PROJECT}|{PROJECT_NUMBER})/alertPolicies/[0-9]+", name):
                raise OpsError("create_response_invalid_check_live_state_before_retry")
            status = "created"
        receipt = {"policy": number, "status": status, "name": name, "dryRun": dry_run}
        receipts.append(receipt)
        emit(receipt)
    return receipts


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="Read-only live prerequisite checks")
    parser.add_argument("--policy", action="append", default=[], choices=["01", "02", "03", "04", "05"])
    args = parser.parse_args(argv)
    try:
        if os.environ.get("GCP_PROJECT") != PROJECT:
            raise OpsError("GCP_PROJECT_must_be_ko-lernen-app")
        channel = channel_name(os.environ.get("NOTIFICATION_CHANNEL_ID", ""))
        policies = load_policies(POLICY_DIR, args.policy, channel)
        apply(Monitoring(access_token()), policies, channel, dry_run=args.dry_run)
        return 0
    except OpsError as error:
        emit({"status": "failed", "error": str(error), "dryRun": args.dry_run})
        return 1
    except (OSError, ValueError, KeyError, TypeError):
        emit({"status": "failed", "error": "invalid_configuration_or_response", "dryRun": args.dry_run})
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
