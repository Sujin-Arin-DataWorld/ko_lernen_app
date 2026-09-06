"""Unit tests for tool/audit_grammar_card_faces.py -- W10 PR-A T-G4.

2 개 테스트, 지시서 3항 요구대로:
  (a) 규칙(rule)이 있고 예문이 2개인 행은 flag 안 됨; rule 이 비고 예문이
      1개인 행은 flag 됨.
  (b) 생성된 마크다운 리포트에 레벨별 표와 flag 된 id 가 실제로 들어있음.

CI 배선은 파일 패턴 자동이다 (`tool/test_*.py`, 선례:
tool/test_audit_vocab_levels.py) -- ci.yml 을 고칠 필요 없음.
"""

from __future__ import annotations

import csv
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import audit_grammar_card_faces as audit  # noqa: E402

CSV_HEADER = [
    "pattern",
    "level",
    "type_de",
    "explanation_de",
    "example_korean",
    "example_german",
    "note",
    "type_en",
    "explanation_en",
    "example_en",
    "note_en",
    "id",
    "quiz_focus_de",
    "quiz_focus_en",
    "quiz_enabled",
    "quiz_distractor_ids",
]


def _row(
    *,
    row_id: str,
    pattern: str = "N은/는",
    level: str = "A1",
    type_de: str = "Thema-Partikel",
    explanation_de: str,
    example_korean: str,
    example_german: str,
    note: str = "",
) -> dict[str, str]:
    return {
        "pattern": pattern,
        "level": level,
        "type_de": type_de,
        "explanation_de": explanation_de,
        "example_korean": example_korean,
        "example_german": example_german,
        "note": note,
        "type_en": "",
        "explanation_en": "",
        "example_en": "",
        "note_en": "",
        "id": row_id,
        "quiz_focus_de": "",
        "quiz_focus_en": "",
        "quiz_enabled": "",
        "quiz_distractor_ids": "",
    }


class DeriveFacesTest(unittest.TestCase):
    def test_rule_and_two_examples_is_not_flagged(self) -> None:
        row = _row(
            row_id="grammar_a1_has_rule",
            explanation_de="Markiert das Satzthema. Nach Konsonant: 은 · Nach Vokal: 는",
            example_korean="저는 학생이에요. / 학교는 커요.",
            example_german="Ich bin Student. / Die Schule ist groß.",
        )
        faces = audit.derive_faces(row)
        self.assertEqual(faces.rules, ["Nach Konsonant: 은", "Nach Vokal: 는"])
        self.assertEqual(len(faces.examples), 2)
        self.assertFalse(faces.back_adds_nothing)

    def test_empty_rule_and_one_example_is_flagged(self) -> None:
        row = _row(
            row_id="grammar_a1_no_rule",
            explanation_de="Nur eine kurze Erklärung ohne weitere Klauseln.",
            example_korean="집에 가요.",
            example_german="Ich gehe nach Hause.",
        )
        faces = audit.derive_faces(row)
        self.assertEqual(faces.rules, [])
        self.assertEqual(len(faces.examples), 1)
        self.assertEqual(faces.note, "")
        self.assertTrue(faces.back_adds_nothing)


class ReportTest(unittest.TestCase):
    def test_report_contains_level_table_and_flagged_id(self) -> None:
        rows = [
            _row(
                row_id="grammar_a1_flagged",
                level="A1",
                explanation_de="Nur eine kurze Erklärung ohne weitere Klauseln.",
                example_korean="집에 가요.",
                example_german="Ich gehe nach Hause.",
            ),
            _row(
                row_id="grammar_a2_not_flagged",
                level="A2",
                explanation_de="Erklärung mit Regel. Nach Konsonant: 아 · Nach Vokal: 야",
                example_korean="밥을 먹었어요. / 물을 마셨어요.",
                example_german="Ich habe Reis gegessen. / Ich habe Wasser getrunken.",
            ),
        ]
        faces = audit.audit(rows)

        with tempfile.TemporaryDirectory() as tmp:
            out_path = Path(tmp) / "grammar_card_faces_report.md"
            audit.write_report(faces, out_path)
            text = out_path.read_text(encoding="utf-8")

        self.assertIn("| level | rows | flagged | pct |", text)
        self.assertIn("| A1 | 1 | 1 | 100.0% |", text)
        self.assertIn("| A2 | 1 | 0 | 0.0% |", text)
        self.assertIn("grammar_a1_flagged", text)
        self.assertNotIn("grammar_a2_not_flagged", text)


class CsvLoadingTest(unittest.TestCase):
    def test_load_rows_round_trips_through_real_csv_writer(self) -> None:
        row = _row(
            row_id="grammar_a1_csv_roundtrip",
            explanation_de="Nur eine kurze Erklärung ohne weitere Klauseln.",
            example_korean="집에 가요.",
            example_german="Ich gehe nach Hause.",
        )
        with tempfile.TemporaryDirectory() as tmp:
            csv_path = Path(tmp) / "grammar.csv"
            with csv_path.open("w", encoding="utf-8", newline="") as f:
                writer = csv.DictWriter(f, fieldnames=CSV_HEADER, lineterminator="\n")
                writer.writeheader()
                writer.writerow(row)

            rows = audit.load_rows(csv_path)

        self.assertEqual(len(rows), 1)
        faces = audit.derive_faces(rows[0])
        self.assertTrue(faces.back_adds_nothing)


if __name__ == "__main__":
    unittest.main()
