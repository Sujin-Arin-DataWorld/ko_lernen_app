#!/usr/bin/env python3
"""Materialize human-authored scenario source into review candidates.

This tool is deliberately offline.  It does not generate prose, translate text,
call an API, approve content, synthesize TTS, or touch runtime assets.  Its job
is to combine locked briefs with an authored multilingual source, extract the
runtime learning bundle, and write deterministic candidate JSON for review.

The Korean dialogue in ``canonical_scenarios/authored`` is the sole semantic
source.  German and English lines in that source are independent localizations
of the same turn.  Missing localizations are errors rather than fallbacks.
"""

from __future__ import annotations

import argparse
from collections import OrderedDict
import csv
import json
from pathlib import Path
import re
import sys
from typing import Any, Iterable, Mapping, Sequence


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import scenario_corpus_pipeline as pipeline


ROOT = SCRIPT_DIR.parents[1]
AUTHORED_DIR = ROOT / "tools/content_factory/canonical_scenarios/authored"
DEFAULT_OUTPUT = ROOT / "tools/content_factory/review/canonical_120_v1/candidates"
DEFAULT_REGRESSION_OUTPUT = (
    ROOT / "tools/content_factory/review/canonical_120_v1/regression_candidates"
)

LEVEL_RANK = {level: index for index, level in enumerate(pipeline.LEVELS)}
XP_BY_LEVEL = {"a1": 100, "a2": 110, "b1": 120, "b2": 130, "c1": 140, "c2": 150}
EMOJI_BY_BACKDROP = {
    "airport": "✈️",
    "bank": "🏦",
    "cafe": "☕",
    "convenience": "📦",
    "directions": "🗺️",
    "home": "🏠",
    "hotel": "🧳",
    "market": "🛍️",
    "office": "💬",
    "pharmacy": "💊",
    "restaurant": "🍽️",
    "salon": "✂️",
    "station": "🚇",
    "taxi": "🚕",
}

SHELF_BY_BUCKET = {
    "a1": {
        "identity_relationships": "a1_greet",
        "daily_home_time_weather": "a1_home",
        "food_shopping_services": "a1_counter",
        "transport_travel": "a1_transit",
        "school_leisure": "a1_friends",
        "health_mistake_emotion": "a1_body",
        "regression": "a1_repeat",
    },
    "a2": {
        "relationships_emotions_plans": "a2_plan",
        "daily_home_food": "a2_eat",
        "consumer_delivery_public_services": "a2_delivery",
        "transport_travel": "a2_move",
        "study_work_digital_media": "a2_work",
        "health_leisure": "a2_body",
        "regression": "a2_work",
    },
    "b1": {
        "relationships_romance_cultural_difference": "b1_feel",
        "study_work_digital_communication": "b1_team",
        "consumer_housing_complaint_resolution": "b1_refund",
        "travel_food_sport_media": "b1_delay",
        "familiar_community_environment": "b1_neighbor",
        "regression": "b1_incident",
    },
    "b2": {
        "work_education": "b2_meeting",
        "media_technology": "b2_evidence",
        "housing_consumer_transport": "b2_contract",
        "relationships_culture": "b2_friends",
        "society_community_environment": "b2_public",
        "regression": "b2_privacy",
    },
    "c1": {
        "society_community_institutions": "c1_policy",
        "work_academia": "c1_briefing",
        "media_ai_technology": "c1_critique",
        "culture_art_identity": "c1_attribution",
        "city_environment_generations": "c1_mediation",
        "regression": "c1_facework",
    },
    "c2": {
        "politics_economy_institutions_ethics": "c2_discourse",
        "academic_science_professional": "c2_ethics",
        "media_discourse_power": "c2_representation",
        "automation_accountability": "c2_automation",
        "culture_relationships_narrative_identity": "c2_memory",
        "regression": "c2_record",
    },
}

# Runtime grammar IDs live in ``assets/data/grammar.csv``.  These signals are
# intentionally conservative: an item is attached only when its surface form
# is present in the Korean scene.  Same-level signals win; lower-level grammar
# remains valid when it is the real learning element in a harder scene.
GRAMMAR_SIGNALS: dict[str, str] = {
    "grammar_a1_service_location_question": r"어디에 있어요",
    "grammar_a1_service_request": r"(?:주세요|줘요|줘\b)",
    "grammar_a1_polite_prohibition": r"지 마세요",
    "grammar_a1_copula_polite": r"(?:이에요|예요|이세요)",
    "grammar_a1_action_location_particle": r"에서",
    "grammar_a1_direction_time_particle": r"에(?:서)?\s",
    "grammar_a1_only_particle": r"만(?:\s|[,.?])",
    "grammar_a1_sequence_connector": r"고\s",
    "grammar_a1_short_negation": r"안\s",
    "grammar_a1_cannot_short": r"못\s",
    "grammar_a1_degree_question": r"얼마나",
    "grammar_a1_please_particle": r"좀\s",
    "grammar_a2_future_intention": r"(?:을|ㄹ)\s*거(?:예요|야)",
    "grammar_a2_conditional": r"(?:으)?면(?:\s|,)",
    "grammar_a2_contrast": r"지만",
    "grammar_a2_cause_sequence": r"(?:아서|어서|해서)",
    "grammar_a2_progressive": r"고\s+있",
    "grammar_a2_polite_proposal": r"(?:을|ㄹ)까요",
    "grammar_a2_permission": r"(?:아|어|해)도\s+(?:돼|되)",
    "grammar_a2_favor": r"(?:아|어|해)\s*주",
    "grammar_a2_promise": r"(?:을|ㄹ)게요",
    "grammar_a2_cause_nikka": r"(?:으)?니까",
    "grammar_a2_when": r"(?:을|ㄹ)\s*때|\s때",
    "grammar_a2_permission_check_batch20": r"(?:아|어|해)도\s+괜찮아요",
    "grammar_b1_intention": r"(?:으)?려고",
    "grammar_b1_obligation": r"(?:아|어|해)야\s+(?:하|해|돼|되)",
    "grammar_b1_before": r"기\s+전에",
    "grammar_b1_background_contrast": r"는데(?:요|,|\s)",
    "grammar_b1_decision": r"기로\s+(?:했|하)",
    "grammar_b1_future_probability": r"(?:을|ㄹ)\s*것\s*같",
    "grammar_b1_about": r"에\s*대해",
    "grammar_b1_explanatory_reason": r"거든요",
    "grammar_b1_indirect_speech": r"(?:다|라|냐|자)고(?:\s|,)",
    "grammar_b1_whether": r"(?:는|은|ㄴ)지",
    "grammar_b1_skill": r"(?:을|ㄹ)\s*줄\s*(?:알|몰)",
    "grammar_b1_nominalizer_gi": r"(?:하|되|가|오|먹|보|쓰|읽|쉬|말|받|찾|바꾸|확인)기(?:가|를|는|\s)",
    "grammar_b1_wish": r"(?:았|었|했)으면\s+좋겠",
    "grammar_b1_prepared_state": r"(?:아|어|해)\s*놓",
    "grammar_b1_near_miss": r"(?:을|ㄹ)\s*뻔",
    "grammar_b1_soft_request_batch19": r"(?:아|어|해)\s*주실\s+수\s+있을까요",
    "grammar_b1_reason_context": r"는\s+바람에",
    "grammar_b1_conceded_context_batch20": r"기는\s+한데",
    "grammar_b2_even_if": r"더라도",
    "grammar_b2_not_only": r"뿐만\s+아니라",
    "grammar_b2_according_to": r"에\s+따라",
    "grammar_b2_contrast": r"는\s+반면",
    "grammar_b2_formal_cause": r"(?:으)?로\s+인해",
    "grammar_b2_despite": r"에도\s+불구하고",
    "grammar_b2_formal_arrangement": r"도록\s+하",
    "grammar_b2_not_automatic_conclusion": r"다고\s+해서.*것은\s+아니",
    "grammar_b2_outcome_depends": r"느냐에\s+달려\s+있",
    "grammar_b2_shared_merit": r"다는\s+점에서",
    "grammar_b2_instead_tradeoff": r"는\s+대신",
    "grammar_b2_rather_than_direct": r"기보다",
    "grammar_b2_not_by_one_metric": r"만으로\s+판단하기\s+어렵",
    "grammar_b2_criterion_view_batch20": r"(?:을|를)\s+기준으로\s+보면",
    "grammar_b2_considering_fact_batch20": r"다는\s+점을\s+고려하면",
    "grammar_c1_unless_condition": r"지\s+않는\s+한",
    "grammar_c1_room_for": r"(?:을|ㄹ)\s+여지가\s+있",
    "grammar_c1_taking_into_account": r"(?:을|를)\s+감안하면",
    "grammar_c1_limited_to": r"에\s+국한하면",
    "grammar_c1_not_necessarily": r"(?:ㄴ|는)다고\s+해서.*것은\s+아니",
    "grammar_c1_even_accounting_for": r"(?:을|를)\s+감안하더라도",
    "grammar_c1_effect_varies_by": r"에\s+따라.*달라질\s+수\s+있",
    "grammar_c1_excluded_in_process": r"는\s+과정에서.*배제",
    "grammar_c1_difficult_to_conclude_batch20": r"다고\s+단정하기\s+어렵",
    "grammar_c1_burden_recipient_batch20": r"누구에게\s+돌아가는지",
    "grammar_c1_but_not": r"[가-힣]+하되(?:\s|,)",
    "grammar_c2_even_assuming": r"(?:ㄴ|는)다고\s+치더라도",
    "grammar_c2_nothing_more_than": r"에\s+불과하",
    "grammar_c2_on_the_premise": r"(?:을|를)\s+전제로",
    "grammar_c2_merely_on_grounds": r"(?:았|었|했다)는\s+이유만으로",
    "grammar_c2_take_as_premise": r"(?:을|를)\s+전제로\s+삼",
    "grammar_c2_responsibility_remains": r"(?:았|었|했다)고\s+해서\s+책임이\s+사라지는\s+것은\s+아니",
    "grammar_c2_cannot_reduce_to": r"으로\s+환원할\s+수\s+없",
    "grammar_c2_no_reduction_batch20": r"으로\s+환원해서는\s+안\s+되",
    "grammar_c2_premise_review_batch20": r"이라는\s+전제하에\s+검토하",
    "grammar_c2_no_more_than_doing": r"는\s+데\s+그치",
}


class AuthoredSourceError(ValueError):
    """Raised when the editorial source cannot safely become a candidate."""


def _map(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise AuthoredSourceError(f"{label} must be an object")
    return value


def _text(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise AuthoredSourceError(f"{label} must be a nonempty string")
    return value.strip()


def _localized(value: Any, label: str, *, korean: bool = True) -> dict[str, str]:
    raw = _map(value, label)
    languages = ("ko", "de", "en") if korean else ("de", "en")
    result = {language: _text(raw.get(language), f"{label}.{language}") for language in languages}
    if not korean and isinstance(raw.get("ko"), str):
        result["ko"] = raw["ko"].strip()
    return result


def _load_authored(path: Path) -> list[dict[str, Any]]:
    raw = pipeline.read_json(path)
    root = _map(raw, str(path))
    rows = root.get("scenarios")
    if not isinstance(rows, list):
        raise AuthoredSourceError(f"{path} must contain a scenarios array")
    result: list[dict[str, Any]] = []
    seen: set[str] = set()
    for index, row in enumerate(rows):
        item = _map(row, f"{path}.scenarios[{index}]")
        scenario_id = _text(item.get("id"), f"{path}.scenarios[{index}].id")
        if scenario_id in seen:
            raise AuthoredSourceError(f"duplicate authored scenario id: {scenario_id}")
        seen.add(scenario_id)
        result.append(item)
    return result


def _load_grammar_patterns(root: Path) -> list[dict[str, Any]]:
    path = root / "assets/data/grammar.csv"
    try:
        with path.open("r", encoding="utf-8", newline="") as handle:
            return [dict(row) for row in csv.DictReader(handle)]
    except OSError as error:
        raise AuthoredSourceError(f"cannot read {path}: {error}") from error


def _concepts_by_unit(root: Path) -> dict[str, list[str]]:
    raw = _map(
        pipeline.read_json(root / "assets/data/curriculum_manifest.json"),
        "curriculum_manifest",
    )
    units = raw.get("courseUnits")
    if not isinstance(units, list):
        raise AuthoredSourceError("curriculum_manifest.courseUnits must be an array")
    result: dict[str, list[str]] = {}
    for row in units:
        if not isinstance(row, dict) or not isinstance(row.get("id"), str):
            continue
        concepts = row.get("requiredConceptIds")
        if isinstance(concepts, list) and concepts and all(isinstance(item, str) for item in concepts):
            result[row["id"]] = list(concepts)
    return result


def _dialog(source: Mapping[str, Any], brief: pipeline.ScenarioBrief) -> list[dict[str, str]]:
    raw = source.get("dialog")
    if not isinstance(raw, list) or len(raw) < 6:
        raise AuthoredSourceError(f"{brief.scenario_id}.dialog needs at least six turns")
    result: list[dict[str, str]] = []
    known = set(brief.participant_ids)
    for index, value in enumerate(raw):
        line = _map(value, f"{brief.scenario_id}.dialog[{index}]")
        authored_speaker = _text(line.get("speaker"), f"{brief.scenario_id}.dialog[{index}].speaker")
        if authored_speaker not in known:
            raise AuthoredSourceError(
                f"{brief.scenario_id}.dialog[{index}] uses unknown speaker {authored_speaker!r}"
            )
        speaker = "user" if authored_speaker == brief.player_character_id else authored_speaker
        localized = _localized(line, f"{brief.scenario_id}.dialog[{index}]")
        result.append({"speaker": speaker, **localized})
    if not any(item["speaker"] == "user" for item in result):
        raise AuthoredSourceError(f"{brief.scenario_id} has no player turn")
    return result


def _grammar_for(
    *,
    level: str,
    korean: str,
    patterns: Sequence[Mapping[str, Any]],
) -> dict[str, Any]:
    eligible: list[tuple[int, int, Mapping[str, Any]]] = []
    for order, pattern in enumerate(patterns):
        pattern_level = str(pattern.get("level", "")).lower()
        if pattern_level not in LEVEL_RANK or LEVEL_RANK[pattern_level] > LEVEL_RANK[level]:
            continue
        grammar_id = pattern.get("id")
        expression = GRAMMAR_SIGNALS.get(str(grammar_id))
        if expression is None:
            continue
        try:
            if re.search(expression, korean):
                level_distance = LEVEL_RANK[level] - LEVEL_RANK[pattern_level]
                eligible.append((level_distance, order, pattern))
        except re.error as error:
            raise AuthoredSourceError(f"invalid grammar regex {pattern.get('id')}: {error}") from error
    if not eligible:
        raise AuthoredSourceError(
            f"no actually attested grammar pattern found for {level.upper()} dialogue"
        )
    pattern = min(eligible, key=lambda item: (item[0], item[1]))[2]
    grammar_id = _text(pattern.get("id"), "grammar.id")
    return {
        "id": grammar_id,
        "block": {
            "title": {
                "ko": _text(pattern.get("pattern"), f"{grammar_id}.pattern"),
                "de": _text(pattern.get("type_de"), f"{grammar_id}.type_de"),
                "en": _text(pattern.get("type_en"), f"{grammar_id}.type_en"),
            },
            "explanation": {
                "ko": "이 장면의 실제 대사에서 쓰인 표현이에요.",
                "de": _text(pattern.get("explanation_de"), f"{grammar_id}.explanation_de"),
                "en": _text(pattern.get("explanation_en"), f"{grammar_id}.explanation_en"),
            },
        },
    }


def _unique_lines(dialog: Sequence[Mapping[str, str]]) -> list[Mapping[str, str]]:
    unique: OrderedDict[str, Mapping[str, str]] = OrderedDict()
    for line in dialog:
        unique.setdefault(line["ko"], line)
    if len(unique) < 6:
        raise AuthoredSourceError("dialogue needs six distinct Korean lines for extracted learning items")
    return list(unique.values())


def _vocab(dialog: Sequence[Mapping[str, str]]) -> list[dict[str, Any]]:
    return [
        {
            "korean": line["ko"],
            "note": {"ko": "장면 핵심 표현", "de": line["de"], "en": line["en"]},
        }
        for line in _unique_lines(dialog)[:6]
    ]


def _quests(scenario_id: str, dialog: Sequence[Mapping[str, str]]) -> list[dict[str, Any]]:
    unique = _unique_lines(dialog)
    heard = next((line for line in unique if line["speaker"] != "user"), unique[0])
    player_lines = [line for line in unique if line["speaker"] == "user"]
    translated = player_lines[0]
    build = player_lines[-1]

    hearing_options = [heard] + [line for line in unique if line is not heard][:3]
    korean_options = [translated] + [line for line in unique if line is not translated][:3]
    distractors = [line["ko"] for line in unique if line is not build][:3]
    return [
        {
            "id": f"quest_{scenario_id}_01",
            "type": "hoerverstehen",
            "data": {
                "audioKo": heard["ko"],
                "options": [
                    {"de": line["de"], "en": line["en"]} for line in hearing_options
                ],
                "correctIndex": 0,
            },
        },
        {
            "id": f"quest_{scenario_id}_02",
            "type": "uebersetzen",
            "data": {
                "promptDe": translated["de"],
                "promptEn": translated["en"],
                "options": [{"ko": line["ko"]} for line in korean_options],
                "correctIndex": 0,
            },
        },
        {
            "id": f"quest_{scenario_id}_03",
            "type": "satzBauen",
            "data": {
                "targetKo": build["ko"],
                "audioKo": build["ko"],
                "promptDe": build["de"],
                "promptEn": build["en"],
                "distractors": distractors,
            },
        },
    ]


def _audit() -> dict[str, Any]:
    def pending(note: str) -> dict[str, Any]:
        return {"verdict": "pending", "notes": [note]}

    return {
        "criticalErrors": [],
        "accuracy": pending("Awaiting the hash-bound model and Jin review receipts."),
        "naturalness": pending("Awaiting the hash-bound model and Jin review receipts."),
        "pragmatics": pending("Awaiting the hash-bound model and Jin review receipts."),
        "relationship": pending("Awaiting the hash-bound model and Jin review receipts."),
        "cefr": pending("Awaiting the hash-bound model and Jin review receipts."),
        "warnings": [],
        "provenance": "materialization_pending_external_audit",
    }


def materialize_one(
    *,
    source: Mapping[str, Any],
    brief: pipeline.ScenarioBrief,
    concepts_by_unit: Mapping[str, list[str]],
    grammar_patterns: Sequence[Mapping[str, Any]],
    sources: pipeline.CorpusSources,
) -> dict[str, Any]:
    if source.get("id") != brief.scenario_id:
        raise AuthoredSourceError("authored source and brief IDs differ")
    dialog = _dialog(source, brief)
    combined_ko = "\n".join(line["ko"] for line in dialog)
    try:
        grammar = _grammar_for(
            level=brief.level,
            korean=combined_ko,
            patterns=grammar_patterns,
        )
    except AuthoredSourceError as error:
        raise AuthoredSourceError(f"{brief.scenario_id}: {error}") from error
    concepts = concepts_by_unit.get(brief.course_unit_id)
    if not concepts:
        raise AuthoredSourceError(f"{brief.scenario_id} course unit has no known concepts")
    title_support = _localized(source.get("title"), f"{brief.scenario_id}.title", korean=False)
    intro = _localized(source.get("intro"), f"{brief.scenario_id}.intro")
    culture_note = source.get("culturalNote")
    if culture_note is not None:
        note = _map(culture_note, f"{brief.scenario_id}.culturalNote")
        culture_note = {
            "title": _localized(note.get("title"), f"{brief.scenario_id}.culturalNote.title"),
            "body": _localized(note.get("body"), f"{brief.scenario_id}.culturalNote.body"),
        }
    shelf = SHELF_BY_BUCKET.get(brief.level, {}).get(brief.portfolio_bucket)
    if shelf is None:
        raise AuthoredSourceError(
            f"no shelf mapping for {brief.level}:{brief.portfolio_bucket}"
        )
    scenario = {
        "id": brief.scenario_id,
        "level": brief.level,
        "emoji": EMOJI_BY_BACKDROP[str(brief.raw["backdrop"])],
        "register": brief.raw["register"],
        "speechStyle": brief.raw["register"],
        "title": {"ko": brief.raw["titleKo"], "de": title_support["de"], "en": title_support["en"]},
        "intro": intro,
        "courseUnitId": brief.course_unit_id,
        "playerCharacterId": brief.player_character_id,
        "participantIds": list(brief.participant_ids),
        "relationshipContext": brief.raw["relationship"],
        "intent": brief.raw["playerGoal"],
        "shelf": shelf,
        "backdrop": brief.raw["backdrop"],
        "vocab": _vocab(dialog),
        "conceptIds": concepts,
        "surfaceFormIds": [],
        "grammarIds": [grammar["id"]],
        "grammarBlock": grammar["block"],
        "dialog": dialog,
        "quests": _quests(brief.scenario_id, dialog),
        "culturalNote": culture_note,
        "xpReward": XP_BY_LEVEL[brief.level],
    }
    candidate = {
        "kind": "scenario_candidate",
        "scenarioId": brief.scenario_id,
        "scenario": scenario,
        "audit": _audit(),
        "editorialSource": "canonical_scenarios/authored",
    }
    report = pipeline.validate_candidate(candidate, brief, sources)
    report.require_ok()
    candidate["audit"]["warnings"] = report.warnings
    return candidate


def materialize_level(
    *,
    level: str,
    root: Path = ROOT,
    output: Path = DEFAULT_OUTPUT,
    regression: bool = False,
) -> list[Path]:
    normalized = level.lower()
    if normalized not in pipeline.LEVELS:
        raise AuthoredSourceError(f"unknown level: {level}")
    source_name = f"regression_{normalized}.json" if regression else f"{normalized}.json"
    authored = _load_authored(AUTHORED_DIR / source_name)
    if regression:
        main_sources = {
            item["id"]: item for item in _load_authored(AUTHORED_DIR / f"{normalized}.json")
        }
        resolved: list[dict[str, Any]] = []
        for item in authored:
            copy_from = item.get("copyFrom")
            if copy_from is None:
                resolved.append(item)
                continue
            if not isinstance(copy_from, str) or copy_from not in main_sources:
                raise AuthoredSourceError(
                    f"{item['id']} references unknown same-level copyFrom {copy_from!r}"
                )
            inherited = json.loads(json.dumps(main_sources[copy_from], ensure_ascii=False))
            inherited["id"] = item["id"]
            for optional in ("title", "intro", "dialog", "culturalNote"):
                if optional in item:
                    inherited[optional] = item[optional]
            resolved.append(inherited)
        authored = resolved
    sources = pipeline.load_sources(root)
    briefs = sources.regression_briefs if regression else sources.briefs
    expected = [brief for brief in briefs if brief.level == normalized]
    by_id = {item["id"]: item for item in authored}
    expected_ids = {brief.scenario_id for brief in expected}
    if set(by_id) != expected_ids:
        missing = sorted(expected_ids - set(by_id))
        extra = sorted(set(by_id) - expected_ids)
        raise AuthoredSourceError(
            f"{source_name} ID mismatch; missing={missing}, extra={extra}"
        )
    patterns = _load_grammar_patterns(root)
    concepts = _concepts_by_unit(root)
    output_root = output if output.is_absolute() else root / output
    target = output_root / normalized
    target.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    for brief in expected:
        candidate = materialize_one(
            source=by_id[brief.scenario_id],
            brief=brief,
            concepts_by_unit=concepts,
            grammar_patterns=patterns,
            sources=sources,
        )
        path = target / f"{brief.scenario_id}.json"
        path.write_text(pipeline.json_text(candidate), encoding="utf-8")
        written.append(path)
    return written


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("level", choices=pipeline.LEVELS)
    parser.add_argument("--regression", action="store_true")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    output = args.output or (DEFAULT_REGRESSION_OUTPUT if args.regression else DEFAULT_OUTPUT)
    try:
        written = materialize_level(
            level=args.level,
            output=output,
            regression=args.regression,
        )
    except (pipeline.CorpusError, AuthoredSourceError) as error:
        print(error, file=sys.stderr)
        return 1
    print(json.dumps({"level": args.level, "regression": args.regression, "count": len(written)}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
