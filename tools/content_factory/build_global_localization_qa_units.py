from __future__ import annotations

import hashlib
import json
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
COVERAGE = ROOT / "tools/content_factory/review/global_localization_coverage_20261006.json"
OUTPUT = ROOT / "tools/content_factory/review/global_localization_qa_units_20261006.json"
DECISIONS = ROOT / "tools/content_factory/review/global_localization_qa_decisions_20261006.json"

SMALLTALK_OWNER_TYPES = {
    "smalltalk_expression",
    "smalltalk_expression_variant",
    "smalltalk_followup",
}
G4_TYPES = {
    "scenario_dialogue_turn",
    "culture_editorial_note",
    "culture_story_title",
    "culture_story_summary",
    "listening_lesson_intro",
    "listening_lesson_title",
    "listening_question_explanation",
    "listening_question_option",
    "listening_question_prompt",
    "smalltalk_lesson_intro",
    "smalltalk_lesson_title",
    "smalltalk_question_explanation",
    "smalltalk_question_option",
    "smalltalk_question_prompt",
}
TARGET_TYPES = SMALLTALK_OWNER_TYPES | G4_TYPES

SENSITIVE_TOPICS = {
    "health_body",
    "money_finance_contracts",
    "services_public_admin",
    "politics_law_institutions",
    "economy_business_labour",
    "science_research_evidence",
    "technology_digital_ai",
    "professional_specialised_fields",
}
REGISTER_SENSITIVE_TOPICS = {
    "work_career",
    "social_etiquette_customs",
    "intercultural_globalisation_migration",
    "education_study",
}
PEDAGOGICAL_TYPES = {
    "listening_lesson_intro",
    "listening_lesson_title",
    "listening_question_explanation",
    "listening_question_option",
    "listening_question_prompt",
    "smalltalk_lesson_intro",
    "smalltalk_lesson_title",
    "smalltalk_question_explanation",
    "smalltalk_question_option",
    "smalltalk_question_prompt",
}
EDITORIAL_TYPES = {"culture_editorial_note", "culture_story_title", "culture_story_summary"}

HANGUL = re.compile(r"[가-힣]")
DU = re.compile(r"\b(?:du|dir|dich|dein\w*)\b", re.I)
FORMAL_SECOND_PERSON = re.compile(r"\b(?:Ihnen|Ihrem|Ihren|Ihrer|Ihres|Ihre|Ihr)\b")
FORMAL_LET_US = re.compile(r"\bLet us\b")
KNOWN_LITERAL_EN = re.compile(
    r"customer center|civil affairs|make a reservation for|do a reservation",
    re.I,
)


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))



def stable_review_key(ko: str, occurrence_ids: list[str]) -> str:
    raw = ko + "\u241f" + "\u241f".join(sorted(occurrence_ids))
    return hashlib.sha1(raw.encode("utf-8")).hexdigest()[:16]


def decision_index() -> dict[str, dict[str, Any]]:
    if not DECISIONS.exists():
        return {}
    payload = load_json(DECISIONS)
    return {str(row["stableReviewKey"]): row for row in payload.get("decisions", [])}

def register_lane(record: dict[str, Any], ko: str, en: str, de: str) -> str:
    surface = str(record.get("surfaceType") or "")
    topic = str(record.get("canonicalTopicId") or "")
    notes = str(record.get("notes") or "")
    if surface in PEDAGOGICAL_TYPES:
        return "pedagogical_metalinguistic"
    if surface in EDITORIAL_TYPES:
        return "editorial_culture"
    if topic in {"work_career", "professional_specialised_fields", "economy_business_labour"}:
        return "work_professional"
    if topic in {"services_public_admin", "politics_law_institutions", "science_research_evidence"}:
        return "institutional_public"
    if "relationshipContext=peer" in notes or DU.search(de):
        return "everyday_casual"
    if FORMAL_SECOND_PERSON.search(de) or ko.rstrip().endswith(("습니다.", "세요.", "습니까?")):
        return "service_polite"
    return "everyday_neutral"


def risk_signals(ko: str, en: str, de: str) -> list[str]:
    signals: list[str] = []
    ko_q = ko.rstrip().endswith("?")
    if ko_q != en.rstrip().endswith("?"):
        signals.append("en_question_mismatch")
    if ko_q != de.rstrip().endswith("?"):
        signals.append("de_question_mismatch")
    if DU.search(de) and FORMAL_SECOND_PERSON.search(de):
        signals.append("de_du_sie_mixed")
    if FORMAL_LET_US.search(en):
        signals.append("formal_let_us")
    if KNOWN_LITERAL_EN.search(en):
        signals.append("known_literal_en")
    ko_words = max(1, len(ko.split()))
    if len(en.split()) >= max(12, ko_words * 3 + 3):
        signals.append("en_length_extreme")
    if len(de.split()) >= max(12, ko_words * 3 + 3):
        signals.append("de_length_extreme")
    # Hangul is common and intentional in pedagogical explanations/options.
    # Keep it as a review note rather than a P0 defect signal.
    if HANGUL.search(en):
        signals.append("embedded_korean_en")
    if HANGUL.search(de):
        signals.append("embedded_korean_de")
    return signals


def priority_for(
    topic_ids: set[str],
    lane: str,
    signals: list[str],
) -> tuple[str, str]:
    strong = {
        "formal_let_us",
        "known_literal_en",
    }
    if strong.intersection(signals):
        return "P0", "explicit_native_risk_signal"
    if topic_ids.intersection(SENSITIVE_TOPICS):
        return "P1", "sensitive_domain"
    if lane in {"work_professional", "institutional_public", "service_polite"} or topic_ids.intersection(
        REGISTER_SENSITIVE_TOPICS
    ):
        return "P2", "register_sensitive"
    if lane in {"pedagogical_metalinguistic", "editorial_culture"}:
        return "P3", "pedagogical_or_editorial"
    return "P4", "everyday_core"


def main() -> None:
    coverage = load_json(COVERAGE)
    decisions = decision_index()
    groups: dict[tuple[str, str, str], list[dict[str, Any]]] = defaultdict(list)
    for record in coverage["records"]:
        if record.get("surfaceType") not in TARGET_TYPES:
            continue
        key = (
            str(record.get("ko") or ""),
            str(record.get("en") or ""),
            str(record.get("de") or ""),
        )
        groups[key].append(record)

    units: list[dict[str, Any]] = []
    for (ko, en, de), occurrences in groups.items():
        topic_ids = {str(r.get("canonicalTopicId") or "") for r in occurrences}
        topic_ids.discard("")
        lanes = Counter(register_lane(r, ko, en, de) for r in occurrences)
        lane = lanes.most_common(1)[0][0]
        signals = risk_signals(ko, en, de)
        priority, priority_reason = priority_for(topic_ids, lane, signals)
        digest = hashlib.sha1((ko + "\u241f" + en + "\u241f" + de).encode("utf-8")).hexdigest()[:12]
        occurrence_ids = sorted(str(r["itemId"]) for r in occurrences)
        stable_key = stable_review_key(ko, occurrence_ids)
        decision = decisions.get(stable_key)
        units.append(
            {
                "unitId": f"qa_{digest}",
                "stableReviewKey": stable_key,
                "ko": ko,
                "en": en,
                "de": de,
                "canonicalTopicIds": sorted(topic_ids),
                "registerLane": lane,
                "registerLaneEvidence": dict(sorted(lanes.items())),
                "riskTier": priority,
                "riskReason": priority_reason,
                "riskSignals": signals,
                "occurrenceCount": len(occurrences),
                "surfaceTypes": sorted({str(r["surfaceType"]) for r in occurrences}),
                "occurrenceIds": occurrence_ids,
                "sourcePaths": sorted({str(r["sourcePath"]) for r in occurrences}),
                "approvalStates": sorted({str(r.get("approvalState") or "") for r in occurrences}),
                "qaStatus": (decision.get("qaStatus") if decision else "pending_model_native_qa"),
                "qaDecision": (decision.get("decision") if decision else None),
                "qaNote": (decision.get("note") if decision else None),
                "modelReviewedDate": (decision.get("reviewedDate") if decision else None),
                "humanNativeReviewStatus": "not_reviewed",
            }
        )

    priority_order = {"P0": 0, "P1": 1, "P2": 2, "P3": 3, "P4": 4}
    units.sort(
        key=lambda u: (
            priority_order[u["riskTier"]],
            ",".join(u["canonicalTopicIds"]),
            u["registerLane"],
            u["unitId"],
        )
    )

    # Batch by priority + primary topic + register. Keep review packets <= 80 unique units.
    batches: list[dict[str, Any]] = []
    grouped: dict[tuple[str, str, str], list[dict[str, Any]]] = defaultdict(list)
    for unit in units:
        primary_topic = unit["canonicalTopicIds"][0] if unit["canonicalTopicIds"] else "unmapped"
        grouped[(unit["riskTier"], primary_topic, unit["registerLane"])].append(unit)

    batch_index: dict[str, str] = {}
    serial = 1
    for key in sorted(grouped, key=lambda k: (priority_order[k[0]], k[1], k[2])):
        risk, topic, lane = key
        members = grouped[key]
        for start in range(0, len(members), 80):
            chunk = members[start : start + 80]
            batch_id = f"GLQ-{serial:03d}"
            serial += 1
            for unit in chunk:
                batch_index[unit["unitId"]] = batch_id
            batches.append(
                {
                    "batchId": batch_id,
                    "riskTier": risk,
                    "canonicalTopicId": topic,
                    "registerLane": lane,
                    "unitCount": len(chunk),
                    "occurrenceCount": sum(u["occurrenceCount"] for u in chunk),
                    "unitIds": [u["unitId"] for u in chunk],
                    "qaStatus": (
                        "model_direct_ko_review_complete"
                        if all(not u["qaStatus"].startswith("pending") for u in chunk)
                        else "pending_model_native_qa"
                    ),
                }
            )
    for unit in units:
        unit["batchId"] = batch_index[unit["unitId"]]

    by_risk = Counter(u["riskTier"] for u in units)
    by_register = Counter(u["registerLane"] for u in units)
    by_surface = Counter()
    for unit in units:
        for surface in unit["surfaceTypes"]:
            by_surface[surface] += 1

    payload = {
        "schemaVersion": 1,
        "generatedDate": "2026-10-06",
        "generatedBy": "tools/content_factory/build_global_localization_qa_units.py",
        "status": "GLOBAL_LOCALIZATION_NATIVE_QA_QUEUE",
        "policy": {
            "dedupeRule": "Exact KO/EN/DE triples are reviewed once; every original occurrence remains traceable.",
            "ordering": "P0 explicit native-risk signals -> P1 sensitive domains -> P2 register-sensitive -> P3 pedagogical/editorial -> P4 everyday core.",
            "humanNativeSignoff": False,
            "ttsOwnership": "Jin; this queue may review spoken-surface text but never generate or overwrite audio.",
        },
        "summary": {
            "rawOccurrenceCount": sum(u["occurrenceCount"] for u in units),
            "uniqueQaUnitCount": len(units),
            "batchCount": len(batches),
            "pendingQaUnitCount": sum(u["qaStatus"].startswith("pending") for u in units),
            "modelReviewedQaUnitCount": sum(not u["qaStatus"].startswith("pending") for u in units),
            "byRiskTier": dict(sorted(by_risk.items())),
            "byRegisterLane": dict(sorted(by_register.items())),
            "uniqueUnitsBySurfaceType": dict(sorted(by_surface.items())),
            "allUnitsHaveTopic": all(bool(u["canonicalTopicIds"]) for u in units),
            "allUnitsHaveBatch": all(bool(u["batchId"]) for u in units),
        },
        "batches": batches,
        "units": units,
    }
    OUTPUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload["summary"], ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
