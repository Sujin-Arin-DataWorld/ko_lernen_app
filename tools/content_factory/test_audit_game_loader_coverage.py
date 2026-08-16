#!/usr/bin/env python3
"""Regression tests for loader-aware content coverage."""

from __future__ import annotations

from pathlib import Path
import unittest

from audit_game_loader_coverage import LoaderCoverageAudit, ROOT


BATCH_06 = Path("tools/content_factory/drafts/batch_06_manifest.json")


class LoaderCoverageAuditTest(unittest.TestCase):
    def test_live_report_matches_current_runtime_contracts(self) -> None:
        report = LoaderCoverageAudit(ROOT).build()

        self.assertEqual(report["state"], "live")
        self.assertEqual(report["inventory"]["scenario"]["exactPerLevel"]["c1"], 0)
        self.assertEqual(report["inventory"]["pronunciation"]["total"], 4)
        self.assertEqual(
            report["libraryLoader"]["pronunciationVisiblePerLearnerLevel"]["c2"],
            4,
        )
        self.assertEqual(
            report["libraryLoader"]["listeningInitial"]["c2"]["effectiveSourceLevel"],
            "b2",
        )
        self.assertEqual(
            report["libraryLoader"]["smalltalkCategoryCoverage"]["c1"][
                "emptyCategoryCount"
            ],
            18,
        )
        other = report["libraryLoader"]["otherGames"]
        self.assertEqual(other["silben"]["exactPerLevel"]["c1"], 0)
        self.assertFalse(other["silben"]["selectablePerLevel"]["c1"])
        self.assertEqual(other["kkeunmari"]["exactPerLevel"]["c2"], 0)
        self.assertEqual(other["mediaPhrases"]["exactPerLevel"]["b1"], 0)
        self.assertEqual(other["grammarPatterns"]["exactPerLevel"]["b2"], 0)
        self.assertGreater(other["vocabDerived"]["exactPerLevel"]["c2"], 0)
        self.assertTrue(all(not ids for ids in report["unroutedIds"].values()))

    def test_batch_06_preview_routes_every_graph_compatible_record(self) -> None:
        report = LoaderCoverageAudit(ROOT, BATCH_06).build()

        self.assertEqual(report["state"], "preview")
        self.assertEqual(report["inventory"]["scenario"]["total"], 62)
        self.assertEqual(report["inventory"]["smalltalk"]["total"], 293)
        self.assertEqual(report["inventory"]["cloze"]["total"], 530)
        self.assertEqual(report["inventory"]["satz"]["total"], 443)
        self.assertEqual(report["inventory"]["pronunciation"]["total"], 20)
        self.assertEqual(report["inventory"]["scenario"]["exactPerLevel"]["c1"], 1)
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
