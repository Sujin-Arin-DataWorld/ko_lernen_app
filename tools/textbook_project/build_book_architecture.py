#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BLUEPRINT = ROOT / "tools" / "content_factory" / "canonical_scenarios" / "course_unit_blueprint.json"
OUT = ROOT / "docs" / "textbook_project" / "data" / "TEXTBOOK_BOOK_ARCHITECTURE_1A_6B.json"
REPORT = ROOT / "docs" / "textbook_project" / "BOOK_ARCHITECTURE_1A_6B.md"

BOOK_META = {
    "1A": ("A1", "첫 만남과 생존 한국어", "First encounters & survival Korean", "Erste Begegnungen & Überlebens-Koreanisch"),
    "1B": ("A1", "일상과 관계의 시작", "Daily life & first relationships", "Alltag & erste Beziehungen"),
    "2A": ("A2", "계획·메시지·감정", "Plans, messages & feelings", "Pläne, Nachrichten & Gefühle"),
    "2B": ("A2", "서비스·일·이동·집", "Services, work, travel & home", "Service, Arbeit, Unterwegssein & Zuhause"),
    "3A": ("B1", "경험·정보·직장", "Experience, information & work", "Erfahrung, Information & Arbeit"),
    "3B": ("B1", "관계·문제 해결·공동체", "Relationships, problem solving & community", "Beziehungen, Problemlösung & Gemeinschaft"),
    "4A": ("B2", "공식 대화와 협의", "Formal interaction & negotiation", "Formelle Interaktion & Abstimmung"),
    "4B": ("B2", "책임·면접·공동체 판단", "Responsibility, interviews & community judgment", "Verantwortung, Bewerbung & gemeinschaftliche Entscheidungen"),
    "5A": ("C1", "근거·포용·미디어", "Evidence, inclusion & media", "Evidenz, Teilhabe & Medien"),
    "5B": ("C1", "정책·문화노동·관계 경계", "Policy, cultural labor & boundaries", "Politik, Kulturarbeit & Grenzen"),
    "6A": ("C2", "제도·기술윤리·이의제기", "Institutions, tech ethics & redress", "Institutionen, Technikethik & Rechtsbehelf"),
    "6B": ("C2", "책임·기억·담론 권력", "Accountability, memory & discourse power", "Verantwortung, Erinnerung & Diskursmacht"),
}

LEVEL_BOOKS = {
    "a1": ("1A", "1B", 8),
    "a2": ("2A", "2B", 4),
    "b1": ("3A", "3B", 3),
    "b2": ("4A", "4B", 3),
    "c1": ("5A", "5B", 3),
    "c2": ("6A", "6B", 3),
}

UNIT_TOPICS = {
    # A1
    "a1_01_greetings_hangul": ["personal_identification", "social_etiquette_customs"],
    "a1_02_self_intro_identity": ["personal_identification", "family_relationships"],
    "a1_03_topic_subject_particles": ["shopping_consumption"],
    "a1_04_order_request_object": ["food_drink"],
    "a1_05_numbers_time": ["numbers_time_dates", "daily_life_routines"],
    "a1_06_transport_directions": ["transport_wayfinding", "travel_accommodation"],
    "a1_07_contact_address": ["communication_phone_digital"],
    "a1_08_clarify_repair": ["language_learning_communication_repair"],
    "a1_09_home_daily_life": ["house_home", "daily_life_routines"],
    "a1_10_health_safety": ["health_body", "feelings_character"],
    "a1_11_titles_relationships": ["free_time_hobbies_sport", "media_entertainment_culture_pop", "family_relationships"],
    "a1_12_daily_negation": ["food_drink", "shopping_consumption"],
    "a1_13_register_switching": ["social_etiquette_customs", "language_learning_communication_repair"],
    "a1_14_payment_delivery": ["shopping_consumption", "money_finance_contracts", "services_public_admin"],
    "a1_15_first_class_work": ["education_study", "personal_identification", "work_career"],
    "a1_16_survival_capstone": ["daily_life_routines", "weather_nature_climate", "neighbourhood_environment", "technology_digital_ai"],
    # A2
    "a2_01_haeyo_transition": ["free_time_hobbies_sport", "media_entertainment_culture_pop", "feelings_character"],
    "a2_02_plans_proposals": ["daily_life_routines", "numbers_time_dates", "family_relationships", "free_time_hobbies_sport"],
    "a2_03_chat_relationships": ["communication_phone_digital", "family_relationships"],
    "a2_04_feelings_health": ["health_body", "feelings_character"],
    "a2_05_delivery_services": ["shopping_consumption", "services_public_admin", "money_finance_contracts"],
    "a2_06_study_work": ["education_study", "work_career", "technology_digital_ai"],
    "a2_07_travel_repair": ["transport_wayfinding", "travel_accommodation", "services_public_admin"],
    "a2_08_home_money": ["house_home", "money_finance_contracts", "neighbourhood_environment"],
    # B1
    "b1_01_experience_reasons": ["travel_accommodation", "daily_life_routines", "health_body", "free_time_hobbies_sport", "weather_nature_climate"],
    "b1_02_indirect_speech": ["work_career", "communication_phone_digital", "media_entertainment_culture_pop", "science_research_evidence"],
    "b1_03_work_softening": ["work_career", "technology_digital_ai", "education_study"],
    "b1_04_relationships": ["family_relationships", "feelings_character", "social_etiquette_customs", "language_learning_communication_repair"],
    "b1_05_complaint_resolution": ["house_home", "money_finance_contracts", "shopping_consumption", "services_public_admin", "transport_wayfinding", "food_drink"],
    "b1_06_life_capstone": ["neighbourhood_environment", "society_current_affairs", "environment_sustainability", "arts_literature_history", "ethics_philosophy_abstract"],
    # B2
    "b2_01_formal_opening": ["work_career", "services_public_admin", "politics_law_institutions"],
    "b2_02_professional_opinion": ["work_career", "science_research_evidence", "technology_digital_ai", "ethics_philosophy_abstract"],
    "b2_03_precise_requests": ["work_career", "money_finance_contracts", "services_public_admin", "communication_phone_digital"],
    "b2_04_complaint_resolution": ["house_home", "money_finance_contracts", "shopping_consumption", "services_public_admin", "transport_wayfinding", "health_body"],
    "b2_05_interview": ["work_career", "education_study", "personal_identification"],
    "b2_06_advanced_capstone": ["society_current_affairs", "environment_sustainability", "politics_law_institutions", "media_entertainment_culture_pop", "ethics_philosophy_abstract", "social_etiquette_customs", "arts_literature_history"],
    # C1
    "c1_01_evidence_public_reasoning": ["science_research_evidence", "society_current_affairs", "politics_law_institutions", "professional_specialised_fields", "money_finance_contracts"],
    "c1_02_inclusive_sustainable_systems": ["environment_sustainability", "society_current_affairs", "services_public_admin", "house_home", "health_body"],
    "c1_03_media_evidence_literacy": ["media_entertainment_culture_pop", "technology_digital_ai", "science_research_evidence", "communication_phone_digital"],
    "c1_04_play_time_policy": ["education_study", "politics_law_institutions", "technology_digital_ai", "society_current_affairs", "daily_life_routines"],
    "c1_05_fan_labor_sustainability": ["economy_business_labour", "media_entertainment_culture_pop", "work_career", "professional_specialised_fields"],
    "c1_06_intimacy_safety_design": ["family_relationships", "work_career", "health_body", "ethics_philosophy_abstract", "social_etiquette_customs", "feelings_character"],
    # C2
    "c2_01_interpretation_institutions": ["politics_law_institutions", "ethics_philosophy_abstract", "science_research_evidence", "professional_specialised_fields", "society_current_affairs"],
    "c2_02_technology_public_ethics": ["technology_digital_ai", "ethics_philosophy_abstract", "society_current_affairs", "science_research_evidence"],
    "c2_03_automation_redress": ["technology_digital_ai", "politics_law_institutions", "services_public_admin", "money_finance_contracts", "professional_specialised_fields"],
    "c2_04_sanction_accountability": ["politics_law_institutions", "ethics_philosophy_abstract", "economy_business_labour", "professional_specialised_fields", "society_current_affairs"],
    "c2_05_relationship_narratives": ["family_relationships", "arts_literature_history", "intercultural_globalisation_migration", "social_etiquette_customs", "feelings_character"],
    "c2_06_fandom_discourse_power": ["media_entertainment_culture_pop", "ethics_philosophy_abstract", "society_current_affairs", "language_learning_communication_repair", "technology_digital_ai"],
}


def main():
    raw = json.loads(BLUEPRINT.read_text(encoding="utf-8-sig"))
    units = raw["courseUnits"]
    per_level = {}
    for unit in units:
        per_level.setdefault(unit["level"], []).append(unit)

    books = []
    unit_rows = []
    for level, level_units in per_level.items():
        book_a, book_b, split_at = LEVEL_BOOKS[level]
        for idx, unit in enumerate(level_units):
            book = book_a if idx < split_at else book_b
            unit_rows.append(
                {
                    "unitId": unit["unitId"],
                    "level": level.upper(),
                    "book": book,
                    "bookUnitIndex": idx + 1 if book == book_a else idx - split_at + 1,
                    "title": unit["title"],
                    "canDo": unit["canDo"],
                    "checkpointScenarioId": unit["checkpointScenarioId"],
                    "topicIds": UNIT_TOPICS[unit["unitId"]],
                }
            )

    for code, (level, ko, en, de) in BOOK_META.items():
        bu = [x for x in unit_rows if x["book"] == code]
        books.append(
            {
                "book": code,
                "koreanLevel": int(code[0]),
                "cefrLens": level,
                "title": {"ko": ko, "en": en, "de": de},
                "macroUnitCount": len(bu),
                "unitIds": [x["unitId"] for x in bu],
                "policy": "Keep canonical macro-units; split into micro-units only after source-pool density audit.",
            }
        )

    payload = {
        "schemaVersion": 1,
        "date": "2026-10-06",
        "status": "PUBLISHING_ARCHITECTURE_V1",
        "bookCount": 12,
        "macroUnitCount": len(unit_rows),
        "books": books,
        "units": unit_rows,
        "principles": [
            "A-book establishes the level; B-book deepens interaction, register and transfer.",
            "Canonical 48 app macro-units are preserved as the first publishing spine.",
            "Do not invent a 96-unit structure before measuring actual source-pool density.",
            "Micro-units are created only for overloaded or pedagogically heterogeneous macro-units.",
        ],
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    lines = [
        "# 1A–6B Book Architecture",
        "",
        "The first publishing spine preserves the **48 canonical macro-units** and splits them across 12 books.",
        "Micro-units are added only after allocation reveals a real density or pedagogy problem.",
        "",
        "| Book | Level lens | Macro units | Theme |",
        "|---|---|---:|---|",
    ]
    for b in books:
        lines.append(
            f"| {b['book']} | {b['cefrLens']} | {b['macroUnitCount']} | {b['title']['ko']} |"
        )
    lines += ["", "## Units", ""]
    for b in books:
        lines += [f"### {b['book']} — {b['title']['ko']}", ""]
        for uid in b["unitIds"]:
            u = next(x for x in unit_rows if x["unitId"] == uid)
            lines.append(f"- **{uid}** — {u['title']['ko']}")
        lines.append("")
    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"PASS books={len(books)} macro_units={len(unit_rows)}")


if __name__ == "__main__":
    main()
