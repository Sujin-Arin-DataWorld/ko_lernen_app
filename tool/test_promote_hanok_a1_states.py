from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

from derive_hanok_a1_thumbnails import ThumbnailError, derive_thumbnail
from hanok_v1_asset_contract import a1_expected_files, sha256_file
from promote_hanok_a1_states import (
    PromotionError,
    _validate_state,
    collect_approved_states,
    promote_states,
)


class PromoteAndThumbnailTest(unittest.TestCase):
    def test_promotion_stays_fail_closed_until_all_sixteen_exist(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            Image.new("RGB", (1536, 1152), (10, 10, 10)).save(
                root / "06_columns.webp",
                "WEBP",
                quality=82,
            )
            with self.assertRaises(PromotionError):
                collect_approved_states(qa_root=root)

    def test_promotion_copies_only_a_complete_valid_set(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            qa = Path(temp_dir) / "qa"
            runtime = Path(temp_dir) / "runtime"
            qa.mkdir()
            for name in a1_expected_files():
                Image.new("RGB", (1536, 1152), (12, 24, 36)).save(
                    qa / name,
                    "WEBP",
                    quality=80,
                    method=6,
                )
            names = promote_states(qa_root=qa, runtime_root=runtime, dry_run=True)
            self.assertEqual(names, a1_expected_files())
            self.assertFalse(runtime.exists())
            copied = promote_states(qa_root=qa, runtime_root=runtime, dry_run=False)
            self.assertEqual(len(copied), 16)
            self.assertTrue((runtime / "16_landscape_move_in.webp").is_file())

    def test_promotion_rejects_rgba_or_chroma_webp(self) -> None:
        geometry = {"canvas_width": 1536, "canvas_height": 1152}
        with tempfile.TemporaryDirectory() as temp_dir:
            chroma = Path(temp_dir) / "chroma.webp"
            Image.new("RGB", (1536, 1152), (0, 255, 0)).save(
                chroma,
                "WEBP",
                lossless=True,
            )
            with self.assertRaises(PromotionError):
                _validate_state(chroma, geometry, 350000)

            rgba = Path(temp_dir) / "rgba.webp"
            layer = Image.new("RGBA", (1536, 1152), (12, 24, 36, 255))
            layer.putpixel((0, 0), (12, 24, 36, 0))
            layer.save(rgba, "WEBP", lossless=True)
            with self.assertRaises(PromotionError):
                _validate_state(rgba, geometry, 350000)

    def test_promotion_rejects_runtime_leftovers(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            qa = Path(temp_dir) / "qa"
            runtime = Path(temp_dir) / "runtime"
            qa.mkdir()
            runtime.mkdir()
            (runtime / "extra.webp").write_bytes(b"nope")
            for name in a1_expected_files():
                Image.new("RGB", (1536, 1152), (12, 24, 36)).save(
                    qa / name,
                    "WEBP",
                    quality=80,
                    method=6,
                )
            with self.assertRaises(PromotionError):
                promote_states(qa_root=qa, runtime_root=runtime, dry_run=True)

    def test_thumbnail_hash_gate_rejects_a_changed_source(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            source = Path(temp_dir) / "state.webp"
            output = Path(temp_dir) / "thumb.webp"
            Image.new("RGB", (1536, 1152), (40, 30, 20)).save(source, "WEBP")
            actual = sha256_file(source)
            derive_thumbnail(source, output, expected_source_sha256=actual)
            self.assertTrue(output.is_file())
            with self.assertRaises(ThumbnailError):
                derive_thumbnail(
                    source,
                    output,
                    expected_source_sha256="0" * 64,
                )


if __name__ == "__main__":
    unittest.main()
