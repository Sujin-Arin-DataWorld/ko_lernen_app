#!/usr/bin/env python3
"""Batch 11 시나리오 초안의 레벨 계약·ID 충돌·review projection 회귀."""

from __future__ import annotations

import csv
import json
from pathlib import Path
import sys
import unittest

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import scenario_store

import build_batch_11_scenarios as builder
from data.batch_11_scene_scripts import SCENES

ROOT = SCRIPT_DIR.parents[1]
CATEGORIES = ("daily", "friends", "dating", "youtube", "gaming", "kpop")
LEVELS = ("a1", "a2", "b1", "b2", "c1", "c2")
QUEST_TYPES = ("hoerverstehen", "uebersetzen", "luecken", "satzBauen", "diktat")
REGISTERS = ("polite", "casual", "business", "intimate")
SCENE_KEYS = ("airport", "cafe", "convenience", "directions", "home", "hotel",
              "market", "office", "pharmacy", "restaurant", "station", "taxi")
SHELL_PHRASES = (
    "알겠습니다. 지금 바로 확인하겠습니다.",
    "네, 그렇게 해 주세요.",
    "안녕하세요. 무엇을 도와드릴까요?",
)


def authored_levels() -> tuple[str, ...]:
    return tuple(level for level in LEVELS if any(s["level"] == level for s in SCENES))


class SceneContractTest(unittest.TestCase):
    def test_authored_levels_have_six_categories_each(self):
        for level in authored_levels():
            cats = sorted(s["category"] for s in SCENES if s["level"] == level)
            self.assertEqual(cats, sorted(CATEGORIES), f"{level} category set")

    def test_ids_follow_level_category_pattern(self):
        for scene in SCENES:
            self.assertTrue(
                scene["id"].startswith(f"{scene['level']}_{scene['category']}_"),
                f"{scene['id']} must start with level_category",
            )

    def test_no_collision_with_live_scenarios(self):
        # 코퍼스는 레벨 샤드 6 개다 (2026-08-17). 병합 뷰는 store 만 만든다.
        live = scenario_store.load_root(ROOT / "assets" / "data")
        live_ids = {item["id"] for item in live["scenarios"]}
        live_quests = {
            q["id"]
            for item in live["scenarios"]
            for q in item.get("quests", [])
            if isinstance(q, dict) and isinstance(q.get("id"), str)
        }
        for scene in SCENES:
            self.assertNotIn(scene["id"], live_ids, f"{scene['id']} already live")
            for quest in scene["quests"]:
                self.assertNotIn(quest["id"], live_quests, f"{quest['id']} already live")

    def test_dialog_is_eight_trilingual_turns(self):
        for scene in SCENES:
            self.assertEqual(len(scene["dialog"]), 8, f"{scene['id']} dialog length")
            for turn in scene["dialog"]:
                self.assertIn(turn["speaker"], ("user", scene["sidekick"]))
                for key in ("ko", "de", "en"):
                    self.assertTrue(turn[key].strip(), f"{scene['id']} empty {key}")

    def test_five_quests_one_of_each_type(self):
        for scene in SCENES:
            types = [quest["type"] for quest in scene["quests"]]
            self.assertEqual(sorted(types), sorted(QUEST_TYPES), f"{scene['id']} quest types")
            for quest, suffix in zip(scene["quests"], builder.QUEST_SUFFIXES):
                self.assertEqual(quest["id"], f"quest_{scene['id']}_{suffix}")
                self.assertEqual(quest["conceptIds"], scene["conceptIds"])

    def test_vocab_has_at_least_six_entries(self):
        for scene in SCENES:
            self.assertGreaterEqual(len(scene["vocab"]), 6, f"{scene['id']} vocab count")
            for entry in scene["vocab"]:
                self.assertTrue(entry["korean"].strip())

    def test_grammar_ids_exist_and_match_level(self):
        with (ROOT / "assets/data/grammar.csv").open(encoding="utf-8", newline="") as handle:
            rows = list(csv.DictReader(handle))
        live = {row["id"]: row["level"].lower() for row in rows}
        for scene in SCENES:
            self.assertTrue(scene["grammarIds"], f"{scene['id']} needs a grammar id")
            for gid in scene["grammarIds"]:
                self.assertIn(gid, live, f"{gid} missing from grammar.csv")
                self.assertEqual(live[gid], scene["level"], f"{gid} level mismatch")
                self.assertIn(gid, builder.LEVEL_GRAMMAR_ALLOWLIST[scene["level"]],
                              f"{gid} outside {scene['level']} allowlist")

    def test_units_and_concepts_exist(self):
        manifest = json.loads((ROOT / "assets/data/curriculum_manifest.json").read_text(encoding="utf-8"))
        units = {u["id"]: (u["level"], set(u["requiredConceptIds"])) for u in manifest["courseUnits"]}
        for scene in SCENES:
            level, concepts = units[scene["courseUnitId"]]
            self.assertEqual(level, scene["level"], f"{scene['id']} unit level")
            for concept in scene["conceptIds"]:
                self.assertIn(concept, concepts, f"{concept} not required by {scene['courseUnitId']}")

    def test_enums_and_backdrops(self):
        for scene in SCENES:
            self.assertIn(scene["register"], REGISTERS)
            self.assertIn(scene["speechStyle"], REGISTERS)
            self.assertIn(scene["sidekick"], ("jieun", "minsu"))
            self.assertIn(scene["backdrop"], SCENE_KEYS)
            self.assertTrue(scene["emoji"].strip())

    def test_no_shell_phrases_and_no_repeated_lines(self):
        for scene in SCENES:
            lines = [turn["ko"] for turn in scene["dialog"]]
            self.assertEqual(len(lines), len(set(lines)), f"{scene['id']} repeats a Korean line")
            for line in lines:
                self.assertNotIn(line, SHELL_PHRASES, f"{scene['id']} uses a shell phrase")

    def test_intents_are_unique(self):
        intents = [scene["intent"] for scene in SCENES]
        self.assertEqual(len(intents), len(set(intents)), "intents must be unique")


class BuildOutputTest(unittest.TestCase):
    def setUp(self):
        self.counts = builder.build()
        self.draft = json.loads(
            (ROOT / "tools/content_factory/drafts/c1_batch11_scenarios_a1_c2.json").read_text(encoding="utf-8"))
        self.manifest = json.loads(
            (ROOT / "tools/content_factory/drafts/batch_11_manifest.json").read_text(encoding="utf-8"))
        with (ROOT / "tools/content_factory/review/c1_batch11_scenarios.csv").open(
                encoding="utf-8", newline="") as handle:
            self.review = list(csv.DictReader(handle))

    def test_manifest_counts_match_draft(self):
        records = self.draft["scenarios"]
        self.assertEqual(self.manifest["recordCount"], len(records))
        self.assertEqual(self.counts["scenarios"], len(records))
        quests = [q for record in records for q in record["quests"]]
        self.assertEqual(self.manifest["questCount"], len(quests))
        artifact = self.manifest["artifacts"][0]
        self.assertEqual(artifact["count"], len(records))
        levels = {}
        for record in records:
            levels[record["level"]] = levels.get(record["level"], 0) + 1
        self.assertEqual(artifact["levels"], levels)

    def test_review_projection_is_byte_identical(self):
        records = self.draft["scenarios"]
        self.assertEqual([row["id"] for row in self.review], [r["id"] for r in records])
        for row, record in zip(self.review, records):
            self.assertEqual(row["level"], record["level"].upper())
            self.assertEqual(row["ko"], record["title"]["ko"])
            self.assertEqual(row["de"], record["title"]["de"])
            self.assertEqual(row["en"], record["title"]["en"])
            self.assertEqual(row["상태"], "draft")
            self.assertTrue(row["field_notes"].strip())

    def test_manifest_links_and_backdrops_cover_every_scenario(self):
        ids = [record["id"] for record in self.draft["scenarios"]]
        self.assertEqual([link["contentId"] for link in self.manifest["contentLinks"]], ids)
        self.assertEqual(set(self.manifest["backdrops"]), set(ids))
        for link in self.manifest["contentLinks"]:
            self.assertEqual(link["role"], "practice")
            self.assertEqual(link["contentKind"], "scenario")

    def test_manifest_stays_review_only(self):
        self.assertEqual(self.manifest["status"], "review_only_draft")
        self.assertEqual(self.manifest["batch"], "11")
        self.assertEqual(self.manifest["provenance"]["rights"], "original")


if __name__ == "__main__":
    unittest.main()
