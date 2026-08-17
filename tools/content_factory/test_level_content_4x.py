#!/usr/bin/env python3
"""Regressions for the review-only Batch 07/08 4x content drafts.

Run with:
    python3 -m unittest tools/content_factory/test_level_content_4x.py
"""

from __future__ import annotations

import csv
import json
from pathlib import Path
import sys
import unittest


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import build_level_content_4x as builder
from integrate_scenario_batch import integrate
from rr_romanize import romanize_korean
from validate_batch_01 import validate_review_batch


BATCH_06_CLOZE = SCRIPT_DIR / "drafts" / "c2_batch06_cloze_b1_c2.json"
BATCH_06_SATZ = SCRIPT_DIR / "drafts" / "c2_batch06_satz_b1_c2.json"
BATCH_06_SMALLTALK = SCRIPT_DIR / "drafts" / "c2_batch06_smalltalk_b1_c2.json"
BATCH_06_SCENARIOS = SCRIPT_DIR / "drafts" / "c1_batch06_scenarios_b1_c2.json"
BATCH_07_MANIFEST = SCRIPT_DIR / "drafts" / "batch_07_manifest.json"
BATCH_08_MANIFEST = SCRIPT_DIR / "drafts" / "batch_08_manifest.json"


def _json_ids(path: Path, collection: str) -> set[str]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return {str(item["id"]) for item in payload[collection]}


class RevisedRomanizationTest(unittest.TestCase):
    def test_keeps_spaces_and_romanizes_hangul(self) -> None:
        self.assertEqual(romanize_korean("한글 소리"), "hangeul sori")
        self.assertEqual(romanize_korean("우체국"), "ucheguk")


class PackSourceTest(unittest.TestCase):
    def test_authored_packs_are_unique_korea_level_sets(self) -> None:
        packs = builder.load_packs()
        self.assertEqual(len(packs), 48)
        live_korean = builder.load_live()[1]
        headwords: list[str] = []
        by_level: dict[str, int] = {}
        for pack in packs:
            words = pack["words"]
            self.assertEqual(len(words), 12, pack["packId"])
            by_level[pack["level"]] = by_level.get(pack["level"], 0) + 1
            for row in words:
                korean, _german, _english, _pos_de, _pos_en, example_ko, _de, _en = row
                self.assertIn(korean, example_ko, pack["packId"])
                self.assertNotIn(korean, live_korean, pack["packId"])
                headwords.append(korean)
        self.assertEqual(len(headwords), 576)
        self.assertEqual(len(set(headwords)), 576)
        self.assertEqual(by_level, {level: 8 for level in builder.LEVELS})

    def test_grammar_quiz_focus_occurs_once_in_examples(self) -> None:
        rows = builder.grammar_records()
        self.assertEqual(len(rows), 24)
        for row in rows:
            self.assertEqual(row["example_german"].count(row["quiz_focus_de"]), 1, row["id"])
            self.assertEqual(row["example_en"].count(row["quiz_focus_en"]), 1, row["id"])
            distractors = row["quiz_distractor_ids"].split("|")
            self.assertEqual(len(distractors), 3, row["id"])
            self.assertNotIn(row["id"], distractors)


class Batch07ReviewDraftTest(unittest.TestCase):
    def test_manifest_counts_and_overlay_pass(self) -> None:
        manifest = json.loads(BATCH_07_MANIFEST.read_text(encoding="utf-8"))
        self.assertEqual(manifest["status"], "review_only_draft")
        self.assertEqual(manifest["recordCount"], 1764)
        self.assertEqual(len(manifest["vocabPacks"]), 48)
        self.assertTrue(manifest["requiresCompleteSentenceDerivations"])
        result = validate_review_batch(manifest_path=BATCH_07_MANIFEST)
        self.assertEqual(result.record_count, 1764)
        self.assertEqual(len(result.planned_pack_ids), 48)

    def test_review_ledgers_are_original_drafts(self) -> None:
        manifest = json.loads(BATCH_07_MANIFEST.read_text(encoding="utf-8"))
        for artifact in manifest["artifacts"]:
            with (SCRIPT_DIR.parents[1] / artifact["review"]).open(
                encoding="utf-8-sig",
                newline="",
            ) as handle:
                rows = list(csv.DictReader(handle))
            self.assertEqual(len(rows), artifact["count"], artifact["kind"])
            for row in rows:
                self.assertEqual(row["상태"], "draft")
                self.assertIn("rights: original", row["field_notes"])

    def test_ids_do_not_collide_with_batch_06(self) -> None:
        cloze_07 = _json_ids(SCRIPT_DIR / "drafts" / "c2_batch07_cloze_a1_c2.json", "items")
        satz_07 = _json_ids(SCRIPT_DIR / "drafts" / "c2_batch07_satz_a1_c2.json", "items")
        smalltalk_07 = _json_ids(
            SCRIPT_DIR / "drafts" / "c2_batch07_smalltalk_a1_c2.json",
            "phrases",
        )
        self.assertFalse(cloze_07 & _json_ids(BATCH_06_CLOZE, "items"))
        self.assertFalse(satz_07 & _json_ids(BATCH_06_SATZ, "items"))
        self.assertFalse(smalltalk_07 & _json_ids(BATCH_06_SMALLTALK, "phrases"))


class Batch08ScenarioDraftTest(unittest.TestCase):
    def test_preview_reaches_four_times_live_scenarios(self) -> None:
        manifest = json.loads(BATCH_08_MANIFEST.read_text(encoding="utf-8"))
        self.assertEqual(manifest["status"], "review_only")
        self.assertEqual(manifest["recordCount"], 815)
        scenarios = json.loads(
            (SCRIPT_DIR / "drafts" / "c1_batch08_scenarios_a1_c2.json").read_text(
                encoding="utf-8"
            )
        )["scenarios"]
        self.assertEqual(len(scenarios), 174)
        per_level = {level: 0 for level in builder.LEVELS}
        for row in scenarios:
            per_level[row["level"]] += 1
        self.assertEqual(per_level, {"a1": 45, "a2": 45, "b1": 32, "b2": 36, "c1": 8, "c2": 8})
        reserved = set(builder.RESERVED_SCENARIOS) | _json_ids(BATCH_06_SCENARIOS, "scenarios")
        self.assertFalse({row["id"] for row in scenarios} & reserved)

        counts, amount = integrate(manifest_path=BATCH_08_MANIFEST, apply=False)
        self.assertEqual(amount, 815)
        self.assertEqual(counts["scenario"], 232)
        self.assertEqual(counts["satz"], 1060)

    def test_unused_live_satz_avoids_reserved_ids(self) -> None:
        satz_08 = _json_ids(SCRIPT_DIR / "drafts" / "c2_batch08_satz_unused_live.json", "items")
        satz_07 = _json_ids(SCRIPT_DIR / "drafts" / "c2_batch07_satz_a1_c2.json", "items")
        self.assertEqual(len(satz_08), 641)
        self.assertFalse(satz_08 & satz_07)
        self.assertFalse(satz_08 & _json_ids(BATCH_06_SATZ, "items"))


if __name__ == "__main__":
    unittest.main()
