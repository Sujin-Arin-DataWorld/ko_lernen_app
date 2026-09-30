"""Reconcile one historical category route without moving published progress."""
import hashlib
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import relevel_ledger
import validate_promoted_batch as promoted

MANIFEST = ROOT / "tools/content_factory/drafts/batch_18_manifest.json"
RECEIPT = ROOT / "tools/content_factory/review/batch_18_routing_reconciliation_20260917.json"


class Batch18RoutingReconciliationTest(unittest.TestCase):
    def test_real_132_record_batch_validates(self):
        levels = relevel_ledger.load_ledger(ROOT / "tools/content_factory/relevel_ledger.json")
        count, _ = promoted.validate(MANIFEST, root=ROOT, ledger=levels)
        self.assertEqual(132, count)

    def test_only_the_exact_recorded_route_is_accepted(self):
        receipt = promoted._json(RECEIPT)
        manifest = promoted._json(MANIFEST)
        rule = next(r for r in manifest["smalltalkCategoryMappings"]
                    if r["level"] == "c2" and r["category"] == "job_hunting")
        before = {key: rule[key] for key in ("courseUnitId", "conceptIds")}
        after = promoted._json(ROOT / "assets/data/curriculum_manifest.json")["smalltalkCategoryUnitMap"]["c2:job_hunting"]
        self.assertEqual(before, receipt["before"])
        self.assertEqual(after, receipt["after"])
        revisions = promoted._routing_revisions(root=ROOT, manifest_path=MANIFEST)
        self.assertEqual({("smalltalkCategoryUnitMap", "c2:job_hunting")}, set(revisions))
        self.assertTrue(promoted._require_reviewed_routing_revision(
            map_name="smalltalkCategoryUnitMap", ident="c2:job_hunting",
            before=before, after=after, revisions=revisions,
        ))
        for changed in ({**after, "courseUnitId": "unreviewed_unit"},
                        {**after, "conceptIds": ["unreviewed_concept"]}):
            with self.subTest(changed=changed), self.assertRaises(promoted.PromotedBatchError):
                promoted._require_reviewed_routing_revision(
                    map_name="smalltalkCategoryUnitMap", ident="c2:job_hunting",
                    before=before, after=changed, revisions=revisions,
                )
        self.assertFalse(promoted._require_reviewed_routing_revision(
            map_name="smalltalkCategoryUnitMap", ident="c2:another_category",
            before=before, after=after, revisions=revisions,
        ))

    def test_existing_cando_ownership_and_phrase_content_stay_intact(self):
        receipt = promoted._json(RECEIPT)
        phrases = {r["id"]: r for r in promoted._json(ROOT / "assets/data/smalltalk.json")["phrases"]}
        authority = promoted._json(ROOT / "assets/data/can_do_content_authorities.json")
        segments = promoted._json(ROOT / "assets/data/can_do_segments.json")
        for item in receipt["currentCategoryMembers"]:
            ident = item["id"]
            with self.subTest(id=ident):
                self.assertEqual(item["phraseSha256"], promoted._fingerprint(phrases[ident]))
                reference = next(r for r in authority["contentReferences"]
                                 if r["kind"] == "smalltalk" and r["id"] == ident)
                self.assertEqual(item["publishedAuthority"], reference)
                cluster_ids = [c["id"] for c in segments["contentClusters"]
                               if {"kind": "smalltalk", "id": ident} in c["contentReferences"]]
                self.assertEqual(item["publishedClusterIds"], cluster_ids)

    def test_no_original_approval_or_review_file_is_rewritten(self):
        receipt = promoted._json(RECEIPT)
        self.assertEqual("pending", receipt["humanReviewStatus"])
        for key in ("approvalAdded", "rightsAdded", "runtimeChanged", "frozenDraftsModified"):
            self.assertIs(False, receipt[key])
        for item in receipt["frozenFiles"]:
            self.assertEqual(item["sha256"], hashlib.sha256((ROOT / item["path"]).read_bytes()).hexdigest())


if __name__ == "__main__":
    unittest.main()
