#!/usr/bin/env bash
# tool/ops/apply_alerts.sh
#
# Applies every policy in tool/ops/alert_policies/*.json to Cloud Monitoring via
# `gcloud alpha monitoring policies create --policy-from-file=...`. Never updates
# or deletes an existing policy — rerunning this creates duplicates, which is
# intentional (review + delete the old one by hand rather than have a script
# silently mutate live alerting config).
#
# Requires env vars GCP_PROJECT=ko-lernen-app and NOTIFICATION_CHANNEL_ID (see
# tool/ops/.env.ops.example). Run tool/ops/log_metrics.sh first — policy 03
# depends on the log-based metrics it creates.
#
# Usage:
#   GCP_PROJECT=ko-lernen-app NOTIFICATION_CHANNEL_ID=xxxx bash tool/ops/apply_alerts.sh
#   GCP_PROJECT=ko-lernen-app NOTIFICATION_CHANNEL_ID=xxxx bash tool/ops/apply_alerts.sh --dry-run

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
if [[ "${GCP_PROJECT}" != "ko-lernen-app" ]]; then
  echo "ERROR: GCP_PROJECT must be exactly 'ko-lernen-app', got '${GCP_PROJECT}'." >&2
  exit 1
fi
if [[ -z "${NOTIFICATION_CHANNEL_ID:-}" ]]; then
  echo "ERROR: NOTIFICATION_CHANNEL_ID env var is required. Create a channel first:" >&2
  echo "  gcloud alpha monitoring channels create --project=ko-lernen-app --display-name=... --type=email --channel-labels=email_address=..." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY_DIR="${SCRIPT_DIR}/alert_policies"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

printf '%-40s %-10s %s\n' "POLICY FILE" "STATUS" "POLICY NAME / ERROR"
printf '%-40s %-10s %s\n' "----------------------------------------" "----------" "--------------------"

for policy_file in "${POLICY_DIR}"/[0-9]*.json; do
  base="$(basename "${policy_file}")"
  tmp_file="${WORK_DIR}/${base}"

  # Strip metadata keys (anything starting with "_") that are not part of the
  # AlertPolicy API schema, then substitute the notification channel placeholder.
  python3 - "${policy_file}" "${tmp_file}" "${NOTIFICATION_CHANNEL_ID}" <<'PYEOF'
import json, sys
src, dst, channel_id = sys.argv[1], sys.argv[2], sys.argv[3]
with open(src, encoding="utf-8") as f:
    policy = json.load(f)
policy = {k: v for k, v in policy.items() if not k.startswith("_")}
raw = json.dumps(policy)
raw = raw.replace("${NOTIFICATION_CHANNEL_ID}", channel_id)
with open(dst, "w", encoding="utf-8") as f:
    f.write(raw)
PYEOF

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '%-40s %-10s %s\n' "${base}" "DRY-RUN" "gcloud alpha monitoring policies create --project=${GCP_PROJECT} --policy-from-file=${tmp_file}"
    continue
  fi

  if output=$(gcloud alpha monitoring policies create \
      --project="${GCP_PROJECT}" \
      --policy-from-file="${tmp_file}" \
      --format="value(name)" 2>&1); then
    printf '%-40s %-10s %s\n' "${base}" "CREATED" "${output}"
  else
    printf '%-40s %-10s %s\n' "${base}" "FAILED" "${output//$'\n'/ }"
  fi
done

echo
echo "Receipt: paste the CREATED policy name/ID rows above into docs/runbooks/ops-alerts.md § 적용 영수증."
echo "Verify with: gcloud alpha monitoring policies list --project=${GCP_PROJECT}"
