"""시나리오 대사·smalltalk 표현 원어민 자연화.

대부분 이미 자연스러움 (Jin이 06-09/06-18/07-01 감사에서 정리). 이번 pass에서는:
- 시나리오: 남아있는 교재틱·조사 어색·형식 혼용 튜닝
- smalltalk: 몇몇 bare opener를 실감나게

각 편집은 (id/index, old, new) 명시 → grep으로 위치 검증 후 in-place 치환.
"""

from __future__ import annotations
import json
import shutil
from pathlib import Path

SCEN = Path("assets/data/scenarios.json")
SMALL = Path("assets/data/smalltalk.json")

# ── 시나리오: (scenario_id, dialog_index, old_ko, new_ko) ────────────
SCENARIO_EDITS: list[tuple[str, int, str, str]] = [
    # airport_arrival: "관광이에요" 는 stiff → "관광하러 왔어요"
    ("airport_arrival", 3, "네, 처음이에요. 관광이에요.", "네, 처음이에요. 관광하러 왔어요."),

    # business_meeting_intro: 첫 인사만 처음 뵙겠습니다(습니다체), 이후 요체 혼용은 어색 → 습니다체 통일
    ("business_meeting_intro", 3,
     "저는 해외 마케팅을 담당하고 있어요. 꼼꼼하게 챙기는 편이라 잘 맞을 것 같습니다.",
     "저는 해외 마케팅을 담당하고 있습니다. 꼼꼼하게 챙기는 편이라 잘 맞을 것 같습니다."),

    # subway_directions: 조사 에 없이가 더 자연스러움
    ("subway_directions", 0, "저기요, 강남역에 어떻게 가요?", "저기요, 강남역 어떻게 가요?"),

    # bunshik_tteokbokki: staff 마무리 인사 삽입 (실제 분식집 톤)
    # (skip — dialog already flowing)

    # hotel_checkin: "예약했는데요. 이름은" (period between two) → 자연 이어가기
    ("hotel_checkin", 1, "예약했는데요. 이름은 [이름]이에요.", "예약했는데요, 이름이 [이름]이에요."),

    # mart_grocery: 주세요 반복 → 자연스러운 연결
    ("mart_grocery", 4, "그럼 사과 주세요. 봉지도 주세요.", "그럼 사과 주시고, 봉지도 하나 주세요."),

    # job_interview: 삼 년 → 3년 (실제 대화체) + 자연화
    ("job_interview", 1, "네, 마케팅 경험이 삼 년 있습니다.", "네, 마케팅 분야에서 3년 정도 일했습니다."),

    # feeling_sick line 4: bare → 자연 부드럽게
    # (skip — already casual natural)

    # convenience_store: "다 되셨어요?" → 좀 더 실사용 어투
    ("convenience_store", 0, "안녕하세요. 다 되셨어요?", "안녕하세요, 계산 도와드릴까요?"),
]


# ── smalltalk: (phrase_index in list, old_ko, new_ko) ─────────────────
SMALLTALK_EDITS: list[tuple[int, str, str]] = [
    # bare opener → 자연화
    # 참고: json phrases 배열 순서 기준으로 직접 매치보다 안전한 방법은
    #  ko 문자열 완전 일치로 찾아 치환.
    # 저는 여행을 좋아해요 → 저 여행 진짜 좋아해요 (구어)
    (-1, "저는 여행을 좋아해요.", "저 여행 진짜 좋아해요."),
    (-1, "저는 그림을 그려요.", "저 요즘 그림 그려요."),
    (-1, "노래 들어요.", "저 요즘 이 노래 자주 들어요."),
    (-1, "취업 준비해요.", "요즘 취업 준비 중이에요."),
    (-1, "이 노래 좋아요.", "이 노래 진짜 좋아요."),
    (-1, "영화 좋아해요.", "저 영화 좋아해요."),
    (-1, "배고파요.", "아, 진짜 배고파요."),
    (-1, "좀 졸려요.", "아, 좀 졸리네요."),
    (-1, "떨려요.", "아, 진짜 떨리네요."),
    (-1, "비가 와요.", "밖에 비 오네요."),
    (-1, "이사했어요.", "저 얼마 전에 이사했어요."),
    (-1, "케이팝 좋아해요.", "저 케이팝 진짜 좋아해요."),
    (-1, "병원 가요.", "오늘 병원 좀 다녀오려고요."),
    (-1, "바다 좋아해요.", "저 바다 진짜 좋아해요."),
    (-1, "오늘 바빠요.", "오늘 좀 정신없어요."),
    (-1, "잘 자요.", "잘 자요, 좋은 꿈 꿔요."),
    (-1, "주말 잘 보내세요.", "주말 잘 보내세요!"),  # 이미 자연 — 감탄부호만
    (-1, "면접 잘 보세요.", "면접 잘 보세요, 응원할게요!"),
]


def edit_scenarios() -> list[tuple[str, str, str]]:
    with SCEN.open(encoding="utf-8") as f:
        d = json.load(f)

    changed = []
    for sc in d["scenarios"]:
        scid = sc["id"]
        for sid, i, old, new in SCENARIO_EDITS:
            if scid != sid:
                continue
            if i >= len(sc["dialog"]):
                print(f"⚠️ {sid} dialog idx {i} 없음")
                continue
            line = sc["dialog"][i]
            if line["ko"] != old:
                print(f"⚠️ {sid}[{i}] 원본 미일치:\n  기대: {old}\n  실제: {line['ko']}")
                continue
            line["ko"] = new
            changed.append((sid, old, new))

    if changed:
        bak = SCEN.with_suffix(".json.bak")
        if not bak.exists():
            shutil.copy2(SCEN, bak)
        with SCEN.open("w", encoding="utf-8") as f:
            json.dump(d, f, ensure_ascii=False, indent=1)

    return changed


def edit_smalltalk() -> list[tuple[str, str]]:
    with SMALL.open(encoding="utf-8") as f:
        d = json.load(f)

    changed = []
    edit_map = {old: new for _, old, new in SMALLTALK_EDITS}

    for p in d["phrases"]:
        if p["ko"] in edit_map:
            new = edit_map[p["ko"]]
            if new != p["ko"]:
                changed.append((p["ko"], new))
                p["ko"] = new

    if changed:
        bak = SMALL.with_suffix(".json.bak")
        if not bak.exists():
            shutil.copy2(SMALL, bak)
        with SMALL.open("w", encoding="utf-8") as f:
            json.dump(d, f, ensure_ascii=False, indent=1)
            f.write("\n")

    return changed


if __name__ == "__main__":
    sc = edit_scenarios()
    print(f"\n시나리오 편집 {len(sc)}건:")
    for sid, o, n in sc:
        print(f"  [{sid}] '{o}' → '{n}'")

    st = edit_smalltalk()
    print(f"\nsmalltalk 편집 {len(st)}건:")
    for o, n in st:
        print(f"  '{o}' → '{n}'")
