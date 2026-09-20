"""Keep kinship, honorific meaning and exact historical revisions intact."""
import csv
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import relevel_ledger
import validate_promoted_batch as promoted

MANIFEST = ROOT / "tools/content_factory/drafts/batch_07_partner_family_manifest.json"
RECEIPT = ROOT / "tools/content_factory/review/batch_07_grammar_reconciliation_20260916.json"


class Batch07GrammarReconciliationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with (ROOT / "assets/data/grammar.csv").open(encoding="utf-8-sig", newline="") as stream:
            cls.live = {row["id"]: row for row in csv.DictReader(stream)}

    def test_translations_keep_the_korean_family_relationship(self):
        relatives = {
            "grammar_a1_honorific_kke": ("장인어른", "Vater meiner Frau", "wife's father"),
            "grammar_a2_humble_give": ("할머니", "Großmutter", "grandmother"),
            "grammar_b1_honorific_subject_kkeyseo": ("시어머니", "Mutter meines Mannes", "husband's mother"),
        }
        for ident, (ko, de, en) in relatives.items():
            with self.subTest(id=ident):
                row = self.live[ident]
                self.assertIn(ko, row["example_korean"])
                self.assertIn(de, row["example_german"])
                self.assertIn(en, row["example_en"])
                self.assertIn(row["quiz_focus_de"], row["example_german"])
                self.assertIn(row["quiz_focus_en"], row["example_en"])

    def test_subject_honorific_forms_are_not_each_others_wrong_answer(self):
        pair = ("grammar_b1_honorific_si", "grammar_b1_honorific_subject_kkeyseo")
        for ident, alternative in (pair, pair[::-1]):
            with self.subTest(id=ident):
                row = self.live[ident]
                self.assertEqual("true", row["quiz_enabled"])
                options = row["quiz_distractor_ids"].split("|")
                self.assertEqual(3, len(set(options)))
                self.assertNotIn(alternative, options)
                for option in options:
                    self.assertEqual(row["level"], self.live[option]["level"])

    def test_honorific_explanations_do_not_conflate_subject_and_recipient(self):
        subject = self.live["grammar_b1_honorific_si"]
        benefit = self.live["grammar_a2_humble_give"]
        for field in ("explanation_de", "explanation_en"):
            self.assertNotIn("에게", subject[field])
        self.assertNotIn("the speaker", benefit["explanation_en"])
        self.assertNotIn("sprechende Person", benefit["explanation_de"])
        self.assertNotIn("Do not mix", benefit["note_en"])
        self.assertIn("따라 주다", benefit["note_en"])
        self.assertIn("따라 드리다", benefit["note_en"])

    def test_comparison_focus_includes_the_action_and_quote_keeps_telling(self):
        row = self.live["grammar_b2_rather_than_direct"]
        self.assertIn("“다음에 말씀드릴게요.”라고", row["example_korean"])
        self.assertIn("거절하기보다", row["example_korean"])
        self.assertIn("abzulehnen", row["quiz_focus_de"])
        self.assertIn("refusing", row["quiz_focus_en"])
        self.assertIn("beim nächsten Mal", row["example_german"])
        self.assertIn("next time", row["example_en"])
        self.assertNotIn("explain", row["example_en"])
        self.assertNotIn("erkl", row["example_german"])

    def test_family_example_names_the_remark_in_all_languages(self):
        row = self.live["grammar_c1_family_framing"]
        self.assertIn("“우리 며느리”", row["example_korean"])
        self.assertNotIn("그 말은", row["example_korean"])
        self.assertNotIn("Rahmen", row["example_german"])
        self.assertNotIn("frame says", row["example_en"])
        for example, focus in (("example_german", "quiz_focus_de"), ("example_en", "quiz_focus_en")):
            self.assertIn(row[focus], row[example])
        self.assertIn("Willkommens", row["quiz_focus_de"])
        self.assertIn("welcome", row["quiz_focus_en"])

    def test_regardless_quiz_excludes_equivalent_and_preserves_proposal(self):
        row = self.live["grammar_c2_regardless_of_kin"]
        self.assertNotIn("grammar_c2_regardless_of", row["quiz_distractor_ids"].split("|"))
        self.assertIn("하자고", row["example_korean"])
        self.assertIn("schlug ich vor", row["example_german"])
        self.assertIn("suggested", row["example_en"])
        self.assertNotIn("asked", row["example_en"])

    def test_six_exact_revisions_reject_any_unreviewed_content(self):
        receipt = json.loads(RECEIPT.read_text(encoding="utf-8"))
        self.assertEqual(6, len(receipt["rows"]))
        levels = relevel_ledger.load_ledger(ROOT / "tools/content_factory/relevel_ledger.json")
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        artifact = next(a for a in manifest["artifacts"] if a["kind"] == "grammar")
        _, drafts = promoted._csv(ROOT / artifact["draft"])
        drafts = {row["id"]: row for row in drafts}
        revisions = promoted._copy_revisions(root=ROOT, manifest_path=MANIFEST)
        for item in receipt["rows"]:
            ident = item["id"]
            with self.subTest(id=ident):
                draft, live = drafts[ident], self.live[ident]
                compared = promoted._relevel_normalized_live("grammar", ident, live, draft, levels)
                self.assertEqual(item["beforeSha256"], promoted._fingerprint(draft))
                self.assertEqual(item["actualAfterSha256"], promoted._fingerprint(live))
                self.assertEqual(item["comparisonAfterSha256"], promoted._fingerprint(compared))
                self.assertTrue(promoted._require_reviewed_copy_revision(
                    kind="grammar", ident=ident, draft=draft, live=compared,
                    revisions=revisions, batch_revisions={},
                ))
                with self.assertRaises(promoted.PromotedBatchError):
                    promoted._require_reviewed_copy_revision(
                        kind="grammar", ident=ident, draft=draft,
                        live={**compared, "example_en": "An unreviewed translation."},
                        revisions=revisions, batch_revisions={},
                    )
        extra = receipt["relatedCorrections"]
        self.assertEqual(["grammar_b1_honorific_si"], [r["id"] for r in extra])
        self.assertEqual(extra[0]["actualAfterSha256"], promoted._fingerprint(self.live[extra[0]["id"]]))
        self.assertIsNone(extra[0]["manifest"])

    def test_frozen_files_and_human_gates_remain_unchanged(self):
        import hashlib
        receipt = json.loads(RECEIPT.read_text(encoding="utf-8"))
        self.assertEqual("pending", receipt["humanReviewStatus"])
        for key in ("approvalAdded", "rightsAdded", "frozenDraftsModified"):
            self.assertIs(False, receipt[key])
        for entry in receipt["frozenFiles"]:
            self.assertEqual(entry["sha256"], hashlib.sha256((ROOT / entry["path"]).read_bytes()).hexdigest())
        # Correcting grammar is not permission to waive the other Batch 07 drift.
        levels = relevel_ledger.load_ledger(ROOT / "tools/content_factory/relevel_ledger.json")
        with self.assertRaisesRegex(promoted.PromotedBatchError, "vocab:vocab_a1_0213"):
            promoted.validate(MANIFEST, root=ROOT, ledger=levels)


if __name__ == "__main__":
    unittest.main()
