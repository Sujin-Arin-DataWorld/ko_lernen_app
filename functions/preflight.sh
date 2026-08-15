#!/usr/bin/env bash
# Cloud deployment preflight. It is read-only and never deploys or mutates
# Firestore. Use `bash functions/preflight.sh analyze` to check only the Python
# book-analysis component, or omit the argument for repository-wide checks.

set -u
cd "$(dirname "$0")/.." || exit 2

component="${1:-all}"
case "$component" in
  all|analyze) ;;
  *)
    printf 'usage: bash functions/preflight.sh [all|analyze]\n' >&2
    exit 2
    ;;
esac

fail=0
ok() { printf '[PASS] %s\n' "$1"; }
bad() {
  printf '[FAIL] %s\n' "$1"
  fail=1
}

python_cmd=()
if [ -n "${ANALYSIS_PYTHON:-}" ] &&
  "$ANALYSIS_PYTHON" -c 'import sys;raise SystemExit(sys.version_info[:2] != (3, 12))' 2>/dev/null; then
  python_cmd=("$ANALYSIS_PYTHON")
elif command -v python >/dev/null 2>&1 &&
  python -c 'import sys;raise SystemExit(sys.version_info[:2] != (3, 12))' 2>/dev/null; then
  python_cmd=(python)
elif command -v python3.12 >/dev/null 2>&1 &&
  python3.12 -c 'import sys;raise SystemExit(sys.version_info[:2] != (3, 12))' 2>/dev/null; then
  python_cmd=(python3.12)
elif command -v py >/dev/null 2>&1 &&
  py -3.12 -c 'import sys;raise SystemExit(sys.version_info[:2] != (3, 12))' 2>/dev/null; then
  python_cmd=(py -3.12)
elif command -v python3 >/dev/null 2>&1 &&
  python3 -c 'import sys;raise SystemExit(sys.version_info[:2] != (3, 12))' 2>/dev/null; then
  python_cmd=(python3)
fi

printf '%s\n' '--- analyze_korean_text (Python / gcloud) ---'
if [ "${#python_cmd[@]}" -eq 0 ]; then
  bad 'Python 3.12 runtime not found'
else
  ok "Python $("${python_cmd[@]}" -c 'import platform;print(platform.python_version())')"
fi

analysis_dir='functions/analyze_korean_text'

if [ "${#python_cmd[@]}" -gt 0 ]; then
  if "${python_cmd[@]}" -c \
    'import deepl, firebase_admin, flask, functions_framework, kiwipiepy; from google.cloud import firestore' \
    >/dev/null 2>&1; then
    ok 'requirements imports available'
  else
    bad 'requirements imports failed; install requirements.txt into Python 3.12'
  fi

  if "${python_cmd[@]}" -m py_compile \
    "$analysis_dir/main.py" \
    "$analysis_dir/dictionary_validation.py" \
    "$analysis_dir/grammar_analysis.py" \
    "$analysis_dir/security.py" \
    "$analysis_dir/text_quality.py" \
    "$analysis_dir/smoke_test.py" \
    "$analysis_dir/verify_deployed_source.py" \
    "$analysis_dir/cleanup_translation_cache.py" 2>/dev/null; then
    ok 'runtime and operator Python modules compile'
  else
    bad 'Python module compilation failed'
  fi

  if "${python_cmd[@]}" "$analysis_dir/verify_deployed_source.py" \
    --check-gcloud-upload --check-app-ids >/dev/null; then
    ok 'upload closure and deploy App IDs match actual mobile configs'
  else
    bad 'source upload closure or mobile App ID contract drifted'
  fi

  test_output="$({
    cd "$analysis_dir" || exit 2
    "${python_cmd[@]}" -m unittest discover -s . -p 'test_*.py' -v
  } 2>&1)"
  test_status=$?
  if [ "$test_status" -eq 0 ] &&
    ! printf '%s\n' "$test_output" | grep -Eq 'skipped=[1-9][0-9]*'; then
    ok 'full unittest discovery passed with skip=0'
  else
    bad 'full unittest discovery failed or skipped tests'
    printf '%s\n' "$test_output"
  fi

  if (
    cd "$analysis_dir" || exit 2
    "${python_cmd[@]}" -m unittest test_translation_cache_contract.py >/dev/null
  ) 2>/dev/null; then
    ok 'translation_cache rule and expiresAt TTL JSON are exact'
  else
    bad 'translation_cache rule or expiresAt TTL JSON drifted'
  fi
fi

if [ "$component" = 'analyze' ]; then
  if [ "$fail" -eq 0 ]; then
    printf '%s\n' '[PASS] ANALYSIS PREFLIGHT COMPLETE - no deployment performed'
  else
    printf '%s\n' '[FAIL] ANALYSIS PREFLIGHT BLOCKED - no deployment performed'
    exit 1
  fi
  exit 0
fi

printf '\n%s\n' '--- gye (Node / Firebase) ---'
if node --check functions/gye/index.js 2>/dev/null; then
  ok 'gye/index.js syntax'
else
  bad 'gye/index.js syntax or Node PATH failure'
fi
for fn in on_pack_cleared weekly_goal_rollover on_report_created; do
  if grep -q "exports.$fn" functions/gye/index.js; then
    ok "index.js export: $fn"
  else
    bad "index.js export missing: $fn"
  fi
done
if grep -q 'firebase-functions/v2' functions/gye/index.js; then
  ok 'gye uses 2nd gen API'
else
  bad 'gye does not use firebase-functions/v2'
fi
if grep -q 'europe-west3' functions/gye/index.js; then
  ok 'gye region is europe-west3'
else
  bad 'gye region is missing'
fi
if [ -f functions/gye/smoke_test.js ]; then
  ok 'gye smoke_test.js exists'
else
  bad 'gye smoke_test.js missing'
fi

printf '\n%s\n' '--- Firestore configuration ---'
for fn in isAdmin isActiveGyeMember; do
  if grep -q "function $fn" firestore.rules; then
    ok "rules helper: $fn"
  else
    bad "rules helper missing: $fn"
  fi
done
if grep -Eq 'match /translation_cache/\{document=\*\*\}' firestore.rules; then
  ok 'translation_cache has an explicit server-only rule'
else
  bad 'translation_cache server-only rule missing'
fi
if [ "${#python_cmd[@]}" -gt 0 ]; then
  for file in firestore.indexes.json firebase.json functions/gye/package.json; do
    if "${python_cmd[@]}" -c \
      "import json;json.load(open('$file', encoding='utf-8'))" 2>/dev/null; then
      ok "valid JSON: $file"
    else
      bad "invalid JSON: $file"
    fi
  done
fi

printf '\n'
if [ "$fail" -eq 0 ]; then
  printf '%s\n' '[PASS] PREFLIGHT COMPLETE - no deployment performed'
else
  printf '%s\n' '[FAIL] PREFLIGHT BLOCKED - no deployment performed'
  exit 1
fi
