"""Copy reconciliation stays exact and cannot authorize a new semantic route."""
import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
import reconcile_promoted_copy_revisions as reconcile
import validate_promoted_batch as promoted


class PromotedCopySuccessorTest(unittest.TestCase):
    def test_new_copy_is_exact_and_expires_on_a_later_unrecorded_edit(self):
        draft = {"id": "vocab_a1_demo", "level": "A1", "korean": "학교", "example_korean": "학교에 가요."}
        live = {**draft, "example_korean": "학교에서 공부해요."}
        entry = reconcile.successor_entry("manifest.json", "vocab", draft, live, None, {})
        self.assertTrue(promoted._require_reviewed_copy_revision(
            kind="vocab", ident=draft["id"], draft=draft, live=live,
            revisions={("vocab", draft["id"]): entry}, batch_revisions={}))
        with self.assertRaises(promoted.PromotedBatchError):
            promoted._require_reviewed_copy_revision(
                kind="vocab", ident=draft["id"], draft=draft,
                live={**live, "example_korean": "학교가 멀어요."},
                revisions={("vocab", draft["id"]): entry}, batch_revisions={})
        for field in ("level", "korean", "pack_id"):
            with self.subTest(field=field), self.assertRaisesRegex(ValueError, "non-copy"):
                reconcile.successor_entry("manifest.json", "vocab", draft,
                                          {**live, field: "changed"}, None, {})

    def test_previous_headword_revision_does_not_authorize_another_headword_edit(self):
        draft = {"id": "vocab_demo", "level": "A1", "korean": "값", "example_korean": "값이 비싸요."}
        prior = {**draft, "korean": "가격", "example_korean": "가격이 비싸요."}
        previous = {"fields": ["korean", "example_korean"]}
        self.assertIsNotNone(reconcile.successor_entry(
            "manifest.json", "vocab", draft, prior, previous, {}, predecessor=prior))
        with self.assertRaisesRegex(ValueError, "non-copy"):
            reconcile.successor_entry(
                "manifest.json", "vocab", draft, {**prior, "korean": "돈"},
                previous, {}, predecessor=prior)

    def test_batch_approval_and_prior_receipts_are_preserved_without_expansion(self):
        draft = {"id": "vocab_demo", "level": "A1", "romanization": "before", "example_english": "before"}
        live = {**draft, "romanization": "after", "example_english": "after"}
        batch = {("vocab", "romanization"): {"approval": {"authority": "Jin"}}}
        frozen = copy.deepcopy(batch)
        entry = reconcile.successor_entry("manifest.json", "vocab", draft, live, None, batch)
        self.assertEqual(["example_english"], entry["fields"])
        self.assertEqual(promoted._fingerprint({**live, "romanization": "before"}), entry["afterSha256"])
        self.assertEqual(frozen, batch)
        entry["reviewReceipt"] = "historical_receipt.json"
        changed = reconcile.successor_entry("manifest.json", "vocab", draft,
                                            {**live, "example_english": "next"}, entry, batch)
        self.assertEqual(entry["reviewReceipt"], changed["reviewReceipt"])
        self.assertNotIn("approval", changed)


if __name__ == "__main__":
    unittest.main()
