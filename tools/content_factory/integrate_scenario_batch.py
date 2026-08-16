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


def _validate_batch(
    root: Path,
    relative_manifest: Path,
    *,
    require_approved: bool,
) -> tuple[Path, dict[str, Any], list[dict[str, Any]], dict[str, str]]:
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
    if not isinstance(artifacts, list) or len(artifacts) != 1 or not isinstance(artifacts[0], dict):
        raise ScenarioIntegrationError(f"{manifest_path}: needs exactly one scenario artifact")
    artifact = artifacts[0]
    if artifact.get("kind") != "scenario":
        raise ScenarioIntegrationError(f"{manifest_path}: artifact kind must be scenario")
    draft_path = _under_root(root, artifact.get("draft"))
    review_path = _under_root(root, artifact.get("review"))
    draft = _read_json(draft_path)
    records = draft.get("scenarios")
    if not isinstance(records, list) or not records or any(not isinstance(item, dict) for item in records):
        raise ScenarioIntegrationError(f"{draft_path}: scenarios must be a nonempty array of objects")
    if artifact.get("count") != len(records) or manifest.get("recordCount") != len(records):
        raise ScenarioIntegrationError(f"{manifest_path}: scenario record count disagrees with its draft")
    levels: dict[str, int] = {}
    ids: list[str] = []
    for record in records:
        ident = record.get("id")
        level = record.get("level")
        if not isinstance(ident, str) or not ident or not isinstance(level, str) or level not in LOWER_LEVELS:
            raise ScenarioIntegrationError(f"{draft_path}: every record needs an id and A1-C2 lowercase level")
        ids.append(ident)
        levels[level] = levels.get(level, 0) + 1
    if len(ids) != len(set(ids)):
        raise ScenarioIntegrationError(f"{draft_path}: duplicate scenario ID")
    if artifact.get("levels") != levels:
        raise ScenarioIntegrationError(f"{manifest_path}: scenario level counts disagree with draft")
    if "questCount" in manifest:
        quests = [
            quest
            for record in records
            for quest in (record.get("quests") if isinstance(record.get("quests"), list) else [])
        ]
        if manifest.get("questCount") != len(quests):
            raise ScenarioIntegrationError(f"{manifest_path}: quest count disagrees with draft")
        quest_ids: list[str] = []
        for quest in quests:
            if not isinstance(quest, dict) or not isinstance(quest.get("id"), str) or not quest["id"].strip():
                raise ScenarioIntegrationError(f"{draft_path}: counted quests need stable nonempty IDs")
            quest_ids.append(quest["id"])
        if len(quest_ids) != len(set(quest_ids)):
            raise ScenarioIntegrationError(f"{draft_path}: duplicate scenario quest ID")

    review_rows = _read_review(review_path)
    if len(review_rows) != len(records):
        raise ScenarioIntegrationError(f"{review_path}: row count must match draft")
    if [row.get("id") for row in review_rows] != ids:
        raise ScenarioIntegrationError(f"{review_path}: IDs must exactly match draft order")
    for record, row in zip(records, review_rows):
        title = record.get("title")
        if not isinstance(title, dict):
            raise ScenarioIntegrationError(f"{draft_path}: {record['id']} title must be localized")
        if row.get("level") != record["level"].upper():
            raise ScenarioIntegrationError(f"{review_path}: {record['id']} level disagrees with draft")
        for key in ("ko", "de", "en"):
            if row.get(key) != title.get(key):
                raise ScenarioIntegrationError(f"{review_path}: {record['id']} {key} disagrees with title projection")
        review_status = (row.get("상태") or "").strip().casefold()
        if not _review_status_is_known(review_status):
            raise ScenarioIntegrationError(f"{review_path}: {record['id']} has an unknown review status")
        approval_required = require_approved or manifest_status in {"approved", "merged"}
        if approval_required and review_status not in APPROVED:
            raise ScenarioIntegrationError(f"{review_path}: {record['id']} is not approved")

    links = manifest.get("contentLinks")
    if not isinstance(links, list) or len(links) != len(records):
        raise ScenarioIntegrationError(f"{manifest_path}: needs one curriculum content link per scenario")
    link_ids = [item.get("contentId") for item in links if isinstance(item, dict)]
    if link_ids != ids:
        raise ScenarioIntegrationError(f"{manifest_path}: curriculum links must match scenario draft order")
    backdrops = manifest.get("backdrops")
    if not isinstance(backdrops, dict) or set(backdrops) != set(ids):
        raise ScenarioIntegrationError(f"{manifest_path}: backdrop map must cover every scenario exactly once")
    if any(value not in SCENE_KEYS for value in backdrops.values()):
        raise ScenarioIntegrationError(f"{manifest_path}: backdrop uses an unknown existing scene category")
    return manifest_path, manifest, records, {key: str(value) for key, value in backdrops.items()}


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


def integrate(*, root: Path = ROOT, manifest_path: Path = DEFAULT_MANIFEST, apply: bool) -> tuple[dict[str, int], int]:
    root = root.resolve()
    manifest_path, manifest, records, backdrops = _validate_batch(
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
        scenarios_root = _read_json(data / "scenarios.json")
        scenarios = scenarios_root.get("scenarios")
        if not isinstance(scenarios, list) or any(not isinstance(item, dict) for item in scenarios):
            raise ScenarioIntegrationError("live scenarios.json must contain an array of objects")
        live_ids = {str(item.get("id") or "") for item in scenarios}
        batch_ids = {str(item["id"]) for item in records}
        overlap = live_ids & batch_ids
        if overlap:
            if overlap != batch_ids or manifest.get("status") != "merged":
                raise ScenarioIntegrationError("scenario draft duplicates a live scenario ID")
            live_by_id = {str(item["id"]): item for item in scenarios}
            if any(live_by_id[str(item["id"])] != item for item in records):
                raise ScenarioIntegrationError("merged scenario payload no longer matches its approved draft")
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
            return ContentValidator(root).inventory_counts(), len(records)
        scenarios_root["scenarios"] = [*scenarios, *records]
        (data / "scenarios.json").write_text(_json_text(scenarios_root), encoding="utf-8")

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
        (data / "content_audit_manifest.json").write_text(_json_text(audit), encoding="utf-8")
        issues = ContentValidator(stage).validate()
        if issues:
            detail = "\n".join(f"{issue.source}: {issue.message}" for issue in issues)
            raise ScenarioIntegrationError(f"staged content validation failed:\n{detail}")

        backdrop_file = root / "lib" / "models" / "scenario.dart"
        outputs = {
            root / "assets" / "data" / "scenarios.json": (data / "scenarios.json").read_text(encoding="utf-8"),
            root / "assets" / "data" / "curriculum_manifest.json": (data / "curriculum_manifest.json").read_text(encoding="utf-8"),
            root / "assets" / "data" / "content_audit_manifest.json": (data / "content_audit_manifest.json").read_text(encoding="utf-8"),
            backdrop_file: _update_backdrop_map(
                backdrop_file.read_text(encoding="utf-8"),
                backdrops,
                str(manifest["batch"]),
            ),
        }
        if not apply:
            return counts, len(records)
        merged_manifest = dict(manifest)
        merged_manifest["status"] = "merged"
        provenance = dict(merged_manifest.get("provenance") or {})
        provenance["mergedAt"] = date.today().isoformat()
        merged_manifest["provenance"] = provenance
        outputs[manifest_path] = _json_text(merged_manifest)
        originals = {path: path.read_text(encoding="utf-8") for path in outputs}
        try:
            for path, content in outputs.items():
                _atomic_write(path, content)
            final_issues = ContentValidator(root).validate()
            if final_issues:
                detail = "\n".join(f"{issue.source}: {issue.message}" for issue in final_issues)
                raise ScenarioIntegrationError(f"post-write content validation failed:\n{detail}")
        except Exception as error:
            for path, content in originals.items():
                _atomic_write(path, content)
            raise ScenarioIntegrationError(f"scenario integration rolled back: {error}") from error
    return counts, len(records)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", default=str(DEFAULT_MANIFEST), help="scenario batch manifest")
    parser.add_argument("--apply", action="store_true", help="write the staged scenario integration")
    args = parser.parse_args()
    try:
        counts, amount = integrate(manifest_path=Path(args.manifest), apply=args.apply)
    except ScenarioIntegrationError as error:
        print(f"✗ {error}")
        return 1
    print(f"✓ {'applied' if args.apply else 'preview'}: {amount} scenarios; inventory {counts}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
