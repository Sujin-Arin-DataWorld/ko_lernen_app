#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "docs" / "textbook_project" / "data"

SECOND = DATA / "TEXTBOOK_REUSE_AUDIT_SECOND_PASS.csv"
RESOLUTION = DATA / "TEXTBOOK_LEXICAL_REWRITE_RESOLUTION_20261006.csv"
OUT = DATA / "TEXTBOOK_LEXICAL_MATERIALIZED_20261006.json"

CLOZE_TEMPLATES = {
    "사진 전송": {
        "sentenceKo": "단체 채팅방에 ＿＿＿ 전에 같이 찍힌 사람에게 먼저 물어봤어요.",
        "answer": "사진을 보내기",
        "distractors": ["사진을 지우기", "사진을 고르기", "사진을 인쇄하기"],
    },
    "선물 분배": {
        "sentenceKo": "양가에 가져갈 ＿＿＿ 미리 정했어요.",
        "answer": "선물을 어떻게 나눌지",
        "distractors": ["선물을 어디서 살지", "선물을 언제 포장할지", "선물을 누가 고를지"],
    },
    "시어머니 말씀": {
        "sentenceKo": "시어머니 말씀의 뜻을 제가 제대로 이해했는지 배우자에게 먼저 ＿＿＿.",
        "answer": "확인했어요",
        "distractors": ["전했어요", "감췄어요", "정했어요"],
    },
    "장인어른 건강": {
        "sentenceKo": "장인어른께 ＿＿＿ 먼저 여쭤봤어요.",
        "answer": "건강은 어떠신지",
        "distractors": ["몇 시에 오시는지", "어디에 사시는지", "무슨 일을 하시는지"],
    },
    "호칭 질문": {
        "sentenceKo": "처음 만났을 때 어떻게 부르면 되는지 먼저 ＿＿＿.",
        "answer": "호칭을 물어봤어요",
        "distractors": ["날짜를 정했어요", "사진을 골랐어요", "주소를 적었어요"],
    },
    "역할 언어": {
        "sentenceKo": "‘며느리니까 해야 한다’처럼 ＿＿＿ 개인의 선택을 의무처럼 보이게 만들 수 있다.",
        "answer": "역할을 규정하는 표현은",
        "distractors": ["일정을 알려 주는 표현은", "감정을 묻는 표현은", "장소를 설명하는 표현은"],
    },
    "보이지 않는 일": {
        "sentenceKo": "가족 행사를 준비할 때는 일정 조율과 연락처럼 ＿＿＿ 함께 나눠야 한다.",
        "answer": "보이지 않는 노동도",
        "distractors": ["개인 취미도", "교통비도", "식사 메뉴도"],
    },
    "호칭의 정치": {
        "sentenceKo": "이 논문은 가족 호칭이 친밀감뿐 아니라 ＿＿＿ 드러낼 수 있다고 분석한다.",
        "answer": "권력 관계도",
        "distractors": ["계절 변화도", "식사 취향도", "지역 날씨도"],
    },
    "일회용 밴드": {
        "sentenceKo": "작은 ＿＿＿ 하나 주세요.",
        "answer": "반창고",
        "distractors": ["붕대", "휴지", "수건"],
    },
    "선택 보고": {
        "sentenceKo": "유리한 결과만 보여 주는 ＿＿＿ 피하려면 분석한 지표를 모두 공개해야 한다.",
        "answer": "선택적 보고를",
        "distractors": ["자료 수집을", "표본 구성을", "결과 해석을"],
    },
    "기념 문장": {
        "sentenceKo": "역사적 사건을 다루는 ＿＿＿ 사실과 현재의 해석을 구분해야 한다.",
        "answer": "기념 문구를 쓸 때는",
        "distractors": ["광고 문구를 쓸 때는", "일정표를 만들 때는", "메뉴판을 읽을 때는"],
    },
    "자동 결정": {
        "sentenceKo": "＿＿＿ 이의를 제기하려면 어떤 자료와 기준이 사용됐는지 확인할 수 있어야 한다.",
        "answer": "자동화된 결정에",
        "distractors": ["개인적인 취향에", "날씨 변화에", "여행 일정에"],
    },
    "문지기 담론": {
        "sentenceKo": "누가 진짜 팬인지 계속 가르는 ＿＿＿ 참여의 문턱을 높일 수 있다.",
        "answer": "배타적 팬 담론은",
        "distractors": ["공연 후기 글은", "팬 번역 활동은", "공식 일정 안내는"],
    },
}

# Only needed when the canonical example translation is not an exact translation
# of the materialized cloze sentence.
CLOZE_TRANSLATION_OVERRIDES = {
    "시어머니 말씀": {
        "de": "Ich fragte zuerst bei meinem Partner nach, ob ich die Worte meiner Schwiegermutter richtig verstanden hatte.",
        "en": "I first checked with my partner whether I had understood my mother-in-law's remark correctly.",
    },
    "호칭 질문": {
        "de": "Beim ersten Treffen habe ich zuerst gefragt, wie ich die Person ansprechen soll.",
        "en": "When we first met, I first asked how I should address them.",
    },
}


def load_csv(path):
    return list(csv.DictReader(path.open(encoding="utf-8-sig", newline="")))


def main():
    second = load_csv(SECOND)
    resolution = {r["lexeme"]: r for r in load_csv(RESOLUTION)}
    rows = [r for r in second if r["secondPassResolution"] == "LEXICAL_OVERRIDE_READY"]

    materialized = []
    for row in rows:
        lexeme = row["lexemeHint"]
        rr = resolution[lexeme]
        rec = {
            "sourceId": row["sourceId"],
            "surface": row["surface"],
            "level": row["finalTextbookLevel"],
            "replacesLexeme": lexeme,
            "replacementTarget": rr["replacementTarget"],
            "pedagogyRole": rr["pedagogyRole"],
        }

        if row["surface"] == "sentence_building":
            rec["replacement"] = {
                "targetKo": rr["replacementExampleKo"],
                "promptDe": rr["replacementExampleDe"],
                "promptEn": rr["replacementExampleEn"],
                "vocabKo": rr["replacementTarget"],
            }

        elif row["surface"] == "cloze":
            t = CLOZE_TEMPLATES[lexeme]
            full = t["sentenceKo"].replace("＿＿＿", t["answer"])
            tr = CLOZE_TRANSLATION_OVERRIDES.get(lexeme, {})
            rec["replacement"] = {
                "sentenceKo": t["sentenceKo"],
                "answer": t["answer"],
                "fullKo": full,
                "de": tr.get("de", rr["replacementExampleDe"]),
                "en": tr.get("en", rr["replacementExampleEn"]),
                "distractors": t["distractors"],
            }

        else:
            raise ValueError(f"Unexpected surface: {row['surface']}")

        materialized.append(rec)

    payload = {
        "schemaVersion": 1,
        "date": "2026-10-06",
        "status": "MATERIALIZED_TEXTBOOK_REWRITE",
        "count": len(materialized),
        "clozeCount": sum(x["surface"] == "cloze" for x in materialized),
        "sentenceBuildingCount": sum(
            x["surface"] == "sentence_building" for x in materialized
        ),
        "items": materialized,
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        f"materialized={payload['count']} cloze={payload['clozeCount']} "
        f"sentence={payload['sentenceBuildingCount']}"
    )


if __name__ == "__main__":
    main()
