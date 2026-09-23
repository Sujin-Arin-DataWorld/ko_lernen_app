"""Regression tests for the reviewed semantic grammar correspondence catalog."""

from __future__ import annotations

import csv
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from build_level_bible_tables import (  # noqa: E402
    REPO,
    build_f1,
    load_grammar_correspondences,
)


EXPECTED = {
    "G1:이다": ("grammar_a1_copula_polite", "학생이에요.", "match"),
    "G1:이 아니다": ("grammar_a1_copula_negation", "학생이 아니에요.", "match"),
    "G1:-겠-": ("grammar_a2_intention_guess", "제가 하겠어요.", "match"),
    "G3:-고 나다": (
        "grammar_a2_after_finishing",
        "숙제를 하고 나서 놀아요.",
        "level_mismatch",
    ),
    "G3:-으면 좋겠다": (
        "grammar_a2_preference_soft_batch20",
        "관리비가 계약서에 따로 적혀 있으면 좋겠어요.",
        "level_mismatch",
    ),
    "G2:-지 말다": (
        "grammar_a1_polite_prohibition",
        "여기서 사진 찍지 마세요.",
        "match",
    ),
    "G2:-다가1(1)": (
        "grammar_a2_interrupted_action",
        "숙제를 하다가 텔레비전을 봤습니다. / 집에 가다가 친구를 만났어.",
        "match",
    ),
}


def _read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as fh:
        return list(csv.DictReader(fh))


class GrammarCorrespondenceCatalogTest(unittest.TestCase):
    def test_reviewed_catalog_resolves_exact_cards_and_current_levels(self):
        grammar_rows = _read_csv(REPO / "assets" / "data" / "grammar.csv")
        nikl_rows = _read_csv(
            REPO
            / "tools"
            / "content_factory"
            / "lexicon"
            / "nikl_kiiq_2017_grammar.csv"
        )
        correspondences = load_grammar_correspondences(
            REPO, grammar_rows, nikl_rows
        )
        self.assertEqual(
            {item.source_key for item in correspondences} - {"G1:-지 않다"},
            set(EXPECTED) | {"G2:-지", "G3:-는다고3", "G3:-으나", "G3:이고", "G3:-거든2"},
        )

        result = build_f1(grammar_rows, nikl_rows, correspondences)
        rows = {
            f"G{row.nikl_grade}:{row.nikl_form}": row for row in result.rows
        }
        app_by_id = {row["id"]: row for row in grammar_rows}
        self.assertEqual(app_by_id["grammar_a2_intention_guess"]["level"], "A1")
        self.assertEqual(app_by_id["grammar_a2_after_finishing"]["level"], "A2")
        self.assertEqual(app_by_id["grammar_a1_polite_prohibition"]["level"], "A2")
        for source_key, (app_id, example, status) in EXPECTED.items():
            with self.subTest(source_key=source_key):
                row = rows[source_key]
                self.assertEqual(row.matched_app_ids, (app_id,))
                self.assertEqual(row.status, status)
                self.assertEqual(app_by_id[app_id]["example_korean"], example)

        quotation = rows["G3:-는다고3"]
        self.assertEqual(quotation.status, "match")
        self.assertEqual(
            quotation.matched_app_ids,
            (
                "grammar_b1_indirect_command",
                "grammar_b1_indirect_question",
                "grammar_b1_indirect_speech",
                "grammar_b1_indirect_suggestion",
            ),
        )

        self.assertEqual(rows["G1:-지 않다"].status, "match")
        self.assertEqual(
            rows["G1:-지 않다"].matched_app_ids,
            ("grammar_a1_long_negation",),
        )

        partial_ji = rows["G2:-지"]
        self.assertEqual(partial_ji.status, "missing_in_app")
        self.assertEqual(partial_ji.matched_app_ids, ())
        correspondence_by_key = {item.source_key: item for item in correspondences}
        for source_key in ("G3:-으나", "G3:이고", "G3:-거든2"):
            with self.subTest(unconfirmed_source_key=source_key):
                correspondence = correspondence_by_key[source_key]
                self.assertEqual(correspondence.review_state, "observed_syntactic_candidate")
                self.assertEqual(correspondence.semantic_status, "observed_syntactic_candidate")
                self.assertFalse(correspondence.is_confirmed_semantic_match)
        self.assertEqual(
            correspondence_by_key["G2:-지"].semantic_status,
            "observed_syntactic_candidate",
        )

    def test_unrelated_particle_and_ending_are_not_confirmed_by_catalog(self):
        grammar_rows = _read_csv(REPO / "assets" / "data" / "grammar.csv")
        nikl_rows = _read_csv(
            REPO
            / "tools"
            / "content_factory"
            / "lexicon"
            / "nikl_kiiq_2017_grammar.csv"
        )
        correspondences = load_grammar_correspondences(
            REPO, grammar_rows, nikl_rows
        )
        confirmed_keys = {item.source_key for item in correspondences}
        self.assertNotIn("G1:이", confirmed_keys)
        self.assertIn("G2:-지", confirmed_keys)
        result = build_f1(grammar_rows, nikl_rows, correspondences)
        rows = {
            f"G{row.nikl_grade}:{row.nikl_form}": row for row in result.rows
        }
        self.assertNotEqual(rows["G1:이"].matched_app_ids, ("grammar_a1_copula_polite",))
        self.assertIn("G2:-지", rows)


if __name__ == "__main__":
    unittest.main()
