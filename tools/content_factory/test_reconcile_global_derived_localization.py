from __future__ import annotations

import csv
import json
from pathlib import Path
import sys
import unittest

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import reconcile_global_derived_localization as reconcile


class GlobalDerivedLocalizationReconciliationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        reconcile.main()
        cls.report = json.loads(reconcile.REPORT.read_text(encoding="utf-8"))

    def test_resolved_derived_surfaces_have_zero_drift(self) -> None:
        summary = self.report["summary"]
        self.assertEqual(summary["derivedSurfaceCount"], 5250)
        self.assertEqual(summary["resolvedOwnerCount"], 4641)
        self.assertEqual(summary["unresolvedOwnerCount"], 609)
        self.assertEqual(summary["koOwnerMismatchCount"], 0)
        self.assertEqual(summary["postReconcileDriftCount"], 0)

    def test_known_semantic_owner_correction_is_present(self) -> None:
        with reconcile.VOCAB.open(encoding="utf-8-sig", newline="") as handle:
            row = next(r for r in csv.DictReader(handle) if r["id"] == "vocab_a1_0218")
        self.assertEqual(
            row["example_english"],
            "I wasn't sure how to address them, so I asked Sujin.",
        )
        self.assertEqual(
            row["example_german"],
            "Die Anrede war schwierig, also habe ich Sujin gefragt.",
        )


if __name__ == "__main__":
    unittest.main()
