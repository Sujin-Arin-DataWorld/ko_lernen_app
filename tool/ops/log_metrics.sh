#!/usr/bin/env bash
# Shared read-before-write preflight; preserves the existing command entrypoint.
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec "${PYTHON:-python3}" "$SCRIPT_DIR/log_metrics.py" "$@"
