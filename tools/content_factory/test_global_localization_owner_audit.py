from __future__ import annotations

import json
from pathlib import Path
import sys
import unittest

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import build_global_localization_owner_audit as audit


class GlobalLocalizationOwnerAuditTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        audit.main()
        cls.payload = json.loads(audit.OUTPUT.read_text(encoding="utf-8"))

    def test_expected_owner_inventory_is_complete(self) -> None:
        summary = self.payload["summary"]
        self.assertEqual(summary["ownerRecordCount"], 7706)
        self.assertEqual(summary["bySurfaceType"]["vocab_lexeme"], 2968)
        self.assertEqual(summary["bySurfaceType"]["vocab_example"], 2968)
        self.assertEqual(summary["bySurfaceType"]["smalltalk_expression"], 590)
        self.assertEqual(summary["bySurfaceType"]["smalltalk_expression_variant"], 590)
        self.assertEqual(summary["bySurfaceType"]["smalltalk_followup"], 590)

    def test_every_record_has_explicit_qa_axes(self) -> None:
        for row in self.payload["records"]:
            self.assertIn(row["structuralQaStatus"], {"structural_pass", "needs_correction"})
            self.assertEqual(row["corpusQaStatus"], "pending_native_usage_qa")
            self.assertIn(row["modelDirectKoReviewStatus"], {"reviewed", "not_reviewed"})
            self.assertEqual(row["humanNativeReviewStatus"], "not_reviewed")
            self.assertIn("spokenSurfaceStatus", row)

    def test_all_g2_owner_surfaces_have_canonical_topics(self) -> None:
        summary = self.payload["summary"]
        self.assertEqual(summary["topicMappedCount"], summary["ownerRecordCount"])
        self.assertEqual(summary["manualTopicReviewCount"], 0)
        self.assertTrue(all(row["canonicalTopicId"] for row in self.payload["records"]))

    def test_anchor_review_debt_is_explicitly_resolved(self) -> None:
        summary = self.payload["summary"]
        self.assertEqual(summary["manualReviewFlaggedCount"], 0)
        self.assertEqual(summary["reviewFlagCounts"], {})
        explicit = {
            key: value
            for key, value in summary["resolvedAuditNoteCounts"].items()
            if key.startswith("example_anchor:explicit_")
        }
        self.assertEqual(sum(explicit.values()), 63)
        self.assertEqual(explicit["example_anchor:explicit_inflected_surface"], 29)
        self.assertEqual(explicit["example_anchor:explicit_multiword_realization"], 25)
        self.assertEqual(explicit["example_anchor:explicit_semantic_concept_example"], 9)

    def test_length_ratio_direct_ko_queue_is_fully_reviewed(self) -> None:
        summary = self.payload["summary"]
        self.assertEqual(summary["modelDirectKoReviewedVocabRowCount"], 82)
        self.assertEqual(summary["modelDirectKoReviewedOwnerSurfaceCount"], 164)

    def test_no_human_native_review_is_claimed(self) -> None:
        self.assertEqual(self.payload["summary"]["humanNativeReviewedCount"], 0)


if __name__ == "__main__":
    unittest.main()
