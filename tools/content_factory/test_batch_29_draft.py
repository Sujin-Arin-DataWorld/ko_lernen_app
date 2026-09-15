#!/usr/bin/env python3
"""Regression tests for the C3 Batch 29 (A1 reinforcement, verbs/adjectives)
DRAFT files.

These tests validate the draft-only artifacts produced for Batch 29:
    tools/content_factory/drafts/batch_29_a1_rows.csv
    tools/content_factory/drafts/batch_29_a1_cloze.json
    tools/content_factory/drafts/batch_29_a1_satz.json
    tools/content_factory/drafts/batch_29_a1_reinforcement_manifest.json

They never touch assets/data/** -- this batch has NOT been approved by Jin
yet (level-canon program hard rule) and must not be promoted until then.

Mirrors test_batch_27/28_draft.py's schema/checks, importing the shared
helpers from a1_draft_rules.py and distractor_rules.py, plus batch-specific
additions:
  - headword-overlap checks against Batch 25/26/27/28's own draft headwords
    (word-source rule: NIKL grade-1, not yet live, not in any prior draft);
  - a verb/adjective ("용언") cloze-distractor rule that is new for this
    batch (Fable brief, 2026-09-16): for the 41 non-waiver 용언 rows, the 3
    distractors must be conjugated in the SAME ending/tense GROUP as the
    answer (e.g. answer "걸어요" -> distractors must also be a present-tense
    -아/어/해요 form, not -았/었어요 past or -(으)세요 honorific); for the 14
    rows tagged waiver=predicate_slot in the generator (open predicate
    slots where >=3 same-form clashing candidates don't exist), distractors
    are bare dictionary-form verbs/adjectives instead (Batch 25-28's
    PREDICATE_SLOT_WAIVER technique) -- test_verb_adj_distractors_match_
    ending_group_or_are_waived enforces this split mechanically. The actual
    "does substituting this produce nonsense" semantic judgement is NOT
    something this test can verify (same as every prior batch's distractor
    hygiene tests) -- that judgement is recorded row-by-row in the review
    packet's evidence table, same convention as Batch 28's 189-row table;
  - test_noun_rows_use_standard_particle_and_batchim_rules: the 10 noun
    rows get the same batchim-class / particle-fold checks Batch 26-28 used
    for all-noun batches.

Run with:
    python -m unittest tools.content_factory.test_batch_29_draft -v
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
BATCH28_VOCAB_CSV = DRAFTS / "batch_28_a1_rows.csv"
PRIOR_BATCH_CSVS = (BATCH26_VOCAB_CSV, BATCH27_VOCAB_CSV, BATCH28_VOCAB_CSV)

VOCAB_COLUMNS = R.VOCAB_COLUMNS

NOUN_HEADWORDS = {
    "가운데", "계속", "말", "먼저", "모두", "영", "전", "제일", "주일", "천만",
}

# Rows whose cloze answer spans a wide-open predicate slot where >=3
# same-ending clashing candidates don't exist (invitation/minimal-response/
# bare-imperative shapes) -- keyed by headword. Their distractors are bare
# dictionary-form verbs/adjectives (Batch 25-28's PREDICATE_SLOT_WAIVER
# technique), not same-ending-group conjugated forms. See the manifest's
# predicateSlotWaiverRows for the per-row reasoning.
#
# R8 revision (Fable coordinator review of 09aea5de, 2026-09-16): the first
# draft over-used this waiver -- 들다, 잘하다, 못하다, 어떻다, 그렇다, 싫다,
# 괜찮다, 특별하다, 한가하다, 반갑다, 멋있다 all had 3 real same-ending
# clashing candidates available and are now Tier A (see EXCLUDE in the
# generator for how each row's collocation risks were closed). Only rows
# with a genuinely open predicate slot -- an invitation/minimal-response/
# manner-adverb frame that accepts a wide range of real verbs/adjectives
# validly -- keep the waiver:
PREDICATE_SLOT_WAIVER_HEADWORDS = {"놀다", "지내다", "울다", "춤추다", "고맙다", "아니다"}

# Ending "groups" for the non-waiver 용언 rows -- a distractor must share
# the answer's group (both members conjugated the same tense/mood), not
# necessarily the identical suffix text (허용: 하다-paradigm 해요 groups
# with plain 아요/어요 present since both are the plain present-polite
# ending, just different final-vowel harmony/contraction).
_SSANGSIOT_JONG = 20  # index of ㅆ among the 28 Hangul syllable finals


def _has_ssangsiot_batchim(ch: str) -> bool:
    code = ord(ch) - 0xAC00
    if not (0 <= code < 11172):
        return False
    return code % 28 == _SSANGSIOT_JONG


# Explicit override for the answer side only: 멋있다/재미없다's dictionary
# form itself already ends in 있다/없다 (lexical ㅆ batchim, not a past-tense
# marker), which would otherwise false-positive the batchim heuristic below
# into classifying their plain-present "멋있어요"/"재미없어요" as past. None
# of the distractor pools contain another 있다/없다-final word, so this
# override is needed only here, not on the distractor side.
ANSWER_ENDING_GROUP_OVERRIDE = {
    "멋있다": "present",
    "재미없다": "present",
}


def _ending_group(text: str) -> str | None:
    """Classify a conjugated 용언 form into a coarse ending/tense group, by
    EXCLUSION rather than positive suffix enumeration -- Korean vowel
    contraction produces too many surface shapes (타요, 와요, 춰요, 봐요,
    돼요, ...) to reliably enumerate as literal regex suffixes. Checked
    most-specific-first: a multi-morpheme ending (수 있어요/고 싶어요/지
    않아요) is checked before the shorter -세요/-까요 endings it could
    otherwise be confused with. Past tense is detected by checking whether
    the syllable 3 characters from the end carries a ㅆ batchim (았/었/했
    and any of their own contracted forms, e.g. 났 in 났어요, 왔 in
    다녀왔어요, 탔 in 탔어요, are ALL a base syllable + ㅆ batchim -- a
    literal '았어요'/'었어요' substring match misses these because the
    contraction fuses the tense marker's ㅆ onto a DIFFERENT syllable block
    than the literal jamo sequence 아+ㅆ). Any remaining '-요'-final polite
    form that isn't past falls through to 'present' (this batch's forms are
    all one of these categories -- see ROWS in the generator)."""
    if text.endswith("수 있어요"):
        return "ability"
    if text.endswith("고 싶어요"):
        return "want"
    if text.endswith("지 않아요"):
        return "negation_short"
    if text.endswith("까요"):
        return "invitation"
    if text.endswith("세요"):
        return "honorific_imperative"
    if len(text) >= 3 and text.endswith("어요") and _has_ssangsiot_batchim(text[-3]):
        return "past"
    if text.endswith("요"):
        return "present"
    return None


def _load_json(path: Path):
    return R.load_json(path)


def _load_vocab_rows(path: Path):
    return R.load_vocab_rows(path)


class TestBatch29DraftFilesExist(unittest.TestCase):
    def test_files_exist(self):
        for name in (
            "batch_29_a1_rows.csv",
            "batch_29_a1_cloze.json",
            "batch_29_a1_satz.json",
            "batch_29_a1_reinforcement_manifest.json",
        ):
            self.assertTrue((DRAFTS / name).exists(), f"missing draft file: {name}")

    def test_review_packet_exists(self):
        packet = REPO_ROOT / "docs/data/review_packets/batch_29_a1_jin_sample.md"
        self.assertTrue(packet.exists())


class TestBatch29NeverTouchesLiveAssets(unittest.TestCase):
    def test_manifest_marks_draft_and_unapproved(self):
        manifest = _load_json(DRAFTS / "batch_29_a1_reinforcement_manifest.json")
        self.assertEqual(manifest["status"], "draft")
        self.assertEqual(manifest["provenance"]["approval"], {})
        self.assertFalse(manifest["promotion"]["assetsDataWritten"])
        self.assertFalse(manifest["promotion"]["runtime"])
        self.assertFalse(manifest["promotion"]["tts"])
        self.assertFalse(manifest["promotion"]["firebase"])

    def test_no_live_headword_was_added(self):
        draft_rows = _load_vocab_rows(DRAFTS / "batch_29_a1_rows.csv")
        live_rows = _load_vocab_rows(VOCAB_CSV)
        live_korean = {r["korean"] for r in live_rows}
        for row in draft_rows:
            self.assertNotIn(
                row["korean"], live_korean,
                f"{row['korean']} ({row['id']}) is already live -- draft should not duplicate it",
            )

    def test_no_overlap_with_prior_batch_words(self):
        draft_rows = _load_vocab_rows(DRAFTS / "batch_29_a1_rows.csv")
        draft_korean = {r["korean"] for r in draft_rows}
        for path in (BATCH25_VOCAB_CSV, *PRIOR_BATCH_CSVS):
            if not path.exists():
                continue
            prior_korean = {r["korean"] for r in _load_vocab_rows(path)}
            overlap = draft_korean & prior_korean
            self.assertEqual(overlap, set(), f"Batch 29 reuses {path.name} words: {overlap}")


class TestBatch29VocabRows(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = _load_vocab_rows(DRAFTS / "batch_29_a1_rows.csv")
        cls.live_rows = _load_vocab_rows(VOCAB_CSV)
        cls.live_pack_ids = {r["pack_id"] for r in cls.live_rows}
        cls.manifest = _load_json(DRAFTS / "batch_29_a1_reinforcement_manifest.json")

    def test_header_matches_live_csv(self):
        with (DRAFTS / "batch_29_a1_rows.csv").open(encoding="utf-8") as f:
            header = next(csv.reader(f))
        self.assertEqual(header, VOCAB_COLUMNS)

    def test_row_count_in_range(self):
        self.assertGreaterEqual(len(self.rows), 60)
        self.assertLessEqual(len(self.rows), 70)

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
        for path in PRIOR_BATCH_CSVS:
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
        cloze = _load_json(DRAFTS / "batch_29_a1_cloze.json")["items"]
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

    def test_no_ji_malda_grammar(self):
        """'-지 말다' (prohibitive) is 2급 grammar, out of scope for this
        batch (Batch 28 R8 precedent). 말다 itself is authored using its
        other, non-auxiliary dictionary sense instead -- see the manifest's
        malDecisionNote."""
        for row in self.rows:
            self.assertNotRegex(
                row["example_korean"], r"지\s*마세요|지\s*마요|지\s*말(?!아요)",
                f"{row['id']}: uses '-지 말다' prohibitive (out of scope): {row['example_korean']}",
            )

    def test_no_jinjja(self):
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
            own_rows,
            extra_headword_csvs=[BATCH25_VOCAB_CSV, *PRIOR_BATCH_CSVS],
        )
        overrides = {
            "걸어요": "걸다", "그려요": "그리다", "났어요": "나다", "넣어요": "넣다",
            "놀까요": "놀다", "되고": "되다", "불러요": "부르다",
            "시켜요": "시키다", "찍어요": "찍다", "춰요": "추다", "쳐요": "치다",
            "다녀왔어요": "다녀오다", "돌아가요": "돌아가다", "돌아오세요": "돌아오다",
            "들어가지": "들어가다", "들어와요": "들어오다", "올라갈": "올라가다",
            "불어요": "불다", "울어요": "울다", "잘해요": "잘하다", "지나요": "지나다",
            "지내요": "지내다", "피우지": "피우다", "못해요": "못하다",
            "알려요": "알리다", "찾아봐요": "찾아보다", "춤춰요": "춤추다",
            "같아요": "같다", "고마워요": "고맙다", "고파요": "고프다",
            "괜찮아요": "괜찮다", "그래요": "그렇다", "깨끗해요": "깨끗하다",
            "나빠요": "나쁘다", "낮아요": "낮다", "높아요": "높다", "달라요": "다르다",
            "따뜻해요": "따뜻하다", "맑아요": "맑다", "멋있어요": "멋있다",
            "반가워요": "반갑다", "시원해요": "시원하다", "싫어요": "싫다",
            "아니에요": "아니다", "아름다워요": "아름답다", "어때요": "어떻다",
            "재미없어요": "재미없다", "적어요": "적다", "친해요": "친하다",
            "특별해요": "특별하다", "한가해요": "한가하다", "흐릴까요": "흐리다",
            "힘들어요": "힘들다",
            "씻어요": "씻다", "들어요": "듣다",
            "만나서": "만나다", "와요": "오다", "친구들이": "친구",
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


class TestBatch29Cloze(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(DRAFTS / "batch_29_a1_cloze.json")["items"]
        cls.live_cloze = _load_json(REPO_ROOT / "assets/data/cloze.json")["items"]
        cls.rows_by_id = {
            r["id"]: r for r in _load_vocab_rows(DRAFTS / "batch_29_a1_rows.csv")
        }

    def test_count_matches_vocab(self):
        rows = _load_vocab_rows(DRAFTS / "batch_29_a1_rows.csv")
        self.assertEqual(len(self.items), len(rows))

    def test_ids_unique_and_above_live_and_prior_batches_max(self):
        live_max = max(
            int(i["id"].rsplit("_", 1)[1]) for i in self.live_cloze if i["id"].startswith("cloze_a1_")
        )
        floor = live_max
        for name in ("batch_26_a1_cloze.json", "batch_27_a1_cloze.json", "batch_28_a1_cloze.json"):
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

    def test_verb_adj_distractors_match_ending_group_or_are_waived(self):
        """For the 41 non-waiver 용언 (verb/adjective) rows, all 3
        distractors must be conjugated in the SAME ending/tense GROUP as
        the answer (see ENDING_GROUPS above). For the 14 rows tagged
        waiver=predicate_slot (open predicate slots -- see the manifest's
        predicateSlotWaiverRows), distractors are bare dictionary-form
        verbs/adjectives instead (end in plain '다', optionally prefixed
        with '잘 ' for the 잘하다/못하다 '잘 + V' slot)."""
        vocab_by_source = self.rows_by_id
        for item in self.items:
            headword = vocab_by_source[item["sourceVocabId"]]["korean"]
            if headword in NOUN_HEADWORDS:
                continue
            if headword in PREDICATE_SLOT_WAIVER_HEADWORDS:
                for d in item["distractors"]:
                    bare = d[2:] if d.startswith("잘 ") else d
                    self.assertTrue(
                        bare.endswith("다"),
                        f"{item['id']} ({headword}): waived distractor {d!r} is not a bare dictionary form",
                    )
                continue
            answer_group = ANSWER_ENDING_GROUP_OVERRIDE.get(headword) or _ending_group(item["answer"])
            self.assertIsNotNone(
                answer_group, f"{item['id']} ({headword}): answer {item['answer']!r} matches no known ending group"
            )
            for d in item["distractors"]:
                dg = _ending_group(d)
                self.assertEqual(
                    dg, answer_group,
                    f"{item['id']} ({headword}): distractor {d!r} is ending-group {dg!r}, "
                    f"answer {item['answer']!r} is {answer_group!r}",
                )

    def test_noun_rows_use_standard_particle_and_batchim_rules(self):
        """The 10 noun rows: at least 2/3 distractors are themselves
        noun-like (not bare verbs), mirroring Batch 26-28's noun-batch
        convention."""
        vocab_by_source = self.rows_by_id
        verb_like_suffixes = ("다", "요")
        for item in self.items:
            headword = vocab_by_source[item["sourceVocabId"]]["korean"]
            if headword not in NOUN_HEADWORDS:
                continue
            noun_like = [d for d in item["distractors"] if not d.endswith("다")]
            self.assertGreaterEqual(
                len(noun_like), 2,
                f"{item['id']} ({headword}): fewer than 2/3 distractors are noun-like: {item['distractors']}",
            )

    def test_distractors_carry_the_same_particle_as_a_folded_answer(self):
        vocab_by_source = self.rows_by_id
        for item in self.items:
            headword = vocab_by_source[item["sourceVocabId"]]["korean"]
            bad = R.distractor_particle_mismatches(headword, item["answer"], item["distractors"])
            self.assertEqual(
                bad, [],
                f"{item['id']} ({headword}, answer {item['answer']!r}): distractor(s) "
                f"{bad} don't carry a particle matching the answer's fold",
            )


class TestBatch29Satz(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(DRAFTS / "batch_29_a1_satz.json")["items"]
        cls.live_satz = _load_json(REPO_ROOT / "assets/data/satz_sentences.json")["items"]

    def test_count_matches_vocab(self):
        rows = _load_vocab_rows(DRAFTS / "batch_29_a1_rows.csv")
        self.assertEqual(len(self.items), len(rows))

    def test_ids_unique_and_above_live_and_prior_batches_max(self):
        live_max = max(
            int(i["id"].rsplit("_", 1)[1]) for i in self.live_satz if i["id"].startswith("satz_a1_")
        )
        floor = live_max
        for name in ("batch_26_a1_satz.json", "batch_27_a1_satz.json", "batch_28_a1_satz.json"):
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

    def test_distractors_not_in_target(self):
        for item in self.items:
            for d in item["distractors"]:
                self.assertNotIn(d, item["targetKo"], f"{item['id']}: distractor {d!r} already in targetKo")

    def test_three_way_invariant_example_equals_cloze_equals_satz(self):
        vocab_rows = _load_vocab_rows(DRAFTS / "batch_29_a1_rows.csv")
        vocab_by_id = {r["id"]: r["example_korean"] for r in vocab_rows}
        cloze_by_id = {
            c["sourceVocabId"]: c["fullKo"]
            for c in _load_json(DRAFTS / "batch_29_a1_cloze.json")["items"]
        }
        for item in self.items:
            vid = item["sourceVocabId"]
            self.assertEqual(vocab_by_id[vid], item["targetKo"])
            self.assertEqual(cloze_by_id[vid], item["targetKo"])


class TestBatch29Packs(unittest.TestCase):
    def test_new_packs_have_declared_word_count(self):
        manifest = _load_json(DRAFTS / "batch_29_a1_reinforcement_manifest.json")
        draft_rows = _load_vocab_rows(DRAFTS / "batch_29_a1_rows.csv")
        draft_counts = Counter(r["pack_id"] for r in draft_rows)
        for entry in manifest.get("newPacks", []):
            self.assertEqual(
                draft_counts.get(entry["pack_id"], 0), entry["wordCount"],
                f"new pack {entry['pack_id']} draft count != declared wordCount",
            )

    def test_no_under_12_live_pack_was_missed_without_documented_reason(self):
        manifest = _load_json(DRAFTS / "batch_29_a1_reinforcement_manifest.json")
        self.assertEqual(manifest.get("packsFilledTo12"), [])
        left = {p["pack_id"] for p in manifest.get("packsLeftUnfilled", [])}
        self.assertEqual(left, {"a1_colors", "a1_partner_meet_names_1"})


if __name__ == "__main__":
    unittest.main()
