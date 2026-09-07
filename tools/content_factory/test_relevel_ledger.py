#!/usr/bin/env python3
"""Tests for ``relevel_ledger.py`` (plan §4.3, task T1.7).

Run with:
    python -m unittest tools.content_factory.test_relevel_ledger -v
"""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path
import sys

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from relevel_ledger import (  # noqa: E402
    DEFAULT_LEDGER_PATH,
    KINDS,
    Ledger,
    LedgerEntry,
    LedgerError,
    load_ledger,
    validate_ledger,
)


def make_entry(
    ident: str = "vocab_a1_0001",
    kind: str = "vocab",
    from_level: str = "a1",
    to_level: str = "b1",
    movedAt: str = "2026-09-07",
    batch: str = "relevel_test",
    reason: str = "unit test fixture",
) -> LedgerEntry:
    return LedgerEntry(
        id=ident,
        kind=kind,
        from_level=from_level,
        to_level=to_level,
        movedAt=movedAt,
        batch=batch,
        reason=reason,
    )


class LedgerEntryTest(unittest.TestCase):
    def test_round_trips_through_dict(self) -> None:
        entry = make_entry()
        restored = LedgerEntry.from_dict(entry.to_dict())
        self.assertEqual(entry, restored)

    def test_rejects_unknown_kind(self) -> None:
        with self.assertRaises(LedgerError):
            make_entry(kind="essay")

    def test_rejects_non_canonical_level(self) -> None:
        with self.assertRaises(LedgerError):
            make_entry(from_level="A1")  # must be lowercase
        with self.assertRaises(LedgerError):
            make_entry(to_level="b7")

    def test_rejects_id_kind_prefix_mismatch(self) -> None:
        with self.assertRaises(LedgerError):
            make_entry(ident="cloze_a1_0001", kind="vocab")

    def test_rejects_missing_field(self) -> None:
        data = make_entry().to_dict()
        del data["reason"]
        with self.assertRaises(LedgerError):
            LedgerEntry.from_dict(data)


class LedgerAllowsAndIdsForTest(unittest.TestCase):
    def setUp(self) -> None:
        self.ledger = Ledger(
            version=1,
            entries=[
                make_entry(ident="vocab_a1_0001", kind="vocab", from_level="a1", to_level="b1"),
                make_entry(ident="cloze_a1_0002", kind="cloze", from_level="a1", to_level="a2"),
            ],
        )

    def test_allows_true_when_kind_id_and_to_match(self) -> None:
        self.assertTrue(self.ledger.allows("vocab", "vocab_a1_0001", "b1"))

    def test_allows_false_when_to_does_not_match(self) -> None:
        self.assertFalse(self.ledger.allows("vocab", "vocab_a1_0001", "a2"))

    def test_allows_false_for_unknown_id(self) -> None:
        self.assertFalse(self.ledger.allows("vocab", "vocab_a1_9999", "b1"))

    def test_allows_false_when_kind_does_not_match_id(self) -> None:
        # Same id string under a different kind must not match -- kind is
        # part of the identity, not a hint.
        self.assertFalse(self.ledger.allows("cloze", "vocab_a1_0001", "b1"))

    def test_ids_for_returns_only_that_kind(self) -> None:
        self.assertEqual(self.ledger.ids_for("vocab"), frozenset({"vocab_a1_0001"}))
        self.assertEqual(self.ledger.ids_for("cloze"), frozenset({"cloze_a1_0002"}))
        self.assertEqual(self.ledger.ids_for("satz"), frozenset())

    def test_get_returns_entry_or_none(self) -> None:
        self.assertIsNotNone(self.ledger.get("vocab", "vocab_a1_0001"))
        self.assertIsNone(self.ledger.get("vocab", "vocab_a1_0002"))

    def test_entries_are_kept_sorted_by_kind_then_id(self) -> None:
        keys = [(entry.kind, entry.id) for entry in self.ledger.entries]
        self.assertEqual(keys, sorted(keys))


class LedgerAppendTest(unittest.TestCase):
    def test_append_adds_new_entry_and_keeps_sort(self) -> None:
        ledger = Ledger(version=1, entries=[make_entry(ident="vocab_b1_0001", kind="vocab")])
        grown = ledger.append(make_entry(ident="cloze_a1_0001", kind="cloze"))
        self.assertEqual(len(grown.entries), 2)
        keys = [(entry.kind, entry.id) for entry in grown.entries]
        self.assertEqual(keys, sorted(keys))
        # original ledger is untouched
        self.assertEqual(len(ledger.entries), 1)

    def test_append_rejects_duplicate_id(self) -> None:
        ledger = Ledger(version=1, entries=[make_entry(ident="vocab_a1_0001", kind="vocab")])
        with self.assertRaises(LedgerError):
            ledger.append(make_entry(ident="vocab_a1_0001", kind="vocab", to_level="a2"))

    def test_constructor_rejects_duplicate_id_up_front(self) -> None:
        with self.assertRaises(LedgerError):
            Ledger(
                version=1,
                entries=[
                    make_entry(ident="vocab_a1_0001"),
                    make_entry(ident="vocab_a1_0001", to_level="a2"),
                ],
            )


class LoadLedgerTest(unittest.TestCase):
    # T1.7's original 19-row migration of the three hard-coded
    # LEGACY_*_LEVEL_EXCEPTIONS frozensets (commit b233eccc). Every batch
    # since (L2a's 17-pack apply, L2a2's scenario move, ...) only ever
    # *appends* to the shipped ledger, so this checks the seed rows are
    # still present rather than pinning the ever-growing exact total --
    # a previous version of this test hard-coded 619/221/199/199 and broke
    # on the very next legitimate batch (LCP PR-L2a2, T2.4b-1 plan step
    # 2(d): "so future batches do not break it").
    ORIGINAL_SEED_ENTRIES = frozenset({
        ("cloze", "cloze_a1_0104"),
        ("satz", "satz_a1_0068"),
        ("vocab", "vocab_a1_0216"),
        ("vocab", "vocab_b1_0013"),
        ("vocab", "vocab_b1_0192"),
        ("vocab", "vocab_b1_0195"),
        ("vocab", "vocab_b2_0089"),
        ("vocab", "vocab_b2_0094"),
        ("vocab", "vocab_b2_0095"),
        ("vocab", "vocab_b2_0109"),
        ("vocab", "vocab_b2_0110"),
        ("vocab", "vocab_b2_0111"),
        ("vocab", "vocab_b2_0112"),
        ("vocab", "vocab_b2_0113"),
        ("vocab", "vocab_b2_0116"),
        ("vocab", "vocab_b2_0117"),
        ("vocab", "vocab_b2_0118"),
        ("vocab", "vocab_b2_0145"),
        ("vocab", "vocab_b2_0146"),
    })

    def test_default_ledger_file_loads_and_contains_the_original_seed_entries(self) -> None:
        ledger = load_ledger()
        present = {(entry.kind, entry.id) for entry in ledger.entries}
        self.assertTrue(
            self.ORIGINAL_SEED_ENTRIES.issubset(present),
            self.ORIGINAL_SEED_ENTRIES - present,
        )
        self.assertGreaterEqual(len(ledger.entries), len(self.ORIGINAL_SEED_ENTRIES))
        for entry in ledger.entries:
            self.assertIn(entry.kind, KINDS)

    def test_default_ledger_path_is_sibling_of_this_module(self) -> None:
        self.assertEqual(DEFAULT_LEDGER_PATH.name, "relevel_ledger.json")
        self.assertEqual(DEFAULT_LEDGER_PATH.parent, SCRIPT_DIR)

    def test_missing_file_raises(self) -> None:
        with self.assertRaises(LedgerError):
            load_ledger(SCRIPT_DIR / "does_not_exist_relevel_ledger.json")

    def test_bad_json_raises(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "bad.json"
            path.write_text("{not json", encoding="utf-8")
            with self.assertRaises(LedgerError):
                load_ledger(path)

    def test_non_dict_root_raises(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "list_root.json"
            path.write_text("[]", encoding="utf-8")
            with self.assertRaises(LedgerError):
                load_ledger(path)

    def test_missing_entries_key_raises(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "no_entries.json"
            path.write_text(json.dumps({"version": 1}), encoding="utf-8")
            with self.assertRaises(LedgerError):
                load_ledger(path)

    def test_duplicate_id_in_file_raises(self) -> None:
        entry = make_entry().to_dict()
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "dup.json"
            path.write_text(
                json.dumps({"version": 1, "entries": [entry, entry]}),
                encoding="utf-8",
            )
            with self.assertRaises(LedgerError):
                load_ledger(path)

    def test_round_trip_save_and_reload(self) -> None:
        ledger = Ledger(version=1, entries=[make_entry(ident="vocab_a1_0001")])
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "roundtrip.json"
            ledger.save(path)
            reloaded = load_ledger(path)
            self.assertEqual(reloaded.entries, ledger.entries)

    def test_save_writes_lf_only(self) -> None:
        # T2.3-R2: relevel_ledger.json is `eol=lf`; save() must not let
        # Windows text-mode writing turn it back into CRLF.
        ledger = Ledger(version=1, entries=[make_entry(ident="vocab_a1_0001")])
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "lf_check.json"
            ledger.save(path)
            self.assertNotIn(b"\r", path.read_bytes())


class ValidateLedgerTest(unittest.TestCase):
    def setUp(self) -> None:
        self.ledger = Ledger(
            version=1,
            entries=[
                make_entry(ident="vocab_a1_0001", kind="vocab", from_level="a1", to_level="b1"),
            ],
        )

    def test_no_issues_when_live_data_matches(self) -> None:
        live_levels = {"vocab": {"vocab_a1_0001": "b1"}}
        self.assertEqual(validate_ledger(self.ledger, live_levels), [])

    def test_reports_missing_id_in_live_data(self) -> None:
        live_levels: dict[str, dict[str, str]] = {"vocab": {}}
        issues = validate_ledger(self.ledger, live_levels)
        self.assertEqual(len(issues), 1)
        self.assertIn("vocab_a1_0001", issues[0])
        self.assertIn("not found", issues[0])

    def test_reports_wrong_to_level(self) -> None:
        live_levels = {"vocab": {"vocab_a1_0001": "a2"}}
        issues = validate_ledger(self.ledger, live_levels)
        self.assertEqual(len(issues), 1)
        self.assertIn("vocab_a1_0001", issues[0])
        self.assertIn("to=", issues[0])

    def test_reports_wrong_from_level(self) -> None:
        # id segment says a1, but the ledger entry claims from=a2 -- a
        # tampered/hand-edited ledger row.
        bad_ledger = Ledger(
            version=1,
            entries=[
                make_entry(ident="vocab_a1_0001", kind="vocab", from_level="a2", to_level="b1"),
            ],
        )
        live_levels = {"vocab": {"vocab_a1_0001": "b1"}}
        issues = validate_ledger(bad_ledger, live_levels)
        self.assertEqual(len(issues), 1)
        self.assertIn("from=", issues[0])

    def test_missing_kind_in_live_levels_reports_all_ids_missing(self) -> None:
        issues = validate_ledger(self.ledger, {})
        self.assertEqual(len(issues), 1)
        self.assertIn("not found", issues[0])

    def test_the_shipped_ledger_validates_clean_against_live_assets(self) -> None:
        # Builds live_levels for whichever kinds the shipped ledger
        # actually uses today (structural, not a fixed kind list) --
        # kind="scenario" entries (LCP PR-L2a2) need scenario_store's
        # merged-shard view rather than a single CSV/JSON file, same as
        # every other kind here needs its own real source file.
        import csv

        repo_root = SCRIPT_DIR.parents[1]
        data_dir = repo_root / "assets" / "data"
        ledger = load_ledger()

        def _csv_levels(name: str) -> dict[str, str]:
            with (data_dir / name).open(encoding="utf-8", newline="") as handle:
                return {row["id"]: row["level"].lower() for row in csv.DictReader(handle)}

        def _json_item_levels(name: str) -> dict[str, str]:
            root = json.loads((data_dir / name).read_text(encoding="utf-8"))
            return {item["id"]: str(item["level"]).lower() for item in root["items"]}

        def _scenario_levels() -> dict[str, str]:
            import scenario_store  # sys.path already primed at module import time

            return {
                str(item["id"]): str(item["level"]).lower()
                for item in scenario_store.load_scenarios(data_dir)
            }

        builders = {
            "vocab": lambda: _csv_levels("korean_vocab.csv"),
            "grammar": lambda: _csv_levels("grammar.csv"),
            "cloze": lambda: _json_item_levels("cloze.json"),
            "satz": lambda: _json_item_levels("satz_sentences.json"),
            "smalltalk": lambda: _json_item_levels("smalltalk.json"),
            "pronunciation": lambda: _json_item_levels("pronunciation_phrases.json"),
            "scenario": _scenario_levels,
        }
        used_kinds = {entry.kind for entry in ledger.entries}
        live_levels = {kind: builders[kind]() for kind in used_kinds}
        self.assertEqual(validate_ledger(ledger, live_levels), [])


if __name__ == "__main__":
    unittest.main()
