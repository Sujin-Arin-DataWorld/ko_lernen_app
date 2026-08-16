#!/usr/bin/env python3
"""Regression tests for generic review-only scenario batch validation."""

from __future__ import annotations

import csv
import json
from pathlib import Path
import tempfile
import unittest

from integrate_scenario_batch import (
    REVIEW_HEADER,
    ScenarioIntegrationError,
    _update_backdrop_map,
    _validate_batch,
)


class ScenarioBatchValidationTest(unittest.TestCase):
    def make_batch(self, root: Path, *, quest_count: int = 2) -> Path:
        draft_path = root / "tools" / "content_factory" / "drafts" / "scenarios.json"
        review_path = root / "tools" / "content_factory" / "review" / "scenarios.csv"
        manifest_path = root / "tools" / "content_factory" / "drafts" / "batch_06_manifest.json"
        draft_path.parent.mkdir(parents=True)
        review_path.parent.mkdir(parents=True)
        scenarios = [
            {
                "id": "c1_review_example",
                "level": "c1",
                "title": {"ko": "근거 검토", "de": "Evidenz prüfen", "en": "Reviewing evidence"},
                "quests": [{"id": "quest_c1_review", "type": "diktat", "data": {}}],
            },
            {
                "id": "c2_appeal_example",
                "level": "c2",
                "title": {"ko": "이의 제기", "de": "Einspruch", "en": "Appeal"},
                "quests": [{"id": "quest_c2_appeal", "type": "diktat", "data": {}}],
            },
        ]
        draft_path.write_text(
            json.dumps({"version": 1, "scenarios": scenarios}, ensure_ascii=False),
            encoding="utf-8",
        )
        with review_path.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=REVIEW_HEADER)
            writer.writeheader()
            for record in scenarios:
                writer.writerow(
                    {
                        "id": record["id"],
                        "level": record["level"].upper(),
                        "ko": record["title"]["ko"],
                        "de": record["title"]["de"],
                        "en": record["title"]["en"],
                        "field_notes": "rights: original",
                        "상태": "draft",
                        "jin_memo": "",
                    }
                )
        manifest = {
            "version": 1,
            "batch": "06",
            "status": "review_only",
            "artifacts": [
                {
                    "kind": "scenario",
                    "draft": "tools/content_factory/drafts/scenarios.json",
                    "review": "tools/content_factory/review/scenarios.csv",
                    "count": 2,
                    "levels": {"c1": 1, "c2": 1},
                }
            ],
            "recordCount": 2,
            "questCount": quest_count,
            "contentLinks": [
                {
                    "contentKind": "scenario",
                    "contentId": "c1_review_example",
                    "courseUnitId": "c1_example",
                    "role": "assess",
                },
                {
                    "contentKind": "scenario",
                    "contentId": "c2_appeal_example",
                    "courseUnitId": "c2_example",
                    "role": "assess",
                },
            ],
            "backdrops": {
                "c1_review_example": "office",
                "c2_appeal_example": "office",
            },
        }
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        return manifest_path.relative_to(root)

    def test_preview_accepts_review_only_c1_c2_batch(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = self.make_batch(root)
            _, parsed, records, backdrops = _validate_batch(
                root,
                manifest,
                require_approved=False,
            )
            self.assertEqual(parsed["batch"], "06")
            self.assertEqual([record["level"] for record in records], ["c1", "c2"])
            self.assertEqual(set(backdrops), {"c1_review_example", "c2_appeal_example"})

    def test_apply_rejects_unapproved_batch(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = self.make_batch(root)
            with self.assertRaisesRegex(ScenarioIntegrationError, "approved before promotion"):
                _validate_batch(root, manifest, require_approved=True)

    def test_quest_count_is_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = self.make_batch(root, quest_count=3)
            with self.assertRaisesRegex(ScenarioIntegrationError, "quest count disagrees"):
                _validate_batch(root, manifest, require_approved=False)

    def test_backdrop_comment_uses_current_batch(self) -> None:
        source = "const map = {\n    // cafe -- anchor\n};\n"
        updated = _update_backdrop_map(source, {"c2_appeal_example": "office"}, "06")
        self.assertIn("Reviewed scenario Batch 06", updated)
        self.assertIn("'c2_appeal_example': 'office'", updated)


if __name__ == "__main__":
    unittest.main()
