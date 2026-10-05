from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "tools/content_factory/review/living_korea_program_manifest_20261005.json"


class LivingKoreaProgramManifestTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        cls.wave_payloads = {}
        for wave_name, wave in cls.manifest["waves"].items():
            cls.wave_payloads[wave_name] = {
                key: json.loads((ROOT / rel).read_text(encoding="utf-8"))
                for key, rel in wave.items()
                if key != "reviewState"
            }
        cls.personas = json.loads(
            (ROOT / cls.manifest["canonicalSources"]["personaCanon"]).read_text(
                encoding="utf-8"
            )
        )
        cls.topics = json.loads(
            (ROOT / cls.manifest["canonicalSources"]["topicRegistry"]).read_text(
                encoding="utf-8"
            )
        )

    def test_program_is_review_ready_not_live(self) -> None:
        self.assertEqual(self.manifest["schemaVersion"], 1)
        self.assertEqual(
            self.manifest["status"],
            "ALL_TOPICS_REVIEW_READY_NOT_LIVE",
        )
        scope = self.manifest["scopeBoundaries"]
        self.assertTrue(scope["ttsOwnedByJin"])
        self.assertFalse(scope["ttsTouched"])
        self.assertFalse(scope["liveScenarioWritePerformed"])
        self.assertFalse(scope["masteryOwnershipChanged"])
        self.assertFalse(scope["rewardOwnershipChanged"])
        self.assertFalse(scope["secondWaveHumanLanguageApprovalClaimed"])
        self.assertFalse(scope["nativeSpeakerQaClaimed"])
        self.assertTrue(scope["securityContentDefensiveOnly"])
        self.assertFalse(scope["politicalPersuasion"])

    def test_first_wave_reviewed_second_wave_pending_review(self) -> None:
        self.assertEqual(
            self.manifest["waves"]["first"]["reviewState"],
            "USER_REVIEWED_5_ACCEPTED_4_REVISED_PENDING_FINAL_CONFIRMATION",
        )
        self.assertEqual(
            self.manifest["waves"]["second"]["reviewState"],
            "MODEL_AUTHORED_PENDING_USER_REVIEW",
        )

    def test_program_counts_reproduce_from_wave_artifacts(self) -> None:
        counts = self.manifest["counts"]
        first = self.wave_payloads["first"]
        second = self.wave_payloads["second"]

        first_scenes = [
            scene
            for arc in first["sceneDraft"]["arcs"]
            for scene in arc["scenes"]
        ]
        second_scenes = [
            scene
            for arc in second["sceneDraft"]["arcs"]
            for scene in arc["scenes"]
        ]
        all_scenes = first_scenes + second_scenes
        all_mining = (
            first["languageMining"]["scenes"]
            + second["languageMining"]["scenes"]
        )
        all_cards = (
            first["cultureCards"]["cards"]
            + second["cultureCards"]["cards"]
        )

        self.assertEqual(
            counts["canonicalPersonas"],
            len(self.personas["recurringCharacters"]),
        )
        self.assertEqual(counts["frozenTopics"], len(self.topics["topics"]))
        self.assertEqual(
            counts["personaAssignments"],
            len(self.topics["personaAssignments"]),
        )
        self.assertEqual(
            counts["arcs"],
            len(first["sceneDraft"]["arcs"])
            + len(second["sceneDraft"]["arcs"]),
        )
        self.assertEqual(counts["scenes"], len(all_scenes))
        self.assertEqual(
            counts["dialogueTurns"],
            sum(len(scene["dialog"]) for scene in all_scenes),
        )
        self.assertEqual(counts["cultureCards"], len(all_cards))
        self.assertEqual(
            counts["minedVocabularyTargets"],
            sum(len(row["vocabulary"]) for row in all_mining),
        )
        self.assertEqual(
            counts["minedGrammarTargets"],
            sum(len(row["grammar"]) for row in all_mining),
        )
        self.assertEqual(
            counts["minedPragmaticExpressions"],
            sum(len(row["pragmatics"]) for row in all_mining),
        )
        self.assertEqual(
            counts["registerMarkers"],
            sum(len(row["registerMarkers"]) for row in all_mining),
        )

    def test_all_eleven_topics_have_dialogue_and_exactly_one_card(self) -> None:
        topic_ids = {row["id"] for row in self.topics["topics"]}
        scene_topic_ids = {
            topic_id
            for payload in self.wave_payloads.values()
            for arc in payload["sceneDraft"]["arcs"]
            for scene in arc["scenes"]
            for topic_id in scene["topicIds"]
        }
        card_topic_ids = [
            card["topicId"]
            for payload in self.wave_payloads.values()
            for card in payload["cultureCards"]["cards"]
        ]
        self.assertEqual(scene_topic_ids, topic_ids)
        self.assertEqual(set(card_topic_ids), topic_ids)
        self.assertEqual(len(card_topic_ids), len(set(card_topic_ids)))
        self.assertEqual(len(card_topic_ids), 11)

    def test_both_wave_lcp_exits_match_program_manifest(self) -> None:
        for manifest_key, wave_name in (
            ("firstWave", "first"),
            ("secondWave", "second"),
        ):
            expected = self.wave_payloads[wave_name]["lcpAudit"]["exitConditions"]
            self.assertEqual(self.manifest["lcpExit"][manifest_key], expected)

    def test_sujin_christian_register_is_canonical_banmal_now(self) -> None:
        self.assertEqual(
            self.manifest["coverage"]["sujinChristianCurrentRegister"],
            "banmal_except_first_meeting_and_early_relationship",
        )
        characters = {
            row["id"]: row for row in self.personas["recurringCharacters"]
        }
        for char_id, partner in (
            ("sujin", "christian"),
            ("christian", "sujin"),
        ):
            self.assertIn(
                "현재 연애 시점에서는 서로 반말",
                characters[char_id]["relationships"][partner],
            )
        edge = next(
            row
            for row in self.personas["relationshipGraph"]["edges"]
            if {row["a"], row["b"]} == {"sujin", "christian"}
        )
        self.assertEqual(
            edge["registerKo"],
            "첫 만남·초기 관계에서는 해요체, 현재 연애 시점에서는 서로 반말",
        )

    def test_global_lcp_and_freshness_closeout(self) -> None:
        lcp = self.manifest["lcpExit"]
        self.assertEqual(lcp["globalClozeUnknown"], 276)
        self.assertEqual(lcp["globalClozeTokenCount"], 14721)
        self.assertEqual(lcp["globalClozeUnknownRatchet"], 0.0188)
        freshness = self.manifest["freshness"]
        self.assertTrue(
            freshness["allTopicsCoveredExactlyOnceByCardsAcrossWaves"]
        )
        self.assertTrue(freshness["dynamicReviewAfterGate"])
        self.assertTrue(freshness["eventAndSourceWindowGate"])

    def test_dependency_and_next_step_are_explicit(self) -> None:
        dependency = self.manifest["dependency"]
        self.assertEqual(dependency["basePullRequest"], 449)
        self.assertEqual(dependency["featurePullRequest"], 450)
        self.assertIn("User review", self.manifest["next"]["required"])


if __name__ == "__main__":
    unittest.main()
