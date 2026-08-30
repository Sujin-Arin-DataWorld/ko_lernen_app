"""Check-mode regression tests for the scenario quest auditor."""

from __future__ import annotations

import sys
import tempfile
import unittest
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import audit_scenario_quests  # noqa: E402


class ScenarioQuestAuditCheckTest(unittest.TestCase):
    def test_check_is_read_only_and_detects_report_drift(self) -> None:
        groups, diagnostics = audit_scenario_quests.scan_all()
        rendered = audit_scenario_quests.render_report(groups, diagnostics)
        self.assertEqual(
            audit_scenario_quests.strict_issue_count(groups, diagnostics),
            0,
        )

        with tempfile.TemporaryDirectory() as tmp:
            report = Path(tmp) / "scenario_quest_report.md"
            report.write_text(rendered, encoding="utf-8", newline="\n")
            before = report.read_bytes()

            self.assertEqual(
                audit_scenario_quests.main(
                    ["--check", "--report", str(report)]
                ),
                0,
            )
            self.assertEqual(report.read_bytes(), before)

            report.write_text("stale\n", encoding="utf-8", newline="\n")
            self.assertEqual(
                audit_scenario_quests.main(
                    ["--check", "--report", str(report)]
                ),
                1,
            )
            self.assertEqual(report.read_text(encoding="utf-8"), "stale\n")

    def test_strict_count_includes_every_ambiguous_finding(self) -> None:
        diagnostics = {
            "broken_payloads": [object(), object()],
            "unsupported_types": Counter({"newQuest": 3}),
        }
        self.assertEqual(
            audit_scenario_quests.strict_issue_count([object()], diagnostics),
            6,
        )


if __name__ == "__main__":
    unittest.main()
