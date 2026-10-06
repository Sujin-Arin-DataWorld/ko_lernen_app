#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "docs" / "textbook_project" / "data"
ALLOC = DATA / "TEXTBOOK_SOURCE_POOL_ALLOCATION_1A_6B.csv"
OUT = DATA / "TEXTBOOK_MICRO_UNIT_SPLITS_20261006.json"
ASSIGN = DATA / "TEXTBOOK_MICRO_UNIT_ASSIGNMENTS_20261006.csv"
REPORT = ROOT / "docs" / "textbook_project" / "MICRO_UNIT_SPLIT_RECOMMENDATIONS_20261006.md"

MICRO_UNITS = {
    "b1_04_relationships": [
        {
            "microUnitId": "b1_04a_relationship_register",
            "book": "3B",
            "title": {
                "ko": "관계의 거리와 말투",
                "en": "Relationship distance & speech style",
                "de": "Beziehungsnähe & Sprechstil",
            },
            "canDo": {
                "ko": "친밀도와 관계 변화에 맞춰 말투를 조절하고 오해를 풀 수 있어요.",
                "en": "I can adjust speech style to relationship distance and repair misunderstandings.",
                "de": "Ich kann meinen Sprechstil an Nähe und Beziehung anpassen und Missverständnisse klären.",
            },
        },
        {
            "microUnitId": "b1_04b_family_customs",
            "book": "3B",
            "title": {
                "ko": "가족·호칭·선물과 명절",
                "en": "Family, address terms, gifts & holidays",
                "de": "Familie, Anrede, Geschenke & Feiertage",
            },
            "canDo": {
                "ko": "가족 호칭과 방문·선물·명절 관습을 상황에 맞게 묻고 조율할 수 있어요.",
                "en": "I can ask about and navigate family address terms, visits, gifts, and holiday customs.",
                "de": "Ich kann Familienanreden, Besuche, Geschenke und Feiertagsbräuche erfragen und abstimmen.",
            },
        },
        {
            "microUnitId": "b1_04c_boundaries_private_life",
            "book": "3B",
            "title": {
                "ko": "사생활·경계·민감한 질문",
                "en": "Privacy, boundaries & sensitive questions",
                "de": "Privatsphäre, Grenzen & sensible Fragen",
            },
            "canDo": {
                "ko": "결혼·직장·종교·사생활처럼 민감한 질문에 경계를 세우고 부드럽게 화제를 조정할 수 있어요.",
                "en": "I can set boundaries around sensitive questions and redirect a conversation tactfully.",
                "de": "Ich kann bei sensiblen Fragen Grenzen setzen und das Gespräch taktvoll umlenken.",
            },
        },
    ],
    "b2_06_advanced_capstone": [
        {
            "microUnitId": "b2_06a_society_environment",
            "book": "4B",
            "title": {
                "ko": "사회·환경·공동체 판단",
                "en": "Society, environment & community judgment",
                "de": "Gesellschaft, Umwelt & gemeinschaftliche Entscheidungen",
            },
            "canDo": {
                "ko": "공동체 문제에서 여러 이해관계를 비교하고 실행 가능한 절충안을 제안할 수 있어요.",
                "en": "I can compare competing interests in community issues and propose workable compromises.",
                "de": "Ich kann bei Gemeinschaftsfragen unterschiedliche Interessen abwägen und umsetzbare Kompromisse vorschlagen.",
            },
        },
        {
            "microUnitId": "b2_06b_media_culture_language",
            "book": "4B",
            "title": {
                "ko": "미디어·문화·언어 해석",
                "en": "Interpreting media, culture & language",
                "de": "Medien, Kultur & Sprache interpretieren",
            },
            "canDo": {
                "ko": "미디어와 문화 표현의 어감·맥락·관점을 비교해 해석할 수 있어요.",
                "en": "I can interpret tone, context, and perspective in media and cultural language.",
                "de": "Ich kann Ton, Kontext und Perspektive in Medien- und Kultursprache vergleichen und deuten.",
            },
        },
        {
            "microUnitId": "b2_06c_ethics_responsibility",
            "book": "4B",
            "title": {
                "ko": "윤리·관점·책임 조정",
                "en": "Ethics, perspective & responsibility",
                "de": "Ethik, Perspektive & Verantwortung",
            },
            "canDo": {
                "ko": "가치 충돌에서 관점과 책임 범위를 구분하고 조건부 입장을 제시할 수 있어요.",
                "en": "I can distinguish perspectives and responsibility in value conflicts and state a qualified position.",
                "de": "Ich kann bei Wertekonflikten Perspektiven und Verantwortung unterscheiden und eine abgestufte Position formulieren.",
            },
        },
    ],
}

B1_REGISTER = (
    "반말", "존댓말", "말투", "호칭", "맞장구", "통역", "눈짓", "말실수",
    "별명", "장난", "친구", "데이트", "연애", "커피", "약속", "편하게",
    "어색", "나이 확인", "말 놓", "읽씹", "메시지", "감정", "서운",
    "취소", "이상형", "오해", "칭찬", "농담", "관계", "같이 웃",
    "공통점", "분위기 파악", "게임 한 판", "동생 편", "단톡방", "뉘앙스",
    "천천히 말해", "오역", "잔소리 해석", "다음엔 내가", "단톡 입장",
    "공지 확인", "읽음 표시", "전체 알림", "읽은 척", "의견 충돌",
    "친해", "유창", "놀려", "편을", "웃고 넘기", "요약해서 전하",
    "그대로 옮기", "빠뜨리", "끼어들", "다시 확인", "눈치 보",
    "대충 하지", "직접 대답", "격려", "위로", "존중", "화해",
    "이모티콘", "답장을 미루", "답장을 미뤘", "사진 올리기", "단체 사진",
    "놀리", "편들", "대충 하",
)
B1_FAMILY = (
    "시아버지", "시어머니", "시누이", "시동생", "처남", "처제", "형부",
    "올케", "장모", "장인", "며느리", "사위", "막내", "맏이", "선물",
    "답례", "상품권", "꽃다발", "한복", "명절", "건배", "술잔", "폭음",
    "취중진담", "대리 운전", "반찬", "보자기", "봉투", "과일", "정성",
    "포장", "빈손", "양손", "감사 인사", "양쪽 집", "연휴", "방문 순서",
    "가족 단톡", "집까지", "냉동", "김치", "가족", "건강식품",
    "받아 주세요", "사양하", "밀폐 용기", "비닐봉지", "가방이 무겁",
    "좌석 배정", "싸 주", "국물", "잔을 받", "잔을 따", "취하",
    "분위기 맞추", "먼저 따르", "물로 받", "자리 피하", "문 열어 두",
    "이불 개", "발소리를 죽이", "이 방은", "방문 두드리", "다용도 공간",
    "다음 방문", "방문 후기", "교통 대란", "일정표 공유", "올해는 못 가요",
    "영상 인사", "부부", "친척", "하루만 가", "동생",
)
B1_BOUNDARY = (
    "결혼", "월급", "연봉", "종교", "국적", "허락", "비자", "계약직",
    "원격 근무", "이직", "체류", "야근", "퇴사", "직장 분위기", "취업",
    "혼자", "잠자리", "사생활", "민감", "경계", "부담", "개인", "선을 ",
    "한국어 능력", "언제 결혼", "방 배정", "같이 자", "잠옷",
    "돌려 말", "화제 돌리", "솔직한 선", "다음에 말씀드릴게요",
    "안정적으로", "비밀 보장", "말하지 않기로", "아이를 가질", "아이 가지",
    "나가기 금지", "코골이 사과", "불 끄기", "실수 목록",
)

B1_SOURCE_OVERRIDES = {
    "cancelled_trip_hurt_feelings": "b1_04a_relationship_register",
    "date_or_friendly_coffee": "b1_04a_relationship_register",
    "speech_level_after_friendship": "b1_04a_relationship_register",
    "b1_theme_park_date_thrill": "b1_04a_relationship_register",
    "b1_w10_friends": "b1_04a_relationship_register",
    "b1_w10_partner": "b1_04c_boundaries_private_life",
    "smalltalk.b1.mood.day": "b1_04a_relationship_register",
    "smalltalk.b1.family.contact": "b1_04a_relationship_register",
    "smalltalk.b1.dating.gettingtoknow": "b1_04a_relationship_register",
    "smalltalk.b1.partner_family.privacy": "b1_04c_boundaries_private_life",
    "smalltalk.b1.partner_family.voice": "b1_04a_relationship_register",
    "smalltalk.b1.partner_family.arrange": "b1_04b_family_customs",
    "smalltalk.b1.partner_family.reflection": "b1_04a_relationship_register",
}

B2_TOPIC_MAP = {
    "society_current_affairs": "b2_06a_society_environment",
    "environment_sustainability": "b2_06a_society_environment",
    "politics_law_institutions": "b2_06a_society_environment",
    "neighbourhood_environment": "b2_06a_society_environment",
    "media_entertainment_culture_pop": "b2_06b_media_culture_language",
    "arts_literature_history": "b2_06b_media_culture_language",
    "language_learning_communication_repair": "b2_06b_media_culture_language",
    "social_etiquette_customs": "b2_06b_media_culture_language",
    "ethics_philosophy_abstract": "b2_06c_ethics_responsibility",
    "family_relationships": "b2_06c_ethics_responsibility",
    "money_finance_contracts": "b2_06c_ethics_responsibility",
    "technology_digital_ai": "b2_06c_ethics_responsibility",
}

B2_SOURCE_OVERRIDES = {
    "accessible_festival_route": "b2_06a_society_environment",
    "community_event_compromise": "b2_06a_society_environment",
    "recycling_policy_pilot": "b2_06a_society_environment",
    "fremdschaemen_live": "b2_06b_media_culture_language",
    "partner_family_titles": "b2_06b_media_culture_language",
    "b2_w10_partner": "b2_06c_ethics_responsibility",
    "b2_w10_fandom": "b2_06c_ethics_responsibility",
}


def load_rows():
    return list(csv.DictReader(ALLOC.open(encoding="utf-8-sig", newline="")))


def root_source_id(row):
    sid = row["sourceId"]
    if row["surface"] == "listening_lesson" and sid.startswith("listening.b1."):
        return sid[len("listening.b1."):]
    if row["surface"] == "listening_lesson" and sid.startswith("listening.b2."):
        return sid[len("listening.b2."):]
    return sid


def contains_any(text, needles):
    return any(n in text for n in needles)


def classify_b1(row):
    root = root_source_id(row)
    if root in B1_SOURCE_OVERRIDES:
        return B1_SOURCE_OVERRIDES[root], "SOURCE_OVERRIDE"

    topic = row["canonicalTopicId"]
    if topic in {"feelings_character", "language_learning_communication_repair", "technology_digital_ai"}:
        return "b1_04a_relationship_register", "TOPIC_RULE"
    if topic == "social_etiquette_customs":
        return "b1_04b_family_customs", "TOPIC_RULE"

    text = " ".join([row.get("lexemeHint", ""), row.get("titleKo", ""), root])
    if contains_any(text, B1_BOUNDARY):
        return "b1_04c_boundaries_private_life", "BOUNDARY_KEYWORD"
    if contains_any(text, B1_FAMILY):
        return "b1_04b_family_customs", "FAMILY_CUSTOM_KEYWORD"
    if contains_any(text, B1_REGISTER):
        return "b1_04a_relationship_register", "REGISTER_KEYWORD"

    return "", "MICRO_MANUAL_REVIEW"


def classify_b2(row):
    root = root_source_id(row)
    if root in B2_SOURCE_OVERRIDES:
        return B2_SOURCE_OVERRIDES[root], "SOURCE_OVERRIDE"
    topic = row["canonicalTopicId"]
    if topic in B2_TOPIC_MAP:
        return B2_TOPIC_MAP[topic], "TOPIC_RULE"
    return "", "MICRO_MANUAL_REVIEW"


def main():
    rows = load_rows()
    assignments = []
    for row in rows:
        parent = row["preferredUnitId"]
        if parent == "b1_04_relationships":
            micro, reason = classify_b1(row)
        elif parent == "b2_06_advanced_capstone":
            micro, reason = classify_b2(row)
        else:
            continue

        assignments.append(
            {
                "sourceId": row["sourceId"],
                "surface": row["surface"],
                "book": row["book"],
                "parentUnitId": parent,
                "microUnitId": micro,
                "microAssignmentReason": reason,
                "canonicalTopicId": row["canonicalTopicId"],
                "textbookRole": row["textbookRole"],
                "lexemeHint": row["lexemeHint"],
                "titleKo": row["titleKo"],
            }
        )

    fields = list(assignments[0].keys())
    with ASSIGN.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(assignments)

    counts = defaultdict(Counter)
    role_counts = defaultdict(Counter)
    manual = []
    for row in assignments:
        micro = row["microUnitId"] or "MANUAL"
        counts[row["parentUnitId"]][micro] += 1
        role_counts[micro][row["textbookRole"]] += 1
        if not row["microUnitId"]:
            manual.append(row)

    payload = {
        "schemaVersion": 1,
        "date": "2026-10-06",
        "status": "MICRO_SPLIT_V1",
        "parents": [],
        "manualMicroReviewCount": len(manual),
    }

    for parent, micros in MICRO_UNITS.items():
        payload["parents"].append(
            {
                "parentUnitId": parent,
                "book": micros[0]["book"],
                "microUnits": [
                    {
                        **m,
                        "assignedSourceCount": counts[parent][m["microUnitId"]],
                        "roleCounts": dict(role_counts[m["microUnitId"]]),
                    }
                    for m in micros
                ],
                "manualReviewCount": counts[parent]["MANUAL"],
            }
        )

    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    lines = [
        "# Micro-unit Split Recommendations — 2026-10-06",
        "",
        "Only two macro-units exceeded the first density threshold. They are split by communicative purpose, not by arbitrary item count.",
        "",
    ]
    for parent in payload["parents"]:
        lines += [f"## {parent['parentUnitId']} ({parent['book']})", ""]
        lines += [
            "| Micro unit | Source rows | CORE | RECYCLE | OPTIONAL | Manual review |",
            "|---|---:|---:|---:|---:|---:|",
        ]
        for m in parent["microUnits"]:
            rc = m["roleCounts"]
            lines.append(
                f"| {m['microUnitId']} — {m['title']['ko']} | {m['assignedSourceCount']:,} | "
                f"{rc.get('CORE',0):,} | {rc.get('RECYCLE',0):,} | {rc.get('OPTIONAL',0):,} | — |"
            )
        lines.append(
            f"| Unresolved within parent | {parent['manualReviewCount']:,} | — | — | — | "
            f"{parent['manualReviewCount']:,} |"
        )
        lines += ["", "### Rationale", ""]
        for m in parent["microUnits"]:
            lines.append(f"- **{m['microUnitId']}**: {m['canDo']['ko']}")
        lines.append("")

    lines += [
        "## Safety rule",
        "",
        "Rows that cannot be classified from source identity, canonical topic, or explicit lexical cues remain in micro-level manual review. They are not force-assigned for the sake of symmetry.",
    ]
    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(
        json.dumps(
            {
                "assigned": sum(1 for r in assignments if r["microUnitId"]),
                "manual": len(manual),
                "parents": {
                    p: dict(c) for p, c in counts.items()
                },
            },
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main()
