from __future__ import annotations

import unittest

from tools.content_factory.build_productive_assessments import (
    reviewed_dictation_variants,
)


class ReviewedDictationVariantsTest(unittest.TestCase):
    def test_defaults_to_the_canonical_example(self) -> None:
        self.assertEqual(
            reviewed_dictation_variants("안녕하세요.", None),
            ["안녕하세요."],
        )

    def test_adds_reviewed_surface_variants_after_the_canonical(self) -> None:
        self.assertEqual(
            reviewed_dictation_variants("다시 말씀드릴게요.", ["다시 말씀 드릴게요"]),
            ["다시 말씀드릴게요.", "다시 말씀 드릴게요"],
        )

    def test_accepts_reviewed_unicode_punctuation_changes(self) -> None:
        self.assertEqual(
            reviewed_dictation_variants(
                "안내: ‘다시 말씀드릴게요.’",
                ["안내 다시 말씀드릴게요"],
            ),
            ["안내: ‘다시 말씀드릴게요.’", "안내 다시 말씀드릴게요"],
        )

    def test_rejects_semantic_paraphrases(self) -> None:
        with self.assertRaisesRegex(ValueError, "lexical sequence"):
            reviewed_dictation_variants(
                "다시 말씀드릴게요.",
                ["나중에 연락드릴게요."],
            )

    def test_rejects_duplicate_or_canonical_entries(self) -> None:
        with self.assertRaisesRegex(ValueError, "additional unique"):
            reviewed_dictation_variants("안녕하세요.", ["안녕하세요."])


if __name__ == "__main__":
    unittest.main()
