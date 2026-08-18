#!/usr/bin/env bash
# 듣기 카드 후처리 — docs/LISTENING_CARD_RECIPE.md §후처리 의 실행본.
#
# 레시피는 `finish.sh {key} {url}` 을 참조하지만 스크립트가 저장소에 없었다
# (2026-08-17 세션의 임시 파일). 계약 그대로 옮겨 커밋한 것이 이 파일이다.
#
#   curl 다운로드 → sips -Z 800 → apply_paper_grain.py(fine 5.0 / coarse 4.0)
#   → cwebp -q 84 → assets/illustrations/listening/{key}.webp
#
# 사용: scripts/finish_listening_card.sh C1Briefing https://.../out.png
# 산출물 85~105KB 가 정상(그레인이 엔트로피를 올린다).
set -euo pipefail

# 오류 메시지 안에 중괄호를 쓰면 ${x:?...} 확장이 먼저 닫혀 URL 이 잘린다.
USAGE='사용: scripts/finish_listening_card.sh KEY URL'
KEY="${1:?$USAGE}"
URL="${2:?$USAGE}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="$ROOT/.grain-venv/bin/python"
DEST="$ROOT/assets/illustrations/listening/$KEY.webp"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

[ -x "$VENV" ] || {
  echo "!! .grain-venv 가 없다. 먼저:" >&2
  echo "   python3 -m venv .grain-venv && .grain-venv/bin/pip install pillow numpy" >&2
  exit 1
}

curl -fsSL "$URL" -o "$TMP/raw"
# 확장자 없이 받아도 sips 가 컨테이너를 읽는다. webp 입력은 -Z 가 조용히 실패하므로
# 항상 png 로 정규화한 뒤 리사이즈한다.
sips -s format png "$TMP/raw" --out "$TMP/in.png" >/dev/null
sips -Z 800 "$TMP/in.png" --out "$TMP/sized.png" >/dev/null

"$VENV" "$ROOT/scripts/apply_paper_grain.py" "$TMP/sized.png" >/dev/null
cwebp -q 84 "$TMP/sized.grain.jpg" -o "$DEST" >/dev/null 2>&1

SIZE=$(( $(stat -f%z "$DEST") / 1024 ))
echo "$KEY → assets/illustrations/listening/$KEY.webp  (${SIZE}KB)"
[ "$SIZE" -ge 85 ] && [ "$SIZE" -le 105 ] || \
  echo "   ⚠ 규약 범위(85~105KB) 밖이다 — 그레인이 안 먹었거나 소재가 너무 단순한지 확인" >&2
