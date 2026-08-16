#!/usr/bin/env python3
"""Regression tests for the reference intake schema and live-ID sync gate."""

from __future__ import annotations

from pathlib import Path
import shutil
import tempfile
import unittest

from validate_reference_intake import ROOT, ReferenceIntakeValidator


class ReferenceIntakeValidatorTest(unittest.TestCase):
    def copy_fixture(self, root: Path) -> None:
        for relative in (
            "assets/data/korean_vocab.csv",
            "assets/data/grammar.csv",
            "assets/data/curriculum_manifest.json",
            "assets/data/scenarios.json",
            "tools/content_factory/reference_intake",
            "tools/content_factory/drafts/batch_04_manifest.json",
            "tools/content_factory/drafts/c1_batch04_scenarios_b1_b2.json",
            "tools/content_factory/drafts/batch_06_manifest.json",
            "tools/content_factory/drafts/c1_batch06_scenarios_b1_c2.json",
        ):
            source = ROOT / relative
            target = root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            if source.is_dir():
                shutil.copytree(source, target)
            else:
                shutil.copy2(source, target)

    def test_current_intake_is_consistent(self) -> None:
        self.assertEqual(ReferenceIntakeValidator().validate(), [])

    def test_clean_room_brief_rejects_source_provenance(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.copy_fixture(root)
            path = root / "tools/content_factory/reference_intake/content_briefs.csv"
            path.write_text(
                path.read_text(encoding="utf-8").replace(
                    "service repair follow-up",
                    "ref0001 service repair follow-up",
                    1,
                ),
                encoding="utf-8",
            )
            issues = ReferenceIntakeValidator(root).validate()
            self.assertTrue(any("leaks source provenance" in issue.message for issue in issues))

    def test_seed_rejects_wrong_live_course_unit(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.copy_fixture(root)
            path = root / "tools/content_factory/reference_intake/seed_bundle_plan.csv"
            path.write_text(
                path.read_text(encoding="utf-8").replace(
                    "b1_05_complaint_resolution",
                    "b1_missing_unit",
                    1,
                ),
                encoding="utf-8",
            )
            issues = ReferenceIntakeValidator(root).validate()
            self.assertTrue(any("invalid course unit" in issue.message for issue in issues))


if __name__ == "__main__":
    unittest.main()
