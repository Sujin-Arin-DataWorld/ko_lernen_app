"""Static checks for tool/ops/alert_policies/*.json — no network access.

Run: python -m unittest tool.ops.test_alert_policies
(or): .venv/Scripts/python.exe -m unittest tool.ops.test_alert_policies
"""
import json
import re
import unittest
from pathlib import Path

ALERT_DIR = Path(__file__).resolve().parent / "alert_policies"
SOURCES_MD = ALERT_DIR / "_sources.md"
PLACEHOLDER = "${NOTIFICATION_CHANNEL_ID}"

# filename -> substrings that MUST appear somewhere in the filter(s) of that policy.
EXPECTED_METRIC_STRINGS = {
    "01_functions_5xx_rate.json": ["run.googleapis.com/request_count", "response_code_class"],
    "02_appcheck_rejections.json": [
        "firebaseappcheck.googleapis.com/services/verification_count",
        'metric.label."result"="DENY"',
    ],
    "03_ai_cost_breaker_unavailable.json": [
        "logging.googleapis.com/user/ai_cost_breaker_unavailable",
        "logging.googleapis.com/user/apple_revocation_config_invalid",
    ],
    "04_deletion_worker_stalled.json": ["cloudscheduler.googleapis.com/job/execution_count"],
    "05_firestore_write_surge.json": ["firestore.googleapis.com/document/write_count"],
}

# filename -> {condition-level checks}. Every condition dict in the policy is
# searched; these values must be found on at least one condition unless noted.
EXPECTED_THRESHOLDS = {
    "01_functions_5xx_rate.json": {"thresholdValue": 0.02, "duration": "300s"},
    "02_appcheck_rejections.json": {"thresholdValue": 50, "duration": "300s"},
    "03_ai_cost_breaker_unavailable.json": {"thresholdValue": 0, "duration": "0s"},
    "05_firestore_write_surge.json": {"thresholdValue": 10000, "duration": "0s"},
}


def _all_filters(policy: dict) -> str:
    """Concatenate every filter-ish string in the policy so substring checks
    don't need to know which condition type (threshold vs absence) holds it."""
    chunks = []
    for cond in policy.get("conditions", []):
        for key in ("conditionThreshold", "conditionAbsent", "conditionMonitoringQueryLanguage"):
            block = cond.get(key)
            if not block:
                continue
            for field in ("filter", "denominatorFilter", "query"):
                if field in block:
                    chunks.append(str(block[field]))
    return "\n".join(chunks)


def _all_conditions(policy: dict):
    for cond in policy.get("conditions", []):
        for key in ("conditionThreshold", "conditionAbsent"):
            if key in cond:
                yield key, cond[key]


class AlertPolicyFilesTest(unittest.TestCase):
    def test_alert_dir_exists_and_has_five_numbered_policies(self):
        self.assertTrue(ALERT_DIR.is_dir(), f"missing dir: {ALERT_DIR}")
        numbered = sorted(p.name for p in ALERT_DIR.glob("[0-9]*.json"))
        self.assertEqual(
            numbered,
            [
                "01_functions_5xx_rate.json",
                "02_appcheck_rejections.json",
                "03_ai_cost_breaker_unavailable.json",
                "04_deletion_worker_stalled.json",
                "05_firestore_write_surge.json",
            ],
        )

    def test_sources_md_exists(self):
        self.assertTrue(SOURCES_MD.is_file(), f"missing: {SOURCES_MD}")


def _make_policy_test(filename: str):
    path = ALERT_DIR / filename

    def test(self: unittest.TestCase):
        with open(path, encoding="utf-8") as f:
            policy = json.load(f)  # must parse as valid JSON

        # Required top-level shape.
        self.assertIn("displayName", policy)
        self.assertTrue(policy["displayName"].strip())
        self.assertIn("combiner", policy)
        self.assertIn(policy["combiner"], {"OR", "AND", "AND_WITH_MATCHING_RESOURCE"})
        self.assertIn("conditions", policy)
        self.assertIsInstance(policy["conditions"], list)
        self.assertGreaterEqual(len(policy["conditions"]), 1)
        for cond in policy["conditions"]:
            self.assertIn("displayName", cond)
            self.assertTrue(
                "conditionThreshold" in cond or "conditionAbsent" in cond,
                f"{filename}: condition missing conditionThreshold/conditionAbsent",
            )

        # Placeholder present, never a real-looking channel ID.
        channels = policy.get("notificationChannels", [])
        self.assertIn(PLACEHOLDER, channels)
        for ch in channels:
            self.assertFalse(
                re.fullmatch(r"projects/[\w-]+/notificationChannels/\d+", ch),
                f"{filename}: looks like a real notification channel ID, not the placeholder",
            )

        # Metric strings.
        haystack = _all_filters(policy)
        for expected in EXPECTED_METRIC_STRINGS.get(filename, []):
            self.assertIn(expected, haystack, f"{filename}: expected metric string {expected!r} not found in filters")

        # Threshold values match the plan.
        expected_thresholds = EXPECTED_THRESHOLDS.get(filename)
        if expected_thresholds is not None:
            found = False
            for _, block in _all_conditions(policy):
                if "thresholdValue" not in block:
                    continue
                if (
                    block["thresholdValue"] == expected_thresholds["thresholdValue"]
                    and block.get("duration") == expected_thresholds["duration"]
                ):
                    found = True
                    break
            self.assertTrue(
                found,
                f"{filename}: no condition matched thresholdValue={expected_thresholds['thresholdValue']} "
                f"duration={expected_thresholds['duration']!r}",
            )

        # _unverified, if present, must be a bool and (if true) explained.
        if "_unverified" in policy:
            self.assertIsInstance(policy["_unverified"], bool)
            if policy["_unverified"]:
                self.assertIn("_unverified_reason", policy)
                self.assertTrue(policy["_unverified_reason"].strip())

    test.__name__ = f"test_{filename.replace('.', '_')}"
    return test


for _filename in EXPECTED_METRIC_STRINGS:
    setattr(AlertPolicyFilesTest, f"test_{_filename.replace('.', '_')}", _make_policy_test(_filename))


class UnverifiedFlagsListedInSourcesTest(unittest.TestCase):
    def test_every_unverified_policy_is_named_in_sources_md(self):
        sources_text = SOURCES_MD.read_text(encoding="utf-8")
        for path in sorted(ALERT_DIR.glob("[0-9]*.json")):
            with open(path, encoding="utf-8") as f:
                policy = json.load(f)
            if policy.get("_unverified") is True:
                self.assertIn(
                    path.name,
                    sources_text,
                    f"{path.name} is marked _unverified but not mentioned in _sources.md",
                )
                self.assertIn(
                    "UNVERIFIED",
                    sources_text.split(path.name, 1)[1][:400].upper(),
                    f"{path.name}: _sources.md doesn't explain the gap near its mention",
                )

    def test_04_is_the_one_currently_flagged_unverified(self):
        # Documents the current, intentional state so a silent flip doesn't
        # slip through review unnoticed. Update this test if that changes.
        with open(ALERT_DIR / "04_deletion_worker_stalled.json", encoding="utf-8") as f:
            policy = json.load(f)
        self.assertTrue(policy.get("_unverified") is True)

        for name in [
            "01_functions_5xx_rate.json",
            "02_appcheck_rejections.json",
            "03_ai_cost_breaker_unavailable.json",
            "05_firestore_write_surge.json",
        ]:
            with open(ALERT_DIR / name, encoding="utf-8") as f:
                self.assertIsNot(json.load(f).get("_unverified"), True, f"{name} unexpectedly unverified")


if __name__ == "__main__":
    unittest.main()
