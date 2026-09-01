#!/usr/bin/env python3
"""Task 3 — 코퍼스 접근 단일 지점.

Run with:
    python3 -m unittest tools/content_factory/test_scenario_store.py
"""

from __future__ import annotations

import json
from pathlib import Path
import sys
import tempfile
import unittest

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import scenario_store


def _scenario(scenario_id: str, level: str) -> dict:
    return {"id": scenario_id, "level": level}


class ScenarioStoreTest(unittest.TestCase):
    def test_shard_name_rejects_unknown_level(self) -> None:
        self.assertEqual(scenario_store.shard_name("A1"), "scenarios_a1.json")
        with self.assertRaises(ValueError):
            scenario_store.shard_name("d1")

    def test_reads_legacy_single_file_when_no_shards(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            data = Path(tmp)
            (data / "scenarios.json").write_text(
                json.dumps({"version": 1, "scenarios": [_scenario("x", "b1")]}),
                encoding="utf-8",
            )
            self.assertFalse(scenario_store.has_shards(data))
            self.assertEqual(
                [item["id"] for item in scenario_store.load_scenarios(data)], ["x"]
            )

    def test_write_then_read_round_trips_in_level_order(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            data = Path(tmp)
            counts = scenario_store.write_shards(
                [_scenario("c", "c2"), _scenario("a", "a1"), _scenario("b", "a1")],
                data,
            )
            self.assertEqual(counts["a1"], 2)
            self.assertEqual(counts["c2"], 1)
            self.assertEqual(counts["b1"], 0)
            self.assertTrue(scenario_store.has_shards(data))
            self.assertEqual(
                [item["id"] for item in scenario_store.load_scenarios(data)],
                ["a", "b", "c"],
            )
            raw = (data / "scenarios_a1.json").read_bytes()
            self.assertTrue(raw.endswith(b"\n"))
            self.assertNotIn(b"\r\n", raw)

    def test_shards_win_over_a_stale_legacy_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            data = Path(tmp)
            scenario_store.write_shards([_scenario("fresh", "a2")], data)
            (data / "scenarios.json").write_text(
                json.dumps({"version": 1, "scenarios": [_scenario("stale", "a2")]}),
                encoding="utf-8",
            )
            self.assertEqual(
                [item["id"] for item in scenario_store.load_scenarios(data)], ["fresh"]
            )

    def test_write_rejects_an_unknown_level(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(ValueError):
                scenario_store.write_shards([_scenario("x", "")], Path(tmp))

    def test_target_shard_follows_the_level(self) -> None:
        self.assertEqual(
            scenario_store.target_shard(_scenario("x", "B2")), "scenarios_b2.json"
        )

    def test_live_corpus_is_readable_and_complete(self) -> None:
        scenarios = scenario_store.load_scenarios()
        self.assertEqual(len(scenarios), 120)
        counts = {
            level: sum(1 for item in scenarios if item.get("level") == level)
            for level in scenario_store.LEVELS
        }
        self.assertEqual(counts, {level: 20 for level in scenario_store.LEVELS})


if __name__ == "__main__":
    unittest.main()
