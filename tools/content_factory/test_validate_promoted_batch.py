#!/usr/bin/env python3
"""Regression tests for the post-merge promoted-batch validator.

Run with:
    python3 -m unittest tools/content_factory/test_validate_promoted_batch.py
"""

from __future__ import annotations

import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = Path(__file__).resolve().parents[2]
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import validate_batch_01 as review_batch
import validate_promoted_batch as promoted
import scenario_store


BATCH_17 = Path("tools/content_factory/drafts/batch_17_manifest.json")


class PromotedBatchValidationTest(unittest.TestCase):
    def test_merged_batch_17_matches_live_assets(self) -> None:
        count, inventory = promoted.validate(REPO_ROOT / BATCH_17)

        self.assertEqual(144, count)
        self.assertEqual(407, inventory["scenario"])
        self.assertEqual(486, inventory["smalltalk"])
        self.assertEqual(1769, inventory["cloze"])
        self.assertEqual(2297, inventory["satz"])
        self.assertEqual(72, inventory["pronunciation"])

    def test_review_batch_tool_points_merged_batch_17_at_promoted_validator(self) -> None:
        with self.assertRaisesRegex(
            review_batch.BatchValidationError,
            r"status is merged; use tools/content_factory/validate_promoted_batch.py",
        ):
            review_batch.validate_review_batch(manifest_path=BATCH_17)

    def test_rejects_review_only_status(self) -> None:
        root = self._copy_tree()
        path = root / BATCH_17
        manifest = json.loads(path.read_text(encoding="utf-8"))
        manifest["status"] = "review_only_draft"
        path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

        with self.assertRaisesRegex(promoted.PromotedBatchError, "status must be merged"):
            promoted.validate(path, root=root)

    def test_rejects_unknown_artifact_kind(self) -> None:
        root = self._copy_tree()
        path = root / BATCH_17
        manifest = json.loads(path.read_text(encoding="utf-8"))
        manifest["artifacts"][0]["kind"] = "puzzle"
        path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

        with self.assertRaisesRegex(promoted.PromotedBatchError, "unsupported promoted artifact kind"):
            promoted.validate(path, root=root)

    def test_rejects_missing_live_record(self) -> None:
        root = self._copy_tree()
        data_dir = root / "assets" / "data"
        payload = scenario_store.load_root(data_dir)
        payload["scenarios"] = [
            row
            for row in payload["scenarios"]
            if row.get("id") != "c1_kpop_platform_localization_review"
        ]
        scenario_store.write_shards(payload["scenarios"], data_dir)

        with self.assertRaisesRegex(
            promoted.PromotedBatchError,
            "c1_kpop_platform_localization_review",
        ):
            promoted.validate(root / BATCH_17, root=root)

    def _copy_tree(self) -> Path:
        temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(temporary_directory.cleanup)
        root = Path(temporary_directory.name) / "repo"
        shutil.copytree(REPO_ROOT / "assets" / "data", root / "assets" / "data")
        shutil.copytree(
            REPO_ROOT / "tools" / "content_factory" / "drafts",
            root / "tools" / "content_factory" / "drafts",
        )
        shutil.copytree(
            REPO_ROOT / "tools" / "content_factory" / "review",
            root / "tools" / "content_factory" / "review",
        )
        return root


if __name__ == "__main__":
    unittest.main()
