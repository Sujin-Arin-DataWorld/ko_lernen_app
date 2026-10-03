"""Exact successor amendments cannot replace original review evidence."""
import copy
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
import reconcile_promoted_copy_revisions as reconcile
import validate_promoted_batch as promoted

COMMIT = "6f45199ca" + "0" * 31


class PromotedCopySuccessorTest(unittest.TestCase):
    def fixture(self, *, mutate=None, drift_original=False):
        before = dict(id="vocab_a1_demo", level="A1", korean="학교", example_korean="학교에 가요.")
        main = {**before, "example_korean": "학교에서 공부해요."}
        latest = {**main, "example_korean": "학교에서 한국어를 배워요."}
        original = reconcile.successor_entry("drafts/manifest.json", "vocab", before, main, None,
            source_commit=COMMIT, source_path="assets/data/korean_vocab.csv")
        original.pop("predecessorSuccessorSha256")
        amendment = reconcile.successor_entry("drafts/manifest.json", "vocab", main, latest, original,
            source_commit=COMMIT, source_path="assets/data/korean_vocab.csv")
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = root / "drafts/manifest.json"
            manifest.parent.mkdir(parents=True)
            manifest.write_text(json.dumps(dict(artifacts=[
                dict(kind="vocab", draft="drafts/vocab.csv")
            ])), encoding="utf-8")
            source = root / "assets/data/korean_vocab.csv"
            source.parent.mkdir(parents=True)
            source.write_text("fixture", encoding="utf-8")
            original_path = root / promoted.EDITORIAL_SUCCESSOR_LEDGER
            original_path.parent.mkdir(parents=True)
            gates = dict(schemaVersion=1, reviewStatus="MODEL_REVIEW_ONLY",
                humanApprovalClaim=False, humanReviewStatus="required_before_native-quality-claim")
            original_bytes = (json.dumps({**gates, "entries": [original]}) + "\n").encode("utf-8")
            original_path.write_bytes(original_bytes)
            copy_path = root / promoted.COPY_REVISION_LEDGER
            copy_bytes = b'{"originalApproval":"Jin","pendingHumanGate":true}\n'
            copy_path.write_bytes(copy_bytes)
            payload = {**gates, "entries": [amendment], "predecessorGitCommit": COMMIT,
                "predecessorLedgerSha256": hashlib.sha256(original_bytes).hexdigest(),
                "copyRevisionLedgerSha256": hashlib.sha256(copy_bytes).hexdigest()}
            if mutate:
                mutate(payload)
            if drift_original:
                original_path.write_bytes(original_bytes + b"\n")
            (root / promoted.EDITORIAL_SUCCESSOR_AMENDMENT_LEDGER).write_text(
                json.dumps(payload), encoding="utf-8")
            result = promoted._editorial_successors(root=root, manifest_path=manifest)
            self.assertEqual(original_bytes, original_path.read_bytes())
            self.assertEqual(copy_bytes, copy_path.read_bytes())
            return result, before, main, latest

    def test_amendment_resolves_to_original_review_and_expires_on_live_drift(self):
        entries, before, main, latest = self.fixture()
        key = ("vocab", before["id"])
        self.assertEqual(before, promoted._editorial_predecessor(*key, latest, entries))
        with self.assertRaisesRegex(promoted.PromotedBatchError, "stale editorial successor"):
            promoted._editorial_predecessor(*key, {**latest, "example_korean": "미등록 문장"}, entries)
        draft = {**before, "example_korean": "승인되지 않은 옛 문장"}
        with self.assertRaisesRegex(promoted.PromotedBatchError, "stale promoted copy revision"):
            promoted._require_reviewed_copy_revision(kind=key[0], ident=key[1], draft=draft,
                live=promoted._editorial_predecessor(*key, latest, entries),
                revisions={key: dict(level="a1", fields=["example_korean"],
                    beforeSha256=promoted._fingerprint(draft), afterSha256="wrong")},
                batch_revisions={})

    def test_chain_or_frozen_evidence_drift_is_rejected(self):
        def replace_before(payload):
            row = payload["entries"][0]
            row["before"]["example_korean"] = "A different predecessor"
            row["beforeSha256"] = promoted._fingerprint(row["before"])
        for mutate in (
            replace_before,
            lambda p: p["entries"][0].update(predecessorSuccessorSha256="0" * 64),
            lambda p: p["entries"][0].update(sourceGitCommit="1" * 40),
            lambda p: p.update(humanApprovalClaim=True),
        ):
            with self.subTest(mutate=mutate), self.assertRaises(promoted.PromotedBatchError):
                self.fixture(mutate=mutate)
        with self.assertRaisesRegex(promoted.PromotedBatchError, "frozen predecessor ledger"):
            self.fixture(drift_original=True)

    def test_an_existing_headword_revision_does_not_authorize_another_edit(self):
        before = dict(id="vocab_a1_demo", level="A1", korean="학교", example_korean="학교에 가요.")
        main = {**before, "korean": "교실"}
        original = dict(before=before, after=main)
        for field in ("korean", "level", "pack_id"):
            with self.subTest(field=field), self.assertRaisesRegex(ValueError, "non-copy"):
                reconcile.successor_entry("drafts/manifest.json", "vocab", main,
                    {**main, field: "unregistered"}, original,
                    source_commit=COMMIT, source_path="assets/data/korean_vocab.csv")
        with self.assertRaisesRegex(ValueError, "predecessor successor"):
            reconcile.successor_entry("drafts/manifest.json", "vocab", before,
                {**before, "example_korean": "새 문장"}, original,
                source_commit=COMMIT, source_path="assets/data/korean_vocab.csv")


if __name__ == "__main__":
    unittest.main()
