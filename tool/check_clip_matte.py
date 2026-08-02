#!/usr/bin/env python3
"""캐릭터 클립의 배경(matte)이 순백인지 검사하고 리포트를 갱신한다.

**왜 필요한가**

`CharacterClipPlayer` / `TigerStageVideo` 는 흰 배경 mp4 를 `BlendMode.multiply`
로 배경에 녹인다. multiply 는 **흰색(255)일 때만 항등원**이다:

    255 × X ÷ 255 = X        → 흰 배경은 사라진다
    #F800F9 × #FFFFFF        → 자홍이 그대로 남는다 (핑크 사각형)

2026-07-31 실제 사고: `tiger_sitting2.mp4` 가 자홍 배경(`#F800F9`)으로 출력돼
프로필 아바타에 핑크 사각형이 떴다. 프로필 클립이 랜덤이라 5개 중 1개에서만
재현돼 원인 파악이 늦어졌다.

**ffmpeg 는 둘 중 아무거나 있으면 된다**

    winget install --id Gyan.FFmpeg -e   # 시스템 설치 (PATH 등록)
    pip install imageio-ffmpeg           # 파이썬 휠에 정적 바이너리 포함

시스템 PATH 를 먼저 보고, 없으면 `imageio-ffmpeg` 가 들고 있는 바이너리를 쓴다.
CI 에서는 pip 쪽이 편하다 — 관리자 권한도 PATH 설정도 필요 없다.

**사용**

    python tool/check_clip_matte.py            # 검사 + 리포트 갱신
    python tool/check_clip_matte.py --check    # 검사만 (리포트 안 씀, CI용)

검사 대상은 `assets/video/character/` 뿐이다. `assets/video/loops/` 는 전체 화면
배경으로 `BoxFit.cover` 재생하며 블렌드를 안 하므로 배경색 제약이 없다.

리포트: `tool/clip_matte_report.json` — `test/character_clip_matte_test.dart` 가 읽는다.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CLIP_DIR = ROOT / "assets" / "video" / "character"
REPORT = Path(__file__).resolve().parent / "clip_matte_report.json"

# 순백으로 인정할 하한. H.264 는 손실 압축이라 255 를 정확히 못 맞춘다.
WHITE_MIN = 248
# 모든 프레임을 이 크기로 줄여서 받는다. 배경은 넓은 단색이라 축소해도 모서리
# 색이 보존되고, ffprobe 로 해상도를 물어볼 필요가 없어진다(프레임 크기가 고정).
GRID = 64
# 모서리에서 안쪽으로 이만큼 (축소 시 가장자리 링잉 회피).
INSET = 1
# **네 모서리만** 본다. 변 중앙은 캐릭터가 프레임 끝에 닿는 순간 오탐이 난다 —
# 초판에서 `tiger_choose` 가 호랑이 몸통 주황(`#BD570D`)을 배경으로 오인했다.
# 모서리도 한두 번은 걸릴 수 있으므로 다수결로 판정한다.
MIN_WHITE_RATIO = 0.75


def die(msg: str) -> None:
    print(f"오류: {msg}", file=sys.stderr)
    sys.exit(2)


def find_ffmpeg() -> str:
    exe = shutil.which("ffmpeg")
    if exe:
        return exe
    try:
        from imageio_ffmpeg import get_ffmpeg_exe

        return get_ffmpeg_exe()
    except Exception:  # noqa: BLE001
        die(
            "ffmpeg 를 못 찾았다. 둘 중 하나:\n"
            "      winget install --id Gyan.FFmpeg -e   (설치 후 새 터미널)\n"
            "      pip install imageio-ffmpeg"
        )
        raise  # die() 가 종료하지만 타입 체커용


def corners(frame: bytes):
    """`GRID`x`GRID` RGB24 프레임의 네 모서리 픽셀."""
    i = INSET
    out = []
    for x, y in ((i, i), (GRID - 1 - i, i), (i, GRID - 1 - i), (GRID - 1 - i, GRID - 1 - i)):
        o = (y * GRID + x) * 3
        out.append((frame[o], frame[o + 1], frame[o + 2]))
    return out


def check(path: Path, ffmpeg: str) -> dict:
    base = {"path": path.name, "bytes": path.stat().st_size}
    try:
        proc = subprocess.run(
            [ffmpeg, "-v", "error", "-i", str(path),
             "-vf", f"scale={GRID}:{GRID}", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
            capture_output=True, timeout=120,
        )
    except subprocess.TimeoutExpired:
        return {**base, "ok": False, "matte": None, "white_ratio": 0.0,
                "frames_sampled": 0, "reason": "디코드 타임아웃"}

    raw, size = proc.stdout, GRID * GRID * 3
    n = len(raw) // size
    if n == 0:
        err = proc.stderr.decode("utf-8", "replace").strip().split("\n")[-1][:120]
        return {**base, "ok": False, "matte": None, "white_ratio": 0.0,
                "frames_sampled": 0, "reason": f"프레임을 못 읽었다: {err or '원인 불명'}"}

    samples = []
    for k in range(n):
        samples.extend(corners(raw[k * size:(k + 1) * size]))

    white = [c for c in samples if all(v >= WHITE_MIN for v in c)]
    ratio = len(white) / len(samples)
    ok = ratio >= MIN_WHITE_RATIO

    # 대표 배경색 = 흰색이 아닌 샘플의 최빈값 (오탐 한두 개에 안 휘둘리게).
    non_white = [c for c in samples if not all(v >= WHITE_MIN for v in c)]
    matte = Counter(non_white).most_common(1)[0][0] if non_white else (255, 255, 255)

    if ok:
        reason = ""
    elif matte[0] > 150 and matte[2] > 150 and matte[1] < min(matte[0], matte[2]) - 30:
        reason = "자홍(magenta) 배경 — 흰 매트로 재출력 필요"
    elif sum(matte) < 300:
        reason = "어두운 배경 — multiply 블렌드에 부적합"
    else:
        reason = "배경이 순백이 아님"

    return {**base, "ok": ok, "matte": "#%02X%02X%02X" % matte,
            "white_ratio": round(ratio, 3), "frames_sampled": n, "reason": reason}


def main() -> int:
    check_only = "--check" in sys.argv
    ffmpeg = find_ffmpeg()

    if not CLIP_DIR.is_dir():
        die(f"{CLIP_DIR} 가 없다.")
    clips = sorted(CLIP_DIR.glob("*.mp4"))
    if not clips:
        die(f"{CLIP_DIR} 에 mp4 가 없다.")

    print(f"  ffmpeg: {ffmpeg}\n")
    results = [check(p, ffmpeg) for p in clips]

    width = max(len(r["path"]) for r in results)
    print(f"  {'클립':<{width}}  {'배경':<9} {'흰비율':>6} {'프레임':>6}  판정")
    print("  " + "─" * (width + 48))
    for r in results:
        mark = "OK" if r["ok"] else "✗ " + r["reason"]
        print(f"  {r['path']:<{width}}  {r['matte'] or '-':<9} "
              f"{r['white_ratio'] * 100:5.0f}% {r['frames_sampled']:>6}  {mark}")

    bad = [r for r in results if not r["ok"]]
    print()
    print(f"  {len(results)}개 중 {len(bad)}개 실패")

    if not check_only:
        REPORT.write_text(
            json.dumps(
                {
                    "note": "tool/check_clip_matte.py 가 생성한다. 직접 고치지 말 것. "
                            "클립을 추가·교체하면 이 스크립트를 다시 돌릴 것.",
                    "white_min": WHITE_MIN,
                    "clips": results,
                },
                ensure_ascii=False, indent=2,
            ) + "\n",
            encoding="utf-8",
        )
        print(f"  리포트 갱신: {REPORT.relative_to(ROOT)}")

    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
