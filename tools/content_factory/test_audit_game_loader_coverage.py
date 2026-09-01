#!/usr/bin/env python3
"""Regression tests for loader-aware content coverage through Batch 20."""

from __future__ import annotations

from pathlib import Path
import unittest

from audit_game_loader_coverage import LoaderCoverageAudit, ROOT


BATCH_06 = Path("tools/content_factory/drafts/batch_06_manifest.json")


class LoaderCoverageAuditTest(unittest.TestCase):
    def test_live_report_matches_current_runtime_contracts(self) -> None:
        report = LoaderCoverageAudit(ROOT).build()

        self.assertEqual(report["state"], "live")
        self.assertEqual(report["inventory"]["scenario"]["total"], 120)
        self.assertEqual(
            report["inventory"]["scenario"]["exactPerLevel"],
            {level: 20 for level in ("a1", "a2", "b1", "b2", "c1", "c2")},
        )
        self.assertEqual(report["inventory"]["pronunciation"]["total"], 84)
        self.assertEqual(
            report["libraryLoader"]["pronunciationVisiblePerLearnerLevel"]["c2"],
            84,
        )
        self.assertEqual(
            report["libraryLoader"]["listeningInitial"]["c2"]["effectiveSourceLevel"],
            "c2",
        )
        self.assertEqual(
            report["libraryLoader"]["smalltalkCategoryCoverage"]["c1"][
                "emptyCategoryCount"
            ],
            0,
        )
        other = report["libraryLoader"]["otherGames"]
        self.assertEqual(other["grammarCards"]["exactPerLevel"]["c2"], 23)
        self.assertTrue(other["grammarCards"]["appCallSite"])
        self.assertEqual(other["silben"]["exactPerLevel"]["c1"], 20)
        self.assertTrue(other["silben"]["selectablePerLevel"]["c1"])
        self.assertEqual(other["kkeunmari"]["exactPerLevel"]["c2"], 28)
        self.assertEqual(other["mediaPhrases"]["exactPerLevel"]["b1"], 12)
        self.assertTrue(other["mediaPhrases"]["appCallSite"])
        self.assertEqual(other["grammarPatterns"]["exactPerLevel"]["b2"], 3)
        self.assertEqual(other["wordRelations"]["exactPerLevel"]["c2"], 8)
        self.assertEqual(other["cultureNotes"]["exactPerLevel"]["c2"], 1)
        self.assertEqual(other["cultureNotes"]["unmatchedHeadwords"], [])
        self.assertTrue(other["cultureNotes"]["appCallSite"])
        self.assertGreater(other["vocabDerived"]["exactPerLevel"]["c2"], 0)
        self.assertEqual(
            report["courseLoader"]["smalltalk"]["a1"]["countsByUnit"][
                "a1_14_payment_delivery"
            ],
            2,
        )
        self.assertEqual(
            report["courseLoader"]["smalltalk"]["a1"][
                "recordDeficitToTarget"
            ],
            0,
        )
        self.assertTrue(all(not ids for ids in report["unroutedIds"].values()))

    def test_batch_06_overlay_is_idempotent_after_live_promotion(self) -> None:
        live = LoaderCoverageAudit(ROOT).build()
        report = LoaderCoverageAudit(ROOT, BATCH_06).build()

        self.assertEqual(report["state"], "preview")
        self.assertEqual(report["inventory"], live["inventory"])
        self.assertEqual(report["inventory"]["scenario"]["total"], 120)
        self.assertEqual(report["inventory"]["smalltalk"]["total"], 582)
        self.assertEqual(report["inventory"]["cloze"]["total"], 1805)
        self.assertEqual(report["inventory"]["satz"]["total"], 2333)
        self.assertEqual(report["inventory"]["pronunciation"]["total"], 84)
        self.assertEqual(report["inventory"]["scenario"]["exactPerLevel"]["c1"], 20)
        self.assertEqual(
            report["libraryLoader"]["pronunciationVisiblePerLearnerLevel"]["c2"],
            84,
        )
        self.assertEqual(
            report["libraryLoader"]["listeningInitial"]["c2"]["effectiveSourceLevel"],
            "c2",
        )
        self.assertTrue(all(not ids for ids in report["unroutedIds"].values()))


if __name__ == "__main__":
    unittest.main()
