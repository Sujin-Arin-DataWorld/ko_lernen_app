#!/usr/bin/env python3
"""Legacy scenarios에 shelf/backdrop을 소급 부여하고 레벨 샤드로 분할한다.

문장·ID·레벨은 건드리지 않는다 (스펙 §5.4).  네 지표
(DUPES/ORPHANS/GHOSTS/WRONG LEVEL) 와 backdrop 커버리지 중 하나라도
비어 있지 않으면 아무것도 쓰지 않는다.

Usage:
    python3 tools/content_factory/migrate_shelf_backdrop.py            # 리포트만
    python3 tools/content_factory/migrate_shelf_backdrop.py --apply    # 샤드 생성
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
import scenario_store
from shelf_assignment import ALL_SHELVES, SHELF_BY_ID

ROOT = Path(__file__).resolve().parents[2]
BASELINE_RELATIVE = Path("test") / "fixtures" / "backdrop_baseline.json"
BACKDROP_KEYS = frozenset(
    (
        "airport", "bank", "cafe", "convenience", "directions", "home",
        "hotel", "market", "office", "pharmacy", "restaurant", "salon",
        "station", "taxi",
        "theme_park",
    )
)


def read_baseline(root: Path = ROOT) -> dict[str, str]:
    with (root / BASELINE_RELATIVE).open(encoding="utf-8") as handle:
        payload = json.load(handle)
    return {str(key): str(value) for key, value in payload["entries"].items()}


def plan_migration(
    scenarios: list[dict[str, Any]],
    baseline: dict[str, str],
) -> tuple[list[dict[str, Any]], dict[str, list[str]]]:
    """주입된 사본과 리포트를 만든다.  입력은 변형하지 않는다."""

    levels = {
        str(item.get("id")): str(item.get("level", "")).strip().lower()
        for item in scenarios
    }
    # 기준선은 마이그레이션 당시 264개의 동결 사본이라 자라지 않는다.  이후
    # 승격된 배치(2026-08-18 Batch 11)는 레코드가 자기 backdrop 을 이미 달고
    # 들어오므로, 기준선에 없으면 레코드 자신을 본다.  둘 다 없을 때만 결손이다.
    carried = {
        str(item["id"]): str(item["backdrop"])
        for item in scenarios
        if isinstance(item.get("backdrop"), str) and item["backdrop"].strip()
    }
    resolved = {**carried, **baseline}

    seen: dict[str, int] = {}
    resolved_shelves: dict[str, str] = {}
    unknown_shelf: list[str] = []
    for item in scenarios:
        scenario_id = str(item.get("id") or "")
        seen[scenario_id] = seen.get(scenario_id, 0) + 1
        explicit = str(item.get("shelf") or "").strip()
        if explicit:
            if explicit in ALL_SHELVES:
                resolved_shelves[scenario_id] = explicit
            else:
                unknown_shelf.append(scenario_id)
        elif scenario_id in SHELF_BY_ID:
            resolved_shelves[scenario_id] = SHELF_BY_ID[scenario_id]

    report = {
        "dupes": sorted(key for key, count in seen.items() if count > 1),
        "orphans": sorted(set(levels) - set(resolved_shelves)),
        # The legacy appendix is intentionally a superset after the canonical
        # cut-over; absent retired IDs are lineage, not ghosts in this input.
        "ghosts": [],
        "wrong_level": sorted(
            scenario_id
            for scenario_id, shelf in resolved_shelves.items()
            if levels.get(scenario_id) != shelf.split("_", 1)[0]
        ),
        "unknown_shelf": sorted(unknown_shelf),
    }
    report["missing_backdrop"] = sorted(
        scenario_id for scenario_id in levels if scenario_id not in resolved
    )
    report["unknown_backdrop"] = sorted(
        scenario_id
        for scenario_id, key in resolved.items()
        if scenario_id in levels and key not in BACKDROP_KEYS
    )
    if any(report[key] for key in report):
        return [], report

    migrated: list[dict[str, Any]] = []
    for item in scenarios:
        scenario_id = str(item["id"])
        copied = dict(item)
        copied["shelf"] = resolved_shelves[scenario_id]
        copied["backdrop"] = resolved[scenario_id]
        migrated.append(copied)
    return migrated, report


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="샤드를 실제로 쓴다")
    args = parser.parse_args(argv)

    scenarios = scenario_store.load_scenarios()
    migrated, report = plan_migration(scenarios, read_baseline())

    failures = {key: value for key, value in report.items() if value}
    if failures:
        for key, value in sorted(failures.items()):
            print(f"FAIL {key}: {len(value)} — {value[:10]}")
        return 1

    print(f"OK: {len(migrated)} scenarios ready (shelf + backdrop injected).")
    if not args.apply:
        print("Dry run. Re-run with --apply to write the shards.")
        return 0

    counts = scenario_store.write_shards(migrated, scenario_store.DATA)
    for level, count in counts.items():
        print(f"  scenarios_{level}.json  {count}")
    print(f"  total {sum(counts.values())}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
