#!/usr/bin/env python3
"""Emit review-only Batch 16 scenario drafts: C2 기능 확장 6칸.

PR #71 이 만든 기능 확장 18칸은 콘텐츠가 한 번도 집필된 적이 없다. 그중 A1 3칸을
칸당 4편으로 채우는 파일럿이다. Preview only — assets/data 나 lib 을 쓰지 않는다.
"""

from __future__ import annotations

import csv
import json
from pathlib import Path
import sys
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from data.batch_16_scene_scripts import SCENES

ROOT = SCRIPT_DIR.parents[1]
DRAFT_PATH = Path("tools/content_factory/drafts/c1_batch16_scenarios_c2.json")
MANIFEST_PATH = Path("tools/content_factory/drafts/batch_16_manifest.json")
REVIEW_PATH = Path("tools/content_factory/review/c1_batch16_scenarios.csv")
REVIEW_HEADER = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]
QUEST_SUFFIXES = ("hear", "tr", "gap", "build", "dict")
# A1 만 6번째 퀘스트를 갖는다.  test/a1_real_life_scenarios_test.dart 가 모든 A1
# 시나리오에 조사·받침·활용 교정 퀘스트를 요구하는데(입문자는 판정만으로는 조사를
# 못 고친다), 위 5종에는 교정형이 없다.  상위 레벨에는 그 계약이 없어 5종 그대로다.
A1_CORRECTION_SUFFIX = "particle"
LEVEL_ORDER = ("a1", "a2", "b1", "b2", "c1", "c2")
CATEGORY_ORDER = ("ethics", "history", "aesthetic", "limitation", "jurisdiction", "representation")

LEVEL_GRAMMAR_ALLOWLIST: dict[str, frozenset[str]] = {
    "a1": frozenset({
        "grammar_a1_direction_time_particle", "grammar_a1_which_question", "grammar_a1_want",
        "grammar_a1_short_negation", "grammar_a1_polite_past", "grammar_a1_object_particle",
        "grammar_a1_polite_request", "grammar_a1_copula_polite",
    }),
    "a2": frozenset({
        "grammar_a2_probability", "grammar_a2_polite_proposal", "grammar_a2_noun_cause",
        "grammar_a2_exclamation", "grammar_a2_recommendation", "grammar_a2_ability",
        "grammar_a2_gentle_question", "grammar_a2_cause_nikka", "grammar_a2_or_verbs",
    }),
    "b1": frozenset({
        "grammar_b1_decision", "grammar_b1_indirect_speech", "grammar_b1_wish",
        "grammar_b1_negative_cause", "grammar_b1_experience", "grammar_b1_background_contrast",
        "grammar_b1_soft_request",
    }),
    "b2": frozenset({
        "grammar_b2_formal_arrangement", "grammar_b2_explicit_formal_request",
        "grammar_b2_not_automatic_conclusion", "grammar_b2_as_long_as",
        "grammar_b2_instead_tradeoff", "grammar_b2_formal_intention",
        "grammar_b2_formal_reason", "grammar_b2_shared_merit",
    }),
    "c1": frozenset({
        "grammar_c1_taking_into_account", "grammar_c1_room_for", "grammar_c1_unless_condition",
        "grammar_c1_two_sides", "grammar_c1_even_at_cost", "grammar_c1_given_situation",
    }),
    "c2": frozenset({
        "grammar_c2_even_assuming", "grammar_c2_on_the_premise", "grammar_c2_nothing_more_than",
        "grammar_c2_defined_as", "grammar_c2_regardless_of_kin", "grammar_c2_even_if_concession",
    }),
}

SCENARIO_KEYS = (
    "id", "level", "emoji", "register", "speechStyle", "relationshipContext", "intent",
    "courseUnitId", "conceptIds", "surfaceFormIds", "sidekick", "xpReward",
    "title", "intro", "vocab", "grammarIds", "grammarBlock", "dialog", "quests",
)


def _sort_key(scene: dict[str, Any]) -> tuple[int, int]:
    return LEVEL_ORDER.index(scene["level"]), CATEGORY_ORDER.index(scene["category"])


def _to_record(scene: dict[str, Any]) -> dict[str, Any]:
    record: dict[str, Any] = {}
    for key in SCENARIO_KEYS:
        record[key] = [] if key == "surfaceFormIds" else scene[key]
    if scene.get("culturalNote"):
        record["culturalNote"] = scene["culturalNote"]
    return record


def build(root: Path = ROOT) -> dict[str, int]:
    scenes = sorted(SCENES, key=_sort_key)
    records = [_to_record(scene) for scene in scenes]
    quests = [quest for record in records for quest in record["quests"]]

    levels: dict[str, int] = {}
    for record in records:
        levels[record["level"]] = levels.get(record["level"], 0) + 1

    draft = {
        "version": 1,
        "_comment": "Review-only Batch 16 scenarios. C2 expansion shelves, four per shelf.",
        "scenarios": records,
    }
    manifest = {
        "version": 1,
        "batch": "16",
        "status": "review_only_draft",
        "provenance": {
            "scope": "Original A1 episodes for the C2 expansion shelves.",
            "rights": "original",
            "requiresJinReview": True,
            "promotedAt": "2026-08-18 — Jin 승인 하에 live 로 승격됐다(A1 확장 3칸 파일럿). 이 매니페스트는 생성물이라 status 는 항상 review_only_draft 로 다시 쓰인다 — 승격 여부의 정본은 shelf_assignment.ASSIGNMENT 와 SESSION_LOG 다.",
            "originalPlan": "docs/HANDOFF_HOEREN_GRID_2026-08-17.md §3.2 (기능 확장 3칸)",
        },
        "artifacts": [
            {
                "kind": "scenario",
                "draft": DRAFT_PATH.as_posix(),
                "review": REVIEW_PATH.as_posix(),
                "collection": "scenarios",
                "count": len(records),
                "levels": levels,
            }
        ],
        "recordCount": len(records),
        "questCount": len(quests),
        "contentLinks": [
            {
                "contentKind": "scenario",
                "contentId": record["id"],
                "courseUnitId": record["courseUnitId"],
                "conceptIds": list(record["conceptIds"]),
                "role": "practice",
            }
            for record in records
        ],
        "backdrops": {scene["id"]: scene["backdrop"] for scene in scenes},
        "nonMergeGuards": [
            "Jin approval required before --apply",
            "no TTS synthesis or Firebase writes",
            "no assets/data or lib edits from this batch",
        ],
    }

    (root / DRAFT_PATH).write_text(
        json.dumps(draft, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    (root / MANIFEST_PATH).write_text(
        json.dumps(manifest, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    with (root / REVIEW_PATH).open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=REVIEW_HEADER)
        writer.writeheader()
        for scene, record in zip(scenes, records):
            writer.writerow({
                "id": record["id"],
                "level": record["level"].upper(),
                "ko": record["title"]["ko"],
                "de": record["title"]["de"],
                "en": record["title"]["en"],
                "field_notes": scene["fieldNotes"],
                "상태": "draft",
                "jin_memo": "",
            })
    return {"scenarios": len(records), "quests": len(quests)}


def main() -> int:
    counts = build()
    print(f"OK: staged {counts['scenarios']} scenarios and {counts['quests']} quests (review-only)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
