"""Pure unit tests for language-sensitive grammar analysis."""

from __future__ import annotations

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

    def test_english_grammar_output_uses_explicit_english_fallback(self):
        grammar = detect_grammar("공부하고 있어요.", "en-US")

        self.assertTrue(grammar)
        self.assertIn("Korean grammar", grammar[0]["nameDe"])
        self.assertIn("detected", grammar[0]["explanationDe"])
        self.assertNotIn("Handlung", grammar[0]["explanationDe"])

    def test_part_of_speech_labels_follow_the_normalized_language(self):
        self.assertEqual(localize_pos_tag("NNG", "de"), "Nomen")
        self.assertEqual(localize_pos_tag("NNG", "en-US"), "Noun")
        self.assertEqual(localize_pos_tag("VV", "en"), "Verb")
        self.assertEqual(localize_pos_tag("VA", "en"), "Adjective")
        self.assertEqual(localize_pos_tag("UNKNOWN", "en"), "Word")


if __name__ == "__main__":
    unittest.main()
