#!/usr/bin/env python3
"""배치 시나리오를 레벨별 '몰빵 유닛'에서 주제 유닛으로 되돌린다.

**왜 필요한가.** batch 10–16 로 추가된 시나리오 179 편은 `courseUnitId` 를
레벨마다 하나뿐인 포괄 유닛(`a1_16_survival_capstone`,
`a2_07_travel_repair`, `b1_05_complaint_resolution`,
`b2_04_complaint_resolution`)에, `conceptIds` 도 그 유닛의 포괄 개념 하나에
일괄로 박아 넣었다.  그 결과 코스 유닛 48 개 중 일부는 시나리오가 1–4 편뿐인데
포괄 유닛 하나가 40–96 편을 쥔다.  듣기 책가도(칸=`shelf`)는 정상인데 코스
미션·마스터리는 이 편중을 그대로 물려받는다.

**어떻게 되돌리나.** `shelf` 는 `shelf_assignment.py` 가 정한 주제 정본이고
이미 전수 태깅돼 있다.  그래서 "포괄 유닛에 들어 있는 시나리오"만 골라
`shelf → (courseUnitId, conceptIds)` 표로 다시 배정한다.  표의 목적지는
발명한 게 아니라 **같은 칸의 손으로 쓴 시나리오가 이미 앉아 있는 유닛**과
그 유닛 `canDo` 를 따랐다.  포괄 유닛에 남기는 칸(예: A2 `a2_move`,
B1 환불·수리·지연·보험)은 원래 그 유닛 주제가 맞는 것들이다.

체크포인트로 선언된 시나리오는 절대 옮기지 않는다(유닛의
`checkpointContentIds` 계약이 깨진다).

    python3 tools/content_factory/rebalance_scenario_units.py --dry-run
    python3 tools/content_factory/rebalance_scenario_units.py
"""

from __future__ import annotations

import argparse
import collections
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import scenario_store  # noqa: E402

MANIFEST = scenario_store.DATA / "curriculum_manifest.json"

# 레벨별 몰빵 유닛 — 여기 들어 있는 시나리오만 재배정 대상이다.
OVERLOADED_UNITS = {
    "a1": "a1_16_survival_capstone",
    "a2": "a2_07_travel_repair",
    "b1": "b1_05_complaint_resolution",
    "b2": "b2_04_complaint_resolution",
}

# shelf → (목적지 유닛, conceptIds). 표에 없는 칸은 몰빵 유닛에 그대로 둔다
# (그 유닛 주제가 실제로 맞는 칸이다).
REASSIGNMENT = {
    # ── A1 ────────────────────────────────────────────────────────────
    "a1_greet": ("a1_01_greetings_hangul", ["concept_greeting_politeness"]),
    "a1_eat": ("a1_04_order_request_object", ["concept_request_polite"]),
    "a1_transit": ("a1_06_transport_directions", ["concept_a1_directions"]),
    "a1_taxi_stay": ("a1_06_transport_directions", ["concept_a1_directions"]),
    "a1_repeat": ("a1_08_clarify_repair", ["concept_a1_clarification"]),
    "a1_home": ("a1_09_home_daily_life", ["concept_a1_home_daily"]),
    "a1_body": ("a1_10_health_safety", ["concept_a1_health_safety"]),
    "a1_counter": ("a1_14_payment_delivery", ["concept_a1_payment_delivery"]),
    # ── A2 ── (a2_move 는 a2_07 주제 그대로 — 교통·분실·수리)
    "a2_plan": ("a2_02_plans_proposals", ["concept_proposal_polite"]),
    "a2_friends": ("a2_03_chat_relationships", ["concept_a2_relationships"]),
    "a2_body": ("a2_04_feelings_health", ["concept_a2_feelings"]),
    "a2_buy": ("a2_05_delivery_services", ["concept_a2_services"]),
    "a2_eat": ("a2_05_delivery_services", ["concept_a2_services"]),
    "a2_work": ("a2_06_study_work", ["concept_a2_work_study"]),
    "a2_money": ("a2_08_home_money", ["concept_a2_home_money"]),
    "a2_apt": ("a2_08_home_money", ["concept_a2_home_money"]),
    # ── B1 ── (refund·repair·delay·insurance 는 b1_05 주제 그대로)
    "b1_fandom": ("b1_01_experience_reasons", ["concept_b1_reasons_experience"]),
    "b1_team": ("b1_03_work_softening", ["concept_b1_softening"]),
    "b1_neighbor": ("b1_04_relationships", ["concept_b1_relationships"]),
    "b1_bill": ("b1_06_life_capstone", ["concept_b1_life"]),
    "b1_form": ("b1_06_life_capstone", ["concept_b1_life"]),
    # ── B2 ── (notice·travel 은 b2_04 주제 그대로)
    "b2_meeting": ("b2_01_formal_opening", ["concept_b2_formal_opening"]),
    "b2_evidence": ("b2_02_professional_opinion", ["concept_b2_opinion"]),
    "b2_friends": ("b2_02_professional_opinion", ["concept_b2_opinion"]),
    "b2_contract": ("b2_03_precise_requests", ["concept_b2_precise_requests"]),
    "b2_health": ("b2_03_precise_requests", ["concept_b2_precise_requests"]),
    "b2_negotiate": ("b2_03_precise_requests", ["concept_b2_precise_requests"]),
    "b2_public": ("b2_06_advanced_capstone", ["concept_b2_advanced"]),
}


def _manifest() -> dict:
    with MANIFEST.open(encoding="utf-8") as handle:
        return json.load(handle)


def _checkpoint_scenario_ids(manifest: dict) -> set[str]:
    ids: set[str] = set()
    for unit in manifest.get("courseUnits", []):
        for checkpoint in unit.get("checkpointContentIds", []) or []:
            kind, _, content_id = str(checkpoint).partition(":")
            if kind == "scenario" and content_id:
                ids.add(content_id)
    return ids


def _catchall_concepts(manifest: dict) -> dict[str, str]:
    """레벨 → 몰빵 유닛의 포괄 개념 (예: a1 -> concept_a1_survival)."""

    by_id = {unit["id"]: unit for unit in manifest.get("courseUnits", [])}
    catchall: dict[str, str] = {}
    for level, unit_id in OVERLOADED_UNITS.items():
        required = by_id[unit_id].get("requiredConceptIds") or []
        if len(required) != 1:
            raise SystemExit(f"{unit_id} 의 포괄 개념이 1 개가 아니다: {required}")
        catchall[level] = required[0]
    return catchall


def rebalance(scenarios: list[dict], manifest: dict) -> list[tuple[str, str, str]]:
    """제자리에서 `courseUnitId`/`conceptIds` 를 고치고 이동 목록을 돌려준다.

    퀘스트의 `conceptIds` 도 같이 고친다. 링크 빌더가 퀘스트 개념을 그 개념을
    요구하는 **모든** 유닛으로 팬아웃하기 때문에, 시나리오만 옮기고 퀘스트에
    포괄 개념을 남겨 두면 몰빵 유닛이 링크를 그대로 되찾는다.
    """

    unit_ids = {unit["id"] for unit in manifest.get("courseUnits", [])}
    concept_ids = {concept["id"] for concept in manifest.get("concepts", [])}
    protected = _checkpoint_scenario_ids(manifest)
    catchall = _catchall_concepts(manifest)

    for shelf, (unit, concepts) in REASSIGNMENT.items():
        if unit not in unit_ids:
            raise SystemExit(f"목적지 유닛이 매니페스트에 없다: {shelf} -> {unit}")
        for concept in concepts:
            if concept not in concept_ids:
                raise SystemExit(f"개념이 매니페스트에 없다: {shelf} -> {concept}")

    moves: list[tuple[str, str, str]] = []
    for scenario in scenarios:
        level = str(scenario.get("level", "")).strip().lower()
        current = scenario.get("courseUnitId", "")
        if OVERLOADED_UNITS.get(level) == current:
            if scenario["id"] in protected:
                continue
            target = REASSIGNMENT.get(scenario.get("shelf", ""))
            if target is None:
                continue
            unit, concepts = target
            moves.append((scenario["id"], current, unit))
            scenario["courseUnitId"] = unit
            scenario["conceptIds"] = list(concepts)

        # 이미 옮겨진 시나리오도 매번 통과한다 — 도구를 다시 돌려도 결과가 같다.
        if OVERLOADED_UNITS.get(level) == scenario.get("courseUnitId"):
            continue
        stale = catchall.get(level)
        replacement = list(scenario.get("conceptIds") or [])
        if stale is None or not replacement:
            continue
        for quest in scenario.get("quests", []) or []:
            if list(quest.get("conceptIds") or []) == [stale]:
                quest["conceptIds"] = list(replacement)
    return moves


def retarget_explicit_links(manifest: dict, scenarios: list[dict]) -> int:
    """매니페스트의 명시 `contentLinks` 중 낡은 **assess** 간선을 따라 옮긴다.

    링크 빌더는 `manifest.explicitLinks` 를 먼저 깔고 시작하므로, 시나리오만
    옮기고 이걸 두면 몰빵 유닛이 링크 45·34·29·19 개를 그대로 되찾는다.

    `practice` 간선은 건드리지 않는다 — 캡스톤이 다른 유닛의 콘텐츠를
    연습시키는 건 의도된 설계이고, 소유권(=평가)만 따라가면 된다.
    """

    owner = {s["id"]: s for s in scenarios}
    overloaded = set(OVERLOADED_UNITS.values())
    changed = 0
    for link in manifest.get("contentLinks", []):
        if link.get("contentKind") != "scenario" or link.get("role") != "assess":
            continue
        if link.get("courseUnitId") not in overloaded:
            continue
        scenario = owner.get(link.get("contentId", ""))
        if scenario is None:
            continue
        target = scenario.get("courseUnitId", "")
        if not target or target == link["courseUnitId"]:
            continue
        link["courseUnitId"] = target
        link["conceptIds"] = list(scenario.get("conceptIds") or [])
        changed += 1
    return changed


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv)

    manifest = _manifest()
    scenarios = scenario_store.load_scenarios()
    before = collections.Counter(s["courseUnitId"] for s in scenarios)
    moves = rebalance(scenarios, manifest)
    after = collections.Counter(s["courseUnitId"] for s in scenarios)
    retargeted = retarget_explicit_links(manifest, scenarios)

    print(f"이동 {len(moves)}편 · 명시 assess 링크 재조준 {retargeted}개")
    for unit in sorted(set(before) | set(after)):
        if before.get(unit, 0) != after.get(unit, 0):
            print(f"  {unit:38} {before.get(unit, 0):>3} -> {after.get(unit, 0):>3}")

    if args.dry_run:
        print("(dry-run — 파일 미기록)")
        return 0

    counts = scenario_store.write_shards(scenarios)
    MANIFEST.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print("샤드 기록:", counts)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
