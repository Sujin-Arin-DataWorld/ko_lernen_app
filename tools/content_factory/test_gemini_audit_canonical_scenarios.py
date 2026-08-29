from __future__ import annotations

import io
import json
import unittest
from unittest import mock
import urllib.error

import gemini_audit_canonical_scenarios as audit


def _scenario(scenario_id: str, *, verdict: str = "pass") -> dict:
    return {
        "scenarioId": scenario_id,
        "verdict": verdict,
        "scores": {
            "koreanNaturalness": 5,
            "levelFit": 5,
            "germanLocalization": 5,
            "englishLocalization": 5,
            "pragmaticAlignment": 5,
        },
        "findings": [],
        "strengthsKo": [],
    }


class GeminiCanonicalAuditTest(unittest.TestCase):
    def test_level_payload_contains_exact_twenty_candidates(self) -> None:
        candidates, payload = audit.level_payload("a1")

        self.assertEqual(len(candidates), 20)
        self.assertEqual(len(payload["scenes"]), 20)
        self.assertEqual(
            [item["scenarioId"] for item in candidates],
            [item["candidate"]["scenarioId"] for item in payload["scenes"]],
        )

    def test_validate_model_audit_preserves_locked_order(self) -> None:
        ids = [f"scenario_{index:02d}" for index in range(20)]
        result = {
            "level": "a1",
            "scenarios": [_scenario(value) for value in reversed(ids)],
            "summaryKo": "문제 없음",
        }

        normalized = audit.validate_model_audit(
            result, level="a1", expected_ids=ids
        )

        self.assertEqual(
            [item["scenarioId"] for item in normalized["scenarios"]], ids
        )

    def test_validate_model_audit_rejects_critical_pass(self) -> None:
        ids = [f"scenario_{index:02d}" for index in range(20)]
        scenarios = [_scenario(value) for value in ids]
        scenarios[0]["findings"] = [
            {
                "severity": "critical",
                "code": "ACC",
                "scope": "multi",
                "path": "/scenario/dialog/0",
                "evidence": "x",
                "analysisKo": "x",
                "recommendationKo": "x",
            }
        ]
        result = {"level": "a1", "scenarios": scenarios, "summaryKo": ""}

        with self.assertRaises(audit.GeminiAuditError):
            audit.validate_model_audit(result, level="a1", expected_ids=ids)

    def test_estimate_cost_uses_six_bounded_requests(self) -> None:
        counts = {level: 10_000 for level in audit.pipeline.LEVELS}

        estimate = audit.estimate_cost(counts, max_output_tokens=12_288)

        self.assertEqual(estimate["totalInputTokens"], 60_000)
        self.assertLess(estimate["estimatedUpperUsd"], 2.0)

    def test_actual_cost_includes_thinking_tokens(self) -> None:
        value = audit.actual_cost(
            {
                "promptTokenCount": 10_000,
                "candidatesTokenCount": 2_000,
                "thoughtsTokenCount": 1_000,
            }
        )

        self.assertAlmostEqual(value, 0.056)

    def test_depleted_prepayment_is_not_retried(self) -> None:
        error = urllib.error.HTTPError(
            "https://example.invalid",
            429,
            "Too Many Requests",
            {},
            io.BytesIO(
                json.dumps(
                    {"error": {"message": "Your prepayment credits are depleted."}}
                ).encode("utf-8")
            ),
        )
        client = audit.GeminiClient("secret", max_attempts=3)

        with mock.patch("urllib.request.urlopen", side_effect=error) as urlopen:
            with self.assertRaises(audit.GeminiAuditError):
                client.count_tokens("model", [{"parts": [{"text": "x"}]}])

        self.assertEqual(urlopen.call_count, 1)


if __name__ == "__main__":
    unittest.main()
