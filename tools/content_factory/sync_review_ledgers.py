#!/usr/bin/env python3
"""Synchronize compact review ledgers from schema-complete JSON drafts.

The draft remains the only content source. This helper projects the common
eight review columns, preserves existing status and reviewer memo by stable
ID, and refuses unknown artifact kinds or malformed records. Preview is the
default; ``--apply`` writes every declared ledger as one rollback-safe group.
"""

from __future__ import annotations

import argparse
import csv
from io import StringIO
import json
import os
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MANIFEST = Path("tools/content_factory/drafts/batch_06_manifest.json")
REVIEW_HEADER = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]
PROJECTIONS = {
    "scenario": ("scenarios", ("title", "ko"), ("title", "de"), ("title", "en")),
    "smalltalk": ("phrases", ("ko",), ("de",), ("en",)),
    "cloze": ("items", ("fullKo",), ("de",), ("en",)),
    "satz": ("items", ("targetKo",), ("promptDe",), ("promptEn",)),
    "pronunciation": ("phrases", ("ko",), ("de",), ("en",)),
}


class ReviewSyncError(ValueError):
    """Raised when a manifest cannot produce trustworthy review ledgers."""


def _under_root(root: Path, raw: str) -> Path:
    if not isinstance(raw, str) or not raw.strip():
        raise ReviewSyncError("manifest paths must be nonempty repository-relative strings")
    path = (root / raw).resolve()
    try:
        path.relative_to(root.resolve())
    except ValueError as error:
        raise ReviewSyncError(f"path escapes repository root: {raw}") from error
    return path


def _read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ReviewSyncError(f"cannot read {path}: {error}") from error
    if not isinstance(value, dict):
        raise ReviewSyncError(f"{path}: root must be an object")
    return value


def _read_existing(path: Path) -> dict[str, dict[str, str]]:
    if not path.exists():
        return {}
    try:
        with path.open(encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            if list(reader.fieldnames or []) != REVIEW_HEADER:
                raise ReviewSyncError(f"{path}: existing review header is not the common schema")
            rows = list(reader)
    except (OSError, csv.Error) as error:
        raise ReviewSyncError(f"cannot read {path}: {error}") from error
    by_id: dict[str, dict[str, str]] = {}
    for row in rows:
        ident = (row.get("id") or "").strip()
        if not ident or ident in by_id:
            raise ReviewSyncError(f"{path}: existing review IDs must be unique and nonempty")
        by_id[ident] = row
    return by_id


def _required(record: dict[str, Any], path: tuple[str, ...], label: str) -> str:
    value: Any = record
    for key in path:
        if not isinstance(value, dict):
            raise ReviewSyncError(f"{label}: cannot project {'.'.join(path)}")
        value = value.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ReviewSyncError(f"{label}: {'.'.join(path)} must be a nonempty string")
    return value.strip()


def _csv_text(rows: list[dict[str, str]]) -> str:
    output = StringIO(newline="")
    writer = csv.DictWriter(output, fieldnames=REVIEW_HEADER, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return output.getvalue()


def build_ledgers(
    *,
    root: Path = ROOT,
    manifest_path: Path = DEFAULT_MANIFEST,
) -> dict[Path, str]:
    root = root.resolve()
    manifest_file = _under_root(root, str(manifest_path))
    manifest = _read_json(manifest_file)
    artifacts = manifest.get("artifacts")
    if not isinstance(artifacts, list) or not artifacts:
        raise ReviewSyncError(f"{manifest_file}: artifacts must be a nonempty array")

    outputs: dict[Path, str] = {}
    seen_kinds: set[str] = set()
    for artifact in artifacts:
        if not isinstance(artifact, dict):
            raise ReviewSyncError(f"{manifest_file}: artifact entries must be objects")
        kind = artifact.get("kind")
        if kind not in PROJECTIONS or kind in seen_kinds:
            raise ReviewSyncError(f"{manifest_file}: unsupported or duplicate artifact kind {kind!r}")
        seen_kinds.add(str(kind))
        collection, ko_path, de_path, en_path = PROJECTIONS[str(kind)]
        if artifact.get("collection") not in (None, collection):
            raise ReviewSyncError(f"{manifest_file}: {kind} collection disagrees with its schema")
        draft_path = _under_root(root, artifact.get("draft"))
        review_path = _under_root(root, artifact.get("review"))
        draft = _read_json(draft_path)
        records = draft.get(collection)
        if not isinstance(records, list) or any(not isinstance(item, dict) for item in records):
            raise ReviewSyncError(f"{draft_path}: {collection} must be an array of objects")
        if artifact.get("count") != len(records):
            raise ReviewSyncError(f"{draft_path}: manifest count disagrees with the draft")
        existing = _read_existing(review_path)
        rows: list[dict[str, str]] = []
        seen_ids: set[str] = set()
        for index, record in enumerate(records):
            ident = _required(record, ("id",), f"{draft_path}:{index}")
            level = _required(record, ("level",), f"{draft_path}:{ident}").upper()
            if ident in seen_ids:
                raise ReviewSyncError(f"{draft_path}: duplicate ID {ident!r}")
            seen_ids.add(ident)
            previous = existing.get(ident, {})
            seed = str(record.get("sourceSeedId") or "unassigned")
            unit = str(record.get("courseUnitId") or "unassigned")
            rows.append(
                {
                    "id": ident,
                    "level": level,
                    "ko": _required(record, ko_path, f"{draft_path}:{ident}"),
                    "de": _required(record, de_path, f"{draft_path}:{ident}"),
                    "en": _required(record, en_path, f"{draft_path}:{ident}"),
                    "field_notes": previous.get("field_notes")
                    or f"rights: original; clean-room seed {seed}; course {unit}; kind {kind}",
                    "상태": previous.get("상태") or "draft",
                    "jin_memo": previous.get("jin_memo") or "",
                }
            )
        if set(existing) - seen_ids:
            removed = ", ".join(sorted(set(existing) - seen_ids))
            raise ReviewSyncError(f"{review_path}: existing IDs disappeared from the draft: {removed}")
        outputs[review_path] = _csv_text(rows)
    return outputs


def apply_ledgers(outputs: dict[Path, str]) -> None:
    originals = {path: path.read_text(encoding="utf-8") if path.exists() else None for path in outputs}
    try:
        for path, content in outputs.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            temporary = path.with_name(f".{path.name}.review-sync.tmp")
            temporary.write_text(content, encoding="utf-8")
            os.replace(temporary, path)
    except Exception as error:
        for path, content in originals.items():
            if content is None:
                path.unlink(missing_ok=True)
            else:
                path.write_text(content, encoding="utf-8")
        raise ReviewSyncError(f"review ledger sync rolled back: {error}") from error


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", default=str(DEFAULT_MANIFEST))
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    try:
        outputs = build_ledgers(manifest_path=Path(args.manifest))
        if args.apply:
            apply_ledgers(outputs)
    except ReviewSyncError as error:
        print(f"ERROR: {error}")
        return 1
    action = "updated" if args.apply else "preview"
    rows = sum(content.count("\n") - 1 for content in outputs.values())
    print(f"OK: {action} {len(outputs)} review ledgers with {rows} rows")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
