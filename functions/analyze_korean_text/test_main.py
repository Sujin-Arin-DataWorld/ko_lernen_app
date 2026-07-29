"""Pure unit tests for language-sensitive grammar analysis."""

from __future__ import annotations

import json
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).parent))

from grammar_analysis import detect_grammar, localize_pos_tag, normalize_language


class LanguageAwareGrammarTest(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main()
