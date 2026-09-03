"""Prelaunch dependency/runtime and privacy checks must stay in CI."""
import json
from pathlib import Path
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
        self.assertNotIn("secrets.", job)


if __name__ == "__main__":
    unittest.main()
