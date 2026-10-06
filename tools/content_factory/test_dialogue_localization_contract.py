from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CONTRACT = (
    ROOT
    / "tools"
    / "content_factory"
    / "canonical_scenarios"
    / "dialogue_localization_contract_20261006.json"
)
REGISTRY = (
    ROOT
    / "tools"
    / "content_factory"
    / "canonical_scenarios"
    / "trilingual_native_usage_registry_20261006.json"
)


class DialogueLocalizationContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
        cls.registry = json.loads(REGISTRY.read_text(encoding="utf-8"))

    def test_contract_is_canonical_and_ko_direct(self) -> None:
        self.assertEqual(self.contract["status"], "CANONICAL")
        principles = self.contract["principles"]
        self.assertTrue(principles["koreanIsSemanticPragmaticSourceOfTruth"])
        self.assertTrue(principles["englishAuthoredDirectlyFromKorean"])
        self.assertTrue(principles["germanAuthoredDirectlyFromKorean"])
        self.assertTrue(principles["englishAndGermanMustNotBeTranslationChains"])

    def test_contract_consumes_canonical_native_usage_registry(self) -> None:
        self.assertEqual(
            self.contract["dependencies"]["nativeUsageRegistry"],
            "tools/content_factory/canonical_scenarios/"
            "trilingual_native_usage_registry_20261006.json",
        )
        gate = self.contract["nativeUsageGate"]
        self.assertEqual(gate["requiredProfileStatus"], "deep_pass_complete")
        self.assertEqual(gate["requiredLanguages"], ["ko", "en", "de"])
        self.assertTrue(gate["requireCategoryShiftRisks"])
        self.assertTrue(gate["requirePedagogicalAlignmentNotes"])

    def test_all_32_topics_satisfy_localization_native_usage_gate(self) -> None:
        self.assertEqual(len(self.registry["topics"]), 32)
        for topic in self.registry["topics"]:
            with self.subTest(topic=topic["topicId"]):
                self.assertTrue(topic["crossLanguage"]["categoryShiftRisks"])
                self.assertTrue(topic["crossLanguage"]["pedagogicalAlignmentNotes"])
                for lang in ("ko", "en", "de"):
                    profile = topic[lang]
                    self.assertEqual(
                        profile["nativeUsageProfileStatus"],
                        "deep_pass_complete",
                    )
                    self.assertTrue(profile["researchDate"])
                    self.assertTrue(profile["avoidTranslationese"])
                    if topic["requiresAuthoritativeTermCheckForDeepPass"]:
                        self.assertTrue(profile["authoritativeTermChecks"])

    def test_display_and_spoken_surfaces_are_separate(self) -> None:
        surfaces = self.contract["surfacePolicies"]
        self.assertIn("spokenDialogue", surfaces)
        self.assertIn("ㅋㅋ", surfaces["spokenDialogue"]["rule"])
        self.assertIn("lol", surfaces["spokenDialogue"]["rule"])
        tts = self.contract["ttsBoundary"]
        self.assertEqual(tts["ttsOwner"], "Jin")
        self.assertFalse(tts["contentFactoryGeneratesTts"])

    def test_future_promotion_gate_starts_after_legacy_batches(self) -> None:
        promotion = self.contract["promotionPolicy"]
        self.assertEqual(promotion["futureScenarioBatchFloor"], 39)
        self.assertIn("1-38", promotion["legacyGrandfathering"])
        self.assertEqual(
            promotion["requiredManifestFields"],
            ["localizationContract", "nativeUsageTopicIds"],
        )


if __name__ == "__main__":
    unittest.main()
