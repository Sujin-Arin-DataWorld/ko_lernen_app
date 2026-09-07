#!/usr/bin/env python3

from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock


SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = SCRIPT_DIR.parents[1]
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import scenario_revision_review as review


class CurrentReviewIndexTest(unittest.TestCase):
    def test_index_is_bound_to_the_locked_120_candidate_receipts(self) -> None:
        index = review.build_current_index(ROOT)
        approvals = json.loads(
            (SCRIPT_DIR / "canonical_scenarios/approvals.json").read_text(
                encoding="utf-8"
            )
        )
        receipt_hashes = {
            value["editorialAuditReceipt"]["candidateSetSha256"]
            for value in approvals["levels"].values()
        }

        self.assertEqual(index["generationId"], "canonical_120_v1")
        self.assertEqual(index["candidateCount"], 120)
        self.assertEqual(index["countsByLevel"], {
            "a1": 20,
            "a2": 20,
            "b1": 20,
            "b2": 20,
            "c1": 20,
            "c2": 20,
        })
        self.assertEqual(receipt_hashes, {index["candidateSetSha256"]})
        self.assertFalse(index["runtimeWriteIncluded"])
        self.assertFalse(index["ttsGenerationIncluded"])

    def test_taxi_entry_keeps_the_current_no_automatic_payment_rule(self) -> None:
        index = review.build_current_index(ROOT)
        taxi = next(
            item for item in index["scenarios"] if item["scenarioId"] == "taxi_kakao"
        )

        self.assertIn("자동 결제", taxi["mustAvoidKo"])
        self.assertRegex(taxi["candidateSha256"], r"^[0-9a-f]{64}$")
        self.assertRegex(taxi["candidateFileSha256"], r"^[0-9a-f]{64}$")

    def test_checked_in_index_matches_the_current_locked_candidates(self) -> None:
        checked_in = json.loads(review.DEFAULT_INDEX.read_text(encoding="utf-8"))

        self.assertEqual(
            review.verify_current_index(checked_in, root=ROOT),
            {
                "ok": True,
                "candidateCount": 120,
                "candidateSetSha256": (
                    "63dc5ea8743ec7f95fed04c5efb2a32d"
                    "d2445c310444e87237414c0ced980060"
                ),
            },
        )


class SalvageEvidenceTest(unittest.TestCase):
    def test_evidence_freezes_all_eleven_original_non_graphify_files(self) -> None:
        evidence = json.loads(review.DEFAULT_EVIDENCE.read_text(encoding="utf-8"))
        report = review.validate_salvage_evidence(evidence)

        self.assertEqual(report, {"ok": True, "fileCount": 11})
        self.assertEqual(evidence["sourceCommit"], "c89907e64bd8d3702f185799eb0e25ba7968148d")
        by_path = {item["path"]: item for item in evidence["files"]}
        self.assertEqual(
            by_path["tools/content_factory/manage_scenario_revisions.py"]["sha256"],
            "3783e14c1c2720f1db69fb7f1ef4c58452a6a82f2a8dcdd03bb5751304dbbd08",
        )
        self.assertEqual(
            by_path[
                "tools/content_factory/review/scenario_persona_a1_001_overlay.json"
            ]["disposition"],
            "hash_only_obsolete_overlay",
        )

    def test_evidence_rejects_runtime_write_or_graphify_base_drift(self) -> None:
        evidence = json.loads(review.DEFAULT_EVIDENCE.read_text(encoding="utf-8"))
        evidence["runtimeWriteAuthorized"] = True

        with self.assertRaisesRegex(review.ReviewError, "runtime write"):
            review.validate_salvage_evidence(evidence)

        evidence = json.loads(review.DEFAULT_EVIDENCE.read_text(encoding="utf-8"))
        evidence["graphifyAudit"]["updateBaseCommit"] = "0" * 40

        with self.assertRaisesRegex(review.ReviewError, "Graphify update base"):
            review.validate_salvage_evidence(evidence)

    def test_all_eleven_original_receipts_are_fixed(self) -> None:
        evidence = json.loads(review.DEFAULT_EVIDENCE.read_text(encoding="utf-8"))
        actual = {
            item["path"]: (item["sizeBytes"], item["sha256"])
            for item in evidence["files"]
        }
        expected = {
            "tools/content_factory/manage_scenario_revisions.py": (
                7306,
                "3783e14c1c2720f1db69fb7f1ef4c58452a6a82f2a8dcdd03bb5751304dbbd08",
            ),
            "tools/content_factory/prompts/scenario_persona_repair_v1.md": (
                4719,
                "665d972085e468d6bc5e1b3698897c30b4f672e2d7cd0db6ab77b9412e60f2ec",
            ),
            "tools/content_factory/review/cloze_naturalness_20260826.json": (
                4889,
                "12a2e0fd4666701afd9769257757dd4997e1c43697cd5d136b88bab264e31f17",
            ),
            "tools/content_factory/review/scenario_persona_a1_001.json": (
                261545,
                "4e67f00374caf143f320841c03b27de94044e2dac5df106a8fd4b213a31c6fe7",
            ),
            "tools/content_factory/review/scenario_persona_a1_001.md": (
                115017,
                "7776aa4e6e6a17f1d8b945186c606ace5602292adb74736522bdb6b97c83cf13",
            ),
            "tools/content_factory/review/scenario_persona_a1_001_overlay.json": (
                54050,
                "340ccca3fc03d6f8644a4cef652e3c7fa84644d35f38a8fa09025281d38696c6",
            ),
            "tools/content_factory/review/scenario_theme_audit_20260826.json": (
                234492,
                "87c9fb208389d31b3981958a3a45836094b12c019793a071eef1511323f14d59",
            ),
            "tools/content_factory/scenario_revision_pipeline.py": (
                35521,
                "054f851cd0222ac745dbce2ac603e3c5cbc4494ab4fee62afdb532df79e5a7f2",
            ),
            "tools/content_factory/test_cloze_copy_review.py": (
                2167,
                "2fcebf5232ed87555c9d8967a4cc3dc6cc81098265f6077ffd9f11e1d1f7d1cf",
            ),
            "tools/content_factory/test_scenario_revision_pipeline.py": (
                12791,
                "0e7407a18d323de4a43d42c74e75f310e73e4fd02b901293e3a578bcf0fcbf88",
            ),
            "tools/content_factory/validate_cloze_copy_review.py": (
                5759,
                "2980b33b0cade92d3427934663d30929a8f988b3af01a2dac290cf42865e5b3d",
            ),
        }

        self.assertEqual(actual, expected)

    def test_optional_source_root_recomputes_all_eleven_receipts(self) -> None:
        evidence = json.loads(review.DEFAULT_EVIDENCE.read_text(encoding="utf-8"))
        with tempfile.TemporaryDirectory() as directory:
            source_root = Path(directory)
            for item in evidence["files"]:
                data = (item["path"] + "\n").encode("utf-8")
                path = source_root / item["path"]
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
                item["sizeBytes"] = len(data)
                item["sha256"] = hashlib.sha256(data).hexdigest()

            report = review.validate_salvage_evidence(
                evidence,
                source_root=source_root,
            )
            self.assertEqual(report["sourceFilesVerified"], 11)

            first_path = source_root / evidence["files"][0]["path"]
            first_path.write_bytes(b"drift")
            with self.assertRaisesRegex(review.ReviewError, "source file receipt"):
                review.validate_salvage_evidence(evidence, source_root=source_root)


class ReviewOutputSafetyTest(unittest.TestCase):
    def test_output_cannot_overwrite_locked_canonical_candidates(self) -> None:
        candidate_path = (
            ROOT
            / "tools/content_factory/review/canonical_120_v1/candidates/a1/taxi_kakao.json"
        )

        with self.assertRaisesRegex(review.ReviewError, "scenario_revision_v2"):
            review._review_output(candidate_path)

    def test_output_cannot_overwrite_reserved_receipts_or_existing_reviews(self) -> None:
        for reserved in (review.DEFAULT_EVIDENCE, review.DEFAULT_INDEX):
            with self.subTest(path=reserved):
                with self.assertRaisesRegex(review.ReviewError, "reserved"):
                    review._review_output(reserved)

        existing = review.REVISION_REVIEW_ROOT / "taxi_kakao_review.md"
        with self.assertRaisesRegex(review.ReviewError, "already exists"):
            review._write_review_output(existing, "replacement")


class OverlayValidationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.index = review.build_current_index(ROOT)
        cls.taxi = next(
            item
            for item in cls.index["scenarios"]
            if item["scenarioId"] == "taxi_kakao"
        )

    def _overlay(self, *, before: str, after: str) -> dict:
        return {
            "schemaVersion": 1,
            "kind": "canonical_scenario_revision_overlay",
            "generationId": self.index["generationId"],
            "candidateSetSha256": self.index["candidateSetSha256"],
            "scenarios": [
                {
                    "scenarioId": "taxi_kakao",
                    "candidateSha256": self.taxi["candidateSha256"],
                    "changes": [
                        {
                            "path": "/dialog/1/ko",
                            "before": before,
                            "after": after,
                            "issueCodes": ["PRAG"],
                            "status": "draft_change",
                        }
                    ],
                }
            ],
        }

    def test_stale_candidate_set_fingerprint_is_rejected(self) -> None:
        overlay = self._overlay(
            before="네. 여기 세워 주세요.",
            after="네. 여기에서 세워 주세요.",
        )
        overlay["candidateSetSha256"] = "0" * 64

        with self.assertRaisesRegex(review.ReviewError, "candidate-set SHA"):
            review.validate_overlay(overlay, root=ROOT)

    def test_before_must_match_the_current_candidate_exactly(self) -> None:
        overlay = self._overlay(
            before="옛 대사",
            after="네. 여기에서 세워 주세요.",
        )

        with self.assertRaisesRegex(review.ReviewError, "before mismatch"):
            review.validate_overlay(overlay, root=ROOT)

    def test_taxi_overlay_cannot_assert_automatic_payment(self) -> None:
        overlay = self._overlay(
            before="네. 여기 세워 주세요.",
            after="네. 자동 결제로 하고 여기 세워 주세요.",
        )

        with self.assertRaisesRegex(review.ReviewError, "자동 결제"):
            review.validate_overlay(overlay, root=ROOT)

    def test_taxi_rule_rejects_automatic_payment_variants_in_ko_de_en(self) -> None:
        cases = (
            (
                "/dialog/1/ko",
                "네. 여기 세워 주세요.",
                "네. 결제는 자동으로 되고 여기 세워 주세요.",
            ),
            (
                "/dialog/1/de",
                "Ja. Bitte halten Sie hier.",
                "Ja. Die Zahlung erfolgt automatisch. Bitte halten Sie hier.",
            ),
            (
                "/dialog/1/en",
                "Yes. Please stop here.",
                "Yes. Payment is automatic. Please stop here.",
            ),
            (
                "/dialog/1/ko",
                "네. 여기 세워 주세요.",
                "네. 결제는 알아서 처리되고 여기 세워 주세요.",
            ),
            (
                "/dialog/1/de",
                "Ja. Bitte halten Sie hier.",
                "Ja. Die Zahlung wird automatisiert. Bitte halten Sie hier.",
            ),
            (
                "/dialog/1/en",
                "Yes. Please stop here.",
                "Yes. Payment is automated. Please stop here.",
            ),
            (
                "/dialog/1/en",
                "Yes. Please stop here.",
                "Yes. The fare is paid automatically. Please stop here.",
            ),
        )
        for path, before, after in cases:
            with self.subTest(path=path):
                overlay = self._overlay(before=before, after=after)
                overlay["scenarios"][0]["changes"][0]["path"] = path
                with self.assertRaisesRegex(review.ReviewError, "automatic payment"):
                    review.validate_overlay(overlay, root=ROOT)

    def test_taxi_rule_covers_korean_review_fields_outside_dialogue(self) -> None:
        overlay = self._overlay(
            before="장면 핵심 표현",
            after="자동 결제로 처리되는 표현",
        )
        overlay["scenarios"][0]["changes"][0]["path"] = "/vocab/0/note/ko"

        with self.assertRaisesRegex(review.ReviewError, "자동 결제"):
            review.validate_overlay(overlay, root=ROOT)

    def test_human_gate_cannot_smuggle_a_forbidden_korean_suggestion(self) -> None:
        overlay = self._overlay(
            before="네. 여기 세워 주세요.",
            after="네. 자동 결제로 하고 여기 세워 주세요.",
        )
        overlay["scenarios"][0]["changes"][0]["status"] = "human_gate"

        with self.assertRaisesRegex(review.ReviewError, "자동 결제"):
            review.validate_overlay(overlay, root=ROOT)

    def test_unregistered_approval_fields_are_rejected_at_every_level(self) -> None:
        overlay = self._overlay(
            before="네. 여기 세워 주세요.",
            after="네, 여기 세워 주세요.",
        )
        overlay["reviewStatus"] = "approved"
        with self.assertRaisesRegex(review.ReviewError, "unexpected fields"):
            review.validate_overlay(overlay, root=ROOT)

        overlay = self._overlay(
            before="네. 여기 세워 주세요.",
            after="네, 여기 세워 주세요.",
        )
        overlay["scenarios"][0]["changes"][0]["approved"] = True
        with self.assertRaisesRegex(review.ReviewError, "unexpected fields"):
            review.validate_overlay(overlay, root=ROOT)

    def test_overlay_validation_refuses_a_stale_checked_in_index(self) -> None:
        overlay = self._overlay(
            before="네. 여기 세워 주세요.",
            after="네, 여기 세워 주세요.",
        )
        with mock.patch.object(
            review,
            "verify_current_index",
            side_effect=review.ReviewError("checked-in index is stale"),
        ) as verify:
            with self.assertRaisesRegex(review.ReviewError, "checked-in index"):
                review.validate_overlay(overlay, root=ROOT)
        verify.assert_called_once()

    def test_valid_overlay_is_a_dry_run_and_does_not_change_candidates(self) -> None:
        candidate_path = (
            ROOT
            / "tools/content_factory/review/canonical_120_v1/candidates/a1/taxi_kakao.json"
        )
        original = candidate_path.read_bytes()
        overlay = self._overlay(
            before="네. 여기 세워 주세요.",
            after="네, 여기 세워 주세요.",
        )

        result = review.validate_overlay(copy.deepcopy(overlay), root=ROOT)

        self.assertEqual(candidate_path.read_bytes(), original)
        self.assertEqual(result["scenarioCount"], 1)
        self.assertEqual(result["proposedChangeCount"], 1)
        self.assertFalse(result["runtimeWritten"])
        self.assertFalse(result["ttsGenerationRequested"])


if __name__ == "__main__":
    unittest.main()
