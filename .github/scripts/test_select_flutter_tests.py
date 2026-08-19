import pathlib
import tempfile
import unittest

import select_flutter_tests as selector


def _write(root: pathlib.Path, rel: str, text: str) -> None:
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


class ClassifyPathsTest(unittest.TestCase):
    def test_dart_only_changes_are_scoped(self):
        self.assertEqual(
            selector.classify_paths(["lib/screens/foo_screen.dart", "test/foo_test.dart"]),
            "scoped",
        )

    def test_content_l10n_pubspec_goldens_and_platform_force_full(self):
        for path in (
            "assets/data/cloze.json",
            "lib/l10n/app_de.arb",
            "lib/l10n/generated/app_localizations.dart",
            "pubspec.yaml",
            "pubspec.lock",
            "analysis_options.yaml",
            "test/goldens/baselines/x.png",
            "android/app/build.gradle",
            "web/index.html",
        ):
            with self.subTest(path=path):
                self.assertEqual(selector.classify_paths([path]), "full")

    def test_docs_and_ci_only_changes_are_scoped_to_guards(self):
        self.assertEqual(
            selector.classify_paths([".github/workflows/ci.yml", "docs/SESSION_LOG.md"]),
            "scoped",
        )


class ImportResolutionTest(unittest.TestCase):
    def test_package_relative_and_foreign_imports(self):
        importer = "test/screens/foo_test.dart"
        self.assertEqual(
            selector.resolve_import(importer, "package:ko_lernen_app/screens/foo.dart"),
            "lib/screens/foo.dart",
        )
        self.assertEqual(
            selector.resolve_import(importer, "../helpers/pump.dart"),
            "test/helpers/pump.dart",
        )
        self.assertIsNone(selector.resolve_import(importer, "package:flutter/material.dart"))
        self.assertIsNone(selector.resolve_import(importer, "dart:io"))
        self.assertIsNone(selector.resolve_import(importer, "../../pubspec.yaml"))

    def test_import_specs_cover_import_export_part_and_conditional(self):
        text = (
            "import 'package:ko_lernen_app/a.dart';\n"
            "export \"b.dart\" show B;\n"
            "part 'c.dart';\n"
            "import 'd_stub.dart' if (dart.library.io) 'd_io.dart';\n"
            "const x = 'not_an_import.dart';\n"
        )
        self.assertEqual(
            selector.dart_import_specs(text),
            ["package:ko_lernen_app/a.dart", "b.dart", "c.dart", "d_stub.dart", "d_io.dart"],
        )


class SelectTestsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.tmp.name)
        _write(self.root, "lib/services/tts.dart", "class Tts {}\n")
        _write(self.root, "lib/services/quiz.dart", "import 'tts.dart';\nclass Quiz {}\n")
        _write(self.root, "lib/screens/quiz_screen.dart", "import 'package:ko_lernen_app/services/quiz.dart';\n")
        _write(self.root, "lib/screens/other_screen.dart", "class Other {}\n")
        _write(self.root, "test/helpers/pump.dart", "import 'package:ko_lernen_app/screens/quiz_screen.dart';\n")
        _write(self.root, "test/quiz_screen_test.dart", "import 'helpers/pump.dart';\n")
        _write(self.root, "test/tts_test.dart", "import 'package:ko_lernen_app/services/tts.dart';\n")
        _write(self.root, "test/other_test.dart", "import 'package:ko_lernen_app/screens/other_screen.dart';\n")
        _write(self.root, "test/typography_guard_test.dart", "void main() {}\n")
        self.graph = selector.build_import_graph(self.root)

    def tearDown(self):
        self.tmp.cleanup()

    def test_transitive_lib_change_selects_only_dependent_tests_plus_guards(self):
        selected = selector.select_tests(
            ["lib/services/tts.dart"], self.graph, always_on=("test/typography_guard_test.dart",)
        )
        self.assertEqual(
            selected,
            ["test/quiz_screen_test.dart", "test/tts_test.dart", "test/typography_guard_test.dart"],
        )

    def test_changed_test_helper_selects_the_tests_that_import_it(self):
        selected = selector.select_tests(["test/helpers/pump.dart"], self.graph, always_on=())
        self.assertEqual(selected, ["test/quiz_screen_test.dart"])

    def test_changed_test_file_selects_itself(self):
        selected = selector.select_tests(["test/other_test.dart"], self.graph, always_on=())
        self.assertEqual(selected, ["test/other_test.dart"])

    def test_no_dart_change_still_runs_guards(self):
        selected = selector.select_tests(
            ["docs/SESSION_LOG.md"], self.graph, always_on=("test/typography_guard_test.dart",)
        )
        self.assertEqual(selected, ["test/typography_guard_test.dart"])

    def test_missing_guard_is_skipped_rather_than_failing(self):
        selected = selector.select_tests([], self.graph, always_on=("test/does_not_exist_test.dart",))
        self.assertEqual(selected, [])


class DecideTest(unittest.TestCase):
    def test_non_pull_request_events_keep_the_full_suite(self):
        for env in (
            {"CI_EVENT_NAME": "push"},
            {"CI_EVENT_NAME": "workflow_dispatch"},
            {"CI_EVENT_NAME": "pull_request", "CI_MANUAL_TASK": "full"},
        ):
            with self.subTest(env=env):
                mode, tests, _ = selector.decide(env, pathlib.Path("."))
                self.assertEqual((mode, tests), ("full", []))

    def test_always_on_guards_exist_in_this_repository(self):
        repo = pathlib.Path(__file__).resolve().parents[2]
        for guard in selector.ALWAYS_ON_TESTS:
            with self.subTest(guard=guard):
                self.assertTrue((repo / guard).is_file(), guard)


class WorkflowWiringTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = pathlib.Path(".github/workflows/ci.yml").read_text(encoding="utf-8")

    def test_changes_job_publishes_the_selection(self):
        # Job keys sit at two-space indent on their own line; the outputs block
        # also contains "      website:", so split on the job-key form only.
        changes = self.workflow.split("\n  changes:\n", 1)[1].split("\n  website:\n", 1)[0]
        self.assertIn("select_flutter_tests.py", changes)
        self.assertIn("flutter_test_mode: ${{ steps.flutter_tests.outputs.flutter_test_mode }}", changes)
        self.assertIn("flutter_tests: ${{ steps.flutter_tests.outputs.flutter_tests }}", changes)

    def test_changes_job_does_not_clone_every_branch(self):
        # PR 95: fetch-depth 0 made checkout pull every branch and tag
        # for 5 minutes and cancelled the required Select check.
        changes = self.workflow.split("\n  changes:\n", 1)[1].split("\n  website:\n", 1)[0]
        active = "\n".join(
            line
            for line in changes.splitlines()
            if not line.lstrip().startswith("#")
        )
        self.assertNotIn("fetch-depth: 0", active)
        self.assertIn("fetch-depth: 1", active)
        self.assertIn("timeout-minutes: 15", active)
        self.assertIn("Fetch comparison history", active)
        self.assertIn("filter=blob:none", active)
        self.assertIn("+refs/heads/${CI_DEFAULT_BRANCH}", active)
        self.assertNotIn("+refs/heads/*", active)
        self.assertNotIn("+refs/tags/*", active)

    def test_build_job_skips_drafts_scopes_pr_tests_and_keeps_main_full(self):
        build = self.workflow.split("\n  build:\n", 1)[1].split("\n  release-internal:\n", 1)[0]
        self.assertIn("github.event.pull_request.draft == false", build)
        self.assertIn('if [[ "$FLUTTER_TEST_MODE" == "scoped" && -n "$FLUTTER_TESTS" ]]; then', build)
        self.assertIn("flutter test $FLUTTER_TESTS", build)
        self.assertIn("            flutter test\n", build)
        self.assertIn("if: github.event_name != 'pull_request'\n        run: flutter build web --release", build)

    def test_build_job_does_not_apt_install_ffmpeg(self):
        # apt-get update hit Azure mirrors and exited 124 at 180s.
        build = self.workflow.split("\n  build:\n", 1)[1].split("\n  release-internal:\n", 1)[0]
        active = "\n".join(
            line
            for line in build.splitlines()
            if not line.lstrip().startswith("#")
        )
        self.assertNotIn("apt-get update", active)
        self.assertNotIn("apt-get install", active)
        self.assertIn("eugeneware/ffmpeg-static", active)
        self.assertIn("${name}-linux-x64", active)
        self.assertIn("install_static ffmpeg", active)
        self.assertIn("install_static ffprobe", active)


if __name__ == "__main__":
    unittest.main()
