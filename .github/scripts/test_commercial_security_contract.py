"""Prelaunch dependency/runtime and privacy checks must stay in CI."""
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


class CommercialSecurityContractTest(unittest.TestCase):
    def test_all_node_function_sources_target_supported_node22(self):
        for name in ("gye", "tts", "pronunciation", "auth_cleanup"):
            package = json.loads((ROOT / "functions" / name / "package.json").read_text(encoding="utf-8"))
            self.assertEqual(package["engines"]["node"], "22")
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        auth_job = workflow.split("  auth-cleanup-functions-security:", 1)[1].split("  asset-gates:", 1)[0]
        self.assertIn("node-version: '22'", auth_job)

    def test_storage_emulator_and_dependency_regressions_are_not_local_only(self):
        package = json.loads((ROOT / "functions/gye/package.json").read_text(encoding="utf-8"))
        self.assertIn("dependency_security.test.js", package["scripts"]["test"])
        self.assertIn("--only storage", package["scripts"]["test:storage-rules"])
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        self.assertIn("run: npm run test:storage-rules", workflow)
        self.assertIn("run: npm run test:billing-emulator", workflow)

    def test_canonical_allowlist_is_checked_against_runtime_corpus_in_ci(self):
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        tts_job = workflow.split("  tts-functions-security:", 1)[1].split("  auth-cleanup-functions-security:", 1)[0]
        self.assertIn("python functions/tts/build_canonical_manifest.py --check", tts_job)

    def test_ios_gate_reuses_existing_setup_without_signing_or_upload(self):
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        self.assertIn("  ios-native-build:", workflow)
        if "  ios-native-build:" not in workflow:
            return
        job = workflow.split("  ios-native-build:", 1)[1].split("  release-internal:", 1)[0]
        self.assertIn("needs.changes.outputs.ios == 'true'", job)
        self.assertIn("bash ios/ci_scripts/ci_post_clone.sh", job)
        self.assertIn("flutter build ios --release --no-codesign", job)
        self.assertIn("xcrun simctl list devices available -j", job)
        self.assertIn("xcodebuild test", job)
        self.assertIn("-only-testing:RunnerTests", job)
        self.assertIn("CODE_SIGNING_ALLOWED=NO", job)
        self.assertNotIn("secrets.", job)

    def test_book_ci_updates_pip_before_installing_function_dependencies(self):
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        job = workflow.split("  book-analysis-security:", 1)[1].split("  gye-functions-security:", 1)[0]
        bootstrap = "python -m pip install --upgrade pip==26.2.1"
        dependencies = "python -m pip install -r functions/analyze_korean_text/requirements.txt"
        self.assertIn(bootstrap, job)
        self.assertIn(dependencies, job)
        self.assertLess(job.index(bootstrap), job.index(dependencies))

    def test_ios_tests_use_an_isolated_debug_host_without_app_or_network_imports(self):
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        job = workflow.split("  ios-native-build:", 1)[1].split("  release-internal:", 1)[0]
        native_test = job.split("xcodebuild test", 1)[1]
        self.assertIn("FLUTTER_TARGET=test/support/native_test_host.dart", native_test)
        self.assertIn("FLUTTER_BUILD_MODE=debug", native_test)
        host = (ROOT / "test/support/native_test_host.dart").read_text(encoding="utf-8")
        directives = re.findall(r"^\s*(?:import|export|part)\s+['\"]([^'\"]+)['\"]", host, re.MULTILINE)
        self.assertEqual(directives, ["package:flutter/widgets.dart"])
        self.assertIn("void main()", host)
        self.assertIn("runApp(const SizedBox.shrink())", host)


if __name__ == "__main__":
    unittest.main()
