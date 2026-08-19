import pathlib
import re
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
        release = self.workflow.split("  release-internal:", 1)[1].split(
            "  release-website:", 1
        )[0]
        self.assertIn("fetch-depth: 0", release)
        self.assertIn("flutter build appbundle --release --obfuscate", release)
        self.assertIn("ANDROID_UPLOAD_KEYSTORE_BASE64", release)
        self.assertIn("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON", release)
        self.assertIn("r0adkll/upload-google-play@v1.1.5", release)
        self.assertIn("Build signed internal-testing bundle", release)
        self.assertNotIn("closed-testing bundle", release)
        self.assertEqual(release.count("r0adkll/upload-google-play"), 1)
        self.assertEqual(release.count("tracks:"), 1)
        self.assertIn("tracks: internal", release)
        for forbidden in (
            "tracks: production",
            "tracks: alpha",
            "tracks: beta",
            "tracks: closed",
            "tracks: open",
        ):
            self.assertNotIn(forbidden, release)

    def test_ci_never_deploys_ios_or_closed_testing(self):
        uses = re.findall(r"^\s+uses:\s+(\S+)", self.workflow, re.MULTILINE)
        play_uploads = [
            action for action in uses if "upload-google-play" in action
        ]
        self.assertEqual(play_uploads, ["r0adkll/upload-google-play@v1.1.5"])
        ios_uploads = [
            action
            for action in uses
            if any(
                token in action.lower()
                for token in (
                    "testflight",
                    "fastlane",
                    "app-store-connect",
                    "apple-actions",
                )
            )
        ]
        self.assertEqual(ios_uploads, [])
        self.assertEqual(self.workflow.count("tracks:"), 1)

    def test_main_release_survives_unrelated_follow_up_pushes(self):
        workflow_concurrency = self.workflow.split("jobs:", 1)[0]
        self.assertIn(
            "cancel-in-progress: ${{ github.event_name == 'pull_request' }}",
            workflow_concurrency,
        )

        release = self.workflow.split("  release-internal:", 1)[1]
        self.assertIn("group: google-play-internal", release)
        self.assertIn("cancel-in-progress: false", release)

    def test_release_fits_private_runner_memory_and_preserves_diagnostics(self):
        release = self.workflow.split("  release-internal:", 1)[1]
        self.assertIn("Fit Gradle to GitHub runner memory", release)
        self.assertIn("org.gradle.jvmargs=-Xmx4G", release)
        self.assertIn("-XX:MaxMetaspaceSize=1G", release)
        self.assertIn("org.gradle.workers.max=2", release)
        self.assertIn("org.gradle.parallel=false", release)
        self.assertIn("org.gradle.daemon=false", release)
        self.assertIn("org.gradle.vfs.watch=false", release)
        self.assertIn("kotlin.compiler.execution.strategy=in-process", release)
        self.assertIn("Preserve Android failure diagnostics", release)

    def test_release_stays_under_the_runner_disk_ceiling(self):
        # 2026-08-17 run 32001006286: upload succeeded, then setup-java's
        # post-step Gradle cache save failed with "No space left on device".
        release = self.workflow.split("  release-internal:", 1)[1].split(
            "  release-website:", 1
        )[0]
        self.assertIn("Free runner disk for the release build", release)
        self.assertIn("/opt/hostedtoolcache}/CodeQL", release)
        self.assertNotIn("cache: gradle", release)


if __name__ == "__main__":
    unittest.main()
