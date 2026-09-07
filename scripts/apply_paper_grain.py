"""종이/인쇄물 그레인 후처리 — 일러스트 세트 공통 파이프라인 (2026-08-14 §I).

Jin 피드백("벡터같이 깨끗함 — 인쇄물 질감 원함")의 해법. 재생성(크레딧+스타일
드리프트) 대신 로컬 후처리로: 미세 가우시안 입자(fine, 인쇄 그레인) + 1/6 해상도
저주파 노이즈 확대(coarse, 한지 섬유 얼룩)를 **휘도에만** 더한다 (색상 불변).

사용 (venv 에 pillow numpy 필요):
    python3 -m venv .grain-venv && .grain-venv/bin/pip install pillow numpy
    .grain-venv/bin/python scripts/apply_paper_grain.py foo.jpg bar.jpg
    → foo.grain.jpg ... 생성 후 `cwebp -q 84` 로 재인코딩해 규약 경로에 드롭.

강도 튜닝: fine(기본 5.0)=입자 거칠기, coarse(4.0)=얼룩 대비. 현재 번들
38장(activities 24 + packs 14)은 기본값으로 처리했다.
그레인은 엔트로피를 늘려 webp 가 커진다(≈60→87KB/장) — 의도적 트레이드오프.
"""

import sys

import numpy as np
from PIL import Image


def grain(path, out, fine=5.0, coarse=4.0, seed=7):
    img = np.asarray(Image.open(path).convert('RGB')).astype(np.float32)
    h, w = img.shape[:2]
    rng = np.random.default_rng(seed + h + w)
    g_fine = rng.normal(0, fine, (h, w))
    small = rng.normal(0, coarse, (max(h // 6, 1), max(w // 6, 1)))
    g_coarse = np.asarray(
        Image.fromarray(
            ((small - small.min()) / (np.ptp(small) + 1e-6) * 255).astype('uint8')
        ).resize((w, h), Image.BILINEAR),
        dtype=np.float32,
    )
    g_coarse = (g_coarse / 255.0 - 0.5) * 2 * coarse
    noise = (g_fine + g_coarse)[..., None]
    Image.fromarray(np.clip(img + noise, 0, 255).astype('uint8')).save(out, quality=93)


if __name__ == '__main__':
    for name in sys.argv[1:]:
        stem = name.rsplit('.', 1)[0]
        grain(name, f'{stem}.grain.jpg')
        print(stem, 'done')
