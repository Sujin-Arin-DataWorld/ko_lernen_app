#!/usr/bin/env python3
"""레벨 샤딩된 시나리오 코퍼스의 유일한 읽기/쓰기 지점.

`assets/data/scenarios.json` 을 직접 열던 도구가 38 개였다.  샤딩 이후에도
각자 6 개 파일을 합치게 두면 병합 순서와 쓰기 대상이 파일마다 갈린다.
모든 도구는 이 모듈만 부른다.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Iterable

from shelf_assignment import LEVELS

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "assets" / "data"
LEGACY_NAME = "scenarios.json"
SCHEMA_VERSION = 1
SHARD_COMMENT = (
    "Szenarien für Phase 5, nach CEFR-Level geshardet. "
    "Schema: lib/models/scenario.dart. Pflege-Pattern: ko ist Lerninhalt; "
    "de/en sind Mutterspracheübersetzungen. "
    "Schreiben nur über tools/content_factory/scenario_store.py."
)


def shard_name(level: str) -> str:
    normalized = str(level).strip().lower()
    if normalized not in LEVELS:
        raise ValueError(f"unknown scenario level {level!r}")
    return f"scenarios_{normalized}.json"


def shard_paths(data: Path = DATA) -> list[Path]:
    return [data / shard_name(level) for level in LEVELS]


def has_shards(data: Path = DATA) -> bool:
    return all(path.exists() for path in shard_paths(data))


def load_shard(level: str, data: Path = DATA) -> dict[str, Any]:
    with (data / shard_name(level)).open(encoding="utf-8") as handle:
        return json.load(handle)


def load_root(data: Path = DATA) -> dict[str, Any]:
    """병합된 코퍼스 뷰.  샤드가 전부 있으면 샤드가, 아니면 레거시가 진실이다."""

    if not has_shards(data):
        with (data / LEGACY_NAME).open(encoding="utf-8") as handle:
            return json.load(handle)
    scenarios: list[dict[str, Any]] = []
    version = SCHEMA_VERSION
    for level in LEVELS:
        root = load_shard(level, data)
        version = root.get("version", version)
        scenarios.extend(root.get("scenarios", []))
    return {"version": version, "scenarios": scenarios}


def load_scenarios(data: Path = DATA) -> list[dict[str, Any]]:
    return list(load_root(data).get("scenarios", []))


def target_shard(scenario: dict[str, Any]) -> str:
    """이 시나리오가 들어갈 샤드 파일명.  레벨이 곧 대상이라 모호함이 없다."""

    return shard_name(scenario.get("level", ""))


def write_shards(
    scenarios: Iterable[dict[str, Any]],
    data: Path = DATA,
    version: int = SCHEMA_VERSION,
) -> dict[str, int]:
    """전 코퍼스를 6 개 샤드로 덮어쓴다.  빈 레벨도 파일을 만든다."""

    buckets: dict[str, list[dict[str, Any]]] = {level: [] for level in LEVELS}
    for scenario in scenarios:
        level = str(scenario.get("level", "")).strip().lower()
        if level not in buckets:
            raise ValueError(
                f"scenario {scenario.get('id')!r} has unknown level {level!r}"
            )
        buckets[level].append(scenario)
    counts: dict[str, int] = {}
    for level in LEVELS:
        payload = {
            "version": version,
            "_comment": SHARD_COMMENT,
            "scenarios": buckets[level],
        }
        with (data / shard_name(level)).open(
            "w",
            encoding="utf-8",
            newline="\n",
        ) as handle:
            handle.write(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
        counts[level] = len(buckets[level])
    return counts
