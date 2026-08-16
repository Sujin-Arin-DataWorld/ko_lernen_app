"""Pure unit tests for language-sensitive grammar analysis."""

from __future__ import annotations

import json
import pathlib
import sys
import unittest
from types import SimpleNamespace

sys.path.insert(0, str(pathlib.Path(__file__).parent))

from grammar_analysis import detect_grammar, localize_pos_tag, normalize_language
from kiwipiepy import Kiwi


class LanguageAwareGrammarTest(unittest.TestCase):
    @staticmethod
    def _token(form: str, tag: str, start: int) -> SimpleNamespace:
        return SimpleNamespace(form=form, tag=tag, start=start, len=len(form))

    def test_normalizes_supported_variants_and_safely_defaults(self):
        self.assertEqual(normalize_language("EN-us"), "en")
        self.assertEqual(normalize_language("de_AT"), "de")
        self.assertEqual(normalize_language("fr"), "de")
        self.assertEqual(normalize_language(None), "de")

    def test_german_grammar_output_uses_german_pattern_content(self):
        grammar = detect_grammar("공부하고 있어요.", "de")

        self.assertTrue(grammar)
        self.assertIn("Progressiv", grammar[0]["nameDe"])
        self.assertIn("Handlung", grammar[0]["explanationDe"])

    def test_english_grammar_output_uses_curated_meaning(self):
        grammar = detect_grammar("공부하고 있어요.", "en-US")

        self.assertTrue(grammar)
        self.assertEqual(grammar[0]["nameDe"], "Progressive aspect (-고 있다)")
        self.assertIn("currently in progress", grammar[0]["explanationDe"])
        self.assertNotIn("Handlung", grammar[0]["explanationDe"])

    def test_topic_particle_is_not_guessed_as_an_attributive_ending(self):
        grammar = detect_grammar("저는 학생이에요.", "de")

        self.assertNotIn(
            "g_attribute_present", {item["id"] for item in grammar}
        )

    def test_attributive_forms_fail_closed_without_morphology_evidence(self):
        grammar = detect_grammar(
            "공부하는 학생이 좋은 책과 읽을 책을 골랐어요.",
            "de",
        )

        ids = {item["id"] for item in grammar}
        self.assertTrue(
            {
                "g_attribute_present",
                "g_attribute_past",
                "g_attribute_future",
            }.isdisjoint(ids)
        )

    def test_morphology_distinguishes_present_past_and_future_attributes(self):
        text = "좋은 책, 먹은 음식, 먹을 음식"
        tokens = [
            self._token("좋", "VA", 0),
            self._token("은", "ETM", 1),
            self._token("책", "NNG", 3),
            self._token(",", "SP", 4),
            self._token("먹", "VV", 6),
            self._token("은", "ETM", 7),
            self._token("음식", "NNG", 9),
            self._token(",", "SP", 11),
            self._token("먹", "VV", 13),
            self._token("을", "ETM", 14),
            self._token("음식", "NNG", 16),
        ]

        grammar = detect_grammar(text, "de", tokens=tokens)
        attributes = [
            item for item in grammar if item["id"].startswith("g_attribute_")
        ]

        self.assertEqual(
            [item["id"] for item in attributes],
            [
                "g_attribute_present",
                "g_attribute_past",
                "g_attribute_future",
            ],
        )
        self.assertEqual(
            [item["matched"] for item in attributes],
            ["좋은 책", "먹은 음식", "먹을 음식"],
        )

    def test_topic_particle_is_not_morphology_evidence(self):
        text = "저는 학생이에요."
        tokens = [
            self._token("저", "NP", 0),
            self._token("는", "JX", 1),
            self._token("학생", "NNG", 3),
        ]

        grammar = detect_grammar(text, "de", tokens=tokens)

        self.assertFalse(
            any(item["id"].startswith("g_attribute_") for item in grammar)
        )

    def test_kiwi_conjoining_jamo_endings_are_supported(self):
        text = "예쁜 꽃, 간 사람, 갈 사람"
        tokens = [
            SimpleNamespace(form="예쁘", tag="VA", start=0, len=2),
            SimpleNamespace(form="ᆫ", tag="ETM", start=1, len=1),
            self._token("꽃", "NNG", 3),
            self._token(",", "SP", 4),
            SimpleNamespace(form="가", tag="VV", start=6, len=1),
            SimpleNamespace(form="ᆫ", tag="ETM", start=6, len=1),
            self._token("사람", "NNG", 8),
            self._token(",", "SP", 10),
            SimpleNamespace(form="가", tag="VV", start=12, len=1),
            SimpleNamespace(form="ᆯ", tag="ETM", start=12, len=1),
            self._token("사람", "NNG", 14),
        ]

        grammar = detect_grammar(text, "de", tokens=tokens)
        attributes = [
            item for item in grammar if item["id"].startswith("g_attribute_")
        ]

        self.assertEqual(
            [(item["id"], item["matched"]) for item in attributes],
            [
                ("g_attribute_present", "예쁜 꽃"),
                ("g_attribute_past", "간 사람"),
                ("g_attribute_future", "갈 사람"),
            ],
        )

    def test_morphology_cards_use_requested_english_content(self):
        text = "좋은 책"
        tokens = [
            self._token("좋", "VA", 0),
            self._token("은", "ETM", 1),
            self._token("책", "NNG", 3),
        ]

        grammar = detect_grammar(text, "en", tokens=tokens)
        present = next(
            item for item in grammar if item["id"] == "g_attribute_present"
        )

        self.assertEqual(
            present["nameDe"], "Present attributive form (-는/-(으)ㄴ)"
        )
        self.assertIn("present action verbs", present["explanationDe"])

    def test_specific_conditional_suppresses_overlapping_general_match(self):
        grammar = detect_grammar("시간이 있다면 가요.", "de")

        ids = {item["id"] for item in grammar}
        self.assertIn("g_conditional_seasonal", ids)
        self.assertNotIn("g_conditional", ids)

    def test_distinct_general_and_specific_conditionals_are_both_kept(self):
        grammar = detect_grammar(
            "비가 오면 집에 있고, 시간이 있다면 책을 읽어요.",
            "de",
        )

        ids = {item["id"] for item in grammar}
        self.assertIn("g_conditional", ids)
        self.assertIn("g_conditional_seasonal", ids)

    def test_all_patterns_have_distinct_english_content_and_datasets_match(self):
        function_path = pathlib.Path(__file__).with_name("grammar_patterns.json")
        asset_path = (
            pathlib.Path(__file__).parents[2]
            / "assets"
            / "data"
            / "grammar_patterns.json"
        )
        self.assertEqual(function_path.read_bytes(), asset_path.read_bytes())
        patterns = json.loads(function_path.read_text(encoding="utf-8"))
        self.assertEqual(len(patterns), 31)
        for pattern in patterns:
            self.assertTrue(pattern["name_en"].strip(), pattern["id"])
            self.assertTrue(pattern["explanation_en"].strip(), pattern["id"])
            self.assertNotEqual(pattern["name_en"], pattern["name_de"])
            self.assertNotEqual(
                pattern["explanation_en"], pattern["explanation_de"]
            )
        by_id = {pattern["id"]: pattern for pattern in patterns}
        for pattern_id in (
            "g_attribute_present",
            "g_attribute_past",
            "g_attribute_future",
        ):
            self.assertEqual(by_id[pattern_id]["detector"], "morphology")
        self.assertEqual(
            by_id["g_conditional_seasonal"]["supersedes"],
            ["g_conditional"],
        )

    def test_curated_english_preserves_grammar_distinctions(self):
        path = pathlib.Path(__file__).with_name("grammar_patterns.json")
        patterns = {
            item["id"]: item
            for item in json.loads(path.read_text(encoding="utf-8"))
        }
        self.assertEqual(
            patterns["g_attribute_present"]["name_en"],
            "Present attributive form (-는/-(으)ㄴ)",
        )
        self.assertIn(
            "present action verbs",
            patterns["g_attribute_present"]["explanation_en"],
        )
        self.assertIn(
            "statement, question, command, or proposal",
            patterns["g_quote_indirect"]["explanation_en"],
        )
        self.assertEqual(
            patterns["g_with_hago"]["name_en"], "And / with (-하고)"
        )
        self.assertEqual(
            patterns["g_to_e"]["explanation_en"],
            "Marks the location where something exists, a destination, or a point in time.",
        )

    def test_part_of_speech_labels_follow_the_normalized_language(self):
        self.assertEqual(localize_pos_tag("NNG", "de"), "Nomen")
        self.assertEqual(localize_pos_tag("NNG", "en-US"), "Noun")
        self.assertEqual(localize_pos_tag("VV", "en"), "Verb")
        self.assertEqual(localize_pos_tag("VA", "en"), "Adjective")
        self.assertEqual(localize_pos_tag("UNKNOWN", "en"), "Word")


class RealKiwiGrammarRegressionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.kiwi = Kiwi()

    def test_real_kiwi_tokens_distinguish_attributive_forms(self):
        text = "좋은 책, 먹은 음식, 먹을 음식"
        tokens = self.kiwi.tokenize(text, normalize_coda=True)

        attributes = [
            item
            for item in detect_grammar(text, "de", tokens=tokens)
            if item["id"].startswith("g_attribute_")
        ]

        self.assertEqual(
            [(item["id"], item["matched"]) for item in attributes],
            [
                ("g_attribute_present", "좋은 책"),
                ("g_attribute_past", "먹은 음식"),
                ("g_attribute_future", "먹을 음식"),
            ],
        )

    def test_real_kiwi_topic_particle_is_not_attributive_evidence(self):
        text = "저는 학생이에요."
        tokens = self.kiwi.tokenize(text, normalize_coda=True)

        grammar = detect_grammar(text, "de", tokens=tokens)

        self.assertFalse(
            any(item["id"].startswith("g_attribute_") for item in grammar)
        )

    def test_structured_unit_separator_blocks_cross_card_morphology(self):
        text = "좋은。\n책이에요."
        tokens = self.kiwi.tokenize(text, normalize_coda=True)

        grammar = detect_grammar(text, "de", tokens=tokens)

        self.assertFalse(
            any(item["id"].startswith("g_attribute_") for item in grammar)
        )


if __name__ == "__main__":
    unittest.main()
