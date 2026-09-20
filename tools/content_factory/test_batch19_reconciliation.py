"""Guard quiz meaning and distinguish exact copy repair from scenario retirement."""
import copy
import hashlib
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import relevel_ledger
import scenario_store
import validate_promoted_batch as promoted

MANIFEST = ROOT / "tools/content_factory/drafts/batch_19_manifest.json"
RECEIPT = ROOT / "tools/content_factory/review/batch_19_reconciliation_20260917.json"


def records(path, kind):
    if path.suffix == ".csv":
        return promoted._csv(path)[1]
    return promoted._json(path)[promoted.TARGETS[kind][1]]


class Batch19ReconciliationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.grammar = {r["id"]: r for r in promoted._csv(ROOT / "assets/data/grammar.csv")[1]}

    def test_polite_requests_cannot_be_each_others_wrong_answer(self):
        pair = ("grammar_b1_soft_request", "grammar_b1_soft_request_batch19")
        for ident, alternative in (pair, pair[::-1]):
            with self.subTest(id=ident):
                row = self.grammar[ident]
                self.assertNotIn(alternative, row["quiz_distractor_ids"].split("|"))
                self.assertIn("Zeitplan", row["example_german"])
                self.assertNotIn("Termin", row["example_german"])

    def test_causal_focus_and_note_do_not_teach_an_absolute_prohibition(self):
        row = self.grammar["grammar_b1_reason_context"]
        self.assertEqual("B2", row["level"])
        self.assertNotIn("grammar_b2_according_to", row["quiz_distractor_ids"].split("|"))
        self.assertTrue(row["quiz_focus_en"].endswith(", so"))
        self.assertIn("Meist", row["note"])
        self.assertIn("usually", row["note_en"])
        self.assertNotIn("does not fit", row["note_en"])

    def test_all_reviewed_grammar_choices_keep_current_level_and_visible_focus(self):
        for ident in ("grammar_a2_available_if", "grammar_b1_soft_request",
                      "grammar_b1_soft_request_batch19", "grammar_b1_reason_context"):
            with self.subTest(id=ident):
                row = self.grammar[ident]
                options = row["quiz_distractor_ids"].split("|")
                self.assertEqual(3, len(set(options)))
                self.assertNotIn(ident, options)
                for option in options:
                    self.assertEqual(row["level"], self.grammar[option]["level"])
                self.assertIn(row["quiz_focus_de"], row["example_german"])
                self.assertIn(row["quiz_focus_en"], row["example_en"])

    def test_ten_exact_revisions_reject_unreviewed_copy_and_preserve_relevel(self):
        receipt = promoted._json(RECEIPT)
        manifest = promoted._json(MANIFEST)
        self.assertEqual(10, len(receipt["rows"]))
        levels = relevel_ledger.load_ledger(ROOT / "tools/content_factory/relevel_ledger.json")
        revisions = promoted._copy_revisions(root=ROOT, manifest_path=MANIFEST)
        for item in receipt["rows"]:
            kind, ident = item["kind"], item["id"]
            artifact = next(a for a in manifest["artifacts"] if a["kind"] == kind)
            draft = next(r for r in records(ROOT / artifact["draft"], kind) if r["id"] == ident)
            live = next(r for r in records(ROOT / "assets/data" / promoted.TARGETS[kind][0], kind) if r["id"] == ident)
            compared = promoted._relevel_normalized_live(kind, ident, live, draft, levels)
            with self.subTest(id=ident):
                self.assertEqual(item["beforeSha256"], promoted._fingerprint(draft))
                self.assertEqual(item["actualAfterSha256"], promoted._fingerprint(live))
                self.assertEqual(item["comparisonAfterSha256"], promoted._fingerprint(compared))
                self.assertTrue(promoted._require_reviewed_copy_revision(
                    kind=kind, ident=ident, draft=draft, live=compared,
                    revisions=revisions, batch_revisions={},
                ))
                changed = copy.deepcopy(compared)
                field = {"vocab": "example_english", "grammar": "example_en", "cloze": "en", "satz": "promptEn"}[kind]
                changed[field] = "An unreviewed change."
                with self.assertRaises(promoted.PromotedBatchError):
                    promoted._require_reviewed_copy_revision(
                        kind=kind, ident=ident, draft=draft, live=changed,
                        revisions=revisions, batch_revisions={},
                    )
                for track in item["historyTracks"].values():
                    self.assertTrue(track["historyComplete"])
                    self.assertEqual([], track["unparsedSnapshots"])

    def test_retired_scenarios_are_preserved_and_do_not_reappear_as_live_refs(self):
        receipt = promoted._json(RECEIPT)
        frozen = {r["id"]: r for r in records(ROOT / "tools/content_factory/drafts/batch19_scenario.json", "scenario")}
        live_ids = {r["id"] for r in scenario_store.load_root(ROOT / "assets/data")["scenarios"]}
        retired = promoted._json(ROOT / "tools/content_factory/relevel/canonical_120_v1_retired_seeds.json")
        pairs = {(r["clusterId"], r["seedId"]) for r in retired["retiredClusterSeeds"]}
        self.assertEqual(set(frozen), {r["id"] for r in receipt["retirements"]["rows"]})
        for item in receipt["retirements"]["rows"]:
            ident = item["id"]
            with self.subTest(id=ident):
                self.assertEqual(item["preservedSha256"], promoted._fingerprint(frozen[ident]))
                self.assertEqual(item["preservedSha256"], item["beforeRemovalSha256"])
                self.assertNotIn(ident, live_ids)
                self.assertIn((item["clusterId"], item["seedId"]), pairs)
                for path in ("can_do_segments.json", "can_do_content_authorities.json"):
                    self.assertNotIn(ident, (ROOT / "assets/data" / path).read_text(encoding="utf-8"))
                if ident.startswith("b1_"):
                    self.assertEqual(item["initialPromotionSha256"], item["preservedSha256"])
                else:
                    self.assertNotEqual(item["initialPromotionSha256"], item["preservedSha256"])
        self.assertIsNone(receipt["retirements"]["oneToOneSuccessorMap"])
        self.assertEqual("not_executed", receipt["retirements"]["physicalDeviceMigrationVerification"])

    def test_frozen_evidence_and_other_batch_approval_are_not_rewritten(self):
        receipt = promoted._json(RECEIPT)
        self.assertEqual("pending", receipt["humanReviewStatus"])
        for key in ("approvalAdded", "rightsAdded", "frozenDraftsModified"):
            self.assertIs(False, receipt[key])
        for item in receipt["frozenFiles"]:
            self.assertEqual(item["sha256"], hashlib.sha256((ROOT / item["path"]).read_bytes()).hexdigest())
        related = receipt["relatedCorrections"][0]
        self.assertEqual("grammar_b1_soft_request", related["id"])
        self.assertFalse(related["revisionRegistered"])
        self.assertEqual("pending", related["historicalReviewStatus"])
        revisions = promoted._copy_revisions(root=ROOT, manifest_path=ROOT / related["manifest"])
        self.assertNotIn(("grammar", related["id"]), revisions)

    def test_strict_promotion_gate_still_reports_retired_live_records(self):
        levels = relevel_ledger.load_ledger(ROOT / "tools/content_factory/relevel_ledger.json")
        with self.assertRaisesRegex(promoted.PromotedBatchError, "scenario: 'a1_register_first_day_choice' is missing from live assets"):
            promoted.validate(MANIFEST, root=ROOT, ledger=levels)


if __name__ == "__main__":
    unittest.main()
