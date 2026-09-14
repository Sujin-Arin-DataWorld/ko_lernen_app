"""Verify the Android versionCode lanes used by every Play upload workflow."""

import pathlib
import re
import unittest


GRADLE = pathlib.Path("android/app/build.gradle.kts")
CI = pathlib.Path(".github/workflows/ci.yml")
PUBLIC = pathlib.Path(".github/workflows/play_closed.yml")

BASH_FORMULA = re.compile(
    r'version_code="\$\(\(\s*commit_count\s*\*\s*'
    r"(?P<factor>\d+)\s*\+\s*(?P<offset>[^\s]+)\s*\)\)\""
)


class PlayVersionCodeContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gradle = GRADLE.read_text(encoding="utf-8")
        cls.ci = CI.read_text(encoding="utf-8")
        cls.public = PUBLIC.read_text(encoding="utf-8")

    def test_gradle_assigns_three_fail_closed_track_lanes(self):
        gradle = self.gradle
        self.assertIn('System.getenv("PLAY_TRACK")', gradle)
        self.assertRegex(gradle, r'"",\s*"internal"\s*->\s*0')
        self.assertRegex(gradle, r'"alpha"\s*->\s*1')
        self.assertRegex(gradle, r'"beta"\s*->\s*2')
        self.assertIn("Unsupported PLAY_TRACK", gradle)
        self.assertRegex(gradle, r"commitCount\s*\*\s*3\s*\+\s*playTrackVersionOffset")

    def test_release_git_identity_fails_closed_but_debug_has_a_fallback(self):
        gradle = self.gradle
        self.assertIn("process.exitValue()", gradle)
        self.assertIn("gitCommitCount ?: 21", gradle)
        self.assertIn("releaseTaskScheduled && gitCommitCount == null", gradle)
        self.assertIn("Cannot derive release versionCode from git HEAD", gradle)

    def test_workflows_build_in_their_declared_lanes(self):
        internal = self.ci.split("  release-internal:", 1)[1].split(
            "  release-website:", 1
        )[0]
        self.assertIn("PLAY_TRACK: internal", internal)
        self.assertIn("PLAY_TRACK: ${{ inputs.target_track }}", self.public)

        internal_match = BASH_FORMULA.search(internal)
        public_match = BASH_FORMULA.search(self.public)
        self.assertIsNotNone(internal_match)
        self.assertIsNotNone(public_match)
        self.assertEqual(internal_match.group("factor"), "3")
        self.assertEqual(internal_match.group("offset"), "0")
        self.assertEqual(public_match.group("factor"), "3")
        self.assertEqual(public_match.group("offset"), "track_offset")

    def test_same_and_adjacent_commits_never_share_a_version_code(self):
        lanes = {"internal": 0, "alpha": 1, "beta": 2}
        for commit_count in (1, 21, 761, 10_000):
            current = {track: commit_count * 3 + offset for track, offset in lanes.items()}
            following = {
                track: (commit_count + 1) * 3 + offset
                for track, offset in lanes.items()
            }
            self.assertEqual(len(set(current.values())), 3)
            self.assertEqual(len(set(following.values())), 3)
            self.assertTrue(set(current.values()).isdisjoint(following.values()))
            self.assertLess(max(current.values()), min(following.values()))

    def test_internal_release_remains_explicitly_disabled_by_current_repo_policy(self):
        release = self.ci.split("  release-internal:", 1)[1].split(
            "  release-website:", 1
        )[0]
        self.assertIn("vars.PLAY_INTERNAL_RELEASE_ENABLED == 'true'", release)
        self.assertNotIn("PLAY_INTERNAL_RELEASE_DISABLED", release)

    def test_public_workflow_maps_only_alpha_and_beta_offsets(self):
        public = self.public
        self.assertIn("alpha) track_offset=1", public)
        self.assertIn("beta) track_offset=2", public)
        self.assertIn("Unsupported public testing track", public)
        self.assertNotIn("production) track_offset", public)
        self.assertNotIn("internal) track_offset", public)


if __name__ == "__main__":
    unittest.main()
