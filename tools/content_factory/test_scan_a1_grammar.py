#!/usr/bin/env python3
"""C2d step 5 -- guards for tools/content_factory/scan_a1_grammar.py.

1. Detector unit tests: catches -다고 하셨어요/-으면/-을게요/-네요 (grade>=2
   patterns actually found in the live corpora before this rewrite), allows
   the 1급-safe replies 그래요/이에요/-을까요/-으세요/-었어요/-고 싶어요.
2. Live guard: after the C2d rewrite, korean_vocab.csv/cloze.json/
   satz_sentences.json A1 rows must have ZERO flagged rows (with a
   documented exception list -- currently empty; add an id here only with
   a comment explaining why it is deliberately kept, mirroring
   test_character_profiles_speech_style.py's RETIRED_STRINGS pattern).

Run with:
    python3 -m unittest tools/content_factory/test_scan_a1_grammar.py
"""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tool"))
sys.path.insert(0, str(REPO_ROOT / "tools" / "content_factory"))

from cefr_lexicon import CefrLexicon, GrammarIndex  # noqa: E402
import scan_a1_grammar as S  # noqa: E402

# Deliberately-kept exceptions: (kind, id) rows that scan_a1_grammar.py may
# still flag after the C2d rewrite, with the reason recorded here so a
# future edit can't silently reintroduce a violation without noticing this
# list.
#
# Coordinator round 3 (2026-09-15): extending the detector for contracted
# -아/어 보다 / -아/어 주다 (+ -는 법 / -는 게) surfaced 38 rows (12 vocab +
# 13 cloze + 13 satz), almost all the same "-아/어 주세요" benefactive-
# request family spanning many packs (phone/address exchange, pronunciation
# repair, postal requests, borrowing money, etc.) -- see
# docs/data/a1_grammar_scan_2026-09-15.md. Per the coordinator's explicit
# ">30 new hits: stop and report before rewriting" instruction, these were
# reported but NOT rewritten in this PR -- kept here as a tracked,
# deliberate exception list (not silently ignored) pending a rewrite-
# strategy decision, since unilaterally changing how the whole app phrases
# "please do X for me" 20+ times needs sign-off first.
DOCUMENTED_EXCEPTIONS: set[tuple[str, str]] = {
    ("vocab", "vocab_a1_0141"), ("vocab", "vocab_a1_0202"), ("vocab", "vocab_a1_0203"),
    ("vocab", "vocab_b1_0196"), ("vocab", "vocab_a1_0217"), ("vocab", "vocab_a1_0311"),
    ("vocab", "vocab_a1_0316"), ("vocab", "vocab_a1_0408"), ("vocab", "vocab_a1_0409"),
    ("vocab", "vocab_a1_0410"), ("vocab", "vocab_a1_0438"), ("vocab", "vocab_a1_0456"),
    ("cloze", "cloze_a1_0094"), ("cloze", "cloze_a1_0105"), ("cloze", "cloze_a1_0199"),
    ("cloze", "cloze_a1_0204"), ("cloze", "cloze_a1_0316"), ("cloze", "cloze_a1_0317"),
    ("cloze", "cloze_a1_0319"), ("cloze", "cloze_a1_0320"), ("cloze", "cloze_a1_0324"),
    ("cloze", "cloze_a1_0331"), ("cloze", "cloze_a1_0332"), ("cloze", "cloze_a1_0367"),
    ("cloze", "cloze_a1_0390"),
    ("satz", "satz_a1_0028"), ("satz", "satz_a1_0059"), ("satz", "satz_a1_0069"),
    ("satz", "satz_a1_0163"), ("satz", "satz_a1_0168"), ("satz", "satz_a1_0300"),
    ("satz", "satz_b1_0407"), ("satz", "satz_a1_0315"), ("satz", "satz_a1_0316"),
    ("satz", "satz_a1_0317"), ("satz", "satz_a1_0321"), ("satz", "satz_a1_0353"),
    ("satz", "satz_a1_0371"),
}


class DetectorUnitTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.lexicon = CefrLexicon.load(REPO_ROOT)
        cls.grammar_index = GrammarIndex.load(REPO_ROOT)

    def _hits(self, text: str):
        patterns = [(h.pattern_id, h.grade, h.text) for h in S._grammar_hits_ge2(self.lexicon, self.grammar_index, text)]
        for m in S.EXPLICIT_QUOTE_RE.finditer(text):
            patterns.append(("explicit_quote", 3, m.group(0)))
        for m in S.BARE_QUOTE_HASYEOSEO_RE.finditer(text):
            patterns.append(("bare_quote", 3, m.group(0)))
        patterns.extend(S._attributive_noun_hits(text))
        patterns.extend(S._contracted_aux_hits(text))
        return patterns

    # -- must catch (real examples pulled from the pre-rewrite A1 corpora) --

    def test_catches_quoted_prohibition_하셨어요(self) -> None:
        # vocab_a1_0269 before C2d.
        hits = self._hits("차례상 앞에서는 사진을 찍지 말라고 하셨어요.")
        self.assertTrue(hits, "quoted -라고 하셨어요 (grade 3-4) must be flagged")

    def test_catches_conditional_으면(self) -> None:
        # vocab_a1_0336 before C2d.
        hits = self._hits("늦으면 미리 연락해 주세요.")
        self.assertTrue(any(h[1] >= 2 for h in hits), "-으면 (grade 2) must be flagged")

    def test_catches_promise_을게요(self) -> None:
        # vocab_a1_0343 before C2d (embedded, but the ending itself is the point).
        hits = self._hits("제가 먼저 잡을게요.")
        self.assertTrue(any(h[1] >= 2 for h in hits), "-을게요 (grade 2) must be flagged")

    def test_catches_exclamation_네요(self) -> None:
        # vocab_a1_0045 before C2d.
        hits = self._hits("오늘 눈이 좀 피곤하네요.")
        self.assertTrue(any(h[1] >= 2 for h in hits), "-네요 (grade 2) must be flagged")

    def test_catches_attributive_noun_전성어미(self) -> None:
        # Fable R8: 관형사형 -는/-ㄴ + noun (전성어미, grade 2) is not
        # covered by GrammarIndex at all -- explicit collocation list.
        for text in ("처음 만난 분께 인사해요.", "집에 가는 친구가 있어요.",
                     "가게를 나가는 손님이 많아요."):
            with self.subTest(text=text):
                self.assertTrue(self._hits(text), f"{text!r} must be flagged")

    def test_catches_bare_quote_하셔서(self) -> None:
        # vocab_a1_0248 before C2d.
        hits = self._hits("진지 드세요 하셔서 숟가락을 들었어요.")
        self.assertTrue(hits, "bare '[phrase] 하셔서' quotation must be flagged")

    def test_catches_contracted_aux_try_아어보다(self) -> None:
        # Coordinator round 3: batched -았/었- fusion (봤) is NOT undone by
        # cefr_lexicon.expand_contractions (only unbatched vowel fusions
        # like 봐<-보아 are), so these need the explicit check.
        for text in ("호칭이 어려워서 수진 씨에게 물어봤어요.",  # single-token fusion
                     "이 음식을 먹어 봤어요."):                   # space-separated
            with self.subTest(text=text):
                self.assertTrue(self._hits(text), f"{text!r} must be flagged")

    def test_catches_contracted_aux_give_아어주다(self) -> None:
        for text in ("전화번호를 알려 주세요.", "이 단어 발음을 다시 들려주세요.",
                     "시어머니께서 웃어 주셨어요."):
            with self.subTest(text=text):
                self.assertTrue(self._hits(text), f"{text!r} must be flagged")

    def test_allows_lexical_보다_주다_alone(self) -> None:
        # Coordinator's explicit negative case: 보다/주다 as their OWN main
        # verb, not an auxiliary -- the object particle right before them
        # (를/을/...) never ends in a verb connecting-vowel character, so
        # the heuristic naturally excludes these without an allowlist.
        for text in ("영화를 봐요.", "선물을 줘요.", "매일 텔레비전을 봐요.",
                     "생일에 선물을 줬어요."):
            with self.subTest(text=text):
                self.assertEqual(self._hits(text), [], f"{text!r} must NOT be flagged")

    def test_catches_는_법(self) -> None:
        hits = self._hits("세배하는 법을 배웠어요.")
        self.assertTrue(hits)

    def test_catches_는_게(self) -> None:
        hits = self._hits("이해하는 게 어려워요.")
        self.assertTrue(hits)

    def test_allows_는_게_false_positive_across_word_boundary(self) -> None:
        # "저는 게를 좋아해요" ("I like crab") -- 는(topic particle on 저) +
        # 게(crab, unrelated noun) coincidentally produces the substring
        # "는 게", but "게를" continues past the \b the regex requires.
        self.assertEqual(self._hits("저는 게를 좋아해요."), [])

    # -- must allow (1급-safe A1 content, incl. the C2d rewritten forms) --

    def test_allows_그래요(self) -> None:
        self.assertEqual(self._hits("네, 그래요."), [])

    def test_allows_copula_이에요_예요(self) -> None:
        self.assertEqual(self._hits("저는 학생이에요."), [])
        self.assertEqual(self._hits("이건 사과예요."), [])

    def test_allows_invitation_을까요(self) -> None:
        self.assertEqual(self._hits("옆에 앉을까요?"), [])

    def test_allows_honorific_imperative_으세요(self) -> None:
        self.assertEqual(self._hits("할머니, 진지 드세요."), [])

    def test_allows_past_tense_었어요(self) -> None:
        self.assertEqual(self._hits("어제 학교에 갔어요."), [])

    def test_allows_want_고_싶다(self) -> None:
        self.assertEqual(self._hits("저는 집에 가고 싶어요."), [])

    def test_allows_같이_as_adverb(self) -> None:
        # nikl_kiiq_2017_vocab.csv grade=1 부사 homograph ("함께" sense),
        # not the grade-3 조사 homograph -- see scan_a1_grammar.py docstring.
        self.assertEqual(self._hits("언니랑 같이 가요."), [])


class LiveA1CorpusGuardTest(unittest.TestCase):
    """After the C2d rewrite, every A1 row in the three corpora must be
    grammar-clean (§B.1's 45-item 1급 table only)."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.lexicon = CefrLexicon.load(REPO_ROOT)
        cls.grammar_index = GrammarIndex.load(REPO_ROOT)
        cls.vocab_rows = S._load_vocab_rows()
        for row in cls.vocab_rows:
            row["level"] = (row.get("level") or "").strip().lower()
        cls.cloze_items = S._load_json(S.CLOZE_JSON)["items"]
        cls.satz_items = S._load_json(S.SATZ_JSON)["items"]

    def _assert_clean(self, kind, rows, id_key, text_key):
        flagged, _mismatch = S.scan_corpus(
            self.lexicon, self.grammar_index, rows,
            id_key=id_key, text_key=text_key, level_key="level",
            target_level="a1", kind=kind,
        )
        unexpected = [f for f in flagged if (kind, f["id"]) not in DOCUMENTED_EXCEPTIONS]
        self.assertEqual(
            unexpected, [],
            msg=f"{kind}: A1 rows still carry grade>=2 grammar: "
            f"{[(f['id'], f['text']) for f in unexpected]}",
        )

    def test_headword_embedded_grammar_is_a_documented_exception(self) -> None:
        # Fable R8: vocab_a1_0341's headword "늦을 것 같다" bakes in a
        # grade-2 표현; scan_corpus must not flag it (nor its cloze/satz
        # mirrors) once its example correctly uses the headword verbatim.
        row = next(r for r in self.vocab_rows if r["id"] == "vocab_a1_0341")
        self.assertIn("늦을 것 같", row["example_korean"])
        flagged, _ = S.scan_corpus(
            self.lexicon, self.grammar_index, [row],
            id_key="id", text_key="example_korean", level_key="level",
            target_level="a1", kind="vocab",
        )
        self.assertEqual(flagged, [])

    def test_vocab_a1_examples_are_grammar_clean(self) -> None:
        self._assert_clean("vocab", self.vocab_rows, "id", "example_korean")

    def test_cloze_a1_items_are_grammar_clean(self) -> None:
        self._assert_clean("cloze", self.cloze_items, "id", "fullKo")

    def test_satz_a1_items_are_grammar_clean(self) -> None:
        self._assert_clean("satz", self.satz_items, "id", "targetKo")


if __name__ == "__main__":
    unittest.main()
