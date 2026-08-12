#!/usr/bin/env python3
"""Validate the precomposited Hanji matte used by the home hero videos.

The regular character clips must keep a white matte for runtime multiply.
HomeHeroClips instead avoids the unreliable Android texture color-filter path,
so its two derivatives have the Hanji backdrop baked into every frame.

**왜 이 도구가 YUV 를 직접 변환하는가 (2026-08-12 실기기 재현으로 확정)**

이전 판은 ffmpeg 에 `-pix_fmt rgb24` 를 시켜 나온 RGB 를 그대로 매트로 적었다.
그 값(`#F9F4EB`)을 앱 배경에 그대로 깔았는데도 실기기에서 사각형이 계속 보였다.
원인은 두 가지였다:

1. **클립에 색공간 태그가 없었다** (`color_space=unknown`). 태그가 없으면
   디코더마다 다르게 해석한다 — ffmpeg/swscale 은 BT.601 로, Android
   MediaCodec 은 BT.709 로 읽는다. 같은 파일이 도구에서는 `#F9F4EB`,
   폰에서는 `#FBF5EB` 로 나왔다. **도구가 폰과 다른 색을 보고 있었다.**
2. swscale 은 고정소수점 반올림 때문에 정확한 행렬 계산보다 채널당 1 낮게
   나온다. 태그를 붙인 뒤에도 swscale 은 `#FAF4EA`, 폰은 `#FBF5EB` 였다.

그래서 이제 ① 클립이 **명시적 BT.709/tv 태그**를 갖도록 강제하고(태그가
없으면 실패), ② rgb24 변환을 ffmpeg 에 맡기지 않고 raw YUV 를 받아
**ITU-R BT.709 limited-range 공식으로 직접** 변환한다. 이 값이 실기기
(M2101K6G / Android 12)에서 `adb exec-out screencap` 으로 실측한 픽셀과
정확히 일치한다.

태그는 재인코딩 없이 붙일 수 있다(비트스트림 무손실):

    ffmpeg -i in.mp4 -c copy \
      -bsf:v h264_metadata=colour_primaries=1:transfer_characteristics=1:\
matrix_coefficients=1:video_full_range_flag=0 out.mp4

Usage:
    python tool/check_home_hero_matte.py
    python tool/check_home_hero_matte.py --check
"""

from __future__ import annotations

import json
import hashlib
import shutil
import subprocess
import sys
from collections import Counter
from pathlib import Path

from check_clip_matte import GRID, INSET, die, find_ffmpeg

ROOT = Path(__file__).resolve().parent.parent
CLIP_DIR = ROOT / "assets" / "video" / "home_hero"
REPORT = Path(__file__).resolve().parent / "home_hero_matte_report.json"
TARGET = (250, 246, 236)  # SoriColors.lightBg / #FAF6EC
TOLERANCE = 2
# A moving wing can touch one sampled corner in a single frame. As with the
# white-matte checker, use a strong majority instead of misclassifying subject
# pixels as background drift.
MIN_MATCH_RATIO = 0.99
EXPECTED_FRAMES = {
    "tiger_rise_hanji.mp4": 121,
    "magpie_walking_front_hanji.mp4": 113,
}
# 홈 클립은 반드시 이 태그를 들고 있어야 한다. 없으면 디코더마다 다른 색이
# 나오고, 그게 2026-08-06~08-12 내내 "동영상 흰 배경"으로 보고된 원인이다.
REQUIRED_TAGS = {
    "color_space": "bt709",
    "color_primaries": "bt709",
    "color_transfer": "bt709",
    "color_range": "tv",
}


def find_ffprobe() -> str:
    """ffmpeg 옆의 ffprobe. 태그 검증은 선택이 아니라 계약이라 없으면 죽는다."""
    found = shutil.which("ffprobe")
    if found:
        return found
    sibling = Path(find_ffmpeg()).with_name("ffprobe")
    for candidate in (sibling, sibling.with_suffix(".exe")):
        if candidate.exists():
            return str(candidate)
    die(
        "ffprobe not found. Install a full ffmpeg build (winget install "
        "--id Gyan.FFmpeg -e) — the color-tag contract cannot be checked "
        "without it."
    )
    raise AssertionError("unreachable")


def color_tags(path: Path, ffprobe: str) -> dict:
    proc = subprocess.run(
        [
            ffprobe,
            "-v",
            "error",
            "-select_streams",
            "v:0",
            "-show_entries",
            "stream=color_space,color_primaries,color_transfer,color_range",
            "-of",
            "json",
            str(path),
        ],
        capture_output=True,
        timeout=60,
    )
    try:
        streams = json.loads(proc.stdout.decode("utf-8", "replace"))["streams"]
    except (ValueError, KeyError):
        return {}
    if not streams:
        return {}
    return {key: streams[0].get(key, "unknown") for key in REQUIRED_TAGS}


def bt709_limited(y: int, u: int, v: int):
    """ITU-R BT.709 limited-range (studio swing) YCbCr → RGB, 정확 계산.

    swscale 의 고정소수점 경로를 쓰지 않는다 — 채널당 1 어긋나고, 그 1 이
    큰 단색 사각형에서는 경계로 보인다.
    """
    luma = (y - 16) / 219.0
    cb = (u - 128) / 224.0
    cr = (v - 128) / 224.0
    r = luma + 1.5748 * cr
    g = luma - 0.187324 * cb - 0.468124 * cr
    b = luma + 1.8556 * cb
    return tuple(max(0, min(255, round(channel * 255))) for channel in (r, g, b))


def corners_yuv444(frame: bytes):
    """GRID×GRID yuv444p 프레임의 네 모서리를 RGB 로."""
    plane = GRID * GRID
    out = []
    for row, col in (
        (INSET, INSET),
        (INSET, GRID - 1 - INSET),
        (GRID - 1 - INSET, INSET),
        (GRID - 1 - INSET, GRID - 1 - INSET),
    ):
        index = row * GRID + col
        out.append(
            bt709_limited(frame[index], frame[plane + index], frame[2 * plane + index])
        )
    return out


def check(path: Path, ffmpeg: str, ffprobe: str) -> dict:
    base = {
        "path": path.name,
        "bytes": path.stat().st_size,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest().upper(),
    }
    tags = color_tags(path, ffprobe)
    tags_ok = tags == REQUIRED_TAGS

    try:
        proc = subprocess.run(
            [
                ffmpeg,
                "-v",
                "error",
                "-i",
                str(path),
                "-vf",
                f"scale={GRID}:{GRID}",
                "-f",
                "rawvideo",
                # 4:4:4 로 받아 모서리마다 자기 크로마를 갖게 한다. 여기서는
                # 행렬 변환이 일어나지 않으므로 swscale 반올림이 끼지 않는다.
                "-pix_fmt",
                "yuv444p",
                "-",
            ],
            capture_output=True,
            timeout=120,
        )
    except subprocess.TimeoutExpired:
        return {
            **base,
            "ok": False,
            "color_tags": tags,
            "matte": None,
            "match_ratio": 0.0,
            "frames_sampled": 0,
            "reason": "decode timeout",
        }

    frame_size = GRID * GRID * 3
    frame_count = len(proc.stdout) // frame_size
    if frame_count == 0:
        error = proc.stderr.decode("utf-8", "replace").strip().split("\n")[-1]
        return {
            **base,
            "ok": False,
            "color_tags": tags,
            "matte": None,
            "match_ratio": 0.0,
            "frames_sampled": 0,
            "reason": f"could not decode frames: {error[:120]}",
        }

    samples = []
    for index in range(frame_count):
        start = index * frame_size
        samples.extend(corners_yuv444(proc.stdout[start : start + frame_size]))

    matching = [
        color
        for color in samples
        if all(abs(value - target) <= TOLERANCE for value, target in zip(color, TARGET))
    ]
    ratio = len(matching) / len(samples)
    matte = Counter(samples).most_common(1)[0][0]
    expected_frames = EXPECTED_FRAMES.get(path.name)
    frames_ok = expected_frames == frame_count
    ok = ratio >= MIN_MATCH_RATIO and frames_ok and tags_ok
    reasons = []
    if not tags_ok:
        missing = {
            key: tags.get(key, "missing")
            for key in REQUIRED_TAGS
            if tags.get(key) != REQUIRED_TAGS[key]
        }
        reasons.append(f"color tags must be explicit BT.709/tv, got {missing}")
    if ratio < MIN_MATCH_RATIO:
        reasons.append("corner matte differs from #FAF6EC")
    if not frames_ok:
        reasons.append(f"expected {expected_frames} frames, found {frame_count}")

    return {
        **base,
        "ok": ok,
        "color_tags": tags,
        "matte": "#%02X%02X%02X" % matte,
        "match_ratio": round(ratio, 3),
        "frames_sampled": frame_count,
        "reason": "; ".join(reasons),
    }


def main() -> int:
    check_only = "--check" in sys.argv
    ffmpeg = find_ffmpeg()
    ffprobe = find_ffprobe()
    if not CLIP_DIR.is_dir():
        die(f"{CLIP_DIR} does not exist")

    clips = sorted(CLIP_DIR.glob("*.mp4"))
    if {clip.name for clip in clips} != set(EXPECTED_FRAMES):
        die("home hero directory must contain exactly the two declared clips")

    print(f"  ffmpeg: {ffmpeg}\n  ffprobe: {ffprobe}\n")
    results = [check(path, ffmpeg, ffprobe) for path in clips]
    for result in results:
        mark = "OK" if result["ok"] else f"FAIL {result['reason']}"
        print(
            f"  {result['path']}: {result['matte']} "
            f"{result['match_ratio'] * 100:.0f}% "
            f"{result['frames_sampled']} frames  {mark}"
        )

    bad = [result for result in results if not result["ok"]]
    if not check_only:
        REPORT.write_text(
            json.dumps(
                {
                    "note": "Generated by tool/check_home_hero_matte.py; do not edit manually.",
                    "target": "#FAF6EC",
                    "tolerance": TOLERANCE,
                    "decode": "ITU-R BT.709 limited range, computed exactly (not swscale)",
                    "clips": results,
                },
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
        print(f"\n  report updated: {REPORT.relative_to(ROOT)}")

    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
