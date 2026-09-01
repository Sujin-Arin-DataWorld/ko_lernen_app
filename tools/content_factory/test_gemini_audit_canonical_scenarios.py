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
    def test_verify_free_tier_project_matches_key_without_recording_secret(self) -> None:
        billing = json.dumps(
            {"projectId": "free-project", "billingEnabled": False}
        )
        keys = json.dumps([{"uid": "key-uid"}])

        with mock.patch(
            "gemini_audit_canonical_scenarios._gcloud_output",
            side_effect=(billing, keys, "secret"),
        ):
            result = audit.verify_free_tier_project(
                "secret", "free-project", gcloud_executable="gcloud"
            )

        self.assertFalse(result["billingEnabled"])
        self.assertEqual(result["apiKeyUid"], "key-uid")
        self.assertNotIn("secret", json.dumps(result))

    def test_verify_free_tier_project_rejects_billing_enabled_project(self) -> None:
        billing = json.dumps(
            {"projectId": "paid-project", "billingEnabled": True}
        )
        with mock.patch(
            "gemini_audit_canonical_scenarios._gcloud_output",
            side_effect=(billing, "[]"),
        ):
            with self.assertRaises(audit.GeminiAuditError):
                audit.verify_free_tier_project(
                    "secret", "paid-project", gcloud_executable="gcloud"
                )

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

    def test_validate_model_audit_rejects_relaxed_schema_drift(self) -> None:
        ids = [f"scenario_{index:02d}" for index in range(20)]
        scenarios = [_scenario(value) for value in ids]
        scenarios[0]["scores"]["levelFit"] = 8

        with self.assertRaises(audit.GeminiAuditError):
            audit.validate_model_audit(
                {"level": "a1", "scenarios": scenarios, "summaryKo": ""},
                level="a1",
                expected_ids=ids,
            )

        relaxed = audit.audit_schema(relaxed=True)
        self.assertNotIn("additionalProperties", relaxed)

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

    def test_free_tier_cost_is_zero(self) -> None:
        counts = {level: 10_000 for level in audit.pipeline.LEVELS}

        estimate = audit.estimate_cost(
            counts,
            max_output_tokens=12_288,
            pricing_tier="free",
        )
        actual = audit.actual_cost(
            {
                "promptTokenCount": 10_000,
                "candidatesTokenCount": 2_000,
                "thoughtsTokenCount": 1_000,
            },
            pricing_tier="free",
        )

        self.assertEqual(estimate["estimatedUpperUsd"], 0.0)
        self.assertEqual(actual, 0.0)
        self.assertIn("billing-disabled", estimate["basis"])

    def test_free_tier_estimate_does_not_spend_count_token_requests(self) -> None:
        client = mock.Mock()

        count = audit.prompt_token_count_for_estimate(
            client,
            model="gemini-3.5-flash",
            contents=[{"parts": [{"text": "x"}]}],
            pricing_tier="free",
        )

        self.assertEqual(count, 0)
        client.count_tokens.assert_not_called()

    def test_retry_delay_honors_free_tier_retry_window(self) -> None:
        delay = audit.retry_delay_seconds(
            "Quota exceeded. Please retry in 24.540926362s.",
            attempt=1,
        )

        self.assertAlmostEqual(delay, 25.540926362)

    def test_request_hash_changes_with_audit_contract(self) -> None:
        base = {
            "generation_id": "generation",
            "model": "gemini-3.5-flash",
            "thinking_level": "low",
            "max_output_tokens": 100,
            "contents": [{"role": "user", "parts": [{"text": "one"}]}],
            "schema": {"type": "object"},
        }

        first = audit.audit_request_hash(**base)
        changed = dict(base)
        changed["contents"] = [{"role": "user", "parts": [{"text": "two"}]}]

        self.assertNotEqual(first, audit.audit_request_hash(**changed))

    def test_resume_reuses_only_exact_valid_receipt(self) -> None:
        ids = [f"scenario_{index:02d}" for index in range(20)]
        expected = {"candidateSetSha256": "current", "auditRequestSha256": "request"}
        receipt = {
            **expected,
            "modelVersion": "gemini-version",
            "responseId": "response-id",
            "audit": {
                "level": "a1",
                "scenarios": [_scenario(value) for value in ids],
                "summaryKo": "",
            },
        }

        self.assertIsNotNone(
            audit.reusable_resume_audit(
                receipt,
                expected_fields=expected,
                level="a1",
                expected_ids=ids,
            )
        )
        stale = dict(receipt, candidateSetSha256="stale")
        self.assertIsNone(
            audit.reusable_resume_audit(
                stale,
                expected_fields=expected,
                level="a1",
                expected_ids=ids,
            )
        )

    def test_audit_instructions_do_not_map_haeyo_style_to_sie(self) -> None:
        instructions = audit._audit_instructions("a2")

        self.assertIn("-요체는 독일어 Sie의 자동 근거가 아니다", instructions)
        self.assertIn("친구·친한 사이·연애 관계", instructions)
        self.assertIn("Könnte ich ...?", instructions)
        self.assertIn("findings=[]와 pass", instructions)
        self.assertIn("기계적으로 Sie/du", instructions)

    def test_structured_output_validation_retries_once(self) -> None:
        ids = [f"scenario_{index:02d}" for index in range(20)]
        valid = {
            "level": "a1",
            "scenarios": [_scenario(value) for value in ids],
            "summaryKo": "",
        }
        client = mock.Mock()
        client.generate.side_effect = (
            {"candidates": [{"content": {"parts": [{"text": "not-json"}]}}]},
            {
                "candidates": [
                    {"content": {"parts": [{"text": json.dumps(valid)}]}}
                ]
            },
        )

        _, result = audit.generate_validated_audit(
            client,
            model="gemini-3.5-flash",
            contents=[],
            schema={},
            thinking_level="low",
            max_output_tokens=100,
            level="a1",
            expected_ids=ids,
        )

        self.assertEqual(client.generate.call_count, 2)
        self.assertEqual(result["level"], "a1")

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
