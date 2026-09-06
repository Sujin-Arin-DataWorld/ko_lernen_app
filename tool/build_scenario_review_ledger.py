#!/usr/bin/env python3
"""Build the W10 owner review ledger for the 52 new `_w10_` scenarios.

Reads the six level shards (``assets/data/scenarios_{a1,a2,b1,b2,c1,c2}.json``),
selects every scenario whose ``id`` contains ``_w10_``, and writes a Korean
Markdown review table to ``docs/data/scenario_w10_review_jin.md`` so Jin can
read every Korean line without opening the JSON shards.

The output is deterministic: scenarios are sorted by level (A1 -> C2) then by
shelf slug, the generation date is a fixed constant (not ``date.today()``), and
no other non-deterministic data (timestamps, dict iteration order beyond what
we explicitly sort) leaks into the file. Running this script twice in a row
must produce a byte-identical file.

Usage:
    .venv/Scripts/python.exe -X utf8 tool/build_scenario_review_ledger.py
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "assets" / "data"
DEFAULT_OUT = ROOT / "docs" / "data" / "scenario_w10_review_jin.md"

LEVELS = ["a1", "a2", "b1", "b2", "c1", "c2"]

GENERATION_DATE = "2026-09-06"

LEGEND = (
    "판정칸: ok / 수정(무엇을) / 삭제. 이 표는 Fable이 전 문장을 직독해 정정 "
    "1라운드(A1 7편·A2 5편·B1 5편·B2 8편·C1 3편·C2 6편 반려 반영)를 거친 뒤 "
    "통합한 상태다. 수정 요청은 텍스트만 바꾸면 되고 TTS 결손은 "
    "`generate_tts.py --missing-from-storage`로 채운다."
)


def load_w10_scenarios(level: str) -> list[dict[str, Any]]:
    """Load scenarios for one level shard, filtered to `_w10_` ids."""
    path = DATA_DIR / f"scenarios_{level}.json"
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    scenarios = data["scenarios"]
    return [s for s in scenarios if "_w10_" in s.get("id", "")]


def escape_cell(text: str) -> str:
    """Escape text so it renders safely inside a Markdown table cell."""
    return text.replace("|", "\\|").replace("\n", " ").strip()


def format_participants(scenario: dict[str, Any]) -> str:
    player = scenario.get("playerCharacterId", "")
    participants = scenario.get("participantIds", []) or []
    return f"{player} ({', '.join(participants)})"


def format_style(scenario: dict[str, Any]) -> str:
    register = scenario.get("register", "")
    speech_style = scenario.get("speechStyle", "")
    return f"{register}/{speech_style}"


def build_table_row(idx: int, scenario: dict[str, Any]) -> str:
    dialog = scenario.get("dialog", []) or []
    first_line = dialog[0]["ko"] if dialog else ""
    title_ko = scenario.get("title", {}).get("ko", "")
    cells = [
        str(idx),
        escape_cell(scenario.get("id", "")),
        escape_cell(scenario.get("shelf", "")),
        escape_cell(title_ko),
        escape_cell(format_participants(scenario)),
        escape_cell(format_style(scenario)),
        escape_cell(first_line),
        str(len(dialog)),
        "",  # Jin 판정
        "",  # 메모
    ]
    return "| " + " | ".join(cells) + " |"


def build_dialog_block(scenario: dict[str, Any]) -> str:
    dialog = scenario.get("dialog", []) or []
    title_ko = scenario.get("title", {}).get("ko", "")
    lines = [f"<details><summary>{scenario.get('id', '')} — {title_ko}</summary>", ""]
    for n, turn in enumerate(dialog, start=1):
        speaker = turn.get("speaker", "")
        ko = turn.get("ko", "")
        lines.append(f"{n}. {speaker}: {ko}")
    lines.append("")
    lines.append("</details>")
    return "\n".join(lines)


def build_level_section(level: str, scenarios: list[dict[str, Any]]) -> str:
    ordered = sorted(scenarios, key=lambda s: s.get("shelf", ""))
    level_label = level.upper()
    lines = [f"## {level_label} ({len(ordered)}편)", ""]
    header = (
        "| # | id | 칸(shelf slug) | 제목(ko) | 참여자(playerCharacterId + "
        "participantIds) | 문체(register/speechStyle) | 첫 대사(ko) | 대사 수 "
        "| Jin 판정 | 메모 |"
    )
    separator = "|---|---|---|---|---|---|---|---|---|---|"
    lines.append(header)
    lines.append(separator)
    for idx, scenario in enumerate(ordered, start=1):
        lines.append(build_table_row(idx, scenario))
    lines.append("")
    for scenario in ordered:
        lines.append(build_dialog_block(scenario))
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def build_document() -> str:
    by_level: dict[str, list[dict[str, Any]]] = {}
    for level in LEVELS:
        by_level[level] = load_w10_scenarios(level)

    total = sum(len(v) for v in by_level.values())
    per_level_counts = " · ".join(
        f"{level.upper()} {len(by_level[level])}" for level in LEVELS
    )

    parts = [
        "# W10 시나리오 52편 Jin 검수표",
        "",
        f"생성일: {GENERATION_DATE}",
        f"총 개수: {total}",
        f"레벨별 개수: {per_level_counts}",
        "",
        f"> {LEGEND}",
        "",
        "---",
        "",
    ]

    for level in LEVELS:
        parts.append(build_level_section(level, by_level[level]))
        parts.append("---")
        parts.append("")

    # Drop the trailing "---" + blank line after the last level section.
    while parts and parts[-1] in ("", "---"):
        parts.pop()

    return "\n".join(parts).rstrip() + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out",
        type=Path,
        default=DEFAULT_OUT,
        help="Output Markdown path (default: docs/data/scenario_w10_review_jin.md)",
    )
    args = parser.parse_args()

    document = build_document()
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8", newline="\n") as f:
        f.write(document)
    print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
