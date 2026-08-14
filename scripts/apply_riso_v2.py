"""리소그래프 한지 인쇄 후처리 v2 (2026-08-14 UI/UX 개편 2 §R-1).

기존 `apply_paper_grain.py` 를 확장한다. 번들 39장은 이미 fine 5.0/coarse 4.0
그레인이 구워져 있으므로 그레인 단계는 **추가분(delta)** 만 얹는다.

단계:
  1. grain delta  fine +2.0 / coarse +1.5  (휘도 전용, 기존 grain() 재사용)
  2. R 채널 미스레지스터  (+1.5, +0.5)px 시프트 사본을 60% 블렌드
  3. 잉크 스펙클  0.4%, 휘도 L<40% 면만
  4. 가장자리 번짐  1px, opacity 20%
  5. 웜 캐스트  4% overlay #F4E8D0
시드: crc32(파일명) — 파일별 결정적 재현.

사용:
    python3 scripts/apply_riso_v2.py packs/bamboo.webp
    → packs/bamboo.riso.jpg

⛔ 샘플 3장(packs/bamboo, activities/listening, reward/paywall_hero)의
Jin 승인 없이 39장 일괄 처리 금지.
"""

from __future__ import annotations

import binascii
import os
import sys

import numpy as np
from PIL import Image, ImageFilter


def grain(img: np.ndarray, fine: float = 2.0, coarse: float = 1.5, seed: int = 7) -> np.ndarray:
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


def _shift_channel(channel: np.ndarray, dx: float, dy: float) -> np.ndarray:
    pil = Image.fromarray(channel.astype(np.uint8), mode="L")
    shifted = pil.transform(
        pil.size,
        Image.AFFINE,
        (1, 0, -dx, 0, 1, -dy),
        resample=Image.BILINEAR,
    )
    return np.asarray(shifted, dtype=np.float32)


def misregister_r(img: np.ndarray, dx: float = 1.5, dy: float = 0.5, blend: float = 0.6) -> np.ndarray:
    out = img.copy()
    shifted = _shift_channel(img[:, :, 0], dx, dy)
    out[:, :, 0] = img[:, :, 0] * (1.0 - blend) + shifted * blend
    return out


def speckle(img: np.ndarray, density: float = 0.004, seed: int = 7) -> np.ndarray:
    h, w = img.shape[:2]
    rng = np.random.default_rng(seed + 13)
    luma = img.mean(axis=2)
    dark = luma < (0.40 * 255.0)
    hits = (rng.random((h, w)) < density) & dark
    out = img.copy()
    out[hits] = np.clip(out[hits] + rng.uniform(40, 90, size=(int(hits.sum()), 1)), 0, 255)
    return out


def edge_bleed(img: np.ndarray, radius: int = 1, opacity: float = 0.20) -> np.ndarray:
    luma = img.mean(axis=2)
    dark = (luma < (0.40 * 255.0)).astype(np.uint8) * 255
    mask = Image.fromarray(dark, mode="L").filter(ImageFilter.MaxFilter(radius * 2 + 1))
    expanded = np.asarray(mask, dtype=np.float32) / 255.0
    original = (luma < (0.40 * 255.0)).astype(np.float32)
    ring = np.clip(expanded - original, 0, 1)[..., None]
    ink = img * (1.0 - ring) + (img * 0.55) * ring
    return img * (1.0 - opacity) + ink * opacity


def warm_cast(img: np.ndarray, amount: float = 0.04) -> np.ndarray:
    ivory = np.array([0xF4, 0xE8, 0xD0], dtype=np.float32)
    return np.clip(img * (1.0 - amount) + ivory * amount, 0, 255)


def apply_riso(path: str, out: str | None = None) -> str:
    seed = binascii.crc32(os.path.basename(path).encode("utf-8")) & 0xFFFFFFFF
    img = np.asarray(Image.open(path).convert("RGB")).astype(np.float32)
    img = grain(img, fine=2.0, coarse=1.5, seed=seed)
    img = misregister_r(img)
    img = speckle(img, seed=seed)
    img = edge_bleed(img)
    img = warm_cast(img)
    dest = out or f"{path.rsplit('.', 1)[0]}.riso.jpg"
    Image.fromarray(img.astype(np.uint8)).save(dest, quality=93)
    return dest


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: apply_riso_v2.py <image> [image...]", file=sys.stderr)
        sys.exit(2)
    for name in sys.argv[1:]:
        dest = apply_riso(name)
        print(name, "->", dest)
