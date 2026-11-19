from __future__ import annotations

import json
from pathlib import Path
import sys
import unittest

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import build_global_localization_g4_audit as audit


class GlobalLocalizationG4AuditTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        audit.main()
        cls.payload = json.loads(audit.OUTPUT.read_text(encoding="utf-8"))
        cls.summary = cls.payload["summary"]

    def test_registered_g4_inventory_is_complete(self) -> None:
        self.assertEqual(self.summary["recordCount"], 9537)
        self.assertEqual(self.summary["bySurfaceType"]["scenario_dialogue_turn"], 1453)
        lesson_and_culture = self.summary["recordCount"] - 1453
        self.assertEqual(lesson_and_culture, 8084)

    def test_structural_debt_is_zero(self) -> None:
        self.assertEqual(self.summary["structuralPassCount"], 9537)
        self.assertEqual(self.summary["needsCorrectionCount"], 0)
        self.assertEqual(self.summary["issueCounts"], {})

    def test_embedded_korean_is_explicitly_classified(self) -> None:
        review_counts = self.summary["reviewFlagCounts"]
        self.assertNotIn("embedded_korean_term_en", review_counts)
        self.assertNotIn("embedded_korean_term_de", review_counts)
        resolutions = self.summary["resolvedAuditNoteCounts"]
        self.assertEqual(
            resolutions["explicit_korean_learning_or_culture_surface_en"], 3
        )
        self.assertEqual(
            resolutions["explicit_korean_learning_or_culture_surface_de"], 4
        )
        self.assertEqual(
            resolutions["intentional_korean_recognition_surface_en"], 627
        )
        self.assertEqual(
            resolutions["intentional_korean_recognition_surface_de"], 627
        )

    def test_topic_reconciliation_debt_is_zero(self) -> None:
        self.assertEqual(self.summary["reviewFlagCounts"], {})
        self.assertEqual(self.summary["reviewFlaggedRecordCount"], 0)
        self.assertEqual(self.summary["topicMappedCount"], 9537)
        self.assertEqual(self.summary["topicReviewCount"], 0)

    def test_no_human_native_signoff_is_claimed(self) -> None:
        self.assertEqual(self.summary["humanNativeReviewedCount"], 0)
        self.assertTrue(
            all(
                row["humanNativeReviewStatus"] == "not_reviewed"
                for row in self.payload["records"]
            )
        )


if __name__ == "__main__":
    unittest.main()
