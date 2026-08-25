#!/usr/bin/env python3
"""Mechanical conformance check for staged clip treatments.

The visual sheet (`tool/preview_clip_treatment.py`) answers "did we damage the
art". It cannot answer "did we silently drop the audio track", "did a frame go
missing", or "is the colour tag still ambiguous" — and those break the app just
as hard. `magpie_choose` and `magpie_bob2` carry audio; an earlier draft of the
whitener passed `-an` and would have dropped it without a word.

Every check here is a hard equality against the original, except the two we
deliberately change:

* `color_primaries` — sources are mostly `unknown`, which is precisely the
  ambiguity that made ffmpeg and Android MediaCodec disagree about the matte
  (2026-08-12 note in `character_clip.dart`). Treated clips must be `bt709`.
* file size — re-encoding moves it; flag only a large swing.

Usage:
    python tool/verify_staged_clips.py
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from check_home_hero_matte import find_ffprobe

ROOT = Path(__file__).resolve().parent.parent
CLIP_DIR = ROOT / "assets" / "video" / "character"
STAGE_DIR = ROOT / "build" / "whitened_clips"

# 재인코딩으로 용량이 이 배수를 넘게 움직이면 사람이 봐야 한다.
SIZE_TOLERANCE = 1.60


def probe(path: Path, ffprobe: str) -> dict:
    out = subprocess.run(
        [ffprobe, "-v", "error", "-show_streams", "-show_format",
         "-of", "json", str(path)],
        capture_output=True, text=True, check=True,
    ).stdout
    data = json.loads(out)
    video = next(s for s in data["streams"] if s["codec_type"] == "video")
    audio = [s for s in data["streams"] if s["codec_type"] == "audio"]
    return {
        "width": video["width"],
        "height": video["height"],
        "fps": video["r_frame_rate"],
        "frames": video.get("nb_frames"),
        "pix_fmt": video["pix_fmt"],
        "primaries": video.get("color_primaries", "unknown"),
        "range": video.get("color_range", "unknown"),
        "audio": [(a["codec_name"], a.get("sample_rate")) for a in audio],
        "bytes": path.stat().st_size,
    }


def compare(name: str, src: dict, out: dict) -> list[str]:
    problems: list[str] = []
    for key in ("width", "height", "fps", "frames", "pix_fmt"):
        if src[key] != out[key]:
            problems.append(f"{key}: {src[key]} → {out[key]}")
    if src["audio"] != out["audio"]:
        problems.append(f"오디오 스트림: {src['audio']} → {out['audio']}")
    if out["primaries"] != "bt709":
        problems.append(f"색공간 태그가 bt709 가 아님: {out['primaries']}")
    if out["range"] not in ("tv", "unknown"):
        problems.append(f"color_range 가 tv 가 아님: {out['range']}")
    ratio = out["bytes"] / max(src["bytes"], 1)
    if ratio > SIZE_TOLERANCE or ratio < 1 / SIZE_TOLERANCE:
        problems.append(f"용량 {src['bytes']:,} → {out['bytes']:,} ({ratio:.2f}x)")
    return problems


def main() -> int:
    ffprobe = find_ffprobe()
    staged = sorted(STAGE_DIR.glob("*.mp4"))
    if not staged:
        print(f"{STAGE_DIR} 에 처리본이 없다.", file=sys.stderr)
        return 2

    failures = 0
    print(f"  {'클립':<28} {'프레임':>7} {'오디오':>7} {'태그':>8} {'용량':>8}  판정")
    print("  " + "─" * 76)
    for item in staged:
        src_path = CLIP_DIR / item.name
        if not src_path.is_file():
            print(f"  {item.name:<28} 원본 없음")
            failures += 1
            continue
        src, out = probe(src_path, ffprobe), probe(item, ffprobe)
        problems = compare(item.name, src, out)
        verdict = "OK" if not problems else "✗ " + " · ".join(problems)
        if problems:
            failures += 1
        print(f"  {item.name:<28} {str(out['frames']):>7} "
              f"{len(out['audio']):>7} {out['primaries']:>8} "
              f"{out['bytes'] / max(src['bytes'], 1):>7.2f}x  {verdict}")

    print(f"\n  {len(staged)}개 중 {failures}개 실패")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
