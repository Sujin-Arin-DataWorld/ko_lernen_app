"""Calibration-discipline tests for tool/check_style_conformance.py.

Phase 2-2 of the "살아 있는 한옥" plan requires this discipline, enforced as
tests rather than left as a docstring promise:

  1. ShippedBaselineTest first — every currently-shipped family member must
     pass. A gate that rejects approved art is measuring the wrong thing
     (exactly how the first version of check_decoration_cutouts.py's plain
     saturation check was caught: it flagged the set's own walnut browns).
  2. A synthetic-drift test proves the gate can actually reject something:
     take a shipped file, multiply saturation by 1.6 and value by 1.4, and
     confirm it's rejected. A gate that only ever passes isn't a gate.
"""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_style_conformance as gate  # noqa: E402
import style_lock  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]


def _closed_temp_png_path() -> Path:
    """Reserve a temp PNG path without leaking an open Windows file handle."""
    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as handle:
        return Path(handle.name)


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
    r = np.select(
        [i == 0, i == 1, i == 2, i == 3, i == 4, i == 5],
        [v, q, p, p, t, v],
    )
    g = np.select(
        [i == 0, i == 1, i == 2, i == 3, i == 4, i == 5],
        [t, v, v, q, p, p],
    )
    b = np.select(
        [i == 0, i == 1, i == 2, i == 3, i == 4, i == 5],
        [p, p, t, v, v, q],
    )
    return np.stack([r, g, b], axis=-1)


def _drift_saturation_value(path: Path, sat_mult: float, val_mult: float) -> Path:
    """Write a copy of `path` with every visible pixel's HSV S and V scaled."""
    with Image.open(path) as im:
        rgba = np.array(im.convert("RGBA"))
    rgb = rgba[:, :, :3].astype(np.float64) / 255.0
    alpha = rgba[:, :, 3]
    hsv = _rgb_to_hsv(rgb)
    hsv[..., 1] = np.minimum(1.0, hsv[..., 1] * sat_mult)
    hsv[..., 2] = np.minimum(1.0, hsv[..., 2] * val_mult)
    out = _hsv_to_rgb(hsv)
    out_u8 = np.clip(out * 255, 0, 255).astype(np.uint8)
    drifted = np.dstack([out_u8, alpha])
    tmp = _closed_temp_png_path()
    Image.fromarray(drifted, mode="RGBA").save(tmp)
    return tmp


class ShippedBaselineTest(unittest.TestCase):
    """Rule 1: every shipped family member passes the gate it's measured under."""

    def test_every_family_member_passes(self) -> None:
        lock = style_lock.load_style_lock()
        checked = 0
        for family_name, family in lock["families"].items():
            for member in family["members"]:
                path = None
                for directory in family["dirs"]:
                    for ext in (".png", ".webp"):
                        candidate = ROOT / directory / f"{member}{ext}"
                        if candidate.exists():
                            path = candidate
                            break
                    if path:
                        break
                if path is None:
                    continue  # not yet promoted (e.g. Phase 3 unbuilt members)
                with self.subTest(family=family_name, member=member):
                    result = gate.check(path, lock, family_name)
                    self.assertTrue(
                        result["ok"],
                        f"{path} fails an approved-art gate: {result['failures']}",
                    )
                    checked += 1
        self.assertGreater(checked, 40, "the baseline scan found suspiciously few files")


class SyntheticDriftTest(unittest.TestCase):
    """Rule 2: a gate that never fails anything isn't a gate."""

    def test_saturation_and_value_drift_is_rejected(self) -> None:
        lock = style_lock.load_style_lock()
        anchor = ROOT / "assets/illustrations/decorations/decoration_geomungo.png"
        self.assertTrue(anchor.exists())
        drifted = _drift_saturation_value(anchor, sat_mult=1.6, val_mult=1.4)
        try:
            result = gate.check(drifted, lock, "F-A")
            self.assertFalse(
                result["ok"],
                "a 1.6x-saturation/1.4x-value drifted copy of a shipped F-A "
                "file must be rejected -- if it passes, the gate has no teeth",
            )
        finally:
            drifted.unlink()

    def test_estate_family_drift_is_also_rejected(self) -> None:
        lock = style_lock.load_style_lock()
        # rear_garden sits near the top of F-C-estate's satMean range
        # (measured 0.525 of [0.24, 0.65]) -- a low-baseline file like sadang
        # (0.264) can absorb a 1.6x/1.4x drift and stay in-range, which would
        # make this test flaky by anchor choice rather than prove anything.
        anchor = ROOT / "assets/illustrations/personal_hanok_v2/map/landscape/rear_garden.png"
        self.assertTrue(anchor.exists())
        drifted = _drift_saturation_value(anchor, sat_mult=1.6, val_mult=1.4)
        try:
            result = gate.check(drifted, lock, "F-C-estate")
            self.assertFalse(result["ok"], result["failures"])
        finally:
            drifted.unlink()


class PaletteDistanceIsWarningOnlyTest(unittest.TestCase):
    """Rule 4: paletteDistance has no shipped precedent yet, so it must never
    fail a file on its own -- only satMean/valMean/neonFraction/chromaResidue
    /greenRimFraction (where gated) may."""

    def test_a_wildly_off_palette_still_only_warns(self) -> None:
        lock = style_lock.load_style_lock()
        anchor = ROOT / "assets/illustrations/decorations/decoration_geomungo.png"
        # Hue-rotate toward a palette far from F-A's walnut/lacquer anchors,
        # but keep sat/val inside the family's gate range so only
        # paletteDistance could plausibly object.
        with Image.open(anchor) as im:
            rgba = np.array(im.convert("RGBA"))
        rgb = rgba[:, :, :3].astype(np.float64) / 255.0
        alpha = rgba[:, :, 3]
        hsv = _rgb_to_hsv(rgb)
        hsv[..., 0] = (hsv[..., 0] + 0.5) % 1.0  # opposite hue
        out = _hsv_to_rgb(hsv)
        out_u8 = np.clip(out * 255, 0, 255).astype(np.uint8)
        tmp = _closed_temp_png_path()
        Image.fromarray(np.dstack([out_u8, alpha]), mode="RGBA").save(tmp)
        try:
            result = gate.check(tmp, lock, "F-A")
            palette_failures = [
                f for f in result["failures"] if "paletteDistance" in f or "palette" in f
            ]
            self.assertEqual(
                palette_failures,
                [],
                "paletteDistance must never itself appear in failures (warning-only, rule 4)",
            )
        finally:
            tmp.unlink()


if __name__ == "__main__":
    unittest.main()
