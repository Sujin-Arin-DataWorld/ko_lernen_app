"""Executable contracts for offline release-tool verification (no downloads)."""

import copy
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("release_integrity.py")
MODULE_SPEC = importlib.util.spec_from_file_location("release_integrity_under_test", SCRIPT)
integrity = importlib.util.module_from_spec(MODULE_SPEC)
MODULE_SPEC.loader.exec_module(integrity)
PIN = "11d5960a326750d5838078e36cf38b85af677262"
ABC_SHA256 = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"


class FileBoundaryMutation:
    """Keep real bytes and file descriptors; change only at a read boundary."""

    def __init__(self, path, mutate, *, after_close=False):
        self.path = path
        self.mutate = mutate
        self.after_close = after_close
        self.mutated = False

    def lstat(self):
        return self.path.lstat()

    def open(self, mode):
        self.stream = self.path.open(mode)
        return self

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.stream.close()
        if self.after_close:
            self.mutate()

    def fileno(self):
        return self.stream.fileno()

    def read(self, size):
        data = self.stream.read(size)
        if not data and not self.after_close and not self.mutated:
            self.mutated = True
            self.mutate()
        return data


class ReleaseIntegrityTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.manifest = self.root / "toolchain.json"
        self.spec = {
            "schemaVersion": 1,
            "actions": {
                "actions/checkout": {"version": "v4", "sha": PIN},
            },
            "binaries": {
                "ffmpeg-linux-x64": {
                    "url": "https://github.com/eugeneware/ffmpeg-static/releases/download/b6.1.1/ffmpeg-linux-x64",
                    "sha256": ABC_SHA256,
                },
            },
        }
        self.write_manifest()

    def write_manifest(self):
        self.manifest.write_text(json.dumps(self.spec), encoding="utf-8")

    def run_check(self, *args):
        return subprocess.run(
            [sys.executable, str(SCRIPT), "--manifest", str(self.manifest), *args],
            capture_output=True,
            text=True,
            timeout=15,
            check=False,
        )

    def binary(self, contents=b"abc"):
        artifact = self.root / "ffmpeg"
        artifact.write_bytes(contents)
        return artifact

    def workflow(self, reference=None, comment="v4", extra=""):
        workflow = self.root / "workflow.yml"
        reference = reference or f"actions/checkout@{PIN}"
        workflow.write_text(
            "name: verify\non: [push]\njobs:\n  verify:\n    runs-on: ubuntu-latest\n"
            f"    steps:\n      - uses: {reference} # {comment}\n{extra}",
            encoding="utf-8",
        )
        return workflow

    def assert_failure(self, result, code):
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr.strip(), f"error[{code}]")

    def test_accepts_only_verified_binary_bytes(self):
        result = self.run_check("binary", "ffmpeg-linux-x64", str(self.binary()))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["sha256"], ABC_SHA256)

    def test_accepts_stable_bytes_with_preserved_download_modification_time(self):
        artifact = self.binary()
        os.utime(artifact, (1_700_000_000, 1_700_000_000))
        result = self.run_check("binary", "ffmpeg-linux-x64", str(artifact))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["sha256"], ABC_SHA256)

    def test_rejects_tampered_binary(self):
        self.assert_failure(
            self.run_check("binary", "ffmpeg-linux-x64", str(self.binary(b"abd"))),
            "checksum_mismatch",
        )

    def test_rejects_same_size_content_change_at_end_of_read(self):
        artifact = self.binary()
        boundary = FileBoundaryMutation(artifact, lambda: artifact.write_bytes(b"abd"))
        failure = None
        try:
            integrity.verify_binary(self.spec, "ffmpeg-linux-x64", boundary)
        except integrity.IntegrityError as error:
            failure = error
        self.assertEqual(artifact.read_bytes(), b"abd")
        self.assertIsNotNone(failure, "verifier blessed bytes that changed before its verdict")
        self.assertEqual(str(failure), "binary_changed")

    def test_rejects_path_replaced_between_read_and_verdict(self):
        artifact = self.binary()
        replacement = self.root / "replacement"
        replacement.write_bytes(b"abd")
        boundary = FileBoundaryMutation(artifact, lambda: os.replace(replacement, artifact),
                                        after_close=True)
        failure = None
        try:
            integrity.verify_binary(self.spec, "ffmpeg-linux-x64", boundary)
        except integrity.IntegrityError as error:
            failure = error
        self.assertEqual(artifact.read_bytes(), b"abd")
        self.assertIsNotNone(failure, "replaced path retained an obsolete success verdict")
        self.assertEqual(str(failure), "binary_changed")

    def test_rejects_path_removed_between_read_and_verdict(self):
        artifact = self.binary()
        boundary = FileBoundaryMutation(artifact, artifact.unlink, after_close=True)
        failure = None
        try:
            integrity.verify_binary(self.spec, "ffmpeg-linux-x64", boundary)
        except integrity.IntegrityError as error:
            failure = error
        self.assertFalse(artifact.exists())
        self.assertIsNotNone(failure, "removed path retained an obsolete success verdict")
        self.assertEqual(str(failure), "binary_unavailable")

    def test_rejects_empty_binary(self):
        self.assert_failure(
            self.run_check("binary", "ffmpeg-linux-x64", str(self.binary(b""))),
            "empty_binary",
        )

    def test_missing_binary_does_not_look_like_download_success(self):
        self.assert_failure(
            self.run_check("binary", "ffmpeg-linux-x64", str(self.root / "missing")),
            "binary_unavailable",
        )

    def test_rejects_directory_instead_of_binary(self):
        self.assert_failure(
            self.run_check("binary", "ffmpeg-linux-x64", str(self.root)),
            "binary_unavailable",
        )

    def test_unknown_binary_cannot_use_an_unreviewed_checksum(self):
        self.assert_failure(
            self.run_check("binary", "unknown", str(self.binary())), "unknown_binary"
        )

    def test_bad_checksums_and_missing_digests_are_rejected(self):
        artifact = self.binary()
        for digest in (None, "", "sha256:" + ABC_SHA256, "g" * 64, "0" * 63):
            with self.subTest(digest=digest):
                self.spec["binaries"]["ffmpeg-linux-x64"]["sha256"] = digest
                self.write_manifest()
                self.assert_failure(
                    self.run_check("binary", "ffmpeg-linux-x64", str(artifact)),
                    "invalid_manifest",
                )

    def test_manifest_rejects_unknown_schema_and_duplicate_keys(self):
        self.spec["schemaVersion"] = True
        self.write_manifest()
        self.assert_failure(self.run_check("manifest"), "invalid_manifest")
        self.manifest.write_text('{"schemaVersion":1,"schemaVersion":2}', encoding="utf-8")
        self.assert_failure(self.run_check("manifest"), "invalid_manifest")

    def test_manifest_rejects_noncanonical_download_origins(self):
        original = copy.deepcopy(self.spec)
        for url in (
            "http://github.com/eugeneware/ffmpeg-static/releases/download/b6.1.1/ffmpeg-linux-x64",
            "https://github.com.attacker.test/eugeneware/ffmpeg-static/releases/download/b6.1.1/ffmpeg-linux-x64",
            "https://github.com/eugeneware/ffmpeg-static/releases/download/latest/ffmpeg-linux-x64",
        ):
            with self.subTest(url=url):
                self.spec = copy.deepcopy(original)
                self.spec["binaries"]["ffmpeg-linux-x64"]["url"] = url
                self.write_manifest()
                self.assert_failure(self.run_check("manifest"), "invalid_manifest")

    def test_accepts_full_sha_with_reviewed_version_comment(self):
        result = self.run_check("actions", str(self.workflow()))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["actionsChecked"], 1)

    def test_mutable_action_tag_is_rejected(self):
        self.assert_failure(
            self.run_check("actions", str(self.workflow("actions/checkout@v4"))),
            "mutable_action",
        )

    def test_wrong_repository_or_sha_is_rejected(self):
        for reference in (f"evil/checkout@{PIN}", "actions/checkout@" + "a" * 40):
            with self.subTest(reference=reference):
                self.assert_failure(
                    self.run_check("actions", str(self.workflow(reference))),
                    "unreviewed_action",
                )

    def test_version_comment_is_required_and_exact(self):
        for comment in ("", "v5", "v4.0.0"):
            with self.subTest(comment=comment):
                self.assert_failure(
                    self.run_check("actions", str(self.workflow(comment=comment))),
                    "version_comment_mismatch",
                )

    def test_quoted_action_reference_is_still_checked(self):
        result = self.run_check("actions", str(self.workflow(f'"actions/checkout@{PIN}"')))
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_flow_style_action_cannot_bypass_checker(self):
        path = self.workflow()
        path.write_text("jobs: {test: {steps: [{uses: 'actions/checkout@v4'}]}}", encoding="utf-8")
        self.assert_failure(self.run_check("actions", str(path)), "mutable_action")

    def test_yaml_aliases_and_duplicate_keys_fail_closed(self):
        for source in (
            "x: &a actions/checkout@v4\njobs: {test: {steps: [{uses: *a}]}}",
            f"jobs: {{test: {{steps: [{{uses: 'actions/checkout@v4', uses: 'actions/checkout@{PIN}'}}]}}}}",
        ):
            with self.subTest(source=source):
                path = self.workflow()
                path.write_text(source, encoding="utf-8")
                self.assert_failure(self.run_check("actions", str(path)), "invalid_workflow")

    def test_empty_or_invalid_workflow_cannot_pass(self):
        for source in ("", "not: [valid", "jobs: {}"):
            with self.subTest(source=source):
                path = self.workflow()
                path.write_text(source, encoding="utf-8")
                self.assert_failure(self.run_check("actions", str(path)), "invalid_workflow")

    def test_multiline_action_does_not_escape_with_an_unsanitized_exception(self):
        path = self.workflow()
        path.write_text(
            "jobs:\n  test:\n    steps:\n      - uses: >-\n          actions/checkout@" + PIN + "\n",
            encoding="utf-8",
        )
        self.assert_failure(self.run_check("actions", str(path)), "invalid_workflow")

    def test_deep_yaml_fails_with_fixed_diagnostic_without_traceback(self):
        path = self.workflow()
        original = path.read_text(encoding="utf-8")
        path.write_text("untrusted: " + "[" * 600 + "0" + "]" * 600 + "\n" + original,
                        encoding="utf-8")
        self.assert_failure(self.run_check("actions", str(path)), "invalid_workflow")

    def test_oversized_yaml_is_rejected_before_parsing(self):
        path = self.workflow()
        original = path.read_text(encoding="utf-8")
        path.write_text("#" + "x" * (1024 * 1024) + "\n" + original, encoding="utf-8")
        self.assert_failure(self.run_check("actions", str(path)), "invalid_workflow")

    def test_malformed_custom_yaml_does_not_echo_input_or_exception(self):
        path = self.workflow()
        path.write_text("jobs: !<sensitive@example.test token=synthetic-secret> {broken",
                        encoding="utf-8")
        self.assert_failure(self.run_check("actions", str(path)), "invalid_workflow")

    def test_every_action_and_every_workflow_is_checked(self):
        first = self.workflow()
        second = self.root / "second.yml"
        second.write_text("jobs: {test: {uses: 'actions/checkout@v4'}}", encoding="utf-8")
        self.assert_failure(self.run_check("actions", str(first), str(second)), "mutable_action")

    def test_diagnostic_does_not_echo_untrusted_manifest_data(self):
        self.manifest.write_text('sensitive@example.test token=synthetic-secret', encoding="utf-8")
        result = self.run_check("manifest")
        self.assert_failure(result, "invalid_manifest")
        self.assertNotIn("synthetic-secret", result.stdout + result.stderr)

    def test_repository_workflows_are_fully_pinned(self):
        # Guards against a new unpinned `uses:` ever slipping into a real
        # workflow: run the real verifier against the real manifest and the
        # real workflow files, and require every `uses:` line to be checked
        # (an added-but-unpinned action would fail closed via mutable_action
        # before this count comparison, and a missed action would make the
        # checked count fall short of the line count). Requires PyYAML; if it
        # is unavailable this test fails rather than skipping, so a CI runner
        # that forgot to install PyYAML still fails the workflow-pin gate.
        repo_root = Path(__file__).resolve().parent.parent
        manifest = integrity.load_manifest(integrity.MANIFEST)
        uses_line = re.compile(r"^\s*(?:-\s*)?uses:\s")
        for name in ("ci.yml", "play_closed.yml", "playwright.yml"):
            with self.subTest(workflow=name):
                path = repo_root / ".github" / "workflows" / name
                expected = sum(
                    1
                    for line in path.read_text(encoding="utf-8").splitlines()
                    if uses_line.match(line)
                )
                self.assertGreater(expected, 0, f"no uses: lines found in {name}")
                checked = integrity.verify_workflow(manifest, path)
                self.assertEqual(checked, expected)


if __name__ == "__main__":
    unittest.main()
