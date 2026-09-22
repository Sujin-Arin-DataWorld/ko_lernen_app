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
from copy_field_path import text_field


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
SMALLTALK_TRANSLATION_LEDGER_REF = (
    "tools/content_factory/review/smalltalk_translation_corrections_20260922.json"
)
SMALLTALK_TRANSLATION_LEDGER_PATH = ROOT / SMALLTALK_TRANSLATION_LEDGER_REF
PUBLISHED_AT = "2026-08-16T00:00:00.000Z"
LEVELS = ("a1", "a2", "b1", "b2", "c1", "c2")
EXPECTED_COUNTS = {"a1": 16, "a2": 16, "b1": 18, "b2": 20, "c1": 8, "c2": 8}
REVIEW_BATCH_MANIFEST_PATHS = (
    ROOT / "tools" / "content_factory" / "drafts" / "batch_06_manifest.json",
)
RELEVEL_DIR = ROOT / "tools" / "content_factory" / "relevel"
# C7 (2026-09-15): ledger-aware exemptions consulted by
# _preserve_cluster_history/_validate_authority_history so the append-only
# publication guarantee still holds for genuine future regressions, without
# requiring two already-documented historical events to be re-litigated by
# hand every time the generator runs:
#   1. Pack id renames from the PR-L2a relevel (bundle/newPackId pairs in
#      relevel_bundle_L2a*.json) -- a historical seed naming an old pack id
#      is satisfied if the renamed pack's seed is present instead.
#   2. Scenario ids retired outright by the 2026-09-01 canonical_120_v1
#      corpus promotion (ca00acad) -- ca00acad's own code comment says old
#      scenario ids "must not be required to keep old IDs live", but that
#      exemption was only ever wired into REVIEW_CONTENT_PROMOTIONS, not
#      into the seed/reference immutability guards below. The exact
#      (cluster, seed) pairs affected are enumerated in
#      canonical_120_v1_retired_seeds.json, generated once from a diagnostic
#      diff against the pre-C7 catalog and confirmed absent from the live
#      scenario corpus -- not an unbounded "if legacy, allow anything" rule.
RETIRED_SEEDS_LEDGER_PATH = RELEVEL_DIR / "canonical_120_v1_retired_seeds.json"


def _pack_id_renames() -> dict[str, str]:
    renames: dict[str, str] = {}
    for path in sorted(RELEVEL_DIR.glob("relevel_bundle_L2a*.json")):
        bundle = _read_json(path)
        for move in bundle.get("moves", []):
            old_id, new_id = move.get("bundle"), move.get("newPackId")
            if old_id and new_id and old_id != new_id:
                renames[old_id] = new_id
    return renames


def _retired_seed_pairs() -> set[tuple[str, str]]:
    if not RETIRED_SEEDS_LEDGER_PATH.exists():
        return set()
    ledger = _read_json(RETIRED_SEEDS_LEDGER_PATH)
    return {
        (row["clusterId"], row["seedId"])
        for row in ledger["retiredClusterSeeds"]
    }


def _renamed_seed_equivalent(seed_id: str, pack_renames: dict[str, str]) -> str | None:
    prefix, suffix = "seed_vocab_pack_", "_v1"
    if not (seed_id.startswith(prefix) and seed_id.endswith(suffix)):
        return None
    new_pack_id = pack_renames.get(seed_id[len(prefix):-len(suffix)])
    return f"{prefix}{new_pack_id}{suffix}" if new_pack_id else None


def _retired_scenario_reference_keys() -> set[str]:
    keys = set()
    for _cluster_id, seed_id in _retired_seed_pairs():
        if seed_id.startswith("seed_scenario_") and seed_id.endswith("_v1"):
            keys.add(f"scenario:{seed_id[len('seed_scenario_'):-len('_v1')]}")
    return keys

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
    return text_field(record, field_path)


def _copy_revision_metadata(row: dict[str, Any]) -> dict[str, Any] | None:
    changes = _humanization_changes_by_id().get(row["id"])
    ledger_ref = CONTENT_HUMANIZATION_LEDGER_REF
    ledger = _read_json(SMALLTALK_TRANSLATION_LEDGER_PATH)
    if ledger.get("scope") != "assets/data/smalltalk.json":
        raise ValueError("smalltalk translation ledger has an unexpected scope")
    translation_changes = [
        change for change in ledger["changes"] if change["id"] == row["id"]
    ]
    if translation_changes:
        if changes:
            raise ValueError(f"{row['id']}: overlapping copy revision ledgers")
        if any(change["field"] not in {"de", "en"} for change in translation_changes):
            raise ValueError("smalltalk translation ledger must only change DE/EN copy")
        changes = translation_changes
        ledger_ref = SMALLTALK_TRANSLATION_LEDGER_REF
    if not changes:
        return None
    previous = copy.deepcopy(row)
    for change in changes:
        current_parent, current_key = _at_nested_field(row, change["field"])
        if current_parent.get(current_key) != change["after"]:
            raise ValueError(
                f"{row['id']}.{change['field']}: live copy does not match "
                f"the copy revision ledger {ledger_ref}"
            )
        previous_parent, previous_key = _at_nested_field(previous, change["field"])
        previous_parent[previous_key] = change["before"]
    return {
        "copyRevision": 1,
        "copyReviewStatus": "nativeReviewRequired",
        "copyRevisionLedger": ledger_ref,
        "previousPhraseFingerprintSha256": _json_fingerprint(previous),
    }


A1_PRACTICE: dict[str, tuple[str, str, str]] = {
    "a1_01_greetings_hangul": ("scenario", "airport_arrival", "guidedProduction"),
    "a1_02_self_intro_identity": ("scenario", "introduce_yourself", "connectedProduction"),
    "a1_03_topic_subject_particles": ("scenario", "mart_grocery", "guidedProduction"),
    "a1_04_order_request_object": ("scenario", "bunshik_tteokbokki", "guidedProduction"),
    "a1_05_numbers_time": ("vocabPack", "a1_numbers_1", "dictation"),
    "a1_06_transport_directions": ("scenario", "taxi_kakao", "guidedProduction"),
    "a1_07_contact_address": ("scenario", "kakao_contact_after_class", "dictation"),
    "a1_08_clarify_repair": ("scenario", "clarify_repeat", "guidedProduction"),
    "a1_09_home_daily_life": ("scenario", "home_morning_routine", "connectedProduction"),
    "a1_10_health_safety": ("scenario", "subway_step_apology", "connectedProduction"),
    "a1_11_titles_relationships": ("scenario", "a1_w10_partner", "guidedProduction"),
    "a1_12_daily_negation": ("vocabPack", "a1_daily_1", "guidedProduction"),
    "a1_13_register_switching": ("cloze", "cloze_a1_0076", "connectedProduction"),
    "a1_14_payment_delivery": ("scenario", "bakery_payment_bag", "dictation"),
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
    _scenario_spec("a2_friend_birthday", "a2", "a2_02_plans_proposals", "a2_w10_booking"),
    _scenario_spec("a2_running_late", "a2", "a2_03_chat_relationships", "running_late"),
    _scenario_spec("a2_pharmacy_headache", "a2", "a2_04_feelings_health", "pharmacy_cold_medicine"),
    _scenario_spec("a2_gym_signup", "a2", "a2_04_feelings_health", "a2_w10_enrolment"),
    _scenario_spec("a2_feeling_sick", "a2", "a2_04_feelings_health", "gym_class_cancel"),
    _scenario_spec("a2_cafe_starbucks_basic", "a2", "a2_05_delivery_services", "a2_w10_buy"),
    _scenario_spec("a2_myeongdong_shopping", "a2", "a2_05_delivery_services", "clothing_refund_size"),
    _named_spec(
        "a2_cafe_study", "a2", "a2_06_study_work",
        "vocabPack", "a2_school_supplies_1",
        ("카페에서 공부하기", "Im Café lernen", "Studying at a café"),
        "connectedProduction",
    ),
    _scenario_spec("a2_subway_transfer", "a2", "a2_07_travel_repair", "train_seat_swap"),
    _scenario_spec("a2_taxi_street", "a2", "a2_07_travel_repair", "taxi_slow_down"),
    _scenario_spec("a2_subway_directions", "a2", "a2_07_travel_repair", "jeju_bus_missed"),
    # KNOWN_MISSING_SCENARIO_SLOTS (see test_build_can_do_segments.py): scenario
    # "lost_phone" was retired by the 2026-09-01 canonical_120_v1 corpus promotion
    # with no direct replacement written yet. Explicit text keeps this segment
    # buildable until the A2/B1 enrichment wave writes real scenario content.
    _named_spec(
        "a2_lost_phone", "a2", "a2_07_travel_repair",
        "scenario", "lost_phone",
        ("휴대폰을 잃어버렸을 때", "Wenn du dein Handy verloren hast", "When you've lost your phone"),
        "connectedProduction",
    ),
    _scenario_spec("a2_ktx_ticket", "a2", "a2_08_home_money", "library_card_problem"),
    _scenario_spec("a2_rent_bank_transfer", "a2", "a2_08_home_money", "a2_w10_money"),
    _scenario_spec("b1_plans_with_reasons", "b1", "b1_01_experience_reasons", "jeju_rain_plan_change"),
    _named_spec(
        "b1_travel_experience", "b1", "b1_01_experience_reasons",
        "vocabPack", "b1_travel_transport_1",
        ("여행 경험 설명", "Reiseerfahrungen schildern", "Describing travel experience"),
        "connectedProduction",
    ),
    _scenario_spec("b1_relay_social_speech", "b1", "b1_02_indirect_speech", "team_update_indirect_speech"),
    _named_spec(
        "b1_relay_media_claim", "b1", "b1_02_indirect_speech",
        "vocabPack", "b1_media_culture_1",
        ("매체 주장 전달", "Aussagen aus Medien wiedergeben", "Relaying a media claim"),
        "connectedProduction",
    ),
    # KNOWN_MISSING_SCENARIO_SLOTS (see test_build_can_do_segments.py): scenario
    # "bank_account" was retired by the 2026-09-01 canonical_120_v1 corpus
    # promotion with no direct replacement written yet. Explicit text keeps
    # this segment buildable until the A2/B1 enrichment wave writes real
    # scenario content.
    _named_spec(
        "b1_bank_soft_request", "b1", "b1_03_work_softening",
        "scenario", "bank_account",
        ("은행 계좌 만들기", "Ein Bankkonto eröffnen", "Opening a bank account"),
        "connectedProduction",
    ),
    _scenario_spec("b1_team_role_coordination", "b1", "b1_03_work_softening", "work_message_too_direct"),
    _scenario_spec("b1_attendance_and_coverage", "b1", "b1_03_work_softening", "company_instagram_wrong_account"),
    _scenario_spec("b1_schedule_softening", "b1", "b1_03_work_softening", "community_festival_shift"),
    # "shared_document_old_version" (moved A2->B1 by PR-L2a's scenario
    # relevel, docs/data/relevel_L2a_report.md row for that id) has no
    # published can-do segment yet -- the relevel report itself flags this
    # spec as added without a matching can_do_segments.json entry ("자산은
    # 재생성하지 않는다"), and the report note that it is "worth a look if
    # it is ever unfrozen". Publishing the segment is a content decision,
    # not tooling drift, so it stays out of AB_SPECS; see
    # KNOWN_UNPUBLISHED_LIVE_SCENARIOS for the matching coverage exemption.
    _scenario_spec("b1_encouragement", "b1", "b1_04_relationships", "speech_level_after_friendship"),
    _scenario_spec("b1_intimate_feelings", "b1", "b1_04_relationships", "date_or_friendly_coffee"),
    _named_spec(
        "b1_social_invitation", "b1", "b1_04_relationships",
        "vocabPack", "b1_social_events_1",
        ("사회적 초대와 응답", "Einladungen aussprechen und beantworten", "Inviting and responding socially"),
        "connectedProduction",
    ),
    _scenario_spec("b1_delivery_resolution", "b1", "b1_05_complaint_resolution", "food_delivery_wrong_order"),
    _scenario_spec("b1_property_damage_report", "b1", "b1_05_complaint_resolution", "b1_w10_repair"),
    _scenario_spec("b1_housing_contract", "b1", "b1_05_complaint_resolution", "b1_w10_cancellation"),
    _scenario_spec("b1_safety_health_concern", "b1", "b1_05_complaint_resolution", "b1_w10_insurance"),
    _scenario_spec("b1_relationship_conflict_repair", "b1", "b1_06_life_capstone", "park_pet_manners"),
    _scenario_spec("b1_move_in_handover", "b1", "b1_06_life_capstone", "apartment_recycling_mixup"),
    _named_spec(
        "b1_life_course_narrative", "b1", "b1_06_life_capstone",
        "vocabPack", "b1_time_life_1",
        ("생애 과정 서술", "Einen Lebensweg erzählen", "Narrating a life course"),
        "connectedProduction",
    ),
    _scenario_spec("b2_formal_meeting_opening", "b2", "b2_01_formal_opening", "meeting_opening_context"),
    _named_spec(
        "b2_honorific_register_transform", "b2", "b2_01_formal_opening",
        "vocabPack", "b2_honorifics_1",
        ("높임말과 격식 전환", "Höflichkeitsstufen formell umformen", "Transforming honorific register"),
        "guidedProduction",
    ),
    _scenario_spec("b2_decision_criteria", "b2", "b2_02_professional_opinion", "meeting_disagreement_evidence"),
    _scenario_spec("b2_public_wording_revision", "b2", "b2_02_professional_opinion", "direct_feedback_misread", "openWriting"),
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
    _scenario_spec("b2_medical_precision", "b2", "b2_03_precise_requests", "b2_w10_health"),
    _scenario_spec("b2_contract_scope", "b2", "b2_03_precise_requests", "freelance_scope_change", "openWriting"),
    _scenario_spec("b2_terms_deferral", "b2", "b2_03_precise_requests", "b2_w10_negotiate", "openWriting"),
    _named_spec(
        "b2_environmental_tradeoff", "b2", "b2_03_precise_requests",
        "vocabPack", "b2_environment_1",
        ("환경 상충관계 조정", "Ökologische Zielkonflikte abwägen", "Balancing environmental trade-offs"),
        "openWriting",
    ),
    _scenario_spec("b2_formal_complaint", "b2", "b2_04_complaint_resolution", "delivery_refund_evidence", "openWriting"),
    _scenario_spec("b2_remedy_and_appeal", "b2", "b2_04_complaint_resolution", "b2_w10_notice", "openWriting"),
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
    _scenario_spec("b2_interview_experience", "b2", "b2_05_interview", "portfolio_interview_gap"),
    _scenario_spec("b2_literary_cultural_response", "b2", "b2_06_advanced_capstone", "b2_w10_fandom", "openWriting"),
    _named_spec(
        "b2_formal_soft_reformulation", "b2", "b2_06_advanced_capstone",
        "grammar", "grammar_b2_only_course",
        ("격식 있고 부드러운 재표현", "Formell und behutsam umformulieren", "Reformulating formally and tactfully"),
        "guidedProduction",
    ),
)


# Content gaps documented alongside test_build_can_do_segments.py's
# ABSpecScenarioReferencesLiveTest.KNOWN_MISSING_SCENARIO_SLOTS: the
# 2026-09-01 canonical_120_v1 corpus promotion (ca00acad) retired scenarios
# "lost_phone" and "bank_account" with no direct replacement written yet.
# a2_lost_phone/b1_bank_soft_request above carry explicit fallback text so
# the catalog stays buildable; this keeps the exact-coverage check below
# honest about the gap instead of silently dropping it. Remove once the
# A2/B1 enrichment wave writes real scenario content for both slots.
KNOWN_MISSING_SCENARIO_SLOTS: frozenset[str] = frozenset({"lost_phone", "bank_account"})

# The inverse drift: these scenarios exist in the live corpus (written by
# PR-L2a's scenario relevel) but have no published can_do_segments.json
# segment yet, so AB_SPECS must not claim them and the exact-coverage check
# below must not require them. Remove once a follow-up PR publishes the
# segment(s).
KNOWN_UNPUBLISHED_LIVE_SCENARIOS: frozenset[str] = frozenset({"shared_document_old_version"})


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

# Theme Park Date route approvals are static fingerprints of the 40 A1-B2
# learner-facing phrases approved for live integration by Jin on 2026-08-30.
# C1-C2 content uses the published C-level course-unit route and is outside the
# A1-B2 phrase-decision ledger below.
_THEME_PARK_DATE_SMALLTALK_ROUTE_APPROVALS = (
    ("smalltalk_a1_0091", "b87433dde6613d7a0ff773e510004a59d2ab6e971e658f8a8631c455129cdcf5", "segment_a1_11_titles_relationships", "f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b"),
    ("smalltalk_a1_0092", "a9374e6cc3294ca51233df3e6be4351d226370f7a90f45e8019ccdffc180e652", "segment_a1_11_titles_relationships", "f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b"),
    ("smalltalk_a1_0093", "77cba50b5e94c3cd78ae83438fc4d88bf08a5c0a2282a1fb2c34cc8024123dad", "segment_a1_11_titles_relationships", "f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b"),
    ("smalltalk_a1_0094", "0e0670eb8f51107fdde0c76fa3bbd0352191c3d36859555fcd04c69d10ecc69d", "segment_a1_11_titles_relationships", "f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b"),
    ("smalltalk_a1_0095", "cc3e7a02ecde78ddc395025cdfb7e35792acced390ec25343d93a5db83eefbdb", "segment_a1_11_titles_relationships", "f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b"),
    ("smalltalk_a1_0096", "ccc7b2557b51adb1b8f46a1d773b7822ac9bcbef020eb6f4fb69c8e85123ed51", "segment_a1_11_titles_relationships", "f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b"),
    ("smalltalk_a1_0097", "e451b06be52de4ba17e2c234f2cd5e287f0a1de4e730bf4310681ae317fc280b", "segment_a1_11_titles_relationships", "f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b"),
    ("smalltalk_a1_0098", "f70bfcf99cdbcfdb50e899ddfea62b07dec64a10507293f0a96a920df0c97ded", "segment_a1_11_titles_relationships", "f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b"),
    ("smalltalk_a1_0099", "9f2cfd9a0a17a9147c5f824f55081c0a94081a952c6e09ff3a24231164a7c244", "segment_a1_11_titles_relationships", "f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b"),
    ("smalltalk_a1_0100", "2c410fe792c0a08d7c8ca88d300c9ec858d8277ccdf46834fc4171df6ece2208", "segment_a1_11_titles_relationships", "f6d0a3c31f9c18c1e0c20ea5f6d9c72a6ce0dd5df4f17d2591a0db0813f7044b"),
    ("smalltalk_a2_0084", "ba859ae48fece78f8886fc169314e1f15a5e0234b2633f50f74266d0b40cac8e", "segment_a2_running_late", "fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27"),
    ("smalltalk_a2_0085", "1fc43f0de62a589b0b411fe613900fec43897b9626cdb12e01edc4052086f6f0", "segment_a2_running_late", "fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27"),
    ("smalltalk_a2_0086", "fd56ccbbabc52e1f19a85ed1fd179dd4307c5a05528d9bd91f579f7888649064", "segment_a2_running_late", "fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27"),
    ("smalltalk_a2_0087", "ad795ef7f54ef83010a38f7a2b29325e451bd9e1485963b2044beec8040c360a", "segment_a2_running_late", "fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27"),
    ("smalltalk_a2_0088", "21afbd0d67fc43a077eb0845de02be8a764d7dd0fd27be99b9499eed72231b2b", "segment_a2_running_late", "fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27"),
    ("smalltalk_a2_0089", "cb9ebeb79fcb574965816120dedf3a770d469d6daac37fc081b6612ced5b18bf", "segment_a2_running_late", "fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27"),
    ("smalltalk_a2_0090", "b6cf9af269ee6c744ffab19128fede370129fd305d89a7632589f6583622f0fd", "segment_a2_running_late", "fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27"),
    ("smalltalk_a2_0091", "46c683b7bf9a3288b2129884fcda762dbfbb03def957f1f032616ef99be09082", "segment_a2_running_late", "fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27"),
    ("smalltalk_a2_0092", "1c6e9b4796bdfa577710def6eec671430d52ffc4879240598b36d38637ac36ee", "segment_a2_running_late", "fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27"),
    ("smalltalk_a2_0093", "cb81a45832e150030ae770cf67d4f933420f4c3641820197cdc43b13ab932c8f", "segment_a2_running_late", "fab074a96029136b9d59a3ccd4c02ead17286ae529287fb398a9bcbf20cd6a27"),
    ("smalltalk_b1_0079", "697db0071e71f311b5aa792c768431207dc07a3d7bcbe963cf87ee704850a670", "segment_b1_intimate_feelings", "6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651"),
    ("smalltalk_b1_0080", "da150032a46c40b47612aa8000463ce5151407040fb269185bbcaaa54f6298f0", "segment_b1_intimate_feelings", "6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651"),
    ("smalltalk_b1_0081", "35f373aba5bd41b164edfa95e7164657e43ca517843074c674f74a8a537911a9", "segment_b1_intimate_feelings", "6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651"),
    ("smalltalk_b1_0082", "e75915a8705228203cfcf92be89b7dd7fa913bb40ae2cc6a1e0e93d7e3e66d26", "segment_b1_intimate_feelings", "6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651"),
    ("smalltalk_b1_0083", "3ba118106084a7c16be955d47c35bcb093fbf59d03caf6ec32ea328924e52cb3", "segment_b1_intimate_feelings", "6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651"),
    ("smalltalk_b1_0084", "fb4b7a549061fa035bb76cbaac21022e1433114b0878aa275b28262a093f975d", "segment_b1_intimate_feelings", "6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651"),
    ("smalltalk_b1_0085", "9599563d4cc32a96831e66f01aef8b6c2c10966c2f449ed37a4955fe28d66fae", "segment_b1_intimate_feelings", "6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651"),
    ("smalltalk_b1_0086", "c82bf4dd37ce2c046ad800214ee403e930f50cd5140536d80cc0e7a381c6e023", "segment_b1_intimate_feelings", "6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651"),
    ("smalltalk_b1_0087", "b91e8824d7b8b6571a30761982dc5e22434bd136fe655cd4aeb721ad520f484a", "segment_b1_intimate_feelings", "6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651"),
    ("smalltalk_b1_0088", "387b337cb554c9e7de07c278cd457a1b2bfba3990ce65de19eef57282d60fd5e", "segment_b1_intimate_feelings", "6a2de13eba2679e09f9041d6d71f4fcb0cb150227cc8841c7a67d62188355651"),
    ("smalltalk_b2_0119", "6631dd154d8c4c779916e916829947fafd2d9dfba8c39bf1ef1904982f8c06a1", "segment_b2_contract_scope", "1ce4a30a3a7f78b39517e0bcc2b3402f136a8b9e4aa399d45bd294366f32d41a"),
    ("smalltalk_b2_0120", "eda0ac99b8c74a0223b7816f98cbf93f37b7876b3b05952f8afb31ffa4efe34b", "segment_b2_contract_scope", "1ce4a30a3a7f78b39517e0bcc2b3402f136a8b9e4aa399d45bd294366f32d41a"),
    ("smalltalk_b2_0121", "13a77330e2a2ec849fcb81c3cd47af05207ffa96e9760bfd608eaf78b21ffc4c", "segment_b2_contract_scope", "1ce4a30a3a7f78b39517e0bcc2b3402f136a8b9e4aa399d45bd294366f32d41a"),
    ("smalltalk_b2_0122", "cea74b6caf69c607422237ab3cb412b09ed6231d1b09cea88cbf5200083ba9b8", "segment_b2_contract_scope", "1ce4a30a3a7f78b39517e0bcc2b3402f136a8b9e4aa399d45bd294366f32d41a"),
    ("smalltalk_b2_0123", "8d18e983cb1d3ce5c1760ec353bc60cf36667a769d90e2649fe472fd0bb455d8", "segment_b2_contract_scope", "1ce4a30a3a7f78b39517e0bcc2b3402f136a8b9e4aa399d45bd294366f32d41a"),
    ("smalltalk_b2_0124", "622295a96856389c18720bc238393a757768a62e853ae64e65fcaf14399048f5", "segment_b2_contract_scope", "1ce4a30a3a7f78b39517e0bcc2b3402f136a8b9e4aa399d45bd294366f32d41a"),
    ("smalltalk_b2_0125", "f2f1c1f1998348036d237b88776d1c14ccb7dee7e88c1ba831439d7fba2d95f5", "segment_b2_contract_scope", "1ce4a30a3a7f78b39517e0bcc2b3402f136a8b9e4aa399d45bd294366f32d41a"),
    ("smalltalk_b2_0126", "382fd7a01f3d7f587057afa969bcf189cbbb6321863cbf4c5bf185e3b6a6f6e7", "segment_b2_contract_scope", "1ce4a30a3a7f78b39517e0bcc2b3402f136a8b9e4aa399d45bd294366f32d41a"),
    ("smalltalk_b2_0127", "2c54bb563e3a68e498227b27f2896314c003ac25a540615f43a7408e25813cbb", "segment_b2_contract_scope", "1ce4a30a3a7f78b39517e0bcc2b3402f136a8b9e4aa399d45bd294366f32d41a"),
    ("smalltalk_b2_0128", "3b6efbeff37b8ca03766521bfe9230b95266124e43988a430a1f33aea8da20c9", "segment_b2_contract_scope", "1ce4a30a3a7f78b39517e0bcc2b3402f136a8b9e4aa399d45bd294366f32d41a"),
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
        in _THEME_PARK_DATE_SMALLTALK_ROUTE_APPROVALS
    }
)
for _theme_park_revised_phrase_id in (
    "smalltalk_a2_0090",
    "smalltalk_b1_0082",
    "smalltalk_b2_0124",
):
    SMALLTALK_REVIEW_APPROVALS[_theme_park_revised_phrase_id][
        "reviewRevision"
    ] = 2



# PR #288 (aa0d932f) curriculum canDo text is source of truth; Fable ruling 2026-09-15; C7b
_C7B_SMALLTALK_REBINDING_APPROVALS = (
    ('smalltalk_a1_0001', 'da49e567c834cfb03e2a583c9d477f51205748f5873897ce85a86b9ccd11de66', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0002', '3a2402cbc42a20eb629db6d9ea49d215fcbd4b587b2931d15a3c8d7f53adedc3', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0003', '3cf82d9760e7668e604e0238395682fb41dc843cfd3011a2e58f71a897334bea', 'segment_a1_12_daily_negation', 'fbea0f8682214cf2ea2c2d029ca3522039241f46111ce026233ae8f5a6d42658', 'approved', 2),
    ('smalltalk_a1_0004', '85cd88ddd4b477d9ad66ec54881bfe9fee289b514e26c1aedc1ff2b0a5c816a6', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0005', '0e4a455cf4cfcbe887d9067434af9415c9e805b05b457865570d067c576d3a58', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0006', '7bb704573eb774aaae0fbedc4570f37482a58218e949b68a333287ba3a464ea3', 'segment_a1_12_daily_negation', 'fbea0f8682214cf2ea2c2d029ca3522039241f46111ce026233ae8f5a6d42658', 'approved', 2),
    ('smalltalk_a1_0007', 'afbcb1b0b4db3ebaff7f0897b237b875d1880d577b149c00e569eb71f120e1e7', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0021', '127b0e556abdd6b72232a28decb42719de9039725bd7a3fc8974095850379895', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 1),
    ('smalltalk_a1_0025', 'c06e1f7ad6c8a7bd5ef12c4e620a4fe5827e16c381cdae29915e8b4e01689afd', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0042', 'c4501bb124bd23f929e6e4cd474d21d084520cd86d951d463795f9372ca91d0c', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 1),
    ('smalltalk_a1_0043', '64cde28b1da498d3e856a2ff42e253f299a75bbcaf10b817fa534512bde8936a', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 1),
    ('smalltalk_a1_0044', '4eb39ebad4a9315538bf68672f5cdb014fee3b2a564f32c41c7c354221b222cd', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 1),
    ('smalltalk_a1_0051', '1dba529fc0c4479ad5953eacc9f80a74943b3b48bd7c282a64dd1af18d9e08d8', 'segment_a1_07_contact_address', 'f0b2de476336b8393d0d3f291ca7bf6e0a4f261d6d7cb766e0110ffb87ceb318', 'approved', 2),
    ('smalltalk_a1_0059', 'dd1360ca15f73c60bddda1d07a7c864c5afd59da6d9e7b0f629bce55f7b3c061', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0075', 'e76087d22c9d74d65f1e2b317dd6528c22fc09784c77f2313af2c70105c957dd', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0076', 'b4fcdd8751af3e5f98982b7fe04006f2f61f0d255873813f00de240b7bb0ce56', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0081', '6210610af78fe92b870c3e75443e9c5a72d685eaa55797eb0d893c5c2537a516', 'segment_a1_12_daily_negation', 'fbea0f8682214cf2ea2c2d029ca3522039241f46111ce026233ae8f5a6d42658', 'approved', 1),
    ('smalltalk_a2_0001', 'd68f9dfa954bd5b192dbf9d19bbbac5bff6b384062b6ae6cd1c50644b961128a', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 1),
    ('smalltalk_a2_0015', 'ac30a2c83152228278a0c0297beb91b42c00c62797eceb1d754e4bee47552eb0', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0016', 'af174c897d60466f3c1a38962d3729a3b3a66f423bf27ced0ed9314bed78c790', 'segment_a2_cafe_starbucks_basic', '23de0a68ee5e7803e95b6fbe7ee50cddd6fa66cf56a7b8feac41f1d8f430bd8c', 'approved', 1),
    ('smalltalk_a2_0023', 'aa340e23500a65a65486d95cd8f94f1ce64d1d5ff7d5a7eb1832295c854651ad', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 1),
    ('smalltalk_a2_0026', '736f0acc2a775b595c0a2ece238ca93c360d34ce825d1a8a81b82dec6b382481', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 1),
    ('smalltalk_a2_0043', '8e85934c6c559d376b05627ee833314e4957f93bc8dc3a645c2e2a19eeed9724', 'segment_a2_myeongdong_shopping', 'c82ee1b27476bd9d495fa5e42b09f7739c3b7fa4ddf084734003a8d0504cb064', 'approved', 1),
    ('smalltalk_a2_0050', 'd4988f0831cb155f137add6d12c09f2cd9255cbd47ab7832344e88415733422f', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 1),
    ('smalltalk_a2_0062', 'd5e8e61399b5d3b5eda941c56ccff8a7af7f890023065d34d769e497933b9cff', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 2),
    ('smalltalk_a2_0066', 'eb9491cafc31ef5766b412d1ee39ae296b758bc3666070d2bb86f228d6985d70', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 2),
    ('smalltalk_a2_0068', 'c842410a36208ced07c63e2de38e926c2ec63cb96c9d358b5745dff897118abf', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 2),
    ('smalltalk_a2_0071', 'aad3be4e2d162ad8efcb92e7d70720c0f00c29e48a39b8ddbe214ae5172dc9b3', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 2),
    ('smalltalk_a2_0074', 'b3de808e994ff2436088c3ae6cb7a5e988e43d06a77b59f4e17256d4be0048d1', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 1),
    ('smalltalk_b1_0002', '2c68c043aeb739155aacc9c6f50278685eb735c2a086a089d35c1146a1ed7775', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 1),
    ('smalltalk_b1_0025', '54352d446219f9afdaccc1d5874e2fde2e57ae46eff2de28676a47bdef64976f', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 1),
    ('smalltalk_b1_0029', '358bb45e837f1ce9afd9668082c2f8a0c2d80356566339a535f0a126a34396dc', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 1),
    ('smalltalk_b1_0030', 'ef0ae87b209dc2c3a1d437b08ddbf2e072a49759d2eb3bbedebe84b34a0b3e3f', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 1),
    ('smalltalk_b1_0057', 'e8df150a7ada11a78c0181c6e5b900263e0d369d3ca6ff1cff0718da62781a03', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 2),
    ('smalltalk_b1_0066', '9813e919d49707f1ebbea4568f784f3136309a0db7596ac94267c45e519cbedc', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 2),
    ('smalltalk_b1_0068', 'f9b8800d62a6d4bf7aad7657a464051171348c8217f2a7a70d08c545702cf74a', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 2),
    ('smalltalk_b1_0071', '2822c744ccb233b933afb8b71f421319e5593f1e90b327496fd58ccffb4ca375', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 1),
    ('smalltalk_b2_0007', '9584f45a4cd6072f3334caf4db5609353537d86627b42afa44338dc0b9a1271c', 'segment_b2_literary_cultural_response', 'e99e9cacd4a66254c25cfb6957e52f6322313a7b1872d518f7b3601aa4b59409', 'approved', 1),
    ('smalltalk_b2_0025', '8cff207ad5c5ef0536bc3ba4102669761786d8c4a493d6849ba810a70eccad32', 'segment_b2_literary_cultural_response', 'e99e9cacd4a66254c25cfb6957e52f6322313a7b1872d518f7b3601aa4b59409', 'approved', 1),
    ('smalltalk_b2_0099', '2d11ae068efebbe51eac02e76c2ab336259ec30467d1d50c564d25098fe46504', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 1),
    ('smalltalk_b2_0100', '8dc8c5191e3c2bfa272ceb0459c39ab934d1ba303f83a3ddeb63efe89fc40bda', 'segment_b2_formal_meeting_opening', '26da06c8bde1f79fe7d103fdf51970fe17f776764bf512ebb8601e2899f907e8', 'approved', 1),
)
SMALLTALK_REVIEW_APPROVALS.update(
    {
        phrase_id: {
            "phraseFingerprintSha256": phrase_fingerprint,
            "canDoSegmentId": segment_id,
            "canDoFingerprintSha256": segment_fingerprint,
            "semanticStatus": semantic_status,
            "reviewRevision": review_revision,
        }
        for phrase_id, phrase_fingerprint, segment_id, segment_fingerprint, semantic_status, review_revision
        in _C7B_SMALLTALK_REBINDING_APPROVALS
    }
)
# provenance: approvedBy='Jin' approvedAt='2026-09-15' count=41



# PR #288 (aa0d932f) curriculum canDo text is source of truth; Fable ruling 2026-09-15; C7b
_C7B_SMALLTALK_REBINDING_APPROVALS_2 = (
    ('smalltalk_a1_0008', 'ff67e9feb807efff56a3be3c311fb626e48f6c6ddca59f241c5dd27dbfd55fd2', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0009', '5b63aacd6fc0454ac71e9a6fa3f5196fe1c673fbfc979dd8d87849dea7b2ecca', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0010', 'e4d26d3607d3f641ab1ee2986c0b7959f4bbea228844df4486062726ddbb37d4', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0011', '8c82e0082cefd7ffcbc136fc3232fbfe43339ccda424b693ea2636b6e5066053', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0012', '80ba896ca855ae649eb14137c604a5251c3760a05fa055cbb18a817802b260a6', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0013', '521fef19e7369e1620a1d6390e2f601634697df0eb1e96322ae9b46319c72848', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0014', '8297f759b789e05c6c8632bc7d52d8e363a47695275f0ea7f43456391fbba95b', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0015', '82b9b7020f1e7b93b9eea3e8229f8c397869901952bc221a81253aa5ae11d350', 'segment_a1_12_daily_negation', 'fbea0f8682214cf2ea2c2d029ca3522039241f46111ce026233ae8f5a6d42658', 'approved', 2),
    ('smalltalk_a1_0016', '58f8e24d76d030a18135b2c7d6386824c4fc76755e3493969505f622367bb269', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0017', '1cd56c1c746e6b1ab2e72e3e9cd16f3554be7e3d2502f9bc4214b91d5fb7d198', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0018', 'e3f311ac3974b106bc2b6472f016931497858951047f67c8fc0e90f80393fee7', 'segment_a1_12_daily_negation', 'fbea0f8682214cf2ea2c2d029ca3522039241f46111ce026233ae8f5a6d42658', 'approved', 2),
    ('smalltalk_a1_0019', 'bd271e4cf3908a8a232bcb9a65393117799853b4a761336b40646e97d74b936e', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 3),
    ('smalltalk_a1_0020', '1ef26accecef5bc18e0802485e84cc47b4221bb6341831505a9aa436653fc7e4', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0022', 'b96f9cf4d196f07181eec08f198d7fb722e252aebcf8fd75c1c1b9d547945c64', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0023', '9ca84baab8c0d0ccba4bca6d584f42340de6e06882c593699214a15e5c328dd1', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0024', '3f98b0f72ffb0d88a52c289e0c5e132febc9fe063a22944be76678083ac4b34e', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0026', '47c3da786b94c76c2bfa121468a5f6ffe01fab6f84c338e74ad7efdef9eddc36', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0027', 'fc86b0989a43bc9bd5f167f87202efa5cae3408d4d8501681aead1e944b18c9f', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0028', '48752a9c0eb75582925598be16541a84c28a637ebfa52bc9e613c275f6550210', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0029', 'e4112204dc919931ba613d1e2328667bf5ad7b64536550cecd2f0e4e3fc9ef78', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0030', 'df4b81a683e6c006cdc3a558fa2c3fdb3b9aee8c457ee320b428f4af8b1286b2', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0031', '5ffac261b38e3a2e8422a589e36798fb89cdc5cf5112a2082fd08c8d13cf0148', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0032', '7cb968f33e35587b2252f74605f10a4dd1b92cd02fd9d0b8989f194e4a426753', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0033', 'd91d9e1b04ca6e4e65d9b80943575daf8c7a8c886a5039c64fc062834569be07', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0034', '67caa8470b4f13a00961a681c1e8ae9eca6e3f10fe9a00c6174125fb81717861', 'segment_a1_07_contact_address', 'f0b2de476336b8393d0d3f291ca7bf6e0a4f261d6d7cb766e0110ffb87ceb318', 'approved', 2),
    ('smalltalk_a1_0035', 'a63baaabc5975b057ce6e47c8539d7a486fa865a639f761454269c73b0da6f2b', 'segment_a1_07_contact_address', 'f0b2de476336b8393d0d3f291ca7bf6e0a4f261d6d7cb766e0110ffb87ceb318', 'approved', 2),
    ('smalltalk_a1_0036', 'a2daee8ab06bc8858c6d93a452d963f41103ef09d80d1a4c2befba05877691be', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0037', '56e450be5ff666f15cd141e883b49c44e3b3d7f49e2cec96fc6f51a2c9bb9b7d', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0038', '7f06f3bf91ca4fa18e4948325d29360353e408ccc5bca975a427701f72e057f1', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0039', '21b3732cff39ffb67c8e5010108b91e7ca88b14216ac7c78f14b4065ca909c7f', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0040', 'bb50e039f13f0f9cb20f9163561be784a98a8b747c11ac6de600278583249931', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0041', '91d9b69fa847aa273158719a124b3bd8e6cb8d309c1b8b5a31b43dc2b900644f', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0045', 'cc3afc8f4e4479e085a168a20bede442fce90723f2c423ca5a4165ae18dadf30', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0046', 'b19a97b4a6c9c5c39150c6091881da2a14438b7dcb4c4039d484c230e4112949', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0047', '003fe2486280ed80d50cc6a33eca37a48cf875c6a459f2cb91b1501a4b8885b8', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0048', '0c28550b770268eabaf6e6a34ee8150d6724567f0af5122a4e62a78635e874fe', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0049', 'a2f6bc904062add7502af1659e0c848a0f18e5b61504a0aa9ab24428b9e4d391', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0050', 'ba72da418fbeecd1f38152ca28ef01fe51b83b001d987e0aebdc82fd6f32ad3b', 'segment_a1_07_contact_address', 'f0b2de476336b8393d0d3f291ca7bf6e0a4f261d6d7cb766e0110ffb87ceb318', 'approved', 3),
    ('smalltalk_a1_0052', 'b914fc1a0827f1a81897b6f6528f28067bea7b6c23c962545e68dab8a4753742', 'segment_a1_07_contact_address', 'f0b2de476336b8393d0d3f291ca7bf6e0a4f261d6d7cb766e0110ffb87ceb318', 'approved', 3),
    ('smalltalk_a1_0053', '7d7803ece33ab87bf3f9ff52c27bd6257df4baf66c6dda57b554db276d5a25ef', 'segment_a1_08_clarify_repair', '2c8abeefaefda451b1c100d8a6b62bb336e3b9b4262bc5297ea500ee5964c7e2', 'approved', 3),
    ('smalltalk_a1_0054', 'ba5a5ab3b74b0ab414d065dfb6575b6adfbde480488f28355b4d624348c07b0b', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0055', 'bd01f98660eabf847925ce514bcf9d329bd9d298c6562bff59b80c9c154ad67b', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0056', '4c32af430bb9c66c9bb006add3bece624e847f517faac48165a31a60248dbccb', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0057', '2336abd103a52c548bca6de3a40e3325afd71458a02eba234a69590c675882d6', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0058', '4cad355e2a0f306a6275728734ffb1408357642de0edaede450cbc4340e4fe7f', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0060', '6767ada09e63a41fdb0bc7a13bca49025bf0e513391871d95a8082042b5196a6', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 3),
    ('smalltalk_a1_0061', '5581cc77143ab28fee1ec16defc623ad1ab98bceb8f64a7e259ec9830eda5b78', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0062', '8852bf38ba69a527964f6bf37d6e9394e4235a3f29feec8491cc8c2c2185d4ca', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0063', '28f86ed1cb3a7d3073c4f344c09085b981aa4dc814e8abf988595750f1366770', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0064', 'cca448a19be75ff641b17161292e7b029f85e3b8d693e9bae56226ced522e68d', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0065', '5f28c52d3bd1da681a77ad5f1c31992457551ffd414419c08c59f6e6f0250e3e', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0066', '2943ba5a22c4e16203547c402e9ccf35c13a8e35a38325b6a84de6a90d1de496', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0067', '68cf68c617358c6901083f396e04f841f26f809d3bc002c6dedccd6a842df974', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0068', '1ae6aa274c3d18ee10fec4f1c62b5f154577f730a5ee53d4851c1e3b5b36a7cd', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0069', 'b8bf62e1618417aa9241458ada4033e8583bc34d21b50e3c91a997ef7da76587', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0070', '4bb24e889a6c85ec6eb98fffa7dd58d0915a37d14dd3c762a204c2f639767f78', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0071', '5d82a8db430194a8511492ef5287d2b1cbba39062cbc3f8d562a2e29eb5b88d6', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0072', '56096bc1a1bf488d6ae16b5d64559788893d1d5ddf67e154075734256ca291c0', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0073', 'bbbaf0a899d059202edbfa69353b957a393365cf69ca8ec9b355d7dad0614e36', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0074', 'aa37ea1e4b3ffc06cd39d0aeb94b29756469196827cc73a049d1d5aaa02974bc', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0077', 'd09127af7c7c3fab10d529b0868b06f21967a01a08438de9e959d016d9d260b1', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0078', '07251bfa2463b9815c302d75fd3d75eaa0b32710708cc5574cda530054ad52e3', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0079', '5e9d6b22de23daa74ade9f74daead3984175fc3c173ac1f76c6f3b6da4650eec', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0080', '6283274fcfb9b27859f62217a3122583d5125da3153f8a0dce2c5155017a4298', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0082', 'c544d93960617e4d7311e28e556ab77aa8f62f144d89680cb9d78f109edf58d3', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0083', 'b2c01466b0c489dd274cb494eb8bee136c757aa738321f2490a01ea2fe5bff5f', 'segment_a1_14_payment_delivery', 'b68383b7804a5f01b2cdef5b7742fb4e077bad2bb7016849b76baaab9d466df5', 'approved', 2),
    ('smalltalk_a1_0084', '7e0f1d7b0fd71b43221ccbec8d40cbcfe67438db5435fbc8f32ad0648a49092f', 'segment_a1_14_payment_delivery', 'b68383b7804a5f01b2cdef5b7742fb4e077bad2bb7016849b76baaab9d466df5', 'approved', 2),
    ('smalltalk_a1_0085', 'cf974cd2f2b6d732b885e5dd13d0b576c5bb2bec192be08cfabc23410d2aca1a', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0086', '17e10fcfca224198cae0189c1c611e81a8716f4f40d298c2d5d2bc645de97e7e', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0087', 'be5c098564b6d10b4842462f37db8bd86ff0b5d7d04509dd683b316ff5a8affa', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0088', 'f99f21b30a114883b1dcb53ddf908ce2d0684e4990f34c141622de0f2fab9688', 'segment_a1_05_numbers_time', '1de22a8006c64cfedc64054d6b25fcefbbdd9e97fd7ab0dbbdb9b5f1c0c00fba', 'approved', 2),
    ('smalltalk_a1_0089', '578acf2f8cc4684af0d05e5865bade5cb2abbeefaf9f2da372a94abf0e52ba1a', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0090', 'e0ec98c677d90ca5bfeb53226621f951f02f3a255ae347736f8cd10d80be4cb3', 'segment_a1_12_daily_negation', 'fbea0f8682214cf2ea2c2d029ca3522039241f46111ce026233ae8f5a6d42658', 'approved', 2),
    ('smalltalk_a1_0091', 'b87433dde6613d7a0ff773e510004a59d2ab6e971e658f8a8631c455129cdcf5', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0092', 'a9374e6cc3294ca51233df3e6be4351d226370f7a90f45e8019ccdffc180e652', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0093', '77cba50b5e94c3cd78ae83438fc4d88bf08a5c0a2282a1fb2c34cc8024123dad', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0094', '0e0670eb8f51107fdde0c76fa3bbd0352191c3d36859555fcd04c69d10ecc69d', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0095', 'cc3e7a02ecde78ddc395025cdfb7e35792acced390ec25343d93a5db83eefbdb', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0096', 'ccc7b2557b51adb1b8f46a1d773b7822ac9bcbef020eb6f4fb69c8e85123ed51', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0097', 'e451b06be52de4ba17e2c234f2cd5e287f0a1de4e730bf4310681ae317fc280b', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0098', 'f70bfcf99cdbcfdb50e899ddfea62b07dec64a10507293f0a96a920df0c97ded', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0099', '9f2cfd9a0a17a9147c5f824f55081c0a94081a952c6e09ff3a24231164a7c244', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0100', '2c410fe792c0a08d7c8ca88d300c9ec858d8277ccdf46834fc4171df6ece2208', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a2_0002', 'f92f9d0c78608b409f3a52c568fca335c6fcf00a050efae1fd35fd18a3726eec', 'segment_a2_feeling_sick', 'c063f6602f0aa7dac6d1128268a6820c655feb8b2f1a40edc1c3bc3aadae5f12', 'approved', 3),
    ('smalltalk_a2_0003', '7e00aee1886b9f4eb47d6affb86b842bec43a4bd6bb479cc8d516ff8616f3db5', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 3),
    ('smalltalk_a2_0004', '01c15d7e3b7cb35055086e8c326e14dbdfbe01f8a7b9ce30f308763604e94543', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 3),
    ('smalltalk_a2_0006', '0e212b5fbf9f425dd1a726c002495877d08d094f16b453cf6fea553af15e31a2', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0007', '745447b9f9443191d8f627eed514a8c8af64ff1fb4be441e70c334122f2441a0', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0008', '1b072620aae176156fb482b364cd8b19f45745af75fae64904775b859747e283', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0009', '65575cf35a4cde928d99d515b2d08d4d148a285f7cc11b5e14c8a397451d804c', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0011', 'c56a2d39927fae7302b1266eebc234f01318e31f3351e672f7526e73ced66917', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0012', '19d506b2ae68ae43e8ade2b7f7c66a185b28934fd3fff8f6b46d05b493162f85', 'segment_a2_gym_signup', '673649c1ca92c9e09d766f7f3b3f090ccbace9fac3a2db43f91fa20e679667d1', 'approved', 3),
    ('smalltalk_a2_0013', '3be35be9fcb7cbf7af034555e351d177df396006240ee12f035204c4bc14042c', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0014', '178d6407e8f3c8be0a44df9c085ab81a34d9bb19a1a864380bd6f0bb4f92d4e6', 'segment_a2_feeling_sick', 'c063f6602f0aa7dac6d1128268a6820c655feb8b2f1a40edc1c3bc3aadae5f12', 'approved', 3),
    ('smalltalk_a2_0017', '71fc72d6abdc6ef33a7c8a9bc65d4da78d85c6cf4f5f72091915addab08f4b62', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0018', '6fbb525cfa17576e95ed8b605aace69518cdf4d15f4556fdde97e3d2726f1c32', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0019', '7be498002442d94d2d5afd3bd6dd433aa8e6a746509c9bdf8f3e5d13533b81d1', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0020', 'd3429e7081c9f89306feebc024692971acdc878c37b4efc8abdedd9e9d8b299c', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0021', 'c5c3131bea54b2222696eba3e07c34d10f08128e6c0c65db801ca2e1b240482c', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0022', '718e36632fead91810f58fb170b7618d57cd070ded9b32e1d1181e3ff04a6ddc', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 3),
    ('smalltalk_a2_0024', 'e52ff80eb918bf64c03c51ed23a34fd3983574e3cef34cc93007d4679b7a38e8', 'segment_a2_feeling_sick', 'c063f6602f0aa7dac6d1128268a6820c655feb8b2f1a40edc1c3bc3aadae5f12', 'approved', 2),
    ('smalltalk_a2_0025', '270d112e0095a3fc4877c876218c1184e678550d0b712392a8981cea57b367fe', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0027', '3da3f3801f9ce86c2e24f02be523d2a37c10b5474b7948b7e15bf490f9aec7d2', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0028', 'b6938dddc20431e7118d8a53b179f35d7459d6de43462a4d7bc5c5c58536c3f7', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0033', '3a2cd93c5c413a88a57f245f7ce853369f8bd29e059ed2b58b65156c445c66fb', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 2),
    ('smalltalk_a2_0034', '9d7308ed1ac715e7f7de0c830de23a8bfbe8b424e80f597bb29d2f39ed97895c', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 2),
    ('smalltalk_a2_0035', 'a91fbe66f50f433a625c6a5f0465ca6229d1cd8a024c4686d04fc78b28226bd6', 'segment_a2_pharmacy_headache', 'd81c0c13ce917cdea14a5b791888382b3f6573102a97609e99e280ad800f0817', 'approved', 2),
    ('smalltalk_a2_0036', 'e020b1b2f1f1afa7e5b4248f8580da905549af89816b4c00f8ff8a1a5b5a278a', 'segment_a2_pharmacy_headache', 'd81c0c13ce917cdea14a5b791888382b3f6573102a97609e99e280ad800f0817', 'approved', 2),
    ('smalltalk_a2_0037', '7e5566e9cf5c377ee09881eb1f4152a456eebcb93fc5d99219879ac42ddf9112', 'segment_a2_subway_directions', '7c4a12d5fadd31dcc1df848d07151ba0de412e98ab038833387297225ca65931', 'approved', 2),
    ('smalltalk_a2_0038', '71eb8227d3f88b44f6a5ebfdd1fb89d07d5924faecc51e07e5c234ed0662fc72', 'segment_a2_subway_transfer', '454dd11389ccb0c32e45d33206fe01b5b47febc3a460f971e643743bcc4ab916', 'approved', 3),
    ('smalltalk_a2_0039', '19e1670fcf2e163e41efb67572e0db2130963631bc7da275ddfc61132b3e885e', 'segment_a2_subway_directions', '7c4a12d5fadd31dcc1df848d07151ba0de412e98ab038833387297225ca65931', 'approved', 2),
    ('smalltalk_a2_0040', '995e653629a11086033d0ff4aa1ce59555ab0096826ce37c3b1e540a52d7904f', 'segment_a2_taxi_street', '47133178b1c055bdf21f2bc83e853b77df7c5ba6c7e46ca70754df80baa1d6ea', 'approved', 3),
    ('smalltalk_a2_0041', '59df51422fa8628ca8c1b1e764813450fce6445d2cd13e65ade99533a2bc08ed', 'segment_a2_taxi_street', '47133178b1c055bdf21f2bc83e853b77df7c5ba6c7e46ca70754df80baa1d6ea', 'approved', 3),
    ('smalltalk_a2_0042', 'eee57b846c53fb9aeedf1fea21ad643d35db4b4758247cf1e2ec48f71d27868a', 'segment_a2_ktx_ticket', 'afdf8dfd33b5c441510d4221f75ca05adc579d14c8c49ee1681d9935065e87b8', 'approved', 3),
    ('smalltalk_a2_0044', 'e2db6270ae51c8db48ba7f3ee5d7d5e1ac148cd0d6d161edc3a2a37c23ccc394', 'segment_a2_myeongdong_shopping', 'c82ee1b27476bd9d495fa5e42b09f7739c3b7fa4ddf084734003a8d0504cb064', 'approved', 2),
    ('smalltalk_a2_0045', '012919e2d367e0c6c3d2f75d946c3b253978883e93b65f630a42616ac20ca73e', 'segment_a2_myeongdong_shopping', 'c82ee1b27476bd9d495fa5e42b09f7739c3b7fa4ddf084734003a8d0504cb064', 'approved', 2),
    ('smalltalk_a2_0046', 'c5a509603a826c9945ec436f353f41eafe99cd86cedbf5fb2173439302f5507b', 'segment_a2_myeongdong_shopping', 'c82ee1b27476bd9d495fa5e42b09f7739c3b7fa4ddf084734003a8d0504cb064', 'approved', 2),
    ('smalltalk_a2_0047', 'ba2a78f09ec1d23f66c6bc3109b744591b3b60cd7617fc3f2a5fe5046ae9f308', 'segment_a2_myeongdong_shopping', 'c82ee1b27476bd9d495fa5e42b09f7739c3b7fa4ddf084734003a8d0504cb064', 'approved', 2),
    ('smalltalk_a2_0048', '11b40d85e848f7af5d2c9474a77a3844f2334a5e28c7bb9dd50d2aa9f5bffdf9', 'segment_a2_myeongdong_shopping', 'c82ee1b27476bd9d495fa5e42b09f7739c3b7fa4ddf084734003a8d0504cb064', 'approved', 2),
    ('smalltalk_a2_0052', 'dc98c366b9d9290e7920675af56597e346206af104f17dd55872272d3ff4ed58', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 2),
    ('smalltalk_a2_0056', 'c4f9d8050d73dc3500018d6787d2831c9e7396c94737993b190f9dd115e0f996', 'segment_a2_cafe_starbucks_basic', '23de0a68ee5e7803e95b6fbe7ee50cddd6fa66cf56a7b8feac41f1d8f430bd8c', 'approved', 2),
    ('smalltalk_a2_0057', '789a9ce465ef77e3e106a0f404b535032ed560b744d75087e9881f196f7fd92f', 'segment_a2_cafe_starbucks_basic', '23de0a68ee5e7803e95b6fbe7ee50cddd6fa66cf56a7b8feac41f1d8f430bd8c', 'approved', 2),
    ('smalltalk_a2_0058', '77ad168ef73886297c66e6b0e76e92ba869f9c8bd45c7352c0bc0b91edd1df79', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0059', 'cbcd214df4f40c327fc7b1e6e7fe64a493638b300dd5fbeb0037f29ea6801ff4', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0060', 'fc80d41205da48f1db1b17a2be3cd0885f7c5f90b0783fe0fbeb5c88b4d2b4f8', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0061', '3b2a02b5e508b7f599f4bc277a7b4263d8bf672e9a03c7b2b1a3acc035fe9795', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0063', '85b3f05c829727ce9e4293b5669fe10f73dc8db557e7c649f246db8611d28dc2', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0064', 'b835e8d835c375cf023fb4d70823fbccf1ab41134d1b75e67f7e0ca508883519', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0065', '4e8ac453afa50fa2ab2b9994a0f06e150998795aad388e94854d915ad7b23948', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0067', 'e17a16c91ec0cf61acab06a2f598979c9ce04f389470ff5b1ba7769aae720f47', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0069', 'c168ce2920a04dc081325efeaa57e859ba0e1c264d62d4b5d0549cbf4e535d3e', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0070', '1ad99bac2fcdbb0fcfb945bdf3a9e02658bc5176865d1e21a7ceeecd9fb10546', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0072', '9e06834b9907fbe1ecb3e726bca21af18b752f79e7e539b86c556b913b1f15d1', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0073', '7a874861240db7f0c301964f334a8e48a4ae64c30154880b7522195417a14f85', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0075', '73c27bd3105e8da5f9a3a0828aecd6095d7df6f93288432fa4b4df46a4da1219', 'segment_a2_feeling_sick', 'c063f6602f0aa7dac6d1128268a6820c655feb8b2f1a40edc1c3bc3aadae5f12', 'approved', 2),
    ('smalltalk_a2_0076', '64f181f5b51375b05ba0384497c8a2cadc0a3a78b6a95ae7dfa5849b984bb629', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0077', 'f71aa47c63ef2fad2090527b24ff16021ef8f4476698cb4b9545644b9d1d930c', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0078', '75b5aec219c07c1c64c2d01e5adf3c2a708c5409f323853f0eb49772dd7f62cb', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 2),
    ('smalltalk_a2_0079', 'a6fa27d5870ff1c4999fb2371d51750a7981648de740a787e9f795c9bfb2fb47', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 2),
    ('smalltalk_a2_0080', 'c5f20249ab6a9213c28e0ca188b415809eef0c861ba89097846188fc54dcfe9e', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 2),
    ('smalltalk_a2_0081', 'e8525f906dd6610ca98877fa0256920a7bd6ae086e8004c011533418661be8bf', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 2),
    ('smalltalk_a2_0082', 'b51af6c8ae1aa660a600f1c8fc318ef1ba51696994d2e42ed0f9900bafa0c2d5', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 2),
    ('smalltalk_a2_0083', '7b540833d55b3c63412405759fb39b12fbba9fe55d79633d4be58a0288157d5c', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 2),
    ('smalltalk_a2_0084', 'ba859ae48fece78f8886fc169314e1f15a5e0234b2633f50f74266d0b40cac8e', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 2),
    ('smalltalk_a2_0085', '1fc43f0de62a589b0b411fe613900fec43897b9626cdb12e01edc4052086f6f0', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 2),
    ('smalltalk_a2_0086', 'fd56ccbbabc52e1f19a85ed1fd179dd4307c5a05528d9bd91f579f7888649064', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 2),
    ('smalltalk_a2_0087', 'ad795ef7f54ef83010a38f7a2b29325e451bd9e1485963b2044beec8040c360a', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 2),
    ('smalltalk_a2_0088', '21afbd0d67fc43a077eb0845de02be8a764d7dd0fd27be99b9499eed72231b2b', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 2),
    ('smalltalk_a2_0089', 'cb9ebeb79fcb574965816120dedf3a770d469d6daac37fc081b6612ced5b18bf', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 2),
    ('smalltalk_a2_0090', 'b6cf9af269ee6c744ffab19128fede370129fd305d89a7632589f6583622f0fd', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0091', '46c683b7bf9a3288b2129884fcda762dbfbb03def957f1f032616ef99be09082', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 2),
    ('smalltalk_a2_0092', '1c6e9b4796bdfa577710def6eec671430d52ffc4879240598b36d38637ac36ee', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 2),
    ('smalltalk_a2_0093', 'cb81a45832e150030ae770cf67d4f933420f4c3641820197cdc43b13ab932c8f', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 2),
    ('smalltalk_b1_0001', 'b6f63c294e5d8fdfb10838b4ea950be095b73c10585100720272ffb843aa1cc0', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 2),
    ('smalltalk_b1_0003', '766664b603e12af48084b8d95848192bb711ea99361f1fe1c653756eeeb2f3ec', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 2),
    ('smalltalk_b1_0005', '7b0cb30a54df6e5c89c16aaaf70bfe44b553afaedc1e3655ea4767805f770f2a', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 2),
    ('smalltalk_b1_0007', 'e3dd56745af1d9a9fa82e3b5d5c7e294778de697a941c314067861ceb64c71b2', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 2),
    ('smalltalk_b1_0008', '5163656093db9befdd7d5b00c15de1f9854ca5b08b267976eb2a4103eea3fc91', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 2),
    ('smalltalk_b1_0010', '9dd25467a03a03dd3f8365317c8d25d3bc35986d3f52114307661c537843e5cf', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 2),
    ('smalltalk_b1_0011', '89bb6145a1d313709eb38b94ea43530c75c1be50e9c98c67caabbb9fd15a3cab', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 2),
    ('smalltalk_b1_0012', '1e0a0aff8b052b00592878b3c0e817ff32a252cf44df4df1bc1b21b44067343d', 'segment_b1_safety_health_concern', '2ed9f0133a5f86a4d1bf1df1611f4bf9f815e57d41c114b791464a380772edce', 'approved', 2),
    ('smalltalk_b1_0013', 'd26cf8784ac70387d55a89bafbf3b08456b75f229945fc4c0d7616000d39522b', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 2),
    ('smalltalk_b1_0014', '8505548cd589a1af4c66873b6a4b90ad9b4bc8d2427b19a6fd7095090eeccf10', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 2),
    ('smalltalk_b1_0015', '10a556c72108418570bc03fea3ce91c82a16596a60d51db7214b05db04a95ddd', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 2),
    ('smalltalk_b1_0017', '7803c403af02b96f89db143748b5f1cdd3c9c29ac32f13de1608eaa9adc2ce9a', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 2),
    ('smalltalk_b1_0019', '63bc4903fc721f01c52bcb460f5fc15bd1d6c47cd10919eb4c337059c9955926', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 2),
    ('smalltalk_b1_0020', 'aea9c84e2e8cda533214b6f0b2d4cbc044c87f49b8b891ce42c54eb787c7482c', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 2),
    ('smalltalk_b1_0022', 'bfb65891b02629378d4913019b3bbffad9e48b5fad8452d73c8cd1cdc8f7a322', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 2),
    ('smalltalk_b1_0023', 'ebc4b1a93286af51cfbea3f45d4469d88f3c74137e34f8acfc6d182b6bc19e53', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 2),
    ('smalltalk_b1_0024', '3c680135ae47c8e584a191e8adad4b781b9fb7eb91a85ba81ed47cdcb52bf0b9', 'segment_b1_safety_health_concern', '2ed9f0133a5f86a4d1bf1df1611f4bf9f815e57d41c114b791464a380772edce', 'approved', 2),
    ('smalltalk_b1_0026', 'df84fce03b7827bf8485cc03e65dd4984cf5725da7e1722d51c801c6d61a8dcd', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 2),
    ('smalltalk_b1_0027', 'f086fe38c5460bdd6bf7e720437e65c5fb4b7a0cd6aca079f3fb9ef53abc644d', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 2),
    ('smalltalk_b1_0028', '9488df2c49670251f053b9d6a455e65990ea400b73733aaaff44bc87588a70c3', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 2),
    ('smalltalk_b1_0031', '99fb9f930239728d3c549ddc138676c752c35d7294b65714c517d65c157d4b12', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 2),
    ('smalltalk_b1_0032', 'c4128122d0d79ccdd1a3db8976c5c55b925ebff1d493b1a40da3e8a00abde576', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 2),
    ('smalltalk_b1_0033', '59ec3cc9136a0ff03cb6395eb03e5723ab3d21b41e2ccbb603085efbe7d8b4c8', 'segment_b1_move_in_handover', '41d09f057199e28cb40b8d1ef7b316b90e09878265954771505b511812c34bd3', 'approved', 3),
    ('smalltalk_b1_0034', 'ebfc309930b7e69c33697cc38e3651a3c3f16925769b9f011529051bfd28c97d', 'segment_b1_housing_contract', 'cd68a24c4f45c05c8aa7cfd585ef181dc2ed59d76a5ca72336c0fbf42a171657', 'approved', 3),
    ('smalltalk_b1_0035', '890a40b461c6939675e5dc98ad9634f65bcb6aac4906e40d026bf77d872d821c', 'segment_b1_safety_health_concern', '2ed9f0133a5f86a4d1bf1df1611f4bf9f815e57d41c114b791464a380772edce', 'approved', 2),
    ('smalltalk_b1_0036', '7ebd7d0cbb4d0d174c2e8d82534777f7c1c5246f26355860974e3a46324a6ba6', 'segment_b1_safety_health_concern', '2ed9f0133a5f86a4d1bf1df1611f4bf9f815e57d41c114b791464a380772edce', 'approved', 2),
    ('smalltalk_b1_0039', '9d50707e4e11b0c69cf6aab53009839b8ed4bcd77c1ecf21769896e350be24db', 'segment_b1_delivery_resolution', '32efb35084bd7bef92f1edfd1d960b491080de65489d990e21ea9f951edd3219', 'approved', 2),
    ('smalltalk_b1_0040', '9097803715319929e3d4b8970f0fd3bba135d49ab5e777657019ba0d7e4c802c', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 3),
    ('smalltalk_b1_0041', '579f0e67b05faac3b1216b479a67769a3def8865e70df15e862c8f35bf00934b', 'segment_b1_schedule_softening', '754bc847f466e74fee41377c380159eb59fb8407c1e79a90b005609bfad45471', 'approved', 3),
    ('smalltalk_b1_0042', 'b9d0b274e66052e7f1dc6847dc99f8be68ab40d3d6b3744a2fd501bb61d8f7dd', 'segment_b1_relay_social_speech', 'f4ed8eb70ae95eec3a61c4245ad3ffc14ec9c6ebbc6ca1a38e8aa8de538528f4', 'approved', 3),
    ('smalltalk_b1_0043', 'deaba2cbf4b7ba2435cff0ac0b6260895a44c6b074b7b44f2a1cde109ec7d098', 'segment_b1_property_damage_report', '4be1c31b7e3d878fc9ff6a172e71388046eecd8ebdbdff40c59840c890f3d95c', 'approved', 3),
    ('smalltalk_b1_0044', '9cc71a84eb4c35c866947db678f885093d03bf1ea67db5b1f230128fb49cddb2', 'segment_b1_safety_health_concern', '2ed9f0133a5f86a4d1bf1df1611f4bf9f815e57d41c114b791464a380772edce', 'approved', 2),
    ('smalltalk_b1_0045', '42f780c01e566f0d5bcdad91d9e1d5e18b3d6b5b4bebc56de06537694223a663', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0046', '77132e2a99351f508e8c00c9209f8e3063db71db2bce41ae01b5f2b7b0648a02', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0047', 'afd20d62046b0945d774b73cb715cd48583a83b73329ebec78d9cc14429f70fc', 'segment_b1_schedule_softening', '754bc847f466e74fee41377c380159eb59fb8407c1e79a90b005609bfad45471', 'approved', 3),
    ('smalltalk_b1_0048', 'edd8dd83baab2949abf470363b1d3e913bd51bc1b11de77a314f7d451e271e7c', 'segment_b1_schedule_softening', '754bc847f466e74fee41377c380159eb59fb8407c1e79a90b005609bfad45471', 'approved', 3),
    ('smalltalk_b1_0049', 'd5a71e4a0294ce0f1db218b542f397d999c7662e8f2fb60d5bc1c20956f0f576', 'segment_b1_attendance_and_coverage', '60056aaa67f38f8bebdec4f8b2dce821101ccb5ad19a01d3b03322996167b258', 'approved', 3),
    ('smalltalk_b1_0050', '4296a26e62b57f2cca3829510930f602502ef91b9467f211265eb5ec4d5527aa', 'segment_b1_attendance_and_coverage', '60056aaa67f38f8bebdec4f8b2dce821101ccb5ad19a01d3b03322996167b258', 'approved', 3),
    ('smalltalk_b1_0051', '6c6f6067ae53bca8d359b034324deb55846eccad05bcd5d9540d1713f2fd05a5', 'segment_b1_attendance_and_coverage', '60056aaa67f38f8bebdec4f8b2dce821101ccb5ad19a01d3b03322996167b258', 'approved', 3),
    ('smalltalk_b1_0052', '37beb2cd681e7ade3dbfbaf6c6d597a0b7917877facefa6a78da09f2ef3e2fe8', 'segment_b1_attendance_and_coverage', '60056aaa67f38f8bebdec4f8b2dce821101ccb5ad19a01d3b03322996167b258', 'approved', 3),
    ('smalltalk_b1_0053', 'ecf9da40dc1ada9342d68f8aba22bd7a35c25c2ecb893d9dce7a0108ec08b70a', 'segment_b1_property_damage_report', '4be1c31b7e3d878fc9ff6a172e71388046eecd8ebdbdff40c59840c890f3d95c', 'approved', 2),
    ('smalltalk_b1_0054', 'ed3281284913374f6176e46d9a02c2f625c8ed3527e2d5fc25b06ea6cee498ca', 'segment_b1_property_damage_report', '4be1c31b7e3d878fc9ff6a172e71388046eecd8ebdbdff40c59840c890f3d95c', 'approved', 2),
    ('smalltalk_b1_0055', 'bda3da2a4702adca217474ac505c676ef4a49b799f7237ed8eae487c0d7e51f7', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0056', '9dca3536ab0a9d052f6f23682820d9f4795720ac73e1e4c1176ee409d53977bf', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0058', 'c9e5fd28646a107235d47257d43e2bb94c6c2fc2d49f59abc91b7c5a0c1289b3', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0059', 'bcd7d4baddeb667ec4aaf0e4b88e54f6567bbd4cad324ddf221197bfa6db5b1f', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0060', '6998c169c346495ea5b6008ac2a0ab81cfea4013b0cef65fdfd225bce9c88b92', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0061', 'b72a6dce32e13262dc233443b40d995556dfe9651b4bc1c7d410784ff7e016bb', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0062', '3941747fd82c88b319a965df12d508bc967bf5108a13582e825f7f1ed55d4a9b', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0063', 'eac369d404f902ba4750b61e0f77ca9f5ae0049291c4926eda5ab422f60e32ce', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0064', '762fe5611e60b86ed67515bc1d29896000b3f68c49ef50ac86d3aece7ad69c38', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0065', 'f0256ba1e529f8d47f0f61a9dfd11986edf4bef65fc7c0a1e8875f628763dfab', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0067', '67c727b68c0a50995e2b8fd8cbbf8247b4ef0dfee789773d21f4924a6c2f38f5', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0069', '443fa17b7d7c1df268fcd226ffd0abea0a69d516545fa5c835cd53eb071cbf88', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0070', '99a2de3887ae48f08df7c7005b1ea3d27509a65539f7cf43a766a8c3aedaa1ed', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0072', '38f407574f4afc1426c4818777fc3c28abdc5b70a158ab67ecdf2ee230b7aaba', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 2),
    ('smalltalk_b1_0073', '059f7baf79d87307fca40b342d7b7b1d73196d024a708f05bbc7ee8ffe1b64d2', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 2),
    ('smalltalk_b1_0074', '1863b0544bc45c0a2ff4b8ee82704749e36802bd65f7c6947a56a2ec21f4cabf', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 2),
    ('smalltalk_b1_0075', 'd6f81fd25530afb5879949aa879ae8c13bc2d7e07c71c9917f30abe261e1bc0a', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 2),
    ('smalltalk_b1_0076', 'da7465c2af96ca27c28f5be9ef1de2520f5e2a3b7fa46ca24deb7e4bcf1abf0a', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 2),
    ('smalltalk_b1_0077', '2da6ddd1dc89d5b817a36adb6779e93a766ec98553ebebbfad4f39b473bd870f', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 2),
    ('smalltalk_b1_0078', 'dcb5641473e107c86516cad605c1060d9be8ac22c37b8131986d2ec02ffc19bb', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 2),
    ('smalltalk_b1_0079', '697db0071e71f311b5aa792c768431207dc07a3d7bcbe963cf87ee704850a670', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 2),
    ('smalltalk_b1_0080', 'da150032a46c40b47612aa8000463ce5151407040fb269185bbcaaa54f6298f0', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 2),
    ('smalltalk_b1_0081', '35f373aba5bd41b164edfa95e7164657e43ca517843074c674f74a8a537911a9', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 2),
    ('smalltalk_b1_0082', 'e75915a8705228203cfcf92be89b7dd7fa913bb40ae2cc6a1e0e93d7e3e66d26', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0083', '3ba118106084a7c16be955d47c35bcb093fbf59d03caf6ec32ea328924e52cb3', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 2),
    ('smalltalk_b1_0084', 'fb4b7a549061fa035bb76cbaac21022e1433114b0878aa275b28262a093f975d', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 2),
    ('smalltalk_b1_0085', '9599563d4cc32a96831e66f01aef8b6c2c10966c2f449ed37a4955fe28d66fae', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 2),
    ('smalltalk_b1_0086', 'c82bf4dd37ce2c046ad800214ee403e930f50cd5140536d80cc0e7a381c6e023', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 2),
    ('smalltalk_b1_0087', 'b91e8824d7b8b6571a30761982dc5e22434bd136fe655cd4aeb721ad520f484a', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 2),
    ('smalltalk_b1_0088', '387b337cb554c9e7de07c278cd457a1b2bfba3990ce65de19eef57282d60fd5e', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 2),
    ('smalltalk_b2_0006', '987577d842ea86c75624fc9d338f7dea126dbfd588c48d2607a4588a9295fe24', 'segment_b2_literary_cultural_response', 'e99e9cacd4a66254c25cfb6957e52f6322313a7b1872d518f7b3601aa4b59409', 'approved', 2),
    ('smalltalk_b2_0012', '2a69e39068986705bebb2b8389b77112889afb07a6f69c958b0a75a689c1d6a3', 'segment_b2_medical_precision', 'a332c22528aebe7aafe4a2ea629c45ba832f52a5105e97d5654faa7874caf20b', 'approved', 2),
    ('smalltalk_b2_0018', '11ec60beab121ebcfa7ef39fe8fa5f50b466287198a44052f7008a5a60f5271b', 'segment_b2_literary_cultural_response', 'e99e9cacd4a66254c25cfb6957e52f6322313a7b1872d518f7b3601aa4b59409', 'approved', 2),
    ('smalltalk_b2_0019', '291cd8193ad71c40b99d83dec84482bc243a17a72f08bc03fb7ed3394806219f', 'segment_b2_literary_cultural_response', 'e99e9cacd4a66254c25cfb6957e52f6322313a7b1872d518f7b3601aa4b59409', 'approved', 2),
    ('smalltalk_b2_0024', '24928b35ae1f6a6d85c81da48e3731a520761b1e5ad3cf97d67a09974c6abca2', 'segment_b2_medical_precision', 'a332c22528aebe7aafe4a2ea629c45ba832f52a5105e97d5654faa7874caf20b', 'approved', 2),
    ('smalltalk_b2_0026', '7a7ecceefe7f867787d735a81387acfaf811d3ebb076303fa1d2b3b6c59ad809', 'segment_b2_literary_cultural_response', 'e99e9cacd4a66254c25cfb6957e52f6322313a7b1872d518f7b3601aa4b59409', 'approved', 2),
    ('smalltalk_b2_0029', '7efb98331bf4fbd74f28277e33a5664104bfed811a0a1c0b38750d99c9d2312a', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 2),
    ('smalltalk_b2_0030', '8b5bb5ba3826ae27cf5b1219dc8b92e3e0d93bde380720bcdf6f7a9bf41d1349', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 2),
    ('smalltalk_b2_0031', '2136af6a59fecea4a1ab0092a9cb53aaca2e83fc27edb859c8cf335d8819d4a1', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 2),
    ('smalltalk_b2_0032', 'e3ce109a2ca709ccfe248dfdaf54b7d5e64fe3f7870937668ac49d2eb740145e', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 2),
    ('smalltalk_b2_0034', '344626fda15db834795adfcc6ffdb2e2080634c714b0e2fc5ada828256b78936', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0035', '3e71d4f41e77ae174a84799bd49e77de6ea4ac8fafa58a22f7582d7189a368e8', 'segment_b2_medical_precision', 'a332c22528aebe7aafe4a2ea629c45ba832f52a5105e97d5654faa7874caf20b', 'approved', 2),
    ('smalltalk_b2_0036', '17e941166f2106abeb02500626553f3edf2802ae0670aba762c1794fe83b53fe', 'segment_b2_medical_precision', 'a332c22528aebe7aafe4a2ea629c45ba832f52a5105e97d5654faa7874caf20b', 'approved', 2),
    ('smalltalk_b2_0037', '71ee60d5b0d0d860ea1fb2ed685e5fd8753bdedc9b73ecfd3a1d95f39fef2f8e', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0038', 'fab76cb64c3eb9b0b7305f24ffb7e15435a7ed5fb1afe2bedf0476c7844135be', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0039', '6c487bb749f8571a05850a14e19d109130dcce9a8cb993c8fe3fc0ac68d67c79', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0040', '71a3cd66ddc0d0852547faf605ebfd0b45ebf5e7977fc58b041f8de236948db8', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0041', '7afd9504b2e6154a93c075dcb0c5883d726780ff97ee83424331ccfd37842940', 'segment_b2_formal_meeting_opening', '26da06c8bde1f79fe7d103fdf51970fe17f776764bf512ebb8601e2899f907e8', 'approved', 2),
    ('smalltalk_b2_0042', 'cbd35f5ae8f5477d91fc2ac688813a41c543dfbf5ebc26cbecc0a308eab324f6', 'segment_b2_formal_meeting_opening', '26da06c8bde1f79fe7d103fdf51970fe17f776764bf512ebb8601e2899f907e8', 'approved', 2),
    ('smalltalk_b2_0045', '22d08a2a7b4ee26614e47340aba286a341ae734285bbb720bb83bf8fdb491692', 'segment_b2_formal_complaint', 'f83ca7b01f47d33f052ccabef5b2d386fec7ce96c730da586c71076316b27dda', 'approved', 3),
    ('smalltalk_b2_0046', '3f9ae81b33f468eb413352cd918f35e7be029991ac23aabbe064080818f17588', 'segment_b2_formal_complaint', 'f83ca7b01f47d33f052ccabef5b2d386fec7ce96c730da586c71076316b27dda', 'approved', 3),
    ('smalltalk_b2_0047', 'fdfa9cee7ad1d16c6ee7523cb7e72cf073fc07d2cce65e83f05566fbf80bf06d', 'segment_b2_remedy_and_appeal', 'a1be69870db12624788b3f2de3d2d0e7f9f8a1fa0b9f1578f8e866c55cbcdf9a', 'approved', 3),
    ('smalltalk_b2_0048', 'ed1b8542d2d24e92556db624110b1b1d3d0b28a1be99c3568de80dd822d85dee', 'segment_b2_remedy_and_appeal', 'a1be69870db12624788b3f2de3d2d0e7f9f8a1fa0b9f1578f8e866c55cbcdf9a', 'approved', 3),
    ('smalltalk_b2_0049', 'b725bdd608d02d4e7557ff50c6f27a84b84327b074130af41ad72f82ac2d955d', 'segment_b2_remedy_and_appeal', 'a1be69870db12624788b3f2de3d2d0e7f9f8a1fa0b9f1578f8e866c55cbcdf9a', 'approved', 3),
    ('smalltalk_b2_0050', 'b7596ebd509fe33f4c7625fde3cebdac095c78874c2e17238dddd69c4f163c61', 'segment_b2_remedy_and_appeal', 'a1be69870db12624788b3f2de3d2d0e7f9f8a1fa0b9f1578f8e866c55cbcdf9a', 'approved', 3),
    ('smalltalk_b2_0051', 'f6197cd9e3a84fd95f0ace4c14eb1200e7b7b671c19530a3bb992f7e671a3dc1', 'segment_b2_remedy_and_appeal', 'a1be69870db12624788b3f2de3d2d0e7f9f8a1fa0b9f1578f8e866c55cbcdf9a', 'approved', 3),
    ('smalltalk_b2_0052', 'c7173134c6b9c1cde906bedd01fdf1226b2ff6161c4375f8a7a396db058dcc77', 'segment_b2_remedy_and_appeal', 'a1be69870db12624788b3f2de3d2d0e7f9f8a1fa0b9f1578f8e866c55cbcdf9a', 'approved', 3),
    ('smalltalk_b2_0053', '3f88e9359bf9c09602e164cbcc49d7172ae332607da1cf941d4412e802bafab6', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0054', 'fdfc812475bf1e0d9fd1fc2e8d5bfae6783a2bd6bd2c3b18b4732f9572ba7422', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0055', '82c39adb7f16f1043eb8abeb2bfd950b5d5088a57c138e333141f06aa4a10e64', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0056', '820853a4ade44a79d4f7a9e3a084d07b3d7ea739e46cd8578fb923a87e8a7014', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0057', 'c5870824dbfe208debd0a2838149c268a18ac927c1eace8fb9c5d02ff8ecada4', 'segment_b2_literary_cultural_response', 'e99e9cacd4a66254c25cfb6957e52f6322313a7b1872d518f7b3601aa4b59409', 'approved', 3),
    ('smalltalk_b2_0058', 'b176b0c480d0066758f62684a7bc1e9ba79c668be5880310bfa6a0916d5f3706', 'segment_b2_literary_cultural_response', 'e99e9cacd4a66254c25cfb6957e52f6322313a7b1872d518f7b3601aa4b59409', 'approved', 3),
    ('smalltalk_b2_0059', '9c99657a18dc7fb5ff1cfd25fa19e834808d1f700450122af90c03d07a8dca13', 'segment_b2_literary_cultural_response', 'e99e9cacd4a66254c25cfb6957e52f6322313a7b1872d518f7b3601aa4b59409', 'approved', 3),
    ('smalltalk_b2_0060', '788a165294438a402f944a1c387341e9111a29f50ada5254e055dd4f486ffbb7', 'segment_b2_literary_cultural_response', 'e99e9cacd4a66254c25cfb6957e52f6322313a7b1872d518f7b3601aa4b59409', 'approved', 3),
    ('smalltalk_b2_0072', '80f9b6d1de270d8d67283f6df7caab069f68d9f131202a45326912ad2945b5fb', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0081', '2c7f653b5bfabbd8ce9c94b5038d24dc7a78b5d277c169d3952f56e9943be800', 'segment_b2_remedy_and_appeal', 'a1be69870db12624788b3f2de3d2d0e7f9f8a1fa0b9f1578f8e866c55cbcdf9a', 'approved', 2),
    ('smalltalk_b2_0082', 'e27dc5bacde1ca5418de701e3152b54490e0d7c7f09db2cc49cab6e9281d8575', 'segment_b2_remedy_and_appeal', 'a1be69870db12624788b3f2de3d2d0e7f9f8a1fa0b9f1578f8e866c55cbcdf9a', 'approved', 2),
    ('smalltalk_b2_0101', 'd7cff1b0e3876aba1c100630df7e1aba50c301ac7d59c524032eecef86133a57', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 2),
    ('smalltalk_b2_0102', 'c6ef28052bd4d9ec4c3ba4707968b459230a3e58e2bf0b4379e35d97c4b04c59', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 2),
    ('smalltalk_b2_0103', '1c1e89bd3d29921f95cd296137b8953c7de58fb0d61bf1d19cb2c4aef7b8120e', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 2),
    ('smalltalk_b2_0104', '2ba99f66d948a37986e908ff6727ff6d9e8212b18a037d8b426563dc3abe32cf', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 2),
    ('smalltalk_b2_0105', '43500ab946a3aa94fdcc35d262a3286eed3b97eaeca0075c6186726c1402f002', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 2),
    ('smalltalk_b2_0106', 'b4dda2b730f6be73d1defb1fc85e95d8833f58c0a4d29db5829671fb873f948e', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 2),
    ('smalltalk_b2_0107', 'b6277688bfc2e02aeaf44f47bf0e19f4ac6c4df683ca1408441fae52877d08ef', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 2),
    ('smalltalk_b2_0108', '1bfe05e8bccc51543fd40ff97b081db9988da3bd0350002499c76c3fd46e47bc', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 2),
    ('smalltalk_b2_0110', '274f419e2adebf86c9cf1d5b7de0891e0bcbb9eea6e31cea98634fd3a9fe2004', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 2),
    ('smalltalk_b2_0111', '717c44469ee115b5d5ff8dc28b83e5301a46926e9fc6b3ad6c5694e346a8bd7e', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 2),
    ('smalltalk_b2_0112', 'd7c9dcfe0fb81ace2924b3c4d590b68e1dd9564f31aadda04a8b0d13f1416c2b', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 2),
    ('smalltalk_b2_0114', '202021b955a031c8a26b79254783a0dd0cfdd4cf536271a70cea16216bfc9132', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 2),
    ('smalltalk_b2_0116', '17b404a17d188de74e3b04cc5c46b8136ac2bd2d659cbabdee0505df69f0fc65', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 2),
    ('smalltalk_b2_0117', '4ff0b1151de820ce984152f5f2bd9fcbe22a04111a6a1599355cdfaac27e6918', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 2),
    ('smalltalk_b2_0118', '058783e1fb34ac8701ad29557dfb0bf508fa192977eb5565afd9fce547f0b986', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 2),
    ('smalltalk_b2_0119', '6631dd154d8c4c779916e916829947fafd2d9dfba8c39bf1ef1904982f8c06a1', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 2),
    ('smalltalk_b2_0120', 'eda0ac99b8c74a0223b7816f98cbf93f37b7876b3b05952f8afb31ffa4efe34b', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 2),
    ('smalltalk_b2_0121', '13a77330e2a2ec849fcb81c3cd47af05207ffa96e9760bfd608eaf78b21ffc4c', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 2),
    ('smalltalk_b2_0122', 'cea74b6caf69c607422237ab3cb412b09ed6231d1b09cea88cbf5200083ba9b8', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 2),
    ('smalltalk_b2_0123', '8d18e983cb1d3ce5c1760ec353bc60cf36667a769d90e2649fe472fd0bb455d8', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 2),
    ('smalltalk_b2_0124', '622295a96856389c18720bc238393a757768a62e853ae64e65fcaf14399048f5', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0125', 'f2f1c1f1998348036d237b88776d1c14ccb7dee7e88c1ba831439d7fba2d95f5', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 2),
    ('smalltalk_b2_0126', '382fd7a01f3d7f587057afa969bcf189cbbb6321863cbf4c5bf185e3b6a6f6e7', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 2),
    ('smalltalk_b2_0127', '2c54bb563e3a68e498227b27f2896314c003ac25a540615f43a7408e25813cbb', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 2),
    ('smalltalk_b2_0128', '3b6efbeff37b8ca03766521bfe9230b95266124e43988a430a1f33aea8da20c9', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 2),
)
SMALLTALK_REVIEW_APPROVALS.update(
    {
        phrase_id: {
            "phraseFingerprintSha256": phrase_fingerprint,
            "canDoSegmentId": segment_id,
            "canDoFingerprintSha256": segment_fingerprint,
            "semanticStatus": semantic_status,
            "reviewRevision": review_revision,
        }
        for phrase_id, phrase_fingerprint, segment_id, segment_fingerprint, semantic_status, review_revision
        in _C7B_SMALLTALK_REBINDING_APPROVALS_2
    }
)
# provenance: approvedBy='Jin' approvedAt='2026-09-15' count=288



# PR #288 (aa0d932f) curriculum canDo text is source of truth; Fable ruling 2026-09-15; C7b
_C7B_SMALLTALK_REBINDING_APPROVALS_3 = (
    ('smalltalk_a1_0008', 'ff67e9feb807efff56a3be3c311fb626e48f6c6ddca59f241c5dd27dbfd55fd2', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0009', '5b63aacd6fc0454ac71e9a6fa3f5196fe1c673fbfc979dd8d87849dea7b2ecca', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0010', 'e4d26d3607d3f641ab1ee2986c0b7959f4bbea228844df4486062726ddbb37d4', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0011', '8c82e0082cefd7ffcbc136fc3232fbfe43339ccda424b693ea2636b6e5066053', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0012', '80ba896ca855ae649eb14137c604a5251c3760a05fa055cbb18a817802b260a6', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0013', '521fef19e7369e1620a1d6390e2f601634697df0eb1e96322ae9b46319c72848', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0014', '8297f759b789e05c6c8632bc7d52d8e363a47695275f0ea7f43456391fbba95b', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0015', '82b9b7020f1e7b93b9eea3e8229f8c397869901952bc221a81253aa5ae11d350', 'segment_a1_12_daily_negation', 'fbea0f8682214cf2ea2c2d029ca3522039241f46111ce026233ae8f5a6d42658', 'approved', 2),
    ('smalltalk_a1_0016', '58f8e24d76d030a18135b2c7d6386824c4fc76755e3493969505f622367bb269', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0017', '1cd56c1c746e6b1ab2e72e3e9cd16f3554be7e3d2502f9bc4214b91d5fb7d198', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0018', 'e3f311ac3974b106bc2b6472f016931497858951047f67c8fc0e90f80393fee7', 'segment_a1_12_daily_negation', 'fbea0f8682214cf2ea2c2d029ca3522039241f46111ce026233ae8f5a6d42658', 'approved', 2),
    ('smalltalk_a1_0019', 'bd271e4cf3908a8a232bcb9a65393117799853b4a761336b40646e97d74b936e', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 3),
    ('smalltalk_a1_0020', '1ef26accecef5bc18e0802485e84cc47b4221bb6341831505a9aa436653fc7e4', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0022', 'b96f9cf4d196f07181eec08f198d7fb722e252aebcf8fd75c1c1b9d547945c64', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0023', '9ca84baab8c0d0ccba4bca6d584f42340de6e06882c593699214a15e5c328dd1', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0024', '3f98b0f72ffb0d88a52c289e0c5e132febc9fe063a22944be76678083ac4b34e', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0026', '47c3da786b94c76c2bfa121468a5f6ffe01fab6f84c338e74ad7efdef9eddc36', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0027', 'fc86b0989a43bc9bd5f167f87202efa5cae3408d4d8501681aead1e944b18c9f', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0028', '48752a9c0eb75582925598be16541a84c28a637ebfa52bc9e613c275f6550210', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0029', 'e4112204dc919931ba613d1e2328667bf5ad7b64536550cecd2f0e4e3fc9ef78', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0030', 'df4b81a683e6c006cdc3a558fa2c3fdb3b9aee8c457ee320b428f4af8b1286b2', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0031', '5ffac261b38e3a2e8422a589e36798fb89cdc5cf5112a2082fd08c8d13cf0148', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0032', '7cb968f33e35587b2252f74605f10a4dd1b92cd02fd9d0b8989f194e4a426753', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0033', 'd91d9e1b04ca6e4e65d9b80943575daf8c7a8c886a5039c64fc062834569be07', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0034', '67caa8470b4f13a00961a681c1e8ae9eca6e3f10fe9a00c6174125fb81717861', 'segment_a1_07_contact_address', 'f0b2de476336b8393d0d3f291ca7bf6e0a4f261d6d7cb766e0110ffb87ceb318', 'approved', 2),
    ('smalltalk_a1_0035', 'a63baaabc5975b057ce6e47c8539d7a486fa865a639f761454269c73b0da6f2b', 'segment_a1_07_contact_address', 'f0b2de476336b8393d0d3f291ca7bf6e0a4f261d6d7cb766e0110ffb87ceb318', 'approved', 2),
    ('smalltalk_a1_0036', 'a2daee8ab06bc8858c6d93a452d963f41103ef09d80d1a4c2befba05877691be', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0037', '56e450be5ff666f15cd141e883b49c44e3b3d7f49e2cec96fc6f51a2c9bb9b7d', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0038', '7f06f3bf91ca4fa18e4948325d29360353e408ccc5bca975a427701f72e057f1', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0039', '21b3732cff39ffb67c8e5010108b91e7ca88b14216ac7c78f14b4065ca909c7f', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0040', 'bb50e039f13f0f9cb20f9163561be784a98a8b747c11ac6de600278583249931', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0041', '91d9b69fa847aa273158719a124b3bd8e6cb8d309c1b8b5a31b43dc2b900644f', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0045', 'cc3afc8f4e4479e085a168a20bede442fce90723f2c423ca5a4165ae18dadf30', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0046', 'b19a97b4a6c9c5c39150c6091881da2a14438b7dcb4c4039d484c230e4112949', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0047', '003fe2486280ed80d50cc6a33eca37a48cf875c6a459f2cb91b1501a4b8885b8', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0048', '0c28550b770268eabaf6e6a34ee8150d6724567f0af5122a4e62a78635e874fe', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0049', 'a2f6bc904062add7502af1659e0c848a0f18e5b61504a0aa9ab24428b9e4d391', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0050', 'ba72da418fbeecd1f38152ca28ef01fe51b83b001d987e0aebdc82fd6f32ad3b', 'segment_a1_07_contact_address', 'f0b2de476336b8393d0d3f291ca7bf6e0a4f261d6d7cb766e0110ffb87ceb318', 'approved', 3),
    ('smalltalk_a1_0052', 'b914fc1a0827f1a81897b6f6528f28067bea7b6c23c962545e68dab8a4753742', 'segment_a1_07_contact_address', 'f0b2de476336b8393d0d3f291ca7bf6e0a4f261d6d7cb766e0110ffb87ceb318', 'approved', 3),
    ('smalltalk_a1_0053', '7d7803ece33ab87bf3f9ff52c27bd6257df4baf66c6dda57b554db276d5a25ef', 'segment_a1_08_clarify_repair', '2c8abeefaefda451b1c100d8a6b62bb336e3b9b4262bc5297ea500ee5964c7e2', 'approved', 3),
    ('smalltalk_a1_0054', 'ba5a5ab3b74b0ab414d065dfb6575b6adfbde480488f28355b4d624348c07b0b', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0055', 'bd01f98660eabf847925ce514bcf9d329bd9d298c6562bff59b80c9c154ad67b', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0056', '4c32af430bb9c66c9bb006add3bece624e847f517faac48165a31a60248dbccb', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0057', '2336abd103a52c548bca6de3a40e3325afd71458a02eba234a69590c675882d6', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0058', '4cad355e2a0f306a6275728734ffb1408357642de0edaede450cbc4340e4fe7f', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0060', '6767ada09e63a41fdb0bc7a13bca49025bf0e513391871d95a8082042b5196a6', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 3),
    ('smalltalk_a1_0061', '5581cc77143ab28fee1ec16defc623ad1ab98bceb8f64a7e259ec9830eda5b78', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0062', '8852bf38ba69a527964f6bf37d6e9394e4235a3f29feec8491cc8c2c2185d4ca', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0063', '28f86ed1cb3a7d3073c4f344c09085b981aa4dc814e8abf988595750f1366770', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0064', 'cca448a19be75ff641b17161292e7b029f85e3b8d693e9bae56226ced522e68d', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0065', '5f28c52d3bd1da681a77ad5f1c31992457551ffd414419c08c59f6e6f0250e3e', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0066', '2943ba5a22c4e16203547c402e9ccf35c13a8e35a38325b6a84de6a90d1de496', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0067', '68cf68c617358c6901083f396e04f841f26f809d3bc002c6dedccd6a842df974', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0068', '1ae6aa274c3d18ee10fec4f1c62b5f154577f730a5ee53d4851c1e3b5b36a7cd', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0069', 'b8bf62e1618417aa9241458ada4033e8583bc34d21b50e3c91a997ef7da76587', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0070', '4bb24e889a6c85ec6eb98fffa7dd58d0915a37d14dd3c762a204c2f639767f78', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0071', '5d82a8db430194a8511492ef5287d2b1cbba39062cbc3f8d562a2e29eb5b88d6', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0072', '56096bc1a1bf488d6ae16b5d64559788893d1d5ddf67e154075734256ca291c0', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0073', 'bbbaf0a899d059202edbfa69353b957a393365cf69ca8ec9b355d7dad0614e36', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0074', 'aa37ea1e4b3ffc06cd39d0aeb94b29756469196827cc73a049d1d5aaa02974bc', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0077', 'd09127af7c7c3fab10d529b0868b06f21967a01a08438de9e959d016d9d260b1', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0078', '07251bfa2463b9815c302d75fd3d75eaa0b32710708cc5574cda530054ad52e3', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0079', '5e9d6b22de23daa74ade9f74daead3984175fc3c173ac1f76c6f3b6da4650eec', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0080', '6283274fcfb9b27859f62217a3122583d5125da3153f8a0dce2c5155017a4298', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0082', 'c544d93960617e4d7311e28e556ab77aa8f62f144d89680cb9d78f109edf58d3', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0083', 'b2c01466b0c489dd274cb494eb8bee136c757aa738321f2490a01ea2fe5bff5f', 'segment_a1_14_payment_delivery', 'b68383b7804a5f01b2cdef5b7742fb4e077bad2bb7016849b76baaab9d466df5', 'approved', 2),
    ('smalltalk_a1_0084', '7e0f1d7b0fd71b43221ccbec8d40cbcfe67438db5435fbc8f32ad0648a49092f', 'segment_a1_14_payment_delivery', 'b68383b7804a5f01b2cdef5b7742fb4e077bad2bb7016849b76baaab9d466df5', 'approved', 2),
    ('smalltalk_a1_0085', 'cf974cd2f2b6d732b885e5dd13d0b576c5bb2bec192be08cfabc23410d2aca1a', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0086', '17e10fcfca224198cae0189c1c611e81a8716f4f40d298c2d5d2bc645de97e7e', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0087', 'be5c098564b6d10b4842462f37db8bd86ff0b5d7d04509dd683b316ff5a8affa', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0088', 'f99f21b30a114883b1dcb53ddf908ce2d0684e4990f34c141622de0f2fab9688', 'segment_a1_05_numbers_time', '1de22a8006c64cfedc64054d6b25fcefbbdd9e97fd7ab0dbbdb9b5f1c0c00fba', 'approved', 2),
    ('smalltalk_a1_0089', '578acf2f8cc4684af0d05e5865bade5cb2abbeefaf9f2da372a94abf0e52ba1a', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0090', 'e0ec98c677d90ca5bfeb53226621f951f02f3a255ae347736f8cd10d80be4cb3', 'segment_a1_12_daily_negation', 'fbea0f8682214cf2ea2c2d029ca3522039241f46111ce026233ae8f5a6d42658', 'approved', 2),
    ('smalltalk_a1_0091', 'b87433dde6613d7a0ff773e510004a59d2ab6e971e658f8a8631c455129cdcf5', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0092', 'a9374e6cc3294ca51233df3e6be4351d226370f7a90f45e8019ccdffc180e652', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0093', '77cba50b5e94c3cd78ae83438fc4d88bf08a5c0a2282a1fb2c34cc8024123dad', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0094', '0e0670eb8f51107fdde0c76fa3bbd0352191c3d36859555fcd04c69d10ecc69d', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0095', 'cc3e7a02ecde78ddc395025cdfb7e35792acced390ec25343d93a5db83eefbdb', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0096', 'ccc7b2557b51adb1b8f46a1d773b7822ac9bcbef020eb6f4fb69c8e85123ed51', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0097', 'e451b06be52de4ba17e2c234f2cd5e287f0a1de4e730bf4310681ae317fc280b', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0098', 'f70bfcf99cdbcfdb50e899ddfea62b07dec64a10507293f0a96a920df0c97ded', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0099', '9f2cfd9a0a17a9147c5f824f55081c0a94081a952c6e09ff3a24231164a7c244', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0100', '2c410fe792c0a08d7c8ca88d300c9ec858d8277ccdf46834fc4171df6ece2208', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a2_0002', 'f92f9d0c78608b409f3a52c568fca335c6fcf00a050efae1fd35fd18a3726eec', 'segment_a2_feeling_sick', 'c063f6602f0aa7dac6d1128268a6820c655feb8b2f1a40edc1c3bc3aadae5f12', 'approved', 3),
    ('smalltalk_a2_0003', '7e00aee1886b9f4eb47d6affb86b842bec43a4bd6bb479cc8d516ff8616f3db5', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 3),
    ('smalltalk_a2_0004', '01c15d7e3b7cb35055086e8c326e14dbdfbe01f8a7b9ce30f308763604e94543', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 3),
    ('smalltalk_a2_0006', '0e212b5fbf9f425dd1a726c002495877d08d094f16b453cf6fea553af15e31a2', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0007', '745447b9f9443191d8f627eed514a8c8af64ff1fb4be441e70c334122f2441a0', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0008', '1b072620aae176156fb482b364cd8b19f45745af75fae64904775b859747e283', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0009', '65575cf35a4cde928d99d515b2d08d4d148a285f7cc11b5e14c8a397451d804c', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0011', 'c56a2d39927fae7302b1266eebc234f01318e31f3351e672f7526e73ced66917', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0012', '19d506b2ae68ae43e8ade2b7f7c66a185b28934fd3fff8f6b46d05b493162f85', 'segment_a2_gym_signup', '673649c1ca92c9e09d766f7f3b3f090ccbace9fac3a2db43f91fa20e679667d1', 'approved', 3),
    ('smalltalk_a2_0013', '3be35be9fcb7cbf7af034555e351d177df396006240ee12f035204c4bc14042c', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0014', '178d6407e8f3c8be0a44df9c085ab81a34d9bb19a1a864380bd6f0bb4f92d4e6', 'segment_a2_feeling_sick', 'c063f6602f0aa7dac6d1128268a6820c655feb8b2f1a40edc1c3bc3aadae5f12', 'approved', 3),
    ('smalltalk_a2_0017', '71fc72d6abdc6ef33a7c8a9bc65d4da78d85c6cf4f5f72091915addab08f4b62', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0018', '6fbb525cfa17576e95ed8b605aace69518cdf4d15f4556fdde97e3d2726f1c32', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0019', '7be498002442d94d2d5afd3bd6dd433aa8e6a746509c9bdf8f3e5d13533b81d1', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0020', 'd3429e7081c9f89306feebc024692971acdc878c37b4efc8abdedd9e9d8b299c', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0021', 'c5c3131bea54b2222696eba3e07c34d10f08128e6c0c65db801ca2e1b240482c', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0022', '718e36632fead91810f58fb170b7618d57cd070ded9b32e1d1181e3ff04a6ddc', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 3),
    ('smalltalk_a2_0024', 'e52ff80eb918bf64c03c51ed23a34fd3983574e3cef34cc93007d4679b7a38e8', 'segment_a2_feeling_sick', 'c063f6602f0aa7dac6d1128268a6820c655feb8b2f1a40edc1c3bc3aadae5f12', 'approved', 2),
    ('smalltalk_a2_0025', '270d112e0095a3fc4877c876218c1184e678550d0b712392a8981cea57b367fe', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0027', '3da3f3801f9ce86c2e24f02be523d2a37c10b5474b7948b7e15bf490f9aec7d2', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0028', 'b6938dddc20431e7118d8a53b179f35d7459d6de43462a4d7bc5c5c58536c3f7', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0033', '3a2cd93c5c413a88a57f245f7ce853369f8bd29e059ed2b58b65156c445c66fb', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 2),
    ('smalltalk_a2_0034', '9d7308ed1ac715e7f7de0c830de23a8bfbe8b424e80f597bb29d2f39ed97895c', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 2),
    ('smalltalk_a2_0035', 'a91fbe66f50f433a625c6a5f0465ca6229d1cd8a024c4686d04fc78b28226bd6', 'segment_a2_pharmacy_headache', 'd81c0c13ce917cdea14a5b791888382b3f6573102a97609e99e280ad800f0817', 'approved', 2),
    ('smalltalk_a2_0036', 'e020b1b2f1f1afa7e5b4248f8580da905549af89816b4c00f8ff8a1a5b5a278a', 'segment_a2_pharmacy_headache', 'd81c0c13ce917cdea14a5b791888382b3f6573102a97609e99e280ad800f0817', 'approved', 2),
    ('smalltalk_a2_0037', '7e5566e9cf5c377ee09881eb1f4152a456eebcb93fc5d99219879ac42ddf9112', 'segment_a2_subway_directions', '7c4a12d5fadd31dcc1df848d07151ba0de412e98ab038833387297225ca65931', 'approved', 2),
    ('smalltalk_a2_0038', '71eb8227d3f88b44f6a5ebfdd1fb89d07d5924faecc51e07e5c234ed0662fc72', 'segment_a2_subway_transfer', '454dd11389ccb0c32e45d33206fe01b5b47febc3a460f971e643743bcc4ab916', 'approved', 3),
    ('smalltalk_a2_0039', '19e1670fcf2e163e41efb67572e0db2130963631bc7da275ddfc61132b3e885e', 'segment_a2_subway_directions', '7c4a12d5fadd31dcc1df848d07151ba0de412e98ab038833387297225ca65931', 'approved', 2),
    ('smalltalk_a2_0040', '995e653629a11086033d0ff4aa1ce59555ab0096826ce37c3b1e540a52d7904f', 'segment_a2_taxi_street', '47133178b1c055bdf21f2bc83e853b77df7c5ba6c7e46ca70754df80baa1d6ea', 'approved', 3),
    ('smalltalk_a2_0041', '59df51422fa8628ca8c1b1e764813450fce6445d2cd13e65ade99533a2bc08ed', 'segment_a2_taxi_street', '47133178b1c055bdf21f2bc83e853b77df7c5ba6c7e46ca70754df80baa1d6ea', 'approved', 3),
    ('smalltalk_a2_0042', 'eee57b846c53fb9aeedf1fea21ad643d35db4b4758247cf1e2ec48f71d27868a', 'segment_a2_ktx_ticket', 'afdf8dfd33b5c441510d4221f75ca05adc579d14c8c49ee1681d9935065e87b8', 'approved', 3),
    ('smalltalk_a2_0044', 'e2db6270ae51c8db48ba7f3ee5d7d5e1ac148cd0d6d161edc3a2a37c23ccc394', 'segment_a2_myeongdong_shopping', 'c82ee1b27476bd9d495fa5e42b09f7739c3b7fa4ddf084734003a8d0504cb064', 'approved', 2),
    ('smalltalk_a2_0045', '012919e2d367e0c6c3d2f75d946c3b253978883e93b65f630a42616ac20ca73e', 'segment_a2_myeongdong_shopping', 'c82ee1b27476bd9d495fa5e42b09f7739c3b7fa4ddf084734003a8d0504cb064', 'approved', 2),
    ('smalltalk_a2_0046', 'c5a509603a826c9945ec436f353f41eafe99cd86cedbf5fb2173439302f5507b', 'segment_a2_myeongdong_shopping', 'c82ee1b27476bd9d495fa5e42b09f7739c3b7fa4ddf084734003a8d0504cb064', 'approved', 2),
    ('smalltalk_a2_0047', 'ba2a78f09ec1d23f66c6bc3109b744591b3b60cd7617fc3f2a5fe5046ae9f308', 'segment_a2_myeongdong_shopping', 'c82ee1b27476bd9d495fa5e42b09f7739c3b7fa4ddf084734003a8d0504cb064', 'approved', 2),
    ('smalltalk_a2_0048', '11b40d85e848f7af5d2c9474a77a3844f2334a5e28c7bb9dd50d2aa9f5bffdf9', 'segment_a2_myeongdong_shopping', 'c82ee1b27476bd9d495fa5e42b09f7739c3b7fa4ddf084734003a8d0504cb064', 'approved', 2),
    ('smalltalk_a2_0052', 'dc98c366b9d9290e7920675af56597e346206af104f17dd55872272d3ff4ed58', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 2),
    ('smalltalk_a2_0056', 'c4f9d8050d73dc3500018d6787d2831c9e7396c94737993b190f9dd115e0f996', 'segment_a2_cafe_starbucks_basic', '23de0a68ee5e7803e95b6fbe7ee50cddd6fa66cf56a7b8feac41f1d8f430bd8c', 'approved', 2),
    ('smalltalk_a2_0057', '789a9ce465ef77e3e106a0f404b535032ed560b744d75087e9881f196f7fd92f', 'segment_a2_cafe_starbucks_basic', '23de0a68ee5e7803e95b6fbe7ee50cddd6fa66cf56a7b8feac41f1d8f430bd8c', 'approved', 2),
    ('smalltalk_a2_0058', '77ad168ef73886297c66e6b0e76e92ba869f9c8bd45c7352c0bc0b91edd1df79', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0059', 'cbcd214df4f40c327fc7b1e6e7fe64a493638b300dd5fbeb0037f29ea6801ff4', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0060', 'fc80d41205da48f1db1b17a2be3cd0885f7c5f90b0783fe0fbeb5c88b4d2b4f8', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0061', '3b2a02b5e508b7f599f4bc277a7b4263d8bf672e9a03c7b2b1a3acc035fe9795', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0063', '85b3f05c829727ce9e4293b5669fe10f73dc8db557e7c649f246db8611d28dc2', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0064', 'b835e8d835c375cf023fb4d70823fbccf1ab41134d1b75e67f7e0ca508883519', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0065', '4e8ac453afa50fa2ab2b9994a0f06e150998795aad388e94854d915ad7b23948', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0067', 'e17a16c91ec0cf61acab06a2f598979c9ce04f389470ff5b1ba7769aae720f47', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0069', 'c168ce2920a04dc081325efeaa57e859ba0e1c264d62d4b5d0549cbf4e535d3e', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0070', '1ad99bac2fcdbb0fcfb945bdf3a9e02658bc5176865d1e21a7ceeecd9fb10546', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0072', '9e06834b9907fbe1ecb3e726bca21af18b752f79e7e539b86c556b913b1f15d1', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0073', '7a874861240db7f0c301964f334a8e48a4ae64c30154880b7522195417a14f85', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0075', '73c27bd3105e8da5f9a3a0828aecd6095d7df6f93288432fa4b4df46a4da1219', 'segment_a2_feeling_sick', 'c063f6602f0aa7dac6d1128268a6820c655feb8b2f1a40edc1c3bc3aadae5f12', 'approved', 3),
    ('smalltalk_a2_0076', '64f181f5b51375b05ba0384497c8a2cadc0a3a78b6a95ae7dfa5849b984bb629', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 3),
    ('smalltalk_a2_0077', 'f71aa47c63ef2fad2090527b24ff16021ef8f4476698cb4b9545644b9d1d930c', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 3),
    ('smalltalk_a2_0078', '75b5aec219c07c1c64c2d01e5adf3c2a708c5409f323853f0eb49772dd7f62cb', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 3),
    ('smalltalk_a2_0079', 'a6fa27d5870ff1c4999fb2371d51750a7981648de740a787e9f795c9bfb2fb47', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 3),
    ('smalltalk_a2_0080', 'c5f20249ab6a9213c28e0ca188b415809eef0c861ba89097846188fc54dcfe9e', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 3),
    ('smalltalk_a2_0081', 'e8525f906dd6610ca98877fa0256920a7bd6ae086e8004c011533418661be8bf', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 3),
    ('smalltalk_a2_0082', 'b51af6c8ae1aa660a600f1c8fc318ef1ba51696994d2e42ed0f9900bafa0c2d5', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 3),
    ('smalltalk_a2_0083', '7b540833d55b3c63412405759fb39b12fbba9fe55d79633d4be58a0288157d5c', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 3),
    ('smalltalk_a2_0084', 'ba859ae48fece78f8886fc169314e1f15a5e0234b2633f50f74266d0b40cac8e', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0085', '1fc43f0de62a589b0b411fe613900fec43897b9626cdb12e01edc4052086f6f0', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0086', 'fd56ccbbabc52e1f19a85ed1fd179dd4307c5a05528d9bd91f579f7888649064', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0087', 'ad795ef7f54ef83010a38f7a2b29325e451bd9e1485963b2044beec8040c360a', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0088', '21afbd0d67fc43a077eb0845de02be8a764d7dd0fd27be99b9499eed72231b2b', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0089', 'cb9ebeb79fcb574965816120dedf3a770d469d6daac37fc081b6612ced5b18bf', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0090', 'b6cf9af269ee6c744ffab19128fede370129fd305d89a7632589f6583622f0fd', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0091', '46c683b7bf9a3288b2129884fcda762dbfbb03def957f1f032616ef99be09082', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0092', '1c6e9b4796bdfa577710def6eec671430d52ffc4879240598b36d38637ac36ee', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0093', 'cb81a45832e150030ae770cf67d4f933420f4c3641820197cdc43b13ab932c8f', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_b1_0053', 'ecf9da40dc1ada9342d68f8aba22bd7a35c25c2ecb893d9dce7a0108ec08b70a', 'segment_b1_property_damage_report', '4be1c31b7e3d878fc9ff6a172e71388046eecd8ebdbdff40c59840c890f3d95c', 'approved', 3),
    ('smalltalk_b1_0054', 'ed3281284913374f6176e46d9a02c2f625c8ed3527e2d5fc25b06ea6cee498ca', 'segment_b1_property_damage_report', '4be1c31b7e3d878fc9ff6a172e71388046eecd8ebdbdff40c59840c890f3d95c', 'approved', 3),
    ('smalltalk_b1_0055', 'bda3da2a4702adca217474ac505c676ef4a49b799f7237ed8eae487c0d7e51f7', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0056', '9dca3536ab0a9d052f6f23682820d9f4795720ac73e1e4c1176ee409d53977bf', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0058', 'c9e5fd28646a107235d47257d43e2bb94c6c2fc2d49f59abc91b7c5a0c1289b3', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0059', 'bcd7d4baddeb667ec4aaf0e4b88e54f6567bbd4cad324ddf221197bfa6db5b1f', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0060', '6998c169c346495ea5b6008ac2a0ab81cfea4013b0cef65fdfd225bce9c88b92', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0061', 'b72a6dce32e13262dc233443b40d995556dfe9651b4bc1c7d410784ff7e016bb', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0062', '3941747fd82c88b319a965df12d508bc967bf5108a13582e825f7f1ed55d4a9b', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0063', 'eac369d404f902ba4750b61e0f77ca9f5ae0049291c4926eda5ab422f60e32ce', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0064', '762fe5611e60b86ed67515bc1d29896000b3f68c49ef50ac86d3aece7ad69c38', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0065', 'f0256ba1e529f8d47f0f61a9dfd11986edf4bef65fc7c0a1e8875f628763dfab', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0067', '67c727b68c0a50995e2b8fd8cbbf8247b4ef0dfee789773d21f4924a6c2f38f5', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0069', '443fa17b7d7c1df268fcd226ffd0abea0a69d516545fa5c835cd53eb071cbf88', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0070', '99a2de3887ae48f08df7c7005b1ea3d27509a65539f7cf43a766a8c3aedaa1ed', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0072', '38f407574f4afc1426c4818777fc3c28abdc5b70a158ab67ecdf2ee230b7aaba', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 3),
    ('smalltalk_b1_0073', '059f7baf79d87307fca40b342d7b7b1d73196d024a708f05bbc7ee8ffe1b64d2', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0074', '1863b0544bc45c0a2ff4b8ee82704749e36802bd65f7c6947a56a2ec21f4cabf', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0075', 'd6f81fd25530afb5879949aa879ae8c13bc2d7e07c71c9917f30abe261e1bc0a', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0076', 'da7465c2af96ca27c28f5be9ef1de2520f5e2a3b7fa46ca24deb7e4bcf1abf0a', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0077', '2da6ddd1dc89d5b817a36adb6779e93a766ec98553ebebbfad4f39b473bd870f', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0078', 'dcb5641473e107c86516cad605c1060d9be8ac22c37b8131986d2ec02ffc19bb', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0079', '697db0071e71f311b5aa792c768431207dc07a3d7bcbe963cf87ee704850a670', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0080', 'da150032a46c40b47612aa8000463ce5151407040fb269185bbcaaa54f6298f0', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0081', '35f373aba5bd41b164edfa95e7164657e43ca517843074c674f74a8a537911a9', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0082', 'e75915a8705228203cfcf92be89b7dd7fa913bb40ae2cc6a1e0e93d7e3e66d26', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0083', '3ba118106084a7c16be955d47c35bcb093fbf59d03caf6ec32ea328924e52cb3', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0084', 'fb4b7a549061fa035bb76cbaac21022e1433114b0878aa275b28262a093f975d', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0085', '9599563d4cc32a96831e66f01aef8b6c2c10966c2f449ed37a4955fe28d66fae', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0086', 'c82bf4dd37ce2c046ad800214ee403e930f50cd5140536d80cc0e7a381c6e023', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0087', 'b91e8824d7b8b6571a30761982dc5e22434bd136fe655cd4aeb721ad520f484a', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0088', '387b337cb554c9e7de07c278cd457a1b2bfba3990ce65de19eef57282d60fd5e', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b2_0081', '2c7f653b5bfabbd8ce9c94b5038d24dc7a78b5d277c169d3952f56e9943be800', 'segment_b2_remedy_and_appeal', 'a1be69870db12624788b3f2de3d2d0e7f9f8a1fa0b9f1578f8e866c55cbcdf9a', 'approved', 3),
    ('smalltalk_b2_0082', 'e27dc5bacde1ca5418de701e3152b54490e0d7c7f09db2cc49cab6e9281d8575', 'segment_b2_remedy_and_appeal', 'a1be69870db12624788b3f2de3d2d0e7f9f8a1fa0b9f1578f8e866c55cbcdf9a', 'approved', 3),
    ('smalltalk_b2_0101', 'd7cff1b0e3876aba1c100630df7e1aba50c301ac7d59c524032eecef86133a57', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0102', 'c6ef28052bd4d9ec4c3ba4707968b459230a3e58e2bf0b4379e35d97c4b04c59', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0103', '1c1e89bd3d29921f95cd296137b8953c7de58fb0d61bf1d19cb2c4aef7b8120e', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 3),
    ('smalltalk_b2_0104', '2ba99f66d948a37986e908ff6727ff6d9e8212b18a037d8b426563dc3abe32cf', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 3),
    ('smalltalk_b2_0105', '43500ab946a3aa94fdcc35d262a3286eed3b97eaeca0075c6186726c1402f002', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0106', 'b4dda2b730f6be73d1defb1fc85e95d8833f58c0a4d29db5829671fb873f948e', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0107', 'b6277688bfc2e02aeaf44f47bf0e19f4ac6c4df683ca1408441fae52877d08ef', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0108', '1bfe05e8bccc51543fd40ff97b081db9988da3bd0350002499c76c3fd46e47bc', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0110', '274f419e2adebf86c9cf1d5b7de0891e0bcbb9eea6e31cea98634fd3a9fe2004', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 3),
    ('smalltalk_b2_0111', '717c44469ee115b5d5ff8dc28b83e5301a46926e9fc6b3ad6c5694e346a8bd7e', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0112', 'd7c9dcfe0fb81ace2924b3c4d590b68e1dd9564f31aadda04a8b0d13f1416c2b', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0114', '202021b955a031c8a26b79254783a0dd0cfdd4cf536271a70cea16216bfc9132', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0116', '17b404a17d188de74e3b04cc5c46b8136ac2bd2d659cbabdee0505df69f0fc65', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 3),
    ('smalltalk_b2_0117', '4ff0b1151de820ce984152f5f2bd9fcbe22a04111a6a1599355cdfaac27e6918', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0118', '058783e1fb34ac8701ad29557dfb0bf508fa192977eb5565afd9fce547f0b986', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0119', '6631dd154d8c4c779916e916829947fafd2d9dfba8c39bf1ef1904982f8c06a1', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0120', 'eda0ac99b8c74a0223b7816f98cbf93f37b7876b3b05952f8afb31ffa4efe34b', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0121', '13a77330e2a2ec849fcb81c3cd47af05207ffa96e9760bfd608eaf78b21ffc4c', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0122', 'cea74b6caf69c607422237ab3cb412b09ed6231d1b09cea88cbf5200083ba9b8', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0123', '8d18e983cb1d3ce5c1760ec353bc60cf36667a769d90e2649fe472fd0bb455d8', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0124', '622295a96856389c18720bc238393a757768a62e853ae64e65fcaf14399048f5', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 4),
    ('smalltalk_b2_0125', 'f2f1c1f1998348036d237b88776d1c14ccb7dee7e88c1ba831439d7fba2d95f5', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0126', '382fd7a01f3d7f587057afa969bcf189cbbb6321863cbf4c5bf185e3b6a6f6e7', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0127', '2c54bb563e3a68e498227b27f2896314c003ac25a540615f43a7408e25813cbb', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0128', '3b6efbeff37b8ca03766521bfe9230b95266124e43988a430a1f33aea8da20c9', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
)
SMALLTALK_REVIEW_APPROVALS.update(
    {
        phrase_id: {
            "phraseFingerprintSha256": phrase_fingerprint,
            "canDoSegmentId": segment_id,
            "canDoFingerprintSha256": segment_fingerprint,
            "semanticStatus": semantic_status,
            "reviewRevision": review_revision,
        }
        for phrase_id, phrase_fingerprint, segment_id, segment_fingerprint, semantic_status, review_revision
        in _C7B_SMALLTALK_REBINDING_APPROVALS_3
    }
)
# provenance: approvedBy='Jin' approvedAt='2026-09-15' count=212



# PR #288 (aa0d932f) curriculum canDo text is source of truth; Fable ruling 2026-09-15; C7b
_C7B_SMALLTALK_REBINDING_APPROVALS_4 = (
    ('smalltalk_a1_0008', 'ff67e9feb807efff56a3be3c311fb626e48f6c6ddca59f241c5dd27dbfd55fd2', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0009', '5b63aacd6fc0454ac71e9a6fa3f5196fe1c673fbfc979dd8d87849dea7b2ecca', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0010', 'e4d26d3607d3f641ab1ee2986c0b7959f4bbea228844df4486062726ddbb37d4', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0011', '8c82e0082cefd7ffcbc136fc3232fbfe43339ccda424b693ea2636b6e5066053', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0012', '80ba896ca855ae649eb14137c604a5251c3760a05fa055cbb18a817802b260a6', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0013', '521fef19e7369e1620a1d6390e2f601634697df0eb1e96322ae9b46319c72848', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0014', '8297f759b789e05c6c8632bc7d52d8e363a47695275f0ea7f43456391fbba95b', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0015', '82b9b7020f1e7b93b9eea3e8229f8c397869901952bc221a81253aa5ae11d350', 'segment_a1_12_daily_negation', 'fbea0f8682214cf2ea2c2d029ca3522039241f46111ce026233ae8f5a6d42658', 'approved', 2),
    ('smalltalk_a1_0016', '58f8e24d76d030a18135b2c7d6386824c4fc76755e3493969505f622367bb269', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0017', '1cd56c1c746e6b1ab2e72e3e9cd16f3554be7e3d2502f9bc4214b91d5fb7d198', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0018', 'e3f311ac3974b106bc2b6472f016931497858951047f67c8fc0e90f80393fee7', 'segment_a1_12_daily_negation', 'fbea0f8682214cf2ea2c2d029ca3522039241f46111ce026233ae8f5a6d42658', 'approved', 2),
    ('smalltalk_a1_0019', 'bd271e4cf3908a8a232bcb9a65393117799853b4a761336b40646e97d74b936e', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 3),
    ('smalltalk_a1_0020', '1ef26accecef5bc18e0802485e84cc47b4221bb6341831505a9aa436653fc7e4', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0022', 'b96f9cf4d196f07181eec08f198d7fb722e252aebcf8fd75c1c1b9d547945c64', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0023', '9ca84baab8c0d0ccba4bca6d584f42340de6e06882c593699214a15e5c328dd1', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0024', '3f98b0f72ffb0d88a52c289e0c5e132febc9fe063a22944be76678083ac4b34e', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0026', '47c3da786b94c76c2bfa121468a5f6ffe01fab6f84c338e74ad7efdef9eddc36', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0027', 'fc86b0989a43bc9bd5f167f87202efa5cae3408d4d8501681aead1e944b18c9f', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0028', '48752a9c0eb75582925598be16541a84c28a637ebfa52bc9e613c275f6550210', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0029', 'e4112204dc919931ba613d1e2328667bf5ad7b64536550cecd2f0e4e3fc9ef78', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0030', 'df4b81a683e6c006cdc3a558fa2c3fdb3b9aee8c457ee320b428f4af8b1286b2', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0031', '5ffac261b38e3a2e8422a589e36798fb89cdc5cf5112a2082fd08c8d13cf0148', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0032', '7cb968f33e35587b2252f74605f10a4dd1b92cd02fd9d0b8989f194e4a426753', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0033', 'd91d9e1b04ca6e4e65d9b80943575daf8c7a8c886a5039c64fc062834569be07', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0034', '67caa8470b4f13a00961a681c1e8ae9eca6e3f10fe9a00c6174125fb81717861', 'segment_a1_07_contact_address', 'f0b2de476336b8393d0d3f291ca7bf6e0a4f261d6d7cb766e0110ffb87ceb318', 'approved', 2),
    ('smalltalk_a1_0035', 'a63baaabc5975b057ce6e47c8539d7a486fa865a639f761454269c73b0da6f2b', 'segment_a1_07_contact_address', 'f0b2de476336b8393d0d3f291ca7bf6e0a4f261d6d7cb766e0110ffb87ceb318', 'approved', 2),
    ('smalltalk_a1_0036', 'a2daee8ab06bc8858c6d93a452d963f41103ef09d80d1a4c2befba05877691be', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0037', '56e450be5ff666f15cd141e883b49c44e3b3d7f49e2cec96fc6f51a2c9bb9b7d', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0038', '7f06f3bf91ca4fa18e4948325d29360353e408ccc5bca975a427701f72e057f1', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0039', '21b3732cff39ffb67c8e5010108b91e7ca88b14216ac7c78f14b4065ca909c7f', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0040', 'bb50e039f13f0f9cb20f9163561be784a98a8b747c11ac6de600278583249931', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0041', '91d9b69fa847aa273158719a124b3bd8e6cb8d309c1b8b5a31b43dc2b900644f', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0045', 'cc3afc8f4e4479e085a168a20bede442fce90723f2c423ca5a4165ae18dadf30', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0046', 'b19a97b4a6c9c5c39150c6091881da2a14438b7dcb4c4039d484c230e4112949', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0047', '003fe2486280ed80d50cc6a33eca37a48cf875c6a459f2cb91b1501a4b8885b8', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0048', '0c28550b770268eabaf6e6a34ee8150d6724567f0af5122a4e62a78635e874fe', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0049', 'a2f6bc904062add7502af1659e0c848a0f18e5b61504a0aa9ab24428b9e4d391', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0050', 'ba72da418fbeecd1f38152ca28ef01fe51b83b001d987e0aebdc82fd6f32ad3b', 'segment_a1_07_contact_address', 'f0b2de476336b8393d0d3f291ca7bf6e0a4f261d6d7cb766e0110ffb87ceb318', 'approved', 3),
    ('smalltalk_a1_0052', 'b914fc1a0827f1a81897b6f6528f28067bea7b6c23c962545e68dab8a4753742', 'segment_a1_07_contact_address', 'f0b2de476336b8393d0d3f291ca7bf6e0a4f261d6d7cb766e0110ffb87ceb318', 'approved', 3),
    ('smalltalk_a1_0053', '7d7803ece33ab87bf3f9ff52c27bd6257df4baf66c6dda57b554db276d5a25ef', 'segment_a1_08_clarify_repair', '2c8abeefaefda451b1c100d8a6b62bb336e3b9b4262bc5297ea500ee5964c7e2', 'approved', 3),
    ('smalltalk_a1_0054', 'ba5a5ab3b74b0ab414d065dfb6575b6adfbde480488f28355b4d624348c07b0b', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0055', 'bd01f98660eabf847925ce514bcf9d329bd9d298c6562bff59b80c9c154ad67b', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0056', '4c32af430bb9c66c9bb006add3bece624e847f517faac48165a31a60248dbccb', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0057', '2336abd103a52c548bca6de3a40e3325afd71458a02eba234a69590c675882d6', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0058', '4cad355e2a0f306a6275728734ffb1408357642de0edaede450cbc4340e4fe7f', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0060', '6767ada09e63a41fdb0bc7a13bca49025bf0e513391871d95a8082042b5196a6', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 3),
    ('smalltalk_a1_0061', '5581cc77143ab28fee1ec16defc623ad1ab98bceb8f64a7e259ec9830eda5b78', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0062', '8852bf38ba69a527964f6bf37d6e9394e4235a3f29feec8491cc8c2c2185d4ca', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0063', '28f86ed1cb3a7d3073c4f344c09085b981aa4dc814e8abf988595750f1366770', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0064', 'cca448a19be75ff641b17161292e7b029f85e3b8d693e9bae56226ced522e68d', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0065', '5f28c52d3bd1da681a77ad5f1c31992457551ffd414419c08c59f6e6f0250e3e', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0066', '2943ba5a22c4e16203547c402e9ccf35c13a8e35a38325b6a84de6a90d1de496', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0067', '68cf68c617358c6901083f396e04f841f26f809d3bc002c6dedccd6a842df974', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0068', '1ae6aa274c3d18ee10fec4f1c62b5f154577f730a5ee53d4851c1e3b5b36a7cd', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0069', 'b8bf62e1618417aa9241458ada4033e8583bc34d21b50e3c91a997ef7da76587', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0070', '4bb24e889a6c85ec6eb98fffa7dd58d0915a37d14dd3c762a204c2f639767f78', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0071', '5d82a8db430194a8511492ef5287d2b1cbba39062cbc3f8d562a2e29eb5b88d6', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0072', '56096bc1a1bf488d6ae16b5d64559788893d1d5ddf67e154075734256ca291c0', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0073', 'bbbaf0a899d059202edbfa69353b957a393365cf69ca8ec9b355d7dad0614e36', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0074', 'aa37ea1e4b3ffc06cd39d0aeb94b29756469196827cc73a049d1d5aaa02974bc', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0077', 'd09127af7c7c3fab10d529b0868b06f21967a01a08438de9e959d016d9d260b1', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0078', '07251bfa2463b9815c302d75fd3d75eaa0b32710708cc5574cda530054ad52e3', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0079', '5e9d6b22de23daa74ade9f74daead3984175fc3c173ac1f76c6f3b6da4650eec', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0080', '6283274fcfb9b27859f62217a3122583d5125da3153f8a0dce2c5155017a4298', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0082', 'c544d93960617e4d7311e28e556ab77aa8f62f144d89680cb9d78f109edf58d3', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0083', 'b2c01466b0c489dd274cb494eb8bee136c757aa738321f2490a01ea2fe5bff5f', 'segment_a1_14_payment_delivery', 'b68383b7804a5f01b2cdef5b7742fb4e077bad2bb7016849b76baaab9d466df5', 'approved', 2),
    ('smalltalk_a1_0084', '7e0f1d7b0fd71b43221ccbec8d40cbcfe67438db5435fbc8f32ad0648a49092f', 'segment_a1_14_payment_delivery', 'b68383b7804a5f01b2cdef5b7742fb4e077bad2bb7016849b76baaab9d466df5', 'approved', 2),
    ('smalltalk_a1_0085', 'cf974cd2f2b6d732b885e5dd13d0b576c5bb2bec192be08cfabc23410d2aca1a', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0086', '17e10fcfca224198cae0189c1c611e81a8716f4f40d298c2d5d2bc645de97e7e', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0087', 'be5c098564b6d10b4842462f37db8bd86ff0b5d7d04509dd683b316ff5a8affa', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0088', 'f99f21b30a114883b1dcb53ddf908ce2d0684e4990f34c141622de0f2fab9688', 'segment_a1_05_numbers_time', '1de22a8006c64cfedc64054d6b25fcefbbdd9e97fd7ab0dbbdb9b5f1c0c00fba', 'approved', 2),
    ('smalltalk_a1_0089', '578acf2f8cc4684af0d05e5865bade5cb2abbeefaf9f2da372a94abf0e52ba1a', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0090', 'e0ec98c677d90ca5bfeb53226621f951f02f3a255ae347736f8cd10d80be4cb3', 'segment_a1_12_daily_negation', 'fbea0f8682214cf2ea2c2d029ca3522039241f46111ce026233ae8f5a6d42658', 'approved', 2),
    ('smalltalk_a1_0091', 'b87433dde6613d7a0ff773e510004a59d2ab6e971e658f8a8631c455129cdcf5', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0092', 'a9374e6cc3294ca51233df3e6be4351d226370f7a90f45e8019ccdffc180e652', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0093', '77cba50b5e94c3cd78ae83438fc4d88bf08a5c0a2282a1fb2c34cc8024123dad', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0094', '0e0670eb8f51107fdde0c76fa3bbd0352191c3d36859555fcd04c69d10ecc69d', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0095', 'cc3e7a02ecde78ddc395025cdfb7e35792acced390ec25343d93a5db83eefbdb', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0096', 'ccc7b2557b51adb1b8f46a1d773b7822ac9bcbef020eb6f4fb69c8e85123ed51', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0097', 'e451b06be52de4ba17e2c234f2cd5e287f0a1de4e730bf4310681ae317fc280b', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0098', 'f70bfcf99cdbcfdb50e899ddfea62b07dec64a10507293f0a96a920df0c97ded', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0099', '9f2cfd9a0a17a9147c5f824f55081c0a94081a952c6e09ff3a24231164a7c244', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0100', '2c410fe792c0a08d7c8ca88d300c9ec858d8277ccdf46834fc4171df6ece2208', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a2_0002', 'f92f9d0c78608b409f3a52c568fca335c6fcf00a050efae1fd35fd18a3726eec', 'segment_a2_feeling_sick', 'c063f6602f0aa7dac6d1128268a6820c655feb8b2f1a40edc1c3bc3aadae5f12', 'approved', 3),
    ('smalltalk_a2_0003', '7e00aee1886b9f4eb47d6affb86b842bec43a4bd6bb479cc8d516ff8616f3db5', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 3),
    ('smalltalk_a2_0004', '01c15d7e3b7cb35055086e8c326e14dbdfbe01f8a7b9ce30f308763604e94543', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 3),
    ('smalltalk_a2_0006', '0e212b5fbf9f425dd1a726c002495877d08d094f16b453cf6fea553af15e31a2', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0007', '745447b9f9443191d8f627eed514a8c8af64ff1fb4be441e70c334122f2441a0', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0008', '1b072620aae176156fb482b364cd8b19f45745af75fae64904775b859747e283', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0009', '65575cf35a4cde928d99d515b2d08d4d148a285f7cc11b5e14c8a397451d804c', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0011', 'c56a2d39927fae7302b1266eebc234f01318e31f3351e672f7526e73ced66917', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0012', '19d506b2ae68ae43e8ade2b7f7c66a185b28934fd3fff8f6b46d05b493162f85', 'segment_a2_gym_signup', '673649c1ca92c9e09d766f7f3b3f090ccbace9fac3a2db43f91fa20e679667d1', 'approved', 3),
    ('smalltalk_a2_0013', '3be35be9fcb7cbf7af034555e351d177df396006240ee12f035204c4bc14042c', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0014', '178d6407e8f3c8be0a44df9c085ab81a34d9bb19a1a864380bd6f0bb4f92d4e6', 'segment_a2_feeling_sick', 'c063f6602f0aa7dac6d1128268a6820c655feb8b2f1a40edc1c3bc3aadae5f12', 'approved', 3),
    ('smalltalk_a2_0017', '71fc72d6abdc6ef33a7c8a9bc65d4da78d85c6cf4f5f72091915addab08f4b62', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0018', '6fbb525cfa17576e95ed8b605aace69518cdf4d15f4556fdde97e3d2726f1c32', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0019', '7be498002442d94d2d5afd3bd6dd433aa8e6a746509c9bdf8f3e5d13533b81d1', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0020', 'd3429e7081c9f89306feebc024692971acdc878c37b4efc8abdedd9e9d8b299c', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0021', 'c5c3131bea54b2222696eba3e07c34d10f08128e6c0c65db801ca2e1b240482c', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0022', '718e36632fead91810f58fb170b7618d57cd070ded9b32e1d1181e3ff04a6ddc', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 3),
    ('smalltalk_a2_0024', 'e52ff80eb918bf64c03c51ed23a34fd3983574e3cef34cc93007d4679b7a38e8', 'segment_a2_feeling_sick', 'c063f6602f0aa7dac6d1128268a6820c655feb8b2f1a40edc1c3bc3aadae5f12', 'approved', 2),
    ('smalltalk_a2_0025', '270d112e0095a3fc4877c876218c1184e678550d0b712392a8981cea57b367fe', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0027', '3da3f3801f9ce86c2e24f02be523d2a37c10b5474b7948b7e15bf490f9aec7d2', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0028', 'b6938dddc20431e7118d8a53b179f35d7459d6de43462a4d7bc5c5c58536c3f7', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0033', '3a2cd93c5c413a88a57f245f7ce853369f8bd29e059ed2b58b65156c445c66fb', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 2),
    ('smalltalk_a2_0034', '9d7308ed1ac715e7f7de0c830de23a8bfbe8b424e80f597bb29d2f39ed97895c', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 2),
    ('smalltalk_a2_0035', 'a91fbe66f50f433a625c6a5f0465ca6229d1cd8a024c4686d04fc78b28226bd6', 'segment_a2_pharmacy_headache', 'd81c0c13ce917cdea14a5b791888382b3f6573102a97609e99e280ad800f0817', 'approved', 2),
    ('smalltalk_a2_0036', 'e020b1b2f1f1afa7e5b4248f8580da905549af89816b4c00f8ff8a1a5b5a278a', 'segment_a2_pharmacy_headache', 'd81c0c13ce917cdea14a5b791888382b3f6573102a97609e99e280ad800f0817', 'approved', 2),
    ('smalltalk_a2_0037', '7e5566e9cf5c377ee09881eb1f4152a456eebcb93fc5d99219879ac42ddf9112', 'segment_a2_subway_directions', '7c4a12d5fadd31dcc1df848d07151ba0de412e98ab038833387297225ca65931', 'approved', 2),
    ('smalltalk_a2_0038', '71eb8227d3f88b44f6a5ebfdd1fb89d07d5924faecc51e07e5c234ed0662fc72', 'segment_a2_subway_transfer', '454dd11389ccb0c32e45d33206fe01b5b47febc3a460f971e643743bcc4ab916', 'approved', 3),
    ('smalltalk_a2_0039', '19e1670fcf2e163e41efb67572e0db2130963631bc7da275ddfc61132b3e885e', 'segment_a2_subway_directions', '7c4a12d5fadd31dcc1df848d07151ba0de412e98ab038833387297225ca65931', 'approved', 2),
    ('smalltalk_a2_0040', '995e653629a11086033d0ff4aa1ce59555ab0096826ce37c3b1e540a52d7904f', 'segment_a2_taxi_street', '47133178b1c055bdf21f2bc83e853b77df7c5ba6c7e46ca70754df80baa1d6ea', 'approved', 3),
    ('smalltalk_a2_0041', '59df51422fa8628ca8c1b1e764813450fce6445d2cd13e65ade99533a2bc08ed', 'segment_a2_taxi_street', '47133178b1c055bdf21f2bc83e853b77df7c5ba6c7e46ca70754df80baa1d6ea', 'approved', 3),
    ('smalltalk_a2_0042', 'eee57b846c53fb9aeedf1fea21ad643d35db4b4758247cf1e2ec48f71d27868a', 'segment_a2_ktx_ticket', 'afdf8dfd33b5c441510d4221f75ca05adc579d14c8c49ee1681d9935065e87b8', 'approved', 3),
    ('smalltalk_a2_0044', 'e2db6270ae51c8db48ba7f3ee5d7d5e1ac148cd0d6d161edc3a2a37c23ccc394', 'segment_a2_myeongdong_shopping', 'c82ee1b27476bd9d495fa5e42b09f7739c3b7fa4ddf084734003a8d0504cb064', 'approved', 2),
    ('smalltalk_a2_0045', '012919e2d367e0c6c3d2f75d946c3b253978883e93b65f630a42616ac20ca73e', 'segment_a2_myeongdong_shopping', 'c82ee1b27476bd9d495fa5e42b09f7739c3b7fa4ddf084734003a8d0504cb064', 'approved', 2),
    ('smalltalk_a2_0046', 'c5a509603a826c9945ec436f353f41eafe99cd86cedbf5fb2173439302f5507b', 'segment_a2_myeongdong_shopping', 'c82ee1b27476bd9d495fa5e42b09f7739c3b7fa4ddf084734003a8d0504cb064', 'approved', 2),
    ('smalltalk_a2_0047', 'ba2a78f09ec1d23f66c6bc3109b744591b3b60cd7617fc3f2a5fe5046ae9f308', 'segment_a2_myeongdong_shopping', 'c82ee1b27476bd9d495fa5e42b09f7739c3b7fa4ddf084734003a8d0504cb064', 'approved', 2),
    ('smalltalk_a2_0048', '11b40d85e848f7af5d2c9474a77a3844f2334a5e28c7bb9dd50d2aa9f5bffdf9', 'segment_a2_myeongdong_shopping', 'c82ee1b27476bd9d495fa5e42b09f7739c3b7fa4ddf084734003a8d0504cb064', 'approved', 2),
    ('smalltalk_a2_0052', 'dc98c366b9d9290e7920675af56597e346206af104f17dd55872272d3ff4ed58', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 2),
    ('smalltalk_a2_0056', 'c4f9d8050d73dc3500018d6787d2831c9e7396c94737993b190f9dd115e0f996', 'segment_a2_cafe_starbucks_basic', '23de0a68ee5e7803e95b6fbe7ee50cddd6fa66cf56a7b8feac41f1d8f430bd8c', 'approved', 2),
    ('smalltalk_a2_0057', '789a9ce465ef77e3e106a0f404b535032ed560b744d75087e9881f196f7fd92f', 'segment_a2_cafe_starbucks_basic', '23de0a68ee5e7803e95b6fbe7ee50cddd6fa66cf56a7b8feac41f1d8f430bd8c', 'approved', 2),
    ('smalltalk_a2_0058', '77ad168ef73886297c66e6b0e76e92ba869f9c8bd45c7352c0bc0b91edd1df79', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0059', 'cbcd214df4f40c327fc7b1e6e7fe64a493638b300dd5fbeb0037f29ea6801ff4', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0060', 'fc80d41205da48f1db1b17a2be3cd0885f7c5f90b0783fe0fbeb5c88b4d2b4f8', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0061', '3b2a02b5e508b7f599f4bc277a7b4263d8bf672e9a03c7b2b1a3acc035fe9795', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0063', '85b3f05c829727ce9e4293b5669fe10f73dc8db557e7c649f246db8611d28dc2', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0064', 'b835e8d835c375cf023fb4d70823fbccf1ab41134d1b75e67f7e0ca508883519', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0065', '4e8ac453afa50fa2ab2b9994a0f06e150998795aad388e94854d915ad7b23948', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0067', 'e17a16c91ec0cf61acab06a2f598979c9ce04f389470ff5b1ba7769aae720f47', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0069', 'c168ce2920a04dc081325efeaa57e859ba0e1c264d62d4b5d0549cbf4e535d3e', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0070', '1ad99bac2fcdbb0fcfb945bdf3a9e02658bc5176865d1e21a7ceeecd9fb10546', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0072', '9e06834b9907fbe1ecb3e726bca21af18b752f79e7e539b86c556b913b1f15d1', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0073', '7a874861240db7f0c301964f334a8e48a4ae64c30154880b7522195417a14f85', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0075', '73c27bd3105e8da5f9a3a0828aecd6095d7df6f93288432fa4b4df46a4da1219', 'segment_a2_feeling_sick', 'c063f6602f0aa7dac6d1128268a6820c655feb8b2f1a40edc1c3bc3aadae5f12', 'approved', 3),
    ('smalltalk_a2_0076', '64f181f5b51375b05ba0384497c8a2cadc0a3a78b6a95ae7dfa5849b984bb629', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 3),
    ('smalltalk_a2_0077', 'f71aa47c63ef2fad2090527b24ff16021ef8f4476698cb4b9545644b9d1d930c', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 3),
    ('smalltalk_a2_0078', '75b5aec219c07c1c64c2d01e5adf3c2a708c5409f323853f0eb49772dd7f62cb', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 3),
    ('smalltalk_a2_0079', 'a6fa27d5870ff1c4999fb2371d51750a7981648de740a787e9f795c9bfb2fb47', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 3),
    ('smalltalk_a2_0080', 'c5f20249ab6a9213c28e0ca188b415809eef0c861ba89097846188fc54dcfe9e', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 3),
    ('smalltalk_a2_0081', 'e8525f906dd6610ca98877fa0256920a7bd6ae086e8004c011533418661be8bf', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 3),
    ('smalltalk_a2_0082', 'b51af6c8ae1aa660a600f1c8fc318ef1ba51696994d2e42ed0f9900bafa0c2d5', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 3),
    ('smalltalk_a2_0083', '7b540833d55b3c63412405759fb39b12fbba9fe55d79633d4be58a0288157d5c', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 3),
    ('smalltalk_a2_0084', 'ba859ae48fece78f8886fc169314e1f15a5e0234b2633f50f74266d0b40cac8e', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0085', '1fc43f0de62a589b0b411fe613900fec43897b9626cdb12e01edc4052086f6f0', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0086', 'fd56ccbbabc52e1f19a85ed1fd179dd4307c5a05528d9bd91f579f7888649064', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0087', 'ad795ef7f54ef83010a38f7a2b29325e451bd9e1485963b2044beec8040c360a', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0088', '21afbd0d67fc43a077eb0845de02be8a764d7dd0fd27be99b9499eed72231b2b', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0089', 'cb9ebeb79fcb574965816120dedf3a770d469d6daac37fc081b6612ced5b18bf', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0090', 'b6cf9af269ee6c744ffab19128fede370129fd305d89a7632589f6583622f0fd', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0091', '46c683b7bf9a3288b2129884fcda762dbfbb03def957f1f032616ef99be09082', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0092', '1c6e9b4796bdfa577710def6eec671430d52ffc4879240598b36d38637ac36ee', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0093', 'cb81a45832e150030ae770cf67d4f933420f4c3641820197cdc43b13ab932c8f', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_b1_0053', 'ecf9da40dc1ada9342d68f8aba22bd7a35c25c2ecb893d9dce7a0108ec08b70a', 'segment_b1_property_damage_report', '4be1c31b7e3d878fc9ff6a172e71388046eecd8ebdbdff40c59840c890f3d95c', 'approved', 3),
    ('smalltalk_b1_0054', 'ed3281284913374f6176e46d9a02c2f625c8ed3527e2d5fc25b06ea6cee498ca', 'segment_b1_property_damage_report', '4be1c31b7e3d878fc9ff6a172e71388046eecd8ebdbdff40c59840c890f3d95c', 'approved', 3),
    ('smalltalk_b1_0055', 'bda3da2a4702adca217474ac505c676ef4a49b799f7237ed8eae487c0d7e51f7', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0056', '9dca3536ab0a9d052f6f23682820d9f4795720ac73e1e4c1176ee409d53977bf', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0058', 'c9e5fd28646a107235d47257d43e2bb94c6c2fc2d49f59abc91b7c5a0c1289b3', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0059', 'bcd7d4baddeb667ec4aaf0e4b88e54f6567bbd4cad324ddf221197bfa6db5b1f', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0060', '6998c169c346495ea5b6008ac2a0ab81cfea4013b0cef65fdfd225bce9c88b92', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0061', 'b72a6dce32e13262dc233443b40d995556dfe9651b4bc1c7d410784ff7e016bb', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0062', '3941747fd82c88b319a965df12d508bc967bf5108a13582e825f7f1ed55d4a9b', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0063', 'eac369d404f902ba4750b61e0f77ca9f5ae0049291c4926eda5ab422f60e32ce', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0064', '762fe5611e60b86ed67515bc1d29896000b3f68c49ef50ac86d3aece7ad69c38', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0065', 'f0256ba1e529f8d47f0f61a9dfd11986edf4bef65fc7c0a1e8875f628763dfab', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0067', '67c727b68c0a50995e2b8fd8cbbf8247b4ef0dfee789773d21f4924a6c2f38f5', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0069', '443fa17b7d7c1df268fcd226ffd0abea0a69d516545fa5c835cd53eb071cbf88', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0070', '99a2de3887ae48f08df7c7005b1ea3d27509a65539f7cf43a766a8c3aedaa1ed', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0072', '38f407574f4afc1426c4818777fc3c28abdc5b70a158ab67ecdf2ee230b7aaba', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 3),
    ('smalltalk_b1_0073', '059f7baf79d87307fca40b342d7b7b1d73196d024a708f05bbc7ee8ffe1b64d2', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0074', '1863b0544bc45c0a2ff4b8ee82704749e36802bd65f7c6947a56a2ec21f4cabf', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0075', 'd6f81fd25530afb5879949aa879ae8c13bc2d7e07c71c9917f30abe261e1bc0a', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0076', 'da7465c2af96ca27c28f5be9ef1de2520f5e2a3b7fa46ca24deb7e4bcf1abf0a', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0077', '2da6ddd1dc89d5b817a36adb6779e93a766ec98553ebebbfad4f39b473bd870f', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0078', 'dcb5641473e107c86516cad605c1060d9be8ac22c37b8131986d2ec02ffc19bb', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0079', '697db0071e71f311b5aa792c768431207dc07a3d7bcbe963cf87ee704850a670', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0080', 'da150032a46c40b47612aa8000463ce5151407040fb269185bbcaaa54f6298f0', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0081', '35f373aba5bd41b164edfa95e7164657e43ca517843074c674f74a8a537911a9', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0082', 'e75915a8705228203cfcf92be89b7dd7fa913bb40ae2cc6a1e0e93d7e3e66d26', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0083', '3ba118106084a7c16be955d47c35bcb093fbf59d03caf6ec32ea328924e52cb3', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0084', 'fb4b7a549061fa035bb76cbaac21022e1433114b0878aa275b28262a093f975d', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0085', '9599563d4cc32a96831e66f01aef8b6c2c10966c2f449ed37a4955fe28d66fae', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0086', 'c82bf4dd37ce2c046ad800214ee403e930f50cd5140536d80cc0e7a381c6e023', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0087', 'b91e8824d7b8b6571a30761982dc5e22434bd136fe655cd4aeb721ad520f484a', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0088', '387b337cb554c9e7de07c278cd457a1b2bfba3990ce65de19eef57282d60fd5e', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b2_0081', '2c7f653b5bfabbd8ce9c94b5038d24dc7a78b5d277c169d3952f56e9943be800', 'segment_b2_remedy_and_appeal', 'a1be69870db12624788b3f2de3d2d0e7f9f8a1fa0b9f1578f8e866c55cbcdf9a', 'approved', 3),
    ('smalltalk_b2_0082', 'e27dc5bacde1ca5418de701e3152b54490e0d7c7f09db2cc49cab6e9281d8575', 'segment_b2_remedy_and_appeal', 'a1be69870db12624788b3f2de3d2d0e7f9f8a1fa0b9f1578f8e866c55cbcdf9a', 'approved', 3),
    ('smalltalk_b2_0101', 'd7cff1b0e3876aba1c100630df7e1aba50c301ac7d59c524032eecef86133a57', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0102', 'c6ef28052bd4d9ec4c3ba4707968b459230a3e58e2bf0b4379e35d97c4b04c59', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0103', '1c1e89bd3d29921f95cd296137b8953c7de58fb0d61bf1d19cb2c4aef7b8120e', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 3),
    ('smalltalk_b2_0104', '2ba99f66d948a37986e908ff6727ff6d9e8212b18a037d8b426563dc3abe32cf', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 3),
    ('smalltalk_b2_0105', '43500ab946a3aa94fdcc35d262a3286eed3b97eaeca0075c6186726c1402f002', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0106', 'b4dda2b730f6be73d1defb1fc85e95d8833f58c0a4d29db5829671fb873f948e', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0107', 'b6277688bfc2e02aeaf44f47bf0e19f4ac6c4df683ca1408441fae52877d08ef', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0108', '1bfe05e8bccc51543fd40ff97b081db9988da3bd0350002499c76c3fd46e47bc', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0110', '274f419e2adebf86c9cf1d5b7de0891e0bcbb9eea6e31cea98634fd3a9fe2004', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 3),
    ('smalltalk_b2_0111', '717c44469ee115b5d5ff8dc28b83e5301a46926e9fc6b3ad6c5694e346a8bd7e', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0112', 'd7c9dcfe0fb81ace2924b3c4d590b68e1dd9564f31aadda04a8b0d13f1416c2b', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0114', '202021b955a031c8a26b79254783a0dd0cfdd4cf536271a70cea16216bfc9132', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0116', '17b404a17d188de74e3b04cc5c46b8136ac2bd2d659cbabdee0505df69f0fc65', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 3),
    ('smalltalk_b2_0117', '4ff0b1151de820ce984152f5f2bd9fcbe22a04111a6a1599355cdfaac27e6918', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0118', '058783e1fb34ac8701ad29557dfb0bf508fa192977eb5565afd9fce547f0b986', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0119', '6631dd154d8c4c779916e916829947fafd2d9dfba8c39bf1ef1904982f8c06a1', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0120', 'eda0ac99b8c74a0223b7816f98cbf93f37b7876b3b05952f8afb31ffa4efe34b', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0121', '13a77330e2a2ec849fcb81c3cd47af05207ffa96e9760bfd608eaf78b21ffc4c', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0122', 'cea74b6caf69c607422237ab3cb412b09ed6231d1b09cea88cbf5200083ba9b8', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0123', '8d18e983cb1d3ce5c1760ec353bc60cf36667a769d90e2649fe472fd0bb455d8', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0124', '622295a96856389c18720bc238393a757768a62e853ae64e65fcaf14399048f5', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 4),
    ('smalltalk_b2_0125', 'f2f1c1f1998348036d237b88776d1c14ccb7dee7e88c1ba831439d7fba2d95f5', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0126', '382fd7a01f3d7f587057afa969bcf189cbbb6321863cbf4c5bf185e3b6a6f6e7', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0127', '2c54bb563e3a68e498227b27f2896314c003ac25a540615f43a7408e25813cbb', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0128', '3b6efbeff37b8ca03766521bfe9230b95266124e43988a430a1f33aea8da20c9', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
)
SMALLTALK_REVIEW_APPROVALS.update(
    {
        phrase_id: {
            "phraseFingerprintSha256": phrase_fingerprint,
            "canDoSegmentId": segment_id,
            "canDoFingerprintSha256": segment_fingerprint,
            "semanticStatus": semantic_status,
            "reviewRevision": review_revision,
        }
        for phrase_id, phrase_fingerprint, segment_id, segment_fingerprint, semantic_status, review_revision
        in _C7B_SMALLTALK_REBINDING_APPROVALS_4
    }
)
# provenance: approvedBy='Jin' approvedAt='2026-09-15' count=212



# PR #288 (aa0d932f) curriculum canDo text is source of truth; Fable ruling 2026-09-15; C7b
_C7B_SMALLTALK_REBINDING_APPROVALS_5 = (
    ('smalltalk_a1_0008', 'ff67e9feb807efff56a3be3c311fb626e48f6c6ddca59f241c5dd27dbfd55fd2', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0009', '5b63aacd6fc0454ac71e9a6fa3f5196fe1c673fbfc979dd8d87849dea7b2ecca', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0010', 'e4d26d3607d3f641ab1ee2986c0b7959f4bbea228844df4486062726ddbb37d4', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0011', '8c82e0082cefd7ffcbc136fc3232fbfe43339ccda424b693ea2636b6e5066053', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0012', '80ba896ca855ae649eb14137c604a5251c3760a05fa055cbb18a817802b260a6', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0013', '521fef19e7369e1620a1d6390e2f601634697df0eb1e96322ae9b46319c72848', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0014', '8297f759b789e05c6c8632bc7d52d8e363a47695275f0ea7f43456391fbba95b', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0015', '82b9b7020f1e7b93b9eea3e8229f8c397869901952bc221a81253aa5ae11d350', 'segment_a1_12_daily_negation', 'fbea0f8682214cf2ea2c2d029ca3522039241f46111ce026233ae8f5a6d42658', 'approved', 2),
    ('smalltalk_a1_0016', '58f8e24d76d030a18135b2c7d6386824c4fc76755e3493969505f622367bb269', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0017', '1cd56c1c746e6b1ab2e72e3e9cd16f3554be7e3d2502f9bc4214b91d5fb7d198', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0018', 'e3f311ac3974b106bc2b6472f016931497858951047f67c8fc0e90f80393fee7', 'segment_a1_12_daily_negation', 'fbea0f8682214cf2ea2c2d029ca3522039241f46111ce026233ae8f5a6d42658', 'approved', 2),
    ('smalltalk_a1_0019', 'bd271e4cf3908a8a232bcb9a65393117799853b4a761336b40646e97d74b936e', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 3),
    ('smalltalk_a1_0020', '1ef26accecef5bc18e0802485e84cc47b4221bb6341831505a9aa436653fc7e4', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0022', 'b96f9cf4d196f07181eec08f198d7fb722e252aebcf8fd75c1c1b9d547945c64', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0023', '9ca84baab8c0d0ccba4bca6d584f42340de6e06882c593699214a15e5c328dd1', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0024', '3f98b0f72ffb0d88a52c289e0c5e132febc9fe063a22944be76678083ac4b34e', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0026', '47c3da786b94c76c2bfa121468a5f6ffe01fab6f84c338e74ad7efdef9eddc36', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0027', 'fc86b0989a43bc9bd5f167f87202efa5cae3408d4d8501681aead1e944b18c9f', 'segment_a1_09_home_daily_life', 'bc299bc52558e0f926332ffd2476226a6fb0f30c8bd73fd8c346c5cc83e57fc3', 'approved', 2),
    ('smalltalk_a1_0028', '48752a9c0eb75582925598be16541a84c28a637ebfa52bc9e613c275f6550210', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0029', 'e4112204dc919931ba613d1e2328667bf5ad7b64536550cecd2f0e4e3fc9ef78', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0030', 'df4b81a683e6c006cdc3a558fa2c3fdb3b9aee8c457ee320b428f4af8b1286b2', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0031', '5ffac261b38e3a2e8422a589e36798fb89cdc5cf5112a2082fd08c8d13cf0148', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0032', '7cb968f33e35587b2252f74605f10a4dd1b92cd02fd9d0b8989f194e4a426753', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0033', 'd91d9e1b04ca6e4e65d9b80943575daf8c7a8c886a5039c64fc062834569be07', 'segment_a1_15_first_class_work', '600f95f993a50ece22baf4b8504f46148ebe15154fbff0ab0089ef6db654f915', 'approved', 2),
    ('smalltalk_a1_0034', '67caa8470b4f13a00961a681c1e8ae9eca6e3f10fe9a00c6174125fb81717861', 'segment_a1_07_contact_address', 'f0b2de476336b8393d0d3f291ca7bf6e0a4f261d6d7cb766e0110ffb87ceb318', 'approved', 2),
    ('smalltalk_a1_0035', 'a63baaabc5975b057ce6e47c8539d7a486fa865a639f761454269c73b0da6f2b', 'segment_a1_07_contact_address', 'f0b2de476336b8393d0d3f291ca7bf6e0a4f261d6d7cb766e0110ffb87ceb318', 'approved', 2),
    ('smalltalk_a1_0036', 'a2daee8ab06bc8858c6d93a452d963f41103ef09d80d1a4c2befba05877691be', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0037', '56e450be5ff666f15cd141e883b49c44e3b3d7f49e2cec96fc6f51a2c9bb9b7d', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0038', '7f06f3bf91ca4fa18e4948325d29360353e408ccc5bca975a427701f72e057f1', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0039', '21b3732cff39ffb67c8e5010108b91e7ca88b14216ac7c78f14b4065ca909c7f', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0040', 'bb50e039f13f0f9cb20f9163561be784a98a8b747c11ac6de600278583249931', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0041', '91d9b69fa847aa273158719a124b3bd8e6cb8d309c1b8b5a31b43dc2b900644f', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0045', 'cc3afc8f4e4479e085a168a20bede442fce90723f2c423ca5a4165ae18dadf30', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0046', 'b19a97b4a6c9c5c39150c6091881da2a14438b7dcb4c4039d484c230e4112949', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0047', '003fe2486280ed80d50cc6a33eca37a48cf875c6a459f2cb91b1501a4b8885b8', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0048', '0c28550b770268eabaf6e6a34ee8150d6724567f0af5122a4e62a78635e874fe', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0049', 'a2f6bc904062add7502af1659e0c848a0f18e5b61504a0aa9ab24428b9e4d391', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0050', 'ba72da418fbeecd1f38152ca28ef01fe51b83b001d987e0aebdc82fd6f32ad3b', 'segment_a1_07_contact_address', 'f0b2de476336b8393d0d3f291ca7bf6e0a4f261d6d7cb766e0110ffb87ceb318', 'approved', 3),
    ('smalltalk_a1_0052', 'b914fc1a0827f1a81897b6f6528f28067bea7b6c23c962545e68dab8a4753742', 'segment_a1_07_contact_address', 'f0b2de476336b8393d0d3f291ca7bf6e0a4f261d6d7cb766e0110ffb87ceb318', 'approved', 3),
    ('smalltalk_a1_0053', '7d7803ece33ab87bf3f9ff52c27bd6257df4baf66c6dda57b554db276d5a25ef', 'segment_a1_08_clarify_repair', '2c8abeefaefda451b1c100d8a6b62bb336e3b9b4262bc5297ea500ee5964c7e2', 'approved', 3),
    ('smalltalk_a1_0054', 'ba5a5ab3b74b0ab414d065dfb6575b6adfbde480488f28355b4d624348c07b0b', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0055', 'bd01f98660eabf847925ce514bcf9d329bd9d298c6562bff59b80c9c154ad67b', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0056', '4c32af430bb9c66c9bb006add3bece624e847f517faac48165a31a60248dbccb', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0057', '2336abd103a52c548bca6de3a40e3325afd71458a02eba234a69590c675882d6', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0058', '4cad355e2a0f306a6275728734ffb1408357642de0edaede450cbc4340e4fe7f', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0060', '6767ada09e63a41fdb0bc7a13bca49025bf0e513391871d95a8082042b5196a6', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 3),
    ('smalltalk_a1_0061', '5581cc77143ab28fee1ec16defc623ad1ab98bceb8f64a7e259ec9830eda5b78', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0062', '8852bf38ba69a527964f6bf37d6e9394e4235a3f29feec8491cc8c2c2185d4ca', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0063', '28f86ed1cb3a7d3073c4f344c09085b981aa4dc814e8abf988595750f1366770', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0064', 'cca448a19be75ff641b17161292e7b029f85e3b8d693e9bae56226ced522e68d', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0065', '5f28c52d3bd1da681a77ad5f1c31992457551ffd414419c08c59f6e6f0250e3e', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0066', '2943ba5a22c4e16203547c402e9ccf35c13a8e35a38325b6a84de6a90d1de496', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0067', '68cf68c617358c6901083f396e04f841f26f809d3bc002c6dedccd6a842df974', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0068', '1ae6aa274c3d18ee10fec4f1c62b5f154577f730a5ee53d4851c1e3b5b36a7cd', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0069', 'b8bf62e1618417aa9241458ada4033e8583bc34d21b50e3c91a997ef7da76587', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0070', '4bb24e889a6c85ec6eb98fffa7dd58d0915a37d14dd3c762a204c2f639767f78', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0071', '5d82a8db430194a8511492ef5287d2b1cbba39062cbc3f8d562a2e29eb5b88d6', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0072', '56096bc1a1bf488d6ae16b5d64559788893d1d5ddf67e154075734256ca291c0', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0073', 'bbbaf0a899d059202edbfa69353b957a393365cf69ca8ec9b355d7dad0614e36', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0074', 'aa37ea1e4b3ffc06cd39d0aeb94b29756469196827cc73a049d1d5aaa02974bc', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0077', 'd09127af7c7c3fab10d529b0868b06f21967a01a08438de9e959d016d9d260b1', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0078', '07251bfa2463b9815c302d75fd3d75eaa0b32710708cc5574cda530054ad52e3', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0079', '5e9d6b22de23daa74ade9f74daead3984175fc3c173ac1f76c6f3b6da4650eec', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0080', '6283274fcfb9b27859f62217a3122583d5125da3153f8a0dce2c5155017a4298', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 3),
    ('smalltalk_a1_0082', 'c544d93960617e4d7311e28e556ab77aa8f62f144d89680cb9d78f109edf58d3', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0083', 'b2c01466b0c489dd274cb494eb8bee136c757aa738321f2490a01ea2fe5bff5f', 'segment_a1_14_payment_delivery', 'b68383b7804a5f01b2cdef5b7742fb4e077bad2bb7016849b76baaab9d466df5', 'approved', 2),
    ('smalltalk_a1_0084', '7e0f1d7b0fd71b43221ccbec8d40cbcfe67438db5435fbc8f32ad0648a49092f', 'segment_a1_14_payment_delivery', 'b68383b7804a5f01b2cdef5b7742fb4e077bad2bb7016849b76baaab9d466df5', 'approved', 2),
    ('smalltalk_a1_0085', 'cf974cd2f2b6d732b885e5dd13d0b576c5bb2bec192be08cfabc23410d2aca1a', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0086', '17e10fcfca224198cae0189c1c611e81a8716f4f40d298c2d5d2bc645de97e7e', 'segment_a1_10_health_safety', '7ff72fde93ad1fa7104d4ef4fd12ee486df2170933a6f8b57bfd8ab51a5eb084', 'approved', 2),
    ('smalltalk_a1_0087', 'be5c098564b6d10b4842462f37db8bd86ff0b5d7d04509dd683b316ff5a8affa', 'segment_a1_06_transport_directions', '70981f0e7c1439893fc71aa299b562052ec9a4dd74936afb9994e63c0c9473c4', 'approved', 2),
    ('smalltalk_a1_0088', 'f99f21b30a114883b1dcb53ddf908ce2d0684e4990f34c141622de0f2fab9688', 'segment_a1_05_numbers_time', '1de22a8006c64cfedc64054d6b25fcefbbdd9e97fd7ab0dbbdb9b5f1c0c00fba', 'approved', 2),
    ('smalltalk_a1_0089', '578acf2f8cc4684af0d05e5865bade5cb2abbeefaf9f2da372a94abf0e52ba1a', 'segment_a1_04_order_request_object', '7a1c0355c9e9cab017255e62ff5a89b40a06ae3fd588bec241e2def30a11fc2d', 'approved', 2),
    ('smalltalk_a1_0090', 'e0ec98c677d90ca5bfeb53226621f951f02f3a255ae347736f8cd10d80be4cb3', 'segment_a1_12_daily_negation', 'fbea0f8682214cf2ea2c2d029ca3522039241f46111ce026233ae8f5a6d42658', 'approved', 2),
    ('smalltalk_a1_0091', 'b87433dde6613d7a0ff773e510004a59d2ab6e971e658f8a8631c455129cdcf5', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0092', 'a9374e6cc3294ca51233df3e6be4351d226370f7a90f45e8019ccdffc180e652', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0093', '77cba50b5e94c3cd78ae83438fc4d88bf08a5c0a2282a1fb2c34cc8024123dad', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0094', '0e0670eb8f51107fdde0c76fa3bbd0352191c3d36859555fcd04c69d10ecc69d', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0095', 'cc3e7a02ecde78ddc395025cdfb7e35792acced390ec25343d93a5db83eefbdb', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0096', 'ccc7b2557b51adb1b8f46a1d773b7822ac9bcbef020eb6f4fb69c8e85123ed51', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0097', 'e451b06be52de4ba17e2c234f2cd5e287f0a1de4e730bf4310681ae317fc280b', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0098', 'f70bfcf99cdbcfdb50e899ddfea62b07dec64a10507293f0a96a920df0c97ded', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0099', '9f2cfd9a0a17a9147c5f824f55081c0a94081a952c6e09ff3a24231164a7c244', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a1_0100', '2c410fe792c0a08d7c8ca88d300c9ec858d8277ccdf46834fc4171df6ece2208', 'segment_a1_11_titles_relationships', '41d7b41c710721891f9fe0961502e0bd35ac66e9549dce15f3be6bb2bf02e65e', 'approved', 2),
    ('smalltalk_a2_0002', 'f92f9d0c78608b409f3a52c568fca335c6fcf00a050efae1fd35fd18a3726eec', 'segment_a2_feeling_sick', 'c063f6602f0aa7dac6d1128268a6820c655feb8b2f1a40edc1c3bc3aadae5f12', 'approved', 3),
    ('smalltalk_a2_0003', '7e00aee1886b9f4eb47d6affb86b842bec43a4bd6bb479cc8d516ff8616f3db5', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 3),
    ('smalltalk_a2_0004', '01c15d7e3b7cb35055086e8c326e14dbdfbe01f8a7b9ce30f308763604e94543', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 3),
    ('smalltalk_a2_0006', '0e212b5fbf9f425dd1a726c002495877d08d094f16b453cf6fea553af15e31a2', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0007', '745447b9f9443191d8f627eed514a8c8af64ff1fb4be441e70c334122f2441a0', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0008', '1b072620aae176156fb482b364cd8b19f45745af75fae64904775b859747e283', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0009', '65575cf35a4cde928d99d515b2d08d4d148a285f7cc11b5e14c8a397451d804c', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 2),
    ('smalltalk_a2_0058', '77ad168ef73886297c66e6b0e76e92ba869f9c8bd45c7352c0bc0b91edd1df79', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0059', 'cbcd214df4f40c327fc7b1e6e7fe64a493638b300dd5fbeb0037f29ea6801ff4', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0060', 'fc80d41205da48f1db1b17a2be3cd0885f7c5f90b0783fe0fbeb5c88b4d2b4f8', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0061', '3b2a02b5e508b7f599f4bc277a7b4263d8bf672e9a03c7b2b1a3acc035fe9795', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0063', '85b3f05c829727ce9e4293b5669fe10f73dc8db557e7c649f246db8611d28dc2', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0064', 'b835e8d835c375cf023fb4d70823fbccf1ab41134d1b75e67f7e0ca508883519', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0065', '4e8ac453afa50fa2ab2b9994a0f06e150998795aad388e94854d915ad7b23948', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0067', 'e17a16c91ec0cf61acab06a2f598979c9ce04f389470ff5b1ba7769aae720f47', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0069', 'c168ce2920a04dc081325efeaa57e859ba0e1c264d62d4b5d0549cbf4e535d3e', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0070', '1ad99bac2fcdbb0fcfb945bdf3a9e02658bc5176865d1e21a7ceeecd9fb10546', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0072', '9e06834b9907fbe1ecb3e726bca21af18b752f79e7e539b86c556b913b1f15d1', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0073', '7a874861240db7f0c301964f334a8e48a4ae64c30154880b7522195417a14f85', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0075', '73c27bd3105e8da5f9a3a0828aecd6095d7df6f93288432fa4b4df46a4da1219', 'segment_a2_feeling_sick', 'c063f6602f0aa7dac6d1128268a6820c655feb8b2f1a40edc1c3bc3aadae5f12', 'approved', 3),
    ('smalltalk_a2_0076', '64f181f5b51375b05ba0384497c8a2cadc0a3a78b6a95ae7dfa5849b984bb629', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 3),
    ('smalltalk_a2_0077', 'f71aa47c63ef2fad2090527b24ff16021ef8f4476698cb4b9545644b9d1d930c', 'segment_a2_plans_with_friend', '592f94001e11a3849742dfa720ba17eac39cc9d45f2024882c8bd3d6eb18e33e', 'approved', 3),
    ('smalltalk_a2_0078', '75b5aec219c07c1c64c2d01e5adf3c2a708c5409f323853f0eb49772dd7f62cb', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 3),
    ('smalltalk_a2_0079', 'a6fa27d5870ff1c4999fb2371d51750a7981648de740a787e9f795c9bfb2fb47', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 3),
    ('smalltalk_a2_0080', 'c5f20249ab6a9213c28e0ca188b415809eef0c861ba89097846188fc54dcfe9e', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 3),
    ('smalltalk_a2_0081', 'e8525f906dd6610ca98877fa0256920a7bd6ae086e8004c011533418661be8bf', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 3),
    ('smalltalk_a2_0082', 'b51af6c8ae1aa660a600f1c8fc318ef1ba51696994d2e42ed0f9900bafa0c2d5', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 3),
    ('smalltalk_a2_0083', '7b540833d55b3c63412405759fb39b12fbba9fe55d79633d4be58a0288157d5c', 'segment_a2_rent_bank_transfer', '44f037f3b53b77f475f0cd4d14f8f9c676c899a908c6b32e6b47687cb3625c13', 'approved', 3),
    ('smalltalk_a2_0084', 'ba859ae48fece78f8886fc169314e1f15a5e0234b2633f50f74266d0b40cac8e', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0085', '1fc43f0de62a589b0b411fe613900fec43897b9626cdb12e01edc4052086f6f0', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0086', 'fd56ccbbabc52e1f19a85ed1fd179dd4307c5a05528d9bd91f579f7888649064', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0087', 'ad795ef7f54ef83010a38f7a2b29325e451bd9e1485963b2044beec8040c360a', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0088', '21afbd0d67fc43a077eb0845de02be8a764d7dd0fd27be99b9499eed72231b2b', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0089', 'cb9ebeb79fcb574965816120dedf3a770d469d6daac37fc081b6612ced5b18bf', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0090', 'b6cf9af269ee6c744ffab19128fede370129fd305d89a7632589f6583622f0fd', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 4),
    ('smalltalk_a2_0091', '46c683b7bf9a3288b2129884fcda762dbfbb03def957f1f032616ef99be09082', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0092', '1c6e9b4796bdfa577710def6eec671430d52ffc4879240598b36d38637ac36ee', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_a2_0093', 'cb81a45832e150030ae770cf67d4f933420f4c3641820197cdc43b13ab932c8f', 'segment_a2_running_late', '8d77321e597225b4d499225f11d639025bd1ed432dfdb9ecc3c90dcba211f8aa', 'approved', 3),
    ('smalltalk_b1_0053', 'ecf9da40dc1ada9342d68f8aba22bd7a35c25c2ecb893d9dce7a0108ec08b70a', 'segment_b1_property_damage_report', '4be1c31b7e3d878fc9ff6a172e71388046eecd8ebdbdff40c59840c890f3d95c', 'approved', 3),
    ('smalltalk_b1_0054', 'ed3281284913374f6176e46d9a02c2f625c8ed3527e2d5fc25b06ea6cee498ca', 'segment_b1_property_damage_report', '4be1c31b7e3d878fc9ff6a172e71388046eecd8ebdbdff40c59840c890f3d95c', 'approved', 3),
    ('smalltalk_b1_0055', 'bda3da2a4702adca217474ac505c676ef4a49b799f7237ed8eae487c0d7e51f7', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0056', '9dca3536ab0a9d052f6f23682820d9f4795720ac73e1e4c1176ee409d53977bf', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0058', 'c9e5fd28646a107235d47257d43e2bb94c6c2fc2d49f59abc91b7c5a0c1289b3', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0059', 'bcd7d4baddeb667ec4aaf0e4b88e54f6567bbd4cad324ddf221197bfa6db5b1f', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0060', '6998c169c346495ea5b6008ac2a0ab81cfea4013b0cef65fdfd225bce9c88b92', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0061', 'b72a6dce32e13262dc233443b40d995556dfe9651b4bc1c7d410784ff7e016bb', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0062', '3941747fd82c88b319a965df12d508bc967bf5108a13582e825f7f1ed55d4a9b', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0063', 'eac369d404f902ba4750b61e0f77ca9f5ae0049291c4926eda5ab422f60e32ce', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0064', '762fe5611e60b86ed67515bc1d29896000b3f68c49ef50ac86d3aece7ad69c38', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0065', 'f0256ba1e529f8d47f0f61a9dfd11986edf4bef65fc7c0a1e8875f628763dfab', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0067', '67c727b68c0a50995e2b8fd8cbbf8247b4ef0dfee789773d21f4924a6c2f38f5', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0069', '443fa17b7d7c1df268fcd226ffd0abea0a69d516545fa5c835cd53eb071cbf88', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0070', '99a2de3887ae48f08df7c7005b1ea3d27509a65539f7cf43a766a8c3aedaa1ed', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0072', '38f407574f4afc1426c4818777fc3c28abdc5b70a158ab67ecdf2ee230b7aaba', 'segment_b1_plans_with_reasons', '94fc5a228818e26c760738f32fd0a61021013e0e1732ec0af2d8fe87edbc07e9', 'approved', 3),
    ('smalltalk_b1_0073', '059f7baf79d87307fca40b342d7b7b1d73196d024a708f05bbc7ee8ffe1b64d2', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0074', '1863b0544bc45c0a2ff4b8ee82704749e36802bd65f7c6947a56a2ec21f4cabf', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0075', 'd6f81fd25530afb5879949aa879ae8c13bc2d7e07c71c9917f30abe261e1bc0a', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0076', 'da7465c2af96ca27c28f5be9ef1de2520f5e2a3b7fa46ca24deb7e4bcf1abf0a', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0077', '2da6ddd1dc89d5b817a36adb6779e93a766ec98553ebebbfad4f39b473bd870f', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0078', 'dcb5641473e107c86516cad605c1060d9be8ac22c37b8131986d2ec02ffc19bb', 'segment_b1_team_role_coordination', 'bab502a04681afd1380caba6da4f53b356cfe91570f92891217ac77bd946eb49', 'approved', 3),
    ('smalltalk_b1_0079', '697db0071e71f311b5aa792c768431207dc07a3d7bcbe963cf87ee704850a670', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0080', 'da150032a46c40b47612aa8000463ce5151407040fb269185bbcaaa54f6298f0', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0081', '35f373aba5bd41b164edfa95e7164657e43ca517843074c674f74a8a537911a9', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0082', 'e75915a8705228203cfcf92be89b7dd7fa913bb40ae2cc6a1e0e93d7e3e66d26', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 4),
    ('smalltalk_b1_0083', '3ba118106084a7c16be955d47c35bcb093fbf59d03caf6ec32ea328924e52cb3', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0084', 'fb4b7a549061fa035bb76cbaac21022e1433114b0878aa275b28262a093f975d', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0085', '9599563d4cc32a96831e66f01aef8b6c2c10966c2f449ed37a4955fe28d66fae', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0086', 'c82bf4dd37ce2c046ad800214ee403e930f50cd5140536d80cc0e7a381c6e023', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0087', 'b91e8824d7b8b6571a30761982dc5e22434bd136fe655cd4aeb721ad520f484a', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b1_0088', '387b337cb554c9e7de07c278cd457a1b2bfba3990ce65de19eef57282d60fd5e', 'segment_b1_intimate_feelings', 'f8713bca25f894a761f3f3e85c70102c3e03c905ca5125dec427c8c3f8484828', 'approved', 3),
    ('smalltalk_b2_0081', '2c7f653b5bfabbd8ce9c94b5038d24dc7a78b5d277c169d3952f56e9943be800', 'segment_b2_remedy_and_appeal', 'a1be69870db12624788b3f2de3d2d0e7f9f8a1fa0b9f1578f8e866c55cbcdf9a', 'approved', 3),
    ('smalltalk_b2_0082', 'e27dc5bacde1ca5418de701e3152b54490e0d7c7f09db2cc49cab6e9281d8575', 'segment_b2_remedy_and_appeal', 'a1be69870db12624788b3f2de3d2d0e7f9f8a1fa0b9f1578f8e866c55cbcdf9a', 'approved', 3),
    ('smalltalk_b2_0101', 'd7cff1b0e3876aba1c100630df7e1aba50c301ac7d59c524032eecef86133a57', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0102', 'c6ef28052bd4d9ec4c3ba4707968b459230a3e58e2bf0b4379e35d97c4b04c59', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0103', '1c1e89bd3d29921f95cd296137b8953c7de58fb0d61bf1d19cb2c4aef7b8120e', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 3),
    ('smalltalk_b2_0104', '2ba99f66d948a37986e908ff6727ff6d9e8212b18a037d8b426563dc3abe32cf', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 3),
    ('smalltalk_b2_0105', '43500ab946a3aa94fdcc35d262a3286eed3b97eaeca0075c6186726c1402f002', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0106', 'b4dda2b730f6be73d1defb1fc85e95d8833f58c0a4d29db5829671fb873f948e', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0107', 'b6277688bfc2e02aeaf44f47bf0e19f4ac6c4df683ca1408441fae52877d08ef', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0108', '1bfe05e8bccc51543fd40ff97b081db9988da3bd0350002499c76c3fd46e47bc', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0110', '274f419e2adebf86c9cf1d5b7de0891e0bcbb9eea6e31cea98634fd3a9fe2004', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 3),
    ('smalltalk_b2_0111', '717c44469ee115b5d5ff8dc28b83e5301a46926e9fc6b3ad6c5694e346a8bd7e', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0112', 'd7c9dcfe0fb81ace2924b3c4d590b68e1dd9564f31aadda04a8b0d13f1416c2b', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0114', '202021b955a031c8a26b79254783a0dd0cfdd4cf536271a70cea16216bfc9132', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0116', '17b404a17d188de74e3b04cc5c46b8136ac2bd2d659cbabdee0505df69f0fc65', 'segment_b2_interview_experience', '768fa31b6996a5f9301abb1afcbd1512c4da29a045544e5a17bde41ac2dcf666', 'approved', 3),
    ('smalltalk_b2_0117', '4ff0b1151de820ce984152f5f2bd9fcbe22a04111a6a1599355cdfaac27e6918', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0118', '058783e1fb34ac8701ad29557dfb0bf508fa192977eb5565afd9fce547f0b986', 'segment_b2_decision_criteria', 'c83491c425c40921067a348e97f186b5db76baf9de47508d70d417e6446882e1', 'approved', 3),
    ('smalltalk_b2_0119', '6631dd154d8c4c779916e916829947fafd2d9dfba8c39bf1ef1904982f8c06a1', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0120', 'eda0ac99b8c74a0223b7816f98cbf93f37b7876b3b05952f8afb31ffa4efe34b', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0121', '13a77330e2a2ec849fcb81c3cd47af05207ffa96e9760bfd608eaf78b21ffc4c', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0122', 'cea74b6caf69c607422237ab3cb412b09ed6231d1b09cea88cbf5200083ba9b8', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0123', '8d18e983cb1d3ce5c1760ec353bc60cf36667a769d90e2649fe472fd0bb455d8', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0124', '622295a96856389c18720bc238393a757768a62e853ae64e65fcaf14399048f5', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 4),
    ('smalltalk_b2_0125', 'f2f1c1f1998348036d237b88776d1c14ccb7dee7e88c1ba831439d7fba2d95f5', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0126', '382fd7a01f3d7f587057afa969bcf189cbbb6321863cbf4c5bf185e3b6a6f6e7', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0127', '2c54bb563e3a68e498227b27f2896314c003ac25a540615f43a7408e25813cbb', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
    ('smalltalk_b2_0128', '3b6efbeff37b8ca03766521bfe9230b95266124e43988a430a1f33aea8da20c9', 'segment_b2_contract_scope', 'beef75c8d40b74b12b27536e52bea0a9bcc91e675508ae291d32bf8c1dad8ff6', 'approved', 3),
)
SMALLTALK_REVIEW_APPROVALS.update(
    {
        phrase_id: {
            "phraseFingerprintSha256": phrase_fingerprint,
            "canDoSegmentId": segment_id,
            "canDoFingerprintSha256": segment_fingerprint,
            "semanticStatus": semantic_status,
            "reviewRevision": review_revision,
        }
        for phrase_id, phrase_fingerprint, segment_id, segment_fingerprint, semantic_status, review_revision
        in _C7B_SMALLTALK_REBINDING_APPROVALS_5
    }
)
# provenance: approvedBy='Jin' approvedAt='2026-09-15' count=180


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
        review_promotions = REVIEW_CONTENT_PROMOTIONS
        if self.curriculum.get("scenarioCorpusGeneration") == "canonical_120_v1":
            # These promotions are immutable lineage for the retired 419-row
            # corpus. The canonical scenarios are routed by the current
            # curriculum graph and must not be required to keep old IDs live.
            review_promotions = {
                key: value
                for key, value in REVIEW_CONTENT_PROMOTIONS.items()
                if key[0] != "scenario"
            }
        _validate_review_batch_boundaries(
            {
                "scenario": set(self.scenarios),
                "smalltalk": set(self.smalltalk),
                "cloze": set(self.cloze),
                "satz": set(self.satz),
                "pronunciation": set(self.pronunciation),
            },
            promotions=review_promotions,
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
            if reference.id in KNOWN_MISSING_SCENARIO_SLOTS:
                # Content gap, not a routing decision: this scenario was
                # retired by the 2026-09-01 canonical_120_v1 corpus
                # promotion and has no live row to resolve against yet.
                # Trust the spec's own level/parent until the A2/B1
                # enrichment wave writes real scenario content.
                actual_level = expected_level
                actual_parent = expected_parent
            else:
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
    pack_renames = _pack_id_renames()
    retired_pairs = _retired_seed_pairs()
    retired_scenario_keys = _retired_scenario_reference_keys()
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
        new_seed_id_set = set(new_seed_ids)
        missing_seeds = sorted(set(old_seed_ids) - new_seed_id_set)
        unresolved_seeds = [
            seed_id
            for seed_id in missing_seeds
            if _renamed_seed_equivalent(seed_id, pack_renames) not in new_seed_id_set
            and (cluster_id, seed_id) not in retired_pairs
        ]
        if unresolved_seeds:
            raise ValueError(
                f"published cluster {cluster_id!r} cannot remove seeds: {unresolved_seeds}"
            )
        # A retired (cluster, seed) pair is accepted above as historically
        # gone -- it must not then be carried back into the runtime cluster.
        # can_do_content_authorities.json never re-emits a retired seed's
        # authority (_validate_authority_history only tolerates its absence,
        # it does not resurrect it), so blindly re-adding every old_seed_id
        # here would leave sourceSeedIds pointing at a seed with no matching
        # authority entry -- the exact "unknown source seed" the Dart loaders
        # reject. Only seeds that are NOT retired for this cluster (or that
        # the fresh build still produces) are carried forward.
        carried_old_seed_ids = [
            seed_id
            for seed_id in old_seed_ids
            if (cluster_id, seed_id) not in retired_pairs
            or seed_id in new_seed_id_set
        ]
        cluster["sourceSeedIds"] = carried_old_seed_ids + [
            seed_id
            for seed_id in new_seed_ids
            if seed_id not in set(carried_old_seed_ids)
        ]

        old_references = list(old["contentReferences"])
        new_references = list(cluster["contentReferences"])
        old_keys = [_reference_key(row) for row in old_references]
        old_by_key = {_reference_key(row): row for row in old_references}
        current_by_key = {_reference_key(row): row for row in new_references}
        missing_references = sorted(
            key
            for key in set(old_keys) - set(current_by_key)
            if key not in retired_scenario_keys
        )
        if missing_references:
            raise ValueError(
                f"published cluster {cluster_id!r} cannot remove or move refs: "
                f"{missing_references}"
            )
        # Same reasoning as sourceSeedIds: a retired scenario's
        # contentReference key must not be re-emitted once the fresh build
        # has dropped it, or the cluster ends up pointing at a scenario key
        # with no live content authority.
        carried_old_keys = [
            key
            for key in old_keys
            if key not in retired_scenario_keys or key in current_by_key
        ]
        cluster["contentReferences"] = [
            current_by_key.get(key, old_by_key[key]) for key in carried_old_keys
        ] + [
            row
            for row in new_references
            if _reference_key(row) not in set(carried_old_keys)
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
    # See the KNOWN_MISSING_SCENARIO_SLOTS-adjacent comment above
    # RELEVEL_DIR/RETIRED_SEEDS_LEDGER_PATH: pack renames and
    # canonical_120_v1 scenario retirements are documented, ledger-backed
    # exceptions to this immutability guard, not a blanket bypass.
    pack_renames = _pack_id_renames()
    retired_seed_ids = {seed_id for _cluster_id, seed_id in _retired_seed_pairs()}
    retired_scenario_keys = _retired_scenario_reference_keys()

    old_seeds = {row["id"]: row for row in previous["sourceSeeds"]}
    new_seeds = {row["id"]: row for row in current["sourceSeeds"]}
    for seed_id, old in old_seeds.items():
        next_seed = new_seeds.get(seed_id)
        if next_seed is not None:
            if next_seed != old:
                raise ValueError(f"published source seed {seed_id!r} is immutable")
            continue
        renamed = _renamed_seed_equivalent(seed_id, pack_renames)
        if renamed is not None and renamed in new_seeds:
            continue
        if seed_id in retired_seed_ids:
            continue
        raise ValueError(f"published source seed {seed_id!r} is immutable")

    old_references = {
        _reference_key(row): row for row in previous["contentReferences"]
    }
    new_references = {
        _reference_key(row): row for row in current["contentReferences"]
    }
    for key, old in old_references.items():
        next_reference = new_references.get(key)
        if next_reference is not None:
            if next_reference != old:
                raise ValueError(f"published content authority {key!r} is immutable")
            continue
        if key in retired_scenario_keys:
            continue
        kind, _, content_id = key.partition(":")
        if kind == "vocabPack":
            renamed = pack_renames.get(content_id)
            if renamed is not None and f"vocabPack:{renamed}" in new_references:
                continue
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
            if decision.get("copyRevisionLedger") not in {
                CONTENT_HUMANIZATION_LEDGER_REF,
                SMALLTALK_TRANSLATION_LEDGER_REF,
            }:
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
                if decision["copyRevisionLedger"] == SMALLTALK_TRANSLATION_LEDGER_REF:
                    raise ValueError(
                        f"smalltalk {phrase_id!r} translation correction changed "
                        "its semantic route"
                    )
                # C7b, Jin 승인 2026-09-15: PR #288's curriculum canDo-text
                # edits shifted canDoFingerprintSha256 for many segments
                # without actually re-routing any copy-revision phrase --
                # that re-binding is itself Jin-approved (curriculum canDo
                # text is source of truth), so an explicit
                # SMALLTALK_REVIEW_APPROVALS entry recorded against the
                # *current* segment id and fingerprint is accepted here,
                # exactly like it would be. This does not weaken the gate:
                # it still raises for any phrase without such an entry, and
                # an entry is only ever recorded (by
                # record_smalltalk_review_approvals.py) for phrases already
                # confirmed to have an unchanged canDoSegmentId -- a
                # genuine reroute has no matching entry and still raises.
                approval = approvals.get(phrase_id)
                approved_rebinding = (
                    approval is not None
                    and approval.get("canDoSegmentId") == decision.get("canDoSegmentId")
                    and approval.get("canDoFingerprintSha256")
                    == decision.get("canDoFingerprintSha256")
                )
                if not approved_rebinding:
                    raise ValueError(
                        f"smalltalk {phrase_id!r} copy revision changed its "
                        "semantic route"
                    )
                used_approvals.add(phrase_id)
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
        if scenario_id in KNOWN_UNPUBLISHED_LIVE_SCENARIOS:
            # Written to the live corpus by PR-L2a's scenario relevel but
            # never published to can_do_segments.json (see
            # KNOWN_UNPUBLISHED_LIVE_SCENARIOS above). Do not let the
            # course-unit fallback silently absorb it into another
            # segment's evidence -- that would drift the generated catalog
            # away from the published asset.
            continue
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
        expected_ids=(set(source.scenarios) - KNOWN_UNPUBLISHED_LIVE_SCENARIOS)
        | KNOWN_MISSING_SCENARIO_SLOTS,
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
    content_id = reference.id
    if reference.kind == "vocabPack":
        # A relevel-renamed pack's seed lineage predates the rename (every
        # published authority for a renamed pack cites the *pre-rename*
        # pack id as sourceSeedId -- see the RETIRED_SEEDS_LEDGER_PATH
        # comment above). Keep minting the same seed id after a rename so
        # this stays byte-identical instead of only being true because a
        # human hand-edited it once during PR-L2a.
        content_id = _original_pack_id(content_id)
    return f"seed_{kind}_{content_id}_v1"


def _original_pack_id(pack_id: str) -> str:
    for old_id, new_id in _pack_id_renames().items():
        if new_id == pack_id:
            return old_id
    return pack_id


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
