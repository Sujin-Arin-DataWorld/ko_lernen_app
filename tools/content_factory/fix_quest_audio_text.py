#!/usr/bin/env python3
"""fix_quest_audio_text.py — 퀘스트 발화 텍스트 정리 (2026-08-12, Jin 승인).

배경: particlePop 은 prefix+정답+suffix 를 그대로 이어 붙여 말한다
(particle_pop_quest.dart _fullSentence). 데이터 규약상 suffix 는 새 단어로
시작하면 **선행 공백**이 있어야 하는데 31개 중 27개가 빠져 "사과를주세요"
처럼 붙어 발음·표기됐다. 추가로 자기소개 시나리오에 [이름]/[Name]
플레이스홀더가 그대로 남아 TTS 가 대괄호를 읽었다.

수정 (scenarios.json 원문 문자열 수술 — 포맷 보존):
1. particlePop suffix 선행 공백 주입 (아래 목록의 정확한 값만)
2. '안' 부사 퀘스트의 prefix 뒤 공백 ("왜 어제 답장" → "왜 어제 답장 ")
3. [이름]이에요 → 현우예요 · [Name] → Hyunwoo (전화 표현의 '현우'와 통일)

실행 후 tool/generate_tts.py 재실행 → 바뀐 문장만 자동 재합성.
Nutzung: python tools/content_factory/fix_quest_audio_text.py --write
"""
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PATH = os.path.join(ROOT, "assets", "data", "scenarios.json")

# suffix 값 → 기대 치환 횟수 (2026-08-12 전수 덤프 기준)
SUFFIX_FIXES = {
    "주세요.": 3,          # 사이즈로/왕복으로/사과를
    "했어?": 1,
    "가주세요.": 2,        # 강남역/홍대입구
    "갈아타세요.": 2,      # 종로3가/교대역 3호선
    "있어요.": 1,          # 예약이
    "아파요.": 1,
    "담당하고 있어요.": 1,
    "처리해 드리겠습니다.": 1,
    "다시 오세요.": 1,
    "만날까?": 1,
    "놓쳤어.": 1,
    "갑자기 일이 생겼어.": 1,
    "못 갈 것 같아.": 1,
    "뭐예요?": 1,
    "말씀해 주시겠어요?": 1,
    "시작했어요.": 1,
    "만들려고 해요.": 1,
    "있습니다.": 1,
    "사랑해.": 1,
    "나.": 1,
    "잃어버렸어요.": 1,
    "사 줄게.": 1,
}

# (찾기, 바꾸기, 기대 횟수) — 플레이스홀더·'안' prefix
LITERAL_FIXES = [
    ('"prefix": "왜 어제 답장"', '"prefix": "왜 어제 답장 "', 1),
    ('"suffix": "[이름]이에요."', '"suffix": " 현우예요."', 1),
    ("[이름]이에요", "현우예요", 2),  # dialog ko 2곳 (suffix 는 위에서 처리됨)
    ("[Name]", "Hyunwoo", 6),  # de/en 3쌍
]


def main():
    text = open(PATH, encoding="utf-8").read()

    total = 0
    for suffix, expected in SUFFIX_FIXES.items():
        old = f'"suffix": "{suffix}"'
        new = f'"suffix": " {suffix}"'
        n = text.count(old)
        assert n == expected, f"suffix {suffix!r}: {n}건 (기대 {expected})"
        text = text.replace(old, new)
        total += n

    for old, new, expected in LITERAL_FIXES:
        n = text.count(old)
        assert n == expected, f"{old!r}: {n}건 (기대 {expected})"
        text = text.replace(old, new)
        total += n

    # 검증: JSON 유효 + 잔여 플레이스홀더/붙은 seam 없음
    data = json.loads(text)
    assert "[이름]" not in text and "[Name]" not in text
    bad = []
    for s in data["scenarios"]:
        for q in s.get("quests", []):
            if q.get("type") != "particlePop":
                continue
            d = q.get("data") or {}
            opts = d.get("options") or []
            idx = int(d.get("correctIndex") or 0)
            suffix = d.get("suffix") or ""
            if suffix and not (suffix.startswith(" ") or suffix[0] in ".?!,"):
                bad.append(
                    (d.get("prefix", "") + opts[idx] + suffix) if opts else suffix
                )
    assert not bad, f"여전히 붙은 suffix: {bad}"

    print(f"치환 {total}건 · particlePop seam 전부 정상 · 플레이스홀더 0")

    if "--write" in sys.argv:
        with open(PATH, "w", encoding="utf-8", newline="") as f:
            f.write(text)
        print(f"✅ geschrieben: {PATH}")
    else:
        print("(Dry-Run — mit --write schreiben)")


if __name__ == "__main__":
    main()
