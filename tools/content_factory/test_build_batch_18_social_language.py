#!/usr/bin/env python3
"""Regression tests for Batch 18 social-language content."""

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

import build_batch_18_social_language as builder
from data.batch_18_social_language import GRAMMAR, SMALLTALK, VOCAB


ROOT = SCRIPT_DIR.parents[1]
EXPECTED = {"vocab": 36, "grammar": 12, "smalltalk": 12, "cloze": 36, "satz": 36, "records": 132}


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


class Batch18BuildTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.counts = builder.build(ROOT)
        cls.manifest = read_json(ROOT / builder.MANIFEST_PATH)
        cls.records = {
            "vocab": read_csv(ROOT / builder.DRAFT_PATHS["vocab"]),
            "grammar": read_csv(ROOT / builder.DRAFT_PATHS["grammar"]),
            "smalltalk": read_json(ROOT / builder.DRAFT_PATHS["smalltalk"])["phrases"],
            "cloze": read_json(ROOT / builder.DRAFT_PATHS["cloze"])["items"],
            "satz": read_json(ROOT / builder.DRAFT_PATHS["satz"])["items"],
        }

    def test_exact_counts_and_level_balance(self):
        self.assertEqual(self.counts, EXPECTED)
        self.assertEqual(self.manifest["recordCount"], 132)
        for kind, per_level in {"vocab": 12, "grammar": 4, "smalltalk": 4, "cloze": 12, "satz": 12}.items():
            self.assertEqual(Counter(row["level"].lower() for row in self.records[kind]), {
                "b2": per_level, "c1": per_level, "c2": per_level,
            })

    def test_four_theme_matrix_is_complete(self):
        expected = Counter({(level, theme): 3 for level in builder.LEVELS for theme in builder.THEMES})
        actual = Counter((level, item["theme"]) for level, values in VOCAB.items() for item in values)
        self.assertEqual(actual, expected)
        self.assertEqual(
            Counter((item["level"].lower(), item["theme"]) for item in GRAMMAR),
            Counter({(level, theme): 1 for level in builder.LEVELS for theme in builder.THEMES}),
        )
        self.assertEqual(
            Counter((item["level"].lower(), item["theme"]) for item in SMALLTALK),
            Counter({(level, theme): 1 for level in builder.LEVELS for theme in builder.THEMES}),
        )

    def test_vocabulary_cards_are_complete_and_originally_routed(self):
        for row in self.records["vocab"]:
            self.assertEqual(row["example_korean"].count(row["korean"]), 1, row["id"])
            self.assertTrue(row["example_german"].strip(), row["id"])
            self.assertTrue(row["example_english"].strip(), row["id"])
            self.assertRegex(row["id"], r"^vocab_(b2|c1|c2)_\d{4}$")
        for level in builder.LEVELS:
            level_rows = [row for row in self.records["vocab"] if row["level"].lower() == level]
            self.assertEqual([row["pack_order"] for row in level_rows], [str(i) for i in range(1, 13)])
            self.assertEqual([row["pack_order"] for row in level_rows if row["is_review_boss"] == "true"], ["10", "11", "12"])

    def test_grammar_quiz_focus_and_distractors_are_valid(self):
        with (ROOT / "assets/data/grammar.csv").open(encoding="utf-8-sig", newline="") as handle:
            live_ids = {row["id"] for row in csv.DictReader(handle)}
        new_ids = {row["id"] for row in self.records["grammar"]}
        for row in self.records["grammar"]:
            self.assertEqual(row["quiz_enabled"], "true")
            self.assertEqual(row["example_german"].count(row["quiz_focus_de"]), 1, row["id"])
            self.assertEqual(row["example_en"].count(row["quiz_focus_en"]), 1, row["id"])
            distractors = row["quiz_distractor_ids"].split("|")
            self.assertEqual(len(set(distractors)), 3, row["id"])
            self.assertTrue(set(distractors).issubset(live_ids - new_ids), row["id"])

    def test_smalltalk_preserves_one_trilingual_event(self):
        for row in self.records["smalltalk"]:
            self.assertEqual(row["kind"], "question")
            self.assertEqual(row["relationshipContext"], "coworker")
            self.assertEqual(row["safeAlternativeQuestions"][0]["turnKind"], "question")
            self.assertEqual(row["followUp"]["turnKind"], "reaction")
            for field in ("ko", "de", "en"):
                self.assertTrue(row[field].strip(), row["id"])
                self.assertTrue(row["reply"][field].strip(), row["id"])
                self.assertTrue(row["safeAlternativeQuestions"][0][field].strip(), row["id"])
                self.assertTrue(row["followUp"][field].strip(), row["id"])

    def test_cloze_and_satz_are_one_to_one_derivations(self):
        vocab_by_level = {
            level: [row for row in self.records["vocab"] if row["level"].lower() == level]
            for level in builder.LEVELS
        }
        for level in builder.LEVELS:
            cloze = [row for row in self.records["cloze"] if row["level"] == level]
            satz = [row for row in self.records["satz"] if row["level"] == level]
            for vocab, gap, sentence in zip(vocab_by_level[level], cloze, satz):
                self.assertEqual(gap["fullKo"], vocab["example_korean"])
                self.assertEqual(gap["answer"], vocab["korean"])
                self.assertEqual(gap["sentenceKo"].count(builder.BLANK), 1)
                self.assertEqual(len(set(gap["distractors"])), 3)
                self.assertNotIn(gap["answer"], gap["distractors"])
                self.assertEqual(sentence["targetKo"], vocab["example_korean"])
                self.assertEqual(sentence["vocabKo"], vocab["korean"])
                self.assertTrue(all(word not in sentence["targetKo"] for word in sentence["distractors"]), sentence["id"])

    def test_manifest_declares_every_runtime_route(self):
        grammar_routes = {item["id"] for item in self.manifest["grammarIntents"]}
        self.assertEqual(grammar_routes, {row["id"] for row in self.records["grammar"]})
        smalltalk_routes = {(item["level"], item["category"]) for item in self.manifest["smalltalkCategoryMappings"]}
        self.assertTrue({(row["level"], row["category"]) for row in self.records["smalltalk"]}.issubset(smalltalk_routes))
        cloze_routes = {(item["level"], item["topic"].lower()) for item in self.manifest["clozeTopicMappings"]}
        self.assertEqual(cloze_routes, {(row["level"], row["topic"].lower()) for row in self.records["cloze"]})
        self.assertTrue(self.manifest["requiresCompleteSentenceDerivations"])
        self.assertEqual(len(self.manifest["sentenceDerivationSets"]), 3)

    def test_ids_and_review_ledgers_match_promotion_state(self):
        live = {
            "vocab": read_csv(ROOT / "assets/data/korean_vocab.csv"),
            "grammar": read_csv(ROOT / "assets/data/grammar.csv"),
            "smalltalk": read_json(ROOT / "assets/data/smalltalk.json")["phrases"],
            "cloze": read_json(ROOT / "assets/data/cloze.json")["items"],
            "satz": read_json(ROOT / "assets/data/satz_sentences.json")["items"],
        }
        for artifact in self.manifest["artifacts"]:
            kind = artifact["kind"]
            draft_ids = [row["id"] for row in self.records[kind]]
            live_ids = {row["id"] for row in live[kind]}
            overlap = set(draft_ids) & live_ids
            expected_status = "approved" if self.manifest["status"] == "merged" else "draft"
            self.assertEqual(overlap, set(draft_ids) if expected_status == "approved" else set(), kind)
            ledger = read_csv(ROOT / artifact["review"])
            self.assertEqual([row["id"] for row in ledger], draft_ids)
            self.assertTrue(all(row["상태"] == expected_status for row in ledger))


if __name__ == "__main__":
    unittest.main()
