#!/usr/bin/env python3
"""Promote or verify the reviewed Theme Park Date pack in live assets."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import scenario_store


ROOT = Path(__file__).resolve().parents[2]
LEVELS = ("a1", "a2", "b1", "b2", "c1", "c2")
SMALLTALK_DRAFT = Path(
    "tools/content_factory/drafts/theme_park_date_smalltalk_v1.json"
)
SCENARIO_DRAFT = Path(
    "tools/content_factory/drafts/theme_park_date_scenarios_v1.json"
)
MAPPINGS = {
    "a1": ("a1_11_titles_relationships", "concept_a1_titles_relationships"),
    "a2": ("a2_03_chat_relationships", "concept_a2_relationships"),
    "b1": ("b1_04_relationships", "concept_b1_relationships"),
    "b2": ("b2_03_precise_requests", "concept_b2_precise_requests"),
    "c1": ("c1_06_intimacy_safety_design", "concept_c1_intimacy_safety"),
    "c2": ("c2_05_relationship_narratives", "concept_c2_relationship_narratives"),
}


class PromotionError(ValueError):
    pass


def _json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _write(path: Path, payload: Any) -> None:
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")


def _merge_rows(
    existing: list[dict[str, Any]],
    incoming: list[dict[str, Any]],
    *,
    label: str,
    check: bool,
) -> list[dict[str, Any]]:
    by_id = {str(row.get("id") or ""): row for row in existing}
    positions = {
        str(row.get("id") or ""): index for index, row in enumerate(existing)
    }
    result = list(existing)
    for row in incoming:
        ident = str(row.get("id") or "")
        current = by_id.get(ident)
        if current is None:
            if check:
                raise PromotionError(f"{label} {ident!r} is missing from live assets")
            result.append(row)
            by_id[ident] = row
            positions[ident] = len(result) - 1
        elif current != row:
            if check:
                raise PromotionError(
                    f"{label} {ident!r} differs from the reviewed draft"
                )
            result[positions[ident]] = row
            by_id[ident] = row
    return result


def _merge_scenario_links(
    existing: list[dict[str, Any]],
    scenarios: list[dict[str, Any]],
    *,
    check: bool,
) -> list[dict[str, Any]]:
    result = list(existing)
    for scenario in scenarios:
        ident = str(scenario.get("id") or "")
        expected = {
            "contentKind": "scenario",
            "contentId": ident,
            "courseUnitId": scenario["courseUnitId"],
            "conceptIds": list(scenario["conceptIds"]),
            "role": "practice",
        }
        matches = [
            link
            for link in result
            if link.get("contentKind") == "scenario"
            and str(link.get("contentId") or "") == ident
        ]
        if not matches:
            if check:
                raise PromotionError(
                    f"curriculum contentLink for scenario {ident!r} is missing"
                )
            result.append(expected)
        elif matches != [expected]:
            raise PromotionError(
                f"curriculum contentLink for scenario {ident!r} differs"
            )
    return result


def promote(root: Path, *, check: bool) -> dict[str, int]:
    data = root / "assets" / "data"
    smalltalk_draft = _json(root / SMALLTALK_DRAFT)
    scenario_draft = _json(root / SCENARIO_DRAFT)
    incoming_scenarios = list(scenario_draft["scenarios"])

    smalltalk_path = data / "smalltalk.json"
    smalltalk = _json(smalltalk_path)
    category = smalltalk_draft["category"]
    categories = list(smalltalk.get("categories") or [])
    current_category = next(
        (row for row in categories if row.get("id") == category["id"]),
        None,
    )
    if current_category is None:
        if check:
            raise PromotionError("theme_park_date category is missing")
        categories.append(category)
    elif current_category != category:
        raise PromotionError("theme_park_date category differs from reviewed draft")
    existing_phrases = list(smalltalk.get("phrases") or [])
    # Clean up IDs from the pre-promotion draft format if an interrupted local
    # run wrote them before the canonical numeric smalltalk IDs were assigned.
    if not check:
        existing_phrases = [
            row
            for row in existing_phrases
            if not str(row.get("id") or "").startswith("theme_park_date_")
        ]
    phrases = _merge_rows(
        existing_phrases,
        list(smalltalk_draft["phrases"]),
        label="smalltalk",
        check=check,
    )
    smalltalk["categories"] = categories
    smalltalk["phrases"] = phrases

    curriculum_path = data / "curriculum_manifest.json"
    curriculum = _json(curriculum_path)
    category_map = curriculum["smalltalkCategoryUnitMap"]
    for level in LEVELS:
        course_unit_id, concept_id = MAPPINGS[level]
        key = f"{level}:theme_park_date"
        expected = {
            "courseUnitId": course_unit_id,
            "conceptIds": [concept_id],
        }
        current = category_map.get(key)
        if current is None:
            if check:
                raise PromotionError(f"curriculum mapping {key!r} is missing")
            category_map[key] = expected
        elif current != expected:
            raise PromotionError(f"curriculum mapping {key!r} differs")

    content_links = _merge_scenario_links(
        list(curriculum.get("contentLinks") or []),
        incoming_scenarios,
        check=check,
    )
    curriculum["contentLinks"] = content_links

    scenarios = _merge_rows(
        scenario_store.load_scenarios(data),
        incoming_scenarios,
        label="scenario",
        check=check,
    )
    if not check:
        _write(smalltalk_path, smalltalk)
        _write(curriculum_path, curriculum)
        scenario_store.write_shards(scenarios, data=data)

    return {
        "smalltalk": len(phrases),
        "scenarios": len(scenarios),
        "categoryMappings": len(category_map),
        "contentLinks": len(content_links),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--apply", action="store_true")
    mode.add_argument("--check", action="store_true")
    parser.add_argument("--root", type=Path, default=ROOT)
    args = parser.parse_args()
    try:
        counts = promote(args.root.resolve(), check=args.check)
    except (OSError, KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}")
        return 1
    action = "verified" if args.check else "promoted"
    print(f"OK: Theme Park Date {action}: {counts}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
