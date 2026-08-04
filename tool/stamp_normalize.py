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

# 512px 로 내보낸다. BIBLE 의 마스코트 규격 1254² 를 그대로 쓰면 6배 과잉이다:
#   앱에서 도장이 가장 크게 나오는 곳이 `vocab_pack_result_screen` 의 118dp 이고,
#   4배 DPI(xxxhdpi) 에서도 472px 다. `DancheongStamp` 은 이미 cacheWidth 로
#   표시 크기에 맞춰 디코드하므로 큰 파일은 APK 용량만 먹는다.
#   실측: 1254px 942KB · 768px 396KB · 512px 179KB (14종이면 13MB vs 2.5MB).
#   색수를 줄이거나 그레인을 뭉개는 건 화질만 깎고 효과가 작았다 — 해상도가 레버다.
SIZE = 512
TARGET_DIAM = 0.974   # 원 지름 / 캔버스 — 기존 8종 실측(투명 25.5%)에서 역산
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


def fit_circle(rgba: Image.Image) -> Image.Image:
    """원이 캔버스를 차지하는 비율을 기존 8종에 맞춘다.

    기존 도장은 투명 25.5% 안팎 = 원 지름이 캔버스의 97.4%.
    생성물은 34% 안팎(=91.7%)이라 그대로 쓰면 같은 박스에서 6% 작게 보인다.
    알파 bbox 로 원을 잘라내 목표 지름으로 리샘플한 뒤 가운데 놓는다.
    """
    a = np.asarray(rgba)[:, :, 3]
    ys, xs = np.where(a > 8)
    if len(xs) == 0:
        return rgba
    box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    crop = rgba.crop(box)

    d = round(SIZE * TARGET_DIAM)
    # 원이므로 긴 변을 목표 지름에 맞춘다(가로세로 비는 유지).
    scale = d / max(crop.size)
    crop = crop.resize(
        (max(1, round(crop.width * scale)), max(1, round(crop.height * scale))),
        Image.LANCZOS,
    )
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.alpha_composite(crop, ((SIZE - crop.width) // 2, (SIZE - crop.height) // 2))
    return out


def to_palette(rgba: Image.Image) -> Image.Image:
    """P 모드 + 이진 투명으로 변환 — 기존 8종과 같은 형식.

    RGBA 로 두면 파일이 2배가 된다. 도장은 색수가 적어 255색이면 손실이 없다.

    주의: `Image.fromarray(idx,"P")` 로 만든 뒤 `info["transparency"]` 를 넣고
    저장하면 PIL 이 256바이트 알파 테이블(전부 불투명)을 써버려 **투명이 통째로
    날아간다**. 팔레트를 직접 조립하고 `transparency=` 만 넘겨야 한다.
    (2026-08-04: 이 버그로 6종이 투명 0% 로 나갔다 — 모서리가 검게 찍힘.)
    """
    alpha = np.asarray(rgba)[:, :, 3] > 128
    pal = rgba.convert("RGB").quantize(colors=255, method=Image.Quantize.MEDIANCUT)

    idx = np.asarray(pal).copy()
    idx[~alpha] = 255                       # 255번을 투명 인덱스로 예약

    table = list(pal.getpalette()[:255 * 3]) + [255, 255, 255]
    out = Image.new("P", rgba.size)
    out.putpalette(table)
    out.frombytes(idx.astype(np.uint8).tobytes())
    out.info.pop("transparency", None)
    return out


def main() -> int:
    files = sorted(p for p in SRC.glob("stamp_*.png"))
    if not files:
        print(f"[!] {SRC} 가 비어 있습니다.")
        return 1

    for p in files:
        im = Image.open(p)
        pre = np.asarray(im.convert("RGBA"))[:, :, 3]
        already_cut = (pre == 0).mean() > 0.05

        rgba = im.convert("RGBA") if already_cut else cutout(im.convert("RGB"))
        rgba = fit_circle(rgba)
        a = np.asarray(rgba)[:, :, 3]
        transparent = 100 * (a == 0).mean()

        out = DST / p.name
        to_palette(rgba).save(out, "PNG", optimize=True, transparency=255)

        flag = "" if 22 <= transparent <= 30 else "  ⚠ 투명 비율 이상"
        print(f"  {p.name:24s} {out.stat().st_size / 1024:6.0f} KB  "
              f"투명 {transparent:5.1f}%{flag}")

    print("\n기존 8종 기준 투명 25% 안팎 · 300KB 안팎이면 정상.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
