#!/usr/bin/env python3
"""Inventory the productive-assessment draft without granting runtime evidence."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


LEVELS = ("A1", "A2", "B1", "B2", "C1", "C2")
SOURCE_RELATIVE_PATH = Path("tools") / "content_factory" / "drafts" / "productive_assessments.json"
KINDS = ("definition", "project", "source_snippet")


def _error(message: str) -> ValueError:
    return ValueError(f"productive assessment draft: {message}")


def _string(value: Any, where: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise _error(f"{where} must be a non-empty string")
    return value


def _list(value: Any, where: str) -> list[Any]:
    if not isinstance(value, list):
        raise _error(f"{where} must be an array")
    return value


def _level(record: dict[str, Any], where: str) -> str | None:
    value = record.get("level")
    if value is None:
        return None
    if not isinstance(value, str) or value.upper() not in LEVELS:
        raise _error(f"{where}.level must be one of {', '.join(LEVELS)}")
    return value.upper()


def _ids(value: Any, where: str) -> list[str]:
    values = _list(value, where)
    result = []
    for index, item in enumerate(values):
        result.append(_string(item, f"{where}[{index}]"))
    return result


def _check_records(data: dict[str, Any], key: str, id_field: str) -> list[dict[str, Any]]:
    records = _list(data.get(key), key)
    seen: set[str] = set()
    for index, record in enumerate(records):
        where = f"/{key}/{index}"
        if not isinstance(record, dict):
            raise _error(f"{where} must be an object")
        record_id = _string(record.get(id_field), f"{where}/{id_field}")
        if record_id in seen:
            raise _error(f"duplicate {key} {id_field}: {record_id}")
        seen.add(record_id)
        _level(record, where)
    return records


def _source_ids(value: Any, where: str) -> list[str]:
    """Collect authored source IDs from the known rubric reference fields."""
    result: list[str] = []

    def add(values: Any, path: str) -> None:
        for item in _ids(values, path):
            if item not in result:
                result.append(item)

    if "requiredSourceSnippetIds" in value:
        add(value["requiredSourceSnippetIds"], f"{where}/requiredSourceSnippetIds")
    groups = value.get("oneOfSourceGroups", [])
    if not isinstance(groups, list):
        raise _error(f"{where}/oneOfSourceGroups must be an array")
    for index, group in enumerate(groups):
        add(group, f"{where}/oneOfSourceGroups/{index}")
    relationship_requirements = value.get("relationshipRequirements", [])
    if not isinstance(relationship_requirements, list):
        raise _error(f"{where}/relationshipRequirements must be an array")
    for index, requirement in enumerate(relationship_requirements):
        requirement_where = f"{where}/relationshipRequirements/{index}"
        if not isinstance(requirement, dict):
            raise _error(f"{requirement_where} must be an object")
        if "oneOfSourceSnippetIds" in requirement:
            add(
                requirement["oneOfSourceSnippetIds"],
                f"{requirement_where}/oneOfSourceSnippetIds",
            )
    variants = value.get("sourceMentionVariants", {})
    if not isinstance(variants, dict):
        raise _error(f"{where}/sourceMentionVariants must be an object")
    for source_id in variants:
        _string(source_id, f"{where}/sourceMentionVariants key")
        if source_id not in result:
            result.append(source_id)
    return result


def _record(
    *,
    kind: str,
    record_id: str,
    level: str | None,
    index: int,
    source_relative_path: str,
    grammar_ids: list[str] | None = None,
    source_ids: list[str] | None = None,
    examples: list[str] | None = None,
    source_korean_text: str | None = None,
) -> dict[str, Any]:
    result: dict[str, Any] = {
        "kind": kind,
        "id": record_id,
        "level": level,
        "reviewState": "draft_only",
        "runtimeLinked": False,
        "assessable": False,
        "source": {
            "path": source_relative_path,
            "recordIndex": index,
            "jsonPointer": f"/{ {'definition': 'definitions', 'project': 'projects', 'source_snippet': 'sourceSnippets'}[kind] }/{index}",
        },
        "grammarReferenceIds": sorted(grammar_ids or []),
        "sourceSnippetIds": sorted(source_ids or []),
    }
    if examples:
        result["authoredContextExamples"] = list(examples)
    if source_korean_text is not None:
        result["sourceKoreanText"] = source_korean_text
    return result


def build_inventory(root: Path) -> dict[str, Any]:
    """Return a deterministic, draft-only inventory rooted at ``root``."""
    root = Path(root)
    try:
        root_resolved = root.resolve(strict=True)
    except OSError as exc:
        raise _error(f"root is not readable: {root}") from exc
    input_path = root / SOURCE_RELATIVE_PATH
    try:
        resolved_input = input_path.resolve(strict=True)
        resolved_input.relative_to(root_resolved)
    except (OSError, ValueError) as exc:
        raise _error(f"input is missing or escapes root: {SOURCE_RELATIVE_PATH}") from exc

    try:
        data = json.loads(resolved_input.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise _error(f"cannot read valid JSON from {SOURCE_RELATIVE_PATH}") from exc
    if not isinstance(data, dict):
        raise _error("top level must be an object")
    if not isinstance(data.get("schemaVersion"), int) or isinstance(data["schemaVersion"], bool):
        raise _error("/schemaVersion must be an integer")
    if data["schemaVersion"] != 1:
        raise _error("/schemaVersion must be 1")

    definitions = _check_records(data, "definitions", "assessmentItemId")
    projects = _check_records(data, "projects", "id")
    snippets = _check_records(data, "sourceSnippets", "id")
    relative_path = SOURCE_RELATIVE_PATH.as_posix()
    records: list[dict[str, Any]] = []

    for index, definition in enumerate(definitions):
        rubric = definition.get("textRubric")
        if rubric is None:
            rubric = definition.get("connectedEvidenceRubric")
        if rubric is not None and not isinstance(rubric, dict):
            raise _error(f"/definitions/{index}/rubric must be an object")
        examples = definition.get("authoredContextExamples", [])
        if not isinstance(examples, list) or any(
            not isinstance(item, str) or not item.strip() for item in examples
        ):
            raise _error(f"/definitions/{index}/authoredContextExamples must contain non-empty strings")
        records.append(
            _record(
                kind="definition",
                record_id=definition["assessmentItemId"],
                level=_level(definition, f"/definitions/{index}"),
                index=index,
                source_relative_path=relative_path,
                grammar_ids=_ids(definition.get("grammarReferenceIds", []), f"/definitions/{index}/grammarReferenceIds"),
                source_ids=_source_ids(rubric or {}, f"/definitions/{index}/rubric"),
                examples=examples,
            )
        )

    for index, project in enumerate(projects):
        steps = _list(project.get("steps"), f"/projects/{index}/steps")
        source_ids: list[str] = []
        for step_index, step in enumerate(steps):
            if not isinstance(step, dict):
                raise _error(f"/projects/{index}/steps/{step_index} must be an object")
            for source_id in _ids(step.get("snippetIds", []), f"/projects/{index}/steps/{step_index}/snippetIds"):
                if source_id not in source_ids:
                    source_ids.append(source_id)
        records.append(
            _record(
                kind="project",
                record_id=project["id"],
                level=_level(project, f"/projects/{index}"),
                index=index,
                source_relative_path=relative_path,
                source_ids=source_ids,
            )
        )

    for index, snippet in enumerate(snippets):
        text = snippet.get("text")
        if not isinstance(text, dict):
            raise _error(f"/sourceSnippets/{index}/text must be an object")
        source_text = text.get("ko")
        if not isinstance(source_text, str) or not source_text.strip():
            raise _error(f"/sourceSnippets/{index}/text/ko must be a non-empty string")
        records.append(
            _record(
                kind="source_snippet",
                record_id=snippet["id"],
                level=_level(snippet, f"/sourceSnippets/{index}"),
                index=index,
                source_relative_path=relative_path,
                source_korean_text=source_text,
            )
        )

    by_kind = {kind: sum(record["kind"] == kind for record in records) for kind in KINDS}
    by_level = {
        level: {
            kind: sum(record["kind"] == kind and record["level"] == level for record in records)
            for kind in KINDS
        }
        for level in LEVELS
    }
    unassigned = {kind: sum(record["kind"] == kind and record["level"] is None for record in records) for kind in KINDS}
    declared_approved = data.get("runtimeContentApproved", False)
    if not isinstance(declared_approved, bool):
        raise _error("/runtimeContentApproved must be a boolean when present")
    warnings = ["declared runtimeContentApproved=true is ignored for draft evidence"] if declared_approved else []
    return {
        "metadata": {
            "sourcePath": relative_path,
            "schemaVersion": data["schemaVersion"],
            "declaredRuntimeContentApproved": declared_approved,
            "warnings": warnings,
        },
        "counts": {
            "definitions": by_kind["definition"],
            "projects": by_kind["project"],
            "sourceSnippets": by_kind["source_snippet"],
            "total": len(records),
            "byKind": by_kind,
            "byLevel": by_level,
            "unassigned": unassigned,
            "published": 0,
            "assessable": 0,
        },
        "records": sorted(records, key=lambda item: (item["kind"], item["id"])),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd(), help="repository root containing the draft")
    args = parser.parse_args()
    print(json.dumps(build_inventory(args.root), ensure_ascii=False, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
