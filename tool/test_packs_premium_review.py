"""PACKS visual sign-off is tied to the delivered bytes, not a reusable flag."""
import copy
import hashlib
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_card_style as gate
import style_lock


class PacksPremiumReviewTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.lock = style_lock.load_style_lock()
        self.ledger_rel = self.lock["families"][gate.FAMILY]["knownDeviations"][
            gate.PACKS_PREMIUM_PROFILE
        ]["reviewLedger"]
        source = json.loads((gate.ROOT / self.ledger_rel).read_text(encoding="utf-8"))
        self.ledger = copy.deepcopy(source)
        self.entry = self.ledger["assets"][0]
        for rel in (self.entry["asset"], self.ledger["reference"]):
            target = self.root / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(gate.ROOT / rel, target)
        self.candidate = self.root / self.entry["asset"]

    def check(self):
        path = self.root / self.ledger_rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(self.ledger), encoding="utf-8")
        with patch.object(gate, "ROOT", self.root):
            return gate.check_packs_premium(self.candidate, self.lock)

    def test_reviewed_delivered_bytes_pass(self):
        self.assertTrue(self.check()["ok"])

    def test_replacing_reviewed_bytes_requires_a_new_visual_review(self):
        with self.candidate.open("ab") as handle:
            handle.write(b"changed")
        result = self.check()
        self.assertFalse(result["ok"])
        self.assertIn("PACKS premium visual review sha256 mismatch", result["failures"])

    def test_missing_visual_dimension_is_rejected(self):
        self.entry["qa"].pop("thumbnail100px")
        self.assertIn(
            "PACKS premium visual review is incomplete", self.check()["failures"]
        )

    def test_encoding_below_bible_quality_is_rejected(self):
        self.entry["normalization"]["quality"] = 84
        self.assertIn(
            "PACKS premium requires WebP quality >= 90", self.check()["failures"]
        )

    def test_visual_flags_cannot_make_a_solid_gray_image_pass(self):
        Image.new("RGB", (800, 600), "#c8c8c8").save(
            self.candidate, "WEBP", quality=90, method=6
        )
        self.entry["sha256"] = hashlib.sha256(self.candidate.read_bytes()).hexdigest()
        result = self.check()
        self.assertFalse(result["ok"])
        self.assertTrue(any("palette presence" in f for f in result["failures"]))


if __name__ == "__main__":
    unittest.main()
