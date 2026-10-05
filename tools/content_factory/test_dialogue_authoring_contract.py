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
    / "dialogue_authoring_contract_20261006.json"
)
PROFILES = (
    ROOT
    / "tools"
    / "content_factory"
    / "canonical_scenarios"
    / "character_profiles.json"
)
FIRST_WAVE = (
    ROOT
    / "tools"
    / "content_factory"
    / "drafts"
    / "living_korea_scene_first_drafts_20261005.json"
)
SECOND_WAVE = (
    ROOT
    / "tools"
    / "content_factory"
    / "drafts"
    / "living_korea_second_wave_scene_first_drafts_20261005.json"
)
AUTHORING_BRIEF = (
    ROOT
    / "tools"
    / "content_factory"
    / "drafts"
    / "persona_culture_authoring_brief_20261005.json"
)
AUTHORING_PIPELINE = (
    ROOT
    / "tools"
    / "content_factory"
    / "review"
    / "persona_culture_authoring_pipeline_20261005.json"
)


class DialogueAuthoringContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
        cls.profiles = json.loads(PROFILES.read_text(encoding="utf-8"))
        cls.persona_ids = {
            row["id"] for row in cls.profiles["recurringCharacters"]
        }

    def test_contract_is_canonical_and_scene_first(self) -> None:
        self.assertEqual(self.contract["schemaVersion"], 1)
        self.assertEqual(self.contract["status"], "CANONICAL")
        principles = self.contract["principles"]
        self.assertTrue(principles["relationshipBeforeTopic"])
        self.assertTrue(principles["naturalDialogueBeforePedagogy"])
        self.assertTrue(principles["languageMiningAfterDialogue"])
        self.assertTrue(principles["cefrMayChangeSceneLevelInsteadOfFlatteningCharacter"])
        self.assertTrue(principles["userReviewedNaturalnessOverridesModelDraft"])

    def test_all_canonical_personas_have_distinct_human_beat_guidance(self) -> None:
        styles = self.contract["personaHumanBeatStyles"]
        self.assertEqual(set(styles), self.persona_ids)
        for persona_id, style in styles.items():
            with self.subTest(persona=persona_id):
                self.assertTrue(style["preferred"])
                self.assertTrue(style["avoid"])
                self.assertEqual(
                    len(style["preferred"]),
                    len(set(style["preferred"])),
                )

    def test_relationship_register_overrides_match_profile_canon(self) -> None:
        rules = self.contract["relationshipRegisterRules"]
        self.assertIn("mutual banmal", rules["sujin_christian"]["current"])
        self.assertIn("mutual banmal", rules["andrea_minho"]["private"])

        edges = {
            frozenset((row["a"], row["b"])): row
            for row in self.profiles["relationshipGraph"]["edges"]
        }
        sujin_christian = edges[frozenset(("sujin", "christian"))]
        andrea_minho = edges[frozenset(("andrea", "minho"))]
        self.assertIn("현재 연애 시점에서는 서로 반말", sujin_christian["registerKo"])
        self.assertIn("사적 대화에서는 서로 반말", andrea_minho["registerKo"])

    def test_human_beat_policy_requires_relationship_texture_not_random_jokes(self) -> None:
        policy = self.contract["humanBeatPolicy"]
        self.assertTrue(policy["required"])
        self.assertEqual(policy["minimumPerSixTurnScene"], 1)
        self.assertGreaterEqual(len(policy["allowedTypes"]), 8)
        self.assertIn("danger", policy["seriousSceneRule"].lower())
        self.assertIn("any character", policy["antiPattern"])

    def test_anti_textbook_contract_guards_the_two_user_review_failures(self) -> None:
        text = "\n".join(self.contract["antiTextbookRules"])
        self.assertIn("textbook", text)
        self.assertIn("universal expert", text)
        self.assertIn("grammar target", text)
        self.assertIn("childish", text)
        self.assertIn("moral", text)

    def test_review_loop_requires_remining_after_human_copy_change(self) -> None:
        order = "\n".join(self.contract["authoringOrder"])
        self.assertIn("discard stale mined targets", order)
        self.assertIn("re-mine/re-audit", order)

    def test_current_persona_dialogue_artifacts_reference_contract(self) -> None:
        expected = (
            "tools/content_factory/canonical_scenarios/"
            "dialogue_authoring_contract_20261006.json"
        )
        for path in (
            FIRST_WAVE,
            SECOND_WAVE,
            AUTHORING_BRIEF,
            AUTHORING_PIPELINE,
        ):
            payload = json.loads(path.read_text(encoding="utf-8"))
            with self.subTest(path=path.name):
                self.assertEqual(payload["dialogueAuthoringContract"], expected)
        pipeline = json.loads(AUTHORING_PIPELINE.read_text(encoding="utf-8"))
        self.assertTrue(
            pipeline["dialogueAuthoringContractRequiredForFuturePersonaDialogue"]
        )


if __name__ == "__main__":
    unittest.main()
