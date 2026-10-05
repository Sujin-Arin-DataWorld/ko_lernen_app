from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DRAFT = ROOT / "tools/content_factory/drafts/living_korea_second_wave_scene_first_drafts_20261005.json"
TOPICS = (
    ROOT
    / "tools/content_factory/canonical_scenarios"
    / "contemporary_korea_topics_20251005_20261005.json"
)
PROFILES = (
    ROOT
    / "tools/content_factory/canonical_scenarios"
    / "character_profiles.json"
)


class LivingKoreaSecondWaveSceneFirstDraftTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.payload = json.loads(DRAFT.read_text(encoding="utf-8"))
        cls.topic_payload = json.loads(TOPICS.read_text(encoding="utf-8"))
        cls.profile_payload = json.loads(PROFILES.read_text(encoding="utf-8"))
        cls.topic_ids = {row["id"] for row in cls.topic_payload["topics"]}
        cls.assignments = cls.topic_payload["personaAssignments"]
        cls.profiles = {
            row["id"]: row for row in cls.profile_payload["recurringCharacters"]
        }
        cls.relationships = {
            frozenset((row["a"], row["b"])): row["type"]
            for row in cls.profile_payload["relationshipGraph"]["edges"]
        }
        cls.scenes = [
            scene for arc in cls.payload["arcs"] for scene in arc["scenes"]
        ]

    def test_scene_first_contract(self) -> None:
        self.assertEqual(self.payload["schemaVersion"], 1)
        self.assertEqual(self.payload["status"], "review_only_scene_first")
        self.assertEqual(self.payload["wave"], "second_wave")
        policy = self.payload["authoringPolicy"]
        self.assertTrue(policy["dialogueAuthoredBeforeLanguageMining"])
        self.assertFalse(policy["grammarTargetsAssignedBeforeDialogue"])
        self.assertTrue(policy["koreanCanonicalFirst"])
        self.assertEqual(
            policy["localizationStatus"],
            "pending_after_korean_dialogue_review",
        )
        self.assertEqual(policy["ttsStatus"], "excluded_jin_owned")
        self.assertFalse(policy["liveWritePerformed"])

    def test_second_wave_has_seven_arcs_fourteen_scenes_and_eighty_four_turns(self) -> None:
        self.assertEqual(len(self.payload["arcs"]), 7)
        self.assertEqual(len(self.scenes), 14)
        ids = [scene["id"] for scene in self.scenes]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(sum(len(scene["dialog"]) for scene in self.scenes), 84)

    def test_remaining_seven_topics_are_all_covered(self) -> None:
        expected = {
            "reduced_work_hours_45_2026",
            "work_family_demography_2025_2026",
            "minimum_wage_small_business_2026",
            "tourism_local_life_2026",
            "hallyu_diversification_2026",
            "apec_gyeongju_2025",
            "heatwave_electricity_safety_2026",
        }
        actual = {
            topic_id
            for scene in self.scenes
            for topic_id in scene["topicIds"]
        }
        self.assertEqual(actual, expected)

    def test_every_scene_uses_canonical_relationship_and_assigned_topic(self) -> None:
        for scene in self.scenes:
            participants = scene["participantIds"]
            self.assertEqual(len(participants), 2)
            self.assertEqual(len(set(participants)), 2)
            self.assertIn(scene["playerCharacterId"], participants)
            edge = frozenset(participants)
            with self.subTest(scene=scene["id"]):
                self.assertIn(edge, self.relationships)
                for persona_id in participants:
                    self.assertIn(persona_id, self.profiles)
                for topic_id in scene["topicIds"]:
                    self.assertIn(topic_id, self.topic_ids)
                    assigned = any(
                        topic_id
                        in (
                            self.assignments[persona_id]["primary"]
                            + self.assignments[persona_id]["secondary"]
                        )
                        for persona_id in participants
                    )
                    self.assertTrue(
                        assigned,
                        msg=f"{scene['id']} has no assigned persona owner for {topic_id}",
                    )

    def test_hyuna_and_lena_are_central_to_second_wave(self) -> None:
        counts = {"hyuna": 0, "lena": 0}
        for scene in self.scenes:
            for persona_id in counts:
                if persona_id in scene["participantIds"]:
                    counts[persona_id] += 1
        self.assertGreaterEqual(counts["hyuna"], 5)
        self.assertGreaterEqual(counts["lena"], 2)

    def test_dialogue_is_korean_only_six_turns_and_unmined(self) -> None:
        for scene in self.scenes:
            with self.subTest(scene=scene["id"]):
                self.assertEqual(len(scene["dialog"]), 6)
                non_player = set(scene["participantIds"]) - {
                    scene["playerCharacterId"]
                }
                speakers = set()
                for turn in scene["dialog"]:
                    self.assertEqual(set(turn), {"speaker", "ko"})
                    self.assertTrue(turn["ko"].strip())
                    self.assertNotIn("de", turn)
                    self.assertNotIn("en", turn)
                    speakers.add(turn["speaker"])
                    self.assertTrue(
                        turn["speaker"] == "user"
                        or turn["speaker"] in non_player
                    )
                self.assertIn("user", speakers)
                self.assertTrue(non_player & speakers)
                for forbidden in (
                    "grammarTargets",
                    "vocabTargets",
                    "pragmaticTargets",
                    "grammarIds",
                ):
                    self.assertNotIn(forbidden, scene)

    def test_andrea_minho_private_scenes_use_banmal(self) -> None:
        pair = {"andrea", "minho"}
        scenes = [
            scene
            for scene in self.scenes
            if set(scene["participantIds"]) == pair
        ]
        self.assertEqual(len(scenes), 2)
        for scene in scenes:
            with self.subTest(scene=scene["id"]):
                self.assertIn("반말", scene["relationshipContextKo"])
                dialogue = "\n".join(turn["ko"] for turn in scene["dialog"])
                self.assertNotIn("제가 ", dialogue)
                for turn in scene["dialog"]:
                    self.assertFalse(
                        turn["ko"].rstrip().endswith(
                            ("요.", "요?", "습니다.", "습니까?")
                        ),
                        msg=(scene["id"], turn["ko"]),
                    )

    def test_volatile_topic_numbers_are_not_embedded_in_dialogue(self) -> None:
        full_text = "\n".join(
            turn["ko"] for scene in self.scenes for turn in scene["dialog"]
        )
        for literal in (
            "10,320",
            "41.4",
            "293개",
            "1,000만",
            "254,457",
            "46.5%",
            "0.80",
        ):
            self.assertNotIn(literal, full_text)

    def test_sensitive_boundaries_remain_nonprescriptive(self) -> None:
        all_boundaries = "\n".join(
            boundary
            for scene in self.scenes
            for boundary in scene["personaBoundaries"]
        )
        for expected in (
            "출산을 개인의 의무",
            "세무·노무",
            "외교 성과나 정치적 평가",
            "위험한 전기 수리",
        ):
            self.assertIn(expected, all_boundaries)

    def test_heatwave_electrical_scene_says_turn_off_not_repair(self) -> None:
        scene = next(
            row
            for row in self.scenes
            if row["id"] == "b1_byeongcheol_sujin_heat_electricity"
        )
        text = "\n".join(turn["ko"] for turn in scene["dialog"])
        self.assertIn("먼저 끄고 손대지 마", text)
        self.assertIn("열어 보진 않을게", text)
        for unsafe in ("분해", "선을 연결", "퓨즈를 교체"):
            self.assertNotIn(unsafe, text)


if __name__ == "__main__":
    unittest.main()
