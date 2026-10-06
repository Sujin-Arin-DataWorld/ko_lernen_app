from __future__ import annotations

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LOCALIZATION = ROOT / "tools/content_factory/review/living_korea_localization_20261006.json"
REGISTRY = ROOT / "tools/content_factory/canonical_scenarios/trilingual_native_usage_registry_20261006.json"
FIRST = ROOT / "tools/content_factory/drafts/living_korea_scene_first_drafts_20261005.json"
SECOND = ROOT / "tools/content_factory/drafts/living_korea_second_wave_scene_first_drafts_20261005.json"

SPINE_FIELDS = {
    "semanticCore",
    "speechAct",
    "relationship",
    "authority",
    "tone",
    "humanBeat",
    "mustPreserve",
    "mayAdapt",
    "mustNotBecome",
    "registerLane",
}


def load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


class LivingKoreaLocalizationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.out = load(LOCALIZATION)
        cls.registry = load(REGISTRY)
        cls.source_scenes = {}
        for path in (FIRST, SECOND):
            payload = load(path)
            for arc in payload["arcs"]:
                for scene in arc["scenes"]:
                    cls.source_scenes[scene["id"]] = scene

    def test_covers_all_23_scenes_and_138_turns(self) -> None:
        localized = {row["sceneId"]: row for row in self.out["scenes"]}
        self.assertEqual(set(localized), set(self.source_scenes))
        self.assertEqual(len(localized), 23)
        self.assertEqual(sum(len(row["turns"]) for row in localized.values()), 138)
        self.assertEqual(self.out["summary"]["promotionReadySceneCount"], 23)

    def test_every_scene_has_complete_localization_spine(self) -> None:
        for scene in self.out["scenes"]:
            self.assertTrue(SPINE_FIELDS.issubset(scene["localizationSpine"]))
            for field in SPINE_FIELDS:
                value = scene["localizationSpine"][field]
                self.assertNotIn(value, (None, "", []), (scene["sceneId"], field))

    def test_every_native_usage_topic_is_deep_pass_complete(self) -> None:
        registry = {row["topicId"]: row for row in self.registry["topics"]}
        for scene in self.out["scenes"]:
            topic_id = scene["canonicalNativeUsageTopicId"]
            self.assertIn(topic_id, registry)
            self.assertEqual(
                registry[topic_id]["researchStatus"],
                "deep_pass_complete",
                scene["sceneId"],
            )

    def test_every_turn_has_display_and_spoken_en_de(self) -> None:
        for scene in self.out["scenes"]:
            source = self.source_scenes[scene["sceneId"]]
            self.assertEqual(len(scene["turns"]), len(source["dialog"]))
            for turn, src in zip(scene["turns"], source["dialog"]):
                self.assertEqual(turn["ko"], src["ko"])
                for field in ("enDisplay", "deDisplay", "enSpoken", "deSpoken"):
                    self.assertTrue(turn[field].strip(), (scene["sceneId"], field))

    def test_chat_only_markers_are_not_in_spoken_surfaces(self) -> None:
        forbidden = ("ㅋㅋ", "ㅎㅎ", "lmao", " lol", "haha")
        for scene in self.out["scenes"]:
            for turn in scene["turns"]:
                spoken = (turn["enSpoken"] + " " + turn["deSpoken"]).lower()
                for marker in forbidden:
                    self.assertNotIn(marker, spoken, (scene["sceneId"], turn["turnIndex"]))

    def test_phishing_scenes_do_not_literalize_voice_phishing(self) -> None:
        for scene in self.out["scenes"]:
            if "voice_phishing_digital_safety_2026" not in scene["contemporaryTopicIds"]:
                continue
            for turn in scene["turns"]:
                localized = (turn["enDisplay"] + " " + turn["deDisplay"]).lower()
                self.assertNotIn("voice phishing", localized)

    def test_corpus_qa_is_not_mislabeled_as_human_native_review(self) -> None:
        self.assertFalse(self.out["policy"]["humanNativeReviewedClaimed"])
        for scene in self.out["scenes"]:
            qa = scene["nativeUsageQa"]
            self.assertEqual(qa["status"], "corpus_qa_complete")
            self.assertFalse(qa["humanNativeReviewed"])
            self.assertEqual(scene["promotion"]["status"], "promotion_ready")
            self.assertFalse(scene["promotion"]["liveWritePerformed"])

    def test_tts_boundary_is_preserved(self) -> None:
        self.assertFalse(self.out["policy"]["ttsAudioGenerated"])
        self.assertTrue(self.out["policy"]["spokenSurfacePrepared"])


if __name__ == "__main__":
    unittest.main()
