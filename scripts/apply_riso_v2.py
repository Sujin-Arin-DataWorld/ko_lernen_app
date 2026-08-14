#!/usr/bin/env python3
"""리소그래프 한지 인쇄 후처리 — UI/UX 개편 2 §R-1 (2026-08-14).

기존 `apply_paper_grain.py` 는 보존한다. 이 스크립트는 이미 fine 5.0/coarse 4.0
이 구워진 번들 위에 **추가분(delta)** 만 얹고, 미스레지스터·스펙클·가장자리 번짐·
웜 캐스트를 적용한다.

⚠️ Jin 게이트: 샘플 3장(before/after) 승인 전에 전량 처리 금지.
기본은 출력 파일만 만들고 원본을 덮지 않는다 (`--inplace` 는 승인 후).

사용:
    python3 -m venv .riso-venv && .riso-venv/bin/pip install pillow numpy
    .riso-venv/bin/python scripts/apply_riso_v2.py \\
        assets/illustrations/packs/bamboo.webp \\
        --out /tmp/riso_samples/bamboo.webp

파라미터 기본값 (§R-1 표):
  fine_delta=+2.0, coarse_delta=+1.5, misreg=1.5px (R),
  speckle=0.4% on L<40%, edge blur radius=1 opacity=20%,
  warm cast 4% #F4E8D0, seed=crc32(filename).
"""

from __future__ import annotations

import argparse
import binascii
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


HANJI_IVORY = np.array([0xF4, 0xE8, 0xD0], dtype=np.float32)


def _seed_for(path: Path) -> int:
    return binascii.crc32(path.name.encode("utf-8")) & 0xFFFFFFFF


def grain_delta(
    img: np.ndarray, *, fine: float, coarse: float, seed: int
) -> np.ndarray:
    """휘도 전용 그레인 추가분 (색상 불변). apply_paper_grain.grain 과 동일 기하."""
    h, w = img.shape[:2]
    rng = np.random.default_rng(seed + h + w)
    g_fine = rng.normal(0, fine, (h, w))
    small = rng.normal(0, coarse, (max(h // 6, 1), max(w // 6, 1)))
    g_coarse = np.asarray(
        Image.fromarray(
            ((small - small.min()) / (np.ptp(small) + 1e-6) * 255).astype("uint8")
        ).resize((w, h), Image.BILINEAR),
        dtype=np.float32,
    )
    g_coarse = (g_coarse / 255.0 - 0.5) * 2 * coarse
    noise = (g_fine + g_coarse)[..., None]
    return np.clip(img + noise, 0, 255)


def misregister_r(img: np.ndarray, *, offset_x: float, offset_y: float) -> np.ndarray:
    """R 채널만 시프트한 사본을 60% 블렌드."""
    h, w = img.shape[:2]
    shifted = np.zeros_like(img)
    shifted[..., 1:] = img[..., 1:]
    dx, dy = int(round(offset_x)), int(round(offset_y))
    src = Image.fromarray(img[..., 0].astype(np.uint8))
    canvas = Image.new("L", (w, h), 0)
    canvas.paste(src, (dx, dy))
    shifted[..., 0] = np.asarray(canvas, dtype=np.float32)
    return img * 0.4 + shifted * 0.6


def ink_speckle(
    img: np.ndarray, *, density: float, seed: int, luma_max: float = 0.40
) -> np.ndarray:
    """다크 면(L<40%)에 밝은 점 — 잉크가 안 앉은 종이 알갱이."""
    h, w = img.shape[:2]
    rng = np.random.default_rng(seed ^ 0xA5A5)
    luma = (
        0.2126 * img[..., 0] + 0.7152 * img[..., 1] + 0.0722 * img[..., 2]
    ) / 255.0
    mask = luma < luma_max
    speck = rng.random((h, w)) < density
    hit = mask & speck
    out = img.copy()
    out[hit] = np.clip(out[hit] + rng.uniform(18, 48, size=hit.sum())[..., None], 0, 255)
    return out


def edge_bleed(img: np.ndarray, *, radius: int = 1, opacity: float = 0.20) -> np.ndarray:
    """다크 플레인 마스크 팽창 후 저불투명 합성."""
    luma = (
        0.2126 * img[..., 0] + 0.7152 * img[..., 1] + 0.0722 * img[..., 2]
    )
    dark = (luma < 102).astype(np.uint8) * 255
    mask = Image.fromarray(dark, mode="L").filter(ImageFilter.MaxFilter(radius * 2 + 1))
    m = np.asarray(mask, dtype=np.float32) / 255.0 * opacity
    bleed = img * 0.85
    return img * (1.0 - m[..., None]) + bleed * m[..., None]


def warm_cast(img: np.ndarray, *, amount: float = 0.04) -> np.ndarray:
    return img * (1.0 - amount) + HANJI_IVORY * amount


def apply_riso(
    path: Path,
    *,
    fine_delta: float = 2.0,
    coarse_delta: float = 1.5,
    misreg: float = 1.5,
    speckle: float = 0.004,
    edge_opacity: float = 0.20,
    warm: float = 0.04,
) -> Image.Image:
    src = Image.open(path)
    has_alpha = src.mode in ("RGBA", "LA") or (
        src.mode == "P" and "transparency" in src.info
    )
    rgba = src.convert("RGBA") if has_alpha else None
    rgb = np.asarray((rgba or src).convert("RGB"), dtype=np.float32)
    seed = _seed_for(path)

    out = grain_delta(rgb, fine=fine_delta, coarse=coarse_delta, seed=seed)
    out = misregister_r(out, offset_x=misreg, offset_y=misreg * 0.33)
    out = ink_speckle(out, density=speckle, seed=seed)
    out = edge_bleed(out, radius=1, opacity=edge_opacity)
    out = warm_cast(out, amount=warm)
    out_u8 = np.clip(out, 0, 255).astype(np.uint8)

    if rgba is not None:
        alpha = np.asarray(rgba.split()[-1])
        return Image.fromarray(np.dstack([out_u8, alpha]), mode="RGBA")
    return Image.fromarray(out_u8, mode="RGB")


def _save(img: Image.Image, dest: Path, *, webp_q: int = 88) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.suffix.lower() == ".webp":
        img.save(dest, "WEBP", quality=webp_q, method=6)
    else:
        img.save(dest, quality=93)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("inputs", nargs="+", type=Path, help="입력 이미지 경로")
    p.add_argument(
        "--out-dir",
        type=Path,
        default=None,
        help="출력 디렉터리 (미지정 시 <stem>.riso.webp 옆에 생성)",
    )
    p.add_argument(
        "--out",
        type=Path,
        default=None,
        help="단일 입력일 때만 쓰는 명시 출력 경로",
    )
    p.add_argument(
        "--inplace",
        action="store_true",
        help="원본 덮어쓰기 (Jin 샘플 승인 후에만)",
    )
    p.add_argument("--fine-delta", type=float, default=2.0)
    p.add_argument("--coarse-delta", type=float, default=1.5)
    p.add_argument("--misreg", type=float, default=1.5)
    p.add_argument("--speckle", type=float, default=0.004)
    p.add_argument("--warm", type=float, default=0.04)
    p.add_argument("--webp-q", type=int, default=88)
    args = p.parse_args(argv)

    if args.out is not None and len(args.inputs) != 1:
        print("--out requires exactly one input", file=sys.stderr)
        return 2

    for src in args.inputs:
        if not src.is_file():
            print(f"missing: {src}", file=sys.stderr)
            return 1
        img = apply_riso(
            src,
            fine_delta=args.fine_delta,
            coarse_delta=args.coarse_delta,
            misreg=args.misreg,
            speckle=args.speckle,
            warm=args.warm,
        )
        if args.inplace:
            dest = src
        elif args.out is not None:
            dest = args.out
        elif args.out_dir is not None:
            dest = args.out_dir / (src.stem + ".riso.webp")
        else:
            dest = src.with_name(src.stem + ".riso.webp")
        _save(img, dest, webp_q=args.webp_q)
        print(f"{src} → {dest} ({os.path.getsize(dest)} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
