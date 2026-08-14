#!/usr/bin/env python3
"""Regression tests for the read-only Batch 01 pre-review validator.

Run with:
    python3 -m unittest tools/content_factory/test_validate_batch_01.py
"""

from __future__ import annotations

import csv
from io import StringIO
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest import mock


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = Path(__file__).resolve().parents[2]
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import validate_batch_01 as batch


class Batch01PreReviewValidationTest(unittest.TestCase):
    """Exercise the actual Batch 01 handoff on an isolated source tree."""

    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.root = Path(self.temporary_directory.name) / "repo"
        self._copy_fixture_tree()

    def _copy_fixture_tree(self) -> None:
        shutil.copytree(
            REPO_ROOT / "assets" / "data",
            self.root / "assets" / "data",
        )
        shutil.copytree(
            REPO_ROOT / "tools" / "content_factory" / "drafts",
            self.root / "tools" / "content_factory" / "drafts",
        )
        shutil.copytree(
            REPO_ROOT / "tools" / "content_factory" / "review",
            self.root / "tools" / "content_factory" / "review",
        )
        self._copy_file(
            "functions/analyze_korean_text/grammar_patterns.json",
        )
        self._copy_file("lib/services/vocab_pack_service.dart")
        self._copy_file("lib/widgets/sori/dancheong_stamp.dart")

    def _copy_file(self, relative: str) -> None:
        source = REPO_ROOT / relative
        target = self.root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)

    def _fixture_path(self, relative: str) -> Path:
        return self.root / relative

    def _snapshot(self) -> dict[Path, bytes]:
        return {
            path.relative_to(self.root): path.read_bytes()
            for path in self.root.rglob("*")
            if path.is_file()
        }

    def _manifest(self) -> tuple[Path, dict[str, object]]:
        path = self._fixture_path("tools/content_factory/drafts/batch_01_manifest.json")
        return path, json.loads(path.read_text(encoding="utf-8"))

    def _batch02_manifest(self) -> tuple[Path, dict[str, object]]:
        path = self._fixture_path("tools/content_factory/drafts/batch_02_manifest.json")
        return path, json.loads(path.read_text(encoding="utf-8"))

    def _write_manifest(self, path: Path, manifest: dict[str, object]) -> None:
        path.write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    def _rewrite_review(
        self,
        relative: str,
        mutate: object,
    ) -> None:
        self._rewrite_csv(relative, mutate)

    def _rewrite_csv(
        self,
        relative: str,
        mutate: object,
    ) -> None:
        path = self._fixture_path(relative)
        with path.open(encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            header = list(reader.fieldnames or [])
            rows = list(reader)
        mutate(rows)
        buffer = StringIO(newline="")
        writer = csv.DictWriter(
            buffer,
            fieldnames=header,
            extrasaction="raise",
            lineterminator="\n",
        )
        writer.writeheader()
        writer.writerows(rows)
        path.write_text(buffer.getvalue(), encoding="utf-8")

    def _rewrite_json(self, relative: str, mutate: object) -> None:
        path = self._fixture_path(relative)
        payload = json.loads(path.read_text(encoding="utf-8"))
        mutate(payload)
        path.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    def _validate_batch02(self) -> batch.BatchValidationResult:
        return batch.validate_review_batch(
            root=self.root,
            manifest_path=Path("tools/content_factory/drafts/batch_02_manifest.json"),
        )

    def test_current_batch_passes_and_does_not_write_any_fixture_source(self) -> None:
        before = self._snapshot()

        result = batch.validate_batch_01(root=self.root)

        self.assertEqual(96, result.record_count)
        self.assertEqual(
            ("b1_housing_contract_1", "b2_formal_agreement_1"),
            result.planned_pack_ids,
        )
        self.assertEqual(before, self._snapshot())

    def test_rejects_review_copy_that_does_not_match_its_draft_projection(self) -> None:
        self._rewrite_review(
            "tools/content_factory/review/c2_batch01_smalltalk.csv",
            lambda rows: rows[0].update({"de": "Changed review-only German text."}),
        )

        with self.assertRaisesRegex(batch.BatchValidationError, "canonical draft projection"):
            batch.validate_batch_01(root=self.root)

    def test_rejects_a_non_draft_review_status(self) -> None:
        self._rewrite_review(
            "tools/content_factory/review/c3_batch01_vocab.csv",
            lambda rows: rows[0].update({"상태": "approved"}),
        )

        with self.assertRaisesRegex(batch.BatchValidationError, "상태 must be exactly 'draft'"):
            batch.validate_batch_01(root=self.root)

    def test_generic_validator_accepts_a_later_batch_manifest_without_batch01_ids(self) -> None:
        path, manifest = self._manifest()
        manifest["batch"] = "02"
        self._write_manifest(path, manifest)

        result = batch.validate_review_batch(
            root=self.root,
            manifest_path=path,
        )

        self.assertEqual(96, result.record_count)

    def test_later_batch_rejects_any_predecessor_draft_id_reuse(self) -> None:
        self._rewrite_json(
            "tools/content_factory/drafts/c2_batch02_smalltalk_b1_b2.json",
            lambda payload: payload["phrases"][0].update({"id": "smalltalk_b1_0037"}),
        )
        self._rewrite_review(
            "tools/content_factory/review/c2_batch02_smalltalk.csv",
            lambda rows: rows[0].update({"id": "smalltalk_b1_0037"}),
        )

        with self.assertRaisesRegex(batch.BatchValidationError, "reuses predecessor draft ID"):
            self._validate_batch02()

    def test_later_batch_rejects_predecessor_vocabulary_headword_reuse(self) -> None:
        self._rewrite_csv(
            "tools/content_factory/drafts/c3_batch02_vocab_b1_b2.csv",
            lambda rows: rows[0].update({"korean": "관리비"}),
        )
        self._rewrite_review(
            "tools/content_factory/review/c3_batch02_vocab.csv",
            lambda rows: rows[0].update({"ko": "관리비"}),
        )
        self._rewrite_json(
            "tools/content_factory/drafts/c2_batch02_satz_b1_b2.json",
            lambda payload: payload["items"][0].update({"vocabKo": "관리비"}),
        )

        with self.assertRaisesRegex(
            batch.BatchValidationError,
            "reuses predecessor draft headword",
        ):
            self._validate_batch02()

    def test_later_batch_rejects_conflicting_predecessor_companion_mapping(self) -> None:
        path, manifest = self._batch02_manifest()
        mappings = manifest["smalltalkCategoryMappings"]
        self.assertIsInstance(mappings, list)
        phone = next(
            entry
            for entry in mappings
            if entry["level"] == "b1" and entry["category"] == "phone"
        )
        phone["courseUnitId"] = "b1_01_experience_reasons"
        phone["conceptIds"] = ["concept_b1_reasons_experience"]
        self._write_manifest(path, manifest)

        with self.assertRaisesRegex(
            batch.BatchValidationError,
            "conflicting predecessor smalltalkCategoryUnitMap entry",
        ):
            self._validate_batch02()

    def test_later_batch_allows_an_identical_predecessor_companion_mapping(self) -> None:
        # Batch 02 intentionally shares B1 phone, B2 phone, and B2 shopping
        # ownership with Batch 01.  Bypass the unrelated final overlay here so
        # this test isolates the reservation guard itself.
        with mock.patch.object(batch, "_write_overlay", return_value={}):
            with mock.patch.object(batch.ContentValidator, "validate", return_value=[]):
                result = self._validate_batch02()

        self.assertEqual(96, result.record_count)

    def test_batch02_satz_distractors_keep_reviewed_alternate_sentences_impossible(self) -> None:
        """Do not restore tile pairs that complete a second natural answer.

        Satzbau accepts an exact target at runtime, but a distractor pair that
        also completes the visible prefix makes the exercise pedagogically
        ambiguous.  These reviewed pairs are deliberately incompatible noun
        fragments, so this sentinel protects the human-language correction.
        """

        payload = json.loads(
            self._fixture_path(
                "tools/content_factory/drafts/c2_batch02_satz_b1_b2.json",
            ).read_text(encoding="utf-8"),
        )
        actual = {
            item["id"]: item["distractors"]
            for item in payload["items"]
            if item["id"]
            in {
                "satz_b1_0062",
                "satz_b1_0067",
                "satz_b1_0068",
                "satz_b1_0070",
                "satz_b1_0071",
                "satz_b1_0072",
                "satz_b2_0054",
                "satz_b2_0055",
                "satz_b2_0058",
                "satz_b2_0060",
                "satz_b2_0061",
                "satz_b2_0063",
            }
        }
        self.assertEqual(
            {
                "satz_b1_0062": ["회의실을", "참석 여부를"],
                "satz_b1_0067": ["회의실을", "마감일을"],
                "satz_b1_0068": ["참석 여부를", "회의실을"],
                "satz_b1_0070": ["회의실을", "참석 여부를"],
                "satz_b1_0071": ["회의실을", "업무 분담을"],
                "satz_b1_0072": ["마감일을", "참석 여부를"],
                "satz_b2_0054": ["서면 답변을", "보상 방안을"],
                "satz_b2_0055": ["민원을", "서면 답변을"],
                "satz_b2_0058": ["서면 답변을", "보상 방안을"],
                "satz_b2_0060": ["서면 답변을", "보상 방안을"],
                "satz_b2_0061": ["보상 방안을", "서면 답변을"],
                "satz_b2_0063": ["민원을", "보상 방안을"],
            },
            actual,
        )

    def test_rejects_a_derived_translation_that_drifts_from_its_vocab_source(self) -> None:
        self._rewrite_json(
            "tools/content_factory/drafts/c2_batch01_cloze_b1_b2.json",
            lambda payload: payload["items"][0].update({"de": "A different translation."}),
        )
        self._rewrite_review(
            "tools/content_factory/review/c2_batch01_cloze.csv",
            lambda rows: rows[0].update({"de": "A different translation."}),
        )

        with self.assertRaisesRegex(
            batch.BatchValidationError,
            "must exactly share the canonical vocabulary example",
        ):
            batch.validate_batch_01(root=self.root)

    def test_rejects_missing_curriculum_companion_mapping(self) -> None:
        path, manifest = self._manifest()
        grammar_intents = manifest["grammarIntents"]
        self.assertIsInstance(grammar_intents, list)
        grammar_intents.pop()
        self._write_manifest(path, manifest)

        with self.assertRaisesRegex(batch.BatchValidationError, "grammarIntents does not cover"):
            batch.validate_batch_01(root=self.root)

    def test_overlay_rejects_a_cloze_rule_that_the_review_projection_cannot_mask(self) -> None:
        self._rewrite_json(
            "tools/content_factory/drafts/c2_batch01_cloze_b1_b2.json",
            lambda payload: payload["items"][0].update({"sentenceKo": "잘못된 빈칸 문장"}),
        )

        with self.assertRaisesRegex(
            batch.BatchValidationError,
            r"overlay cloze\.json: cloze_b1_0056 sentenceKo must be fullKo",
        ):
            batch.validate_batch_01(root=self.root)

    def test_pack_preflight_rejects_a_non_next_pack_sequence(self) -> None:
        path, manifest = self._manifest()
        vocab_packs = manifest["vocabPacks"]
        self.assertIsInstance(vocab_packs, list)
        vocab_packs[0]["orderInLevel"] = 18
        self._write_manifest(path, manifest)

        with self.assertRaisesRegex(
            batch.BatchValidationError,
            "vocabulary pack preflight failed",
        ):
            batch.validate_batch_01(root=self.root)


if __name__ == "__main__":
    unittest.main()
