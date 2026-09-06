import pathlib
import unittest


class PlayClosedWorkflowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = pathlib.Path(
            ".github/workflows/play_closed.yml"
        ).read_text(encoding="utf-8")

    def test_is_manual_exact_main_release_only(self):
        workflow = self.workflow
        self.assertIn("workflow_dispatch:", workflow)
        self.assertNotIn("pull_request:", workflow)
        self.assertNotIn("\n  push:", workflow)
        self.assertIn("expected_sha:", workflow)
        self.assertIn('GITHUB_REF" != "refs/heads/main', workflow)
        self.assertIn("^[0-9a-f]{40}$", workflow)
        self.assertIn('GITHUB_SHA" != "$EXPECTED_SHA', workflow)

    def test_requires_successful_exact_sha_main_ci(self):
        workflow = self.workflow
        self.assertIn("actions: read", workflow)
        self.assertIn("actions/workflows/ci.yml/runs", workflow)
        self.assertIn(".head_sha == $sha", workflow)
        self.assertIn('.head_branch == "main"', workflow)
        self.assertIn('.event == "push"', workflow)
        self.assertIn('.conclusion == "success"', workflow)

    def test_signed_bundle_targets_closed_alpha_only(self):
        workflow = self.workflow
        self.assertIn("flutter build appbundle --release --obfuscate", workflow)
        self.assertIn("--dart-define=ENABLE_TESTER_FEEDBACK=true", workflow)
        self.assertIn("--dart-define=GIT_COMMIT=${{ github.sha }}", workflow)
        self.assertIn(
            "--dart-define=APPLE_SERVICES_ID=${{ vars.APPLE_SERVICES_ID }}",
            workflow,
        )
        self.assertIn(
            "--dart-define=APPLE_REDIRECT_URI=${{ vars.APPLE_REDIRECT_URI }}",
            workflow,
        )
        self.assertNotIn("BETA_UNLOCK_ALL=true", workflow)
        self.assertIn("ANDROID_UPLOAD_KEYSTORE_BASE64", workflow)
        self.assertIn("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON", workflow)
        self.assertEqual(workflow.count("r0adkll/upload-google-play"), 1)
        self.assertEqual(workflow.count("tracks:"), 1)
        self.assertIn("tracks: alpha", workflow)
        for forbidden in (
            "tracks: internal",
            "tracks: beta",
            "tracks: open",
            "tracks: production",
        ):
            self.assertNotIn(forbidden, workflow)

    def test_artifacts_and_concurrency_are_retained_safely(self):
        workflow = self.workflow
        self.assertIn("group: google-play-closed", workflow)
        self.assertIn("cancel-in-progress: false", workflow)
        self.assertIn("fetch-depth: 0", workflow)
        self.assertIn("sha256sum", workflow)
        self.assertIn("git rev-list --count HEAD", workflow)
        self.assertIn("retention-days: 30", workflow)
        self.assertIn("Preserve Android failure diagnostics", workflow)


class CiWorkflowAppleConfigTest(unittest.TestCase):
    """ci.yml's release-internal appbundle build must pass the same public
    Apple web-flow dart-defines as play_closed.yml (unset repo vars expand to
    empty strings, so this is a no-op until Jin configures Apple + Firebase).
    """

    @classmethod
    def setUpClass(cls):
        cls.workflow = pathlib.Path(".github/workflows/ci.yml").read_text(
            encoding="utf-8"
        )

    def test_internal_bundle_gets_apple_dart_defines(self):
        workflow = self.workflow
        self.assertIn("Build signed internal-testing bundle", workflow)
        self.assertIn(
            "--dart-define=APPLE_SERVICES_ID=${{ vars.APPLE_SERVICES_ID }}",
            workflow,
        )
        self.assertIn(
            "--dart-define=APPLE_REDIRECT_URI=${{ vars.APPLE_REDIRECT_URI }}",
            workflow,
        )


if __name__ == "__main__":
    unittest.main()
