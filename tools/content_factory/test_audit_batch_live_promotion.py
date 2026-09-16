#!/usr/bin/env python3
"""Regression tests for the all-Batch live projection ledger."""

from __future__ import annotations

from pathlib import Path
import json
import tempfile
import unittest
from unittest.mock import patch

from audit_batch_live_promotion import ROOT, _read_csv, audit


class BatchLivePromotionAuditTest(unittest.TestCase):
    def test_promoted_batches_are_live_and_pending_batches_are_absent(self) -> None:
        result = audit(ROOT)

        self.assertTrue(result["ok"], result["errors"])
        self.assertEqual(result["version"], 4)
        self.assertEqual(result["trackedIds"], 7669)
        self.assertEqual(result["liveIds"], 7298)
        self.assertEqual(result["pendingIds"], 576)
        self.assertEqual(result["retiredScenarioIds"], 371)
        self.assertEqual(
            result["trackedIds"],
            result["liveIds"] + result["retiredScenarioIds"],
        )
        reports = {row["batch"]: row for row in result["reports"]}
        for number in (32, 33, 34):
            report = reports[f"c3_batch{number}_a2_reinforcement"]
            self.assertEqual(report["auditStatus"], "pending_not_live")
            self.assertEqual(report["live"], 0)
            self.assertEqual(report["tracked"], 192)
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


class PromotionBoundaryTest(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        data = self.root / "assets/data"
        data.mkdir(parents=True)
        (data / "curriculum_manifest.json").write_text(
            json.dumps({"scenarioCorpusGeneration": "canonical_120_v1"}), encoding="utf-8"
        )
        drafts = self.root / "tools/content_factory/drafts"
        drafts.mkdir(parents=True)
        (self.root / "draft.csv").write_text("id,korean\nnew_1,단어\n", encoding="utf-8")
        self.review = self.root / "review.csv"
        self.review.write_text("id,상태\nnew_1,pending\n", encoding="utf-8")
        self.manifest_path = drafts / "batch_test_manifest.json"
        self.manifest = {
            "batch": "test", "status": "draft", "recordCount": 1,
            "artifacts": [{"kind": "vocab", "draft": "draft.csv", "review": "review.csv", "count": 1}],
        }

    def run_audit(self, live=None, supplemental=None):
        self.manifest_path.write_text(json.dumps(self.manifest), encoding="utf-8")
        with patch("audit_batch_live_promotion._live_records", return_value=live or {"vocab": []}), patch(
            "audit_batch_live_promotion._supplemental_live_records", return_value=supplemental or {}
        ):
            return audit(self.root)

    def test_pending_draft_still_validates_counts_and_review_ids(self):
        self.assertTrue(self.run_audit()["ok"])
        self.review.write_text("id,상태\nwrong_1,pending\n", encoding="utf-8")
        self.manifest["artifacts"][0]["count"] = 2
        errors = self.run_audit()["errors"]
        self.assertTrue(any("review IDs differ" in error for error in errors))
        self.assertTrue(any("manifest count" in error for error in errors))

    def test_accidental_draft_promotion_is_rejected(self):
        result = self.run_audit(live={"vocab": [{"id": "new_1"}]})
        self.assertFalse(result["ok"])
        self.assertIn("unpromoted draft is live: vocab:new_1", result["errors"][0])

    def test_pending_scenario_is_not_counted_as_retired(self):
        self.manifest["artifacts"][0]["kind"] = "scenario"
        result = self.run_audit(live={"scenario": []})
        self.assertTrue(result["ok"])
        self.assertEqual(result["retiredScenarioIds"], 0)
        self.assertEqual(result["pendingIds"], 1)

    def test_supplemental_draft_promotion_is_rejected(self):
        self.manifest["supplementalArtifacts"] = [
            {"kind": "wordRelation", "keyField": "id", "keys": ["relation_1"], "count": 1}
        ]
        result = self.run_audit(supplemental={"wordRelation": ("id", [{"id": "relation_1"}])})
        self.assertFalse(result["ok"])
        self.assertTrue(any("unpromoted draft is live: wordRelation:relation_1" in e for e in result["errors"]))

    def test_legacy_promoted_draft_still_requires_live_ids(self):
        self.manifest.update(status="review_only_draft", provenance={"promotedAt": "historical evidence"})
        self.assertFalse(self.run_audit()["ok"])
        result = self.run_audit(live={"vocab": [{"id": "new_1"}]})
        self.assertTrue(result["ok"])
        self.assertEqual(result["pendingIds"], 0)

    def test_merged_without_authority_or_with_pending_reviews_fails(self):
        self.manifest["status"] = "merged"
        live = {"vocab": [{"id": "new_1"}]}
        self.assertFalse(self.run_audit(live=live)["ok"])
        self.manifest["provenance"] = {"approval": {"authority": "Jin"}}
        result = self.run_audit(live=live)
        self.assertFalse(result["ok"])
        self.assertTrue(any("all review rows approved" in e for e in result["errors"]))

    def test_unknown_status_is_not_a_draft_escape_hatch(self):
        self.manifest["status"] = "typo"
        self.assertFalse(self.run_audit()["ok"])


if __name__ == "__main__":
    unittest.main()
