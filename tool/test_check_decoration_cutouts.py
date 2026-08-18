"""Gate tests for tool/check_decoration_cutouts.py.

The first test is the important one: the six 사랑방 cutouts Jin already approved
must pass every gate. A gate that rejects shipped, approved art is measuring the
wrong thing — that is exactly how the first version of this file was caught
(plain saturation flagged the set's own walnut browns at 46 %).
"""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

import check_decoration_cutouts as gate

ROOT = Path(__file__).resolve().parents[1]
SHIPPED_INTERIOR = (
    "decoration_seoan.png",
    "decoration_soban.png",
    "decoration_munbangsau.png",
    "decoration_jagae_mungap.png",
    "decoration_chaekgado.png",
    "decoration_gat_buchae.png",
)


def cutout(
    size: tuple[int, int] = (400, 400),
    color: tuple[int, int, int] = (140, 90, 50),
    pad: int = 20,
) -> Image.Image:
    canvas = np.zeros((size[1], size[0], 4), dtype=np.uint8)
    canvas[pad : size[1] - pad, pad : size[0] - pad, :3] = color
    canvas[pad : size[1] - pad, pad : size[0] - pad, 3] = 255
    return Image.fromarray(canvas, mode="RGBA")


class ShippedBaselineTest(unittest.TestCase):
    def test_every_approved_interior_cutout_passes(self) -> None:
        for name in SHIPPED_INTERIOR:
            with self.subTest(name=name):
                result = gate.check(ROOT / "assets" / "illustrations" / "decorations" / name)
                self.assertTrue(
                    result["ok"],
                    f"{name} fails an approved-art gate: {result['failures']}",
                )


class SyntheticGateTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.tmp = Path(self._tmp.name)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def write(self, image: Image.Image, name: str = "decoration_test.png") -> Path:
        path = self.tmp / name
        image.save(path)
        return path

    def test_clean_cutout_passes(self) -> None:
        result = gate.check(self.write(cutout()))
        self.assertTrue(result["ok"], result["failures"])

    def test_palette_with_transparency_passes(self) -> None:
        """pngquant output is P+tRNS and must pass — it still carries true alpha.

        Ten of the 24 shipped decorations are already palette PNGs, and
        quantizing the A2 set cut it from 11.7 MB to 4.5 MB with a mean RGB
        delta near 1.5, so the gate checks for alpha, not for a storage mode.
        """
        source = cutout()
        palette = source.convert("P", palette=Image.ADAPTIVE, colors=255)
        palette.info["transparency"] = 255
        alpha = source.split()[3].point(lambda v: 255 if v == 0 else 0)
        palette.paste(255, mask=alpha)
        path = self.write(palette, "decoration_palette.png")
        result = gate.check(path)
        self.assertTrue(result["ok"], result["failures"])
        self.assertEqual(result["mode"], "P")

    def test_opaque_rgb_without_alpha_fails(self) -> None:
        path = self.write(cutout().convert("RGB"), "decoration_rgb.png")
        result = gate.check(path)
        self.assertFalse(result["ok"])
        self.assertTrue(any("true alpha" in f for f in result["failures"]))

    def test_leftover_chroma_fails(self) -> None:
        image = cutout()
        pixels = np.array(image)
        pixels[100:140, 100:140, :3] = (0, 255, 0)
        result = gate.check(self.write(Image.fromarray(pixels, "RGBA"), "decoration_chroma.png"))
        self.assertFalse(result["ok"])
        self.assertTrue(any("#00FF00" in f for f in result["failures"]))

    def test_opaque_edge_fails(self) -> None:
        result = gate.check(self.write(cutout(pad=0), "decoration_noedge.png"))
        self.assertFalse(result["ok"])
        self.assertTrue(any("outer row/column" in f for f in result["failures"]))

    def test_bright_saturated_flood_fails(self) -> None:
        result = gate.check(
            self.write(cutout(color=(20, 240, 190)), "decoration_neon.png")
        )
        self.assertFalse(result["ok"])
        self.assertTrue(any("saturated AND bright" in f for f in result["failures"]))

    def test_tiny_object_fails_coverage(self) -> None:
        canvas = np.zeros((400, 400, 4), dtype=np.uint8)
        canvas[10:20, 10:20, :3] = (140, 90, 50)
        canvas[10:20, 10:20, 3] = 255
        result = gate.check(
            self.write(Image.fromarray(canvas, "RGBA"), "decoration_tiny.png")
        )
        self.assertFalse(result["ok"])
        self.assertTrue(any("coverage" in f or "visible pixels" in f for f in result["failures"]))


if __name__ == "__main__":
    unittest.main()
