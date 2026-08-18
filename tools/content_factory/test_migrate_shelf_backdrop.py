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
        # 264(마이그레이션 당시) + 36(2026-08-18 Batch 11 승격).
        self.assertEqual(len(migrated), 312)

    def test_every_scenario_gets_both_fields(self) -> None:
        migrated, _ = migrate.plan_migration(self.scenarios, self.baseline)
        carried = {
            str(item["id"]): item.get("backdrop") for item in self.scenarios
        }
        for item in migrated:
            self.assertEqual(item["shelf"], SHELF_BY_ID[item["id"]])
            # 기준선은 264 에서 동결이다.  거기 있는 id 는 기준선이 이기고,
            # 이후 승격분은 레코드가 달고 온 값을 그대로 쓴다.
            expected = self.baseline.get(item["id"]) or carried[item["id"]]
            self.assertEqual(item["backdrop"], expected)

    def test_baseline_still_wins_over_a_drifted_record(self) -> None:
        # 승격분 폴백이 기준선을 덮어쓰면 backdrop 무회귀 보증이 깨진다.
        first = dict(self.scenarios[0])
        self.assertIn(first["id"], self.baseline)
        first["backdrop"] = "taxi" if self.baseline[first["id"]] != "taxi" else "cafe"
        migrated, report = migrate.plan_migration(
            [first] + [dict(s) for s in self.scenarios[1:]], self.baseline
        )
        self.assertEqual(report["missing_backdrop"], [])
        self.assertEqual(migrated[0]["backdrop"], self.baseline[first["id"]])

    def test_sentences_and_ids_are_untouched(self) -> None:
        migrated, _ = migrate.plan_migration(self.scenarios, self.baseline)
        def without_new_fields(record: dict) -> dict:
            return {
                key: value
                for key, value in record.items()
                if key not in ("shelf", "backdrop")
            }

        for before, after in zip(self.scenarios, migrated):
            # 이미 마이그레이션된 코퍼스를 다시 통과시켜도 두 필드 밖은 그대로다.
            self.assertEqual(without_new_fields(after), without_new_fields(before))

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
