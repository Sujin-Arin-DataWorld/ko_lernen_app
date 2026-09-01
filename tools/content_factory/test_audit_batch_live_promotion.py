#!/usr/bin/env python3
"""Regression tests for the all-Batch live projection ledger."""

from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

from audit_batch_live_promotion import ROOT, _read_csv, audit


class BatchLivePromotionAuditTest(unittest.TestCase):
    def test_every_active_batch_id_is_live_with_authority_evidence(self) -> None:
        result = audit(ROOT)

        self.assertTrue(result["ok"], result["errors"])
        self.assertEqual(result["version"], 3)
        self.assertEqual(result["trackedIds"], 6331)
        self.assertEqual(result["liveIds"], 5960)
        self.assertEqual(result["retiredScenarioIds"], 371)
        self.assertEqual(
            result["trackedIds"],
            result["liveIds"] + result["retiredScenarioIds"],
        )
        reports = {row["batch"]: row for row in result["reports"]}
        self.assertEqual(reports["theme_park_date_v1"]["tracked"], 66)
        self.assertEqual(
            reports["theme_park_date_v1"]["auditStatus"],
            "live_verified_modern",
        )
        self.assertEqual(
            reports["theme_park_date_v1"]["reviewStatuses"],
            {"approved": 66},
        )
        self.assertEqual(reports["20"]["tracked"], 318)
        self.assertEqual(
            reports["20"]["auditStatus"],
            "lineage_verified_modern_retired_scenarios",
        )
        self.assertEqual(reports["20"]["reviewStatuses"], {"approved": 210})
        self.assertEqual(len(reports["20"]["liveProjectionSha256"]), 64)
        self.assertEqual(
            reports["11"]["auditStatus"],
            "lineage_verified_legacy_retired_scenarios",
        )
        self.assertEqual(reports["11"]["reviewStatuses"], {"draft": 36})

    def test_csv_reader_rejects_unquoted_extra_fields(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "review.csv"
            path.write_text(
                "id,ko,상태\nitem_1,문장,안쪽 쉼표,draft\n",
                encoding="utf-8",
            )
            _, errors = _read_csv(path)

        self.assertEqual(len(errors), 1)
        self.assertIn("extra unquoted CSV fields", errors[0])


if __name__ == "__main__":
    unittest.main()
