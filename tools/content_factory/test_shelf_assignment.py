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
    INTEREST_SLUGS,
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
    def test_every_level_has_fifteen_shelves(self) -> None:
        # 기능 9 + 기능확장 3 + 관심 3.  2026-08-18 Jin 재결정으로 12 → 15.
        for level in LEVELS:
            self.assertEqual(len(SHELF_SLUGS[level]), 15, level)
            self.assertEqual(len(set(SHELF_SLUGS[level])), 15, level)
        self.assertEqual(len(ALL_SHELVES), 90)

    def test_assignment_covers_the_live_corpus_exactly(self) -> None:
        live = _live_levels()
        self.assertEqual(len(live), 419)
        report = check_assignment(live)
        self.assertEqual(report["dupes"], [])
        self.assertEqual(report["orphans"], [])
        self.assertEqual(report["ghosts"], [])
        self.assertEqual(report["wrong_level"], [])

    def test_assigned_shelves_are_declared_shelves(self) -> None:
        self.assertTrue(set(ASSIGNMENT).issubset(ALL_SHELVES))
        self.assertEqual(len(SHELF_BY_ID), 419)

    def test_interest_shelves_are_stocked_at_every_level(self) -> None:
        # 관심 3칸은 Batch 11 승격으로 전 레벨이 채워졌다.  한 레벨이라도 비면
        # 학습자가 스크롤해 내려간 자리가 레벨마다 다른 뜻이 된다 — 축이 전
        # 레벨에서 같은 것을 뜻해야 한다는 게 이 칸들의 존재 이유다.
        for level in LEVELS:
            self.assertEqual(INTEREST_SLUGS[level], ("friends", "dating", "fandom"))
            for slug in INTEREST_SLUGS[level]:
                shelf = f"{level}_{slug}"
                self.assertIn(shelf, ALL_SHELVES)
                self.assertNotEqual(ASSIGNMENT.get(shelf, ()), (), shelf)

    def test_unseeded_shelves_are_declared_and_awaiting_authoring(self) -> None:
        # 칸의 **존재**는 ALL_SHELVES 가, **재고**는 ASSIGNMENT 가 말한다.
        # 재고 0 칸도 선언되어 있어야 이후 배치가 그 칸으로 draft 를 넣을 수 있다.
        # 이 수(23)가 줄면 신규 집필이 진척된 것이고, 늘면 축이 또 갈린 것이다.
        unseeded = sorted(
            shelf for shelf in ALL_SHELVES if not ASSIGNMENT.get(shelf, ())
        )
        # Batch 13 이 A1 확장 3칸을 채웠다 (23 → 20).
        # Batch 14 가 A2~B2 확장 7칸을 채웠다 (20 → 13, 남은 건 전부 C1/C2).
        # Batch 15 가 C1 확장 7칸을 채웠다 (13 → 6, 남은 건 전부 C2).
        # Batch 16 이 C2 확장 6칸을 채웠다 (6 → 0). 서재 90칸이 전부 찼다.
        self.assertEqual(len(unseeded), 0, unseeded)
        expansion = {
            f"{level}_{slug}" for level in LEVELS for slug in EXPANSION_SLUGS[level]
        }
        # 빈 칸은 전부 기능축(기능 9 + 기능확장 3) 안에 있다 — 관심 3칸은 위
        # 테스트가 이미 전수 재고를 요구한다.
        interest = {
            f"{level}_{slug}" for level in LEVELS for slug in INTEREST_SLUGS[level]
        }
        self.assertEqual(set(unseeded) & interest, set())
        # daily 3편이 편입된 확장칸은 더 이상 비어 있지 않다.
        for seeded in ("a2_delivery", "b2_authorities", "c1_methodology"):
            self.assertIn(seeded, expansion)
            self.assertNotIn(seeded, unseeded)


if __name__ == "__main__":
    unittest.main()
