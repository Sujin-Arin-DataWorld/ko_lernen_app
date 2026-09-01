#!/usr/bin/env python3
"""Batch 14(A2·B1·B2 확장 7칸) 초안의 계약·초안↔live 일치·review projection 회귀.

Batch 11 테스트의 짝이다. 다른 점은 축이 레벨이 아니라 **한 레벨 안의 세 칸**이라는 것.
"""

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

import build_batch_14_scenarios as builder
from data.batch_14_scene_scripts import SCENES

ROOT = SCRIPT_DIR.parents[1]
CATEGORIES = ("enrolment", "booking", "insurance", "incident",
              "cancellation", "hiring", "privacy")
LEVELS = ("a2", "b1", "b2")
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
    def test_each_shelf_gets_exactly_four_scenes(self):
        # 칸당 4편이 Jin 지시다("레벨 c2까지 4편씩"). 세 칸 모두 같은 재고여야
        # 서재에서 한 칸만 유난히 얇아 보이지 않는다.
        for category in CATEGORIES:
            picked = [s for s in SCENES if s["category"] == category]
            self.assertEqual(len(picked), 4, f"{category} scene count")
        self.assertEqual(len(SCENES), 28)

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
        # 2026-08-18 이 배치는 승격됐다.  그래서 계약이 뒤집힌다: 예전에는
        # "초안 id 가 live 에 없어야 한다"(중복 승격 방지)였고, 지금은 "초안 id 가
        # 전부 live 에 있어야 한다"(초안↔live 이탈 방지)다.  후자가 더 강한 센서다 —
        # 씬 스크립트만 고치고 재승격을 잊으면 여기서 red 가 난다.
        canonical_runtime = json.loads(
            (ROOT / "assets/data/curriculum_manifest.json").read_text(encoding="utf-8")
        ).get("scenarioCorpusGeneration") == "canonical_120_v1"
        for scene in SCENES:
            assertion = self.assertNotIn if canonical_runtime else self.assertIn
            assertion(scene["id"], live_ids, scene["id"])
            for quest in scene["quests"]:
                assertion(quest["id"], live_quests, quest["id"])

    def test_dialog_is_eight_trilingual_turns(self):
        for scene in SCENES:
            self.assertEqual(len(scene["dialog"]), 8, f"{scene['id']} dialog length")
            for turn in scene["dialog"]:
                self.assertIn(turn["speaker"], ("user", scene["sidekick"]))
                for key in ("ko", "de", "en"):
                    self.assertTrue(turn[key].strip(), f"{scene['id']} empty {key}")

    def test_quest_types_match_the_level_contract(self):
        for scene in SCENES:
            # A2 이상에는 A1 전용 교정 퀘스트가 붙지 않는다.
            expected_types = QUEST_TYPES
            suffixes = builder.QUEST_SUFFIXES
            types = [quest["type"] for quest in scene["quests"]]
            self.assertEqual(
                sorted(types), sorted(expected_types), f"{scene['id']} quest types"
            )
            self.assertEqual(len(scene["quests"]), len(suffixes), scene["id"])
            for quest, suffix in zip(scene["quests"], suffixes):
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


class ShelfSlugContractTest(unittest.TestCase):
    def test_categories_are_the_declared_expansion_slugs(self):
        # 카테고리 철자가 shelf_assignment 의 확장 slug 와 어긋나면 칸이 조용히 빈다.
        from shelf_assignment import EXPANSION_SLUGS

        # 이 배치가 모든 확장칸을 덮지는 않는다 — a2_delivery 는 Batch 11 의
        # daily 편이 이미 채웠다. 그래서 "부분집합" 이 계약이고, "전부 찼는가" 는
        # test_shelf_assignment 의 unseeded 카운트가 지킨다.
        for level in LEVELS:
            authored = {s["category"] for s in SCENES if s["level"] == level}
            self.assertTrue(
                authored <= set(EXPANSION_SLUGS[level]),
                f"{level} 의 집필 카테고리가 확장 slug 밖이다: "
                f"{sorted(authored - set(EXPANSION_SLUGS[level]))}",
            )
            self.assertTrue(authored, level)


class BuildOutputTest(unittest.TestCase):
    def setUp(self):
        self.counts = builder.build()
        self.draft = json.loads(
            (ROOT / "tools/content_factory/drafts/c1_batch14_scenarios_a2_b2.json").read_text(encoding="utf-8"))
        self.manifest = json.loads(
            (ROOT / "tools/content_factory/drafts/batch_14_manifest.json").read_text(encoding="utf-8"))
        with (ROOT / "tools/content_factory/review/c1_batch14_scenarios.csv").open(
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
        self.assertEqual(self.manifest["batch"], "14")
        self.assertEqual(self.manifest["provenance"]["rights"], "original")


if __name__ == "__main__":
    unittest.main()
