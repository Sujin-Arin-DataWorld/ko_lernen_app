#!/usr/bin/env python3
"""장면 포스터(scenes/*.png) 정규화.

`scene_asset_resolver.dart` 는 `assets/illustrations/scenes/{id}.png` 를
**확장자 .png 로 하드코딩**해서 찾는다. → 출력은 반드시 PNG.

입력  : assets/illustrations/scenes/_raw/<key>.(png|jpg|jpeg|webp)
출력  : assets/illustrations/scenes/<key>.png   1086x1448 / PNG-8(256색)

BIBLE §장면 포스터 규격 = 1086x1448 palette PNG.
회화체(단청) 그라데이션도 256색 + Floyd-Steinberg 디더링이면
2배 확대에서도 밴딩이 보이지 않는다(검증 완료). 평균오차가 THRESH 를
넘으면 밴딩 위험으로 보고 해당 파일만 RGB PNG 로 폴백한다.

사용:  python3 tool/scene_poster_normalize.py
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

W, H = 1086, 1448
THRESH = 4.0  # 평균 채널오차. 초과 시 RGB 폴백.

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets/illustrations/scenes/_raw"
DST = ROOT / "assets/illustrations/scenes"


def fit(im: Image.Image) -> Image.Image:
    """3:4 로 가운데 잘라내고 1086x1448 로 리샘플."""
    im = im.convert("RGB")
    want = W / H
    got = im.width / im.height
    if abs(got - want) > 1e-3:
        if got > want:  # 너무 넓다 → 좌우 crop
            nw = round(im.height * want)
            x = (im.width - nw) // 2
            im = im.crop((x, 0, x + nw, im.height))
        else:  # 너무 높다 → 상하 crop
            nh = round(im.width / want)
            y = (im.height - nh) // 2
            im = im.crop((0, y, im.width, y + nh))
    return im.resize((W, H), Image.LANCZOS)


def main() -> int:
    files = sorted(
        p for p in SRC.glob("*")
        if p.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}
    )
    if not files:
        print(f"[!] {SRC} 에 원본이 없습니다.")
        return 1

    for p in files:
        im = fit(Image.open(p))
        ref = np.asarray(im).astype(np.int16)

        q = im.quantize(colors=256, method=Image.Quantize.MEDIANCUT,
                        dither=Image.Dither.FLOYDSTEINBERG)
        err = float(np.abs(np.asarray(q.convert("RGB")).astype(np.int16) - ref).mean())

        out = DST / f"{p.stem}.png"
        mode = "P-256"
        if err > THRESH:
            mode = "RGB(폴백)"
            im.save(out, "PNG", optimize=True)
        else:
            q.save(out, "PNG", optimize=True)

        print(f"  {p.name:28s} -> {out.name:20s} "
              f"{out.stat().st_size/1024:7.0f} KB  {mode:10s} meanErr {err:5.2f}")

    print("\n완료. 확인:  git status assets/illustrations/scenes/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
