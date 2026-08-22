#!/usr/bin/env python3
"""Audit every content Batch manifest against learner-facing app assets.

The manifest status is historical metadata, not sufficient proof of promotion.
This audit follows stable record IDs into the live assets and verifies that
scenario records also have their shelf, backdrop and curriculum link.  Index
and superseded manifests are reported but intentionally excluded from the live
gate.
"""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
import sys
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import scenario_store


ROOT = SCRIPT_DIR.parents[1]
MANIFEST_GLOB = "batch*manifest.json"
COLLECTION_BY_KIND = {
    "scenario": "scenarios",
    "smalltalk": "phrases",
    "cloze": "items",
    "satz": "items",
    "pronunciation": "phrases",
}
LIVE_JSON_BY_KIND = {
    "smalltalk": "smalltalk.json",
    "cloze": "cloze.json",
    "satz": "satz_sentences.json",
    "pronunciation": "pronunciation_phrases.json",
}
LIVE_CSV_BY_KIND = {
    "vocab": "korean_vocab.csv",
    "grammar": "grammar.csv",
}
SKIP_STATUSES = {"index", "superseded"}


class BatchAuditError(ValueError):
    """Raised when a Batch lineage file cannot be audited safely."""


def _read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _read_csv(path: Path) -> tuple[list[dict[str, str]], list[str]]:
    errors: list[str] = []
    with path.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        rows = []
        for line_number, row in enumerate(reader, start=2):
            if None in row:
                errors.append(f"{path.as_posix()}:{line_number}: extra unquoted CSV fields")
            rows.append({str(key): str(value or "") for key, value in row.items() if key is not None})
    return rows, errors


def _draft_records(root: Path, artifact: dict[str, Any]) -> tuple[list[dict[str, Any]], list[str]]:
    path = root / str(artifact.get("draft") or "")
    if not path.is_file():
        return [], [f"missing draft: {path.relative_to(root).as_posix()}"]
    if path.suffix.casefold() == ".csv":
        rows, errors = _read_csv(path)
        return list(rows), errors
    payload = _read_json(path)
    collection = artifact.get("collection") or COLLECTION_BY_KIND.get(str(artifact.get("kind") or ""))
    records = payload.get(collection) if isinstance(payload, dict) and collection else None
    if not isinstance(records, list) or any(not isinstance(record, dict) for record in records):
        return [], [f"{path.relative_to(root).as_posix()}: invalid or unknown collection {collection!r}"]
    return records, []


def _live_records(root: Path) -> dict[str, list[dict[str, Any]]]:
    data = root / "assets" / "data"
    result: dict[str, list[dict[str, Any]]] = {
        "scenario": scenario_store.load_scenarios(data),
    }
    for kind, filename in LIVE_CSV_BY_KIND.items():
        rows, errors = _read_csv(data / filename)
        if errors:
            raise BatchAuditError("\n".join(errors))
        result[kind] = rows
    for kind, filename in LIVE_JSON_BY_KIND.items():
        payload = _read_json(data / filename)
        collection = COLLECTION_BY_KIND[kind]
        records = payload.get(collection) if isinstance(payload, dict) else None
        if not isinstance(records, list) or any(not isinstance(record, dict) for record in records):
            raise BatchAuditError(f"assets/data/{filename}: invalid {collection} collection")
        result[kind] = records
    return result


def _index_by_id(kind: str, records: list[dict[str, Any]]) -> tuple[dict[str, dict[str, Any]], list[str]]:
    index: dict[str, dict[str, Any]] = {}
    duplicates: list[str] = []
    for record in records:
        ident = str(record.get("id") or "").strip()
        if not ident:
            duplicates.append(f"{kind}: blank ID")
        elif ident in index:
            duplicates.append(f"{kind}: duplicate ID {ident}")
        else:
            index[ident] = record
    return index, duplicates


def audit(root: Path = ROOT) -> dict[str, Any]:
    root = root.resolve()
    live = _live_records(root)
    live_indexes: dict[str, dict[str, dict[str, Any]]] = {}
    errors: list[str] = []
    for kind, records in live.items():
        live_indexes[kind], duplicate_errors = _index_by_id(kind, records)
        errors.extend(duplicate_errors)

    curriculum = _read_json(root / "assets" / "data" / "curriculum_manifest.json")
    scenario_links = {
        str(link.get("contentId") or "")
        for link in curriculum.get("contentLinks", [])
        if isinstance(link, dict) and link.get("contentKind") == "scenario"
    }

    reports: list[dict[str, Any]] = []
    tracked_total = 0
    live_total = 0
    drafts = root / "tools" / "content_factory" / "drafts"
    for path in sorted(drafts.glob(MANIFEST_GLOB), key=lambda item: item.name):
        manifest = _read_json(path)
        status = str(manifest.get("status") or "unknown")
        if status in SKIP_STATUSES:
            reports.append({
                "manifest": path.name,
                "batch": str(manifest.get("batch") or ""),
                "manifestStatus": status,
                "auditStatus": status,
                "tracked": 0,
                "live": 0,
                "missing": [],
                "errors": [],
            })
            continue

        manifest_errors: list[str] = []
        missing: list[str] = []
        tracked = 0
        present = 0
        for artifact in manifest.get("artifacts", []):
            kind = str(artifact.get("kind") or "")
            if kind not in live_indexes:
                manifest_errors.append(f"{path.name}: unknown active artifact kind {kind!r}")
                continue
            records, draft_errors = _draft_records(root, artifact)
            manifest_errors.extend(draft_errors)
            expected_count = artifact.get("count")
            if expected_count != len(records):
                manifest_errors.append(
                    f"{path.name}:{kind}: manifest count {expected_count!r} != draft count {len(records)}"
                )
            draft_index, duplicate_errors = _index_by_id(f"{path.name}:{kind}", records)
            manifest_errors.extend(duplicate_errors)
            tracked += len(draft_index)
            for ident in draft_index:
                live_record = live_indexes[kind].get(ident)
                if live_record is None:
                    missing.append(f"{kind}:{ident}")
                    continue
                present += 1
                if kind == "scenario":
                    if not str(live_record.get("shelf") or "").strip():
                        manifest_errors.append(f"{path.name}:scenario:{ident}: missing live shelf")
                    if not str(live_record.get("backdrop") or "").strip():
                        manifest_errors.append(f"{path.name}:scenario:{ident}: missing live backdrop")
                    if ident not in scenario_links:
                        manifest_errors.append(f"{path.name}:scenario:{ident}: missing curriculum contentLink")

        if manifest.get("recordCount") != tracked:
            manifest_errors.append(
                f"{path.name}: recordCount {manifest.get('recordCount')!r} != audited draft IDs {tracked}"
            )
        if missing:
            audit_status = "not_live"
        elif manifest_errors:
            audit_status = "invalid"
        elif status == "review_only_draft":
            audit_status = "live_verified_status_stale"
        else:
            audit_status = "live_verified"
        tracked_total += tracked
        live_total += present
        errors.extend(manifest_errors)
        errors.extend(f"{path.name}: missing {item}" for item in missing)
        reports.append({
            "manifest": path.name,
            "batch": str(manifest.get("batch") or ""),
            "manifestStatus": status,
            "auditStatus": audit_status,
            "tracked": tracked,
            "live": present,
            "missing": missing,
            "errors": manifest_errors,
        })

    return {
        "version": 1,
        "scope": "all tools/content_factory/drafts/batch*manifest.json files",
        "trackedIds": tracked_total,
        "liveIds": live_total,
        "reports": reports,
        "errors": errors,
        "ok": not errors,
    }


def _print_human(result: dict[str, Any]) -> None:
    for report in result["reports"]:
        print(
            f"{report['manifest']}: {report['auditStatus']} "
            f"({report['live']}/{report['tracked']} live; manifest={report['manifestStatus']})"
        )
    print(f"TOTAL: {result['liveIds']}/{result['trackedIds']} tracked IDs live")
    if result["errors"]:
        print("ERRORS:")
        for error in result["errors"]:
            print(f"- {error}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    parser.add_argument("--check", action="store_true", help="return nonzero on any active gap")
    args = parser.parse_args()
    result = audit()
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        _print_human(result)
    return 1 if args.check and not result["ok"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
