"""Fail-closed Android Crashlytics symbol evidence, without release wiring.

Requires Python 3.11+, an explicitly pinned Java/bundletool command and a
pinned Node/Firebase CLI command (Firebase >= 11.9.0). No downloads, login,
permission changes, Play upload, or credential-content reads occur here.
Each executable/script/JAR in a command must have a SHA-256 supplied through
reviewed provisioning, not a hash calculated and trusted on first use.

Bundletool reads the *actual AAB* manifest; ELF GNU build IDs pair the actual
AAB libapp.so files with the split-debug symbols. The expected AAB SHA-256,
git SHA and run identity must come from a trusted build job. This is a local
integrity receipt, NOT a signed build attestation, proof of Git provenance,
Crashlytics ingestion, or proof that a device crash has been symbolicated.
Unsupported symbol formats/deferred snapshots fail closed, never degrade to
filename-only validation. A later Play job must independently reverify the
same immutable artifacts and receipt immediately before using them.

CLI: upload|verify|archive --tools-json <private reviewed command config> ...
tools JSON: {"bundletool": {"argv": ["/abs/java", "-jar", "/abs/tool.jar"],
"sha256": {"/abs/java": "<64 hex>", "/abs/tool.jar": "<64 hex>"}},
"firebase": {"argv": ["/abs/node", "/abs/firebase.js"], "sha256": {...}}}
Authentication requires an explicit GOOGLE_APPLICATION_CREDENTIALS file.
Firebase CLI performs actual authentication; this helper neither inspects
the principal nor widens its authority. Use an isolated CI account without
cached Firebase login; FIREBASE_TOKEN is rejected to avoid alternate auth.

References:
https://firebase.google.com/docs/crashlytics/flutter/get-started
https://github.com/google/bundletool/blob/master/src/main/java/com/android/tools/build/bundletool/commands/DumpCommand.java
https://github.com/dart-lang/sdk/blob/main/runtime/vm/elf.cc
"""

from __future__ import annotations

import argparse
import contextlib
import hashlib
import json
import os
import re
import signal
import shutil
import struct
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping


ANDROID_NS = "http://schemas.android.com/apk/res/android"
ARCHITECTURES = {
    "android-arm": ("armeabi-v7a", 40, 1),
    "android-arm64": ("arm64-v8a", 183, 2),
    "android-x64": ("x86_64", 62, 2),
}
ERROR_CODES = {
    "invalid_identity", "invalid_path", "invalid_file", "invalid_symbols",
    "invalid_elf", "invalid_bundle", "aab_mismatch", "symbol_mismatch",
    "invalid_config", "config_mismatch", "invalid_tool", "tool_mismatch",
    "command_failed", "command_timeout", "command_unavailable",
    "invalid_manifest", "version_mismatch", "invalid_auth", "invalid_timeout",
    "invalid_cli_version", "invalid_receipt", "receipt_mismatch",
    "receipt_busy", "receipt_write_failed", "artifact_changed", "archive_mismatch",
    "archive_failed", "invalid_json",
}


class EvidenceError(ValueError):
    """Only fixed, non-sensitive reason codes cross the CLI boundary."""

    def __init__(self, code: str):
        self.code = code if code in ERROR_CODES else "invalid_identity"
        super().__init__(self.code)


@dataclass(frozen=True)
class BuildRequest:
    aab: Path
    symbols: Path
    google_services: Path
    git_sha: str
    run_id: int
    run_attempt: int
    version_code: int
    firebase_app_id: str
    expected_aab_sha256: str


@dataclass(frozen=True)
class ToolCommand:
    argv: tuple[str, ...]
    sha256: Mapping[str, str]


def _matches(value, pattern: str) -> bool:
    return isinstance(value, str) and re.fullmatch(pattern, value) is not None


def _positive(value, maximum: int) -> bool:
    return type(value) is int and 0 < value <= maximum


def _validate_identity(request: BuildRequest) -> None:
    if not (
        _matches(request.git_sha, r"[0-9a-f]{40}")
        and _matches(request.expected_aab_sha256, r"[0-9a-f]{64}")
        and _matches(request.firebase_app_id, r"1:[1-9][0-9]{0,19}:android:[0-9a-f]{16,64}")
        and _positive(request.run_id, 2**63 - 1)
        and _positive(request.run_attempt, 2**31 - 1)
        and _positive(request.version_code, 2_100_000_000)
    ):
        raise EvidenceError("invalid_identity")


def _path(value: Path, *, exists: bool = True) -> Path:
    try:
        path = Path(value).absolute()
        # Refuse symlinks/junctions in any supplied path, including parents.
        for item in (path, *path.parents):
            if item.is_symlink() or getattr(item, "is_junction", lambda: False)():
                raise EvidenceError("invalid_path")
        return path.resolve(strict=exists)
    except (OSError, TypeError, ValueError):
        raise EvidenceError("invalid_path") from None


def _file(value: Path) -> Path:
    path = _path(value)
    if not path.is_file():
        raise EvidenceError("invalid_file")
    return path


def _digest(value: Path) -> str:
    path = _file(value)
    try:
        before = path.stat()
        hasher = hashlib.sha256()
        with path.open("rb") as source:
            for chunk in iter(lambda: source.read(1024 * 1024), b""):
                hasher.update(chunk)
        after = path.stat()
        if (before.st_size, before.st_mtime_ns, before.st_ino) != (
                after.st_size, after.st_mtime_ns, after.st_ino):
            raise EvidenceError("artifact_changed")
        return hasher.hexdigest()
    except OSError:
        raise EvidenceError("invalid_file") from None


def _read_bytes(value: Path, maximum: int) -> bytes:
    path = _file(value)
    try:
        with path.open("rb") as source:
            content = source.read(maximum + 1)
        if not content or len(content) > maximum:
            raise EvidenceError("invalid_file")
        return content
    except OSError:
        raise EvidenceError("invalid_file") from None


def _unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise EvidenceError("invalid_json")
        result[key] = value
    return result


def _read_json(path: Path) -> dict:
    try:
        result = json.loads(_read_bytes(path, 2 * 1024 * 1024), object_pairs_hook=_unique_object)
        if not isinstance(result, dict):
            raise EvidenceError("invalid_json")
        return result
    except (UnicodeError, json.JSONDecodeError, RecursionError):
        raise EvidenceError("invalid_json") from None


def _validate_tool(tool: ToolCommand) -> None:
    if (not isinstance(tool, ToolCommand) or not tool.argv
            or not isinstance(tool.sha256, Mapping)
            or any(not isinstance(arg, str) or not arg or "\0" in arg for arg in tool.argv)):
        raise EvidenceError("invalid_tool")
    executable = Path(tool.argv[0])
    if not executable.is_absolute() or executable.suffix.lower() in {".bat", ".cmd"}:
        # Windows batch wrappers can introduce an implicit shell. Use Node+JS.
        raise EvidenceError("invalid_tool")
    referenced = {str(_file(executable))}
    for argument in tool.argv[1:]:
        if argument.startswith("-"):
            continue
        candidate = Path(argument)
        if candidate.is_absolute() or candidate.suffix.lower() in {".jar", ".js", ".py", ".exe"}:
            if not candidate.is_absolute():
                raise EvidenceError("invalid_tool")
            referenced.add(str(_file(candidate)))
    if set(tool.sha256) != referenced:
        raise EvidenceError("invalid_tool")
    for path, expected in tool.sha256.items():
        if not _matches(expected, r"[0-9a-f]{64}") or _digest(Path(path)) != expected:
            raise EvidenceError("tool_mismatch")


def _run(tool: ToolCommand, arguments: list[str], environment: Mapping[str, str],
         timeout: float, *, capture: bool) -> str:
    _validate_tool(tool)
    if type(timeout) not in (int, float) or not 0 < timeout <= 600:
        raise EvidenceError("invalid_timeout")
    try:
        # Upload output is discarded, not parsed, logged, or included in receipts.
        # Temporary storage bounds memory for manifest/version output; only a
        # small, validated prefix is read after the bounded command finishes.
        with tempfile.TemporaryFile() as output:
            process = subprocess.Popen(
                [*tool.argv, *arguments], stdin=subprocess.DEVNULL,
                stdout=output if capture else subprocess.DEVNULL,
                stderr=subprocess.DEVNULL, shell=False, env=dict(environment),
                start_new_session=os.name != "nt",
                creationflags=(subprocess.CREATE_NEW_PROCESS_GROUP | subprocess.CREATE_NO_WINDOW)
                if os.name == "nt" else 0,
            )
            try:
                return_code = process.wait(timeout=timeout)
            finally:
                if process.poll() is None:
                    _stop_process_tree(process)
            if return_code != 0:
                raise EvidenceError("command_failed")
            _validate_tool(tool)
            if not capture:
                return ""
            output.seek(0)
            raw = output.read(1024 * 1024 + 1)
            if len(raw) > 1024 * 1024:
                raise EvidenceError("command_failed")
            return raw.decode("utf-8")
    except subprocess.TimeoutExpired:
        raise EvidenceError("command_timeout") from None
    except (OSError, UnicodeError):
        raise EvidenceError("command_unavailable") from None


def _stop_process_tree(process: subprocess.Popen) -> None:
    """Stop only this invocation and its children, including Firebase's Java."""
    try:
        if os.name == "nt":
            import ctypes

            buffer = ctypes.create_unicode_buffer(32768)
            if not ctypes.windll.kernel32.GetSystemDirectoryW(buffer, len(buffer)):
                raise OSError
            # Resolve the OS utility without PATH or an environment override.
            subprocess.run([str(Path(buffer.value) / "taskkill.exe"), "/PID",
                            str(process.pid), "/T", "/F"], shell=False,
                           stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL, check=False, timeout=10,
                           creationflags=subprocess.CREATE_NO_WINDOW)
        else:
            os.killpg(process.pid, signal.SIGKILL)
    finally:
        if process.poll() is None:
            process.kill()
        process.wait(timeout=5)


def _elf(data: bytes, machine: int, elf_class: int, *, debug: bool) -> str:
    """Validate section bounds, architecture and a nonzero GNU build ID.

    This is not a DWARF decoder: Firebase still validates the debug payload.
    Unknown/compressed debug layouts are intentionally unsupported.
    """
    def region(offset, size):
        if offset < 0 or size < 0 or offset > len(data) or size > len(data) - offset:
            raise EvidenceError("invalid_elf")
        return data[offset:offset + size]

    try:
        header_size, section_size = (64, 64) if elf_class == 2 else (52, 40)
        if (len(data) < header_size or data[:7] != b"\x7fELF" + bytes((elf_class, 1, 1))
                or struct.unpack_from("<H", data, 18)[0] != machine):
            raise EvidenceError("invalid_elf")
        header = struct.unpack_from("<HHIQQQIHHHHHH" if elf_class == 2
                                    else "<HHIIIIIHHHHHH", data, 16)
        if header[2] != 1 or header[7] != header_size or header[10] != section_size:
            raise EvidenceError("invalid_elf")
        table_offset, count, string_index = header[5], header[11], header[12]
        if not 0 < string_index < count <= 4096:
            raise EvidenceError("invalid_elf")
        region(table_offset, count * section_size)
        sections = [struct.unpack_from("<IIQQQQIIQQ" if elf_class == 2 else
                                       "<IIIIIIIIII", data, table_offset + i * section_size)
                    for i in range(count)]
        strings = sections[string_index]
        if strings[1] != 3:
            raise EvidenceError("invalid_elf")
        names = region(strings[4], strings[5])
        named = {}
        for section in sections[1:]:
            name_start = section[0]
            name_end = names.find(b"\0", name_start)
            if name_start >= len(names) or name_end < 0:
                raise EvidenceError("invalid_elf")
            name = names[name_start:name_end].decode("ascii")
            if name in named:
                raise EvidenceError("invalid_elf")
            named[name] = section
            if section[1] != 8:  # SHT_NOBITS has no physical bytes.
                region(section[4], section[5])
        if debug and any(name not in named or named[name][1] != 1
                         or named[name][5] == 0 or named[name][2] & 0x800
                         for name in (".debug_info", ".debug_line", ".debug_abbrev")):
            raise EvidenceError("invalid_elf")
        note = named.get(".note.gnu.build-id")
        if note is None or note[1] != 7:
            raise EvidenceError("invalid_elf")
        content = region(note[4], note[5])
        name_size, id_size, kind = struct.unpack_from("<III", content)
        if (name_size != 4 or kind != 3 or id_size not in (16, 20, 32)
                or len(content) != 16 + id_size or content[12:16] != b"GNU\0"):
            raise EvidenceError("invalid_elf")
        build_id = content[16:]
        if not any(build_id):
            raise EvidenceError("invalid_elf")
        return build_id.hex()
    except (struct.error, UnicodeError, IndexError):
        raise EvidenceError("invalid_elf") from None


def _artifacts(request: BuildRequest) -> dict:
    _validate_identity(request)
    aab = _file(request.aab)
    aab_hash = _digest(aab)
    if aab_hash != request.expected_aab_sha256:
        raise EvidenceError("aab_mismatch")
    symbols = _path(request.symbols)
    if not symbols.is_dir():
        raise EvidenceError("invalid_symbols")
    filenames = {f"app.{arch}.symbols": arch for arch in ARCHITECTURES}
    result = {}
    try:
        for path in symbols.iterdir():
            if path.name not in filenames or not path.is_file():
                raise EvidenceError("invalid_symbols")
            arch = filenames[path.name]
            _, machine, elf_class = ARCHITECTURES[arch]
            content = _read_bytes(path, 256 * 1024 * 1024)
            result[arch] = {"fileName": path.name,
                            "sha256": hashlib.sha256(content).hexdigest(),
                            "buildId": _elf(content, machine, elf_class, debug=True)}
        if not result:
            raise EvidenceError("invalid_symbols")
        with zipfile.ZipFile(aab) as bundle:
            names = bundle.namelist()
            if len(names) > 100_000 or len(names) != len(set(names)) or not {
                "BundleConfig.pb", "base/manifest/AndroidManifest.xml"
            }.issubset(names):
                raise EvidenceError("invalid_bundle")
            abi_arch = {values[0]: arch for arch, values in ARCHITECTURES.items()}
            bundled = set()
            for name in names:
                if not name.endswith("/libapp.so"):
                    if re.search(r"/libapp[^/]*\.so$", name):
                        raise EvidenceError("invalid_bundle")
                    continue
                match = re.fullmatch(r"base/lib/([^/]+)/libapp\.so", name)
                if not match or match[1] not in abi_arch:
                    raise EvidenceError("invalid_bundle")
                arch = abi_arch[match[1]]
                if arch not in result or bundle.getinfo(name).file_size > 256 * 1024 * 1024:
                    raise EvidenceError("symbol_mismatch")
                _, machine, elf_class = ARCHITECTURES[arch]
                if _elf(bundle.read(name), machine, elf_class, debug=False) != result[arch]["buildId"]:
                    raise EvidenceError("symbol_mismatch")
                bundled.add(arch)
            if bundled != set(result):
                raise EvidenceError("symbol_mismatch")
    except (OSError, zipfile.BadZipFile, RuntimeError):
        raise EvidenceError("invalid_bundle") from None
    if _digest(aab) != aab_hash:
        raise EvidenceError("artifact_changed")
    return {"aabSha256": aab_hash, "symbols": result}


def _identity(request: BuildRequest, bundletool: ToolCommand,
              environment: Mapping[str, str], timeout: float) -> dict:
    before = _artifacts(request)
    manifest_text = _run(bundletool, ["dump", "manifest", f"--bundle={_file(request.aab)}",
                                     "--module=base"], environment, timeout, capture=True)
    if "<!" in manifest_text:
        raise EvidenceError("invalid_manifest")
    try:
        manifest = ET.fromstring(manifest_text)
        version = manifest.get(f"{{{ANDROID_NS}}}versionCode")
        package = manifest.get("package")
        if (manifest.tag != "manifest" or not _matches(version, r"[1-9][0-9]{0,9}")
                or not _matches(package, r"[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+")
                or manifest.get(f"{{{ANDROID_NS}}}versionCodeMajor", "0") != "0"):
            raise EvidenceError("invalid_manifest")
        if int(version) != request.version_code:
            raise EvidenceError("version_mismatch")
    except ET.ParseError:
        raise EvidenceError("invalid_manifest") from None
    config = _read_json(request.google_services)
    try:
        matching = [client["client_info"]["mobilesdk_app_id"] for client in config["client"]
                    if client["client_info"]["android_client_info"]["package_name"] == package]
    except (KeyError, TypeError):
        raise EvidenceError("invalid_config") from None
    if matching != [request.firebase_app_id]:
        raise EvidenceError("config_mismatch")
    if _artifacts(request) != before:
        raise EvidenceError("artifact_changed")
    return {"schemaVersion": 1, "gitSha": request.git_sha, "runId": request.run_id,
            "runAttempt": request.run_attempt, "versionCode": request.version_code,
            "firebaseAppId": request.firebase_app_id, "packageName": package, **before}


def _cli_version(value: str) -> str:
    # No arbitrary version stdout, suffix, or ANSI escapes enter a receipt.
    if not _matches(value, r"[0-9]{1,4}\.[0-9]{1,4}\.[0-9]{1,4}"):
        raise EvidenceError("invalid_cli_version")
    if tuple(map(int, value.split("."))) < (11, 9, 0):
        raise EvidenceError("invalid_cli_version")
    return value


def _check_receipt(receipt: dict, identity: dict) -> str:
    body = {key: value for key, value in receipt.items() if key != "uploadResult"}
    # Canonical JSON distinguishes bool from int (unlike Python dict equality).
    if json.dumps(body, sort_keys=True) != json.dumps(identity, sort_keys=True):
        raise EvidenceError("receipt_mismatch")
    result = receipt.get("uploadResult")
    if not isinstance(result, dict):
        raise EvidenceError("invalid_receipt")
    status = result.get("status")
    expected = {"status", "cliVersion", "reason"} if status == "failed" else {"status", "cliVersion"}
    if status not in {"pending", "failed", "success"} or set(result) != expected:
        raise EvidenceError("invalid_receipt")
    if status == "failed" and result["reason"] not in ERROR_CODES:
        raise EvidenceError("invalid_receipt")
    _cli_version(result["cliVersion"])
    return status


def _receipt_path(request: BuildRequest, value: Path) -> Path:
    path = _path(value, exists=False)
    if (path in {_path(request.aab, exists=False), _path(request.google_services, exists=False)}
            or path.is_relative_to(_path(request.symbols, exists=False))):
        raise EvidenceError("invalid_path")
    return path


@contextlib.contextmanager
def _receipt_lock(path: Path):
    lock = path.with_name(path.name + ".lock")
    try:
        path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        descriptor = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    except FileExistsError:
        raise EvidenceError("receipt_busy") from None
    except OSError:
        raise EvidenceError("receipt_write_failed") from None
    os.close(descriptor)
    try:
        yield
    finally:
        lock.unlink(missing_ok=True)


def _write_receipt(path: Path, value: dict) -> None:
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", newline="\n",
                                         dir=path.parent, delete=False) as output:
            temporary = Path(output.name)
            json.dump(value, output, sort_keys=True, indent=2, allow_nan=False)
            output.write("\n")
            output.flush()
            os.fsync(output.fileno())
        _path(path, exists=False)
        os.replace(temporary, path)
    except OSError:
        raise EvidenceError("receipt_write_failed") from None
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def upload_symbols(request: BuildRequest, receipt_path: Path, *, bundletool: ToolCommand,
                   firebase: ToolCommand, environment: Mapping[str, str] | None = None,
                   timeout_seconds: float = 120) -> dict:
    """Upload once, or retry only the identical recorded build and symbol set."""
    env = dict(os.environ if environment is None else environment)
    _validate_identity(request)
    _validate_tool(bundletool)
    _validate_tool(firebase)
    identity = _identity(request, bundletool, env, timeout_seconds)
    path = _receipt_path(request, receipt_path)
    with _receipt_lock(path):
        if path.exists():
            previous = _read_json(path)
            if _check_receipt(previous, identity) == "success":
                return previous
        if not env.get("GOOGLE_APPLICATION_CREDENTIALS") or env.get("FIREBASE_TOKEN"):
            raise EvidenceError("invalid_auth")
        # Check presence only. Even malformed credentials are never parsed here.
        _file(Path(env["GOOGLE_APPLICATION_CREDENTIALS"]))
        version = _cli_version(_run(firebase, ["--version"], env, timeout_seconds,
                                    capture=True).strip())
        pending = {**identity, "uploadResult": {"status": "pending", "cliVersion": version}}
        _write_receipt(path, pending)
        try:
            if _identity(request, bundletool, env, timeout_seconds) != identity:
                raise EvidenceError("artifact_changed")
            _run(firebase, ["crashlytics:symbols:upload", "--app", request.firebase_app_id,
                            str(_path(request.symbols)), "--non-interactive"],
                 env, timeout_seconds, capture=False)
            try:
                if _identity(request, bundletool, env, timeout_seconds) != identity:
                    raise EvidenceError("artifact_changed")
            except EvidenceError:
                raise EvidenceError("artifact_changed") from None
        except EvidenceError as failure:
            _write_receipt(path, {**identity, "uploadResult": {
                "status": "failed", "cliVersion": version, "reason": failure.code}})
            raise
        success = {**identity, "uploadResult": {"status": "success", "cliVersion": version}}
        _write_receipt(path, success)
        return success


def _require_success(request: BuildRequest, receipt_path: Path, bundletool: ToolCommand,
                     environment: Mapping[str, str], timeout: float) -> dict:
    identity = _identity(request, bundletool, environment, timeout)
    path = _receipt_path(request, receipt_path)
    if path.with_name(path.name + ".lock").exists():
        raise EvidenceError("receipt_busy")
    receipt = _read_json(path)
    if _check_receipt(receipt, identity) != "success":
        raise EvidenceError("invalid_receipt")
    return receipt


def verify_success_receipt(request: BuildRequest, receipt_path: Path, *,
                           bundletool: ToolCommand, environment: Mapping[str, str] | None = None,
                           timeout_seconds: float = 30) -> bool:
    """Independent read-only gate. Missing, malformed, stale, or failed => False."""
    try:
        _require_success(request, receipt_path, bundletool,
                         os.environ if environment is None else environment, timeout_seconds)
        return True
    except (EvidenceError, OSError, TypeError, ValueError, KeyError):
        return False


def _verify_archive(destination: Path, expected: dict[str, str]) -> None:
    try:
        actual = {}
        for path in destination.rglob("*"):
            resolved = _path(path)
            if resolved.is_file():
                actual[path.relative_to(destination).as_posix()] = _digest(path)
            elif path.relative_to(destination).as_posix() != "symbols":
                raise EvidenceError("archive_mismatch")
        if actual != expected:
            raise EvidenceError("archive_mismatch")
    except OSError:
        raise EvidenceError("archive_mismatch") from None


def archive_release(request: BuildRequest, receipt_path: Path, destination: Path, *,
                    bundletool: ToolCommand, environment: Mapping[str, str] | None = None,
                    timeout_seconds: float = 30) -> Path:
    """Preserve private local evidence; never overwrite a different archive.

    New directories use owner-only POSIX permissions; on Windows callers must
    choose an ACL-restricted parent. Interrupted partial archives stay in place
    and fail verification rather than being silently overwritten or deleted.
    """
    env = os.environ if environment is None else environment
    receipt = _require_success(request, receipt_path, bundletool, env, timeout_seconds)
    receipt_hash = _digest(receipt_path)
    sources = {"app-release.aab": _file(request.aab),
               "upload-receipt.json": _file(receipt_path)}
    expected = {"app-release.aab": receipt["aabSha256"], "upload-receipt.json": receipt_hash}
    for symbol in receipt["symbols"].values():
        name = "symbols/" + symbol["fileName"]
        sources[name] = _file(request.symbols / symbol["fileName"])
        expected[name] = symbol["sha256"]
    target = _path(destination, exists=False)
    if (any(source.is_relative_to(target) for source in sources.values())
            or target.is_relative_to(_path(request.symbols))):
        raise EvidenceError("invalid_path")
    try:
        target.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        try:
            target.mkdir(mode=0o700)
        except FileExistsError:
            if not target.is_dir():
                raise EvidenceError("archive_mismatch")
            _verify_archive(target, expected)
            return target
        (target / "symbols").mkdir(mode=0o700)
        for name, source in sources.items():
            with (target / name).open("xb") as output, source.open("rb") as original:
                os.chmod(target / name, 0o600)
                shutil.copyfileobj(original, output, length=1024 * 1024)
        _verify_archive(target, expected)
        if (_require_success(request, receipt_path, bundletool, env, timeout_seconds) != receipt
                or _digest(receipt_path) != receipt_hash):
            raise EvidenceError("artifact_changed")
        return target
    except OSError:
        raise EvidenceError("archive_failed") from None


def _cli_positive_integer(value: str) -> int:
    if not _matches(value, r"[1-9][0-9]{0,18}"):
        raise argparse.ArgumentTypeError("expected canonical positive decimal integer")
    return int(value)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("operation", choices=("upload", "verify", "archive"))
    for option in ("aab", "symbols", "google-services", "receipt", "tools-json"):
        parser.add_argument("--" + option, type=Path, required=True)
    for option in ("git-sha", "firebase-app-id", "expected-aab-sha256"):
        parser.add_argument("--" + option, required=True)
    for option in ("run-id", "run-attempt", "version-code"):
        parser.add_argument("--" + option, type=_cli_positive_integer, required=True)
    parser.add_argument("--archive-dir", type=Path)
    parser.add_argument("--timeout-seconds", type=float, default=120)
    args = parser.parse_args(argv)
    try:
        config = _read_json(args.tools_json)
        tools = {name: ToolCommand(tuple(value["argv"]), value["sha256"])
                 for name, value in config.items()}
        request = BuildRequest(args.aab, args.symbols, args.google_services, args.git_sha,
                               args.run_id, args.run_attempt, args.version_code,
                               args.firebase_app_id, args.expected_aab_sha256)
        common = {"bundletool": tools["bundletool"], "timeout_seconds": args.timeout_seconds}
        if args.operation == "upload":
            upload_symbols(request, args.receipt, firebase=tools["firebase"], **common)
        elif args.operation == "verify":
            if not verify_success_receipt(request, args.receipt, **common):
                raise EvidenceError("invalid_receipt")
        else:
            if args.archive_dir is None:
                raise EvidenceError("invalid_path")
            archive_release(request, args.receipt, args.archive_dir, **common)
        print(json.dumps({"ok": True, "operation": args.operation}))
        return 0
    except (EvidenceError, OSError, TypeError, ValueError, KeyError) as failure:
        code = failure.code if isinstance(failure, EvidenceError) else "invalid_config"
        print(json.dumps({"ok": False, "reason": code}), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
