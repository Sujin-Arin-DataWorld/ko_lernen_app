from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "tools/content_factory/review/living_korea_first_wave_manifest_20261005.json"


class LivingKoreaFirstWaveManifestTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        cls.artifacts = {}
        for name, rel in cls.manifest["artifacts"].items():
            path = ROOT / rel
            cls.assert_path_exists(path, name)
            cls.artifacts[name] = path

    @staticmethod
    def assert_path_exists(path: Path, name: str) -> None:
        if not path.is_file():
            raise AssertionError(f"missing {name}: {path}")

    def test_review_ready_state_does_not_claim_live_or_human_approval(self) -> None:
        self.assertEqual(self.manifest["status"], "REVIEW_READY_NOT_LIVE")
        boundaries = self.manifest["scopeBoundaries"]
        self.assertTrue(boundaries["ttsOwnedByJin"])
        self.assertFalse(boundaries["ttsTouched"])
        self.assertFalse(boundaries["liveScenarioWritePerformed"])
        self.assertFalse(boundaries["masteryOwnershipChanged"])
        self.assertFalse(boundaries["rewardOwnershipChanged"])
        self.assertFalse(boundaries["humanLanguageApprovalClaimed"])
        self.assertFalse(boundaries["nativeSpeakerQaClaimed"])
        self.assertTrue(boundaries["securityContentDefensiveOnly"])
        self.assertEqual(
            self.manifest["reviewState"]["livePromotion"],
            "BLOCKED_ON_EXPLICIT_REVIEW",
        )

    def test_counts_reproduce_from_canonical_review_artifacts(self) -> None:
        topics = json.loads(
            self.artifacts["topicRegistry"].read_text(encoding="utf-8")
        )
        personas = json.loads(
            self.artifacts["personaCanon"].read_text(encoding="utf-8")
        )
        scenes = json.loads(
            self.artifacts["sceneDraft"].read_text(encoding="utf-8")
        )
        mining = json.loads(
            self.artifacts["languageMining"].read_text(encoding="utf-8")
        )
        cards = json.loads(
            self.artifacts["cultureCards"].read_text(encoding="utf-8")
        )
        counts = self.manifest["counts"]
        scene_rows = [
            scene for arc in scenes["arcs"] for scene in arc["scenes"]
        ]
        self.assertEqual(counts["canonicalPersonas"], len(personas["recurringCharacters"]))
        self.assertEqual(counts["frozenTopics"], len(topics["topics"]))
        self.assertEqual(counts["personaAssignments"], len(topics["personaAssignments"]))
        self.assertEqual(counts["firstWaveArcs"], len(scenes["arcs"]))
        self.assertEqual(counts["firstWaveScenes"], len(scene_rows))
        self.assertEqual(
            counts["dialogueTurns"],
            sum(len(scene["dialog"]) for scene in scene_rows),
        )
        self.assertEqual(counts["cultureCards"], len(cards["cards"]))
        self.assertEqual(
            counts["minedVocabularyTargets"],
            sum(len(row["vocabulary"]) for row in mining["scenes"]),
        )
        self.assertEqual(
            counts["minedGrammarTargets"],
            sum(len(row["grammar"]) for row in mining["scenes"]),
        )
        self.assertEqual(
            counts["minedPragmaticExpressions"],
            sum(len(row["pragmatics"]) for row in mining["scenes"]),
        )
        self.assertEqual(
            counts["registerMarkers"],
            sum(len(row["registerMarkers"]) for row in mining["scenes"]),
        )

    def test_d4_exit_matches_canonical_audit(self) -> None:
        audit = json.loads(
            self.artifacts["lcpAudit"].read_text(encoding="utf-8")
        )
        exit_state = self.manifest["d4Exit"]
        self.assertEqual(exit_state["sentenceUnknown"], audit["exitConditions"]["sentenceUnknown"])
        self.assertEqual(exit_state["minedVocabUnknown"], audit["exitConditions"]["minedVocabUnknown"])
        self.assertEqual(exit_state["minedVocabOver2"], audit["exitConditions"]["minedVocabOver2"])
        self.assertEqual(
            exit_state["maxSentenceLevelDelta"],
            audit["exitConditions"]["maxSentenceLevelDelta"],
        )
        global_effect = audit["globalLexiconSideEffect"]
        self.assertEqual(
            exit_state["globalClozeUnknown"],
            global_effect["clozeSentenceUnknownAfter"],
        )
        self.assertEqual(
            exit_state["globalClozeTokenCount"],
            global_effect["clozeTokenCount"],
        )
        self.assertEqual(
            exit_state["globalClozeUnknownRatchet"],
            global_effect["ratchetCap"],
        )

    def test_branch_dependency_is_explicit(self) -> None:
        dependency = self.manifest["dependency"]
        self.assertEqual(dependency["basePullRequest"], 449)
        self.assertIn("stacked", dependency["reason"].lower())


if __name__ == "__main__":
    unittest.main()
