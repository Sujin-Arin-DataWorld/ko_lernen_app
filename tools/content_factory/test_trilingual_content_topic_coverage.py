from __future__ import annotations

import json
import subprocess
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LEDGER = (
    ROOT
    / "tools"
    / "content_factory"
    / "review"
    / "trilingual_content_topic_coverage_20261006.json"
)
TAXONOMY = ROOT / "tools/content_factory/cefr_matrix/taxonomy.json"
GENERATOR = ROOT / "tools/content_factory/build_trilingual_content_topic_coverage.py"


class TrilingualContentTopicCoverageTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
        cls.taxonomy = json.loads(TAXONOMY.read_text(encoding="utf-8"))
        cls.topic_ids = {row["id"] for row in cls.taxonomy["topics"]}

    def test_generator_output_is_current(self) -> None:
        completed = subprocess.run(
            [sys.executable, str(GENERATOR), "--check"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            encoding="utf-8",
            check=False,
        )
        self.assertEqual(
            completed.returncode,
            0,
            completed.stdout + "\n" + completed.stderr,
        )

    def test_every_tracked_item_is_mapped_or_explicitly_unmapped(self) -> None:
        records = self.ledger["records"]
        self.assertEqual(
            len(records),
            self.ledger["summary"]["trackedItemCount"],
        )
        for row in records:
            with self.subTest(kind=row["kind"], item=row["itemId"]):
                topic_id = row["canonicalTopicId"]
                if topic_id is None:
                    self.assertTrue(row.get("unmappedReason"))
                    self.assertEqual(
                        row["researchCoverageStatus"],
                        "manual_topic_review_required",
                    )
                else:
                    self.assertIn(topic_id, self.topic_ids)
                    self.assertNotIn("unmappedReason", row)
                    self.assertEqual(
                        row["researchCoverageStatus"],
                        "topic_profile_deep_pass_complete",
                    )

    def test_all_32_topics_are_represented_by_mapped_content(self) -> None:
        counts = self.ledger["summary"]["mappedCountsByCanonicalTopic"]
        self.assertEqual(set(counts), self.topic_ids)
        self.assertTrue(all(counts[topic_id] > 0 for topic_id in self.topic_ids))

    def test_living_korea_user_reviewed_scenes_are_all_mapped(self) -> None:
        rows = [
            row
            for row in self.ledger["records"]
            if row["kind"] == "living_korea_scene"
        ]
        self.assertEqual(len(rows), 23)
        self.assertTrue(all(row["canonicalTopicId"] for row in rows))
        self.assertTrue(
            all(row["approvalState"] == "user_reviewed_not_live" for row in rows)
        )

    def test_research_mapping_never_upgrades_approval_state(self) -> None:
        policy = self.ledger["policy"]
        self.assertTrue(policy["researchCoverageDoesNotImplyApproval"])
        states = {row["approvalState"] for row in self.ledger["records"]}
        self.assertIn("live", states)
        self.assertIn("review_only", states)
        self.assertIn("user_reviewed_not_live", states)

    def test_repeatable_draft_schemas_are_tracked_at_item_level(self) -> None:
        file_level_paths = {
            row["sourcePath"] for row in self.ledger["unparsedDraftSources"]
        }
        expected_item_level = {
            "tools/content_factory/drafts/batch_25_a1_rows.csv",
            "tools/content_factory/drafts/batch_25_a1_cloze.json",
            "tools/content_factory/drafts/batch_25_a1_satz.json",
            "tools/content_factory/drafts/c1_batch11_scenarios_a1_c2.json",
            "tools/content_factory/drafts/w10_scenarios_a1.json",
            "tools/content_factory/drafts/c2_batch01_smalltalk_b1_b2.json",
            "tools/content_factory/drafts/persona_a2_listening_20261003.json",
        }
        self.assertTrue(expected_item_level.isdisjoint(file_level_paths))
        item_level_paths = {
            row["sourcePath"]
            for row in self.ledger["records"]
            if row["approvalState"] == "draft_or_review_artifact"
        }
        self.assertTrue(expected_item_level.issubset(item_level_paths))

    def test_unsupported_legacy_drafts_are_explicitly_tracked_at_file_level(self) -> None:
        sources = self.ledger["unparsedDraftSources"]
        self.assertEqual(
            len(sources),
            self.ledger["summary"]["unparsedDraftSourceCount"],
        )
        self.assertGreater(len(sources), 0)
        for row in sources:
            self.assertEqual(
                row["trackingStatus"],
                "file_level_explicit_unmapped",
            )
            self.assertTrue(row["unmappedReason"])


if __name__ == "__main__":
    unittest.main()
