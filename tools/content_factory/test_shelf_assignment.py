#!/usr/bin/env python3
"""Task 1 — 부록 A 배정표의 fail-closed 4지표.

Run with:
    python3 -m unittest tools/content_factory/test_shelf_assignment.py
"""

from __future__ import annotations

import json
from pathlib import Path
import sys
import unittest

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import scenario_store
from shelf_assignment import (
    ALL_SHELVES,
    ASSIGNMENT,
    EXPANSION_SLUGS,
    LEVELS,
    SHELF_BY_ID,
    SHELF_SLUGS,
    check_assignment,
)

ROOT = SCRIPT_DIR.parents[1]
DATA = ROOT / "assets" / "data"


def _live_levels() -> dict[str, str]:
    return {
        str(item["id"]): str(item["level"]).strip().lower()
        for item in scenario_store.load_scenarios(DATA)
    }


class ShelfAssignmentTest(unittest.TestCase):
    def test_every_level_has_twelve_shelves(self) -> None:
        for level in LEVELS:
            self.assertEqual(len(SHELF_SLUGS[level]), 12, level)
            self.assertEqual(len(set(SHELF_SLUGS[level])), 12, level)
        self.assertEqual(len(ALL_SHELVES), 72)

    def test_assignment_covers_the_live_corpus_exactly(self) -> None:
        live = _live_levels()
        self.assertEqual(len(live), 264)
        report = check_assignment(live)
        self.assertEqual(report["dupes"], [])
        self.assertEqual(report["orphans"], [])
        self.assertEqual(report["ghosts"], [])
        self.assertEqual(report["wrong_level"], [])

    def test_assigned_shelves_are_declared_shelves(self) -> None:
        self.assertTrue(set(ASSIGNMENT).issubset(ALL_SHELVES))
        self.assertEqual(len(SHELF_BY_ID), 264)

    def test_expansion_shelves_are_declared_but_unseeded(self) -> None:
        # 기능 확장 3칸(2026-08-17 Jin 결정, 핸드오프 §3.2 (나))은 신규 집필 전까지
        # 재고가 없다. 칸 자체는 존재해야 이후 배치가 그 칸으로 draft 를 넣을 수 있다.
        # 구 관심축(friends·dating·fandom)은 서재 열거에서 빠져야 한다.
        for level in LEVELS:
            for slug in EXPANSION_SLUGS[level]:
                shelf = f"{level}_{slug}"
                self.assertIn(shelf, ALL_SHELVES)
                self.assertEqual(ASSIGNMENT.get(shelf, ()), ())
            for slug in ("friends", "dating", "fandom"):
                self.assertNotIn(f"{level}_{slug}", ALL_SHELVES)


if __name__ == "__main__":
    unittest.main()
