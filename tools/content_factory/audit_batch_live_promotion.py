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
from collections import Counter
import csv
import hashlib
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


def _supplemental_live_records(root: Path) -> dict[str, tuple[str, list[dict[str, Any]]]]:
    data = root / "assets" / "data"
    silben = _read_json(data / "silben_puzzles.json")
    return {
        "mediaPhrase": (
            "id",
            _read_json(data / "media_phrases.json")["phrases"],
        ),
        "wordRelation": (
            "id",
            _read_json(data / "word_relations.json")["clusters"],
        ),
        "grammarPattern": (
            "id",
            _read_json(data / "grammar_patterns.json"),
        ),
        "kkeunmari": (
            "word",
            _read_json(data / "kkeunmari_pool.json")["words"],
        ),
        "silben": (
            "id",
            [
                puzzle
                for puzzles in silben["levels"].values()
                for puzzle in puzzles
            ],
        ),
        "cultureNote": (
            "ko",
            _read_json(data / "culture_notes.json")["notes"],
        ),
    }


def _projection_fingerprint(records: list[dict[str, Any]]) -> str:
    canonical = json.dumps(
        records,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(canonical).hexdigest()


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
    supplemental_live: dict[str, tuple[str, dict[str, dict[str, Any]]]] = {}
    for kind, (key_field, records) in _supplemental_live_records(root).items():
        index: dict[str, dict[str, Any]] = {}
        for record in records:
            key = str(record.get(key_field) or "").strip()
            if not key or key in index:
                errors.append(f"{kind}: blank or duplicate {key_field} {key!r}")
            else:
                index[key] = record
        supplemental_live[kind] = (key_field, index)

    curriculum = _read_json(root / "assets" / "data" / "curriculum_manifest.json")
    canonical_scenario_runtime = (
        curriculum.get("scenarioCorpusGeneration") == "canonical_120_v1"
    )
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
        retired_scenarios: list[str] = []
        projection: list[dict[str, Any]] = []
        review_statuses: Counter[str] = Counter()
        provenance = manifest.get("provenance")
        provenance = provenance if isinstance(provenance, dict) else {}
        approval = provenance.get("approval")
        structured_approval = (
            status == "merged"
            and isinstance(approval, dict)
            and str(approval.get("authority") or "").strip().casefold() == "jin"
        )
        legacy_promotion = bool(str(provenance.get("promotedAt") or "").strip())
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
            review_path = root / str(artifact.get("review") or "")
            if not review_path.is_file():
                manifest_errors.append(
                    f"{path.name}:{kind}: missing review ledger "
                    f"{review_path.relative_to(root).as_posix()}"
                )
            else:
                review_rows, review_errors = _read_csv(review_path)
                manifest_errors.extend(review_errors)
                review_index, review_duplicate_errors = _index_by_id(
                    f"{path.name}:{kind}:review", review_rows
                )
                manifest_errors.extend(review_duplicate_errors)
                if set(review_index) != set(draft_index):
                    manifest_errors.append(
                        f"{path.name}:{kind}: review IDs differ from draft IDs; "
                        f"missing={sorted(set(draft_index) - set(review_index))}, "
                        f"extra={sorted(set(review_index) - set(draft_index))}"
                    )
                review_statuses.update(
                    str(row.get("상태") or "blank").strip().casefold() or "blank"
                    for row in review_rows
                )
            tracked += len(draft_index)
            for ident in draft_index:
                live_record = live_indexes[kind].get(ident)
                if live_record is None:
                    if kind == "scenario" and canonical_scenario_runtime:
                        retired_scenarios.append(ident)
                        continue
                    missing.append(f"{kind}:{ident}")
                    continue
                present += 1
                projection.append({"kind": kind, "id": ident, "record": live_record})
                if kind == "scenario":
                    if not str(live_record.get("shelf") or "").strip():
                        manifest_errors.append(f"{path.name}:scenario:{ident}: missing live shelf")
                    if not str(live_record.get("backdrop") or "").strip():
                        manifest_errors.append(f"{path.name}:scenario:{ident}: missing live backdrop")
                    if ident not in scenario_links:
                        manifest_errors.append(f"{path.name}:scenario:{ident}: missing curriculum contentLink")

        core_tracked = tracked
        if manifest.get("recordCount") != core_tracked:
            manifest_errors.append(
                f"{path.name}: recordCount {manifest.get('recordCount')!r} != audited draft IDs {core_tracked}"
            )
        supplemental_tracked = 0
        supplemental_present = 0
        for artifact in manifest.get("supplementalArtifacts", []):
            kind = str(artifact.get("kind") or "")
            live_spec = supplemental_live.get(kind)
            if live_spec is None:
                manifest_errors.append(
                    f"{path.name}: unknown supplemental artifact kind {kind!r}"
                )
                continue
            expected_field, live_index = live_spec
            key_field = str(artifact.get("keyField") or "")
            keys = artifact.get("keys")
            if key_field != expected_field or not isinstance(keys, list):
                manifest_errors.append(
                    f"{path.name}:{kind}: invalid supplemental key contract"
                )
                continue
            normalized = [str(key).strip() for key in keys]
            if len(set(normalized)) != len(normalized) or any(not key for key in normalized):
                manifest_errors.append(
                    f"{path.name}:{kind}: blank or duplicate supplemental keys"
                )
            if artifact.get("count") != len(normalized):
                manifest_errors.append(
                    f"{path.name}:{kind}: supplemental count differs from keys"
                )
            supplemental_tracked += len(normalized)
            for key in normalized:
                if key in live_index:
                    supplemental_present += 1
                    projection.append({"kind": kind, "id": key, "record": live_index[key]})
                else:
                    missing.append(f"{kind}:{key}")
        if manifest.get("supplementalRecordCount", supplemental_tracked) != supplemental_tracked:
            manifest_errors.append(
                f"{path.name}: supplementalRecordCount differs from audited keys"
            )
        tracked += supplemental_tracked
        present += supplemental_present
        if structured_approval and any(
            review_status != "approved" for review_status in review_statuses
        ):
            manifest_errors.append(
                f"{path.name}: modern merged approval requires all review rows approved; "
                f"found {dict(sorted(review_statuses.items()))}"
            )
        if not structured_approval and not legacy_promotion:
            manifest_errors.append(
                f"{path.name}: live records lack structured Jin approval or legacy promotedAt evidence"
            )

        if missing:
            audit_status = "not_live"
        elif manifest_errors:
            audit_status = "invalid"
        elif retired_scenarios and structured_approval:
            audit_status = "lineage_verified_modern_retired_scenarios"
        elif retired_scenarios:
            audit_status = "lineage_verified_legacy_retired_scenarios"
        elif structured_approval:
            audit_status = "live_verified_modern"
        else:
            audit_status = "live_verified_legacy_authorized"
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
            "retiredScenarios": sorted(retired_scenarios),
            "errors": manifest_errors,
            "approvalEvidence": (
                "structured_jin_approval"
                if structured_approval
                else "legacy_promoted_at"
                if legacy_promotion
                else "missing"
            ),
            "reviewStatuses": dict(sorted(review_statuses.items())),
            "liveProjectionSha256": _projection_fingerprint(
                sorted(projection, key=lambda row: (row["kind"], row["id"]))
            ),
        })

    return {
        "version": 3,
        "scope": "all tools/content_factory/drafts/batch*manifest.json files",
        "trackedIds": tracked_total,
        "liveIds": live_total,
        "retiredScenarioIds": sum(
            len(report.get("retiredScenarios", [])) for report in reports
        ),
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
    parser.add_argument("--output", type=Path, help="write the full JSON audit ledger")
    args = parser.parse_args()
    result = audit()
    rendered = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        output = args.output if args.output.is_absolute() else ROOT / args.output
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(rendered, encoding="utf-8")
        print(f"OK: wrote batch live projection audit to {output}")
    elif args.json:
        print(rendered, end="")
    else:
        _print_human(result)
    return 1 if args.check and not result["ok"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
