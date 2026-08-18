"""Gate tests for tool/cut_single_object.py."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

TOOL = Path(__file__).resolve().parent / "cut_single_object.py"


def green_canvas(width: int = 400, height: int = 400) -> np.ndarray:
    canvas = np.zeros((height, width, 3), dtype=np.uint8)
    canvas[:, :, 1] = 255
    return canvas


def put_block(canvas: np.ndarray, box: tuple[int, int, int, int], color) -> None:
    left, top, right, bottom = box
    canvas[top:bottom, left:right] = color


def run(source: Path, out: Path, *extra: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(TOOL), str(source), str(out), *extra],
        capture_output=True,
        text=True,
    )


class CutSingleObjectTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.tmp = Path(self._tmp.name)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_single_object_is_cut_and_trimmed(self) -> None:
        canvas = green_canvas()
        put_block(canvas, (100, 120, 260, 300), (140, 90, 50))
        source = self.tmp / "raw.png"
        Image.fromarray(canvas).save(source)

        out = self.tmp / "cut.png"
        report = self.tmp / "cut.json"
        result = run(source, out, "--min-area", "500", "--report", str(report))
        self.assertEqual(result.returncode, 0, result.stderr)

        with Image.open(out) as im:
            self.assertEqual(im.mode, "RGBA")
            self.assertEqual(im.size, (160, 180))
            alpha = np.array(im)[:, :, 3]
        self.assertTrue((alpha == 255).all())

        payload = json.loads(report.read_text(encoding="utf-8"))
        self.assertEqual(payload["parts"], 1)
        self.assertEqual(payload["outSize"], [160, 180])

    def test_output_is_deterministic(self) -> None:
        canvas = green_canvas()
        put_block(canvas, (50, 60, 210, 240), (90, 70, 40))
        source = self.tmp / "raw.png"
        Image.fromarray(canvas).save(source)

        first = self.tmp / "a.png"
        second = self.tmp / "b.png"
        self.assertEqual(run(source, first, "--min-area", "500").returncode, 0)
        self.assertEqual(run(source, second, "--min-area", "500").returncode, 0)
        self.assertEqual(first.read_bytes(), second.read_bytes())

    def test_non_chroma_background_is_rejected(self) -> None:
        canvas = np.full((300, 300, 3), 250, dtype=np.uint8)  # white canvas
        put_block(canvas, (80, 80, 200, 200), (120, 80, 40))
        source = self.tmp / "raw.png"
        Image.fromarray(canvas).save(source)

        result = run(source, self.tmp / "cut.png", "--min-area", "500")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not flat #00FF00", result.stderr)

    def test_extra_part_is_rejected(self) -> None:
        canvas = green_canvas()
        put_block(canvas, (40, 40, 140, 140), (130, 90, 50))
        put_block(canvas, (240, 240, 340, 340), (130, 90, 50))
        source = self.tmp / "raw.png"
        Image.fromarray(canvas).save(source)

        result = run(source, self.tmp / "cut.png", "--min-area", "500", "--expect-parts", "1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("found 2 parts", result.stderr)

    def test_declared_multi_part_object_passes(self) -> None:
        canvas = green_canvas()
        put_block(canvas, (40, 40, 140, 140), (130, 90, 50))
        put_block(canvas, (200, 60, 300, 160), (130, 90, 50))
        source = self.tmp / "raw.png"
        Image.fromarray(canvas).save(source)

        out = self.tmp / "cut.png"
        result = run(source, out, "--min-area", "500", "--expect-parts", "2")
        self.assertEqual(result.returncode, 0, result.stderr)
        with Image.open(out) as im:
            self.assertEqual(im.size, (260, 120))

    def test_empty_frame_is_rejected(self) -> None:
        source = self.tmp / "raw.png"
        Image.fromarray(green_canvas()).save(source)
        result = run(source, self.tmp / "cut.png", "--min-area", "500")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("empty green", result.stderr)


if __name__ == "__main__":
    unittest.main()
