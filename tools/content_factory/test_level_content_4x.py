#!/usr/bin/env python3
"""Regressions for the promoted Batch 09/10 4x content remainder.

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
if str(SCRIPT_DIR / "data") not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR / "data"))

import build_level_content_4x as builder
from integrate_scenario_batch import integrate
from rr_romanize import romanize_korean
from validate_promoted_batch import validate as validate_promoted_batch


BATCH_06_CLOZE = SCRIPT_DIR / "drafts" / "c2_batch06_cloze_b1_c2.json"
BATCH_06_SATZ = SCRIPT_DIR / "drafts" / "c2_batch06_satz_b1_c2.json"
BATCH_06_SMALLTALK = SCRIPT_DIR / "drafts" / "c2_batch06_smalltalk_b1_c2.json"
BATCH_06_SCENARIOS = SCRIPT_DIR / "drafts" / "c1_batch06_scenarios_b1_c2.json"
BATCH_09_MANIFEST = SCRIPT_DIR / "drafts" / "batch_09_4x_manifest.json"
BATCH_10_MANIFEST = SCRIPT_DIR / "drafts" / "batch_10_4x_manifest.json"
LIVE_SCENARIOS = SCRIPT_DIR.parents[1] / "assets" / "data" / "scenarios.json"
LIVE_SATZ = SCRIPT_DIR.parents[1] / "assets" / "data" / "satz_sentences.json"


def _json_ids(path: Path, collection: str) -> set[str]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return {str(item["id"]) for item in payload[collection]}


def _live_ids(path: Path, collection: str) -> set[str]:
    return _json_ids(path, collection)


class RevisedRomanizationTest(unittest.TestCase):
    def test_keeps_spaces_and_romanizes_hangul(self) -> None:
        self.assertEqual(romanize_korean("한글 소리"), "hangeul sori")
        self.assertEqual(romanize_korean("우체국"), "ucheguk")


class PackSourceTest(unittest.TestCase):
    def test_authored_packs_are_unique_korea_level_sets(self) -> None:
        packs = builder.load_packs()
        self.assertEqual(len(packs), 48)
        vocab, live_korean, _by_level_words, _used_satz, _live_scenarios = builder.load_live()
        authored_pack_ids = {pack["packId"] for pack in packs}
        other_live_korean = {
            row["korean"]
            for row in vocab
            if (row.get("pack_id") or "") not in authored_pack_ids
        }
        headwords: list[str] = []
        by_level: dict[str, int] = {}
        for pack in packs:
            words = pack["words"]
            self.assertEqual(len(words), 12, pack["packId"])
            by_level[pack["level"]] = by_level.get(pack["level"], 0) + 1
            for row in words:
                korean, _german, _english, _pos_de, _pos_en, example_ko, _de, _en = row
                self.assertIn(korean, example_ko, pack["packId"])
                self.assertNotIn(korean, other_live_korean, pack["packId"])
                self.assertIn(korean, live_korean, pack["packId"])
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


class Batch09ReviewDraftTest(unittest.TestCase):
    def test_manifest_counts_and_overlay_pass(self) -> None:
        manifest = json.loads(BATCH_09_MANIFEST.read_text(encoding="utf-8"))
        self.assertEqual(manifest["status"], "merged")
        self.assertEqual(manifest["batch"], "09")
        self.assertEqual(manifest["recordCount"], 1764)
        self.assertEqual(len(manifest["vocabPacks"]), 48)
        self.assertTrue(manifest["requiresCompleteSentenceDerivations"])
        orders = {level: [] for level in builder.LEVELS}
        for pack in manifest["vocabPacks"]:
            orders[pack["level"]].append(pack["orderInLevel"])
        builder.refresh_live_id_starts()
        for level, values in orders.items():
            self.assertEqual(values, list(range(values[0], values[0] + 8)))
            self.assertEqual(builder.PACK_ORDER_START[level], values[-1] + 1)
        promoted_count, inventory = validate_promoted_batch(BATCH_09_MANIFEST)
        self.assertEqual(promoted_count, 1764)
        self.assertEqual(inventory["vocab"], 2196)
        self.assertEqual(len(manifest["vocabPacks"]), 48)

    def test_review_ledgers_are_original_drafts(self) -> None:
        manifest = json.loads(BATCH_09_MANIFEST.read_text(encoding="utf-8"))
        for artifact in manifest["artifacts"]:
            with (SCRIPT_DIR.parents[1] / artifact["review"]).open(
                encoding="utf-8-sig",
                newline="",
            ) as handle:
                rows = list(csv.DictReader(handle))
            self.assertEqual(len(rows), artifact["count"], artifact["kind"])
            for row in rows:
                self.assertEqual(row["상태"], "approved")
                self.assertIn("rights: original", row["field_notes"])
                self.assertTrue(str(row.get("jin_memo") or "").strip())

    def test_ids_do_not_collide_with_live_or_batch_06(self) -> None:
        cloze_09 = _json_ids(SCRIPT_DIR / "drafts" / "c2_batch09_cloze_a1_c2.json", "items")
        satz_09 = _json_ids(SCRIPT_DIR / "drafts" / "c2_batch09_satz_a1_c2.json", "items")
        smalltalk_09 = _json_ids(
            SCRIPT_DIR / "drafts" / "c2_batch09_smalltalk_a1_c2.json",
            "phrases",
        )
        live_cloze = _live_ids(SCRIPT_DIR.parents[1] / "assets" / "data" / "cloze.json", "items")
        live_satz = _live_ids(LIVE_SATZ, "items")
        live_smalltalk = _live_ids(
            SCRIPT_DIR.parents[1] / "assets" / "data" / "smalltalk.json",
            "phrases",
        )
        self.assertTrue(cloze_09 <= live_cloze)
        self.assertTrue(satz_09 <= live_satz)
        self.assertTrue(smalltalk_09 <= live_smalltalk)
        self.assertFalse(cloze_09 & _json_ids(BATCH_06_CLOZE, "items"))
        self.assertFalse(satz_09 & _json_ids(BATCH_06_SATZ, "items"))
        self.assertFalse(smalltalk_09 & _json_ids(BATCH_06_SMALLTALK, "phrases"))


class Batch10KoreanQualityTest(unittest.TestCase):
    def test_batch_10_korean_has_no_latin_slug_or_object_particle_errors(self) -> None:
        from batch_10_scene_scripts import (
            GENERIC_SERVICE_SHELL,
            LATIN_IN_KO,
            SEED_KO_LEFTOVERS,
            SLANG_PASSWORD,
            TEMPLATE_LEFTOVERS,
            batchim_plus_reul,
            collect_korean_fields,
            frame_lines,
            render_scene,
            SEEDS,
        )

        scenarios = json.loads(
            (SCRIPT_DIR / "drafts" / "c1_batch10_scenarios_a1_c2.json").read_text(
                encoding="utf-8"
            )
        )["scenarios"]
        live = {
            row["id"]: row
            for row in json.loads(LIVE_SCENARIOS.read_text(encoding="utf-8"))["scenarios"]
        }
        self.assertEqual(len(scenarios), 174)
        for row in scenarios:
            ident = row["id"]
            self.assertEqual(row, live[ident], ident)
            for text in collect_korean_fields(row):
                self.assertFalse(
                    LATIN_IN_KO.search(text),
                    f"{ident} has Latin in Korean: {text}",
                )
                self.assertEqual(
                    batchim_plus_reul(text),
                    [],
                    f"{ident} has batchim+를: {text}",
                )
                for leftover in TEMPLATE_LEFTOVERS:
                    self.assertNotIn(leftover, text, ident)
                self.assertIsNone(
                    SLANG_PASSWORD.search(text),
                    f"{ident} uses slang 비번: {text}",
                )
                for leftover in SEED_KO_LEFTOVERS:
                    self.assertNotIn(leftover, text, f"{ident} leftover {leftover}: {text}")

    def test_batch_10_shell_lines_are_unique_per_scene(self) -> None:
        from batch_10_scene_scripts import (
            GENERIC_SERVICE_SHELL,
            HUMANIZER_SHELL_DE,
            HUMANIZER_SHELL_EN,
            HUMANIZER_SHELL_KO,
            SEEDS,
            frame_lines,
            render_scene,
        )

        catalog = {row[0]: (row[3], row[4], row[5]) for row in builder.scenario_catalog()}
        dialogs: dict[tuple[str, ...], str] = {}
        generic_hits = 0
        for ident, seed in SEEDS.items():
            title = catalog[ident]
            scene = render_scene(seed, ident=ident, title=title)
            dialog = scene["dialog"]
            shell = tuple(dialog[index]["ko"] for index in (0, 3, 4, 5, 7))
            full = tuple(line["ko"] for line in dialog)
            self.assertNotIn(full, dialogs, f"{ident} reuses dialog of {dialogs.get(full)}")
            dialogs[full] = ident
            if shell == GENERIC_SERVICE_SHELL:
                generic_hits += 1
            echoed = sum(1 for line in shell if title[0] and title[0] in line)
            self.assertLessEqual(echoed, 2, f"{ident} repeats title {title[0]!r} in shell {shell}")
            lines = frame_lines(ident, seed, *title)
            self.assertEqual(lines["open"][0], dialog[0]["ko"], ident)
            for slot, triple in lines.items():
                for leftover in HUMANIZER_SHELL_KO:
                    self.assertNotIn(leftover, triple[0], f"{ident} {slot} {triple[0]}")
                for leftover in HUMANIZER_SHELL_DE:
                    self.assertNotIn(leftover, triple[1], f"{ident} {slot} {triple[1]}")
                for leftover in HUMANIZER_SHELL_EN:
                    self.assertNotIn(leftover, triple[2], f"{ident} {slot} {triple[2]}")
            for field in ("need", "ask", "wait"):
                spoken_en = seed[field][2]
                self.assertNotIn("Shall I", spoken_en, f"{ident} {field}")
                self.assertNotIn("I will ", spoken_en, f"{ident} {field}")
                self.assertNotIn("in advance", spoken_en, f"{ident} {field}")
                self.assertNotIn("Bitte prüfen", seed[field][1], f"{ident} {field}")
        self.assertEqual(len(dialogs), 174)
        self.assertEqual(generic_hits, 0)


class Batch10ScenarioDraftTest(unittest.TestCase):
    def test_preview_adds_authored_scenarios_without_live_id_overlap(self) -> None:
        manifest = json.loads(BATCH_10_MANIFEST.read_text(encoding="utf-8"))
        self.assertEqual(manifest["status"], "merged")
        self.assertEqual(manifest["batch"], "10")
        scenarios = json.loads(
            (SCRIPT_DIR / "drafts" / "c1_batch10_scenarios_a1_c2.json").read_text(
                encoding="utf-8"
            )
        )["scenarios"]
        unused = json.loads(
            (SCRIPT_DIR / "drafts" / "c2_batch10_satz_unused_live.json").read_text(
                encoding="utf-8"
            )
        )["items"]
        self.assertEqual(len(scenarios), 174)
        self.assertEqual(manifest["recordCount"], 174 + len(unused))
        per_level = {level: 0 for level in builder.LEVELS}
        for row in scenarios:
            per_level[row["level"]] += 1
        self.assertEqual(per_level, {"a1": 45, "a2": 45, "b1": 32, "b2": 36, "c1": 8, "c2": 8})
        live_scenario_ids = _live_ids(LIVE_SCENARIOS, "scenarios")
        reserved = set(builder.RESERVED_SCENARIOS) | _json_ids(BATCH_06_SCENARIOS, "scenarios")
        draft_ids = {row["id"] for row in scenarios}
        self.assertFalse(draft_ids & reserved)
        self.assertTrue(draft_ids <= live_scenario_ids)

        counts, amount = integrate(manifest_path=BATCH_10_MANIFEST, apply=False)
        self.assertEqual(amount, 174 + len(unused))
        self.assertEqual(counts["scenario"], len(live_scenario_ids))
        self.assertEqual(counts["satz"], len(_live_ids(LIVE_SATZ, "items")))

    def test_unused_live_satz_avoids_batch_09_and_live_ids(self) -> None:
        satz_10 = _json_ids(SCRIPT_DIR / "drafts" / "c2_batch10_satz_unused_live.json", "items")
        satz_09 = _json_ids(SCRIPT_DIR / "drafts" / "c2_batch09_satz_a1_c2.json", "items")
        live_satz = _live_ids(LIVE_SATZ, "items")
        self.assertTrue(satz_10)
        self.assertFalse(satz_10 & satz_09)
        self.assertTrue(satz_10 <= live_satz)
        self.assertFalse(satz_10 & _json_ids(BATCH_06_SATZ, "items"))


class SupersededFourXTrackTest(unittest.TestCase):
    def test_old_4x_manifests_are_marked_superseded(self) -> None:
        old_07 = json.loads((SCRIPT_DIR / "drafts" / "batch_07_4x_manifest.json").read_text(encoding="utf-8"))
        old_08 = json.loads((SCRIPT_DIR / "drafts" / "batch_08_4x_manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(old_07["status"], "superseded")
        self.assertEqual(old_08["status"], "superseded")
        self.assertEqual(
            old_07["provenance"]["supersededBy"],
            "tools/content_factory/drafts/batch_09_4x_manifest.json",
        )
        self.assertEqual(
            old_08["provenance"]["supersededBy"],
            "tools/content_factory/drafts/batch_10_4x_manifest.json",
        )


if __name__ == "__main__":
    unittest.main()
