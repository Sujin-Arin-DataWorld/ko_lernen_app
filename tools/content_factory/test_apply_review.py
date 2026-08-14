#!/usr/bin/env python3
"""Regression tests for the human-review content merge gate.

Run with:
    python3 -m unittest tools/content_factory/test_apply_review.py
"""

from __future__ import annotations

import csv
from io import StringIO
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import apply_review as review_tool


VOCAB_HEADER = [
    "korean",
    "romanization",
    "german",
    "level",
    "pos_de",
    "example_korean",
    "example_german",
    "topic",
    "pack_id",
    "pack_order",
    "is_review_boss",
    "english",
    "pos_en",
    "example_english",
    "id",
]


def _vocab_row(
    ident: str,
    *,
    level: str = "a1",
    pack_id: str = "a1_new_1",
    pack_order: int = 1,
    boss: bool = False,
) -> dict[str, str]:
    return {
        "korean": f"word-{ident}",
        "romanization": f"roman-{ident}",
        "german": f"German {ident}",
        "level": level,
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


def _vocab_csv(*rows: dict[str, str]) -> str:
    buffer = StringIO(newline="")
    writer = csv.DictWriter(buffer, fieldnames=VOCAB_HEADER, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return buffer.getvalue()


def _vocab_ids(path: Path) -> list[str]:
    with path.open(encoding="utf-8", newline="") as handle:
        return [row["id"] for row in csv.DictReader(handle)]


class ApplyReviewTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.root = Path(self.temporary_directory.name)
        self.data = self.root / "assets" / "data"
        self.data.mkdir(parents=True)
        self.target = self.data / "korean_vocab.csv"
        self.manifest = self.data / "content_audit_manifest.json"
        self.review = self.root / "review.csv"
        self.draft = self.root / "draft.csv"
        self.pack_metadata = self.root / "batch_manifest.json"

        self.target.write_text(
            _vocab_csv(_vocab_row("existing", pack_id="a1_existing_1")),
            encoding="utf-8",
        )
        self.manifest.write_text(
            json.dumps(
                {
                    "version": 1,
                    "sources": [
                        {"kind": "vocab", "count": 1, "source": "korean_vocab.csv"}
                    ],
                },
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
        self.draft.write_text(
            _vocab_csv(
                _vocab_row("new-approved", pack_id="a1_existing_1", pack_order=2),
                _vocab_row("new-ok", pack_id="a1_existing_1", pack_order=3, boss=True),
                _vocab_row("new-no", pack_id="a1_existing_1", pack_order=4),
                _vocab_row("new-fix", pack_id="a1_existing_1", pack_order=5),
                _vocab_row("new-draft", pack_id="a1_existing_1", pack_order=6),
            ),
            encoding="utf-8",
        )
        self.review.write_text(
            "id,status\n"
            "new-approved,approved\n"
            "new-ok,ok\n"
            "new-no,no\n"
            "new-fix,fix: German wording\n"
            "new-draft,draft\n",
            encoding="utf-8",
        )

        self._patches = [
            mock.patch.object(review_tool, "ROOT", self.root),
            mock.patch.object(review_tool, "DATA_DIR", self.data),
            mock.patch.object(review_tool, "MANIFEST_PATH", self.manifest),
        ]
        for patcher in self._patches:
            patcher.start()
            self.addCleanup(patcher.stop)

    def _new_pack_rows(
        self,
        *,
        pack_id: str = "a1_new_pack_1",
        count: int = 11,
        boss_orders: set[int] | None = None,
        orders: list[int] | None = None,
    ) -> list[dict[str, str]]:
        actual_orders = orders or list(range(1, count + 1))
        actual_boss_orders = boss_orders if boss_orders is not None else {count - 1, count}
        return [
            _vocab_row(
                f"vocab_a1_{100 + index:04d}",
                pack_id=pack_id,
                pack_order=order,
                boss=order in actual_boss_orders,
            )
            for index, order in enumerate(actual_orders, start=1)
        ]

    def _write_pack_preflight_support(self) -> None:
        (self.root / "lib" / "services").mkdir(parents=True, exist_ok=True)
        (self.root / "lib" / "widgets" / "sori").mkdir(parents=True, exist_ok=True)
        (self.data / "curriculum_manifest.json").write_text(
            json.dumps(
                {
                    "courseUnits": [
                        {"id": "a1_01_greetings_hangul", "level": "a1"},
                    ],
                },
            ),
            encoding="utf-8",
        )
        (self.root / "lib" / "services" / "vocab_pack_service.dart").write_text(
            """class VocabPackService {
  static const Map<String, int> packOrderInLevel = {
    'a1_existing': 13,
  };
}
""",
            encoding="utf-8",
        )
        (self.root / "lib" / "widgets" / "sori" / "dancheong_stamp.dart").write_text(
            """enum DancheongMotif {
  lotus,
}
""",
            encoding="utf-8",
        )

    def _write_batch_manifest(
        self,
        *,
        pack_id: str = "a1_new_pack_1",
        count: int = 11,
        boss_orders: list[int] | None = None,
        motif: str = "lotus",
    ) -> None:
        actual_boss_orders = boss_orders or [count - 1, count]
        self.pack_metadata.write_text(
            json.dumps(
                {
                    "batchId": "apply-review-test",
                    "vocabPacks": [
                        {
                            "packId": pack_id,
                            "level": "a1",
                            "orderRange": [1, count],
                            "reviewBossOrders": actual_boss_orders,
                            "displayLabel": {
                                "ko": "시험 팩",
                                "de": "Testpaket",
                                "en": "Test pack",
                            },
                            "motif": motif,
                            "curriculum": {
                                "courseUnitId": "a1_01_greetings_hangul",
                                "conceptIds": ["concept_a1_greeting"],
                            },
                        },
                    ],
                },
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )

    def _approve_all_draft_rows(self) -> None:
        self.review.write_text(
            "id,status\n"
            + "".join(
                f"{row_id},approved\n"
                for row_id in _vocab_ids(self.draft)
            ),
            encoding="utf-8",
        )

    def test_preview_only_selects_approved_rows_without_writing(self) -> None:
        original_target = self.target.read_text(encoding="utf-8")
        original_manifest = self.manifest.read_text(encoding="utf-8")

        count, pending = review_tool.apply_review(
            self.review,
            self.draft,
            self.target,
            apply=False,
        )

        self.assertEqual(2, count)
        self.assertEqual(
            ["new-no (rejected)", "new-fix (fix)", "new-draft (draft)"],
            pending,
        )
        self.assertEqual(original_target, self.target.read_text(encoding="utf-8"))
        self.assertEqual(original_manifest, self.manifest.read_text(encoding="utf-8"))

    def test_apply_appends_only_approved_rows_and_bumps_manifest(self) -> None:
        with mock.patch.object(review_tool, "_run_validator") as run_validator:
            count, pending = review_tool.apply_review(
                self.review,
                self.draft,
                self.target,
                apply=True,
            )

        self.assertEqual(2, count)
        self.assertEqual(
            ["new-no (rejected)", "new-fix (fix)", "new-draft (draft)"],
            pending,
        )
        self.assertEqual(["existing", "new-approved", "new-ok"], _vocab_ids(self.target))
        manifest = json.loads(self.manifest.read_text(encoding="utf-8"))
        self.assertEqual(3, manifest["sources"][0]["count"])
        run_validator.assert_called_once_with()

    def test_validator_failure_restores_target_and_manifest(self) -> None:
        self.review.write_text("id,상태\nnew-approved,ok\n", encoding="utf-8")
        self.draft.write_text(
            _vocab_csv(_vocab_row("new-approved", pack_id="a1_existing_1", pack_order=2)),
            encoding="utf-8",
        )
        original_target = self.target.read_text(encoding="utf-8")
        original_manifest = self.manifest.read_text(encoding="utf-8")

        with mock.patch.object(
            review_tool,
            "_run_validator",
            side_effect=review_tool.ReviewError("synthetic validator failure"),
        ):
            with self.assertRaisesRegex(review_tool.ReviewError, "synthetic validator failure"):
                review_tool.apply_review(
                    self.review,
                    self.draft,
                    self.target,
                    apply=True,
                )

        self.assertEqual(original_target, self.target.read_text(encoding="utf-8"))
        self.assertEqual(original_manifest, self.manifest.read_text(encoding="utf-8"))

    def test_duplicate_review_ids_are_rejected_regardless_of_status(self) -> None:
        self.review.write_text(
            "id,status\nnew-approved,ok\nnew-approved,no\n",
            encoding="utf-8",
        )

        with self.assertRaisesRegex(review_tool.ReviewError, "duplicate review id"):
            review_tool.apply_review(self.review, self.draft, self.target, apply=False)

    def test_duplicate_draft_ids_are_rejected_before_any_write(self) -> None:
        self.draft.write_text(
            _vocab_csv(
                _vocab_row("new-approved", pack_order=1),
                _vocab_row("new-approved", level="a2", pack_id="a2_new_1", pack_order=2),
            ),
            encoding="utf-8",
        )

        with self.assertRaisesRegex(review_tool.ReviewError, "duplicate id"):
            review_tool.apply_review(self.review, self.draft, self.target, apply=False)

    def test_partial_new_vocab_pack_is_rejected_in_preview_and_apply_without_writing(self) -> None:
        self.draft.write_text(
            _vocab_csv(*self._new_pack_rows(pack_id="a1_partial_1")),
            encoding="utf-8",
        )
        self.review.write_text("id,status\nvocab_a1_0101,ok\n", encoding="utf-8")
        original_target = self.target.read_text(encoding="utf-8")
        original_manifest = self.manifest.read_text(encoding="utf-8")

        for apply in (False, True):
            with self.subTest(apply=apply):
                with self.assertRaisesRegex(
                    review_tool.ReviewError,
                    "partial approval is not allowed for new vocab pack 'a1_partial_1'",
                ):
                    review_tool.apply_review(self.review, self.draft, self.target, apply=apply)
                self.assertEqual(original_target, self.target.read_text(encoding="utf-8"))
                self.assertEqual(original_manifest, self.manifest.read_text(encoding="utf-8"))

    def test_malformed_new_vocab_pack_is_rejected_in_preview_and_apply_without_writing(self) -> None:
        cases = [
            (
                "wrong-row-count",
                self._new_pack_rows(count=10),
                "has 10 rows; expected 11 or 12",
            ),
            (
                "non-contiguous-order",
                self._new_pack_rows(orders=[*range(1, 11), 12]),
                "pack_order must be contiguous 1..11",
            ),
            (
                "wrong-boss-count",
                self._new_pack_rows(boss_orders={11}),
                "has 1 Boss rows; expected 2 or 3",
            ),
            (
                "boss-not-final",
                self._new_pack_rows(boss_orders={1, 11}),
                "Boss rows must occupy final pack_order values",
            ),
        ]
        original_target = self.target.read_text(encoding="utf-8")
        original_manifest = self.manifest.read_text(encoding="utf-8")

        for name, rows, message in cases:
            with self.subTest(name=name):
                self.draft.write_text(_vocab_csv(*rows), encoding="utf-8")
                self._approve_all_draft_rows()
                for apply in (False, True):
                    with self.subTest(apply=apply):
                        with self.assertRaisesRegex(review_tool.ReviewError, message):
                            review_tool.apply_review(
                                self.review,
                                self.draft,
                                self.target,
                                apply=apply,
                            )
                        self.assertEqual(original_target, self.target.read_text(encoding="utf-8"))
                        self.assertEqual(original_manifest, self.manifest.read_text(encoding="utf-8"))

    def test_complete_new_vocab_pack_preview_needs_no_metadata_and_writes_nothing(self) -> None:
        self.draft.write_text(_vocab_csv(*self._new_pack_rows()), encoding="utf-8")
        self._approve_all_draft_rows()
        original_target = self.target.read_text(encoding="utf-8")
        original_manifest = self.manifest.read_text(encoding="utf-8")

        count, pending = review_tool.apply_review(
            self.review,
            self.draft,
            self.target,
            apply=False,
        )

        self.assertEqual(11, count)
        self.assertEqual([], pending)
        self.assertEqual(original_target, self.target.read_text(encoding="utf-8"))
        self.assertEqual(original_manifest, self.manifest.read_text(encoding="utf-8"))

    def test_zero_approved_complete_new_pack_preview_needs_no_metadata_and_writes_nothing(self) -> None:
        self.draft.write_text(_vocab_csv(*self._new_pack_rows()), encoding="utf-8")
        self.review.write_text("id,status\n", encoding="utf-8")
        original_target = self.target.read_text(encoding="utf-8")
        original_manifest = self.manifest.read_text(encoding="utf-8")

        count, pending = review_tool.apply_review(
            self.review,
            self.draft,
            self.target,
            apply=False,
        )

        self.assertEqual(0, count)
        self.assertEqual([], pending)
        self.assertEqual(original_target, self.target.read_text(encoding="utf-8"))
        self.assertEqual(original_manifest, self.manifest.read_text(encoding="utf-8"))

    def test_complete_new_vocab_pack_apply_requires_metadata_without_writing(self) -> None:
        self.draft.write_text(_vocab_csv(*self._new_pack_rows()), encoding="utf-8")
        self._approve_all_draft_rows()
        original_target = self.target.read_text(encoding="utf-8")
        original_manifest = self.manifest.read_text(encoding="utf-8")

        with self.assertRaisesRegex(review_tool.ReviewError, "--pack-metadata is required"):
            review_tool.apply_review(self.review, self.draft, self.target, apply=True)

        self.assertEqual(original_target, self.target.read_text(encoding="utf-8"))
        self.assertEqual(original_manifest, self.manifest.read_text(encoding="utf-8"))

    def test_new_vocab_pack_rejects_invalid_supplied_metadata_without_writing(self) -> None:
        self._write_pack_preflight_support()
        self.draft.write_text(_vocab_csv(*self._new_pack_rows()), encoding="utf-8")
        self._approve_all_draft_rows()
        self._write_batch_manifest(motif="not_a_real_motif")
        original_target = self.target.read_text(encoding="utf-8")
        original_manifest = self.manifest.read_text(encoding="utf-8")

        for apply in (False, True):
            with self.subTest(apply=apply):
                with self.assertRaisesRegex(
                    review_tool.ReviewError,
                    "pack metadata preflight rejected the draft: metadata vocabPacks\\[0\\]: motif",
                ):
                    review_tool.apply_review(
                        self.review,
                        self.draft,
                        self.target,
                        apply=apply,
                        pack_metadata=self.pack_metadata,
                    )
                self.assertEqual(original_target, self.target.read_text(encoding="utf-8"))
                self.assertEqual(original_manifest, self.manifest.read_text(encoding="utf-8"))

    def test_complete_new_vocab_pack_is_accepted_only_with_metadata(self) -> None:
        self._write_pack_preflight_support()
        self.draft.write_text(
            _vocab_csv(*self._new_pack_rows()),
            encoding="utf-8",
        )
        self._approve_all_draft_rows()
        self._write_batch_manifest()

        with mock.patch.object(review_tool, "_run_validator") as run_validator:
            count, pending = review_tool.apply_review(
                self.review,
                self.draft,
                self.target,
                apply=True,
                pack_metadata=self.pack_metadata,
            )

        self.assertEqual(11, count)
        self.assertEqual([], pending)
        self.assertEqual(12, len(_vocab_ids(self.target)))
        run_validator.assert_called_once_with()

    def test_target_must_be_the_exact_whitelisted_asset(self) -> None:
        lookalike = self.data / "drafts" / "korean_vocab.csv"
        lookalike.parent.mkdir()
        lookalike.write_text("id,level\nexisting,a1\n", encoding="utf-8")

        with self.assertRaisesRegex(review_tool.ReviewError, "canonical assets/data files"):
            review_tool.apply_review(self.review, self.draft, lookalike, apply=False)

    def test_grammar_patterns_require_a_future_paired_mirror_flow(self) -> None:
        target = self.data / "grammar_patterns.json"
        target.write_text("[]\n", encoding="utf-8")

        with self.assertRaisesRegex(review_tool.ReviewError, "canonical assets/data files"):
            review_tool.apply_review(self.review, self.draft, target, apply=False)

    def test_json_preview_uses_the_canonical_collection_without_writing(self) -> None:
        target = self.data / "pronunciation_phrases.json"
        draft = self.root / "pronunciation_draft.json"
        review = self.root / "pronunciation_review.csv"
        target.write_text(
            json.dumps(
                {
                    "version": 1,
                    "phrases": [
                        {
                            "id": "pronunciation_a1_0001",
                            "level": "a1",
                            "ko": "안녕하세요",
                            "de": "Hallo",
                            "en": "Hello",
                            "focus": "basic greeting",
                        }
                    ],
                },
                ensure_ascii=False,
            ),
            encoding="utf-8",
        )
        draft.write_text(
            json.dumps(
                {
                    "phrases": [
                        {
                            "id": "pronunciation_a1_0002",
                            "level": "a1",
                            "ko": "감사합니다",
                            "de": "Danke",
                            "en": "Thank you",
                            "focus": "formal ending",
                        },
                        {
                            "id": "pronunciation_a2_0001",
                            "level": "a2",
                            "ko": "천천히 말해 주세요",
                            "de": "Bitte sprechen Sie langsam.",
                            "en": "Please speak slowly.",
                            "focus": "liaison",
                        },
                    ]
                },
                ensure_ascii=False,
            ),
            encoding="utf-8",
        )
        review.write_text(
            "id,상태\npronunciation_a1_0002,ok\npronunciation_a2_0001,fix: check tone\n",
            encoding="utf-8",
        )
        original_target = target.read_text(encoding="utf-8")

        count, pending = review_tool.apply_review(review, draft, target, apply=False)

        self.assertEqual(1, count)
        self.assertEqual(["pronunciation_a2_0001 (fix)"], pending)
        self.assertEqual(original_target, target.read_text(encoding="utf-8"))


class ReviewStatusTest(unittest.TestCase):
    def test_status_normalization_never_approves_unknown_text(self) -> None:
        self.assertEqual("approved", review_tool.normalize_status("approved"))
        self.assertEqual("approved", review_tool.normalize_status(" OK "))
        self.assertEqual("rejected", review_tool.normalize_status("no"))
        self.assertEqual("fix", review_tool.normalize_status("fix: tone"))
        self.assertEqual("draft", review_tool.normalize_status("ready soon"))
        self.assertEqual("draft", review_tool.normalize_status(None))


if __name__ == "__main__":
    unittest.main()
