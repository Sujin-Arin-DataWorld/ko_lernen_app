from __future__ import annotations

import json
from pathlib import Path
import sys
import unittest

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import build_global_localization_qa_units as build


class GlobalLocalizationQaUnitsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        build.main()
        cls.payload = json.loads(build.OUTPUT.read_text(encoding="utf-8"))
        cls.summary = cls.payload["summary"]

    def test_expected_raw_and_unique_counts(self) -> None:
        self.assertEqual(self.summary["rawOccurrenceCount"], 11307)
        self.assertEqual(self.summary["uniqueQaUnitCount"], 7783)

    def test_every_unit_is_topic_and_batch_addressable(self) -> None:
        self.assertTrue(self.summary["allUnitsHaveTopic"])
        self.assertTrue(self.summary["allUnitsHaveBatch"])
        self.assertTrue(all(row["canonicalTopicIds"] for row in self.payload["units"]))
        self.assertTrue(all(row["batchId"] for row in self.payload["units"]))

    def test_batches_are_bounded_and_exhaustive(self) -> None:
        batches = self.payload["batches"]
        self.assertTrue(batches)
        self.assertTrue(all(1 <= row["unitCount"] <= 80 for row in batches))
        self.assertEqual(sum(row["unitCount"] for row in batches), 7783)
        self.assertEqual(
            {u["unitId"] for u in self.payload["units"]},
            {unit_id for batch in batches for unit_id in batch["unitIds"]},
        )

    def test_priority_and_register_axes_exist(self) -> None:
        self.assertTrue(set(self.summary["byRiskTier"]).issubset({"P0", "P1", "P2", "P3", "P4"}))
        self.assertTrue({"P1", "P2", "P3", "P4"}.issubset(set(self.summary["byRiskTier"])))
        decisions = json.loads(build.DECISIONS.read_text(encoding="utf-8"))
        reviewed = decisions["decisionCount"]
        self.assertEqual(self.summary["modelReviewedQaUnitCount"], reviewed)
        self.assertEqual(self.summary["pendingQaUnitCount"], 7783 - reviewed)
        allowed = {
            "everyday_casual",
            "everyday_neutral",
            "service_polite",
            "work_professional",
            "institutional_public",
            "pedagogical_metalinguistic",
            "editorial_culture",
        }
        self.assertTrue(set(self.summary["byRegisterLane"]).issubset(allowed))
        self.assertTrue(all(u["registerLane"] in allowed for u in self.payload["units"]))

    def test_no_human_native_signoff_is_claimed(self) -> None:
        self.assertFalse(self.payload["policy"]["humanNativeSignoff"])
        self.assertTrue(
            all(u["humanNativeReviewStatus"] == "not_reviewed" for u in self.payload["units"])
        )


if __name__ == "__main__":
    unittest.main()
