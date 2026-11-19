from __future__ import annotations

import json
import unittest
from datetime import date
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REGISTRY = (
    ROOT
    / "tools"
    / "content_factory"
    / "canonical_scenarios"
    / "contemporary_korea_topics_20251005_20261005.json"
)
PROFILES = (
    ROOT
    / "tools"
    / "content_factory"
    / "canonical_scenarios"
    / "character_profiles.json"
)


class ContemporaryKoreaTopicRegistryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.registry = json.loads(REGISTRY.read_text(encoding="utf-8"))
        cls.profiles = json.loads(PROFILES.read_text(encoding="utf-8"))
        cls.topics = {row["id"]: row for row in cls.registry["topics"]}
        cls.persona_ids = {
            row["id"] for row in cls.profiles["recurringCharacters"]
        }

    def test_window_and_snapshot_are_frozen(self) -> None:
        self.assertEqual(self.registry["schemaVersion"], 1)
        self.assertEqual(self.registry["snapshotDate"], "2026-10-05")
        self.assertEqual(
            self.registry["window"],
            {"start": "2025-10-05", "end": "2026-10-05"},
        )

    def test_topics_have_unique_ids_and_source_backing(self) -> None:
        rows = self.registry["topics"]
        self.assertEqual(len(rows), 11)
        self.assertEqual(len(self.topics), len(rows))
        allowed_status = {"canonical", "watch", "archive"}
        start = date.fromisoformat(self.registry["window"]["start"])
        end = date.fromisoformat(self.registry["window"]["end"])
        for topic in rows:
            with self.subTest(topic=topic["id"]):
                self.assertIn(topic["status"], allowed_status)
                self.assertTrue(topic["stableFacts"])
                self.assertTrue(topic["learningAngles"])
                self.assertTrue(topic["candidateGrammar"])
                self.assertTrue(topic["candidateVocab"])
                self.assertTrue(topic["candidatePragmatics"])
                self.assertTrue(topic["sources"])
                self.assertGreater(date.fromisoformat(topic["reviewAfter"]), end)
                for event_date in topic["eventDates"]:
                    parsed = date.fromisoformat(event_date)
                    self.assertGreaterEqual(parsed, start)
                    self.assertLessEqual(parsed, end)
                for source in topic["sources"]:
                    parsed = date.fromisoformat(source["date"])
                    self.assertGreaterEqual(parsed, start)
                    self.assertLessEqual(parsed, end)
                    self.assertTrue(source["url"].startswith("https://"))

    def test_every_canonical_persona_has_two_primary_and_one_secondary_topic(self) -> None:
        assignments = self.registry["personaAssignments"]
        self.assertEqual(set(assignments), self.persona_ids)
        for persona_id, assignment in assignments.items():
            with self.subTest(persona=persona_id):
                self.assertEqual(len(assignment["primary"]), 2)
                self.assertEqual(len(assignment["secondary"]), 1)
                combined = assignment["primary"] + assignment["secondary"]
                self.assertEqual(len(combined), len(set(combined)))
                for topic_id in combined:
                    self.assertIn(topic_id, self.topics)
                self.assertTrue(assignment["rationale"].strip())

    def test_christian_is_systems_student_not_data_engineer(self) -> None:
        christian = next(
            row
            for row in self.profiles["recurringCharacters"]
            if row["id"] == "christian"
        )
        self.assertEqual(
            christian["background"]["major"],
            "인터넷 시스템 통합·시스템 관리",
        )
        self.assertIn("시스템 보안", christian["interests"])
        self.assertNotIn("앱 개발", christian["interests"])
        hints = "\n".join(christian["writerHints"])
        self.assertIn("데이터 엔지니어·데이터 분석가 역할로 쓰지 않는다", hints)
        self.assertIn("시스템 보안", hints)
        self.assertEqual(
            self.registry["personaAssignments"]["christian"]["primary"],
            [
                "cyber_privacy_credentials_2026",
                "voice_phishing_digital_safety_2026",
            ],
        )

    def test_security_topics_are_explicitly_defensive(self) -> None:
        for topic_id in (
            "cyber_privacy_credentials_2026",
            "voice_phishing_digital_safety_2026",
        ):
            text = " ".join(self.topics[topic_id]["avoid"])
            with self.subTest(topic=topic_id):
                self.assertTrue(
                    "공격 절차" in text
                    or "사기 실행" in text,
                    msg=f"{topic_id} must explicitly block offensive how-to content",
                )


if __name__ == "__main__":
    unittest.main()
