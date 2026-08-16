#!/usr/bin/env python3
"""Build the canonical 86-segment course catalog from reviewed source IDs.

The immutable segment denominator is authored here. Raw learning records are
validated as practice provenance only; their count never creates segments.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "assets" / "data"
CATALOG_PATH = DATA / "can_do_segments.json"
AUTHORITY_PATH = DATA / "can_do_content_authorities.json"
PUBLISHED_AT = "2026-08-16T00:00:00.000Z"
LEVELS = ("a1", "a2", "b1", "b2", "c1", "c2")
EXPECTED_COUNTS = {"a1": 16, "a2": 16, "b1": 18, "b2": 20, "c1": 8, "c2": 8}
REVIEW_BATCH_MANIFEST_PATHS = (
    ROOT / "tools" / "content_factory" / "drafts" / "batch_06_manifest.json",
)

# A review-batch record may enter a live source asset only after an explicit
# human-approved promotion. Practice provenance is never assessment authority.
REVIEW_CONTENT_PROMOTIONS: dict[tuple[str, str], dict[str, Any]] = {}
PRACTICE_ONLY_KINDS = frozenset(
    {"pronunciation", "cloze", "satz", "smalltalk", "scenario"}
)

# Human-review hints only. These IDs are deliberately not consulted by routing;
# final review must copy an approved target into REVIEW_CONTENT_PROMOTIONS.
BATCH06_PROVISIONAL_SCENARIO_TARGETS = {
    "b1_repair_visit_followup": "b1_property_damage_report",
    "b2_device_failure_escalation": "b2_remedy_and_appeal",
    "c1_survey_limits_briefing": "c1_evidence_limits_conclusion",
    "c2_automated_decision_appeal": "c2_technology_traceability_appeal",
}

MODE_SUFFIX = {
    "guidedProduction": "guided_production",
    "dictation": "dictation",
    "connectedProduction": "connected_production",
    "openWriting": "open_writing",
    "oralProduction": "oral_production",
    "connectedEvidence": "connected_evidence",
}


@dataclass(frozen=True)
class PracticeRef:
    kind: str
    id: str
    source_seed_id: str | None = None


@dataclass(frozen=True)
class SegmentSpec:
    key: str
    level: str
    parent: str
    refs: tuple[PracticeRef, ...]
    mode: str = "connectedProduction"
    title: dict[str, str] | None = None
    can_do: dict[str, str] | None = None
    concepts: tuple[str, ...] | None = None
    source_seed_ids: tuple[str, ...] | None = None


def _text(ko: str, de: str, en: str) -> dict[str, str]:
    return {"ko": ko, "de": de, "en": en}


def _ref(kind: str, content_id: str, seed: str | None = None) -> PracticeRef:
    return PracticeRef(kind=kind, id=content_id, source_seed_id=seed)


def _scenario_spec(
    key: str,
    level: str,
    parent: str,
    scenario_id: str,
    mode: str = "connectedProduction",
) -> SegmentSpec:
    return SegmentSpec(
        key=key,
        level=level,
        parent=parent,
        refs=(_ref("scenario", scenario_id),),
        mode=mode,
    )


def _named_spec(
    key: str,
    level: str,
    parent: str,
    kind: str,
    content_id: str,
    title: tuple[str, str, str],
    mode: str,
) -> SegmentSpec:
    localized_title = _text(*title)
    return SegmentSpec(
        key=key,
        level=level,
        parent=parent,
        refs=(_ref(kind, content_id),),
        mode=mode,
        title=localized_title,
        can_do=_generic_can_do(localized_title),
    )


def _generic_can_do(title: dict[str, str]) -> dict[str, str]:
    return _text(
        f"{title['ko']} 상황에서 필요한 정보를 연결해 목적을 이룰 수 있어요.",
        f"Ich kann die Aufgabe „{title['de']}“ mit passenden koreanischen Ausdrücken bewältigen.",
        f"I can complete “{title['en']}” by connecting appropriate Korean expressions.",
    )


def _json_fingerprint(value: Any) -> str:
    canonical = json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(canonical).hexdigest()


A1_PRACTICE: dict[str, tuple[str, str, str]] = {
    "a1_01_greetings_hangul": ("scenario", "airport_arrival", "guidedProduction"),
    "a1_02_self_intro_identity": ("scenario", "introduce_yourself", "connectedProduction"),
    "a1_03_topic_subject_particles": ("scenario", "mart_grocery", "guidedProduction"),
    "a1_04_order_request_object": ("scenario", "bunshik_tteokbokki", "guidedProduction"),
    "a1_05_numbers_time": ("vocabPack", "a1_numbers_1", "dictation"),
    "a1_06_transport_directions": ("scenario", "taxi_kakao", "guidedProduction"),
    "a1_07_contact_address": ("scenario", "phone_messenger_reply", "dictation"),
    "a1_08_clarify_repair": ("scenario", "clarify_repeat", "guidedProduction"),
    "a1_09_home_daily_life": ("scenario", "home_morning_routine", "connectedProduction"),
    "a1_10_health_safety": ("scenario", "clinic_safety", "connectedProduction"),
    "a1_11_titles_relationships": ("scenario", "titles_relationship_distance", "guidedProduction"),
    "a1_12_daily_negation": ("vocabPack", "a1_daily_1", "guidedProduction"),
    "a1_13_register_switching": ("cloze", "cloze_a1_0076", "connectedProduction"),
    "a1_14_payment_delivery": ("scenario", "delivery_address_confirmation", "dictation"),
    "a1_15_first_class_work": ("scenario", "first_class_meeting", "connectedProduction"),
    "a1_16_survival_capstone": ("scenario", "survival_day_capstone", "connectedProduction"),
}


AB_SPECS: tuple[SegmentSpec, ...] = (
    _named_spec(
        "a2_haeyo_register_transition", "a2", "a2_01_haeyo_transition",
        "vocabPack", "a2_change_verbs_1",
        ("합니다체와 해요체 전환", "Zwischen 합니다체 und 해요체 wechseln", "Switching between formal and polite styles"),
        "guidedProduction",
    ),
    _scenario_spec("a2_plans_with_friend", "a2", "a2_02_plans_proposals", "plans_with_friend"),
    _scenario_spec("a2_friend_birthday", "a2", "a2_02_plans_proposals", "friend_birthday"),
    _scenario_spec("a2_running_late", "a2", "a2_03_chat_relationships", "running_late"),
    _scenario_spec("a2_pharmacy_headache", "a2", "a2_04_feelings_health", "pharmacy_headache"),
    _scenario_spec("a2_gym_signup", "a2", "a2_04_feelings_health", "gym_signup"),
    _scenario_spec("a2_feeling_sick", "a2", "a2_04_feelings_health", "feeling_sick"),
    _scenario_spec("a2_cafe_starbucks_basic", "a2", "a2_05_delivery_services", "cafe_starbucks_basic"),
    _scenario_spec("a2_myeongdong_shopping", "a2", "a2_05_delivery_services", "myeongdong_shopping"),
    _scenario_spec("a2_cafe_study", "a2", "a2_06_study_work", "cafe_study"),
    _scenario_spec("a2_subway_transfer", "a2", "a2_07_travel_repair", "subway_transfer"),
    _scenario_spec("a2_taxi_street", "a2", "a2_07_travel_repair", "taxi_street"),
    _scenario_spec("a2_subway_directions", "a2", "a2_07_travel_repair", "subway_directions"),
    _scenario_spec("a2_lost_phone", "a2", "a2_07_travel_repair", "lost_phone"),
    _scenario_spec("a2_ktx_ticket", "a2", "a2_08_home_money", "ktx_ticket"),
    _scenario_spec("a2_rent_bank_transfer", "a2", "a2_08_home_money", "rent_bank_transfer"),
    _scenario_spec("b1_plans_with_reasons", "b1", "b1_01_experience_reasons", "postpone_plans"),
    _named_spec(
        "b1_travel_experience", "b1", "b1_01_experience_reasons",
        "vocabPack", "b1_travel_transport_1",
        ("여행 경험 설명", "Reiseerfahrungen schildern", "Describing travel experience"),
        "connectedProduction",
    ),
    _scenario_spec("b1_relay_social_speech", "b1", "b1_02_indirect_speech", "company_dinner_hoeshik"),
    _named_spec(
        "b1_relay_media_claim", "b1", "b1_02_indirect_speech",
        "vocabPack", "b1_media_culture_1",
        ("매체 주장 전달", "Aussagen aus Medien wiedergeben", "Relaying a media claim"),
        "connectedProduction",
    ),
    _scenario_spec("b1_bank_soft_request", "b1", "b1_03_work_softening", "bank_account"),
    _scenario_spec("b1_team_role_coordination", "b1", "b1_03_work_softening", "b1_team_meeting_coordination"),
    _scenario_spec("b1_attendance_and_coverage", "b1", "b1_03_work_softening", "b1_attendance_followup"),
    _scenario_spec("b1_schedule_softening", "b1", "b1_03_work_softening", "b1_reschedule_request"),
    _scenario_spec("b1_encouragement", "b1", "b1_04_relationships", "warm_encouragement"),
    _scenario_spec("b1_intimate_feelings", "b1", "b1_04_relationships", "love_confession"),
    _named_spec(
        "b1_social_invitation", "b1", "b1_04_relationships",
        "vocabPack", "b1_social_events_1",
        ("사회적 초대와 응답", "Einladungen aussprechen und beantworten", "Inviting and responding socially"),
        "connectedProduction",
    ),
    _scenario_spec("b1_delivery_resolution", "b1", "b1_05_complaint_resolution", "food_delivery"),
    _scenario_spec("b1_property_damage_report", "b1", "b1_05_complaint_resolution", "b1_leak_report"),
    _scenario_spec("b1_housing_contract", "b1", "b1_05_complaint_resolution", "b1_contract_appointment"),
    _scenario_spec("b1_safety_health_concern", "b1", "b1_05_complaint_resolution", "b1_heating_safety_call"),
    _scenario_spec("b1_relationship_conflict_repair", "b1", "b1_06_life_capstone", "couple_argument"),
    _scenario_spec("b1_move_in_handover", "b1", "b1_06_life_capstone", "b1_move_in_handover"),
    _named_spec(
        "b1_life_course_narrative", "b1", "b1_06_life_capstone",
        "vocabPack", "b1_time_life_1",
        ("생애 과정 서술", "Einen Lebensweg erzählen", "Narrating a life course"),
        "connectedProduction",
    ),
    _scenario_spec("b2_formal_meeting_opening", "b2", "b2_01_formal_opening", "business_meeting_intro"),
    _named_spec(
        "b2_honorific_register_transform", "b2", "b2_01_formal_opening",
        "vocabPack", "b2_honorifics_1",
        ("높임말과 격식 전환", "Höflichkeitsstufen formell umformen", "Transforming honorific register"),
        "guidedProduction",
    ),
    _scenario_spec("b2_decision_criteria", "b2", "b2_02_professional_opinion", "b2_decision_criteria_workshop"),
    _scenario_spec("b2_public_wording_revision", "b2", "b2_02_professional_opinion", "b2_public_wording_feedback", "openWriting"),
    _named_spec(
        "b2_collaborative_feedback", "b2", "b2_02_professional_opinion",
        "vocabPack", "b2_collaborative_feedback_1",
        ("협업 피드백", "Kooperatives Feedback", "Collaborative feedback"),
        "connectedProduction",
    ),
    _named_spec(
        "b2_digital_source_judgment", "b2", "b2_02_professional_opinion",
        "vocabPack", "b2_digital_judgment_1",
        ("디지털 출처 판단", "Digitale Quellen beurteilen", "Judging digital sources"),
        "openWriting",
    ),
    _named_spec(
        "b2_societal_evidence_argument", "b2", "b2_02_professional_opinion",
        "vocabPack", "b2_abstract_concepts_1",
        ("사회적 근거 논증", "Gesellschaftlich mit Evidenz argumentieren", "Building a social evidence argument"),
        "openWriting",
    ),
    _named_spec(
        "b2_language_social_change", "b2", "b2_02_professional_opinion",
        "vocabPack", "b2_language_change",
        ("언어와 사회 변화", "Sprachlichen und sozialen Wandel erklären", "Explaining language and social change"),
        "openWriting",
    ),
    _scenario_spec("b2_medical_precision", "b2", "b2_03_precise_requests", "doctor_consultation"),
    _scenario_spec("b2_contract_scope", "b2", "b2_03_precise_requests", "b2_signature_scope_confirmation", "openWriting"),
    _scenario_spec("b2_terms_deferral", "b2", "b2_03_precise_requests", "b2_deadline_deferral_request", "openWriting"),
    _named_spec(
        "b2_environmental_tradeoff", "b2", "b2_03_precise_requests",
        "vocabPack", "b2_environment_1",
        ("환경 상충관계 조정", "Ökologische Zielkonflikte abwägen", "Balancing environmental trade-offs"),
        "openWriting",
    ),
    _scenario_spec("b2_formal_complaint", "b2", "b2_04_complaint_resolution", "complaint_delivery", "openWriting"),
    _scenario_spec("b2_remedy_and_appeal", "b2", "b2_04_complaint_resolution", "b2_remedy_plan_request", "openWriting"),
    _named_spec(
        "b2_shared_space_coordination", "b2", "b2_04_complaint_resolution",
        "vocabPack", "b2_shared_space_coordination_1",
        ("공용 공간 조율", "Gemeinschaftsräume abstimmen", "Coordinating shared space"),
        "connectedProduction",
    ),
    _named_spec(
        "b2_personal_boundaries", "b2", "b2_04_complaint_resolution",
        "vocabPack", "b2_personal_boundaries_1",
        ("개인 경계 협의", "Persönliche Grenzen aushandeln", "Negotiating personal boundaries"),
        "connectedProduction",
    ),
    _named_spec(
        "b2_household_safety_rule", "b2", "b2_04_complaint_resolution",
        "vocabPack", "b2_safety_rules_1",
        ("생활 안전 규칙", "Regeln für Sicherheit im Alltag", "Setting household safety rules"),
        "openWriting",
    ),
    _scenario_spec("b2_interview_experience", "b2", "b2_05_interview", "job_interview"),
    _scenario_spec("b2_literary_cultural_response", "b2", "b2_06_advanced_capstone", "b2_reading_circle_response", "openWriting"),
    _named_spec(
        "b2_formal_soft_reformulation", "b2", "b2_06_advanced_capstone",
        "grammar", "grammar_b2_only_course",
        ("격식 있고 부드러운 재표현", "Formell und behutsam umformulieren", "Reformulating formally and tactfully"),
        "guidedProduction",
    ),
)


C_TEXT: dict[str, tuple[dict[str, str], dict[str, str]]] = {
    "c1_evidence_validity": (
        _text("근거 타당성 판단", "Evidenz auf Gültigkeit prüfen", "Evaluating Evidence Validity"),
        _text("서로 다른 자료의 표본과 방법을 대조해 주장에 맞는 근거의 타당성과 인과 한계를 판단할 수 있어요.", "Ich kann Stichprobe und Methode verschiedener Quellen vergleichen und die Tragfähigkeit der Evidenz sowie kausale Grenzen beurteilen.", "I can compare sampling and methods across sources and judge evidential validity and causal limits."),
    ),
    "c1_evidence_limits_conclusion": (
        _text("한계를 반영한 결론", "Schlussfolgerungen mit Grenzen", "Drawing Qualified Conclusions"),
        _text("반례와 한계를 반영해 결론의 강도와 재검토 조건을 조절할 수 있어요.", "Ich kann Gegenbeispiele und Grenzen einbeziehen und Stärke sowie Revisionsbedingungen einer Schlussfolgerung abstufen.", "I can incorporate counterexamples and limitations to calibrate a conclusion and its revision conditions."),
    ),
    "c1_risk_uncertainty": (
        _text("위험과 불확실성", "Risiko und Unsicherheit", "Risk and Uncertainty"),
        _text("확인된 사실, 모르는 점, 가능성과 확률을 구분해 공공 위험 정보를 설명할 수 있어요.", "Ich kann bestätigte Fakten, Unbekanntes, Möglichkeit und Wahrscheinlichkeit in Risikoinformationen unterscheiden.", "I can distinguish confirmed facts, unknowns, possibility, and probability in public risk information."),
    ),
    "c1_risk_update_correction": (
        _text("위험 정보 갱신과 정정", "Risikoinformation aktualisieren und berichtigen", "Updating and Correcting Risk Information"),
        _text("새 근거가 나오면 이전 정보와 달라진 점, 결론의 영향, 다음 조치를 책임 있게 정정할 수 있어요.", "Ich kann Risikoinformation bei neuer Evidenz verantwortungsvoll berichtigen und Änderungen, Folgen und nächste Schritte nennen.", "I can responsibly correct risk information when evidence changes, stating what changed, its impact, and next steps."),
    ),
    "c1_accessibility_barrier_diagnosis": (
        _text("접근 장벽 진단", "Zugangsbarrieren diagnostizieren", "Diagnosing Access Barriers"),
        _text("여러 이용 자료를 대조해 접근 장벽, 영향을 받는 사람과 원인을 구분해 설명할 수 있어요.", "Ich kann Nutzungsdaten vergleichen und Zugangsbarrieren, betroffene Personen und Ursachen unterscheiden.", "I can compare usage evidence and distinguish access barriers, affected people, and causes."),
    ),
    "c1_participatory_access_remedy": (
        _text("참여형 접근 개선", "Partizipative Zugangsverbesserung", "Participatory Access Improvement"),
        _text("당사자 요구와 비용·운영 제약을 연결해 선택권을 보장하는 개선안을 제안할 수 있어요.", "Ich kann Anforderungen Betroffener mit Kosten und Betrieb verbinden und eine Verbesserung mit echter Wahlmöglichkeit vorschlagen.", "I can connect stakeholder needs with cost and operational constraints and propose an improvement that preserves choice."),
    ),
    "c1_sustainable_lifecycle": (
        _text("지속 가능한 생애주기 판단", "Nachhaltigkeit über den Lebenszyklus beurteilen", "Evaluating Lifecycle Sustainability"),
        _text("초기 비용뿐 아니라 유지, 수명과 실제 이용 효과를 비교해 지속 가능한 선택을 권고할 수 있어요.", "Ich kann Anschaffung, Wartung, Lebensdauer und tatsächliche Nutzung vergleichen und eine nachhaltige Wahl empfehlen.", "I can compare upfront cost, maintenance, lifespan, and actual use to recommend a sustainable option."),
    ),
    "c1_local_tradeoff_adaptation": (
        _text("지역 상충관계 조정", "Lokale Zielkonflikte abwägen", "Balancing Local Trade-offs"),
        _text("외부 사례를 지역 제약과 부담에 맞게 조정해 시험 가능한 개선안을 만들 수 있어요.", "Ich kann externe Beispiele an lokale Zwänge und Belastungen anpassen und einen prüfbaren Pilotvorschlag entwickeln.", "I can adapt outside examples to local constraints and burdens and design a testable pilot."),
    ),
    "c2_procedural_legitimacy": (
        _text("절차적 정당성 감사", "Verfahrenslegitimität prüfen", "Auditing Procedural Legitimacy"),
        _text("결과와 절차를 분리해 배제된 목소리와 필요한 구제책을 근거로 감사할 수 있어요.", "Ich kann Ergebnis und Verfahren trennen und Legitimität anhand ausgeschlossener Stimmen und nötiger Abhilfe prüfen.", "I can separate outcome from process and audit legitimacy using excluded voices and required remedies."),
    ),
    "c2_institutional_deliberation": (
        _text("제도적 이견 조정", "Institutionelle Differenzen vermitteln", "Mediating Institutional Disagreement"),
        _text("권한, 이해관계와 불가양보선을 드러내며 실행 가능한 제도적 조정안을 만들 수 있어요.", "Ich kann Mandate, Interessen und nicht verhandelbare Grenzen offenlegen und eine tragfähige institutionelle Vermittlung entwerfen.", "I can surface mandates, interests, and non-negotiable limits and design a workable institutional mediation."),
    ),
    "c2_narrative_perspective": (
        _text("서술 관점 분석", "Erzählperspektiven analysieren", "Analyzing Narrative Perspective"),
        _text("화자, 시간 배열과 생략이 같은 사건의 의미를 어떻게 바꾸는지 비교할 수 있어요.", "Ich kann vergleichen, wie Erzähler, Zeitordnung und Auslassungen die Bedeutung desselben Ereignisses verändern.", "I can compare how narrator, chronology, and omissions change the meaning of the same event."),
    ),
    "c2_interpretation_justification": (
        _text("해석 근거화", "Deutungen begründen", "Justifying Interpretation"),
        _text("본문 단서와 맥락을 연결하고 대안 해석의 한계를 다루며 해석을 정당화할 수 있어요.", "Ich kann Textsignale und Kontext verbinden, Grenzen alternativer Deutungen behandeln und eine Interpretation begründen.", "I can connect textual clues and context, address the limits of alternative readings, and justify an interpretation."),
    ),
    "c2_framing_responsibility": (
        _text("프레이밍과 책임 분석", "Framing und Verantwortung analysieren", "Analyzing Framing and Responsibility"),
        _text("표현의 숨은 전제와 책임 배분을 드러내고 더 정확한 대안 표현을 만들 수 있어요.", "Ich kann verborgene Prämissen und Verantwortungszuschreibungen aufdecken und präzisere Formulierungen entwickeln.", "I can expose hidden premises and allocations of responsibility and produce more precise framing."),
    ),
    "c2_discourse_boundary_power": (
        _text("담론 경계와 권력", "Diskursive Grenzen und Macht", "Discourse Boundaries and Power"),
        _text("명명, 범주와 침묵이 가능한 반박과 선택을 어떻게 제한하는지 분석하고 수정할 수 있어요.", "Ich kann analysieren und überarbeiten, wie Benennung, Kategorien und Schweigen mögliche Einwände und Optionen begrenzen.", "I can analyze and revise how naming, categories, and silence constrain possible objections and choices."),
    ),
    "c2_technology_traceability_appeal": (
        _text("자동화 추적성과 이의제기", "Nachvollziehbarkeit und Einspruch bei Automatisierung", "Automation Traceability and Appeal"),
        _text("자동 판정의 자료, 기준과 사람의 개입을 추적하고 이용 가능한 이의 절차를 설계할 수 있어요.", "Ich kann Daten, Kriterien und menschliche Eingriffe automatisierter Entscheidungen nachverfolgen und ein nutzbares Einspruchsverfahren entwerfen.", "I can trace data, rules, and human intervention in automated decisions and design a usable appeal process."),
    ),
    "c2_technology_responsibility_rights": (
        _text("기술 책임과 권리 헌장", "Charta für technische Verantwortung und Rechte", "Technology Accountability and Rights Charter"),
        _text("기술의 편익과 위험, 책임 주체, 철회·감사권을 명시한 공공 책임 헌장을 만들 수 있어요.", "Ich kann eine öffentliche Charta verfassen, die Nutzen, Risiken, Verantwortliche sowie Widerrufs- und Prüfungsrechte festlegt.", "I can create a public accountability charter covering benefits, risks, responsible parties, and withdrawal and audit rights."),
    ),
}


C_ROWS: tuple[tuple[str, str, str, str, str, tuple[int, ...], tuple[str, ...], tuple[str, ...]], ...] = (
    ("c1_evidence_validity", "c1_01_evidence_public_reasoning", "c1_evidence_reasoning_1", "c1_evidence", "c1", (13, 14, 15, 16, 18, 24), ("smalltalk_c1_0003", "smalltalk_c1_0006"), ()),
    ("c1_evidence_limits_conclusion", "c1_01_evidence_public_reasoning", "c1_evidence_reasoning_1", "c1_evidence", "c1", (17, 19, 20, 21, 22, 23), ("smalltalk_c1_0004", "smalltalk_c1_0008"), ()),
    ("c1_risk_uncertainty", "c1_01_evidence_public_reasoning", "c1_risk_communication_1", "c1_risk", "c1", (25, 26, 28, 29, 32, 34), ("smalltalk_c1_0009", "smalltalk_c1_0010"), ("grammar_c1_rather_than", "grammar_c1_unless_condition")),
    ("c1_risk_update_correction", "c1_01_evidence_public_reasoning", "c1_risk_communication_1", "c1_risk", "c1", (27, 30, 31, 33, 35, 36), ("smalltalk_c1_0011", "smalltalk_c1_0012"), ("grammar_c1_even_at_cost", "grammar_c1_no_exaggeration")),
    ("c1_accessibility_barrier_diagnosis", "c1_02_inclusive_sustainable_systems", "c1_accessible_participation_1", "c1_accessibility", "c1", (1, 2, 5, 7, 10, 11), ("smalltalk_c1_0001", "smalltalk_c1_0005"), ()),
    ("c1_participatory_access_remedy", "c1_02_inclusive_sustainable_systems", "c1_accessible_participation_1", "c1_accessibility", "c1", (3, 4, 6, 8, 9, 12), ("smalltalk_c1_0002", "smalltalk_c1_0007"), ()),
    ("c1_sustainable_lifecycle", "c1_02_inclusive_sustainable_systems", "c1_sustainable_tradeoffs_1", "c1_sustainability", "c1", (37, 38, 40, 43, 44, 47), ("smalltalk_c1_0013", "smalltalk_c1_0014"), ("grammar_c1_two_sides", "grammar_c1_excessive_result")),
    ("c1_local_tradeoff_adaptation", "c1_02_inclusive_sustainable_systems", "c1_sustainable_tradeoffs_1", "c1_sustainability", "c1", (39, 41, 42, 45, 46, 48), ("smalltalk_c1_0015", "smalltalk_c1_0016"), ("grammar_c1_room_for", "grammar_c1_taking_into_account")),
    ("c2_procedural_legitimacy", "c2_01_interpretation_institutions", "c2_institutional_mediation_1", "c2_institution", "c2", (3, 4, 5, 9, 10, 12), ("smalltalk_c2_0002", "smalltalk_c2_0007"), ("grammar_c2_regardless_of", "grammar_c2_even_if_concession")),
    ("c2_institutional_deliberation", "c2_01_interpretation_institutions", "c2_institutional_mediation_1", "c2_institution", "c2", (1, 2, 6, 7, 8, 11), ("smalltalk_c2_0001", "smalltalk_c2_0003", "smalltalk_c2_0008"), ()),
    ("c2_narrative_perspective", "c2_01_interpretation_institutions", "c2_narrative_perspective_1", "c2_narrative", "c2", (13, 14, 15, 18, 21, 23), ("smalltalk_c2_0004", "smalltalk_c2_0005"), ("grammar_c2_expected_assumption",)),
    ("c2_interpretation_justification", "c2_01_interpretation_institutions", "c2_narrative_perspective_1", "c2_narrative", "c2", (16, 17, 19, 20, 22, 24), ("smalltalk_c2_0006",), ("grammar_c2_fortunate_counterfactual",)),
    ("c2_framing_responsibility", "c2_01_interpretation_institutions", "c2_language_framing_1", "c2_framing", "c2", (25, 26, 27, 29, 32, 36), ("smalltalk_c2_0009", "smalltalk_c2_0010"), ()),
    ("c2_discourse_boundary_power", "c2_01_interpretation_institutions", "c2_language_framing_1", "c2_framing", "c2", (28, 30, 31, 33, 34, 35), ("smalltalk_c2_0011", "smalltalk_c2_0012"), ()),
    ("c2_technology_traceability_appeal", "c2_02_technology_public_ethics", "c2_technology_ethics_1", "c2_technology", "c2", (37, 38, 39, 41, 43, 46), ("smalltalk_c2_0013", "smalltalk_c2_0014"), ("grammar_c2_even_assuming", "grammar_c2_nothing_more_than")),
    ("c2_technology_responsibility_rights", "c2_02_technology_public_ethics", "c2_technology_ethics_1", "c2_technology", "c2", (40, 42, 44, 45, 47, 48), ("smalltalk_c2_0015", "smalltalk_c2_0016"), ("grammar_c2_if_indeed", "grammar_c2_likely_negative")),
)


UNIT_DEFAULT_ROUTE: dict[str, str] = {
    **{unit_id: unit_id for unit_id in A1_PRACTICE},
    "a2_01_haeyo_transition": "a2_haeyo_register_transition",
    "a2_02_plans_proposals": "a2_plans_with_friend",
    "a2_03_chat_relationships": "a2_running_late",
    "a2_04_feelings_health": "a2_feeling_sick",
    "a2_05_delivery_services": "a2_cafe_starbucks_basic",
    "a2_06_study_work": "a2_cafe_study",
    "a2_07_travel_repair": "a2_subway_directions",
    "a2_08_home_money": "a2_rent_bank_transfer",
    "b1_01_experience_reasons": "b1_plans_with_reasons",
    "b1_02_indirect_speech": "b1_relay_social_speech",
    "b1_03_work_softening": "b1_team_role_coordination",
    "b1_04_relationships": "b1_intimate_feelings",
    "b1_05_complaint_resolution": "b1_delivery_resolution",
    "b1_06_life_capstone": "b1_life_course_narrative",
    "b2_01_formal_opening": "b2_formal_meeting_opening",
    "b2_02_professional_opinion": "b2_decision_criteria",
    "b2_03_precise_requests": "b2_contract_scope",
    "b2_04_complaint_resolution": "b2_formal_complaint",
    "b2_05_interview": "b2_interview_experience",
    "b2_06_advanced_capstone": "b2_formal_soft_reformulation",
}


PACK_ROUTES: dict[str, str] = {
    "a2_change_verbs": "a2_haeyo_register_transition",
    "a2_feelings": "a2_feeling_sick",
    "a2_health_misc": "a2_pharmacy_headache",
    "a2_food": "a2_cafe_starbucks_basic",
    "a2_food_more": "a2_cafe_starbucks_basic",
    "a2_restaurant": "a2_cafe_starbucks_basic",
    "a2_shopping": "a2_myeongdong_shopping",
    "a2_clothing": "a2_myeongdong_shopping",
    "a2_wearing_verbs": "a2_myeongdong_shopping",
    "a2_work": "a2_cafe_study",
    "a2_education": "a2_cafe_study",
    "a2_school_uni": "a2_cafe_study",
    "a2_people_jobs": "a2_cafe_study",
    "a2_transport": "a2_subway_directions",
    "a2_home": "a2_rent_bank_transfer",
    "a2_household": "a2_rent_bank_transfer",
    "a2_money": "a2_rent_bank_transfer",
    "b1_travel_transport": "b1_travel_experience",
    "b1_media_culture": "b1_relay_media_claim",
    "b1_communication_lang": "b1_relay_social_speech",
    "b1_work_coordination": "b1_team_role_coordination",
    "b1_social_events": "b1_social_invitation",
    "b1_emotions_relations": "b1_intimate_feelings",
    "b1_character_feelings": "b1_intimate_feelings",
    "b1_housing_contract": "b1_housing_contract",
    "b1_health_hospital": "b1_safety_health_concern",
    "b1_time_life": "b1_life_course_narrative",
    "b2_honorifics": "b2_honorific_register_transform",
    "b2_collaborative_feedback": "b2_collaborative_feedback",
    "b2_digital_judgment": "b2_digital_source_judgment",
    "b2_abstract_concepts": "b2_societal_evidence_argument",
    "b2_society": "b2_societal_evidence_argument",
    "b2_language_change": "b2_language_social_change",
    "b2_language_society": "b2_language_social_change",
    "b2_environment": "b2_environmental_tradeoff",
    "b2_formal_agreement": "b2_contract_scope",
    "b2_formal_complaint": "b2_remedy_and_appeal",
    "b2_shared_space_coordination": "b2_shared_space_coordination",
    "b2_personal_boundaries": "b2_personal_boundaries",
    "b2_safety_rules": "b2_household_safety_rule",
    "b2_reading_response": "b2_literary_cultural_response",
    "b2_literature_emotion": "b2_literary_cultural_response",
    "b2_events_culture": "b2_literary_cultural_response",
}


GRAMMAR_ID_ROUTES = {
    "grammar_a2_or_verbs": "a2_cafe_starbucks_basic",
    "grammar_a2_after_finishing": "a2_running_late",
    "grammar_a2_when": "a2_running_late",
    "grammar_a2_exclamation": "a2_running_late",
    "grammar_a2_irregular_eu": "a2_haeyo_register_transition",
    "grammar_a2_irregular_bieup": "a2_haeyo_register_transition",
    "grammar_a2_irregular_digeut": "a2_haeyo_register_transition",
    "grammar_a2_irregular_rieul": "a2_haeyo_register_transition",
}


EXTRA_SCENARIO_ROUTES = {
    "hotel_checkin": "a1_07_contact_address",
    "convenience_store": "a1_14_payment_delivery",
    "cancel_plans": "b1_plans_with_reasons",
    "b1_covering_absence": "b1_attendance_and_coverage",
    "b2_contract_clause_inquiry": "b2_contract_scope",
    "b2_objection_status_request": "b2_remedy_and_appeal",
}


SMALLTALK_ID_ROUTES: dict[str, str] = {
    "smalltalk_a2_0015": "a2_plans_with_friend",
    "smalltalk_a2_0022": "a2_plans_with_friend",
    **{
        f"smalltalk_b1_{number:04d}": key
        for number, key in {
            45: "b1_team_role_coordination",
            46: "b1_team_role_coordination",
            47: "b1_schedule_softening",
            48: "b1_schedule_softening",
            49: "b1_attendance_and_coverage",
            50: "b1_attendance_and_coverage",
            51: "b1_attendance_and_coverage",
            52: "b1_attendance_and_coverage",
        }.items()
    },
    **{
        f"smalltalk_b2_{number:04d}": key
        for number, key in {
            45: "b2_formal_complaint",
            46: "b2_formal_complaint",
            47: "b2_remedy_and_appeal",
            48: "b2_remedy_and_appeal",
            49: "b2_remedy_and_appeal",
            50: "b2_remedy_and_appeal",
            51: "b2_remedy_and_appeal",
            52: "b2_remedy_and_appeal",
            53: "b2_decision_criteria",
            54: "b2_decision_criteria",
            55: "b2_decision_criteria",
            56: "b2_decision_criteria",
            57: "b2_literary_cultural_response",
            58: "b2_literary_cultural_response",
            59: "b2_literary_cultural_response",
            60: "b2_literary_cultural_response",
            61: "b2_language_social_change",
            62: "b2_language_social_change",
            63: "b2_language_social_change",
            64: "b2_language_social_change",
            65: "b2_collaborative_feedback",
            66: "b2_collaborative_feedback",
            67: "b2_collaborative_feedback",
            68: "b2_digital_source_judgment",
            69: "b2_digital_source_judgment",
            70: "b2_digital_source_judgment",
            71: "b2_collaborative_feedback",
            72: "b2_decision_criteria",
            73: "b2_shared_space_coordination",
            74: "b2_shared_space_coordination",
            75: "b2_shared_space_coordination",
            76: "b2_shared_space_coordination",
            77: "b2_personal_boundaries",
            78: "b2_personal_boundaries",
            79: "b2_personal_boundaries",
            80: "b2_personal_boundaries",
        }.items()
    },
    "smalltalk_a1_0007": "a1_09_home_daily_life",
    "smalltalk_a1_0019": "a1_09_home_daily_life",
    "smalltalk_a1_0025": "a1_09_home_daily_life",
    "smalltalk_a1_0050": "a1_07_contact_address",
    "smalltalk_a1_0051": "a1_07_contact_address",
    "smalltalk_a1_0052": "a1_07_contact_address",
    "smalltalk_a1_0053": "a1_08_clarify_repair",
    "smalltalk_a1_0059": "a1_04_order_request_object",
    "smalltalk_a1_0060": "a1_04_order_request_object",
    "smalltalk_a2_0001": "a2_plans_with_friend",
    "smalltalk_a2_0002": "a2_feeling_sick",
    "smalltalk_a2_0003": "a2_plans_with_friend",
    "smalltalk_a2_0004": "a2_plans_with_friend",
    "smalltalk_a2_0006": "a2_plans_with_friend",
    "smalltalk_a2_0007": "a2_plans_with_friend",
    "smalltalk_a2_0008": "a2_plans_with_friend",
    "smalltalk_a2_0009": "a2_plans_with_friend",
    "smalltalk_a2_0011": "a2_plans_with_friend",
    "smalltalk_a2_0012": "a2_gym_signup",
    "smalltalk_a2_0013": "a2_plans_with_friend",
    "smalltalk_a2_0014": "a2_feeling_sick",
    "smalltalk_a2_0017": "a2_running_late",
    "smalltalk_a2_0018": "a2_plans_with_friend",
    "smalltalk_a2_0019": "a2_plans_with_friend",
    "smalltalk_a2_0020": "a2_plans_with_friend",
    "smalltalk_a2_0021": "a2_plans_with_friend",
    "smalltalk_a2_0023": "a2_plans_with_friend",
    "smalltalk_a2_0025": "a2_plans_with_friend",
    "smalltalk_a2_0026": "a2_plans_with_friend",
    "smalltalk_a2_0027": "a2_plans_with_friend",
    "smalltalk_a2_0028": "a2_plans_with_friend",
    "smalltalk_a2_0038": "a2_subway_transfer",
    "smalltalk_a2_0040": "a2_taxi_street",
    "smalltalk_a2_0041": "a2_taxi_street",
    "smalltalk_a2_0042": "a2_ktx_ticket",
    "smalltalk_a2_0049": "a2_haeyo_register_transition",
    "smalltalk_a2_0051": "a2_haeyo_register_transition",
    "smalltalk_b1_0004": "b1_social_invitation",
    "smalltalk_b1_0009": "b1_travel_experience",
    "smalltalk_b1_0016": "b1_social_invitation",
    "smalltalk_b1_0021": "b1_travel_experience",
    "smalltalk_b1_0033": "b1_move_in_handover",
    "smalltalk_b1_0034": "b1_housing_contract",
    "smalltalk_b1_0037": "b1_travel_experience",
    "smalltalk_b1_0038": "b1_travel_experience",
    "smalltalk_b1_0040": "b1_plans_with_reasons",
    "smalltalk_b1_0041": "b1_schedule_softening",
    "smalltalk_b1_0042": "b1_relay_social_speech",
    "smalltalk_b1_0043": "b1_property_damage_report",
    "smalltalk_b2_0001": "b2_personal_boundaries",
    "smalltalk_b2_0002": "b2_personal_boundaries",
    "smalltalk_b2_0003": "b2_personal_boundaries",
    "smalltalk_b2_0004": "b2_personal_boundaries",
    "smalltalk_b2_0005": "b2_personal_boundaries",
    "smalltalk_b2_0006": "b2_literary_cultural_response",
    "smalltalk_b2_0007": "b2_literary_cultural_response",
    "smalltalk_b2_0008": "b2_personal_boundaries",
    "smalltalk_b2_0009": "b2_personal_boundaries",
    "smalltalk_b2_0010": "b2_collaborative_feedback",
    "smalltalk_b2_0011": "b2_personal_boundaries",
    "smalltalk_b2_0012": "b2_medical_precision",
    "smalltalk_b2_0013": "b2_environmental_tradeoff",
    "smalltalk_b2_0014": "b2_personal_boundaries",
    "smalltalk_b2_0015": "b2_personal_boundaries",
    "smalltalk_b2_0016": "b2_personal_boundaries",
    "smalltalk_b2_0017": "b2_personal_boundaries",
    "smalltalk_b2_0018": "b2_literary_cultural_response",
    "smalltalk_b2_0019": "b2_literary_cultural_response",
    "smalltalk_b2_0020": "b2_personal_boundaries",
    "smalltalk_b2_0021": "b2_personal_boundaries",
    "smalltalk_b2_0022": "b2_personal_boundaries",
    "smalltalk_b2_0023": "b2_personal_boundaries",
    "smalltalk_b2_0024": "b2_medical_precision",
    "smalltalk_b2_0025": "b2_literary_cultural_response",
    "smalltalk_b2_0026": "b2_literary_cultural_response",
    "smalltalk_b2_0027": "b2_personal_boundaries",
    "smalltalk_b2_0028": "b2_personal_boundaries",
    "smalltalk_b2_0033": "b2_shared_space_coordination",
    "smalltalk_b2_0034": "b2_contract_scope",
    "smalltalk_b2_0037": "b2_decision_criteria",
    "smalltalk_b2_0038": "b2_decision_criteria",
    "smalltalk_b2_0039": "b2_contract_scope",
    "smalltalk_b2_0040": "b2_contract_scope",
    "smalltalk_b2_0043": "b2_household_safety_rule",
    "smalltalk_b2_0044": "b2_household_safety_rule",
    "smalltalk_b2_0069": "b2_personal_boundaries",
}


BEST_AVAILABLE_SMALLTALK_IDS = {
    *{
        f"smalltalk_a2_{number:04d}"
        for number in (1, 6, 7, 8, 9, 11, 13, 18, 19, 20, 21, 23, 25, 26, 27, 28)
    },
    *{f"smalltalk_b2_{number:04d}" for number in range(1, 29)},
    "smalltalk_b2_0043",
    "smalltalk_b2_0044",
}

# These generated Cloze rows have an example sentence that occurs in more than
# one pack. Their answer token identifies the reviewed vocabulary source; never
# resolve them by CSV order.
DERIVED_SOURCE_VOCAB_OVERRIDES = {
    "cloze_a1_0011": "vocab_a1_0020",  # 학교
    "cloze_a1_0050": "vocab_a1_0074",  # 의자
    "cloze_a1_0066": "vocab_a1_0156",  # 시간
}

# Explicit approvals for a new or semantically changed A1-B2 phrase are added
# here after human review. The checked-in authority asset remains the ledger for
# unchanged decisions; no future phrase is auto-approved by category alone.
SMALLTALK_REVIEW_APPROVALS: dict[str, dict[str, Any]] = {}


SMALLTALK_CATEGORY_ROUTES: dict[tuple[str, str], str] = {
    ("a2", "food"): "a2_cafe_starbucks_basic",
    ("a2", "shopping"): "a2_myeongdong_shopping",
    ("a2", "health"): "a2_feeling_sick",
    ("a2", "hospital"): "a2_pharmacy_headache",
    ("a2", "transport"): "a2_subway_directions",
    ("a2", "emergency"): "a2_lost_phone",
    ("a2", "moving"): "a2_rent_bank_transfer",
    ("b1", "travel"): "b1_life_course_narrative",
    ("b1", "screen"): "b1_relay_media_claim",
    ("b1", "dating"): "b1_intimate_feelings",
    ("b1", "family"): "b1_intimate_feelings",
    ("b1", "food"): "b1_delivery_resolution",
    ("b1", "health"): "b1_safety_health_concern",
    ("b1", "hospital"): "b1_safety_health_concern",
    ("b1", "shopping"): "b1_delivery_resolution",
    ("b1", "emergency"): "b1_safety_health_concern",
    ("b2", "interview"): "b2_interview_experience",
    ("b2", "job_hunting"): "b2_interview_experience",
    ("b2", "moving"): "b2_formal_soft_reformulation",
    ("b2", "shopping"): "b2_formal_complaint",
    ("b2", "emergency"): "b2_formal_complaint",
    ("b2", "hospital"): "b2_medical_precision",
    ("b2", "health"): "b2_medical_precision",
}


class SourceIndex:
    def __init__(self) -> None:
        self.curriculum = _read_json(DATA / "curriculum_manifest.json")
        self.units = {row["id"]: row for row in self.curriculum["courseUnits"]}
        self.concepts = {row["id"]: row for row in self.curriculum["concepts"]}
        self.vocab_pack_units = dict(self.curriculum["vocabPackUnitMap"])
        self.smalltalk_category_units = {
            key: value["courseUnitId"]
            for key, value in self.curriculum["smalltalkCategoryUnitMap"].items()
        }
        self.smalltalk_phrase_units = {
            key: value["courseUnitId"]
            for key, value in self.curriculum["smalltalkCheckpointPhraseMap"].items()
        }
        self.grammar_units = {
            key: value["courseUnitId"]
            for key, value in self.curriculum["grammarRuleMap"].items()
        }
        scenario_root = _read_json(DATA / "scenarios.json")
        self.scenarios = {row["id"]: row for row in scenario_root["scenarios"]}
        smalltalk_root = _read_json(DATA / "smalltalk.json")
        self.smalltalk = {row["id"]: row for row in smalltalk_root["phrases"]}
        cloze_root = _read_json(DATA / "cloze.json")
        self.cloze = {row["id"]: row for row in cloze_root["items"]}
        satz_root = _read_json(DATA / "satz_sentences.json")
        self.satz = {row["id"]: row for row in satz_root["items"]}
        pronunciation_root = _read_json(DATA / "pronunciation_phrases.json")
        self.pronunciation = {
            row["id"]: row for row in pronunciation_root["phrases"]
        }
        self.grammar = {row["id"]: row for row in _read_csv(DATA / "grammar.csv")}
        self.vocab = {row["id"]: row for row in _read_csv(DATA / "korean_vocab.csv")}
        vocab_by_example: dict[tuple[str, str], list[dict[str, str]]] = {}
        vocab_by_term: dict[tuple[str, str], list[dict[str, str]]] = {}
        for row in self.vocab.values():
            vocab_by_example.setdefault(
                (row["level"].lower(), row["example_korean"]), []
            ).append(row)
            vocab_by_term.setdefault(
                (row["level"].lower(), row["korean"]), []
            ).append(row)
        self.vocab_by_unique_example = self._unique_pack_rows(vocab_by_example)
        self.vocab_by_unique_term = self._unique_pack_rows(vocab_by_term)
        self.cloze_topic_units = {
            key.lower(): value for key, value in self.curriculum["clozeTopicUnitMap"].items()
        }
        _validate_review_batch_boundaries(
            {
                "scenario": set(self.scenarios),
                "smalltalk": set(self.smalltalk),
                "cloze": set(self.cloze),
                "satz": set(self.satz),
                "pronunciation": set(self.pronunciation),
            }
        )

    @staticmethod
    def _unique_pack_rows(
        grouped: dict[tuple[str, str], list[dict[str, str]]],
    ) -> dict[tuple[str, str], dict[str, str]]:
        return {
            key: sorted(rows, key=lambda row: row["id"])[0]
            for key, rows in grouped.items()
            if len({row["pack_id"] for row in rows}) == 1
        }

    def smalltalk_unit(self, row: dict[str, Any]) -> str:
        exact = self.smalltalk_phrase_units.get(row["id"])
        if exact is not None:
            return exact
        return _require(
            self.smalltalk_category_units,
            f"{row['level']}:{row['category']}",
            "smalltalk category mapping",
        )

    def resolve(
        self,
        reference: PracticeRef,
        *,
        expected_level: str,
        expected_parent: str,
    ) -> None:
        if reference.kind == "scenario":
            row = _require(self.scenarios, reference.id, "scenario")
            actual_level = row["level"]
            actual_parent = row["courseUnitId"]
        elif reference.kind == "vocabPack":
            base_pack_id = re.sub(r"_\d+$", "", reference.id)
            actual_parent = _require(self.vocab_pack_units, base_pack_id, "vocab pack")
            rows = [row for row in self.vocab.values() if row["pack_id"] == reference.id]
            if not rows:
                raise ValueError(f"vocab pack {reference.id!r} has no rows")
            levels = {row["level"].lower() for row in rows}
            if len(levels) != 1:
                raise ValueError(f"vocab pack {reference.id!r} spans levels {sorted(levels)}")
            actual_level = next(iter(levels))
        elif reference.kind == "grammar":
            row = _require(self.grammar, reference.id, "grammar")
            actual_level = row["level"].lower()
            mapped_parent = _require(self.grammar_units, reference.id, "grammar mapping")
            mapped_level = _require(self.units, mapped_parent, "grammar parent")["level"]
            if mapped_level != actual_level and reference.id in GRAMMAR_ID_ROUTES:
                actual_parent = expected_parent
            else:
                actual_parent = mapped_parent
        elif reference.kind == "smalltalk":
            row = _require(self.smalltalk, reference.id, "smalltalk")
            actual_level = row["level"]
            actual_parent = expected_parent  # reviewed exact phrase-level authority
        elif reference.kind == "cloze":
            row = _require(self.cloze, reference.id, "cloze")
            actual_level = row["level"]
            if _promotion_segment_key("cloze", reference.id) is not None:
                actual_parent = expected_parent
            else:
                topic_key = f"{actual_level}:{row['topic'].lower()}"
                actual_parent = _require(
                    self.cloze_topic_units, topic_key, "cloze topic mapping"
                )
            if actual_level in ("c1", "c2"):
                self._validate_derived_example(
                    row["fullKo"], actual_level, reference.id
                )
        elif reference.kind == "satz":
            row = _require(self.satz, reference.id, "satz")
            actual_level = row["level"]
            if _promotion_segment_key("satz", reference.id) is not None:
                actual_parent = expected_parent
            else:
                vocab = self._validate_satz_source(row, reference.id)
                base_pack_id = re.sub(r"_\d+$", "", vocab["pack_id"])
                actual_parent = _require(
                    self.vocab_pack_units, base_pack_id, "satz vocab pack"
                )
        elif reference.kind == "project":
            actual_level = expected_level
            actual_parent = expected_parent
        else:
            raise ValueError(f"unsupported content reference kind {reference.kind!r}")
        if actual_level != expected_level or actual_parent != expected_parent:
            raise ValueError(
                f"{reference.kind}:{reference.id} belongs to {actual_level}/{actual_parent}, "
                f"expected {expected_level}/{expected_parent}"
            )

    def _validate_derived_example(
        self, korean: str, level: str, content_id: str
    ) -> dict[str, str]:
        vocab = self.vocab_by_unique_example.get((level, korean))
        if vocab is None:
            raise ValueError(f"{content_id!r} does not join one same-level vocab example")
        return vocab

    def _validate_satz_source(
        self, row: dict[str, Any], content_id: str
    ) -> dict[str, str]:
        level = row["level"]
        exact = self.vocab_by_unique_example.get((level, row["targetKo"]))
        if exact is not None:
            return exact
        vocab = self.vocab_by_unique_term.get((level, row["vocabKo"]))
        if vocab is None:
            raise ValueError(
                f"{content_id!r} does not join one same-level unique vocab source"
            )
        return vocab

    def cloze_vocab_source(
        self, row: dict[str, Any], content_id: str
    ) -> dict[str, str] | None:
        override_id = DERIVED_SOURCE_VOCAB_OVERRIDES.get(content_id)
        if override_id is None:
            return self.vocab_by_unique_example.get((row["level"], row["fullKo"]))
        vocab = _require(self.vocab, override_id, "derived vocab override")
        if (
            vocab["level"].lower() != row["level"]
            or vocab["example_korean"] != row["fullKo"]
            or vocab["korean"] != row["answer"]
        ):
            raise ValueError(
                f"derived vocab override {override_id!r} does not exactly support "
                f"{content_id!r}"
            )
        return vocab


def build_assets() -> tuple[dict[str, Any], dict[str, Any]]:
    source = SourceIndex()
    specs, coverage = _build_specs(source)
    counts = {level: 0 for level in LEVELS}
    segments: list[dict[str, Any]] = []
    clusters: list[dict[str, Any]] = []
    content_authorities: dict[tuple[str, str], dict[str, Any]] = {}
    seed_authorities: dict[str, dict[str, Any]] = {}
    edition_members = {level: [] for level in LEVELS}

    for spec in specs:
        counts[spec.level] += 1
        order = counts[spec.level]
        unit = _require(source.units, spec.parent, "course unit")
        if unit["level"] != spec.level:
            raise ValueError(f"{spec.key} parent level mismatch")
        default_concepts = tuple(
            concept_id
            for concept_id in unit["requiredConceptIds"]
            if _require(source.concepts, concept_id, "course unit concept")["level"]
            == spec.level
        )
        concepts = list(spec.concepts or default_concepts)
        if not concepts or not set(concepts).issubset(set(unit["requiredConceptIds"])):
            raise ValueError(f"{spec.key} has concepts outside parent unit")
        if any(
            _require(source.concepts, concept_id, "segment concept")["level"]
            != spec.level
            for concept_id in concepts
        ):
            raise ValueError(f"{spec.key} has a cross-level concept")
        cluster_id = f"cluster_{spec.key}_v1"
        segment_id = f"segment_{spec.key}"
        title, can_do = _segment_text(spec, source)
        seed_ids = list(spec.source_seed_ids or ())
        refs_json: list[dict[str, str]] = []
        for reference in spec.refs:
            source.resolve(reference, expected_level=spec.level, expected_parent=spec.parent)
            seed_id = reference.source_seed_id or _default_seed(reference)
            if seed_id not in seed_ids:
                seed_ids.append(seed_id)
            seed_authorities.setdefault(seed_id, {"id": seed_id, "level": spec.level})
            if seed_authorities[seed_id]["level"] != spec.level:
                raise ValueError(f"source seed {seed_id!r} crosses levels")
            authority = {
                "kind": reference.kind,
                "id": reference.id,
                "level": spec.level,
                "sourceSeedId": seed_id,
                "courseUnitId": spec.parent,
            }
            key = (reference.kind, reference.id)
            existing = content_authorities.setdefault(key, authority)
            if existing != authority:
                raise ValueError(f"content authority {reference.kind}:{reference.id} is ambiguous")
            refs_json.append({"kind": reference.kind, "id": reference.id})

        requirements = _requirements(spec.key, spec.mode)
        clusters.append(
            {
                "id": cluster_id,
                "level": spec.level,
                "revision": 1,
                "sourceSeedIds": seed_ids,
                "contentReferences": refs_json,
            }
        )
        segments.append(
            {
                "id": segment_id,
                "constructLineageId": segment_id,
                "parentCourseUnitId": spec.parent,
                "level": spec.level,
                "order": order,
                "title": title,
                "canDo": can_do,
                "requiredConceptIds": concepts,
                "contentClusterIds": [cluster_id],
                "proofRevision": 1,
                "evidencePolicy": "allOf",
                "assessmentRequirements": requirements,
                "ownedAssessmentItemIds": [row["assessmentItemId"] for row in requirements],
                "releaseTrackId": "core_2026_v1",
                "trackEditionId": f"edition_core_{spec.level}_v1",
                "lifecycle": "published",
            }
        )
        edition_members[spec.level].append(segment_id)

    if counts != EXPECTED_COUNTS:
        raise ValueError(f"canonical counts changed: {counts}, expected {EXPECTED_COUNTS}")

    catalog = {
        "schemaVersion": 1,
        "contentClusters": clusters,
        "segments": segments,
        "trackEditions": [
            {
                "id": f"edition_core_{level}_v1",
                "releaseTrackId": "core_2026_v1",
                "level": level,
                "segmentIds": edition_members[level],
                "publishedAt": PUBLISHED_AT,
                "status": "published",
            }
            for level in LEVELS
        ],
        "releaseTracks": [
            {
                "id": "core_2026_v1",
                "kind": "core",
                "order": 1,
                "title": _text("한옥 V1 코어", "Hanok V1 Kernkurs", "Hanok V1 Core"),
                "editionIds": [f"edition_core_{level}_v1" for level in LEVELS],
                "publishedAt": PUBLISHED_AT,
                "status": "published",
            }
        ],
    }
    authorities = {
        "schemaVersion": 1,
        "sourceSeeds": sorted(
            seed_authorities.values(), key=lambda row: (LEVELS.index(row["level"]), row["id"])
        ),
        "contentReferences": sorted(
            content_authorities.values(),
            key=lambda row: (LEVELS.index(row["level"]), row["kind"], row["id"]),
        ),
        "coverage": coverage,
    }
    _reconcile_published_history(catalog, authorities)
    return catalog, authorities


def _reconcile_published_history(
    catalog: dict[str, Any], authorities: dict[str, Any]
) -> None:
    """Keep published cluster provenance append-only across content growth.

    The checked-in assets are the release ledger. Existing references and
    authorities may not move; newly routed practice is appended and increments
    only the affected cluster revision. A fresh bootstrap has no prior ledger.
    """
    if not CATALOG_PATH.exists() and not AUTHORITY_PATH.exists():
        return
    if not CATALOG_PATH.exists() or not AUTHORITY_PATH.exists():
        raise ValueError("canonical catalog and authority ledgers must coexist")
    previous_catalog = _read_json(CATALOG_PATH)
    previous_authorities = _read_json(AUTHORITY_PATH)
    _preserve_cluster_history(catalog, previous_catalog)
    _validate_authority_history(authorities, previous_authorities)


def _preserve_cluster_history(
    current: dict[str, Any], previous: dict[str, Any]
) -> None:
    previous_clusters = {row["id"]: row for row in previous["contentClusters"]}
    current_clusters = {row["id"]: row for row in current["contentClusters"]}
    missing_clusters = sorted(set(previous_clusters) - set(current_clusters))
    if missing_clusters:
        raise ValueError(f"published content clusters cannot be removed: {missing_clusters}")
    for cluster_id, cluster in current_clusters.items():
        old = previous_clusters.get(cluster_id)
        if old is None:
            cluster["revision"] = 1
            continue
        if cluster["level"] != old["level"]:
            raise ValueError(f"published cluster {cluster_id!r} cannot change level")
        old_seed_ids = list(old["sourceSeedIds"])
        new_seed_ids = list(cluster["sourceSeedIds"])
        missing_seeds = sorted(set(old_seed_ids) - set(new_seed_ids))
        if missing_seeds:
            raise ValueError(
                f"published cluster {cluster_id!r} cannot remove seeds: {missing_seeds}"
            )
        cluster["sourceSeedIds"] = old_seed_ids + [
            seed_id for seed_id in new_seed_ids if seed_id not in set(old_seed_ids)
        ]

        old_references = list(old["contentReferences"])
        new_references = list(cluster["contentReferences"])
        old_keys = [_reference_key(row) for row in old_references]
        current_by_key = {_reference_key(row): row for row in new_references}
        missing_references = sorted(set(old_keys) - set(current_by_key))
        if missing_references:
            raise ValueError(
                f"published cluster {cluster_id!r} cannot remove or move refs: "
                f"{missing_references}"
            )
        cluster["contentReferences"] = [
            current_by_key[key] for key in old_keys
        ] + [
            row for row in new_references if _reference_key(row) not in set(old_keys)
        ]
        changed = (
            cluster["sourceSeedIds"] != old_seed_ids
            or cluster["contentReferences"] != old_references
        )
        old_revision = old["revision"]
        if not isinstance(old_revision, int) or old_revision <= 0:
            raise ValueError(f"published cluster {cluster_id!r} has invalid revision")
        cluster["revision"] = old_revision + 1 if changed else old_revision


def _validate_authority_history(
    current: dict[str, Any], previous: dict[str, Any]
) -> None:
    old_seeds = {row["id"]: row for row in previous["sourceSeeds"]}
    new_seeds = {row["id"]: row for row in current["sourceSeeds"]}
    for seed_id, old in old_seeds.items():
        next_seed = new_seeds.get(seed_id)
        if next_seed is None or next_seed != old:
            raise ValueError(f"published source seed {seed_id!r} is immutable")

    old_references = {
        _reference_key(row): row for row in previous["contentReferences"]
    }
    new_references = {
        _reference_key(row): row for row in current["contentReferences"]
    }
    for key, old in old_references.items():
        next_reference = new_references.get(key)
        if next_reference is None or next_reference != old:
            raise ValueError(f"published content authority {key!r} is immutable")
    _validate_smalltalk_review_history(current, previous)


def _validate_smalltalk_review_history(
    current: dict[str, Any],
    previous: dict[str, Any],
    *,
    review_approvals: dict[str, dict[str, Any]] | None = None,
) -> None:
    approvals = (
        SMALLTALK_REVIEW_APPROVALS
        if review_approvals is None
        else review_approvals
    )
    old_decisions = {
        row["phraseId"]: row
        for row in previous["coverage"]["smalltalkRoutingAudit"]["phraseDecisions"]
    }
    new_decisions = {
        row["phraseId"]: row
        for row in current["coverage"]["smalltalkRoutingAudit"]["phraseDecisions"]
    }
    missing = sorted(set(old_decisions) - set(new_decisions))
    if missing:
        raise ValueError(f"reviewed smalltalk decisions cannot be removed: {missing}")
    used_approvals: set[str] = set()
    for phrase_id, decision in new_decisions.items():
        old = old_decisions.get(phrase_id)
        if old is not None and _same_smalltalk_decision(old, decision):
            decision["reviewRevision"] = old["reviewRevision"]
        conservative_downgrade = (
            old is not None
            and old["semanticStatus"] == "approved"
            and decision["semanticStatus"] in ("bestAvailable", "exactMapped")
            and _same_smalltalk_decision(old, decision, ignore_semantic=True)
        )
        if conservative_downgrade:
            decision["reviewRevision"] = old["reviewRevision"] + 1
        approval = approvals.get(phrase_id)
        if approval is not None:
            approved_revision = approval.get("reviewRevision")
            if not isinstance(approved_revision, int) or approved_revision <= 0:
                raise ValueError(
                    f"smalltalk review approval for {phrase_id!r} has an "
                    "invalid reviewRevision"
                )
            decision["reviewRevision"] = approved_revision
            expected_approval = {
                "phraseFingerprintSha256": decision["phraseFingerprintSha256"],
                "canDoSegmentId": decision["canDoSegmentId"],
                "canDoFingerprintSha256": decision["canDoFingerprintSha256"],
                "semanticStatus": decision["semanticStatus"],
                "reviewRevision": decision["reviewRevision"],
            }
            if approval != expected_approval:
                raise ValueError(
                    f"smalltalk review approval for {phrase_id!r} does not match "
                    f"the generated decision: {expected_approval}"
                )
            used_approvals.add(phrase_id)
        if old == decision:
            continue
        if conservative_downgrade:
            continue
        if approval is None:
            expected_approval = {
                "phraseFingerprintSha256": decision["phraseFingerprintSha256"],
                "canDoSegmentId": decision["canDoSegmentId"],
                "canDoFingerprintSha256": decision["canDoFingerprintSha256"],
                "semanticStatus": decision["semanticStatus"],
                "reviewRevision": 1 if old is None else old["reviewRevision"] + 1,
            }
            raise ValueError(
                f"smalltalk {phrase_id!r} is new or changed and requires an "
                "explicit SMALLTALK_REVIEW_APPROVALS entry: "
                f"{expected_approval}"
            )
        previous_revision = 0 if old is None else old["reviewRevision"]
        if decision["reviewRevision"] <= previous_revision:
            raise ValueError(
                f"smalltalk review revision for {phrase_id!r} must increase"
            )
    unused_approvals = sorted(set(approvals) - used_approvals)
    if unused_approvals:
        raise ValueError(f"unused smalltalk review approvals: {unused_approvals}")


def _same_smalltalk_decision(
    old: dict[str, Any],
    current: dict[str, Any],
    *,
    ignore_semantic: bool = False,
) -> bool:
    ignored = {"reviewRevision"}
    if ignore_semantic:
        ignored.update({"semanticStatus", "reasonCode"})
    keys = set(old) | set(current)
    return all(old.get(key) == current.get(key) for key in keys - ignored)


def _reference_key(row: dict[str, Any]) -> str:
    return f"{row['kind']}:{row['id']}"


def _validate_review_batch_boundaries(
    raw_ids_by_kind: dict[str, set[str]],
    *,
    manifest_paths: Iterable[Path] = REVIEW_BATCH_MANIFEST_PATHS,
    promotions: dict[tuple[str, str], dict[str, Any]] = REVIEW_CONTENT_PROMOTIONS,
    repository_root: Path = ROOT,
) -> None:
    review_items: set[tuple[str, str]] = set()
    promoted_live_items: set[tuple[str, str]] = set()
    for manifest_path in manifest_paths:
        if not manifest_path.exists():
            continue
        manifest = _read_json(manifest_path)
        if manifest.get("status") not in {"review_only", "live"}:
            raise ValueError(f"unsupported review-batch status in {manifest_path}")
        for artifact in manifest.get("artifacts", []):
            kind = artifact.get("kind")
            collection = artifact.get("collection")
            draft = artifact.get("draft")
            if (
                kind not in PRACTICE_ONLY_KINDS
                or not isinstance(collection, str)
                or not isinstance(draft, str)
            ):
                raise ValueError(f"invalid review artifact in {manifest_path}")
            draft_path = repository_root / draft
            draft_asset = _read_json(draft_path)
            rows = draft_asset.get(collection)
            if not isinstance(rows, list):
                raise ValueError(f"{draft_path} has no {collection!r} collection")
            for row in rows:
                if not isinstance(row, dict) or not isinstance(row.get("id"), str):
                    raise ValueError(f"{draft_path} contains an invalid review row")
                key = (kind, row["id"])
                if key in review_items:
                    raise ValueError(f"duplicate review-batch content {key!r}")
                review_items.add(key)
                if row["id"] not in raw_ids_by_kind.get(kind, set()):
                    continue
                promotion = promotions.get(key)
                expected = {
                    "approved": True,
                    "live": True,
                    "canDoSegmentKey": promotion.get("canDoSegmentKey")
                    if promotion is not None
                    else None,
                    "assessmentAuthority": False,
                }
                if (
                    promotion != expected
                    or not isinstance(expected["canDoSegmentKey"], str)
                    or not expected["canDoSegmentKey"]
                ):
                    raise ValueError(
                        f"review-batch content {key!r} reached a live asset without "
                        "an exact approved+live non-assessment promotion"
                    )
                promoted_live_items.add(key)
    unused_promotions = sorted(set(promotions) - promoted_live_items)
    if unused_promotions:
        raise ValueError(
            f"review-content promotions are unused or not live: {unused_promotions}"
        )


def _promotion_segment_key(kind: str, content_id: str) -> str | None:
    promotion = REVIEW_CONTENT_PROMOTIONS.get((kind, content_id))
    if promotion is None:
        return None
    target = promotion.get("canDoSegmentKey")
    if not isinstance(target, str) or not target:
        raise ValueError(f"promotion for {(kind, content_id)!r} has no can-do target")
    return target


def _build_specs(source: SourceIndex) -> tuple[list[SegmentSpec], dict[str, Any]]:
    specs: list[SegmentSpec] = []
    for unit in source.curriculum["courseUnits"]:
        unit_id = unit["id"]
        if unit["level"] != "a1":
            continue
        kind, content_id, mode = _require(A1_PRACTICE, unit_id, "A1 practice")
        specs.append(
            SegmentSpec(
                key=unit_id,
                level="a1",
                parent=unit_id,
                refs=(_ref(kind, content_id),),
                mode=mode,
                title=dict(unit["title"]),
                can_do=dict(unit["canDo"]),
            )
        )
    specs.extend(AB_SPECS)
    specs.extend(_build_c_specs())
    return _expand_ab_practice(specs, source)


def _expand_ab_practice(
    specs: list[SegmentSpec], source: SourceIndex
) -> tuple[list[SegmentSpec], dict[str, Any]]:
    """Route every existing A1-B2 practice source exactly once.

    Cloze rows inherit through an exact same-level example. Satz rows may also
    use their unique same-level vocab term. Non-derived Cloze stays explicit.
    """
    spec_by_key = {spec.key: spec for spec in specs}
    refs_by_key = {spec.key: list(spec.refs) for spec in specs}
    owners_by_reference: dict[tuple[str, str], set[str]] = {}
    for spec in specs:
        for reference in spec.refs:
            key = (reference.kind, reference.id)
            owners = owners_by_reference.setdefault(key, set())
            owners.add(spec.key)
            if len(owners) > 1 and spec.level not in ("c1", "c2"):
                raise ValueError(f"A/B practice reference {key} is shared by segments")

    def add(
        reference: PracticeRef,
        target_key: str,
        *,
        expected_level: str,
    ) -> None:
        target = _require(spec_by_key, target_key, "segment route")
        if target.level != expected_level:
            raise ValueError(
                f"practice reference {(reference.kind, reference.id)!r} is "
                f"{expected_level}, but target {target_key!r} is {target.level}"
            )
        key = (reference.kind, reference.id)
        existing = owners_by_reference.get(key)
        if existing is not None:
            if target_key not in existing:
                raise ValueError(f"practice reference {key} routes to two segments")
            return
        refs_by_key[target_key].append(reference)
        owners_by_reference[key] = {target_key}

    actual_packs = sorted({row["pack_id"] for row in source.vocab.values()})
    ab_pack_ids = []
    for pack_id in actual_packs:
        rows = [row for row in source.vocab.values() if row["pack_id"] == pack_id]
        level = rows[0]["level"].lower()
        if level in ("c1", "c2"):
            continue
        if {row["level"].lower() for row in rows} != {level}:
            raise ValueError(f"vocab pack {pack_id!r} crosses levels")
        base_pack_id = re.sub(r"_\d+$", "", pack_id)
        unit_id = _require(source.vocab_pack_units, base_pack_id, "vocab pack")
        target = PACK_ROUTES.get(base_pack_id, _require(UNIT_DEFAULT_ROUTE, unit_id, "unit route"))
        add(_ref("vocabPack", pack_id), target, expected_level=level)
        ab_pack_ids.append(pack_id)

    ab_grammar_ids = []
    for grammar_id, row in sorted(source.grammar.items()):
        level = row["level"].lower()
        if level in ("c1", "c2"):
            continue
        target = GRAMMAR_ID_ROUTES.get(grammar_id)
        if target is None:
            unit_id = _require(source.grammar_units, grammar_id, "grammar mapping")
            target = _require(UNIT_DEFAULT_ROUTE, unit_id, "unit route")
        add(_ref("grammar", grammar_id), target, expected_level=level)
        ab_grammar_ids.append(grammar_id)

    ab_scenario_ids = []
    for scenario_id, row in sorted(source.scenarios.items()):
        level = row["level"]
        promoted_target = _promotion_segment_key("scenario", scenario_id)
        if level in ("c1", "c2"):
            if promoted_target is not None:
                add(
                    _ref("scenario", scenario_id),
                    promoted_target,
                    expected_level=level,
                )
            continue
        anchor = owners_by_reference.get(("scenario", scenario_id))
        target = (
            next(iter(anchor))
            if anchor
            else promoted_target or EXTRA_SCENARIO_ROUTES.get(scenario_id)
        )
        if target is None:
            raise ValueError(f"scenario {scenario_id!r} needs an explicit semantic segment route")
        add(_ref("scenario", scenario_id), target, expected_level=level)
        ab_scenario_ids.append(scenario_id)

    ab_smalltalk_ids = []
    exact_smalltalk_override_ids: list[str] = []
    category_smalltalk_fallback_ids: list[str] = []
    course_unit_smalltalk_fallback_ids: list[str] = []
    legacy_smalltalk_unit_overrides: list[dict[str, str]] = []
    smalltalk_phrase_decisions: list[dict[str, Any]] = []
    for phrase_id, row in sorted(source.smalltalk.items()):
        level = row["level"]
        promoted_target = _promotion_segment_key("smalltalk", phrase_id)
        if level in ("c1", "c2"):
            if promoted_target is not None:
                add(
                    _ref("smalltalk", phrase_id),
                    promoted_target,
                    expected_level=level,
                )
            continue
        unit_id = source.smalltalk_unit(row)
        target = promoted_target or SMALLTALK_ID_ROUTES.get(phrase_id)
        if target is not None:
            exact_smalltalk_override_ids.append(phrase_id)
            routing_source = "exactOverride"
        else:
            target = SMALLTALK_CATEGORY_ROUTES.get((level, row["category"]))
            if target is not None:
                category_smalltalk_fallback_ids.append(phrase_id)
                routing_source = "categoryFallback"
            else:
                target = _require(UNIT_DEFAULT_ROUTE, unit_id, "unit route")
                course_unit_smalltalk_fallback_ids.append(phrase_id)
                routing_source = "courseUnitFallback"
        target_parent = _require(spec_by_key, target, "smalltalk segment route").parent
        if target_parent != unit_id:
            if phrase_id not in SMALLTALK_ID_ROUTES and promoted_target is None:
                raise ValueError(
                    f"smalltalk {phrase_id!r} maps to {unit_id!r}, "
                    f"but category route {target!r} belongs to {target_parent!r}"
                )
            legacy_smalltalk_unit_overrides.append(
                {
                    "id": phrase_id,
                    "legacyCourseUnitId": unit_id,
                    "courseUnitId": target_parent,
                    "canDoSegmentId": f"segment_{target}",
                }
            )
        target_spec = _require(spec_by_key, target, "smalltalk segment route")
        target_title, target_can_do = _segment_text(target_spec, source)
        is_best_available = (
            routing_source != "exactOverride"
            or phrase_id in BEST_AVAILABLE_SMALLTALK_IDS
        )
        approval = SMALLTALK_REVIEW_APPROVALS.get(phrase_id)
        if approval is not None:
            semantic_status = "approved"
            reason_code = "topicAndFunctionMatch"
        elif is_best_available:
            semantic_status = "bestAvailable"
            reason_code = "closestPublishedCoreSegment"
        else:
            semantic_status = "exactMapped"
            reason_code = "explicitSemanticRoute"
        smalltalk_phrase_decisions.append(
            {
                "phraseId": phrase_id,
                "phraseFingerprintSha256": _json_fingerprint(row),
                "routingSource": routing_source,
                "canDoSegmentId": f"segment_{target}",
                "canDoFingerprintSha256": _json_fingerprint(
                    {"title": target_title, "canDo": target_can_do}
                ),
                "semanticStatus": semantic_status,
                "reasonCode": reason_code,
                "reviewRevision": 1,
            }
        )
        add(_ref("smalltalk", phrase_id), target, expected_level=level)
        ab_smalltalk_ids.append(phrase_id)

    unknown_best_available = BEST_AVAILABLE_SMALLTALK_IDS - set(ab_smalltalk_ids)
    if unknown_best_available:
        raise ValueError(
            f"best-available smalltalk IDs do not exist: {sorted(unknown_best_available)}"
        )

    inherited_cloze_ids: list[str] = []
    inherited_content_references: list[dict[str, str]] = []
    explicit_cloze_ids: list[str] = []
    direct_override_cloze_ids: list[str] = []
    for content_id, row in sorted(source.cloze.items()):
        level = row["level"]
        promoted_target = _promotion_segment_key("cloze", content_id)
        if level in ("c1", "c2"):
            if promoted_target is not None:
                add(
                    _ref("cloze", content_id),
                    promoted_target,
                    expected_level=level,
                )
            continue
        if ("cloze", content_id) in owners_by_reference:
            direct_override_cloze_ids.append(content_id)
            continue
        if promoted_target is not None:
            add(
                _ref("cloze", content_id),
                promoted_target,
                expected_level=level,
            )
            direct_override_cloze_ids.append(content_id)
            continue
        vocab = source.cloze_vocab_source(row, content_id)
        if vocab is not None:
            pack_owner = owners_by_reference.get(("vocabPack", vocab["pack_id"]))
            if pack_owner is None:
                raise ValueError(f"cloze {content_id!r} inherits an unrouted vocab pack")
            owner_key = next(iter(pack_owner))
            owner = _require(spec_by_key, owner_key, "inherited cloze owner")
            inherited_cloze_ids.append(content_id)
            inherited_content_references.append(
                {
                    "kind": "cloze",
                    "id": content_id,
                    "sourceKind": "vocabPack",
                    "sourceId": vocab["pack_id"],
                    "sourceVocabId": vocab["id"],
                    "sourceVocabFingerprintSha256": _json_fingerprint(vocab),
                    "level": level,
                    "canDoSegmentId": f"segment_{owner_key}",
                    "courseUnitId": owner.parent,
                }
            )
            continue
        topic_key = f"{level}:{row['topic'].lower()}"
        unit_id = _require(source.cloze_topic_units, topic_key, "cloze topic mapping")
        add(
            _ref("cloze", content_id),
            _require(UNIT_DEFAULT_ROUTE, unit_id, "unit route"),
            expected_level=level,
        )
        explicit_cloze_ids.append(content_id)

    inherited_satz_ids: list[str] = []
    for content_id, row in sorted(source.satz.items()):
        level = row["level"]
        promoted_target = _promotion_segment_key("satz", content_id)
        if level in ("c1", "c2"):
            if promoted_target is not None:
                add(
                    _ref("satz", content_id),
                    promoted_target,
                    expected_level=level,
                )
            continue
        if promoted_target is not None:
            add(
                _ref("satz", content_id),
                promoted_target,
                expected_level=level,
            )
            continue
        vocab = source._validate_satz_source(row, content_id)
        if ("vocabPack", vocab["pack_id"]) not in owners_by_reference:
            raise ValueError(f"satz {content_id!r} inherits an unrouted vocab pack")
        owner_key = next(iter(owners_by_reference[("vocabPack", vocab["pack_id"])]))
        owner = _require(spec_by_key, owner_key, "inherited satz owner")
        inherited_satz_ids.append(content_id)
        inherited_content_references.append(
            {
                "kind": "satz",
                "id": content_id,
                "sourceKind": "vocabPack",
                "sourceId": vocab["pack_id"],
                "sourceVocabId": vocab["id"],
                "sourceVocabFingerprintSha256": _json_fingerprint(vocab),
                "level": level,
                "canDoSegmentId": f"segment_{owner_key}",
                "courseUnitId": owner.parent,
            }
        )

    expanded = [replace(spec, refs=tuple(refs_by_key[spec.key])) for spec in specs]
    _require_exact_direct_coverage(
        owners_by_reference,
        kind="vocabPack",
        expected_ids={row["pack_id"] for row in source.vocab.values()},
    )
    _require_exact_direct_coverage(
        owners_by_reference,
        kind="grammar",
        expected_ids=set(source.grammar),
    )
    _require_exact_direct_coverage(
        owners_by_reference,
        kind="smalltalk",
        expected_ids=set(source.smalltalk),
    )
    _require_exact_direct_coverage(
        owners_by_reference,
        kind="scenario",
        expected_ids=set(source.scenarios),
    )
    _require_exact_derived_coverage(
        owners_by_reference,
        kind="cloze",
        inherited_ids=set(inherited_cloze_ids),
        expected_ids=set(source.cloze),
    )
    _require_exact_derived_coverage(
        owners_by_reference,
        kind="satz",
        inherited_ids=set(inherited_satz_ids),
        expected_ids=set(source.satz),
    )
    direct_counts = {
        kind: sum(1 for reference_kind, _ in owners_by_reference if reference_kind == kind)
        for kind in ("vocabPack", "grammar", "smalltalk", "scenario", "cloze", "satz", "project")
    }
    coverage = {
        "directReferenceCounts": direct_counts,
        "inheritedReferenceCounts": {
            "cloze": len(inherited_cloze_ids),
            "satz": len(inherited_satz_ids),
        },
        "inheritedContentReferences": sorted(
            inherited_content_references,
            key=lambda row: (row["level"], row["kind"], row["id"]),
        ),
        "inheritanceRules": [
            {
                "childKind": "cloze",
                "sourceKind": "vocabPack",
                "levels": ["a1", "a2", "b1", "b2"],
                "join": "same_level_unique_pack_example_or_reviewed_vocab_override",
            },
            {
                "childKind": "satz",
                "sourceKind": "vocabPack",
                "levels": ["a1", "a2", "b1", "b2"],
                "join": "same_level_exact_example_or_unique_vocab_term_pack",
            },
        ],
        "explicitNonDerivedClozeCount": len(explicit_cloze_ids),
        "directOverrideChildIds": sorted(direct_override_cloze_ids),
        "smalltalkRoutingAudit": {
            "exactRouteOverrideIds": sorted(exact_smalltalk_override_ids),
            "categoryFallbackIds": sorted(category_smalltalk_fallback_ids),
            "courseUnitFallbackIds": sorted(course_unit_smalltalk_fallback_ids),
            "legacyCourseUnitOverrides": sorted(
                legacy_smalltalk_unit_overrides, key=lambda row: row["id"]
            ),
            "phraseDecisions": sorted(
                smalltalk_phrase_decisions, key=lambda row: row["phraseId"]
            ),
            "unresolvedAmbiguousIds": [],
        },
        "uncoveredSourceIds": [],
    }
    return expanded, coverage


def _require_exact_direct_coverage(
    owners: dict[tuple[str, str], set[str]], *, kind: str, expected_ids: set[str]
) -> None:
    actual_ids = {content_id for reference_kind, content_id in owners if reference_kind == kind}
    if actual_ids != expected_ids:
        missing = sorted(expected_ids - actual_ids)
        extra = sorted(actual_ids - expected_ids)
        raise ValueError(f"{kind} coverage mismatch; missing={missing}, extra={extra}")


def _require_exact_derived_coverage(
    owners: dict[tuple[str, str], set[str]],
    *,
    kind: str,
    inherited_ids: set[str],
    expected_ids: set[str],
) -> None:
    direct_ids = {
        content_id for reference_kind, content_id in owners if reference_kind == kind
    }
    duplicate_ids = sorted(direct_ids & inherited_ids)
    missing = sorted(expected_ids - direct_ids - inherited_ids)
    extra = sorted((direct_ids | inherited_ids) - expected_ids)
    if duplicate_ids or missing or extra:
        raise ValueError(
            f"{kind} lineage mismatch; duplicate={duplicate_ids}, "
            f"missing={missing}, extra={extra}"
        )


def _build_c_specs() -> Iterable[SegmentSpec]:
    for key, parent, pack, theme, level, numbers, smalltalk_ids, grammar_ids in C_ROWS:
        batch_seed = f"seed_batch05_{pack}_v1"
        project_seed = f"seed_project_{theme}_v1"
        refs = [_ref("vocabPack", pack, batch_seed)]
        refs.extend(_ref("cloze", f"cloze_{level}_{number:04d}", batch_seed) for number in numbers)
        refs.extend(_ref("satz", f"satz_{level}_{number:04d}", batch_seed) for number in numbers)
        refs.extend(
            _ref("smalltalk", content_id, batch_seed)
            for content_id in smalltalk_ids
        )
        refs.extend(_ref("grammar", content_id, batch_seed) for content_id in grammar_ids)
        refs.append(_ref("project", f"project_{theme}_v1", project_seed))
        title, can_do = C_TEXT[key]
        yield SegmentSpec(
            key=key,
            level=level,
            parent=parent,
            refs=tuple(refs),
            mode="cProject",
            title=title,
            can_do=can_do,
            source_seed_ids=(batch_seed, project_seed),
        )


def _segment_text(
    spec: SegmentSpec, source: SourceIndex
) -> tuple[dict[str, str], dict[str, str]]:
    if spec.title is not None and spec.can_do is not None:
        return dict(spec.title), dict(spec.can_do)
    scenario_ref = next((ref for ref in spec.refs if ref.kind == "scenario"), None)
    if scenario_ref is None:
        raise ValueError(f"{spec.key} has no localized segment text")
    scenario = source.scenarios[scenario_ref.id]
    title = dict(scenario["title"])
    return title, _generic_can_do(title)


def _requirements(key: str, mode: str) -> list[dict[str, Any]]:
    modes = (
        ("openWriting", "oralProduction", "connectedEvidence")
        if mode == "cProject"
        else (mode,)
    )
    return [
        {
            "assessmentItemId": f"assess_{key}_{MODE_SUFFIX[item]}_v1",
            "missionContentLinkId": f"mission_{key}_{MODE_SUFFIX[item]}_v1",
            "evidenceMode": item,
            "rubricVersion": 1,
            "minimumScore": 0.7,
        }
        for item in modes
    ]


def _default_seed(reference: PracticeRef) -> str:
    kind = {
        "vocabPack": "vocab_pack",
        "smalltalk": "smalltalk",
        "grammar": "grammar",
        "cloze": "cloze",
        "satz": "satz",
        "scenario": "scenario",
        "project": "project",
    }[reference.kind]
    return f"seed_{kind}_{reference.id}_v1"


def _read_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return value


def _read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def _require(mapping: dict[str, Any], key: str, label: str) -> Any:
    if key not in mapping:
        raise ValueError(f"unknown {label} {key!r}")
    return mapping[key]


def _json_bytes(value: dict[str, Any]) -> bytes:
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def _write_or_check(path: Path, payload: bytes, *, check: bool) -> None:
    if check:
        if not path.exists() or path.read_bytes() != payload:
            raise SystemExit(f"generated asset is stale: {path.relative_to(ROOT)}")
        return
    path.write_bytes(payload)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="fail if generated files drift")
    args = parser.parse_args()
    catalog, authorities = build_assets()
    _write_or_check(CATALOG_PATH, _json_bytes(catalog), check=args.check)
    _write_or_check(AUTHORITY_PATH, _json_bytes(authorities), check=args.check)


if __name__ == "__main__":
    main()
