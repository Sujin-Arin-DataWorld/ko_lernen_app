"""cloze 절단 어간(dangling stem) 답 해소 — 지시서 2.8 / brief_x_content T1.

배경: 일부 cloze 정답이 "-하다/-되다" 동사의 어간만 잘려 들어가 있다
(예: 표제어가 "충돌하다" 인데 answer 가 "충돌하"). 검출 규칙은
tool/audit_content_naturalness.py 의 check_dangling_stem /
test/cloze_dangling_stem_ratchet_test.dart 의 Dart 이식과 동일하다.

이 스크립트는 검출이 아니라 **해소**를 한다: 빈칸(＿＿＿) 바로 뒤에 붙어
있던 어미(지/니/기/는/자 등, 공백·문장부호 전까지)를 빈칸이 덮도록 answer/
distractors 로 옮기고, sentenceKo 에서는 그 어미를 제거한다. fullKo/de/en
은 절대 바뀌지 않는다(빈칸 위치만 뒤로 밀릴 뿐, 복원 결과는 동일).

변환 규칙 (항목당):
    ending      = sentenceKo 에서 빈칸(＿＿＿) 직후, 첫 공백/문장부호
                  전까지의 문자열.
    answer2     = answer + ending
    distractors2 = [d + ending for d in distractors]   (오답 후보 전부,
                  순서 유지 — 브리프 표현으로는 "options" 지만 실제 cloze.json
                  필드명은 distractors 이고 3개다. 4지선다는
                  answer + distractors 3개를 합친 것.)
    sentenceKo2 = sentenceKo 에서 빈칸 뒤 첫 `ending` 글자수만큼 제거
    fullKo, de, en, level, topic 등 나머지 필드는 불변.

불변식(자체 검증): sentenceKo2.replace(blank, answer2, 1) == fullKo
(test/cloze_content_guard_test.dart 의 "빈칸 복원" 가드와 동일 계약).

재실행 안전: 이미 빈칸 직후가 공백/문장부호인 항목(= ending == "")은
그대로 스킵(변경 없음으로 취급)한다. --apply 를 다시 돌려도 안전.

사용:
    python tool/fix_dangling_stems.py                # dry-run, 기본 16건
    python tool/fix_dangling_stems.py --apply         # 실제 적용, 기본 16건
    python tool/fix_dangling_stems.py cloze_a2_0082 --apply   # 특정 id만
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from typing import Optional

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLOZE_PATH = os.path.join(ROOT, "assets", "data", "cloze.json")

BLANK = "＿＿＿"

# 2026-09-04 실측 — test/cloze_dangling_stem_ratchet_test.dart::knownDanglingStemIds
DEFAULT_IDS = [
    "cloze_a2_0082",
    "cloze_b1_0109",
    "cloze_b1_0118",
    "cloze_b1_0119",
    "cloze_b1_0126",
    "cloze_b1_0131",
    "cloze_b1_0153",
    "cloze_b2_0264",
    "cloze_c1_0064",
    "cloze_c1_0075",
    "cloze_c1_0076",
    "cloze_c2_0062",
    "cloze_c2_0063",
    "cloze_c2_0064",
    "cloze_c2_0075",
    "cloze_c2_0076",
]

# 빈칸 직후 "어미"로 간주할 문자 클래스 — 공백·흔한 문장부호 전까지.
_STOP_CHARS = " \t\n,.!?~·…\"'“”‘’()[]"
_ENDING_RE = re.compile(r"^[^" + re.escape(_STOP_CHARS) + r"]+")


class FixError(Exception):
    pass


def _load(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def _dump(data: dict, path: str) -> None:
    serialized = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(serialized)


def compute_ending(sentence_ko: str, item_id: str) -> str:
    idx = sentence_ko.find(BLANK)
    if idx < 0:
        raise FixError(f"{item_id}: sentenceKo 에 빈칸({BLANK})이 없음")
    after = sentence_ko[idx + len(BLANK):]
    m = _ENDING_RE.match(after)
    return m.group(0) if m else ""


def plan_item(item: dict) -> Optional[dict]:
    """항목 하나에 대한 변경안을 계산. 이미 해소된(ending=="") 항목은 None."""
    item_id = item["id"]
    sentence_ko = item["sentenceKo"]
    answer = item["answer"]
    full_ko = item["fullKo"]
    distractors = list(item.get("distractors") or [])

    ending = compute_ending(sentence_ko, item_id)
    if not ending:
        return None  # 이미 해소됨 — 재실행 안전

    idx = sentence_ko.find(BLANK)
    after = sentence_ko[idx + len(BLANK):]
    new_sentence_ko = sentence_ko[: idx + len(BLANK)] + after[len(ending):]
    new_answer = answer + ending
    new_distractors = [d + ending for d in distractors]

    # 자체 검증: 복원 불변식.
    rebuilt = new_sentence_ko.replace(BLANK, new_answer, 1)
    if rebuilt != full_ko:
        raise FixError(
            f"{item_id}: 복원 불변식 위반 — rebuilt={rebuilt!r} fullKo={full_ko!r}"
        )

    return {
        "id": item_id,
        "ending": ending,
        "before": {
            "sentenceKo": sentence_ko,
            "answer": answer,
            "distractors": distractors,
        },
        "after": {
            "sentenceKo": new_sentence_ko,
            "answer": new_answer,
            "distractors": new_distractors,
        },
    }


def run(target_ids: list[str], apply: bool, cloze_path: str = CLOZE_PATH) -> list[dict]:
    data = _load(cloze_path)
    items = data["items"]
    by_id = {it["id"]: it for it in items}

    missing = [i for i in target_ids if i not in by_id]
    if missing:
        raise FixError(f"cloze.json 에 없는 id: {missing}")

    plans = []
    for item_id in target_ids:
        plan = plan_item(by_id[item_id])
        if plan is not None:
            plans.append(plan)

    if apply and plans:
        for plan in plans:
            item = by_id[plan["id"]]
            item["sentenceKo"] = plan["after"]["sentenceKo"]
            item["answer"] = plan["after"]["answer"]
            item["distractors"] = plan["after"]["distractors"]
        _dump(data, cloze_path)

    return plans


def _print_report(plans: list[dict], apply: bool) -> None:
    if not plans:
        print("변경 대상 없음 (이미 전부 해소됨).")
        return
    verb = "적용됨" if apply else "dry-run (변경 없음)"
    print(f"# fix_dangling_stems 결과 — {len(plans)}건 {verb}\n")
    for plan in plans:
        print(f"## {plan['id']}  (ending={plan['ending']!r})")
        print(f"- answer:      {plan['before']['answer']!r} -> {plan['after']['answer']!r}")
        print(f"- distractors: {plan['before']['distractors']!r} -> {plan['after']['distractors']!r}")
        print(f"- sentenceKo:  {plan['before']['sentenceKo']!r}")
        print(f"            -> {plan['after']['sentenceKo']!r}")
        print()


def main(argv: Optional[list[str]] = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("ids", nargs="*", help="대상 cloze id 목록 (생략 시 기본 16건)")
    parser.add_argument("--apply", action="store_true", help="실제로 assets/data/cloze.json 을 갱신한다 (기본은 dry-run)")
    args = parser.parse_args(argv)

    target_ids = args.ids if args.ids else list(DEFAULT_IDS)

    try:
        plans = run(target_ids, apply=args.apply)
    except FixError as exc:
        print(f"오류: {exc}", file=sys.stderr)
        return 1

    _print_report(plans, args.apply)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
