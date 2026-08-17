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

from shelf_assignment import (
    ALL_SHELVES,
    ASSIGNMENT,
    LEVELS,
    SHELF_BY_ID,
    SHELF_SLUGS,
    check_assignment,
)

ROOT = SCRIPT_DIR.parents[1]
DATA = ROOT / "assets" / "data"


def _live_levels() -> dict[str, str]:
    with (DATA / "scenarios.json").open(encoding="utf-8") as handle:
        root = json.load(handle)
    return {
        str(item["id"]): str(item["level"]).strip().lower()
        for item in root["scenarios"]
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

    def test_interest_shelves_are_declared_but_unseeded(self) -> None:
        # 관심 3칸은 Batch 11 이 들어오기 전까지 재고가 없다. 칸 자체는 존재해야
        # 계획 3 이 그 칸으로 draft 를 넣을 수 있다.
        for level in LEVELS:
            for slug in ("friends", "dating", "fandom"):
                shelf = f"{level}_{slug}"
                self.assertIn(shelf, ALL_SHELVES)
                self.assertEqual(ASSIGNMENT.get(shelf, ()), ())


if __name__ == "__main__":
    unittest.main()
