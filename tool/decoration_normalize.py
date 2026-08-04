#!/usr/bin/env python3
"""장식(decorations/*.png) 정규화 — 흰 배경 컷아웃 + 여백 정리.

입력 : assets/illustrations/decorations/_raw/<slug>.(png|jpg|jpeg|webp)
출력 : assets/illustrations/decorations/<slug>.png   RGBA, 배경 투명

기존 장식은 크기가 제각각이다(1254², 1254x836, 1200x200, 1024x1536) —
`DecorationLayer` 가 `widthFrac` 으로 폭만 맞추고 높이는 비율대로 두기 때문에
**정사각으로 맞추면 안 된다**. 내용에 딱 맞게 자르고 긴 변만 MAX_EDGE 로 제한한다.

배경 제거는 테두리에서 시작하는 플러드필이라, 물체 안쪽의 흰 부분
(한지·백자·여백)은 물체에 막혀 뚫리지 않는다.

주의: `Image.fromarray(...).copy()` 없이 floodfill 하면 numpy 버퍼를 공유해
조용히 0% 만 채운다 — 도장 툴에서 겪은 것과 같은 함정.

사용:  python3 tool/decoration_normalize.py
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

MAX_EDGE = 1254          # 기존 장식의 최대 변과 동일
PAD = 0.03               # 잘라낸 뒤 사방 여백(긴 변 대비)

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets/illustrations/decorations/_raw"
DST = ROOT / "assets/illustrations/decorations"


def cutout(im: Image.Image) -> Image.Image:
    rgb = np.asarray(im.convert("RGB")).astype(np.int16)
    mx, mn = rgb.max(axis=2), rgb.min(axis=2)
    white = (mn >= 228) & (mx - mn <= 14)

    mask = Image.fromarray(np.where(white, 255, 0).astype(np.uint8), "L").copy()
    h, w = white.shape
    for seed in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        if mask.getpixel(seed) == 255:
            ImageDraw.floodfill(mask, seed, 128, thresh=0)
    outside = np.asarray(mask) == 128

    out = np.dstack([rgb.astype(np.uint8),
                     np.where(outside, 0, 255).astype(np.uint8)])
    return Image.fromarray(out, "RGBA")


def trim_and_fit(rgba: Image.Image) -> Image.Image:
    a = np.asarray(rgba)[:, :, 3]
    ys, xs = np.where(a > 8)
    if len(xs) == 0:
        return rgba
    rgba = rgba.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))

    if max(rgba.size) > MAX_EDGE:
        k = MAX_EDGE / max(rgba.size)
        rgba = rgba.resize(
            (max(1, round(rgba.width * k)), max(1, round(rgba.height * k))),
            Image.LANCZOS,
        )

    pad = round(max(rgba.size) * PAD)
    canvas = Image.new("RGBA", (rgba.width + 2 * pad, rgba.height + 2 * pad),
                       (0, 0, 0, 0))
    canvas.alpha_composite(rgba, (pad, pad))
    return canvas


def main() -> int:
    files = sorted(p for p in SRC.glob("*")
                   if p.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"})
    if not files:
        print(f"[!] {SRC} 가 비어 있습니다.")
        return 1

    for p in files:
        im = Image.open(p)
        pre = np.asarray(im.convert("RGBA"))[:, :, 3]
        rgba = im.convert("RGBA") if (pre == 0).mean() > 0.02 else cutout(im)
        rgba = trim_and_fit(rgba)

        out = DST / f"{p.stem}.png"
        rgba.save(out, "PNG", optimize=True)

        a = np.asarray(rgba)[:, :, 3]
        print(f"  {p.name:30s} -> {rgba.width}x{rgba.height}  "
              f"{out.stat().st_size / 1024:6.0f} KB  투명 {100*(a==0).mean():4.0f}%")

    print("\n배치 후 `kAvailableDecorations` 에 슬러그를 추가할 것 -"
          " test/decoration_slot_test.dart 가 대조한다.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
