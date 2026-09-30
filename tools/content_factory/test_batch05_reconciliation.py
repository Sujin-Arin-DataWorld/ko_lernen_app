"""Keep Batch 05 copy history exact without granting human approval."""
import copy
import json
from pathlib import Path
import unittest

import relevel_ledger
import validate_promoted_batch as promoted

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "tools/content_factory/drafts/batch_05_manifest.json"
RECEIPT = ROOT / "tools/content_factory/review/batch_05_reconciliation_20260916.json"


class Batch05ReconciliationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.receipt = json.loads(RECEIPT.read_text(encoding="utf-8"))
        cls.manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))

    def test_unreconciled_course_units_still_block_batch_promotion(self):
        levels = relevel_ledger.load_ledger(ROOT / "tools/content_factory/relevel_ledger.json")
        self.assertEqual("unresolved", self.receipt["curriculumReviewStatus"])
        self.assertEqual(4, len(self.receipt["unresolvedCurriculum"]))
        with self.assertRaisesRegex(promoted.PromotedBatchError, "curriculum courseUnits:"):
            promoted.validate(MANIFEST, root=ROOT, ledger=levels)

    def test_exact_receipts_reject_unreviewed_followup_changes(self):
        artifact = next(a for a in self.manifest["artifacts"] if a["kind"] == "smalltalk")
        drafts = {r["id"]: r for r in promoted._json(ROOT / artifact["draft"])["phrases"]}
        current = {r["id"]: r for r in promoted._json(ROOT / "assets/data/smalltalk.json")["phrases"]}
        revisions = promoted._copy_revisions(root=ROOT, manifest_path=MANIFEST)
        self.assertEqual(5, len(self.receipt["rows"]))
        for item in self.receipt["rows"]:
            ident = item["id"]
            with self.subTest(id=ident):
                draft, live = drafts[ident], current[ident]
                self.assertEqual(item["beforeSha256"], promoted._fingerprint(draft))
                self.assertEqual(item["actualAfterSha256"], promoted._fingerprint(live))
                self.assertTrue(promoted._require_reviewed_copy_revision(
                    kind="smalltalk", ident=ident, draft=draft, live=live,
                    revisions=revisions, batch_revisions={},
                ))
                changed = copy.deepcopy(live)
                changed["followUp"]["en"] = "An unreviewed change to the condition."
                with self.assertRaises(promoted.PromotedBatchError):
                    promoted._require_reviewed_copy_revision(
                        kind="smalltalk", ident=ident, draft=draft, live=changed,
                        revisions=revisions, batch_revisions={},
                    )

    def test_copy_preserves_semantic_decision_and_requires_native_review(self):
        self.assertEqual("pending", self.receipt["humanReviewStatus"])
        for key in ("approvalAdded", "rightsAdded", "frozenDraftsModified"):
            self.assertIs(False, self.receipt[key])
        evidence, = self.receipt["copyReview"]
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


if __name__ == "__main__":
    unittest.main()
