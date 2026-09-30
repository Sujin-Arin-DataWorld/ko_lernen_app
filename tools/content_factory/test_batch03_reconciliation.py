"""Verify the real promotion and keep Batch 03 reconciliation exact."""
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import relevel_ledger
import validate_promoted_batch as promoted

MANIFEST = ROOT / "tools/content_factory/drafts/batch_03_manifest.json"
RECEIPT = ROOT / "tools/content_factory/review/batch_03_reconciliation_20260916.json"


class Batch03ReconciliationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.receipt = json.loads(RECEIPT.read_text(encoding="utf-8"))
        cls.manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        cls.levels = relevel_ledger.load_ledger(ROOT / "tools/content_factory/relevel_ledger.json")

    def test_real_126_row_promoted_batch_validates(self):
        count, _ = promoted.validate(MANIFEST, root=ROOT, ledger=self.levels)
        self.assertEqual(126, count)

    def test_six_row_receipts_match_actual_and_normalized_content_exactly(self):
        self.assertEqual(6, len(self.receipt["rows"]))
        revisions = promoted._copy_revisions(root=ROOT, manifest_path=MANIFEST)
        for item in self.receipt["rows"]:
            kind, ident = item["kind"], item["id"]
            with self.subTest(id=ident):
                artifact = next(a for a in self.manifest["artifacts"] if a["kind"] == kind)
                if kind == "grammar":
                    _, drafts = promoted._csv(ROOT / artifact["draft"])
                    _, current = promoted._csv(ROOT / "assets/data/grammar.csv")
                else:
                    drafts = promoted._json(ROOT / artifact["draft"])["phrases"]
                    current = promoted._json(ROOT / "assets/data/smalltalk.json")["phrases"]
                draft = next(r for r in drafts if r["id"] == ident)
                live = next(r for r in current if r["id"] == ident)
                normalized = promoted._relevel_normalized_live(kind, ident, live, draft, self.levels)
                self.assertEqual(item["beforeSha256"], promoted._fingerprint(draft))
                self.assertEqual(item["actualAfterSha256"], promoted._fingerprint(live))
                self.assertEqual(item["comparisonAfterSha256"], promoted._fingerprint(normalized))
                self.assertTrue(promoted._require_reviewed_copy_revision(
                    kind=kind, ident=ident, draft=draft, live=normalized,
                    revisions=revisions, batch_revisions={},
                ))
                field = "example_korean" if kind == "grammar" else "ko"
                with self.assertRaises(promoted.PromotedBatchError):
                    promoted._require_reviewed_copy_revision(
                        kind=kind, ident=ident, draft=draft,
                        live={**normalized, field: "검토하지 않은 새 내용"},
                        revisions=revisions, batch_revisions={},
                    )

    def test_routing_receipts_allow_only_the_recorded_destinations(self):
        self.assertEqual(2, len(self.receipt["routing"]))
        revisions = promoted._routing_revisions(root=ROOT, manifest_path=MANIFEST)
        curriculum = promoted._json(ROOT / "assets/data/curriculum_manifest.json")
        for item in self.receipt["routing"]:
            with self.subTest(id=item["id"]):
                actual = curriculum[item["map"]][item["id"]]
                self.assertEqual(item["after"], actual)
                self.assertTrue(promoted._require_reviewed_routing_revision(
                    map_name=item["map"], ident=item["id"], before=item["before"],
                    after=actual, revisions=revisions,
                ))
                with self.assertRaisesRegex(promoted.PromotedBatchError, "stale routing revision"):
                    promoted._require_reviewed_routing_revision(
                        map_name=item["map"], ident=item["id"], before=item["before"],
                        after={**actual, "courseUnitId": "unreviewed_destination"},
                        revisions=revisions,
                    )

    def test_reconciliation_never_grants_human_approval(self):
        self.assertEqual("pending", self.receipt["humanReviewStatus"])
        for field in ("approvalAdded", "rightsAdded", "frozenDraftsModified"):
            self.assertIs(False, self.receipt[field])

    def test_smalltalk_copy_keeps_the_published_route_and_native_review_gate(self):
        evidence = self.receipt["copyReview"]
        authority = promoted._json(ROOT / "assets/data/can_do_content_authorities.json")
        current = next(r for r in authority["coverage"]["smalltalkRoutingAudit"]["phraseDecisions"]
                       if r["phraseId"] == evidence["id"])
        before = evidence["previousDecision"]
        for key in before:
            if key != "phraseFingerprintSha256":
                self.assertEqual(before[key], current[key], key)
        self.assertEqual("nativeReviewRequired", current["copyReviewStatus"])
        self.assertEqual(before["phraseFingerprintSha256"], current["previousPhraseFingerprintSha256"])
        self.assertNotEqual(before["phraseFingerprintSha256"], current["phraseFingerprintSha256"])
        self.assertEqual("pending", evidence["humanReviewStatus"])


if __name__ == "__main__":
    unittest.main()
