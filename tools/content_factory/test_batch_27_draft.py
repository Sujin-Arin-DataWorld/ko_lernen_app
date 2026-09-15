#!/usr/bin/env python3
"""Regression tests for the C3 Batch 27 (A1 reinforcement) DRAFT files.

These tests validate the draft-only artifacts produced for Batch 27:
    tools/content_factory/drafts/batch_27_a1_rows.csv
    tools/content_factory/drafts/batch_27_a1_cloze.json
    tools/content_factory/drafts/batch_27_a1_satz.json
    tools/content_factory/drafts/batch_27_a1_reinforcement_manifest.json

They never touch assets/data/** -- this batch has NOT been approved by Jin
yet (level-canon program hard rule) and must not be promoted until then.

This file mirrors test_batch_26_draft.py's schema/checks (same base
contract), refactored to import the shared helpers from a1_draft_rules.py
instead of re-defining them (Batch 27 authoring, 2026-09-15), plus:
  - a batch-specific check that none of the 63 headwords duplicate
    Batch 25's or Batch 26's headwords (word-source rule: NIKL grade-1,
    not yet live, not in the Batch 26 draft);
  - a predicate-slot-waiver check for the 3 verb rows (켜다/끄다/웃다),
    whose cloze answer is a conjugated predicate, not a bare noun -- their
    distractors are bare dictionary-form verbs (distractor_rules.py's
    waiver technique), not batchim-matched nouns.

Run with:
    python -m unittest tools.content_factory.test_batch_27_draft -v
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

VOCAB_COLUMNS = R.VOCAB_COLUMNS

# This batch's own 3 verb headwords -- their cloze answer is a conjugated
# predicate (sentence-final), covered by the predicate-slot waiver, not the
# "2/3 distractors are noun-like" rule used for the other 60 (all Nomen)
# rows.
VERB_HEADWORDS = {"켜다", "끄다", "웃다"}

# R8 (Fable coordinator review of PR #342, 2026-09-15): 4 rows keep a
# structurally "open" adjective/existential slot that a rewrite couldn't
# fully narrow (수첩/건너편/대사관/기분 -- see the review packet's
# "선정 요약 및 방법론" section). For these, a concrete-object noun
# distractor (drawn from this batch's own 60 headwords) risks forming a
# SECOND VALID sentence (e.g. "이 사무실이 정말 예뻐요" reads fine). Their
# noun-type distractors must come only from this hand-verified
# per-predicate-safe abstract-noun allowlist instead of an arbitrary
# concrete-object headword.
OPEN_SLOT_HEADWORDS = {"수첩", "건너편", "대사관", "기분"}
OPEN_SLOT_ABSTRACT_ALLOWLIST = {"미안", "실례", "피곤"}

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


class TestBatch27DraftFilesExist(unittest.TestCase):
    def test_files_exist(self):
        for name in (
            "batch_27_a1_rows.csv",
            "batch_27_a1_cloze.json",
            "batch_27_a1_satz.json",
            "batch_27_a1_reinforcement_manifest.json",
        ):
            self.assertTrue((DRAFTS / name).exists(), f"missing draft file: {name}")

    def test_review_packet_exists(self):
        packet = REPO_ROOT / "docs/data/review_packets/batch_27_a1_jin_sample.md"
        self.assertTrue(packet.exists())


class TestBatch27NeverTouchesLiveAssets(unittest.TestCase):
    """Hard rule: this batch is a draft-only packet. It must not appear in
    the live app data until Jin approves it."""

    def test_manifest_marks_draft_and_unapproved(self):
        manifest = _load_json(DRAFTS / "batch_27_a1_reinforcement_manifest.json")
        self.assertEqual(manifest["status"], "draft")
        self.assertEqual(manifest["provenance"]["approval"], {})
        self.assertFalse(manifest["promotion"]["assetsDataWritten"])
        self.assertFalse(manifest["promotion"]["runtime"])
        self.assertFalse(manifest["promotion"]["tts"])
        self.assertFalse(manifest["promotion"]["firebase"])

    def test_no_live_headword_was_added(self):
        draft_rows = _load_vocab_rows(DRAFTS / "batch_27_a1_rows.csv")
        live_rows = _load_vocab_rows(VOCAB_CSV)
        live_korean = {r["korean"] for r in live_rows}
        for row in draft_rows:
            self.assertNotIn(
                row["korean"], live_korean,
                f"{row['korean']} ({row['id']}) is already live -- draft should not duplicate it",
            )

    def test_no_overlap_with_batch_25_words(self):
        draft_rows = _load_vocab_rows(DRAFTS / "batch_27_a1_rows.csv")
        if not BATCH25_VOCAB_CSV.exists():
            self.skipTest("batch_25_a1_rows.csv not present in this checkout")
        b25_korean = {r["korean"] for r in _load_vocab_rows(BATCH25_VOCAB_CSV)}
        overlap = {r["korean"] for r in draft_rows} & b25_korean
        self.assertEqual(overlap, set(), f"Batch 27 reuses Batch 25 words: {overlap}")

    def test_no_overlap_with_batch_26_words(self):
        draft_rows = _load_vocab_rows(DRAFTS / "batch_27_a1_rows.csv")
        if not BATCH26_VOCAB_CSV.exists():
            self.skipTest("batch_26_a1_rows.csv not present in this checkout")
        b26_korean = {r["korean"] for r in _load_vocab_rows(BATCH26_VOCAB_CSV)}
        overlap = {r["korean"] for r in draft_rows} & b26_korean
        self.assertEqual(overlap, set(), f"Batch 27 reuses Batch 26 words: {overlap}")


class TestBatch27VocabRows(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = _load_vocab_rows(DRAFTS / "batch_27_a1_rows.csv")
        cls.live_rows = _load_vocab_rows(VOCAB_CSV)
        cls.live_pack_ids = {r["pack_id"] for r in cls.live_rows}
        cls.manifest = _load_json(DRAFTS / "batch_27_a1_reinforcement_manifest.json")

    def test_header_matches_live_csv(self):
        with (DRAFTS / "batch_27_a1_rows.csv").open(encoding="utf-8") as f:
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

    def test_all_ids_unique_and_above_live_and_b26_max(self):
        live_max = max(
            int(r["id"].rsplit("_", 1)[1]) for r in self.live_rows if r["id"].startswith("vocab_a1_")
        )
        b26_rows = _load_vocab_rows(BATCH26_VOCAB_CSV) if BATCH26_VOCAB_CSV.exists() else []
        b26_max = max(
            [int(r["id"].rsplit("_", 1)[1]) for r in b26_rows if r["id"].startswith("vocab_a1_")],
            default=0,
        )
        floor = max(live_max, b26_max)
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
        cloze = _load_json(DRAFTS / "batch_27_a1_cloze.json")["items"]
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
        """'진짜' must never appear -- A1 emphasis is always '정말' (Jin
        ruling carried over from Batch 26)."""
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
            own_rows, extra_headword_csvs=[BATCH26_VOCAB_CSV, BATCH25_VOCAB_CSV],
        )
        overrides = {
            "켜요": "켜다", "꺼요": "끄다", "웃어요": "웃다",
            "잔이": "잔", "표가": "표", "층에": "층", "개가": "개", "꽃이": "꽃",
            "산에": "산", "비가": "비", "불이": "불", "후에": "후",
            "와요": "오다", "났어요": "나다", "바빴어요": "바쁘다", "바빠요": "바쁘다",
            "아팠어요": "아프다", "만났어요": "만나다", "만나요": "만나다",
            "피곤해요": "피곤", "사랑해요": "사랑", "친절해요": "친절", "유명해요": "유명",
            "대답해요": "대답", "소개해요": "소개", "설명해요": "설명", "감사해요": "감사",
            "미안해요": "미안", "높아요": "높다", "커요": "크다", "읽어요": "읽다",
            "써요": "쓰다", "살아요": "살다", "있어요": "있다", "실례합니다": "실례",
            "예뻐요": "예쁘다", "자요": "자다", "여기서": "여기", "갈까요": "가다",
            "해요": "하다", "주세요": "주다",
            "잘까요": "자다", "마셔요": "마시다", "줘요": "주다", "올라가요": "올라가다",
            "아파요": "아프다", "일해요": "일하다", "입었어요": "입다", "입고": "입다",
            "수영해요": "수영", "뭐가": "뭐", "명이": "명", "어디에": "어디",
            "찍어요": "찍다", "잔으로": "잔", "꽃에": "꽃",
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


class TestBatch27Cloze(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(DRAFTS / "batch_27_a1_cloze.json")["items"]
        cls.live_cloze = _load_json(REPO_ROOT / "assets/data/cloze.json")["items"]
        cls.rows_by_id = {
            r["id"]: r for r in _load_vocab_rows(DRAFTS / "batch_27_a1_rows.csv")
        }

    def test_count_matches_vocab(self):
        rows = _load_vocab_rows(DRAFTS / "batch_27_a1_rows.csv")
        self.assertEqual(len(self.items), len(rows))

    def test_ids_unique_and_above_live_and_b26_max(self):
        live_max = max(
            int(i["id"].rsplit("_", 1)[1]) for i in self.live_cloze if i["id"].startswith("cloze_a1_")
        )
        b26_path = DRAFTS / "batch_26_a1_cloze.json"
        b26_items = _load_json(b26_path)["items"] if b26_path.exists() else []
        b26_max = max(
            [int(i["id"].rsplit("_", 1)[1]) for i in b26_items if i["id"].startswith("cloze_a1_")],
            default=0,
        )
        floor = max(live_max, b26_max)
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
        """Every non-verb Batch 27 headword is a Nomen, so at least 2 of the
        3 distractors must themselves be noun-like. The 3 verb-headword rows
        (켜다/끄다/웃다) use the predicate-slot waiver instead (their answer
        spans the whole conjugated predicate; all 3 distractors are bare
        dictionary-form verbs, which is stricter than the 2/3 noun rule,
        not a relaxation of it)."""
        vocab_by_source = self.rows_by_id
        for item in self.items:
            headword = vocab_by_source[item["sourceVocabId"]]["korean"]
            if headword in {"켜다", "끄다", "웃다"}:
                for d in item["distractors"]:
                    self.assertIn(d, VERB_WORDS, f"{item['id']}: predicate-slot distractor {d!r} is not a bare dictionary-form verb")
                continue
            noun_like = [d for d in item["distractors"] if _is_noun_like(d)]
            self.assertGreaterEqual(
                len(noun_like), 2,
                f"{item['id']}: fewer than 2/3 distractors are noun-like: {item['distractors']}",
            )

    def test_no_concrete_object_noun_in_an_open_adjective_or_existential_slot(self):
        """R8 (Fable, 2026-09-15): 수첩/건너편/대사관/기분 keep a bare open
        adjective/existential slot (e.g. "이 ___이 정말 예뻐요.",
        "___이 어디에 있어요?") that this batch's OWN concrete-object
        headwords (가방/사무실/수영장/...) would slot into just as
        validly as the real answer -- e.g. "이 사무실이 정말 예뻐요" is a
        perfectly natural sentence, so a cross-pack concrete noun there is
        a second valid answer, not nonsense. For these 4 rows, every
        noun-type distractor must come from the hand-verified
        per-predicate-safe abstract allowlist instead."""
        vocab_by_source = self.rows_by_id
        for item in self.items:
            headword = vocab_by_source[item["sourceVocabId"]]["korean"]
            if headword not in OPEN_SLOT_HEADWORDS:
                continue
            noun_like = [d for d in item["distractors"] if _is_noun_like(d)]
            for d in noun_like:
                self.assertIn(
                    d, OPEN_SLOT_ABSTRACT_ALLOWLIST,
                    f"{item['id']} ({headword}): open-slot distractor {d!r} is a concrete-object "
                    f"noun, not from the verified-safe abstract allowlist {OPEN_SLOT_ABSTRACT_ALLOWLIST}",
                )

    def test_verb_row_distractors_exclude_the_natural_collocate_boda(self):
        """R8 (Fable, 2026-09-15): 보다 (dictionary-form "watch/look at") is
        a too-natural collocate of both 텔레비전을 ___ (켜다) and
        불을 ___ (끄다/보다 = "look at the light/fire") -- even as an
        unconjugated predicate-slot distractor it reads as thematically
        plausible in a way a learner could mistake for a hint. Excluded
        from all 3 verb rows' distractor pools."""
        vocab_by_source = self.rows_by_id
        for item in self.items:
            headword = vocab_by_source[item["sourceVocabId"]]["korean"]
            if headword in VERB_HEADWORDS:
                self.assertNotIn(
                    "보다", item["distractors"],
                    f"{item['id']} ({headword}): 보다 is a too-natural collocate distractor",
                )

    def test_distractors_carry_the_same_particle_as_a_folded_answer(self):
        """Fable coordinator review of PR #344 (2026-09-15): when `answer`
        is a headword+particle fold (e.g. "잔으로", "표가", "층에"), every
        distractor must carry the matching particle allomorph too (대사관으로/
        건물로, not bare 대사관/건물) -- otherwise the answer is the only
        option with a particle attached and is identifiable by form alone.
        9 rows fixed on 2026-09-15 (distractors only, no KO/DE/EN changed).
        See a1_draft_rules.distractor_particle_mismatches."""
        vocab_by_source = self.rows_by_id
        for item in self.items:
            headword = vocab_by_source[item["sourceVocabId"]]["korean"]
            bad = R.distractor_particle_mismatches(headword, item["answer"], item["distractors"])
            self.assertEqual(
                bad, [],
                f"{item['id']} ({headword}, answer {item['answer']!r}): distractor(s) "
                f"{bad} don't carry a particle matching the answer's fold",
            )


class TestBatch27Satz(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(DRAFTS / "batch_27_a1_satz.json")["items"]
        cls.live_satz = _load_json(REPO_ROOT / "assets/data/satz_sentences.json")["items"]

    def test_count_matches_vocab(self):
        rows = _load_vocab_rows(DRAFTS / "batch_27_a1_rows.csv")
        self.assertEqual(len(self.items), len(rows))

    def test_ids_unique_and_above_live_and_b26_max(self):
        live_max = max(
            int(i["id"].rsplit("_", 1)[1]) for i in self.live_satz if i["id"].startswith("satz_a1_")
        )
        b26_path = DRAFTS / "batch_26_a1_satz.json"
        b26_items = _load_json(b26_path)["items"] if b26_path.exists() else []
        b26_max = max(
            [int(i["id"].rsplit("_", 1)[1]) for i in b26_items if i["id"].startswith("satz_a1_")],
            default=0,
        )
        floor = max(live_max, b26_max)
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
        vocab_rows = _load_vocab_rows(DRAFTS / "batch_27_a1_rows.csv")
        vocab_by_id = {r["id"]: r["example_korean"] for r in vocab_rows}
        cloze_by_id = {
            c["sourceVocabId"]: c["fullKo"]
            for c in _load_json(DRAFTS / "batch_27_a1_cloze.json")["items"]
        }
        for item in self.items:
            vid = item["sourceVocabId"]
            self.assertEqual(vocab_by_id[vid], item["targetKo"])
            self.assertEqual(cloze_by_id[vid], item["targetKo"])


class TestBatch27PacksFilledTo12(unittest.TestCase):
    def test_touched_packs_reach_twelve(self):
        manifest = _load_json(DRAFTS / "batch_27_a1_reinforcement_manifest.json")
        draft_rows = _load_vocab_rows(DRAFTS / "batch_27_a1_rows.csv")
        live_rows = _load_vocab_rows(VOCAB_CSV)
        live_counts = Counter(r["pack_id"] for r in live_rows if r["level"] == "A1")
        draft_counts = Counter(r["pack_id"] for r in draft_rows)
        for pack_id in manifest["packsFilledTo12"]:
            total = live_counts.get(pack_id, 0) + draft_counts.get(pack_id, 0)
            self.assertEqual(total, 12, f"{pack_id}: live {live_counts.get(pack_id, 0)} + draft {draft_counts.get(pack_id, 0)} != 12")

    def test_new_packs_have_exactly_twelve_words(self):
        manifest = _load_json(DRAFTS / "batch_27_a1_reinforcement_manifest.json")
        draft_rows = _load_vocab_rows(DRAFTS / "batch_27_a1_rows.csv")
        draft_counts = Counter(r["pack_id"] for r in draft_rows)
        for entry in manifest.get("newPacks", []):
            self.assertEqual(
                draft_counts.get(entry["pack_id"], 0), 12,
                f"new pack {entry['pack_id']} does not have exactly 12 words in the draft",
            )


if __name__ == "__main__":
    unittest.main()
