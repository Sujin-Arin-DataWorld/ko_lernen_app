#!/usr/bin/env python3
"""Live scenario/grammar level contracts added by LCP Stage C-3."""

from __future__ import annotations

import csv
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LEVEL_RANK = {level: rank for rank, level in enumerate(
    ("a1", "a2", "b1", "b2", "c1", "c2"), start=1
)}
C3_IDS = (
    "a1_w10_partner",
    "a1_w10_fandom",
    "b1_w10_insurance",
    "b2_w10_travel",
    "b2_w10_hiring",
    "b2_w10_authorities",
)
SOURCE_FILES = {
    "a1_w10_partner": (
        "tools/content_factory/drafts/w10_scenarios_a1.json",
        "tools/content_factory/drafts/w10_wave1_scenario.json",
    ),
    "a1_w10_fandom": (
        "tools/content_factory/drafts/w10_scenarios_a1.json",
        "tools/content_factory/drafts/w10_wave1_scenario.json",
    ),
    "b1_w10_insurance": (
        "tools/content_factory/drafts/w10_scenarios_b1.json",
        "tools/content_factory/drafts/w10_wave1_scenario.json",
    ),
    "b2_w10_travel": (
        "tools/content_factory/drafts/w10_scenarios_b2.json",
        "tools/content_factory/drafts/w10_wave2_scenario.json",
    ),
    "b2_w10_hiring": (
        "tools/content_factory/drafts/w10_scenarios_b2.json",
        "tools/content_factory/drafts/w10_wave2_scenario.json",
    ),
    "b2_w10_authorities": (
        "tools/content_factory/drafts/w10_scenarios_b2.json",
        "tools/content_factory/drafts/w10_wave2_scenario.json",
    ),
}


def _scenario_array(payload: object) -> list[dict]:
    if isinstance(payload, list):
        return [item for item in payload if isinstance(item, dict)]
    if isinstance(payload, dict):
        for key in ("scenarios", "items", "records"):
            value = payload.get(key)
            if isinstance(value, list):
                return [item for item in value if isinstance(item, dict)]
    return []


def _read_json(relative: str) -> object:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def _live_scenarios() -> dict[str, dict]:
    result: dict[str, dict] = {}
    for path in sorted((ROOT / "assets" / "data").glob("scenarios_*.json")):
        for scenario in _scenario_array(
            json.loads(path.read_text(encoding="utf-8"))
        ):
            result[scenario["id"]] = scenario
    return result


class ScenarioGrammarLevelContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.live = _live_scenarios()
        with (ROOT / "assets/data/grammar.csv").open(
            encoding="utf-8", newline=""
        ) as handle:
            cls.grammar_levels = {
                row["id"]: row["level"].strip().lower()
                for row in csv.DictReader(handle)
            }

    def test_live_scenarios_never_reference_grammar_above_their_level(self) -> None:
        violations: list[str] = []
        for scenario_id, scenario in sorted(self.live.items()):
            scenario_level = scenario["level"].strip().lower()
            for grammar_id in scenario.get("grammarIds", []):
                grammar_level = self.grammar_levels.get(grammar_id)
                if grammar_level is None:
                    violations.append(
                        f"{scenario_id}: unknown grammar {grammar_id}"
                    )
                    continue
                if LEVEL_RANK[grammar_level] > LEVEL_RANK[scenario_level]:
                    violations.append(
                        f"{scenario_id}({scenario_level}) -> "
                        f"{grammar_id}({grammar_level})"
                    )
        self.assertEqual(violations, [])

    def test_c3_w10_authoring_sources_match_live_objects(self) -> None:
        for scenario_id in C3_IDS:
            with self.subTest(scenario=scenario_id):
                live = self.live[scenario_id]
                for relative in SOURCE_FILES[scenario_id]:
                    matches = [
                        item
                        for item in _scenario_array(_read_json(relative))
                        if item.get("id") == scenario_id
                    ]
                    self.assertEqual(
                        len(matches),
                        1,
                        f"{relative}: expected one {scenario_id}",
                    )
                    self.assertEqual(matches[0], live)

    def test_a1_partner_no_longer_teaches_the_a2_recipient_particle(self) -> None:
        scenario = self.live["a1_w10_partner"]
        encoded = json.dumps(scenario, ensure_ascii=False)
        self.assertNotIn("어머니께", encoded)
        self.assertIn("어머니한테", encoded)
        self.assertNotIn("grammar_a1_honorific_kke", scenario["grammarIds"])

    def test_insurance_listening_copy_matches_the_revised_dialogue(self) -> None:
        lessons = _read_json("assets/data/listening_lessons.json")
        lesson_list = lessons["lessons"] if isinstance(lessons, dict) else lessons
        lesson = next(
            item
            for item in lesson_list
            if "b1_w10_insurance" in item.get("contentIds", [])
        )
        encoded = json.dumps(lesson, ensure_ascii=False)
        ko = "보험 내용과 받은 진료를 먼저 확인해야 해요. 확인한 뒤에 알려 드릴게요."
        de = (
            "Wir müssen zuerst Ihren Tarif und die Behandlung prüfen. "
            "Danach kann ich Ihnen Bescheid geben."
        )
        en = (
            "We need to check your coverage and the treatment first. "
            "Then I can let you know."
        )
        self.assertIn(ko, encoded)
        self.assertIn(de, encoded)
        self.assertIn(en, encoded)
        self.assertNotIn(
            "Ob es gedeckt ist, müssen wir anhand Ihres Tarifs und der "
            "Behandlung prüfen.",
            encoded,
        )
        self.assertNotIn(
            "We need to check your coverage and the treatment you received "
            "before we can tell.",
            encoded,
        )


if __name__ == "__main__":
    unittest.main()
