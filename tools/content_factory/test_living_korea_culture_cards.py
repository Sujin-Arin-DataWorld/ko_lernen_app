from __future__ import annotations

import json
import unittest
from datetime import date
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CARDS = ROOT / "tools/content_factory/drafts/living_korea_culture_cards_20261005.json"
TOPICS = (
    ROOT
    / "tools/content_factory/canonical_scenarios"
    / "contemporary_korea_topics_20251005_20261005.json"
)
SCENES = ROOT / "tools/content_factory/drafts/living_korea_scene_first_drafts_20261005.json"


class LivingKoreaCultureCardsTest(unittest.TestCase):
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
        self.assertEqual(self.cards["snapshotDate"], "2026-10-05")
        policy = self.cards["policy"]
        self.assertTrue(policy["factsMustExistInTopicRegistryStableFacts"])
        self.assertTrue(policy["sourcesMustMatchTopicRegistry"])
        self.assertTrue(policy["volatileFactsStayOutOfDialogue"])
        self.assertTrue(policy["cardsMayAgeWithoutRewritingDialogue"])
        self.assertFalse(policy["liveWritePerformed"])
        self.assertFalse(policy["ttsTouched"])

    def test_first_wave_has_four_source_backed_cards(self) -> None:
        cards = self.cards["cards"]
        self.assertEqual(len(cards), 4)
        self.assertEqual(len({row["id"] for row in cards}), 4)
        self.assertEqual(
            {row["topicId"] for row in cards},
            {
                "ai_transparency_2026",
                "cyber_privacy_credentials_2026",
                "school_smartphone_rules_2026",
                "voice_phishing_digital_safety_2026",
            },
        )

    def test_fact_and_source_indexes_resolve_inside_topic_registry(self) -> None:
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

    def test_card_review_after_matches_topic_registry(self) -> None:
        snapshot = date.fromisoformat(self.cards["snapshotDate"])
        for card in self.cards["cards"]:
            topic = self.topics[card["topicId"]]
            with self.subTest(card=card["id"]):
                self.assertEqual(card["reviewAfter"], topic["reviewAfter"])
                self.assertGreater(date.fromisoformat(card["reviewAfter"]), snapshot)

    def test_cards_only_reference_first_wave_scenes(self) -> None:
        for card in self.cards["cards"]:
            with self.subTest(card=card["id"]):
                self.assertTrue(card["sceneIds"])
                self.assertTrue(set(card["sceneIds"]).issubset(self.scenes))

    def test_learner_copy_is_context_not_unsourced_fact_ledger(self) -> None:
        for card in self.cards["cards"]:
            with self.subTest(card=card["id"]):
                self.assertTrue(card["titleKo"].strip())
                self.assertTrue(card["learnerContextKo"].strip())
                self.assertGreaterEqual(len(card["cultureQuestionsKo"]), 2)
                self.assertNotIn("http://", card["learnerContextKo"])
                self.assertNotIn("https://", card["learnerContextKo"])

    def test_voice_phishing_card_keeps_defensive_boundary(self) -> None:
        card = next(
            row
            for row in self.cards["cards"]
            if row["topicId"] == "voice_phishing_digital_safety_2026"
        )
        text = card["learnerContextKo"] + "\n" + "\n".join(card["cultureQuestionsKo"])
        for expected in ("바로 누르지", "공식", "확인"):
            self.assertIn(expected, text)
        for prohibited in ("우회", "탈취", "악성코드", "침투"):
            self.assertNotIn(prohibited, text)


if __name__ == "__main__":
    unittest.main()
