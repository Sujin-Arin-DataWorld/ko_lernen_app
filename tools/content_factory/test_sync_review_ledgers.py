#!/usr/bin/env python3
"""Regression tests for deterministic review-ledger projection."""

from __future__ import annotations

import csv
from io import StringIO
import json
from pathlib import Path
import tempfile
import unittest

from sync_review_ledgers import REVIEW_HEADER, ReviewSyncError, build_ledgers


class ReviewLedgerSyncTest(unittest.TestCase):
    def make_fixture(self, root: Path) -> Path:
        draft = root / "tools" / "content_factory" / "drafts" / "smalltalk.json"
        review = root / "tools" / "content_factory" / "review" / "smalltalk.csv"
        manifest = root / "tools" / "content_factory" / "drafts" / "batch_99_manifest.json"
        draft.parent.mkdir(parents=True)
        review.parent.mkdir(parents=True)
        draft.write_text(
            json.dumps(
                {
                    "version": 1,
                    "phrases": [
                        {
                            "id": "smalltalk_b1_9999",
                            "level": "b1",
                            "ko": "방문 시간을 확인할 수 있을까요?",
                            "de": "Könnte ich den Besuchstermin bestätigen?",
                            "en": "Could I confirm the visit time?",
                            "sourceSeedId": "seed_b1_fixture",
                            "courseUnitId": "b1_fixture",
                        }
                    ],
                },
                ensure_ascii=False,
            ),
            encoding="utf-8",
        )
        manifest.write_text(
            json.dumps(
                {
                    "version": 1,
                    "batch": "99",
                    "artifacts": [
                        {
                            "kind": "smalltalk",
                            "draft": str(draft.relative_to(root)).replace("\\", "/"),
                            "review": str(review.relative_to(root)).replace("\\", "/"),
                            "collection": "phrases",
                            "count": 1,
                        }
                    ],
                },
                ensure_ascii=False,
            ),
            encoding="utf-8",
        )
        return manifest.relative_to(root)

    def test_current_batch_projection_matches_committed_ledgers(self) -> None:
        outputs = build_ledgers()
        self.assertEqual(len(outputs), 5)
        for path, expected in outputs.items():
            self.assertEqual(path.read_text(encoding="utf-8"), expected)

    def test_existing_status_and_memo_are_preserved_by_id(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = self.make_fixture(root)
            review = root / "tools" / "content_factory" / "review" / "smalltalk.csv"
            review.write_text(
                "id,level,ko,de,en,field_notes,상태,jin_memo\n"
                "smalltalk_b1_9999,B1,old,old,old,rights: original,fix: ko,check register\n",
                encoding="utf-8",
            )
            output = next(iter(build_ledgers(root=root, manifest_path=manifest).values()))
            rows = list(csv.DictReader(StringIO(output)))
            self.assertEqual(list(rows[0]), REVIEW_HEADER)
            self.assertEqual(rows[0]["상태"], "fix: ko")
            self.assertEqual(rows[0]["jin_memo"], "check register")
            self.assertEqual(rows[0]["ko"], "방문 시간을 확인할 수 있을까요?")

    def test_disappearing_review_id_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = self.make_fixture(root)
            review = root / "tools" / "content_factory" / "review" / "smalltalk.csv"
            review.write_text(
                "id,level,ko,de,en,field_notes,상태,jin_memo\n"
                "smalltalk_b1_9998,B1,old,old,old,rights: original,draft,\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ReviewSyncError, "disappeared"):
                build_ledgers(root=root, manifest_path=manifest)


if __name__ == "__main__":
    unittest.main()
