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


class Batch39PersonaCultureDraftTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest_path = (
            ROOT / "tools/content_factory/drafts/batch_39_persona_culture_manifest.json"
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
        cls.vocab_review = json.loads(
            (ROOT / cls.manifest["vocabLevelingReview"]).read_text(encoding="utf-8")
        )

    def test_batch39_approved_bundle_has_expected_scenes(self) -> None:
        self.assertEqual(self.manifest["status"], "merged")
        self.assertFalse(self.manifest["provenance"]["humanLanguageQaClaim"])
        expected = [
            "a2_andrea_minho_bojagi_housewarming",
            "b1_minho_christian_hanok_cafe_meeting",
            "a2_lena_maya_buchae_gift_choice",
            "b2_maya_daniel_pansori_promo_clip",
            "b2_hyuna_daniel_nongak_festival_filming",
        ]
        self.assertEqual([scene["id"] for scene in self.scenarios], expected)

        review_path = ROOT / self.manifest["artifacts"][0]["review"]
        with review_path.open(encoding="utf-8-sig", newline="") as handle:
            rows = list(csv.DictReader(handle))
        self.assertEqual([row["id"] for row in rows], expected)
        self.assertTrue(all(row["상태"] == "approved" for row in rows))

    def test_existing_glossary_terms_are_reused_exactly(self) -> None:
        linked = {
            link["scenarioId"]: tuple(link["termIds"])
            for link in self.links
        }
        self.assertEqual(
            linked,
            {
                "a2_andrea_minho_bojagi_housewarming": ("bojagi",),
                "b1_minho_christian_hanok_cafe_meeting": ("hanok", "madang"),
                "a2_lena_maya_buchae_gift_choice": ("buchae",),
                "b2_maya_daniel_pansori_promo_clip": ("pansori",),
                "b2_hyuna_daniel_nongak_festival_filming": ("nongak",),
            },
        )

    def test_listening_is_grounded_in_dialogue(self) -> None:
        result = validate_records(
            self.listening,
            {scene["id"]: scene for scene in self.scenarios},
        )
        self.assertEqual(result["lessons"], 5)
        self.assertEqual(result["questions"], 20)

    def test_key_vocab_has_no_unresolved_level_debt(self) -> None:
        totals = self.vocab_review["totals"]
        self.assertEqual(totals["items"], 30)
        self.assertEqual(totals["cultureAnchor"], 6)
        self.assertEqual(totals["aboveTarget"], 0)
        self.assertEqual(totals["unmappedCandidate"], 0)

    def test_minho_is_activated_without_new_relationships(self) -> None:
        minho_scenes = [
            scene
            for scene in self.scenarios
            if "minho" in scene["participantIds"]
        ]
        self.assertEqual(len(minho_scenes), 2)
        report = pipeline.run_pipeline(
            manifest_path=self.manifest_path,
            write_derived=False,
        )
        self.assertEqual(report["status"], "MERGED_AUDIT_PASS")
        self.assertFalse(report["liveWritePerformed"])
        self.assertTrue(report["humanApprovalClaimed"])


if __name__ == "__main__":
    unittest.main()
