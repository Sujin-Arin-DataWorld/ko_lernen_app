from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_personal_hanok_assets as checker
from hanok_v1_asset_contract import ROOT, qa_composite_path


class PersonalHanokAssetCheckerTest(unittest.TestCase):
    def test_qa_composite_is_outside_the_runtime_map(self) -> None:
        path = qa_composite_path()
        self.assertEqual(
            path,
            ROOT / "assets_unused" / "pending_review" / "reference_full_estate.png",
        )
        self.assertNotIn("personal_hanok_v2/map", str(path).replace("\\", "/"))
        self.assertFalse((checker.ASSET_ROOT / "reference_full_estate.png").exists())

    def test_write_reference_refuses_the_runtime_map_folder(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            forbidden = Path(temp_dir) / "map" / "reference_full_estate.png"
            forbidden.parent.mkdir(parents=True)
            with patch(
                "check_personal_hanok_assets.qa_composite_path",
                return_value=forbidden,
            ), patch(
                "check_personal_hanok_assets.ASSET_ROOT",
                forbidden.parent,
            ):
                with self.assertRaises(SystemExit):
                    checker._write_reference()

    def test_runtime_alias_of_the_qa_composite_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            runtime = Path(temp_dir) / "reference_full_estate.png"
            Image.new("RGB", (8, 8), (1, 2, 3)).save(runtime)
            with patch.object(checker, "ASSET_ROOT", Path(temp_dir)):
                lines = checker._check_reference()
        self.assertTrue(any(line.startswith("[fail]") for line in lines))

    def test_leftover_runtime_a1_files_fail_even_when_set_absent(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            (root / "extra.webp").write_bytes(b"nope")
            with patch(
                "check_personal_hanok_assets.A1_RUNTIME_STATES_ROOT",
                root,
            ):
                lines = checker._check_a1_runtime_states(required=False)
        self.assertTrue(any("leftover" in line for line in lines))

    def test_partial_runtime_a1_states_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            (root / "06_columns.webp").write_bytes(b"not-a-real-image")
            with patch(
                "check_personal_hanok_assets.A1_RUNTIME_STATES_ROOT",
                root,
            ):
                lines = checker._check_a1_runtime_states(required=False)
        self.assertTrue(any("atomically" in line for line in lines))

    def test_repo_runtime_layers_and_qa_composite_pass(self) -> None:
        self.assertEqual(checker.main([]), 0)


if __name__ == "__main__":
    unittest.main()
