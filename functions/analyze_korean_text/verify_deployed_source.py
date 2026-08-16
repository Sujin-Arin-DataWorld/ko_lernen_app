#!/usr/bin/env python3
"""Verify the exact Gen2 source archive against the local runtime source.

The default mode is offline and validates the local `.gcloudignore` exact
allowlist. Pass `--archive` to compare an already downloaded Cloud Functions
source ZIP. Pass `--function` to describe and download a deployed generation
with gcloud before comparing it. Source contents and environment values are
never printed.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import sys
import tempfile
from typing import Iterable
import zipfile


RUNTIME_FILES = (
    "main.py",
    "requirements.txt",
    "dictionary_validation.py",
    "grammar_analysis.py",
    "grammar_patterns.json",
    "security.py",
    "text_quality.py",
)


class SourceVerificationError(RuntimeError):
    """Raised when a local or deployed source manifest is unsafe or stale."""


def firebase_app_ids_from_options(options_path: Path) -> tuple[str, str]:
    """Read Android/iOS App IDs from the FlutterFire runtime configuration."""
    source = options_path.read_text(encoding="utf-8")
    app_ids: list[str] = []
    for platform in ("android", "ios"):
        block = re.search(
            rf"static\s+const\s+FirebaseOptions\s+{platform}\s*=\s*"
            r"FirebaseOptions\((.*?)\n\s*\);",
            source,
            flags=re.DOTALL,
        )
        if block is None:
            raise SourceVerificationError("FlutterFire mobile app configuration is incomplete")
        app_id = re.search(r"\bappId:\s*'([^']+)'", block.group(1))
        if app_id is None or not app_id.group(1).startswith("1:"):
            raise SourceVerificationError("FlutterFire mobile App ID is invalid")
        app_ids.append(app_id.group(1))
    if app_ids[0] == app_ids[1]:
        raise SourceVerificationError("FlutterFire mobile App IDs must be distinct")
    return app_ids[0], app_ids[1]


def app_ids_from_deploy_env(deploy_env_path: Path) -> tuple[str, str]:
    """Read the only permitted non-secret deployment setting."""
    active = [
        line.strip()
        for line in deploy_env_path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    if len(active) != 1:
        raise SourceVerificationError("deploy env must have exactly one setting")
    match = re.fullmatch(
        r'ALLOWED_FIREBASE_APP_IDS:\s*"([^"\r\n]+)"', active[0]
    )
    if match is None:
        raise SourceVerificationError("deploy env setting is not the App ID allowlist")
    app_ids = tuple(item.strip() for item in match.group(1).split(","))
    if len(app_ids) != 2 or any(not item.startswith("1:") for item in app_ids):
        raise SourceVerificationError("deploy env must contain two Firebase App IDs")
    return app_ids[0], app_ids[1]


def validate_deploy_app_ids(
    source_dir: Path,
    *,
    options_path: Path | None = None,
    android_config_path: Path | None = None,
    deploy_env_path: Path | None = None,
) -> tuple[str, str]:
    """Require deploy IDs to match real Flutter and Android app configs."""
    repository = source_dir.resolve().parents[1]
    options_path = options_path or repository / "lib" / "firebase_options.dart"
    android_config_path = (
        android_config_path
        or repository / "android" / "app" / "google-services.json"
    )
    deploy_env_path = deploy_env_path or source_dir / "deploy.env.yaml"

    configured = firebase_app_ids_from_options(options_path)
    deployed = app_ids_from_deploy_env(deploy_env_path)
    try:
        android_config = json.loads(android_config_path.read_text(encoding="utf-8"))
        native_android_ids = {
            client["client_info"]["mobilesdk_app_id"]
            for client in android_config["client"]
        }
    except (KeyError, TypeError, json.JSONDecodeError) as error:
        raise SourceVerificationError("Android Firebase app configuration is invalid") from error
    if configured[0] not in native_android_ids:
        raise SourceVerificationError("Flutter and Android Firebase App IDs differ")
    if deployed != configured:
        raise SourceVerificationError("deploy App IDs differ from the app configuration")
    return configured


def _normalized_archive_name(raw_name: str) -> str:
    name = raw_name.replace("\\", "/")
    path = PurePosixPath(name)
    if path.is_absolute() or ".." in path.parts:
        raise SourceVerificationError("source archive contains an unsafe path")
    normalized = str(path)
    if normalized.startswith("./"):
        normalized = normalized[2:]
    return normalized


def declared_allowlist(ignore_path: Path) -> tuple[str, ...]:
    """Return root file negations from the exact-allowlist .gcloudignore."""
    lines = ignore_path.read_text(encoding="utf-8").splitlines()
    active = [line.strip() for line in lines if line.strip() and not line.lstrip().startswith("#")]
    if not active or active[0] != "*":
        raise SourceVerificationError(".gcloudignore must start by ignoring everything")
    if any(not line.startswith("!") for line in active[1:]):
        raise SourceVerificationError(".gcloudignore may contain only allowlist negations after '*'")
    allowed = tuple(line[1:] for line in active[1:])
    if any(not item or "/" in item or "\\" in item for item in allowed):
        raise SourceVerificationError("runtime allowlist must contain root files only")
    if len(set(allowed)) != len(allowed):
        raise SourceVerificationError("runtime allowlist contains duplicates")
    return allowed


def validate_local_manifest(source_dir: Path) -> tuple[str, ...]:
    declared = declared_allowlist(source_dir / ".gcloudignore")
    if set(declared) != set(RUNTIME_FILES):
        raise SourceVerificationError(
            "runtime allowlist does not match the audited import closure"
        )
    missing = [name for name in RUNTIME_FILES if not (source_dir / name).is_file()]
    if missing:
        raise SourceVerificationError(
            "local runtime source is missing required files: " + ", ".join(missing)
        )
    return declared


def validate_gcloud_upload_manifest(source_dir: Path) -> tuple[str, ...]:
    """Ask gcloud which files it would really upload and require exactness."""
    raw = _run_gcloud(["meta", "list-files-for-upload", str(source_dir)])
    uploaded = tuple(
        _normalized_archive_name(line.strip())
        for line in raw.splitlines()
        if line.strip()
    )
    if len(uploaded) != len(set(uploaded)):
        raise SourceVerificationError("gcloud upload manifest contains duplicates")
    expected = set(RUNTIME_FILES)
    names = set(uploaded)
    if names != expected:
        missing = sorted(expected - names)
        detail = f"; missing known runtime files: {', '.join(missing)}" if missing else ""
        raise SourceVerificationError(
            f"gcloud upload manifest is not the exact {len(RUNTIME_FILES)}-file allowlist"
            f" (unexpected file count: {len(names - expected)}){detail}"
        )
    return uploaded


def _digest_entries(entries: Iterable[tuple[str, bytes]]) -> str:
    digest = hashlib.sha256()
    for name, content in sorted(entries):
        encoded_name = name.encode("utf-8")
        digest.update(len(encoded_name).to_bytes(4, "big"))
        digest.update(encoded_name)
        digest.update(len(content).to_bytes(8, "big"))
        digest.update(content)
    return digest.hexdigest()


def local_source_digest(source_dir: Path) -> str:
    validate_local_manifest(source_dir)
    return _digest_entries(
        (name, (source_dir / name).read_bytes()) for name in RUNTIME_FILES
    )


def archive_source_digest(archive_path: Path) -> str:
    try:
        with zipfile.ZipFile(archive_path) as archive:
            files: dict[str, bytes] = {}
            for info in archive.infolist():
                if info.is_dir():
                    continue
                name = _normalized_archive_name(info.filename)
                if name in files:
                    raise SourceVerificationError(
                        "source archive contains duplicate file paths"
                    )
                files[name] = archive.read(info)
    except zipfile.BadZipFile as error:
        raise SourceVerificationError("deployed source is not a valid ZIP") from error

    names = set(files)
    expected = set(RUNTIME_FILES)
    if names != expected:
        missing = sorted(expected - names)
        detail = f"; missing known runtime files: {', '.join(missing)}" if missing else ""
        raise SourceVerificationError(
            f"source archive manifest is not the exact {len(RUNTIME_FILES)}-file allowlist"
            f" (unexpected file count: {len(names - expected)}){detail}"
        )
    return _digest_entries(files.items())


def verify_archive(source_dir: Path, archive_path: Path) -> str:
    local_digest = local_source_digest(source_dir)
    deployed_digest = archive_source_digest(archive_path)
    if local_digest != deployed_digest:
        raise SourceVerificationError(
            "deployed source bytes do not match the local runtime source "
            f"(local={local_digest}, deployed={deployed_digest})"
        )
    return local_digest


def _run_gcloud(arguments: list[str]) -> str:
    executable = shutil.which("gcloud.cmd" if os.name == "nt" else "gcloud")
    if executable is None:
        raise SourceVerificationError("gcloud was not found on PATH")
    try:
        completed = subprocess.run(
            [executable, *arguments],
            check=True,
            capture_output=True,
            text=True,
            encoding="utf-8",
        )
    except FileNotFoundError as error:
        raise SourceVerificationError("gcloud was not found on PATH") from error
    except subprocess.CalledProcessError as error:
        raise SourceVerificationError(
            f"gcloud command failed with exit code {error.returncode}"
        ) from error
    return completed.stdout


def download_deployed_archive(
    function_name: str,
    *,
    project: str,
    region: str,
    destination: Path,
) -> None:
    raw = _run_gcloud(
        [
            "functions",
            "describe",
            function_name,
            "--gen2",
            f"--project={project}",
            f"--region={region}",
            "--format=json",
        ]
    )
    try:
        storage_source = json.loads(raw)["buildConfig"]["source"]["storageSource"]
        bucket = storage_source["bucket"]
        object_name = storage_source["object"]
        generation = storage_source.get("generation")
    except (KeyError, TypeError, json.JSONDecodeError) as error:
        raise SourceVerificationError(
            "function description has no readable storage source"
        ) from error
    uri = f"gs://{bucket}/{object_name}"
    if generation:
        uri += f"#{generation}"
    _run_gcloud(["storage", "cp", "--quiet", uri, str(destination)])


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source-dir",
        type=Path,
        default=Path(__file__).resolve().parent,
    )
    source = parser.add_mutually_exclusive_group()
    source.add_argument("--archive", type=Path)
    source.add_argument("--function", metavar="NAME")
    parser.add_argument("--project", default="ko-lernen-app")
    parser.add_argument("--region", default="europe-west3")
    parser.add_argument(
        "--check-gcloud-upload",
        action="store_true",
        help="also verify gcloud meta list-files-for-upload output",
    )
    parser.add_argument(
        "--check-app-ids",
        action="store_true",
        help="verify deploy App IDs against FlutterFire and Android configs",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        validate_local_manifest(args.source_dir)
        if args.check_gcloud_upload:
            validate_gcloud_upload_manifest(args.source_dir)
        if args.check_app_ids:
            validate_deploy_app_ids(args.source_dir)
        if args.archive:
            digest = verify_archive(args.source_dir, args.archive)
            print(f"PASS exact source archive: {len(RUNTIME_FILES)} files, sha256={digest}")
            return 0
        if args.function:
            with tempfile.TemporaryDirectory(prefix="hangul-sori-source-") as temporary:
                archive = Path(temporary) / "source.zip"
                download_deployed_archive(
                    args.function,
                    project=args.project,
                    region=args.region,
                    destination=archive,
                )
                digest = verify_archive(args.source_dir, archive)
            print(f"PASS deployed source: {len(RUNTIME_FILES)} files, sha256={digest}")
            return 0
        digest = local_source_digest(args.source_dir)
        checks = []
        if args.check_gcloud_upload:
            checks.append("gcloud upload manifest")
        if args.check_app_ids:
            checks.append("mobile App IDs")
        suffix = f" + {' + '.join(checks)}" if checks else ""
        print(
            f"PASS local source allowlist{suffix}: "
            f"{len(RUNTIME_FILES)} files, sha256={digest}"
        )
        return 0
    except (OSError, SourceVerificationError) as error:
        print(f"FAIL source verification: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
