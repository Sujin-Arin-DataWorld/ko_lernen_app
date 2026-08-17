#!/usr/bin/env python3
"""Task 5 — shelf/backdrop 주입의 fail-closed 계약.

Run with:
    python3 -m unittest tools/content_factory/test_migrate_shelf_backdrop.py
"""

from __future__ import annotations

from pathlib import Path
import sys
import unittest

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import migrate_shelf_backdrop as migrate
import scenario_store
from shelf_assignment import SHELF_BY_ID


class MigrationPlanTest(unittest.TestCase):
    def setUp(self) -> None:
        self.scenarios = scenario_store.load_scenarios()
        self.baseline = migrate.read_baseline()

    def test_live_corpus_migrates_clean(self) -> None:
        migrated, report = migrate.plan_migration(self.scenarios, self.baseline)
        self.assertEqual(report["dupes"], [])
        self.assertEqual(report["orphans"], [])
        self.assertEqual(report["ghosts"], [])
        self.assertEqual(report["wrong_level"], [])
        self.assertEqual(report["missing_backdrop"], [])
        self.assertEqual(report["unknown_backdrop"], [])
        self.assertEqual(len(migrated), 264)

    def test_every_scenario_gets_both_fields(self) -> None:
        migrated, _ = migrate.plan_migration(self.scenarios, self.baseline)
        for item in migrated:
            self.assertEqual(item["shelf"], SHELF_BY_ID[item["id"]])
            self.assertEqual(item["backdrop"], self.baseline[item["id"]])

    def test_sentences_and_ids_are_untouched(self) -> None:
        migrated, _ = migrate.plan_migration(self.scenarios, self.baseline)
        for before, after in zip(self.scenarios, migrated):
            stripped = {
                key: value
                for key, value in after.items()
                if key not in ("shelf", "backdrop")
            }
            self.assertEqual(stripped, before)

    def test_a_scenario_missing_from_the_baseline_is_fail_closed(self) -> None:
        migrated, report = migrate.plan_migration(
            [{"id": "ghost_probe", "level": "a1"}], {}
        )
        self.assertEqual(migrated, [])
        self.assertIn("ghost_probe", report["orphans"])

    def test_unknown_backdrop_value_is_fail_closed(self) -> None:
        one = self.scenarios[:1]
        migrated, report = migrate.plan_migration(one, {one[0]["id"]: "spaceship"})
        self.assertEqual(migrated, [])
        self.assertEqual(report["unknown_backdrop"], [one[0]["id"]])


if __name__ == "__main__":
    unittest.main()
