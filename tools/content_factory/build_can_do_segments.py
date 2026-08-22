#!/usr/bin/env python3
"""Build the canonical 86-segment course catalog from reviewed source IDs.

The immutable segment denominator is authored here. Raw learning records are
validated as practice provenance only; their count never creates segments.
"""

from __future__ import annotations

import argparse
import copy
import csv
import hashlib
import json
import re
import sys
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Any, Iterable

sys.path.insert(0, str(Path(__file__).resolve().parent))
import scenario_store


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "assets" / "data"
CATALOG_PATH = DATA / "can_do_segments.json"
AUTHORITY_PATH = DATA / "can_do_content_authorities.json"
CONTENT_HUMANIZATION_LEDGER_PATH = (
    ROOT
    / "tools"
    / "content_factory"
    / "review"
    / "content_humanization_20260821.json"
)
CONTENT_HUMANIZATION_LEDGER_REF = (
    "tools/content_factory/review/content_humanization_20260821.json"
)
PUBLISHED_AT = "2026-08-16T00:00:00.000Z"
LEVELS = ("a1", "a2", "b1", "b2", "c1", "c2")
EXPECTED_COUNTS = {"a1": 16, "a2": 16, "b1": 18, "b2": 20, "c1": 8, "c2": 8}
REVIEW_BATCH_MANIFEST_PATHS = (
    ROOT / "tools" / "content_factory" / "drafts" / "batch_06_manifest.json",
)

# A review-batch record may enter a live source asset only after an explicit
# human-approved promotion. Practice provenance is never assessment authority.
REVIEW_CONTENT_PROMOTIONS: dict[tuple[str, str], dict[str, Any]] = {
    ("scenario", "b1_repair_visit_followup"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b1_property_damage_report",
        "assessmentAuthority": False,
    },
    ("scenario", "b2_device_failure_escalation"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b2_remedy_and_appeal",
        "assessmentAuthority": False,
    },
    ("scenario", "c1_survey_limits_briefing"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c1_evidence_limits_conclusion",
        "assessmentAuthority": False,
    },
    ("scenario", "c2_automated_decision_appeal"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c2_technology_traceability_appeal",
        "assessmentAuthority": False,
    },
    ("smalltalk", "smalltalk_b1_0053"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b1_property_damage_report",
        "assessmentAuthority": False,
    },
    ("smalltalk", "smalltalk_b1_0054"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b1_property_damage_report",
        "assessmentAuthority": False,
    },
    ("smalltalk", "smalltalk_b2_0081"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b2_remedy_and_appeal",
        "assessmentAuthority": False,
    },
    ("smalltalk", "smalltalk_b2_0082"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b2_remedy_and_appeal",
        "assessmentAuthority": False,
    },
    ("smalltalk", "smalltalk_c1_0017"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c1_evidence_limits_conclusion",
        "assessmentAuthority": False,
    },
    ("smalltalk", "smalltalk_c1_0018"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c1_evidence_limits_conclusion",
        "assessmentAuthority": False,
    },
    ("smalltalk", "smalltalk_c2_0017"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c2_technology_traceability_appeal",
        "assessmentAuthority": False,
    },
    ("smalltalk", "smalltalk_c2_0018"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c2_technology_traceability_appeal",
        "assessmentAuthority": False,
    },
    ("cloze", "cloze_b1_0080"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b1_property_damage_report",
        "assessmentAuthority": False,
    },
    ("cloze", "cloze_b1_0081"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b1_property_damage_report",
        "assessmentAuthority": False,
    },
    ("cloze", "cloze_b1_0082"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b1_property_damage_report",
        "assessmentAuthority": False,
    },
    ("cloze", "cloze_b1_0083"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b1_property_damage_report",
        "assessmentAuthority": False,
    },
    ("cloze", "cloze_b2_0166"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b2_remedy_and_appeal",
        "assessmentAuthority": False,
    },
    ("cloze", "cloze_b2_0167"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b2_remedy_and_appeal",
        "assessmentAuthority": False,
    },
    ("cloze", "cloze_b2_0168"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b2_remedy_and_appeal",
        "assessmentAuthority": False,
    },
    ("cloze", "cloze_b2_0169"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b2_remedy_and_appeal",
        "assessmentAuthority": False,
    },
    ("cloze", "cloze_c1_0049"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c1_evidence_limits_conclusion",
        "assessmentAuthority": False,
    },
    ("cloze", "cloze_c1_0050"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c1_evidence_limits_conclusion",
        "assessmentAuthority": False,
    },
    ("cloze", "cloze_c1_0051"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c1_evidence_limits_conclusion",
        "assessmentAuthority": False,
    },
    ("cloze", "cloze_c1_0052"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c1_evidence_limits_conclusion",
        "assessmentAuthority": False,
    },
    ("cloze", "cloze_c2_0049"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c2_technology_traceability_appeal",
        "assessmentAuthority": False,
    },
    ("cloze", "cloze_c2_0050"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c2_technology_traceability_appeal",
        "assessmentAuthority": False,
    },
    ("cloze", "cloze_c2_0051"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c2_technology_traceability_appeal",
        "assessmentAuthority": False,
    },
    ("cloze", "cloze_c2_0052"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c2_technology_traceability_appeal",
        "assessmentAuthority": False,
    },
    ("satz", "satz_b1_0074"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b1_property_damage_report",
        "assessmentAuthority": False,
    },
    ("satz", "satz_b1_0075"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b1_property_damage_report",
        "assessmentAuthority": False,
    },
    ("satz", "satz_b1_0076"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b1_property_damage_report",
        "assessmentAuthority": False,
    },
    ("satz", "satz_b1_0077"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b1_property_damage_report",
        "assessmentAuthority": False,
    },
    ("satz", "satz_b1_0078"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b1_property_damage_report",
        "assessmentAuthority": False,
    },
    ("satz", "satz_b1_0079"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b1_property_damage_report",
        "assessmentAuthority": False,
    },
    ("satz", "satz_b2_0150"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b2_remedy_and_appeal",
        "assessmentAuthority": False,
    },
    ("satz", "satz_b2_0151"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b2_remedy_and_appeal",
        "assessmentAuthority": False,
    },
    ("satz", "satz_b2_0152"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b2_remedy_and_appeal",
        "assessmentAuthority": False,
    },
    ("satz", "satz_b2_0153"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b2_remedy_and_appeal",
        "assessmentAuthority": False,
    },
    ("satz", "satz_b2_0154"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b2_remedy_and_appeal",
        "assessmentAuthority": False,
    },
    ("satz", "satz_b2_0155"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b2_remedy_and_appeal",
        "assessmentAuthority": False,
    },
    ("satz", "satz_c1_0049"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c1_evidence_limits_conclusion",
        "assessmentAuthority": False,
    },
    ("satz", "satz_c1_0050"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c1_evidence_limits_conclusion",
        "assessmentAuthority": False,
    },
    ("satz", "satz_c1_0051"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c1_evidence_limits_conclusion",
        "assessmentAuthority": False,
    },
    ("satz", "satz_c1_0052"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c1_evidence_limits_conclusion",
        "assessmentAuthority": False,
    },
    ("satz", "satz_c1_0053"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c1_evidence_limits_conclusion",
        "assessmentAuthority": False,
    },
    ("satz", "satz_c1_0054"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c1_evidence_limits_conclusion",
        "assessmentAuthority": False,
    },
    ("satz", "satz_c2_0049"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c2_technology_traceability_appeal",
        "assessmentAuthority": False,
    },
    ("satz", "satz_c2_0050"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c2_technology_traceability_appeal",
        "assessmentAuthority": False,
    },
    ("satz", "satz_c2_0051"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c2_technology_traceability_appeal",
        "assessmentAuthority": False,
    },
    ("satz", "satz_c2_0052"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c2_technology_traceability_appeal",
        "assessmentAuthority": False,
    },
    ("satz", "satz_c2_0053"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c2_technology_traceability_appeal",
        "assessmentAuthority": False,
    },
    ("satz", "satz_c2_0054"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c2_technology_traceability_appeal",
        "assessmentAuthority": False,
    },
    ("pronunciation", "pronunciation_b1_0001"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b1_property_damage_report",
        "assessmentAuthority": False,
    },
    ("pronunciation", "pronunciation_b1_0002"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b1_property_damage_report",
        "assessmentAuthority": False,
    },
    ("pronunciation", "pronunciation_b1_0003"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b1_property_damage_report",
        "assessmentAuthority": False,
    },
    ("pronunciation", "pronunciation_b1_0004"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b1_property_damage_report",
        "assessmentAuthority": False,
    },
    ("pronunciation", "pronunciation_b2_0001"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b2_remedy_and_appeal",
        "assessmentAuthority": False,
    },
    ("pronunciation", "pronunciation_b2_0002"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b2_remedy_and_appeal",
        "assessmentAuthority": False,
    },
    ("pronunciation", "pronunciation_b2_0003"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b2_remedy_and_appeal",
        "assessmentAuthority": False,
    },
    ("pronunciation", "pronunciation_b2_0004"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "b2_remedy_and_appeal",
        "assessmentAuthority": False,
    },
    ("pronunciation", "pronunciation_c1_0001"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c1_evidence_limits_conclusion",
        "assessmentAuthority": False,
    },
    ("pronunciation", "pronunciation_c1_0002"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c1_evidence_limits_conclusion",
        "assessmentAuthority": False,
    },
    ("pronunciation", "pronunciation_c1_0003"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c1_evidence_limits_conclusion",
        "assessmentAuthority": False,
    },
    ("pronunciation", "pronunciation_c1_0004"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c1_evidence_limits_conclusion",
        "assessmentAuthority": False,
    },
    ("pronunciation", "pronunciation_c2_0001"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c2_technology_traceability_appeal",
        "assessmentAuthority": False,
    },
    ("pronunciation", "pronunciation_c2_0002"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c2_technology_traceability_appeal",
        "assessmentAuthority": False,
    },
    ("pronunciation", "pronunciation_c2_0003"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c2_technology_traceability_appeal",
        "assessmentAuthority": False,
    },
    ("pronunciation", "pronunciation_c2_0004"): {
        "approved": True,
        "live": True,
        "canDoSegmentKey": "c2_technology_traceability_appeal",
        "assessmentAuthority": False,
    },
}

# Partner-family Batch 07/08 attaches extra practice to published core
# segments. This map is not a review-batch promotion ledger, so unused
# REVIEW_CONTENT_PROMOTIONS checks stay limited to Batch 06.
PARTNER_FAMILY_SEGMENT_ROUTES: dict[tuple[str, str], str] = {}
_C1_FAMILY = "c1_participatory_access_remedy"
_C2_FAMILY = "c2_institutional_deliberation"
_AB_FAMILY = {
    "a1": "a1_11_titles_relationships",
    "a2": "a2_running_late",
    "b1": "b1_intimate_feelings",
    "b2": "b2_formal_soft_reformulation",
}
for _ident, _level in (
    ("a1_partner_first_door", "a1"),
    ("a1_partner_seollal_bow", "a1"),
    ("a1_partner_songpyeon_too_big", "a1"),
    ("a1_partner_more_side_dishes", "a1"),
    ("a1_partner_gift_too_big", "a1"),
    ("a1_partner_wrong_seat", "a1"),
    ("a1_partner_new_year_money", "a1"),
    ("a2_partner_leftover_bags", "a2"),
    ("a2_partner_holiday_train", "a2"),
    ("a2_partner_banmal_slip", "a2"),
    ("a2_partner_morning_greeting", "a2"),
    ("a2_partner_group_chat_join", "a2"),
    ("a2_partner_hanbok_rental", "a2"),
    ("b1_partner_marriage_question", "b1"),
    ("b1_partner_drink_table", "b1"),
    ("b1_partner_overnight_door", "b1"),
    ("b1_partner_salary_deflect", "b1"),
    ("b1_partner_interpret_skip", "b1"),
    ("b1_partner_heavy_bags_home", "b1"),
    ("b2_partner_inlaw_rotation", "b2"),
    ("b2_partner_public_intro", "b2"),
    ("b2_partner_dowry_joke", "b2"),
    ("b2_partner_holiday_labor_chart", "b2"),
    ("b2_partner_photo_permission", "b2"),
    ("c1_partner_invisible_labor", "c1"),
    ("c1_partner_guest_or_family", "c1"),
    ("c2_partner_name_and_memory", "c2"),
    ("c2_partner_document_the_place", "c2"),
):
    PARTNER_FAMILY_SEGMENT_ROUTES[("scenario", _ident)] = (
        _C1_FAMILY if _level == "c1" else _C2_FAMILY if _level == "c2" else _AB_FAMILY[_level]
    )
for _ident in (
    "c1_partner_family_framing_1",
    "c1_partner_holiday_labor_1",
):
    PARTNER_FAMILY_SEGMENT_ROUTES[("vocabPack", _ident)] = _C1_FAMILY
for _ident in (
    "c2_partner_inlaw_power_1",
    "c2_partner_name_memory_1",
):
    PARTNER_FAMILY_SEGMENT_ROUTES[("vocabPack", _ident)] = _C2_FAMILY
PARTNER_FAMILY_SEGMENT_ROUTES[("grammar", "grammar_c1_family_framing")] = _C1_FAMILY
PARTNER_FAMILY_SEGMENT_ROUTES[("grammar", "grammar_c2_regardless_of_kin")] = _C2_FAMILY
for _number in range(65, 81):
    PARTNER_FAMILY_SEGMENT_ROUTES[("smalltalk", f"smalltalk_a1_{_number:04d}")] = _AB_FAMILY["a1"]
for _number in range(58, 74):
    PARTNER_FAMILY_SEGMENT_ROUTES[("smalltalk", f"smalltalk_a2_{_number:04d}")] = _AB_FAMILY["a2"]
for _number in range(55, 71):
    PARTNER_FAMILY_SEGMENT_ROUTES[("smalltalk", f"smalltalk_b1_{_number:04d}")] = _AB_FAMILY["b1"]
for _number in range(83, 99):
    PARTNER_FAMILY_SEGMENT_ROUTES[("smalltalk", f"smalltalk_b2_{_number:04d}")] = _AB_FAMILY["b2"]
for _number in range(19, 23):
    PARTNER_FAMILY_SEGMENT_ROUTES[("smalltalk", f"smalltalk_c1_{_number:04d}")] = _C1_FAMILY
    PARTNER_FAMILY_SEGMENT_ROUTES[("smalltalk", f"smalltalk_c2_{_number:04d}")] = _C2_FAMILY
for _number in range(53, 77):
    PARTNER_FAMILY_SEGMENT_ROUTES[("cloze", f"cloze_c1_{_number:04d}")] = _C1_FAMILY
    PARTNER_FAMILY_SEGMENT_ROUTES[("cloze", f"cloze_c2_{_number:04d}")] = _C2_FAMILY
for _number in range(55, 79):
    PARTNER_FAMILY_SEGMENT_ROUTES[("satz", f"satz_c1_{_number:04d}")] = _C1_FAMILY
    PARTNER_FAMILY_SEGMENT_ROUTES[("satz", f"satz_c2_{_number:04d}")] = _C2_FAMILY

# Batch 09/10 4x remainder attaches extra practice to published core
# segments without changing the 86-slot denominator.
FOUR_X_SEGMENT_ROUTES: dict[tuple[str, str], str] = {}
_C1_EVIDENCE = "c1_evidence_limits_conclusion"
_C1_ACCESS = "c1_participatory_access_remedy"
_C1_TRADEOFF = "c1_local_tradeoff_adaptation"
_C1_RISK = "c1_risk_uncertainty"
_C2_INSTITUTION = "c2_institutional_deliberation"
_C2_FRAMING = "c2_framing_responsibility"
_C2_TECH = "c2_technology_traceability_appeal"
_AB_FOUR_X = {
    "a1": "a1_16_survival_capstone",
    "a2": "a2_subway_directions",
    "b1": "b1_delivery_resolution",
    "b2": "b2_formal_complaint",
}
for _ident in (
    "c1_evidence_caveat_1",
    "c1_public_briefing_1",
    "c1_survey_design_1",
    "c1_risk_wording_1",
):
    FOUR_X_SEGMENT_ROUTES[("vocabPack", _ident)] = _C1_EVIDENCE
for _ident in (
    "c1_access_cost_1",
    "c1_participation_design_1",
):
    FOUR_X_SEGMENT_ROUTES[("vocabPack", _ident)] = _C1_ACCESS
for _ident in (
    "c1_local_tradeoff_1",
    "c1_maintenance_burden_1",
):
    FOUR_X_SEGMENT_ROUTES[("vocabPack", _ident)] = _C1_TRADEOFF
for _ident in (
    "c2_framing_analysis_1",
    "c2_institutional_voice_1",
):
    FOUR_X_SEGMENT_ROUTES[("vocabPack", _ident)] = _C2_FRAMING
for _ident in (
    "c2_memory_narrative_1",
    "c2_authority_language_1",
):
    FOUR_X_SEGMENT_ROUTES[("vocabPack", _ident)] = _C2_INSTITUTION
for _ident in (
    "c2_appeal_path_1",
    "c2_audit_trail_1",
    "c2_withdrawal_right_1",
    "c2_automated_harm_1",
):
    FOUR_X_SEGMENT_ROUTES[("vocabPack", _ident)] = _C2_TECH
for _ident in (
    "grammar_c1_regardless_noun",
    "grammar_c1_given_situation",
    "grammar_c1_leaning_on",
    "grammar_c1_even_if_doing",
):
    FOUR_X_SEGMENT_ROUTES[("grammar", _ident)] = _C1_EVIDENCE
for _ident in (
    "grammar_c2_defined_as",
    "grammar_c2_as_already_set",
    "grammar_c2_on_the_premise",
    "grammar_c2_wishing_to",
):
    FOUR_X_SEGMENT_ROUTES[("grammar", _ident)] = _C2_INSTITUTION
FOUR_X_SEGMENT_ROUTES[("smalltalk", "smalltalk_a1_0081")] = "a1_12_daily_negation"
FOUR_X_SEGMENT_ROUTES[("smalltalk", "smalltalk_a1_0082")] = "a1_04_order_request_object"
FOUR_X_SEGMENT_ROUTES[("smalltalk", "smalltalk_a2_0074")] = "a2_running_late"
FOUR_X_SEGMENT_ROUTES[("smalltalk", "smalltalk_a2_0075")] = "a2_feeling_sick"
FOUR_X_SEGMENT_ROUTES[("smalltalk", "smalltalk_b1_0071")] = "b1_team_role_coordination"
FOUR_X_SEGMENT_ROUTES[("smalltalk", "smalltalk_b1_0072")] = "b1_plans_with_reasons"
FOUR_X_SEGMENT_ROUTES[("smalltalk", "smalltalk_b2_0099")] = "b2_interview_experience"
FOUR_X_SEGMENT_ROUTES[("smalltalk", "smalltalk_b2_0100")] = "b2_formal_meeting_opening"
FOUR_X_SEGMENT_ROUTES[("smalltalk", "smalltalk_c1_0023")] = _C1_EVIDENCE
FOUR_X_SEGMENT_ROUTES[("smalltalk", "smalltalk_c1_0024")] = _C1_RISK
FOUR_X_SEGMENT_ROUTES[("smalltalk", "smalltalk_c2_0023")] = _C2_INSTITUTION
FOUR_X_SEGMENT_ROUTES[("smalltalk", "smalltalk_c2_0024")] = _C2_TECH
for _number in range(77, 125):
    FOUR_X_SEGMENT_ROUTES[("cloze", f"cloze_c1_{_number:04d}")] = _C1_EVIDENCE
    FOUR_X_SEGMENT_ROUTES[("cloze", f"cloze_c2_{_number:04d}")] = _C2_INSTITUTION
for _number in range(125, 173):
    FOUR_X_SEGMENT_ROUTES[("cloze", f"cloze_c1_{_number:04d}")] = _C1_ACCESS
    FOUR_X_SEGMENT_ROUTES[("cloze", f"cloze_c2_{_number:04d}")] = _C2_TECH
for _number in range(79, 127):
    FOUR_X_SEGMENT_ROUTES[("satz", f"satz_c1_{_number:04d}")] = _C1_EVIDENCE
    FOUR_X_SEGMENT_ROUTES[("satz", f"satz_c2_{_number:04d}")] = _C2_INSTITUTION
for _number in range(127, 175):
    FOUR_X_SEGMENT_ROUTES[("satz", f"satz_c1_{_number:04d}")] = _C1_TRADEOFF
    FOUR_X_SEGMENT_ROUTES[("satz", f"satz_c2_{_number:04d}")] = _C2_TECH
for _ident in (
    "c1_uncertainty",
    "c1_sample_bias",
    "c1_briefing_number",
    "c1_question_window",
    "c1_leading_item",
    "c1_relative_risk",
    "c1_access_time",
    "c1_speaking_slot",
):
    FOUR_X_SEGMENT_ROUTES[("scenario", _ident)] = _C1_EVIDENCE
for _ident in (
    "c2_discourse_premise",
    "c2_passive_hide",
    "c2_mandate_edge",
    "c2_archive_gap",
    "c2_appeal_bot",
    "c2_trace_log",
    "c2_withdraw_deep",
    "c2_uneven_impact",
):
    FOUR_X_SEGMENT_ROUTES[("scenario", _ident)] = _C2_TECH
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

# Batch 11 (2026-08-18 승격) 의 C1/C2 12편.  A1~B2 는 courseUnitId 로
# UNIT_DEFAULT_ROUTE 폴백을 타지만 C1/C2 분기에는 그 폴백이 없어서
# (_build_specs 의 `if level in ("c1", "c2")`), 명시 라우트가 없으면 조용히
# 건너뛰고 _require_exact_direct_coverage 가 red 로 잡는다.
# 소재(팬덤·연애·게임)가 아니라 **담화 기능**으로 붙였다.
# 제약: 세그먼트의 parentCourseUnitId 가 시나리오의 courseUnitId 와 같아야 한다
# (SourceIndex.resolve 의 expected_parent).  그래서 라우트는 "의미가 제일 가까운
# 세그먼트"가 아니라 "그 유닛 **안에서** 의미가 제일 가까운 세그먼트"다.
BATCH_11_SEGMENT_ROUTES: dict[tuple[str, str], str] = {
    # c1_01_evidence_public_reasoning
    ("scenario", "c1_daily_prices_vs_data"): "c1_evidence_limits_conclusion",
    ("scenario", "c1_youtube_health_claims"): "c1_evidence_validity",
    ("scenario", "c1_gaming_playtime_policy"): "c1_risk_uncertainty",
    # c1_02_inclusive_sustainable_systems
    ("scenario", "c1_friends_venue_access"): "c1_accessibility_barrier_diagnosis",
    ("scenario", "c1_dating_app_safety"): "c1_participatory_access_remedy",
    ("scenario", "c1_kpop_fan_labor"): "c1_sustainable_lifecycle",
    # c2_01_interpretation_institutions
    ("scenario", "c2_dating_romance_frames"): "c2_narrative_perspective",
    ("scenario", "c2_kpop_fandom_language"): "c2_discourse_boundary_power",
    ("scenario", "c2_friends_quoted_privately"): "c2_interpretation_justification",
    # c2_02_technology_public_ethics
    ("scenario", "c2_daily_automation_redress"): "c2_technology_traceability_appeal",
    ("scenario", "c2_gaming_auto_sanction"): "c2_technology_traceability_appeal",
    ("scenario", "c2_youtube_algorithm_duty"): "c2_technology_responsibility_rights",
}

# Batch 12 (2026-08-18 승격) 의 신규 8유닛 콘텐츠.  유닛은 늘었지만 세그먼트 86 은
# 그대로다 — Batch 09/10 4x 와 같은 원칙으로 기존 published 세그먼트에 붙인다.
# 주제 짝은 같은 소재를 다루는 Batch 11 시나리오 라우트와 일치시켰다.
BATCH_12_SEGMENT_ROUTES: dict[tuple[str, str], str] = {
    ("vocabPack", "c1_media_evidence_1"): "c1_evidence_validity",
    ("vocabPack", "c1_play_time_policy_1"): "c1_local_tradeoff_adaptation",
    ("vocabPack", "c1_fan_labor_1"): "c1_sustainable_lifecycle",
    ("vocabPack", "c1_intimacy_safety_1"): "c1_participatory_access_remedy",
    ("vocabPack", "c2_automation_redress_1"): "c2_technology_traceability_appeal",
    ("vocabPack", "c2_sanction_accountability_1"): "c2_technology_responsibility_rights",
    ("vocabPack", "c2_relationship_narratives_1"): "c2_narrative_perspective",
    ("vocabPack", "c2_fandom_discourse_1"): "c2_discourse_boundary_power",
    # grammar
    ("grammar", "grammar_c1_limited_to"): "c1_evidence_validity",
    ("grammar", "grammar_c2_no_more_than_doing"): "c2_technology_traceability_appeal",
    ("grammar", "grammar_c1_not_necessarily"): "c1_local_tradeoff_adaptation",
    ("grammar", "grammar_c2_merely_on_grounds"): "c2_technology_responsibility_rights",
    ("grammar", "grammar_c1_insufficient_for"): "c1_sustainable_lifecycle",
    ("grammar", "grammar_c2_as_if_framing"): "c2_narrative_perspective",
    ("grammar", "grammar_c1_but_not"): "c1_participatory_access_remedy",
    ("grammar", "grammar_c2_no_matter_how"): "c2_discourse_boundary_power",
    # smalltalk
    ("smalltalk", "smalltalk_c1_0025"): "c1_evidence_validity",
    ("smalltalk", "smalltalk_c1_0026"): "c1_evidence_validity",
    ("smalltalk", "smalltalk_c2_0025"): "c2_technology_traceability_appeal",
    ("smalltalk", "smalltalk_c2_0026"): "c2_technology_traceability_appeal",
    ("smalltalk", "smalltalk_c1_0027"): "c1_local_tradeoff_adaptation",
    ("smalltalk", "smalltalk_c1_0028"): "c1_local_tradeoff_adaptation",
    ("smalltalk", "smalltalk_c2_0027"): "c2_technology_responsibility_rights",
    ("smalltalk", "smalltalk_c2_0028"): "c2_technology_responsibility_rights",
    ("smalltalk", "smalltalk_c1_0029"): "c1_sustainable_lifecycle",
    ("smalltalk", "smalltalk_c1_0030"): "c1_sustainable_lifecycle",
    ("smalltalk", "smalltalk_c2_0029"): "c2_narrative_perspective",
    ("smalltalk", "smalltalk_c2_0030"): "c2_narrative_perspective",
    ("smalltalk", "smalltalk_c1_0031"): "c1_participatory_access_remedy",
    ("smalltalk", "smalltalk_c1_0032"): "c1_participatory_access_remedy",
    ("smalltalk", "smalltalk_c2_0031"): "c2_discourse_boundary_power",
    ("smalltalk", "smalltalk_c2_0032"): "c2_discourse_boundary_power",
    # cloze
    ("cloze", "cloze_c1_0173"): "c1_evidence_validity",
    ("cloze", "cloze_c1_0174"): "c1_evidence_validity",
    ("cloze", "cloze_c1_0175"): "c1_evidence_validity",
    ("cloze", "cloze_c1_0176"): "c1_evidence_validity",
    ("cloze", "cloze_c1_0177"): "c1_evidence_validity",
    ("cloze", "cloze_c1_0178"): "c1_evidence_validity",
    ("cloze", "cloze_c1_0179"): "c1_evidence_validity",
    ("cloze", "cloze_c1_0180"): "c1_evidence_validity",
    ("cloze", "cloze_c1_0181"): "c1_evidence_validity",
    ("cloze", "cloze_c1_0182"): "c1_evidence_validity",
    ("cloze", "cloze_c1_0183"): "c1_evidence_validity",
    ("cloze", "cloze_c1_0184"): "c1_evidence_validity",
    ("cloze", "cloze_c1_0185"): "c1_local_tradeoff_adaptation",
    ("cloze", "cloze_c1_0186"): "c1_local_tradeoff_adaptation",
    ("cloze", "cloze_c1_0187"): "c1_local_tradeoff_adaptation",
    ("cloze", "cloze_c1_0188"): "c1_local_tradeoff_adaptation",
    ("cloze", "cloze_c1_0189"): "c1_local_tradeoff_adaptation",
    ("cloze", "cloze_c1_0190"): "c1_local_tradeoff_adaptation",
    ("cloze", "cloze_c1_0191"): "c1_local_tradeoff_adaptation",
    ("cloze", "cloze_c1_0192"): "c1_local_tradeoff_adaptation",
    ("cloze", "cloze_c1_0193"): "c1_local_tradeoff_adaptation",
    ("cloze", "cloze_c1_0194"): "c1_local_tradeoff_adaptation",
    ("cloze", "cloze_c1_0195"): "c1_local_tradeoff_adaptation",
    ("cloze", "cloze_c1_0196"): "c1_local_tradeoff_adaptation",
    ("cloze", "cloze_c1_0197"): "c1_sustainable_lifecycle",
    ("cloze", "cloze_c1_0198"): "c1_sustainable_lifecycle",
    ("cloze", "cloze_c1_0199"): "c1_sustainable_lifecycle",
    ("cloze", "cloze_c1_0200"): "c1_sustainable_lifecycle",
    ("cloze", "cloze_c1_0201"): "c1_sustainable_lifecycle",
    ("cloze", "cloze_c1_0202"): "c1_sustainable_lifecycle",
    ("cloze", "cloze_c1_0203"): "c1_sustainable_lifecycle",
    ("cloze", "cloze_c1_0204"): "c1_sustainable_lifecycle",
    ("cloze", "cloze_c1_0205"): "c1_sustainable_lifecycle",
    ("cloze", "cloze_c1_0206"): "c1_sustainable_lifecycle",
    ("cloze", "cloze_c1_0207"): "c1_sustainable_lifecycle",
    ("cloze", "cloze_c1_0208"): "c1_sustainable_lifecycle",
    ("cloze", "cloze_c1_0209"): "c1_participatory_access_remedy",
    ("cloze", "cloze_c1_0210"): "c1_participatory_access_remedy",
    ("cloze", "cloze_c1_0211"): "c1_participatory_access_remedy",
    ("cloze", "cloze_c1_0212"): "c1_participatory_access_remedy",
    ("cloze", "cloze_c1_0213"): "c1_participatory_access_remedy",
    ("cloze", "cloze_c1_0214"): "c1_participatory_access_remedy",
    ("cloze", "cloze_c1_0215"): "c1_participatory_access_remedy",
    ("cloze", "cloze_c1_0216"): "c1_participatory_access_remedy",
    ("cloze", "cloze_c1_0217"): "c1_participatory_access_remedy",
    ("cloze", "cloze_c1_0218"): "c1_participatory_access_remedy",
    ("cloze", "cloze_c1_0219"): "c1_participatory_access_remedy",
    ("cloze", "cloze_c1_0220"): "c1_participatory_access_remedy",
    ("cloze", "cloze_c2_0173"): "c2_technology_traceability_appeal",
    ("cloze", "cloze_c2_0174"): "c2_technology_traceability_appeal",
    ("cloze", "cloze_c2_0175"): "c2_technology_traceability_appeal",
    ("cloze", "cloze_c2_0176"): "c2_technology_traceability_appeal",
    ("cloze", "cloze_c2_0177"): "c2_technology_traceability_appeal",
    ("cloze", "cloze_c2_0178"): "c2_technology_traceability_appeal",
    ("cloze", "cloze_c2_0179"): "c2_technology_traceability_appeal",
    ("cloze", "cloze_c2_0180"): "c2_technology_traceability_appeal",
    ("cloze", "cloze_c2_0181"): "c2_technology_traceability_appeal",
    ("cloze", "cloze_c2_0182"): "c2_technology_traceability_appeal",
    ("cloze", "cloze_c2_0183"): "c2_technology_traceability_appeal",
    ("cloze", "cloze_c2_0184"): "c2_technology_traceability_appeal",
    ("cloze", "cloze_c2_0185"): "c2_technology_responsibility_rights",
    ("cloze", "cloze_c2_0186"): "c2_technology_responsibility_rights",
    ("cloze", "cloze_c2_0187"): "c2_technology_responsibility_rights",
    ("cloze", "cloze_c2_0188"): "c2_technology_responsibility_rights",
    ("cloze", "cloze_c2_0189"): "c2_technology_responsibility_rights",
    ("cloze", "cloze_c2_0190"): "c2_technology_responsibility_rights",
    ("cloze", "cloze_c2_0191"): "c2_technology_responsibility_rights",
    ("cloze", "cloze_c2_0192"): "c2_technology_responsibility_rights",
    ("cloze", "cloze_c2_0193"): "c2_technology_responsibility_rights",
    ("cloze", "cloze_c2_0194"): "c2_technology_responsibility_rights",
    ("cloze", "cloze_c2_0195"): "c2_technology_responsibility_rights",
    ("cloze", "cloze_c2_0196"): "c2_technology_responsibility_rights",
    ("cloze", "cloze_c2_0197"): "c2_narrative_perspective",
    ("cloze", "cloze_c2_0198"): "c2_narrative_perspective",
    ("cloze", "cloze_c2_0199"): "c2_narrative_perspective",
    ("cloze", "cloze_c2_0200"): "c2_narrative_perspective",
    ("cloze", "cloze_c2_0201"): "c2_narrative_perspective",
    ("cloze", "cloze_c2_0202"): "c2_narrative_perspective",
    ("cloze", "cloze_c2_0203"): "c2_narrative_perspective",
    ("cloze", "cloze_c2_0204"): "c2_narrative_perspective",
    ("cloze", "cloze_c2_0205"): "c2_narrative_perspective",
    ("cloze", "cloze_c2_0206"): "c2_narrative_perspective",
    ("cloze", "cloze_c2_0207"): "c2_narrative_perspective",
    ("cloze", "cloze_c2_0208"): "c2_narrative_perspective",
    ("cloze", "cloze_c2_0209"): "c2_discourse_boundary_power",
    ("cloze", "cloze_c2_0210"): "c2_discourse_boundary_power",
    ("cloze", "cloze_c2_0211"): "c2_discourse_boundary_power",
    ("cloze", "cloze_c2_0212"): "c2_discourse_boundary_power",
    ("cloze", "cloze_c2_0213"): "c2_discourse_boundary_power",
    ("cloze", "cloze_c2_0214"): "c2_discourse_boundary_power",
    ("cloze", "cloze_c2_0215"): "c2_discourse_boundary_power",
    ("cloze", "cloze_c2_0216"): "c2_discourse_boundary_power",
    ("cloze", "cloze_c2_0217"): "c2_discourse_boundary_power",
    ("cloze", "cloze_c2_0218"): "c2_discourse_boundary_power",
    ("cloze", "cloze_c2_0219"): "c2_discourse_boundary_power",
    ("cloze", "cloze_c2_0220"): "c2_discourse_boundary_power",
    # satz
    ("satz", "satz_c1_0175"): "c1_evidence_validity",
    ("satz", "satz_c1_0176"): "c1_evidence_validity",
    ("satz", "satz_c1_0177"): "c1_evidence_validity",
    ("satz", "satz_c1_0178"): "c1_evidence_validity",
    ("satz", "satz_c1_0179"): "c1_evidence_validity",
    ("satz", "satz_c1_0180"): "c1_evidence_validity",
    ("satz", "satz_c1_0181"): "c1_evidence_validity",
    ("satz", "satz_c1_0182"): "c1_evidence_validity",
    ("satz", "satz_c1_0183"): "c1_evidence_validity",
    ("satz", "satz_c1_0184"): "c1_evidence_validity",
    ("satz", "satz_c1_0185"): "c1_evidence_validity",
    ("satz", "satz_c1_0186"): "c1_evidence_validity",
    ("satz", "satz_c1_0187"): "c1_local_tradeoff_adaptation",
    ("satz", "satz_c1_0188"): "c1_local_tradeoff_adaptation",
    ("satz", "satz_c1_0189"): "c1_local_tradeoff_adaptation",
    ("satz", "satz_c1_0190"): "c1_local_tradeoff_adaptation",
    ("satz", "satz_c1_0191"): "c1_local_tradeoff_adaptation",
    ("satz", "satz_c1_0192"): "c1_local_tradeoff_adaptation",
    ("satz", "satz_c1_0193"): "c1_local_tradeoff_adaptation",
    ("satz", "satz_c1_0194"): "c1_local_tradeoff_adaptation",
    ("satz", "satz_c1_0195"): "c1_local_tradeoff_adaptation",
    ("satz", "satz_c1_0196"): "c1_local_tradeoff_adaptation",
    ("satz", "satz_c1_0197"): "c1_local_tradeoff_adaptation",
    ("satz", "satz_c1_0198"): "c1_local_tradeoff_adaptation",
    ("satz", "satz_c1_0199"): "c1_sustainable_lifecycle",
    ("satz", "satz_c1_0200"): "c1_sustainable_lifecycle",
    ("satz", "satz_c1_0201"): "c1_sustainable_lifecycle",
    ("satz", "satz_c1_0202"): "c1_sustainable_lifecycle",
    ("satz", "satz_c1_0203"): "c1_sustainable_lifecycle",
    ("satz", "satz_c1_0204"): "c1_sustainable_lifecycle",
    ("satz", "satz_c1_0205"): "c1_sustainable_lifecycle",
    ("satz", "satz_c1_0206"): "c1_sustainable_lifecycle",
    ("satz", "satz_c1_0207"): "c1_sustainable_lifecycle",
    ("satz", "satz_c1_0208"): "c1_sustainable_lifecycle",
    ("satz", "satz_c1_0209"): "c1_sustainable_lifecycle",
    ("satz", "satz_c1_0210"): "c1_sustainable_lifecycle",
    ("satz", "satz_c1_0211"): "c1_participatory_access_remedy",
    ("satz", "satz_c1_0212"): "c1_participatory_access_remedy",
    ("satz", "satz_c1_0213"): "c1_participatory_access_remedy",
    ("satz", "satz_c1_0214"): "c1_participatory_access_remedy",
    ("satz", "satz_c1_0215"): "c1_participatory_access_remedy",
    ("satz", "satz_c1_0216"): "c1_participatory_access_remedy",
    ("satz", "satz_c1_0217"): "c1_participatory_access_remedy",
    ("satz", "satz_c1_0218"): "c1_participatory_access_remedy",
    ("satz", "satz_c1_0219"): "c1_participatory_access_remedy",
    ("satz", "satz_c1_0220"): "c1_participatory_access_remedy",
    ("satz", "satz_c1_0221"): "c1_participatory_access_remedy",
    ("satz", "satz_c1_0222"): "c1_participatory_access_remedy",
    ("satz", "satz_c2_0175"): "c2_technology_traceability_appeal",
    ("satz", "satz_c2_0176"): "c2_technology_traceability_appeal",
    ("satz", "satz_c2_0177"): "c2_technology_traceability_appeal",
    ("satz", "satz_c2_0178"): "c2_technology_traceability_appeal",
    ("satz", "satz_c2_0179"): "c2_technology_traceability_appeal",
    ("satz", "satz_c2_0180"): "c2_technology_traceability_appeal",
    ("satz", "satz_c2_0181"): "c2_technology_traceability_appeal",
    ("satz", "satz_c2_0182"): "c2_technology_traceability_appeal",
    ("satz", "satz_c2_0183"): "c2_technology_traceability_appeal",
    ("satz", "satz_c2_0184"): "c2_technology_traceability_appeal",
    ("satz", "satz_c2_0185"): "c2_technology_traceability_appeal",
    ("satz", "satz_c2_0186"): "c2_technology_traceability_appeal",
    ("satz", "satz_c2_0187"): "c2_technology_responsibility_rights",
    ("satz", "satz_c2_0188"): "c2_technology_responsibility_rights",
    ("satz", "satz_c2_0189"): "c2_technology_responsibility_rights",
    ("satz", "satz_c2_0190"): "c2_technology_responsibility_rights",
    ("satz", "satz_c2_0191"): "c2_technology_responsibility_rights",
    ("satz", "satz_c2_0192"): "c2_technology_responsibility_rights",
    ("satz", "satz_c2_0193"): "c2_technology_responsibility_rights",
    ("satz", "satz_c2_0194"): "c2_technology_responsibility_rights",
    ("satz", "satz_c2_0195"): "c2_technology_responsibility_rights",
    ("satz", "satz_c2_0196"): "c2_technology_responsibility_rights",
    ("satz", "satz_c2_0197"): "c2_technology_responsibility_rights",
    ("satz", "satz_c2_0198"): "c2_technology_responsibility_rights",
    ("satz", "satz_c2_0199"): "c2_narrative_perspective",
    ("satz", "satz_c2_0200"): "c2_narrative_perspective",
    ("satz", "satz_c2_0201"): "c2_narrative_perspective",
    ("satz", "satz_c2_0202"): "c2_narrative_perspective",
    ("satz", "satz_c2_0203"): "c2_narrative_perspective",
    ("satz", "satz_c2_0204"): "c2_narrative_perspective",
    ("satz", "satz_c2_0205"): "c2_narrative_perspective",
    ("satz", "satz_c2_0206"): "c2_narrative_perspective",
    ("satz", "satz_c2_0207"): "c2_narrative_perspective",
    ("satz", "satz_c2_0208"): "c2_narrative_perspective",
    ("satz", "satz_c2_0209"): "c2_narrative_perspective",
    ("satz", "satz_c2_0210"): "c2_narrative_perspective",
    ("satz", "satz_c2_0211"): "c2_discourse_boundary_power",
    ("satz", "satz_c2_0212"): "c2_discourse_boundary_power",
    ("satz", "satz_c2_0213"): "c2_discourse_boundary_power",
    ("satz", "satz_c2_0214"): "c2_discourse_boundary_power",
    ("satz", "satz_c2_0215"): "c2_discourse_boundary_power",
    ("satz", "satz_c2_0216"): "c2_discourse_boundary_power",
    ("satz", "satz_c2_0217"): "c2_discourse_boundary_power",
    ("satz", "satz_c2_0218"): "c2_discourse_boundary_power",
    ("satz", "satz_c2_0219"): "c2_discourse_boundary_power",
    ("satz", "satz_c2_0220"): "c2_discourse_boundary_power",
    ("satz", "satz_c2_0221"): "c2_discourse_boundary_power",
    ("satz", "satz_c2_0222"): "c2_discourse_boundary_power",
}

# Batch 15 (2026-08-18) — C1 확장 7칸 28편. 세그먼트 86 은 그대로 두고 기존
# published 세그먼트에 붙인다 (Batch 09/10·12 와 같은 원칙).
BATCH_15_SEGMENT_ROUTES: dict[tuple[str, str], str] = {
    # conflict_interest → c1_evidence_validity
    ("scenario", "c1_conflict_interest_disclose_stake"): "c1_evidence_validity",
    ("scenario", "c1_conflict_interest_recuse_request"): "c1_evidence_validity",
    ("scenario", "c1_conflict_interest_sponsored_talk"): "c1_evidence_validity",
    ("scenario", "c1_conflict_interest_dual_role"): "c1_evidence_validity",
    # policy → c1_local_tradeoff_adaptation
    ("scenario", "c1_policy_pilot_before_rollout"): "c1_local_tradeoff_adaptation",
    ("scenario", "c1_policy_who_bears_cost"): "c1_local_tradeoff_adaptation",
    ("scenario", "c1_policy_sunset_clause"): "c1_local_tradeoff_adaptation",
    ("scenario", "c1_policy_exemption_edge"): "c1_local_tradeoff_adaptation",
    # clinical → c1_participatory_access_remedy
    ("scenario", "c1_clinical_informed_consent"): "c1_participatory_access_remedy",
    ("scenario", "c1_clinical_second_opinion"): "c1_participatory_access_remedy",
    ("scenario", "c1_clinical_trial_withdrawal"): "c1_participatory_access_remedy",
    ("scenario", "c1_clinical_data_reuse"): "c1_participatory_access_remedy",
    # critique → c1_evidence_limits_conclusion
    ("scenario", "c1_critique_work_not_person"): "c1_evidence_limits_conclusion",
    ("scenario", "c1_critique_anonymous_limits"): "c1_evidence_limits_conclusion",
    ("scenario", "c1_critique_metric_gaming"): "c1_evidence_limits_conclusion",
    ("scenario", "c1_critique_public_wording"): "c1_evidence_limits_conclusion",
    # mediation → c1_accessibility_barrier_diagnosis
    ("scenario", "c1_mediation_ground_rules"): "c1_accessibility_barrier_diagnosis",
    ("scenario", "c1_mediation_restate_position"): "c1_accessibility_barrier_diagnosis",
    ("scenario", "c1_mediation_partial_agreement"): "c1_accessibility_barrier_diagnosis",
    ("scenario", "c1_mediation_walk_away_line"): "c1_accessibility_barrier_diagnosis",
    # facework → c1_risk_update_correction
    ("scenario", "c1_facework_decline_without_wound"): "c1_risk_update_correction",
    ("scenario", "c1_facework_correct_in_private"): "c1_risk_update_correction",
    ("scenario", "c1_facework_accept_correction"): "c1_risk_update_correction",
    ("scenario", "c1_facework_praise_before_others"): "c1_risk_update_correction",
    # attribution → c1_sustainable_lifecycle
    ("scenario", "c1_attribution_author_order"): "c1_sustainable_lifecycle",
    ("scenario", "c1_attribution_unpaid_translation"): "c1_sustainable_lifecycle",
    ("scenario", "c1_attribution_reuse_without_credit"): "c1_sustainable_lifecycle",
    ("scenario", "c1_attribution_collective_byline"): "c1_sustainable_lifecycle",
}

# Batch 16 (2026-08-18) — C2 확장 6칸 24편, 서재 마지막 빈 칸. Batch 15 와 같은
# 원칙으로 기존 published 세그먼트에 붙인다 (세그먼트 86 슬롯 불변).
BATCH_16_SEGMENT_ROUTES: dict[tuple[str, str], str] = {
    # ethics → c2_institutional_deliberation
    ("scenario", "c2_ethics_embargo_disclosure_window"): "c2_institutional_deliberation",
    ("scenario", "c2_ethics_consent_form_scope_gap"): "c2_institutional_deliberation",
    ("scenario", "c2_ethics_reviewer_dual_appointment_disclosure"): "c2_institutional_deliberation",
    ("scenario", "c2_ethics_misconduct_review_procedure_defined"): "c2_institutional_deliberation",
    # history → c2_interpretation_justification
    ("scenario", "c2_history_compile_committee_wording_dispute"): "c2_interpretation_justification",
    ("scenario", "c2_history_monument_inscription_agreement"): "c2_interpretation_justification",
    ("scenario", "c2_history_sealed_records_disclosure_timing"): "c2_interpretation_justification",
    ("scenario", "c2_history_merging_conflicting_testimonies"): "c2_interpretation_justification",
    # aesthetic → c2_narrative_perspective
    ("scenario", "c2_aesthetic_poem_rhythm_meaning_loss"): "c2_narrative_perspective",
    ("scenario", "c2_aesthetic_dialect_subtitle_flatten"): "c2_narrative_perspective",
    ("scenario", "c2_aesthetic_word_without_equivalent"): "c2_narrative_perspective",
    ("scenario", "c2_aesthetic_translator_editor_dispute"): "c2_narrative_perspective",
    # limitation → c2_technology_traceability_appeal
    ("scenario", "c2_limitation_notice_delay_appeal_window"): "c2_technology_traceability_appeal",
    ("scenario", "c2_limitation_extension_premise_error_proof"): "c2_technology_traceability_appeal",
    ("scenario", "c2_limitation_define_accrual_date"): "c2_technology_traceability_appeal",
    ("scenario", "c2_limitation_ex_officio_review_path"): "c2_technology_traceability_appeal",
    # jurisdiction → c2_procedural_legitimacy
    ("scenario", "c2_jurisdiction_neither_claims_authority"): "c2_procedural_legitimacy",
    ("scenario", "c2_jurisdiction_provisional_ruling_no_authority"): "c2_procedural_legitimacy",
    ("scenario", "c2_jurisdiction_cross_border_premise"): "c2_procedural_legitimacy",
    ("scenario", "c2_jurisdiction_even_if_authorized_escalate"): "c2_procedural_legitimacy",
    # representation → c2_discourse_boundary_power
    ("scenario", "c2_representation_fan_rep_mandate_defined"): "c2_discourse_boundary_power",
    ("scenario", "c2_representation_minority_view_regardless"): "c2_discourse_boundary_power",
    ("scenario", "c2_representation_press_quote_not_official"): "c2_discourse_boundary_power",
    ("scenario", "c2_representation_spokesperson_handover_concession"): "c2_discourse_boundary_power",
}

# Batch 17 (2026-08-22) — 2026 social-topic scenarios and their C1/C2
# practice families. Keep the published segment inventory fixed and route every
# promoted source to the closest existing discourse function.
BATCH_17_SEGMENT_ROUTES: dict[tuple[str, str], str] = {
    ("scenario", "c1_moving_rent_relief_roundtable"): "c1_local_tradeoff_adaptation",
    ("scenario", "c1_work_ai_hiring_pilot_review"): "c1_evidence_validity",
    ("scenario", "c1_daily_migration_demography_policy_forum"): "c1_local_tradeoff_adaptation",
    ("scenario", "c1_kpop_platform_localization_review"): "c1_sustainable_lifecycle",
    ("scenario", "c2_moving_affordability_definition_hearing"): "c2_framing_responsibility",
    ("scenario", "c2_work_ai_accountability_board"): "c2_technology_responsibility_rights",
    ("scenario", "c2_daily_integration_metric_editorial"): "c2_framing_responsibility",
    ("scenario", "c2_kpop_authenticity_platform_panel"): "c2_discourse_boundary_power",
}
for _number in range(33, 35):
    BATCH_17_SEGMENT_ROUTES[("smalltalk", f"smalltalk_c1_{_number:04d}")] = (
        "c1_local_tradeoff_adaptation"
    )
    BATCH_17_SEGMENT_ROUTES[("smalltalk", f"smalltalk_c2_{_number:04d}")] = (
        "c2_framing_responsibility"
    )
for _number in range(35, 37):
    BATCH_17_SEGMENT_ROUTES[("smalltalk", f"smalltalk_c1_{_number:04d}")] = (
        "c1_evidence_validity"
    )
    BATCH_17_SEGMENT_ROUTES[("smalltalk", f"smalltalk_c2_{_number:04d}")] = (
        "c2_technology_responsibility_rights"
    )
for _number in range(37, 39):
    BATCH_17_SEGMENT_ROUTES[("smalltalk", f"smalltalk_c1_{_number:04d}")] = (
        "c1_local_tradeoff_adaptation"
    )
    BATCH_17_SEGMENT_ROUTES[("smalltalk", f"smalltalk_c2_{_number:04d}")] = (
        "c2_framing_responsibility"
    )
for _number in range(39, 41):
    BATCH_17_SEGMENT_ROUTES[("smalltalk", f"smalltalk_c1_{_number:04d}")] = (
        "c1_sustainable_lifecycle"
    )
    BATCH_17_SEGMENT_ROUTES[("smalltalk", f"smalltalk_c2_{_number:04d}")] = (
        "c2_discourse_boundary_power"
    )
for _number in range(221, 224):
    BATCH_17_SEGMENT_ROUTES[("cloze", f"cloze_c1_{_number:04d}")] = (
        "c1_local_tradeoff_adaptation"
    )
    BATCH_17_SEGMENT_ROUTES[("cloze", f"cloze_c2_{_number:04d}")] = (
        "c2_framing_responsibility"
    )
for _number in range(224, 227):
    BATCH_17_SEGMENT_ROUTES[("cloze", f"cloze_c1_{_number:04d}")] = (
        "c1_evidence_validity"
    )
    BATCH_17_SEGMENT_ROUTES[("cloze", f"cloze_c2_{_number:04d}")] = (
        "c2_technology_responsibility_rights"
    )
for _number in range(227, 230):
    BATCH_17_SEGMENT_ROUTES[("cloze", f"cloze_c1_{_number:04d}")] = (
        "c1_local_tradeoff_adaptation"
    )
    BATCH_17_SEGMENT_ROUTES[("cloze", f"cloze_c2_{_number:04d}")] = (
        "c2_framing_responsibility"
    )
for _number in range(230, 233):
    BATCH_17_SEGMENT_ROUTES[("cloze", f"cloze_c1_{_number:04d}")] = (
        "c1_sustainable_lifecycle"
    )
    BATCH_17_SEGMENT_ROUTES[("cloze", f"cloze_c2_{_number:04d}")] = (
        "c2_discourse_boundary_power"
    )
for _number in range(223, 226):
    BATCH_17_SEGMENT_ROUTES[("satz", f"satz_c1_{_number:04d}")] = (
        "c1_local_tradeoff_adaptation"
    )
    BATCH_17_SEGMENT_ROUTES[("satz", f"satz_c2_{_number:04d}")] = (
        "c2_framing_responsibility"
    )
for _number in range(226, 229):
    BATCH_17_SEGMENT_ROUTES[("satz", f"satz_c1_{_number:04d}")] = (
        "c1_evidence_validity"
    )
    BATCH_17_SEGMENT_ROUTES[("satz", f"satz_c2_{_number:04d}")] = (
        "c2_technology_responsibility_rights"
    )
for _number in range(229, 232):
    BATCH_17_SEGMENT_ROUTES[("satz", f"satz_c1_{_number:04d}")] = (
        "c1_local_tradeoff_adaptation"
    )
    BATCH_17_SEGMENT_ROUTES[("satz", f"satz_c2_{_number:04d}")] = (
        "c2_framing_responsibility"
    )
for _number in range(232, 235):
    BATCH_17_SEGMENT_ROUTES[("satz", f"satz_c1_{_number:04d}")] = (
        "c1_sustainable_lifecycle"
    )
    BATCH_17_SEGMENT_ROUTES[("satz", f"satz_c2_{_number:04d}")] = (
        "c2_discourse_boundary_power"
    )

# Batch 18 (2026-08-22) — independent follow-up practice for the same public
# topics. These exact routes make regeneration deterministic without changing
# any historical source assignment.
BATCH_18_SEGMENT_ROUTES: dict[tuple[str, str], str] = {
    ("vocabPack", "c1_2026_social_topics_1"): "c1_local_tradeoff_adaptation",
    ("vocabPack", "c2_2026_social_topics_1"): "c2_framing_responsibility",
    ("grammar", "grammar_c1_even_accounting_for"): "c1_local_tradeoff_adaptation",
    ("grammar", "grammar_c1_while_also_consider"): "c1_evidence_validity",
    ("grammar", "grammar_c1_effect_varies_by"): "c1_local_tradeoff_adaptation",
    ("grammar", "grammar_c1_excluded_in_process"): "c1_sustainable_lifecycle",
    ("grammar", "grammar_c2_take_as_premise"): "c2_framing_responsibility",
    ("grammar", "grammar_c2_definition_by_viewpoint"): "c2_technology_responsibility_rights",
    ("grammar", "grammar_c2_responsibility_remains"): "c2_framing_responsibility",
    ("grammar", "grammar_c2_cannot_reduce_to"): "c2_discourse_boundary_power",
    ("smalltalk", "smalltalk_c1_0041"): "c1_local_tradeoff_adaptation",
    ("smalltalk", "smalltalk_c1_0042"): "c1_evidence_validity",
    ("smalltalk", "smalltalk_c1_0043"): "c1_local_tradeoff_adaptation",
    ("smalltalk", "smalltalk_c1_0044"): "c1_sustainable_lifecycle",
    ("smalltalk", "smalltalk_c2_0041"): "c2_framing_responsibility",
    ("smalltalk", "smalltalk_c2_0042"): "c2_technology_responsibility_rights",
    ("smalltalk", "smalltalk_c2_0043"): "c2_framing_responsibility",
    ("smalltalk", "smalltalk_c2_0044"): "c2_discourse_boundary_power",
}
for _number in range(233, 245):
    BATCH_18_SEGMENT_ROUTES[("cloze", f"cloze_c1_{_number:04d}")] = (
        "c1_local_tradeoff_adaptation"
    )
    BATCH_18_SEGMENT_ROUTES[("cloze", f"cloze_c2_{_number:04d}")] = (
        "c2_framing_responsibility"
    )
for _number in range(235, 247):
    BATCH_18_SEGMENT_ROUTES[("satz", f"satz_c1_{_number:04d}")] = (
        "c1_local_tradeoff_adaptation"
    )
    BATCH_18_SEGMENT_ROUTES[("satz", f"satz_c2_{_number:04d}")] = (
        "c2_framing_responsibility"
    )

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


def _humanization_changes_by_id() -> dict[str, list[dict[str, Any]]]:
    if not CONTENT_HUMANIZATION_LEDGER_PATH.exists():
        return {}
    ledger = _read_json(CONTENT_HUMANIZATION_LEDGER_PATH)
    if ledger.get("scope") != "assets/data/smalltalk.json":
        raise ValueError("content humanization ledger has an unexpected scope")
    changes_by_id: dict[str, list[dict[str, Any]]] = {}
    for change in ledger.get("changes", []):
        changes_by_id.setdefault(change["id"], []).append(change)
    return changes_by_id


def _at_nested_field(record: dict[str, Any], field_path: str) -> tuple[dict[str, Any], str]:
    current = record
    parts = field_path.split(".")
    for part in parts[:-1]:
        nested = current.get(part)
        if not isinstance(nested, dict):
            raise ValueError(f"{record.get('id')}.{field_path}: missing object {part}")
        current = nested
    return current, parts[-1]


def _copy_revision_metadata(row: dict[str, Any]) -> dict[str, Any] | None:
    changes = _humanization_changes_by_id().get(row["id"])
    if not changes:
        return None
    previous = copy.deepcopy(row)
    for change in changes:
        current_parent, current_key = _at_nested_field(row, change["field"])
        if current_parent.get(current_key) != change["after"]:
            raise ValueError(
                f"{row['id']}.{change['field']}: live copy does not match "
                "the humanization ledger"
            )
        previous_parent, previous_key = _at_nested_field(previous, change["field"])
        previous_parent[previous_key] = change["before"]
    return {
        "copyRevision": 1,
        "copyReviewStatus": "nativeReviewRequired",
        "copyRevisionLedger": CONTENT_HUMANIZATION_LEDGER_REF,
        "previousPhraseFingerprintSha256": _json_fingerprint(previous),
    }


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

# C1/C2의 공개 can-do 세그먼트 수는 고정되어 있다. 새 유닛이나 새 배치가
# 들어와도 세그먼트를 임의로 늘리지 않고, 각 코스 유닛을 가장 가까운 기존
# 담화 기능에 붙인다. 개별 승인 라우트가 있으면 _promotion_segment_key가 이
# 기본값보다 우선한다. 이 표 덕분에 새 C레벨 자산이 앱에는 실렸지만 can-do
# 근거 그래프에서는 조용히 누락되는 회귀를 막을 수 있다.
C_UNIT_DEFAULT_ROUTE: dict[str, str] = {
    "c1_01_evidence_public_reasoning": "c1_evidence_validity",
    "c1_02_inclusive_sustainable_systems": "c1_local_tradeoff_adaptation",
    "c1_03_media_evidence_literacy": "c1_evidence_limits_conclusion",
    "c1_04_play_time_policy": "c1_risk_uncertainty",
    "c1_05_fan_labor_sustainability": "c1_sustainable_lifecycle",
    "c1_06_intimacy_safety_design": "c1_participatory_access_remedy",
    "c2_01_interpretation_institutions": "c2_framing_responsibility",
    "c2_02_technology_public_ethics": "c2_technology_responsibility_rights",
    "c2_03_automation_redress": "c2_technology_traceability_appeal",
    "c2_04_sanction_accountability": "c2_technology_responsibility_rights",
    "c2_05_relationship_narratives": "c2_narrative_perspective",
    "c2_06_fandom_discourse_power": "c2_discourse_boundary_power",
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
SMALLTALK_REVIEW_APPROVALS: dict[str, dict[str, Any]] = {
    "smalltalk_b1_0053": {
        "phraseFingerprintSha256": "ecf9da40dc1ada9342d68f8aba22bd7a35c25c2ecb893d9dce7a0108ec08b70a",
        "canDoSegmentId": "segment_b1_property_damage_report",
        "canDoFingerprintSha256": "1c8db8c51f66b87febf12aef28202605ccad9e0eb9674318c86e8edad64c3f71",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b1_0054": {
        "phraseFingerprintSha256": "ed3281284913374f6176e46d9a02c2f625c8ed3527e2d5fc25b06ea6cee498ca",
        "canDoSegmentId": "segment_b1_property_damage_report",
        "canDoFingerprintSha256": "1c8db8c51f66b87febf12aef28202605ccad9e0eb9674318c86e8edad64c3f71",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b2_0081": {
        "phraseFingerprintSha256": "2c7f653b5bfabbd8ce9c94b5038d24dc7a78b5d277c169d3952f56e9943be800",
        "canDoSegmentId": "segment_b2_remedy_and_appeal",
        "canDoFingerprintSha256": "1da75e8a44e4c0de82a4a149e1b9d1892d5ea966c4768c234dc52e37bf39b20e",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b2_0082": {
        "phraseFingerprintSha256": "e27dc5bacde1ca5418de701e3152b54490e0d7c7f09db2cc49cab6e9281d8575",
        "canDoSegmentId": "segment_b2_remedy_and_appeal",
        "canDoFingerprintSha256": "1da75e8a44e4c0de82a4a149e1b9d1892d5ea966c4768c234dc52e37bf39b20e",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    'smalltalk_a1_0065': {
        "phraseFingerprintSha256": '5f28c52d3bd1da681a77ad5f1c31992457551ffd414419c08c59f6e6f0250e3e',
        "canDoSegmentId": 'segment_a1_11_titles_relationships',
        "canDoFingerprintSha256": 'f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a1_0066': {
        "phraseFingerprintSha256": '2943ba5a22c4e16203547c402e9ccf35c13a8e35a38325b6a84de6a90d1de496',
        "canDoSegmentId": 'segment_a1_11_titles_relationships',
        "canDoFingerprintSha256": 'f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a1_0067': {
        "phraseFingerprintSha256": '68cf68c617358c6901083f396e04f841f26f809d3bc002c6dedccd6a842df974',
        "canDoSegmentId": 'segment_a1_11_titles_relationships',
        "canDoFingerprintSha256": 'f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a1_0068': {
        "phraseFingerprintSha256": '1ae6aa274c3d18ee10fec4f1c62b5f154577f730a5ee53d4851c1e3b5b36a7cd',
        "canDoSegmentId": 'segment_a1_11_titles_relationships',
        "canDoFingerprintSha256": 'f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a1_0069': {
        "phraseFingerprintSha256": 'b8bf62e1618417aa9241458ada4033e8583bc34d21b50e3c91a997ef7da76587',
        "canDoSegmentId": 'segment_a1_11_titles_relationships',
        "canDoFingerprintSha256": 'f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a1_0070': {
        "phraseFingerprintSha256": '4bb24e889a6c85ec6eb98fffa7dd58d0915a37d14dd3c762a204c2f639767f78',
        "canDoSegmentId": 'segment_a1_11_titles_relationships',
        "canDoFingerprintSha256": 'f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a1_0071': {
        "phraseFingerprintSha256": '5d82a8db430194a8511492ef5287d2b1cbba39062cbc3f8d562a2e29eb5b88d6',
        "canDoSegmentId": 'segment_a1_11_titles_relationships',
        "canDoFingerprintSha256": 'f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a1_0072': {
        "phraseFingerprintSha256": '56096bc1a1bf488d6ae16b5d64559788893d1d5ddf67e154075734256ca291c0',
        "canDoSegmentId": 'segment_a1_11_titles_relationships',
        "canDoFingerprintSha256": 'f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a1_0073': {
        "phraseFingerprintSha256": 'bbbaf0a899d059202edbfa69353b957a393365cf69ca8ec9b355d7dad0614e36',
        "canDoSegmentId": 'segment_a1_11_titles_relationships',
        "canDoFingerprintSha256": 'f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a1_0074': {
        "phraseFingerprintSha256": 'aa37ea1e4b3ffc06cd39d0aeb94b29756469196827cc73a049d1d5aaa02974bc',
        "canDoSegmentId": 'segment_a1_11_titles_relationships',
        "canDoFingerprintSha256": 'f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a1_0075': {
        "phraseFingerprintSha256": 'e76087d22c9d74d65f1e2b317dd6528c22fc09784c77f2313af2c70105c957dd',
        "canDoSegmentId": 'segment_a1_11_titles_relationships',
        "canDoFingerprintSha256": 'f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a1_0076': {
        "phraseFingerprintSha256": 'b4fcdd8751af3e5f98982b7fe04006f2f61f0d255873813f00de240b7bb0ce56',
        "canDoSegmentId": 'segment_a1_11_titles_relationships',
        "canDoFingerprintSha256": 'f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a1_0077': {
        "phraseFingerprintSha256": 'd09127af7c7c3fab10d529b0868b06f21967a01a08438de9e959d016d9d260b1',
        "canDoSegmentId": 'segment_a1_11_titles_relationships',
        "canDoFingerprintSha256": 'f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a1_0078': {
        "phraseFingerprintSha256": '07251bfa2463b9815c302d75fd3d75eaa0b32710708cc5574cda530054ad52e3',
        "canDoSegmentId": 'segment_a1_11_titles_relationships',
        "canDoFingerprintSha256": 'f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a1_0079': {
        "phraseFingerprintSha256": '5e9d6b22de23daa74ade9f74daead3984175fc3c173ac1f76c6f3b6da4650eec',
        "canDoSegmentId": 'segment_a1_11_titles_relationships',
        "canDoFingerprintSha256": 'f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a1_0080': {
        "phraseFingerprintSha256": '6283274fcfb9b27859f62217a3122583d5125da3153f8a0dce2c5155017a4298',
        "canDoSegmentId": 'segment_a1_11_titles_relationships',
        "canDoFingerprintSha256": 'f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a2_0058': {
        "phraseFingerprintSha256": '77ad168ef73886297c66e6b0e76e92ba869f9c8bd45c7352c0bc0b91edd1df79',
        "canDoSegmentId": 'segment_a2_running_late',
        "canDoFingerprintSha256": 'fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a2_0059': {
        "phraseFingerprintSha256": 'cbcd214df4f40c327fc7b1e6e7fe64a493638b300dd5fbeb0037f29ea6801ff4',
        "canDoSegmentId": 'segment_a2_running_late',
        "canDoFingerprintSha256": 'fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a2_0060': {
        "phraseFingerprintSha256": 'fc80d41205da48f1db1b17a2be3cd0885f7c5f90b0783fe0fbeb5c88b4d2b4f8',
        "canDoSegmentId": 'segment_a2_running_late',
        "canDoFingerprintSha256": 'fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a2_0061': {
        "phraseFingerprintSha256": '3b2a02b5e508b7f599f4bc277a7b4263d8bf672e9a03c7b2b1a3acc035fe9795',
        "canDoSegmentId": 'segment_a2_running_late',
        "canDoFingerprintSha256": 'fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a2_0062': {
        "phraseFingerprintSha256": 'd5e8e61399b5d3b5eda941c56ccff8a7af7f890023065d34d769e497933b9cff',
        "canDoSegmentId": 'segment_a2_running_late',
        "canDoFingerprintSha256": 'fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a2_0063': {
        "phraseFingerprintSha256": '85b3f05c829727ce9e4293b5669fe10f73dc8db557e7c649f246db8611d28dc2',
        "canDoSegmentId": 'segment_a2_running_late',
        "canDoFingerprintSha256": 'fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a2_0064': {
        "phraseFingerprintSha256": 'b835e8d835c375cf023fb4d70823fbccf1ab41134d1b75e67f7e0ca508883519',
        "canDoSegmentId": 'segment_a2_running_late',
        "canDoFingerprintSha256": 'fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a2_0065': {
        "phraseFingerprintSha256": '4e8ac453afa50fa2ab2b9994a0f06e150998795aad388e94854d915ad7b23948',
        "canDoSegmentId": 'segment_a2_running_late',
        "canDoFingerprintSha256": 'fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a2_0066': {
        "phraseFingerprintSha256": 'eb9491cafc31ef5766b412d1ee39ae296b758bc3666070d2bb86f228d6985d70',
        "canDoSegmentId": 'segment_a2_running_late',
        "canDoFingerprintSha256": 'fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a2_0067': {
        "phraseFingerprintSha256": 'e17a16c91ec0cf61acab06a2f598979c9ce04f389470ff5b1ba7769aae720f47',
        "canDoSegmentId": 'segment_a2_running_late',
        "canDoFingerprintSha256": 'fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a2_0068': {
        "phraseFingerprintSha256": 'c842410a36208ced07c63e2de38e926c2ec63cb96c9d358b5745dff897118abf',
        "canDoSegmentId": 'segment_a2_running_late',
        "canDoFingerprintSha256": 'fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a2_0069': {
        "phraseFingerprintSha256": 'c168ce2920a04dc081325efeaa57e859ba0e1c264d62d4b5d0549cbf4e535d3e',
        "canDoSegmentId": 'segment_a2_running_late',
        "canDoFingerprintSha256": 'fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a2_0070': {
        "phraseFingerprintSha256": '1ad99bac2fcdbb0fcfb945bdf3a9e02658bc5176865d1e21a7ceeecd9fb10546',
        "canDoSegmentId": 'segment_a2_running_late',
        "canDoFingerprintSha256": 'fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a2_0071': {
        "phraseFingerprintSha256": 'aad3be4e2d162ad8efcb92e7d70720c0f00c29e48a39b8ddbe214ae5172dc9b3',
        "canDoSegmentId": 'segment_a2_running_late',
        "canDoFingerprintSha256": 'fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a2_0072': {
        "phraseFingerprintSha256": '9e06834b9907fbe1ecb3e726bca21af18b752f79e7e539b86c556b913b1f15d1',
        "canDoSegmentId": 'segment_a2_running_late',
        "canDoFingerprintSha256": 'fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_a2_0073': {
        "phraseFingerprintSha256": '7a874861240db7f0c301964f334a8e48a4ae64c30154880b7522195417a14f85',
        "canDoSegmentId": 'segment_a2_running_late',
        "canDoFingerprintSha256": 'fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b1_0055': {
        "phraseFingerprintSha256": 'bda3da2a4702adca217474ac505c676ef4a49b799f7237ed8eae487c0d7e51f7',
        "canDoSegmentId": 'segment_b1_intimate_feelings',
        "canDoFingerprintSha256": '6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b1_0056': {
        "phraseFingerprintSha256": '9dca3536ab0a9d052f6f23682820d9f4795720ac73e1e4c1176ee409d53977bf',
        "canDoSegmentId": 'segment_b1_intimate_feelings',
        "canDoFingerprintSha256": '6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b1_0057': {
        "phraseFingerprintSha256": 'e8df150a7ada11a78c0181c6e5b900263e0d369d3ca6ff1cff0718da62781a03',
        "canDoSegmentId": 'segment_b1_intimate_feelings',
        "canDoFingerprintSha256": '6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b1_0058': {
        "phraseFingerprintSha256": 'c9e5fd28646a107235d47257d43e2bb94c6c2fc2d49f59abc91b7c5a0c1289b3',
        "canDoSegmentId": 'segment_b1_intimate_feelings',
        "canDoFingerprintSha256": '6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b1_0059': {
        "phraseFingerprintSha256": 'bcd7d4baddeb667ec4aaf0e4b88e54f6567bbd4cad324ddf221197bfa6db5b1f',
        "canDoSegmentId": 'segment_b1_intimate_feelings',
        "canDoFingerprintSha256": '6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b1_0060': {
        "phraseFingerprintSha256": '6998c169c346495ea5b6008ac2a0ab81cfea4013b0cef65fdfd225bce9c88b92',
        "canDoSegmentId": 'segment_b1_intimate_feelings',
        "canDoFingerprintSha256": '6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b1_0061': {
        "phraseFingerprintSha256": 'b72a6dce32e13262dc233443b40d995556dfe9651b4bc1c7d410784ff7e016bb',
        "canDoSegmentId": 'segment_b1_intimate_feelings',
        "canDoFingerprintSha256": '6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b1_0062': {
        "phraseFingerprintSha256": '3941747fd82c88b319a965df12d508bc967bf5108a13582e825f7f1ed55d4a9b',
        "canDoSegmentId": 'segment_b1_intimate_feelings',
        "canDoFingerprintSha256": '6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b1_0063': {
        "phraseFingerprintSha256": 'eac369d404f902ba4750b61e0f77ca9f5ae0049291c4926eda5ab422f60e32ce',
        "canDoSegmentId": 'segment_b1_intimate_feelings',
        "canDoFingerprintSha256": '6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b1_0064': {
        "phraseFingerprintSha256": '762fe5611e60b86ed67515bc1d29896000b3f68c49ef50ac86d3aece7ad69c38',
        "canDoSegmentId": 'segment_b1_intimate_feelings',
        "canDoFingerprintSha256": '6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b1_0065': {
        "phraseFingerprintSha256": 'f0256ba1e529f8d47f0f61a9dfd11986edf4bef65fc7c0a1e8875f628763dfab',
        "canDoSegmentId": 'segment_b1_intimate_feelings',
        "canDoFingerprintSha256": '6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b1_0066': {
        "phraseFingerprintSha256": '9813e919d49707f1ebbea4568f784f3136309a0db7596ac94267c45e519cbedc',
        "canDoSegmentId": 'segment_b1_intimate_feelings',
        "canDoFingerprintSha256": '6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b1_0067': {
        "phraseFingerprintSha256": '67c727b68c0a50995e2b8fd8cbbf8247b4ef0dfee789773d21f4924a6c2f38f5',
        "canDoSegmentId": 'segment_b1_intimate_feelings',
        "canDoFingerprintSha256": '6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b1_0068': {
        "phraseFingerprintSha256": 'f9b8800d62a6d4bf7aad7657a464051171348c8217f2a7a70d08c545702cf74a',
        "canDoSegmentId": 'segment_b1_intimate_feelings',
        "canDoFingerprintSha256": '6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b1_0069': {
        "phraseFingerprintSha256": '443fa17b7d7c1df268fcd226ffd0abea0a69d516545fa5c835cd53eb071cbf88',
        "canDoSegmentId": 'segment_b1_intimate_feelings',
        "canDoFingerprintSha256": '6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b1_0070': {
        "phraseFingerprintSha256": '99a2de3887ae48f08df7c7005b1ea3d27509a65539f7cf43a766a8c3aedaa1ed',
        "canDoSegmentId": 'segment_b1_intimate_feelings',
        "canDoFingerprintSha256": '6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b2_0083': {
        "phraseFingerprintSha256": '4a5367f024f94cd70a11da39583717d56c10d22f5a1d5fa003347ddf98c273aa',
        "canDoSegmentId": 'segment_b2_formal_soft_reformulation',
        "canDoFingerprintSha256": '9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b2_0084': {
        "phraseFingerprintSha256": 'fc47f99e16d6fc13d0711a9595a96a1c5c5bce85d65ff0ec173f0e6c8f0dbb60',
        "canDoSegmentId": 'segment_b2_formal_soft_reformulation',
        "canDoFingerprintSha256": '9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b2_0085': {
        "phraseFingerprintSha256": '19b69823990b7a0044cd61047533965d6a268d3ab55e8ed5afe75e36e8db7e70',
        "canDoSegmentId": 'segment_b2_formal_soft_reformulation',
        "canDoFingerprintSha256": '9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b2_0086': {
        "phraseFingerprintSha256": '600007533f05407cbf0110234673770da2d3943ac8c4acd56a7728526723e801',
        "canDoSegmentId": 'segment_b2_formal_soft_reformulation',
        "canDoFingerprintSha256": '9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b2_0087': {
        "phraseFingerprintSha256": '11dac0874d717cab03812ce410798182d86949421cbee8832d5fd2c0e1077ba8',
        "canDoSegmentId": 'segment_b2_formal_soft_reformulation',
        "canDoFingerprintSha256": '9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b2_0088': {
        "phraseFingerprintSha256": '1d76f14c34b852334ddfbf2e76df338783295d95b5ef7fbd79dcf6511234ebff',
        "canDoSegmentId": 'segment_b2_formal_soft_reformulation',
        "canDoFingerprintSha256": '9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b2_0089': {
        "phraseFingerprintSha256": 'ed20aca443d5a27956066e658ea290caeebcf06c8d23183a7b603216ad586230',
        "canDoSegmentId": 'segment_b2_formal_soft_reformulation',
        "canDoFingerprintSha256": '9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b2_0090': {
        "phraseFingerprintSha256": 'd62e8b4cd748208e44a9770d5e484b6a5b27faf07ee037efa6f7cb101a28f0ef',
        "canDoSegmentId": 'segment_b2_formal_soft_reformulation',
        "canDoFingerprintSha256": '9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b2_0091': {
        "phraseFingerprintSha256": 'c55373abaa580631f1840c0cb65baecd8de0941966b8fdebfae46b93a65f6fd0',
        "canDoSegmentId": 'segment_b2_formal_soft_reformulation',
        "canDoFingerprintSha256": '9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b2_0092': {
        "phraseFingerprintSha256": '3b00ce29c6b0d0a2aee50821ecb68fe60e6a0590ca9f23c591d0ff3ef69488b5',
        "canDoSegmentId": 'segment_b2_formal_soft_reformulation',
        "canDoFingerprintSha256": '9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b2_0093': {
        "phraseFingerprintSha256": 'f1e08c8acd4109adcb039a312c748e0ff0cd41a249eb8db9dcb684abc481de2b',
        "canDoSegmentId": 'segment_b2_formal_soft_reformulation',
        "canDoFingerprintSha256": '9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b2_0094': {
        "phraseFingerprintSha256": '9c31631062fdbcc955a6429d98449c204df5aabc5ac02a99e32654b44b72e381',
        "canDoSegmentId": 'segment_b2_formal_soft_reformulation',
        "canDoFingerprintSha256": '9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b2_0095': {
        "phraseFingerprintSha256": 'ae9d1784cdefddc9833eeae78ed3e9f97f6981214ab9ebc8df1c87da96d81d16',
        "canDoSegmentId": 'segment_b2_formal_soft_reformulation',
        "canDoFingerprintSha256": '9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b2_0096': {
        "phraseFingerprintSha256": '3401255296249fc45a40620f8a694cf78de225d35b4f189bd5ecf12038c803dc',
        "canDoSegmentId": 'segment_b2_formal_soft_reformulation',
        "canDoFingerprintSha256": '9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b2_0097': {
        "phraseFingerprintSha256": 'd9e65172e9aa6ea6151f55af1b2289897310988f6ec88bbe35b9563456514987',
        "canDoSegmentId": 'segment_b2_formal_soft_reformulation',
        "canDoFingerprintSha256": '9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    'smalltalk_b2_0098': {
        "phraseFingerprintSha256": '6ba0eab353263f2fec214d02f81d03da93693fae048f6ce3b49ef3120a8b90ba',
        "canDoSegmentId": 'segment_b2_formal_soft_reformulation',
        "canDoFingerprintSha256": '9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945',
        "semanticStatus": "approved",
        "reviewRevision": 2,
    },
    "smalltalk_a1_0081": {
        "phraseFingerprintSha256": "6210610af78fe92b870c3e75443e9c5a72d685eaa55797eb0d893c5c2537a516",
        "canDoSegmentId": "segment_a1_12_daily_negation",
        "canDoFingerprintSha256": "08a3b9fbaeb286dec20cb306a59f28ac2794d44462b721f560d063ebb0dbd833",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_a1_0082": {
        "phraseFingerprintSha256": "c544d93960617e4d7311e28e556ab77aa8f62f144d89680cb9d78f109edf58d3",
        "canDoSegmentId": "segment_a1_04_order_request_object",
        "canDoFingerprintSha256": "a3b28672591b1c66a7c32e25f26363cd118a7340d59ddc88a5fe40a40408806f",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_a2_0074": {
        "phraseFingerprintSha256": "b3de808e994ff2436088c3ae6cb7a5e988e43d06a77b59f4e17256d4be0048d1",
        "canDoSegmentId": "segment_a2_running_late",
        "canDoFingerprintSha256": "fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_a2_0075": {
        "phraseFingerprintSha256": "73c27bd3105e8da5f9a3a0828aecd6095d7df6f93288432fa4b4df46a4da1219",
        "canDoSegmentId": "segment_a2_feeling_sick",
        "canDoFingerprintSha256": "9cdbbb15c11ba3c7e755a2d8073b0ecd702f0a1fdcf9e72d29ec0b32a6b4a421",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b1_0071": {
        "phraseFingerprintSha256": "2822c744ccb233b933afb8b71f421319e5593f1e90b327496fd58ccffb4ca375",
        "canDoSegmentId": "segment_b1_team_role_coordination",
        "canDoFingerprintSha256": "204c1167f432f8c59ac93c44c99bb1caee6adb27e735597f716f8a451e853eef",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b1_0072": {
        "phraseFingerprintSha256": "38f407574f4afc1426c4818777fc3c28abdc5b70a158ab67ecdf2ee230b7aaba",
        "canDoSegmentId": "segment_b1_plans_with_reasons",
        "canDoFingerprintSha256": "8b6f3c54bbfa65df74613a6a478c222e2f32a2603fb4d8acf4547a6a79443c44",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b2_0099": {
        "phraseFingerprintSha256": "2d11ae068efebbe51eac02e76c2ab336259ec30467d1d50c564d25098fe46504",
        "canDoSegmentId": "segment_b2_interview_experience",
        "canDoFingerprintSha256": "1b445adc7abafd5b53eb64b460f014e1fa7d76995e947a26a367accf958adeed",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b2_0100": {
        "phraseFingerprintSha256": "8dc8c5191e3c2bfa272ceb0459c39ab934d1ba303f83a3ddeb63efe89fc40bda",
        "canDoSegmentId": "segment_b2_formal_meeting_opening",
        "canDoFingerprintSha256": "b417e1d6ef394b21a40debf5ba9964ffd31fc3a2698733a8a6fe9258c5721fda",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_a1_0083": {
        "phraseFingerprintSha256": "b2c01466b0c489dd274cb494eb8bee136c757aa738321f2490a01ea2fe5bff5f",
        "canDoSegmentId": "segment_a1_14_payment_delivery",
        "canDoFingerprintSha256": "444b749979cee85ecd385741adb78ec584ff7265df9f49f472e625f8832ebd1d",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_a1_0084": {
        "phraseFingerprintSha256": "7e0f1d7b0fd71b43221ccbec8d40cbcfe67438db5435fbc8f32ad0648a49092f",
        "canDoSegmentId": "segment_a1_14_payment_delivery",
        "canDoFingerprintSha256": "444b749979cee85ecd385741adb78ec584ff7265df9f49f472e625f8832ebd1d",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_a2_0076": {
        "phraseFingerprintSha256": "64f181f5b51375b05ba0384497c8a2cadc0a3a78b6a95ae7dfa5849b984bb629",
        "canDoSegmentId": "segment_a2_plans_with_friend",
        "canDoFingerprintSha256": "c4e7ff185459644e7e79a65868a2ebaa49a507edbd439f361fbbb29f7fe57b2f",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_a2_0077": {
        "phraseFingerprintSha256": "f71aa47c63ef2fad2090527b24ff16021ef8f4476698cb4b9545644b9d1d930c",
        "canDoSegmentId": "segment_a2_plans_with_friend",
        "canDoFingerprintSha256": "c4e7ff185459644e7e79a65868a2ebaa49a507edbd439f361fbbb29f7fe57b2f",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b2_0101": {
        "phraseFingerprintSha256": "d7cff1b0e3876aba1c100630df7e1aba50c301ac7d59c524032eecef86133a57",
        "canDoSegmentId": "segment_b2_contract_scope",
        "canDoFingerprintSha256": "1ce4a30a3a7f78b39517e0bcc2b3402f136a8b9e4aa399d45bd294366f32d41a",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b2_0102": {
        "phraseFingerprintSha256": "c6ef28052bd4d9ec4c3ba4707968b459230a3e58e2bf0b4379e35d97c4b04c59",
        "canDoSegmentId": "segment_b2_contract_scope",
        "canDoFingerprintSha256": "1ce4a30a3a7f78b39517e0bcc2b3402f136a8b9e4aa399d45bd294366f32d41a",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b2_0103": {
        "phraseFingerprintSha256": "1c1e89bd3d29921f95cd296137b8953c7de58fb0d61bf1d19cb2c4aef7b8120e",
        "canDoSegmentId": "segment_b2_interview_experience",
        "canDoFingerprintSha256": "1b445adc7abafd5b53eb64b460f014e1fa7d76995e947a26a367accf958adeed",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b2_0104": {
        "phraseFingerprintSha256": "2ba99f66d948a37986e908ff6727ff6d9e8212b18a037d8b426563dc3abe32cf",
        "canDoSegmentId": "segment_b2_interview_experience",
        "canDoFingerprintSha256": "1b445adc7abafd5b53eb64b460f014e1fa7d76995e947a26a367accf958adeed",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b2_0105": {
        "phraseFingerprintSha256": "43500ab946a3aa94fdcc35d262a3286eed3b97eaeca0075c6186726c1402f002",
        "canDoSegmentId": "segment_b2_decision_criteria",
        "canDoFingerprintSha256": "86afe34cfdfb33dc3326ee0a7dc3c2df278c5b7207c71832340cdf78d9bef93e",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b2_0106": {
        "phraseFingerprintSha256": "b4dda2b730f6be73d1defb1fc85e95d8833f58c0a4d29db5829671fb873f948e",
        "canDoSegmentId": "segment_b2_decision_criteria",
        "canDoFingerprintSha256": "86afe34cfdfb33dc3326ee0a7dc3c2df278c5b7207c71832340cdf78d9bef93e",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b2_0107": {
        "phraseFingerprintSha256": "b6277688bfc2e02aeaf44f47bf0e19f4ac6c4df683ca1408441fae52877d08ef",
        "canDoSegmentId": "segment_b2_decision_criteria",
        "canDoFingerprintSha256": "86afe34cfdfb33dc3326ee0a7dc3c2df278c5b7207c71832340cdf78d9bef93e",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b2_0108": {
        "phraseFingerprintSha256": "1bfe05e8bccc51543fd40ff97b081db9988da3bd0350002499c76c3fd46e47bc",
        "canDoSegmentId": "segment_b2_decision_criteria",
        "canDoFingerprintSha256": "86afe34cfdfb33dc3326ee0a7dc3c2df278c5b7207c71832340cdf78d9bef93e",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b2_0109": {
        "phraseFingerprintSha256": "20a771141e4cce40c28561b691a8afef29059cd02deaa6d63818e1fab95efa16",
        "canDoSegmentId": "segment_b2_formal_soft_reformulation",
        "canDoFingerprintSha256": "9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b2_0110": {
        "phraseFingerprintSha256": "274f419e2adebf86c9cf1d5b7de0891e0bcbb9eea6e31cea98634fd3a9fe2004",
        "canDoSegmentId": "segment_b2_interview_experience",
        "canDoFingerprintSha256": "1b445adc7abafd5b53eb64b460f014e1fa7d76995e947a26a367accf958adeed",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b2_0111": {
        "phraseFingerprintSha256": "717c44469ee115b5d5ff8dc28b83e5301a46926e9fc6b3ad6c5694e346a8bd7e",
        "canDoSegmentId": "segment_b2_decision_criteria",
        "canDoFingerprintSha256": "86afe34cfdfb33dc3326ee0a7dc3c2df278c5b7207c71832340cdf78d9bef93e",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
    "smalltalk_b2_0112": {
        "phraseFingerprintSha256": "d7c9dcfe0fb81ace2924b3c4d590b68e1dd9564f31aadda04a8b0d13f1416c2b",
        "canDoSegmentId": "segment_b2_decision_criteria",
        "canDoFingerprintSha256": "86afe34cfdfb33dc3326ee0a7dc3c2df278c5b7207c71832340cdf78d9bef93e",
        "semanticStatus": "approved",
        "reviewRevision": 1,
    },
}

# Batch 20 route approvals are limited to semantic Can-do placement. Jin's
# integration approval authorizes publication, while independent native-copy
# review remains a separate, explicitly open gate in the batch manifest.
_BATCH20_SMALLTALK_ROUTE_APPROVALS = (
    ("smalltalk_a1_0085", "cf974cd2f2b6d732b885e5dd13d0b576c5bb2bec192be08cfabc23410d2aca1a", "segment_a1_06_transport_directions", "84cbe41abdd552c6e1ceb7c6d0dfae71827fba37798e9056e8e3a4b71ed2d7af"),
    ("smalltalk_a1_0086", "17e10fcfca224198cae0189c1c611e81a8716f4f40d298c2d5d2bc645de97e7e", "segment_a1_10_health_safety", "dc0080c4052c51617e5a2a23b7fe0e44b4738bf557a0ea439c9a56a2a561daef"),
    ("smalltalk_a1_0087", "be5c098564b6d10b4842462f37db8bd86ff0b5d7d04509dd683b316ff5a8affa", "segment_a1_06_transport_directions", "84cbe41abdd552c6e1ceb7c6d0dfae71827fba37798e9056e8e3a4b71ed2d7af"),
    ("smalltalk_a1_0088", "f99f21b30a114883b1dcb53ddf908ce2d0684e4990f34c141622de0f2fab9688", "segment_a1_05_numbers_time", "df13f9abc50cada9e113e9b9df07596b8bb579d556caca87ceef7ce4174c1f6f"),
    ("smalltalk_a1_0089", "578acf2f8cc4684af0d05e5865bade5cb2abbeefaf9f2da372a94abf0e52ba1a", "segment_a1_04_order_request_object", "a3b28672591b1c66a7c32e25f26363cd118a7340d59ddc88a5fe40a40408806f"),
    ("smalltalk_a1_0090", "e0ec98c677d90ca5bfeb53226621f951f02f3a255ae347736f8cd10d80be4cb3", "segment_a1_12_daily_negation", "08a3b9fbaeb286dec20cb306a59f28ac2794d44462b721f560d063ebb0dbd833"),
    ("smalltalk_a2_0078", "75b5aec219c07c1c64c2d01e5adf3c2a708c5409f323853f0eb49772dd7f62cb", "segment_a2_rent_bank_transfer", "bd096360bf10272f4ad7bba9da36bf9418a72652ae21d64c0c86aebe07cb9e69"),
    ("smalltalk_a2_0079", "a6fa27d5870ff1c4999fb2371d51750a7981648de740a787e9f795c9bfb2fb47", "segment_a2_rent_bank_transfer", "bd096360bf10272f4ad7bba9da36bf9418a72652ae21d64c0c86aebe07cb9e69"),
    ("smalltalk_a2_0080", "c5f20249ab6a9213c28e0ca188b415809eef0c861ba89097846188fc54dcfe9e", "segment_a2_rent_bank_transfer", "bd096360bf10272f4ad7bba9da36bf9418a72652ae21d64c0c86aebe07cb9e69"),
    ("smalltalk_a2_0081", "e8525f906dd6610ca98877fa0256920a7bd6ae086e8004c011533418661be8bf", "segment_a2_rent_bank_transfer", "bd096360bf10272f4ad7bba9da36bf9418a72652ae21d64c0c86aebe07cb9e69"),
    ("smalltalk_a2_0082", "b51af6c8ae1aa660a600f1c8fc318ef1ba51696994d2e42ed0f9900bafa0c2d5", "segment_a2_rent_bank_transfer", "bd096360bf10272f4ad7bba9da36bf9418a72652ae21d64c0c86aebe07cb9e69"),
    ("smalltalk_a2_0083", "7b540833d55b3c63412405759fb39b12fbba9fe55d79633d4be58a0288157d5c", "segment_a2_rent_bank_transfer", "bd096360bf10272f4ad7bba9da36bf9418a72652ae21d64c0c86aebe07cb9e69"),
    ("smalltalk_b1_0073", "059f7baf79d87307fca40b342d7b7b1d73196d024a708f05bbc7ee8ffe1b64d2", "segment_b1_team_role_coordination", "204c1167f432f8c59ac93c44c99bb1caee6adb27e735597f716f8a451e853eef"),
    ("smalltalk_b1_0074", "1863b0544bc45c0a2ff4b8ee82704749e36802bd65f7c6947a56a2ec21f4cabf", "segment_b1_team_role_coordination", "204c1167f432f8c59ac93c44c99bb1caee6adb27e735597f716f8a451e853eef"),
    ("smalltalk_b1_0075", "d6f81fd25530afb5879949aa879ae8c13bc2d7e07c71c9917f30abe261e1bc0a", "segment_b1_team_role_coordination", "204c1167f432f8c59ac93c44c99bb1caee6adb27e735597f716f8a451e853eef"),
    ("smalltalk_b1_0076", "da7465c2af96ca27c28f5be9ef1de2520f5e2a3b7fa46ca24deb7e4bcf1abf0a", "segment_b1_team_role_coordination", "204c1167f432f8c59ac93c44c99bb1caee6adb27e735597f716f8a451e853eef"),
    ("smalltalk_b1_0077", "2da6ddd1dc89d5b817a36adb6779e93a766ec98553ebebbfad4f39b473bd870f", "segment_b1_team_role_coordination", "204c1167f432f8c59ac93c44c99bb1caee6adb27e735597f716f8a451e853eef"),
    ("smalltalk_b1_0078", "dcb5641473e107c86516cad605c1060d9be8ac22c37b8131986d2ec02ffc19bb", "segment_b1_team_role_coordination", "204c1167f432f8c59ac93c44c99bb1caee6adb27e735597f716f8a451e853eef"),
    ("smalltalk_b2_0113", "30d99981bea80abbb20e62a9a5791174a961ab4645be32388b2625aa4960c330", "segment_b2_formal_soft_reformulation", "9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945"),
    ("smalltalk_b2_0114", "202021b955a031c8a26b79254783a0dd0cfdd4cf536271a70cea16216bfc9132", "segment_b2_decision_criteria", "86afe34cfdfb33dc3326ee0a7dc3c2df278c5b7207c71832340cdf78d9bef93e"),
    ("smalltalk_b2_0115", "525b5c363c2f1a29b0c75c6ecf9814c07967bcebc9168b99ec8dc149a5fbd268", "segment_b2_formal_soft_reformulation", "9bcd683d7f248cd6a1b627e5558bf83b7e24faf804ea1306cd8bd0f6ad611945"),
    ("smalltalk_b2_0116", "17b404a17d188de74e3b04cc5c46b8136ac2bd2d659cbabdee0505df69f0fc65", "segment_b2_interview_experience", "1b445adc7abafd5b53eb64b460f014e1fa7d76995e947a26a367accf958adeed"),
    ("smalltalk_b2_0117", "4ff0b1151de820ce984152f5f2bd9fcbe22a04111a6a1599355cdfaac27e6918", "segment_b2_decision_criteria", "86afe34cfdfb33dc3326ee0a7dc3c2df278c5b7207c71832340cdf78d9bef93e"),
    ("smalltalk_b2_0118", "058783e1fb34ac8701ad29557dfb0bf508fa192977eb5565afd9fce547f0b986", "segment_b2_decision_criteria", "86afe34cfdfb33dc3326ee0a7dc3c2df278c5b7207c71832340cdf78d9bef93e"),
)
SMALLTALK_REVIEW_APPROVALS.update(
    {
        phrase_id: {
            "phraseFingerprintSha256": phrase_fingerprint,
            "canDoSegmentId": segment_id,
            "canDoFingerprintSha256": segment_fingerprint,
            "semanticStatus": "approved",
            "reviewRevision": 1,
        }
        for phrase_id, phrase_fingerprint, segment_id, segment_fingerprint
        in _BATCH20_SMALLTALK_ROUTE_APPROVALS
    }
)


SMALLTALK_CATEGORY_ROUTES: dict[tuple[str, str], str] = {
    ("a1", "partner_family"): "a1_11_titles_relationships",
    ("a2", "partner_family"): "a2_running_late",
    ("b1", "partner_family"): "b1_intimate_feelings",
    ("b2", "partner_family"): "b2_formal_soft_reformulation",
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
        published_catalog = _read_json(DATA / "can_do_segments.json")
        self.published_content_routes: dict[tuple[str, str], str] = {}
        for cluster in published_catalog.get("contentClusters", []):
            match = re.fullmatch(r"cluster_(.+)_v\d+", str(cluster.get("id", "")))
            if match is None:
                continue
            target = match.group(1)
            for reference in cluster.get("contentReferences", []):
                kind = reference.get("kind")
                content_id = reference.get("id")
                if isinstance(kind, str) and isinstance(content_id, str):
                    self.published_content_routes[(kind, content_id)] = target
        published_authorities = _read_json(DATA / "can_do_content_authorities.json")
        published_decisions = (
            published_authorities.get("coverage", {})
            .get("smalltalkRoutingAudit", {})
            .get("phraseDecisions", [])
        )
        self.published_smalltalk_routes = {
            row["phraseId"]: {
                "target": row["canDoSegmentId"].removeprefix("segment_"),
                "routingSource": row.get("routingSource", "courseUnitFallback"),
            }
            for row in published_decisions
            if isinstance(row, dict)
            and isinstance(row.get("phraseId"), str)
            and isinstance(row.get("canDoSegmentId"), str)
        }
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
        scenario_root = scenario_store.load_root(DATA)
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
            if (
                _promotion_segment_key("scenario", reference.id) is not None
                or (reference.kind, reference.id) in self.published_content_routes
                or (
                    actual_level in ("c1", "c2")
                    and row["courseUnitId"] in C_UNIT_DEFAULT_ROUTE
                )
            ):
                # 라우팅된 시나리오는 자기 코스 유닛이 아니라 붙기로 한 세그먼트를
                # 따른다.  Batch 12 가 만든 신규 유닛(c1_03~c1_06 등)에는 세그먼트가
                # 없고, 모듈 첫머리의 교리대로 세그먼트를 새로 만들지도 않기 때문에
                # 이 우회가 없으면 그 유닛의 시나리오는 어디에도 붙지 못한다.
                # cloze·satz·grammar·vocabPack 에는 이미 있던 우회다.
                actual_parent = expected_parent
            else:
                actual_parent = row["courseUnitId"]
        elif reference.kind == "vocabPack":
            base_pack_id = re.sub(r"_\d+$", "", reference.id)
            mapped_parent = _require(self.vocab_pack_units, base_pack_id, "vocab pack")
            if (
                _promotion_segment_key("vocabPack", reference.id) is not None
                or (reference.kind, reference.id) in self.published_content_routes
                or mapped_parent in C_UNIT_DEFAULT_ROUTE
            ):
                # 명시적으로 라우팅된 팩은 자기 유닛이 아니라 붙기로 한 세그먼트를
                # 따른다.  cloze·satz·grammar·smalltalk 에는 이미 있던 우회이고,
                # 모듈 첫머리의 교리("their count never creates segments")를 지키려면
                # vocabPack 에도 있어야 한다 — 새 코스 유닛은 세그먼트를 만들지
                # 않으므로 그 유닛의 팩은 기존 세그먼트에 붙는 수밖에 없다.
                actual_parent = expected_parent
            else:
                actual_parent = mapped_parent
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
            if (
                mapped_level != actual_level and reference.id in GRAMMAR_ID_ROUTES
            ) or _promotion_segment_key("grammar", reference.id) is not None or (
                (reference.kind, reference.id) in self.published_content_routes
                or (
                    actual_level in ("c1", "c2")
                    and mapped_parent in C_UNIT_DEFAULT_ROUTE
                )
            ):
                # 명시적으로 라우팅된 문법은 붙기로 한 세그먼트를 따른다.
                # 기존 조건(레벨 불일치)만으로는 같은 레벨의 신규 유닛이 기존
                # 세그먼트에 붙는 경우를 못 덮는다 — Batch 12 가 그 첫 사례다.
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
            if (
                _promotion_segment_key("cloze", reference.id) is not None
                or (reference.kind, reference.id) in self.published_content_routes
                or (
                    actual_level in ("c1", "c2")
                    and row.get("courseUnitId") in C_UNIT_DEFAULT_ROUTE
                )
            ):
                actual_parent = expected_parent
                validate_derived = False
            else:
                topic_key = f"{actual_level}:{row['topic'].lower()}"
                actual_parent = _require(
                    self.cloze_topic_units, topic_key, "cloze topic mapping"
                )
                validate_derived = True
            if actual_level in ("c1", "c2") and validate_derived:
                self._validate_derived_example(
                    row["fullKo"], actual_level, reference.id
                )
        elif reference.kind == "satz":
            row = _require(self.satz, reference.id, "satz")
            actual_level = row["level"]
            if (
                _promotion_segment_key("satz", reference.id) is not None
                or (reference.kind, reference.id) in self.published_content_routes
                or (
                    actual_level in ("c1", "c2")
                    and row.get("courseUnitId") in C_UNIT_DEFAULT_ROUTE
                )
            ):
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
        copy_revision = decision.get("copyRevision")
        if copy_revision is not None:
            if copy_revision != 1:
                raise ValueError(f"smalltalk {phrase_id!r} copy revision is invalid")
            if old is None:
                raise ValueError(
                    f"copy revision cannot introduce smalltalk {phrase_id!r}"
                )
            if decision.get("copyReviewStatus") != "nativeReviewRequired":
                raise ValueError(f"smalltalk {phrase_id!r} copy review gate is invalid")
            if decision.get("copyRevisionLedger") != CONTENT_HUMANIZATION_LEDGER_REF:
                raise ValueError(f"smalltalk {phrase_id!r} copy revision ledger is invalid")
            previous_fingerprint = decision.get("previousPhraseFingerprintSha256")
            if old.get("phraseFingerprintSha256") not in {
                previous_fingerprint,
                decision.get("phraseFingerprintSha256"),
            }:
                raise ValueError(
                    f"smalltalk {phrase_id!r} copy revision does not descend "
                    "from the published phrase"
                )
            ignored = {
                "phraseFingerprintSha256",
                "reviewRevision",
                "copyRevision",
                "copyReviewStatus",
                "copyRevisionLedger",
                "previousPhraseFingerprintSha256",
            }
            keys = set(old) | set(decision)
            if any(old.get(key) != decision.get(key) for key in keys - ignored):
                raise ValueError(
                    f"smalltalk {phrase_id!r} copy revision changed its "
                    "semantic route"
                )
            decision["reviewRevision"] = old["reviewRevision"]
            if phrase_id in approvals:
                used_approvals.add(phrase_id)
            continue
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
        if manifest.get("status") not in {"review_only_draft", "merged"}:
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
    if promotion is not None:
        target = promotion.get("canDoSegmentKey")
        if not isinstance(target, str) or not target:
            raise ValueError(f"promotion for {(kind, content_id)!r} has no can-do target")
        return target
    partner = PARTNER_FAMILY_SEGMENT_ROUTES.get((kind, content_id))
    if partner is not None:
        return partner
    batch_11 = BATCH_11_SEGMENT_ROUTES.get((kind, content_id))
    if batch_11 is not None:
        return batch_11
    batch_12 = BATCH_12_SEGMENT_ROUTES.get((kind, content_id))
    if batch_12 is not None:
        return batch_12
    batch_15 = BATCH_15_SEGMENT_ROUTES.get((kind, content_id))
    if batch_15 is not None:
        return batch_15
    batch_16 = BATCH_16_SEGMENT_ROUTES.get((kind, content_id))
    if batch_16 is not None:
        return batch_16
    batch_17 = BATCH_17_SEGMENT_ROUTES.get((kind, content_id))
    if batch_17 is not None:
        return batch_17
    batch_18 = BATCH_18_SEGMENT_ROUTES.get((kind, content_id))
    if batch_18 is not None:
        return batch_18
    return FOUR_X_SEGMENT_ROUTES.get((kind, content_id))


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
            if ("vocabPack", pack_id) in owners_by_reference:
                continue
            promoted_target = _promotion_segment_key("vocabPack", pack_id)
            base_pack_id = re.sub(r"_\d+$", "", pack_id)
            unit_id = _require(source.vocab_pack_units, base_pack_id, "vocab pack")
            target = source.published_content_routes.get(
                ("vocabPack", pack_id)
            ) or promoted_target or _require(
                C_UNIT_DEFAULT_ROUTE, unit_id, "C-level unit route"
            )
            add(_ref("vocabPack", pack_id), target, expected_level=level)
            continue
        if {row["level"].lower() for row in rows} != {level}:
            raise ValueError(f"vocab pack {pack_id!r} crosses levels")
        base_pack_id = re.sub(r"_\d+$", "", pack_id)
        unit_id = _require(source.vocab_pack_units, base_pack_id, "vocab pack")
        target = source.published_content_routes.get(
            ("vocabPack", pack_id)
        ) or PACK_ROUTES.get(
            base_pack_id, _require(UNIT_DEFAULT_ROUTE, unit_id, "unit route")
        )
        add(_ref("vocabPack", pack_id), target, expected_level=level)
        ab_pack_ids.append(pack_id)

    ab_grammar_ids = []
    for grammar_id, row in sorted(source.grammar.items()):
        level = row["level"].lower()
        if level in ("c1", "c2"):
            if ("grammar", grammar_id) in owners_by_reference:
                continue
            promoted_target = _promotion_segment_key("grammar", grammar_id)
            unit_id = _require(source.grammar_units, grammar_id, "grammar mapping")
            target = source.published_content_routes.get(
                ("grammar", grammar_id)
            ) or promoted_target or _require(
                C_UNIT_DEFAULT_ROUTE, unit_id, "C-level unit route"
            )
            add(_ref("grammar", grammar_id), target, expected_level=level)
            continue
        target = source.published_content_routes.get(("grammar", grammar_id))
        if target is None:
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
            if ("scenario", scenario_id) in owners_by_reference:
                continue
            target = source.published_content_routes.get(
                ("scenario", scenario_id)
            ) or promoted_target or _require(
                C_UNIT_DEFAULT_ROUTE,
                row["courseUnitId"],
                "C-level unit route",
            )
            add(_ref("scenario", scenario_id), target, expected_level=level)
            continue
        anchor = owners_by_reference.get(("scenario", scenario_id))
        target = (
            next(iter(anchor))
            if anchor
            else source.published_content_routes.get(("scenario", scenario_id))
            or promoted_target
            or EXTRA_SCENARIO_ROUTES.get(scenario_id)
            or UNIT_DEFAULT_ROUTE.get(str(row.get("courseUnitId") or ""))
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
            if ("smalltalk", phrase_id) in owners_by_reference:
                continue
            unit_id = source.smalltalk_unit(row)
            target = promoted_target or _require(
                C_UNIT_DEFAULT_ROUTE, unit_id, "C-level unit route"
            )
            add(_ref("smalltalk", phrase_id), target, expected_level=level)
            continue
        unit_id = source.smalltalk_unit(row)
        published_route = source.published_smalltalk_routes.get(phrase_id)
        target = promoted_target or SMALLTALK_ID_ROUTES.get(phrase_id)
        if target is not None:
            exact_smalltalk_override_ids.append(phrase_id)
            routing_source = "exactOverride"
        else:
            if published_route is not None:
                target = published_route["target"]
                routing_source = published_route["routingSource"]
                if routing_source == "exactOverride":
                    exact_smalltalk_override_ids.append(phrase_id)
                elif routing_source == "categoryFallback":
                    category_smalltalk_fallback_ids.append(phrase_id)
                else:
                    course_unit_smalltalk_fallback_ids.append(phrase_id)
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
            if (
                phrase_id not in SMALLTALK_ID_ROUTES
                and promoted_target is None
                and published_route is None
            ):
                raise ValueError(
                    f"smalltalk {phrase_id!r} maps to {unit_id!r}, "
                    f"but category route {target!r} belongs to {target_parent!r}"
                )
            if published_route is None:
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
        phrase_decision = {
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
        copy_revision = _copy_revision_metadata(row)
        if copy_revision is not None:
            phrase_decision.update(copy_revision)
        smalltalk_phrase_decisions.append(phrase_decision)
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
            if ("cloze", content_id) in owners_by_reference:
                continue
            unit_id = row.get("courseUnitId")
            if not isinstance(unit_id, str) or not unit_id:
                topic_key = f"{level}:{row['topic'].lower()}"
                unit_id = _require(
                    source.cloze_topic_units, topic_key, "cloze topic mapping"
                )
            target = promoted_target or _require(
                C_UNIT_DEFAULT_ROUTE, unit_id, "C-level unit route"
            )
            add(_ref("cloze", content_id), target, expected_level=level)
            continue
        if ("cloze", content_id) in owners_by_reference:
            direct_override_cloze_ids.append(content_id)
            continue
        published_target = source.published_content_routes.get(("cloze", content_id))
        if published_target is not None:
            add(_ref("cloze", content_id), published_target, expected_level=level)
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
            if ("satz", content_id) in owners_by_reference:
                continue
            unit_id = row.get("courseUnitId")
            if not isinstance(unit_id, str) or not unit_id:
                vocab = source._validate_satz_source(row, content_id)
                base_pack_id = re.sub(r"_\d+$", "", vocab["pack_id"])
                unit_id = _require(
                    source.vocab_pack_units, base_pack_id, "satz vocab pack"
                )
            target = promoted_target or _require(
                C_UNIT_DEFAULT_ROUTE, unit_id, "C-level unit route"
            )
            add(_ref("satz", content_id), target, expected_level=level)
            continue
        if promoted_target is not None:
            add(
                _ref("satz", content_id),
                promoted_target,
                expected_level=level,
            )
            continue
        published_target = source.published_content_routes.get(("satz", content_id))
        if published_target is not None:
            add(_ref("satz", content_id), published_target, expected_level=level)
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
