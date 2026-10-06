from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ARCS = ROOT / "tools/content_factory/review/living_korea_cross_persona_arcs_20261005.json"
DRAFT = ROOT / "tools/content_factory/drafts/living_korea_scene_first_drafts_20261005.json"
PROFILES = (
    ROOT
    / "tools/content_factory/canonical_scenarios"
    / "character_profiles.json"
)


class LivingKoreaCrossPersonaArcsTest(unittest.TestCase):
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
        cls.relationships = {}
        for edge in cls.profiles["relationshipGraph"]["edges"]:
            key = frozenset((edge["a"], edge["b"]))
            cls.relationships[key] = edge["type"]

    def test_d6_contract_is_review_only_and_has_zero_invention_claim(self) -> None:
        self.assertEqual(self.arcs["schemaVersion"], 1)
        self.assertEqual(self.arcs["status"], "D6_PASS_REVIEW_ONLY")
        claims = self.arcs["claims"]
        self.assertEqual(claims["inventedRelationshipCount"], 0)
        self.assertEqual(claims["inventedAuthorityCount"], 0)
        self.assertFalse(claims["liveWritePerformed"])
        self.assertFalse(claims["humanApproval"])

    def test_review_arcs_match_scene_first_arc_ids(self) -> None:
        review_ids = {arc["arcId"] for arc in self.arcs["arcs"]}
        self.assertEqual(review_ids, set(self.arc_map))

    def test_every_review_edge_matches_canonical_relationship_type(self) -> None:
        reviewed_scenes = set()
        for arc in self.arcs["arcs"]:
            for edge in arc["edges"]:
                reviewed_scenes.add(edge["sceneId"])
                key = frozenset((edge["a"], edge["b"]))
                with self.subTest(scene=edge["sceneId"]):
                    self.assertIn(key, self.relationships)
                    self.assertEqual(
                        edge["canonicalType"],
                        self.relationships[key],
                    )
                    scene = self.scene_map[edge["sceneId"]]
                    self.assertEqual(
                        set(scene["participantIds"]),
                        {edge["a"], edge["b"]},
                    )
                    self.assertTrue(edge["authorityBoundaryKo"].strip())
        self.assertEqual(reviewed_scenes, set(self.scene_map))

    def test_each_arc_is_connected(self) -> None:
        for arc in self.arcs["arcs"]:
            adjacency = {}
            for edge in arc["edges"]:
                adjacency.setdefault(edge["a"], set()).add(edge["b"])
                adjacency.setdefault(edge["b"], set()).add(edge["a"])
            start = next(iter(adjacency))
            seen = {start}
            frontier = [start]
            while frontier:
                node = frontier.pop()
                for neighbor in adjacency[node]:
                    if neighbor not in seen:
                        seen.add(neighbor)
                        frontier.append(neighbor)
            with self.subTest(arc=arc["arcId"]):
                self.assertEqual(seen, set(adjacency))

    def test_star_arc_uses_declared_continuity_owner(self) -> None:
        arc = next(
            row
            for row in self.arcs["arcs"]
            if row["arcId"] == "classroom_phone_boundaries"
        )
        owner = arc["continuityOwner"]
        self.assertEqual(owner, "jun")
        for edge in arc["edges"]:
            self.assertIn(owner, {edge["a"], edge["b"]})

    def test_security_arc_never_promotes_christian_to_security_authority(self) -> None:
        arc = next(
            row
            for row in self.arcs["arcs"]
            if row["arcId"] == "verify_before_you_tap"
        )
        text = "\n".join(edge["authorityBoundaryKo"] for edge in arc["edges"])
        self.assertIn("전문가", text)
        self.assertIn("단정하지", text)
        self.assertNotIn("사고 책임자", text)


if __name__ == "__main__":
    unittest.main()
