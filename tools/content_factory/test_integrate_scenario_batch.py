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
    _refresh_meta,
    _update_backdrop_map,
    _validate_batch,
    _validate_bundle,
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

    def test_companion_game_artifact_is_validated_and_counted(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest_path = root / self.make_batch(root)
            draft_path = root / "tools" / "content_factory" / "drafts" / "pronunciation.json"
            review_path = root / "tools" / "content_factory" / "review" / "pronunciation.csv"
            record = {
                "id": "pronunciation_c1_9999",
                "level": "c1",
                "ko": "근거를 다시 검토하겠습니다.",
                "de": "Ich werde die Evidenz erneut prüfen.",
                "en": "I will review the evidence again.",
                "focus": "문장 끝 억양",
            }
            draft_path.write_text(
                json.dumps({"version": 1, "phrases": [record]}, ensure_ascii=False),
                encoding="utf-8",
            )
            with review_path.open("w", encoding="utf-8", newline="") as handle:
                writer = csv.DictWriter(handle, fieldnames=REVIEW_HEADER)
                writer.writeheader()
                writer.writerow(
                    {
                        "id": record["id"],
                        "level": "C1",
                        "ko": record["ko"],
                        "de": record["de"],
                        "en": record["en"],
                        "field_notes": "rights: original",
                        "상태": "draft",
                        "jin_memo": "",
                    }
                )
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            manifest["artifacts"].append(
                {
                    "kind": "pronunciation",
                    "draft": "tools/content_factory/drafts/pronunciation.json",
                    "review": "tools/content_factory/review/pronunciation.csv",
                    "collection": "phrases",
                    "count": 1,
                    "levels": {"c1": 1},
                }
            )
            manifest["recordCount"] = 3
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            _, _, records, _ = _validate_bundle(
                root,
                manifest_path.relative_to(root),
                require_approved=False,
            )
            self.assertEqual(set(records), {"scenario", "pronunciation"})

    def test_meta_refresh_uses_all_six_levels(self) -> None:
        root = {
            "meta": {"total": 1, "perLevel": {"a1": 1}},
            "items": [
                {"level": "a1"},
                {"level": "c1"},
                {"level": "c2"},
            ],
        }
        _refresh_meta(root, "items")
        self.assertEqual(root["meta"]["total"], 3)
        self.assertEqual(
            root["meta"]["perLevel"],
            {"a1": 1, "a2": 0, "b1": 0, "b2": 0, "c1": 1, "c2": 1},
        )


if __name__ == "__main__":
    unittest.main()
