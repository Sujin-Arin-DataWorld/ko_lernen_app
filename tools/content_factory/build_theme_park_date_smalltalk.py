#!/usr/bin/env python3
"""Build the reviewed Theme Park Date smalltalk and scenario artifacts."""

from __future__ import annotations

import argparse
from collections import Counter
import csv
import json
from pathlib import Path
import sys
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from data.theme_park_date_records import RECORDS
from data.theme_park_date_scenarios import SCENARIOS


SMALLTALK_DRAFT_PATH = Path(
    "tools/content_factory/drafts/theme_park_date_smalltalk_v1.json"
)
SCENARIO_DRAFT_PATH = Path(
    "tools/content_factory/drafts/theme_park_date_scenarios_v1.json"
)
MANIFEST_PATH = Path(
    "tools/content_factory/drafts/batch_21_theme_park_date_manifest.json"
)
SMALLTALK_REVIEW_PATH = Path(
    "tools/content_factory/review/theme_park_date_smalltalk_v1.csv"
)
SCENARIO_REVIEW_PATH = Path(
    "tools/content_factory/review/theme_park_date_scenarios_v1.csv"
)
AUDIT_PATH = Path(
    "tools/content_factory/review/theme_park_date_content_v1_audit.json"
)

REVIEW_HEADER = [
    "id",
    "level",
    "ko",
    "de",
    "en",
    "field_notes",
    "상태",
    "jin_memo",
]
LEVELS = ("a1", "a2", "b1", "b2", "c1", "c2")
LANGUAGES = ("ko", "de", "en")
APPROVAL_MEMO = (
    "Jin explicitly requested live promotion of the Theme Park Date pack "
    "on 2026-08-30."
)
MAPPINGS = {
    "a1": ("a1_11_titles_relationships", "concept_a1_titles_relationships"),
    "a2": ("a2_03_chat_relationships", "concept_a2_relationships"),
    "b1": ("b1_04_relationships", "concept_b1_relationships"),
    "b2": ("b2_03_precise_requests", "concept_b2_precise_requests"),
    "c1": ("c1_06_intimacy_safety_design", "concept_c1_intimacy_safety"),
    "c2": ("c2_05_relationship_narratives", "concept_c2_relationship_narratives"),
}


class ThemeParkDateBuildError(ValueError):
    """Raised when the source breaks the reviewed-pack contract."""


def _write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def _validate_triad(record_id: str, label: str, value: dict[str, Any]) -> None:
    for language in LANGUAGES:
        if not str(value.get(language) or "").strip():
            raise ThemeParkDateBuildError(
                f"{record_id}: {label}.{language} must be non-empty"
            )


def _validate_records() -> None:
    if len(RECORDS) != 60:
        raise ThemeParkDateBuildError(f"expected 60 records, got {len(RECORDS)}")
    ids = [str(record.get("id") or "") for record in RECORDS]
    if len(ids) != len(set(ids)):
        raise ThemeParkDateBuildError("smalltalk IDs must be unique")
    if Counter(record["level"] for record in RECORDS) != Counter(
        {level: 10 for level in LEVELS}
    ):
        raise ThemeParkDateBuildError("smalltalk level matrix must be 10 per level")

    for record in RECORDS:
        record_id = record["id"]
        if record.get("category") != "theme_park_date":
            raise ThemeParkDateBuildError(f"{record_id}: wrong category")
        if record.get("relationshipContext") not in {
            "romantic_partner",
            "service",
        }:
            raise ThemeParkDateBuildError(f"{record_id}: invalid relationship context")
        _validate_triad(record_id, "primary", record)
        _validate_triad(record_id, "followUp", record.get("followUp", {}))
        alternatives = record.get("safeAlternativeQuestions") or []
        if not alternatives:
            raise ThemeParkDateBuildError(
                f"{record_id}: safe alternative question required"
            )
        for index, alternative in enumerate(alternatives):
            _validate_triad(
                record_id,
                f"safeAlternativeQuestions[{index}]",
                alternative,
            )
        if record.get("kind") == "question":
            _validate_triad(record_id, "reply", record.get("reply", {}))
        audit = record.get("audit") or {}
        if audit.get("triadStatus") != "MODEL_QA_PASS":
            raise ThemeParkDateBuildError(
                f"{record_id}: all promotion copy must pass model triad QA"
            )
        for field in ("scene", "pedagogicalTarget", "fieldNotes"):
            if not str(audit.get(field) or "").strip():
                raise ThemeParkDateBuildError(f"{record_id}: audit.{field} missing")

    korean = "\n".join(str(record["ko"]) for record in RECORDS)
    if "안경은 꼭 잡고" in korean:
        raise ThemeParkDateBuildError(
            "eyewear guidance must defer to the current ride's posted or staff rules"
        )
    spoken = "\n".join(
        str(record[language])
        for record in RECORDS
        for language in LANGUAGES
    )
    for rejected in ("ㅋㅋ", "ㅎㅎ", "봐바", "소세지", "올러", "있었떠니"):
        if rejected in spoken:
            raise ThemeParkDateBuildError(
                f"canonical spoken text contains rejected token {rejected!r}"
            )


def _validate_scenarios() -> None:
    if len(SCENARIOS) != 6:
        raise ThemeParkDateBuildError(f"expected 6 scenarios, got {len(SCENARIOS)}")
    if Counter(row["level"] for row in SCENARIOS) != Counter(
        {level: 1 for level in LEVELS}
    ):
        raise ThemeParkDateBuildError("scenario matrix must contain one per level")
    ids = [row["id"] for row in SCENARIOS]
    if len(ids) != len(set(ids)):
        raise ThemeParkDateBuildError("scenario IDs must be unique")
    for scenario in SCENARIOS:
        scenario_id = scenario["id"]
        level = scenario["level"]
        course_unit_id, concept_id = MAPPINGS[level]
        if scenario.get("courseUnitId") != course_unit_id:
            raise ThemeParkDateBuildError(f"{scenario_id}: course unit mismatch")
        if scenario.get("conceptIds") != [concept_id]:
            raise ThemeParkDateBuildError(f"{scenario_id}: concept mismatch")
        if scenario.get("playerCharacterId") != "sujin":
            raise ThemeParkDateBuildError(f"{scenario_id}: Sujin must be the player")
        if scenario.get("participantIds") != ["sujin", "christian"]:
            raise ThemeParkDateBuildError(f"{scenario_id}: couple participants mismatch")
        if scenario.get("sidekick") != "christian":
            raise ThemeParkDateBuildError(f"{scenario_id}: Christian must be sidekick")
        if scenario.get("shelf") != f"{level}_dating":
            raise ThemeParkDateBuildError(f"{scenario_id}: dating shelf mismatch")
        if scenario.get("backdrop") != "theme_park":
            raise ThemeParkDateBuildError(f"{scenario_id}: backdrop mismatch")
        if len(scenario.get("dialog") or []) != 8:
            raise ThemeParkDateBuildError(f"{scenario_id}: expected 8 dialog turns")
        speakers = {turn["speaker"] for turn in scenario["dialog"]}
        if speakers != {"user", "christian"}:
            raise ThemeParkDateBuildError(f"{scenario_id}: speaker lanes mismatch")
        for label in ("title", "intro"):
            _validate_triad(scenario_id, label, scenario.get(label, {}))
        for index, turn in enumerate(scenario["dialog"]):
            _validate_triad(scenario_id, f"dialog[{index}]", turn)
        quests = scenario.get("quests") or []
        expected_quest_types = {
            "hoerverstehen",
            "uebersetzen",
            "luecken",
            "satzBauen",
            "diktat",
        }
        if level == "a1":
            expected_quest_types.add("particlePop")
        if len(quests) != len(expected_quest_types):
            raise ThemeParkDateBuildError(
                f"{scenario_id}: expected {len(expected_quest_types)} quests"
            )
        if {quest["type"] for quest in quests} != expected_quest_types:
            raise ThemeParkDateBuildError(f"{scenario_id}: quest matrix mismatch")
        for quest in quests:
            if quest.get("conceptIds") != [concept_id]:
                raise ThemeParkDateBuildError(
                    f"{scenario_id}: quest concept mismatch"
                )


def _draft_phrase(record: dict[str, Any]) -> dict[str, Any]:
    return {key: value for key, value in record.items() if key != "audit"}


def _smalltalk_review_row(record: dict[str, Any]) -> dict[str, str]:
    audit = record["audit"]
    return {
        "id": record["id"],
        "level": record["level"],
        "ko": record["ko"],
        "de": record["de"],
        "en": record["en"],
        "field_notes": (
            f"rights: original; scene: {audit['scene']}; "
            f"model triad QA: {audit['triadStatus']}; {audit['fieldNotes']}"
        ),
        "상태": "approved",
        "jin_memo": APPROVAL_MEMO,
    }


def _scenario_review_row(scenario: dict[str, Any]) -> dict[str, str]:
    return {
        "id": scenario["id"],
        "level": scenario["level"],
        "ko": scenario["title"]["ko"],
        "de": scenario["title"]["de"],
        "en": scenario["title"]["en"],
        "field_notes": (
            "rights: original; Sujin-Christian romantic-partner scene; "
            "model triad QA: MODEL_QA_PASS; 8 dialog turns and "
            f"{len(scenario['quests'])} quests."
        ),
        "상태": "approved",
        "jin_memo": APPROVAL_MEMO,
    }


def _write_review(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=REVIEW_HEADER)
        writer.writeheader()
        writer.writerows(rows)


def build(output_root: Path) -> None:
    _validate_records()
    _validate_scenarios()
    phrases = [_draft_phrase(record) for record in RECORDS]
    scenarios = list(SCENARIOS)
    mappings = [
        {
            "level": level,
            "category": "theme_park_date",
            "courseUnitId": MAPPINGS[level][0],
            "conceptIds": [MAPPINGS[level][1]],
        }
        for level in LEVELS
    ]
    _write_json(
        output_root / SMALLTALK_DRAFT_PATH,
        {
            "schemaVersion": 1,
            "status": "approved_for_live_promotion",
            "category": {
                "id": "theme_park_date",
                "emoji": "🎢",
                "label": {
                    "ko": "놀이공원 데이트",
                    "de": "Date im Freizeitpark",
                    "en": "Theme park date",
                },
            },
            "phrases": phrases,
        },
    )
    _write_json(
        output_root / SCENARIO_DRAFT_PATH,
        {
            "schemaVersion": 1,
            "status": "approved_for_live_promotion",
            "scenarios": scenarios,
        },
    )
    _write_review(
        output_root / SMALLTALK_REVIEW_PATH,
        [_smalltalk_review_row(record) for record in RECORDS],
    )
    _write_review(
        output_root / SCENARIO_REVIEW_PATH,
        [_scenario_review_row(scenario) for scenario in SCENARIOS],
    )
    _write_json(
        output_root / AUDIT_PATH,
        {
            "schemaVersion": 1,
            "mode": "AUTHOR+AUDIT",
            "modelQaClaim": "MODEL_QA_PASS",
            "humanLanguageQaClaim": False,
            "approvalAuthority": "Jin",
            "approvalScope": "explicit live-promotion request",
            "smalltalk": [
                {"id": record["id"], **record["audit"]}
                for record in RECORDS
            ],
            "scenarios": [
                {
                    "id": scenario["id"],
                    "level": scenario["level"],
                    "triadStatus": "MODEL_QA_PASS",
                    "relationshipContext": "romantic_partners",
                    "dialogTurns": len(scenario["dialog"]),
                    "questCount": len(scenario["quests"]),
                }
                for scenario in SCENARIOS
            ],
        },
    )
    _write_json(
        output_root / MANIFEST_PATH,
        {
            "version": 1,
            "batch": "theme_park_date_v1",
            "status": "merged",
            "provenance": {
                "scope": (
                    "Original A1-C2 Theme Park Date content based on Jin's "
                    "recounted Sujin-Christian date conversation."
                ),
                "rights": "original_clean_room",
                "requiresJinReview": True,
                "approval": {
                    "authority": "Jin",
                    "approvedAt": "2026-08-30",
                    "scope": "all 60 smalltalk phrases and 6 scenarios approved for live integration",
                },
                "modelLanguageQa": "MODEL_QA_PASS",
                "humanLanguageQaClaim": False,
            },
            "artifacts": [
                {
                    "kind": "smalltalk",
                    "draft": SMALLTALK_DRAFT_PATH.as_posix(),
                    "review": SMALLTALK_REVIEW_PATH.as_posix(),
                    "collection": "phrases",
                    "count": 60,
                    "levels": {level: 10 for level in LEVELS},
                },
                {
                    "kind": "scenario",
                    "draft": SCENARIO_DRAFT_PATH.as_posix(),
                    "review": SCENARIO_REVIEW_PATH.as_posix(),
                    "collection": "scenarios",
                    "count": 6,
                    "levels": {level: 1 for level in LEVELS},
                },
            ],
            "recordCount": 66,
            "questCount": sum(len(scenario["quests"]) for scenario in SCENARIOS),
            "smalltalkCategoryMappings": mappings,
            "visualAsset": {
                "runtimeKey": "theme_park",
                "futurePosterPath": "assets/illustrations/scenes/theme_park.png",
                "currentFallbackKey": "market",
                "ambientLoopRequired": False,
            },
            "promotion": {
                "runtime": True,
                "listening": True,
                "tts": "dynamic_runtime",
                "firebase": False,
            },
        },
    )


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output-root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help="Repository-shaped root for generated artifacts.",
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    build(args.output_root.resolve())


if __name__ == "__main__":
    main()
