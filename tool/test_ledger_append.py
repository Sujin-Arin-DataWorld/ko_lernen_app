"""Tests for tool/ledger_append.py.

The acceptance bar from the "살아 있는 한옥" plan: `--validate` must pass
against the real, already-committed HANOK_V1_ASSET_PROVENANCE.json ledger.
The rest of this file exercises the individual rules against small synthetic
ledgers so a future rule change is caught here, not only against the one
real file.
"""

from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import ledger_append  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]


def _minimal_ledger(records: list[dict], allowed_inputs: list[dict] | None = None) -> dict:
    return {
        "allowedModelInputs": allowed_inputs or [],
        "generationLedger": {
            "schemaVersion": 1,
            "hashAlgorithm": "sha256",
            "budgetCredits": {"staticMax": 100.0, "videoMax": 10.0, "totalMax": 110.0},
            "recordSchema": {
                "requiredFields": list(ledger_append.REQUIRED_RECORD_FIELDS),
                "inputAssetFields": list(ledger_append.INPUT_ASSET_FIELDS),
                "outputAssetFields": list(ledger_append.OUTPUT_ASSET_FIELDS),
                "outputAssetKinds": ["part", "state"],
            },
            "records": records,
            "priorDiscardedCredits": {"credits": 0.0},
        },
    }


class ValidateRealLedgerTest(unittest.TestCase):
    def test_the_real_hanok_ledger_validates_clean(self) -> None:
        data = ledger_append.load_ledger()
        problems = ledger_append.validate(data)
        self.assertEqual(problems, [])


class ValidateSyntheticRuleTest(unittest.TestCase):
    def test_local_provider_must_cost_zero(self) -> None:
        data = _minimal_ledger([
            {
                "id": "r1", "provider": "local", "model": "x", "mediaKind": "static",
                "occurredAtUtc": "2026-08-18T00:00:00Z", "costCredits": 1.0,
                "promptSha256": "a" * 64, "inputAssets": [], "outputAssets": [],
            }
        ])
        problems = ledger_append.validate(data)
        self.assertTrue(any("must cost exactly 0" in p for p in problems))

    def test_paid_provider_must_cost_more_than_zero(self) -> None:
        data = _minimal_ledger([
            {
                "id": "r1", "provider": "bbanana", "model": "x", "mediaKind": "static",
                "occurredAtUtc": "2026-08-18T00:00:00Z", "costCredits": 0.0,
                "promptSha256": "a" * 64, "inputAssets": [], "outputAssets": [],
            }
        ])
        problems = ledger_append.validate(data)
        self.assertTrue(any("must cost > 0" in p for p in problems))

    def test_non_utc_timestamp_fails(self) -> None:
        data = _minimal_ledger([
            {
                "id": "r1", "provider": "local", "model": "x", "mediaKind": "static",
                "occurredAtUtc": "2026-08-18T00:00:00", "costCredits": 0.0,
                "promptSha256": "a" * 64, "inputAssets": [], "outputAssets": [],
            }
        ])
        problems = ledger_append.validate(data)
        self.assertTrue(any("canonical UTC" in p for p in problems))

    def test_input_must_be_a_known_allowlisted_or_approved_path(self) -> None:
        data = _minimal_ledger([
            {
                "id": "r1", "provider": "local", "model": "x", "mediaKind": "static",
                "occurredAtUtc": "2026-08-18T00:00:00Z", "costCredits": 0.0,
                "promptSha256": "a" * 64,
                "inputAssets": [{"path": "some/unknown.png", "sha256": "b" * 64}],
                "outputAssets": [],
            }
        ])
        problems = ledger_append.validate(data)
        self.assertTrue(any("not a known allowlisted" in p for p in problems))

    def test_an_approved_output_becomes_a_known_input_for_later_records(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            output_path = Path(tmp) / "generated.png"
            output_path.write_bytes(b"fake png bytes")
            sha = hashlib.sha256(output_path.read_bytes()).hexdigest()
            rel = str(output_path.relative_to(ROOT)) if output_path.is_relative_to(ROOT) else str(output_path)
            data = _minimal_ledger([
                {
                    "id": "r1", "provider": "local", "model": "x", "mediaKind": "static",
                    "occurredAtUtc": "2026-08-18T00:00:00Z", "costCredits": 0.0,
                    "promptSha256": "a" * 64, "inputAssets": [],
                    "outputAssets": [{"path": rel, "sha256": sha, "decision": "approved", "kind": "part"}],
                },
                {
                    "id": "r2", "provider": "local", "model": "x", "mediaKind": "static",
                    "occurredAtUtc": "2026-08-18T00:01:00Z", "costCredits": 0.0,
                    "promptSha256": "a" * 64,
                    "inputAssets": [{"path": rel, "sha256": sha}],
                    "outputAssets": [],
                },
            ])
            problems = ledger_append.validate(data)
            self.assertEqual(problems, [])

    def test_a_rejected_output_does_not_become_a_known_input(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            output_path = Path(tmp) / "rejected.png"
            output_path.write_bytes(b"fake rejected bytes")
            sha = hashlib.sha256(output_path.read_bytes()).hexdigest()
            data = _minimal_ledger([
                {
                    "id": "r1", "provider": "local", "model": "x", "mediaKind": "static",
                    "occurredAtUtc": "2026-08-18T00:00:00Z", "costCredits": 0.0,
                    "promptSha256": "a" * 64, "inputAssets": [],
                    "outputAssets": [{"path": str(output_path), "sha256": sha, "decision": "rejected"}],
                },
                {
                    "id": "r2", "provider": "local", "model": "x", "mediaKind": "static",
                    "occurredAtUtc": "2026-08-18T00:01:00Z", "costCredits": 0.0,
                    "promptSha256": "a" * 64,
                    "inputAssets": [{"path": str(output_path), "sha256": sha}],
                    "outputAssets": [],
                },
            ])
            problems = ledger_append.validate(data)
            self.assertTrue(any("not a known allowlisted" in p for p in problems))

    def test_budget_overflow_is_caught(self) -> None:
        data = _minimal_ledger([
            {
                "id": "r1", "provider": "bbanana", "model": "x", "mediaKind": "static",
                "occurredAtUtc": "2026-08-18T00:00:00Z", "costCredits": 200.0,
                "promptSha256": "a" * 64, "inputAssets": [], "outputAssets": [],
            }
        ])
        problems = ledger_append.validate(data)
        self.assertTrue(any("exceed staticMax" in p for p in problems))

    def test_duplicate_ids_are_caught(self) -> None:
        rec = {
            "id": "dupe", "provider": "local", "model": "x", "mediaKind": "static",
            "occurredAtUtc": "2026-08-18T00:00:00Z", "costCredits": 0.0,
            "promptSha256": "a" * 64, "inputAssets": [], "outputAssets": [],
        }
        data = _minimal_ledger([dict(rec), dict(rec)])
        problems = ledger_append.validate(data)
        self.assertTrue(any("duplicate generation record id" in p for p in problems))


class AppendRecordTest(unittest.TestCase):
    def test_append_computes_hashes_and_writes_a_valid_record(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            asset = tmp_path / "input.png"
            asset.write_bytes(b"some bytes")
            asset_sha = hashlib.sha256(asset.read_bytes()).hexdigest()

            ledger_path = tmp_path / "ledger.json"
            ledger_path.write_text(
                json.dumps(_minimal_ledger(
                    [], allowed_inputs=[{"path": str(asset), "sha256": asset_sha}]
                )),
                encoding="utf-8",
            )

            output = tmp_path / "output.png"
            output.write_bytes(b"generated bytes")

            spec_path = tmp_path / "spec.json"
            spec_path.write_text(
                json.dumps({
                    "id": "new-record",
                    "provider": "local",
                    "model": "python fake_tool.py",
                    "mediaKind": "static",
                    "occurredAtUtc": "2026-08-18T00:00:00Z",
                    "costCredits": 0.0,
                    "promptText": "python fake_tool.py",
                    "inputAssets": [{"path": str(asset)}],
                    "outputAssets": [{"path": str(output), "decision": "approved", "kind": "part"}],
                }),
                encoding="utf-8",
            )

            ledger_append.append_record(ledger_path, spec_path)

            written = json.loads(ledger_path.read_text(encoding="utf-8"))
            records = written["generationLedger"]["records"]
            self.assertEqual(len(records), 1)
            self.assertEqual(records[0]["id"], "new-record")
            self.assertEqual(records[0]["outputAssets"][0]["sha256"], hashlib.sha256(output.read_bytes()).hexdigest())
            self.assertEqual(ledger_append.validate(written), [])

    def test_append_refuses_a_duplicate_id(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            ledger_path = tmp_path / "ledger.json"
            existing = {
                "id": "already-there", "provider": "local", "model": "x", "mediaKind": "static",
                "occurredAtUtc": "2026-08-18T00:00:00Z", "costCredits": 0.0,
                "promptSha256": "a" * 64, "inputAssets": [], "outputAssets": [],
            }
            ledger_path.write_text(json.dumps(_minimal_ledger([existing])), encoding="utf-8")

            spec_path = tmp_path / "spec.json"
            spec_path.write_text(
                json.dumps({
                    "id": "already-there", "provider": "local", "model": "x", "mediaKind": "static",
                    "occurredAtUtc": "2026-08-18T00:01:00Z", "costCredits": 0.0,
                    "promptText": "x", "inputAssets": [], "outputAssets": [],
                }),
                encoding="utf-8",
            )
            with self.assertRaises(ledger_append.LedgerValidationError):
                ledger_append.append_record(ledger_path, spec_path)


if __name__ == "__main__":
    unittest.main()
