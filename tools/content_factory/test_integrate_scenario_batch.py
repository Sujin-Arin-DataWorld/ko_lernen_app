#!/usr/bin/env python3
"""Narrow transaction regressions for scenario-batch integration."""

from __future__ import annotations

import json
from pathlib import Path
import shutil
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import integrate_scenario_batch as integration


class ScenarioBatchTransactionTest(unittest.TestCase):
    def test_atomic_restore_preserves_original_bytes_and_newlines(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "content.csv"
            original = b"id,level\r\nexample,a1\r\n"
            target.write_bytes(original)

            integration._atomic_write(target, "id,level\nchanged,c2\n")
            integration._atomic_restore(target, original)

            self.assertEqual(original, target.read_bytes())
            self.assertFalse(
                target.with_name(f".{target.name}.scenario-integration.tmp").exists()
            )

    def test_post_write_failure_restores_every_target_byte_exactly(self) -> None:
        repository = SCRIPT_DIR.parents[1]
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "repo"
            shutil.copytree(repository / "assets" / "data", root / "assets" / "data")

            grammar_source = (
                repository
                / "functions"
                / "analyze_korean_text"
                / "grammar_patterns.json"
            )
            grammar_target = (
                root / "functions" / "analyze_korean_text" / "grammar_patterns.json"
            )
            grammar_target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(grammar_source, grammar_target)

            backdrop_target = root / "lib" / "models" / "scenario.dart"
            backdrop_target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(repository / "lib" / "models" / "scenario.dart", backdrop_target)

            relative_manifest = Path(
                "tools/content_factory/drafts/rollback_probe_manifest.json"
            )
            manifest_target = root / relative_manifest
            manifest_target.parent.mkdir(parents=True, exist_ok=True)
            manifest_target.write_bytes(b'{"status":"approved"}\r\n')

            scenarios_target = root / "assets" / "data" / "scenarios.json"
            scenarios_root = json.loads(scenarios_target.read_text(encoding="utf-8"))
            record = dict(scenarios_root["scenarios"][0])
            record["id"] = "scenario_transaction_rollback_probe"
            unit_id = record["courseUnitId"]
            manifest = {
                "status": "approved",
                "contentLinks": [
                    {
                        "contentKind": "scenario",
                        "contentId": record["id"],
                        "courseUnitId": unit_id,
                        "role": "practice",
                    }
                ],
                "provenance": {},
            }
            outputs = [
                scenarios_target,
                root / "assets" / "data" / "curriculum_manifest.json",
                root / "assets" / "data" / "content_audit_manifest.json",
                backdrop_target,
                manifest_target,
            ]
            originals = {path: path.read_bytes() for path in outputs}
            failure = SimpleNamespace(
                source="rollback-probe",
                message="forced post-write validation failure",
            )

            with (
                mock.patch.object(
                    integration,
                    "_validate_batch",
                    return_value=(
                        manifest_target,
                        manifest,
                        [record],
                        {record["id"]: "home"},
                    ),
                ),
                mock.patch.object(
                    integration.ContentValidator,
                    "validate",
                    side_effect=[[], [failure]],
                ),
            ):
                with self.assertRaisesRegex(
                    integration.ScenarioIntegrationError,
                    "scenario integration rolled back",
                ):
                    integration.integrate(
                        root=root,
                        manifest_path=relative_manifest,
                        apply=True,
                    )

            for path, expected in originals.items():
                self.assertEqual(expected, path.read_bytes(), path)
                self.assertFalse(
                    path.with_name(
                        f".{path.name}.scenario-integration.tmp"
                    ).exists(),
                    path,
                )


if __name__ == "__main__":
    unittest.main()
