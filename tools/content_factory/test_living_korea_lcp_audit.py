from __future__ import annotations

import json
import unittest
from pathlib import Path

import tool.cefr_lexicon as cl


ROOT = Path(__file__).resolve().parents[2]
DRAFT = ROOT / "tools/content_factory/drafts/living_korea_scene_first_drafts_20261005.json"
MINING = ROOT / "tools/content_factory/review/living_korea_language_mining_20261005.json"
AUDIT = ROOT / "tools/content_factory/review/living_korea_lcp_audit_20261005.json"


class LivingKoreaLcpAuditTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.draft = json.loads(DRAFT.read_text(encoding="utf-8"))
        cls.mining = json.loads(MINING.read_text(encoding="utf-8"))
        cls.audit = json.loads(AUDIT.read_text(encoding="utf-8"))
        cls.lex = cl.CefrLexicon.load()
        cls.grammar = cl.GrammarIndex.load()
        cls.grade = cl.CEFR_TO_GRADE
        cls.scenes = {
            scene["id"]: scene
            for arc in cls.draft["arcs"]
            for scene in arc["scenes"]
        }
        cls.mined = {row["sceneId"]: row for row in cls.mining["scenes"]}

    def test_static_audit_contract(self) -> None:
        self.assertEqual(self.audit["schemaVersion"], 1)
        self.assertEqual(self.audit["status"], "D4_PASS")
        self.assertEqual(
            self.audit["exitConditions"],
            {
                "sentenceUnknown": 0,
                "minedVocabUnknown": 0,
                "minedVocabOver2": 0,
                "maxSentenceLevelDelta": 1,
            },
        )
        claims = self.audit["claims"]
        self.assertFalse(claims["humanApproval"])
        self.assertFalse(claims["nativeSpeakerQa"])
        self.assertFalse(claims["ttsTouched"])
        self.assertFalse(claims["liveScenarioWrite"])

    def test_all_54_dialogue_turns_have_zero_unknown_and_no_over2_level_jump(self) -> None:
        turn_count = 0
        max_delta = -99
        for scene in self.scenes.values():
            target = self.grade[scene["level"].upper()]
            for turn in scene["dialog"]:
                turn_count += 1
                profile = self.lex.sentence_profile(turn["ko"], self.grammar)
                self.assertEqual(
                    profile.unknown,
                    (),
                    msg=(scene["id"], turn["ko"], profile.unknown),
                )
                estimate = self.grade[profile.level_estimate.upper()]
                delta = estimate - target
                max_delta = max(max_delta, delta)
                self.assertLess(
                    delta,
                    2,
                    msg=(scene["id"], scene["level"], profile.level_estimate, turn["ko"]),
                )
        self.assertEqual(turn_count, 54)
        self.assertEqual(max_delta, 1)

    def test_all_mined_vocab_has_owner_and_no_over2(self) -> None:
        for scene_id, row in self.mined.items():
            target = self.grade[self.scenes[scene_id]["level"].upper()]
            for vocab in row["vocabulary"]:
                lemma = vocab["lemma"]
                result = (
                    self.lex.phrase_grade(lemma)
                    if " " in lemma
                    else self.lex.word_grade(lemma)
                )
                with self.subTest(scene=scene_id, lemma=lemma):
                    self.assertIsNotNone(result.grade)
                    self.assertLess(result.grade - target, 2)

    def test_modern_life_exact_owners_are_narrow_and_expected(self) -> None:
        cases = [
            ("링크", 2, "A2"),
            ("폴더", 3, "B1"),
        ]
        for surface, grade, cefr in cases:
            with self.subTest(surface=surface):
                result = self.lex.word_grade(surface)
                self.assertEqual(
                    (result.grade, result.cefr, result.source, result.matched),
                    (grade, cefr, "exception", surface),
                )

    def test_morphology_repairs_match_audit_ledger(self) -> None:
        for row in self.audit["decisions"]["auditorMorphologyRepairs"]:
            with self.subTest(surface=row["surface"]):
                result = self.lex._resolve_eojeol(row["surface"])
                self.assertEqual(result.matched, row["lemma"])
                self.assertIsNotNone(result.grade)

    def test_global_unknown_ratchet_is_tighter_after_d4(self) -> None:
        effect = self.audit["globalLexiconSideEffect"]
        self.assertEqual(effect["clozeSentenceUnknownBefore"], 282)
        self.assertEqual(effect["clozeSentenceUnknownAfter"], 278)
        self.assertEqual(effect["clozeTokenCount"], 14721)
        self.assertEqual(effect["ratchetCap"], 0.0189)


if __name__ == "__main__":
    unittest.main()
