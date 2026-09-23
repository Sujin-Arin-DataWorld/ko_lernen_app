"""Verify/create the three CP2026 counters without updating or deleting metrics.

Only an explicit GET 404 means absent. Preflight all selected metrics before any
POST. Dry-run uses the same reads. Creation is not proof of event delivery.
"""
import argparse
import copy
import http.client
import json
import os
import urllib.error
import urllib.request

if __package__:
    from .apply_alerts import MAX_BYTES, PROJECT, OpsError, access_token
else:
    from apply_alerts import MAX_BYTES, PROJECT, OpsError, access_token

ROOT = f"https://logging.googleapis.com/v2/projects/{PROJECT}/metrics"
DEFINITIONS = {
    "ai_cost_breaker_unavailable": {
        "description": "Counts log entries where the AI cost-control breaker rejected a request (service_cost_controls/ai_v1 failed validation). See functions/pronunciation/service_cost_policy.js and functions/tts/service_cost_policy.js.",
        "filter": 'resource.type="cloud_run_revision" AND (textPayload:"AI cost approval unavailable" OR jsonPayload.message:"AI cost approval unavailable")',
    },
    "apple_revocation_config_invalid": {
        "description": "Counts log entries where Apple token-revocation config/secrets are invalid, so account deletion could not revoke the Apple grant. See functions/gye/apple_revocation_adapter.js.",
        "filter": 'resource.type="cloud_run_revision" AND (textPayload:"apple/revocation-config-invalid" OR jsonPayload.message:"apple/revocation-config-invalid" OR jsonPayload.error.code="apple/revocation-config-invalid")',
    },
    "auth_anonymous_account_created": {
        "description": "Auth creation event deliveries for accounts without a linked provider, email or phone. Includes Admin-created providerless accounts; duplicate deliveries are possible. Not login, token refresh or TTS request counts. See functions/gye/AUTH_CREATION_OBSERVATION.md.",
        "filter": 'resource.type="cloud_function" AND resource.labels.function_name="on_auth_account_created" AND jsonPayload.event="auth_account_created" AND jsonPayload.accountKind="anonymous" AND jsonPayload.schemaVersion=1',
    },
}


def selected_metrics(names):
    names = list(names) if names else list(DEFINITIONS)
    if len(names) != len(set(names)) or any(n not in DEFINITIONS for n in names):
        raise OpsError("invalid_metric_selection")
    return [{"name": n, **DEFINITIONS[n], "metricDescriptor": {
        "metricKind": "DELTA", "valueType": "INT64", "unit": "1",
    }} for n in names]


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise OpsError("logging_redirect_rejected")


class Logging:
    def __init__(self, token):
        self.token = token
        self.opener = urllib.request.build_opener(NoRedirect())

    def request(self, method, name="", body=None):
        if method == "GET":
            if name not in DEFINITIONS or body is not None:
                raise OpsError("invalid_logging_operation")
        elif method == "POST":
            if name or not isinstance(body, dict) or body not in selected_metrics(None):
                raise OpsError("invalid_logging_operation")
        else:
            raise OpsError("invalid_logging_operation")
        req = urllib.request.Request(
            ROOT + ("/" + name if name else ""), method=method,
            data=None if body is None else json.dumps(body).encode("utf-8"),
            headers={"Authorization": f"Bearer {self.token}", "Content-Type": "application/json"},
        )
        try:
            # No automatic retries, including uncertain POST outcomes.
            with self.opener.open(req, timeout=20) as response:
                raw = response.read(MAX_BYTES + 1)
            if len(raw) > MAX_BYTES:
                raise OpsError("logging_response_too_large")
            value = json.loads(raw)
            if not isinstance(value, dict):
                raise OpsError("logging_invalid_response")
            return value
        except urllib.error.HTTPError as error:
            if method == "GET" and error.code == 404:
                return None
            raise OpsError(f"logging_http_{error.code}") from None
        except (OSError, ValueError, http.client.HTTPException):
            raise OpsError("logging_request_failed") from None


def same_configuration(desired, actual):
    """Ignore documented output fields/default encodings, retain extra config."""
    def canonical(metric):
        metric = copy.deepcopy(metric)
        for key in ("createTime", "updateTime"):
            metric.pop(key, None)
        if metric.get("version") in ("V2", "VERSION_UNSPECIFIED"):
            metric.pop("version")
        if metric.get("disabled") is False:
            metric.pop("disabled")
        for key, default in (("bucketName", ""), ("valueExtractor", ""), ("labelExtractors", {}), ("bucketOptions", {})):
            if metric.get(key) == default:
                metric.pop(key)
        descriptor = metric["metricDescriptor"]
        for key in ("name", "type", "description"):
            descriptor.pop(key, None)
        if descriptor.get("labels") == []:
            descriptor.pop("labels")
        return metric

    try:
        if not isinstance(actual, dict) or type(actual.get("disabled", False)) is not bool:
            return False
        resource_name = actual.get("resourceName", f"projects/{PROJECT}/metrics/{desired['name']}")
        if resource_name != f"projects/{PROJECT}/metrics/{desired['name']}":
            return False
        actual = copy.deepcopy(actual)
        actual.pop("resourceName", None)
        # These are API-derived resource compatibility metadata, not custom labels.
        descriptor = actual["metricDescriptor"]
        resource_types = descriptor.pop("monitoredResourceTypes", [])
        if not isinstance(resource_types, list) or any(not isinstance(v, str) for v in resource_types):
            return False
        return canonical(desired) == canonical(actual)
    except (KeyError, TypeError, AttributeError):
        return False


def emit(value):
    print(json.dumps(value, sort_keys=True), flush=True)


def apply(api, metrics, dry_run=False):
    pending = []
    # A late read failure/drift prevents ALL writes in this batch.
    for metric in metrics:
        actual = api.request("GET", metric["name"])
        if actual is not None and not same_configuration(metric, actual):
            raise OpsError("metric_configuration_drift:" + metric["name"])
        pending.append((metric, actual is None))
    for metric, missing in pending:
        status = "unchanged"
        if missing:
            status = "would_create"
            if not dry_run:
                # Intent receipt survives partial success/uncertain write outcomes.
                emit({"metric": metric["name"], "status": "create_requested", "project": PROJECT})
                created = api.request("POST", body=metric)
                if not same_configuration(metric, created):
                    raise OpsError("metric_create_response_mismatch:" + metric["name"])
                if not same_configuration(metric, api.request("GET", metric["name"])):
                    raise OpsError("metric_post_create_mismatch:" + metric["name"])
                status = "created"
        emit({"metric": metric["name"], "status": status, "project": PROJECT,
              "eventDeliveryVerified": False})


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--metric", action="append", choices=list(DEFINITIONS))
    args = parser.parse_args(argv)
    try:
        if os.environ.get("GCP_PROJECT") != PROJECT:
            raise OpsError("expected_GCP_PROJECT_ko-lernen-app")
        metrics = selected_metrics(args.metric)
        apply(Logging(access_token()), metrics, args.dry_run)
    except OpsError as error:
        emit({"status": "failed", "error": str(error)})
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
