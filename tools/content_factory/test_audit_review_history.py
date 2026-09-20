"""Exercise history tracing on real isolated Git timelines, not the repo's CI depth."""
import csv
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

import audit_review_history as history


class HistoryTraceTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.name", "History fixture")
        self.git("config", "user.email", "history@example.invalid")
        self.git("config", "core.autocrlf", "false")
        self.git("config", "core.hooksPath", str(self.root / "no-hooks"))
        self.manifest = "drafts/batch.json"
        self.draft = "drafts/words.csv"
        self.review = "review/words.csv"
        self.live = "assets/data/korean_vocab.csv"
        self.write(self.manifest, json.dumps({"artifacts": [{"kind": "vocab", "draft": self.draft, "review": self.review}]}))
        self.word(self.draft, "여기")
        self.word(self.live, "여기")
        self.write(self.review, "id,상태,ko\nv1,pending,여기\n")
        self.promotion = self.commit("initial promotion fixture")

    def git(self, *args):
        return subprocess.check_output(["git", *args], cwd=self.root, stderr=subprocess.STDOUT).decode().strip()

    def write(self, path, text):
        dest = self.root / path
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(text, encoding="utf-8", newline="\n")

    def word(self, path, ko):
        stream = io.StringIO(newline="")
        writer = csv.writer(stream, lineterminator="\n")
        writer.writerow(["id", "korean"])
        writer.writerow(["v1", ko])
        self.write(path, stream.getvalue())

    def commit(self, message):
        self.git("add", ".")
        self.git("commit", "-q", "-m", message)
        return self.git("rev-parse", "HEAD")

    def audit(self):
        return history.audit(root=self.root, manifest=self.manifest, promotion_manifest=self.manifest,
                             promotion=self.promotion, integration=self.promotion)

    def test_separate_draft_review_live_tracks_do_not_grant_approval(self):
        self.word(self.draft, "거기")
        draft_commit = self.commit("edit only draft")
        self.word(self.live, "저기")
        live_commit = self.commit("edit only live")
        before = {p: (self.root / p).read_bytes() for p in [self.draft, self.review, self.live, self.manifest]}
        result = self.audit()
        artifact, = result["artifacts"]
        self.assertEqual(artifact["originalDraftLiveMismatches"], [])
        self.assertEqual(artifact["currentDraftChangedSincePromotion"], ["v1"])
        self.assertEqual(artifact["currentRawDraftLiveDifferences"], ["v1"])
        self.assertEqual(artifact["tracks"]["draft"]["rows"][0]["transitions"][0]["commit"], draft_commit)
        self.assertEqual(artifact["tracks"]["live"]["rows"][0]["transitions"][0]["commit"], live_commit)
        self.assertEqual(artifact["tracks"]["review"]["rows"][0]["transitions"], [])
        self.assertFalse(result["approvalAdded"])
        self.assertEqual(result["humanReviewStatus"], "not_assessed")
        self.assertEqual(before, {p: (self.root / p).read_bytes() for p in before})
        self.assertEqual(self.git("status", "--porcelain"), "")

    def test_reverted_content_still_has_two_observed_transitions(self):
        self.word(self.live, "거기")
        self.commit("change")
        self.word(self.live, "여기")
        self.commit("restore")
        result = self.audit()
        self.assertEqual(result["summary"]["rawDraftLiveDifferences"], 0)
        self.assertEqual(result["summary"]["transitionsByTrack"]["live"], 2)

    def test_malformed_middle_snapshot_is_a_reported_gap_not_invented_history(self):
        self.write(self.review, "id,상태,ko\nv1,pending,여기,unquoted comma\n")
        broken = self.commit("broken CSV")
        self.write(self.review, "id,상태,ko\nv1,pending,거기\n")
        fixed = self.commit("repair CSV")
        result = self.audit()
        track = result["artifacts"][0]["tracks"]["review"]
        self.assertFalse(track["historyComplete"])
        self.assertEqual(track["unparsedSnapshots"][0]["commit"], broken)
        transition, = track["rows"][0]["transitions"]
        self.assertEqual(transition["commit"], fixed)
        self.assertEqual(transition["unparsedInterval"], [broken])
        self.assertEqual(result["summary"]["unparsedSnapshots"], 1)

    def test_source_wip_is_not_silently_excluded(self):
        self.word(self.live, "uncommitted change")
        with self.assertRaises(history.HistoryError):
            self.audit()

    def test_pinned_evidence_is_reproducible_after_later_content_commits(self):
        before = self.audit()
        self.word(self.live, "later copy")
        self.commit("later copy outside pinned endpoint")
        after = history.audit(root=self.root, manifest=self.manifest, promotion_manifest=self.manifest,
                              promotion=self.promotion, integration=self.promotion, head_ref=self.promotion)
        self.assertEqual(before, after)

    def install_cli_fixture(self):
        script = "tools/content_factory/audit_review_history.py"
        helper = "tools/content_factory/validate_promoted_batch.py"
        self.write(script, Path(history.__file__).read_text(encoding="utf-8"))
        self.write(helper, 'import hashlib, json\n'
                   'TARGETS = {"vocab": ("korean_vocab.csv", None)}\n'
                   'def _fingerprint(value):\n'
                   '    return hashlib.sha256(json.dumps(value, ensure_ascii=False, '
                   'sort_keys=True, separators=(",", ":")).encode("utf-8")).hexdigest()\n')
        return script, helper, self.commit("install CLI fixture")

    def cli_audit(self, script, head):
        return subprocess.check_output(
            [sys.executable, "-B", str(self.root / script), "--root", str(self.root),
             "--manifest", self.manifest, "--promotion-manifest", self.manifest,
             "--promotion", self.promotion, "--integration", self.promotion,
             "--head", head], cwd=self.root,
        )

    def test_pinned_cli_ignores_uncommitted_fingerprint_helper(self):
        script, helper, head = self.install_cli_fixture()
        before = self.cli_audit(script, head)
        with (self.root / helper).open("a", encoding="utf-8") as handle:
            handle.write('\ndef _fingerprint(value):\n    return "uncommitted-hash"\n')
        self.assertEqual(before, self.cli_audit(script, head))

    def test_pinned_cli_ignores_later_committed_target_mapping(self):
        script, helper, head = self.install_cli_fixture()
        before = self.cli_audit(script, head)
        # A later helper must not redirect an older audit to this new live file.
        self.word("assets/data/later_vocab.csv", "나중")
        with (self.root / helper).open("a", encoding="utf-8") as handle:
            handle.write('\nTARGETS["vocab"] = ("later_vocab.csv", None)\n')
        self.commit("change target mapping after pinned endpoint")
        self.assertEqual(before, self.cli_audit(script, head))

    def test_nonancestor_promotion_is_rejected(self):
        self.git("checkout", "--orphan", "unrelated")
        self.git("add", ".")
        self.git("commit", "-q", "-m", "unrelated origin")
        with self.assertRaises(history.HistoryError):
            self.audit()


class SnapshotParseTest(unittest.TestCase):
    def test_duplicate_ids_and_malformed_csv_are_not_normalized_away(self):
        for blob in [b'id,ko\na,x\na,y\n', b'id,ko\na,x,y\n', b'id,ko\na\n', b'id,ko\na,"unterminated\n', b'"id,ko\na,x\n']:
            with self.subTest(blob=blob), self.assertRaises(history.SnapshotError):
                history._records(blob, "words.csv", None)

    def test_malformed_json_has_explicit_snapshot_error(self):
        for blob in [b'{', b'[]', b'{"items":[{"id":"a"},{"id":"a"}]}',
                     b'{"items":[{"id":"a","ko":"first","ko":"last"}]}',
                     b'{"items":[{"id":"a","value":NaN}]}']:
            with self.subTest(blob=blob), self.assertRaises(history.SnapshotError):
                history._records(blob, "items.json", "items")

    def test_added_null_field_is_distinct_from_missing(self):
        delta = history._delta({"id": "a"}, {"id": "a", "note": None})
        self.assertEqual(delta["note"], {"beforePresent": False, "afterPresent": True, "before": None, "after": None})

    def test_repository_path_cannot_escape(self):
        for path in ["../secret", "/secret", "C:/secret", "a/../b", "a\\b"]:
            with self.subTest(path=path), self.assertRaises(history.HistoryError):
                history._path(path)


if __name__ == "__main__":
    unittest.main()
