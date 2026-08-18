#!/usr/bin/env python3
"""Regression tests for loader-aware content coverage.

2026-08-18 Batch 11 승격으로 코퍼스가 264 → 300 (레벨마다 +6) 이 됐다.
C1 은 11 → 17 이다.
"""

from __future__ import annotations

from pathlib import Path
import unittest

from audit_game_loader_coverage import LoaderCoverageAudit, ROOT


BATCH_06 = Path("tools/content_factory/drafts/batch_06_manifest.json")


class LoaderCoverageAuditTest(unittest.TestCase):
    def test_live_report_matches_current_runtime_contracts(self) -> None:
        report = LoaderCoverageAudit(ROOT).build()

        self.assertEqual(report["state"], "live")
        self.assertEqual(report["inventory"]["scenario"]["exactPerLevel"]["c1"], 17)
        self.assertEqual(report["inventory"]["pronunciation"]["total"], 20)
        self.assertEqual(
            report["libraryLoader"]["pronunciationVisiblePerLearnerLevel"]["c2"],
            20,
        )
        self.assertEqual(
            report["libraryLoader"]["listeningInitial"]["c2"]["effectiveSourceLevel"],
            "c2",
        )
        self.assertEqual(
            report["libraryLoader"]["smalltalkCategoryCoverage"]["c1"][
                "emptyCategoryCount"
            ],
            # Batch 12 가 c1 의 screen·hobby·kpop·dating 4개를 채웠다 (18 → 14).
            14,
        )
        other = report["libraryLoader"]["otherGames"]
        self.assertEqual(other["silben"]["exactPerLevel"]["c1"], 0)
        self.assertFalse(other["silben"]["selectablePerLevel"]["c1"])
        self.assertEqual(other["kkeunmari"]["exactPerLevel"]["c2"], 0)
        self.assertEqual(other["mediaPhrases"]["exactPerLevel"]["b1"], 0)
        self.assertEqual(other["grammarPatterns"]["exactPerLevel"]["b2"], 0)
        self.assertGreater(other["vocabDerived"]["exactPerLevel"]["c2"], 0)
        self.assertTrue(all(not ids for ids in report["unroutedIds"].values()))

    def test_batch_06_overlay_is_idempotent_after_live_promotion(self) -> None:
        live = LoaderCoverageAudit(ROOT).build()
        report = LoaderCoverageAudit(ROOT, BATCH_06).build()

        self.assertEqual(report["state"], "preview")
        self.assertEqual(report["inventory"], live["inventory"])
        self.assertEqual(report["inventory"]["scenario"]["total"], 300)
        self.assertEqual(report["inventory"]["smalltalk"]["total"], 377)
        self.assertEqual(report["inventory"]["cloze"]["total"], 1538)
        self.assertEqual(report["inventory"]["satz"]["total"], 2091)
        self.assertEqual(report["inventory"]["pronunciation"]["total"], 20)
        self.assertEqual(report["inventory"]["scenario"]["exactPerLevel"]["c1"], 17)
        self.assertEqual(
            report["libraryLoader"]["pronunciationVisiblePerLearnerLevel"]["c2"],
            20,
        )
        self.assertEqual(
            report["libraryLoader"]["listeningInitial"]["c2"]["effectiveSourceLevel"],
            "c2",
        )
        self.assertTrue(all(not ids for ids in report["unroutedIds"].values()))


if __name__ == "__main__":
    unittest.main()
