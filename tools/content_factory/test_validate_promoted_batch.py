#!/usr/bin/env python3
"""Regression tests for the post-merge promoted-batch validator.

Run with:
    python3 -m unittest tools/content_factory/test_validate_promoted_batch.py
"""

from __future__ import annotations

import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = Path(__file__).resolve().parents[2]
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import relevel_ledger
import validate_batch_01 as review_batch
import validate_promoted_batch as promoted
import scenario_store


BATCH_17 = Path("tools/content_factory/drafts/batch_17_manifest.json")
CANONICAL_SCENARIO_RUNTIME = (
    json.loads(
        (REPO_ROOT / "assets/data/curriculum_manifest.json").read_text(
            encoding="utf-8"
        )
    ).get("scenarioCorpusGeneration")
    == "canonical_120_v1"
)


class PromotedBatchValidationTest(unittest.TestCase):
    @unittest.skipIf(
        CANONICAL_SCENARIO_RUNTIME,
        "historical promoted-scenario replay predates canonical_120_v1",
    )
    def test_merged_batch_17_matches_live_assets(self) -> None:
        count, inventory = promoted.validate(REPO_ROOT / BATCH_17)

        self.assertEqual(144, count)
        self.assertEqual(419, inventory["scenario"])
        self.assertEqual(582, inventory["smalltalk"])
        self.assertEqual(1805, inventory["cloze"])
        self.assertEqual(2333, inventory["satz"])
        self.assertEqual(84, inventory["pronunciation"])

    def test_review_batch_tool_points_merged_batch_17_at_promoted_validator(self) -> None:
        with self.assertRaisesRegex(
            review_batch.BatchValidationError,
            r"status is merged; use tools/content_factory/validate_promoted_batch.py",
        ):
            review_batch.validate_review_batch(manifest_path=BATCH_17)

    def test_rejects_review_only_status(self) -> None:
        root = self._copy_tree()
        path = root / BATCH_17
        manifest = json.loads(path.read_text(encoding="utf-8"))
        manifest["status"] = "review_only_draft"
        path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

        with self.assertRaisesRegex(promoted.PromotedBatchError, "status must be merged"):
            promoted.validate(path, root=root)

    def test_rejects_unknown_artifact_kind(self) -> None:
        root = self._copy_tree()
        path = root / BATCH_17
        manifest = json.loads(path.read_text(encoding="utf-8"))
        manifest["artifacts"][0]["kind"] = "puzzle"
        path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

        with self.assertRaisesRegex(promoted.PromotedBatchError, "unsupported promoted artifact kind"):
            promoted.validate(path, root=root)

    @unittest.skipIf(
        CANONICAL_SCENARIO_RUNTIME,
        "historical promoted-scenario replay predates canonical_120_v1",
    )
    def test_rejects_missing_live_record(self) -> None:
        root = self._copy_tree()
        data_dir = root / "assets" / "data"
        payload = scenario_store.load_root(data_dir)
        payload["scenarios"] = [
            row
            for row in payload["scenarios"]
            if row.get("id") != "c1_kpop_platform_localization_review"
        ]
        scenario_store.write_shards(payload["scenarios"], data_dir)

        with self.assertRaisesRegex(
            promoted.PromotedBatchError,
            "c1_kpop_platform_localization_review",
        ):
            promoted.validate(root / BATCH_17, root=root)

    def _copy_tree(self) -> Path:
        temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(temporary_directory.cleanup)
        root = Path(temporary_directory.name) / "repo"
        shutil.copytree(REPO_ROOT / "assets" / "data", root / "assets" / "data")
        shutil.copytree(
            REPO_ROOT / "tools" / "content_factory" / "drafts",
            root / "tools" / "content_factory" / "drafts",
        )
        shutil.copytree(
            REPO_ROOT / "tools" / "content_factory" / "review",
            root / "tools" / "content_factory" / "review",
        )
        return root


class RelevelNormalizedLiveTest(unittest.TestCase):
    """Task T2.9a: validate_promoted_batch must tolerate a live/draft
    difference confined to level/pack_id (vocab) or level (cloze/satz/
    smalltalk/pronunciation) for an id relevel_ledger.json records as
    relevel-moved -- any other field differing must still fail. Exercises
    `_relevel_normalized_live` directly against small, hand-built fixture
    ledgers rather than the real (7000+ line) relevel_ledger.json, per the
    ledger/ledger_path injection `validate()` itself now accepts."""

    @staticmethod
    def _ledger(*entries: relevel_ledger.LedgerEntry) -> relevel_ledger.Ledger:
        return relevel_ledger.Ledger(version=1, entries=list(entries))

    @staticmethod
    def _entry(ident: str, kind: str, *, from_level: str = "a1", to_level: str = "a2") -> relevel_ledger.LedgerEntry:
        return relevel_ledger.LedgerEntry(
            id=ident, kind=kind, from_level=from_level, to_level=to_level,
            movedAt="2026-09-07", batch="TEST", reason="fixture",
        )

    def test_vocab_pure_relevel_diff_normalizes_to_equal_draft(self) -> None:
        ledger = self._ledger(self._entry("vocab_a1_0001", "vocab"))
        draft = {"id": "vocab_a1_0001", "level": "A1", "pack_id": "a1_old_1", "pack_order": "3", "korean": "가다"}
        live = {"id": "vocab_a1_0001", "level": "A2", "pack_id": "a2_new_1", "pack_order": "9", "korean": "가다"}
        normalized = promoted._relevel_normalized_live("vocab", "vocab_a1_0001", live, draft, ledger)
        self.assertEqual(normalized, draft)

    def test_vocab_relevel_plus_unrelated_diff_only_normalizes_tolerated_fields(self) -> None:
        ledger = self._ledger(self._entry("vocab_a1_0002", "vocab"))
        draft = {
            "id": "vocab_a1_0002", "level": "A1", "pack_id": "a1_old_1", "pack_order": "3",
            "example_german": "alt",
        }
        live = {
            "id": "vocab_a1_0002", "level": "A2", "pack_id": "a2_new_1", "pack_order": "9",
            "example_german": "neu",
        }
        normalized = promoted._relevel_normalized_live("vocab", "vocab_a1_0002", live, draft, ledger)
        self.assertEqual(normalized["level"], draft["level"])
        self.assertEqual(normalized["pack_id"], draft["pack_id"])
        self.assertEqual(normalized["pack_order"], draft["pack_order"])
        self.assertEqual(normalized["example_german"], "neu", "a non-tolerated field must stay live's value")
        self.assertNotEqual(normalized, draft, "the unrelated diff must still be visible to the caller")

    def test_non_ledgered_id_is_untouched(self) -> None:
        ledger = self._ledger(self._entry("vocab_a1_0001", "vocab"))
        draft = {"id": "vocab_a1_0099", "level": "A1", "pack_id": "a1_old_1"}
        live = {"id": "vocab_a1_0099", "level": "A2", "pack_id": "a2_new_1"}
        normalized = promoted._relevel_normalized_live("vocab", "vocab_a1_0099", live, draft, ledger)
        self.assertEqual(normalized, live, "an id absent from the ledger must be a no-op")

    def test_cloze_kind_tolerates_level_only(self) -> None:
        ledger = self._ledger(self._entry("cloze_a1_0001", "cloze"))
        draft = {"id": "cloze_a1_0001", "level": "a1", "topic": "x"}
        live = {"id": "cloze_a1_0001", "level": "a2", "topic": "x"}
        normalized = promoted._relevel_normalized_live("cloze", "cloze_a1_0001", live, draft, ledger)
        self.assertEqual(normalized, draft)

    def test_cloze_kind_never_tolerates_a_non_level_field(self) -> None:
        ledger = self._ledger(self._entry("cloze_a1_0002", "cloze"))
        draft = {"id": "cloze_a1_0002", "level": "a1", "topic": "x"}
        live = {"id": "cloze_a1_0002", "level": "a2", "topic": "y"}
        normalized = promoted._relevel_normalized_live("cloze", "cloze_a1_0002", live, draft, ledger)
        self.assertEqual(normalized["level"], "a1", "level is tolerated")
        self.assertEqual(normalized["topic"], "y", "topic is not tolerated -- must stay live's value")

    def test_grammar_kind_is_never_ledger_tolerant(self) -> None:
        # "grammar" is a valid relevel_ledger.py kind (its KINDS constant
        # includes it), so this ledger entry is itself well-formed -- but
        # neither relevel_bundle.py nor tool/relevel_vocab.py ever moves a
        # grammar row, and LEDGER_TOLERANT_KINDS deliberately omits it
        # (matches current tooling, not a hypothetical). Even a real,
        # well-formed grammar ledger entry must not grant tolerance.
        ledger = self._ledger(self._entry("grammar_a1_topic", "grammar", from_level="a1", to_level="a2"))
        draft = {"id": "grammar_a1_topic", "level": "a1"}
        live = {"id": "grammar_a1_topic", "level": "a2"}
        normalized = promoted._relevel_normalized_live("grammar", "grammar_a1_topic", live, draft, ledger)
        self.assertEqual(normalized, live)


if __name__ == "__main__":
    unittest.main()
