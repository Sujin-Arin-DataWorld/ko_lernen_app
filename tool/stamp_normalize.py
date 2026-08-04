#!/usr/bin/env python3
"""단청 도장(stamps/stamp_*.png) 정규화.

`DancheongStamp._assetSlug` 가 `stamps/stamp_{motif.name}.png` 로 찾는다.
파일명 = enum 이름. 그림만 넣고 이름을 틀리면 테스트가 잡는다.

입력  : assets/illustrations/stamps/_raw/stamp_<name>.png
출력  : assets/illustrations/stamps/stamp_<name>.png
        1254x1254 / RGBA / 원 바깥은 완전 투명

생성물은 흰 배경 위에 원이 얹힌 형태로 오므로, **테두리에서 시작하는
플러드필**로 바깥 흰색만 지운다. 원 안쪽 크림 바탕은 붉은 링에 막혀
테두리와 연결되지 않으므로 절대 뚫리지 않는다 — 클립 배경 제거와 같은 원리.

사용:  python3 tool/stamp_normalize.py
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

SIZE = 1254
ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets/illustrations/stamps/_raw"
DST = ROOT / "assets/illustrations/stamps"


def cutout(im: Image.Image) -> Image.Image:
    """테두리에서 닿는 흰 영역만 투명으로.

    scipy 없이 PIL 의 4-연결 플러드필만 쓴다 (기기 VM 에 scipy 가 없고
    네트워크도 없다). 네 모서리에서 각각 채워 넣으므로 한쪽이 흰색이
    아니어도 안전하다.
    """
    rgb = np.asarray(im.convert("RGB")).astype(np.int16)
    mx, mn = rgb.max(axis=2), rgb.min(axis=2)
    white = (mn >= 232) & (mx - mn <= 12)

    # .copy() 필수 — Image.fromarray 는 numpy 버퍼를 공유해서, 그 상태로
    # floodfill 하면 변경이 반영되지 않는다(조용히 0% 채움).
    mask = Image.fromarray(
        np.where(white, 255, 0).astype(np.uint8), "L"
    ).copy()
    h, w = white.shape
    for seed in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        if mask.getpixel(seed) == 255:
            ImageDraw.floodfill(mask, seed, 128, thresh=0)
    outside = np.asarray(mask) == 128

    out = np.dstack([rgb.astype(np.uint8),
                     np.where(outside, 0, 255).astype(np.uint8)])
    return Image.fromarray(out, "RGBA")


def main() -> int:
    files = sorted(p for p in SRC.glob("stamp_*.png"))
    if not files:
        print(f"[!] {SRC} 가 비어 있습니다.")
        return 1

    for p in files:
        im = Image.open(p)
        pre = np.asarray(im.convert("RGBA"))[:, :, 3]
        already_cut = (pre == 0).mean() > 0.05

        if im.size != (SIZE, SIZE):
            mode = "RGBA" if already_cut else "RGB"
            im = im.convert(mode).resize((SIZE, SIZE), Image.LANCZOS)

        # 이미 잘라낸 원본(투명 배경)은 다시 뚫지 않는다 — RGB 로 합성하면
        # 투명부가 검정이 돼 흰색 탐지가 통째로 빗나간다.
        rgba = im.convert("RGBA") if already_cut else cutout(im)
        a = np.asarray(rgba)[:, :, 3]
        transparent = 100 * (a == 0).mean()

        out = DST / p.name
        rgba.save(out, "PNG", optimize=True)

        flag = "" if 18 <= transparent <= 34 else "  ⚠ 투명 비율 이상"
        print(f"  {p.name:24s} {out.stat().st_size / 1024:7.0f} KB  "
              f"투명 {transparent:5.1f}%{flag}")

    print("\n기존 8종은 25% 안팎이다. 크게 벗어나면 원 바깥이 안 뚫렸거나"
          " 안쪽까지 뚫린 것이니 확인할 것.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
