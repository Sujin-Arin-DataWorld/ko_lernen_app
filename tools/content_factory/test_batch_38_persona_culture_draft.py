from __future__ import annotations

import csv
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool"))
from validate_listening_lessons import validate_records  # noqa: E402


class Batch38PersonaCultureDraftTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest = json.loads(
            (ROOT / "tools/content_factory/drafts/batch_38_persona_culture_manifest.json")
            .read_text(encoding="utf-8")
        )
        cls.scenarios = json.loads(
            (ROOT / cls.manifest["artifacts"][0]["draft"]).read_text(encoding="utf-8")
        )["scenarios"]
        cls.listening = json.loads(
            (ROOT / cls.manifest["listeningDraft"]).read_text(encoding="utf-8")
        )
        cls.culture_links = json.loads(
            (ROOT / cls.manifest["cultureLinksDraft"]).read_text(encoding="utf-8")
        )
        cls.glossary = json.loads(
            (ROOT / "docs/data/cultural_glossary.json").read_text(encoding="utf-8")
        )
        cls.profiles = json.loads(
            (
                ROOT
                / "tools/content_factory/canonical_scenarios/character_profiles.json"
            ).read_text(encoding="utf-8")
        )["recurringCharacters"]

    def test_batch_stays_review_only_with_exact_five_scenes(self) -> None:
        self.assertEqual(self.manifest["status"], "review_only_draft")
        self.assertTrue(self.manifest["provenance"]["requiresJinReview"])
        self.assertFalse(self.manifest["provenance"]["humanLanguageQaClaim"])
        expected = [
            "b1_dongsun_norigae_shop_post",
            "b1_byeongcheol_hwaseong_memory_check",
            "a2_jun_hwaseong_school_slide",
            "c1_maya_hyuna_daniel_talchum_shortform",
            "b2_daniel_hyuna_hanji_filming_scope",
        ]
        self.assertEqual([scene["id"] for scene in self.scenarios], expected)
        with (ROOT / self.manifest["artifacts"][0]["review"]).open(
            encoding="utf-8-sig", newline=""
        ) as handle:
            rows = list(csv.DictReader(handle))
        self.assertEqual([row["id"] for row in rows], expected)
        self.assertTrue(
            all(row["상태"] in {"draft", "approved"} for row in rows)
        )
        self.assertTrue(
            all(
                row["jin_memo"].strip()
                for row in rows
                if row["상태"] == "approved"
            )
        )

    def test_culture_links_cover_only_the_batch_and_live_glossary_terms(self) -> None:
        scenario_ids = [scene["id"] for scene in self.scenarios]
        links = self.culture_links["links"]
        self.assertEqual([link["scenarioId"] for link in links], scenario_ids)
        known_terms = {entry["termId"] for entry in self.glossary["entries"]}
        self.assertTrue(
            all(
                link["termIds"]
                and set(link["termIds"]).issubset(known_terms)
                and len(link["termIds"]) == len(set(link["termIds"]))
                for link in links
            )
        )
        self.assertEqual(self.manifest["cultureLinkCount"], len(links))

    def test_authored_listening_is_grounded_in_each_draft_scene(self) -> None:
        sources = {scene["id"]: scene for scene in self.scenarios}
        result = validate_records(self.listening, sources)
        self.assertEqual(result["lessons"], 5)
        self.assertEqual(result["questions"], 20)

    def test_cross_persona_pairs_exist_in_canonical_relationships(self) -> None:
        profiles = {item["id"]: item for item in self.profiles}
        required_pairs = [
            ("maya", "dongsun"),
            ("hyuna", "byeongcheol"),
            ("jun", "christian"),
            ("maya", "daniel"),
            ("hyuna", "daniel"),
        ]
        for left, right in required_pairs:
            left_rel = profiles[left].get("relationships", {})
            right_rel = profiles[right].get("relationships", {})
            self.assertTrue(
                right in left_rel or left in right_rel,
                f"{left} <-> {right} is not canonical",
            )


if __name__ == "__main__":
    unittest.main()
