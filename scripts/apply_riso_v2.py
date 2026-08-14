"""리소그래프 인쇄 질감 v2 — 아트 디렉션 §R-1 (UI 개편 2, 2026-08-14).

Jin 확정 §1-5: 아날로그 질감 = **리소그래프 인쇄 느낌** — 그레인 강화 +
잉크 미스레지스터 + 가장자리 번짐 + 얼룩. 은은한 수준이 아니라 "손으로 찍은
인쇄물"로 보여야 한다.

기존 `apply_paper_grain.py`(휘도 전용 fine 5.0/coarse 4.0)의 **확장**이다 —
기존 스크립트는 배포 세트의 정본 이력으로 보존한다.

⚠️ 전제: 번들 39장(activities 24 + packs 14 + reward/paywall_hero)은 전부
이미 fine 5.0/coarse 4.0 그레인이 구워져 있고 원본은 소멸됐다. 따라서
① 그레인 단계는 **추가분(delta)만** 얹는다.

| 단계 | 파라미터 (기본값) |
|---|---|
| ① 그레인 추가분 | fine +2.0 / coarse +1.5 (기베이크 5.0/4.0 위 → 체감 ~7.0/5.5) |
| ② 잉크 미스레지스터 | R 채널 (+1.5, +0.5)px 시프트 사본 60% 블렌드 |
| ③ 잉크 스펙클 | density 0.4%, 휘도 L<40% 면 한정 (잉크가 안 앉은 종이 알갱이) |
| ④ 가장자리 번짐 | 다크 플레인 마스크 1px 팽창, opacity 20% |
| ⑤ 웜 캐스트 | 4% overlay #F4E8D0 (Hanji Ivory) |
| 시드 | crc32(파일명) — 파일별 결정적 재현 |

적용 대상: 위 39장 전부. `gye/`·`hanok_stages/`·`stamps/`(투명 PNG·레이어
합성물)는 **스코프 제외** — Jin 별도 결정.

⛔ 게이트 (§J-1): 샘플 3장(packs/bamboo · activities/listening ·
reward/paywall_hero) before/after 를 Jin 이 승인하기 전에는 번들 일괄 처리
금지. 그래서 기본 모드는 `--samples`(번들 밖 리뷰 폴더에만 출력)이고, 번들
덮어쓰기는 `--apply --jin-approved` 둘 다 있어야 실행된다.

사용 (venv 에 pillow numpy 필요):
    python3 -m venv .grain-venv && .grain-venv/bin/pip install pillow numpy
    # 1) Jin 게이트용 샘플 3장 (번들 무접촉):
    .grain-venv/bin/python scripts/apply_riso_v2.py --samples
    # 2) 승인 후 번들 39장 일괄 (webp q88 재인코딩, 장당 ≤70KB 목표):
    .grain-venv/bin/python scripts/apply_riso_v2.py --apply --jin-approved
"""

from __future__ import annotations

import argparse
import os
import sys
import zlib

import numpy as np
from PIL import Image, ImageFilter

# ── 파라미터 (기본값 = 핸드오프 §R-1 표) ─────────────────────────────────
FINE_DELTA = 2.0
COARSE_DELTA = 1.5
MISREGISTER_SHIFT = (1.5, 0.5)  # R 채널 (dx, dy) px
MISREGISTER_BLEND = 0.60
SPECKLE_DENSITY = 0.004  # 0.4%
SPECKLE_LUMA_MAX = 0.40  # L<40% 면 한정
BLEED_RADIUS_PX = 1
BLEED_OPACITY = 0.20
WARM_CAST = 0.04  # 4% overlay
WARM_COLOR = (0xF4, 0xE8, 0xD0)  # Hanji Ivory
WEBP_QUALITY = 88

SAMPLES = [
    'assets/illustrations/packs/bamboo.webp',
    'assets/illustrations/activities/listening.webp',
    'assets/illustrations/reward/paywall_hero.webp',
]

BATCH_DIRS = [
    'assets/illustrations/activities',
    'assets/illustrations/packs',
]
BATCH_EXTRA = ['assets/illustrations/reward/paywall_hero.webp']

SAMPLE_OUT_DIR = 'docs/assets/riso_samples_2026-08-14'


def _seed_for(path: str) -> int:
    return zlib.crc32(os.path.basename(path).encode('utf-8'))


def _grain_delta(img: np.ndarray, rng: np.random.Generator) -> np.ndarray:
    """① 휘도 전용 그레인 추가분 — apply_paper_grain.grain() 과 같은 구조."""
    h, w = img.shape[:2]
    g_fine = rng.normal(0, FINE_DELTA, (h, w))
    small = rng.normal(0, COARSE_DELTA, (max(h // 6, 1), max(w // 6, 1)))
    g_coarse = np.asarray(
        Image.fromarray(
            ((small - small.min()) / (np.ptp(small) + 1e-6) * 255).astype('uint8')
        ).resize((w, h), Image.BILINEAR),
        dtype=np.float32,
    )
    g_coarse = (g_coarse / 255.0 - 0.5) * 2 * COARSE_DELTA
    return img + (g_fine + g_coarse)[..., None]


def _misregister(img: np.ndarray) -> np.ndarray:
    """② R 채널만 (+dx, +dy) 시프트한 사본을 60% 블렌드 — 단청 적/금에서
    판 어긋남이 드러난다."""
    dx, dy = MISREGISTER_SHIFT
    r = Image.fromarray(np.clip(img[..., 0], 0, 255).astype('uint8'))
    shifted = r.transform(
        r.size,
        Image.AFFINE,
        (1, 0, -dx, 0, 1, -dy),
        resample=Image.BILINEAR,
        fillcolor=None,
    )
    shifted_arr = np.asarray(shifted, dtype=np.float32)
    out = img.copy()
    out[..., 0] = img[..., 0] * (1 - MISREGISTER_BLEND) + shifted_arr * MISREGISTER_BLEND
    return out


def _luma(img: np.ndarray) -> np.ndarray:
    return 0.2126 * img[..., 0] + 0.7152 * img[..., 1] + 0.0722 * img[..., 2]


def _speckle(img: np.ndarray, rng: np.random.Generator) -> np.ndarray:
    """③ 다크 면에 밝은 점 노이즈 — 잉크가 안 앉은 종이 알갱이."""
    h, w = img.shape[:2]
    dark = _luma(img) < (SPECKLE_LUMA_MAX * 255.0)
    hits = rng.random((h, w)) < SPECKLE_DENSITY
    mask = dark & hits
    lift = rng.uniform(55, 110, (h, w))[..., None]
    return np.where(mask[..., None], np.clip(img + lift, 0, 255), img)


def _edge_bleed(img: np.ndarray) -> np.ndarray:
    """④ 다크 플레인 마스크를 1px 팽창해 저불투명 합성 — 잉크 번짐."""
    dark_mask = (_luma(img) < (SPECKLE_LUMA_MAX * 255.0)).astype('uint8') * 255
    dilated = np.asarray(
        Image.fromarray(dark_mask).filter(
            ImageFilter.MaxFilter(2 * BLEED_RADIUS_PX + 1)
        ),
        dtype=np.float32,
    )
    ring = np.clip(dilated - dark_mask.astype(np.float32), 0, 255) / 255.0
    dark_mean = img[_luma(img) < (SPECKLE_LUMA_MAX * 255.0)]
    ink = dark_mean.mean(axis=0) if dark_mean.size else np.array([26, 20, 16])
    alpha = (ring * BLEED_OPACITY)[..., None]
    return img * (1 - alpha) + ink[None, None, :] * alpha


def _warm_cast(img: np.ndarray) -> np.ndarray:
    """⑤ 전체 소폭 온도 상승 — Hanji Ivory 4% overlay."""
    warm = np.array(WARM_COLOR, dtype=np.float32)[None, None, :]
    return img * (1 - WARM_CAST) + warm * WARM_CAST


def riso(path: str, out: str) -> None:
    rng = np.random.default_rng(_seed_for(path))
    img = np.asarray(Image.open(path).convert('RGB')).astype(np.float32)
    img = _grain_delta(img, rng)
    img = _misregister(img)
    img = _speckle(img, rng)
    img = _edge_bleed(img)
    img = _warm_cast(img)
    result = Image.fromarray(np.clip(img, 0, 255).astype('uint8'))
    result.save(out, format='WEBP', quality=WEBP_QUALITY, method=6)


def run_samples() -> None:
    os.makedirs(SAMPLE_OUT_DIR, exist_ok=True)
    for src in SAMPLES:
        name = os.path.basename(src).rsplit('.', 1)[0]
        before = os.path.join(SAMPLE_OUT_DIR, f'{name}.before.webp')
        after = os.path.join(SAMPLE_OUT_DIR, f'{name}.riso_v2.webp')
        # before = 현 번들본 그대로 복사 (비교 기준).
        Image.open(src).convert('RGB').save(
            before, format='WEBP', quality=WEBP_QUALITY, method=6
        )
        riso(src, after)
        kb = os.path.getsize(after) / 1024
        print(f'{src} → {after} ({kb:.0f}KB)')
    print(f'\nJin 게이트: {SAMPLE_OUT_DIR} 의 before/after 를 시각 승인한 뒤에만'
          f' --apply --jin-approved 로 번들 일괄 처리.')


def run_apply() -> None:
    targets: list[str] = []
    for d in BATCH_DIRS:
        targets += sorted(
            os.path.join(d, f) for f in os.listdir(d) if f.endswith('.webp')
        )
    targets += BATCH_EXTRA
    for src in targets:
        riso(src, src)
        kb = os.path.getsize(src) / 1024
        flag = '' if kb <= 70 else '  ⚠️ >70KB'
        print(f'{src} ({kb:.0f}KB){flag}')
    print(f'\n{len(targets)}장 처리 완료 — asset-integrity/매트 가드 테스트를 재실행할 것.')


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--samples', action='store_true',
                        help='Jin 게이트용 샘플 3장 (번들 무접촉)')
    parser.add_argument('--apply', action='store_true',
                        help='번들 39장 일괄 덮어쓰기 (게이트 필요)')
    parser.add_argument('--jin-approved', action='store_true',
                        help='샘플 승인 완료 확인 — --apply 의 필수 게이트')
    args = parser.parse_args()
    if args.apply:
        if not args.jin_approved:
            print('⛔ 게이트: --apply 는 --jin-approved 와 함께만 실행된다 '
                  '(§J-1 — 미승인 파라미터로 전량 처리 금지).', file=sys.stderr)
            return 2
        run_apply()
        return 0
    run_samples()
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
