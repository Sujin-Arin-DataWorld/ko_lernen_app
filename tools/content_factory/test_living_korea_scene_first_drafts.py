from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DRAFT = ROOT / "tools/content_factory/drafts/living_korea_scene_first_drafts_20261005.json"
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


class LivingKoreaSceneFirstDraftTest(unittest.TestCase):
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
        cls.scenes = [
            scene for arc in cls.payload["arcs"] for scene in arc["scenes"]
        ]

    def test_scene_first_contract(self) -> None:
        self.assertEqual(self.payload["schemaVersion"], 1)
        self.assertEqual(self.payload["status"], "review_only_scene_first")
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

    def test_first_wave_has_three_arcs_and_nine_scenes(self) -> None:
        self.assertEqual(len(self.payload["arcs"]), 3)
        self.assertEqual(len(self.scenes), 9)
        ids = [scene["id"] for scene in self.scenes]
        self.assertEqual(len(ids), len(set(ids)))

    def test_every_scene_uses_real_personas_and_declared_relationship(self) -> None:
        for scene in self.scenes:
            with self.subTest(scene=scene["id"]):
                participants = scene["participantIds"]
                self.assertEqual(len(participants), 2)
                self.assertEqual(len(set(participants)), 2)
                self.assertIn(scene["playerCharacterId"], participants)
                for persona_id in participants:
                    self.assertIn(persona_id, self.profiles)
                left, right = participants
                declared = (
                    right in self.profiles[left].get("relationships", {})
                    or left in self.profiles[right].get("relationships", {})
                )
                self.assertTrue(
                    declared,
                    msg=f"undeclared persona relationship {left}<->{right}",
                )

    def test_every_scene_topic_exists_and_fits_at_least_one_participant(self) -> None:
        for scene in self.scenes:
            with self.subTest(scene=scene["id"]):
                self.assertTrue(scene["topicIds"])
                for topic_id in scene["topicIds"]:
                    self.assertIn(topic_id, self.topic_ids)
                    assigned = False
                    for persona_id in scene["participantIds"]:
                        assignment = self.assignments[persona_id]
                        if topic_id in (
                            assignment["primary"] + assignment["secondary"]
                        ):
                            assigned = True
                    self.assertTrue(
                        assigned,
                        msg=f"{scene['id']} uses unassigned topic {topic_id}",
                    )

    def test_dialogue_is_korean_only_and_six_turns_before_mining(self) -> None:
        for scene in self.scenes:
            with self.subTest(scene=scene["id"]):
                dialog = scene["dialog"]
                self.assertEqual(len(dialog), 6)
                speakers = set()
                non_player = set(scene["participantIds"]) - {
                    scene["playerCharacterId"]
                }
                for turn in dialog:
                    self.assertEqual(set(turn), {"speaker", "ko"})
                    self.assertTrue(turn["ko"].strip())
                    self.assertNotIn("de", turn)
                    self.assertNotIn("en", turn)
                    speakers.add(turn["speaker"])
                    self.assertTrue(
                        turn["speaker"] == "user"
                        or turn["speaker"] in non_player,
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

    def test_dialogue_keeps_volatile_numbers_out(self) -> None:
        volatile_literals = (
            "10,320",
            "41.4",
            "293개",
            "1,000만",
            "254,457",
            "46.5%",
            "0.80",
        )
        full_text = "\n".join(
            turn["ko"] for scene in self.scenes for turn in scene["dialog"]
        )
        for literal in volatile_literals:
            with self.subTest(literal=literal):
                self.assertNotIn(literal, full_text)

    def test_christian_scenes_keep_student_security_boundary(self) -> None:
        christian_scenes = [
            scene
            for scene in self.scenes
            if "christian" in scene["participantIds"]
        ]
        self.assertGreaterEqual(len(christian_scenes), 4)
        boundary_text = "\n".join(
            boundary
            for scene in christian_scenes
            for boundary in scene["personaBoundaries"]
        )
        self.assertIn("학생", boundary_text)
        self.assertIn("보안 전문가", boundary_text)
        dialog_text = "\n".join(
            turn["ko"]
            for scene in christian_scenes
            for turn in scene["dialog"]
        )
        self.assertIn("제가 아는 범위에서는", dialog_text)
        self.assertIn("추측하지 않고", dialog_text)

    def test_security_arc_is_defensive_only(self) -> None:
        arc = next(
            row for row in self.payload["arcs"] if row["id"] == "verify_before_you_tap"
        )
        text = "\n".join(
            turn["ko"] for scene in arc["scenes"] for turn in scene["dialog"]
        )
        for expected in ("누르지", "택배 앱", "확인"):
            self.assertIn(expected, text)
        for prohibited in ("우회", "탈취", "공격 코드", "악성코드 만들"):
            self.assertNotIn(prohibited, text)


if __name__ == "__main__":
    unittest.main()
