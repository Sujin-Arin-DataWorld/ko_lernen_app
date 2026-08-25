#!/usr/bin/env python3
"""Build a human-checkable sheet for a staged clip treatment.

Metrics alone were not enough. `tool/whiten_clip_matte.py`'s first mask scored
"50.6% → 5.3% shadow, success" while it had actually blown Joy's shoulder
plumage out to flat white — the number said pass, the picture said no. Every
later attempt to build a numeric damage score also failed to separate "cleaned
background mottling" from "destroyed feather detail", because both are textured.

So the gate is a picture. For each sampled frame this renders three panels:

    original | treated | change overlay

The overlay tints every changed pixel red over a faded original, which makes
the shape of the edit obvious: a clean run tints the ground shadow and the
background haze only. Red sitting *on the character* is the failure mode, and
it is unmistakable at a glance.

Frames are chosen adversarially: the darkest-shadow frame, plus evenly spaced
samples, so a pose that only misbehaves mid-animation cannot slip through.

Usage:
    python tool/preview_clip_treatment.py --clip magpie_choose.mp4
    python tool/preview_clip_treatment.py            # every staged clip
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from check_clip_matte import find_ffmpeg
from check_home_hero_matte import find_ffprobe
from compose_home_hero_hanji import load_rgb_frames, probe_wh
from whiten_clip_matte import floor_grey_ratio

ROOT = Path(__file__).resolve().parent.parent
CLIP_DIR = ROOT / "assets" / "video" / "character"
STAGE_DIR = ROOT / "build" / "whitened_clips"
FONT = ROOT / "assets" / "fonts" / "WantedSans" / "WantedSans-Medium.otf"

TILE = 300
PAD = 10
LABEL = 22


def pick_frames(frames: np.ndarray, count: int = 4) -> list[int]:
    """최악(그림자 최대) 프레임 + 균등 표본."""
    ratios = [floor_grey_ratio(f) for f in frames]
    worst = int(np.argmax(ratios))
    spread = [int(round(i * (len(frames) - 1) / (count - 1))) for i in range(count - 1)]
    return sorted(dict.fromkeys([worst, *spread]))


# 재인코딩만으로도 디테일한 곳은 픽셀이 ±몇 단계 흔들린다. 그 흔들림까지
# 빨강으로 칠하면 캐릭터 전체가 빨갛게 나와 판독이 불가능해진다(초판 실패).
# 손실 압축 잡음은 대개 8 이하이므로 그 위만 "실제 편집"으로 본다.
NOISE_FLOOR = 16


def overlay(orig: np.ndarray, treated: np.ndarray) -> np.ndarray:
    """의미 있게 바뀐 픽셀만 빨강 — 캐릭터 위에 빨강이 있으면 그림을 건드린 것."""
    diff = np.abs(orig.astype(np.int16) - treated.astype(np.int16)).max(axis=2)
    changed = diff > NOISE_FLOOR
    faded = (orig.astype(np.float32) * 0.35 + 255 * 0.65)
    faded[changed] = np.array([220, 40, 40], dtype=np.float32)
    return np.clip(faded, 0, 255).astype(np.uint8)


def sheet(clip: str) -> Path:
    src = CLIP_DIR / clip
    staged = STAGE_DIR / clip
    if not staged.is_file():
        raise SystemExit(f"스테이징 처리본이 없다: {staged}")
    ffmpeg, ffprobe = find_ffmpeg(), find_ffprobe()
    w, h = probe_wh(src, ffprobe)
    a = load_rgb_frames(src, ffmpeg, w, h)
    tw, th = probe_wh(staged, ffprobe)
    b = load_rgb_frames(staged, ffmpeg, tw, th)
    if a.shape != b.shape:
        raise SystemExit(f"프레임 형상 불일치 {a.shape} vs {b.shape}")

    idx = pick_frames(a)
    font = ImageFont.truetype(str(FONT), 15) if FONT.is_file() else ImageFont.load_default()
    cols = 3
    width = PAD + cols * (TILE + PAD)
    height = PAD + len(idx) * (TILE + LABEL + PAD)
    canvas = Image.new("RGB", (width, height), (250, 247, 242))
    draw = ImageDraw.Draw(canvas)

    for row, i in enumerate(idx):
        panels = [
            (a[i], f"원본 f{i} · 그림자 {floor_grey_ratio(a[i]):.1%}"),
            (b[i], f"처리 f{i} · 그림자 {floor_grey_ratio(b[i]):.1%}"),
            (overlay(a[i], b[i]), "변경 픽셀(빨강) — 캐릭터 위면 불량"),
        ]
        y = PAD + row * (TILE + LABEL + PAD)
        for col, (arr, text) in enumerate(panels):
            img = Image.fromarray(arr)
            img.thumbnail((TILE, TILE), Image.LANCZOS)
            x = PAD + col * (TILE + PAD)
            draw.rectangle([x, y, x + TILE, y + TILE], outline=(210, 200, 186))
            canvas.paste(img, (x + (TILE - img.width) // 2,
                               y + (TILE - img.height) // 2))
            draw.text((x + 3, y + TILE + 4), text, fill=(60, 48, 34), font=font)

    out = STAGE_DIR / "preview" / f"{Path(clip).stem}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out)
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--clip", action="append", default=None)
    args = parser.parse_args()
    clips = args.clip or [p.name for p in sorted(STAGE_DIR.glob("*.mp4"))]
    if not clips:
        print(f"{STAGE_DIR} 에 처리본이 없다.", file=sys.stderr)
        return 2
    for clip in clips:
        print(f"  {sheet(clip)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
