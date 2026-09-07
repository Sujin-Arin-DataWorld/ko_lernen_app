"""Tests for tool/cefr_lexicon.py (plan Section 6/T1.2; R3-revised).

Three layers:

* Synthetic-fixture tests (`TestCefrLexiconSynthetic`,
  `TestGrammarIndexTableDriven`) exercise the lookup-order contract and the
  10 required grammar patterns against tiny, hand-built rows -- independent
  of the real (large, occasionally-updated) lexicon CSVs.
* Real-data tests (`TestRealLexiconGoldenCases`, `TestVocabUnknownRatio`,
  `TestSentenceUnknownRatio`) load the actual
  `tools/content_factory/lexicon/*.csv` and
  `assets/data/{grammar,korean_vocab,cloze}.{csv,json}` produced by T1.1,
  and check the golden cases from the R3 brief plus the two unknown-ratio
  measurements (Section 6/T1.2 targets: vocab headword unknown ratio <=10%,
  sentence unknown-token ratio over all cloze fullKo <=12%).
* `TestR3TokenizerGoldenCases` and `TestR3GrammarOverMatching` are the
  rework's own golden suites, one assertion per bullet in the R3 rejection
  brief (homograph minimum-grade, confidence/low-confidence capping, proper
  nouns, the ~25 tokenizer/irregular-conjugation cases, and the
  grammar-over-matching fixes).

Known, documented deviation from an early draft of the brief's golden
cases -- see `TestRealLexiconGoldenCases.test_cheunggan_soeum_is_unknown_not_a_fabricated_grade_3`
below and the module docstring of `tool/cefr_lexicon.py`: layer-noise word
(cheunggan soeum) is not a headword in either remaining NIKL source list
(verified directly against both CSVs -- see the grep evidence in the T1.2
report to Fable), so `word_grade()` on it correctly resolves to `unknown`,
not the `(3, 'B1', 'kiiq')` an earlier brief draft assumed. This test
asserts the real, data-backed behaviour instead of a fabricated grade.

Also documented for Fable (T1.2 report §open_questions), NOT a test
failure: `word_grade('진지')` (the honorific/culture word for "meal")
resolves to kiiq grade 5 / C1 because that is genuinely the ONLY kiiq row
for the headword '진지' (checked directly -- no sibling homograph at a
lower grade exists to take the minimum over, unlike '싸다'). The R3 fix
(minimum grade across every homograph sharing a headword) is real and
verified by `test_homograph_insensitive_takes_the_minimum_not_the_highest`
below; it does not by itself lower a headword that has only one kiiq row.
Overriding kiiq's own grade for a single-entry headword would mean
inventing lexicon data, which this module deliberately never does (see the
층간소음 test) -- so this is flagged as a data/curriculum question for
Fable's ruling (alias vs. accepted kiiq-register mismatch), not silently
patched.
"""

from __future__ import annotations

import csv
import json
import sys
import unittest
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tool import cefr_lexicon as cl


def _kiiq_row(grade, headword, homograph=0, pos="명사", guide="", band="초급"):
    return {
        "grade": str(grade), "headword": headword, "homograph": str(homograph),
        "pos": pos, "guide": guide, "band": band,
    }


def _basic_row(grade, headword, homograph=0, pos="명사", origin="고유어"):
    return {
        "grade": str(grade), "headword": headword, "homograph": str(homograph),
        "pos": pos, "origin": origin,
    }


def _alias_row(app_form, lexicon_form, note=""):
    return {"app_form": app_form, "lexicon_form": lexicon_form, "note": note}


class TestCefrLexiconSynthetic(unittest.TestCase):
    """Lookup-order contract (plan Section 3.C.1, R3-revised) against a
    tiny, fully-controlled fixture -- independent of the real lexicon CSVs."""

    @classmethod
    def setUpClass(cls):
        kiiq_rows = [
            _kiiq_row(1, "공부"),
            _kiiq_row(1, "안녕", homograph=2, pos="감탄사"),
            _kiiq_row(3, "층"),  # unrelated root; not the compound under test
            _kiiq_row(2, "휴대폰"),
            _kiiq_row(1, "저", homograph=1, pos="대명사"),
            _kiiq_row(1, "저", homograph=3, pos="대명사"),
            _kiiq_row(4, "확보"),
            _kiiq_row(1, "걸리다", homograph=1, pos="동사"),
            # R3 item 1 fixture: a headword whose homograph-0 row is the
            # HIGHEST grade, mirroring the real '싸다' bug (homograph 0 =
            # 고급/5 "입이 싸다", homograph 3 = 초급/1 "가격이 싸다").
            _kiiq_row(5, "싸다", homograph=0, pos="형용사", guide="입이 싸다"),
            _kiiq_row(2, "싸다", homograph=1, pos="동사", guide="짐을 싸다"),
            _kiiq_row(3, "싸다", homograph=2, pos="동사", guide="오줌을 싸다"),
            _kiiq_row(1, "싸다", homograph=3, pos="형용사", guide="가격이 싸다"),
        ]
        basic_rows = [
            _basic_row(5, "층간"),
            _basic_row(1, "소음", homograph=6),
            _basic_row(5, "장모님"),
        ]
        alias_rows = [
            _alias_row("핸드폰", "휴대폰", "구어 별칭"),
            _alias_row("화이팅", "", "감탄 표현, A1 유지 예외"),
            _alias_row("여자친구", "여자 친구", ""),
        ]
        cls.lex = cl.CefrLexicon.from_rows(
            kiiq_rows, basic_rows, alias_rows, proper_nouns=("현우", "지은")
        )

    def test_kiiq_exact(self):
        wg = self.lex.word_grade("공부")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (1, "A1", "kiiq"))

    def test_derived_strips_hada_to_kiiq_root(self):
        wg = self.lex.word_grade("공부하다")
        self.assertEqual((wg.grade, wg.cefr, wg.source, wg.matched), (1, "A1", "derived", "공부"))

    def test_homograph_insensitive_takes_minimum_grade(self):
        # '저' only exists as homograph 1 and 3 (no homograph 0) -- must
        # still resolve, and to the minimum of the two (both are grade 1
        # here, but see the dedicated '싸다'-style test below for a case
        # where the homograph-0 row is NOT the minimum).
        wg = self.lex.word_grade("저")
        self.assertEqual((wg.grade, wg.source), (1, "kiiq"))
        self.assertEqual(wg.matched, "저(h1,h3)")

    def test_homograph_insensitive_takes_the_minimum_not_the_highest(self):
        # R3 item 1 (the reworked bug): the old code privileged the
        # homograph-0 row unconditionally, so '싸다' resolved to grade 5
        # (its homograph-0 "입이 싸다" sense) even though homograph 3
        # ("가격이 싸다", "cheap") is grade 1. The fix takes the MINIMUM
        # across every row sharing the headword, including homograph 0.
        wg = self.lex.word_grade("싸다")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (1, "A1", "kiiq"))
        self.assertEqual(wg.matched, "싸다(h0,h1,h2,h3)")

    def test_word_grade_confidence_is_high_for_kiiq(self):
        self.assertEqual(self.lex.word_grade("공부").confidence, "high")

    def test_word_grade_confidence_is_high_for_derived(self):
        self.assertEqual(self.lex.word_grade("공부하다").confidence, "high")

    def test_word_grade_confidence_is_high_for_alias(self):
        self.assertEqual(self.lex.word_grade("핸드폰").confidence, "high")

    def test_word_grade_confidence_is_low_for_basic2023(self):
        # basic2023 is the general-literacy fallback tier (R3 item 2) --
        # word_grade() still returns the RAW (uncapped) grade.
        wg = self.lex.word_grade("장모님")
        self.assertEqual((wg.grade, wg.source, wg.confidence), (6, "basic2023", "low"))

    def test_word_grade_confidence_is_none_when_unresolved(self):
        self.assertIsNone(self.lex.word_grade("가나다라마바").confidence)

    def test_alias_direct(self):
        wg = self.lex.word_grade("핸드폰")
        self.assertEqual((wg.grade, wg.cefr, wg.source, wg.matched), (2, "A2", "alias", "휴대폰"))

    def test_alias_empty_lexicon_form_is_a1_exception(self):
        wg = self.lex.word_grade("화이팅")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (1, "A1", "alias"))

    def test_alias_multiword_lexicon_form_reports_alias_source(self):
        wg = self.lex.word_grade("여자친구")
        # Neither "여자" nor "친구" exists in this tiny fixture, so the
        # resolved grade is None, but the source must still say 'alias'
        # (this is a lookup-routing test, not a real-grade test).
        self.assertEqual(wg.source, "alias")

    def test_basic2023_fallback(self):
        # basic2023 grade 5 -> BASIC2023_TO_CEFR[5] == 'C2' (int grade 6).
        wg = self.lex.word_grade("층간")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (6, "C2", "basic2023"))

    def test_no_kcenter_source_remains(self):
        # R3 item 3: the kcenter tier is removed entirely -- no word_grade
        # result may report it, and from_rows() no longer accepts a
        # kcenter_rows argument (see setUpClass -- from_rows is called with
        # exactly 3 positional row iterables + proper_nouns).
        for word in ("공부", "핸드폰", "층간", "가나다라마바"):
            self.assertNotEqual(self.lex.word_grade(word).source, "kcenter")

    def test_unknown_word(self):
        wg = self.lex.word_grade("가나다라마바")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (None, None, None))

    def test_unspaced_compound_of_two_known_parts_is_still_unknown(self):
        # Mirrors the real-data finding: two real headwords concatenated
        # with no space form a single token, which the multiword step
        # (space-separated input only) never touches -- so it falls
        # through to unknown even though the two PARTS exist separately.
        wg = self.lex.word_grade("층간소음")
        self.assertIsNone(wg.grade)

    def test_phrase_grade_takes_max_over_content_words(self):
        pg = self.lex.phrase_grade("접근성을 확보하다")
        self.assertEqual(pg.grade, 4)
        self.assertIn("접근성을", pg.unknown)

    def test_phrase_grade_restores_hada_greeting(self):
        pg = self.lex.phrase_grade("안녕하세요")
        self.assertEqual(pg.grade, 1)
        self.assertEqual(pg.cefr, "A1")

    def test_contraction_restores_verb_via_lemma_candidates(self):
        # geollyeoseo (geollida + eoseo, i+eo -> yeo fusion) should
        # resolve to the kiiq-listed geollida (grade 1) via
        # expand_contractions + the lemmatizer.
        pg = self.lex.phrase_grade("걸려서")
        self.assertEqual(pg.grade, 1)

    def test_proper_noun_excluded_from_grading_and_unknown(self):
        wg = self.lex.word_grade("현우")
        self.assertEqual((wg.grade, wg.source), (None, "proper_noun"))
        pg = self.lex.phrase_grade("현우가 공부해요")
        self.assertNotIn("현우가", pg.unknown)


class TestGrammarIndexTableDriven(unittest.TestCase):
    """The 10 required patterns, each with a positive and a negative
    sentence, compiled from grammar_rows shaped exactly like
    assets/data/grammar.csv (id, level, pattern)."""

    PATTERNS = [
        ("gr_geot_gatda", "B1", "V-(으)ㄹ 것 같다", 3,
         "저 아이가 사과를 다 먹을 것 같다.", "저는 사과를 먹었다."),
        ("gr_pyeonida", "B1", "A/V-(으)ㄴ/는 편이다", 3,
         "그는 운동을 매일 하는 편이다.", "그는 운동을 매일 한다."),
        ("gr_bulguhago", "B2", "N에도 불구하고", 4,
         "그는 실패에도 불구하고 다시 도전했다.", "그는 실패해서 포기했다."),
        ("gr_daeyo", "B2", "-대요/-(이)래요/-냬요/-재요", 4,
         "친구가 요즘 바쁘대요.", "친구가 요즘 바빠요."),
        ("gr_go_sipda", "A1", "V-고 싶다", 1,
         "저는 여행을 가고 싶다.", "저는 여행을 갔다."),
        ("gr_seyo", "A1", "V-(으)세요", 1,
         "여기 앉으세요.", "여기 앉았어요."),
        ("gr_eun_neun", "A1", "N은/는", 1,
         "저는 학생이에요.", "이것이 좋아요."),
        ("gr_a_eo_boda", "A2", "V-아/어 보다", 2,
         "이 옷을 한번 입어 보다.", "이 옷을 입었어요."),
        ("gr_gi_ttaemune", "A2", "V-기 때문에", 2,
         "비가 오기 때문에 우산을 가져왔다.", "비가 와서 좋다."),
        ("gr_jeogi_itda", "B1", "V-(으)ㄴ 적이 있다/없다", 3,
         "저는 그 음식을 먹은 적이 있다.", "저는 그 음식을 안 먹어요."),
    ]

    @classmethod
    def setUpClass(cls):
        grammar_rows = [
            {"id": pid, "level": level, "pattern": pattern}
            for pid, level, pattern, _grade, _pos, _neg in cls.PATTERNS
        ]
        cls.index = cl.GrammarIndex.build(grammar_rows, [])

    def test_each_pattern_hits_positive_and_spares_negative(self):
        for pid, _level, pattern, grade, positive, negative in self.PATTERNS:
            with self.subTest(pattern=pattern):
                pos_hits = [h for h in self.index.detect(positive) if h.pattern_id == pid]
                neg_hits = [h for h in self.index.detect(negative) if h.pattern_id == pid]
                self.assertTrue(pos_hits, "%r did not match its positive sentence" % (pattern,))
                self.assertEqual(pos_hits[0].grade, grade)
                self.assertFalse(
                    neg_hits, "%r incorrectly matched its negative sentence" % (pattern,)
                )

    def test_compile_pattern_regex_topic_particle(self):
        regex = cl.compile_pattern_regex("N은/는")
        self.assertTrue(regex.search("저는 학생이에요."))
        self.assertIsNone(regex.search("이것이 좋아요."))

    def test_compile_pattern_regex_drops_trailing_da_for_known_predicate(self):
        regex = cl.compile_pattern_regex("V-고 싶다")
        self.assertTrue(regex.search("가고 싶어요"))  # conjugated, not bare form

    def test_compile_pattern_regex_keeps_non_predicate_trailing_da(self):
        # An allomorph ending in a bare "다" that is NOT a real predicate
        # lemma must not be reduced to a single character -- that would
        # match almost anything.
        regex = cl.compile_pattern_regex("-어다", strip_slot_prefix=False)
        self.assertEqual(regex.pattern, "어다")


class TestR3GrammarOverMatching(unittest.TestCase):
    """R3 item 6: the eojeol-boundary check, overlap dedup (lowest grade
    wins), and the literal-core-length/grade gate, against a small
    hand-built index that reproduces the real over-matching bug (two NIKL
    rows tagging the SAME bare 2-syllable literal at different grades)."""

    @classmethod
    def setUpClass(cls):
        nikl_rows = [
            # Mirrors the real '다고' duplication: same literal core,
            # grade 3 (연결어미, legitimate) vs grade 6 (연결어미, also
            # tagged on the identical 2-syllable literal).
            {"grade": "3", "category": "연결어미", "form": "-는다고1",
             "variants": "-다고1", "meaning": "이유"},
            {"grade": "6", "category": "연결어미", "form": "-는다고1",
             "variants": "-다고1", "meaning": "의도"},
            # A grade-2 "어 있다" (multi-syllable, survives the length
            # gate) duplicated by a bogus higher-grade "어 있다"-alike --
            # overlap dedup must keep the lower one.
            {"grade": "2", "category": "표현", "form": "-어 있다", "variants": ""},
            {"grade": "4", "category": "표현", "form": "-어 있다", "variants": ""},
        ]
        cls.index = cl.GrammarIndex.build([], nikl_rows)

    def test_short_grade3_literal_core_is_not_built(self):
        # '다고' is exactly 2 Hangul syllables; grade 3 is outside
        # _SHORT_FRAGMENT_ALLOWED_GRADES ({1, 2}), so NEITHER the grade-3
        # nor the grade-6 row for it should ever produce a hit.
        hits = self.index.detect("그가 온다고 말했다")
        self.assertFalse(hits, "expected no hits for a >2-grade short literal core: %r" % (hits,))

    def test_overlap_dedup_keeps_lowest_grade(self):
        # detect() takes literal text (callers -- sentence_profile()
        # included -- run expand_contractions first); use the already-open
        # form directly so this test isolates dedup, not the fusion
        # expander.
        hits = self.index.detect("문이 열리어 있다")
        grades = sorted({h.grade for h in hits})
        self.assertEqual(grades, [2], "expected only the grade-2 hit to survive overlap dedup: %r" % (hits,))

    def test_grammar_max_derived_from_grammar_hits(self):
        hits = self.index.detect("문이 열리어 있다")
        self.assertEqual(max(h.grade for h in hits), 2)


class TestRealLexiconGoldenCases(unittest.TestCase):
    """Golden cases from the brief, against the real T1.1 lexicon CSVs and
    the real assets/data/grammar.csv."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()
        cls.grammar = cl.GrammarIndex.load()

    def test_word_grade_gongbuhada_derived(self):
        wg = self.lex.word_grade("공부하다")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (1, "A1", "derived"))

    def test_word_grade_haendeupon_alias(self):
        wg = self.lex.word_grade("핸드폰")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (2, "A2", "alias"))

    def test_word_grade_unknown_nonsense(self):
        wg = self.lex.word_grade("가나다라마바")
        self.assertIsNone(wg.grade)

    def test_word_grade_ssada_takes_minimum_homograph(self):
        # R3 item 1, real data: 싸다 has kiiq homographs at grade 1 ("가격이
        # 싸다", cheap), 2, 3, and homograph 0 at grade 5 ("입이 싸다") --
        # must resolve to the minimum (1), not the homograph-0 row (5).
        wg = self.lex.word_grade("싸다")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (1, "A1", "kiiq"))

    def test_cheunggan_soeum_is_unknown_not_a_fabricated_grade_3(self):
        """The compound is absent from both remaining lexicon CSVs (kiiq/
        basic2023) -- confirmed by exact and substring search over every
        headword in each file. Its parts don't combine to grade 3 either
        (one part is basic2023 grade 5 -> C2; the other is kiiq grade 4 ->
        B2 -- see the T1.2 report evidence). This test locks in the real,
        honest 'unknown' result so a future change can't silently paper
        over the gap with an invented lexicon row; the fix (alias vs.
        accepting the gap) is Fable's ruling to make, per aliases.csv's
        own README."""
        wg = self.lex.word_grade("층간소음")  # 층간소음
        self.assertIsNone(
            wg.grade,
            "if this now resolves, a lexicon/alias change made it so -- "
            "confirm it was a deliberate, reviewed addition",
        )

    def test_phrase_grade_annyeonghaseyo(self):
        pg = self.lex.phrase_grade("안녕하세요")
        self.assertEqual(pg.grade, 1)
        self.assertEqual(pg.cefr, "A1")

    def test_phrase_grade_jeopgeunseong_hwakbohada_takes_max(self):
        pg = self.lex.phrase_grade("접근성을 확보하다")
        known = [w.grade for w in pg.words if w.grade is not None]
        self.assertEqual(pg.grade, max(known))
        self.assertIn("접근성을", pg.unknown)

    def test_sentence_profile_jeoneun_haksaengieyo(self):
        sp = self.lex.sentence_profile("저는 학생이에요.", self.grammar)
        self.assertEqual(sp.eojeol_count, 2)
        self.assertEqual(sp.grammar_max, 1)
        self.assertEqual(sp.level_estimate, "A1")

    def test_sentence_profile_gamgie_geollyeoseo(self):
        sentence = "감기에 걸려서 축제에 못 갔어요."
        sp = self.lex.sentence_profile(sentence, self.grammar)
        eoseo_hits = [h for h in sp.grammar_hits if "어서" in h.text and h.grade == 1]
        self.assertTrue(eoseo_hits, "expected a grade-1 (kiiq) hit for -eoseo")
        self.assertNotIn("못", [u.rstrip(".") for u in sp.unknown])
        self.assertIn(sp.level_estimate, ("A1", "A2"))

    def test_grammar_index_detects_eo_itda_grade_2(self):
        text = "관리비에 인터넷 요금도 포함되어 있나요?"
        hits = self.grammar.detect(cl.expand_contractions(text))
        matches = [h for h in hits if "있" in h.text and h.grade == 2]
        self.assertTrue(matches, "expected a grade-2 -eo itda hit, got %r" % (hits,))

    def test_no_kcenter_source_in_real_data(self):
        # R3 item 3.
        self.assertFalse(cl.LEXICON_DIR.joinpath("nikl_kcenter_vocab_bands.csv").exists())
        self.assertFalse(hasattr(cl, "KCENTER_CSV"))
        self.assertFalse(hasattr(cl, "KCENTER_BAND_TO_GRADE"))


class TestR3TokenizerGoldenCases(unittest.TestCase):
    """R3 item 4: every inflected/irregular-conjugation form named in the
    rejection brief must resolve to its correct dictionary headword. Each
    case is a (surface form, expected dictionary form) pair; the assertion
    is on `_resolve_eojeol(...).matched` (the lemma the tokenizer landed
    on) so a wrong-but-still-grade-resolving lemma is still caught."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()

    CASES = [
        ("드렸어요.", "드리다"),
        ("처음에는", "처음"),
        ("받으셨어요", "받다"),
        ("앉으시는", "앉다"),
        ("앉으니", "앉다"),
        ("따뜻해서", "따뜻하다"),
        ("서늘해서", "서늘하다"),
        ("자리예요.", "자리"),
        ("된다고", "되다"),
        ("오라고", "오다"),
        ("과한", "과하다"),
        ("아팠어요", "아프다"),
        ("갔어요", "가다"),
        ("왔어요", "오다"),
        ("봤어요", "보다"),
        ("줬어요", "주다"),
        ("했어요", "하다"),
        ("먹었어요", "먹다"),
        ("추워요", "춥다"),
        ("더워서", "덥다"),
        ("고마워요", "고맙다"),
        ("들어요", "듣다"),
        ("몰라요", "모르다"),
        ("나아요", "낫다"),
        ("노란", "노랗다"),
    ]

    def test_all_golden_tokenizer_cases(self):
        for surface, expected in self.CASES:
            with self.subTest(surface=surface):
                wg = self.lex._resolve_eojeol(cl._normalize_token(surface))
                self.assertEqual(
                    wg.matched, expected,
                    "%r resolved to %r, expected %r (grade=%r source=%r)"
                    % (surface, wg.matched, expected, wg.grade, wg.source),
                )
                self.assertIsNotNone(
                    wg.grade, "%r -> %r resolved but has no grade" % (surface, wg.matched)
                )


class TestR3ConfidenceAndProperNouns(unittest.TestCase):
    """R3 items 2 and 5 against the real lexicon + character_profiles.json."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()
        cls.grammar = cl.GrammarIndex.load()

    def test_low_confidence_capped_at_grade_3_for_lexical_p90_but_not_word_grade(self):
        sentence = "장모님께 과일을 드렸어요."
        sp = self.lex.sentence_profile(sentence, self.grammar)
        # Word-level lookup keeps the raw (uncapped) basic2023 grade.
        wg = self.lex.word_grade("장모님")
        self.assertEqual(wg.grade, 6)
        self.assertEqual(wg.confidence, "low")
        # Sentence-level: flagged as low-confidence, and the sentence must
        # NOT be dragged to C2 by that single fallback-graded word.
        self.assertIn("장모님께", sp.low_confidence)
        self.assertNotEqual(sp.level_estimate, "C2")

    def test_character_names_loaded_from_profiles_json(self):
        names = cl.load_character_names()
        for extra in cl.EXTRA_PROPER_NOUNS:
            self.assertIn(extra, names)
        # At least one name must come from character_profiles.json itself
        # (i.e. the file is actually read, not just the fixed extra list).
        self.assertGreater(len(names), len(cl.EXTRA_PROPER_NOUNS))

    def test_proper_noun_with_particle_excluded_from_sentence_unknown_and_grading(self):
        sp = self.lex.sentence_profile("현우가 과한 선물을 받았어요.", self.grammar)
        self.assertIn("현우", sp.proper_nouns)
        self.assertNotIn("현우가", sp.unknown)


class TestVocabUnknownRatio(unittest.TestCase):
    """Measures word_grade() unknown-ratio over all 2,420 live headwords
    (Section 6/T1.2 R3 target: <= 10%, tightened from the original 25%)."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()
        with cl.VOCAB_CSV.open(encoding="utf-8", newline="") as fh:
            cls.rows = list(csv.DictReader(fh))

    def test_unknown_ratio_at_most_10_percent(self):
        unknown = [
            row["korean"] for row in self.rows
            if self.lex.word_grade(row["korean"]).grade is None
        ]
        ratio = len(unknown) / len(self.rows)
        top = Counter(unknown).most_common()
        top.sort(key=lambda pair: (-pair[1], pair[0]))
        print("\n[vocab unknown ratio] %d/%d = %.4f" % (len(unknown), len(self.rows), ratio))
        print("[top 30 unknown headwords]")
        for word, count in top[:30]:
            print("  %s x%d" % (word, count))
        self.assertLessEqual(ratio, 0.10)
        self.assertEqual(len(self.rows), 2420)


class TestSentenceUnknownRatio(unittest.TestCase):
    """Section 6/T1.2 R3 target: sentence unknown-TOKEN ratio over every
    cloze.json fullKo sentence <= 12% (eojeol-level, not headword-level --
    a sentence contributes one denominator entry per eojeol)."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()
        cls.grammar = cl.GrammarIndex.load()
        cloze_path = cl.REPO / "assets" / "data" / "cloze.json"
        with cloze_path.open(encoding="utf-8") as fh:
            data = json.load(fh)
        cls.sentences = [item["fullKo"] for item in data["items"] if item.get("fullKo")]

    def test_sentence_unknown_token_ratio_at_most_12_percent(self):
        total_tokens = 0
        total_unknown = 0
        unknown_counter: Counter = Counter()
        for sentence in self.sentences:
            sp = self.lex.sentence_profile(sentence, self.grammar)
            total_tokens += sp.eojeol_count
            total_unknown += len(sp.unknown)
            unknown_counter.update(sp.unknown)
        ratio = total_unknown / total_tokens if total_tokens else 0.0
        print(
            "\n[sentence unknown-token ratio] %d/%d = %.4f over %d sentences"
            % (total_unknown, total_tokens, ratio, len(self.sentences))
        )
        print("[top 30 unknown tokens]")
        for token, count in unknown_counter.most_common(30):
            print("  %s x%d" % (token, count))
        self.assertLessEqual(ratio, 0.12)
        self.assertGreater(len(self.sentences), 0)


if __name__ == "__main__":
    unittest.main()
