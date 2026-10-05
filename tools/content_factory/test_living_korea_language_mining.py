from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DRAFT = ROOT / "tools/content_factory/drafts/living_korea_scene_first_drafts_20261005.json"
MINING = ROOT / "tools/content_factory/review/living_korea_language_mining_20261005.json"


class LivingKoreaLanguageMiningTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.draft = json.loads(DRAFT.read_text(encoding="utf-8"))
        cls.mining = json.loads(MINING.read_text(encoding="utf-8"))
        cls.scenes = {
            scene["id"]: scene
            for arc in cls.draft["arcs"]
            for scene in arc["scenes"]
        }
        cls.mined = {row["sceneId"]: row for row in cls.mining["scenes"]}

    def test_mining_is_downstream_of_scene_first_copy(self) -> None:
        self.assertEqual(self.mining["schemaVersion"], 1)
        self.assertEqual(self.mining["status"], "model_mined_review_only")
        self.assertEqual(
            self.mining["miningOrder"],
            "dialogue_first_then_language",
        )
        self.assertFalse(self.mining["humanApprovalClaim"])
        self.assertFalse(self.mining["nativeSpeakerQaClaim"])
        self.assertEqual(self.mining["cefrAuditStatus"], "pending_d4")

    def test_every_scene_has_exactly_one_mining_record(self) -> None:
        self.assertEqual(set(self.mined), set(self.scenes))
        self.assertEqual(len(self.mined), 9)

    def test_every_mined_target_is_attested_in_the_dialogue(self) -> None:
        for scene_id, row in self.mined.items():
            dialogue = "\n".join(
                turn["ko"] for turn in self.scenes[scene_id]["dialog"]
            )
            with self.subTest(scene=scene_id):
                for key in ("vocabulary", "grammar", "pragmatics"):
                    self.assertTrue(row[key], f"{scene_id} has empty {key}")
                    for target in row[key]:
                        surface = target["attestedSurface"]
                        self.assertIn(
                            surface,
                            dialogue,
                            msg=f"{scene_id} ungrounded {key} target: {surface}",
                        )
                self.assertTrue(row["registerMarkers"])

    def test_vocabulary_has_lemma_and_surface_without_duplicates(self) -> None:
        for scene_id, row in self.mined.items():
            pairs = [
                (item["lemma"], item["attestedSurface"])
                for item in row["vocabulary"]
            ]
            with self.subTest(scene=scene_id):
                self.assertEqual(len(pairs), len(set(pairs)))
                for lemma, surface in pairs:
                    self.assertTrue(lemma.strip())
                    self.assertTrue(surface.strip())

    def test_grammar_is_descriptive_not_preattached_to_scene_draft(self) -> None:
        for scene_id, row in self.mined.items():
            draft_scene = self.scenes[scene_id]
            with self.subTest(scene=scene_id):
                self.assertNotIn("grammarTargets", draft_scene)
                self.assertNotIn("grammarIds", draft_scene)
                for item in row["grammar"]:
                    self.assertTrue(item["pattern"].strip())
                    self.assertTrue(item["attestedSurface"].strip())

    def test_cross_scene_repetition_only_references_real_scenes(self) -> None:
        valid = set(self.scenes)
        families = self.mining["crossSceneRepetition"]
        self.assertGreaterEqual(len(families), 4)
        for family in families:
            with self.subTest(family=family["family"]):
                self.assertGreaterEqual(len(family["sceneIds"]), 3)
                self.assertTrue(set(family["sceneIds"]).issubset(valid))
                self.assertTrue(family["repeatedLanguage"])

    def test_security_language_remains_verification_oriented(self) -> None:
        ids = {
            "a2_dongsun_christian_suspicious_delivery_text",
            "b1_christian_sujin_suspicious_text_followup",
            "b1_sujin_byeongcheol_family_verification_rule",
        }
        blob = json.dumps(
            [self.mined[scene_id] for scene_id in ids],
            ensure_ascii=False,
        )
        for expected in ("확인", "링크", "공식"):
            self.assertIn(expected, blob)
        for prohibited in ("우회", "탈취", "침투 절차", "악성코드 제작"):
            self.assertNotIn(prohibited, blob)


if __name__ == "__main__":
    unittest.main()
