"""Exact successor amendments cannot replace original review evidence."""
import copy
import csv
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
    def genesis_fixture(self, mutate=None, *, original_copy=False):
        draft = dict(id="cloze_c2_0264", level="c2", answer="충분조건",
            fullKo="충분조건이지만 필요조건은 아니다.", sentenceKo="＿＿＿이지만 필요조건은 아니다.",
            de="hinreichend", en="sufficient", distractors=["필요조건", "논리적 귀결", "단서 조항"])
        before = {**draft, "en": "sufficient condition"} if original_copy else copy.deepcopy(draft)
        after = {**before, "distractors": ["동치 조건", "논리적 귀결", "단서 조항"]}
        newer_commit = "8" * 40
        amendment = reconcile.successor_entry("drafts/manifest.json", "cloze", before, after, None,
            source_commit=newer_commit, source_path="assets/data/cloze.json")
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            artifact = dict(kind="cloze", draft="drafts/cloze.json", review="drafts/review.csv")
            manifest = root / "drafts/manifest.json"
            manifest.parent.mkdir(parents=True)
            manifest.write_text(json.dumps(dict(artifacts=[artifact])), encoding="utf-8")
            (root / artifact["draft"]).write_text(json.dumps(dict(items=[draft])), encoding="utf-8")
            review = dict(id=draft["id"], level="c2", ko=draft["fullKo"], de="hinreichend",
                en="sufficient", field_notes="rights: original_clean_room", 상태="approved", jin_memo="Original batch approval")
            with (root / artifact["review"]).open("w", encoding="utf-8", newline="") as handle:
                writer = csv.DictWriter(handle, fieldnames=promoted.REVIEW_HEADER)
                writer.writeheader()
                writer.writerow(review)
            amendment["genesisPredecessor"] = dict(sourceGitCommit=newer_commit,
                draft=artifact["draft"], review=artifact["review"],
                draftSha256=promoted._fingerprint(draft), reviewRowSha256=promoted._fingerprint(review))
            source = root / "assets/data/cloze.json"
            source.parent.mkdir(parents=True)
            source.write_text(json.dumps(dict(items=[before])), encoding="utf-8")
            gates = dict(schemaVersion=1, reviewStatus="MODEL_REVIEW_ONLY",
                humanApprovalClaim=False, humanReviewStatus="required_before_native-quality-claim")
            original = root / promoted.EDITORIAL_SUCCESSOR_LEDGER
            original.parent.mkdir(parents=True)
            original.write_text(json.dumps({**gates, "entries": []}), encoding="utf-8")
            copy_path = root / promoted.COPY_REVISION_LEDGER
            if original_copy:
                revision = dict(manifest="drafts/manifest.json", kind="cloze", id=draft["id"],
                    level="c2", fields=["en"], beforeSha256=promoted._fingerprint(draft),
                    afterSha256=promoted._fingerprint(before))
                copy_path.write_text(json.dumps(dict(schemaVersion=2,
                    humanReviewStatus="required_before_native-quality-claim",
                    manifests=["drafts/manifest.json"], entries=[revision])), encoding="utf-8")
                amendment["genesisPredecessor"]["copyRevisionSha256"] = promoted._fingerprint(revision)
            else:
                copy_path.write_text("{}", encoding="utf-8")
            payload = {**gates, "predecessorGitCommit": COMMIT, "entries": [amendment],
                "predecessorLedgerSha256": hashlib.sha256(original.read_bytes()).hexdigest(),
                "copyRevisionLedgerSha256": hashlib.sha256(copy_path.read_bytes()).hexdigest()}
            if mutate:
                mutate(payload, root, review)
            (root / promoted.EDITORIAL_SUCCESSOR_AMENDMENT_LEDGER).write_text(json.dumps(payload), encoding="utf-8")
            entries = promoted._editorial_successors(root=root, manifest_path=manifest)
            self.assertEqual(COMMIT, payload["predecessorGitCommit"])
            self.assertEqual(newer_commit, entries[("cloze", before["id"])]["sourceGitCommit"])
            return entries, before, after

    def test_later_batch_genesis_keeps_original_chain_anchor_and_frozen_review(self):
        entries, before, after = self.genesis_fixture()
        self.assertEqual(before, promoted._editorial_predecessor("cloze", before["id"], after, entries))
        with self.assertRaisesRegex(promoted.PromotedBatchError, "stale editorial successor"):
            promoted._editorial_predecessor("cloze", before["id"],
                {**after, "distractors": ["미등록", *after["distractors"][1:]]}, entries)

    def test_genesis_cannot_substitute_or_weaken_original_review(self):
        def mutate_review(payload, root, review):
            review["상태"] = "draft"
            with (root / "drafts/review.csv").open("w", encoding="utf-8", newline="") as handle:
                writer = csv.DictWriter(handle, fieldnames=promoted.REVIEW_HEADER)
                writer.writeheader()
                writer.writerow(review)
            payload["entries"][0]["genesisPredecessor"]["reviewRowSha256"] = promoted._fingerprint(review)
        def mutate_before(payload, root, review):
            row = payload["entries"][0]
            row["before"]["distractors"][0] = "다른 원본"
            row["beforeSha256"] = promoted._fingerprint(row["before"])
            row["genesisPredecessor"]["draftSha256"] = row["beforeSha256"]
        for mutate in (
            mutate_review, mutate_before,
            lambda p, r, v: p["entries"][0].pop("genesisPredecessor"),
            lambda p, r, v: p["entries"][0]["genesisPredecessor"].update(sourceGitCommit="9" * 40),
            lambda p, r, v: p["entries"][0]["genesisPredecessor"].update(review="drafts/other_review.csv"),
        ):
            with self.subTest(mutate=mutate), self.assertRaises(promoted.PromotedBatchError):
                self.genesis_fixture(mutate)

    def test_genesis_extends_the_exact_original_copy_revision(self):
        entries, before, after = self.genesis_fixture(original_copy=True)
        self.assertEqual(before, promoted._editorial_predecessor("cloze", before["id"], after, entries))

    def test_genesis_cannot_replace_original_copy_revision_or_revert_to_old_copy(self):
        def drift_revision(payload, root, review):
            path = root / promoted.COPY_REVISION_LEDGER
            ledger = json.loads(path.read_text(encoding="utf-8"))
            ledger["entries"][0]["afterSha256"] = "0" * 64
            path.write_text(json.dumps(ledger), encoding="utf-8")
            # Even a newly bound file checksum cannot make a stale row valid.
            payload["copyRevisionLedgerSha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
            payload["entries"][0]["genesisPredecessor"]["copyRevisionSha256"] = promoted._fingerprint(ledger["entries"][0])
        def substitute_predecessor(payload, root, review):
            row = payload["entries"][0]
            row["before"]["en"] = "unregistered wording"
            row["beforeSha256"] = promoted._fingerprint(row["before"])
        for mutate in (
            drift_revision, substitute_predecessor,
            lambda p, r, v: p["entries"][0]["genesisPredecessor"].pop("copyRevisionSha256"),
            lambda p, r, v: p["entries"][0]["genesisPredecessor"].update(copyRevisionSha256="0" * 64),
        ):
            with self.subTest(mutate=mutate), self.assertRaises(promoted.PromotedBatchError):
                self.genesis_fixture(mutate, original_copy=True)

    def test_actual_batch21_follow_up_resolves_through_frozen_original_review(self):
        root = Path(__file__).resolve().parents[2]
        manifest_path = root / "tools/content_factory/drafts/batch_21_theme_park_date_manifest.json"
        manifest = promoted._json(manifest_path)
        ident = "smalltalk_a2_0089"
        draft_ref = next(row["draft"] for row in manifest["artifacts"] if row["kind"] == "smalltalk")
        draft = next(row for row in promoted._json(root / draft_ref)["phrases"] if row["id"] == ident)
        live = next(row for row in promoted._json(root / "assets/data/smalltalk.json")["phrases"] if row["id"] == ident)
        successors = promoted._editorial_successors(root=root, manifest_path=manifest_path)
        previous = promoted._editorial_predecessor("smalltalk", ident, live, successors)
        self.assertNotEqual(draft, previous)
        self.assertTrue(promoted._require_reviewed_copy_revision(kind="smalltalk", ident=ident,
            draft=promoted._promotion_projection("smalltalk", draft), live=previous,
            revisions=promoted._copy_revisions(root=root, manifest_path=manifest_path),
            batch_revisions=promoted._batch_field_revisions(root=root)))
        self.assertEqual("If we get permission, let's take the photo next to the character.", live["followUp"]["en"])
        stale = copy.deepcopy(live)
        stale["followUp"]["en"] = previous["followUp"]["en"]
        with self.assertRaisesRegex(promoted.PromotedBatchError, "stale editorial successor"):
            promoted._editorial_predecessor("smalltalk", ident, stale, successors)

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

    def test_explicit_vocab_headword_opt_in_changes_copy_only_fields(self):
        before = dict(
            id="vocab_b1_demo",
            level="B1",
            korean="기존 표현",
            romanization="gijon pyohyeon",
            german="alte Formulierung",
            english="old wording",
            example_korean="기존 표현을 써요.",
            example_german="Ich benutze die alte Formulierung.",
            example_english="I use the old wording.",
        )
        after = {
            **before,
            "korean": "새 표현",
            "romanization": "sae pyohyeon",
            "german": "neue Formulierung",
            "english": "new wording",
            "example_korean": "새 표현을 써요.",
            "example_german": "Ich benutze die neue Formulierung.",
            "example_english": "I use the new wording.",
        }
        successor = reconcile.successor_entry(
            "drafts/manifest.json",
            "vocab",
            before,
            after,
            None,
            source_commit=COMMIT,
            source_path="assets/data/korean_vocab.csv",
            allow_vocab_headword=True,
        )
        self.assertIn("korean", successor["fields"])
        self.assertIn("romanization", successor["fields"])
        self.assertIn("LCP vocab headword replacement", successor["reason"])

        for field in ("level", "pack_id"):
            with self.subTest(field=field), self.assertRaisesRegex(ValueError, "non-copy"):
                reconcile.successor_entry(
                    "drafts/manifest.json",
                    "vocab",
                    before,
                    {**after, field: "unregistered"},
                    None,
                    source_commit=COMMIT,
                    source_path="assets/data/korean_vocab.csv",
                    allow_vocab_headword=True,
                )


if __name__ == "__main__":
    unittest.main()
