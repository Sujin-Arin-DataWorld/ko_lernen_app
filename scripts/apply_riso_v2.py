"""리소그래프 인쇄 질감 v2 — 아트 디렉션 §R-1 (UI 개편 2, 2026-08-14).

Jin 확정 §1-5: 아날로그 질감 = **리소그래프 인쇄 느낌** — 그레인 강화 +
잉크 미스레지스터 + 가장자리 번짐 + 얼룩. 은은한 수준이 아니라 "손으로 찍은
인쇄물"로 보여야 한다.

기존 `apply_paper_grain.py`(휘도 전용 fine 5.0/coarse 4.0)의 **확장**이다 —
기존 스크립트는 배포 세트의 정본 이력으로 보존한다.

⚠️ 전제: 번들 38장(activities 24 + packs 14)은 전부
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

적용 대상: 위 38장 전부. `gye/`·`hanok_stages/`·`stamps/`(투명 PNG·레이어
합성물)는 **스코프 제외** — Jin 별도 결정.

⛔ 게이트 (§J-1): 샘플 2장(packs/bamboo · activities/listening)의
before/after 를 Jin 이 승인하기 전에는 번들 일괄 처리
금지. 그래서 기본 모드는 `--samples`(번들 밖 리뷰 폴더에만 출력)이고, 번들
덮어쓰기는 `--apply --jin-approved --approval-sha256 <샘플 manifest hash>`
세 값이 모두 있어야 실행된다. 대상 38장의 원본 해시도 일치해야 하므로 이미
처리했거나 리뷰 뒤 바뀐 번들에 효과가 중복 적용되지 않는다.

사용 (venv 에 pillow numpy 필요):
    python3 -m venv .grain-venv && .grain-venv/bin/pip install pillow numpy
    # 1) Jin 게이트용 샘플 2장 (번들 무접촉):
    .grain-venv/bin/python scripts/apply_riso_v2.py --samples
    # 2) 승인 후 번들 38장 일괄 (출력된 manifest hash 사용, q88 장당 ≤70KB 강제):
    .grain-venv/bin/python scripts/apply_riso_v2.py --apply --jin-approved \
      --approval-sha256 <approval_manifest.json SHA-256>
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import tempfile
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
MAX_WEBP_BYTES = 70 * 1024

SAMPLES = [
    'assets/illustrations/packs/bamboo.webp',
    'assets/illustrations/activities/listening.webp',
]

TARGET_PREIMAGE_SHA256 = {
    'assets/illustrations/activities/book_capture.webp': '43e4cf3c9fa394d2706f8e060d0b57140b498664296357d6c74b92a3f6416192',
    'assets/illustrations/activities/bookshelf.webp': '21c775be5d9cd625426f9094f8294f1e8225316a7030da2527818f0f2babefdf',
    'assets/illustrations/activities/calligraphy.webp': '152ebcf5bbeb24f19bb90f011736013fc5821d151a0d600aa58c1b30972f9829',
    'assets/illustrations/activities/chosung.webp': '49aa02c02279ae8d1b92216b61d4fb8c5520d4c368b0ae09b977174d3879b41a',
    'assets/illustrations/activities/cloze.webp': 'd9c35878b0c7c5fd7a267d89128e677a6950a48832c31897d53e69a10c607bf9',
    'assets/illustrations/activities/course.webp': '40b3cb1192893a49d306ae6edd8c5b469b2601a8a77f18c2d17f678a5555ce6b',
    'assets/illustrations/activities/custom_matching.webp': '2da3c678c109dffb164d36deb8749f6305cab1f8b6786f2675cbd725ab6978f2',
    'assets/illustrations/activities/custom_quiz.webp': '95a789f432fdc149de12911407d1ef3df869222a1eefe62b9443110caeb688d0',
    'assets/illustrations/activities/custom_typing.webp': '9fc43c973d608f30b5cc509ea34ae1b9410fc11d6b440b5b2fffcee1bd080d19',
    'assets/illustrations/activities/daily_game.webp': '01a7b80d9699c3bc04622d7f3613a11074cf7a0e241eed6db89b7cb9038b8b5f',
    'assets/illustrations/activities/grammar.webp': '330c7b9ef18e6ebe4718b8f141a899026397d5cabc5805d5d44fa7e749d4bdb1',
    'assets/illustrations/activities/hangul.webp': '77cb04dde970a0c06d9730a01c8ef43724672bfcb801e34a09874eac85850b02',
    'assets/illustrations/activities/hard_words.webp': '2b4b54c4ad179260d6716aa62c40dfa7a6a43f3a40137819fa79fdf082473f6a',
    'assets/illustrations/activities/kkeunmari.webp': '1653ca7f9980c9a5e40624e4b890d1515eb3791a1bfb0edaff52d3ed7001f19d',
    'assets/illustrations/activities/listening.webp': '7ff8742bba87adf0309b0b1adf62734700be672b64d1ab28a758d2e9069aab2e',
    'assets/illustrations/activities/pronunciation.webp': 'fb6d9be0f7f0a4eeb0f0bce6a66743dd16ed3d4cff9467d76d91dd9961992391',
    'assets/illustrations/activities/scenarios.webp': 'fa8df13eff1dacd1d2f0cda4c3809bd85fd44bbdb6de850fa81b46f7f7311372',
    'assets/illustrations/activities/sentence_arcade.webp': '83ea42125bf1a21000423fff29c10dad079a4527f38fdece270cae4f6c87c312',
    'assets/illustrations/activities/smalltalk.webp': 'bad8279ccf1638fdf6054fc1b4fb052db61c1a818116286e7b6ce7ae5c0b5ed9',
    'assets/illustrations/activities/speed_match.webp': 'bb84e5c15aa900a92af845e8e283dcc55773e7cf176176f1b72fcfb8bb9f1c9a',
    'assets/illustrations/activities/srs.webp': '7627d4088a9109ef19710ceba7df36edbf5c83a55b408c9890bc3809c2681156',
    'assets/illustrations/activities/syllable_cross.webp': '688bca9d768491bcaa4487d6450cdddde3357c536d6b905f06bf81922b398e13',
    'assets/illustrations/activities/vocab_packs.webp': '1facf8ff344ca7d09362e8e639593caca8910e8e60f6532d3d1e8140c8d1dcc0',
    'assets/illustrations/activities/word_search.webp': 'fee3b57d0bd4b539e9db137462ecaf2300ca197bcf0791714056268eb48a8c21',
    'assets/illustrations/packs/bamboo.webp': '807afdbea0af9827d6a6c8acdcde4f27a4fbcbba6b80e0510a859826f40fe42e',
    'assets/illustrations/packs/chilbo.webp': '0175f487466403589dc4fe5a09e968716453fa9ee30bdcf9c543eec6a2e08b0c',
    'assets/illustrations/packs/chrysanthemum.webp': '2ccc6d924a6ead04fc4766535c9531df1837fd1f8ccd5a4ac82f413200804d72',
    'assets/illustrations/packs/cloud.webp': 'e6457666fd5c389d61d4a90b097638f6202d66ca18af4dbe3817d8fef8f280e3',
    'assets/illustrations/packs/gwigap.webp': 'f763dafde98dc35ab25c92f38f962a51183bdba53913811196351f8ae5a95817',
    'assets/illustrations/packs/lotus.webp': 'ae3ff1034e46489c56fbef0dd831473b8be3db4397ab7315bfaefa4383e3ab2e',
    'assets/illustrations/packs/manja.webp': 'f9b47d8c7ed59e32d3ca85bdfd8b3d6019acfeacd6b33db65dc7d059ac6a55ee',
    'assets/illustrations/packs/mountain.webp': '6bfd3f78f41fb7c70e77349c1031095e12f26c90bf2e76ff8165b8fb6718bc53',
    'assets/illustrations/packs/octagon.webp': 'f5bfbe5d3f12abfa7620439377edd5b5680483dd758ac5d5c1d5232a0ec87225',
    'assets/illustrations/packs/peony.webp': '538575cd3d84a0c422128875ccd504344cebb8a472dc76914647d72a8e04d8d6',
    'assets/illustrations/packs/plum.webp': '2cfed8051d3b32b24cc3ea33315620a9e18d66fd1b136a993b2388d9c7c3033c',
    'assets/illustrations/packs/taegeuk.webp': '134b57e57d590f67a44a308718a801971bc96c6a9647ee859c42c3f279585091',
    'assets/illustrations/packs/vine.webp': '7e1327c786c346c137f0843390ccbbf958f6d026ce69670ab3de5b61ba5838be',
    'assets/illustrations/packs/wave.webp': '6a9cf0f7e3975eb538a85ddeda2d869b410139d516a02cd1c03305bee375340f',
}

SAMPLE_OUT_DIR = 'docs/assets/riso_samples_2026-08-14'
APPROVAL_MANIFEST = os.path.join(SAMPLE_OUT_DIR, 'approval_manifest.json')


def _sha256(path: str) -> str:
    digest = hashlib.sha256()
    with open(path, 'rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def _pipeline_parameters() -> dict[str, object]:
    return {
        'fine_delta': FINE_DELTA,
        'coarse_delta': COARSE_DELTA,
        'misregister_shift': list(MISREGISTER_SHIFT),
        'misregister_blend': MISREGISTER_BLEND,
        'speckle_density': SPECKLE_DENSITY,
        'speckle_luma_max': SPECKLE_LUMA_MAX,
        'bleed_radius_px': BLEED_RADIUS_PX,
        'bleed_opacity': BLEED_OPACITY,
        'warm_cast': WARM_CAST,
        'warm_color': list(WARM_COLOR),
        'webp_quality': WEBP_QUALITY,
        'max_webp_bytes': MAX_WEBP_BYTES,
    }


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
    sample_records: list[dict[str, object]] = []
    for src in SAMPLES:
        name = os.path.basename(src).rsplit('.', 1)[0]
        before = os.path.join(SAMPLE_OUT_DIR, f'{name}.before.webp')
        after = os.path.join(SAMPLE_OUT_DIR, f'{name}.riso_v2.webp')
        # before = 현 번들본 그대로 복사 (비교 기준).
        Image.open(src).convert('RGB').save(
            before, format='WEBP', quality=WEBP_QUALITY, method=6
        )
        riso(src, after)
        size = os.path.getsize(after)
        sample_records.append({
            'source': src,
            'source_sha256': _sha256(src),
            'before': before,
            'before_sha256': _sha256(before),
            'after': after,
            'after_sha256': _sha256(after),
            'after_bytes': size,
        })
        kb = size / 1024
        flag = '' if size <= MAX_WEBP_BYTES else '  ⚠️ production limit exceeded'
        print(f'{src} → {after} ({kb:.0f}KB){flag}')
    manifest = {
        'schema': 1,
        'pipeline_parameters': _pipeline_parameters(),
        'target_preimage_sha256': TARGET_PREIMAGE_SHA256,
        'samples': sample_records,
    }
    with open(APPROVAL_MANIFEST, 'w', encoding='utf-8') as stream:
        json.dump(manifest, stream, ensure_ascii=False, indent=2, sort_keys=True)
        stream.write('\n')
    approval_sha256 = _sha256(APPROVAL_MANIFEST)
    print(f'\nJin 게이트: {SAMPLE_OUT_DIR} 의 before/after 를 시각 승인한 뒤에만'
          f' --apply --jin-approved --approval-sha256 {approval_sha256} 로 '
          f'번들 일괄 처리.')


def _validate_approval(approval_sha256: str) -> bool:
    if not os.path.isfile(APPROVAL_MANIFEST):
        print('⛔ approval manifest missing; run --samples again.', file=sys.stderr)
        return False
    actual = _sha256(APPROVAL_MANIFEST)
    if approval_sha256 != actual:
        print(
            f'⛔ approval artifact mismatch: expected current manifest {actual}.',
            file=sys.stderr,
        )
        return False
    try:
        with open(APPROVAL_MANIFEST, encoding='utf-8') as stream:
            manifest = json.load(stream)
    except (OSError, ValueError) as error:
        print(f'⛔ invalid approval manifest: {error}', file=sys.stderr)
        return False
    if (manifest.get('pipeline_parameters') != _pipeline_parameters() or
            manifest.get('target_preimage_sha256') != TARGET_PREIMAGE_SHA256):
        print('⛔ pipeline changed after sample review; run --samples again.',
              file=sys.stderr)
        return False
    records = manifest.get('samples')
    if not isinstance(records, list) or {
            record.get('source') for record in records if isinstance(record, dict)
    } != set(SAMPLES):
        print('⛔ sample manifest is incomplete; run --samples again.', file=sys.stderr)
        return False
    for record in records:
        if not isinstance(record, dict):
            return False
        for path_key, hash_key in (
            ('source', 'source_sha256'),
            ('before', 'before_sha256'),
            ('after', 'after_sha256'),
        ):
            path = record.get(path_key)
            digest = record.get(hash_key)
            if (not isinstance(path, str) or not os.path.isfile(path) or
                    not isinstance(digest, str) or _sha256(path) != digest):
                print(
                    f'⛔ reviewed sample changed: {path}; run --samples again.',
                    file=sys.stderr,
                )
                return False
    return True


def _discover_batch_targets() -> set[str]:
    targets: set[str] = set()
    for directory in (
        'assets/illustrations/activities',
        'assets/illustrations/packs',
    ):
        targets.update(
            os.path.join(directory, name)
            for name in os.listdir(directory)
            if name.endswith('.webp')
        )
    return targets


def run_apply(approval_sha256: str) -> int:
    if not _validate_approval(approval_sha256):
        return 2
    expected = set(TARGET_PREIMAGE_SHA256)
    discovered = _discover_batch_targets()
    if discovered != expected:
        missing = sorted(expected - discovered)
        unexpected = sorted(discovered - expected)
        print(
            '⛔ exact manifest drift; bundle untouched. '
            f'missing={missing}, unexpected={unexpected}',
            file=sys.stderr,
        )
        return 3
    preimage_drift = [
        path for path, digest in TARGET_PREIMAGE_SHA256.items()
        if _sha256(path) != digest
    ]
    if preimage_drift:
        print(
            '⛔ preimage drift or pipeline already applied; bundle untouched:',
            file=sys.stderr,
        )
        for path in preimage_drift:
            print(f'  {path}', file=sys.stderr)
        return 3
    targets = sorted(expected)

    # Render the complete batch outside the asset directories first. Size is
    # a release contract, not a warning: if even one q88 result exceeds 70KB,
    # no production source is overwritten.
    with tempfile.TemporaryDirectory(prefix='.riso-v2-', dir='.') as temp_dir:
        rendered: list[tuple[str, str, int]] = []
        oversized: list[tuple[str, int]] = []
        for index, src in enumerate(targets):
            out = os.path.join(temp_dir, f'{index:02d}.webp')
            riso(src, out)
            size = os.path.getsize(out)
            rendered.append((src, out, size))
            if size > MAX_WEBP_BYTES:
                oversized.append((src, size))

        if oversized:
            print(
                '⛔ q88 size gate failed; bundle untouched:',
                file=sys.stderr,
            )
            for src, size in oversized:
                print(f'  {src}: {size / 1024:.0f}KB > 70KB', file=sys.stderr)
            return 3

        for src, out, size in rendered:
            os.replace(out, src)
            print(f'{src} ({size / 1024:.0f}KB)')
    print(f'\n{len(targets)}장 처리 완료 — asset-integrity/매트 가드 테스트를 재실행할 것.')
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--samples', action='store_true',
                        help='Jin 게이트용 샘플 2장 (번들 무접촉)')
    parser.add_argument('--apply', action='store_true',
                        help='번들 38장 일괄 덮어쓰기 (게이트 필요)')
    parser.add_argument('--jin-approved', action='store_true',
                        help='샘플 승인 완료 확인 — --apply 의 필수 게이트')
    parser.add_argument('--approval-sha256',
                        help='승인한 approval_manifest.json 의 SHA-256')
    args = parser.parse_args()
    if args.apply:
        if not args.jin_approved or not args.approval_sha256:
            print('⛔ 게이트: --apply 는 --jin-approved 와 승인한 '
                  '--approval-sha256 를 함께 요구한다 '
                  '(§J-1 — 미승인 파라미터로 전량 처리 금지).', file=sys.stderr)
            return 2
        return run_apply(args.approval_sha256)
    run_samples()
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
