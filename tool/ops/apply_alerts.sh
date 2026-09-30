#!/usr/bin/env bash
# Shared preflight, JSON receipts and nonzero failure exit; no temporary files.
# --dry-run runs only GETs. Repeat --policy to select reviewed policies.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${PYTHON:-python3}" "${SCRIPT_DIR}/apply_alerts.py" "$@"
