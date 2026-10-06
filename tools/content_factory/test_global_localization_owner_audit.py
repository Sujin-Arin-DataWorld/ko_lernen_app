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
            self.assertEqual(row["humanNativeReviewStatus"], "not_reviewed")
            self.assertIn("spokenSurfaceStatus", row)

    def test_all_g2_owner_surfaces_have_canonical_topics(self) -> None:
        summary = self.payload["summary"]
        self.assertEqual(summary["topicMappedCount"], summary["ownerRecordCount"])
        self.assertEqual(summary["manualTopicReviewCount"], 0)
        self.assertTrue(all(row["canonicalTopicId"] for row in self.payload["records"]))

    def test_no_human_native_review_is_claimed(self) -> None:
        self.assertEqual(self.payload["summary"]["humanNativeReviewedCount"], 0)


if __name__ == "__main__":
    unittest.main()
