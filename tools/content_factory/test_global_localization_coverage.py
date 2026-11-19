from __future__ import annotations

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LEDGER = ROOT / "tools/content_factory/review/global_localization_coverage_20261006.json"


class GlobalLocalizationCoverageTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
        cls.records = cls.ledger["records"]
        cls.summary = cls.ledger["summary"]

    def test_inventory_is_complete_for_registered_surfaces(self) -> None:
        self.assertEqual(self.summary["trackedSurfaceCount"], len(self.records))
        self.assertEqual(self.summary["trackedSurfaceCount"], 22631)
        self.assertEqual(self.summary["canonicalOwnerSurfaceCount"], 9339)
        self.assertEqual(self.summary["derivedSurfaceCount"], 13292)

    def test_every_registered_surface_has_ko_en_de(self) -> None:
        self.assertEqual(self.summary["missingLocalizedFieldCount"], 0)
        self.assertEqual(
            self.summary["allThreePresentCount"],
            self.summary["trackedSurfaceCount"],
        )
        for row in self.records:
            self.assertTrue(row["localizedPresence"]["ko"], row["itemId"])
            self.assertTrue(row["localizedPresence"]["en"], row["itemId"])
            self.assertTrue(row["localizedPresence"]["de"], row["itemId"])

    def test_living_korea_overlay_is_complete(self) -> None:
        rows = [r for r in self.records if r["surfaceType"] == "living_korea_turn"]
        self.assertEqual(len(rows), 138)
        self.assertTrue(all(r["allThreePresent"] for r in rows))
        self.assertTrue(all(r["canonicalTopicId"] for r in rows))
        self.assertTrue(all(r["approvalState"] == "live" for r in rows))

    def test_lesson_and_culture_surfaces_are_registered(self) -> None:
        expected = {
            "listening_lesson_title": 191,
            "listening_lesson_intro": 191,
            "listening_question_prompt": 764,
            "listening_question_explanation": 764,
            "listening_question_option": 1719,
            "smalltalk_lesson_title": 209,
            "smalltalk_lesson_intro": 209,
            "smalltalk_question_prompt": 799,
            "smalltalk_question_explanation": 799,
            "smalltalk_question_option": 2397,
            "culture_editorial_note": 36,
            "culture_story_title": 3,
            "culture_story_summary": 3,
        }
        for surface_type, count in expected.items():
            self.assertEqual(
                self.summary["bySurfaceType"][surface_type]["total"], count
            )
        self.assertEqual(sum(expected.values()), 8084)

    def test_derived_owner_debt_is_explicit(self) -> None:
        derived = [r for r in self.records if r["derived"]]
        unresolved = [r for r in derived if not r["ownerId"]]
        self.assertEqual(len(derived), self.summary["derivedSurfaceCount"])
        self.assertEqual(len(unresolved), self.summary["derivedOwnerUnresolvedCount"])
        self.assertEqual(len(unresolved), 609)
        self.assertTrue(all(r["ownerKind"] == "unresolved_owner" for r in unresolved))

    def test_topic_mapping_debt_is_explicit(self) -> None:
        unresolved = [r for r in self.records if r["canonicalTopicId"] is None]
        self.assertEqual(len(unresolved), self.summary["explicitTopicReviewCount"])
        self.assertTrue(
            all(r["topicReviewStatus"] == "manual_topic_review_required" for r in unresolved)
        )

    def test_g2_owner_surfaces_have_no_topic_mapping_debt(self) -> None:
        owner_types = {
            "vocab_lexeme",
            "vocab_example",
            "smalltalk_expression",
            "smalltalk_expression_variant",
            "smalltalk_followup",
        }
        owners = [r for r in self.records if r["surfaceType"] in owner_types]
        self.assertEqual(len(owners), 7706)
        self.assertTrue(all(r["canonicalTopicId"] for r in owners))
        self.assertTrue(all(r["topicReviewStatus"] == "mapped" for r in owners))

    def test_inventory_does_not_claim_quality_review(self) -> None:
        self.assertTrue(all(r["qaStatus"] == "inventory_only" for r in self.records))
        self.assertTrue(self.ledger["policy"]["inventoryDoesNotImplyQa"])
        self.assertTrue(self.ledger["policy"]["inventoryDoesNotImplyPromotion"])
        self.assertTrue(self.ledger["policy"]["ttsAudioUntouched"])


if __name__ == "__main__":
    unittest.main()
