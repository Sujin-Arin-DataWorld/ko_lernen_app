#!/usr/bin/env python3
"""Regression tests for review-only Batch 17 social-topic content."""

from __future__ import annotations

from collections import Counter
import csv
import json
from pathlib import Path
import sys
import unittest

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import build_batch_17_social_topics as builder
import scenario_store
from data.batch_17_records import SCENES

ROOT = SCRIPT_DIR.parents[1]
EXPECTED = {
    "scenario": 12, "smalltalk": 24, "cloze": 36,
    "satz": 36, "pronunciation": 36, "quests": 60,
}
BEGINNER_SHELLS = {"안녕하세요", "감사합니다", "네, 알겠습니다.", "무엇을 도와드릴까요?"}


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def mapped_unit(value) -> str:
    if isinstance(value, str):
        return value
    if isinstance(value, dict):
        return str(value.get("courseUnitId") or "")
    return ""


class Batch17BuildTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.counts = builder.build(ROOT)
        cls.manifest = read_json(ROOT / builder.MANIFEST_PATH)
        cls.records = {}
        for artifact in cls.manifest["artifacts"]:
            payload = read_json(ROOT / artifact["draft"])
            cls.records[artifact["kind"]] = payload[artifact["collection"]]
        cls.curriculum = read_json(ROOT / "assets/data/curriculum_manifest.json")

    def test_exact_counts_and_level_balance(self):
        self.assertEqual(self.counts, EXPECTED)
        self.assertEqual(self.manifest["recordCount"], 144)
        self.assertEqual(self.manifest["questCount"], 60)
        expected_per_level = {
            "scenario": 4, "smalltalk": 8, "cloze": 12,
            "satz": 12, "pronunciation": 12,
        }
        for kind, per_level in expected_per_level.items():
            self.assertEqual(Counter(row["level"] for row in self.records[kind]), {
                "b2": per_level, "c1": per_level, "c2": per_level,
            })

    def test_four_topics_exist_once_per_level(self):
        matrix = Counter((scene["level"], scene["theme"]) for scene in SCENES)
        self.assertEqual(
            matrix,
            Counter({
                (level, theme): 1
                for level in ("b2", "c1", "c2")
                for theme in ("housing", "work_ai", "migration_demography", "k_culture")
            }),
        )

    def test_scenario_contract_and_quest_answer_uniqueness(self):
        for scene in self.records["scenario"]:
            self.assertEqual(len(scene["dialog"]), 8, scene["id"])
            self.assertEqual(len(scene["quests"]), 5, scene["id"])
            self.assertGreaterEqual(len(scene["vocab"]), 6, scene["id"])
            self.assertEqual([q["type"] for q in scene["quests"]], [
                "hoerverstehen", "uebersetzen", "luecken", "satzBauen", "diktat",
            ])
            for turn in scene["dialog"]:
                self.assertIn(turn["speaker"], ("user", scene["sidekick"]))
                for key in ("ko", "de", "en"):
                    self.assertTrue(turn[key].strip())
                self.assertNotIn(turn["ko"], BEGINNER_SHELLS)
            for quest in scene["quests"]:
                self.assertTrue(quest["id"].startswith(f"quest_{scene['id']}_"))
                self.assertEqual(quest["conceptIds"], scene["conceptIds"])
                data = quest["data"]
                if "options" in data:
                    values = [json.dumps(value, ensure_ascii=False, sort_keys=True) for value in data["options"]]
                    self.assertEqual(len(values), len(set(values)), quest["id"])
                    self.assertIn(data["correctIndex"], range(len(values)))

    def test_cloze_has_one_visible_blank_and_unique_answer(self):
        for item in self.records["cloze"]:
            self.assertEqual(item["sentenceKo"].count(builder.BLANK), 1, item["id"])
            self.assertEqual(item["fullKo"].count(item["answer"]), 1, item["id"])
            self.assertEqual(len(item["distractors"]), 3, item["id"])
            self.assertEqual(len(set(item["distractors"])), 3, item["id"])
            self.assertNotIn(item["answer"], item["distractors"])

    def test_existing_loader_routes_resolve(self):
        units = {unit["id"]: unit["level"] for unit in self.curriculum["courseUnits"]}
        for item in self.records["cloze"]:
            key = f"{item['level']}:{item['topic'].lower()}"
            unit = mapped_unit(self.curriculum["clozeTopicUnitMap"].get(key))
            self.assertEqual(unit, item["courseUnitId"], item["id"])
            self.assertEqual(units[unit], item["level"])
        for item in self.records["smalltalk"]:
            key = f"{item['level']}:{item['category'].lower()}"
            unit = mapped_unit(self.curriculum["smalltalkCategoryUnitMap"].get(key))
            self.assertEqual(units.get(unit), item["level"], item["id"])

        pack_unit = {
            key: mapped_unit(value)
            for key, value in self.curriculum["vocabPackUnitMap"].items()
        }
        vocab_source = {}
        with (ROOT / "assets/data/korean_vocab.csv").open(encoding="utf-8-sig", newline="") as handle:
            for row in csv.DictReader(handle):
                parts = row["pack_id"].lower().split("_")
                if parts and parts[-1].isdigit():
                    parts.pop()
                vocab_source.setdefault((row["level"].lower(), row["korean"]), []).append(pack_unit.get("_".join(parts)))
        for item in self.records["satz"]:
            routes = vocab_source.get((item["level"], item["vocabKo"]), [])
            self.assertEqual(routes, [item["courseUnitId"]], item["id"])

    def test_ids_match_promotion_state(self):
        canonical_runtime = self.curriculum.get("scenarioCorpusGeneration") == "canonical_120_v1"
        live = {
            "scenario": scenario_store.load_scenarios(ROOT / "assets/data"),
            "smalltalk": read_json(ROOT / "assets/data/smalltalk.json")["phrases"],
            "cloze": read_json(ROOT / "assets/data/cloze.json")["items"],
            "satz": read_json(ROOT / "assets/data/satz_sentences.json")["items"],
            "pronunciation": read_json(ROOT / "assets/data/pronunciation_phrases.json")["phrases"],
        }
        for kind, draft in self.records.items():
            live_ids = {row["id"] for row in live[kind]}
            draft_ids = [row["id"] for row in draft]
            self.assertEqual(len(draft_ids), len(set(draft_ids)), kind)
            overlap = live_ids.intersection(draft_ids)
            if canonical_runtime and kind == "scenario":
                self.assertFalse(overlap, kind)
            elif self.manifest["status"] == "merged":
                self.assertEqual(overlap, set(draft_ids), kind)
            else:
                self.assertFalse(overlap, kind)

    def test_review_ledgers_match_promotion_state(self):
        for artifact in self.manifest["artifacts"]:
            with (ROOT / artifact["review"]).open(encoding="utf-8-sig", newline="") as handle:
                rows = list(csv.DictReader(handle))
            records = self.records[artifact["kind"]]
            self.assertEqual([row["id"] for row in rows], [record["id"] for record in records])
            expected_status = "approved" if self.manifest["status"] == "merged" else "draft"
            self.assertTrue(all(row["상태"] == expected_status for row in rows))
            self.assertTrue(all(row["field_notes"].strip() for row in rows))
            if expected_status == "approved":
                self.assertTrue(all(row["jin_memo"].strip() for row in rows))
            else:
                self.assertTrue(all(not row["jin_memo"] for row in rows))

    def test_manifest_matches_review_or_promotion_state(self):
        self.assertIn(self.manifest["status"], {"review_only_draft", "merged"})
        self.assertEqual(self.manifest["batch"], "17")
        self.assertTrue(self.manifest["provenance"]["requiresJinReview"])
        self.assertEqual(self.manifest["provenance"]["rights"], "original_clean_room")
        self.assertEqual(len(self.manifest["contentLinks"]), 12)
        self.assertEqual(set(self.manifest["backdrops"]), {scene["id"] for scene in self.records["scenario"]})


if __name__ == "__main__":
    unittest.main()
