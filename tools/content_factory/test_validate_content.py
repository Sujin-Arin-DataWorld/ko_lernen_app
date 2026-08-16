#!/usr/bin/env python3
"""Negative regression tests for the C0 content fast-fail gate.

Run with:
    python3 -m unittest tools/content_factory/test_validate_content.py
"""

from __future__ import annotations

import copy
import csv
import json
from pathlib import Path
import sys
import unittest
from unittest import mock


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from validate_content import ContentValidator


class ContentValidatorTest(unittest.TestCase):
    def _asset_json(self, name: str):
        with (Path("assets/data") / name).open(encoding="utf-8") as handle:
            return json.load(handle)

    def _with_json_override(self, **overrides):
        validator = ContentValidator()
        original_load_json = validator.load_json

        def load_json(name: str):
            return overrides[name] if name in overrides else original_load_json(name)

        validator.load_json = load_json  # type: ignore[method-assign]
        return validator

    @staticmethod
    def _messages(validator: ContentValidator) -> list[str]:
        return [issue.message for issue in validator.issues]

    def test_current_repository_content_passes(self) -> None:
        self.assertEqual(ContentValidator().validate(), [])

    def test_malformed_vocab_row_is_reported_without_crashing(self) -> None:
        with (Path("assets/data") / "korean_vocab.csv").open(
            encoding="utf-8-sig",
            newline="",
        ) as handle:
            reader = csv.DictReader(handle)
            header = list(reader.fieldnames or [])
            valid_row = next(reader)
        malformed_row = {field: None for field in header}

        validator = ContentValidator()
        original_load_csv = validator.load_csv

        def load_csv(name: str):
            if name == "korean_vocab.csv":
                return header, [valid_row, malformed_row]
            return original_load_csv(name)

        validator.load_csv = load_csv  # type: ignore[method-assign]
        validator.validate_vocab()

        messages = self._messages(validator)
        self.assertTrue(any("row 3 has an empty required field" in message for message in messages))
        self.assertTrue(any("row 3 has invalid vocab id" in message for message in messages))

    def test_pronunciation_requires_version_and_real_string_identity(self) -> None:
        pronunciation = copy.deepcopy(self._asset_json("pronunciation_phrases.json"))
        pronunciation.pop("version")
        pronunciation["phrases"][0]["id"] = 1
        pronunciation["phrases"][0]["level"] = 2

        validator = self._with_json_override(
            **{"pronunciation_phrases.json": pronunciation},
        )
        validator.validate_pronunciation()

        messages = self._messages(validator)
        self.assertTrue(any("version must be a positive integer" in m for m in messages))
        self.assertTrue(any("id must be a string" in m for m in messages))
        self.assertTrue(any("level must be an A1-C2 string" in m for m in messages))

    def test_game_meta_must_match_actual_items_for_all_levels(self) -> None:
        cloze = copy.deepcopy(self._asset_json("cloze.json"))
        cloze["meta"]["total"] -= 1
        cloze["meta"]["perLevel"].pop("c2")

        validator = self._with_json_override(**{"cloze.json": cloze})
        validator.validate_cloze()

        messages = self._messages(validator)
        self.assertTrue(any("meta.total must equal" in message for message in messages))
        self.assertTrue(any("meta.perLevel must contain exact" in message for message in messages))

    def test_audit_graph_counts_must_match_curriculum(self) -> None:
        audit = copy.deepcopy(self._asset_json("content_audit_manifest.json"))
        audit["graph"]["courseUnits"] -= 1
        audit["graph"]["courseUnitsByLevel"]["c2"] = 0
        audit["graph"]["formFamilies"] -= 1

        validator = self._with_json_override(
            **{"content_audit_manifest.json": audit},
        )
        validator.validate_audit_manifest({}, {}, [])

        messages = self._messages(validator)
        self.assertTrue(any("graph courseUnits is" in message for message in messages))
        self.assertTrue(any("graph courseUnitsByLevel is" in message for message in messages))
        self.assertTrue(any("graph formFamilies is" in message for message in messages))

    def test_scenario_vocab_object_and_id_type_are_required(self) -> None:
        scenarios = copy.deepcopy(self._asset_json("scenarios.json"))
        scenarios["scenarios"][0]["id"] = 1
        scenarios["scenarios"][0]["vocab"] = ["not-an-object"] * 6

        validator = self._with_json_override(**{"scenarios.json": scenarios})
        self.assertTrue(validator.validate())

        messages = self._messages(validator)
        self.assertTrue(any("id must be a string" in m for m in messages))
        self.assertTrue(any("vocab[0] must be an object" in m for m in messages))

    def test_silben_requires_runtime_word_schema_and_solvable_pool(self) -> None:
        silben = copy.deepcopy(self._asset_json("silben_puzzles.json"))
        puzzle = silben["levels"]["A1"][0]
        puzzle["words"][0].pop("german")
        puzzle["pool"] = ["절대없는음절"]

        validator = self._with_json_override(**{"silben_puzzles.json": silben})
        validator.validate_silben()

        messages = self._messages(validator)
        self.assertTrue(any("german must be a nonempty string" in m for m in messages))
        self.assertTrue(any("pool is missing solution syllable" in m for m in messages))

    def test_empty_kkeunmari_word_is_reported_without_an_index_error(self) -> None:
        kkeunmari = copy.deepcopy(self._asset_json("kkeunmari_pool.json"))
        kkeunmari["words"][0]["word"] = ""

        validator = self._with_json_override(**{"kkeunmari_pool.json": kkeunmari})
        validator.validate_kkeunmari()

        self.assertTrue(
            any("word must be a nonempty string" in m for m in self._messages(validator)),
        )

    def test_grammar_pattern_mirror_must_match_the_cloud_function_copy(self) -> None:
        validator = ContentValidator()
        mirror = (
            validator.root
            / "functions"
            / "analyze_korean_text"
            / "grammar_patterns.json"
        )
        original_read_bytes = Path.read_bytes

        def read_bytes(path: Path) -> bytes:
            if path == mirror:
                return b"[]"
            return original_read_bytes(path)

        with mock.patch.object(Path, "read_bytes", new=read_bytes):
            validator.validate_grammar_patterns()

        messages = self._messages(validator)
        self.assertTrue(any("must byte-match" in m for m in messages))
        self.assertTrue(any("JSON-equivalent" in m for m in messages))

    def test_new_vocab_pack_without_curriculum_mapping_fails_closed(self) -> None:
        manifest = copy.deepcopy(self._asset_json("curriculum_manifest.json"))
        manifest["vocabPackUnitMap"].pop("b1_work")

        validator = self._with_json_override(
            **{"curriculum_manifest.json": manifest},
        )
        validator.validate_curriculum_graph()

        self.assertTrue(
            any(
                "missing vocabPackUnitMap entry for source pack 'b1_work'" in m
                for m in self._messages(validator)
            ),
        )

    def test_stale_course_unit_audit_count_fails_closed(self) -> None:
        audit = copy.deepcopy(self._asset_json("content_audit_manifest.json"))
        audit["graph"]["courseUnits"] = 36

        validator = self._with_json_override(
            **{"content_audit_manifest.json": audit},
        )
        validator.validate()

        self.assertTrue(
            any(
                "graph courseUnits is 36, actual is 40" in message
                for message in self._messages(validator)
            ),
        )

    def test_stale_per_level_course_unit_audit_fails_closed(self) -> None:
        audit = copy.deepcopy(self._asset_json("content_audit_manifest.json"))
        audit["graph"]["courseUnitsByLevel"]["c2"] = 1

        validator = self._with_json_override(
            **{"content_audit_manifest.json": audit},
        )
        validator.validate()

        self.assertTrue(
            any(
                "graph courseUnitsByLevel" in message
                and "'c2': 2" in message
                for message in self._messages(validator)
            ),
        )


if __name__ == "__main__":
    unittest.main()
