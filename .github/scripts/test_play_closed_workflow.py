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
        self.assertIn("target_track:", workflow)
        self.assertIn("default: alpha", workflow)
        self.assertRegex(workflow, r"options:\s+\- alpha\s+\- beta")
        self.assertIn('GITHUB_REF" != "refs/heads/main', workflow)
        self.assertIn("^[0-9a-f]{40}$", workflow)
        self.assertIn('GITHUB_SHA" != "$EXPECTED_SHA', workflow)
        self.assertIn('case "$TARGET_TRACK" in', workflow)
        self.assertIn("alpha|beta)", workflow)
        self.assertIn("Unsupported public testing track", workflow)

    def test_requires_successful_exact_sha_main_ci(self):
        workflow = self.workflow
        self.assertIn("actions: read", workflow)
        self.assertIn("actions/workflows/ci.yml/runs", workflow)
        self.assertIn(".head_sha == $sha", workflow)
        self.assertIn('.head_branch == "main"', workflow)
        self.assertIn('.event == "push"', workflow)
        self.assertIn('.conclusion == "success"', workflow)

    def test_signed_bundle_targets_allowlisted_public_testing_track(self):
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
        self.assertIn(
            "--dart-define=ENABLE_FREE_PRONUNCIATION_ASSESSMENT="
            "${{ vars.ENABLE_FREE_PRONUNCIATION_ASSESSMENT }}",
            workflow,
        )
        self.assertNotIn("BETA_UNLOCK_ALL=true", workflow)
        self.assertIn("ANDROID_UPLOAD_KEYSTORE_BASE64", workflow)
        self.assertIn("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON", workflow)
        self.assertEqual(workflow.count("r0adkll/upload-google-play"), 1)
        self.assertEqual(workflow.count("tracks:"), 1)
        self.assertIn("PLAY_TRACK: ${{ inputs.target_track }}", workflow)
        self.assertIn("tracks: ${{ inputs.target_track }}", workflow)
        for forbidden in (
            "tracks: internal",
            "tracks: open",
            "tracks: production",
        ):
            self.assertNotIn(forbidden, workflow)

    def test_artifacts_and_concurrency_are_retained_safely(self):
        workflow = self.workflow
        self.assertIn("group: google-play-public-testing", workflow)
        self.assertIn("cancel-in-progress: false", workflow)
        self.assertIn("fetch-depth: 0", workflow)
        self.assertIn("sha256sum", workflow)
        self.assertIn("git rev-list --count HEAD", workflow)
        self.assertIn("retention-days: 30", workflow)
        self.assertIn("Preserve Android failure diagnostics", workflow)

    def test_firebase_whole_artifact_is_verified_before_signing_secrets(self):
        workflow = "\n".join(line for line in self.workflow.splitlines()
                             if not line.lstrip().startswith("#"))
        self.assertNotIn("npm install", workflow)
        self.assertNotIn("uses: actions/setup-node@", workflow)
        self.assertNotIn("firebase_js", workflow)
        self.assertIn('"argv": [firebase_bin]', workflow)
        download = workflow.index("- name: Download and verify firebase-tools")
        checksum = workflow.index('echo "${FIREBASE_TOOLS_SHA256}  $firebase_bin" | sha256sum -c -', download)
        executable = workflow.index('chmod 0555 "$firebase_bin"', download)
        manifest = workflow.index("- name: Write release-evidence tools manifest")
        signing = workflow.index("- name: Restore Android upload signing")
        firebase_secret = workflow.index("- name: Materialise Firebase credentials")
        self.assertLess(checksum, executable)
        self.assertLess(executable, manifest)
        self.assertLess(manifest, signing)
        self.assertLess(signing, firebase_secret)
        step = workflow[download:manifest]
        self.assertIn("set -euo pipefail", step)
        self.assertIn("if: vars.ANDROID_SYMBOL_EVIDENCE_GATE == 'true'", step)
        self.assertNotIn("secrets.", step)
        for name in (
            "Read pinned release-toolchain versions",
            "Pin release-toolchain Java",
            "Download and verify bundletool",
            "Download and verify firebase-tools",
            "Write release-evidence tools manifest",
        ):
            start = workflow.index(f"- name: {name}")
            end = workflow.index("      - name:", start)
            with self.subTest(step=name):
                self.assertLess(start, signing)
                self.assertIn("if: vars.ANDROID_SYMBOL_EVIDENCE_GATE == 'true'",
                              workflow[start:end])
        upload = workflow.index("- name: Upload and verify Crashlytics symbol evidence")
        self.assertEqual(workflow.index("      - name:", firebase_secret), upload - 6)


class CiWorkflowAppleConfigTest(unittest.TestCase):
    """ci.yml's release-internal appbundle build must pass the same public
    Apple web-flow dart-defines as play_closed.yml (unset repo vars expand to
    empty strings, so this is a no-op until Jin configures Apple + Firebase),
    plus the repo-variable-gated ENABLE_FREE_PRONUNCIATION_ASSESSMENT define
    (unset repo var -> empty string -> Dart's bool.fromEnvironment defaults
    to false; server-side gates remain authoritative either way).
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
        self.assertIn(
            "--dart-define=ENABLE_FREE_PRONUNCIATION_ASSESSMENT="
            "${{ vars.ENABLE_FREE_PRONUNCIATION_ASSESSMENT }}",
            workflow,
        )


if __name__ == "__main__":
    unittest.main()
