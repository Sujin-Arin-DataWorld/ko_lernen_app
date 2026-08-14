"""리소그래프 인쇄 질감 후처리 v2 — 아트 디렉션 v2 §R-1 (2026-08-14).

Jin 피드백: 기존 그레인은 "은은한" 수준이라 아직 벡터처럼 보인다. 목표는
**손으로 찍은 인쇄물** — 그레인만으로는 안 되고, 실제 리소 인쇄의 결함들을
같이 넣어야 한다: 색판이 미세하게 어긋나고(misregistration), 잉크가 고르게
안 앉고(speckle), 어두운 면 가장자리가 번지고(bleed), 종이가 따뜻하다.

⚠️ **전제**: 번들 39장(activities 24 + packs 14 + paywall_hero)은 이미
fine 5.0 / coarse 4.0 그레인이 구워져 있고 원본은 소멸했다
(`apply_paper_grain.py` docstring). 그래서 ① 단계는 **추가분(delta)** 이다 —
기본값을 그 위에 얹으면 체감 ~7.0/5.5 가 된다. 원본이 있는 새 아트를
처리할 때는 `--fine 7.0 --coarse 5.5` 로 한 번에 간다.

기존 `apply_paper_grain.py` 는 **지우지 않는다** — 배포된 세트의 정본 이력이다.

단계 (순서 의미 있음):
  ① 그레인 추가분   fine +2.0 / coarse +1.5   휘도 전용(색상 불변)
  ② 잉크 미스레지스터 R 채널만 (+1.5, +0.5)px 시프트 사본을 60% 블렌드
                     — 단청 적/금에서 판 어긋남이 가장 잘 보인다
  ③ 잉크 스펙클     밀도 0.4%, 휘도 L<40% 면 한정. 다크 면에 **밝은** 점
                     = 잉크가 안 앉은 종이 알갱이
  ④ 가장자리 번짐   다크 플레인 마스크를 1px 팽창해 20% 불투명도로 합성
  ⑤ 웜 캐스트       #F4E8D0(Hanji Ivory) 4% overlay

시드는 `crc32(파일명)` — 파일마다 다르되 재실행하면 같은 결과가 나온다.

사용 (venv 에 pillow numpy 필요):
    python3 -m venv .grain-venv && .grain-venv/bin/pip install pillow numpy
    .grain-venv/bin/python scripts/apply_riso_v2.py assets/.../bamboo.webp
    → bamboo.riso.png 생성 후 `cwebp -q 88` 로 재인코딩해 규약 경로에 드롭.

⛔ **게이트**: 샘플 3장(packs/bamboo · activities/listening ·
reward/paywall_hero)을 처리해 before/after 를 Jin 이 승인하기 전에는 전량
처리 금지. 미승인 파라미터로 39장을 덮으면 되돌릴 원본이 없다.
"""

import argparse
import zlib
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

# 한지 아이보리 — ⑤ 웜 캐스트의 오버레이 색.
HANJI_IVORY = (0xF4, 0xE8, 0xD0)


def _luma(rgb: np.ndarray) -> np.ndarray:
    """Rec. 601 휘도 (0..255)."""
    return rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32)


def _grain(rgb: np.ndarray, rng, fine: float, coarse: float) -> np.ndarray:
    """① 휘도 전용 그레인 — `apply_paper_grain.grain()` 과 같은 수식."""
    h, w = rgb.shape[:2]
    g_fine = rng.normal(0, fine, (h, w))
    small = rng.normal(0, coarse, (max(h // 6, 1), max(w // 6, 1)))
    g_coarse = np.asarray(
        Image.fromarray(
            ((small - small.min()) / (np.ptp(small) + 1e-6) * 255).astype('uint8')
        ).resize((w, h), Image.BILINEAR),
        dtype=np.float32,
    )
    g_coarse = (g_coarse / 255.0 - 0.5) * 2 * coarse
    return rgb + (g_fine + g_coarse)[..., None]


def _misregister(rgb: np.ndarray, offset: float, blend: float) -> np.ndarray:
    """② 색판 어긋남 — R 채널만 살짝 밀어 60% 섞는다.

    실제 리소는 판마다 종이를 다시 물려서 1px 안팎으로 어긋난다. 전 채널을
    밀면 그냥 흐려지므로 한 채널만 민다.
    """
    red = Image.fromarray(rgb[..., 0].clip(0, 255).astype('uint8'))
    shifted = np.asarray(
        red.transform(
            red.size,
            Image.AFFINE,
            (1, 0, -offset, 0, 1, -offset / 3),
            resample=Image.BILINEAR,
        ),
        dtype=np.float32,
    )
    out = rgb.copy()
    out[..., 0] = rgb[..., 0] * (1 - blend) + shifted * blend
    return out


def _speckle(rgb: np.ndarray, rng, density: float, dark_below: float) -> np.ndarray:
    """③ 잉크 스펙클 — 어두운 면에만 밝은 점을 흩뿌린다."""
    h, w = rgb.shape[:2]
    dark = _luma(rgb) < (dark_below * 255)
    hits = (rng.random((h, w)) < density) & dark
    out = rgb.copy()
    out[hits] = np.clip(out[hits] + rng.uniform(60, 120, (hits.sum(), 1)), 0, 255)
    return out


def _edge_bleed(rgb: np.ndarray, radius: int, opacity: float) -> np.ndarray:
    """④ 가장자리 번짐 — 다크 플레인 마스크를 팽창해 저불투명 합성."""
    dark = (_luma(rgb) < 110).astype('uint8') * 255
    grown = np.asarray(
        Image.fromarray(dark).filter(ImageFilter.MaxFilter(radius * 2 + 1)),
        dtype=np.float32,
    )
    # 팽창분(원래 어둡지 않았는데 이웃이 어두운 곳)만 남긴다.
    halo = np.clip(grown - dark.astype(np.float32), 0, 255) / 255.0
    return rgb * (1 - halo[..., None] * opacity)


def _warm_cast(rgb: np.ndarray, amount: float) -> np.ndarray:
    """⑤ 웜 캐스트 — 종이 자체의 온도."""
    ivory = np.array(HANJI_IVORY, dtype=np.float32)
    return rgb * (1 - amount) + ivory * amount


def riso(
    path: Path,
    out: Path,
    *,
    fine: float = 2.0,
    coarse: float = 1.5,
    misregister: float = 1.5,
    misregister_blend: float = 0.60,
    speckle: float = 0.004,
    speckle_dark_below: float = 0.40,
    bleed_radius: int = 1,
    bleed_opacity: float = 0.20,
    warm: float = 0.04,
) -> None:
    src = Image.open(path)
    alpha = src.getchannel('A') if src.mode in ('RGBA', 'LA') else None
    rgb = np.asarray(src.convert('RGB')).astype(np.float32)

    # 파일별 결정적 시드 — 같은 파일은 몇 번 돌려도 같은 질감이 나온다.
    rng = np.random.default_rng(zlib.crc32(path.name.encode()) & 0xFFFFFFFF)

    rgb = _grain(rgb, rng, fine, coarse)
    rgb = _misregister(rgb, misregister, misregister_blend)
    rgb = _speckle(rgb, rng, speckle, speckle_dark_below)
    rgb = _edge_bleed(rgb, bleed_radius, bleed_opacity)
    rgb = _warm_cast(rgb, warm)

    result = Image.fromarray(np.clip(rgb, 0, 255).astype('uint8'))
    if alpha is not None:
        # 투명 아트(도장·덱 아이콘)는 알파를 그대로 되돌려 준다 — 질감이
        # 배경까지 칠해 사각형이 생기면 안 된다.
        result = result.convert('RGBA')
        result.putalpha(alpha)
    result.save(out)


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('paths', nargs='+', type=Path)
    p.add_argument('--fine', type=float, default=2.0)
    p.add_argument('--coarse', type=float, default=1.5)
    p.add_argument('--misregister', type=float, default=1.5)
    p.add_argument('--speckle', type=float, default=0.004)
    p.add_argument('--bleed-opacity', type=float, default=0.20)
    p.add_argument('--warm', type=float, default=0.04)
    p.add_argument(
        '--suffix',
        default='.riso.png',
        help='출력 접미. 원본을 덮어쓰지 않는다 (되돌릴 원본이 없다).',
    )
    args = p.parse_args()

    for path in args.paths:
        out = path.with_name(path.stem + args.suffix)
        riso(
            path,
            out,
            fine=args.fine,
            coarse=args.coarse,
            misregister=args.misregister,
            speckle=args.speckle,
            bleed_opacity=args.bleed_opacity,
            warm=args.warm,
        )
        print(f'{path} -> {out}')


if __name__ == '__main__':
    main()
