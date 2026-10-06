from __future__ import annotations

import csv
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/content_factory"))
sys.path.insert(0, str(ROOT / "tool"))

import run_persona_culture_authoring as pipeline  # noqa: E402
from validate_listening_lessons import validate_records  # noqa: E402


class Batch40PersonaCultureDraftTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest_path = (
            ROOT / "tools/content_factory/drafts/batch_40_persona_culture_manifest.json"
        )
        cls.manifest = json.loads(cls.manifest_path.read_text(encoding="utf-8"))
        artifact = cls.manifest["artifacts"][0]
        cls.scenarios = json.loads(
            (ROOT / artifact["draft"]).read_text(encoding="utf-8")
        )["scenarios"]
        cls.listening = json.loads(
            (ROOT / cls.manifest["listeningDraft"]).read_text(encoding="utf-8")
        )
        cls.links = json.loads(
            (ROOT / cls.manifest["cultureLinksDraft"]).read_text(encoding="utf-8")
        )["links"]
        cls.vocab = json.loads(
            (ROOT / cls.manifest["vocabLevelingReview"]).read_text(encoding="utf-8")
        )
        cls.arcs = json.loads(
            (ROOT / cls.manifest["cultureStoryArcsDraft"]).read_text(encoding="utf-8")
        )

    def test_batch40_is_review_only_with_expected_scenes(self) -> None:
        self.assertEqual(self.manifest["status"], "review_only_draft")
        expected = [
            "b1_jun_coding_club_speech_switch",
            "b1_minho_coworker_hoesik_leave_early",
            "a2_dongsun_christian_maehwa_gift",
            "b1_dongsun_customer_maedeup_repair",
            "b1_byeongcheol_hyuna_daecheong_rest",
        ]
        self.assertEqual([scene["id"] for scene in self.scenarios], expected)

        review_path = ROOT / self.manifest["artifacts"][0]["review"]
        with review_path.open(encoding="utf-8-sig", newline="") as handle:
            rows = list(csv.DictReader(handle))
        self.assertEqual([row["id"] for row in rows], expected)
        self.assertTrue(all(row["상태"] == "draft" for row in rows))

    def test_social_language_and_everyday_links_are_exact(self) -> None:
        linked = {
            row["scenarioId"]: tuple(row["termIds"])
            for row in self.links
        }
        self.assertEqual(
            linked,
            {
                "b1_jun_coding_club_speech_switch": (
                    "sunbae_hubae",
                    "jondaetmal_banmal",
                ),
                "b1_minho_coworker_hoesik_leave_early": ("hoesik",),
                "a2_dongsun_christian_maehwa_gift": ("maehwa",),
                "b1_dongsun_customer_maedeup_repair": ("maedeup",),
                "b1_byeongcheol_hyuna_daecheong_rest": ("daecheong",),
            },
        )

    def test_support_roles_do_not_become_recurring_personas(self) -> None:
        participants = {
            scene["id"]: tuple(scene["participantIds"])
            for scene in self.scenarios
        }
        self.assertEqual(
            participants["b1_jun_coding_club_speech_switch"],
            ("jun", "student"),
        )
        self.assertEqual(
            participants["b1_minho_coworker_hoesik_leave_early"],
            ("minho", "coworker"),
        )
        self.assertEqual(
            participants["b1_dongsun_customer_maedeup_repair"],
            ("dongsun", "customer"),
        )

        report = pipeline.run_pipeline(
            manifest_path=self.manifest_path,
            write_derived=False,
        )
        self.assertEqual(report["status"], "REVIEW_ONLY_PIPELINE_PASS")
        self.assertEqual(report["scenarioCount"], 5)
        self.assertFalse(report["liveWritePerformed"])
        self.assertFalse(report["humanApprovalClaimed"])

    def test_listening_is_grounded_in_dialogue(self) -> None:
        result = validate_records(
            self.listening,
            {scene["id"]: scene for scene in self.scenarios},
        )
        self.assertEqual(result["lessons"], 5)
        self.assertEqual(result["questions"], 20)

    def test_key_vocab_has_no_unresolved_level_debt(self) -> None:
        totals = self.vocab["totals"]
        self.assertEqual(totals["items"], 30)
        self.assertEqual(totals["aboveTarget"], 0)
        self.assertEqual(totals["unmappedCandidate"], 0)

    def test_story_arcs_are_derived_read_only(self) -> None:
        self.assertEqual(self.arcs["status"], "review_only")
        self.assertEqual(
            [arc["arcId"] for arc in self.arcs["arcs"]],
            [
                "relationship_language_in_daily_life",
                "patterns_repairs_and_spaces",
            ],
        )
        self.assertTrue(
            all(
                arc["progressMode"] == "derived_read_only"
                for arc in self.arcs["arcs"]
            )
        )


if __name__ == "__main__":
    unittest.main()
