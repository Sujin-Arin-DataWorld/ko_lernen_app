from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SKILL_ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = SKILL_ROOT / "scripts" / "validate-evals.py"
EVALS = SKILL_ROOT / "evals" / "evals.json"


def case(case_id: str, direction: str) -> dict[str, object]:
    return {
        "id": case_id,
        "directions": [direction],
        "phenomena": ["reference"],
        "query": "Translate the supplied sentence.",
        "expected_behavior": ["Preserves the supplied meaning"],
        "forbidden_implications": ["Does not invent an actor"],
        "accepted_variants": ["A neutral target-language structure"],
        "unresolved_fields": [],
        "severity_if_failed": "critical",
        "baseline_observation": "Fixture for validator behavior.",
    }


class ValidateEvalsTest(unittest.TestCase):
    def run_validator(self, payload: list[dict[str, object]]) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "evals.json"
            path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
            return subprocess.run(
                [sys.executable, str(VALIDATOR), str(path)],
                capture_output=True,
                text=True,
                encoding="utf-8",
                check=False,
            )

    @staticmethod
    def complete_matrix() -> list[dict[str, object]]:
        return [
            case("ko-en-case", "ko-en"),
            case("en-ko-case", "en-ko"),
            case("ko-de-case", "ko-de"),
            case("de-ko-case", "de-ko"),
        ]

    def test_repository_evaluation_matrix_is_valid(self) -> None:
        result = subprocess.run(
            [sys.executable, str(VALIDATOR), str(EVALS)],
            capture_output=True,
            text=True,
            encoding="utf-8",
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_accepts_a_complete_four_direction_matrix(self) -> None:
        result = self.run_validator(self.complete_matrix())
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("evals: valid", result.stdout)

    def test_rejects_duplicate_ids(self) -> None:
        payload = self.complete_matrix()
        payload[1]["id"] = payload[0]["id"]
        result = self.run_validator(payload)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("duplicate id", result.stdout)

    def test_rejects_missing_forbidden_implications(self) -> None:
        payload = self.complete_matrix()
        payload[0]["forbidden_implications"] = []
        result = self.run_validator(payload)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("forbidden_implications", result.stdout)

    def test_rejects_an_incomplete_direction_matrix(self) -> None:
        result = self.run_validator(self.complete_matrix()[:3])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing directions: de-ko", result.stdout)

    def test_rejects_non_string_direction_without_crashing(self) -> None:
        payload = self.complete_matrix()
        payload[0]["directions"] = [{"unexpected": "object"}]
        result = self.run_validator(payload)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("entries must be non-empty strings", result.stdout)
        self.assertNotIn("Traceback", result.stderr)


if __name__ == "__main__":
    unittest.main()
