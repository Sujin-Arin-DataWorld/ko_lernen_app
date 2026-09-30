"""Focused regression contract for the recovered C4-G1 grammar set."""

from __future__ import annotations

import csv
import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GRAMMAR = ROOT / "assets" / "data" / "grammar.csv"
MANIFEST = ROOT / "assets" / "data" / "curriculum_manifest.json"
CORRESPONDENCE = (
    ROOT
    / "tools"
    / "content_factory"
    / "cefr_matrix"
    / "grammar_correspondence.json"
)
NIKL = (
    ROOT
    / "tools"
    / "content_factory"
    / "lexicon"
    / "nikl_kiiq_2017_grammar.csv"
)


NEW_IDS = {
    "grammar_b1_indirect_question": "B1",
    "grammar_b1_indirect_command": "B1",
    "grammar_b1_indirect_suggestion": "B1",
    "grammar_b1_conditional_geodeun": "B1",
    "grammar_b1_proportional_mankeum": "B1",
    "grammar_a2_toward_person": "A2",
    "grammar_a2_additive_location": "A2",
    "grammar_a2_starting_point": "A2",
    "grammar_a2_written_directive": "A2",
}

PRESERVED_IDS = {
    "grammar_b1_indirect_speech": "B1",
    "grammar_b2_indirect_speech": "B2",
    "grammar_a2_interrupted_action": "A2",
    "grammar_a2_tag_confirmation": "A2",
}

EXPECTED_UNITS = {
    "grammar_b1_indirect_speech": "b1_02_indirect_speech",
    "grammar_b1_indirect_question": "b1_02_indirect_speech",
    "grammar_b1_indirect_command": "b1_02_indirect_speech",
    "grammar_b1_indirect_suggestion": "b1_02_indirect_speech",
    "grammar_b1_conditional_geodeun": "b1_03_work_softening",
    "grammar_b1_proportional_mankeum": "b1_01_experience_reasons",
    "grammar_a2_interrupted_action": "a2_06_study_work",
    "grammar_a2_toward_person": "a2_03_chat_relationships",
    "grammar_a2_additive_location": "a2_08_home_money",
    "grammar_a2_starting_point": "a2_07_travel_repair",
    "grammar_a2_tag_confirmation": "a2_02_plans_proposals",
    "grammar_a2_written_directive": "a2_06_study_work",
}


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


class C4G1GrammarTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.rows = _rows(GRAMMAR)
        cls.by_id = {row["id"]: row for row in cls.rows}
        cls.manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        cls.correspondences = {
            row["sourceKey"]: row
            for row in json.loads(CORRESPONDENCE.read_text(encoding="utf-8"))[
                "correspondences"
            ]
        }

    def test_priority_rows_exist_without_replacing_existing_ids_or_levels(self):
        for grammar_id, level in {**PRESERVED_IDS, **NEW_IDS}.items():
            with self.subTest(grammar_id=grammar_id):
                self.assertIn(grammar_id, self.by_id)
                self.assertEqual(self.by_id[grammar_id]["level"], level)

        self.assertEqual(
            sum(row["id"] == "grammar_a2_interrupted_action" for row in self.rows),
            1,
        )
        self.assertEqual(
            sum(row["id"] == "grammar_b1_indirect_speech" for row in self.rows),
            1,
        )

    def test_four_indirect_speech_acts_are_separate_b1_learning_cards(self):
        patterns = {
            grammar_id: self.by_id[grammar_id]["pattern"]
            for grammar_id in (
                "grammar_b1_indirect_speech",
                "grammar_b1_indirect_question",
                "grammar_b1_indirect_command",
                "grammar_b1_indirect_suggestion",
            )
        }
        self.assertIn("는)다고", patterns["grammar_b1_indirect_speech"])
        self.assertIn("냐고", patterns["grammar_b1_indirect_question"])
        self.assertIn("라고", patterns["grammar_b1_indirect_command"])
        self.assertIn("자고", patterns["grammar_b1_indirect_suggestion"])

    def test_every_priority_card_has_two_aligned_examples(self):
        for grammar_id in (*NEW_IDS, "grammar_b1_indirect_speech", "grammar_a2_interrupted_action", "grammar_a2_tag_confirmation"):
            row = self.by_id[grammar_id]
            counts = {
                field: len([part for part in row[field].split(" / ") if part.strip()])
                for field in ("example_korean", "example_german", "example_en")
            }
            with self.subTest(grammar_id=grammar_id):
                self.assertEqual(counts, {
                    "example_korean": 2,
                    "example_german": 2,
                    "example_en": 2,
                })

    def test_distractors_are_three_distinct_same_level_cards(self):
        for grammar_id in (*NEW_IDS, "grammar_b1_indirect_speech", "grammar_a2_interrupted_action", "grammar_a2_tag_confirmation"):
            row = self.by_id[grammar_id]
            distractors = row["quiz_distractor_ids"].split("|")
            with self.subTest(grammar_id=grammar_id):
                self.assertEqual(len(distractors), 3)
                self.assertEqual(len(set(distractors)), 3)
                self.assertNotIn(grammar_id, distractors)
                for distractor_id in distractors:
                    self.assertIn(distractor_id, self.by_id)
                    self.assertEqual(self.by_id[distractor_id]["level"], row["level"])

    def test_geodeun_is_conditional_and_not_the_reason_ending(self):
        row = self.by_id["grammar_b1_conditional_geodeun"]
        self.assertEqual(
            row["type_en"],
            "Future condition before a request or suggestion",
        )
        self.assertIn("조건", row["note"])
        self.assertIn("condition", (row["explanation_en"] + row["note_en"]).lower())
        self.assertIn("Bedingung", row["explanation_de"] + row["note"])
        self.assertNotIn("reason", row["explanation_en"].lower())
        self.assertNotEqual(row["pattern"], self.by_id["grammar_b1_explanatory_reason"]["pattern"])

    def test_written_eul_geot_keeps_the_official_directive_meaning(self):
        nikl = {
            (row["grade"], row["form"]): row for row in _rows(NIKL)
        }
        self.assertEqual(nikl[("2", "-을 것1")]["meaning"], "명령/지시")

        row = self.by_id["grammar_a2_written_directive"]
        self.assertIn("지시", row["note"])
        self.assertIn("schrift", (row["explanation_de"] + row["note"]).lower())
        self.assertIn("written", (row["explanation_en"] + row["note_en"]).lower())
        self.assertIn("-는 것", row["note"])
        self.assertNotIn("future", row["explanation_en"].lower())

    def test_mankeum_teaches_the_completed_verb_form_used_by_its_quiz(self):
        row = self.by_id["grammar_b1_proportional_mankeum"]
        self.assertIn("연습한 만큼", row["example_korean"].split(" / ")[0])
        self.assertEqual(set(row["pattern"].split(" / ")), {
            "V-는 만큼", "V-(으)ㄴ 만큼", "A-(으)ㄴ 만큼",
        })
        for field in ("explanation_de", "explanation_en", "note", "note_en"):
            with self.subTest(field=field):
                self.assertIn("V-(으)ㄴ 만큼", row[field])
        self.assertIn("abgeschlossene", row["explanation_de"])
        self.assertIn("completed", row["explanation_en"])
        self.assertIn("완료", row["note"])
        packet = (ROOT / "docs/data/review_packets/c4_g1_grammar_jin_sample.md").read_text(encoding="utf-8")
        card_line = next(line for line in packet.splitlines() if line.startswith("| `grammar_b1_proportional_mankeum`"))
        self.assertIn(row["pattern"], card_line)

    def test_reviewed_correspondences_reuse_existing_cards(self):
        expected = {
            "G2:-다가1(1)": "grammar_a2_interrupted_action",
            "G3:-는다고3": "grammar_b1_indirect_speech",
        }
        for source_key, grammar_id in expected.items():
            with self.subTest(source_key=source_key):
                item = self.correspondences[source_key]
                self.assertIn(grammar_id, item["appGrammarIds"])
                self.assertEqual(item["reviewState"], "reviewed_source")
                self.assertEqual(item["semanticStatus"], "semantically_confirmed")

        partial = self.correspondences["G2:-지"]
        self.assertEqual(partial["appGrammarIds"], ["grammar_a2_tag_confirmation"])
        self.assertEqual(partial["reviewState"], "reviewed_source")
        self.assertEqual(
            partial["semanticStatus"],
            "observed_syntactic_candidate",
        )
        nikl = {(row["grade"], row["form"]): row for row in _rows(NIKL)}
        self.assertEqual(
            nikl[("2", "-지")]["meaning"],
            "서술, 물음, 명령, 요청",
        )
        self.assertIn("command", partial["rationale"]["meaning"].lower())
        self.assertIn("request", partial["rationale"]["meaning"].lower())

    def test_all_priority_cards_are_registered_in_intended_units(self):
        rule_map = self.manifest["grammarRuleMap"]
        for grammar_id, unit_id in EXPECTED_UNITS.items():
            with self.subTest(grammar_id=grammar_id):
                self.assertEqual(rule_map[grammar_id]["courseUnitId"], unit_id)


if __name__ == "__main__":
    unittest.main()
