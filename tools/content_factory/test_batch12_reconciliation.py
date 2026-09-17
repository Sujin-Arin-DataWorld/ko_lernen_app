"""Protect meaning and historical evidence without waiving Batch 12's open gates."""
import copy
import csv
import hashlib
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import relevel_ledger
import validate_promoted_batch as promoted

MANIFEST = ROOT / "tools/content_factory/drafts/batch_12_manifest.json"
RECEIPT = ROOT / "tools/content_factory/review/batch_12_reconciliation_20260917.json"


class Batch12ReconciliationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.phrases = {r["id"]: r for r in promoted._json(ROOT / "assets/data/smalltalk.json")["phrases"]}

    def test_observation_and_inference_are_not_bare_assertions(self):
        for ident in ("smalltalk_c2_0026", "smalltalk_c1_0030"):
            with self.subTest(id=ident):
                row = self.phrases[ident]
                self.assertIn("더라고요", row["ko"])
                self.assertIn("I've found", row["en"])
                self.assertRegex(row["de"], r"Ich habe (festgestellt|gemerkt)")
        reply = self.phrases["smalltalk_c2_0029"]["reply"]
        self.assertIn("Mir ist aufgefallen", reply["de"])
        self.assertIn("I realized", reply["en"])
        follow = self.phrases["smalltalk_c1_0027"]["followUp"]
        self.assertIn("dürfte", follow["de"])
        self.assertIn("probably", follow["en"])

    def test_missing_information_does_not_assert_absence_of_remedy_or_deadline(self):
        remedy = self.phrases["smalltalk_c2_0026"]["followUp"]
        self.assertIn("판단하기", remedy["ko"])
        self.assertIn("beurteilen", remedy["de"])
        self.assertIn("judge", remedy["en"])
        deadline = self.phrases["smalltalk_c2_0027"]["followUp"]
        self.assertIn("기한을 모르면", deadline["ko"])
        self.assertIn("Frist nicht kennt", deadline["de"])
        self.assertIn("don't know the deadline", deadline["en"])

    def test_copy_keeps_emphasis_worry_and_close_friend_address(self):
        sample = self.phrases["smalltalk_c1_0025"]
        self.assertNotIn("영상 주장은", sample["ko"])
        self.assertNotIn("weitreichend", sample["reply"]["de"])
        self.assertNotIn("sweeping", sample["reply"]["en"])
        workload = self.phrases["smalltalk_c1_0029"]
        self.assertIn("wechseln sich", workload["de"])
        self.assertIn("Sorgen", workload["followUp"]["de"])
        self.assertIn("worried", workload["followUp"]["en"])
        friend = self.phrases["smalltalk_c2_0029"]
        self.assertEqual("close_friend", friend["relationshipContext"])
        self.assertIn("deiner Meinung nach", friend["de"])
        self.assertNotIn("Sie", friend["safeAlternativeQuestions"][0]["de"])

    def test_original_promotion_delta_and_history_gaps_are_not_erased(self):
        receipt = promoted._json(RECEIPT)
        self.assertEqual(10, len(receipt["rows"]))
        initial = {r["id"]: r["initialPromotionDelta"] for r in receipt["rows"] if r["initialPromotionDelta"]}
        self.assertEqual({"smalltalk_c2_0025", "smalltalk_c2_0026"}, set(initial))
        for delta in initial.values():
            self.assertEqual({"category": {"before": "daily", "after": "phone"}}, delta)
        self.assertEqual(3, len(receipt["broaderHistoryGaps"]))
        self.assertEqual("unresolved", receipt["approvalChronology"]["status"])
        for row in receipt["rows"]:
            for track in row["historyTracks"].values():
                self.assertTrue(track["historyComplete"])
                self.assertEqual([], track["unparsedSnapshots"])

    def test_registered_row_receipts_reject_unreviewed_followup_changes(self):
        receipt = promoted._json(RECEIPT)
        manifest = promoted._json(MANIFEST)
        levels = relevel_ledger.load_ledger(ROOT / "tools/content_factory/relevel_ledger.json")
        revisions = promoted._copy_revisions(root=ROOT, manifest_path=MANIFEST)
        paths = {"smalltalk": ("assets/data/smalltalk.json", "phrases"),
                 "cloze": ("assets/data/cloze.json", "items"),
                 "satz": ("assets/data/satz_sentences.json", "items")}
        self.assertEqual(8, sum(item["revisionRegistered"] for item in receipt["rows"]))
        for ident in ("smalltalk_c2_0025", "smalltalk_c2_0026"):
            self.assertNotIn(("smalltalk", ident), revisions)
        for item in receipt["rows"]:
            kind, ident = item["kind"], item["id"]
            artifact = next(a for a in manifest["artifacts"] if a["kind"] == kind)
            path, key = paths[kind]
            draft = next(r for r in promoted._json(ROOT / artifact["draft"])[key] if r["id"] == ident)
            live = next(r for r in promoted._json(ROOT / path)[key] if r["id"] == ident)
            compared = promoted._relevel_normalized_live(kind, ident, live, draft, levels)
            with self.subTest(id=ident):
                self.assertEqual(item["beforeSha256"], promoted._fingerprint(draft))
                self.assertEqual(item["actualAfterSha256"], promoted._fingerprint(live))
                if item["revisionRegistered"]:
                    self.assertTrue(promoted._require_reviewed_copy_revision(
                        kind=kind, ident=ident, draft=draft, live=compared,
                        revisions=revisions, batch_revisions={},
                    ))
                changed = copy.deepcopy(compared)
                changed["en" if kind != "satz" else "promptEn"] = "An unreviewed change."
                if item["revisionRegistered"]:
                    with self.assertRaises(promoted.PromotedBatchError):
                        promoted._require_reviewed_copy_revision(
                            kind=kind, ident=ident, draft=draft, live=changed,
                            revisions=revisions, batch_revisions={},
                        )
                else:
                    self.assertFalse(promoted._require_reviewed_copy_revision(
                        kind=kind, ident=ident, draft=draft, live=changed,
                        revisions=revisions, batch_revisions={},
                    ))

    def test_personal_criticism_derivatives_stay_aligned_with_vocabulary(self):
        cloze = next(r for r in promoted._json(ROOT / "assets/data/cloze.json")["items"] if r["id"] == "cloze_c2_0219")
        satz = next(r for r in promoted._json(ROOT / "assets/data/satz_sentences.json")["items"] if r["id"] == "satz_c2_0221")
        with (ROOT / "assets/data/korean_vocab.csv").open(encoding="utf-8-sig", newline="") as stream:
            vocab = next(r for r in csv.DictReader(stream) if r["id"] == "vocab_c2_0215")
        self.assertEqual("비난", cloze["answer"])
        self.assertEqual(cloze["answer"], satz["vocabKo"])
        for c, s, v in (("fullKo", "targetKo", "example_korean"),
                        ("de", "promptDe", "example_german"), ("en", "promptEn", "example_english")):
            self.assertEqual(cloze[c], satz[s])
            self.assertEqual(cloze[c], vocab[v])
        self.assertEqual(cloze["fullKo"], cloze["sentenceKo"].replace("＿＿＿", cloze["answer"]))

    def test_frozen_records_and_unresolved_batch_gate_stay_closed(self):
        receipt = promoted._json(RECEIPT)
        self.assertEqual("pending", receipt["humanReviewStatus"])
        self.assertEqual("unresolved", receipt["curriculumReviewStatus"])
        self.assertGreater(len(receipt["unresolvedCurriculum"]), 0)
        for key in ("approvalAdded", "rightsAdded", "frozenDraftsModified"):
            self.assertIs(False, receipt[key])
        for item in receipt["frozenFiles"]:
            self.assertEqual(item["sha256"], hashlib.sha256((ROOT / item["path"]).read_bytes()).hexdigest())
        levels = relevel_ledger.load_ledger(ROOT / "tools/content_factory/relevel_ledger.json")
        with self.assertRaisesRegex(promoted.PromotedBatchError, "smalltalk:smalltalk_c2_0025"):
            promoted.validate(MANIFEST, root=ROOT, ledger=levels)


if __name__ == "__main__":
    unittest.main()
