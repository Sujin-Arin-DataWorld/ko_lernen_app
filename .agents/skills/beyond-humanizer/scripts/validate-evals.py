#!/usr/bin/env python3
"""Validate Beyond Humanizer evaluation cases and direction coverage."""

from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path
from typing import Any


SKILL_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_EVALS = SKILL_ROOT / "evals" / "evals.json"
SCHEMA_PATH = SKILL_ROOT / "evals" / "schema.json"


def load_json(path: Path) -> Any:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def validate(payload: Any, schema: Any) -> list[str]:
    errors: list[str] = []
    if not isinstance(payload, list) or not payload:
        return ["root must be a non-empty array"]
    if not isinstance(schema, dict):
        return ["schema must be an object"]

    item_schema = schema.get("items", {})
    required = item_schema.get("required", [])
    properties = item_schema.get("properties", {})
    allowed_directions = set(
        properties.get("directions", {}).get("items", {}).get("enum", [])
    )
    allowed_severities = set(
        properties.get("severity_if_failed", {}).get("enum", [])
    )
    list_fields = {
        "directions",
        "phenomena",
        "expected_behavior",
        "forbidden_implications",
        "accepted_variants",
        "unresolved_fields",
    }
    non_empty_lists = list_fields - {"unresolved_fields"}
    string_fields = {
        "id",
        "query",
        "severity_if_failed",
        "baseline_observation",
        "green_observation",
    }

    seen_ids: Counter[str] = Counter()
    observed_directions: set[str] = set()

    for index, item in enumerate(payload):
        label = f"case[{index}]"
        if not isinstance(item, dict):
            errors.append(f"{label}: must be an object")
            continue

        missing = [field for field in required if field not in item]
        if missing:
            errors.append(f"{label}: missing required fields: {', '.join(missing)}")

        for field in string_fields:
            if field in item and (
                not isinstance(item[field], str) or not item[field].strip()
            ):
                errors.append(f"{label}.{field}: must be a non-empty string")

        for field in list_fields:
            if field not in item:
                continue
            value = item[field]
            if not isinstance(value, list):
                errors.append(f"{label}.{field}: must be an array")
                continue
            if field in non_empty_lists and not value:
                errors.append(f"{label}.{field}: must not be empty")
            if any(not isinstance(entry, str) or not entry.strip() for entry in value):
                errors.append(f"{label}.{field}: entries must be non-empty strings")
            string_entries = [entry for entry in value if isinstance(entry, str)]
            if len(string_entries) != len(set(string_entries)):
                errors.append(f"{label}.{field}: duplicate entries are not allowed")

        case_id = item.get("id")
        if isinstance(case_id, str) and case_id.strip():
            seen_ids[case_id] += 1

        directions = item.get("directions")
        if isinstance(directions, list):
            for direction in directions:
                if not isinstance(direction, str):
                    continue
                if direction not in allowed_directions:
                    errors.append(f"{label}.directions: unsupported direction {direction!r}")
                else:
                    observed_directions.add(direction)

        severity = item.get("severity_if_failed")
        if severity is not None and severity not in allowed_severities:
            errors.append(f"{label}.severity_if_failed: unsupported severity {severity!r}")

    for case_id, count in seen_ids.items():
        if count > 1:
            errors.append(f"duplicate id: {case_id}")

    missing_directions = sorted(allowed_directions - observed_directions)
    if missing_directions:
        errors.append(f"missing directions: {', '.join(missing_directions)}")

    return errors


def main(argv: list[str]) -> int:
    evals_path = Path(argv[1]) if len(argv) > 1 else DEFAULT_EVALS
    try:
        schema = load_json(SCHEMA_PATH)
        payload = load_json(evals_path)
    except (OSError, json.JSONDecodeError) as error:
        print(f"evals: invalid: {error}")
        return 1

    errors = validate(payload, schema)
    if errors:
        print("evals: invalid")
        for error in errors:
            print(f"- {error}")
        return 1

    directions = sorted(
        {direction for item in payload for direction in item["directions"]}
    )
    print(f"evals: valid ({len(payload)} cases; directions: {', '.join(directions)})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
