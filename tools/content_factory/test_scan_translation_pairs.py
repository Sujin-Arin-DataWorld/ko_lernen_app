#!/usr/bin/env python3
"""Tests for scan_translation_pairs.py: one positive/negative pair per rule
(R1-R8), plus a live ratchet asserting the current A1 corpus has 0
UNEXPLAINED lint hits (every raw hit is either fixed or a documented,
justified false positive -- see the scanner's DOCUMENTED_FALSE_POSITIVES).
"""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "content_factory"))

import scan_translation_pairs as s  # noqa: E402


def _row(**overrides):
    row = {
        "id": "vocab_a1_0000",
        "korean": "테스트",
        "german": "Test",
        "english": "test",
        "example_korean": "저는 테스트를 해요.",
        "example_german": "Ich mache einen Test.",
        "example_english": "I do a test.",
        "level": "A1",
    }
    row.update(overrides)
    return row


class R1EnglishInDeTest(unittest.TestCase):
    def test_positive_english_token_in_german_field(self):
        row = _row(example_german="Ich mache das with meiner Familie.")
        hits = [r for r, _d in s.scan_row(row)]
        self.assertIn("R1", hits)

    def test_negative_real_german_word_also_not_flagged(self):
        # "also" is real German ("therefore"), not the English "also" --
        # regression guard for the vocab_a1_0218/0249 false positive fixed
        # 2026-09-15.
        row = _row(example_german="Die Anrede war schwierig, also habe ich gefragt.")
        hits = [r for r, _d in s.scan_row(row)]
        self.assertNotIn("R1", hits)


class R2CalqueTest(unittest.TestCase):
    def test_positive_fronted_infinitive_calque(self):
        row = _row(example_german="Das zu besprechen vereinbarten wir gestern.")
        hits = [r for r, _d in s.scan_row(row)]
        self.assertIn("R2", hits)

    def test_negative_normal_word_order_not_flagged(self):
        row = _row(example_german="Wir haben vereinbart, das zu besprechen.")
        hits = [r for r, _d in s.scan_row(row)]
        self.assertNotIn("R2", hits)


class R3HeadwordMissingTest(unittest.TestCase):
    def test_positive_headword_absent(self):
        row = _row(korean="사과", example_korean="저는 매일 운동해요.")
        hits = [r for r, _d in s.scan_row(row)]
        self.assertIn("R3", hits)

    def test_negative_headword_present(self):
        row = _row(korean="사과", example_korean="저는 사과를 먹어요.")
        hits = [r for r, _d in s.scan_row(row)]
        self.assertNotIn("R3", hits)


class R4LengthRatioTest(unittest.TestCase):
    def test_positive_truncated_translation(self):
        row = _row(example_korean="저는 오늘 학교에서 친구를 만나고 같이 점심을 먹었어요.", example_german="Ja.")
        hits = [r for r, _d in s.scan_row(row)]
        self.assertIn("R4", hits)

    def test_negative_proportionate_translation(self):
        row = _row(example_korean="저는 밥을 먹어요.", example_german="Ich esse Reis.")
        hits = [r for r, _d in s.scan_row(row)]
        self.assertNotIn("R4", hits)


class R5DuSieMixedTest(unittest.TestCase):
    def test_positive_du_and_sie_in_one_sentence(self):
        row = _row(example_german="Kannst du mir sagen, wann Sie ankommen?")
        hits = [r for r, _d in s.scan_row(row)]
        self.assertIn("R5", hits)

    def test_negative_sentence_initial_sie_not_flagged(self):
        # sentence-initial "Sie" is ambiguous with "sie" (she/they)
        # capitalized only by position -- not counted as the formal marker.
        row = _row(example_german="Sie geht jetzt nach Hause, weil du müde bist.")
        hits = [r for r, _d in s.scan_row(row)]
        self.assertNotIn("R5", hits)


class R6DashTest(unittest.TestCase):
    def test_positive_en_dash(self):
        row = _row(example_german="Ich komme – vielleicht.")
        hits = [r for r, _d in s.scan_row(row)]
        self.assertIn("R6", hits)

    def test_negative_hyphen_not_flagged(self):
        row = _row(example_german="Ich komme - vielleicht.")
        hits = [r for r, _d in s.scan_row(row)]
        self.assertNotIn("R6", hits)


class R7IdenticalTest(unittest.TestCase):
    def test_positive_identical_example_sentences(self):
        row = _row(example_german="I go to school every day.", example_english="I go to school every day.")
        hits = [r for r, _d in s.scan_row(row)]
        self.assertIn("R7", hits)

    def test_negative_short_cognate_gloss_not_flagged(self):
        row = _row(german="Bus", english="Bus")
        hits = [r for r, _d in s.scan_row(row)]
        self.assertNotIn("R7", hits)


class R8QuestionMismatchTest(unittest.TestCase):
    def test_positive_ko_question_de_statement(self):
        row = _row(example_korean="이거 얼마예요?", example_german="Das kostet zehn Euro.")
        hits = [r for r, _d in s.scan_row(row)]
        self.assertIn("R8", hits)

    def test_negative_both_questions(self):
        row = _row(
            korean="이거",
            example_korean="이거 얼마예요?",
            example_german="Wie viel kostet das?",
            example_english="How much is this?",
        )
        hits = [r for r, _d in s.scan_row(row)]
        self.assertNotIn("R8", hits)


class A1LiveRatchetTest(unittest.TestCase):
    """Live ratchet: every raw lint hit against the CURRENT A1 corpus must
    be a documented, justified false positive (see scanner's
    DOCUMENTED_FALSE_POSITIVES). A new, unexplained hit fails this test --
    either fix the row or add a justified exception."""

    def test_a1_corpus_has_zero_unexplained_hits(self):
        rows = s.load_rows()
        a1_rows = [r for r in rows if (r.get("level") or "").strip().upper() == "A1"]
        unexplained = []
        for row in a1_rows:
            for rule_id, detail in s.scan_row(row):
                if not s.is_documented_false_positive(rule_id, row["id"]):
                    unexplained.append((rule_id, row["id"], detail))
        self.assertEqual(
            unexplained, [],
            f"unexplained lint hits against live A1 corpus: {unexplained}",
        )


if __name__ == "__main__":
    unittest.main()
