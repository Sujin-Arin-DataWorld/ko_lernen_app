"""Integrity and approval boundaries for the preserved settlement artwork."""

import csv
import hashlib
import json
import re
import unittest
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
PACKAGE = "docs/assets/ildu_settlement_construction_20260915"
CATALOG = f"{PACKAGE}/construction_catalog.json"


def read_json(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


class SettlementArtTest(unittest.TestCase):
    def test_canonical_images_and_originals_are_preserved(self):
        catalog = read_json(CATALOG)
        self.assertEqual(catalog["status"], "approved_canonical")
        self.assertEqual(
            [(p["id"], len(p["stages"])) for p in catalog["phases"]],
            [("site", 6), ("wall", 8), ("sotdaeulmun", 12), ("toilet", 12), ("gokgan", 12)],
        )
        by_asset = {}
        for phase in catalog["phases"]:
            for sequence, stage in enumerate(phase["stages"], 1):
                with self.subTest(stage=stage["id"]):
                    self.assertEqual(stage["id"], f"{phase['id']}-{sequence:02}")
                    self.assertEqual(stage["sequence"], sequence)
                    path = ROOT / stage["asset"]
                    self.assertTrue(path.resolve().is_relative_to(ROOT))
                    self.assertNotIn(stage["asset"], by_asset)
                    self.assertEqual(path.stat().st_size, stage["bytes"])
                    self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), stage["sha256"])
                    with Image.open(path) as image:
                        self.assertEqual(image.size, (stage["width"], stage["height"]))
                        self.assertEqual("A" in image.getbands(), stage["hasAlpha"])
                        image.verify()
                    by_asset[stage["asset"]] = stage
        self.assertEqual(len(by_asset), catalog["totalStages"])
        provenance = read_json(f"{PACKAGE}/provenance.json")
        self.assertEqual(len(provenance["originalCopies"]), 38)
        for original in provenance["originalCopies"]:
            canonical = by_asset[original["canonicalAsset"]]
            self.assertEqual((original["sha256"], original["bytes"]), (canonical["sha256"], canonical["bytes"]))
        self.assertEqual(len(provenance["promptRecords"]), 40)
        for record in provenance["promptRecords"]:
            path = ROOT / record["asset"]
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), record["sha256"])

    def test_art_approval_does_not_enable_the_rejected_map_or_bundle(self):
        catalog = read_json(CATALOG)
        presentation = catalog["presentation"]
        for key in ("resampled", "bundled", "progressionIntegrated", "mapCompositingReady", "worldOutlineApproved"):
            self.assertFalse(presentation[key], key)
        self.assertIsNone(presentation["runtimeConsumer"])
        self.assertTrue((ROOT / catalog["wallOutlineHandoff"]).is_file())
        self.assertNotIn("composition", catalog)
        self.assertNotIn("ui", catalog)
        self.assertFalse(any("wall-masterplan" in source["asset"] for source in catalog["sources"]))
        bundled = re.findall(r"^\s+- (assets/\S+)\s*$", (ROOT / "pubspec.yaml").read_text(encoding="utf-8"), re.M)
        for phase in catalog["phases"]:
            for stage in phase["stages"]:
                path = stage["asset"]
                self.assertNotIn(path, bundled)
                self.assertNotIn(str(Path(path).parent).replace("\\", "/") + "/", bundled)
        self.assertFalse((ROOT / "assets/data/ildu_settlement_construction_v1.json").exists())

    def test_all149_allocations_resolve_in_this_checkout_without_wip(self):
        with (ROOT / "docs/superpowers/plans/2026-09-15-ildu-stage-allocation.csv").open(encoding="utf-8-sig", newline="") as stream:
            rows = list(csv.DictReader(stream))
        self.assertEqual(len(rows), 149)
        self.assertEqual(len({r["stageId"] for r in rows}), 149)
        self.assertEqual(sum(int(r["bytes"]) for r in rows), 269109572)
        for row in rows:
            with self.subTest(stage=row["stageId"]):
                self.assertEqual(row["mappingStatus"], "unit_allocated_assessment_unreviewed")
                self.assertNotIn("worktrees", row["sourceRoot"])
                self.assertTrue((ROOT / row["sourceCatalog"]).is_file())
                path = ROOT / row["assetPath"]
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), row["sha256"])


if __name__ == "__main__":
    unittest.main()
