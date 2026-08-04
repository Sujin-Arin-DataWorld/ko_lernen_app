#!/usr/bin/env python3
"""사랑방 빈 슬롯 표현 A/B 목업 — 실루엣 vs 마커.

입력: assets/illustrations/hanok/sarangbang_empty.png  (빈 사랑방 A안)
출력: sarangbang_compare.jpg  (3단 비교 시트)

슬롯 좌표는 A안(3/4 시점, 좌측 벽감·좌상단 횃대) 기준 눈대중이다.
실제 구현에서 쓸 값이 아니라 **표현 방식 비교용**이다 — 어느 쪽이 읽히는지만 본다.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
BG_PATH = ROOT / "assets/illustrations/hanok/sarangbang_empty.png"
DECO = ROOT / "assets/illustrations/decorations"

# (장식 slug, 중심x비율, 중심y비율, 폭비율, 이미 채워졌나)
SLOTS = [
    ("decoration_sagunja_maehwa", 0.50, 0.46, 0.30, True),   # 뒷벽 — 채움
    ("decoration_pyeonaek",       0.50, 0.20, 0.34, False),  # 상단 벽 — 비움
    ("decoration_sagunja_guk",    0.085, 0.52, 0.11, False), # 좌측 벽감 상단 — 비움
    ("decoration_sagunja_juk",    0.085, 0.72, 0.11, False), # 좌측 벽감 하단 — 비움
    ("decoration_sonamu",         0.80, 0.80, 0.20, False),  # 우측 바닥 — 비움
]


def place(canvas, im, cx, cy, wf, W, H):
    w = max(1, int(W * wf))
    h = max(1, int(im.height * w / im.width))
    canvas.alpha_composite(
        im.resize((w, h), Image.LANCZOS),
        (int(W * cx) - w // 2, int(H * cy) - h // 2),
    )


def silhouette(im, opacity):
    a = np.asarray(im)[:, :, 3]
    s = np.zeros((*a.shape, 4), np.uint8)
    s[:, :, 0], s[:, :, 1], s[:, :, 2] = (92, 72, 50)
    s[:, :, 3] = (a * opacity).astype(np.uint8)
    return Image.fromarray(s, "RGBA").filter(ImageFilter.GaussianBlur(0.8))


def marker(w, h):
    m = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([2, 2, w - 3, h - 3], radius=12,
                        outline=(126, 100, 70, 120), width=max(3, w // 90))
    r = max(12, w // 12)
    cx, cy = w // 2, h // 2
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(126, 100, 70, 160), width=4)
    d.line([cx - r // 2, cy, cx + r // 2, cy], fill=(126, 100, 70, 200), width=4)
    d.line([cx, cy - r // 2, cx, cy + r // 2], fill=(126, 100, 70, 200), width=4)
    return m


def render(bg, mode, opacity=0.0):
    W, H = bg.size
    c = bg.copy()
    for slug, cx, cy, wf, filled in SLOTS:
        p = DECO / f"{slug}.png"
        if not p.exists():
            continue
        im = Image.open(p).convert("RGBA")
        if filled:
            place(c, im, cx, cy, wf, W, H)
        elif mode == "sil":
            place(c, silhouette(im, opacity), cx, cy, wf, W, H)
        else:
            w = max(1, int(W * wf))
            h = max(1, int(im.height * w / im.width))
            c.alpha_composite(marker(w, h),
                              (int(W * cx) - w // 2, int(H * cy) - h // 2))
    return c.convert("RGB")


def main() -> int:
    if not BG_PATH.exists():
        print(f"[!] {BG_PATH} 가 없습니다. 빈 사랑방 A안을 먼저 넣어주세요.")
        return 1

    bg = Image.open(BG_PATH).convert("RGBA")
    variants = [
        ("A-1   SILHOUETTE 18%", render(bg, "sil", 0.18)),
        ("A-2   SILHOUETTE 38%", render(bg, "sil", 0.38)),
        ("B     EMPTY-SLOT MARKER", render(bg, "mark")),
    ]

    sw = 760
    sh = int(bg.height * sw / bg.width)
    sheet = Image.new("RGB", (3 * sw, sh + 34), "white")
    d = ImageDraw.Draw(sheet)
    for i, (lab, im) in enumerate(variants):
        x = i * sw
        d.rectangle([x, 0, x + sw, 32], fill=(38, 38, 38))
        d.text((x + 10, 10), lab, fill=(255, 255, 255))
        sheet.paste(im.resize((sw, sh), Image.LANCZOS), (x, 34))
    out = ROOT / "sarangbang_compare.jpg"
    sheet.save(out, quality=90)
    print(f"  완료 → {out.name}  ({sheet.width}x{sheet.height})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
