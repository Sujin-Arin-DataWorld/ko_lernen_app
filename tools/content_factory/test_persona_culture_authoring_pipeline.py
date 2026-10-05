from __future__ import annotations

import copy
import importlib.util
import json
from pathlib import Path
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "tools/content_factory/run_persona_culture_authoring.py"
SPEC = importlib.util.spec_from_file_location("run_persona_culture_authoring", MODULE_PATH)
assert SPEC and SPEC.loader
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)


class PersonaCultureAuthoringPipelineTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest_path = (
            ROOT
            / "tools/content_factory/drafts/batch_38_persona_culture_manifest.json"
        )
        cls.manifest = json.loads(cls.manifest_path.read_text(encoding="utf-8"))
        scenario_artifact = next(
            item
            for item in cls.manifest["artifacts"]
            if item["kind"] == "scenario"
        )
        cls.scenarios = json.loads(
            (ROOT / scenario_artifact["draft"]).read_text(encoding="utf-8")
        )["scenarios"]
        cls.culture_links = json.loads(
            (ROOT / cls.manifest["cultureLinksDraft"]).read_text(encoding="utf-8")
        )["links"]
        cls.story_arcs = json.loads(
            (ROOT / cls.manifest["cultureStoryArcsDraft"]).read_text(encoding="utf-8")
        )

    def test_batch38_full_review_only_pipeline_is_reproducible(self) -> None:
        report = module.run_pipeline(
            manifest_path=self.manifest_path,
            write_derived=False,
        )
        self.assertEqual(report["status"], "REVIEW_ONLY_PIPELINE_PASS")
        self.assertEqual(report["scenarioCount"], 5)
        self.assertEqual(report["cultureLinkCount"], 5)
        self.assertEqual(report["listening"]["lessons"], 5)
        self.assertEqual(report["listening"]["questions"], 20)
        self.assertEqual(report["vocabLeveling"]["totals"]["items"], 30)
        self.assertEqual(report["vocabLeveling"]["totals"]["cultureAnchor"], 5)
        self.assertEqual(report["cultureStoryArcs"]["arcCount"], 1)
        self.assertEqual(report["cultureStoryArcs"]["stepCount"], 4)
        self.assertEqual(
            report["cultureStoryArcs"]["arcIds"],
            ["found_around_nammun"],
        )
        self.assertFalse(report["cultureStoryArcs"]["liveWritePerformed"])
        packet = (ROOT / report["reviewPacket"]).read_text(encoding="utf-8")
        self.assertIn("## Culture Story Arcs (review-only)", packet)
        self.assertIn("`found_around_nammun`", packet)
        self.assertFalse(report["liveWritePerformed"])
        self.assertFalse(report["humanApprovalClaimed"])

    def test_authoring_brief_matches_scenario_people_and_culture_links(self) -> None:
        result = module._validate_authoring_brief(
            manifest=self.manifest,
            scenarios=self.scenarios,
            culture_links=self.culture_links,
        )
        self.assertEqual(result["sceneCount"], 5)
        checked_pairs = {
            (row["scenarioId"], row["left"], row["right"])
            for row in result["relationChecks"]
        }
        self.assertIn(
            (
                "b1_dongsun_norigae_shop_post",
                "maya",
                "dongsun",
            ),
            checked_pairs,
        )
        self.assertIn(
            (
                "c1_maya_hyuna_daniel_talchum_shortform",
                "hyuna",
                "daniel",
            ),
            checked_pairs,
        )

    def test_pipeline_rejects_an_undeclared_persona_relationship(self) -> None:
        profiles = module._profile_map()
        broken = copy.deepcopy(profiles)
        # Maya <-> Dongsun is required by the first brief. Remove both
        # directions to prove that a scene cannot silently invent a relation.
        broken["maya"]["relationships"].pop("dongsun", None)
        broken["dongsun"]["relationships"].pop("maya", None)
        with mock.patch.object(module, "_profile_map", return_value=broken):
            with self.assertRaisesRegex(
                module.PersonaCulturePipelineError,
                "undeclared persona relationship maya<->dongsun",
            ):
                module._validate_authoring_brief(
                    manifest=self.manifest,
                    scenarios=self.scenarios,
                    culture_links=self.culture_links,
                )

    def test_story_arc_matches_review_only_scenarios_personas_and_terms(self) -> None:
        result = module._validate_story_arcs(
            manifest=self.manifest,
            scenarios=self.scenarios,
            culture_links=self.culture_links,
        )
        self.assertEqual(result["arcCount"], 1)
        self.assertEqual(result["stepCount"], 4)
        self.assertEqual(result["arcIds"], ["found_around_nammun"])
        self.assertFalse(result["liveWritePerformed"])

    def test_story_arc_rejects_term_drift(self) -> None:
        broken = copy.deepcopy(self.story_arcs)
        broken["arcs"][0]["steps"][0]["termIds"] = ["hanji"]
        original_read_json = module._read_json

        def fake_read_json(path: Path, label: str) -> dict:
            if label == "culture story arcs":
                return broken
            return original_read_json(path, label)

        with mock.patch.object(module, "_read_json", side_effect=fake_read_json):
            with self.assertRaisesRegex(
                module.PersonaCulturePipelineError,
                "arc terms are not linked to the scenario",
            ):
                module._validate_story_arcs(
                    manifest=self.manifest,
                    scenarios=self.scenarios,
                    culture_links=self.culture_links,
                )

    def test_story_arc_rejects_reward_or_mastery_ownership(self) -> None:
        broken = copy.deepcopy(self.story_arcs)
        broken["arcs"][0]["rewardSlug"] = "decoration_soban"
        original_read_json = module._read_json

        def fake_read_json(path: Path, label: str) -> dict:
            if label == "culture story arcs":
                return broken
            return original_read_json(path, label)

        with mock.patch.object(module, "_read_json", side_effect=fake_read_json):
            with self.assertRaisesRegex(
                module.PersonaCulturePipelineError,
                "may not own reward/mastery state",
            ):
                module._validate_story_arcs(
                    manifest=self.manifest,
                    scenarios=self.scenarios,
                    culture_links=self.culture_links,
                )

    def test_pipeline_rejects_brief_culture_drift(self) -> None:
        links = copy.deepcopy(self.culture_links)
        links[0]["termIds"] = ["norigae"]
        with self.assertRaisesRegex(
            module.PersonaCulturePipelineError,
            "culture terms disagree",
        ):
            module._validate_authoring_brief(
                manifest=self.manifest,
                scenarios=self.scenarios,
                culture_links=links,
            )


if __name__ == "__main__":
    unittest.main()
