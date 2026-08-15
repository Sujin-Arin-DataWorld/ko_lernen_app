#!/usr/bin/env python3
"""Find or delete legacy translation cache documents without printing values.

Dry-run is the default. Documents containing the retired `src` field, a version
different from the current `_CACHE_VERSION`, or no valid TTL timestamp are
selected. `--apply` is required to delete matches; this repository never runs
apply automatically.
"""

from __future__ import annotations

import argparse
import ast
from dataclasses import dataclass
from datetime import datetime
import os
from pathlib import Path
import shutil
import subprocess
import sys
from typing import Any, Iterable, Mapping


COLLECTION = "translation_cache"
COMMIT_LIMIT = 400


@dataclass(frozen=True)
class CleanupReport:
    scanned: int
    matched: int
    deleted: int
    source_bearing: int
    missing_expires_at: int
    version_mismatch: int


def cache_version_from_source(main_path: Path) -> str:
    tree = ast.parse(main_path.read_text(encoding="utf-8"), filename=str(main_path))
    for node in tree.body:
        if isinstance(node, (ast.Assign, ast.AnnAssign)):
            targets = node.targets if isinstance(node, ast.Assign) else [node.target]
            if any(isinstance(target, ast.Name) and target.id == "_CACHE_VERSION" for target in targets):
                value = ast.literal_eval(node.value)
                if isinstance(value, str) and value:
                    return value
    raise ValueError("main.py has no literal _CACHE_VERSION")


def should_delete_document(data: Mapping[str, Any], current_version: str) -> bool:
    return (
        "src" in data
        or data.get("version") != current_version
        or not isinstance(data.get("expiresAt"), datetime)
    )


def cleanup_documents(
    snapshots: Iterable[Any],
    *,
    current_version: str,
    apply: bool,
    batch_factory: Any,
) -> CleanupReport:
    scanned = 0
    matched = 0
    deleted = 0
    source_bearing = 0
    missing_expires_at = 0
    version_mismatch = 0
    batch = batch_factory() if apply else None
    pending = 0
    for snapshot in snapshots:
        scanned += 1
        data = snapshot.to_dict() or {}
        if "src" in data:
            source_bearing += 1
        if not isinstance(data.get("expiresAt"), datetime):
            missing_expires_at += 1
        if data.get("version") != current_version:
            version_mismatch += 1
        if not should_delete_document(data, current_version):
            continue
        matched += 1
        if not apply:
            continue
        batch.delete(snapshot.reference)
        pending += 1
        deleted += 1
        if pending == COMMIT_LIMIT:
            batch.commit()
            batch = batch_factory()
            pending = 0
    if apply and pending:
        batch.commit()
    return CleanupReport(
        scanned=scanned,
        matched=matched,
        deleted=deleted,
        source_bearing=source_bearing,
        missing_expires_at=missing_expires_at,
        version_mismatch=version_mismatch,
    )


def _gcloud_credentials() -> Any:
    """Use the active gcloud account without writing an ADC credential file."""
    from google.oauth2.credentials import Credentials  # type: ignore

    executable = shutil.which("gcloud.cmd" if os.name == "nt" else "gcloud")
    if executable is None:
        raise FileNotFoundError("gcloud was not found on PATH")
    completed = subprocess.run(
        [executable, "auth", "print-access-token"],
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    token = completed.stdout.strip()
    if not token:
        raise RuntimeError("gcloud returned an empty access token")
    return Credentials(token=token)


def run(
    *,
    project: str,
    apply: bool,
    main_path: Path,
    use_gcloud_credentials: bool = False,
) -> CleanupReport:
    from google.cloud import firestore  # type: ignore

    current_version = cache_version_from_source(main_path)
    credentials = _gcloud_credentials() if use_gcloud_credentials else None
    database = firestore.Client(project=project, credentials=credentials)
    query = database.collection(COLLECTION).select(["src", "version", "expiresAt"])
    return cleanup_documents(
        query.stream(),
        current_version=current_version,
        apply=apply,
        batch_factory=database.batch,
    )


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", default="ko-lernen-app")
    parser.add_argument(
        "--main-path",
        type=Path,
        default=Path(__file__).resolve().parent / "main.py",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="delete matching documents; omitted means read-only dry-run",
    )
    parser.add_argument(
        "--use-gcloud-credentials",
        action="store_true",
        help="use the active gcloud token in memory when ADC is unavailable",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        report = run(
            project=args.project,
            apply=args.apply,
            main_path=args.main_path,
            use_gcloud_credentials=args.use_gcloud_credentials,
        )
    except Exception as error:  # noqa: BLE001 - operator CLI boundary
        print(f"cache cleanup failed: {type(error).__name__}", file=sys.stderr)
        return 1
    mode = "apply" if args.apply else "dry-run"
    print(
        f"mode={mode} project={args.project} scanned={report.scanned} "
        f"source_bearing={report.source_bearing} "
        f"missing_expires_at={report.missing_expires_at} "
        f"version_mismatch={report.version_mismatch} "
        f"matched={report.matched} deleted={report.deleted}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
