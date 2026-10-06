from __future__ import annotations

import json
import subprocess
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REPORT = (
    ROOT
    / "tools"
    / "content_factory"
    / "review"
    / "trilingual_native_usage_progress_20261006.json"
)
AUDITOR = ROOT / "tools/content_factory/audit_trilingual_native_usage_progress.py"
REGISTRY = (
    ROOT
    / "tools"
    / "content_factory"
    / "canonical_scenarios"
    / "trilingual_native_usage_registry_20261006.json"
)


class TrilingualNativeUsageProgressTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.report = json.loads(REPORT.read_text(encoding="utf-8"))
        cls.registry = json.loads(REGISTRY.read_text(encoding="utf-8"))
        cls.by_topic = {row["topicId"]: row for row in cls.report["topics"]}

    def test_progress_report_is_current(self) -> None:
        completed = subprocess.run(
            [sys.executable, str(AUDITOR), "--check"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            encoding="utf-8",
            check=False,
        )
        self.assertEqual(
            completed.returncode,
            0,
            completed.stdout + "\n" + completed.stderr,
        )

    def test_summary_matches_32_topics_and_96_profiles(self) -> None:
        summary = self.report["summary"]
        self.assertEqual(summary["topicCount"], 32)
        self.assertEqual(summary["profileCount"], 96)
        self.assertEqual(summary["broadPassCompleteProfileCount"], 96)
        self.assertEqual(summary["deepPassCompleteProfileCount"], 96)
        self.assertEqual(summary["allLanguagesBroadPassCompleteTopicCount"], 32)
        self.assertEqual(summary["allLanguagesDeepPassCompleteTopicCount"], 32)

    def test_broad_complete_profiles_meet_hard_minimums(self) -> None:
        minimum = self.report["hardMinimumPerTopicLanguage"]
        for topic in self.report["topics"]:
            for lang, metrics in topic["languages"].items():
                if not metrics["broadPassComplete"]:
                    continue
                with self.subTest(topic=topic["topicId"], lang=lang):
                    self.assertGreaterEqual(
                        metrics["sourceContextCount"],
                        minimum["independentSourceContexts"],
                    )
                    self.assertGreaterEqual(
                        metrics["phrasePatternCount"],
                        minimum["normalizedUsagePatterns"],
                    )
                    self.assertGreaterEqual(
                        metrics["registerLaneCount"],
                        minimum["registerLanes"],
                    )
                    self.assertGreaterEqual(
                        metrics["translationeseWarningCount"],
                        minimum["translationeseAvoidNotes"],
                    )


    def test_tier1_all_languages_broad_pass_is_complete(self) -> None:
        tier1 = {
            "family_relationships",
            "house_home",
            "food_drink",
            "shopping_consumption",
            "transport_wayfinding",
            "health_body",
            "work_career",
            "services_public_admin",
            "communication_phone_digital",
            "social_etiquette_customs",
            "language_learning_communication_repair",
            "money_finance_contracts",
            "technology_digital_ai",
        }
        self.assertEqual(len(tier1), 13)
        for topic_id in tier1:
            with self.subTest(topic=topic_id):
                self.assertTrue(
                    self.by_topic[topic_id]["allLanguagesBroadPassComplete"]
                )

    def test_tier1_all_languages_deep_pass_is_complete(self) -> None:
        tier1 = {
            "family_relationships",
            "house_home",
            "food_drink",
            "shopping_consumption",
            "transport_wayfinding",
            "health_body",
            "work_career",
            "services_public_admin",
            "communication_phone_digital",
            "social_etiquette_customs",
            "language_learning_communication_repair",
            "money_finance_contracts",
            "technology_digital_ai",
        }
        for topic_id in tier1:
            with self.subTest(topic=topic_id):
                self.assertTrue(
                    self.by_topic[topic_id]["allLanguagesDeepPassComplete"]
                )

    def test_all_32_topics_all_96_profiles_complete_broad_pass(self) -> None:
        summary = self.report["summary"]
        self.assertEqual(summary["broadPassCompleteProfileCount"], 96)
        self.assertEqual(summary["allLanguagesBroadPassCompleteTopicCount"], 32)
        for topic_id, row in self.by_topic.items():
            with self.subTest(topic=topic_id):
                self.assertTrue(row["allLanguagesBroadPassComplete"])

    def test_status_is_computed_not_claimed(self) -> None:
        registry_topics = {row["topicId"]: row for row in self.registry["topics"]}
        for topic_id, progress in self.by_topic.items():
            row = registry_topics[topic_id]
            for lang, metrics in progress["languages"].items():
                expected = (
                    "deep_pass_complete"
                    if metrics["deepPassComplete"]
                    else (
                        "broad_pass_complete"
                        if metrics["broadPassComplete"]
                        else "pending_broad_pass"
                    )
                )
                self.assertEqual(row[lang]["nativeUsageProfileStatus"], expected)


if __name__ == "__main__":
    unittest.main()
