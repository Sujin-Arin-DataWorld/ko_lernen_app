from __future__ import annotations

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class AppStoreScreenshotWorkflowContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.workflow = (ROOT / '.github/workflows/app_store_screenshots.yml').read_text(
            encoding='utf-8'
        )
        cls.runner = (
            ROOT / '.github/scripts/capture_app_store_screenshots.sh'
        ).read_text(encoding='utf-8')
        cls.integration = (
            ROOT / 'integration_test/app_store_screenshots_test.dart'
        ).read_text(encoding='utf-8')
        cls.driver = (
            ROOT / 'test_driver/app_store_screenshots_driver.dart'
        ).read_text(encoding='utf-8')
        cls.receipt = (
            ROOT / '.github/scripts/build_app_store_screenshot_receipt.py'
        ).read_text(encoding='utf-8')

    def test_workflow_is_manual_exact_green_main_only(self) -> None:
        self.assertIn('workflow_dispatch:', self.workflow)
        self.assertNotRegex(self.workflow, r'(?m)^\s+(push|pull_request):')
        self.assertIn('refs/heads/main', self.workflow)
        self.assertIn('=~ ^[0-9a-f]{40}$', self.workflow)
        self.assertIn('head_sha == $sha', self.workflow)
        self.assertIn('head_branch == "main"', self.workflow)
        self.assertIn('conclusion == "success"', self.workflow)
        self.assertIn('macos-15-intel', self.workflow)
        self.assertIn('/Applications/Xcode_26.3.app', self.workflow)
        self.assertIn('test "$sdk_version" = "26.2"', self.workflow)

    def test_runner_builds_once_and_reuses_binary_for_four_drives(self) -> None:
        self.assertEqual(self.runner.count('xcodebuild build-for-testing'), 1)
        self.assertEqual(self.runner.count('flutter build ios'), 1)
        self.assertIn('for device in iphone-6.9 ipad-13', self.runner)
        self.assertIn('for locale in de en', self.runner)
        self.assertIn('--use-application-binary="$app_path"', self.runner)
        self.assertIn('binary_sha256=', self.runner)
        self.assertIn('iPad-Pro-13-inch-M4', self.runner)
        self.assertIn('iPhone-16-Pro-Max', self.runner)
        self.assertNotIn('flutter pub get', self.runner)

    def test_capture_uses_real_production_routes_without_grants(self) -> None:
        self.assertIn('KoLernenApp(', self.integration)
        self.assertNotIn('setMockInitialValues', self.integration)
        for route in (
            "'/course/phases'",
            "'/learning-phase/task'",
            "'/vocab'",
            "'/scenario'",
        ):
            self.assertIn(route, self.integration)
        self.assertEqual(self.integration.count('await _capture('), 5)
        for forbidden in ('grantXp', 'grantReward', "'/hanok'", 'HanokV3Preview'):
            self.assertNotIn(forbidden, self.integration)

    def test_driver_emits_rgb_png_and_receipt_requires_all_sets(self) -> None:
        self.assertIn('convert(numChannels: 3)', self.driver)
        self.assertIn("for locale in ('de', 'en')", self.receipt)
        self.assertIn("for target in ('iphone-6.9', 'ipad-13')", self.receipt)
        self.assertIn('validate_directory(folder, target)', self.receipt)
        self.assertIn("'sourceSha': actual_sha", self.receipt)
        self.assertIn("executable.get('bundleId')", self.receipt)
        self.assertIn("'sha256': _sha256(path)", self.receipt)
        self.assertEqual(len(re.findall(r"'0[1-5]-[^']+\.png'", self.receipt)), 5)


if __name__ == '__main__':
    unittest.main()
