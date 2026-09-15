#!/usr/bin/env python3
"""Regression tests for the C3 Batch 26 (A1 reinforcement) DRAFT files.

These tests validate the draft-only artifacts produced for Batch 26:
    tools/content_factory/drafts/batch_26_a1_rows.csv
    tools/content_factory/drafts/batch_26_a1_cloze.json
    tools/content_factory/drafts/batch_26_a1_satz.json
    tools/content_factory/drafts/batch_26_a1_reinforcement_manifest.json

They never touch assets/data/** -- this batch has NOT been approved by Jin
yet (level-canon program hard rule) and must not be promoted until then.

This file is a copy of test_batch_25_draft.py (same schema, same base
checks) with four additions requested for Batch 26:
  - no example_korean frame (headword replaced by a placeholder) may repeat
    more than 3 times across the batch;
  - any personal name appearing in an example must be one of the app's
    canonical recurring characters (character_profiles.json);
  - at least 2 of a cloze item's 3 distractors must be the same part of
    speech as the answer (noun, since every Batch 26 headword is a noun);
  - Sino-Korean numerals are forbidden immediately before "살" (age uses
    native numerals per the level bible / batch style guide).
  - plus the batch-specific check that none of the 66 headwords duplicate
    Batch 25's 64 headwords.

Run with:
    python3 -m unittest tools.content_factory.test_batch_26_draft -v
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
CHARACTER_PROFILES = (
    REPO_ROOT / "tools/content_factory/canonical_scenarios/character_profiles.json"
)

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
    re.compile(r"아/어\s*보다"),
    re.compile(r"[가-힣]\s*본\s*적"),  # -은 적 있다/없다 (A2)
]

ROMANIZATION_RE = re.compile(r"^[a-z ]+$")

# eojeol (어절) = whitespace-separated token, punctuation stripped before counting
_PUNCT_RE = re.compile(r"[!?.,＿]")

# Sino-Korean numerals that must never directly precede 살 (age uses native
# numerals: 한/두/세/스무/스물한/서른/마흔/쉰/예순 살 etc.)
SINO_NUMERALS = [
    "일", "이", "삼", "사", "오", "육", "칠", "팔", "구", "십",
    "백", "천", "만",
]
SINO_NUMERAL_AGE_RE = re.compile(
    "(?:" + "|".join(SINO_NUMERALS) + r")\s*살\b"
)

# Distractor words that are dictionary-form verbs/adjectives or adverbs (not
# nouns) in this batch's own distractor pools -- used to check the "at least
# 2 of 3 distractors share the answer's part of speech" rule. Every Batch 26
# headword is a Nomen, so a "same POS" distractor is a noun: anything that
# does NOT look like a bare dictionary-form predicate (ends in "다") and is
# not one of the known adverbs counts as noun-like here.
ADV_WORDS = {
    "빨리", "천천히", "가끔", "항상", "다시", "아주", "바로", "주로",
    "이따가", "꼭", "좀", "함께", "참",
}


def _eojeol_count(sentence: str) -> int:
    stripped = _PUNCT_RE.sub("", sentence)
    return len([t for t in stripped.split(" ") if t])


def _load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def _load_vocab_rows(path: Path):
    with path.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def _is_noun_like(word: str) -> bool:
    return not word.endswith("다") and word not in ADV_WORDS


def _frame_key(example_korean: str, headword: str) -> str:
    """Replace the (first occurrence of the) headword with a placeholder so
    two sentences that differ only by which vocab word they use collapse to
    the same key."""
    return example_korean.replace(headword, "￿", 1)


class TestBatch26DraftFilesExist(unittest.TestCase):
    def test_files_exist(self):
        for name in (
            "batch_26_a1_rows.csv",
            "batch_26_a1_cloze.json",
            "batch_26_a1_satz.json",
            "batch_26_a1_reinforcement_manifest.json",
        ):
            self.assertTrue((DRAFTS / name).exists(), f"missing draft file: {name}")

    def test_review_packet_exists(self):
        packet = REPO_ROOT / "docs/data/review_packets/batch_26_a1_jin_sample.md"
        self.assertTrue(packet.exists())


class TestBatch26NeverTouchesLiveAssets(unittest.TestCase):
    """Hard rule: this batch is a draft-only packet. It must not appear in
    the live app data until Jin approves it."""

    def test_manifest_marks_draft_and_unapproved(self):
        manifest = _load_json(DRAFTS / "batch_26_a1_reinforcement_manifest.json")
        self.assertEqual(manifest["status"], "draft")
        self.assertEqual(manifest["provenance"]["approval"], {})
        self.assertFalse(manifest["promotion"]["assetsDataWritten"])
        self.assertFalse(manifest["promotion"]["runtime"])
        self.assertFalse(manifest["promotion"]["tts"])
        self.assertFalse(manifest["promotion"]["firebase"])

    def test_no_live_headword_was_added(self):
        """None of the batch's headwords may already exist in the live
        korean_vocab.csv -- this proves nothing has been promoted."""
        draft_rows = _load_vocab_rows(DRAFTS / "batch_26_a1_rows.csv")
        live_rows = _load_vocab_rows(VOCAB_CSV)
        live_korean = {r["korean"] for r in live_rows}
        for row in draft_rows:
            self.assertNotIn(
                row["korean"], live_korean,
                f"{row['korean']} ({row['id']}) is already live -- draft should not duplicate it",
            )

    def test_no_overlap_with_batch_25_words(self):
        """Batch 26 must not reuse any of Batch 25's 64 headwords."""
        draft_rows = _load_vocab_rows(DRAFTS / "batch_26_a1_rows.csv")
        b25_path = DRAFTS / "batch_25_a1_rows.csv"
        if not b25_path.exists():
            self.skipTest("batch_25_a1_rows.csv not present in this checkout")
        b25_rows = _load_vocab_rows(b25_path)
        b25_korean = {r["korean"] for r in b25_rows}
        overlap = {r["korean"] for r in draft_rows} & b25_korean
        self.assertEqual(overlap, set(), f"Batch 26 reuses Batch 25 words: {overlap}")


class TestBatch26VocabRows(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = _load_vocab_rows(DRAFTS / "batch_26_a1_rows.csv")
        cls.live_rows = _load_vocab_rows(VOCAB_CSV)
        cls.live_pack_ids = {r["pack_id"] for r in cls.live_rows}
        cls.manifest = _load_json(DRAFTS / "batch_26_a1_reinforcement_manifest.json")

    def test_header_matches_live_csv(self):
        with (DRAFTS / "batch_26_a1_rows.csv").open(encoding="utf-8") as f:
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
        declared_new = {p["pack_id"] for p in self.manifest.get("newPacks", [])}
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
        cloze = _load_json(DRAFTS / "batch_26_a1_cloze.json")["items"]
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

    def test_no_sino_numeral_directly_before_sal(self):
        """Age must use native-Korean numerals (스무 살, 예순 살, ...), never
        a Sino-Korean numeral immediately before 살."""
        for row in self.rows:
            m = SINO_NUMERAL_AGE_RE.search(row["example_korean"])
            self.assertIsNone(
                m, f"{row['id']}: Sino-Korean numeral used before 살: {row['example_korean']!r}"
            )

    def test_personal_names_are_canonical_characters(self):
        """Any personal name used in an example must be one of the app's
        recurring characters (character_profiles.json) -- no invented or
        textbook (Sejong) names."""
        profiles = _load_json(CHARACTER_PROFILES)
        allowed_ko_names = {
            c["displayNames"]["ko"] for c in profiles["recurringCharacters"]
        }
        # crude "is this a name" probe: token immediately followed by 씨 or 은/는/이/가
        # honorific-address marker '씨' is the reliable signal used throughout
        # this batch's own examples.
        name_before_ssi = re.compile(r"([가-힣]{2,4})\s*씨")
        for row in self.rows:
            for m in name_before_ssi.finditer(row["example_korean"]):
                name = m.group(1)
                self.assertIn(
                    name, allowed_ko_names,
                    f"{row['id']}: name {name!r} (before 씨) is not a canonical recurring character",
                )

    def test_no_example_frame_repeated_more_than_3_times(self):
        """Replacing each row's headword with a placeholder must not yield
        the same normalized sentence more than 3 times across the batch."""
        from collections import Counter
        keys = [
            _frame_key(row["example_korean"], row["korean"]) for row in self.rows
        ]
        counts = Counter(keys)
        offenders = {k: c for k, c in counts.items() if c > 3}
        self.assertEqual(
            offenders, {}, f"frame(s) repeated more than 3 times: {offenders}"
        )


class TestBatch26Cloze(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(DRAFTS / "batch_26_a1_cloze.json")["items"]
        cls.live_cloze = _load_json(REPO_ROOT / "assets/data/cloze.json")["items"]

    def test_count_matches_vocab(self):
        rows = _load_vocab_rows(DRAFTS / "batch_26_a1_rows.csv")
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

    def test_at_least_two_distractors_are_same_pos_as_answer(self):
        """Every Batch 26 headword is a Nomen, so at least 2 of the 3
        distractors must themselves be noun-like (not a bare dictionary-form
        predicate, not a known adverb) -- same-POS-but-absurd, per the
        Batch 26 authoring rule."""
        for item in self.items:
            noun_like = [d for d in item["distractors"] if _is_noun_like(d)]
            self.assertGreaterEqual(
                len(noun_like), 2,
                f"{item['id']}: fewer than 2/3 distractors are noun-like: {item['distractors']}",
            )


class TestBatch26Satz(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(DRAFTS / "batch_26_a1_satz.json")["items"]
        cls.live_satz = _load_json(REPO_ROOT / "assets/data/satz_sentences.json")["items"]

    def test_count_matches_vocab(self):
        rows = _load_vocab_rows(DRAFTS / "batch_26_a1_rows.csv")
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


class TestBatch26PacksFilledTo12(unittest.TestCase):
    """Sanity check for the selection rationale: every touched existing pack
    should reach exactly 12 words once the draft rows are added to the live
    count, and every declared new pack should have exactly 12 draft rows."""

    def test_touched_packs_reach_twelve(self):
        manifest = _load_json(DRAFTS / "batch_26_a1_reinforcement_manifest.json")
        draft_rows = _load_vocab_rows(DRAFTS / "batch_26_a1_rows.csv")
        live_rows = _load_vocab_rows(VOCAB_CSV)
        from collections import Counter
        live_counts = Counter(r["pack_id"] for r in live_rows if r["level"] == "A1")
        draft_counts = Counter(r["pack_id"] for r in draft_rows)
        for pack_id in manifest["packsFilledTo12"]:
            total = live_counts.get(pack_id, 0) + draft_counts.get(pack_id, 0)
            self.assertEqual(total, 12, f"{pack_id}: live {live_counts.get(pack_id, 0)} + draft {draft_counts.get(pack_id, 0)} != 12")

    def test_new_packs_have_exactly_twelve_words(self):
        manifest = _load_json(DRAFTS / "batch_26_a1_reinforcement_manifest.json")
        draft_rows = _load_vocab_rows(DRAFTS / "batch_26_a1_rows.csv")
        from collections import Counter
        draft_counts = Counter(r["pack_id"] for r in draft_rows)
        for entry in manifest.get("newPacks", []):
            self.assertEqual(
                draft_counts.get(entry["pack_id"], 0), 12,
                f"new pack {entry['pack_id']} does not have exactly 12 words in the draft",
            )


if __name__ == "__main__":
    unittest.main()
