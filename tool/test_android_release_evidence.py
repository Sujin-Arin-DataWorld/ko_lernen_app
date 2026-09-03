"""Release-evidence boundary tests; external tools are local, pinned fakes.

These fixtures are not signed production AABs. The fake bundletool reads a
manifest from the actual fixture ZIP; all file/ELF/hash/receipt logic is real.
"""

from __future__ import annotations

import contextlib
import dataclasses
import hashlib
import importlib.util
import io
import json
import os
import struct
import subprocess
import sys
import tempfile
import time
import unittest
import unittest.mock
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
if importlib.util.find_spec("android_release_evidence"):
    import android_release_evidence as evidence
else:
    evidence = None


APP_ID = "1:567383003300:android:17104a2ced0c9b9b"
PACKAGE = "com.example.release"
GIT_SHA = "0123456789abcdef0123456789abcdef01234567"
ANDROID_NS = "http://schemas.android.com/apk/res/android"
ARCHES = {
    "android-arm": ("armeabi-v7a", 40, 1),
    "android-arm64": ("arm64-v8a", 183, 2),
    "android-x64": ("x86_64", 62, 2),
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def elf_fixture(machine=183, elf_class=2, build_id=b"A" * 16, debug=True):
    """Small little-endian ELF with real section headers and GNU build ID."""
    names = b"\0.shstrtab\0.note.gnu.build-id\0.debug_info\0.debug_line\0.debug_abbrev\0"
    note = struct.pack("<III", 4, len(build_id), 3) + b"GNU\0" + build_id
    contents = [(".shstrtab", 3, names), (".note.gnu.build-id", 7, note)]
    if debug:
        contents += [(name, 1, b"DWARF-fixture") for name in (
            ".debug_info", ".debug_line", ".debug_abbrev")]
    header_size, section_size = (64, 64) if elf_class == 2 else (52, 40)
    body = bytearray(header_size)
    sections = [bytes(section_size)]
    for name, kind, content in contents:
        offset = len(body)
        body += content
        fields = (names.index(name.encode()), kind, 0, 0, offset,
                  len(content), 0, 0, 1, 0)
        sections.append(struct.pack("<IIQQQQIIQQ" if elf_class == 2 else
                                    "<IIIIIIIIII", *fields))
    section_offset = len(body)
    body += b"".join(sections)
    ident = b"\x7fELF" + bytes((elf_class, 1, 1)) + bytes(9)
    header_fields = (3, machine, 1, 0, 0, section_offset, 0, header_size,
                     0, 0, section_size, len(sections), 1)
    body[:header_size] = ident + struct.pack(
        "<HHIQQQIHHHHHH" if elf_class == 2 else "<HHIIIIIHHHHHH",
        *header_fields,
    )
    return bytes(body)


FAKE_TOOL = r'''
import json, os, pathlib, subprocess, sys, time, zipfile
kind, *args = sys.argv[1:]
log = pathlib.Path(os.environ["EVIDENCE_FAKE_LOG"])
with log.open("a", encoding="utf-8") as output:
    output.write(json.dumps({"kind": kind, "args": args}) + "\n")
mode = os.environ.get("EVIDENCE_FAKE_MODE", "success")
if kind == "bundletool":
    bundle = next(a.split("=", 1)[1] for a in args if a.startswith("--bundle="))
    with zipfile.ZipFile(bundle) as source:
        sys.stdout.write(source.read("base/manifest/AndroidManifest.xml").decode())
elif args == ["--version"]:
    print(os.environ.get("EVIDENCE_FAKE_VERSION", "15.2.0"))
else:
    if mode == "timeout": time.sleep(5)
    if mode == "child-timeout":
        subprocess.Popen([sys.executable, "-c", "import pathlib,time;time.sleep(2);"
            "pathlib.Path(" + repr(os.environ["EVIDENCE_FAKE_CHILD_MARKER"]) + ").write_text('escaped')"])
        time.sleep(5)
    if mode == "mutate":
        path = pathlib.Path(os.environ["EVIDENCE_FAKE_MUTATE"])
        path.write_bytes(path.read_bytes() + b"mutation")
    print("PRIVATE-RAW-OUTPUT user@example.invalid token=not-for-receipts")
    print("PRIVATE-STDERR", file=sys.stderr)
    sys.exit(7 if mode == "failure" else 0)
'''


class AndroidReleaseEvidenceTest(unittest.TestCase):
    def setUp(self):
        self.assertIsNotNone(evidence, "Android release-evidence implementation is missing")
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.aab = self.root / "app-release.aab"
        self.symbols = self.root / "split-debug-info"
        self.symbols.mkdir()
        self.config = self.root / "google-services.json"
        self.config.write_text(json.dumps({"client": [{"client_info": {
            "mobilesdk_app_id": APP_ID,
            "android_client_info": {"package_name": PACKAGE},
        }}]}), encoding="utf-8")
        self.adc = self.root / "explicit-adc.json"
        self.adc.write_text("DO NOT PARSE CREDENTIAL CONTENTS", encoding="utf-8")
        self.tool = self.root / "fake_external_tool.py"
        self.tool.write_text(FAKE_TOOL, encoding="utf-8")
        self.log = self.root / "calls.jsonl"
        self.env = {**os.environ, "GOOGLE_APPLICATION_CREDENTIALS": str(self.adc),
                    "EVIDENCE_FAKE_LOG": str(self.log)}
        self.env.pop("FIREBASE_TOKEN", None)
        pins = {str(Path(sys.executable).resolve()): sha256(Path(sys.executable)),
                str(self.tool): sha256(self.tool)}
        self.bundletool = evidence.ToolCommand(
            (str(Path(sys.executable).resolve()), str(self.tool), "bundletool"), pins)
        self.firebase = evidence.ToolCommand(
            (str(Path(sys.executable).resolve()), str(self.tool), "firebase"), pins)
        self.write_bundle()
        self.request = evidence.BuildRequest(
            aab=self.aab, symbols=self.symbols, google_services=self.config,
            git_sha=GIT_SHA, run_id=33723918324, run_attempt=1,
            version_code=977, firebase_app_id=APP_ID,
            expected_aab_sha256=sha256(self.aab),
        )
        self.receipt = self.root / "upload-receipt.json"

    def write_bundle(self, *, version=977, package=PACKAGE, arches=None):
        arches = arches or list(ARCHES)
        with zipfile.ZipFile(self.aab, "w") as bundle:
            bundle.writestr("BundleConfig.pb", b"bundle-fixture")
            bundle.writestr("base/manifest/AndroidManifest.xml",
                            f'<manifest xmlns:android="{ANDROID_NS}" '
                            f'package="{package}" android:versionCode="{version}"/>')
            for index, arch in enumerate(arches):
                abi, machine, elf_class = ARCHES[arch]
                build_id = bytes([index + 1]) * 16
                bundle.writestr(f"base/lib/{abi}/libapp.so", elf_fixture(
                    machine, elf_class, build_id, debug=False))
                (self.symbols / f"app.{arch}.symbols").write_bytes(
                    elf_fixture(machine, elf_class, build_id))

    def upload(self, request=None, **kwargs):
        return evidence.upload_symbols(
            request or self.request, self.receipt,
            bundletool=self.bundletool, firebase=self.firebase,
            environment=self.env, timeout_seconds=2, **kwargs,
        )

    def gate(self, request=None):
        return evidence.verify_success_receipt(
            request or self.request, self.receipt,
            bundletool=self.bundletool, environment=self.env,
        )

    def calls(self):
        if not self.log.exists():
            return []
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def uploads(self):
        return [call for call in self.calls() if
                "crashlytics:symbols:upload" in call["args"]]

    def assert_rejected_without_upload(self, request=None):
        with self.assertRaises(evidence.EvidenceError):
            self.upload(request)
        self.assertEqual(self.uploads(), [])
        self.assertFalse(self.gate(request))

    def test_exact_build_upload_and_independent_gate(self):
        # Catches using package/iOS ID, a different symbol folder, or no receipt.
        result = self.upload()
        self.assertEqual(result["gitSha"], GIT_SHA)
        self.assertEqual(result["aabSha256"], sha256(self.aab))
        self.assertEqual(result["runId"], 33723918324)
        self.assertEqual(result["versionCode"], 977)
        self.assertEqual(result["firebaseAppId"], APP_ID)
        self.assertEqual(result["uploadResult"], {"status": "success", "cliVersion": "15.2.0"})
        self.assertEqual(set(result["symbols"]), set(ARCHES))
        for arch in ARCHES:
            self.assertEqual(result["symbols"][arch]["sha256"],
                             sha256(self.symbols / f"app.{arch}.symbols"))
        self.assertEqual(self.uploads()[0]["args"], [
            "crashlytics:symbols:upload", "--app", APP_ID,
            str(self.symbols.resolve()), "--non-interactive"])
        self.assertTrue(self.gate())

    def test_success_retry_reuses_identical_receipt_without_upload(self):
        first = self.upload()
        self.assertEqual(self.upload(), first)
        self.assertEqual(len(self.uploads()), 1)

    def test_no_receipt_does_not_open_play_gate(self):
        self.assertFalse(self.gate())

    def test_strict_build_identity_rejects_ambiguous_fields_before_upload(self):
        bad_values = {
            "git_sha": ["main", "a" * 39, "z" * 40, "a" * 40 + "\n", "A" * 40, None],
            "run_id": [0, -1, True, "123", 1.5, 2**63],
            "run_attempt": [0, -1, True, "1", 1.5],
            "version_code": [0, -1, True, "977", 2_100_000_001, 977.0],
            "firebase_app_id": [PACKAGE, APP_ID.replace(":android:", ":ios:"), "", APP_ID + "\n"],
            "expected_aab_sha256": ["", "f" * 63, "f" * 64 + "\n", "G" * 64],
        }
        for field, values in bad_values.items():
            for value in values:
                with self.subTest(field=field, value=value):
                    self.assert_rejected_without_upload(dataclasses.replace(
                        self.request, **{field: value}))

    def test_wrong_expected_aab_hash_is_rejected_before_upload(self):
        self.assert_rejected_without_upload(dataclasses.replace(
            self.request, expected_aab_sha256="f" * 64))

    def test_actual_aab_version_must_match_not_just_caller_metadata(self):
        self.assert_rejected_without_upload(dataclasses.replace(self.request, version_code=978))

    def test_actual_aab_package_selects_firebase_config_identity(self):
        self.write_bundle(package="com.different.application")
        self.assert_rejected_without_upload(dataclasses.replace(
            self.request, expected_aab_sha256=sha256(self.aab)))

    def test_firebase_app_id_must_match_google_services(self):
        self.assert_rejected_without_upload(dataclasses.replace(
            self.request, firebase_app_id="1:567383003300:android:0000000000000000"))

    def test_missing_aab_never_uploads(self):
        self.aab.unlink()
        self.assert_rejected_without_upload()

    def test_non_zip_aab_never_uploads(self):
        self.aab.write_bytes(b"not a real bundle")
        self.assert_rejected_without_upload(dataclasses.replace(
            self.request, expected_aab_sha256=sha256(self.aab)))

    def test_missing_architecture_symbol_never_uploads(self):
        (self.symbols / "app.android-arm.symbols").unlink()
        self.assert_rejected_without_upload()

    def test_empty_symbol_never_uploads(self):
        (self.symbols / "app.android-arm64.symbols").write_bytes(b"")
        self.assert_rejected_without_upload()

    def test_corrupt_symbol_never_uploads(self):
        (self.symbols / "app.android-arm64.symbols").write_bytes(b"not ELF")
        self.assert_rejected_without_upload()

    def test_unknown_architecture_or_extra_file_never_uploads(self):
        (self.symbols / "app.android-riscv64.symbols").write_bytes(elf_fixture())
        self.assert_rejected_without_upload()

    def test_nested_symbol_directories_are_not_silently_ignored(self):
        (self.symbols / "stale").mkdir()
        self.assert_rejected_without_upload()

    def test_lying_zip_size_metadata_cannot_bypass_the_read_cap(self):
        # base/lib/armeabi-v7a/libapp.so's central-directory file_size is
        # attacker-crafted metadata a hostile AAB can misstate; monkeypatch
        # ZipInfo.file_size to lie that it is tiny, bypassing the cheap
        # metadata pre-filter. A bounded-read probe stands in for the real
        # decompressed member: it refuses any call that is not an explicit,
        # capped read (raising AssertionError on a bare/unbounded .read(),
        # which is what "bundle.read(name)" -- the pre-fix call -- would
        # issue) and, when asked for the allowed maximum + 1 bytes, returns
        # exactly that many, simulating a real member whose true decompressed
        # length is unbounded/huge despite the lied-small metadata. This
        # isolates the code's own contract (mirrors _read_bytes: bound the
        # actual bytes read, never trust declared size) from zipfile's own
        # CRC/truncation behavior, which independently -- and separately --
        # already rejects a truthfully mismatched declared size.
        target = "base/lib/armeabi-v7a/libapp.so"
        maximum = 256 * 1024 * 1024
        real_getinfo = zipfile.ZipFile.getinfo
        real_open = zipfile.ZipFile.open

        def lying_getinfo(zip_self, name):
            info = real_getinfo(zip_self, name)
            if name == target:
                info.file_size = 4096  # lies: claims a tiny member
            return info

        class BoundedReadProbe:
            def read(self_probe, n=None):
                if not isinstance(n, int) or n <= 0 or n > maximum + 1:
                    raise AssertionError(
                        f"expected a bounded read of at most {maximum + 1} "
                        f"bytes, got n={n!r} (an unbounded/bare read call)")
                return b"\x00" * n

            def __enter__(self_probe):
                return self_probe

            def __exit__(self_probe, *exc_info):
                return False

        def fake_open(zip_self, name, *args, **kwargs):
            if name == target:
                return BoundedReadProbe()
            return real_open(zip_self, name, *args, **kwargs)

        with unittest.mock.patch.object(zipfile.ZipFile, "getinfo", lying_getinfo), \
             unittest.mock.patch.object(zipfile.ZipFile, "open", fake_open):
            try:
                self.upload()
            except evidence.EvidenceError as error:
                self.assertEqual(error.code, "symbol_mismatch")
            else:
                self.fail("lying declared size was accepted")
            self.assertEqual(self.uploads(), [])

    def test_wrong_architecture_elf_never_uploads(self):
        (self.symbols / "app.android-arm64.symbols").write_bytes(elf_fixture(62))
        self.assert_rejected_without_upload()

    def test_symbol_without_debug_sections_never_uploads(self):
        (self.symbols / "app.android-arm64.symbols").write_bytes(elf_fixture(debug=False))
        self.assert_rejected_without_upload()

    def test_symbol_from_different_build_never_uploads(self):
        (self.symbols / "app.android-arm64.symbols").write_bytes(elf_fixture(build_id=b"X" * 16))
        self.assert_rejected_without_upload()

    def test_bad_section_bounds_never_upload(self):
        path = self.symbols / "app.android-arm64.symbols"
        corrupt = bytearray(path.read_bytes())
        struct.pack_into("<Q", corrupt, 40, 2**63)
        path.write_bytes(corrupt)
        self.assert_rejected_without_upload()

    def test_explicit_adc_file_presence_required_without_reading_contents(self):
        self.env.pop("GOOGLE_APPLICATION_CREDENTIALS")
        self.assert_rejected_without_upload()
        self.env["GOOGLE_APPLICATION_CREDENTIALS"] = str(self.root / "missing.json")
        self.assert_rejected_without_upload()

    def test_cli_older_than_11_9_is_rejected(self):
        self.env["EVIDENCE_FAKE_VERSION"] = "11.8.9"
        self.assert_rejected_without_upload()

    def test_unpinned_or_modified_tool_never_runs(self):
        self.tool.write_text(FAKE_TOOL + "\n# changed", encoding="utf-8")
        self.assert_rejected_without_upload()
        self.assertEqual(self.calls(), [])

    def test_failed_upload_is_sanitized_and_can_retry_same_files(self):
        self.env["EVIDENCE_FAKE_MODE"] = "failure"
        with self.assertRaises(evidence.EvidenceError) as raised:
            self.upload()
        self.assertNotIn("PRIVATE", str(raised.exception))
        self.assertNotIn("PRIVATE", self.receipt.read_text())
        self.assertNotIn("token", self.receipt.read_text())
        self.assertFalse(self.gate())
        self.env["EVIDENCE_FAKE_MODE"] = "success"
        self.upload()
        self.assertTrue(self.gate())
        self.assertEqual(len(self.uploads()), 2)

    def test_timeout_does_not_record_success(self):
        self.env["EVIDENCE_FAKE_MODE"] = "timeout"
        with self.assertRaises(evidence.EvidenceError):
            evidence.upload_symbols(self.request, self.receipt,
                bundletool=self.bundletool, firebase=self.firebase,
                environment=self.env, timeout_seconds=0.5)
        self.assertFalse(self.gate())

    def test_unavailable_executable_does_not_record_success(self):
        self.firebase = evidence.ToolCommand((str(self.root / "missing.exe"),), {})
        self.assert_rejected_without_upload()

    def test_pinned_but_unlaunchable_executable_fails_closed(self):
        executable = self.root / "not-executable.exe"
        executable.write_bytes(b"not a valid operating-system executable")
        self.firebase = evidence.ToolCommand((str(executable),), {str(executable): sha256(executable)})
        self.assert_rejected_without_upload()

    def test_timeout_stops_upload_children_not_only_parent(self):
        marker = self.root / "escaped-child"
        self.env.update(EVIDENCE_FAKE_MODE="child-timeout", EVIDENCE_FAKE_CHILD_MARKER=str(marker))
        with self.assertRaises(evidence.EvidenceError):
            evidence.upload_symbols(self.request, self.receipt,
                bundletool=self.bundletool, firebase=self.firebase,
                environment=self.env, timeout_seconds=0.5)
        time.sleep(2.2)
        self.assertFalse(marker.exists(), "timed-out upload child kept running")
        self.assertFalse(self.gate())

    def test_aab_mutation_during_upload_never_records_success(self):
        self.env.update(EVIDENCE_FAKE_MODE="mutate", EVIDENCE_FAKE_MUTATE=str(self.aab))
        with self.assertRaises(evidence.EvidenceError):
            self.upload()
        self.assertEqual(json.loads(self.receipt.read_text())["uploadResult"]["status"], "failed")
        self.assertFalse(self.gate())

    def test_symbol_mutation_during_upload_never_records_success(self):
        self.env.update(EVIDENCE_FAKE_MODE="mutate", EVIDENCE_FAKE_MUTATE=str(
            self.symbols / "app.android-arm64.symbols"))
        with self.assertRaises(evidence.EvidenceError):
            self.upload()
        self.assertFalse(self.gate())

    def test_changed_artifacts_cannot_reuse_failed_receipt(self):
        self.env["EVIDENCE_FAKE_MODE"] = "failure"
        with self.assertRaises(evidence.EvidenceError):
            self.upload()
        first = self.receipt.read_bytes()
        with zipfile.ZipFile(self.aab, "a") as bundle:
            bundle.writestr("new-build-marker", b"different")
        replacement = dataclasses.replace(self.request, expected_aab_sha256=sha256(self.aab))
        with self.assertRaises(evidence.EvidenceError):
            self.upload(replacement)
        self.assertEqual(self.receipt.read_bytes(), first)
        self.assertEqual(len(self.uploads()), 1)

    def test_receipt_strict_fields_and_types_cannot_open_gate(self):
        valid = self.upload()
        mutations = [
            {**valid, "schemaVersion": True}, {**valid, "runId": "33723918324"},
            {**valid, "runAttempt": 2}, {**valid, "versionCode": 978},
            {**valid, "gitSha": "f" * 40}, {**valid, "aabSha256": "f" * 64},
            {**valid, "extra": "untrusted"}, {**valid, "symbols": {}},
            {**valid, "uploadResult": {"status": "success"}},
        ]
        for invalid in mutations:
            with self.subTest(keys=list(invalid)):
                self.receipt.write_text(json.dumps(invalid), encoding="utf-8")
                self.assertFalse(self.gate())

    def test_duplicate_receipt_keys_are_not_accepted(self):
        self.upload()
        content = self.receipt.read_text()
        self.receipt.write_text(content.replace('"schemaVersion": 1',
            '"schemaVersion": 2, "schemaVersion": 1'), encoding="utf-8")
        self.assertFalse(self.gate())

    def test_deep_json_parser_returns_sanitized_evidence_error(self):
        payload = '{"nested":' * 20_000 + '0' + '}' * 20_000
        self.receipt.write_text(payload, encoding="utf-8")
        self.assertEqual(self.receipt.stat().st_size, 220_001)
        self.assertLess(self.receipt.stat().st_size, 2 * 1024 * 1024)
        try:
            evidence._read_json(self.receipt)
        except Exception as error:
            self.assertIsInstance(error, evidence.EvidenceError)
            self.assertEqual(error.code, "invalid_json")
        else:
            self.fail("deep JSON was accepted")

    def test_deep_json_receipt_closes_gate_without_raising(self):
        self.receipt.write_text('{"nested":' * 20_000 + '0' + '}' * 20_000,
            encoding="utf-8")
        try:
            accepted = self.gate()
        except Exception as error:
            self.fail(f"receipt gate raised {type(error).__name__}")
        self.assertFalse(accepted)
        self.assertEqual(self.uploads(), [])

    def test_deep_json_cli_returns_only_sanitized_json(self):
        tools_path = self.root / "deep-tools.json"
        tools_path.write_text('{"nested":' * 20_000 + '0' + '}' * 20_000,
            encoding="utf-8")
        arguments = [str(Path(evidence.__file__)), "upload",
            "--aab", str(self.aab), "--symbols", str(self.symbols),
            "--google-services", str(self.config), "--receipt", str(self.receipt),
            "--tools-json", str(tools_path), "--git-sha", GIT_SHA,
            "--firebase-app-id", APP_ID, "--expected-aab-sha256", sha256(self.aab),
            "--run-id", "33723918324", "--run-attempt", "1", "--version-code", "977"]
        completed = subprocess.run([sys.executable, *arguments], env=self.env,
            capture_output=True, text=True, check=False, timeout=10)
        self.assertEqual(completed.returncode, 1)
        self.assertEqual(completed.stdout, "")
        self.assertEqual(completed.stderr,
            json.dumps({"ok": False, "reason": "invalid_json"}) + "\n")
        self.assertEqual(self.calls(), [])
        self.assertFalse(self.receipt.exists())

    def test_artifact_change_after_success_closes_gate(self):
        self.upload()
        (self.symbols / "app.android-arm64.symbols").write_bytes(b"corrupt after upload")
        self.assertFalse(self.gate())

    def test_ambient_firebase_token_cannot_override_explicit_adc(self):
        self.env["FIREBASE_TOKEN"] = "must-not-be-used"
        self.assert_rejected_without_upload()

    def test_receipt_inside_symbols_is_rejected_without_changing_artifacts(self):
        self.receipt = self.symbols / "receipt.json"
        self.assert_rejected_without_upload()
        self.assertFalse(self.receipt.exists())

    def test_archived_payload_is_verified_and_different_archive_not_overwritten(self):
        self.upload()
        destination = self.root / "private-archive"
        evidence.archive_release(self.request, self.receipt, destination,
            bundletool=self.bundletool, environment=self.env)
        self.assertEqual(sha256(destination / "app-release.aab"), sha256(self.aab))
        self.assertEqual((destination / "upload-receipt.json").read_bytes(), self.receipt.read_bytes())
        evidence.archive_release(self.request, self.receipt, destination,
            bundletool=self.bundletool, environment=self.env)
        marker = destination / "app-release.aab"
        marker.write_bytes(b"different archive must survive")
        with self.assertRaises(evidence.EvidenceError):
            evidence.archive_release(self.request, self.receipt, destination,
                bundletool=self.bundletool, environment=self.env)
        self.assertEqual(marker.read_bytes(), b"different archive must survive")

    def test_invalid_receipt_cannot_be_archived_as_release_evidence(self):
        destination = self.root / "private-archive"
        with self.assertRaises(evidence.EvidenceError):
            evidence.archive_release(self.request, self.receipt, destination,
                bundletool=self.bundletool, environment=self.env)
        self.assertFalse(destination.exists())

    def test_archive_inside_input_symbols_is_rejected_without_mutating_them(self):
        self.upload()
        destination = self.symbols / "archive"
        with self.assertRaises(evidence.EvidenceError):
            evidence.archive_release(self.request, self.receipt, destination,
                bundletool=self.bundletool, environment=self.env)
        self.assertFalse(destination.exists())
        self.assertTrue(self.gate())

    def test_cli_round_trip_and_strict_numeric_inputs(self):
        tools_path = self.root / "tools.json"
        tools_path.write_text(json.dumps({name: dataclasses.asdict(command) for name, command in
            (("bundletool", self.bundletool), ("firebase", self.firebase))}), encoding="utf-8")
        arguments = [str(Path(evidence.__file__)), "upload",
            "--aab", str(self.aab), "--symbols", str(self.symbols),
            "--google-services", str(self.config), "--receipt", str(self.receipt),
            "--tools-json", str(tools_path), "--git-sha", GIT_SHA,
            "--firebase-app-id", APP_ID, "--expected-aab-sha256", sha256(self.aab),
            "--run-id", "33723918324", "--run-attempt", "1", "--version-code", "977"]
        completed = subprocess.run([sys.executable, *arguments], env=self.env,
            capture_output=True, text=True, check=False, timeout=10)
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(json.loads(completed.stdout), {"ok": True, "operation": "upload"})
        self.assertEqual(completed.stderr, "")
        arguments[1] = "verify"
        completed = subprocess.run([sys.executable, *arguments], env=self.env,
            capture_output=True, text=True, check=False, timeout=10)
        self.assertEqual(completed.returncode, 0, completed.stderr)
        attempt_index = arguments.index("--run-attempt") + 1
        for invalid in ("+1", "01", " 1"):
            arguments[attempt_index] = invalid
            completed = subprocess.run([sys.executable, *arguments], env=self.env,
                capture_output=True, text=True, check=False, timeout=10)
            self.assertNotEqual(completed.returncode, 0)

    def test_tool_output_is_never_forwarded_to_console(self):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            self.upload()
        self.assertEqual(out.getvalue(), "")
        self.assertEqual(err.getvalue(), "")


if __name__ == "__main__":
    unittest.main()
