from __future__ import annotations

import json
import unittest
from datetime import date
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TOPICS = (
    ROOT
    / "tools/content_factory/canonical_scenarios"
    / "contemporary_korea_topics_20251005_20261005.json"
)
CARDS = ROOT / "tools/content_factory/drafts/living_korea_culture_cards_20261005.json"
SECOND_CARDS = ROOT / "tools/content_factory/drafts/living_korea_second_wave_culture_cards_20261005.json"
PROFILES = (
    ROOT
    / "tools/content_factory/canonical_scenarios"
    / "character_profiles.json"
)


class LivingKoreaFreshnessGateTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.payload = json.loads(TOPICS.read_text(encoding="utf-8"))
        cls.cards = json.loads(CARDS.read_text(encoding="utf-8"))
        cls.second_cards = json.loads(SECOND_CARDS.read_text(encoding="utf-8"))
        cls.all_cards = cls.cards["cards"] + cls.second_cards["cards"]
        cls.profiles = json.loads(PROFILES.read_text(encoding="utf-8"))
        cls.topics = {row["id"]: row for row in cls.payload["topics"]}
        cls.snapshot = date.fromisoformat(cls.payload["snapshotDate"])
        cls.window_start = date.fromisoformat(cls.payload["window"]["start"])
        cls.window_end = date.fromisoformat(cls.payload["window"]["end"])
        cls.today = date.today()

    def test_snapshot_and_window_are_not_from_the_future(self) -> None:
        self.assertLessEqual(self.snapshot, self.today)
        self.assertEqual(self.window_end, self.snapshot)
        self.assertLessEqual(self.window_start, self.window_end)

    def test_every_topic_has_known_status_and_nonexpired_review_after(self) -> None:
        allowed = {"canonical", "watch", "archive"}
        for topic in self.payload["topics"]:
            with self.subTest(topic=topic["id"]):
                self.assertIn(topic["status"], allowed)
                review_after = date.fromisoformat(topic["reviewAfter"])
                self.assertGreaterEqual(
                    review_after,
                    self.today,
                    msg=(
                        f"{topic['id']} expired on {review_after}; "
                        "review the facts/status before shipping current-affairs copy"
                    ),
                )

    def test_every_event_and_source_date_is_inside_frozen_window(self) -> None:
        for topic in self.payload["topics"]:
            with self.subTest(topic=topic["id"]):
                self.assertTrue(topic["eventDates"])
                self.assertTrue(topic["sources"])
                for raw in topic["eventDates"]:
                    parsed = date.fromisoformat(raw)
                    self.assertGreaterEqual(parsed, self.window_start)
                    self.assertLessEqual(parsed, self.window_end)
                for source in topic["sources"]:
                    self.assertTrue(source["publisher"].strip())
                    self.assertTrue(source["url"].startswith("https://"))
                    parsed = date.fromisoformat(source["date"])
                    self.assertGreaterEqual(parsed, self.window_start)
                    self.assertLessEqual(parsed, self.window_end)

    def test_every_persona_assignment_points_to_existing_topics(self) -> None:
        canonical_personas = {
            row["id"] for row in self.profiles["recurringCharacters"]
        }
        assignments = self.payload["personaAssignments"]
        self.assertEqual(set(assignments), canonical_personas)
        for persona_id, assignment in assignments.items():
            with self.subTest(persona=persona_id):
                ids = assignment["primary"] + assignment["secondary"]
                self.assertEqual(len(assignment["primary"]), 2)
                self.assertEqual(len(assignment["secondary"]), 1)
                self.assertEqual(len(ids), len(set(ids)))
                self.assertTrue(set(ids).issubset(self.topics))

    def test_cards_inherit_topic_review_after_and_never_extend_it(self) -> None:
        for card in self.all_cards:
            topic = self.topics[card["topicId"]]
            with self.subTest(card=card["id"]):
                self.assertEqual(card["reviewAfter"], topic["reviewAfter"])
                self.assertGreaterEqual(
                    date.fromisoformat(card["reviewAfter"]),
                    self.today,
                )

    def test_first_and_second_wave_cards_cover_all_topics_once(self) -> None:
        topic_ids = [card["topicId"] for card in self.all_cards]
        self.assertEqual(len(topic_ids), 11)
        self.assertEqual(len(topic_ids), len(set(topic_ids)))
        self.assertEqual(set(topic_ids), set(self.topics))

    def test_card_snapshots_match_registry_snapshot(self) -> None:
        self.assertEqual(self.cards["snapshotDate"], self.payload["snapshotDate"])
        self.assertEqual(
            self.second_cards["snapshotDate"],
            self.payload["snapshotDate"],
        )

    def test_stable_and_volatile_facts_are_separated(self) -> None:
        for topic in self.payload["topics"]:
            with self.subTest(topic=topic["id"]):
                self.assertTrue(topic["stableFacts"])
                self.assertTrue(topic["volatileFacts"])
                self.assertTrue(
                    set(topic["stableFacts"]).isdisjoint(topic["volatileFacts"])
                )


if __name__ == "__main__":
    unittest.main()
