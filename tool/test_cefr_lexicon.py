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
cases -- see `TestRealLexiconGoldenCases.test_cheunggan_soeum_now_resolves_via_r7_item8_compound_split`
below and the module docstring of `tool/cefr_lexicon.py`: 층간소음
("layer-noise") is not a headword in either remaining NIKL source list as
a WHOLE word (verified directly against both CSVs -- see the grep
evidence in the T1.2 report to Fable), so under R3 `word_grade()` on it
resolved to `unknown`, not the `(3, 'B1', 'kiiq')` an earlier brief draft
assumed. R7 item 8's generic compound split (added in this rework) now
resolves it via its two independently-real parts instead -- still not the
fabricated grade 3, but no longer a bare unknown either; see that test's
own docstring for the current grade.

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

    def test_unspaced_compound_of_two_known_parts_now_resolves_via_compound_split(self):
        # R7 item 8 SUPERSEDES the old R3-era behaviour this test used to
        # lock in (word_grade("층간소음") returning unknown): the multiword
        # step is still space-separated-only, but the NEW generic 2-way
        # compound split (word_grade's last-resort tier) now explicitly
        # handles exactly this "two real headwords concatenated with no
        # space" shape. 층간 (basic2023 grade 5 -> C2/6) + 소음 (basic2023
        # grade 1 -> A2/2) -> max is 6/C2, source='compound',
        # confidence='medium' (two independently-correct parts don't
        # guarantee the compound's actual meaning).
        wg = self.lex.word_grade("층간소음")
        self.assertEqual((wg.grade, wg.cefr, wg.source, wg.confidence), (6, "C2", "compound", "medium"))
        self.assertEqual(wg.matched, "층간+소음")

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

    def test_cheunggan_soeum_now_resolves_via_r7_item8_compound_split(self):
        """SUPERSEDES the R3-era 'stays unknown' lock this test used to
        assert (see the module docstring's 'Known gap' section, written
        when this was flagged for Fable's ruling: alias vs. accepted
        gap). R7 item 8's generic compound split is Fable's ruling on
        that exact question -- 층간소음 is absent from both lexicon CSVs
        as a WHOLE word, but its two parts (층간: basic2023 grade 5 ->
        C2/6; 소음: kiiq grade 4 -> B2/4 in the real data, confirmed
        below) now combine automatically via the split, taking their max
        (6/C2), source='compound', confidence='medium' -- not a
        fabricated grade 3, and not silently invented lexicon data: it is
        the documented, deliberate output of a general, tested mechanism
        applied to two REAL, independently-verified headwords."""
        wg = self.lex.word_grade("층간소음")
        self.assertEqual(wg.matched, "층간+소음")
        self.assertEqual(wg.source, "compound")
        self.assertEqual(wg.confidence, "medium")
        cheunggan = self.lex.word_grade("층간")
        soeum = self.lex.word_grade("소음")
        self.assertEqual(wg.grade, max(cheunggan.grade, soeum.grade))

    def test_phrase_grade_annyeonghaseyo(self):
        pg = self.lex.phrase_grade("안녕하세요")
        self.assertEqual(pg.grade, 1)
        self.assertEqual(pg.cefr, "A1")

    def test_phrase_grade_jeopgeunseong_hwakbohada_takes_max(self):
        pg = self.lex.phrase_grade("접근성을 확보하다")
        known = [w.grade for w in pg.words if w.grade is not None]
        self.assertEqual(pg.grade, max(known))
        # R7 item 8 SUPERSEDES this test's old "접근성을 stays unknown"
        # assertion: 접근성 (a real compound noun, "accessibility") now
        # resolves via the generic compound split instead of falling
        # through -- a strict improvement (fewer unknowns), not a bug.
        self.assertNotIn("접근성을", pg.unknown)
        self.assertEqual(pg.unknown, ())

    def test_sentence_profile_jeoneun_haksaengieyo(self):
        sp = self.lex.sentence_profile("저는 학생이에요.", self.grammar)
        self.assertEqual(sp.eojeol_count, 2)
        self.assertEqual(sp.grammar_max, 1)
        self.assertEqual(sp.level_estimate, "A1")

    def test_sentence_allowance_excuses_one_high_grade_content_word(self):
        # Bible §B "1급 밖 단어는 문화어·고유명사 하나까지만 허용" / §D "문화어
        # 1개 예외": 5 known tokens (>=3), 순하다 is the one outlier -- with
        # it excused from the percentile the sentence reads at A1/A2, not
        # wherever 순하다's own B2 grade would otherwise drag it.
        sp = self.lex.sentence_profile("조금 매워요. 순한 맛도 있어요.", self.grammar)
        self.assertGreaterEqual(len([t for t in sp.tokens if t.grade is not None]), 3)
        self.assertEqual(sp.allowance, ("순하다", 4))
        self.assertIn(sp.level_estimate, ("A1", "A2"))
        self.assertLessEqual(cl.CEFR_TO_GRADE[sp.level_estimate], cl.CEFR_TO_GRADE["A2"])
        # grammar_max/word grading are untouched by the allowance.
        self.assertEqual(self.lex.word_grade("순하다").grade, 4)

    def test_sentence_allowance_needs_at_least_three_graded_tokens(self):
        # "저는 학생이에요." above has exactly 2 known tokens (저, 학생) --
        # too short for the allowance to apply at all.
        sp = self.lex.sentence_profile("저는 학생이에요.", self.grammar)
        self.assertEqual(len([t for t in sp.tokens if t.grade is not None]), 2)
        self.assertIsNone(sp.allowance)

    def test_geollo_contraction_fully_graded(self) -> None:
        # 걸로 (것으로's contraction) used to resolve via a wrong basic2023
        # sense at B2 -- PRONOUN_CONTRACTION_MAP redirects it to 것 (A1).
        sp = self.lex.sentence_profile("안 매운 걸로 주세요.", self.grammar)
        self.assertEqual(sp.unknown, ())
        self.assertEqual(self.lex.word_grade("걸로").grade, 1)

    def test_ige_mwo_contraction_fully_graded(self) -> None:
        # 이게 (이것이's contraction) used to resolve via 이다 at C2; 뭐 is
        # already A1 on its own. Both PRONOUN_CONTRACTION_MAP redirects.
        sp = self.lex.sentence_profile("이게 뭐예요?", self.grammar)
        self.assertEqual(sp.unknown, ())
        self.assertEqual(self.lex.word_grade("이게").grade, 1)

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
        # T2.5 SUPERSEDES this test's original 장모님 example: 장모님 was
        # this module's own motivating case for basic2023's skewed-high
        # grade-5 tail (see the module docstring's R3 item 2 note), and
        # level_exceptions.csv now deliberately caps it at A1/'exception'
        # (see test_word_grade_confidence_is_high_for_exception below) --
        # so it can no longer demonstrate "low-confidence, uncapped
        # word_grade" at all. 가공품 (basic2023 grade 5, NOT kiiq, NOT a
        # level_exceptions.csv headword) replaces it as an unaffected real
        # example of the same underlying mechanism.
        sentence = "시장에서 가공품을 샀어요."
        sp = self.lex.sentence_profile(sentence, self.grammar)
        # Word-level lookup keeps the raw (uncapped) basic2023 grade.
        wg = self.lex.word_grade("가공품")
        self.assertEqual(wg.grade, 6)
        self.assertEqual(wg.confidence, "low")
        # Sentence-level: flagged as low-confidence, and the sentence must
        # NOT be dragged to C2 by that single fallback-graded word.
        self.assertIn("가공품을", sp.low_confidence)
        self.assertNotEqual(sp.level_estimate, "C2")

    def test_word_grade_confidence_is_high_for_exception(self):
        # T2.5: 장모님's own basic2023 grade WAS 6/low (see the test just
        # above) -- level_exceptions.csv's kinship-category ruling now
        # caps it at A1 with 'high' confidence (a deliberate Fable ruling
        # outranks an uncertain general-literacy fallback grade).
        wg = self.lex.word_grade("장모님")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (1, "A1", "exception"))
        self.assertEqual(wg.confidence, "high")

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


class TestR7WordGradeLemmaFallback(unittest.TestCase):
    """R7 item 1: word_grade() called DIRECTLY on a bare (possibly
    inflected/honorific) headword string -- as the vocab-list audit does,
    unlike phrase_grade/sentence_profile which already lemmatize every
    eojeol via _resolve_eojeol -- must now also try the lemma-candidate
    fallback before giving up. Each case asserts both the resolved lemma
    (`matched`) and the grade, against the real lexicon CSVs."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()

    CASES = [
        ("고마워요", "고맙다", 1, "A1"),
        ("괜찮아요", "괜찮다", 1, "A1"),
        ("같은", "같다", 1, "A1"),
        ("늦게", "늦다(h1,h2)", 1, "A1"),
        ("감사합니다", "감사", 1, "A1"),
        ("안녕하세요", "안녕", 1, "A1"),
        ("죄송합니다", "죄송하다", 1, "A1"),
        ("미안해요", "미안", 1, "A1"),
        ("좋아요", "좋다", 1, "A1"),
    ]

    def test_all_golden_bare_headword_cases(self):
        for surface, expected_matched, expected_grade, expected_cefr in self.CASES:
            with self.subTest(surface=surface):
                wg = self.lex.word_grade(surface)
                self.assertEqual(
                    (wg.matched, wg.grade, wg.cefr),
                    (expected_matched, expected_grade, expected_cefr),
                    "word_grade(%r) = %r" % (surface, wg),
                )

    def test_lemma_fallback_does_not_infinite_recurse_on_unresolvable_word(self):
        # A word that resolves nowhere (no candidate, including the
        # identity candidate, ever succeeds) must terminate cleanly.
        wg = self.lex.word_grade("가나다라마바")
        self.assertIsNone(wg.grade)


class TestR7DerivedBasic2023MinReal(unittest.TestCase):
    """R7 item 2, real data: 사양하다 (Fable's flagged wrong-sense case --
    the kiiq root 사양 only carries the grade-6 "specification" (仕樣)
    sense, unrelated to 사양하다's actual "decline/refuse politely"
    meaning). basic2023 DOES have the full form 사양하다 at a much lower
    grade; crossing the two must pull the reported grade down and mark it
    no longer fully trusted."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()

    def test_sayanghada_grade_capped_and_not_high_confidence(self):
        wg = self.lex.word_grade("사양하다")
        self.assertLessEqual(wg.grade, 4, "word_grade(사양하다) = %r" % (wg,))
        self.assertNotEqual(wg.confidence, "high", "word_grade(사양하다) = %r" % (wg,))
        self.assertEqual(wg.source, "derived")


class TestR7DerivedBasic2023MinSynthetic(unittest.TestCase):
    """R7 item 2, synthetic: pin down the exact 'medium' vs 'high'
    boundary (disagreement >=2 grades, OR an ambiguous/multi-homograph
    root) against a tiny controlled fixture, independent of real-CSV
    noise."""

    @classmethod
    def setUpClass(cls):
        kiiq_rows = [
            # Root with a single row, close to its basic2023 full-form
            # grade (diff 1, < 2) -> stays 'high'.
            _kiiq_row(2, "안정"),
            # Root with a single row, far from its basic2023 full-form
            # grade (diff 3, >= 2) -> 'medium'.
            _kiiq_row(5, "왜곡"),
            # Root with TWO rows (ambiguous), even though its (minimum)
            # grade agrees exactly with basic2023 -> still 'medium'.
            _kiiq_row(2, "혼동", homograph=1),
            _kiiq_row(4, "혼동", homograph=2),
        ]
        basic_rows = [
            _basic_row(2, "안정하다"),  # basic2023 grade2 -> CEFR B1 -> grade3
            _basic_row(2, "왜곡하다"),  # basic2023 grade2 -> CEFR B1 -> grade3
            _basic_row(1, "혼동하다"),  # basic2023 grade1 -> CEFR A2 -> grade2
        ]
        cls.lex = cl.CefrLexicon.from_rows(kiiq_rows, basic_rows, [])

    def test_small_disagreement_unambiguous_root_stays_high(self):
        wg = self.lex.word_grade("안정하다")
        self.assertEqual((wg.grade, wg.source, wg.confidence, wg.matched), (2, "derived", "high", "안정"))

    def test_large_disagreement_becomes_medium_and_takes_min(self):
        wg = self.lex.word_grade("왜곡하다")
        # kiiq root grade 5, basic2023-mapped grade 3 -> min is 3.
        self.assertEqual((wg.grade, wg.source, wg.confidence, wg.matched), (3, "derived", "medium", "왜곡"))

    def test_ambiguous_root_becomes_medium_even_when_grades_agree(self):
        wg = self.lex.word_grade("혼동하다")
        # kiiq root minimum grade 2, basic2023-mapped grade 2 -> min is 2,
        # but the root has 2 kiiq rows -> 'medium' regardless.
        self.assertEqual((wg.grade, wg.source, wg.confidence, wg.matched), (2, "derived", "medium", "혼동"))

    def test_medium_confidence_capped_at_4_in_lexical_p90(self):
        # Both sides agree at grade 6 (min is a no-op, still 6) but the
        # root is ambiguous (2 rows) -> 'medium' -- and 6 > 4, so this is
        # the case that actually exercises the p90 cap (unlike the two
        # tests above, whose min() already lands <=4 on its own).
        grammar = cl.GrammarIndex(())
        lex2 = cl.CefrLexicon.from_rows(
            [_kiiq_row(6, "과시", homograph=1), _kiiq_row(6, "과시", homograph=2)],
            [_basic_row(5, "과시하다")],  # basic2023 grade5 -> CEFR C2 -> grade6
            [],
        )
        wg = lex2.word_grade("과시하다")
        self.assertEqual((wg.grade, wg.confidence), (6, "medium"))
        sp = lex2.sentence_profile("과시하다", grammar)
        self.assertEqual(sp.lexical_p90, 4.0)


class TestR7VowelContractionGoldenCases(unittest.TestCase):
    """R7 item 3: generic jamo-arithmetic past-tense vowel-fusion repair
    (`_unfuse_tensed_vowel`), covering ㅕ->ㅣ, ㅝ->ㅜ, ㅘ->ㅗ, ㅙ/ㅚ->ㅚ and
    the ㅐ-stays case, without adding a hand-table entry per verb."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()

    CASES = [
        ("멈췄어요", "멈추다"),  # ㅝ -> ㅜ
        ("나눴어요", "나누다"),  # ㅝ -> ㅜ
        ("세웠어요", "세우다"),  # ㅝ -> ㅜ
        ("냈어요", "내다"),      # ㅐ stays
        ("다녔어요", "다니다"),  # ㅕ -> ㅣ
        ("마셨어요", "마시다"),  # ㅕ -> ㅣ
        ("기다렸어요", "기다리다"),  # ㅕ -> ㅣ
        ("배웠어요", "배우다"),  # ㅝ -> ㅜ
    ]

    def test_all_golden_vowel_contraction_cases(self):
        for surface, expected in self.CASES:
            with self.subTest(surface=surface):
                wg = self.lex._resolve_eojeol(cl._normalize_token(surface))
                self.assertEqual(wg.matched, expected, "%r -> %r" % (surface, wg))
                self.assertIsNotNone(wg.grade)

    def test_unfuse_tensed_vowel_directly(self):
        # Jamo-arithmetic unit checks, independent of lexicon coverage.
        self.assertEqual(cl._unfuse_tensed_vowel("췄"), "추")   # ㅝ -> ㅜ
        self.assertEqual(cl._unfuse_tensed_vowel("왔"), "오")   # ㅘ -> ㅗ (already CONTRACTION_MAP too)
        self.assertEqual(cl._unfuse_tensed_vowel("됐"), "되")   # ㅙ -> ㅚ
        self.assertEqual(cl._unfuse_tensed_vowel("냈"), "내")   # ㅐ stays
        self.assertEqual(cl._unfuse_tensed_vowel("렸"), "리")   # ㅕ -> ㅣ
        self.assertIsNone(cl._unfuse_tensed_vowel("받"))        # no ㅆ batchim -> None
        self.assertIsNone(cl._unfuse_tensed_vowel(""))


class TestR7RieulAndBieupIrregularGoldenCases(unittest.TestCase):
    """R7 item 4: ㄹ-stem attributive/present-tense forms (만든/만들어요/
    아는/사는) and ㅂ-irregular attributives (새로운/어려운/즐거운/더운/
    가까운). Includes a regression lock for the collision this item's
    implementation had to be guarded against (가는 must stay 가다, not
    misresolve to 갈다 or 가늘다 -- see _rieul_stem_attributive_repair's
    and RIEUL_NEUN_MAP's docstrings)."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()

    CASES = [
        ("만든", "만들다"),
        ("만들어요", "만들다"),
        ("아는", "알다"),
        ("사는", "살다"),
        ("새로운", "새롭다"),
        ("어려운", "어렵다"),
        ("즐거운", "즐겁다"),
        ("더운", "덥다"),
        ("가까운", "가깝다"),
    ]

    def test_all_golden_rieul_bieup_cases(self):
        for surface, expected in self.CASES:
            with self.subTest(surface=surface):
                wg = self.lex._resolve_eojeol(cl._normalize_token(surface))
                self.assertEqual(wg.matched, expected, "%r -> %r" % (surface, wg))
                self.assertIsNotNone(wg.grade)

    def test_ganeun_stays_gada_not_hijacked_by_rieul_swap(self):
        # 가다's extremely common attributive "가는" (cloze.json has
        # several) must NOT resolve to 갈다 ("to replace/grind") or
        # 가늘다 ("thin") just because their jamo shape coincides.
        wg = self.lex._resolve_eojeol(cl._normalize_token("가는"))
        self.assertEqual(wg.matched, "가다")

    def test_deun_still_resolves_to_deutda_not_shadowed_by_the_new_fallback(self):
        # The new "already-ㄹ-final-stem" fallback candidate added for
        # 만들어요 must not push 듣다 (the correct ㄷ-irregular reading of
        # the bare 1-syllable stem "들") out of first place.
        wg = self.lex._resolve_eojeol(cl._normalize_token("들어요"))
        self.assertEqual(wg.matched, "듣다")

    def test_ordinary_batchim_nieun_nouns_are_not_hijacked(self):
        for noun in ("돈", "문"):
            with self.subTest(noun=noun):
                wg = self.lex._resolve_eojeol(cl._normalize_token(noun))
                self.assertEqual(wg.matched, noun)


class TestR7NewEndingsGoldenCases(unittest.TestCase):
    """R7 item 5: the new batch of connective/final endings (도록, 길래,
    자, 자마자, (으)ㄹ지, (으)ㄹ게요, (으)시기, 나요, 어때요-style ㅎ-irregular
    fusion, …), including the embedded-ㄹ-batchim "-(으)ㄹX" family that a
    plain string suffix check can never match (see
    _rieul_fused_ending_repair's docstring) and its 1-syllable collision
    guard (RIEUL_FUSED_STRIP_PREFERRED_1SYL)."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()

    CASES = [
        ("묻길래", "묻다"),
        ("하시길래", "하다"),
        ("않도록", "않다"),
        ("주시기", "주다"),
        ("둘지", "두다"),
        ("갈게요", "가다"),
        ("묻자", "묻다"),
        ("있나요?", "있다"),
        ("어때요?", "어떻다"),
        ("줄어들어요", "줄어들다"),  # confirmed a real kiiq headword (grade 4)
    ]

    def test_all_golden_new_ending_cases(self):
        for surface, expected in self.CASES:
            with self.subTest(surface=surface):
                wg = self.lex._resolve_eojeol(cl._normalize_token(surface))
                self.assertEqual(wg.matched, expected, "%r -> %r" % (surface, wg))
                self.assertIsNotNone(wg.grade)

    def test_rieul_fused_ending_does_not_hijack_malda_or_salda(self):
        # 말다/살다's own "-지" forms must stay correct (via the ordinary,
        # pre-existing mechanism), not get shadowed by a wrong "마다"/
        # "사다" guess from the new embedded-batchim repair.
        for surface, expected in (("말지", "말다"), ("살지", "살다")):
            with self.subTest(surface=surface):
                wg = self.lex._resolve_eojeol(cl._normalize_token(surface))
                self.assertEqual(wg.matched, expected)

    def test_ramyeon_noun_not_treated_as_the_ramyeon_conditional_ending(self):
        # "라면" (ramen, a bare headword) must not be stripped as the new
        # "-라면" (if/when) connective ending -- the ending requires a
        # strictly non-empty remaining stem.
        wg = self.lex.word_grade("라면")
        self.assertEqual(wg.matched, "라면")
        self.assertEqual(wg.source, "kiiq")

    def test_meogeulji_consonant_stem_still_works(self):
        wg = self.lex._resolve_eojeol(cl._normalize_token("먹을지"))
        self.assertEqual(wg.matched, "먹다")


class TestR7ParticleStackAndPluralGoldenCases(unittest.TestCase):
    """R7 item 6: plural 들 and stacked particles (에만/에서만/…). "사람들이"
    resolves through TWO strips (이, then 들) -- the first (이) happens in
    `_resolve_eojeol`'s own candidate loop, landing on the intermediate
    candidate "사람들"; the second (들) happens INSIDE that candidate's own
    `word_grade("사람들")` call, via the R7 item 1 lemma-fallback tier,
    landing on "사람" (verified: "사람들" is NOT itself a kiiq headword).
    `_resolve_eojeol` deliberately reports the shallower candidate it
    tried ("사람들"), not the deeper match reached inside it (see
    `_resolve_eojeol`'s own docstring/comment for why -- a pre-existing,
    separately-tested convention this item does not change), so the
    grade/CEFR outcome is what this test pins down, not the literal
    "사람" surface form the brief's prose names."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()

    def test_saramdeuli_resolves_grade_1_via_two_particle_strips(self):
        wg = self.lex._resolve_eojeol(cl._normalize_token("사람들이"))
        self.assertEqual(wg.matched, "사람들")
        self.assertEqual((wg.grade, wg.cefr), (1, "A1"))
        # The deeper match, reachable via word_grade() directly (R7 item 1):
        deep = self.lex.word_grade("사람들")
        self.assertEqual((deep.matched, deep.grade), ("사람", 1))

    def test_hanjjogeman_resolves_to_a_real_headword(self):
        # "한쪽" IS itself a direct kiiq headword (grade 3) -- the golden
        # accepts either 한쪽 or 쪽; this locks in which one this lexicon
        # actually produces.
        wg = self.lex._resolve_eojeol(cl._normalize_token("한쪽에만"))
        self.assertEqual(wg.matched, "한쪽")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (3, "B1", "kiiq"))

    def test_jibeseoman_resolves_to_jib(self):
        wg = self.lex._resolve_eojeol(cl._normalize_token("집에서만"))
        self.assertEqual(wg.matched, "집")
        self.assertEqual((wg.grade, wg.cefr), (1, "A1"))


class TestR7NumeralGoldenCases(unittest.TestCase):
    """R7 item 7: sino/native numerals -> grade 1, 'high' confidence;
    pure ASCII digits -> known-but-ungraded and excluded from `unknown`.
    Includes the two collision regressions found and fixed while
    implementing this: the numeral tier is checked AFTER kiiq/derived/
    alias in `word_grade` (네 "yes" must not be shadowed by native
    numeral 네 "four") and the sino character-class check requires >=2
    characters (사과 "apple" must not particle-strip its "과" down to the
    sino digit 사 "four" and get treated as a numeral -- though see this
    test class's last case: kiiq ITSELF already lists 사 as a 수사/
    관형사 headword, so this specific collision is a pre-existing,
    out-of-scope architectural property of particle-stripping in general,
    not something this item introduced or can fix within its own scope;
    flagged for Fable rather than silently patched)."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()
        cls.grammar = cl.GrammarIndex(())

    def test_sino_numeral_goldens_are_a1(self):
        for word in ("십오", "이십", "백오십", "삼십"):
            with self.subTest(word=word):
                wg = self.lex.word_grade(word)
                self.assertEqual((wg.grade, wg.cefr), (1, "A1"), "word_grade(%r) = %r" % (word, wg))
                self.assertEqual(wg.confidence, "high")

    def test_ascii_digits_are_not_unknown(self):
        for digit in ("3", "10"):
            with self.subTest(digit=digit):
                wg = self.lex.word_grade(digit)
                self.assertIsNone(wg.grade)
                self.assertEqual(wg.source, "number")
        sp = self.lex.sentence_profile("사탕 10 개를 샀어요.", self.grammar)
        self.assertNotIn("10", sp.unknown)

    def test_ne_yes_not_shadowed_by_native_numeral_ne_four(self):
        wg = self.lex._resolve_eojeol(cl._normalize_token("네"))
        self.assertEqual(wg.source, "kiiq")

    def test_sagwa_apple_resolves_exact_headword_not_the_particle_collision(self):
        # SUPERSEDES the pre-R8 "documents the current, pre-existing
        # behaviour" version of this test: R8 item 1 (EXACT-FIRST) now
        # tries the raw token itself as an exact lexicon headword before
        # any particle/ending stripping, so 사과 ("apple", a real kiiq
        # headword) no longer loses to the coincidental particle-stripped
        # reading 사 (수사 "four", from treating 사과's trailing 과 as the
        # comitative particle -- see TestR8ExactHeadwordFirstGoldenCases
        # for the full regression suite this fix needed).
        wg = self.lex._resolve_eojeol(cl._normalize_token("사과"))
        self.assertEqual(wg.matched, "사과")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (1, "A1", "kiiq"))


class TestR7CompoundPrefixNominaliserGoldenCases(unittest.TestCase):
    """R7 item 8: compound-noun 2-way split, the 불/비/미/재/무/초/최/신/구
    prefix table (+1 grade), and the -음/-ㅁ nominaliser. Also locks in
    the collision guard this item needed (word_grade's compound-fallback
    tier is skipped for any word ending in "다" -- see
    `_compound_fallback_chain`'s docstring): without it, byproduct
    candidates like "서늘다" (from "서늘해서"), "만듣다" (from
    D_IRREGULAR_MAP's own documented 들/걸 collision on "만들어요"), and
    "무다" (from an ordinary batchim-ㄴ noun repair on "문") started
    spuriously resolving via the new compound/prefix machinery, breaking
    real, previously-correct resolutions -- caught by this rework's own
    regression run before being fixed."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()

    # T2.5 SUPERSEDES this list's original inclusion of 교통카드: it is now
    # a level_exceptions.csv signage_a2 headword (capped A2/'exception'),
    # so it no longer demonstrates the generic compound-split path -- see
    # test_gyotongkadeu_now_resolves_via_t25_exception below instead.
    COMPOUND_CASES = [
        "신용카드", "신입사원", "유통기한", "조회수", "합의서",
    ]

    def test_compound_goldens_resolve_via_compound_split(self):
        for word in self.COMPOUND_CASES:
            with self.subTest(word=word):
                wg = self.lex.word_grade(word)
                self.assertIsNotNone(wg.grade, "word_grade(%r) = %r" % (word, wg))
                self.assertEqual(wg.source, "compound")
                self.assertEqual(wg.confidence, "medium")

    def test_gyotongkadeu_now_resolves_via_t25_exception(self):
        wg = self.lex.word_grade("교통카드")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (2, "A2", "exception"))

    def test_bulhwaksilseong_prefix_plus_one(self):
        # 불 + 확실성 -- bare 확실/확실성 are not headwords, but 확실하다 IS
        # (kiiq grade 4) -- resolves via the root+하다 fallback, +1 = 5.
        wg = self.lex.word_grade("불확실성")
        root = self.lex.word_grade("확실하다")
        self.assertEqual(wg.grade, min(root.grade + 1, 6))
        self.assertEqual(wg.source, "compound")

    def test_jaegeomto_prefix_plus_one(self):
        wg = self.lex.word_grade("재검토")
        root = self.lex.word_grade("검토")
        self.assertEqual(wg.grade, min(root.grade + 1, 6))
        self.assertEqual(wg.source, "compound")

    def test_dolbom_nominaliser_resolves_to_dolboda(self):
        wg = self.lex.word_grade("돌봄")
        self.assertEqual(wg.matched, "돌보다")
        self.assertIsNotNone(wg.grade)

    def test_compound_fallback_does_not_hijack_verb_candidates(self):
        # Regression lock for the collision found and fixed while
        # implementing this item -- see class docstring.
        cases = [
            ("문", "문", "kiiq"),
            ("서늘해서", "서늘하다", "kiiq"),
            ("만들어요", "만들다", "kiiq"),
        ]
        for surface, expected_matched, expected_source in cases:
            with self.subTest(surface=surface):
                wg = self.lex._resolve_eojeol(cl._normalize_token(surface))
                self.assertEqual(wg.matched, expected_matched)
                self.assertEqual(wg.source, expected_source)

    def test_compound_fallback_skips_words_ending_in_da(self):
        # Direct unit check of the guard itself, independent of any
        # particular collision example above.
        self.assertIsNone(self.lex._compound_fallback_chain("아무렇게나다").grade)


class TestR7AuxiliaryConstructionGoldenCases(unittest.TestCase):
    """R7 item 9: X-아/어 + auxiliary (보다/주다/지다/있다/놓다/두다/버리다/
    내다), and X-고 있다/싶다, grade the MAIN verb. The two-eojeol
    (space-separated) cases already worked correctly with NO new code --
    each eojeol lemmatizes independently -- verified and locked in here
    alongside the single-fused-token cases that needed the new
    _auxiliary_main_verb_repair/_auxiliary_tensed_repair mechanisms."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()
        cls.grammar = cl.GrammarIndex(())

    def test_ibeoboda_resolves_to_ipda_via_word_grade(self):
        # word_grade() called directly (as a vocab-headword audit would)
        # now fully reduces in one pass to the exact golden lemma.
        wg = self.lex.word_grade("입어보다")
        self.assertEqual((wg.matched, wg.grade, wg.cefr), ("입다", 1, "A1"))

    def test_ibeoboda_resolves_correctly_as_a_sentence_eojeol_too(self):
        wg = self.lex._resolve_eojeol(cl._normalize_token("입어보다"))
        self.assertEqual((wg.grade, wg.cefr), (1, "A1"))

    def test_pyeonhaejyeosseoyo_resolves_to_pyeonhada_via_word_grade(self):
        wg = self.lex.word_grade("편해졌어요")
        self.assertEqual((wg.matched, wg.grade, wg.cefr), ("편하다", 2, "A2"))

    def test_pyeonhaejyeosseoyo_grade_correct_as_a_sentence_eojeol_too(self):
        # _resolve_eojeol reports the shallower candidate it tried
        # ("편해지다", itself produced by the pre-existing R7 item 3
        # generic tensed-vowel unfuse) rather than the further-reduced
        # "편하다" reached inside that candidate's own word_grade() call
        # -- same documented shallow-vs-deep convention as
        # TestR7ParticleStackAndPluralGoldenCases's 사람들이 case. The
        # grade/CEFR outcome (identical either way, since 편해지다 itself
        # resolves to 편하다's own grade) is what this pins down.
        wg = self.lex._resolve_eojeol(cl._normalize_token("편해졌어요"))
        self.assertEqual((wg.grade, wg.cefr), (2, "A2"))

    def test_meogeo_bwasseoyo_two_eojeols_main_verb_plus_aux(self):
        sp = self.lex.sentence_profile("먹어 봤어요.", self.grammar)
        matched = [(t.matched, t.grade) for t in sp.tokens]
        self.assertEqual(matched, [("먹다", 1), ("보다", 1)])
        self.assertEqual(sp.unknown, ())

    def test_ilkgo_isseoyo_two_eojeols_main_verb_plus_progressive(self):
        sp = self.lex.sentence_profile("읽고 있어요.", self.grammar)
        matched = [(t.matched, t.grade) for t in sp.tokens]
        self.assertEqual(matched, [("읽다", 1), ("있다", 1)])
        self.assertEqual(sp.unknown, ())


class TestR7AliasA1ExceptionsAndPriorityFix(unittest.TestCase):
    """R7 item 10: three new empty-lexicon_form ("A1 exception") rows
    appended to aliases.csv (진지, 약주, 드시다) -- 잡수시다 was checked
    and NOT appended, since it already resolved to A1 via a direct kiiq
    hit before this item. Also covers the `word_grade` priority fix this
    item needed: 진지 is ALSO a direct kiiq headword (its only row is an
    unrelated grade-5/C1 homograph -- see the module docstring), so an
    empty-lexicon_form alias must be checked BEFORE kiiq, not after (R3's
    original order), or the wrong-register kiiq hit silently shadows it
    forever. Scoped narrowly to empty-lexicon_form aliases only -- the
    two pre-existing 'redirect' aliases that ALSO collide with a direct
    kiiq hit (엄마 -> 어머니, 아빠 -> 아버지) are confirmed UNCHANGED."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()

    def test_jinji_now_a1_via_alias_overriding_the_wrong_register_kiiq_hit(self):
        wg = self.lex.word_grade("진지")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (1, "A1", "alias"))

    def test_yakju_a1_via_alias(self):
        wg = self.lex.word_grade("약주")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (1, "A1", "alias"))

    def test_deusida_a1_via_alias(self):
        wg = self.lex.word_grade("드시다")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (1, "A1", "alias"))

    def test_japsusida_already_a1_via_kiiq_not_appended_as_alias(self):
        wg = self.lex.word_grade("잡수시다")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (1, "A1", "kiiq"))
        self.assertNotIn("잡수시다", self.lex._aliases)

    def test_redirect_aliases_that_collide_with_direct_kiiq_hits_are_unchanged(self):
        # 엄마/아빠 have NON-empty lexicon_form aliases (-> 어머니/아버지)
        # that ALSO collide with a direct kiiq hit on the app_form itself
        # -- confirming the priority fix above is scoped to empty-
        # lexicon_form aliases only and did not touch these.
        for word in ("엄마", "아빠"):
            with self.subTest(word=word):
                wg = self.lex.word_grade(word)
                self.assertEqual(wg.source, "kiiq")
                self.assertEqual(wg.matched, word)


class TestR8ExactHeadwordFirstGoldenCases(unittest.TestCase):
    """R8 item 1 (Fable direct-read finding on live sentence_profile()
    data): `_lemma_candidates` now puts the raw token itself (after
    trailing-punctuation strip) FIRST, before any particle/ending-
    stripped candidate -- so a bare noun that coincidentally ends in a
    character that is ALSO a listed particle/ending (사과's trailing 과,
    which is separately the comitative particle; 가게's trailing 게,
    which is separately the "-게" adverbial ending) resolves to itself
    instead of losing to the coincidental stripped reading. 학교에/
    사과를 (a real particle boundary, where the raw token is NOT itself a
    headword) confirm the ordinary particle-stripping path is untouched."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()

    CASES = [
        ("사과", "사과"),
        ("지도", "지도"),
        ("도로", "도로"),
        ("이유", "이유"),
        ("가게", "가게"),
        ("의사", "의사"),
        ("학교에", "학교"),
        ("사과를", "사과"),
    ]

    def test_all_golden_exact_headword_first_cases(self):
        for surface, expected in self.CASES:
            with self.subTest(surface=surface):
                wg = self.lex._resolve_eojeol(cl._normalize_token(surface))
                self.assertEqual(
                    wg.matched, expected,
                    "%r resolved to %r, expected %r (grade=%r source=%r)"
                    % (surface, wg.matched, expected, wg.grade, wg.source),
                )
                self.assertIsNotNone(wg.grade)

    def test_full_motivating_sentence_does_not_lose_sagwa(self):
        # The exact sentence Fable flagged from live sentence_profile()
        # output: 사과 must resolve as itself, not silently vanish into
        # the wrong "사" (numeral "four") reading.
        grammar = cl.GrammarIndex(())
        sp = self.lex.sentence_profile("사과 두 개하고 오렌지 세 개 주세요.", grammar)
        sagwa = [t for t in sp.tokens if t.matched == "사과"]
        self.assertTrue(sagwa, "expected a token resolved to 사과: %r" % (sp.tokens,))
        self.assertNotIn("사과", [u.rstrip(".") for u in sp.unknown])


class TestR8CopulaNounPreferenceGoldenCases(unittest.TestCase):
    """R8 item 2 (Fable direct-read finding): a token ending in a
    conjugated copula form (이에요/예요/입니다/이었어요/였어요/이라서/이고/
    이지만/인데/이니까/이라고/이야/이죠/이지요/이네요/입니까/이었습니다)
    must offer the NOUN stem as a candidate before PASS 1's verb/
    adjective-conjugation repairs run -- otherwise a stem that
    coincidentally carries a batchim ㄹ (e.g. "길", stem of "길이에요")
    gets hijacked by the pre-existing "already-ㄹ-final-stem" heuristic
    (R7 item 4) into the wrong, but real, "길다" ("to be long") reading.
    예뻐요/커요 lock in that ordinary EU-irregular adjective conjugation
    (unrelated to the copula) is untouched."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()

    CASES = [
        ("길이에요", "길"),
        ("학생이에요", "학생"),
        ("친구예요", "친구"),
        ("선생님입니다", "선생님"),
        ("의사였어요", "의사"),
        ("집인데", "집"),
    ]

    def test_all_golden_copula_noun_cases(self):
        for surface, expected in self.CASES:
            with self.subTest(surface=surface):
                wg = self.lex._resolve_eojeol(cl._normalize_token(surface))
                self.assertEqual(
                    wg.matched, expected,
                    "%r resolved to %r, expected %r (grade=%r source=%r)"
                    % (surface, wg.matched, expected, wg.grade, wg.source),
                )
                self.assertIsNotNone(wg.grade)

    def test_regular_eu_irregular_adjectives_not_treated_as_copula(self):
        # 예뻐요/커요 must keep resolving via the ordinary EU_IRREGULAR_MAP
        # path -- neither is a copula construction, and both are short
        # enough (len 2) that the >len-guard on every copula ending must
        # hold regardless.
        for surface, expected in (("예뻐요", "예쁘다"), ("커요", "크다")):
            with self.subTest(surface=surface):
                wg = self.lex._resolve_eojeol(cl._normalize_token(surface))
                self.assertEqual(wg.matched, expected)


class TestR8StackedEndingsGoldenCases(unittest.TestCase):
    """R8 item 3 (Fable direct-read finding): up to three stacked pre-
    final/final endings (으시/시, 았/었/였, 겠, 더, 았었/었었, plus the
    already-fused honorific-past 으셨/셨, plus the final ending itself)
    must be peelable in one candidate-generation pass -- 알겠습니다 was
    previously unknown because only the FINAL ending (습니다) was ever
    stripped, leaving the pre-final 겠 stuck on the stem (알겠), which is
    not itself a headword and does not restore to one via any existing
    irregular table."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()

    CASES = [
        ("알겠습니다", "알다"),
        ("가시겠어요", "가다"),
        ("먹었겠네요", "먹다"),
        ("오셨습니까", "오다"),
        ("받으셨겠지요", "받다"),
        ("했었어요", "하다"),
    ]

    def test_all_golden_stacked_ending_cases(self):
        for surface, expected in self.CASES:
            with self.subTest(surface=surface):
                wg = self.lex._resolve_eojeol(cl._normalize_token(surface))
                self.assertEqual(
                    wg.matched, expected,
                    "%r resolved to %r, expected %r (grade=%r source=%r)"
                    % (surface, wg.matched, expected, wg.grade, wg.source),
                )
                self.assertIsNotNone(wg.grade)


class TestR8HeadwordCopulaGoldenCases(unittest.TestCase):
    """R8 item 4 (Fable direct-read finding): word_grade() called
    DIRECTLY on a headword spelled in the copula's own citation form
    (stem + 이다, e.g. a vocab-list entry for an X적이다-style adjective)
    was unknown even though the stem is a real, resolvable headword --
    이다 is compositional (it attaches to any noun) and is essentially
    never itself a separate kiiq/basic2023 entry. Checked against the
    real lexicon: 효율적/적극적/객관적/합리적 are direct kiiq headwords
    (grade 4/B2 each), 추상적 is kiiq grade 6/C2, and 서정적ㅡ absent from
    kiiq ㅡ is a basic2023 headword (grade 5 -> C2/6); all six resolve via
    the same stem-is-a-headword check (no case here needed the second,
    strip-적-again fallback -- see TestR8HeadwordCopulaSyntheticFixture
    for a fixture that actually exercises that path)."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()

    CASES = [
        ("효율적이다", "효율적", 4, "B2"),
        ("적극적이다", "적극적", 4, "B2"),
        ("객관적이다", "객관적", 4, "B2"),
        ("추상적이다", "추상적", 6, "C2"),
        ("합리적이다", "합리적", 4, "B2"),
        ("서정적이다", "서정적", 6, "C2"),
        ("학생이다", "학생", 1, "A1"),
    ]

    def test_all_golden_headword_copula_cases(self):
        for surface, expected_matched, expected_grade, expected_cefr in self.CASES:
            with self.subTest(surface=surface):
                wg = self.lex.word_grade(surface)
                self.assertEqual(
                    (wg.matched, wg.grade, wg.cefr), (expected_matched, expected_grade, expected_cefr),
                    "word_grade(%r) = %r" % (surface, wg),
                )
                self.assertEqual(wg.source, "derived")


class TestR8HeadwordCopulaSyntheticFixture(unittest.TestCase):
    """R8 item 4's second check (strip 적 further when the bare X적 stem
    is not itself resolvable), against a tiny controlled fixture -- no
    real-CSV word was found where X적 fails but X alone succeeds, so this
    is exercised synthetically rather than left uncovered.

    The root ("몽상") is placed in basic2023, NOT kiiq: `_base_chain`'s
    kiiq tier (`_kiiq_derived_chain`) already strips DERIVED_SUFFIXES
    (which includes "적") internally via `_derived_lookup` -- so a kiiq
    root would make check 1 (`_base_chain(stem)`, stem="몽상적") succeed
    on its own via that PRE-EXISTING mechanism, never actually reaching
    this item's new check 2. basic2023 has no such suffix-stripping, so
    only a root placed there isolates check 2 specifically."""

    @classmethod
    def setUpClass(cls):
        basic_rows = [_basic_row(2, "몽상")]  # root only; NOT "몽상적"
        cls.lex = cl.CefrLexicon.from_rows([], basic_rows, [])

    def test_strip_jeok_fallback_grades_the_root_at_medium_confidence(self):
        wg = self.lex.word_grade("몽상적이다")
        self.assertEqual((wg.grade, wg.cefr, wg.source, wg.matched), (3, "B1", "derived", "몽상"))
        self.assertEqual(wg.confidence, "medium")

    def test_neither_stem_nor_root_resolvable_stays_unknown(self):
        wg = self.lex.word_grade("가나다적이다")
        self.assertIsNone(wg.grade)


class TestT24aTokenizerFalsePositiveGoldenCases(unittest.TestCase):
    """T2.4a (PR-L2a Part B): auditor-flagged tokenizer false positives,
    against the real lexicon CSVs. Tested through the public API
    (`word_grade`/`sentence_profile`), per Fable's brief for this item --
    every case here was read directly off a real scenario line by the
    auditor, not invented."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()
        cls.gi = cl.GrammarIndex.load()

    # -- B1: honorific -(으)세요/-(으)셨어요/-(으)실 --------------------

    def test_b1_deusillae_never_resolves_to_deuseda(self):
        for surface in ("드세요", "드셨어요", "드실"):
            with self.subTest(surface=surface):
                wg = self.lex.word_grade(surface)
                self.assertEqual(wg.grade, 1)
                self.assertEqual(wg.cefr, "A1")
                self.assertNotEqual(wg.matched, "드세다")

    def test_b1_honorific_seyo_family_already_correct(self):
        cases = [
            ("하세요", "하다"), ("앉으세요", "앉다"), ("오세요", "오다"),
            ("주세요", "주다"), ("말씀하세요", "말씀"),
        ]
        for surface, expected in cases:
            with self.subTest(surface=surface):
                wg = self.lex.word_grade(surface)
                self.assertEqual(wg.matched, expected)
                self.assertEqual(wg.grade, 1)

    def test_b1_pill_instruction_sentence_profiles_as_a1(self):
        prof = self.lex.sentence_profile("이 약은 하루에 세 번 드세요.", self.gi)
        self.assertEqual(prof.unknown, ())
        self.assertEqual(prof.level_estimate, "A1")

    # -- B2: noun+particle must beat a rarer verb/adjective parse -------

    def test_b2_yagun_is_the_noun_not_yakda(self):
        wg = self.lex.word_grade("약은")
        self.assertEqual(wg.grade, 1)
        self.assertNotEqual(wg.matched.split("(")[0], "약다")

    def test_b2_jogakman_is_jogak_plus_man(self):
        wg = self.lex.word_grade("조각만")
        self.assertEqual(wg.matched.split("(")[0], "조각")
        self.assertIsNotNone(wg.grade)

    def test_b2_yeogiyo_is_the_pronoun_not_yeogida(self):
        wg = self.lex.word_grade("여기요")
        self.assertEqual(wg.grade, 1)
        self.assertEqual(wg.matched, "여기")

    def test_b2_munseoinji_is_munseo_at_its_own_grade(self):
        wg = self.lex.word_grade("문서인지")
        self.assertEqual(wg.matched, "문서")
        self.assertEqual(wg.grade, 4)

    # -- B3: ㅂ-irregular predicates --------------------------------------

    B3_CASES = (
        "매워요", "매웠어요", "추워요", "더워요", "어려워요", "쉬워요",
        "가까워요", "무거워요", "가벼워요", "고마워요", "아름다워요",
        "도와요", "도와주세요", "반가워요", "즐거워요", "귀여워요",
        "뜨거워요", "차가워요", "시끄러워요",
    )

    def test_b3_bieup_irregulars_all_resolve_graded(self):
        for surface in self.B3_CASES:
            with self.subTest(surface=surface):
                wg = self.lex.word_grade(surface)
                self.assertIsNotNone(wg.grade, "%r resolved unknown" % surface)
                self.assertNotEqual(wg.source, "basic2023")
                self.assertTrue(wg.matched.endswith("다"), wg.matched)

    def test_b3_bieup_irregulars_exact_lemma(self):
        expected = {
            "매워요": "맵다", "매웠어요": "맵다", "추워요": "춥다",
            "더워요": "덥다", "어려워요": "어렵다", "쉬워요": "쉽다",
            "가까워요": "가깝다", "무거워요": "무겁다", "가벼워요": "가볍다",
            "고마워요": "고맙다", "아름다워요": "아름답다", "도와요": "돕다",
            "도와주세요": "돕다", "반가워요": "반갑다", "즐거워요": "즐겁다",
            "귀여워요": "귀엽다", "뜨거워요": "뜨겁다", "차가워요": "차갑다",
            "시끄러워요": "시끄럽다",
        }
        for surface, lemma in expected.items():
            with self.subTest(surface=surface):
                self.assertEqual(self.lex.word_grade(surface).matched, lemma)

    # -- B4: politeness-요/quotative-요/banmal imperatives ---------------

    def test_b4_yo_after_particle(self):
        for surface, lemma in (("전에요", "전"), ("후에요", "후")):
            with self.subTest(surface=surface):
                wg = self.lex.word_grade(surface)
                self.assertEqual(wg.matched.split("(")[0], lemma)
                self.assertEqual(wg.grade, 1)

    def test_b4_quotative_plus_yo(self):
        expected = {
            "드시라고요": "드시다", "간다고요": "가다", "먹자고요": "먹다",
        }
        for surface, lemma in expected.items():
            with self.subTest(surface=surface):
                wg = self.lex.word_grade(surface)
                self.assertEqual(wg.matched, lemma)
                self.assertIsNotNone(wg.grade)
        wg = self.lex.word_grade("뭐냐고요")
        self.assertEqual(wg.matched, "뭐")
        self.assertIsNotNone(wg.grade)

    def test_b4_banmal_eulge(self):
        self.assertEqual(self.lex.word_grade("옮길게").matched, "옮기다")
        self.assertEqual(self.lex.word_grade("갈게").matched, "가다")

    def test_b4_sentence_final_banmal_imperative_seo_not_grade3(self):
        prof = self.lex.sentence_profile("레나, 여기 서.", self.gi)
        self.assertEqual(prof.unknown, ())
        seo = next(t for t in prof.tokens if t.matched in ("서", "서다"))
        self.assertNotEqual(seo.grade, 3)

    # -- B5: quotation marks stripped before tokenizing ------------------

    def test_b5_curly_and_straight_quotes_both_tokenize_clean(self):
        for text in ("'여기 서'도 맞아?", "‘여기 서’도 맞아?"):
            with self.subTest(text=text):
                prof = self.lex.sentence_profile(text, self.gi)
                self.assertEqual(prof.unknown, ())
                self.assertEqual(len(prof.tokens), 3)

    # -- B6: proper-noun brands / Latin+digit exclusion ------------------

    def test_b6_brand_names_excluded_not_graded_not_unknown(self):
        for brand in (
            "카카오톡", "카톡", "네이버", "인스타그램", "유튜브", "쿠팡",
            "배민", "지도앱",
        ):
            with self.subTest(brand=brand):
                wg = self.lex.word_grade(brand)
                self.assertIsNone(wg.grade)
                self.assertEqual(wg.source, "proper_noun")

    def test_b6_latin_and_digit_tokens_excluded(self):
        for token in ("QR", "5G", "3D"):
            with self.subTest(token=token):
                wg = self.lex.word_grade(token)
                self.assertIsNone(wg.grade)
                self.assertEqual(wg.source, "latin")

    def test_b6_brand_sentence_has_no_unknown(self):
        prof = self.lex.sentence_profile("카카오톡으로 QR 코드를 보냈어요.", self.gi)
        self.assertNotIn("카카오톡으로", prof.unknown)
        self.assertNotIn("QR", prof.unknown)


class TestT25LevelExceptionsGoldenCases(unittest.TestCase):
    """T2.5 (PR-L2a Part A): tools/content_factory/lexicon/level_exceptions.csv
    caps specific headwords' grade at a Fable-ruled allowed_level, against
    the real lexicon CSVs. Golden cases straight from the T2.5 brief."""

    @classmethod
    def setUpClass(cls):
        cls.lex = cl.CefrLexicon.load()
        cls.gi = cl.GrammarIndex.load()

    def test_kinship_jangineoreun_capped_a1_exception(self):
        wg = self.lex.word_grade("장인어른")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (1, "A1", "exception"))

    def test_signage_a2_hwanseung_capped_a2(self):
        wg = self.lex.word_grade("환승")
        self.assertEqual((wg.grade, wg.cefr), (2, "A2"))
        self.assertEqual(wg.source, "exception")

    def test_phrase_seongmyo_ot_takes_max_capped_at_a2(self):
        # 성묘 (culture_advanced exception -> A2) + 옷 (ordinary kiiq A1
        # word) -- the per-eojeol cap on 성묘 alone is enough for
        # phrase_grade's existing max-over-tokens to land on A2.
        pg = self.lex.phrase_grade("성묘 옷")
        self.assertEqual((pg.grade, pg.cefr), (2, "A2"))
        seongmyo = next(w for w in pg.words if w.matched == "성묘")
        self.assertEqual(seongmyo.source, "exception")

    def test_munjeeobseoyo_fixed_expression_a1(self):
        wg = self.lex.word_grade("문제없어요")
        self.assertEqual((wg.grade, wg.cefr), (1, "A1"))

    def test_unlisted_word_unchanged(self):
        # 공부하다 is not in level_exceptions.csv -- ordinary 'derived'
        # resolution must be completely unaffected by this feature.
        wg = self.lex.word_grade("공부하다")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (1, "A1", "derived"))

    def test_every_csv_headword_resolves_at_or_below_its_allowed_level(self):
        rows = cl.load_level_exceptions()
        for row in rows:
            headword = row["headword"].strip()
            allowed_grade = cl.CEFR_TO_GRADE[row["allowed_level"].strip()]
            with self.subTest(headword=headword):
                if " " in headword:
                    result_grade = self.lex.phrase_grade(headword).grade
                else:
                    result_grade = self.lex.word_grade(headword).grade
                self.assertIsNotNone(result_grade, headword)
                self.assertLessEqual(result_grade, allowed_grade, headword)

    def test_multiword_fixed_expression_saehae_bok(self):
        wg = self.lex.word_grade("새해 복 많이 받으세요")
        self.assertEqual((wg.grade, wg.cefr, wg.source), (1, "A1", "exception"))
        pg = self.lex.phrase_grade("새해 복 많이 받으세요")
        self.assertEqual((pg.grade, pg.cefr), (1, "A1"))

    def test_multiword_fixed_expression_jal_meogeotseumnida(self):
        pg = self.lex.phrase_grade("잘 먹었습니다")
        self.assertEqual((pg.grade, pg.cefr), (1, "A1"))

    def test_negation_compound_rule_uses_root_grade_when_not_listed(self):
        # X없어요/X없다/X없는 -> X's own grade, for an X NOT itself in
        # level_exceptions.csv (시간 is an ordinary kiiq headword).
        sigan = self.lex.word_grade("시간")
        for surface in ("시간없어요", "시간없다", "시간없는"):
            with self.subTest(surface=surface):
                wg = self.lex.word_grade(surface)
                self.assertEqual(wg.grade, sigan.grade)
                self.assertEqual(wg.source, "derived")
                self.assertEqual(wg.matched, "시간")

    def test_exception_confidence_is_high(self):
        wg = self.lex.word_grade("환승")
        self.assertEqual(wg.confidence, "high")

    def test_sentence_profile_carries_exception_source_for_listed_token(self):
        prof = self.lex.sentence_profile("추석에 성묘를 갔어요.", self.gi)
        seongmyo = next(t for t in prof.tokens if t.matched == "성묘")
        self.assertEqual(seongmyo.source, "exception")
        self.assertEqual(seongmyo.grade, 2)


if __name__ == "__main__":
    unittest.main()
