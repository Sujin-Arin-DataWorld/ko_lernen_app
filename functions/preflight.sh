#!/usr/bin/env bash
# CF 배포 전 사전점검 (preflight) — 네트워크 불필요, 전부 로컬.
# 배포 사이클 낭비 전에 설정 누락 / 문법 오류 / deploy 목록 누락을 잡는다.
#
# 사용:  bash functions/preflight.sh
# 통과 → exit 0, 하나라도 실패 → exit 1 (배포 중단 신호).
# 배포 절차 본문: docs/store/cloud-function-deploy.md

cd "$(dirname "$0")/.." || exit 2 # repo root
fail=0
ok() { printf '✅ %s\n' "$1"; }
bad() {
  printf '❌ %s\n' "$1"
  fail=1
}

echo "── analyze_korean_text (Python · gcloud) ──"
if [ -f functions/analyze_korean_text/.env ] &&
  grep -Eq '^DEEPL_API_KEY=.+' functions/analyze_korean_text/.env; then
  ok ".env DEEPL_API_KEY 설정됨"
else
  bad ".env 없음 또는 DEEPL_API_KEY 빈값 (functions/analyze_korean_text/.env) — gitignored, Jin 로컬에만"
fi
grep -q 'google-cloud-firestore' functions/analyze_korean_text/requirements.txt &&
  ok "requirements: google-cloud-firestore (번역 캐시)" ||
  bad "requirements: google-cloud-firestore 누락 → 번역 캐시 비활성"
python3 -m py_compile functions/analyze_korean_text/main.py 2>/dev/null &&
  ok "main.py py_compile" || bad "main.py 문법 오류"
[ -f functions/analyze_korean_text/smoke_test.py ] &&
  ok "smoke_test.py 존재" || bad "smoke_test.py 없음"

echo ""
echo "── gye (Node · firebase deploy) ──"
node --check functions/gye/index.js 2>/dev/null &&
  ok "gye/index.js 문법" || bad "gye/index.js 문법 오류"
for fn in on_pack_cleared weekly_goal_rollover on_report_created; do
  grep -q "exports.$fn" functions/gye/index.js &&
    ok "index.js exports: $fn" || bad "index.js exports 누락: $fn"
done
grep -q 'firebase-functions/v2' functions/gye/index.js &&
  ok "gye 함수: 2nd gen (v2 API)" ||
  bad "gye 함수가 v2(2nd gen) 아님 → europe-west3 Firestore 트리거 미지원"
grep -q 'europe-west3' functions/gye/index.js &&
  ok "gye region: europe-west3 (Firestore와 일치)" ||
  bad "gye region 미설정"
[ -f functions/gye/smoke_test.js ] &&
  ok "smoke_test.js 존재" || bad "smoke_test.js 없음"

echo ""
echo "── Firestore (rules · indexes) ──"
for fn in isAdmin isActiveGyeMember; do
  grep -q "function $fn" firestore.rules &&
    ok "rules: $fn()" || bad "rules: $fn() 누락"
done
for f in firestore.indexes.json firebase.json functions/gye/package.json; do
  python3 -c "import json;json.load(open('$f', encoding='utf-8'))" 2>/dev/null &&
    ok "JSON valid: $f" || bad "JSON 깨짐: $f"
done

echo ""
if [ "$fail" -eq 0 ]; then
  echo "🟢 PREFLIGHT PASS — cloud-function-deploy.md §2~7 배포 진행"
else
  echo "🔴 PREFLIGHT FAIL — 위 ❌ 수정 후 재실행"
  exit 1
fi
