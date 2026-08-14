#!/usr/bin/env python3
"""Regression tests for the read-only vocabulary pack preflight.

Run with:
    python3 -m unittest tools/content_factory/test_plan_pack_assignments.py
"""

from __future__ import annotations

import csv
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import plan_pack_assignments as planner


def _vocab_row(
    ident: str,
    *,
    pack_id: str,
    pack_order: int,
    boss: bool,
    korean: str | None = None,
) -> dict[str, str]:
    return {
        "korean": korean or f"word-{ident}",
        "romanization": f"roman-{ident}",
        "german": f"German {ident}",
        "level": "b1",
        "pos_de": "Nomen",
        "example_korean": f"example {ident}",
        "example_german": f"German example {ident}",
        "topic": "Test topic",
        "pack_id": pack_id,
        "pack_order": str(pack_order),
        "is_review_boss": "true" if boss else "false",
        "english": f"English {ident}",
        "pos_en": "noun",
        "example_english": f"English example {ident}",
        "id": ident,
    }


def _csv_text(rows: list[dict[str, str]]) -> str:
    buffer = StringIO(newline="")
    writer = csv.DictWriter(buffer, fieldnames=planner.VOCAB_HEADER, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return buffer.getvalue()


class PackAssignmentPlanTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.root = Path(self.temporary_directory.name)
        data = self.root / "assets" / "data"
        data.mkdir(parents=True)
        (self.root / "lib" / "services").mkdir(parents=True)
        (self.root / "lib" / "widgets" / "sori").mkdir(parents=True)
        self.current_vocab = data / "korean_vocab.csv"
        self.current_vocab.write_text(
            _csv_text(
                [
                    _vocab_row(
                        "vocab_b1_0001",
                        pack_id="b1_existing_1",
                        pack_order=1,
                        boss=False,
                        korean="existing-word",
                    ),
                ],
            ),
            encoding="utf-8",
        )
        (data / "curriculum_manifest.json").write_text(
            json.dumps(
                {
                    "courseUnits": [
                        {"id": "b1_05_complaint_resolution", "level": "b1"},
                        {"id": "b2_03_precise_requests", "level": "b2"},
                    ],
                },
            ),
            encoding="utf-8",
        )
        (self.root / "lib" / "services" / "vocab_pack_service.dart").write_text(
            """class VocabPackService {
  static const Map<String, int> packOrderInLevel = {
    'b1_existing': 18,
    'b2_existing': 17,
  };
}
""",
            encoding="utf-8",
        )
        (self.root / "lib" / "widgets" / "sori" / "dancheong_stamp.dart").write_text(
            """enum DancheongMotif {
  lotus,
  gwigap,
  peony,
}
""",
            encoding="utf-8",
        )
        self.draft = self.root / "draft.csv"
        self.metadata = self.root / "metadata.json"
        self._write_valid_draft()
        self._write_metadata()

    def _write_valid_draft(self) -> None:
        rows = [
            _vocab_row(
                f"vocab_b1_{identifier:04d}",
                pack_id="b1_housing_contract_1",
                pack_order=order,
                boss=order >= 9,
            )
            for order, identifier in enumerate(range(2, 13), start=1)
        ]
        self.draft.write_text(_csv_text(rows), encoding="utf-8")

    def _write_metadata(
        self,
        *,
        order: int = 19,
        motif: str = "gwigap",
        unit: str = "b1_05_complaint_resolution",
    ) -> None:
        self.metadata.write_text(
            json.dumps(
                {
                    "version": 1,
                    "packs": [
                        {
                            "packIdBase": "b1_housing_contract",
                            "level": "b1",
                            "orderInLevel": order,
                            "label": {
                                "de": "Wohnen & Vertrag",
                                "en": "Housing & Contracts",
                            },
                            "motif": motif,
                            "curriculumUnitId": unit,
                        },
                    ],
                },
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )

    def _write_batch_manifest(
        self,
        *,
        review_boss_orders: list[int] | None = None,
        order: int | None = None,
    ) -> None:
        pack = {
            "packId": "b1_housing_contract_1",
            "level": "b1",
            "orderRange": [1, 11],
            "reviewBossOrders": review_boss_orders or [9, 10, 11],
            "displayLabel": {
                "ko": "주거와 계약",
                "de": "Wohnen & Vertrag",
                "en": "Housing & Contracts",
            },
            "motif": "gwigap",
            "curriculum": {
                "courseUnitId": "b1_05_complaint_resolution",
                "conceptIds": ["concept_b1_complaint_resolution"],
            },
        }
        if order is not None:
            pack["orderInLevel"] = order
        self.metadata.write_text(
            json.dumps(
                {
                    "batchId": "batch_01",
                    "vocabPacks": [pack],
                },
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )

    def _write_reserved_manifest(
        self,
        path: Path,
        *,
        pack_id: str,
        level: str = "b1",
        order: int | None = 19,
        motif: str = "gwigap",
        unit: str = "b1_05_complaint_resolution",
    ) -> None:
        pack = {
            "packId": pack_id,
            "level": level,
            "orderRange": [1, 11],
            "reviewBossOrders": [9, 10, 11],
            "displayLabel": {
                "ko": "예약 팩",
                "de": "Reserviertes Paket",
                "en": "Reserved pack",
            },
            "motif": motif,
            "curriculum": {
                "courseUnitId": unit,
                "conceptIds": ["concept_b1_complaint_resolution"],
            },
        }
        if order is not None:
            pack["orderInLevel"] = order
        path.write_text(
            json.dumps(
                {"batchId": path.stem, "vocabPacks": [pack]},
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )

    def test_valid_batch_returns_a_read_only_plan(self) -> None:
        before = {
            path: path.read_bytes()
            for path in (self.current_vocab, self.draft, self.metadata)
        }

        plans = planner.validate_plan(self.draft, self.metadata, root=self.root)

        self.assertEqual(1, len(plans))
        self.assertEqual("b1_housing_contract", plans[0].pack_id_base)
        self.assertEqual(("b1_housing_contract_1",), plans[0].pack_ids)
        self.assertEqual(19, plans[0].order_in_level)
        self.assertEqual("gwigap", plans[0].motif)
        self.assertEqual(
            before,
            {path: path.read_bytes() for path in (self.current_vocab, self.draft, self.metadata)},
        )

    def test_rejects_a_non_next_order_in_level(self) -> None:
        self._write_metadata(order=18)

        with self.assertRaisesRegex(
            planner.PackAssignmentError,
            r"b1 orderInLevel must use the next unused sequence \[19\], got \[18\]",
        ):
            planner.validate_plan(self.draft, self.metadata, root=self.root)

    def test_rejects_a_missing_or_new_motif(self) -> None:
        self._write_metadata(motif="new_motif")

        with self.assertRaisesRegex(planner.PackAssignmentError, "not an existing DancheongMotif"):
            planner.validate_plan(self.draft, self.metadata, root=self.root)

    def test_rejects_incomplete_boss_set(self) -> None:
        rows = [
            _vocab_row(
                f"vocab_b1_{identifier:04d}",
                pack_id="b1_housing_contract_1",
                pack_order=order,
                boss=order == 11,
            )
            for order, identifier in enumerate(range(2, 13), start=1)
        ]
        self.draft.write_text(_csv_text(rows), encoding="utf-8")

        with self.assertRaisesRegex(
            planner.PackAssignmentError,
            "has 1 Boss rows; expected 2 or 3",
        ):
            planner.validate_plan(self.draft, self.metadata, root=self.root)

    def test_rejects_a_curriculum_unit_for_another_level(self) -> None:
        self._write_metadata(unit="b2_03_precise_requests")

        with self.assertRaisesRegex(
            planner.PackAssignmentError,
            "is b2, not b1",
        ):
            planner.validate_plan(self.draft, self.metadata, root=self.root)

    def test_batch_manifest_vocab_packs_is_accepted_without_duplicate_ui_order(self) -> None:
        self._write_batch_manifest()

        plans = planner.validate_plan(self.draft, self.metadata, root=self.root)

        self.assertEqual(1, len(plans))
        self.assertEqual("b1_housing_contract", plans[0].pack_id_base)
        self.assertEqual(19, plans[0].order_in_level)

    def test_batch_manifest_must_match_authored_boss_orders(self) -> None:
        self._write_batch_manifest(review_boss_orders=[10, 11])

        with self.assertRaisesRegex(
            planner.PackAssignmentError,
            r"reviewBossOrders \[10, 11\] do not match draft Boss orders \[9, 10, 11\]",
        ):
            planner.validate_plan(self.draft, self.metadata, root=self.root)

    def test_new_pack_preflight_ignores_rows_for_an_existing_pack(self) -> None:
        existing_addition = _vocab_row(
            "vocab_b1_0013",
            pack_id="b1_existing_1",
            pack_order=2,
            boss=False,
            korean="existing-maintenance-addition",
        )
        rows = [
            existing_addition,
            *[
                _vocab_row(
                    f"vocab_b1_{identifier:04d}",
                    pack_id="b1_housing_contract_1",
                    pack_order=order,
                    boss=order >= 9,
                )
                for order, identifier in enumerate(range(2, 13), start=1)
            ],
        ]
        self.draft.write_text(_csv_text(rows), encoding="utf-8")
        self._write_batch_manifest()

        plans = planner.validate_plan(self.draft, self.metadata, root=self.root)

        self.assertEqual(("b1_housing_contract_1",), plans[0].pack_ids)

    def test_reservations_assign_the_slot_after_multiple_pending_manifests(self) -> None:
        first = self.root / "batch_01_manifest.json"
        second = self.root / "batch_02_manifest.json"
        self._write_reserved_manifest(
            first,
            pack_id="b1_workplace_basics_1",
            order=19,
        )
        self._write_reserved_manifest(
            second,
            pack_id="b1_workplace_negotiation_1",
            order=20,
        )
        self._write_batch_manifest(order=21)
        before = {
            path: path.read_bytes()
            for path in (self.current_vocab, self.draft, self.metadata, first, second)
        }

        plans = planner.validate_plan(
            self.draft,
            self.metadata,
            root=self.root,
            reserved_metadata_paths=[first, second],
        )

        self.assertEqual(21, plans[0].order_in_level)
        self.assertEqual(
            before,
            {
                path: path.read_bytes()
                for path in (self.current_vocab, self.draft, self.metadata, first, second)
            },
        )

        stdout = StringIO()
        stderr = StringIO()
        with (
            redirect_stdout(stdout),
            redirect_stderr(stderr),
            patch.object(planner, "validate_plan", return_value=plans) as validate_plan,
        ):
            result = planner.main(
                [
                    "--draft",
                    str(self.draft),
                    "--metadata",
                    str(self.metadata),
                    "--reserved-metadata",
                    str(first),
                    "--predecessor-metadata",
                    str(second),
                ],
            )
        self.assertEqual(0, result)
        validate_plan.assert_called_once_with(
            self.draft,
            self.metadata,
            reserved_metadata_paths=[first, second],
        )
        self.assertIn("B1 #21", stdout.getvalue())
        self.assertIn("READ-ONLY", stderr.getvalue())

    def test_reservations_require_a_contiguous_prefix_after_live_order(self) -> None:
        predecessor = self.root / "batch_01_manifest.json"
        self._write_reserved_manifest(
            predecessor,
            pack_id="b1_workplace_basics_1",
            order=20,
        )
        self._write_batch_manifest(order=21)

        with self.assertRaisesRegex(
            planner.PackAssignmentError,
            r"reserved b1 orderInLevel must form the contiguous prefix after live order: "
            r"expected \[19\], got \[20\]",
        ):
            planner.validate_plan(
                self.draft,
                self.metadata,
                root=self.root,
                reserved_metadata_paths=[predecessor],
            )

    def test_reservations_reject_duplicate_bases_and_orders(self) -> None:
        conflicting_base = self.root / "conflicting_base.json"
        self._write_reserved_manifest(
            conflicting_base,
            pack_id="b1_housing_contract_1",
            order=19,
        )
        self._write_batch_manifest(order=20)

        with self.assertRaisesRegex(
            planner.PackAssignmentError,
            r"reserved packIdBase conflicts with current metadata: 'b1_housing_contract'",
        ):
            planner.validate_plan(
                self.draft,
                self.metadata,
                root=self.root,
                reserved_metadata_paths=[conflicting_base],
            )

        first = self.root / "batch_01_manifest.json"
        second = self.root / "batch_02_manifest.json"
        self._write_reserved_manifest(first, pack_id="b1_workplace_basics_1", order=19)
        self._write_reserved_manifest(second, pack_id="b1_workplace_forms_1", order=19)

        with self.assertRaisesRegex(
            planner.PackAssignmentError,
            r"duplicate reserved b1 orderInLevel 19",
        ):
            planner.validate_plan(
                self.draft,
                self.metadata,
                root=self.root,
                reserved_metadata_paths=[first, second],
            )

    def test_reservations_validate_vocab_packs_level_and_schema(self) -> None:
        wrong_level = self.root / "wrong_level.json"
        self._write_reserved_manifest(
            wrong_level,
            pack_id="b1_workplace_basics_1",
            order=19,
            unit="b2_03_precise_requests",
        )
        self._write_batch_manifest(order=20)

        with self.assertRaisesRegex(planner.PackAssignmentError, "is b2, not b1"):
            planner.validate_plan(
                self.draft,
                self.metadata,
                root=self.root,
                reserved_metadata_paths=[wrong_level],
            )

        mismatched_pack_level = self.root / "mismatched_pack_level.json"
        self._write_reserved_manifest(
            mismatched_pack_level,
            pack_id="b1_workplace_basics_1",
            level="b2",
            order=18,
            unit="b2_03_precise_requests",
        )
        with self.assertRaisesRegex(
            planner.PackAssignmentError,
            "invalid or level-mismatched packId",
        ):
            planner.validate_plan(
                self.draft,
                self.metadata,
                root=self.root,
                reserved_metadata_paths=[mismatched_pack_level],
            )

        legacy = self.root / "legacy_metadata.json"
        legacy.write_text(
            json.dumps({"version": 1, "packs": []}) + "\n",
            encoding="utf-8",
        )
        with self.assertRaisesRegex(
            planner.PackAssignmentError,
            "reserved metadata must contain a vocabPacks array, not legacy packs",
        ):
            planner.validate_plan(
                self.draft,
                self.metadata,
                root=self.root,
                reserved_metadata_paths=[legacy],
            )

    def test_reservations_require_a_declared_order(self) -> None:
        predecessor = self.root / "batch_01_manifest.json"
        self._write_reserved_manifest(
            predecessor,
            pack_id="b1_workplace_basics_1",
            order=None,
        )
        self._write_batch_manifest(order=20)

        with self.assertRaisesRegex(
            planner.PackAssignmentError,
            "reserved vocabPacks requires a declared orderInLevel",
        ):
            planner.validate_plan(
                self.draft,
                self.metadata,
                root=self.root,
                reserved_metadata_paths=[predecessor],
            )


if __name__ == "__main__":
    unittest.main()
