from __future__ import annotations

import hashlib
import io
import json
import unittest

from PIL import Image, ImageChops

from tool.promote_ildu_anchae_turntable import (
    METRICS_PATH,
    RUNTIME_ROOT,
    RUNTIME_SIZE,
    SHEET_PATH,
    SHEET_SIZE,
    TRANSPARENT_ROOT,
    build_bundle,
)


class PromoteIlDuAnchaeTurntableTest(unittest.TestCase):
    def assert_png_pixels_equal(self, committed_path, generated_bytes: bytes) -> None:
        with (
            Image.open(committed_path) as committed,
            Image.open(io.BytesIO(generated_bytes)) as generated,
        ):
            self.assertEqual(committed.format, "PNG")
            self.assertEqual(generated.format, "PNG")
            self.assertEqual(committed.mode, generated.mode)
            self.assertEqual(committed.size, generated.size)
            self.assertIsNone(ImageChops.difference(committed, generated).getbbox())

    @staticmethod
    def without_encoded_png_hashes(metrics: dict[str, object]) -> dict[str, object]:
        normalized = json.loads(json.dumps(metrics))
        normalized["sheet"].pop("sha256")
        for frame in normalized["frames"]:
            frame.pop("transparent_sha256")
        for frame in normalized["runtime_frames"]:
            frame.pop("sha256")
        return normalized

    def assert_file_sha256(self, path, expected: str) -> None:
        actual = hashlib.sha256(path.read_bytes()).hexdigest().upper()
        self.assertEqual(actual, expected)

    def test_committed_outputs_match_deterministic_build(self) -> None:
        bundle = build_bundle()
        committed_metrics = json.loads(METRICS_PATH.read_text(encoding="utf-8"))

        self.assertEqual(len(bundle.transparent_frames), 8)
        self.assertEqual(len(bundle.runtime_frames), 8)
        self.assertEqual(
            len({frame.sha256 for frame in bundle.transparent_frames}),
            8,
        )
        self.assertEqual(len({frame.sha256 for frame in bundle.runtime_frames}), 8)
        for frame in bundle.transparent_frames:
            self.assert_png_pixels_equal(
                TRANSPARENT_ROOT / frame.output_name,
                frame.png_bytes,
            )
        for frame in bundle.runtime_frames:
            self.assert_png_pixels_equal(
                RUNTIME_ROOT / frame.output_name,
                frame.png_bytes,
            )
        self.assert_png_pixels_equal(SHEET_PATH, bundle.sheet_bytes)
        self.assertEqual(
            self.without_encoded_png_hashes(committed_metrics),
            self.without_encoded_png_hashes(bundle.metrics),
        )
        self.assert_file_sha256(SHEET_PATH, committed_metrics["sheet"]["sha256"])
        for frame in committed_metrics["frames"]:
            self.assert_file_sha256(
                METRICS_PATH.parent / frame["transparent_file"],
                frame["transparent_sha256"],
            )
        for frame in committed_metrics["runtime_frames"]:
            self.assert_file_sha256(
                RUNTIME_ROOT / frame["file"],
                frame["sha256"],
            )

    def test_all_frames_have_real_alpha_safe_margins_and_no_matte_fringe(self) -> None:
        bundle = build_bundle()

        for frame, metrics in zip(
            bundle.transparent_frames,
            bundle.metrics["frames"],
            strict=True,
        ):
            with Image.open(io.BytesIO(frame.png_bytes)) as image:
                self.assertEqual(image.format, "PNG")
                self.assertEqual(image.mode, "RGBA")
                self.assertEqual(image.getchannel("A").getextrema(), (0, 255))
                for corner in (
                    (0, 0),
                    (image.width - 1, 0),
                    (0, image.height - 1),
                    (image.width - 1, image.height - 1),
                ):
                    self.assertEqual(image.getpixel(corner)[3], 0)
            self.assertGreater(metrics["transparent_pixels"], 0)
            self.assertGreater(metrics["partial_alpha_pixels"], 0)
            self.assertGreater(metrics["opaque_pixels"], 0)
            self.assertGreaterEqual(metrics["dominant_ratio"], 0.999)
            self.assertEqual(metrics["max_fringe_core_rgb_delta"], 0)

        for frame in bundle.runtime_frames:
            with Image.open(io.BytesIO(frame.png_bytes)) as image:
                self.assertEqual(image.format, "PNG")
                self.assertEqual(image.mode, "RGBA")
                self.assertEqual(image.size, RUNTIME_SIZE)
                self.assertEqual(image.getchannel("A").getextrema(), (0, 255))
                self.assertEqual(image.getchannel("A").getbbox(), frame.content_bounds)
                for corner in (
                    (0, 0),
                    (RUNTIME_SIZE[0] - 1, 0),
                    (0, RUNTIME_SIZE[1] - 1),
                    (RUNTIME_SIZE[0] - 1, RUNTIME_SIZE[1] - 1),
                ):
                    self.assertEqual(image.getpixel(corner)[3], 0)

        with Image.open(io.BytesIO(bundle.sheet_bytes)) as sheet:
            self.assertEqual(sheet.mode, "RGBA")
            self.assertEqual(sheet.size, SHEET_SIZE)
            self.assertEqual(sheet.getchannel("A").getextrema(), (0, 255))


if __name__ == "__main__":
    unittest.main()
