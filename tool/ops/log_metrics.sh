#!/usr/bin/env bash
# tool/ops/log_metrics.sh
#
# Creates the two policy-03 log metrics and B3 Auth creation observation metric.
# Idempotent: describes each metric first and skips creation if it
# already exists. Never mutates an existing metric's filter (delete + recreate
# by hand if the filter needs to change — this script will not silently
# overwrite one).
#
# Usage:
#   GCP_PROJECT=ko-lernen-app bash tool/ops/log_metrics.sh
#   GCP_PROJECT=ko-lernen-app bash tool/ops/log_metrics.sh --dry-run
#
# Docs: https://cloud.google.com/logging/docs/logs-based-metrics/counter-metrics
# (gcloud logging metrics create NAME --description=... --log-filter=...;
# referenced in Cloud Monitoring as logging.googleapis.com/user/NAME).

set -euo pipefail

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

if [[ -z "${GCP_PROJECT:-}" ]]; then
  echo "ERROR: GCP_PROJECT env var is required (expected: ko-lernen-app)." >&2
  exit 1
fi

create_metric() {
  local name="$1" description="$2" filter="$3"

  echo "--- ${name} ---"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] gcloud logging metrics describe ${name} --project=${GCP_PROJECT}"
    echo "[dry-run] (if missing) gcloud logging metrics create ${name} --project=${GCP_PROJECT} --description=\"${description}\" --log-filter=\"${filter}\""
    return 0
  fi

  if gcloud logging metrics describe "${name}" --project="${GCP_PROJECT}" >/dev/null 2>&1; then
    echo "already exists, skipping create (delete + rerun to change the filter): ${name}"
    return 0
  fi

  gcloud logging metrics create "${name}" \
    --project="${GCP_PROJECT}" \
    --description="${description}" \
    --log-filter="${filter}"
  echo "created: ${name}"
}

create_metric \
  "ai_cost_breaker_unavailable" \
  "Counts log entries where the AI cost-control breaker rejected a request (service_cost_controls/ai_v1 failed validation). See functions/pronunciation/service_cost_policy.js and functions/tts/service_cost_policy.js." \
  'resource.type="cloud_run_revision" AND (textPayload:"AI cost approval unavailable" OR jsonPayload.message:"AI cost approval unavailable")'

create_metric \
  "apple_revocation_config_invalid" \
  "Counts log entries where Apple token-revocation config/secrets are invalid, so account deletion could not revoke the Apple grant. See functions/gye/apple_revocation_adapter.js." \
  'resource.type="cloud_run_revision" AND (textPayload:"apple/revocation-config-invalid" OR jsonPayload.message:"apple/revocation-config-invalid" OR jsonPayload.error.code="apple/revocation-config-invalid")'

create_metric \
  "auth_anonymous_account_created" \
  "Auth creation event deliveries for accounts without a linked provider, email or phone. Includes Admin-created providerless accounts; duplicate deliveries are possible. Not login, token refresh or TTS request counts. See functions/gye/AUTH_CREATION_OBSERVATION.md." \
  'resource.type="cloud_function" AND resource.labels.function_name="on_auth_account_created" AND jsonPayload.event="auth_account_created" AND jsonPayload.accountKind="anonymous" AND jsonPayload.schemaVersion=1'

echo "Done. Verify with: gcloud logging metrics list --project=${GCP_PROJECT}"
