"""Tests for tool/audit_content_levels.py — plan T1.3 (§4.2, §3.C.3).

Test classes:

* ``FixtureAuditTest`` builds a tiny, fully hand-computable content tree
  (vocab packs + 2 standalone words, grammar rows, 1 scenario, 2 cloze,
  2 satz, 2 smalltalk, 3 pronunciation, 2 media, a minimal lexicon) under a
  temp dir and asserts every classification decision (delta, reason,
  suggested_action, blocked_by, bundle_id, pack override, coverage) against
  numbers worked out by hand in the module/task docstrings — see the
  per-item comments below for the arithmetic.
* ``ResolvedLemmaKeysTest`` / ``ApplyPackOverridesGuardTest`` (R4b items 1
  and 2) unit-test two of the module's pure-ish helpers in isolation, with
  a hand-built ``CefrLexicon`` / synthetic ``Item`` lists rather than the
  full corpus fixture — see each class's own docstring.
* ``LiveRatchetTest`` runs the audit against the real repo and checks the
  live counts against CAP constants (current value, "하향 전용" — only ever
  lowered, never raised).

Every fixture Korean string is a single already-dictionary-form kiiq
headword (no particles/endings to strip) chosen so it cannot accidentally
resolve through the tokenizer's particle-stripping fallback to some other
fixture headword — see the "no collision" note by FIXTURE_KIIQ_ROWS.
"""

from __future__ import annotations

import csv
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import audit_content_levels as acl  # noqa: E402

REPO = Path(__file__).resolve().parent.parent

# ---------------------------------------------------------------------------
# Fixture kiiq vocab grades used throughout this file:
#   grade1 (A1): 사과 학교 친구      grade2 (A2): 공원
#   grade3 (B1): 회의 계약           grade5 (C1): 정책
# None of these headwords end in a listed PARTICLES/ENDINGS suffix that
# would make the tokenizer's fallback-candidate chain resolve to some other
# *fixture* headword before reaching the word itself (verified by hand
# against tool/cefr_lexicon.py PARTICLES/ENDINGS; 사과/회의 transiently
# produce a stripped candidate '사'/'회' via the single-char 과/의
# particles, but neither '사' nor '회' is itself a fixture headword, so
# _resolve_eojeol falls through to the un-stripped word).
#
# R4 item 2 additions (coverage 'dedupe homograph and split rows'):
#   - 친구 gets a SECOND grade-1 row (homograph 1) -- a same-grade
#     homograph duplicate that must still count as ONE unique headword.
#   - 공원 gets a SECOND row at grade 5 (in addition to its existing
#     grade-2 row) -- a headword 'split' across grades that must be
#     bucketed ONCE, at its minimum grade (2), never leaking a phantom
#     second count into grade 5's coverage total.
#
# R4b item 1 addition: 우유 (grade 1) is a headword that stays genuinely
# missing (no vocab row's literal `korean` or resolved lemma ever reaches
# it) -- it exists purely so grade1 coverage keeps one real missing word
# to assert against once 친구 becomes present via the NEW resolved-lemma
# path below (see the vocab_a2_0003 fixture row / aliases.csv addition).
# ---------------------------------------------------------------------------

FIXTURE_KIIQ_ROWS = [
    {"grade": "1", "headword": "사과", "homograph": "0", "pos": "명사", "guide": "", "band": "초급"},
    {"grade": "1", "headword": "학교", "homograph": "0", "pos": "명사", "guide": "", "band": "초급"},
    {"grade": "1", "headword": "친구", "homograph": "0", "pos": "명사", "guide": "", "band": "초급"},
    {"grade": "1", "headword": "친구", "homograph": "1", "pos": "명사", "guide": "", "band": "초급"},
    {"grade": "1", "headword": "우유", "homograph": "0", "pos": "명사", "guide": "", "band": "초급"},
    {"grade": "2", "headword": "공원", "homograph": "0", "pos": "명사", "guide": "", "band": "초급"},
    {"grade": "3", "headword": "회의", "homograph": "0", "pos": "명사", "guide": "", "band": "중급"},
    {"grade": "3", "headword": "계약", "homograph": "0", "pos": "명사", "guide": "", "band": "중급"},
    {"grade": "5", "headword": "정책", "homograph": "0", "pos": "명사", "guide": "", "band": "고급"},
    {"grade": "5", "headword": "공원", "homograph": "0", "pos": "명사", "guide": "", "band": "고급"},
]


def _write_csv(path: Path, header, rows) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=header, lineterminator="\n")
        w.writeheader()
        for row in rows:
            w.writerow(row)


def _write_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def build_fixture(root: Path) -> None:
    lex_dir = root / "tools" / "content_factory" / "lexicon"
    assets = root / "assets" / "data"

    _write_csv(lex_dir / "nikl_kiiq_2017_vocab.csv",
               ["grade", "headword", "homograph", "pos", "guide", "band"], FIXTURE_KIIQ_ROWS)
    _write_csv(lex_dir / "nikl_kiiq_2017_grammar.csv",
               ["grade", "category", "form", "variants", "meaning", "band_2stage", "band_1to4"], [])
    # 사전: basic2023-only (not in kiiq at all) at grade 5 -> BASIC2023_TO_GRADE[5]
    # = grade 6 (C2), source='basic2023', confidence='low' (R4 items 4/2:
    # kcenter is gone -- R3/R2 -- so basic2023 is the only remaining
    # low-confidence fallback tier; deliberately grade 5, not 1, so a
    # word/sentence resolving through it lands far enough above any A1/A2
    # fixture level to exercise the new fallback_over2 path below).
    _write_csv(lex_dir / "nikl_basic_2023_vocab.csv",
               ["grade", "headword", "homograph", "pos", "origin"],
               [{"grade": "5", "headword": "사전", "homograph": "1", "pos": "명사", "origin": "고유어"}])
    # R4b item 1: a multiword-alias redirect (app_form has no space,
    # lexicon_form does) -- word_grade("남자친구").matched == "남자 친구"
    # (space-joined; 남자 itself never resolves, 친구 wins the alias's own
    # max-of-known-subwords pick, but _alias_lookup keeps `lexicon_form`
    # verbatim as `matched`, not just the winning subword -- see
    # cefr_lexicon.CefrLexicon._alias_lookup). This is the fixture's only
    # exercise of the "split a multiword resolved-lemma match on ' '"
    # coverage rule; see _resolved_lemma_keys / vocab_a2_0003 below.
    _write_csv(lex_dir / "aliases.csv", ["app_form", "lexicon_form", "note"],
               [{"app_form": "남자친구", "lexicon_form": "남자 친구", "note": ""}])

    # -- vocab: pack1 (a1_test_pack_1, level A1) ---------------------------
    vocab_header = [
        "korean", "romanization", "german", "level", "pos_de", "example_korean",
        "example_german", "topic", "pack_id", "pack_order", "is_review_boss",
        "english", "pos_en", "example_english", "id",
    ]

    def vocab_row(korean, level, pack_id, order, rid, boss="false"):
        return {
            "korean": korean, "romanization": "", "german": "", "level": level,
            "pos_de": "Nomen", "example_korean": korean, "example_german": "",
            "topic": "Test", "pack_id": pack_id, "pack_order": str(order),
            "is_review_boss": boss, "english": "", "pos_en": "noun",
            "example_english": "", "id": rid,
        }

    vocab_rows = [
        # pack1 (A1): HIGH-CONF grades [1,1,3,2] -> median 1.5, delta_pack=
        # +0.5 (no override) -- 사전 (basic2023/low-conf) is EXCLUDED from
        # this median/share (R4 item 4 / R4b item 2a: "pack medians ... use
        # high+medium-confidence word grades only"), so adding it changes
        # n_words (4->5) but leaves median_delta/share_ge_plus2 unchanged;
        # n_hm stays 4, n_low is 1.
        vocab_row("사과", "A1", "a1_test_pack_1", 1, "vocab_a1_0001"),   # g1 delta 0
        vocab_row("학교", "A1", "a1_test_pack_1", 2, "vocab_a1_0002"),   # g1 delta 0
        vocab_row("회의", "A1", "a1_test_pack_1", 3, "vocab_a1_0003"),   # g3 delta+2 over2 (high-conf)
        vocab_row("공원", "A1", "a1_test_pack_1", 4, "vocab_a1_0004"),   # g2 delta+1 over1 (high-conf)
        vocab_row("사전", "A1", "a1_test_pack_1", 5, "vocab_a1_0005"),   # g6/basic2023/low delta+5 -> fallback_over2
        # pack2 (A2): grades [3,5] (both high-conf) -> median 4.0,
        # delta_pack=+2.0 -- clears the >=2 override threshold, but n_hm=2
        # is under the R4b item 2 six-usable-word floor, so the override
        # lands as 'insufficient_sample', not 'bundle_move' (see
        # ApplyPackOverridesGuardTest for the n_hm>=6 case where
        # bundle_move still fires).
        vocab_row("회의", "A2", "a2_test_pack_1", 1, "vocab_a2_0001"),   # g3 delta+1 over1 (overridden)
        vocab_row("정책", "A2", "a2_test_pack_1", 2, "vocab_a2_0002"),   # g5 delta+3 over2
        # standalone, no pack: pure ASCII-digit headword -- R4 item 4
        # ("proper nouns and numbers are neither unknown nor graded"):
        # grade=None by design (source='number'), must be bucket="" (kept),
        # NOT reason="unknown".
        vocab_row("10", "A1", "", 0, "vocab_a1_0006"),
        # pack3 (A1): ONE high-conf word (정책) + ONE fallback_over2 word
        # (사전) -- isolates R4 item 4's "fallback_over2 rows are exempt
        # from the pack median>=2 override" decision: pack3's median
        # (high+medium only, i.e. just 정책's grade 5) is 5.0, delta_pack=
        # +4.0 >= 2 -> override fires, but must only touch 정책 (word_move
        # -> insufficient_sample, n_hm=1 < 6), never 사전 (stays
        # review_fallback regardless of the pack-level guard's outcome).
        vocab_row("사전", "A1", "a1_test_pack_3", 1, "vocab_a1_0007"),   # fallback_over2, exempt from override
        vocab_row("정책", "A1", "a1_test_pack_3", 2, "vocab_a1_0008"),   # g5 delta+4 over2, overridden (insufficient_sample)
        # standalone, no pack -- R4b item 1 (coverage present_in_app by
        # resolved lemma): korean="남자친구" has no literal grade1/2 kiiq
        # headword match, but word_grade("남자친구") resolves via the
        # aliases.csv redirect above to matched="남자 친구" (space-joined) ->
        # split into {"남자","친구"} -> "친구" (grade1) becomes present_in_app
        # even though no row's raw `korean` is ever literally "친구". Its
        # OWN level is A2 (not A1), so it must NOT count toward grade1's
        # `at_level` -- present-but-not-at-level is the point of this row.
        # Item grade: phrase_grade resolves the same alias -> grade1/A1,
        # delta = 1-2 = -1 -> bucket="" (kept), not a suspect -- zero
        # blast radius on counts/CSV beyond the coverage numbers.
        vocab_row("남자친구", "A2", "", 0, "vocab_a2_0003"),
        # standalone, no pack -- R4b item 2b (medium confidence is usable
        # evidence, not fallback): "회의계약" is not itself a kiiq/basic2023/
        # alias/derived entry, so it falls all the way to the last-resort
        # 2-way compound split (회의 g3 + 계약 g3, both real headwords) ->
        # grade=3/B1, source='compound', confidence='medium'. At level A1
        # (rank1) delta=3-1=+2 -> over2. Under the OLD (R4) policy this
        # would have been forced to fallback_over2; under R4b it keeps the
        # ORDINARY vocab over2 action (word_move), with `reason` naming the
        # source ("over2 src=compound") since it isn't a bare kiiq hit.
        vocab_row("회의계약", "A1", "", 0, "vocab_a1_0009"),
    ]
    _write_csv(assets / "korean_vocab.csv", vocab_header, vocab_rows)

    # -- grammar -------------------------------------------------------
    grammar_header = [
        "pattern", "level", "type_de", "explanation_de", "example_korean",
        "example_german", "note", "type_en", "explanation_en", "example_en",
        "note_en", "id", "quiz_focus_de", "quiz_focus_en", "quiz_enabled",
        "quiz_distractor_ids",
    ]

    def grammar_row(pattern, level, example_korean, rid):
        return {
            "pattern": pattern, "level": level, "type_de": "", "explanation_de": "",
            "example_korean": example_korean, "example_german": "", "note": "",
            "type_en": "", "explanation_en": "", "example_en": "", "note_en": "",
            "id": rid, "quiz_focus_de": "", "quiz_focus_en": "", "quiz_enabled": "false",
            "quiz_distractor_ids": "",
        }

    grammar_rows = [
        grammar_row("인사", "A1", "친구", "grammar_a1_easy"),        # g1 delta 0
        grammar_row("회의체", "B1", "회의", "grammar_b1_meeting"),   # g3 delta 0 (used by scenario grammarIds)
        grammar_row("계약서", "A1", "계약", "grammar_a1_hard"),      # g3 delta+2 over2 (high-conf kiiq)
        # sentence-level fallback_over2 (R4 item 4, R4b item 2c: still
        # fallback -- LOW confidence): example_korean is the single
        # low-confidence token 사전 (basic2023 grade 6 capped to 3 for
        # lexical_p90 purposes) -> base_grade=3 (B1), delta = 3-1 = +2
        # over2 raw, but its only contributing token is not high-confidence.
        grammar_row("사전어휘", "A1", "사전", "grammar_a1_fallback"),
        # sentence-level R4b item 2c: example_korean "회의계약" resolves the
        # same last-resort compound split as vocab_a1_0009 above (회의 g3 +
        # 계약 g3 -> grade3/B1, confidence='medium', source='compound') ->
        # lexical_p90=3.0, delta=3-1=+2 over2 raw. MEDIUM (not LOW) drives
        # the verdict, so under R4b it must stay a plain 'over2' (capping
        # logic itself is unchanged -- medium is still capped at grade 4
        # for lexical_p90 purposes, same as before), never fallback_over2.
        grammar_row("회의계약패턴", "A1", "회의계약", "grammar_a1_medium"),
    ]
    _write_csv(assets / "grammar.csv", grammar_header, grammar_rows)

    # -- scenario --------------------------------------------------------
    # sentence pool: [사과(g1), 학교(g1), 정책(g5)] -> p75(linear)=3.0 -> round 3
    # grammarIds=[grammar_b1_meeting] -> rank 3 -> max(3,3)=3 (B1), app A1 delta+2 over2
    scenario = {
        "id": "scn_test_1", "level": "a1", "title": {"ko": "사과"},
        "shelf": "a1_test", "backdrop": "home",
        "grammarIds": ["grammar_b1_meeting"],
        "dialog": [{"speaker": "a", "ko": "학교"}, {"speaker": "b", "ko": "정책"}],
    }
    _write_json(assets / "scenarios_a1.json", {"version": 1, "scenarios": [scenario]})
    for slug in ("a2", "b1", "b2", "c1", "c2"):
        _write_json(assets / f"scenarios_{slug}.json", {"version": 1, "scenarios": []})

    # -- cloze -------------------------------------------------------
    cloze_items = [
        {"id": "cloze_a1_0001", "level": "a1", "sentenceKo": "", "answer": "", "fullKo": "사과",
         "de": "", "en": "", "distractors": [], "topic": "t"},          # g1 delta 0, bundle=a1_test_pack_1
        {"id": "cloze_a1_0002", "level": "a1", "sentenceKo": "", "answer": "", "fullKo": "계약",
         "de": "", "en": "", "distractors": [], "topic": "t"},          # g3 delta+2 over2, bundle="" , can_do_ref
    ]
    _write_json(assets / "cloze.json", {"meta": {}, "items": cloze_items})

    # -- satz -------------------------------------------------------
    satz_items = [
        {"id": "satz_a1_0001", "level": "a1", "targetKo": "학교", "promptDe": "", "promptEn": "",
         "distractors": [], "vocabKo": "학교"},                          # g1 delta 0, bundle=a1_test_pack_1
        {"id": "satz_a1_0002", "level": "a1", "targetKo": "정책", "promptDe": "", "promptEn": "",
         "distractors": [], "vocabKo": "공원"},                          # g5 delta+4 over2, satz_keys=("a1","공원")
    ]
    _write_json(assets / "satz_sentences.json", {"meta": {}, "items": satz_items})

    # -- smalltalk -------------------------------------------------------
    smalltalk = {
        "version": 1, "_comment": "", "categories": [],
        "phrases": [
            {"id": "smalltalk_a1_0001", "category": "c", "level": "a1", "kind": "opener", "ko": "학교"},  # delta 0
            {
                "id": "smalltalk_a1_0002", "category": "c", "level": "a1", "kind": "question",
                "ko": "친구", "reply": {"ko": "정책"}, "followUp": {"ko": "사과"},
            },  # max(1,5,1)=5 (C1) delta+4 over2
        ],
    }
    _write_json(assets / "smalltalk.json", smalltalk)

    # -- pronunciation -------------------------------------------------------
    pronunciation = {
        "version": 1,
        "phrases": [
            {"id": "pronunciation_a1_0001", "level": "a1", "ko": "사과", "de": "", "en": "", "focus": ""},  # delta 0
            {"id": "pronunciation_a1_0002", "level": "a1", "ko": "정책", "de": "", "en": "", "focus": ""},  # delta+4 over2
            {"id": "pronunciation_a1_0003", "level": "a1", "ko": "xyzxyz", "de": "", "en": "", "focus": ""},  # unknown
        ],
    }
    _write_json(assets / "pronunciation_phrases.json", pronunciation)

    # -- media -------------------------------------------------------
    media = {
        "version": 1,
        "phrases": [
            {"id": "media_a1_0001", "level": "A1", "korean": "학교", "romanization": "", "german": "",
             "english": "", "source_type": "", "source_style": "", "grammar_ids": [], "vocab_ids": [],
             "courseUnitId": "", "conceptIds": [], "context_de": "", "context_en": ""},  # delta 0
            {"id": "media_a1_0002", "level": "A1", "korean": "정책", "romanization": "", "german": "",
             "english": "", "source_type": "", "source_style": "", "grammar_ids": [], "vocab_ids": [],
             "courseUnitId": "", "conceptIds": [], "context_de": "", "context_en": ""},  # delta+4 over2
        ],
    }
    _write_json(assets / "media_phrases.json", media)

    # -- can_do_content_authorities -------------------------------------------------------
    can_do = {
        "schemaVersion": 1, "sourceSeeds": [],
        "contentReferences": [
            {"kind": "vocabPack", "id": "a2_test_pack_1", "level": "a2", "sourceSeedId": "x", "courseUnitId": "y"},
            {"kind": "cloze", "id": "cloze_a1_0002", "level": "a1", "sourceSeedId": "x", "courseUnitId": "y"},
            {"kind": "satz", "id": "satz_a1_0002", "level": "a1", "sourceSeedId": "x", "courseUnitId": "y"},
            {"kind": "smalltalk", "id": "smalltalk_a1_0002", "level": "a1", "sourceSeedId": "x", "courseUnitId": "y"},
            {"kind": "scenario", "id": "scn_test_1", "level": "a1", "sourceSeedId": "x", "courseUnitId": "y"},
            {"kind": "grammar", "id": "grammar_a1_hard", "level": "a1", "sourceSeedId": "x", "courseUnitId": "y"},
        ],
        "coverage": {},
    }
    _write_json(assets / "can_do_content_authorities.json", can_do)


class FixtureAuditTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.tmpdir = tempfile.TemporaryDirectory()
        cls.root = Path(cls.tmpdir.name)
        build_fixture(cls.root)
        cls.result = acl.run_audit(cls.root)
        cls.by_kind_id = {
            (it.kind, it.id): it
            for items in cls.result.items_by_kind.values()
            for it in items
        }
        # R4 item 2: loaded separately so tests can call compute_coverage()
        # directly for a grade (5/C1) that run_audit()'s AuditResult does
        # not itself surface (only grade1/grade2 are part of the app's
        # reported "1급·2급 결손" scope).
        cls.corpus = acl.load_corpus(cls.root)

    @classmethod
    def tearDownClass(cls) -> None:
        cls.tmpdir.cleanup()

    # -- vocab / pack override ------------------------------------------------

    def test_vocab_word_within_level_is_kept(self):
        it = self.by_kind_id[("vocab", "vocab_a1_0001")]
        self.assertEqual(it.level, "a1")
        self.assertEqual(it.estimate, "a1")
        self.assertEqual(it.grade, 1)
        self.assertEqual(it.delta, 0)
        self.assertEqual(it.bucket, "")
        self.assertEqual(it.reason, "")
        self.assertEqual(it.suggested_action, "keep")
        self.assertEqual(it.bundle_id, "a1_test_pack_1")
        self.assertEqual(it.confidence, "high")

    def test_vocab_word_over2_word_move_no_pack_override(self):
        it = self.by_kind_id[("vocab", "vocab_a1_0003")]  # 회의 in pack1, pack delta 0.5
        self.assertEqual(it.delta, 2)
        self.assertEqual(it.bucket, "over2")
        self.assertEqual(it.reason, "over2")
        self.assertEqual(it.suggested_action, "word_move")
        self.assertEqual(it.blocked_by, "")
        self.assertEqual(it.confidence, "high")

    def test_vocab_word_over1_step_up_and_satz_blocked(self):
        it = self.by_kind_id[("vocab", "vocab_a1_0004")]  # 공원
        self.assertEqual(it.delta, 1)
        self.assertEqual(it.bucket, "over1")
        self.assertEqual(it.reason, "over1")
        self.assertEqual(it.suggested_action, "step_up_or_swap")
        self.assertEqual(it.blocked_by, "satz_ref")

    # -- R4 item 4: confidence-aware fallback_over2 -----------------------

    def test_vocab_low_confidence_over2_becomes_fallback_over2(self):
        it = self.by_kind_id[("vocab", "vocab_a1_0005")]  # 사전, basic2023/low, delta+5
        self.assertEqual(it.grade, 6)
        self.assertEqual(it.delta, 5)
        self.assertEqual(it.confidence, "low")
        self.assertEqual(it.bucket, "fallback_over2")
        self.assertEqual(it.suggested_action, "review_fallback")
        self.assertIn("fallback:basic2023", it.reason)

    def test_vocab_number_headword_is_kept_not_unknown(self):
        # R4 item 4: "proper nouns and numbers are neither unknown nor
        # graded" -- a bare-digit headword resolves grade=None via
        # source='number', which must NOT be flagged reason="unknown".
        it = self.by_kind_id[("vocab", "vocab_a1_0006")]  # "10"
        self.assertIsNone(it.grade)
        self.assertEqual(it.bucket, "")
        self.assertEqual(it.reason, "")
        self.assertEqual(it.suggested_action, "keep")
        self.assertEqual(it.unknown_count, 0)

    def test_fallback_over2_exempt_from_pack_override(self):
        it = self.by_kind_id[("vocab", "vocab_a1_0007")]  # 사전 in pack3
        self.assertEqual(it.bucket, "fallback_over2")
        # pack3's high+medium-confidence median (4.0, from 정책 alone) is
        # >=2 and DOES trigger the pack override below (as
        # 'insufficient_sample', R4b item 2 guard -- n_hm=1 < 6), but a
        # fallback_over2 row must stay 'review_fallback' regardless of
        # which override action the pack gets -- overriding an explicit
        # "our own confidence is shaky, a human must look" signal would
        # defeat its purpose (R4 item 4 design decision, documented on
        # apply_pack_overrides).
        self.assertEqual(it.suggested_action, "review_fallback")
        self.assertIn("fallback:basic2023", it.reason)

    # -- R4b item 2b: medium confidence is usable evidence, not fallback --

    def test_vocab_medium_confidence_over2_gets_normal_action_with_src_reason(self):
        it = self.by_kind_id[("vocab", "vocab_a1_0009")]  # 회의계약, compound split
        self.assertEqual(it.grade, 3)
        self.assertEqual(it.estimate, "b1")
        self.assertEqual(it.delta, 2)
        self.assertEqual(it.confidence, "medium")
        # NOT fallback_over2/review_fallback -- medium is usable evidence
        # now, so this gets the ordinary vocab over2 action, same as a
        # high-confidence over2 word would.
        self.assertEqual(it.bucket, "over2")
        self.assertEqual(it.suggested_action, "word_move")
        # ... but the reason still names the source, so a reviewer can see
        # this isn't a bare kiiq hit.
        self.assertEqual(it.reason, "over2 src=compound")

    def test_vocab_kept_delta_via_alias_multiword_resolution(self):
        # 남자친구 (R4b item 1's coverage fixture row) resolves through the
        # SAME alias redirect as the coverage test, but via phrase_grade
        # (grade_vocab's own grading path) rather than word_grade -- its
        # OWN item grade/delta must still come out sane (grade1/A1,
        # delta=1-2=-1, kept), independent of what compute_coverage does
        # with the row.
        it = self.by_kind_id[("vocab", "vocab_a2_0003")]
        self.assertEqual(it.level, "a2")
        self.assertEqual(it.grade, 1)
        self.assertEqual(it.estimate, "a1")
        self.assertEqual(it.delta, -1)
        self.assertEqual(it.bucket, "")
        self.assertEqual(it.suggested_action, "keep")
        self.assertEqual(it.confidence, "high")

    def test_pack3_insufficient_sample_still_applies_to_high_confidence_sibling(self):
        # R4b item 2 guard: pack3's median (4.0, from 정책 alone) still
        # clears >=2, but n_hm=1 is under the 6-usable-word floor, so the
        # override lands as 'insufficient_sample', not 'bundle_move' --
        # renamed from test_pack3_override_still_applies_to_high_confidence_sibling.
        it = self.by_kind_id[("vocab", "vocab_a1_0008")]  # 정책 in pack3
        self.assertEqual(it.bucket, "over2")
        self.assertEqual(it.confidence, "high")
        self.assertEqual(it.suggested_action, "insufficient_sample")

    def test_pack2_median_ge_plus2_but_insufficient_sample(self):
        # R4b item 2 guard: pack2's median delta (2.0) still clears the
        # >=2 threshold, but n_hm=2 is under the six-usable-word floor, so
        # BOTH words get 'insufficient_sample' instead of a blanket
        # bundle_move -- renamed from
        # test_pack2_median_ge_plus2_forces_bundle_move_on_both_words; see
        # ApplyPackOverridesGuardTest for the n_hm>=6 case where
        # bundle_move still fires.
        it_low = self.by_kind_id[("vocab", "vocab_a2_0001")]  # 회의, individual delta+1
        it_high = self.by_kind_id[("vocab", "vocab_a2_0002")]  # 정책, individual delta+3
        self.assertEqual(it_low.delta, 1)
        self.assertEqual(it_high.delta, 3)
        self.assertEqual(it_low.suggested_action, "insufficient_sample")
        self.assertEqual(it_high.suggested_action, "insufficient_sample")
        self.assertEqual(it_low.blocked_by, "can_do_ref")
        self.assertEqual(it_high.blocked_by, "can_do_ref")

    def test_pack_stats(self):
        # R4 item 4 / R4b item 2a: n_words counts every pack word; n_hm
        # (was n_high)/median_delta/share_ge_plus2 count HIGH+MEDIUM
        # confidence words (n_low is the low-confidence count, new in
        # R4b). pack1 gains a 5th word (사전, low-conf) but n_hm/median/
        # share are unchanged from the pre-R4 4-word numbers -- proof the
        # low-conf word is excluded, not just coincidentally absent. None
        # of pack1/2/3's OWN words are medium-confidence, so item 2a's
        # "medium now counts too" doesn't change these VALUES, only the
        # field name -- see ApplyPackOverridesGuardTest for a pack that
        # actually contains a medium-confidence word.
        p1 = self.result.pack_stats["a1_test_pack_1"]
        self.assertEqual(p1.n_words, 5)
        self.assertEqual(p1.n_hm, 4)
        self.assertEqual(p1.n_low, 1)
        self.assertAlmostEqual(p1.median_delta, 0.5)
        self.assertAlmostEqual(p1.share_ge_plus2, 0.25)
        p2 = self.result.pack_stats["a2_test_pack_1"]
        self.assertEqual(p2.n_words, 2)
        self.assertEqual(p2.n_hm, 2)
        self.assertEqual(p2.n_low, 0)
        self.assertAlmostEqual(p2.median_delta, 2.0)
        self.assertAlmostEqual(p2.share_ge_plus2, 0.5)
        p3 = self.result.pack_stats["a1_test_pack_3"]
        self.assertEqual(p3.n_words, 2)
        self.assertEqual(p3.n_hm, 1)  # only 정책; 사전 (low-conf) excluded
        self.assertEqual(p3.n_low, 1)
        self.assertAlmostEqual(p3.median_delta, 4.0)
        self.assertAlmostEqual(p3.share_ge_plus2, 1.0)

    # -- bundle_id (cloze/satz) ------------------------------------------------

    def test_cloze_bundle_id_matches_vocab_example(self):
        it = self.by_kind_id[("cloze", "cloze_a1_0001")]
        self.assertEqual(it.delta, 0)
        self.assertEqual(it.bundle_id, "a1_test_pack_1")

    def test_cloze_over2_no_bundle_match_and_can_do_blocked(self):
        it = self.by_kind_id[("cloze", "cloze_a1_0002")]
        self.assertEqual(it.delta, 2)
        self.assertEqual(it.bucket, "over2")
        self.assertEqual(it.reason, "over2 lex_p90=3.0")
        self.assertEqual(it.bundle_id, "")
        self.assertEqual(it.blocked_by, "can_do_ref")
        self.assertEqual(it.suggested_action, "bundle_move")

    def test_satz_bundle_id_matches_vocab_example(self):
        it = self.by_kind_id[("satz", "satz_a1_0001")]
        self.assertEqual(it.delta, 0)
        self.assertEqual(it.bundle_id, "a1_test_pack_1")

    def test_satz_over2_and_can_do_blocked(self):
        it = self.by_kind_id[("satz", "satz_a1_0002")]
        self.assertEqual(it.delta, 4)
        self.assertEqual(it.bucket, "over2")
        self.assertEqual(it.reason, "over2 lex_p90=5.0")
        self.assertEqual(it.blocked_by, "can_do_ref")

    # -- grammar / scenario / smalltalk / pronunciation / media ---------------

    def test_grammar_over2_and_can_do_blocked(self):
        it = self.by_kind_id[("grammar", "grammar_a1_hard")]
        self.assertEqual(it.delta, 2)
        self.assertEqual(it.bucket, "over2")  # 계약 is kiiq/high-conf -- NOT fallback
        self.assertEqual(it.reason, "over2 lex_p90=3.0")
        self.assertEqual(it.blocked_by, "can_do_ref")
        self.assertEqual(it.suggested_action, "bundle_move")

    def test_grammar_matched_level_is_kept(self):
        it = self.by_kind_id[("grammar", "grammar_b1_meeting")]
        self.assertEqual(it.delta, 0)
        self.assertEqual(it.bucket, "")
        self.assertEqual(it.reason, "")

    def test_grammar_low_confidence_over2_becomes_fallback(self):
        # R4 items 4+5: example_korean="사전" (basic2023/low) -> lex_p90
        # capped to 3.0, delta=+2 over2 raw, but low-confidence -> reason
        # must contain BOTH the fallback source and the driving factor.
        it = self.by_kind_id[("grammar", "grammar_a1_fallback")]
        self.assertEqual(it.delta, 2)
        self.assertEqual(it.bucket, "fallback_over2")
        self.assertEqual(it.suggested_action, "review_fallback")
        self.assertIn("fallback:basic2023", it.reason)
        self.assertIn("lex_p90=3.0", it.reason)

    def test_grammar_medium_confidence_stays_over2_not_fallback(self):
        # R4b item 2c: example_korean="회의계약" resolves via the same
        # last-resort compound split as vocab_a1_0009 (confidence=
        # 'medium', not 'low') -> lex_p90=3.0 (medium capped at grade 4,
        # unchanged capping logic), delta=+2 over2 raw. Only a LOW token
        # now triggers the fallback label, so this must stay a plain
        # 'over2' with the ordinary factor-only reason (no 'src=' -- R4b
        # item 2b's source-naming is scoped to vocab, not sentence
        # surfaces).
        it = self.by_kind_id[("grammar", "grammar_a1_medium")]
        self.assertEqual(it.delta, 2)
        self.assertEqual(it.confidence, "medium")
        self.assertEqual(it.bucket, "over2")
        self.assertEqual(it.suggested_action, "bundle_move")
        self.assertEqual(it.reason, "over2 lex_p90=3.0")

    def test_scenario_estimate_and_delta(self):
        it = self.by_kind_id[("scenario", "scn_test_1")]
        self.assertEqual(it.estimate, "b1")
        self.assertEqual(it.level, "a1")
        self.assertEqual(it.delta, 2)
        self.assertEqual(it.bucket, "over2")
        # dialog p75(1,1,5)=3.0 ties grammarIds max(회의체/B1=3) -- grammar
        # wins ties (deterministic, rule-based signal) per _sentence_verdict
        # / scenario grading's identical tie-break.
        self.assertEqual(it.reason, "over2 grammar_ids_max=3")
        self.assertEqual(it.blocked_by, "can_do_ref")

    def test_smalltalk_takes_max_over_ko_reply_followup(self):
        easy = self.by_kind_id[("smalltalk", "smalltalk_a1_0001")]
        self.assertEqual(easy.delta, 0)
        self.assertEqual(easy.bucket, "")
        hard = self.by_kind_id[("smalltalk", "smalltalk_a1_0002")]
        self.assertEqual(hard.estimate, "c1")
        self.assertEqual(hard.delta, 4)
        self.assertEqual(hard.bucket, "over2")
        self.assertEqual(hard.reason, "over2 lex_p90=5.0")
        self.assertEqual(hard.blocked_by, "can_do_ref")

    def test_pronunciation_unknown_reason(self):
        it = self.by_kind_id[("pronunciation", "pronunciation_a1_0003")]
        self.assertIsNone(it.grade)
        self.assertEqual(it.bucket, "unknown")
        self.assertEqual(it.reason, "unknown")
        self.assertEqual(it.suggested_action, "keep")
        # pronunciation has no can-do kind counterpart -> always unblocked
        self.assertEqual(it.blocked_by, "")
        self.assertIsNone(it.confidence)

    def test_media_level_is_normalized_lowercase(self):
        it = self.by_kind_id[("media", "media_a1_0002")]
        self.assertEqual(it.level, "a1")  # normalized lowercase regardless of source "A1" casing
        self.assertEqual(it.delta, 4)
        self.assertEqual(it.bucket, "over2")
        self.assertEqual(it.reason, "over2 lex_p90=5.0")

    # -- matrix / summary / coverage ------------------------------------------------

    def test_matrix_vocab_a1_row(self):
        # Every level=A1 vocab row: pack1 (사과 g1, 학교 g1, 회의 g3, 공원 g2,
        # 사전 g6) + standalone "10" (grade=None, source='number' -> no
        # estimate -> UNK, regardless of its bucket -- the matrix's UNK
        # column tracks "no estimate produced", a different concept from
        # the suspects bucket) + pack3 (사전 g6, 정책 g5) + standalone
        # 회의계약 (R4b item 2b: compound-split g3/B1 -- 남자친구 is level A2,
        # so it does NOT land in this "a1" row).
        all_items = [it for items in self.result.items_by_kind.values() for it in items]
        matrix = acl.build_matrix(all_items)
        row = matrix["vocab"]["a1"]
        self.assertEqual(row["a1"], 2)   # 사과, 학교
        self.assertEqual(row["a2"], 1)   # 공원
        self.assertEqual(row["b1"], 2)   # 회의 + 회의계약
        self.assertEqual(row["c1"], 1)   # 정책 (pack3)
        self.assertEqual(row["c2"], 2)   # 사전 (pack1) + 사전 (pack3)
        self.assertEqual(row["UNK"], 1)  # "10"
        self.assertEqual(row["TOTAL"], 9)

    def test_summary_counts_and_packs_and_coverage(self):
        summary = acl.build_summary(self.result, "fixture")
        self.assertEqual(
            summary["counts"]["vocab"],
            # R4b items 1+2: +1 kept (남자친구, delta-1) doesn't move any
            # bucket count but does raise total; +1 over2 (회의계약, medium
            # confidence, now counted directly as over2 instead of
            # fallback_over2 -- item 2b) raises total again and over2 by 1.
            # fallback_over2 stays 2 -- unchanged, both are still the LOW-
            # confidence 사전 rows.
            {"over2": 4, "over1": 2, "under2": 0, "unknown": 0, "fallback_over2": 2, "total": 12},
        )
        self.assertEqual(
            summary["counts"]["grammar"],
            # R4b item 2c: +1 over2 (grammar_a1_medium, medium confidence,
            # stays plain over2 instead of fallback_over2).
            {"over2": 2, "over1": 0, "under2": 0, "unknown": 0, "fallback_over2": 1, "total": 5},
        )
        self.assertEqual(
            summary["counts"]["pronunciation"],
            {"over2": 1, "over1": 0, "under2": 0, "unknown": 1, "fallback_over2": 0, "total": 3},
        )
        self.assertEqual(
            summary["packs"],
            # pack1/2/3 contain no medium-confidence words of their own,
            # so R4b item 2a's high+medium median/share VALUES are
            # unchanged from high-only -- only the field name (n_high ->
            # n_hm) and the new n_low field differ from the pre-R4b
            # fixture. 남자친구/회의계약 are both pack_id="" (standalone),
            # so they never enter a pack's stats at all.
            {
                "a1": {
                    "median_ge_plus2": 1,  # pack3 (4.0); pack1 (0.5) does not qualify
                    "share_ge_plus2_top10": [
                        {"pack_id": "a1_test_pack_3", "median": 4.0, "share_ge_plus2": 1.0, "n_hm": 1, "n_low": 1},
                        {"pack_id": "a1_test_pack_1", "median": 0.5, "share_ge_plus2": 0.25, "n_hm": 4, "n_low": 1},
                    ],
                },
                "a2": {
                    "median_ge_plus2": 1,
                    "share_ge_plus2_top10": [
                        {"pack_id": "a2_test_pack_1", "median": 2.0, "share_ge_plus2": 0.5, "n_hm": 2, "n_low": 0},
                    ],
                },
            },
        )
        self.assertEqual(
            summary["coverage"]["grade1"],
            # R4b item 1: total_unique grows 3->4 (우유 added, see fixture
            # comment); present_in_app grows 2->3 -- 친구 is now present via
            # 남자친구's resolved-lemma match even though no row's raw
            # `korean` is ever literally "친구" -- but at_level stays 2
            # (that row's OWN level is A2, not A1, so 친구 doesn't count as
            # at_level for grade1's A1 target). missing drops to 1 (우유
            # alone).
            {"total_unique": 4, "present_in_app": 3, "at_level": 2, "missing": 1},
        )
        self.assertEqual(
            summary["coverage"]["grade2"],
            # unaffected: 남자친구/회의계약's resolved-lemma parts (남자/친구,
            # 회의/계약) never include 공원 (grade2's only headword).
            {"total_unique": 1, "present_in_app": 1, "at_level": 0, "missing": 0},
        )
        self.assertEqual(summary["generatedFrom"], "fixture")

    def test_coverage_missing_word_grouped_by_pos(self):
        # R4b item 1: 친구 is no longer missing (see
        # test_summary_counts_and_packs_and_coverage) -- 우유 is now the
        # fixture's one genuinely-missing grade1 headword.
        cov = self.result.coverage["grade1"]
        self.assertEqual(cov.missing_words_by_pos, {"명사": ["우유"]})

    def test_coverage_present_via_resolved_lemma_not_literal_string(self):
        # R4b item 1, isolated from the aggregate summary/missing-words
        # assertions above: 친구 must be `present_in_app` even though NO
        # vocab row's raw `korean` field is ever literally "친구" -- only
        # vocab_a2_0003's ("남자친구") RESOLVED lemma ("남자 친구" -> split on
        # ' ' -> "친구") reaches it. Its supplying row's own level (A2) is
        # not grade1's target (A1), so 친구 must NOT count as `at_level`
        # -- present-in-app and at-level are genuinely different sets
        # under this rule, not just two names for the same thing.
        cov = self.result.coverage["grade1"]
        self.assertEqual(cov.present_in_app, 3)
        self.assertEqual(cov.at_level, 2)
        self.assertNotIn("친구", cov.missing_words_by_pos.get("명사", []))

    def test_coverage_dedupes_split_rows_across_grades(self):
        # R4 item 2: 공원 is listed at BOTH grade 2 and grade 5 in the
        # fixture kiiq CSV. Its minimum grade (2) is where it must be
        # counted; grade 5's coverage must NOT also count it (only 정책
        # belongs there) -- proves split-row dedup, not just a coincidence
        # (a buggy per-row filter would count grade5.total_unique as 2).
        cov5 = acl.compute_coverage(self.corpus, 5, "C1")
        self.assertEqual(cov5.total_unique, 1)
        self.assertEqual(cov5.present_in_app, 1)  # 정책 is in korean_vocab.csv
        self.assertEqual(cov5.missing_words_by_pos, {})

    # -- suspects CSV / summary json / report md plumbing ---------------------

    def test_write_suspects_csv_header_and_row_count_and_sort_order(self):
        out = self.root / "content_level_suspects.csv"
        acl.write_suspects_csv(out, self.result)
        with out.open(encoding="utf-8", newline="") as fh:
            rows = list(csv.reader(fh))
        self.assertEqual(rows[0], list(acl.SUSPECTS_HEADER))
        body = rows[1:]
        # 8 vocab (+1 회의계약, R4b item 2b) + 3 grammar (hard + fallback +
        # 회의계약패턴, R4b item 2c) + 1 scenario + 1 cloze + 1 satz +
        # 1 smalltalk + 2 pronunciation (over2 + unknown) + 1 media = 18
        # total. 남자친구 (R4b item 1) is bucket="" (kept) and never a
        # suspect, so it does not add a row here.
        self.assertEqual(len(body), 18)
        kind_id_pairs = [(r[0], r[1]) for r in body]
        self.assertEqual(kind_id_pairs, sorted(kind_id_pairs))
        # every row is a genuine suspect whose reason starts with its
        # bucket name (over2/over1/under2/unknown/fallback_over2) -- R4
        # items 4-5 make `reason` a richer string than a bare bucket name,
        # so this checks the prefix rather than exact membership.
        for row in body:
            reason = row[5]
            self.assertTrue(
                any(reason == b or reason.startswith(b + " ") or reason.startswith(b + ":")
                    for b in acl.REASON_BUCKETS),
                f"reason {reason!r} does not start with a known bucket",
            )
        # every level/estimate value in the CSV is lowercase (R4 item 3)
        for row in body:
            self.assertEqual(row[2], row[2].lower())  # level
            self.assertEqual(row[3], row[3].lower())  # estimate

    def test_write_summary_json_roundtrip(self):
        summary = acl.build_summary(self.result, "fixture")
        out = self.root / "content_level_summary.json"
        acl.write_summary_json(out, summary)
        loaded = json.loads(out.read_text(encoding="utf-8"))
        self.assertEqual(loaded, summary)

    def test_write_report_md_contains_golden_layout_header(self):
        summary = acl.build_summary(self.result, "fixture")
        out = self.root / "content_level_report.md"
        acl.write_report_md(out, self.result, summary)
        text = out.read_text(encoding="utf-8")
        # fixed column-header labels stay uppercase (a table header, not a
        # per-item data value -- R4 item 3 only lowercases DATA)
        self.assertIn("| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |", text)
        self.assertIn("A1/A2 팩", text)
        self.assertIn("1급 (A1 목표)", text)
        self.assertIn("scn_test_1", text)
        self.assertNotIn("kcenter", text)  # R4 item 1
        # R4 item 3: data rows show lowercase level/estimate
        self.assertIn("`scn_test_1` | a1 | b1 | 2 |", text)

    def test_write_report_md_contains_unknown_ratio_section(self):
        # R4 item 7: unknown-token ratio per surface must be visible.
        summary = acl.build_summary(self.result, "fixture")
        out = self.root / "content_level_report.md"
        acl.write_report_md(out, self.result, summary)
        text = out.read_text(encoding="utf-8")
        self.assertIn("미검출 토큰", text)
        self.assertIn("pronunciation", text)

    def test_write_report_md_pack_table_and_insufficient_sample_section(self):
        # R4b item 2a/guard: the main pack table's header names n_hm/n_low
        # (not n_high), and packs whose override would otherwise be
        # bundle_move but whose n_hm is under 6 (pack2, pack3 here) appear
        # in a separate small table instead of being silently folded into
        # bundle_move.
        summary = acl.build_summary(self.result, "fixture")
        out = self.root / "content_level_report.md"
        acl.write_report_md(out, self.result, summary)
        text = out.read_text(encoding="utf-8")
        self.assertIn("n_hm", text)
        self.assertIn("n_low", text)
        self.assertNotIn("n_high", text)
        self.assertIn("표본 부족", text)
        self.assertIn("a2_test_pack_1", text)
        self.assertIn("a1_test_pack_3", text)


class ResolvedLemmaKeysTest(unittest.TestCase):
    """R4b item 1: isolated tests for `_resolved_lemma_keys`, the coverage
    present_in_app helper -- a tiny hand-built CefrLexicon (not the full
    corpus fixture) so each splitting/stripping rule is checked directly,
    independent of the larger FixtureAuditTest wiring."""

    @classmethod
    def setUpClass(cls) -> None:
        kiiq_rows = [
            {"grade": "1", "headword": "친구", "homograph": "0"},
            {"grade": "1", "headword": "친구", "homograph": "1"},  # 2 homographs -> matched suffix
            {"grade": "1", "headword": "학교", "homograph": "0"},
            {"grade": "3", "headword": "회의", "homograph": "0"},
            {"grade": "3", "headword": "계약", "homograph": "0"},
        ]
        alias_rows = [{"app_form": "남자친구", "lexicon_form": "남자 친구", "note": ""}]
        cls.lexicon = acl.CefrLexicon.from_rows(kiiq_rows, [], alias_rows)

    def test_exact_single_match_has_no_suffix(self):
        self.assertEqual(acl._resolved_lemma_keys(self.lexicon, "학교"), ["학교"])

    def test_homograph_suffix_is_stripped(self):
        # 친구 has 2 homograph rows -> word_grade("친구").matched ==
        # "친구(h0,h1)"; the coverage key must be the bare headword, not
        # the annotated match string.
        self.assertEqual(acl._resolved_lemma_keys(self.lexicon, "친구"), ["친구"])

    def test_multiword_alias_match_splits_on_space(self):
        # 남자친구 -> alias lexicon_form "남자 친구" (남자 itself never
        # resolves; 친구 alone provides the grade) -> matched == "남자 친구"
        # (space-joined, kept verbatim by _alias_lookup) -> split into
        # parts so headword "친구" can match one of them, never the joined
        # whole "남자 친구".
        self.assertEqual(acl._resolved_lemma_keys(self.lexicon, "남자친구"), ["남자", "친구"])

    def test_compound_split_match_splits_on_plus(self):
        # "회의계약" resolves via the last-resort 2-way compound split
        # (회의+계약, both independently kiiq headwords) -> matched ==
        # "회의+계약" -> split on '+'.
        self.assertEqual(acl._resolved_lemma_keys(self.lexicon, "회의계약"), ["회의", "계약"])

    def test_unresolvable_word_returns_no_keys(self):
        self.assertEqual(acl._resolved_lemma_keys(self.lexicon, "가나다라마바사"), [])


class ApplyPackOverridesGuardTest(unittest.TestCase):
    """R4b item 2: isolated tests for `apply_pack_overrides`'s high+medium
    median/share computation and the new insufficient_sample guard --
    hand-built Item/vocab_row lists (not the full corpus fixture), since
    none of FixtureAuditTest's own packs happen to contain a medium-
    confidence word or reach the 6-usable-word floor."""

    @staticmethod
    def _item(id_, grade, confidence, delta, bucket, bundle_id, level="a1"):
        return acl.Item(
            kind="vocab", id=id_, level=level, grade=grade, estimate=None, delta=delta,
            blocked_by="", bundle_id=bundle_id, bucket=bucket, reason=bucket,
            suggested_action=acl._default_action("vocab", bucket), confidence=confidence,
            token_count=1, unknown_count=0,
        )

    def test_median_and_share_use_high_and_medium_exclude_low(self):
        items = [
            self._item("w1", grade=3, confidence="high", delta=2, bucket="over2", bundle_id="px"),
            self._item("w2", grade=4, confidence="medium", delta=3, bucket="over2", bundle_id="px"),
            self._item("w3", grade=6, confidence="low", delta=5, bucket="fallback_over2", bundle_id="px"),
        ]
        vocab_rows = [{"pack_id": "px", "level": "A1"}]
        new_items, pack_stats = acl.apply_pack_overrides(items, vocab_rows)
        p = pack_stats["px"]
        self.assertEqual(p.n_words, 3)
        self.assertEqual(p.n_hm, 2)     # w1, w2 (high+medium)
        self.assertEqual(p.n_low, 1)    # w3
        self.assertAlmostEqual(p.median_delta, 2.5)   # median([3,4])=3.5, rank(A1)=1 -> 2.5
        self.assertAlmostEqual(p.share_ge_plus2, 1.0)  # both w1,w2 have delta>=2

    def test_insufficient_sample_when_usable_words_under_six(self):
        items = [
            self._item("w1", grade=3, confidence="high", delta=2, bucket="over2", bundle_id="px"),
            self._item("w2", grade=4, confidence="medium", delta=3, bucket="over2", bundle_id="px"),
            self._item("w3", grade=6, confidence="low", delta=5, bucket="fallback_over2", bundle_id="px"),
        ]
        vocab_rows = [{"pack_id": "px", "level": "A1"}]
        new_items, _pack_stats = acl.apply_pack_overrides(items, vocab_rows)
        by_id = {it.id: it for it in new_items}
        self.assertEqual(by_id["w1"].suggested_action, "insufficient_sample")
        self.assertEqual(by_id["w2"].suggested_action, "insufficient_sample")
        # a fallback_over2 row stays exempt regardless of which override
        # action the pack gets.
        self.assertEqual(by_id["w3"].suggested_action, "review_fallback")

    def test_bundle_move_still_fires_when_sample_is_sufficient(self):
        items = [
            self._item(f"w{i}", grade=5, confidence="high", delta=4, bucket="over2", bundle_id="py")
            for i in range(6)
        ]
        vocab_rows = [{"pack_id": "py", "level": "A1"}]
        new_items, pack_stats = acl.apply_pack_overrides(items, vocab_rows)
        p = pack_stats["py"]
        self.assertEqual(p.n_hm, 6)
        self.assertGreaterEqual(p.median_delta, 2)
        for it in new_items:
            self.assertEqual(it.suggested_action, "bundle_move")

    def test_no_override_when_median_below_threshold(self):
        items = [self._item("w1", grade=2, confidence="high", delta=1, bucket="over1", bundle_id="pz")]
        vocab_rows = [{"pack_id": "pz", "level": "A1"}]
        new_items, pack_stats = acl.apply_pack_overrides(items, vocab_rows)
        self.assertAlmostEqual(pack_stats["pz"].median_delta, 1.0)  # grade2 - rank1, below the >=2 threshold
        self.assertEqual(new_items[0].suggested_action, "step_up_or_swap")  # untouched, own bucket action


class CliTest(unittest.TestCase):
    def test_draft_flag_raises_not_yet_supported(self):
        with self.assertRaises(NotImplementedError) as ctx:
            acl.main(["--draft", "some_manifest.json"])
        self.assertIn("not yet supported", str(ctx.exception))


class LiveRatchetTest(unittest.TestCase):
    """Ratchet against the real repo's tool/content_level_summary.json —
    lower-only caps (2026-09-07 R4b baseline: item 2's confidence-policy
    change moves every MEDIUM-confidence item that was previously
    reclassified fallback_over2 back into its ordinary over2/bundle_move
    bucket -- CAP_OVER2 rises and CAP_FALLBACK_OVER2 falls by EXACTLY the
    same amount per kind (verified: over2+fallback_over2 together is
    invariant across this rework for every single kind, e.g. vocab
    220+151=371 (R4) == 265+106=371 (R4b) -- this is a relabelling, not a
    net change in flagged items). Run `python tool/audit_content_levels.py`
    first to regenerate the summary."""

    # 2026-09-07 R4b 실측 (`python tool/audit_content_levels.py --json` 출력).
    # 하향 전용 — 상한은 내려갈 수만 있다, 절대 올리지 마라. over2 is now
    # HIGH-or-MEDIUM-confidence by construction (R4b item 2) -- only a LOW
    # >=+2 verdict counts under CAP_FALLBACK_OVER2 instead, see below.
    CAP_OVER2 = {
        "vocab": 265, "grammar": 10, "scenario": 7, "cloze": 241,
        "satz": 273, "smalltalk": 61, "pronunciation": 8, "media": 20,
    }
    # 실측 unknown/total: vocab .0240, 나머지 0 -- unchanged by R4b (items 1/2
    # don't touch which tokens/items resolve to grade=None). +0.01 여유는
    # 브리프 지시(래칫 조건) 그대로.
    CAP_UNKNOWN_RATIO = {
        "vocab": 0.0240, "grammar": 0.0, "scenario": 0.0, "cloze": 0.0,
        "satz": 0.0, "smalltalk": 0.0, "pronunciation": 0.0, "media": 0.0,
    }
    # R4b item 2 guard (insufficient_sample) doesn't change HOW MANY a1/a2
    # packs clear the median>=+2 threshold, only what suggested_action
    # those packs get -- both caps happen to measure the same (6) as the
    # pre-R4b baseline.
    CAP_PACK_A1_MEDIAN_GE_PLUS2 = 6
    CAP_PACK_A2_MEDIAN_GE_PLUS2 = 6
    # R4b item 2 실측 2026-09-07 -- every kind's fallback_over2 falls by
    # exactly its own over2 rise above (see class docstring).
    CAP_FALLBACK_OVER2 = {
        "vocab": 106, "grammar": 2, "scenario": 0, "cloze": 19,
        "satz": 16, "smalltalk": 3, "pronunciation": 0, "media": 3,
    }

    @classmethod
    def setUpClass(cls) -> None:
        summary_path = REPO / "tool" / "content_level_summary.json"
        if not summary_path.exists():
            raise unittest.SkipTest(
                "tool/content_level_summary.json missing — run "
                "`python tool/audit_content_levels.py` first."
            )
        cls.summary = json.loads(summary_path.read_text(encoding="utf-8"))

    def test_over2_counts_do_not_regress(self):
        for kind, cap in self.CAP_OVER2.items():
            with self.subTest(kind=kind):
                over2 = self.summary["counts"][kind]["over2"]
                self.assertLessEqual(over2, cap, f"{kind}.over2={over2} exceeds cap {cap}")

    def test_unknown_ratio_does_not_regress(self):
        for kind, cap in self.CAP_UNKNOWN_RATIO.items():
            with self.subTest(kind=kind):
                c = self.summary["counts"][kind]
                ratio = c["unknown"] / c["total"] if c["total"] else 0.0
                self.assertLessEqual(ratio, cap + 0.01, f"{kind} unknown ratio {ratio:.3f} exceeds cap {cap}")

    def test_pack_median_ge_plus2_does_not_regress(self):
        a1 = self.summary["packs"]["a1"]["median_ge_plus2"]
        a2 = self.summary["packs"]["a2"]["median_ge_plus2"]
        self.assertLessEqual(a1, self.CAP_PACK_A1_MEDIAN_GE_PLUS2)
        self.assertLessEqual(a2, self.CAP_PACK_A2_MEDIAN_GE_PLUS2)

    def test_fallback_over2_counts_do_not_regress(self):
        for kind, cap in self.CAP_FALLBACK_OVER2.items():
            with self.subTest(kind=kind):
                n = self.summary["counts"][kind]["fallback_over2"]
                self.assertLessEqual(n, cap, f"{kind}.fallback_over2={n} exceeds cap {cap}")

    def test_pack_top10_entries_have_expected_shape(self):
        # R4b item 2a: n_high renamed to n_hm (high+medium), n_low added.
        for level in ("a1", "a2"):
            for entry in self.summary["packs"][level]["share_ge_plus2_top10"]:
                self.assertEqual(
                    set(entry), {"pack_id", "median", "share_ge_plus2", "n_hm", "n_low"},
                )


if __name__ == "__main__":
    unittest.main()
