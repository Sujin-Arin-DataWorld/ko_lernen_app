#!/usr/bin/env python3
"""Negative regression tests for the C0 content fast-fail gate.

Run with:
    python3 -m unittest tools/content_factory/test_validate_content.py
"""

from __future__ import annotations

import copy
import csv
import json
import tempfile
from pathlib import Path
import sys
import unittest
from unittest import mock


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import relevel_ledger
import scenario_store
from validate_content import ContentValidator


class ContentValidatorTest(unittest.TestCase):
    def _asset_json(self, name: str):
        # F6: content_audit_manifest.json은 assets/data/가 아니라
        # tools/content_factory/에 산다(번들 제외).
        directory = (
            Path("tools/content_factory")
            if name == "content_audit_manifest.json"
            else Path("assets/data")
        )
        with (directory / name).open(encoding="utf-8") as handle:
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

    def test_cloze_accepted_variants_are_additional_and_never_distractors(self) -> None:
        cloze = copy.deepcopy(self._asset_json("cloze.json"))
        item = cloze["items"][0]
        item["acceptedVariants"] = [item["answer"], item["distractors"][0], "  "]

        validator = self._with_json_override(**{"cloze.json": cloze})
        validator.validate_cloze()

        messages = self._messages(validator)
        self.assertTrue(any("must not repeat the canonical answer" in m for m in messages))
        self.assertTrue(any("must not overlap distractors" in m for m in messages))
        self.assertTrue(any("must contain trimmed nonempty strings" in m for m in messages))

    def test_dictation_variants_allow_surface_changes_but_reject_paraphrases(self) -> None:
        valid = {
            "targetKo": "안내: ‘지금 바로 답드리기보다는, 다시 말씀드릴게요.’",
            "promptDe": "Ich melde mich noch einmal.",
            "promptEn": "I'll get back to you.",
            "acceptedVariants": ["안내 지금 바로 답드리기 보다는 다시 말씀드릴게요"],
        }
        validator = ContentValidator()
        validator._validate_quest(
            "fixture.json",
            "fixture",
            0,
            {"type": "diktat", "data": valid},
        )
        self.assertEqual(self._messages(validator), [])

        invalid = copy.deepcopy(valid)
        invalid["acceptedVariants"] = ["조금 생각해 보고 나중에 연락드릴게요."]
        validator = ContentValidator()
        validator._validate_quest(
            "fixture.json",
            "fixture",
            0,
            {"type": "diktat", "data": invalid},
        )
        self.assertTrue(
            any(
                "must preserve the canonical lexical sequence" in message
                for message in self._messages(validator)
            ),
        )

    def test_dictation_prompt_ko_is_optional_but_must_differ_from_target(self) -> None:
        base = {
            "targetKo": "강남역까지 가주세요.",
            "promptDe": "Bis zur Gangnam Station, bitte.",
            "promptEn": "To Gangnam Station, please.",
        }

        # promptKo 없음 — 허용(§9-3: 선택 필드).
        validator = ContentValidator()
        validator._validate_quest(
            "fixture.json",
            "fixture",
            0,
            {"type": "diktat", "data": dict(base)},
        )
        self.assertEqual(self._messages(validator), [])

        # promptKo가 targetKo와 다른 쉬운 한국어 풀이 — 허용.
        valid = dict(base, promptKo="지하철역 쪽으로 가 주세요.")
        validator = ContentValidator()
        validator._validate_quest(
            "fixture.json",
            "fixture",
            0,
            {"type": "diktat", "data": valid},
        )
        self.assertEqual(self._messages(validator), [])

        # promptKo가 targetKo와 (앞뒤 공백 제외) 동일 — 거부.
        same_as_target = dict(base, promptKo="  강남역까지 가주세요.  ")
        validator = ContentValidator()
        validator._validate_quest(
            "fixture.json",
            "fixture",
            0,
            {"type": "diktat", "data": same_as_target},
        )
        self.assertTrue(
            any(
                "promptKo must differ from targetKo" in message
                for message in self._messages(validator)
            ),
        )

        # promptKo가 공백뿐 — 거부.
        blank = dict(base, promptKo="   ")
        validator = ContentValidator()
        validator._validate_quest(
            "fixture.json",
            "fixture",
            0,
            {"type": "diktat", "data": blank},
        )
        self.assertTrue(
            any(
                "promptKo must be a nonempty string" in message
                for message in self._messages(validator)
            ),
        )

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
        # 코퍼스는 레벨 샤드 6 개라 파일명 하나로는 갈아끼울 수 없다.
        # 병합 뷰를 돌려주는 메서드가 유일한 주입 지점이다.
        scenarios = copy.deepcopy(scenario_store.load_root())
        scenarios["scenarios"][0]["id"] = 1
        scenarios["scenarios"][0]["vocab"] = ["not-an-object"] * 6

        validator = ContentValidator()
        validator.load_scenario_root = lambda: scenarios  # type: ignore[method-assign]
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
                "graph courseUnits is 36, actual is 48" in message
                for message in self._messages(validator)
            ),
        )

    def test_vocab_level_id_mismatch_is_rejected_unless_a_registered_legacy_exception(
        self,
    ) -> None:
        with (Path("assets/data") / "korean_vocab.csv").open(
            encoding="utf-8-sig",
            newline="",
        ) as handle:
            reader = csv.DictReader(handle)
            header = list(reader.fieldnames or [])
            rows = list(reader)
        by_id = {row["id"]: row for row in rows}

        # Unregistered id/level mismatch must still fail closed.
        mismatched_row = dict(rows[0])
        mismatched_row["id"] = "vocab_a1_9999"
        mismatched_row["level"] = "B1"

        validator = ContentValidator()
        original_load_csv = validator.load_csv

        def load_csv(name: str):
            if name == "korean_vocab.csv":
                return header, [mismatched_row]
            return original_load_csv(name)

        validator.load_csv = load_csv  # type: ignore[method-assign]
        validator.validate_vocab()
        messages = self._messages(validator)
        self.assertTrue(
            any(
                "id level disagrees with row level and is not in relevel ledger" in m
                for m in messages
            ),
        )

        # relevel_ledger.json (T1.7, plan §4.3) entry for vocab_a1_0216 —
        # ledgered id must not trip the id/level check. Built as two
        # in-memory ledgers (with/without the entry) and injected through
        # the constructor's `ledger` kwarg, rather than relying on
        # whatever relevel_ledger.json happens to contain on disk.
        registered_row = dict(by_id["vocab_a1_0216"])
        self.assertEqual(registered_row["level"].upper(), "B1")

        entry = relevel_ledger.LedgerEntry(
            id="vocab_a1_0216",
            kind="vocab",
            from_level="a1",
            to_level="b1",
            movedAt="2026-09-05",
            batch="relevel_002",
            reason="test fixture",
        )
        ledger_without_entry = relevel_ledger.Ledger(version=1, entries=[])
        ledger_with_entry = ledger_without_entry.append(entry)

        # Without the entry the ledger still tolerates nothing -- same
        # violation as the unregistered case above.
        validator_without = ContentValidator(ledger=ledger_without_entry)

        def load_csv_registered(name: str):
            if name == "korean_vocab.csv":
                return header, [registered_row]
            return original_load_csv(name)

        validator_without.load_csv = load_csv_registered  # type: ignore[method-assign]
        validator_without.validate_vocab()
        messages_without = self._messages(validator_without)
        self.assertTrue(
            any(
                "id level disagrees with row level and is not in relevel ledger" in m
                for m in messages_without
            ),
        )

        # With the entry present, the same row is tolerated.
        validator2 = ContentValidator(ledger=ledger_with_entry)
        validator2.load_csv = load_csv_registered  # type: ignore[method-assign]
        validator2.validate_vocab()
        messages2 = self._messages(validator2)
        self.assertFalse(any("id level disagrees" in m for m in messages2))

    def test_cloze_level_id_mismatch_is_rejected_unless_a_registered_legacy_exception(
        self,
    ) -> None:
        cloze = self._asset_json("cloze.json")
        items_by_id = {item["id"]: item for item in cloze["items"]}

        def single_item_payload(item: dict) -> dict:
            payload = copy.deepcopy(cloze)
            payload["items"] = [item]
            level = item["level"]
            payload["meta"]["total"] = 1
            payload["meta"]["perLevel"] = {
                lvl: (1 if lvl == level else 0)
                for lvl in ("a1", "a2", "b1", "b2", "c1", "c2")
            }
            return payload

        # Unregistered id/level mismatch must still fail closed.
        mismatched = copy.deepcopy(items_by_id["cloze_a1_0001"])
        mismatched["id"] = "cloze_a1_9999"
        mismatched["level"] = "b1"

        validator = self._with_json_override(
            **{"cloze.json": single_item_payload(mismatched)},
        )
        validator.validate_cloze()
        messages = self._messages(validator)
        self.assertTrue(
            any(
                "cloze_a1_9999 id level disagrees with b1 and is not in relevel ledger" in m
                for m in messages
            ),
        )

        # relevel_ledger.json (T1.7, plan §4.3) entry for cloze_a1_0104 —
        # ledgered id must not trip the id/level check.
        registered = items_by_id["cloze_a1_0104"]
        self.assertEqual(registered["level"], "b1")

        validator2 = self._with_json_override(
            **{"cloze.json": single_item_payload(registered)},
        )
        validator2.validate_cloze()
        messages2 = self._messages(validator2)
        self.assertFalse(any("id level disagrees" in m for m in messages2))

    def test_satz_level_id_mismatch_is_rejected_unless_a_registered_legacy_exception(
        self,
    ) -> None:
        vocab_levels = ContentValidator().validate_vocab()
        satz = self._asset_json("satz_sentences.json")
        items_by_id = {item["id"]: item for item in satz["items"]}

        def single_item_payload(item: dict) -> dict:
            payload = copy.deepcopy(satz)
            payload["items"] = [item]
            level = item["level"]
            payload["meta"]["total"] = 1
            payload["meta"]["perLevel"] = {
                lvl: (1 if lvl == level else 0)
                for lvl in ("a1", "a2", "b1", "b2", "c1", "c2")
            }
            return payload

        # Unregistered id/level mismatch must still fail closed.
        mismatched = copy.deepcopy(items_by_id["satz_a1_0001"])
        mismatched["id"] = "satz_a1_9999"
        mismatched["level"] = "b1"

        validator = self._with_json_override(
            **{"satz_sentences.json": single_item_payload(mismatched)},
        )
        validator.validate_satz(vocab_levels)
        messages = self._messages(validator)
        self.assertTrue(
            any(
                "satz_a1_9999 id level disagrees with b1 and is not in relevel ledger" in m
                for m in messages
            ),
        )

        # relevel_ledger.json (T1.7, plan §4.3) entry for satz_a1_0068 —
        # ledgered id must not trip the id/level check.
        registered = items_by_id["satz_a1_0068"]
        self.assertEqual(registered["level"], "b1")

        validator2 = self._with_json_override(
            **{"satz_sentences.json": single_item_payload(registered)},
        )
        validator2.validate_satz(vocab_levels)
        messages2 = self._messages(validator2)
        self.assertFalse(any("id level disagrees" in m for m in messages2))

    def test_removing_a_ledgered_id_from_a_temp_copied_ledger_reports_that_id(
        self,
    ) -> None:
        """T1.7 (b): trim `vocab_a1_0216` out of a temp copy of
        relevel_ledger.json, load that copy from disk, and confirm the
        validator regains the exact violation the ledger used to
        suppress -- proving the ledger is load-bearing, not decorative."""

        # Read the real, on-disk relevel_ledger.json (the copy this
        # checkout ships) rather than going through
        # relevel_ledger.load_ledger()'s own module-relative default, so
        # this test does not depend on ContentValidator's default
        # resolution behaviour -- only on the constructor's `ledger_path`
        # kwarg, which is exactly what this test is proving works.
        live_ledger_path = relevel_ledger.DEFAULT_LEDGER_PATH
        live_dict = json.loads(live_ledger_path.read_text(encoding="utf-8"))
        trimmed_dict = copy.deepcopy(live_dict)
        trimmed_dict["entries"] = [
            entry for entry in trimmed_dict["entries"] if entry["id"] != "vocab_a1_0216"
        ]
        assert len(trimmed_dict["entries"]) == len(live_dict["entries"]) - 1

        with (Path("assets/data") / "korean_vocab.csv").open(
            encoding="utf-8-sig",
            newline="",
        ) as handle:
            reader = csv.DictReader(handle)
            header = list(reader.fieldnames or [])
            rows = list(reader)
        by_id = {row["id"]: row for row in rows}
        target_row = by_id["vocab_a1_0216"]
        self.assertEqual(target_row["level"].upper(), "B1")

        def load_csv_factory(original_load_csv):
            def load_csv(name: str):
                if name == "korean_vocab.csv":
                    return header, [target_row]
                return original_load_csv(name)

            return load_csv

        with tempfile.TemporaryDirectory() as tmp:
            trimmed_path = Path(tmp) / "relevel_ledger.trimmed.json"
            trimmed_path.write_text(json.dumps(trimmed_dict), encoding="utf-8")

            # Constructor-injected temp ledger with the id removed: the
            # violation the ledger used to suppress must come back.
            validator = ContentValidator(ledger_path=trimmed_path)
            validator.load_csv = load_csv_factory(validator.load_csv)  # type: ignore[method-assign]
            validator.validate_vocab()

        messages = self._messages(validator)
        self.assertEqual(
            sum(
                1
                for m in messages
                if "id level disagrees with row level and is not in relevel ledger" in m
            ),
            1,
        )

        # Sanity check: pointing ledger_path at the *untouched* copy
        # tolerates the same row -- proving the failure above is caused by
        # the missing id, not by some other side effect of the injection.
        with tempfile.TemporaryDirectory() as tmp:
            full_path = Path(tmp) / "relevel_ledger.full.json"
            full_path.write_text(json.dumps(live_dict), encoding="utf-8")

            validator_control = ContentValidator(ledger_path=full_path)
            validator_control.load_csv = load_csv_factory(validator_control.load_csv)  # type: ignore[method-assign]
            validator_control.validate_vocab()
        self.assertFalse(
            any("id level disagrees" in m for m in self._messages(validator_control)),
        )

    def test_smalltalk_level_id_mismatch_is_rejected_unless_registered_in_the_ledger(
        self,
    ) -> None:
        """T1.7 (c): smalltalk had no legacy-exception tolerance at all
        before this task; it must accept a ledger entry the same way
        vocab/cloze/satz do."""

        smalltalk = self._asset_json("smalltalk.json")
        base_item = next(
            item for item in smalltalk["phrases"] if item["id"] == "smalltalk_a1_0001"
        )
        mismatched = copy.deepcopy(base_item)
        mismatched["id"] = "smalltalk_a1_9999"
        mismatched["level"] = "b1"
        payload = copy.deepcopy(smalltalk)
        payload["phrases"] = [mismatched]

        validator = self._with_json_override(**{"smalltalk.json": payload})
        validator.validate_smalltalk()
        messages = self._messages(validator)
        self.assertTrue(
            any(
                "smalltalk_a1_9999 id level disagrees with b1 and is not in relevel ledger" in m
                for m in messages
            ),
        )

        entry = relevel_ledger.LedgerEntry(
            id="smalltalk_a1_9999",
            kind="smalltalk",
            from_level="a1",
            to_level="b1",
            movedAt="2026-09-07",
            batch="test_fixture",
            reason="unit test: smalltalk ledger tolerance",
        )
        ledger_with_entry = relevel_ledger.load_ledger().append(entry)

        validator2 = self._with_json_override(**{"smalltalk.json": payload})
        validator2.ledger = ledger_with_entry
        validator2.validate_smalltalk()
        messages2 = self._messages(validator2)
        self.assertFalse(any("id level disagrees" in m for m in messages2))

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
                # Batch 12 로 c2 코스 유닛이 2 → 6 이 됐다.
                and "'c2': 6" in message
                for message in self._messages(validator)
            ),
        )


if __name__ == "__main__":
    unittest.main()
