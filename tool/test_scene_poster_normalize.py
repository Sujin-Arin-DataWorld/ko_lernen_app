"""Tests for deterministic dedicated scene-poster normalization."""

from __future__ import annotations

import hashlib
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image, UnidentifiedImageError

sys.path.insert(0, str(Path(__file__).resolve().parent))

import scene_poster_normalize  # noqa: E402
import style_lock  # noqa: E402


class ScenePosterNormalizeTest(unittest.TestCase):
    def test_target_contract_matches_scene_style_lock_ssot(self) -> None:
        family = style_lock.load_style_lock()["families"]["F-E-scene-poster"]
        output = family["canonicalOutput"]
        self.assertEqual(
            scene_poster_normalize.TARGET_SIZE,
            (output["width"], output["height"]),
        )
        self.assertEqual(output["aspectRatio"], "3:2")
        self.assertEqual(output["format"], "PNG")
        self.assertEqual(output["modes"], ["RGB", "RGBA"])
        self.assertEqual(output["generatorFallbackAspectRatio"], "4:3")

    def _image(
        self,
        path: Path,
        *,
        size: tuple[int, int],
        mode: str = "RGB",
        color: object | None = None,
    ) -> None:
        if color is None:
            color = (25, 75, 125, 180) if mode == "RGBA" else (25, 75, 125)
        Image.new(mode, size, color).save(path, format="PNG")

    def _normalize(
        self,
        source: Path,
        output_dir: Path,
        *,
        scenario_id: str = "canonical_scene",
        focal_x: float = 0.5,
        focal_y: float = 0.5,
    ):
        return scene_poster_normalize.normalize_scene_poster(
            source,
            output_dir,
            scenario_id,
            canonical_ids={"canonical_scene", "other_scene"},
            focal_x=focal_x,
            focal_y=focal_y,
        )

    def test_landscape_source_becomes_exact_rgb_target(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "landscape.png"
            self._image(source, size=(2400, 1000))

            result = self._normalize(source, root / "out")

            self.assertEqual(result.source_size, (2400, 1000))
            self.assertEqual(result.output_size, (1536, 1024))
            with Image.open(result.output_path) as output:
                output.load()
                self.assertEqual(output.size, (1536, 1024))
                self.assertEqual(output.mode, "RGB")
                self.assertEqual(output.format, "PNG")

    def test_portrait_source_uses_controlled_cover_crop(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "portrait.png"
            self._image(source, size=(1000, 2200))

            result = self._normalize(
                source,
                root / "out",
                focal_y=0.8,
            )

            self.assertEqual(result.crop_box, (0, 1426, 1000, 2093))
            self.assertEqual(result.output_size, (1536, 1024))

    def test_alpha_source_preserves_alpha_channel(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "alpha.png"
            self._image(source, size=(1600, 1200), mode="RGBA")

            result = self._normalize(source, root / "out")

            with Image.open(result.output_path) as output:
                output.load()
                self.assertEqual(output.mode, "RGBA")
                self.assertEqual(output.getchannel("A").getextrema(), (180, 180))

    def test_odd_dimensions_and_focal_point_produce_integer_bounded_crop(self) -> None:
        box = scene_poster_normalize.cover_crop_box(
            (1001, 777),
            focal_x=0.9,
            focal_y=0.1,
        )

        left, top, right, bottom = box
        self.assertEqual(box, (0, 0, 1001, 667))
        self.assertTrue(all(isinstance(value, int) for value in box))
        self.assertGreaterEqual(left, 0)
        self.assertGreaterEqual(top, 0)
        self.assertLessEqual(right, 1001)
        self.assertLessEqual(bottom, 777)

    def test_corrupt_input_fails_without_creating_output(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "corrupt.png"
            source.write_bytes(b"not an image")
            output_dir = root / "out"

            with self.assertRaises(UnidentifiedImageError):
                self._normalize(source, output_dir)

            self.assertFalse((output_dir / "canonical_scene.png").exists())

    def test_existing_output_is_never_overwritten(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "source.png"
            self._image(source, size=(1600, 1000))
            output_dir = root / "out"
            output_dir.mkdir()
            output = output_dir / "canonical_scene.png"
            output.write_bytes(b"keep me")

            with self.assertRaises(FileExistsError):
                self._normalize(source, output_dir)

            self.assertEqual(output.read_bytes(), b"keep me")

    def test_same_input_produces_same_png_hash(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "source.png"
            self._image(source, size=(1777, 1333), mode="RGBA")

            first = self._normalize(source, root / "out-a")
            second = self._normalize(source, root / "out-b")

            first_bytes = first.output_path.read_bytes()
            second_bytes = second.output_path.read_bytes()
            self.assertEqual(first_bytes, second_bytes)
            self.assertEqual(first.sha256, second.sha256)
            self.assertEqual(
                first.sha256,
                hashlib.sha256(first_bytes).hexdigest(),
            )

    def test_noncanonical_id_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "source.png"
            self._image(source, size=(1600, 1000))

            with self.assertRaisesRegex(ValueError, "canonical"):
                scene_poster_normalize.normalize_scene_poster(
                    source,
                    root / "out",
                    "invented_scene",
                    canonical_ids={"canonical_scene"},
                )

    def test_in_place_output_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "canonical_scene.png"
            self._image(source, size=(1600, 1000))

            with self.assertRaisesRegex(ValueError, "in-place"):
                self._normalize(source, root)

    def test_real_inventory_contains_exact_canonical_ids(self) -> None:
        canonical = scene_poster_normalize.load_canonical_ids(
            scene_poster_normalize.DEFAULT_INVENTORY_PATH
        )
        self.assertEqual(len(canonical), 419)
        self.assertIn("airport_arrival", canonical)


if __name__ == "__main__":
    unittest.main()
