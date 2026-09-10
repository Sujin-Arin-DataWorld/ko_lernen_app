#!/usr/bin/env bash
# graphify-out 정리기.
#
# graphify CLI 에는 prune/gc/보존기간 옵션이 없다. 그래서 산출물이 순증만 하다가
# 2026-09-09 에 graphify-out 이 950MB, 추적 파일 4,433개까지 불어났다. 이 스크립트가
# 그 정리 주체다. 규칙 전문은 AGENTS.md "## graphify".
#
# 원칙: 소스에서 무료로 복원되는 것만 지운다. LLM 이 만든 것은 절대 건드리지 않는다.
#
# 사용법:
#   tool/graphify_prune.sh            # dry-run (기본) — 무엇을 지울지만 보여준다
#   tool/graphify_prune.sh --apply    # 실제 삭제
#
# 환경변수:
#   GRAPHIFY_KEEP_SNAPSHOTS=2    날짜 스냅샷 유지 개수
#   GRAPHIFY_CACHE_MAX_AGE=30    cache/ast 보관 일수 (미접근 기준)

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUT="$ROOT/graphify-out"
KEEP="${GRAPHIFY_KEEP_SNAPSHOTS:-2}"
MAX_AGE="${GRAPHIFY_CACHE_MAX_AGE:-30}"

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

[ -d "$OUT" ] || { echo "graphify-out 없음 — 건너뜀"; exit 0; }
# rm -rf 가 엉뚱한 경로로 가지 않도록 방어.
case "$OUT" in */graphify-out) ;; *) echo "안전장치: OUT 경로가 graphify-out 이 아니다 ($OUT)"; exit 1;; esac

# 절대 건드리지 않는 것 — 소스에서 복원 불가능하다.
#   .graphify_labels.json(.sig)  LLM 커뮤니티 이름
#   cache/semantic/              LLM 의미 추출 (154개 파일분)
#   wiki/ GRAPH_REPORT.md manifest.json

freed=0
note() { printf '  %s\n' "$1"; }
kill_path() {
  local p="$1" sz
  sz=$(du -sk "$p" 2>/dev/null | cut -f1 || echo 0)
  freed=$((freed + sz))
  if [ "$APPLY" = 1 ]; then rm -rf "$p"; fi
  note "${p#$ROOT/}  ($((sz / 1024)) MB)"
}

echo "graphify-out 정리 ($([ "$APPLY" = 1 ] && echo 실행 || echo dry-run))"

# 1) 날짜 스냅샷 — 40MB 짜리 graph.json 전체 사본이라 git 히스토리와 역할이 겹친다.
echo "[1] 날짜 스냅샷 (최근 ${KEEP}개 유지)"
mapfile -t snaps < <(find "$OUT" -maxdepth 1 -type d -name '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' | sort)
total=${#snaps[@]}
if [ "$total" -gt "$KEEP" ]; then
  for p in "${snaps[@]:0:$((total - KEEP))}"; do kill_path "$p"; done
else
  note "정리 대상 없음 (${total}개)"
fi

# 2) AST 캐시 — 파일명이 콘텐츠 해시라 append-only. 캐시 미스는 재추출로 무해하다.
echo "[2] AST 캐시 (${MAX_AGE}일 미접근분)"
if [ -d "$OUT/cache/ast" ]; then
  n=$(find "$OUT/cache/ast" -type f -name '*.json' -mtime "+$MAX_AGE" | wc -l)
  if [ "$n" -gt 0 ]; then
    sz=$(find "$OUT/cache/ast" -type f -name '*.json' -mtime "+$MAX_AGE" -printf '%k\n' | awk '{s+=$1} END {print s+0}')
    freed=$((freed + sz))
    [ "$APPLY" = 1 ] && find "$OUT/cache/ast" -type f -name '*.json' -mtime "+$MAX_AGE" -delete
    note "${n}개 ($((sz / 1024)) MB)"
  else
    note "정리 대상 없음"
  fi
fi

# 3) 백업 잔해 + 빈 디렉터리
echo "[3] 백업 잔해"
found=0
for p in "$OUT"/graph.json.bak-*; do [ -e "$p" ] || continue; kill_path "$p"; found=1; done
[ "$found" = 0 ] && note "정리 대상 없음"
[ "$APPLY" = 1 ] && find "$OUT/cache" -type d -empty -delete 2>/dev/null || true

echo
if [ "$APPLY" = 1 ]; then
  echo "회수: $((freed / 1024)) MB / 현재 graphify-out: $(du -sm "$OUT" | cut -f1) MB"
else
  echo "회수 예상: $((freed / 1024)) MB (--apply 로 실제 삭제)"
fi
