import pathlib
import unittest


class PlayInternalWorkflowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = pathlib.Path(".github/workflows/ci.yml").read_text(
            encoding="utf-8"
        )

    def test_release_waits_for_main_quality_gate_and_explicit_enablement(self):
        release = self.workflow.split("  release-internal:", 1)[1]
        self.assertIn("needs: [changes, build]", release)
        self.assertIn("needs.build.result == 'success'", release)
        self.assertIn("github.ref == 'refs/heads/main'", release)
        self.assertIn("vars.PLAY_INTERNAL_RELEASE_ENABLED == 'true'", release)
        self.assertIn("name: google-play-internal", release)

    def test_release_is_signed_reproducible_and_targets_internal_only(self):
        release = self.workflow.split("  release-internal:", 1)[1]
        self.assertIn("fetch-depth: 0", release)
        self.assertIn("flutter build appbundle --release --obfuscate", release)
        self.assertIn("ANDROID_UPLOAD_KEYSTORE_BASE64", release)
        self.assertIn("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON", release)
        self.assertIn("r0adkll/upload-google-play@v1.1.5", release)
        self.assertIn("tracks: internal", release)
        self.assertNotIn("tracks: production", release)

    def test_main_release_survives_unrelated_follow_up_pushes(self):
        workflow_concurrency = self.workflow.split("jobs:", 1)[0]
        self.assertIn(
            "cancel-in-progress: ${{ github.event_name == 'pull_request' }}",
            workflow_concurrency,
        )

        release = self.workflow.split("  release-internal:", 1)[1]
        self.assertIn("group: google-play-internal", release)
        self.assertIn("cancel-in-progress: false", release)


if __name__ == "__main__":
    unittest.main()
