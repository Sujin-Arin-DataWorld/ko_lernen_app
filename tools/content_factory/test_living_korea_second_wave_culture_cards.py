from __future__ import annotations

import json
import unittest
from datetime import date
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CARDS = ROOT / "tools/content_factory/drafts/living_korea_second_wave_culture_cards_20261005.json"
TOPICS = ROOT / "tools/content_factory/canonical_scenarios/contemporary_korea_topics_20251005_20261005.json"
SCENES = ROOT / "tools/content_factory/drafts/living_korea_second_wave_scene_first_drafts_20261005.json"


class LivingKoreaSecondWaveCultureCardsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.cards = json.loads(CARDS.read_text(encoding="utf-8"))
        cls.topic_payload = json.loads(TOPICS.read_text(encoding="utf-8"))
        cls.scene_payload = json.loads(SCENES.read_text(encoding="utf-8"))
        cls.topics = {row["id"]: row for row in cls.topic_payload["topics"]}
        cls.scenes = {
            scene["id"]
            for arc in cls.scene_payload["arcs"]
            for scene in arc["scenes"]
        }

    def test_card_contract_is_review_only_and_tts_free(self) -> None:
        self.assertEqual(self.cards["schemaVersion"], 1)
        self.assertEqual(self.cards["status"], "review_only")
        self.assertEqual(self.cards["wave"], "second_wave")
        self.assertEqual(self.cards["snapshotDate"], "2026-10-05")
        policy = self.cards["policy"]
        self.assertTrue(policy["factsMustExistInTopicRegistryStableFacts"])
        self.assertTrue(policy["sourcesMustMatchTopicRegistry"])
        self.assertTrue(policy["volatileFactsStayOutOfDialogue"])
        self.assertTrue(policy["cardsMayAgeWithoutRewritingDialogue"])
        self.assertFalse(policy["liveWritePerformed"])
        self.assertFalse(policy["ttsTouched"])

    def test_second_wave_has_seven_cards_for_remaining_topics(self) -> None:
        cards = self.cards["cards"]
        self.assertEqual(len(cards), 7)
        self.assertEqual(len({row["id"] for row in cards}), 7)
        self.assertEqual(
            {row["topicId"] for row in cards},
            {
                "reduced_work_hours_45_2026",
                "work_family_demography_2025_2026",
                "minimum_wage_small_business_2026",
                "tourism_local_life_2026",
                "hallyu_diversification_2026",
                "apec_gyeongju_2025",
                "heatwave_electricity_safety_2026",
            },
        )

    def test_fact_source_indexes_resolve_inside_topic_registry(self) -> None:
        for card in self.cards["cards"]:
            topic = self.topics[card["topicId"]]
            with self.subTest(card=card["id"]):
                self.assertTrue(card["factIndexes"])
                self.assertTrue(card["sourceIndexes"])
                for index in card["factIndexes"]:
                    self.assertGreaterEqual(index, 0)
                    self.assertLess(index, len(topic["stableFacts"]))
                    self.assertTrue(topic["stableFacts"][index].strip())
                for index in card["sourceIndexes"]:
                    self.assertGreaterEqual(index, 0)
                    self.assertLess(index, len(topic["sources"]))
                    source = topic["sources"][index]
                    self.assertTrue(source["url"].startswith("https://"))
                    self.assertTrue(source["publisher"].strip())
                    date.fromisoformat(source["date"])

    def test_review_after_matches_topic_registry(self) -> None:
        snapshot = date.fromisoformat(self.cards["snapshotDate"])
        for card in self.cards["cards"]:
            topic = self.topics[card["topicId"]]
            with self.subTest(card=card["id"]):
                self.assertEqual(card["reviewAfter"], topic["reviewAfter"])
                self.assertGreater(date.fromisoformat(card["reviewAfter"]), snapshot)

    def test_cards_cover_all_second_wave_scenes_once(self) -> None:
        refs = [
            scene_id
            for card in self.cards["cards"]
            for scene_id in card["sceneIds"]
        ]
        self.assertEqual(set(refs), self.scenes)
        self.assertEqual(len(refs), len(set(refs)))
        self.assertEqual(len(refs), 14)

    def test_learner_copy_has_context_and_questions_not_raw_urls(self) -> None:
        for card in self.cards["cards"]:
            with self.subTest(card=card["id"]):
                self.assertTrue(card["titleKo"].strip())
                self.assertTrue(card["learnerContextKo"].strip())
                self.assertGreaterEqual(len(card["cultureQuestionsKo"]), 2)
                self.assertNotIn("http://", card["learnerContextKo"])
                self.assertNotIn("https://", card["learnerContextKo"])

    def test_sensitive_cards_keep_scope_boundaries(self) -> None:
        demography = next(
            row for row in self.cards["cards"]
            if row["topicId"] == "work_family_demography_2025_2026"
        )
        self.assertIn("개인의", demography["learnerContextKo"])
        heat = next(
            row for row in self.cards["cards"]
            if row["topicId"] == "heatwave_electricity_safety_2026"
        )
        self.assertIn("직접 수리하지", heat["learnerContextKo"])
        apec = next(
            row for row in self.cards["cards"]
            if row["topicId"] == "apec_gyeongju_2025"
        )
        self.assertIn("국제정치 평가가 아니라", apec["learnerContextKo"])


if __name__ == "__main__":
    unittest.main()
