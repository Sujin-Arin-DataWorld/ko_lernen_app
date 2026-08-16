#!/usr/bin/env python3
"""Atomically promote an approved scenario batch into learner-facing assets.

Scenarios are not a target-local append: the scenario data, curriculum graph,
audit inventory, and fallback backdrop map must move together. This tool stages
all four changes, validates the staged repository, then either writes every
output or restores the original bytes on failure.
"""

from __future__ import annotations

import argparse
import csv
from datetime import date
import json
import os
from pathlib import Path
import re
import shutil
import tempfile
from typing import Any

from validate_content import ContentValidator, LOWER_LEVELS


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MANIFEST = Path("tools/content_factory/drafts/batch_04_manifest.json")
REVIEW_HEADER = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]
APPROVED = frozenset(("approved", "ok"))
MANIFEST_STATUSES = frozenset(("review_only", "approved", "merged"))
SCENE_KEYS = frozenset(("airport", "cafe", "convenience", "directions", "home", "hotel", "market", "office", "pharmacy", "restaurant", "station", "taxi"))
ARTIFACTS = {
    "scenario": ("scenarios.json", "scenarios", (("title", "ko"), ("title", "de"), ("title", "en"))),
    "smalltalk": ("smalltalk.json", "phrases", (("ko",), ("de",), ("en",))),
    "cloze": ("cloze.json", "items", (("fullKo",), ("de",), ("en",))),
    "satz": ("satz_sentences.json", "items", (("targetKo",), ("promptDe",), ("promptEn",))),
    "pronunciation": ("pronunciation_phrases.json", "phrases", (("ko",), ("de",), ("en",))),
}


class ScenarioIntegrationError(ValueError):
    """Raised when an approved scenario batch cannot be promoted safely."""


def _under_root(root: Path, raw: str) -> Path:
    if not isinstance(raw, str) or not raw.strip():
        raise ScenarioIntegrationError("scenario-batch path must be a nonempty repository-relative string")
    path = (root / raw).resolve()
    try:
        path.relative_to(root.resolve())
    except ValueError as error:
        raise ScenarioIntegrationError(f"scenario-batch path escapes repository: {raw}") from error
    return path


def _read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ScenarioIntegrationError(f"cannot read {path}: {error}") from error
    if not isinstance(value, dict):
        raise ScenarioIntegrationError(f"{path}: root must be an object")
    return value


def _json_text(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2) + "\n"


def _read_review(path: Path) -> list[dict[str, str]]:
    try:
        with path.open(encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            if list(reader.fieldnames or []) != REVIEW_HEADER:
                raise ScenarioIntegrationError(f"{path}: review header must exactly match the common ledger schema")
            rows = list(reader)
    except (OSError, csv.Error) as error:
        raise ScenarioIntegrationError(f"cannot read {path}: {error}") from error
    if any(None in row for row in rows):
        raise ScenarioIntegrationError(f"{path}: malformed review CSV row")
    return rows


def _review_status_is_known(raw: str) -> bool:
    status = raw.strip().casefold()
    return status in APPROVED | {"draft", "no", "rejected"} or status.startswith("fix:")


def _project(record: dict[str, Any], path: tuple[str, ...], label: str) -> str:
    value: Any = record
    for key in path:
        if not isinstance(value, dict):
            raise ScenarioIntegrationError(f"{label}: cannot project {'.'.join(path)}")
        value = value.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ScenarioIntegrationError(f"{label}: {'.'.join(path)} must be a nonempty string")
    return value.strip()


def _validate_bundle(
    root: Path,
    relative_manifest: Path,
    *,
    require_approved: bool,
) -> tuple[
    Path,
    dict[str, Any],
    dict[str, list[dict[str, Any]]],
    dict[str, str],
]:
    manifest_path = _under_root(root, str(relative_manifest))
    manifest = _read_json(manifest_path)
    batch = manifest.get("batch")
    if manifest.get("version") != 1 or not isinstance(batch, str) or not re.fullmatch(r"\d{2,}", batch):
        raise ScenarioIntegrationError(f"{manifest_path}: expected a numeric batch manifest version 1")
    manifest_status = manifest.get("status")
    if manifest_status not in MANIFEST_STATUSES:
        raise ScenarioIntegrationError(f"{manifest_path}: unknown scenario manifest status")
    if require_approved and manifest_status not in {"approved", "merged"}:
        raise ScenarioIntegrationError(f"{manifest_path}: status must be approved before promotion")
    artifacts = manifest.get("artifacts")
    if not isinstance(artifacts, list) or not artifacts or any(not isinstance(item, dict) for item in artifacts):
        raise ScenarioIntegrationError(f"{manifest_path}: artifacts must be a nonempty array of objects")
    entries = {str(item.get("kind") or ""): item for item in artifacts}
    if len(entries) != len(artifacts) or "scenario" not in entries or not set(entries).issubset(ARTIFACTS):
        raise ScenarioIntegrationError(f"{manifest_path}: needs one scenario artifact and only supported companion games")

    records_by_kind: dict[str, list[dict[str, Any]]] = {}
    total = 0
    for kind, artifact in entries.items():
        _, collection, projections = ARTIFACTS[kind]
        if artifact.get("collection") not in (None, collection):
            raise ScenarioIntegrationError(f"{manifest_path}: {kind} collection disagrees with its schema")
        draft_path = _under_root(root, artifact.get("draft"))
        review_path = _under_root(root, artifact.get("review"))
        draft = _read_json(draft_path)
        records = draft.get(collection)
        if not isinstance(records, list) or not records or any(not isinstance(item, dict) for item in records):
            raise ScenarioIntegrationError(f"{draft_path}: {collection} must be a nonempty array of objects")
        if artifact.get("count") != len(records):
            raise ScenarioIntegrationError(f"{manifest_path}: {kind} record count disagrees with its draft")
        ids: list[str] = []
        levels: dict[str, int] = {}
        for record in records:
            ident = record.get("id")
            level = record.get("level")
            if not isinstance(ident, str) or not ident or not isinstance(level, str) or level not in LOWER_LEVELS:
                raise ScenarioIntegrationError(f"{draft_path}: every record needs an id and A1-C2 lowercase level")
            ids.append(ident)
            levels[level] = levels.get(level, 0) + 1
        if len(ids) != len(set(ids)):
            raise ScenarioIntegrationError(f"{draft_path}: duplicate {kind} ID")
        if artifact.get("levels") != levels:
            raise ScenarioIntegrationError(f"{manifest_path}: {kind} level counts disagree with draft")
        review_rows = _read_review(review_path)
        if len(review_rows) != len(records) or [row.get("id") for row in review_rows] != ids:
            raise ScenarioIntegrationError(f"{review_path}: IDs and order must exactly match draft")
        for record, row in zip(records, review_rows):
            ident = str(record["id"])
            if row.get("level") != str(record["level"]).upper():
                raise ScenarioIntegrationError(f"{review_path}: {ident} level disagrees with draft")
            for review_key, projection in zip(("ko", "de", "en"), projections):
                if row.get(review_key) != _project(record, projection, f"{draft_path}:{ident}"):
                    raise ScenarioIntegrationError(f"{review_path}: {ident} {review_key} disagrees with draft projection")
            review_status = (row.get("상태") or "").strip().casefold()
            if not _review_status_is_known(review_status):
                raise ScenarioIntegrationError(f"{review_path}: {ident} has an unknown review status")
            approval_required = require_approved or manifest_status in {"approved", "merged"}
            if approval_required and review_status not in APPROVED:
                raise ScenarioIntegrationError(f"{review_path}: {ident} is not approved")
        records_by_kind[kind] = records
        total += len(records)
    if manifest.get("recordCount") != total:
        raise ScenarioIntegrationError(f"{manifest_path}: recordCount disagrees with all artifact drafts")

    scenarios = records_by_kind["scenario"]
    scenario_ids = [str(record["id"]) for record in scenarios]
    quests = [
        quest
        for record in scenarios
        for quest in (record.get("quests") if isinstance(record.get("quests"), list) else [])
    ]
    if manifest.get("questCount") != len(quests):
        raise ScenarioIntegrationError(f"{manifest_path}: quest count disagrees with draft")
    quest_ids: list[str] = []
    for quest in quests:
        if not isinstance(quest, dict) or not isinstance(quest.get("id"), str) or not quest["id"].strip():
            raise ScenarioIntegrationError(f"{manifest_path}: counted quests need stable nonempty IDs")
        quest_ids.append(quest["id"])
    if len(quest_ids) != len(set(quest_ids)):
        raise ScenarioIntegrationError(f"{manifest_path}: duplicate scenario quest ID")

    links = manifest.get("contentLinks")
    if not isinstance(links, list) or len(links) != len(scenarios):
        raise ScenarioIntegrationError(f"{manifest_path}: needs one curriculum content link per scenario")
    link_ids = [item.get("contentId") for item in links if isinstance(item, dict)]
    if link_ids != scenario_ids:
        raise ScenarioIntegrationError(f"{manifest_path}: curriculum links must match scenario draft order")
    backdrops = manifest.get("backdrops")
    if not isinstance(backdrops, dict) or set(backdrops) != set(scenario_ids):
        raise ScenarioIntegrationError(f"{manifest_path}: backdrop map must cover every scenario exactly once")
    if any(value not in SCENE_KEYS for value in backdrops.values()):
        raise ScenarioIntegrationError(f"{manifest_path}: backdrop uses an unknown existing scene category")
    return manifest_path, manifest, records_by_kind, {key: str(value) for key, value in backdrops.items()}


def _validate_batch(
    root: Path,
    relative_manifest: Path,
    *,
    require_approved: bool,
) -> tuple[Path, dict[str, Any], list[dict[str, Any]], dict[str, str]]:
    manifest_path, manifest, records_by_kind, backdrops = _validate_bundle(
        root,
        relative_manifest,
        require_approved=require_approved,
    )
    return manifest_path, manifest, records_by_kind["scenario"], backdrops


def _update_backdrop_map(source: str, backdrops: dict[str, str], batch: str) -> str:
    for ident, category in backdrops.items():
        existing = f"    '{ident}':"
        if existing in source:
            if f"    '{ident}': '{category}'," not in source:
                raise ScenarioIntegrationError(f"scenario backdrop for {ident} conflicts with existing source")
    missing = [(ident, category) for ident, category in backdrops.items() if f"    '{ident}':" not in source]
    if not missing:
        return source
    anchor = "    // cafe"
    if anchor not in source:
        raise ScenarioIntegrationError("cannot locate ScenarioBackdrop insertion anchor")
    lines = [f"    // Reviewed scenario Batch {batch}. Existing backdrop pipeline only."]
    lines.extend(f"    '{ident}': '{category}'," for ident, category in missing)
    return source.replace(anchor, "\n".join(lines) + "\n" + anchor, 1)


def _atomic_write(path: Path, text: str) -> None:
    temporary = path.with_name(f".{path.name}.scenario-integration.tmp")
    try:
        temporary.write_text(text, encoding="utf-8")
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def _atomic_restore(path: Path, data: bytes) -> None:
    """Restore exact pre-transaction bytes, including Windows newlines."""

    temporary = path.with_name(f".{path.name}.scenario-integration.tmp")
    try:
        temporary.write_bytes(data)
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def _refresh_meta(root: dict[str, Any], collection: str) -> None:
    meta = root.get("meta")
    items = root.get(collection)
    if not isinstance(meta, dict) or not isinstance(items, list):
        return
    per_level = {level: 0 for level in LOWER_LEVELS}
    for item in items:
        if isinstance(item, dict) and item.get("level") in per_level:
            per_level[str(item["level"])] += 1
    meta["total"] = len(items)
    meta["perLevel"] = {
        level: per_level[level]
        for level in ("a1", "a2", "b1", "b2", "c1", "c2")
    }


def integrate(*, root: Path = ROOT, manifest_path: Path = DEFAULT_MANIFEST, apply: bool) -> tuple[dict[str, int], int]:
    root = root.resolve()
    manifest_path, manifest, records_by_kind, backdrops = _validate_bundle(
        root,
        manifest_path,
        require_approved=apply,
    )
    with tempfile.TemporaryDirectory(prefix="scenario-batch-integration-") as directory:
        stage = Path(directory) / "repo"
        shutil.copytree(root / "assets" / "data", stage / "assets" / "data")
        mirror_source = root / "functions" / "analyze_korean_text" / "grammar_patterns.json"
        mirror_target = stage / "functions" / "analyze_korean_text" / "grammar_patterns.json"
        mirror_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(mirror_source, mirror_target)
        data = stage / "assets" / "data"
        already_merged = False
        for kind, records in records_by_kind.items():
            target_name, collection, _ = ARTIFACTS[kind]
            target_path = data / target_name
            target_root = _read_json(target_path)
            live_records = target_root.get(collection)
            if not isinstance(live_records, list) or any(not isinstance(item, dict) for item in live_records):
                raise ScenarioIntegrationError(f"live {target_name} must contain an array of objects")
            live_by_id = {str(item.get("id") or ""): item for item in live_records}
            batch_ids = {str(item["id"]) for item in records}
            overlap = set(live_by_id) & batch_ids
            if overlap:
                if overlap != batch_ids or manifest.get("status") != "merged":
                    raise ScenarioIntegrationError(f"{kind} draft duplicates a live ID")
                if any(live_by_id[str(item["id"])] != item for item in records):
                    raise ScenarioIntegrationError(f"merged {kind} payload no longer matches its approved draft")
                already_merged = True
                continue
            if manifest.get("status") == "merged":
                raise ScenarioIntegrationError(f"merged manifest is missing live {kind} records")
            target_root[collection] = [*live_records, *records]
            _refresh_meta(target_root, collection)
            target_path.write_text(_json_text(target_root), encoding="utf-8")

        if already_merged:
            curriculum_live = _read_json(data / "curriculum_manifest.json").get("contentLinks")
            known_links = {
                (item.get("contentKind"), item.get("contentId"), item.get("courseUnitId"), item.get("role"))
                for item in curriculum_live or []
                if isinstance(item, dict)
            }
            required_links = {
                (item.get("contentKind"), item.get("contentId"), item.get("courseUnitId"), item.get("role"))
                for item in manifest["contentLinks"]
            }
            if not required_links.issubset(known_links):
                raise ScenarioIntegrationError("merged scenario batch is missing a curriculum link")
            backdrop_source = (root / "lib" / "models" / "scenario.dart").read_text(encoding="utf-8")
            if any(f"    '{ident}': '{category}'," not in backdrop_source for ident, category in backdrops.items()):
                raise ScenarioIntegrationError("merged scenario batch is missing a backdrop mapping")
            issues = ContentValidator(root).validate()
            if issues:
                detail = "\n".join(f"{issue.source}: {issue.message}" for issue in issues)
                raise ScenarioIntegrationError(f"merged scenario batch no longer validates:\n{detail}")
            return ContentValidator(root).inventory_counts(), int(manifest["recordCount"])

        curriculum = _read_json(data / "curriculum_manifest.json")
        links = curriculum.get("contentLinks")
        additions = manifest["contentLinks"]
        if not isinstance(links, list) or any(not isinstance(item, dict) for item in links):
            raise ScenarioIntegrationError("curriculum manifest contentLinks must be an array")
        known = {(item.get("contentKind"), item.get("contentId"), item.get("courseUnitId"), item.get("role")) for item in links}
        for link in additions:
            key = (link.get("contentKind"), link.get("contentId"), link.get("courseUnitId"), link.get("role"))
            if key in known:
                raise ScenarioIntegrationError(f"curriculum link already exists: {key}")
        curriculum["contentLinks"] = [*links, *additions]
        (data / "curriculum_manifest.json").write_text(_json_text(curriculum), encoding="utf-8")

        audit = _read_json(data / "content_audit_manifest.json")
        counts = ContentValidator(stage).inventory_counts()
        for source in audit.get("sources", []):
            if isinstance(source, dict) and source.get("kind") in counts:
                source["count"] = counts[source["kind"]]
        graph = audit.get("graph")
        course_units = curriculum.get("courseUnits")
        if not isinstance(graph, dict) or not isinstance(course_units, list):
            raise ScenarioIntegrationError(
                "content audit graph and curriculum courseUnits must be present"
            )
        graph["courseUnits"] = len(course_units)
        graph["courseUnitsByLevel"] = {
            level: sum(
                1
                for unit in course_units
                if isinstance(unit, dict)
                and str(unit.get("level", "")).strip().lower() == level
            )
            for level in ("a1", "a2", "b1", "b2", "c1", "c2")
        }
        (data / "content_audit_manifest.json").write_text(_json_text(audit), encoding="utf-8")
        issues = ContentValidator(stage).validate()
        if issues:
            detail = "\n".join(f"{issue.source}: {issue.message}" for issue in issues)
            raise ScenarioIntegrationError(f"staged content validation failed:\n{detail}")

        backdrop_file = root / "lib" / "models" / "scenario.dart"
        outputs = {
            root / "assets" / "data" / "curriculum_manifest.json": (data / "curriculum_manifest.json").read_text(encoding="utf-8"),
            root / "assets" / "data" / "content_audit_manifest.json": (data / "content_audit_manifest.json").read_text(encoding="utf-8"),
            backdrop_file: _update_backdrop_map(
                backdrop_file.read_text(encoding="utf-8"),
                backdrops,
                str(manifest["batch"]),
            ),
        }
        for kind in records_by_kind:
            target_name, _, _ = ARTIFACTS[kind]
            outputs[root / "assets" / "data" / target_name] = (data / target_name).read_text(
                encoding="utf-8"
            )
        if not apply:
            return counts, int(manifest["recordCount"])
        merged_manifest = dict(manifest)
        merged_manifest["status"] = "merged"
        provenance = dict(merged_manifest.get("provenance") or {})
        provenance["mergedAt"] = date.today().isoformat()
        merged_manifest["provenance"] = provenance
        outputs[manifest_path] = _json_text(merged_manifest)
        originals = {path: path.read_bytes() for path in outputs}
        try:
            for path, content in outputs.items():
                _atomic_write(path, content)
            final_issues = ContentValidator(root).validate()
            if final_issues:
                detail = "\n".join(f"{issue.source}: {issue.message}" for issue in final_issues)
                raise ScenarioIntegrationError(f"post-write content validation failed:\n{detail}")
        except Exception as error:
            rollback_errors: list[str] = []
            for path, data in originals.items():
                try:
                    _atomic_restore(path, data)
                except OSError as rollback_error:
                    rollback_errors.append(f"{path}: {rollback_error}")
            suffix = (
                f"; rollback failed: {'; '.join(rollback_errors)}"
                if rollback_errors
                else ""
            )
            raise ScenarioIntegrationError(
                f"scenario integration rolled back: {error}{suffix}"
            ) from error
    return counts, int(manifest["recordCount"])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", default=str(DEFAULT_MANIFEST), help="scenario batch manifest")
    parser.add_argument("--apply", action="store_true", help="write the staged scenario integration")
    args = parser.parse_args()
    try:
        counts, amount = integrate(manifest_path=Path(args.manifest), apply=args.apply)
    except ScenarioIntegrationError as error:
        print(f"ERROR: {error}")
        return 1
    print(f"OK: {'applied' if args.apply else 'preview'} {amount} records; inventory {counts}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
