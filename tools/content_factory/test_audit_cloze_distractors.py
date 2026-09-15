#!/usr/bin/env python3
"""C2c -- regression tests for cloze_distractor_rules.py (D1-D6) and the
live-corpus ratchet (0 mechanical violations after the 2026-09-15 sweep).

Run with:
    python -m unittest tools.content_factory.test_audit_cloze_distractors -v
"""
from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import cloze_distractor_rules as R  # noqa: E402
from audit_cloze_distractors import audit_item  # noqa: E402

CLOZE = R.REPO_ROOT / "assets/data/cloze.json"


class FakeVocab:
    """Minimal stand-in for VocabIndex, built from an explicit row list, so
    D1-D6 unit tests don't depend on the live korean_vocab.csv contents."""

    def __init__(self, rows):
        self.rows = rows
        self.by_word = {}
        self.by_level_pos = {}
        self.by_level = {}
        self.hada_activity_nouns = set()
        for r in rows:
            self.by_word.setdefault(r["korean"], []).append(r)
            self.by_level_pos.setdefault((r["level"].lower(), r["pos_de"]), []).append(r)
            self.by_level.setdefault(r["level"].lower(), []).append(r)
            if r["korean"].endswith("하다") and len(r["korean"]) > 2:
                self.hada_activity_nouns.add(r["korean"][: -len("하다")])

    def pos_of(self, word):
        rows = self.by_word.get(word)
        return rows[0]["pos_de"] if rows else None


def row(korean, level, pos_de, topic="T"):
    return {"korean": korean, "level": level, "pos_de": pos_de, "topic": topic}


VOCAB = FakeVocab([
    row("친구", "A1", "Nomen"), row("남편", "A1", "Nomen"),
    row("가다", "A1", "Verb"), row("맞추다", "A1", "Verb"),
    row("결국", "B1", "Adverb"), row("업무", "B1", "Nomen"),
    row("여기", "A1", "Pronomen"), row("교차로", "A2", "Nomen"),
    row("건강하다", "A2", "Verb"), row("숙제", "A1", "Nomen"),
    row("날씨", "A1", "Nomen"),
])


class D1BatchimClassTests(unittest.TestCase):
    def test_flags_batchim_mismatch_before_alternating_particle(self):
        # 친구 has no batchim -> needs "가" (vowel-final class); 남편 has
        # batchim -> its own class is "consonant", a mismatch here.
        kind, required = R.detect_required_class("제 ＿＿＿가 있어요.", "친구")
        self.assertEqual(required, "vowel")
        self.assertNotEqual(R.batchim_class("남편", kind), required)

    def test_passes_when_batchim_class_matches(self):
        kind, required = R.detect_required_class("제 ＿＿＿가 있어요.", "친구")
        self.assertEqual(R.batchim_class("친구", kind), required)

    def test_no_particle_after_blank_is_not_checked(self):
        kind, required = R.detect_required_class("＿＿＿ 맛있어요!", "정말")
        self.assertIsNone(required)


class D2ParticleFormTests(unittest.TestCase):
    def test_flags_distractor_with_different_attached_particle(self):
        bad = R.check_d2_particle_form("여기에서", ["어제부터", "친구하고"], VOCAB)
        self.assertEqual(bad, ["어제부터", "친구하고"])

    def test_passes_distractor_with_same_attached_particle(self):
        bad = R.check_d2_particle_form("여기에서", ["학교에서", "공원에서"], VOCAB)
        self.assertEqual(bad, [])

    def test_bare_vocab_headword_is_not_treated_as_particle_attached(self):
        # "교차로" ends in the syllable "로" but is itself a headword, not
        # "교차" + the -로 particle.
        self.assertIsNone(R.matching_particle_suffix("교차로", VOCAB))


class D3PosFormTests(unittest.TestCase):
    def test_flags_when_fewer_than_two_of_three_match(self):
        bad, unresolved, pos = R.check_d3_pos_form(
            "결국", ["업무", "친구", "남편"], VOCAB
        )
        self.assertFalse(unresolved)
        self.assertEqual(len(bad), 3)  # 0/3 match Adverb -> all 3 flagged

    def test_passes_when_two_of_three_match_pos(self):
        bad, unresolved, pos = R.check_d3_pos_form(
            "친구", ["남편", "결국", "여기"], VOCAB
        )
        # 남편 (Nomen) and 여기 (Pronomen->NOUN) match; 2/3 clears the bar.
        self.assertEqual(bad, [])

    def test_waiver_item_accepts_dictionary_form_and_bare_particle(self):
        bad, unresolved, pos = R.check_d3_pos_form(
            "알겠습니다", ["가다", "먹다", "에서"], VOCAB, cloze_id="cloze_a1_0413"
        )
        self.assertEqual(bad, [])

    def test_same_ending_survives_vowel_contraction(self):
        # 바꾸다+었습니다 contracts to 바꿨습니다 (no literal "었습니다"
        # substring); 들다+었습니다 doesn't contract. Both are the same
        # grammatical past-formal ending.
        self.assertTrue(R.same_ending("들었습니다", "바꿨습니다"))

    def test_rieul_adnominal_unifies_both_surface_forms(self):
        # 가로막다+을 keeps a literal "을"; 늘리다+ㄹ fuses into "릴".
        self.assertTrue(R.rieul_adnominal_ending("가로막을"))
        self.assertTrue(R.rieul_adnominal_ending("늘릴"))


class D4ActivityNounTests(unittest.TestCase):
    def test_flags_activity_noun_directly_before_hada(self):
        bad = R.check_d4_activity_noun("＿＿＿를 해요.", ["숙제", "건강", "날씨"], VOCAB)
        self.assertIn("건강", bad)  # 건강 in ACTIVITY_NOUN_SET-adjacent vocab (하다-derived) — see hada set
        self.assertNotIn("날씨", bad)

    def test_does_not_fire_on_unrelated_verb_later_in_sentence(self):
        # 친절했어요 contains the literal substring "했어요" but is NOT an
        # N+하다 frame -- the blank isn't adjacent to it.
        self.assertFalse(R.is_activity_slot("＿＿＿이 친절했어요."))

    def test_fires_only_when_blank_is_directly_before_hada_family(self):
        self.assertTrue(R.is_activity_slot("저는 항상 ＿＿＿을 해요."))
        self.assertFalse(R.is_activity_slot("결국 ＿＿＿ 성공했어요."))


class D6ExposureDuplicateTests(unittest.TestCase):
    def test_flags_distractor_exposed_in_remainder(self):
        result = R.check_d6_exposure_and_dupes("학교 앞에서 ＿＿＿ 만나요.", "친구", ["집", "학교"])
        self.assertIn("학교", result["exposed"])

    def test_flags_duplicate_distractors(self):
        result = R.check_d6_exposure_and_dupes("＿＿＿ 좋아요.", "정말", ["가끔", "가끔", "항상"])
        self.assertTrue(result["duplicates"])

    def test_clean_item_has_no_d6_hits(self):
        result = R.check_d6_exposure_and_dupes("＿＿＿ 좋아요.", "정말", ["가끔", "항상", "거의"])
        self.assertEqual(result["exposed"], [])
        self.assertFalse(result["duplicates"])
        self.assertEqual(result["equals_answer"], [])


class D5DetectionTests(unittest.TestCase):
    def test_detects_existential_open_slot(self):
        self.assertTrue(R.is_open_noun_slot("＿＿＿가 있어요.", "친구"))

    def test_not_a_slot_when_answer_is_the_predicate_itself(self):
        self.assertFalse(R.is_open_noun_slot("실수해도 ＿＿＿.", "문제없어요"))

    def test_not_a_slot_when_predicate_absent(self):
        self.assertFalse(R.is_open_noun_slot("＿＿＿에 가요.", "학교"))


class LiveCorpusRatchetTest(unittest.TestCase):
    """0 mechanical (D1/D2/D3/D4/D6) violations on the live corpus after
    the 2026-09-15 C2c sweep. D5 is detection-only by design (see the
    module docstring in cloze_distractor_rules.py) -- this ratchet does
    not require it to be zero."""

    def test_zero_mechanical_violations_on_live_cloze_json(self):
        data = json.loads(CLOZE.read_text(encoding="utf-8"))
        vocab = R.VocabIndex(R.load_vocab_rows())
        flagged = []
        for it in data["items"]:
            result = audit_item(it, vocab)
            if result["any_mechanical"]:
                flagged.append(result["id"])
        self.assertEqual(
            flagged, [],
            f"{len(flagged)} live cloze item(s) still fail D1/D2/D3/D4/D6: {flagged[:10]}",
        )


if __name__ == "__main__":
    unittest.main()
