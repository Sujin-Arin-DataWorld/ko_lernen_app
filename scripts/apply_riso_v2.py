"""리소그래프 인쇄 질감 후처리 파이프라인 v2 (2026-08-14 §R-1).

5단계 후처리:
1. 그레인 추가분 (fine +2.0, coarse +1.5)
2. 잉크 미스레지스터 (R 채널 +1.5px, +0.5px 시프트 60% 블렌드)
3. 잉크 스펙클 (L<40% 어두운 면에 밝은 종이 점 0.4% 밀도)
4. 가장자리 번짐 (다크 플레인 마스크 1px 팽창 20% 투명도 합성)
5. 웜 캐스트 (4% overlay #F4E8D0 Hanji Ivory)
시드: crc32(파일명) 기반 결정론적 생성
"""

import sys
import zlib
from PIL import Image, ImageFilter
import numpy as np


def apply_riso_v2(
    input_path: str,
    output_path: str,
    fine_delta: float = 2.0,
    coarse_delta: float = 1.5,
    misregister_offset: tuple[float, float] = (1.5, 0.5),
    misregister_blend: float = 0.60,
    speckle_density: float = 0.004,
    bleed_radius: int = 1,
    bleed_opacity: float = 0.20,
    warm_cast_opacity: float = 0.04,
    warm_color: tuple[int, int, int] = (244, 232, 208),
):
    orig_img = Image.open(input_path).convert('RGB')
    w, h = orig_img.size
    seed = zlib.crc32(input_path.encode('utf-8')) & 0xFFFFFFFF
    rng = np.random.default_rng(seed)

    arr = np.asarray(orig_img).astype(np.float32)

    # 1. 그레인 추가분 (fine_delta / coarse_delta)
    g_fine = rng.normal(0, fine_delta, (h, w))
    small = rng.normal(0, coarse_delta, (max(h // 6, 1), max(w // 6, 1)))
    g_coarse = np.asarray(
        Image.fromarray(
            ((small - small.min()) / (np.ptp(small) + 1e-6) * 255).astype('uint8')
        ).resize((w, h), Image.BILINEAR),
        dtype=np.float32,
    )
    g_coarse = (g_coarse / 255.0 - 0.5) * 2 * coarse_delta
    noise = (g_fine + g_coarse)[..., None]
    arr = np.clip(arr + noise, 0, 255)

    # 2. 잉크 미스레지스터 (R 채널 shift & blend)
    r_channel = arr[:, :, 0]
    r_img = Image.fromarray(r_channel.astype('uint8'))
    # Translate R channel
    dx, dy = int(round(misregister_offset[0])), int(round(misregister_offset[1]))
    shifted_r = np.roll(r_channel, (dy, dx), axis=(0, 1))
    arr[:, :, 0] = arr[:, :, 0] * (1.0 - misregister_blend) + shifted_r * misregister_blend

    # 3. 잉크 스펙클 (어두운 영역 L < 40% 에 밝은 종이 점)
    # Luminance approx
    lum = 0.299 * arr[:, :, 0] + 0.587 * arr[:, :, 1] + 0.114 * arr[:, :, 2]
    dark_mask = (lum < 102.0) # 40% of 255
    speckle_mask = (rng.random((h, w)) < speckle_density) & dark_mask
    for c in range(3):
        arr[speckle_mask, c] = np.clip(arr[speckle_mask, c] + rng.uniform(40, 90, np.count_nonzero(speckle_mask)), 0, 255)

    # 4. 가장자리 번짐 (Dark plane expansion & low opacity blend)
    img_post = Image.fromarray(arr.astype('uint8'))
    blurred_img = img_post.filter(ImageFilter.GaussianBlur(radius=bleed_radius))
    arr_blurred = np.asarray(blurred_img).astype(np.float32)
    arr = arr * (1.0 - bleed_opacity) + arr_blurred * bleed_opacity

    # 5. 웜 캐스트 (4% overlay #F4E8D0)
    warm_arr = np.ones_like(arr) * np.array(warm_color, dtype=np.float32)
    arr = arr * (1.0 - warm_cast_opacity) + warm_arr * warm_cast_opacity

    final_img = Image.fromarray(np.clip(arr, 0, 255).astype('uint8'))
    final_img.save(output_path, quality=93)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python apply_riso_v2.py <input_image_paths...>")
        sys.exit(1)

    for path in sys.argv[1:]:
        stem = path.rsplit('.', 1)[0]
        ext = path.rsplit('.', 1)[1] if '.' in path else 'png'
        out = f"{stem}.riso.{ext}"
        apply_riso_v2(path, out)
        print(f"Processed {path} -> {out}")
