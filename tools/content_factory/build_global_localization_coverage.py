from __future__ import annotations

import collections
import csv
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "tools/content_factory/review/global_localization_coverage_20261006.json"
TOPIC_LEDGER = ROOT / "tools/content_factory/review/trilingual_content_topic_coverage_20261006.json"
CONTRACT = ROOT / "tools/content_factory/canonical_scenarios/global_localization_contract_20261006.json"
VOCAB = ROOT / "assets/data/korean_vocab.csv"
SMALLTALK = ROOT / "assets/data/smalltalk.json"
CLOZE = ROOT / "assets/data/cloze.json"
SATZ = ROOT / "assets/data/satz_sentences.json"
SCENARIOS = [ROOT / f"assets/data/scenarios_{level}.json" for level in ("a1","a2","b1","b2","c1","c2")]
LIVING = [
    ROOT / "tools/content_factory/drafts/living_korea_scene_first_drafts_20261005.json",
    ROOT / "tools/content_factory/drafts/living_korea_second_wave_scene_first_drafts_20261005.json",
]
LIVING_LOCALIZATION = (
    ROOT / "tools/content_factory/review/living_korea_localization_20261006.json"
)

# Stable source taxonomies that can be mapped to one canonical native-usage topic
# without inspecting the localized copy. Mixed smalltalk buckets are handled by
# phrase-level overrides below rather than being force-mapped as a whole.
VOCAB_TOPIC_TO_CANONICAL = {
    "Begrüßung": "social_etiquette_customs",
    "Geographie": "travel_accommodation",
    "Farben": "shopping_consumption",
    "Automatisierung & Rechtsweg": "technology_digital_ai",
    "Modernes Leben": "society_current_affairs",
    "Sicherheit & Regeln": "politics_law_institutions",
    "Formelle Vereinbarungen": "money_finance_contracts",
    "Fundsachen": "services_public_admin",
    "Dienstmail": "work_career",
    "Reise & Verkehr": "transport_wayfinding",
    "Digitale Aufmerksamkeit": "technology_digital_ai",
    "Bankschalter": "money_finance_contracts",
    "Risikosprache": "professional_specialised_fields",
    "Formelle Beschwerde & Abhilfe": "services_public_admin",
    "Sprache & Gesellschaft": "language_learning_communication_repair",
    "Sprache und Wandel": "language_learning_communication_repair",
    "Betriebslast": "professional_specialised_fields",
    "Framinganalyse": "professional_specialised_fields",
    "Sprache, Deutung & Macht": "ethics_philosophy_abstract",
    "Autoritätssprache": "politics_law_institutions",
    "Widerrufsrecht": "politics_law_institutions",
    "Medien & Evidenz": "science_research_evidence",
    "Fanarbeit & Belastung": "economy_business_labour",
    "AI 투명성과 문화 노동": "technology_digital_ai",
    "Risiko & öffentliche Information": "society_current_affairs",
    "Technikethik & Verantwortung": "ethics_philosophy_abstract",
    "Wochenendzusage": "daily_life_routines",
    "Handytarif": "communication_phone_digital",
    "Fitnesskurs": "free_time_hobbies_sport",
    "Zugangskosten": "society_current_affairs",
    "Ortliche Abwägung": "neighbourhood_environment",
    "Diskurs, Macht & Verantwortung": "ethics_philosophy_abstract",
    "Wohnen & Vertrag": "house_home",
    "Bürgerversammlung": "politics_law_institutions",
    "인구 담론과 제도 책임": "society_current_affairs",
    "주거비와 사회 통합": "intercultural_globalisation_migration",
}

SMALLTALK_CATEGORY_TO_CANONICAL = {
    "weather": "weather_nature_climate",
    "mood": "feelings_character",
    "weekend": "free_time_hobbies_sport",
    "food": "food_drink",
    "daily": "daily_life_routines",
    "screen": "media_entertainment_culture_pop",
    "music": "media_entertainment_culture_pop",
    "hobby": "free_time_hobbies_sport",
    "travel": "travel_accommodation",
    "family": "family_relationships",
    "health": "health_body",
    "kpop": "media_entertainment_culture_pop",
    "dating": "family_relationships",
    "interview": "work_career",
    "job_hunting": "work_career",
    "moving": "house_home",
    "hospital": "health_body",
    "transport": "transport_wayfinding",
    "shopping": "shopping_consumption",
    "phone": "communication_phone_digital",
    "partner_family": "family_relationships",
    "theme_park_date": "free_time_hobbies_sport",
}

SMALLTALK_PHRASE_TOPIC_OVERRIDES = {
    "smalltalk_a1_0011": "work_career",
    "smalltalk_a2_0010": "work_career",
    "smalltalk_b1_0010": "work_career",
    "smalltalk_b2_0010": "work_career",
    "smalltalk_a1_0023": "work_career",
    "smalltalk_a2_0022": "education_study",
    "smalltalk_b1_0022": "work_career",
    "smalltalk_b2_0022": "work_career",
    "smalltalk_b1_0045": "work_career",
    "smalltalk_b1_0046": "work_career",
    "smalltalk_b1_0047": "work_career",
    "smalltalk_b1_0048": "work_career",
    "smalltalk_b2_0065": "work_career",
    "smalltalk_b2_0066": "work_career",
    "smalltalk_b2_0070": "science_research_evidence",
    "smalltalk_b2_0072": "work_career",
    "smalltalk_b2_0078": "work_career",
    "smalltalk_c1_0003": "science_research_evidence",
    "smalltalk_c1_0004": "science_research_evidence",
    "smalltalk_c1_0008": "science_research_evidence",
    "smalltalk_c1_0011": "science_research_evidence",
    "smalltalk_c1_0014": "professional_specialised_fields",
    "smalltalk_c2_0001": "politics_law_institutions",
    "smalltalk_c2_0003": "ethics_philosophy_abstract",
    "smalltalk_c2_0006": "arts_literature_history",
    "smalltalk_c2_0008": "ethics_philosophy_abstract",
    "smalltalk_c2_0011": "ethics_philosophy_abstract",
    "smalltalk_c2_0013": "technology_digital_ai",
    "smalltalk_c2_0015": "technology_digital_ai",
    "smalltalk_c1_0017": "science_research_evidence",
    "smalltalk_c1_0018": "science_research_evidence",
    "smalltalk_b1_0071": "work_career",
    "smalltalk_c1_0023": "science_research_evidence",
    "smalltalk_c2_0023": "ethics_philosophy_abstract",
    "smalltalk_c1_0035": "technology_digital_ai",
    "smalltalk_c1_0036": "technology_digital_ai",
    "smalltalk_c2_0037": "intercultural_globalisation_migration",
    "smalltalk_c2_0038": "intercultural_globalisation_migration",
    "smalltalk_b1_0076": "work_career",
    "smalltalk_b1_0077": "work_career",
    "smalltalk_b1_0078": "work_career",
    "smalltalk_c1_0075": "technology_digital_ai",
    "smalltalk_c2_0073": "science_research_evidence",
    "smalltalk_c2_0076": "ethics_philosophy_abstract",
    "smalltalk_c2_0087": "social_etiquette_customs",
    "smalltalk_c2_0088": "social_etiquette_customs",
    "smalltalk_c2_0089": "social_etiquette_customs",
    "smalltalk_c2_0090": "language_learning_communication_repair",
    "smalltalk_a1_0054": "services_public_admin",
    "smalltalk_a1_0055": "services_public_admin",
    "smalltalk_a1_0056": "health_body",
    "smalltalk_a1_0057": "services_public_admin",
    "smalltalk_a1_0058": "services_public_admin",
    "smalltalk_a2_0053": "travel_accommodation",
    "smalltalk_a2_0054": "services_public_admin",
    "smalltalk_a2_0055": "services_public_admin",
    "smalltalk_b1_0043": "services_public_admin",
    "smalltalk_b1_0044": "services_public_admin",
    "smalltalk_b2_0043": "services_public_admin",
    "smalltalk_b2_0044": "services_public_admin",
    "smalltalk_c1_0070": "services_public_admin",
    "smalltalk_c1_0071": "science_research_evidence",
    "smalltalk_c2_0069": "politics_law_institutions",
    "smalltalk_c2_0070": "technology_digital_ai",
}


def inferred_topic_row(topic_id: str, basis: str) -> dict[str, Any]:
    return {
        "canonicalTopicId": topic_id,
        "researchCoverageStatus": "topic_profile_deep_pass_complete",
        "mappingEvidence": basis,
    }


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def text_present(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def localized_presence(ko: Any, en: Any, de: Any) -> dict[str, bool]:
    return {"ko": text_present(ko), "en": text_present(en), "de": text_present(de)}


def base_record(
    *,
    surface_type: str,
    item_id: str,
    source_path: Path,
    ko: str,
    en: str,
    de: str,
    owner_kind: str,
    owner_id: str,
    approval_state: str,
    topic_row: dict[str, Any] | None,
    derived: bool,
    notes: str = "",
) -> dict[str, Any]:
    presence = localized_presence(ko, en, de)
    row = {
        "surfaceType": surface_type,
        "itemId": item_id,
        "sourcePath": source_path.relative_to(ROOT).as_posix(),
        "approvalState": approval_state,
        "ownerKind": owner_kind,
        "ownerId": owner_id,
        "derived": derived,
        "ko": ko,
        "en": en,
        "de": de,
        "localizedPresence": presence,
        "allThreePresent": all(presence.values()),
        "canonicalTopicId": (topic_row or {}).get("canonicalTopicId"),
        "researchCoverageStatus": (topic_row or {}).get(
            "researchCoverageStatus", "manual_topic_review_required"
        ),
        "qaStatus": "inventory_only",
        "promotionStatus": "live_existing" if approval_state == "live" else "not_live",
    }
    if notes:
        row["notes"] = notes
    if (topic_row or {}).get("mappingEvidence"):
        row["topicMappingEvidence"] = topic_row["mappingEvidence"]
    if row["canonicalTopicId"] is None:
        row["topicReviewStatus"] = "manual_topic_review_required"
    else:
        row["topicReviewStatus"] = "mapped"
    return row


def build() -> dict[str, Any]:
    topic_ledger = load_json(TOPIC_LEDGER)
    topic_index: dict[tuple[str, str], dict[str, Any]] = {
        (r["kind"], r["itemId"]): r for r in topic_ledger["records"]
    }
    records: list[dict[str, Any]] = []

    # Canonical word/expression owners and every canonical vocab example.
    with VOCAB.open(encoding="utf-8-sig", newline="") as handle:
        vocab_rows = list(csv.DictReader(handle))

    vocab_example_owner: dict[tuple[str, str], str] = {}
    vocab_example_by_ko: dict[str, list[str]] = collections.defaultdict(list)
    for row in vocab_rows:
        vocab_id = row["id"]
        topic_row = topic_index.get(("vocab", vocab_id))
        if not (topic_row or {}).get("canonicalTopicId"):
            canonical = VOCAB_TOPIC_TO_CANONICAL.get(str(row.get("topic") or "").strip())
            if canonical:
                topic_row = inferred_topic_row(
                    canonical, f"vocab.topic={row.get('topic','')}"
                )
        records.append(
            base_record(
                surface_type="vocab_lexeme",
                item_id=vocab_id,
                source_path=VOCAB,
                ko=row.get("korean", ""),
                en=row.get("english", ""),
                de=row.get("german", ""),
                owner_kind="canonical_owner",
                owner_id=vocab_id,
                approval_state="live",
                topic_row=topic_row,
                derived=False,
                notes=f"POS EN={row.get('pos_en','')} / DE={row.get('pos_de','')}",
            )
        )
        example_id = f"{vocab_id}#example"
        records.append(
            base_record(
                surface_type="vocab_example",
                item_id=example_id,
                source_path=VOCAB,
                ko=row.get("example_korean", ""),
                en=row.get("example_english", ""),
                de=row.get("example_german", ""),
                owner_kind="canonical_owner",
                owner_id=example_id,
                approval_state="live",
                topic_row=topic_row,
                derived=False,
                notes=f"targetLexeme={row.get('korean','')}",
            )
        )
        key = (row.get("korean", "").strip(), row.get("example_korean", "").strip())
        vocab_example_owner[key] = example_id
        if row.get("example_korean", "").strip():
            vocab_example_by_ko[row["example_korean"].strip()].append(example_id)

    # Canonical conversational expressions plus explicit variant/follow-up copy.
    smalltalk = load_json(SMALLTALK)
    for phrase in smalltalk.get("phrases", []):
        phrase_id = phrase["id"]
        topic_row = topic_index.get(("smalltalk", phrase_id))
        if not (topic_row or {}).get("canonicalTopicId"):
            override = SMALLTALK_PHRASE_TOPIC_OVERRIDES.get(phrase_id)
            if override:
                topic_row = inferred_topic_row(override, f"smalltalk.phrase={phrase_id}")
            else:
                category = str(phrase.get("category") or "").strip()
                canonical = SMALLTALK_CATEGORY_TO_CANONICAL.get(category)
                if canonical:
                    topic_row = inferred_topic_row(canonical, f"smalltalk.category={category}")
        records.append(
            base_record(
                surface_type="smalltalk_expression",
                item_id=phrase_id,
                source_path=SMALLTALK,
                ko=phrase.get("ko", ""),
                en=phrase.get("en", ""),
                de=phrase.get("de", ""),
                owner_kind="canonical_owner",
                owner_id=phrase_id,
                approval_state="live",
                topic_row=topic_row,
                derived=False,
                notes=f"relationshipContext={phrase.get('relationshipContext','')}",
            )
        )
        for i, alt in enumerate(phrase.get("safeAlternativeQuestions", []), 1):
            alt_id = f"{phrase_id}#safe_alt_{i}"
            records.append(
                base_record(
                    surface_type="smalltalk_expression_variant",
                    item_id=alt_id,
                    source_path=SMALLTALK,
                    ko=alt.get("ko", ""),
                    en=alt.get("en", ""),
                    de=alt.get("de", ""),
                    owner_kind="canonical_owner",
                    owner_id=alt_id,
                    approval_state="live",
                    topic_row=topic_row,
                    derived=False,
                    notes="safeAlternativeQuestion",
                )
            )
        follow = phrase.get("followUp") or {}
        if isinstance(follow, dict) and follow.get("ko"):
            follow_id = f"{phrase_id}#followup"
            records.append(
                base_record(
                    surface_type="smalltalk_followup",
                    item_id=follow_id,
                    source_path=SMALLTALK,
                    ko=follow.get("ko", ""),
                    en=follow.get("en", ""),
                    de=follow.get("de", ""),
                    owner_kind="canonical_owner",
                    owner_id=follow_id,
                    approval_state="live",
                    topic_row=topic_row,
                    derived=False,
                    notes=f"turnKind={follow.get('turnKind','')}",
                )
            )

    # Existing live scenario dialogue is a canonical dialogue owner surface.
    for path in SCENARIOS:
        payload = load_json(path)
        for scene in payload.get("scenarios", []):
            topic_row = topic_index.get(("scenario", scene["id"]))
            for idx, turn in enumerate(scene.get("dialog", []), 1):
                records.append(
                    base_record(
                        surface_type="scenario_dialogue_turn",
                        item_id=f"{scene['id']}#turn_{idx}",
                        source_path=path,
                        ko=turn.get("ko", ""),
                        en=turn.get("en", ""),
                        de=turn.get("de", ""),
                        owner_kind="canonical_owner",
                        owner_id=f"{scene['id']}#turn_{idx}",
                        approval_state="live",
                        topic_row=topic_row,
                        derived=False,
                        notes=f"speaker={turn.get('speaker','')}; scene={scene['id']}",
                    )
                )

    # Living Korea is the first review-only reference batch to receive the new QA
    # contract. Its localized review artifact is the EN/DE owner; the Korean scene
    # draft remains the canonical semantic source.
    living_localization = load_json(LIVING_LOCALIZATION)
    localized_turns = {
        (scene["sceneId"], turn["turnIndex"]): turn
        for scene in living_localization["scenes"]
        for turn in scene["turns"]
    }
    for path in LIVING:
        payload = load_json(path)
        for arc in payload["arcs"]:
            for scene in arc["scenes"]:
                topic_row = topic_index.get(("living_korea_scene", scene["id"]))
                for idx, turn in enumerate(scene["dialog"], 1):
                    localized = localized_turns.get((scene["id"], idx), {})
                    records.append(
                        base_record(
                            surface_type="living_korea_turn",
                            item_id=f"{scene['id']}#turn_{idx}",
                            source_path=path,
                            ko=turn.get("ko", ""),
                            en=localized.get("enDisplay", ""),
                            de=localized.get("deDisplay", ""),
                            owner_kind="canonical_owner",
                            owner_id=f"{scene['id']}#turn_{idx}",
                            approval_state="user_reviewed_not_live",
                            topic_row=topic_row,
                            derived=False,
                            notes=(
                                f"speaker={turn.get('speaker','')}; scene={scene['id']}; "
                                "localized in living_korea_localization_20261006.json"
                            ),
                        )
                    )

    # Derived cloze translations should reconcile to the canonical vocab example.
    for item in load_json(CLOZE).get("items", []):
        key = (str(item.get("answer", "")).strip(), str(item.get("fullKo", "")).strip())
        owner_id = vocab_example_owner.get(key)
        if owner_id is None:
            candidates = vocab_example_by_ko.get(str(item.get("fullKo", "")).strip(), [])
            owner_id = candidates[0] if len(candidates) == 1 else ""
        topic_row = topic_index.get(("cloze", item["id"]))
        records.append(
            base_record(
                surface_type="cloze_translation",
                item_id=item["id"],
                source_path=CLOZE,
                ko=item.get("fullKo", ""),
                en=item.get("en", ""),
                de=item.get("de", ""),
                owner_kind="derived_from_vocab_example" if owner_id else "unresolved_owner",
                owner_id=owner_id,
                approval_state="live",
                topic_row=topic_row,
                derived=True,
                notes="Do not edit independently when an owner is resolved.",
            )
        )

    # Derived sentence-building prompts should reconcile to the canonical vocab example.
    vocab_by_target: dict[tuple[str, str], str] = {}
    for row in vocab_rows:
        vocab_by_target[(row.get("korean", "").strip(), row.get("example_korean", "").strip())] = (
            f"{row['id']}#example"
        )
    for item in load_json(SATZ).get("items", []):
        owner_id = vocab_by_target.get(
            (str(item.get("vocabKo", "")).strip(), str(item.get("targetKo", "")).strip()),
            "",
        )
        if not owner_id:
            candidates = vocab_example_by_ko.get(str(item.get("targetKo", "")).strip(), [])
            owner_id = candidates[0] if len(candidates) == 1 else ""
        topic_row = topic_index.get(("satz", item["id"]))
        records.append(
            base_record(
                surface_type="satz_prompt",
                item_id=item["id"],
                source_path=SATZ,
                ko=item.get("targetKo", ""),
                en=item.get("promptEn", ""),
                de=item.get("promptDe", ""),
                owner_kind="derived_from_vocab_example" if owner_id else "unresolved_owner",
                owner_id=owner_id,
                approval_state="live",
                topic_row=topic_row,
                derived=True,
                notes="Do not edit independently when an owner is resolved.",
            )
        )

    by_type: dict[str, dict[str, int]] = {}
    for surface in sorted({r["surfaceType"] for r in records}):
        subset = [r for r in records if r["surfaceType"] == surface]
        by_type[surface] = {
            "total": len(subset),
            "allThreePresent": sum(r["allThreePresent"] for r in subset),
            "topicMapped": sum(r["canonicalTopicId"] is not None for r in subset),
            "ownerResolved": sum(bool(r["ownerId"]) for r in subset),
            "derived": sum(r["derived"] for r in subset),
        }

    owner_records = [r for r in records if not r["derived"]]
    derived_records = [r for r in records if r["derived"]]
    payload = {
        "schemaVersion": 1,
        "generatedDate": "2026-10-06",
        "generatedBy": "tools/content_factory/build_global_localization_coverage.py",
        "status": "GLOBAL_LOCALIZATION_INVENTORY_ACTIVE",
        "contract": CONTRACT.relative_to(ROOT).as_posix(),
        "topicCoverageLedger": TOPIC_LEDGER.relative_to(ROOT).as_posix(),
        "policy": {
            "koreanIsSourceOfTruth": True,
            "ownerFirstLocalization": True,
            "derivedSurfacesMustReconcileToOwner": True,
            "inventoryDoesNotImplyQa": True,
            "inventoryDoesNotImplyPromotion": True,
            "ttsAudioUntouched": True,
        },
        "summary": {
            "trackedSurfaceCount": len(records),
            "canonicalOwnerSurfaceCount": len(owner_records),
            "derivedSurfaceCount": len(derived_records),
            "allThreePresentCount": sum(r["allThreePresent"] for r in records),
            "missingLocalizedFieldCount": sum(not r["allThreePresent"] for r in records),
            "topicMappedCount": sum(r["canonicalTopicId"] is not None for r in records),
            "explicitTopicReviewCount": sum(r["canonicalTopicId"] is None for r in records),
            "derivedOwnerResolvedCount": sum(bool(r["ownerId"]) for r in derived_records),
            "derivedOwnerUnresolvedCount": sum(not r["ownerId"] for r in derived_records),
            "bySurfaceType": by_type,
        },
        "records": records,
    }
    return payload


def main() -> None:
    payload = build()
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload["summary"], ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
