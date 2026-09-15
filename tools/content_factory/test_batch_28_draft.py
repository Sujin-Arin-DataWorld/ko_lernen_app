#!/usr/bin/env python3
"""Regression tests for the C3 Batch 28 (A1 reinforcement) DRAFT files.

These tests validate the draft-only artifacts produced for Batch 28:
    tools/content_factory/drafts/batch_28_a1_rows.csv
    tools/content_factory/drafts/batch_28_a1_cloze.json
    tools/content_factory/drafts/batch_28_a1_satz.json
    tools/content_factory/drafts/batch_28_a1_reinforcement_manifest.json

They never touch assets/data/** -- this batch has NOT been approved by Jin
yet (level-canon program hard rule) and must not be promoted until then.

Mirrors test_batch_27_draft.py's schema/checks, importing the shared
helpers from a1_draft_rules.py and distractor_rules.py instead of
re-defining them, plus:
  - a batch-specific check that none of the 63 headwords duplicate
    Batch 25's, Batch 26's or Batch 27's headwords (word-source rule: NIKL
    grade-1, not yet live, not in the Batch 26/27 drafts);
  - a predicate-slot-waiver check for the 3 verb rows (늦다/묻다/맞다),
    whose cloze answer is a conjugated predicate, not a bare noun -- their
    distractors are bare dictionary-form verbs (distractor_rules.py's
    waiver technique), not batchim-matched nouns;
  - test_no_hada_collocate_in_fused_slot: a MECHANICAL rule test, not an
    allowlist. R6/R8 finding on PR #344 (2026-09-15, Fable coordinator
    review of commit c5bbecc5): an earlier version of this batch claimed
    (in the PR report, not in any committed file) that "N+하다 sibling
    leaks" were fixed, when the committed cloze.json still had them --
    e.g. 샤워's "아침에 ___해요." with distractor 세수 produces "아침에
    세수해요.", a fully valid Korean sentence, not a nonsense distractor.
    This test catches that class of bug directly: for every cloze item
    whose blank is immediately followed by a fused "해요/했어요/할까요"
    (or whose full sentence contains "배워요"/"가르쳐요"), no distractor
    may be a word that combines productively with 하다/배우다/가르치다
    (ACTIVITY_NOUN_SET below) to form a real Korean verb;
  - a handful of rows (생활/방학/곳/태권도/병/잠시/주/교통) keep a
    residually open slot that even ACTIVITY_NOUN_SET exclusion and a
    narrowing rewrite could not fully close (see the review packet's
    "판정 필요" section for the specific, honestly-flagged residual risk
    on each) -- test_open_slot_rows_have_activity_free_distractors checks
    their distractors are at minimum ACTIVITY_NOUN_SET-free, same as
    every other row; it does not claim these are risk-free.

Run with:
    python -m unittest tools.content_factory.test_batch_28_draft -v
"""

from __future__ import annotations

import csv
import re
import unittest
from collections import Counter
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_DIR = Path(__file__).resolve().parent
import sys as _sys
if str(SCRIPT_DIR) not in _sys.path:
    _sys.path.insert(0, str(SCRIPT_DIR))

import a1_draft_rules as R  # noqa: E402
from distractor_rules import (  # noqa: E402
    batchim_class as _batchim_class,
    detect_required_class as _detect_required_class,
)

DRAFTS = REPO_ROOT / "tools/content_factory/drafts"
VOCAB_CSV = REPO_ROOT / "assets/data/korean_vocab.csv"
CHARACTER_PROFILES = R.CHARACTER_PROFILES
BATCH25_VOCAB_CSV = DRAFTS / "batch_25_a1_rows.csv"
BATCH26_VOCAB_CSV = DRAFTS / "batch_26_a1_rows.csv"
BATCH27_VOCAB_CSV = DRAFTS / "batch_27_a1_rows.csv"

VOCAB_COLUMNS = R.VOCAB_COLUMNS

# This batch's own 3 verb headwords -- their cloze answer is a conjugated
# predicate (sentence-final), covered by the predicate-slot waiver, not
# the "2/3 distractors are noun-like" rule used for the other 60 (all
# Nomen) rows. (늦다's answer was originally "늦지 마세요", a 2급
# "-지 말다" negative imperative flagged as out-of-scope in R8 review;
# rewritten to the plain past tense "늦었어요" -- "미안해요, 버스가
# 늦었어요." -- which is 1급.)
VERB_HEADWORDS = {"늦다", "묻다", "맞다"}

# Every headword whose Korean form combines productively with 하다/배우다/
# 가르치다 to make a real (or strongly colloquial-real) Korean verb.
# test_no_hada_collocate_in_fused_slot below enforces that no cloze item
# whose blank is a fused "___해요/했어요/할까요" (or "___ 배워요"/
# "___ 가르쳐요") slot uses a distractor from this set: e.g. 샤워's "아침에
# ___해요." with distractor 세수 gives "아침에 세수해요." -- fully valid
# Korean, not a nonsense distractor. This is the exact bug Fable found in
# commit c5bbecc5 (2026-09-15): several rows had this leak despite the PR
# report claiming it was fixed.
ACTIVITY_NOUN_SET = {
    "샤워", "세수", "청소", "준비", "요리", "식사", "운전", "사용", "부탁",
    "초대", "운동", "아르바이트", "쇼핑", "태권도", "파티", "졸업", "방학",
    "의사", "영화배우", "종업원", "직원", "콘서트", "연극", "외국어",
    "이야기", "안내", "시작", "생활", "선물", "음식",
}

# Rows whose predicate remains productive with a wide range of nouns even
# after ACTIVITY_NOUN_SET exclusion and (for 생활/방학/교통/잠시/주) a
# narrowing rewrite -- see the review packet's "판정 필요" section for the
# specific residual risk honestly flagged on each. Listed here only so a
# reader knows which rows needed the most scrutiny; it is not a safety
# allowlist and does not suppress the mechanical ACTIVITY_NOUN_SET check
# above, which already covers these rows too.
OPEN_SLOT_ROWS = {"생활", "방학", "곳", "태권도", "병", "잠시", "주", "교통"}

ADV_WORDS = {
    "빨리", "천천히", "가끔", "항상", "다시", "아주", "바로", "주로",
    "이따가", "꼭", "좀", "함께", "참",
}
VERB_WORDS = {
    "가다", "오다", "보다", "읽다", "타다", "쓰다", "자다", "입다",
    "알다", "모르다", "돕다", "팔다", "고르다", "빌리다", "끝나다", "다니다",
} | VERB_HEADWORDS


def _is_noun_like(word: str) -> bool:
    return word not in ADV_WORDS and word not in VERB_WORDS


def _load_json(path: Path):
    return R.load_json(path)


def _load_vocab_rows(path: Path):
    return R.load_vocab_rows(path)


class TestBatch28DraftFilesExist(unittest.TestCase):
    def test_files_exist(self):
        for name in (
            "batch_28_a1_rows.csv",
            "batch_28_a1_cloze.json",
            "batch_28_a1_satz.json",
            "batch_28_a1_reinforcement_manifest.json",
        ):
            self.assertTrue((DRAFTS / name).exists(), f"missing draft file: {name}")

    def test_review_packet_exists(self):
        packet = REPO_ROOT / "docs/data/review_packets/batch_28_a1_jin_sample.md"
        self.assertTrue(packet.exists())


class TestBatch28NeverTouchesLiveAssets(unittest.TestCase):
    """Hard rule: this batch is a draft-only packet. It must not appear in
    the live app data until Jin approves it."""

    def test_manifest_marks_draft_and_unapproved(self):
        manifest = _load_json(DRAFTS / "batch_28_a1_reinforcement_manifest.json")
        self.assertEqual(manifest["status"], "draft")
        self.assertEqual(manifest["provenance"]["approval"], {})
        self.assertFalse(manifest["promotion"]["assetsDataWritten"])
        self.assertFalse(manifest["promotion"]["runtime"])
        self.assertFalse(manifest["promotion"]["tts"])
        self.assertFalse(manifest["promotion"]["firebase"])

    def test_no_live_headword_was_added(self):
        draft_rows = _load_vocab_rows(DRAFTS / "batch_28_a1_rows.csv")
        live_rows = _load_vocab_rows(VOCAB_CSV)
        live_korean = {r["korean"] for r in live_rows}
        for row in draft_rows:
            self.assertNotIn(
                row["korean"], live_korean,
                f"{row['korean']} ({row['id']}) is already live -- draft should not duplicate it",
            )

    def test_no_overlap_with_batch_25_words(self):
        draft_rows = _load_vocab_rows(DRAFTS / "batch_28_a1_rows.csv")
        if not BATCH25_VOCAB_CSV.exists():
            self.skipTest("batch_25_a1_rows.csv not present in this checkout")
        b25_korean = {r["korean"] for r in _load_vocab_rows(BATCH25_VOCAB_CSV)}
        overlap = {r["korean"] for r in draft_rows} & b25_korean
        self.assertEqual(overlap, set(), f"Batch 28 reuses Batch 25 words: {overlap}")

    def test_no_overlap_with_batch_26_words(self):
        draft_rows = _load_vocab_rows(DRAFTS / "batch_28_a1_rows.csv")
        if not BATCH26_VOCAB_CSV.exists():
            self.skipTest("batch_26_a1_rows.csv not present in this checkout")
        b26_korean = {r["korean"] for r in _load_vocab_rows(BATCH26_VOCAB_CSV)}
        overlap = {r["korean"] for r in draft_rows} & b26_korean
        self.assertEqual(overlap, set(), f"Batch 28 reuses Batch 26 words: {overlap}")

    def test_no_overlap_with_batch_27_words(self):
        draft_rows = _load_vocab_rows(DRAFTS / "batch_28_a1_rows.csv")
        if not BATCH27_VOCAB_CSV.exists():
            self.skipTest("batch_27_a1_rows.csv not present in this checkout")
        b27_korean = {r["korean"] for r in _load_vocab_rows(BATCH27_VOCAB_CSV)}
        overlap = {r["korean"] for r in draft_rows} & b27_korean
        self.assertEqual(overlap, set(), f"Batch 28 reuses Batch 27 words: {overlap}")


class TestBatch28VocabRows(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = _load_vocab_rows(DRAFTS / "batch_28_a1_rows.csv")
        cls.live_rows = _load_vocab_rows(VOCAB_CSV)
        cls.live_pack_ids = {r["pack_id"] for r in cls.live_rows}
        cls.manifest = _load_json(DRAFTS / "batch_28_a1_reinforcement_manifest.json")

    def test_header_matches_live_csv(self):
        with (DRAFTS / "batch_28_a1_rows.csv").open(encoding="utf-8") as f:
            header = next(csv.reader(f))
        self.assertEqual(header, VOCAB_COLUMNS)

    def test_row_count_in_range(self):
        self.assertGreaterEqual(len(self.rows), 60)
        self.assertLessEqual(len(self.rows), 68)

    def test_no_duplicate_korean_within_batch(self):
        koreans = [r["korean"] for r in self.rows]
        self.assertEqual(len(koreans), len(set(koreans)))

    def test_no_duplicate_korean_vs_live_csv(self):
        live_korean = {r["korean"] for r in self.live_rows}
        for row in self.rows:
            self.assertNotIn(row["korean"], live_korean)

    def test_all_ids_unique_and_above_live_and_prior_batches_max(self):
        live_max = max(
            int(r["id"].rsplit("_", 1)[1]) for r in self.live_rows if r["id"].startswith("vocab_a1_")
        )
        floor = live_max
        for path in (BATCH26_VOCAB_CSV, BATCH27_VOCAB_CSV):
            prior_rows = _load_vocab_rows(path) if path.exists() else []
            prior_max = max(
                [int(r["id"].rsplit("_", 1)[1]) for r in prior_rows if r["id"].startswith("vocab_a1_")],
                default=0,
            )
            floor = max(floor, prior_max)
        ids = [r["id"] for r in self.rows]
        self.assertEqual(len(ids), len(set(ids)))
        for row in self.rows:
            self.assertTrue(row["id"].startswith("vocab_a1_"))
            num = int(row["id"].rsplit("_", 1)[1])
            self.assertGreater(num, floor)

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
            n = R.eojeol_count(row["example_korean"])
            self.assertLessEqual(n, 8, f"{row['id']} example_korean has {n} 어절: {row['example_korean']}")

    def test_headword_or_inflected_answer_present_in_example(self):
        cloze = _load_json(DRAFTS / "batch_28_a1_cloze.json")["items"]
        cloze_answer_by_vid = {c["sourceVocabId"]: c["answer"] for c in cloze}
        for row in self.rows:
            ans = cloze_answer_by_vid.get(row["id"], row["korean"])
            self.assertIn(ans, row["example_korean"], f"{row['id']}: answer {ans!r} not in example")

    def test_no_forbidden_grammar_tokens(self):
        for row in self.rows:
            for pattern in R.FORBIDDEN_GRAMMAR_PATTERNS:
                self.assertIsNone(
                    pattern.search(row["example_korean"]),
                    f"{row['id']} example_korean contains forbidden pattern {pattern.pattern!r}: {row['example_korean']}",
                )

    def test_no_jinjja(self):
        """'진짜' must never appear -- A1 emphasis is always '정말' (carried
        over from Batch 26/27)."""
        for row in self.rows:
            self.assertNotIn("진짜", row["example_korean"], f"{row['id']}: uses 진짜 instead of 정말")

    def test_romanization_charset(self):
        for row in self.rows:
            self.assertRegex(
                row["romanization"], R.ROMANIZATION_RE,
                f"{row['id']} romanization {row['romanization']!r} has chars outside [a-z ]",
            )

    def test_pack_order_is_positive_int(self):
        for row in self.rows:
            self.assertTrue(row["pack_order"].isdigit())
            self.assertGreater(int(row["pack_order"]), 0)

    def test_no_sino_numeral_directly_before_sal(self):
        for row in self.rows:
            m = R.SINO_NUMERAL_AGE_RE.search(row["example_korean"])
            self.assertIsNone(
                m, f"{row['id']}: Sino-Korean numeral used before 살: {row['example_korean']!r}"
            )

    def test_personal_names_are_canonical_characters(self):
        profiles = _load_json(CHARACTER_PROFILES)
        allowed_ko_names = {
            c["displayNames"]["ko"] for c in profiles["recurringCharacters"]
        }
        for row in self.rows:
            for name in R.names_before_ssi(row["example_korean"]):
                self.assertIn(
                    name, allowed_ko_names,
                    f"{row['id']}: name {name!r} (before 씨) is not a canonical recurring character",
                )

    def test_at_most_two_rows_per_persona_and_at_least_eight_persona_rows(self):
        """Cross-checked against the packet's own 화자 table via the
        manifest's `personaRows` field (id -> speaker character id)."""
        speakers = self.manifest.get("personaRows", {})
        counts = Counter(speakers.values())
        offenders = {p: c for p, c in counts.items() if c > 2}
        self.assertEqual(offenders, {}, f"persona used as speaker >2 times: {offenders}")
        self.assertGreaterEqual(
            len(speakers), 8,
            f"only {len(speakers)} rows have an attributed persona speaker (need >=8)",
        )
        profiles = _load_json(CHARACTER_PROFILES)
        allowed_ids = {c["id"] for c in profiles["recurringCharacters"]}
        for vid, pid in speakers.items():
            self.assertIn(pid, allowed_ids, f"{vid}: speaker {pid!r} is not a canonical character id")

    def test_no_example_frame_repeated_more_than_3_times(self):
        keys = [
            R.frame_key(row["example_korean"], row["korean"]) for row in self.rows
        ]
        counts = Counter(keys)
        offenders = {k: c for k, c in counts.items() if c > 3}
        self.assertEqual(
            offenders, {}, f"frame(s) repeated more than 3 times: {offenders}"
        )

    def test_helper_words_are_nikl_grade1_or_live_a1_or_prior_headwords(self):
        own_rows = [{"korean": r["korean"]} for r in self.rows]
        safe_words = R.build_helper_word_scanner(
            own_rows, extra_headword_csvs=[BATCH26_VOCAB_CSV, BATCH27_VOCAB_CSV],
        )
        overrides = {
            "잤어요": "자다", "켜요": "켜다", "불러요": "부르다", "그려요": "그리다",
            "봐요": "보다", "나와요": "나오다", "갈까요": "가다", "배워요": "배우다",
            "여기서": "여기", "걸렸어요": "걸리다", "피워요": "피우다",
            "마셔요": "마시다", "커요": "크다", "줘요": "주다",
            "가르쳐요": "가르치다", "해요": "하다", "써요": "쓰다", "왔어요": "오다",
            "바빠요": "바쁘다", "기다려요": "기다리다", "쳐요": "치다", "났어요": "나다",
            "없어요": "없다", "앉아요": "앉다", "늦었어요": "늦다",
            "아파요": "아프다", "더워요": "덥다", "마실까요": "마시다",
        }
        offenders = {}
        for row in self.rows:
            bad = R.unresolved_helper_tokens(row["example_korean"], safe_words, overrides)
            if bad:
                offenders[row["id"]] = bad
        self.assertEqual(
            offenders, {},
            f"helper word(s) not resolvable against NIKL grade-1 / live A1 / prior headwords: {offenders}",
        )

    def test_woori_gachi_opener_capped_at_6_rows(self):
        count = sum(1 for row in self.rows if "우리 같이" in row["example_korean"])
        self.assertLessEqual(count, 6, f"'우리 같이' used in {count} rows (cap is 6)")

    def test_reaction_openers_not_identical_in_more_than_3_rows(self):
        counts = R.reaction_opener_counts(self.rows)
        offenders = {op: c for op, c in counts.items() if c > 3}
        self.assertEqual(
            offenders, {}, f"reaction opener(s) repeated more than 3 times: {offenders}"
        )

    def test_wa_opener_only_admires_something_present_or_is_exclamation(self):
        for row in self.rows:
            self.assertTrue(
                R.wa_opener_admires_something_present(row["example_korean"]),
                f"{row['id']}: '와' opens a bare invitation with nothing to admire: {row['example_korean']!r}",
            )

    def test_ne_or_joayo_never_used_as_a_bare_opener(self):
        for row in self.rows:
            self.assertFalse(
                R.is_bare_ne_or_joayo_opener(row["example_korean"]),
                f"{row['id']}: starts with a reply-only opener with no preceding question: {row['example_korean']!r}",
            )


class TestBatch28Cloze(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(DRAFTS / "batch_28_a1_cloze.json")["items"]
        cls.live_cloze = _load_json(REPO_ROOT / "assets/data/cloze.json")["items"]
        cls.rows_by_id = {
            r["id"]: r for r in _load_vocab_rows(DRAFTS / "batch_28_a1_rows.csv")
        }

    def test_count_matches_vocab(self):
        rows = _load_vocab_rows(DRAFTS / "batch_28_a1_rows.csv")
        self.assertEqual(len(self.items), len(rows))

    def test_ids_unique_and_above_live_and_prior_batches_max(self):
        live_max = max(
            int(i["id"].rsplit("_", 1)[1]) for i in self.live_cloze if i["id"].startswith("cloze_a1_")
        )
        floor = live_max
        for name in ("batch_26_a1_cloze.json", "batch_27_a1_cloze.json"):
            path = DRAFTS / name
            items = _load_json(path)["items"] if path.exists() else []
            prior_max = max(
                [int(i["id"].rsplit("_", 1)[1]) for i in items if i["id"].startswith("cloze_a1_")],
                default=0,
            )
            floor = max(floor, prior_max)
        ids = [i["id"] for i in self.items]
        self.assertEqual(len(ids), len(set(ids)))
        for item in self.items:
            num = int(item["id"].rsplit("_", 1)[1])
            self.assertGreater(num, floor)

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

    def test_distractors_match_answer_batchim_class_before_alternating_particle(self):
        for item in self.items:
            kind, required = _detect_required_class(item["sentenceKo"], item["answer"])
            if required is None:
                continue
            for d in item["distractors"]:
                dc = _batchim_class(d, kind)
                if dc is None:
                    continue
                self.assertEqual(
                    dc, required,
                    f"{item['id']}: distractor {d!r} is {dc}-final but answer "
                    f"{item['answer']!r} is {required}-final",
                )

    def test_no_distractor_word_reused_more_than_4_times(self):
        counts = Counter()
        for item in self.items:
            counts.update(item["distractors"])
        offenders = {w: c for w, c in counts.items() if c > 4}
        self.assertEqual(offenders, {}, f"distractor(s) reused more than 4 times: {offenders}")

    def test_at_least_two_distractors_are_same_pos_as_answer_or_predicate_waiver(self):
        """Every non-verb Batch 28 headword is a Nomen, so at least 2 of the
        3 distractors must themselves be noun-like. The 3 verb-headword rows
        (늦다/묻다/맞다) use the predicate-slot waiver instead (their answer
        spans the whole conjugated predicate; all 3 distractors are bare
        dictionary-form verbs, which is stricter than the 2/3 noun rule,
        not a relaxation of it)."""
        vocab_by_source = self.rows_by_id
        for item in self.items:
            headword = vocab_by_source[item["sourceVocabId"]]["korean"]
            if headword in VERB_HEADWORDS:
                for d in item["distractors"]:
                    self.assertIn(d, VERB_WORDS, f"{item['id']}: predicate-slot distractor {d!r} is not a bare dictionary-form verb")
                continue
            noun_like = [d for d in item["distractors"] if _is_noun_like(d)]
            self.assertGreaterEqual(
                len(noun_like), 2,
                f"{item['id']}: fewer than 2/3 distractors are noun-like: {item['distractors']}",
            )

    def test_no_hada_collocate_in_fused_slot(self):
        """R6/R8 (Fable coordinator review of commit c5bbecc5, 2026-09-15):
        a cloze blank immediately followed by a bare "해요."/"했어요."/
        "할까요?" (i.e. the headword's own answer is fused directly onto
        the 하다 conjugation, e.g. 샤워 -> "아침에 ___해요.") is exactly as
        productive as '-하다' itself -- ANY word in ACTIVITY_NOUN_SET
        substituted there produces a second, fully valid Korean sentence
        ("아침에 세수해요.", "아침에 청소해요." ...), not a nonsense
        distractor. The same applies to "___ 배워요."/"___ 가르쳐요." slots
        (배우다/가르치다 take any skill/activity noun as freely as 하다
        itself). This is a MECHANICAL check of the committed cloze.json,
        not a description of intent -- it is exactly the class of bug an
        earlier PR report claimed was fixed while the committed file still
        had it."""
        vocab_by_source = self.rows_by_id
        # "잘해요"/"잘 해요" (be good at) is included -- it is exactly as
        # productive with ACTIVITY_NOUN_SET nouns as bare 하다 itself
        # ("식사를 잘해요"/"부탁을 잘해요" both read as plausible), even
        # though the text right after the blank isn't a bare "해요.".
        fused_re = re.compile(r"^\s?(해요|했어요|할까요|잘해요|잘 해요)[.?!]")
        for item in self.items:
            headword = vocab_by_source[item["sourceVocabId"]]["korean"]
            sentence = item["sentenceKo"]
            after_blank = sentence.split("＿＿＿", 1)[1]
            is_fused_hada_slot = bool(fused_re.match(after_blank))
            is_learn_teach_slot = "배워요" in sentence or "가르쳐요" in sentence
            if not (is_fused_hada_slot or is_learn_teach_slot):
                continue
            for d in item["distractors"]:
                self.assertNotIn(
                    d, ACTIVITY_NOUN_SET,
                    f"{item['id']} ({headword}): distractor {d!r} combines with "
                    f"하다/배우다/가르치다 -- substituting it into {sentence!r} "
                    f"produces a second valid Korean sentence, not a nonsense one",
                )

    def test_open_slot_rows_have_activity_free_distractors(self):
        """The residually-open rows (see OPEN_SLOT_ROWS in the module
        docstring) get the same ACTIVITY_NOUN_SET-free check as every
        fused-하다 row, even where their own slot isn't itself a fused
        "___해요" pattern (e.g. 곳's "이 ___에 사람이 많아요." or 교통's
        "___ 카드가 없어요."). This does not certify these rows risk-free
        -- see the packet's 판정 필요 section for the specific residual
        risk honestly flagged on each -- it only guarantees the one
        concrete failure mode (a 하다-collocate leaking in) cannot recur
        here either."""
        vocab_by_source = self.rows_by_id
        for item in self.items:
            headword = vocab_by_source[item["sourceVocabId"]]["korean"]
            if headword not in OPEN_SLOT_ROWS:
                continue
            for d in item["distractors"]:
                self.assertNotIn(
                    d, ACTIVITY_NOUN_SET,
                    f"{item['id']} ({headword}): open-slot distractor {d!r} is an "
                    f"ACTIVITY_NOUN_SET word",
                )

    def test_distractors_carry_the_same_particle_as_a_folded_answer(self):
        """Fable coordinator review of commit b0670d2d (PR #344, 2026-09-15):
        when `answer` is a headword+particle fold (e.g. "생활이", "운전을",
        "주에"), every distractor must carry the matching particle
        allomorph too, appended to the SAME base word already vetted as
        nonsense-only -- otherwise the answer is the only option with a
        particle attached and is identifiable by form alone. See
        a1_draft_rules.distractor_particle_mismatches."""
        vocab_by_source = self.rows_by_id
        for item in self.items:
            headword = vocab_by_source[item["sourceVocabId"]]["korean"]
            bad = R.distractor_particle_mismatches(headword, item["answer"], item["distractors"])
            self.assertEqual(
                bad, [],
                f"{item['id']} ({headword}, answer {item['answer']!r}): distractor(s) "
                f"{bad} don't carry a particle matching the answer's fold",
            )


class TestBatch28Satz(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(DRAFTS / "batch_28_a1_satz.json")["items"]
        cls.live_satz = _load_json(REPO_ROOT / "assets/data/satz_sentences.json")["items"]

    def test_count_matches_vocab(self):
        rows = _load_vocab_rows(DRAFTS / "batch_28_a1_rows.csv")
        self.assertEqual(len(self.items), len(rows))

    def test_ids_unique_and_above_live_and_prior_batches_max(self):
        live_max = max(
            int(i["id"].rsplit("_", 1)[1]) for i in self.live_satz if i["id"].startswith("satz_a1_")
        )
        floor = live_max
        for name in ("batch_26_a1_satz.json", "batch_27_a1_satz.json"):
            path = DRAFTS / name
            items = _load_json(path)["items"] if path.exists() else []
            prior_max = max(
                [int(i["id"].rsplit("_", 1)[1]) for i in items if i["id"].startswith("satz_a1_")],
                default=0,
            )
            floor = max(floor, prior_max)
        ids = [i["id"] for i in self.items]
        self.assertEqual(len(ids), len(set(ids)))
        for item in self.items:
            num = int(item["id"].rsplit("_", 1)[1])
            self.assertGreater(num, floor)

    def test_vocab_ko_and_target_present(self):
        for item in self.items:
            self.assertTrue(item["vocabKo"])
            self.assertGreaterEqual(R.eojeol_count(item["targetKo"]), 1)
            self.assertLessEqual(R.eojeol_count(item["targetKo"]), 8)

    def test_two_distractors(self):
        for item in self.items:
            self.assertEqual(len(item["distractors"]), 2)
            self.assertEqual(len(item["distractors"]), len(set(item["distractors"])))

    def test_three_way_invariant_example_equals_cloze_equals_satz(self):
        """example_korean (vocab row) == cloze fullKo == satz targetKo, for
        every row (matched by sourceVocabId)."""
        vocab_rows = _load_vocab_rows(DRAFTS / "batch_28_a1_rows.csv")
        vocab_by_id = {r["id"]: r["example_korean"] for r in vocab_rows}
        cloze_by_id = {
            c["sourceVocabId"]: c["fullKo"]
            for c in _load_json(DRAFTS / "batch_28_a1_cloze.json")["items"]
        }
        for item in self.items:
            vid = item["sourceVocabId"]
            self.assertEqual(vocab_by_id[vid], item["targetKo"])
            self.assertEqual(cloze_by_id[vid], item["targetKo"])


class TestBatch28PacksFilledTo12(unittest.TestCase):
    def test_touched_packs_reach_twelve(self):
        manifest = _load_json(DRAFTS / "batch_28_a1_reinforcement_manifest.json")
        draft_rows = _load_vocab_rows(DRAFTS / "batch_28_a1_rows.csv")
        live_rows = _load_vocab_rows(VOCAB_CSV)
        b25_rows = _load_vocab_rows(BATCH25_VOCAB_CSV) if BATCH25_VOCAB_CSV.exists() else []
        b26_rows = _load_vocab_rows(BATCH26_VOCAB_CSV) if BATCH26_VOCAB_CSV.exists() else []
        b27_rows = _load_vocab_rows(BATCH27_VOCAB_CSV) if BATCH27_VOCAB_CSV.exists() else []
        live_counts = Counter(r["pack_id"] for r in live_rows if r["level"] == "A1")
        prior_counts = Counter()
        for rows in (b25_rows, b26_rows, b27_rows):
            prior_counts.update(r["pack_id"] for r in rows)
        draft_counts = Counter(r["pack_id"] for r in draft_rows)
        for pack_id in manifest["packsFilledTo12"]:
            total = (
                live_counts.get(pack_id, 0)
                + prior_counts.get(pack_id, 0)
                + draft_counts.get(pack_id, 0)
            )
            self.assertEqual(
                total, 12,
                f"{pack_id}: live {live_counts.get(pack_id, 0)} + prior-batches "
                f"{prior_counts.get(pack_id, 0)} + draft {draft_counts.get(pack_id, 0)} != 12",
            )

    def test_new_packs_have_exactly_twelve_words(self):
        manifest = _load_json(DRAFTS / "batch_28_a1_reinforcement_manifest.json")
        draft_rows = _load_vocab_rows(DRAFTS / "batch_28_a1_rows.csv")
        draft_counts = Counter(r["pack_id"] for r in draft_rows)
        for entry in manifest.get("newPacks", []):
            self.assertEqual(
                draft_counts.get(entry["pack_id"], 0), 12,
                f"new pack {entry['pack_id']} does not have exactly 12 words in the draft",
            )


if __name__ == "__main__":
    unittest.main()
