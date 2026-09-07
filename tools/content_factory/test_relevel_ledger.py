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
    def test_default_ledger_file_loads_and_has_19_seed_entries(self) -> None:
        ledger = load_ledger()
        self.assertEqual(len(ledger.entries), 19)
        self.assertEqual(len(ledger.ids_for("vocab")), 17)
        self.assertEqual(len(ledger.ids_for("cloze")), 1)
        self.assertEqual(len(ledger.ids_for("satz")), 1)

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
        import csv

        repo_root = SCRIPT_DIR.parents[1]
        data_dir = repo_root / "assets" / "data"
        ledger = load_ledger()

        with (data_dir / "korean_vocab.csv").open(encoding="utf-8", newline="") as handle:
            vocab_levels = {
                row["id"]: row["level"].lower() for row in csv.DictReader(handle)
            }
        cloze_root = json.loads((data_dir / "cloze.json").read_text(encoding="utf-8"))
        cloze_levels = {
            item["id"]: item["level"].lower() for item in cloze_root["items"]
        }
        satz_root = json.loads((data_dir / "satz_sentences.json").read_text(encoding="utf-8"))
        satz_levels = {
            item["id"]: item["level"].lower() for item in satz_root["items"]
        }

        live_levels = {"vocab": vocab_levels, "cloze": cloze_levels, "satz": satz_levels}
        self.assertEqual(validate_ledger(ledger, live_levels), [])


if __name__ == "__main__":
    unittest.main()
