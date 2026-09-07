"""Prelaunch dependency/runtime and privacy checks must stay in CI."""
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


class CommercialSecurityContractTest(unittest.TestCase):
    def ios_jobs(self):
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        jobs = dict(re.findall(r"(?ms)^  ([\w-]+):\n(.*?)(?=^  [\w-]+:\n|\Z)", workflow.split("\njobs:\n", 1)[1]))
        for name in ("ios-native-build", "ios-native-tests"):
            self.assertIn(name, list(jobs))
        return jobs["ios-native-build"], jobs["ios-native-tests"]

    def test_all_node_function_sources_target_supported_node22(self):
        for name in ("gye", "tts", "pronunciation", "auth_cleanup"):
            package = json.loads((ROOT / "functions" / name / "package.json").read_text(encoding="utf-8"))
            self.assertEqual(package["engines"]["node"], "22")
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        auth_job = workflow.split("  auth-cleanup-functions-security:", 1)[1].split("  asset-gates:", 1)[0]
        self.assertIn("node-version: '22'", auth_job)

    def test_storage_dependency_gates_remain_and_billing_emulator_is_retired(self):
        package = json.loads((ROOT / "functions/gye/package.json").read_text(encoding="utf-8"))
        self.assertIn("dependency_security.test.js", package["scripts"]["test"])
        self.assertIn("--only storage", package["scripts"]["test:storage-rules"])
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        self.assertIn("run: npm run test:storage-rules", workflow)
        self.assertNotIn("test:billing-emulator", package["scripts"])
        self.assertNotIn("run: npm run test:billing-emulator", workflow)
        self.assertFalse((ROOT / "functions/gye/billing_emulator.test.js").exists())

    def test_canonical_allowlist_is_checked_against_runtime_corpus_in_ci(self):
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        tts_job = workflow.split("  tts-functions-security:", 1)[1].split("  auth-cleanup-functions-security:", 1)[0]
        self.assertIn("python functions/tts/build_canonical_manifest.py --check", tts_job)

    def test_ios_gate_reuses_existing_setup_without_signing_or_upload(self):
        release, simulator = self.ios_jobs()
        for job in (release, simulator):
            self.assertIn("needs.changes.outputs.ios == 'true'", job)
            self.assertIn("github.event.pull_request.draft == false", job)
            self.assertRegex(job, r"(?m)^    needs: changes$")
            self.assertIn("bash ios/ci_scripts/ci_post_clone.sh", job)
            self.assertNotIn("continue-on-error", job)
            self.assertNotIn("secrets.", job)
        self.assertIn("flutter build ios --release --no-codesign", release)
        self.assertNotIn("xcodebuild test", release)
        self.assertNotIn("flutter build ios --release", simulator)
        self.assertIn("xcrun simctl list devices available -j", simulator)
        self.assertIn("xcodebuild test", simulator)
        self.assertIn("-only-testing:RunnerTests", simulator)
        self.assertIn("CODE_SIGNING_ALLOWED=NO", simulator)

    def test_ios_jobs_have_distinct_bounded_release_and_cold_intel_budgets(self):
        release, simulator = self.ios_jobs()
        for job, expected in ((release, "45"), (simulator, "75")):
            self.assertEqual(re.findall(r"(?m)^    timeout-minutes: (.+)$", job), [expected])
            self.assertNotIn("continue-on-error", job)
        self.assertIn("xcodebuild test", simulator)
        self.assertIn("-only-testing:RunnerTests", simulator)

    def test_ios_simulator_uses_native_intel_for_locked_mlkit_slices(self):
        release, simulator = self.ios_jobs()
        self.assertRegex(release, r"(?m)^    runs-on: macos-15$")
        self.assertRegex(simulator, r"(?m)^    runs-on: macos-15-intel$")
        guard_name = "Verify native Intel simulator host"
        self.assertIn(guard_name, simulator)
        guard = simulator.split(f"      - name: {guard_name}\n", 1)[1].split("      - name:", 1)[0]
        self.assertIn("set -euo pipefail", guard)
        self.assertIn('host_arch="$(uname -m)"', guard)
        self.assertIn('test "$host_arch" = "x86_64"', guard)
        self.assertNotIn("||", guard)
        self.assertLess(simulator.index(guard_name), simulator.index("bash ios/ci_scripts/ci_post_clone.sh"))
        native_test = simulator.split("xcodebuild test", 1)[1]
        self.assertIn('-destination "platform=iOS Simulator,id=$simulator_id,arch=x86_64"', native_test)
        self.assertIn("ARCHS=x86_64 ONLY_ACTIVE_ARCH=YES", native_test)
        self.assertNotIn("ARCHS=x86_64", release)
        self.assertNotIn(guard_name, release)

    def test_book_ci_updates_pip_before_installing_function_dependencies(self):
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        job = workflow.split("  book-analysis-security:", 1)[1].split("  gye-functions-security:", 1)[0]
        bootstrap = "python -m pip install --upgrade pip==26.2.1"
        dependencies = "python -m pip install -r functions/analyze_korean_text/requirements.txt"
        self.assertIn(bootstrap, job)
        self.assertIn(dependencies, job)
        self.assertLess(job.index(bootstrap), job.index(dependencies))

    def test_ios_job_pins_and_verifies_xcode_and_both_sdks_before_preparation(self):
        diagnostics = []
        for job in self.ios_jobs():
            job_env = job.split("    env:\n", 1)[1].split("    steps:\n", 1)[0]
            self.assertIn("DEVELOPER_DIR: /Applications/Xcode_26.3.app/Contents/Developer", job_env)
            diagnostics.append(job.split("      - name: Verify pinned Xcode and iOS SDKs\n", 1)[1].split("      - name:", 1)[0])
            self.assertLess(job.index("Verify pinned Xcode and iOS SDKs"), job.index("bash ios/ci_scripts/ci_post_clone.sh"))
            self.assertNotIn("xcode-select --switch", job)
        self.assertEqual(diagnostics[0], diagnostics[1])
        diagnostic = diagnostics[0]
        self.assertIn("set -euo pipefail", diagnostic)
        self.assertIn('test -d "$DEVELOPER_DIR"', diagnostic)
        self.assertIn('xcode_version="$(xcodebuild -version)"', diagnostic)
        self.assertIn('test "${xcode_version%%$\'\\n\'*}" = "Xcode 26.3"', diagnostic)
        self.assertIn("for sdk in iphoneos iphonesimulator; do", diagnostic)
        self.assertIn('xcrun --sdk "$sdk" --show-sdk-version', diagnostic)
        self.assertIn('xcrun --sdk "$sdk" --show-sdk-path', diagnostic)
        self.assertIn('test "$sdk_version" = "26.2"', diagnostic)
        self.assertIn('"$DEVELOPER_DIR"/*) ;;', diagnostic)
        self.assertIn("exit 1", diagnostic)
        self.assertNotIn("|| true", diagnostic)

    def test_ios_simulator_logs_preserve_test_exit_status_and_always_upload(self):
        _, simulator = self.ios_jobs()
        native_step = simulator.split("      - name: Run native privacy tests on an installed iPhone simulator\n", 1)[1].split("      - name:", 1)[0]
        self.assertIn("set -euo pipefail", native_step)
        self.assertIn("xcodebuild test -workspace", native_step)
        self.assertNotIn("-quiet", native_step)
        self.assertIn('2>&1 | tee "$RUNNER_TEMP/native-privacy-build-test.log"', native_step)
        self.assertNotIn("||", native_step)
        self.assertNotIn("if:", native_step)
        artifact = simulator.split("      - name: Retain native test results\n", 1)[1]
        self.assertIn("if: always()", artifact)
        self.assertIn("${{ runner.temp }}/native-privacy.xcresult", artifact)
        self.assertIn("${{ runner.temp }}/native-privacy-build-test.log", artifact)
        self.assertIn("if-no-files-found: error", artifact)
        self.assertIn("retention-days: 3", artifact)

    def test_ios_tests_use_an_isolated_debug_host_without_app_or_network_imports(self):
        _, job = self.ios_jobs()
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
