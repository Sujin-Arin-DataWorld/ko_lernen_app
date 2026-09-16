"""Keep exact historical evidence and reject known semantic alternate answers."""
import csv
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import validate_promoted_batch as promoted

RECEIPT = ROOT / "tools/content_factory/review/grammar_quiz_reconciliation_20260916.json"


class GrammarQuizReconciliationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.receipt = json.loads(RECEIPT.read_text(encoding="utf-8"))
        with (ROOT / "assets/data/grammar.csv").open(encoding="utf-8-sig", newline="") as stream:
            cls.live = {row["id"]: row for row in csv.DictReader(stream)}

    def test_original_review_and_current_rows_match_exact_revision_hashes(self):
        self.assertEqual(8, len(self.receipt["rows"]))
        for evidence in self.receipt["rows"]:
            with self.subTest(id=evidence["id"]):
                manifest_path = ROOT / evidence["manifest"]
                manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
                artifact = next(a for a in manifest["artifacts"] if a["kind"] == "grammar")
                _, rows = promoted._csv(ROOT / artifact["draft"])
                draft = next(r for r in rows if r["id"] == evidence["id"])
                live = self.live[evidence["id"]]
                revisions = promoted._copy_revisions(root=ROOT, manifest_path=manifest_path)
                self.assertEqual(evidence["beforeSha256"], promoted._fingerprint(draft))
                self.assertEqual(evidence["afterSha256"], promoted._fingerprint(live))
                self.assertTrue(promoted._require_reviewed_copy_revision(
                    kind="grammar", ident=live["id"], draft=draft, live=live,
                    revisions=revisions, batch_revisions={},
                ))
                # A receipt is an exact transition, never a field-wide waiver.
                with self.assertRaises(promoted.PromotedBatchError):
                    promoted._require_reviewed_copy_revision(
                        kind="grammar", ident=live["id"], draft=draft,
                        live={**live, "example_korean": live["example_korean"] + " 잘못된 추가."},
                        revisions=revisions, batch_revisions={},
                    )

    def test_semantic_alternatives_are_not_graded_as_wrong(self):
        forbidden = {
            "grammar_a2_permission_check_batch20": {"grammar_a2_permission"},
            "grammar_b1_conceded_context_batch20": {"grammar_b1_concede_but"},
            "grammar_b2_instead_supplement": {"grammar_b2_instead_tradeoff"},
            "grammar_b2_include_total_scope": {"grammar_b2_including_start", "grammar_b2_inclusion"},
        }
        for ident, alternatives in forbidden.items():
            with self.subTest(id=ident):
                self.assertTrue(alternatives.isdisjoint(self.live[ident]["quiz_distractor_ids"].split("|")))

    def test_receipt_never_claims_human_approval_or_rewrites_original_review(self):
        self.assertEqual("pending", self.receipt["humanReviewStatus"])
        self.assertIs(False, self.receipt["approvalAdded"])
        self.assertIs(False, self.receipt["rightsAdded"])
        self.assertIs(False, self.receipt["frozenDraftsModified"])


if __name__ == "__main__":
    unittest.main()
