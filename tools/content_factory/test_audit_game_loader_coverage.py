#!/usr/bin/env python3
"""Regression tests for loader-aware content coverage through Batch 20."""

from __future__ import annotations

import json
from pathlib import Path
import unittest

from audit_game_loader_coverage import LoaderCoverageAudit, ROOT
import scenario_store


BATCH_06 = Path("tools/content_factory/drafts/batch_06_manifest.json")

# The live inventory is pinned to tools/content_factory/content_audit_manifest.json
# (the same denominator test/content_id_contract_test.dart enforces) instead of
# the Batch 20 snapshot literals, which went stale when the scenario corpus
# grew from 126 to its current size (T2.9a, 2026-09-09).
_MANIFEST = json.loads(
    (ROOT / "tools/content_factory/content_audit_manifest.json").read_text(encoding="utf-8")
)
COUNTS = {item["kind"]: int(item["count"]) for item in _MANIFEST["sources"]}
LEVELS = ("a1", "a2", "b1", "b2", "c1", "c2")


def _scenario_counts_per_level() -> dict[str, int]:
    scenarios = scenario_store.load_scenarios(ROOT / "assets" / "data")
    return {
        level: sum(1 for item in scenarios if str(item.get("level", "")).lower() == level)
        for level in LEVELS
    }


class LoaderCoverageAuditTest(unittest.TestCase):
    def test_live_report_matches_current_runtime_contracts(self) -> None:
        report = LoaderCoverageAudit(ROOT).build()

        self.assertEqual(report["state"], "live")
        self.assertEqual(report["inventory"]["scenario"]["total"], COUNTS["scenario"])
        self.assertEqual(
            report["inventory"]["scenario"]["exactPerLevel"],
            _scenario_counts_per_level(),
        )
        self.assertEqual(
            report["inventory"]["pronunciation"]["total"], COUNTS["pronunciation"]
        )
        self.assertEqual(
            report["libraryLoader"]["pronunciationVisiblePerLearnerLevel"]["c2"],
            COUNTS["pronunciation"],
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
        self.assertEqual(report["inventory"]["scenario"]["total"], COUNTS["scenario"])
        self.assertEqual(report["inventory"]["smalltalk"]["total"], COUNTS["smalltalk"])
        self.assertEqual(report["inventory"]["cloze"]["total"], COUNTS["cloze"])
        self.assertEqual(report["inventory"]["satz"]["total"], COUNTS["satz"])
        self.assertEqual(
            report["inventory"]["pronunciation"]["total"], COUNTS["pronunciation"]
        )
        self.assertEqual(
            report["inventory"]["scenario"]["exactPerLevel"],
            _scenario_counts_per_level(),
        )
        self.assertEqual(
            report["libraryLoader"]["pronunciationVisiblePerLearnerLevel"]["c2"],
            COUNTS["pronunciation"],
        )
        self.assertEqual(
            report["libraryLoader"]["listeningInitial"]["c2"]["effectiveSourceLevel"],
            "c2",
        )
        self.assertTrue(all(not ids for ids in report["unroutedIds"].values()))


if __name__ == "__main__":
    unittest.main()
