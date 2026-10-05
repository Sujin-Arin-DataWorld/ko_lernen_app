from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REGISTRY = (
    ROOT
    / "tools"
    / "content_factory"
    / "canonical_scenarios"
    / "trilingual_native_usage_registry_20261006.json"
)
TAXONOMY = ROOT / "tools/content_factory/cefr_matrix/taxonomy.json"


class TrilingualNativeUsageRegistryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.registry = json.loads(REGISTRY.read_text(encoding="utf-8"))
        cls.taxonomy = json.loads(TAXONOMY.read_text(encoding="utf-8"))
        cls.rows = {row["topicId"]: row for row in cls.registry["topics"]}

    def test_registry_covers_all_32_canonical_topics_exactly_once(self) -> None:
        expected = {row["id"] for row in self.taxonomy["topics"]}
        self.assertEqual(len(expected), 32)
        self.assertEqual(set(self.rows), expected)
        self.assertEqual(len(self.rows), 32)

    def test_research_scope_includes_unreviewed_and_does_not_imply_approval(self) -> None:
        scope = self.registry["scope"]
        self.assertTrue(scope["includeReviewedContent"])
        self.assertTrue(scope["includeUnreviewedContent"])
        self.assertTrue(scope["includeLiveContent"])
        self.assertTrue(scope["includeDraftContent"])
        self.assertTrue(scope["approvalStateIndependentFromResearch"])

    def test_each_topic_has_independent_ko_en_de_profiles(self) -> None:
        for topic_id, row in self.rows.items():
            with self.subTest(topic=topic_id):
                for lang in ("ko", "en", "de"):
                    profile = row[lang]
                    self.assertIn("nativeUsageProfileStatus", profile)
                    self.assertIsInstance(profile["phraseBank"], list)
                    self.assertIsInstance(profile["avoidTranslationese"], list)
                    self.assertIsInstance(profile["registerNotes"], list)
                    self.assertIsInstance(profile["speechSurfaceNotes"], list)
                self.assertIn("crossLanguage", row)
                self.assertIsInstance(row["sources"], list)

    def test_research_protocol_has_measurable_completion_gates(self) -> None:
        protocol = self.registry["researchProtocol"]
        minimum = protocol["hardMinimumPerTopicLanguage"]
        self.assertEqual(minimum["independentSourceContexts"], 3)
        self.assertEqual(minimum["normalizedUsagePatterns"], 8)
        self.assertEqual(minimum["registerLanes"], 2)
        self.assertEqual(minimum["translationeseAvoidNotes"], 1)
        self.assertIn("unmappedReason", protocol["mappingRule"])
        self.assertIn("spoken-surface", protocol["ttsRule"])

    def test_language_policy_forbids_translation_chain_corpus(self) -> None:
        policy = self.registry["languagePolicy"]
        self.assertIn("independently", policy["en"].lower())
        self.assertIn("independently", policy["de"].lower())
        self.assertIn("Do not translate", policy["crossLanguageRule"])

    def test_community_sources_are_usage_evidence_not_fact_authority(self) -> None:
        policy = self.registry["sourcePolicy"]
        self.assertIn("word choice", policy["useCommunityFor"])
        self.assertIn("legal", policy["doNotUseCommunityFor"])
        self.assertTrue(policy["storePatternsNotQuotes"])


if __name__ == "__main__":
    unittest.main()
