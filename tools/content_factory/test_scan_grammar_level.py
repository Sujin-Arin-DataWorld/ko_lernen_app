#!/usr/bin/env python3
"""Tests for scan_grammar_level.py (C2b-2, 2026-09-15):
  - A1 mode parity against the legacy scan_a1_grammar.py detector functions
    (same allowlists, same manual ids -- see module docstring).
  - The new -(으)ㄹ래요 (volitional, A2-legal) vs -(으)래요 (reported
    contraction, grade4) discriminator added for the A2 `grammar_b2_
    quoted_contractions` false positive found while building this scanner.
  - Live ratchet: current A2 corpus has 0 grade>=3 hits (vocab/cloze/satz).
"""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool"))
sys.path.insert(0, str(ROOT / "tools" / "content_factory"))

import scan_a1_grammar as legacy  # noqa: E402
import scan_grammar_level as S  # noqa: E402
from cefr_lexicon import CefrLexicon, GrammarIndex  # noqa: E402


class VolitionalVsReportedContractionTest(unittest.TestCase):
    """grammar_b2_quoted_contractions (assets/data/grammar.csv) is matched
    as a bare "래요"/"대요" substring and cannot itself tell -(으)ㄹ래요
    (A2-legal volitional) apart from -(으)래요 (grade4 reported-imperative
    contraction) -- verified empirically against both classes before this
    discriminator was added (see scan_grammar_level.py's own docstring)."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.lexicon = CefrLexicon.load(ROOT)
        cls.grammar_index = GrammarIndex.load(ROOT)

    def _hits_ge3(self, text: str):
        return S._grammar_hits_ge(self.lexicon, self.grammar_index, text, threshold=3)

    def test_volitional_l_raeyo_after_vowel_stem_not_flagged(self):
        # 쉬다 -> 쉴래요 ("I'd rather rest") -- ㄹ batchim fused into 쉴.
        hits = self._hits_ge3("오늘은 그냥 집에서 쉴래요.")
        self.assertFalse(
            any(h.pattern_id == "grammar_b2_quoted_contractions" for h in hits),
            "volitional -ㄹ래요 must not be flagged as the reported contraction",
        )

    def test_volitional_eul_raeyo_after_consonant_stem_not_flagged(self):
        # 입다 -> 입을래요 ("I'll wear") -- 을 syllable's own jongseong is ㄹ.
        hits = self._hits_ge3("오늘은 회색 코트 입을래요.")
        self.assertFalse(
            any(h.pattern_id == "grammar_b2_quoted_contractions" for h in hits),
            "volitional -을래요 must not be flagged as the reported contraction",
        )

    def test_reported_contraction_raeyo_still_flagged(self):
        # 두다 -> 두래요 ("they say to leave it") -- no ㄹ before 래요.
        hits = self._hits_ge3("세배 영상은 가족 앨범에만 두래요.")
        self.assertTrue(
            any(h.pattern_id == "grammar_b2_quoted_contractions" for h in hits),
            "reported -(으)래요 must still be flagged at the A2 (grade>=3) threshold",
        )

    def test_reported_contraction_raeyo_after_haeda_stem_still_flagged(self):
        # 말하다 -> 말하래요 -- vowel stem, no ㄹ before 래요.
        hits = self._hits_ge3("보름달을 보면서 소원을 말해요.")
        self.assertFalse(hits, "sentence was rewritten to remove the reported form")
        hits_orig = self._hits_ge3("보름달을 보며 소원을 말하래요.")
        self.assertTrue(
            any(h.pattern_id == "grammar_b2_quoted_contractions" for h in hits_orig),
        )

    def test_daeyo_statement_contraction_still_flagged(self):
        # -대요 has no volitional homograph at all -- always a real hit.
        hits = self._hits_ge3("내일 온대요.")
        self.assertTrue(
            any(h.pattern_id == "grammar_b2_quoted_contractions" for h in hits),
        )


class A1ParityTest(unittest.TestCase):
    """--level A1 must reproduce the legacy scan_a1_grammar.py script's own
    flagged-row counts against the live corpus (same allowlists, same
    manual ids, only the module they live in changed)."""

    def test_a1_mode_matches_legacy_script_counts(self):
        legacy_report, _ = "", None
        legacy_lexicon = CefrLexicon.load(ROOT)
        legacy_index = GrammarIndex.load(ROOT)
        vocab_rows = legacy._load_vocab_rows()
        for row in vocab_rows:
            row["level"] = (row.get("level") or "").strip().lower()
        cloze_items = legacy._load_json(legacy.CLOZE_JSON)["items"]
        satz_items = legacy._load_json(legacy.SATZ_JSON)["items"]
        legacy_vocab_flagged, _ = legacy.scan_corpus(
            legacy_lexicon, legacy_index, vocab_rows,
            id_key="id", text_key="example_korean", level_key="level",
            target_level="a1", kind="vocab",
        )
        legacy_cloze_flagged, _ = legacy.scan_corpus(
            legacy_lexicon, legacy_index, cloze_items,
            id_key="id", text_key="fullKo", level_key="level",
            target_level="a1", kind="cloze",
        )
        legacy_satz_flagged, _ = legacy.scan_corpus(
            legacy_lexicon, legacy_index, satz_items,
            id_key="id", text_key="targetKo", level_key="level",
            target_level="a1", kind="satz",
        )
        _, counts = S.run("A1")
        self.assertEqual(counts["vocab"], len(legacy_vocab_flagged))
        self.assertEqual(counts["cloze"], len(legacy_cloze_flagged))
        self.assertEqual(counts["satz"], len(legacy_satz_flagged))


class A2LiveRatchetTest(unittest.TestCase):
    """Live ratchet: the current A2 corpus (vocab/cloze/satz) must carry 0
    nikl grade>=3 grammar (see docs/data/grammar_scan_a2_2026-09-15.md)."""

    def test_a2_corpus_has_zero_grade3_hits(self):
        report, counts = S.run("A2")
        self.assertEqual(
            counts, {"vocab": 0, "cloze": 0, "satz": 0},
            f"A2 corpus still carries grade>=3 grammar: {counts}\n{report}",
        )


if __name__ == "__main__":
    unittest.main()
