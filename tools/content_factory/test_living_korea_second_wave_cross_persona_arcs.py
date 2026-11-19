from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ARCS = ROOT / "tools/content_factory/review/living_korea_second_wave_cross_persona_arcs_20261005.json"
DRAFT = ROOT / "tools/content_factory/drafts/living_korea_second_wave_scene_first_drafts_20261005.json"
PROFILES = ROOT / "tools/content_factory/canonical_scenarios/character_profiles.json"


class LivingKoreaSecondWaveCrossPersonaArcsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.arcs = json.loads(ARCS.read_text(encoding="utf-8"))
        cls.draft = json.loads(DRAFT.read_text(encoding="utf-8"))
        cls.profiles = json.loads(PROFILES.read_text(encoding="utf-8"))
        cls.scene_map = {
            scene["id"]: scene
            for arc in cls.draft["arcs"]
            for scene in arc["scenes"]
        }
        cls.arc_map = {arc["id"]: arc for arc in cls.draft["arcs"]}
        cls.relationships = {
            frozenset((row["a"], row["b"])): row["type"]
            for row in cls.profiles["relationshipGraph"]["edges"]
        }

    def test_d6_contract_is_review_only_and_zero_invention(self) -> None:
        self.assertEqual(self.arcs["schemaVersion"], 1)
        self.assertEqual(self.arcs["status"], "D6_PASS_REVIEW_ONLY")
        self.assertEqual(self.arcs["wave"], "second_wave")
        claims = self.arcs["claims"]
        self.assertEqual(claims["inventedRelationshipCount"], 0)
        self.assertEqual(claims["inventedAuthorityCount"], 0)
        self.assertFalse(claims["liveWritePerformed"])
        self.assertFalse(claims["humanApproval"])

    def test_review_arcs_match_scene_first_arc_ids(self) -> None:
        self.assertEqual(
            {row["arcId"] for row in self.arcs["arcs"]},
            set(self.arc_map),
        )

    def test_every_scene_edge_matches_canonical_relationship_type(self) -> None:
        reviewed_scenes = set()
        for arc in self.arcs["arcs"]:
            for edge in arc["edges"]:
                reviewed_scenes.add(edge["sceneId"])
                key = frozenset((edge["a"], edge["b"]))
                with self.subTest(scene=edge["sceneId"]):
                    self.assertIn(key, self.relationships)
                    self.assertEqual(edge["canonicalType"], self.relationships[key])
                    scene = self.scene_map[edge["sceneId"]]
                    self.assertEqual(
                        set(scene["participantIds"]),
                        {edge["a"], edge["b"]},
                    )
                    self.assertTrue(edge["authorityBoundaryKo"].strip())
        self.assertEqual(reviewed_scenes, set(self.scene_map))

    def test_every_second_wave_arc_has_exactly_two_edges(self) -> None:
        self.assertEqual(len(self.arcs["arcs"]), 7)
        for arc in self.arcs["arcs"]:
            with self.subTest(arc=arc["arcId"]):
                self.assertEqual(len(arc["edges"]), 2)
                self.assertTrue(arc["continuityKo"].strip())

    def test_sensitive_authority_boundaries_are_explicit(self) -> None:
        text = "\n".join(
            edge["authorityBoundaryKo"]
            for arc in self.arcs["arcs"]
            for edge in arc["edges"]
        )
        for expected in (
            "세무·노무",
            "정상회의의 외교 성과나 정치적 평가",
            "의료 조언",
            "위험한 직접 수리",
            "주민 전체를 대표",
        ):
            self.assertIn(expected, text)

    def test_hyuna_is_not_promoted_to_universal_authority(self) -> None:
        hyuna_edges = [
            edge
            for arc in self.arcs["arcs"]
            for edge in arc["edges"]
            if "hyuna" in {edge["a"], edge["b"]}
        ]
        self.assertGreaterEqual(len(hyuna_edges), 5)
        text = "\n".join(edge["authorityBoundaryKo"] for edge in hyuna_edges)
        self.assertIn("대표", text)
        self.assertIn("대신하지", text)
        self.assertIn("분리", text)


if __name__ == "__main__":
    unittest.main()
