#!/usr/bin/env python3
"""콘텐츠 종류가 0 인 코스 유닛을, 과잉 유닛에서 매핑 키를 옮겨 채운다.

`rebalance_scenario_units.py` 가 시나리오 편중을 풀고 난 뒤에도 유닛 12 개는
특정 종류가 0 이었다 — 스몰톡 0 인 유닛 6 개, 문법 0 인 유닛 5 개, 클로즈 0 인
유닛 4 개. 콘텐츠가 없어서가 아니라 `{level}:{category}` / 규칙 ID 매핑이 몇몇
유닛에 몰려 있어서다 (예: a1 스몰톡 23 개 주제가 유닛 9 개에만 붙어 a1_09 가 5 개,
a1_01·a1_02·a1_03·a1_05·a1_13·a1_16 은 0).

여기 표는 Jin 승인분(2026-08-19)이다. 목적지 개념은 반드시 그 유닛의
`requiredConceptIds` 안에 있어야 한다 — 아니면 카탈로그가
`unrelated ... map concept` 로 거부한다. 문법 간선은 전부 role=assess 라
개념이 **정확히 1 개**여야 한다(`ambiguous checkpoint link` 검증).

채우지 **못한** 구멍은 콘텐츠 자체가 없어서다(결제·배달 단어팩 등) — 매핑을
억지로 옮기면 다른 유닛이 비므로 손대지 않는다. 상세는 SESSION_LOG 참조.

    python3 tools/content_factory/fill_empty_unit_kinds.py --dry-run
    python3 tools/content_factory/fill_empty_unit_kinds.py
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import scenario_store  # noqa: E402

MANIFEST = scenario_store.DATA / "curriculum_manifest.json"

# (매핑 이름, 키) -> (목적지 유닛, 개념들). 개념이 None 이면 문자열 매핑이다.
SMALLTALK_MOVES = {
    # 날씨는 인사 스몰톡의 정석. a1_09 가 5 개를 쥐고 a1_01 은 0 이었다.
    "a1:weather": ("a1_01_greetings_hangul", ["concept_greeting_politeness"]),
    # "제 최애는요" 시나리오가 이미 a1_02 에 앉아 있다.
    "a1:kpop": ("a1_02_self_intro_identity", ["concept_identity_polite"]),
    # 기분 말하기는 "저는 …" 주제 표지 연습이다.
    "a1:mood": ("a1_03_topic_subject_particles", ["concept_topic_particle"]),
    # 쇼핑 스몰톡은 개수·가격 = 수 표현.
    "a1:shopping": ("a1_05_numbers_time", ["concept_a1_time_numbers"]),
    # 면접은 합니다체↔해요체 전환의 전형이다.
    "a1:interview": ("a1_13_register_switching", ["concept_a1_register_switch"]),
    # 여행 스몰톡 = 생존 종합.
    "a1:travel": ("a1_16_survival_capstone", ["concept_a1_survival"]),
}

GRAMMAR_MOVES = {
    # N동안 / N쯤 — 둘 다 시간 표현인데 a1_05 는 문법이 0 이었다.
    "grammar_a1_duration_span": (
        "a1_05_numbers_time",
        ["concept_a1_time_numbers"],
    ),
    "grammar_a1_approx": ("a1_05_numbers_time", ["concept_a1_time_numbers"]),
    # V-아/어요 는 해요체 그 자체 — 말투 전환 유닛의 핵심인데 a1_12 에 있었다.
    "grammar_a1_polite_present": (
        "a1_13_register_switching",
        ["concept_action_polite"],
    ),
    "grammar_a1_honorific_kke": (
        "a1_13_register_switching",
        ["concept_a1_register_switch"],
    ),
    # 무슨/어떤 N — 처음 만난 자리의 질문.
    "grammar_a1_which_question": (
        "a1_15_first_class_work",
        ["concept_a1_first_meeting"],
    ),
    # V-고 — 하루의 행동을 잇는 문법. 생존 종합에 맞다.
    "grammar_a1_sequence_connector": (
        "a1_16_survival_capstone",
        ["concept_a1_survival"],
    ),
    # A/V-다는 점에서 — 자기 강점 서술 = 면접. b2_02 가 26 개를 쥐고 있었다.
    "grammar_b2_shared_merit": ("b2_05_interview", ["concept_b2_interview"]),
}

CLOZE_MOVES = {
    # 짧은 발표 = 격식 오프닝. b2_01 은 클로즈가 0 이었다.
    "b2:kurzreferat": "b2_01_formal_opening",
}


def _load() -> dict:
    with MANIFEST.open(encoding="utf-8") as handle:
        return json.load(handle)


def apply_moves(manifest: dict) -> list[str]:
    units = {unit["id"]: unit for unit in manifest.get("courseUnits", [])}
    concepts = {concept["id"] for concept in manifest.get("concepts", [])}
    changes: list[str] = []

    def check(unit_id: str, concept_ids: list[str], label: str) -> None:
        unit = units.get(unit_id)
        if unit is None:
            raise SystemExit(f"{label}: 유닛 없음 {unit_id}")
        for concept in concept_ids:
            if concept not in concepts:
                raise SystemExit(f"{label}: 개념 없음 {concept}")
            if concept not in (unit.get("requiredConceptIds") or []):
                raise SystemExit(
                    f"{label}: {concept} 가 {unit_id} 의 requiredConceptIds 밖이다"
                )

    for rule_map, moves, label in (
        (manifest["smalltalkCategoryUnitMap"], SMALLTALK_MOVES, "smalltalk"),
        (manifest["grammarRuleMap"], GRAMMAR_MOVES, "grammar"),
    ):
        for key, (unit_id, concept_ids) in moves.items():
            if key not in rule_map:
                raise SystemExit(f"{label}: 키 없음 {key}")
            check(unit_id, concept_ids, f"{label} {key}")
            before = rule_map[key]
            before_unit = (
                before if isinstance(before, str) else before.get("courseUnitId")
            )
            if before_unit == unit_id:
                continue
            rule_map[key] = {
                "courseUnitId": unit_id,
                "conceptIds": list(concept_ids),
            }
            changes.append(f"{label} {key}: {before_unit} -> {unit_id}")

    cloze_map = manifest["clozeTopicUnitMap"]
    for key, unit_id in CLOZE_MOVES.items():
        if key not in cloze_map:
            raise SystemExit(f"cloze: 키 없음 {key}")
        if unit_id not in units:
            raise SystemExit(f"cloze: 유닛 없음 {unit_id}")
        before = cloze_map[key]
        if before == unit_id:
            continue
        cloze_map[key] = unit_id
        changes.append(f"cloze {key}: {before} -> {unit_id}")

    return changes


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv)

    manifest = _load()
    changes = apply_moves(manifest)
    print(f"이동 {len(changes)}건")
    for line in changes:
        print(f"  {line}")

    if args.dry_run:
        print("(dry-run — 파일 미기록)")
        return 0

    MANIFEST.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
