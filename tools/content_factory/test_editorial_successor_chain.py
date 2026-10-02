import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
import validate_promoted_batch as v


class EditorialSuccessorChainTest(unittest.TestCase):
    def load(self, change=None, *, change_payload=None, prepare=None):
        before = dict(id="vocab_a1_9999", level="A1", german="alt", english="old")
        after = {**before, "german": "neu"}
        entry = dict(manifest="drafts/manifest.json", kind="vocab", id=before["id"],
            before=before, after=after, fields=["german"],
            beforeSha256=v._fingerprint(before), afterSha256=v._fingerprint(after),
            sourceGitCommit="e3ec67afb84b4a1701e0fc5da0ca298af97acbe1",
            sourceGitPath="drafts/vocab.csv",
            reason="Exact model-only copy successor")
        if change:
            change(entry)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest_path = root / "drafts/manifest.json"
            manifest_path.parent.mkdir(parents=True)
            manifest_path.write_text(json.dumps(dict(artifacts=[
                dict(kind="vocab", draft="drafts/vocab.csv"),
                dict(kind="scenario", draft="drafts/scenarios.json"),
            ])), encoding="utf-8")
            for relative in ("drafts/vocab.csv", "drafts/scenarios.json",
                    "assets/data/korean_vocab.csv", "assets/data/scenarios_a1.json",
                    "assets/data/scenarios_a2.json", "drafts/other_batch_vocab.csv"):
                source = root / relative
                source.parent.mkdir(parents=True, exist_ok=True)
                source.write_text("fixture", encoding="utf-8")
            payload = dict(schemaVersion=1, reviewStatus="MODEL_REVIEW_ONLY",
                humanApprovalClaim=False,
                humanReviewStatus="required_before_native-quality-claim", entries=[entry])
            if change_payload:
                payload = change_payload(payload)
            if prepare:
                prepare(root)
            path = root / v.EDITORIAL_SUCCESSOR_LEDGER
            path.parent.mkdir(parents=True)
            path.write_text(json.dumps(payload), encoding="utf-8")
            return v._editorial_successors(root=root, manifest_path=manifest_path)

    def test_source_can_be_exact_manifest_draft_or_live_target(self):
        for source in ("drafts/vocab.csv", "assets/data/korean_vocab.csv"):
            with self.subTest(source=source):
                entries = self.load(lambda row: row.update(sourceGitPath=source))
                self.assertIn(("vocab", "vocab_a1_9999"), entries)

    def test_missing_or_weakened_human_gate_fails_closed(self):
        for field, values in {
            "humanReviewStatus": (None, "", "approved", True),
            "humanApprovalClaim": (None, True, 0),
            "reviewStatus": (None, "HUMAN_APPROVED"),
            "schemaVersion": (None, 2),
        }.items():
            for value in values:
                def change(payload, field=field, value=value):
                    payload[field] = value
                    return payload
                with self.subTest(field=field, value=value):
                    with self.assertRaisesRegex(v.PromotedBatchError, "human review gates"):
                        self.load(change_payload=change)
        def remove_gate(payload):
            del payload["humanReviewStatus"]
            return payload
        with self.assertRaisesRegex(v.PromotedBatchError, "human review gates"):
            self.load(change_payload=remove_gate)

    def test_duplicate_successor_cannot_choose_an_arbitrary_predecessor(self):
        def duplicate(payload):
            payload["entries"].append(copy.deepcopy(payload["entries"][0]))
            return payload
        with self.assertRaisesRegex(v.PromotedBatchError, "duplicate editorial successor"):
            self.load(change_payload=duplicate)

    def test_malformed_ledger_is_rejected_with_domain_error(self):
        for mutate in (lambda payload: [],
                lambda payload: {**payload, "entries": {}},
                lambda payload: {**payload, "entries": [None]},
                lambda payload: {**payload, "entries": ["not a record"]}):
            with self.subTest(mutate=mutate):
                with self.assertRaises(v.PromotedBatchError):
                    self.load(change_payload=mutate)

    def test_malformed_kind_or_id_is_rejected_before_lookup(self):
        for field, values in {
            "kind": (None, [], {}, "grammar", "unknown", " vocab"),
            "id": (None, [], {}, "", " vocab_a1_9999", "../row", "scenario_id"),
        }.items():
            for value in values:
                with self.subTest(field=field, value=value):
                    with self.assertRaisesRegex(v.PromotedBatchError, "invalid kind or id"):
                        self.load(lambda row: row.update({field: value}))

    def test_git_commit_requires_full_hex_object_id(self):
        for commit in (None, 123, "HEAD", "e3ec67a", "g" * 40, "a" * 39,
                "a" * 41, " " + "a" * 40):
            with self.subTest(commit=commit):
                with self.assertRaisesRegex(v.PromotedBatchError, "provenance"):
                    self.load(lambda row: row.update(sourceGitCommit=commit))

    def test_source_path_must_be_canonical_repo_relative(self):
        for source in (None, [], "", "/drafts/vocab.csv", "C:/drafts/vocab.csv",
                "drafts\\vocab.csv", "./drafts/vocab.csv", "drafts//vocab.csv",
                "drafts/../drafts/vocab.csv", "../drafts/vocab.csv"):
            with self.subTest(source=source):
                with self.assertRaisesRegex(v.PromotedBatchError, "canonical repo-relative"):
                    self.load(lambda row: row.update(sourceGitPath=source))

    def test_existing_source_from_other_kind_or_batch_is_rejected(self):
        for source in ("drafts/scenarios.json", "drafts/other_batch_vocab.csv",
                "assets/data/scenarios_a1.json"):
            with self.subTest(source=source):
                with self.assertRaisesRegex(v.PromotedBatchError, "target or manifest draft"):
                    self.load(lambda row: row.update(sourceGitPath=source))

    def test_expected_source_must_exist(self):
        with self.assertRaisesRegex(v.PromotedBatchError, "does not exist"):
            self.load(prepare=lambda root: (root / "drafts/vocab.csv").unlink())

    def test_expected_source_resolving_outside_repository_is_rejected(self):
        with tempfile.TemporaryDirectory() as outside:
            external = Path(outside) / "vocab.csv"
            external.write_text("external", encoding="utf-8")
            real_resolve = Path.resolve
            def resolve(path):
                # Exercise a symlink's resolved destination without requiring
                # Windows' symlink-creation privilege in the test environment.
                if path.as_posix().endswith("/drafts/vocab.csv"):
                    return external
                return real_resolve(path)
            with patch.object(Path, "resolve", autospec=True, side_effect=resolve):
                with self.assertRaisesRegex(v.PromotedBatchError, "escapes repository"):
                    self.load()

    def test_provenance_reason_must_be_nonempty_text(self):
        for reason in (None, True, {}, "", "   "):
            with self.subTest(reason=reason):
                with self.assertRaisesRegex(v.PromotedBatchError, "provenance"):
                    self.load(lambda row: row.update(reason=reason))

    def test_scenario_live_source_must_match_record_level(self):
        def scenario(row, source):
            before = dict(id="scene", level="A1", title=dict(en="old"))
            after = {**before, "title": dict(en="new")}
            row.update(kind="scenario", id="scene", before=before, after=after,
                fields=["title"], beforeSha256=v._fingerprint(before),
                afterSha256=v._fingerprint(after), sourceGitPath=source)
        self.assertIn(("scenario", "scene"), self.load(
            lambda row: scenario(row, "assets/data/scenarios_a1.json")))
        with self.assertRaisesRegex(v.PromotedBatchError, "target or manifest draft"):
            self.load(lambda row: scenario(row, "assets/data/scenarios_a2.json"))

    def test_successor_still_requires_the_exact_original_revision(self):
        entries = self.load()
        row = entries[("vocab", "vocab_a1_9999")]
        predecessor = v._editorial_predecessor("vocab", row["id"], row["after"], entries)
        self.assertEqual(predecessor, row["before"])
        draft = {**predecessor, "german": "frozen"}
        with self.assertRaisesRegex(v.PromotedBatchError, "stale promoted copy revision"):
            v._require_reviewed_copy_revision(kind="vocab", ident=row["id"], draft=draft,
                live=predecessor, revisions={("vocab",row["id"]): dict(
                    level="a1",fields=["german"],beforeSha256=v._fingerprint(draft),
                    afterSha256="unrelated")},batch_revisions={})

    def test_either_hash_or_live_text_drift_fails_closed(self):
        for field in ("beforeSha256", "afterSha256"):
            with self.subTest(field=field), self.assertRaises(v.PromotedBatchError):
                self.load(lambda row: row.update({field:"wrong"}))
        entries=self.load();row=entries[("vocab","vocab_a1_9999")]
        with self.assertRaisesRegex(v.PromotedBatchError,"stale editorial successor"):
            v._editorial_predecessor("vocab",row["id"],{**row["after"],"english":"drift"},entries)

    def test_field_or_embedded_identity_changes_are_rejected(self):
        def change_level(row):
            row["after"]["level"]="A2";row["fields"]=["german","level"]
            row["afterSha256"]=v._fingerprint(row["after"])
        with self.assertRaisesRegex(v.PromotedBatchError,"copy-only"):
            self.load(change_level)
        def change_quest(row):
            row.update(kind="scenario",id="scene",fields=["quests"])
            row["before"]=dict(id="scene",quests=[dict(id="q_before",en="old")])
            row["after"]=dict(id="scene",quests=[dict(id="q_after",en="new")])
            row["beforeSha256"]=v._fingerprint(row["before"])
            row["afterSha256"]=v._fingerprint(row["after"])
        with self.assertRaisesRegex(v.PromotedBatchError,"routing identity"):
            self.load(change_quest)

    def test_nested_scores_answers_and_structure_cannot_be_copy_changes(self):
        before=dict(quests=[dict(id="q", data=dict(correctIndex=0,route="/lesson",
            reward=dict(xp=15),options=[dict(en="old"),dict(en="other")]))])
        for fault in ("correctIndex", "route", "xp", "options"):
            after=copy.deepcopy(before);data=after["quests"][0]["data"]
            if fault=="xp": data["reward"]["xp"]=999
            elif fault=="options": data["options"].append(dict(en="third"))
            elif fault=="route": data["route"]="/different"
            else: data["correctIndex"]=1
            self.assertNotEqual(v._editorial_route_identity(before),
                v._editorial_route_identity(after),fault)
        after=copy.deepcopy(before)
        after["quests"][0]["data"]["options"][0]["en"]="new wording"
        self.assertEqual(v._editorial_route_identity(before),v._editorial_route_identity(after))
