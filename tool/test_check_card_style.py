"""Calibration-discipline tests for tool/check_card_style.py (F-E-cards).

tool/test_check_style_conformance.py 와 같은 규율을 카드 가족에 적용한다:

  1. SweepTest first — 사이드카(docs/assets/CARD_STYLE_BASELINE.json)에
     등록된 전 멤버가 sha256 대조까지 포함해 통과해야 한다. 승인 아트를
     거부하는 게이트는 잘못된 것을 재고 있는 것이다.
  2. 합성 음성(negative) 테스트 — 한 번도 실패하지 않는 게이트는 게이트가
     아니다: 민무늬 회색판·그레인 제거본·채도 드리프트본이 전부 거부되는지.
  3. 미등록 반입 — 가족 디렉터리에 명부 밖 *.webp 를 놓으면 --all 이
     실패해야 한다(그게 이 잠금의 존재 이유다).
"""

from __future__ import annotations

import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_card_style as gate  # noqa: E402
import style_lock  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]


def _rgb_to_hsv(rgb: np.ndarray) -> np.ndarray:
    """Vectorized RGB[0..1] -> HSV[0..1], same convention as colorsys."""
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    maxc = rgb.max(axis=-1)
    minc = rgb.min(axis=-1)
    v = maxc
    delta = maxc - minc
    s = np.where(maxc > 0, delta / np.where(maxc > 0, maxc, 1), 0.0)
    rc = np.where(delta > 0, (maxc - r) / np.where(delta > 0, delta, 1), 0.0)
    gc = np.where(delta > 0, (maxc - g) / np.where(delta > 0, delta, 1), 0.0)
    bc = np.where(delta > 0, (maxc - b) / np.where(delta > 0, delta, 1), 0.0)
    h = np.select(
        [r == maxc, g == maxc, b == maxc],
        [bc - gc, 2.0 + rc - bc, 4.0 + gc - rc],
        default=0.0,
    )
    h = (h / 6.0) % 1.0
    h = np.where(delta == 0, 0.0, h)
    return np.stack([h, s, v], axis=-1)


def _hsv_to_rgb(hsv: np.ndarray) -> np.ndarray:
    """Vectorized HSV[0..1] -> RGB[0..1], same convention as colorsys."""
    h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
    i = np.floor(h * 6.0).astype(np.int64) % 6
    f = (h * 6.0) - np.floor(h * 6.0)
    p = v * (1.0 - s)
    q = v * (1.0 - s * f)
    t = v * (1.0 - s * (1.0 - f))
    r = np.select([i == 0, i == 1, i == 2, i == 3, i == 4, i == 5], [v, q, p, p, t, v])
    g = np.select([i == 0, i == 1, i == 2, i == 3, i == 4, i == 5], [t, v, v, q, p, p])
    b = np.select([i == 0, i == 1, i == 2, i == 3, i == 4, i == 5], [p, p, t, v, v, q])
    return np.stack([r, g, b], axis=-1)


class SweepTest(unittest.TestCase):
    """Rule 1: 등록된 전 멤버 + sha256 + 미등록 반입 없음 = 0 실패."""

    def test_all_registered_members_pass_with_sha256(self) -> None:
        lock = style_lock.load_style_lock()
        results, failures = gate.run_all(lock)
        failing = [(r["path"], r["failures"]) for r in results if not r.get("ok")]
        self.assertEqual(failures, 0, f"approved canon fails the gate: {failing}")
        self.assertGreater(
            len(results), 80, "the sweep found suspiciously few registered files"
        )


class NegativeGateTest(unittest.TestCase):
    """Rule 2: 한 번도 실패하지 않는 게이트는 게이트가 아니다."""

    def setUp(self) -> None:
        self.lock = style_lock.load_style_lock()
        self.tmpdir = Path(tempfile.mkdtemp(prefix="card_style_test_"))

    def tearDown(self) -> None:
        shutil.rmtree(self.tmpdir, ignore_errors=True)

    def test_solid_gray_synthetic_is_rejected(self) -> None:
        path = self.tmpdir / "solid_gray.webp"
        Image.new("RGB", (800, 600), (200, 200, 200)).save(
            path, "WEBP", quality=84, method=6
        )
        result = gate.check(path, self.lock)
        self.assertFalse(result["ok"], "an 800x600 solid #C8C8C8 must be rejected")

    def test_degrained_canon_is_rejected(self) -> None:
        # 그레인 파이프라인을 건너뛴 파일의 합성 재현: 정본을 GaussianBlur(1.5)
        # 로 뭉개고 q84 재인코딩 — fine grain SD 가 대역 밑으로 떨어져야 한다.
        path = self.tmpdir / "degrained_bamboo.webp"
        with Image.open(ROOT / "assets/illustrations/packs/bamboo.webp") as im:
            im.convert("RGB").filter(ImageFilter.GaussianBlur(1.5)).save(
                path, "WEBP", quality=84, method=6
            )
        result = gate.check(path, self.lock)
        self.assertFalse(result["ok"], "a de-grained canon copy must be rejected")
        self.assertTrue(
            any("fine grain" in f for f in result["failures"]),
            f"expected a fine-grain failure, got: {result['failures']}",
        )

    def test_saturation_drifted_canon_is_rejected(self) -> None:
        path = self.tmpdir / "satdrift_plum.webp"
        with Image.open(ROOT / "assets/illustrations/packs/plum.webp") as im:
            arr = np.asarray(im.convert("RGB")).astype(np.float64) / 255.0
        hsv = _rgb_to_hsv(arr)
        hsv[..., 1] = np.minimum(1.0, hsv[..., 1] * 1.6)
        out = np.clip(_hsv_to_rgb(hsv) * 255, 0, 255).astype(np.uint8)
        Image.fromarray(out).save(path, "WEBP", quality=84, method=6)
        result = gate.check(path, self.lock)
        self.assertFalse(
            result["ok"],
            "a 1.6x-saturation drifted copy of a shipped card must be rejected "
            "-- if it passes, the gate has no teeth",
        )


class UnregisteredImportTest(unittest.TestCase):
    """Rule 3: 명부 밖 파일이 가족 디렉터리에 들어오면 --all 이 실패한다."""

    def test_unregistered_webp_in_family_dir_fails_the_sweep(self) -> None:
        lock = style_lock.load_style_lock()
        listening = ROOT / "assets/illustrations/listening"
        # 유일한 이름으로 정본을 복제해 '미등록 반입'을 재현한다.
        intruder = listening / f"zz_unregistered_test_{os.getpid()}.webp"
        self.assertFalse(intruder.exists())
        shutil.copyfile(listening / "A1Arrival.webp", intruder)
        try:
            results, failures = gate.run_all(lock)
            self.assertGreater(failures, 0, "an unregistered import must fail --all")
            intruder_rel = intruder.relative_to(ROOT).as_posix()
            hits = [r for r in results if r["path"] == intruder_rel]
            self.assertEqual(len(hits), 1)
            self.assertTrue(
                any("미등록 반입" in f for f in hits[0]["failures"]),
                hits[0]["failures"],
            )
        finally:
            intruder.unlink(missing_ok=True)


if __name__ == "__main__":
    unittest.main()
