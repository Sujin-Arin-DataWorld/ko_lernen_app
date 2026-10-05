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
