#!/usr/bin/env bash
# 듣기 카드 후처리 — docs/LISTENING_CARD_RECIPE.md §후처리 의 실행본.
#
# 레시피는 `finish.sh {key} {url}` 을 참조하지만 스크립트가 저장소에 없었다
# (2026-08-17 세션의 임시 파일). 계약 그대로 옮겨 커밋한 것이 이 파일이다.
#
#   다운로드 → 800×600 리사이즈 → apply_paper_grain.py(fine 5.0 / coarse 4.0)
#   → WebP q84 → assets/illustrations/listening/{key}.webp
#
# 사용: scripts/finish_listening_card.sh C1Briefing https://.../out.png
# 산출물 85~105KB 가 정상(그레인이 엔트로피를 올린다).
#
# 2026-08-30 — 이식성 교정. 이전 판은 `sips`·`cwebp`·`stat -f%z`·`.grain-venv/bin/python`
# 을 썼는데 넷 다 macOS 전용이라 Windows(Git Bash)에서 전량 실패한다. 이미지 작업을
# Pillow 로 옮겨 두 플랫폼에서 같은 결과가 나오게 했다. `sips -Z 800` 은 긴 변을 800
# 으로 맞추는 것이고 소스가 4:3 이므로 800×600 과 같다 — 4:3 이 아닌 입력이 조용히
# 찌그러지지 않도록 비율을 명시적으로 검사한다.
# 그레인 계산은 그대로 scripts/apply_paper_grain.py 를 호출한다(그 파일은 수정하지 않았다).
set -euo pipefail

# 오류 메시지 안에 중괄호를 쓰면 ${x:?...} 확장이 먼저 닫혀 URL 이 잘린다.
USAGE='사용: scripts/finish_listening_card.sh KEY URL'
KEY="${1:?$USAGE}"
URL="${2:?$USAGE}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT/assets/illustrations/listening/$KEY.webp"

# venv 가 있으면 쓰고 없으면 시스템 python 으로 내려간다. 레시피가 요구하는 건
# pillow+numpy 이지 venv 자체가 아니다.
PY=""
for cand in "$ROOT/.grain-venv/bin/python" "$ROOT/.grain-venv/Scripts/python.exe" python3 python; do
  if [ -x "$cand" ] || command -v "$cand" >/dev/null 2>&1; then PY="$cand"; break; fi
done
[ -n "$PY" ] || { echo "!! python 을 찾지 못했다" >&2; exit 1; }

"$PY" - "$KEY" "$URL" "$DEST" "$ROOT" <<'PYEOF'
import io, os, shutil, subprocess, sys, tempfile, urllib.request
from pathlib import Path

key, url, dest, root = sys.argv[1:5]
sys.path.insert(0, str(Path(root) / 'scripts'))
try:
    from PIL import Image
    from apply_paper_grain import grain           # fine 5.0 / coarse 4.0 / seed 7+h+w
except ImportError as exc:                        # pillow·numpy 미설치
    sys.exit(f'!! {exc} — pip install pillow numpy')

raw = urllib.request.urlopen(url, timeout=120).read()
src = Image.open(io.BytesIO(raw)).convert('RGB')

# 소스 계약은 4:3. 크게 어긋나면 늘려 맞추지 말고 세워서 알린다.
ratio = src.width / src.height
if abs(ratio - 4 / 3) > 0.02:
    sys.exit(f'!! {key}: 소스가 4:3 이 아니다 ({src.width}x{src.height}, {ratio:.3f})')

# 중간 산출물은 전부 OS 임시 디렉터리에 둔다 — 예전엔 assets 디렉터리에
# .tmp.png 를 만들어 크래시 시 자산 트리에 쓰레기가 남았다.
workdir = Path(tempfile.mkdtemp(prefix=f'card_{key}_'))
try:
    tmp_in = workdir / f'{key}.tmp.png'
    tmp_out = tmp_in.with_suffix('.grain.jpg')    # apply_paper_grain 의 출력 이름 규칙
    tmp_webp = workdir / f'{key}.webp'
    src.resize((800, 600), Image.LANCZOS).save(tmp_in)
    grain(str(tmp_in), str(tmp_out))              # 인자 기본값 = 레시피 값. 바꾸지 말 것.
    Image.open(tmp_out).convert('RGB').save(tmp_webp, 'WEBP', quality=84, method=6)

    # 게이트: 통과 전에는 자산 디렉터리에 발도 못 들인다.
    checker = str(Path(root) / 'tool' / 'check_card_style.py')
    verdict = subprocess.run([sys.executable, checker, str(tmp_webp)],
                             capture_output=True, text=True, encoding='utf-8',
                             errors='replace')
    if verdict.returncode != 0:
        sys.stdout.write(verdict.stdout)
        sys.stderr.write(verdict.stderr)
        sys.exit(f'!! {key}: F-E-cards 게이트 실패 — 자산을 배치하지 않는다 (임시본 삭제)')

    os.replace(tmp_webp, dest)                    # 원자적 배치(동일 볼륨 전제)
    kb = Path(dest).stat().st_size // 1024
    print(f'{key} → assets/illustrations/listening/{key}.webp  ({kb}KB)')
    if not 85 <= kb <= 105:
        print('   ⚠ 규약 범위(85~105KB) 밖이다 — 그레인이 안 먹었거나 소재가 너무 단순한지 확인',
              file=sys.stderr)

    # 정본 명부 등록 — 사이드카(sha256+실측) + STYLE_LOCK members.
    register = subprocess.run([sys.executable, checker, '--register', dest],
                              capture_output=True, text=True, encoding='utf-8',
                              errors='replace')
    sys.stdout.write(register.stdout)
    if register.returncode != 0:
        sys.stderr.write(register.stderr)
        sys.exit(f'!! {key}: --register 실패 — 게이트는 통과했으니 수동으로 등록하라')
finally:
    shutil.rmtree(workdir, ignore_errors=True)
PYEOF
