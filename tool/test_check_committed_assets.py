"""Focused local-Git tests for check_committed_assets.py."""

from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("check_committed_assets.py")
MODULE_SPEC = importlib.util.spec_from_file_location("committed_assets_under_test", SCRIPT)
checker = importlib.util.module_from_spec(MODULE_SPEC)
MODULE_SPEC.loader.exec_module(checker)


class CommittedAssetCheckTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name) / "repo"
        self.repo.mkdir()
        self.git("init")
        self.git("config", "user.email", "test@example.invalid")
        self.git("config", "user.name", "Committed asset test")

    def git(self, *args):
        return subprocess.run(
            ["git", "-C", str(self.repo), *args],
            capture_output=True,
            check=True,
            text=True,
            timeout=15,
        )

    def write(self, relative, contents="x"):
        path = self.repo / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents, encoding="utf-8")

    def commit(self, message):
        self.git("add", ".")
        self.git("commit", "-m", message)
        return self.git("rev-parse", "HEAD").stdout.strip()

    def run_check(self, *args):
        return subprocess.run(
            [sys.executable, str(SCRIPT), "--repo", str(self.repo), *args],
            capture_output=True,
            text=True,
            check=False,
            timeout=15,
        )

    def assert_invalid(self, result, code):
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr.strip(), f"error[{code}]")

    def test_retained_files_with_quoted_unicode_paths_and_comments_pass(self):
        self.write(
            "pubspec.yaml",
            "flutter:\n"
            "  assets:\n"
            "    - \"assets/한글 파일.txt\" # quoted Unicode path\n"
            "    - assets/direct/\n"
            "  fonts:\n"
            "    - family: Test\n"
            "      fonts:\n"
            "        - asset: \"assets/fonts/글꼴.ttf\" # retained\n",
        )
        self.write("assets/한글 파일.txt")
        self.write("assets/direct/file.txt")
        self.write("assets/fonts/글꼴.ttf")
        commit = self.commit("retained")

        result = self.run_check("--ref", commit)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            json.loads(result.stdout),
            {
                "assetDeclarations": 2,
                "commit": commit,
                "declarationPresence": "present",
                "fontFiles": 1,
                "missingPaths": [],
            },
        )

    def test_deleted_declared_files_directories_and_fonts_fail(self):
        self.write(
            "pubspec.yaml",
            "flutter:\n  assets:\n    - assets/file.txt\n    - assets/directory/\n"
            "  fonts:\n    - family: Test\n      fonts:\n        - asset: assets/fonts/test.ttf\n",
        )
        self.write("assets/file.txt")
        self.write("assets/directory/direct.txt")
        self.write("assets/fonts/test.ttf")
        self.commit("files exist")
        (self.repo / "assets/file.txt").unlink()
        (self.repo / "assets/directory/direct.txt").unlink()
        (self.repo / "assets/fonts/test.ttf").unlink()
        commit = self.commit("declared files deleted")

        result = self.run_check("--ref", commit)

        self.assertEqual(result.returncode, 1, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["commit"], commit)
        self.assertEqual(payload["declarationPresence"], "missing")
        self.assertEqual(
            payload["missingPaths"],
            ["assets/directory/", "assets/file.txt", "assets/fonts/test.ttf"],
        )

    def test_nested_only_directory_does_not_satisfy_declaration(self):
        self.write("pubspec.yaml", "flutter:\n  assets:\n    - assets/directory/\n")
        self.write("assets/directory/nested/file.txt")
        self.commit("nested only")

        result = self.run_check()

        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual(json.loads(result.stdout)["missingPaths"], ["assets/directory/"])

    def test_working_tree_only_file_cannot_mask_missing_committed_asset(self):
        self.write("pubspec.yaml", "flutter:\n  assets:\n    - assets/missing.txt\n")
        commit = self.commit("declaration only")
        self.write("assets/missing.txt")

        result = self.run_check("--ref", commit)

        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual(json.loads(result.stdout)["missingPaths"], ["assets/missing.txt"])

    def test_invalid_refs_and_unsupported_forms_fail_without_json_success_output(self):
        self.write("pubspec.yaml", "flutter:\n  assets:\n    - path: assets/file.txt\n")
        self.commit("unsupported assets form")

        self.assert_invalid(self.run_check("--ref", "does-not-exist"), "invalid_ref")
        self.assert_invalid(self.run_check(), "unsupported_declaration")

    def test_duplicate_pubspec_keys_fail_without_hiding_a_missing_asset(self):
        self.write(
            "pubspec.yaml",
            "flutter:\n  assets:\n    - assets/missing.txt\n  assets: []\n",
        )
        self.commit("duplicate assets declaration")

        self.assert_invalid(self.run_check(), "invalid_pubspec")

    def test_partial_clone_does_not_lazy_fetch_missing_pubspec_blob(self):
        self.write("pubspec.yaml", "flutter:\n  assets:\n    - assets/retained.txt\n")
        self.write("assets/retained.txt")
        commit = self.commit("partial-clone fixture")
        self.git("config", "uploadpack.allowFilter", "true")
        partial = Path(self.temp.name) / "partial"
        subprocess.run(
            [
                "git",
                "clone",
                "--filter=blob:none",
                "--no-checkout",
                self.repo.as_uri(),
                str(partial),
            ],
            capture_output=True,
            check=True,
            text=True,
            timeout=15,
        )
        no_fetch_environment = os.environ.copy()
        no_fetch_environment["GIT_NO_LAZY_FETCH"] = "1"
        before = subprocess.run(
            ["git", "-C", str(partial), "cat-file", "-e", f"{commit}:pubspec.yaml"],
            capture_output=True,
            check=False,
            env=no_fetch_environment,
            timeout=15,
        )
        self.assertNotEqual(before.returncode, 0, "fixture unexpectedly has the promised blob")

        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--repo", str(partial), "--ref", commit],
            capture_output=True,
            text=True,
            check=False,
            timeout=15,
        )

        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr.strip(), "error[invalid_pubspec]")
        after = subprocess.run(
            ["git", "-C", str(partial), "cat-file", "-e", f"{commit}:pubspec.yaml"],
            capture_output=True,
            check=False,
            env=no_fetch_environment,
            timeout=15,
        )
        self.assertNotEqual(after.returncode, 0, "checker fetched the promised blob")


if __name__ == "__main__":
    unittest.main()
