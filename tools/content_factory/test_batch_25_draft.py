#!/usr/bin/env python3
"""Regression tests for the C3 Batch 25 (A1 reinforcement) DRAFT files.

These tests validate the draft-only artifacts produced for Batch 25:
    tools/content_factory/drafts/batch_25_a1_rows.csv
    tools/content_factory/drafts/batch_25_a1_cloze.json
    tools/content_factory/drafts/batch_25_a1_satz.json
    tools/content_factory/drafts/batch_25_a1_reinforcement_manifest.json

They never touch assets/data/** — this batch has NOT been approved by Jin yet
(level-canon program hard rule) and must not be promoted until then.

Run with:
    python3 -m unittest tools.content_factory.test_batch_25_draft -v
"""

from __future__ import annotations

import csv
import json
import re
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
DRAFTS = REPO_ROOT / "tools/content_factory/drafts"
VOCAB_CSV = REPO_ROOT / "assets/data/korean_vocab.csv"

VOCAB_COLUMNS = [
    "korean", "romanization", "german", "level", "pos_de", "example_korean",
    "example_german", "topic", "pack_id", "pack_order", "is_review_boss",
    "english", "pos_en", "example_english", "id",
]

FORBIDDEN_GRAMMAR_PATTERNS = [
    re.compile(r"다고"),
    re.compile(r"라고\s*하"),
    re.compile(r"ㄹ지"),
    re.compile(r"더라도"),
    re.compile(r"는\s*바람에"),
]

ROMANIZATION_RE = re.compile(r"^[a-z ]+$")

# eojeol (어절) = whitespace-separated token, punctuation stripped before counting
_PUNCT_RE = re.compile(r"[!?.,＿]")


def _eojeol_count(sentence: str) -> int:
    stripped = _PUNCT_RE.sub("", sentence)
    return len([t for t in stripped.split(" ") if t])


def _load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def _load_vocab_rows(path: Path):
    with path.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


class TestBatch25DraftFilesExist(unittest.TestCase):
    def test_files_exist(self):
        for name in (
            "batch_25_a1_rows.csv",
            "batch_25_a1_cloze.json",
            "batch_25_a1_satz.json",
            "batch_25_a1_reinforcement_manifest.json",
        ):
            self.assertTrue((DRAFTS / name).exists(), f"missing draft file: {name}")

    def test_review_packet_exists(self):
        packet = REPO_ROOT / "docs/data/review_packets/batch_25_a1_jin_sample.md"
        self.assertTrue(packet.exists())


class TestBatch25NeverTouchesLiveAssets(unittest.TestCase):
    """Hard rule: this batch is a draft-only packet. It must not appear in
    the live app data until Jin approves it."""

    def test_manifest_marks_draft_and_unapproved(self):
        manifest = _load_json(DRAFTS / "batch_25_a1_reinforcement_manifest.json")
        self.assertEqual(manifest["status"], "draft")
        self.assertEqual(manifest["provenance"]["approval"], {})
        self.assertFalse(manifest["promotion"]["assetsDataWritten"])
        self.assertFalse(manifest["promotion"]["runtime"])
        self.assertFalse(manifest["promotion"]["tts"])
        self.assertFalse(manifest["promotion"]["firebase"])

    def test_no_live_headword_was_added(self):
        """None of the batch's 64 headwords may already exist in the live
        korean_vocab.csv — this proves nothing has been promoted."""
        draft_rows = _load_vocab_rows(DRAFTS / "batch_25_a1_rows.csv")
        live_rows = _load_vocab_rows(VOCAB_CSV)
        live_korean = {r["korean"] for r in live_rows}
        for row in draft_rows:
            self.assertNotIn(
                row["korean"], live_korean,
                f"{row['korean']} ({row['id']}) is already live — draft should not duplicate it",
            )


class TestBatch25VocabRows(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = _load_vocab_rows(DRAFTS / "batch_25_a1_rows.csv")
        cls.live_rows = _load_vocab_rows(VOCAB_CSV)
        cls.live_pack_ids = {r["pack_id"] for r in cls.live_rows}
        cls.manifest = _load_json(DRAFTS / "batch_25_a1_reinforcement_manifest.json")

    def test_header_matches_live_csv(self):
        with (DRAFTS / "batch_25_a1_rows.csv").open(encoding="utf-8") as f:
            header = next(csv.reader(f))
        self.assertEqual(header, VOCAB_COLUMNS)

    def test_row_count_in_range(self):
        self.assertGreaterEqual(len(self.rows), 60)
        self.assertLessEqual(len(self.rows), 68)

    def test_no_duplicate_korean_within_batch(self):
        koreans = [r["korean"] for r in self.rows]
        self.assertEqual(len(koreans), len(set(koreans)), "duplicate korean within the batch itself")

    def test_no_duplicate_korean_vs_live_csv(self):
        live_korean = {r["korean"] for r in self.live_rows}
        for row in self.rows:
            self.assertNotIn(row["korean"], live_korean)

    def test_all_ids_unique_and_above_live_max(self):
        live_max = max(
            int(r["id"].rsplit("_", 1)[1]) for r in self.live_rows if r["id"].startswith("vocab_a1_")
        )
        ids = [r["id"] for r in self.rows]
        self.assertEqual(len(ids), len(set(ids)))
        for row in self.rows:
            self.assertTrue(row["id"].startswith("vocab_a1_"))
            num = int(row["id"].rsplit("_", 1)[1])
            self.assertGreater(num, live_max)

    def test_pack_ids_exist_live_or_declared_new(self):
        declared_new = set(self.manifest.get("newPacks", []))
        for row in self.rows:
            self.assertTrue(
                row["pack_id"] in self.live_pack_ids or row["pack_id"] in declared_new,
                f"pack_id {row['pack_id']} ({row['id']}) is neither live nor declared new in the manifest",
            )

    def test_level_is_a1(self):
        for row in self.rows:
            self.assertEqual(row["level"], "A1")

    def test_is_review_boss_false(self):
        for row in self.rows:
            self.assertEqual(row["is_review_boss"], "false")

    def test_examples_are_at_most_8_eojeol(self):
        for row in self.rows:
            n = _eojeol_count(row["example_korean"])
            self.assertLessEqual(n, 8, f"{row['id']} example_korean has {n} 어절: {row['example_korean']}")

    def test_headword_or_inflected_answer_present_in_example(self):
        """Matches the convention already used by promote_batch24_supplement.py
        (`if ans not in ex`): the literal headword appears in the example for
        nouns/adverbs/expressions, or the answer form used by the derived
        cloze item (a natural inflection) appears for verbs."""
        cloze = _load_json(DRAFTS / "batch_25_a1_cloze.json")["items"]
        cloze_answer_by_vid = {c["sourceVocabId"]: c["answer"] for c in cloze}
        for row in self.rows:
            ans = cloze_answer_by_vid.get(row["id"], row["korean"])
            self.assertIn(ans, row["example_korean"], f"{row['id']}: answer {ans!r} not in example")

    def test_no_forbidden_grammar_tokens(self):
        for row in self.rows:
            for pattern in FORBIDDEN_GRAMMAR_PATTERNS:
                self.assertIsNone(
                    pattern.search(row["example_korean"]),
                    f"{row['id']} example_korean contains forbidden pattern {pattern.pattern!r}: {row['example_korean']}",
                )

    def test_romanization_charset(self):
        for row in self.rows:
            self.assertRegex(
                row["romanization"], ROMANIZATION_RE,
                f"{row['id']} romanization {row['romanization']!r} has chars outside [a-z ]",
            )

    def test_pack_order_is_positive_int(self):
        for row in self.rows:
            self.assertTrue(row["pack_order"].isdigit())
            self.assertGreater(int(row["pack_order"]), 0)


class TestBatch25Cloze(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(DRAFTS / "batch_25_a1_cloze.json")["items"]
        cls.live_cloze = _load_json(REPO_ROOT / "assets/data/cloze.json")["items"]

    def test_count_matches_vocab(self):
        rows = _load_vocab_rows(DRAFTS / "batch_25_a1_rows.csv")
        self.assertEqual(len(self.items), len(rows))

    def test_ids_unique_and_above_live_max(self):
        live_max = max(
            int(i["id"].rsplit("_", 1)[1]) for i in self.live_cloze if i["id"].startswith("cloze_a1_")
        )
        ids = [i["id"] for i in self.items]
        self.assertEqual(len(ids), len(set(ids)))
        for item in self.items:
            num = int(item["id"].rsplit("_", 1)[1])
            self.assertGreater(num, live_max)

    def test_answer_in_full_ko_and_sentence_is_blanked(self):
        for item in self.items:
            self.assertIn(item["answer"], item["fullKo"])
            self.assertEqual(
                item["fullKo"].replace(item["answer"], "＿＿＿", 1), item["sentenceKo"]
            )

    def test_exactly_three_distractors(self):
        for item in self.items:
            self.assertEqual(len(item["distractors"]), 3)

    def test_answer_not_substring_of_distractors(self):
        for item in self.items:
            for d in item["distractors"]:
                self.assertNotIn(item["answer"], d, f"{item['id']}: answer leaks into distractor {d!r}")
                self.assertNotIn(d, item["answer"], f"{item['id']}: distractor {d!r} leaks into answer")

    def test_distractors_not_in_sentence(self):
        for item in self.items:
            for d in item["distractors"]:
                self.assertNotIn(d, item["sentenceKo"], f"{item['id']}: distractor {d!r} already in sentenceKo")

    def test_distractors_are_unique(self):
        for item in self.items:
            self.assertEqual(len(item["distractors"]), len(set(item["distractors"])))


class TestBatch25Satz(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(DRAFTS / "batch_25_a1_satz.json")["items"]
        cls.live_satz = _load_json(REPO_ROOT / "assets/data/satz_sentences.json")["items"]

    def test_count_matches_vocab(self):
        rows = _load_vocab_rows(DRAFTS / "batch_25_a1_rows.csv")
        self.assertEqual(len(self.items), len(rows))

    def test_ids_unique_and_above_live_max(self):
        live_max = max(
            int(i["id"].rsplit("_", 1)[1]) for i in self.live_satz if i["id"].startswith("satz_a1_")
        )
        ids = [i["id"] for i in self.items]
        self.assertEqual(len(ids), len(set(ids)))
        for item in self.items:
            num = int(item["id"].rsplit("_", 1)[1])
            self.assertGreater(num, live_max)

    def test_vocab_ko_and_target_present(self):
        for item in self.items:
            self.assertTrue(item["vocabKo"])
            self.assertGreaterEqual(_eojeol_count(item["targetKo"]), 1)
            self.assertLessEqual(_eojeol_count(item["targetKo"]), 8)

    def test_two_distractors(self):
        for item in self.items:
            self.assertEqual(len(item["distractors"]), 2)
            self.assertEqual(len(item["distractors"]), len(set(item["distractors"])))


class TestBatch25PacksFilledTo12(unittest.TestCase):
    """Sanity check for the selection rationale: every touched pack should
    reach exactly 12 words once the draft rows are added to the live count."""

    def test_touched_packs_reach_twelve(self):
        manifest = _load_json(DRAFTS / "batch_25_a1_reinforcement_manifest.json")
        draft_rows = _load_vocab_rows(DRAFTS / "batch_25_a1_rows.csv")
        live_rows = _load_vocab_rows(VOCAB_CSV)
        from collections import Counter
        live_counts = Counter(r["pack_id"] for r in live_rows if r["level"] == "A1")
        draft_counts = Counter(r["pack_id"] for r in draft_rows)
        for pack_id in manifest["packsFilledTo12"]:
            total = live_counts.get(pack_id, 0) + draft_counts.get(pack_id, 0)
            self.assertEqual(total, 12, f"{pack_id}: live {live_counts.get(pack_id, 0)} + draft {draft_counts.get(pack_id, 0)} != 12")


if __name__ == "__main__":
    unittest.main()
