#!/usr/bin/env python3
"""Offline, human-gated pipeline for the 120-scenario canonical corpus.

The module deliberately does not call an LLM, TTS provider, Firebase, or any
other network service.  It prepares deterministic prompt packets, validates
strict JSON responses, renders review material, records an explicit Jin
approval receipt, and only then permits a level shard to be promoted.

Korean is the sole semantic source. German and English are independent
localizations of the same communicative event, never source languages for one
another.
"""

from __future__ import annotations

from collections import Counter
from dataclasses import dataclass, field
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import tempfile
from typing import Any, Iterable, Mapping, Sequence


ROOT = Path(__file__).resolve().parents[2]
CANONICAL_RELATIVE = Path("tools/content_factory/canonical_scenarios")
PROMPT_RELATIVE = Path("tools/content_factory/prompts/scenario_corpus_master_v1.md")
LEVELS = ("a1", "a2", "b1", "b2", "c1", "c2")
GENERATION_ID = "canonical_120_v1"
LEGACY_GENERATION_ID = "legacy_413_v1"
APPROVAL_REVIEWER = "Jin"
ALLOWED_VOICES = frozenset(("female", "male"))
TTS_CACHE_REVISION = "v3"
TTS_READINESS_KIND = "scenario_tts_storage_verification"
ALLOWED_REGISTERS = frozenset(("polite", "casual", "business", "intimate"))
AUTO_VOICE_SALT = "hangul-sori-auto-voice-v1"
AUDIO_KO_QUESTS = frozenset(("satzBauen", "batchimDrop", "hoerverstehen"))
ALLOWED_QUEST_TYPES = frozenset(
    (
        "uebersetzen",
        "hoerverstehen",
        "luecken",
        "satzBauen",
        "diktat",
        "particlePop",
        "batchimDrop",
    )
)
ALLOWED_BACKDROPS = frozenset(
    (
        "airport",
        "bank",
        "cafe",
        "convenience",
        "directions",
        "home",
        "hotel",
        "market",
        "office",
        "pharmacy",
        "restaurant",
        "salon",
        "station",
        "taxi",
    )
)

ABSTRACT_BLOCKERS = {
    "a1": ("이해관계자", "제도적", "담론", "정당성", "구조적 문제", "프레이밍"),
    "a2": ("이해관계자", "담론 권력", "제도적 정당성", "프레이밍 효과"),
}
GLOBAL_REJECTED_PHRASES = (
    "대리 수치가 느껴",
    "한국인은 원래",
    "한국 사람들은 원래",
    "한국에서는 항상",
)
MODEL_APPROVAL_KEYS = frozenset(
    (
        "approved",
        "approvedBy",
        "approvedAt",
        "jinDecision",
        "humanReviewStatus",
    )
)
RUNTIME_WIRE_SCENARIO_IDS = frozenset(
    (
        "airport_arrival",
        "introduce_yourself",
        "first_class_meeting",
        "bunshik_tteokbokki",
        "taxi_kakao",
    )
)
RUNTIME_WIRE_LINKS = {
    "introduce_yourself": {
        "courseUnitId": "a1_02_self_intro_identity",
        "contentLinkId": "link:94c139e887716700674589b2",
    },
    "bunshik_tteokbokki": {
        "courseUnitId": "a1_04_order_request_object",
        "contentLinkId": "link:e6a9f1197b48c79f58655c9a",
    },
    "taxi_kakao": {
        "courseUnitId": "a1_06_transport_directions",
        "contentLinkId": "link:49a189a1b8b9e4fa022a4557",
    },
}


class CorpusError(ValueError):
    """Raised when a corpus contract or approval gate is violated."""


def _duplicate_safe_object(pairs: Sequence[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise CorpusError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def read_json(path: Path) -> Any:
    try:
        return json.loads(
            path.read_text(encoding="utf-8"),
            object_pairs_hook=_duplicate_safe_object,
        )
    except (OSError, json.JSONDecodeError) as error:
        raise CorpusError(f"cannot read JSON {path}: {error}") from error


def json_text(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2, sort_keys=False) + "\n"


def _nonempty(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise CorpusError(f"{label} must be a nonempty string")
    return value.strip()


def _string_list(value: Any, label: str, *, allow_empty: bool = False) -> tuple[str, ...]:
    if not isinstance(value, list) or (not allow_empty and not value):
        suffix = "a list" if allow_empty else "a nonempty list"
        raise CorpusError(f"{label} must be {suffix}")
    result = tuple(_nonempty(item, f"{label}[]") for item in value)
    if len(result) != len(set(result)):
        raise CorpusError(f"{label} contains duplicates")
    return result


def _map(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise CorpusError(f"{label} must be an object")
    return value


def _canonical_dir(root: Path) -> Path:
    return root / CANONICAL_RELATIVE


@dataclass(frozen=True)
class LevelProfile:
    code: str
    korean_course_level: int
    content_scope: str
    social_range: str
    cognitive_tasks: tuple[str, ...]
    allowed_language: Mapping[str, Any]
    portfolio: Mapping[str, int]
    raw: Mapping[str, Any] = field(repr=False)

    @classmethod
    def from_json(cls, raw: Mapping[str, Any]) -> "LevelProfile":
        code = _nonempty(raw.get("code"), "level.code").lower()
        if code not in LEVELS:
            raise CorpusError(f"unknown level profile: {code}")
        course_level = raw.get("koreanCourseLevel")
        if not isinstance(course_level, int) or not 1 <= course_level <= 6:
            raise CorpusError(f"{code}.koreanCourseLevel must be 1..6")
        portfolio = _map(raw.get("portfolio"), f"{code}.portfolio")
        if any(not isinstance(value, int) or value <= 0 for value in portfolio.values()):
            raise CorpusError(f"{code}.portfolio values must be positive integers")
        return cls(
            code=code,
            korean_course_level=course_level,
            content_scope=_nonempty(raw.get("contentScope"), f"{code}.contentScope"),
            social_range=_nonempty(raw.get("socialRange"), f"{code}.socialRange"),
            cognitive_tasks=_string_list(raw.get("cognitiveTasks"), f"{code}.cognitiveTasks"),
            allowed_language=_map(raw.get("allowedLanguage"), f"{code}.allowedLanguage"),
            portfolio={str(key): int(value) for key, value in portfolio.items()},
            raw=dict(raw),
        )


@dataclass(frozen=True)
class CharacterProfile:
    character_id: str
    display_name_ko: str
    voice: str
    raw: Mapping[str, Any] = field(repr=False)

    @classmethod
    def from_json(cls, raw: Mapping[str, Any]) -> "CharacterProfile":
        names = _map(raw.get("displayNames"), "character.displayNames")
        voice = _nonempty(raw.get("voice"), "character.voice")
        if voice not in ALLOWED_VOICES:
            raise CorpusError(f"unsupported character voice: {voice}")
        return cls(
            character_id=_nonempty(raw.get("id"), "character.id"),
            display_name_ko=_nonempty(names.get("ko"), "character.displayNames.ko"),
            voice=voice,
            raw=dict(raw),
        )


@dataclass(frozen=True)
class ScenarioBrief:
    scenario_id: str
    level: str
    portfolio_bucket: str
    course_unit_id: str
    player_character_id: str
    participant_ids: tuple[str, ...]
    checkpoint_for_unit: bool
    must_include_ko: tuple[str, ...]
    must_avoid_ko: tuple[str, ...]
    raw: Mapping[str, Any] = field(repr=False)

    @classmethod
    def from_json(cls, raw: Mapping[str, Any], *, label: str = "brief") -> "ScenarioBrief":
        level = _nonempty(raw.get("level"), f"{label}.level").lower()
        if level not in LEVELS:
            raise CorpusError(f"{label} has unknown level {level}")
        player = _nonempty(raw.get("playerCharacterId"), f"{label}.playerCharacterId")
        participants = _string_list(raw.get("participantIds"), f"{label}.participantIds")
        if player not in participants:
            raise CorpusError(f"{label}.participantIds must contain the player character")
        checkpoint = raw.get("checkpointForUnit", False)
        if not isinstance(checkpoint, bool):
            raise CorpusError(f"{label}.checkpointForUnit must be boolean")
        return cls(
            scenario_id=_nonempty(raw.get("id"), f"{label}.id"),
            level=level,
            portfolio_bucket=_nonempty(raw.get("portfolioBucket"), f"{label}.portfolioBucket"),
            course_unit_id=_nonempty(raw.get("courseUnitId"), f"{label}.courseUnitId"),
            player_character_id=player,
            participant_ids=participants,
            checkpoint_for_unit=checkpoint,
            must_include_ko=_string_list(
                raw.get("mustIncludeKo", []),
                f"{label}.mustIncludeKo",
                allow_empty=True,
            ),
            must_avoid_ko=_string_list(
                raw.get("mustAvoidKo", []),
                f"{label}.mustAvoidKo",
                allow_empty=True,
            ),
            raw=dict(raw),
        )


@dataclass(frozen=True)
class ScenarioCorpusManifest:
    generation_id: str
    expected_total: int
    promotion_order: tuple[str, ...]
    anchor_scenario_ids: Mapping[str, str]
    raw: Mapping[str, Any] = field(repr=False)

    @classmethod
    def from_json(cls, raw: Mapping[str, Any]) -> "ScenarioCorpusManifest":
        expected_total = raw.get("expectedScenarioCount")
        if not isinstance(expected_total, int) or expected_total <= 0:
            raise CorpusError("manifest.expectedScenarioCount must be positive")
        order = _string_list(raw.get("promotionOrder"), "manifest.promotionOrder")
        if order != LEVELS:
            raise CorpusError("manifest.promotionOrder must be A1 through C2")
        return cls(
            generation_id=_nonempty(raw.get("generationId"), "manifest.generationId"),
            expected_total=expected_total,
            promotion_order=order,
            anchor_scenario_ids={
                str(key): _nonempty(value, f"manifest.anchorScenarioIds.{key}")
                for key, value in _map(
                    raw.get("anchorScenarioIds"), "manifest.anchorScenarioIds"
                ).items()
            },
            raw=dict(raw),
        )


@dataclass
class ValidationReport:
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)

    @property
    def ok(self) -> bool:
        return not self.errors

    def require_ok(self) -> None:
        if self.errors:
            raise CorpusError("; ".join(self.errors))

    def to_json(self) -> dict[str, Any]:
        return {"ok": self.ok, "errors": self.errors, "warnings": self.warnings}


@dataclass(frozen=True)
class CorpusSources:
    manifest: ScenarioCorpusManifest
    level_profiles: Mapping[str, LevelProfile]
    characters: Mapping[str, CharacterProfile]
    role_voices: Mapping[str, str]
    role_names_ko: Mapping[str, str]
    briefs: tuple[ScenarioBrief, ...]
    regression_briefs: tuple[ScenarioBrief, ...]
    course_unit_blueprint: tuple[Mapping[str, Any], ...]
    approvals: Mapping[str, Any]


def load_sources(root: Path = ROOT) -> CorpusSources:
    base = _canonical_dir(root)
    manifest = ScenarioCorpusManifest.from_json(read_json(base / "scenario_corpus_manifest.json"))
    level_root = _map(read_json(base / "level_profiles.json"), "level_profiles root")
    level_profiles = {
        profile.code: profile
        for profile in (
            LevelProfile.from_json(_map(item, "level profile"))
            for item in level_root.get("levels", [])
        )
    }
    character_root = _map(read_json(base / "character_profiles.json"), "character root")
    characters = {
        profile.character_id: profile
        for profile in (
            CharacterProfile.from_json(_map(item, "character profile"))
            for item in character_root.get("recurringCharacters", [])
        )
    }
    role_root = _map(character_root.get("runtimeRoleProfiles"), "runtimeRoleProfiles")
    role_voices: dict[str, str] = {}
    role_names: dict[str, str] = {}
    for role_id, raw_role in role_root.items():
        role = _map(raw_role, f"runtimeRoleProfiles.{role_id}")
        voice = _nonempty(role.get("voice"), f"runtimeRoleProfiles.{role_id}.voice")
        if voice not in ALLOWED_VOICES:
            raise CorpusError(f"runtime role {role_id} has unsupported voice {voice}")
        role_voices[str(role_id)] = voice
        role_names[str(role_id)] = _nonempty(
            role.get("displayNameKo"), f"runtimeRoleProfiles.{role_id}.displayNameKo"
        )
    brief_root = _map(read_json(base / "scenario_briefs.json"), "scenario_briefs root")
    briefs = tuple(
        ScenarioBrief.from_json(_map(item, "brief"), label=f"brief[{index}]")
        for index, item in enumerate(brief_root.get("scenarios", []))
    )
    regression_root = _map(read_json(base / "regression_briefs.json"), "regression root")
    regression = tuple(
        ScenarioBrief.from_json(_map(item, "regression brief"), label=f"regression[{index}]")
        for index, item in enumerate(regression_root.get("scenarios", []))
    )
    blueprint_root = _map(read_json(base / "course_unit_blueprint.json"), "blueprint root")
    blueprint = tuple(_map(item, "course blueprint item") for item in blueprint_root.get("courseUnits", []))
    approvals = _map(read_json(base / "approvals.json"), "approvals root")
    return CorpusSources(
        manifest=manifest,
        level_profiles=level_profiles,
        characters=characters,
        role_voices=role_voices,
        role_names_ko=role_names,
        briefs=briefs,
        regression_briefs=regression,
        course_unit_blueprint=blueprint,
        approvals=approvals,
    )


def validate_portfolio(root: Path = ROOT) -> ValidationReport:
    report = ValidationReport()
    try:
        sources = load_sources(root)
    except CorpusError as error:
        report.errors.append(str(error))
        return report

    if sources.manifest.generation_id != GENERATION_ID:
        report.errors.append(f"generation must be {GENERATION_ID}")
    if set(sources.level_profiles) != set(LEVELS):
        report.errors.append("level profiles must cover A1-C2 exactly")
    if len(sources.characters) != 7:
        report.errors.append("character bible must contain exactly seven recurring characters")
    if len(sources.briefs) != sources.manifest.expected_total or len(sources.briefs) != 120:
        report.errors.append("canonical portfolio must contain exactly 120 scenario briefs")

    brief_ids = [brief.scenario_id for brief in sources.briefs]
    if len(brief_ids) != len(set(brief_ids)):
        report.errors.append("canonical scenario IDs must be unique")
    regression_ids = [brief.scenario_id for brief in sources.regression_briefs]
    if len(regression_ids) != len(set(regression_ids)):
        report.errors.append("regression scenario IDs must be unique")
    if set(brief_ids).intersection(regression_ids):
        report.errors.append("regression IDs must not overlap runtime candidate IDs")

    curriculum_path = root / "assets/data/curriculum_manifest.json"
    curriculum = _map(read_json(curriculum_path), "curriculum manifest")
    current_units = {
        _nonempty(item.get("id"), "course unit id"): item
        for item in (_map(raw, "course unit") for raw in curriculum.get("courseUnits", []))
    }
    if len(current_units) != 48:
        report.errors.append(f"current curriculum must keep 48 units, found {len(current_units)}")

    blueprint_ids = [_nonempty(item.get("unitId"), "blueprint.unitId") for item in sources.course_unit_blueprint]
    if len(blueprint_ids) != 48 or set(blueprint_ids) != set(current_units):
        report.errors.append("course blueprint must cover the existing 48 unit IDs exactly")
    blueprint_by_unit = {
        _nonempty(item.get("unitId"), "blueprint.unitId"): item
        for item in sources.course_unit_blueprint
    }

    recurring_ids = set(sources.characters)
    participant_ids = recurring_ids | set(sources.role_voices)
    checkpoints_by_unit = Counter()
    for level in LEVELS:
        level_briefs = [brief for brief in sources.briefs if brief.level == level]
        if len(level_briefs) != 20:
            report.errors.append(f"{level.upper()} must contain exactly 20 briefs")
        profile = sources.level_profiles.get(level)
        if profile is None:
            continue
        actual_distribution = Counter(brief.portfolio_bucket for brief in level_briefs)
        if dict(actual_distribution) != dict(profile.portfolio):
            report.errors.append(
                f"{level.upper()} portfolio distribution differs: {dict(actual_distribution)}"
            )
        if sum(profile.portfolio.values()) != 20:
            report.errors.append(f"{level.upper()} profile portfolio must total 20")
        for brief in level_briefs:
            if brief.course_unit_id not in current_units:
                report.errors.append(f"{brief.scenario_id}: unknown course unit {brief.course_unit_id}")
            elif str(current_units[brief.course_unit_id].get("level", "")).lower() != level:
                report.errors.append(f"{brief.scenario_id}: course unit level mismatch")
            unknown = set(brief.participant_ids) - participant_ids
            if unknown:
                report.errors.append(f"{brief.scenario_id}: participants lack voice profiles {sorted(unknown)}")
            if brief.checkpoint_for_unit:
                checkpoints_by_unit[brief.course_unit_id] += 1

    for unit_id in current_units:
        count = checkpoints_by_unit[unit_id]
        if count != 1:
            report.errors.append(f"{unit_id}: expected one canonical checkpoint brief, found {count}")
        blueprint = blueprint_by_unit.get(unit_id)
        if blueprint is None:
            continue
        if str(blueprint.get("level", "")).lower() != str(
            current_units[unit_id].get("level", "")
        ).lower():
            report.errors.append(f"{unit_id}: blueprint level differs from the retained unit")
        flagged = sorted(
            brief.scenario_id
            for brief in sources.briefs
            if brief.course_unit_id == unit_id and brief.checkpoint_for_unit
        )
        if flagged != [str(blueprint.get("checkpointScenarioId", ""))]:
            report.errors.append(f"{unit_id}: blueprint checkpoint differs from its flagged brief")
        for field in ("title", "canDo"):
            localized = blueprint.get(field)
            if not isinstance(localized, dict) or any(
                not isinstance(localized.get(language), str)
                or not localized.get(language, "").strip()
                for language in ("ko", "de", "en")
            ):
                report.errors.append(f"{unit_id}: blueprint {field} must contain ko/de/en")

    for anchor, scenario_id in sources.manifest.anchor_scenario_ids.items():
        if scenario_id not in brief_ids:
            report.errors.append(f"missing anchor {anchor}: {scenario_id}")
    missing_wire_ids = RUNTIME_WIRE_SCENARIO_IDS.difference(brief_ids)
    if missing_wire_ids:
        report.errors.append(
            f"onboarding or weekly wire scenario IDs are missing: {sorted(missing_wire_ids)}"
        )

    by_id = {brief.scenario_id: brief for brief in sources.briefs}
    required_anchor_text = {
        "bakery_queue": ("아, 죄송합니다. 몰랐어요",),
        "email_attachment_twice": ("첨부파일", "또 안 붙였"),
        "company_instagram_wrong_account": ("회사 인스타그램",),
        "filming_permission": ("촬영", "괜찮으세요"),
        "after_hours_messages": ("퇴근", "연락"),
        "hidden_gem_local_impact": ("숨은 명소", "지역"),
        "fremdschaemen_live": ("내가 다 민망", "보는 내가 다 부끄러"),
        "taxi_slow_down": ("기사님, 천천히 좀 가 주실 수 있을까요?",),
    }
    for scenario_id, fragments in required_anchor_text.items():
        brief = by_id.get(scenario_id)
        if brief is None:
            report.errors.append(f"missing fixed brief {scenario_id}")
            continue
        combined = " ".join(brief.must_include_ko)
        for fragment in fragments:
            if fragment not in combined:
                report.errors.append(f"{scenario_id}: must include anchor text {fragment}")

    if len(sources.regression_briefs) != 12:
        report.errors.append("non-runtime regression corpus must contain exactly 12 briefs")
    regression_counts = Counter(
        (brief.raw.get("regressionTheme"), brief.level)
        for brief in sources.regression_briefs
    )
    for theme in ("mistake_embarrassment_repair", "digital_contact_permission_responsibility"):
        for level in LEVELS:
            if regression_counts[(theme, level)] != 1:
                report.errors.append(f"regression theme {theme} must contain one {level.upper()} brief")
    if any(brief.raw.get("runtimeEligible") is not False for brief in sources.regression_briefs):
        report.errors.append("every regression brief must be explicitly runtimeEligible=false")

    levels = _map(sources.approvals.get("levels"), "approvals.levels")
    if set(levels) != set(LEVELS):
        report.errors.append("approval ledger must cover A1-C2")
    for level, row in levels.items():
        approval = _map(row, f"approvals.{level}")
        if approval.get("decision") not in ("pending", "approved", "rejected", "revise"):
            report.errors.append(f"approvals.{level} has an unknown decision")
        if approval.get("decision") == "approved" and approval.get("reviewer") != APPROVAL_REVIEWER:
            report.errors.append(f"approvals.{level} was not approved by Jin")
    return report


def _brief_for(sources: CorpusSources, scenario_id: str, *, regression: bool = False) -> ScenarioBrief:
    collection = sources.regression_briefs if regression else sources.briefs
    for brief in collection:
        if brief.scenario_id == scenario_id:
            return brief
    raise CorpusError(f"unknown scenario brief: {scenario_id}")


def build_prompt_packet(
    scenario_id: str,
    *,
    root: Path = ROOT,
    regression: bool = False,
) -> dict[str, Any]:
    sources = load_sources(root)
    validate_portfolio(root).require_ok()
    brief = _brief_for(sources, scenario_id, regression=regression)
    profile = sources.level_profiles[brief.level]
    recurring = [
        profile.raw
        for character_id, profile in sources.characters.items()
        if character_id in brief.participant_ids
    ]
    roles = {
        role_id: {
            "displayNameKo": sources.role_names_ko[role_id],
            "voice": sources.role_voices[role_id],
        }
        for role_id in brief.participant_ids
        if role_id in sources.role_voices
    }
    template = (root / PROMPT_RELATIVE).read_text(encoding="utf-8")
    shared_replacements = {
        "[LEVEL_PROFILE_JSON]": json.dumps(profile.raw, ensure_ascii=False, indent=2),
        "[SCENARIO_BRIEF_JSON]": json.dumps(brief.raw, ensure_ascii=False, indent=2),
        "[CHARACTER_PROFILES_JSON]": json.dumps(
            {"recurringCharacters": recurring, "sceneRoles": roles},
            ensure_ascii=False,
            indent=2,
        ),
    }
    shared_template = template
    for placeholder, value in shared_replacements.items():
        shared_template = shared_template.replace(placeholder, value)
    first_prompt = shared_template.replace("[PIPELINE_MODE]", "ko_scene").replace(
        "[STAGE_INPUT_JSON]", "null"
    )
    stages = [
        {
            "id": "ko_scene",
            "inputKind": "scenario_brief",
            "outputKind": "ko_scene_draft",
            "prompt": first_prompt,
        },
        {
            "id": "learning_extract",
            "inputKind": "ko_scene_draft",
            "outputKind": "learning_bundle_draft",
            "promptTemplate": shared_template.replace(
                "[PIPELINE_MODE]", "learning_extract"
            ),
        },
        {
            "id": "localize",
            "inputKind": "learning_bundle_draft",
            "outputKind": "localized_scenario_draft",
            "promptTemplate": shared_template.replace("[PIPELINE_MODE]", "localize"),
        },
        {
            "id": "audit",
            "inputKind": "localized_scenario_draft",
            "outputKind": "scenario_candidate",
            "promptTemplate": shared_template.replace("[PIPELINE_MODE]", "audit"),
        },
    ]
    return {
        "schemaVersion": 1,
        "kind": "scenario_prompt_packet",
        "pipelineVersion": 1,
        "generationId": sources.manifest.generation_id,
        "scenarioId": brief.scenario_id,
        "level": brief.level,
        "regressionOnly": regression,
        "externalApiAllowed": False,
        "modelMayApprove": False,
        "stages": stages,
    }


def render_stage_prompt(packet: Mapping[str, Any], stage_id: str, stage_input: Any) -> str:
    stages = packet.get("stages")
    if not isinstance(stages, list):
        raise CorpusError("prompt packet stages must be a list")
    stage = next((item for item in stages if isinstance(item, dict) and item.get("id") == stage_id), None)
    if stage is None:
        raise CorpusError(f"unknown prompt stage: {stage_id}")
    if stage_id == "ko_scene":
        return _nonempty(stage.get("prompt"), "ko_scene.prompt")
    template = _nonempty(stage.get("promptTemplate"), f"{stage_id}.promptTemplate")
    return template.replace(
        "[STAGE_INPUT_JSON]",
        json.dumps(stage_input, ensure_ascii=False, indent=2),
    )


def _walk_keys(value: Any) -> Iterable[str]:
    if isinstance(value, dict):
        for key, item in value.items():
            yield str(key)
            yield from _walk_keys(item)
    elif isinstance(value, list):
        for item in value:
            yield from _walk_keys(item)


def validate_candidate(
    payload: Mapping[str, Any],
    brief: ScenarioBrief,
    sources: CorpusSources,
) -> ValidationReport:
    report = ValidationReport()
    if payload.get("kind") != "scenario_candidate":
        report.errors.append("candidate.kind must be scenario_candidate")
    if payload.get("scenarioId") != brief.scenario_id:
        report.errors.append("candidate scenarioId differs from its brief")
    forbidden_approval_keys = MODEL_APPROVAL_KEYS.intersection(_walk_keys(payload))
    if forbidden_approval_keys:
        report.errors.append(
            f"model output contains human-only approval keys: {sorted(forbidden_approval_keys)}"
        )
    scenario = payload.get("scenario")
    if not isinstance(scenario, dict):
        report.errors.append("candidate.scenario must be an object")
        return report
    if scenario.get("id") != brief.scenario_id:
        report.errors.append("runtime scenario ID differs from its brief")
    if str(scenario.get("level", "")).lower() != brief.level:
        report.errors.append("runtime scenario level differs from its brief")
    if scenario.get("courseUnitId") != brief.course_unit_id:
        report.errors.append("runtime scenario courseUnitId differs from its brief")
    if scenario.get("playerCharacterId") != brief.player_character_id:
        report.errors.append("runtime playerCharacterId differs from its brief")
    if scenario.get("participantIds") != list(brief.participant_ids):
        report.errors.append("runtime participantIds differ from the locked brief order")
    if scenario.get("register") not in ALLOWED_REGISTERS:
        report.errors.append("runtime register is unsupported")
    if scenario.get("backdrop") not in ALLOWED_BACKDROPS:
        report.errors.append("runtime backdrop is not an existing scene category")
    for field in ("title", "intro"):
        localized = scenario.get(field)
        if not isinstance(localized, dict) or any(
            not isinstance(localized.get(language), str)
            or not localized.get(language, "").strip()
            for language in ("ko", "de", "en")
        ):
            report.errors.append(f"runtime {field} must contain nonempty ko/de/en")

    dialog = scenario.get("dialog")
    if not isinstance(dialog, list) or len(dialog) < 4:
        report.errors.append("scenario dialogue must contain at least four turns")
        return report
    if not any(isinstance(line, dict) and line.get("speaker") == "user" for line in dialog):
        report.errors.append("scenario must keep at least one speaker=user turn")

    known_speakers = set(brief.participant_ids) | {"user", "narrator"}
    all_ko: list[str] = []
    max_warning = int(sources.level_profiles[brief.level].allowed_language.get("maxKoCharsWarning", 80))
    for index, line in enumerate(dialog):
        if not isinstance(line, dict):
            report.errors.append(f"dialog[{index}] must be an object")
            continue
        speaker = str(line.get("speaker", "")).strip()
        if speaker not in known_speakers:
            report.errors.append(f"dialog[{index}] has unknown speaker {speaker!r}")
        if speaker == brief.player_character_id:
            report.errors.append(
                f"dialog[{index}] must use speaker=user for the player character"
            )
        for language in ("ko", "de", "en"):
            text = line.get(language)
            if not isinstance(text, str) or not text.strip():
                report.errors.append(f"dialog[{index}].{language} must be nonempty")
        korean = str(line.get("ko", "")).strip()
        all_ko.append(korean)
        if len(korean) > max_warning:
            report.warnings.append(
                f"dialog[{index}] Korean length {len(korean)} exceeds review warning {max_warning}"
            )

    combined_ko = "\n".join(all_ko)
    for phrase in brief.must_include_ko:
        if phrase not in combined_ko:
            report.errors.append(f"locked Korean beat is missing: {phrase}")
    for phrase in brief.must_avoid_ko:
        if phrase in combined_ko:
            report.errors.append(f"brief-forbidden Korean phrase is present: {phrase}")
    for phrase in GLOBAL_REJECTED_PHRASES:
        if phrase in combined_ko:
            report.errors.append(f"globally rejected Korean phrasing is present: {phrase}")
    for marker in ABSTRACT_BLOCKERS.get(brief.level, ()):
        if marker in combined_ko:
            report.errors.append(f"{brief.level.upper()} dialogue contains abstract-level blocker: {marker}")

    culture_note = scenario.get("culturalNote")
    if culture_note is not None:
        if not isinstance(culture_note, dict):
            report.errors.append("culturalNote must be null or an object")
        else:
            for field_name in ("title", "body"):
                localized = culture_note.get(field_name)
                if not isinstance(localized, dict):
                    report.errors.append(
                        f"culturalNote.{field_name} must be a localized object"
                    )
                    continue
                for language in ("ko", "de", "en"):
                    value = localized.get(language)
                    if not isinstance(value, str) or not value.strip():
                        report.errors.append(
                            f"culturalNote.{field_name}.{language} must be nonempty"
                        )
            serialized = json.dumps(culture_note, ensure_ascii=False)
            for phrase in GLOBAL_REJECTED_PHRASES[1:]:
                if phrase in serialized:
                    report.errors.append(
                        "culture note contains a fixed national generalization: "
                        f"{phrase}"
                    )

    quests = scenario.get("quests")
    if not isinstance(quests, list) or not quests:
        report.errors.append("scenario must contain at least one extracted quest")
    else:
        for index, quest in enumerate(quests):
            if not isinstance(quest, dict):
                report.errors.append(f"quests[{index}] must be an object")
                continue
            quest_type = quest.get("type")
            if not isinstance(quest_type, str) or not quest_type.strip():
                report.errors.append(f"quests[{index}].type must be nonempty")
                continue
            if quest_type not in ALLOWED_QUEST_TYPES:
                report.errors.append(
                    f"quests[{index}].type is not a supported runtime quest"
                )
            data = quest.get("data")
            if not isinstance(data, dict):
                report.errors.append(f"quests[{index}].data must be an object")
                continue
            if quest_type in AUDIO_KO_QUESTS and not str(
                data.get("audioKo") or ""
            ).strip():
                report.errors.append(
                    f"quests[{index}].data.audioKo is required for TTS playback"
                )
            if quest_type == "diktat" and not str(
                data.get("audioKo") or data.get("targetKo") or ""
            ).strip():
                report.errors.append(
                    f"quests[{index}] diktat requires audioKo or targetKo"
                )

    audit = payload.get("audit")
    if not isinstance(audit, dict):
        report.errors.append("candidate.audit must be an object")
    else:
        critical = audit.get("criticalErrors")
        if not isinstance(critical, list):
            report.errors.append("candidate.audit.criticalErrors must be a list")
        elif critical:
            report.errors.append("candidate still contains critical semantic errors")
        for axis in ("accuracy", "naturalness", "pragmatics", "relationship", "cefr"):
            if axis not in audit:
                report.errors.append(f"candidate.audit must include {axis}")
            elif not isinstance(audit[axis], dict) or audit[axis].get("verdict") != "pass":
                report.errors.append(f"candidate.audit.{axis}.verdict must be pass")
    return report


def load_and_validate_candidate(
    path: Path,
    *,
    root: Path = ROOT,
    regression: bool = False,
) -> tuple[dict[str, Any], ScenarioBrief, ValidationReport]:
    payload = _map(read_json(path), "candidate")
    scenario_id = _nonempty(payload.get("scenarioId"), "candidate.scenarioId")
    sources = load_sources(root)
    brief = _brief_for(sources, scenario_id, regression=regression)
    return payload, brief, validate_candidate(payload, brief, sources)


def _voice_for_speaker(
    speaker: str,
    brief: ScenarioBrief,
    sources: CorpusSources,
) -> str:
    resolved = brief.player_character_id if speaker == "user" else speaker
    character = sources.characters.get(resolved)
    if character is not None:
        return character.voice
    role_voice = sources.role_voices.get(resolved)
    if role_voice is not None:
        return role_voice
    raise CorpusError(f"speaker {speaker!r} has no character or role voice profile")


def _auto_voice(text: str) -> str:
    """Match Dart TtsVoicePolicy and tool/generate_tts.py exactly."""

    digest = hashlib.sha1(f"{AUTO_VOICE_SALT}|{text.strip()}".encode("utf-8")).digest()
    return "male" if digest[0] & 1 else "female"


def _quest_tts_text(quest: Mapping[str, Any], *, label: str) -> tuple[str, str] | None:
    data = _map(quest.get("data"), f"{label}.data")
    quest_type = str(quest.get("type") or "")
    if quest_type in AUDIO_KO_QUESTS:
        raw_text = data.get("audioKo")
        path = "audioKo"
    elif quest_type == "diktat":
        raw_text = data.get("audioKo") or data.get("targetKo")
        path = "audioKo" if data.get("audioKo") else "targetKo"
    elif quest_type == "particlePop":
        options = data.get("options")
        raw_index = data.get("correctIndex", 0)
        if not isinstance(options, list) or type(raw_index) is not int:
            raise CorpusError(f"{label} has invalid particlePop options or correctIndex")
        if raw_index < 0 or raw_index >= len(options):
            raise CorpusError(f"{label}.correctIndex is outside options")
        raw_text = (
            str(data.get("prefix") or "")
            + str(options[raw_index])
            + str(data.get("suffix") or "")
        )
        path = "derivedFullSentence"
    else:
        return None
    if raw_text is None or not str(raw_text).strip():
        return None
    return str(raw_text).strip(), path


def build_tts_pending_manifest(
    candidates: Sequence[Mapping[str, Any]],
    *,
    root: Path = ROOT,
) -> dict[str, Any]:
    sources = load_sources(root)
    items: list[dict[str, Any]] = []
    seen: set[tuple[str, str]] = set()

    def add_item(
        *,
        scenario_id: str,
        path: str,
        speaker: str,
        resolved_character_id: str | None,
        voice: str,
        text: str,
        source: str,
    ) -> None:
        normalized_text = text.strip()
        key = (voice, normalized_text)
        if key in seen:
            return
        seen.add(key)
        digest = hashlib.sha1(f"{voice}|{normalized_text}".encode("utf-8")).hexdigest()
        items.append(
            {
                "scenarioId": scenario_id,
                "path": path,
                "source": source,
                "speaker": speaker,
                "resolvedCharacterId": resolved_character_id,
                "voice": voice,
                "text": normalized_text,
                "cachePath": f"tts/{TTS_CACHE_REVISION}/{voice}/{digest}.mp3",
                "status": "pending",
            }
        )

    for payload in candidates:
        brief = _brief_for(sources, _nonempty(payload.get("scenarioId"), "candidate.scenarioId"))
        report = validate_candidate(payload, brief, sources)
        report.require_ok()
        scenario = _map(payload.get("scenario"), "candidate.scenario")
        for index, raw_line in enumerate(scenario.get("dialog", [])):
            line = _map(raw_line, f"{brief.scenario_id}.dialog[{index}]")
            if line.get("speaker") == "narrator":
                continue
            text = _nonempty(line.get("ko"), f"{brief.scenario_id}.dialog[{index}].ko")
            voice = _voice_for_speaker(str(line.get("speaker")), brief, sources)
            add_item(
                scenario_id=brief.scenario_id,
                path=f"/dialog/{index}/ko",
                source="dialog",
                speaker=str(line.get("speaker")),
                resolved_character_id=(
                    brief.player_character_id
                    if line.get("speaker") == "user"
                    else str(line.get("speaker"))
                ),
                voice=voice,
                text=text,
            )
        for index, raw_quest in enumerate(scenario.get("quests", [])):
            quest = _map(raw_quest, f"{brief.scenario_id}.quests[{index}]")
            resolved = _quest_tts_text(
                quest,
                label=f"{brief.scenario_id}.quests[{index}]",
            )
            if resolved is None:
                continue
            text, field = resolved
            voice = _auto_voice(text)
            add_item(
                scenario_id=brief.scenario_id,
                path=f"/quests/{index}/data/{field}",
                source="quest",
                speaker="auto",
                resolved_character_id=None,
                voice=voice,
                text=text,
            )
    levels = sorted(
        {
            str(_map(payload.get("scenario"), "candidate.scenario").get("level", "")).lower()
            for payload in candidates
        }
    )
    scope = levels[0] if len(levels) == 1 and levels[0] in LEVELS else "corpus"
    return {
        "schemaVersion": 1,
        "kind": "scenario_tts_pending_manifest",
        "generationId": sources.manifest.generation_id,
        "scope": scope,
        "candidateSetSha256": candidate_set_hash(candidates),
        "cacheRevision": TTS_CACHE_REVISION,
        "synthesisRequested": False,
        "uploadRequested": False,
        "releaseGate": "blocked_until_all_items_exist",
        "count": len(items),
        "items": items,
    }


def candidate_set_hash(candidates: Sequence[Mapping[str, Any]]) -> str:
    canonical = json.dumps(
        sorted(candidates, key=lambda item: str(item.get("scenarioId"))),
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def tts_pending_manifest_hash(manifest: Mapping[str, Any]) -> str:
    canonical = json.dumps(
        manifest,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def assert_tts_ready_for_promotion(
    *,
    level: str,
    candidates: Sequence[Mapping[str, Any]],
    manifest: Mapping[str, Any],
    receipt_path: Path | None,
    runtime_write_reviewer: str | None,
    root: Path = ROOT,
) -> dict[str, Any]:
    """Require an exact, read-only Storage verification before runtime writes."""

    normalized = level.lower()
    if runtime_write_reviewer != APPROVAL_REVIEWER:
        raise CorpusError(
            "runtime write requires an explicit --runtime-write-reviewer Jin authorization"
        )
    if receipt_path is None:
        raise CorpusError("runtime write requires a TTS readiness receipt")
    target = receipt_path if receipt_path.is_absolute() else root / receipt_path
    receipt = _map(read_json(target), "TTS readiness receipt")
    expected = {
        "schemaVersion": 1,
        "kind": TTS_READINESS_KIND,
        "generationId": GENERATION_ID,
        "scope": normalized,
        "candidateSetSha256": candidate_set_hash(candidates),
        "ttsManifestSha256": tts_pending_manifest_hash(manifest),
        "expectedCount": manifest.get("count"),
        "cacheRevision": TTS_CACHE_REVISION,
        "verificationMode": "firebase_storage_listing",
    }
    mismatches = [
        f"{key}: expected {value!r}, got {receipt.get(key)!r}"
        for key, value in expected.items()
        if receipt.get(key) != value
    ]
    if receipt.get("missingCount") != 0:
        mismatches.append(
            f"missingCount: expected 0, got {receipt.get('missingCount')!r}"
        )
    if receipt.get("verifiedCachePathCount") != manifest.get("count"):
        mismatches.append(
            "verifiedCachePathCount must equal the exact pending-manifest count"
        )
    if mismatches:
        raise CorpusError(
            "TTS readiness receipt does not match this approved level: "
            + "; ".join(mismatches)
        )
    return receipt


def candidate_paths_for_level(directory: Path, level: str, sources: CorpusSources) -> list[Path]:
    normalized = level.lower()
    expected = sorted(brief.scenario_id for brief in sources.briefs if brief.level == normalized)
    paths = [directory / normalized / f"{scenario_id}.json" for scenario_id in expected]
    missing = [str(path) for path in paths if not path.exists()]
    if missing:
        raise CorpusError(f"missing {len(missing)} candidate files; first: {missing[0]}")
    return paths


def load_level_candidates(
    directory: Path,
    level: str,
    *,
    root: Path = ROOT,
) -> list[dict[str, Any]]:
    sources = load_sources(root)
    candidates: list[dict[str, Any]] = []
    for path in candidate_paths_for_level(directory, level, sources):
        payload, brief, report = load_and_validate_candidate(path, root=root)
        if brief.level != level.lower():
            report.errors.append(f"{path}: candidate is not in {level.upper()}")
        report.require_ok()
        candidates.append(payload)
    if len(candidates) != 20:
        raise CorpusError(f"{level.upper()} approval requires exactly 20 valid candidates")
    return candidates


def load_corpus_candidates(
    directory: Path,
    *,
    root: Path = ROOT,
) -> list[dict[str, Any]]:
    """Load exactly the locked 120 release candidates and reject extras."""

    sources = load_sources(root)
    candidates: list[dict[str, Any]] = []
    expected_paths: set[Path] = set()
    for level in LEVELS:
        paths = candidate_paths_for_level(directory, level, sources)
        expected_paths.update(path.resolve() for path in paths)
        candidates.extend(load_level_candidates(directory, level, root=root))

    actual_paths = {
        path.resolve()
        for level in LEVELS
        for path in (directory / level).glob("*.json")
        if path.is_file()
    }
    if actual_paths != expected_paths:
        missing = sorted(str(path) for path in expected_paths - actual_paths)
        extras = sorted(str(path) for path in actual_paths - expected_paths)
        raise CorpusError(
            "candidate directory differs from the locked 120-file set; "
            f"missing={missing[:3]}, extras={extras[:3]}"
        )

    scenario_ids = [
        _nonempty(payload.get("scenarioId"), "candidate.scenarioId")
        for payload in candidates
    ]
    if len(candidates) != sources.manifest.expected_total:
        raise CorpusError(
            "corpus candidate count differs from manifest: "
            f"{len(candidates)} != {sources.manifest.expected_total}"
        )
    duplicates = sorted(
        scenario_id
        for scenario_id, count in Counter(scenario_ids).items()
        if count > 1
    )
    if duplicates:
        raise CorpusError(f"duplicate corpus candidate IDs: {duplicates[:10]}")
    if not RUNTIME_WIRE_SCENARIO_IDS.issubset(scenario_ids):
        raise CorpusError(
            "canonical corpus is missing runtime wire scenarios: "
            f"{sorted(RUNTIME_WIRE_SCENARIO_IDS - set(scenario_ids))}"
        )
    return candidates


def load_regression_candidates(
    directory: Path,
    *,
    root: Path = ROOT,
) -> list[dict[str, Any]]:
    """Load the 12 non-runtime regression candidates in locked order."""

    sources = load_sources(root)
    candidates: list[dict[str, Any]] = []
    for brief in sources.regression_briefs:
        path = directory / brief.level / f"{brief.scenario_id}.json"
        if not path.exists():
            raise CorpusError(f"missing regression candidate: {path}")
        payload, loaded_brief, report = load_and_validate_candidate(
            path,
            root=root,
            regression=True,
        )
        if loaded_brief.scenario_id != brief.scenario_id:
            report.errors.append(f"{path}: regression brief order drift")
        report.require_ok()
        candidates.append(payload)
    if len(candidates) != 12:
        raise CorpusError("regression review requires exactly 12 candidates")
    return candidates


def _regression_ladder_report(
    candidates: Sequence[Mapping[str, Any]],
    sources: CorpusSources,
) -> dict[str, Any]:
    briefs = {brief.scenario_id: brief for brief in sources.regression_briefs}
    themes: dict[str, list[dict[str, Any]]] = {}
    for payload in candidates:
        scenario_id = _nonempty(payload.get("scenarioId"), "candidate.scenarioId")
        brief = briefs[scenario_id]
        theme = _nonempty(brief.raw.get("regressionTheme"), f"{scenario_id}.regressionTheme")
        scenario = _map(payload.get("scenario"), f"{scenario_id}.scenario")
        dialog = [
            _map(line, f"{scenario_id}.dialog")
            for line in scenario.get("dialog", [])
        ]
        lengths = [len(_nonempty(line.get("ko"), f"{scenario_id}.dialog.ko")) for line in dialog]
        profile = sources.level_profiles[brief.level]
        themes.setdefault(theme, []).append(
            {
                "level": brief.level,
                "scenarioId": scenario_id,
                "contentScope": profile.content_scope,
                "cognitiveTasks": list(profile.cognitive_tasks),
                "canDoKo": str(brief.raw.get("canDoKo") or ""),
                "turnCount": len(dialog),
                "meanKoChars": round(sum(lengths) / len(lengths), 2),
                "maxKoChars": max(lengths),
            }
        )
    expected_themes = set(sources.manifest.raw.get("regressionThemes", []))
    if set(themes) != expected_themes:
        raise CorpusError(
            f"regression themes drifted: actual={sorted(themes)}, expected={sorted(expected_themes)}"
        )
    for theme, rows in themes.items():
        by_level = Counter(str(row["level"]) for row in rows)
        if by_level != Counter({level: 1 for level in LEVELS}):
            raise CorpusError(f"{theme} must contain exactly one scene per A1-C2 level")
        rows.sort(key=lambda row: LEVELS.index(str(row["level"])))
    return {
        "ok": True,
        "kind": "nonrelease_regression_ladder_preflight",
        "releaseEligible": False,
        "lengthIsApprovalCriterion": False,
        "candidateCount": len(candidates),
        "themes": themes,
    }


def preflight_regression_ladders(
    directory: Path,
    *,
    root: Path = ROOT,
) -> dict[str, Any]:
    """Verify both nonrelease themes cover A1-C2 without treating length as level."""

    sources = load_sources(root)
    candidates = load_regression_candidates(directory, root=root)
    return _regression_ladder_report(candidates, sources)


def render_regression_review(
    candidates: Sequence[Mapping[str, Any]],
    *,
    root: Path = ROOT,
) -> str:
    """Render the two A1-C2 ladders without making them runtime-eligible."""

    sources = load_sources(root)
    by_id = {
        _nonempty(candidate.get("scenarioId"), "candidate.scenarioId"): candidate
        for candidate in candidates
    }
    lines = [
        "# 비출시 회귀 세트: 내용·언어 상승 검토",
        "",
        "> 이 12개는 비교용이며 런타임 승격 및 Jin 승인 대상 120개에 포함되지 않습니다.",
        "",
    ]
    ladder = _regression_ladder_report(candidates, sources)
    for theme in ("mistake_embarrassment_repair", "digital_contact_permission_responsibility"):
        lines.extend(
            (
                f"## {theme}",
                "",
                "> 문장 길이는 관찰값일 뿐 합격 기준이 아닙니다. 내용 범위·사회적 거리·인지 과제의 상승을 함께 봅니다.",
                "",
                "| 레벨 | 평균 KO 글자 | 최대 KO 글자 | 말차례 |",
                "|---|---:|---:|---:|",
            )
        )
        for row in ladder["themes"][theme]:
            lines.append(
                f"| {str(row['level']).upper()} | {row['meanKoChars']} | {row['maxKoChars']} | {row['turnCount']} |"
            )
        lines.append("")
        for level in LEVELS:
            brief = next(
                item
                for item in sources.regression_briefs
                if item.level == level and item.raw.get("regressionTheme") == theme
            )
            payload = by_id[brief.scenario_id]
            scenario = _map(payload.get("scenario"), "candidate.scenario")
            profile = sources.level_profiles[level]
            title = _map(scenario.get("title"), "scenario.title")
            lines.extend(
                (
                    f"### {level.upper()} · {title.get('ko')}",
                    "",
                    f"- 내용 범위: {profile.content_scope}",
                    f"- 인지 과제: {', '.join(profile.cognitive_tasks)}",
                    f"- Can-do: {brief.raw.get('canDoKo')}",
                    "",
                )
            )
            for line in scenario.get("dialog", []):
                if not isinstance(line, dict):
                    continue
                lines.append(
                    f"- `{line.get('speaker')}` KO: {line.get('ko')}  "
                    f"DE: {line.get('de')}  EN: {line.get('en')}"
                )
            lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def render_level_review(
    candidates: Sequence[Mapping[str, Any]],
    *,
    root: Path = ROOT,
) -> str:
    sources = load_sources(root)
    lines = [
        f"# {str(candidates[0].get('scenario', {}).get('level', '')).upper()} 정본 시나리오 검토",
        "",
        "> 자동 검사는 승인 증거가 아닙니다. 아래 20개를 모두 읽은 뒤 Jin이 결정합니다.",
        "",
    ]
    for index, payload in enumerate(candidates, start=1):
        scenario_id = _nonempty(payload.get("scenarioId"), "candidate.scenarioId")
        brief = _brief_for(sources, scenario_id)
        scenario = _map(payload.get("scenario"), "candidate.scenario")
        title = _map(scenario.get("title"), f"{scenario_id}.title").get("ko", brief.raw.get("titleKo"))
        lines.extend(
            [
                f"## {index}. {title} (`{scenario_id}`)",
                "",
                f"- 수행 목표: {brief.raw.get('canDoKo', '')}",
                f"- 관계·사건: {brief.raw.get('relationship', '')} / {brief.raw.get('event', '')}",
                f"- 단원: `{brief.course_unit_id}`",
                "",
            ]
        )
        for raw_line in scenario.get("dialog", []):
            line = _map(raw_line, f"{scenario_id}.dialog")
            speaker = str(line.get("speaker", ""))
            resolved = brief.player_character_id if speaker == "user" else speaker
            if speaker == "user":
                name = f"{sources.characters[resolved].display_name_ko} (나)"
            elif resolved in sources.characters:
                name = sources.characters[resolved].display_name_ko
            else:
                name = sources.role_names_ko.get(resolved, resolved)
            lines.extend(
                [
                    f"**{name}**  ",
                    f"KO: {line.get('ko', '')}  ",
                    f"DE: {line.get('de', '')}  ",
                    f"EN: {line.get('en', '')}",
                    "",
                ]
            )
        lines.extend(
            [
                "검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트",
                "",
                "Jin 메모:",
                "",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"


def record_level_approval(
    *,
    level: str,
    candidate_directory: Path,
    reviewer: str,
    root: Path = ROOT,
) -> dict[str, Any]:
    normalized = level.lower()
    if reviewer != APPROVAL_REVIEWER:
        raise CorpusError("only Jin can approve a canonical level")
    sources = load_sources(root)
    candidates = load_level_candidates(candidate_directory, normalized, root=root)
    approvals = json.loads(json.dumps(sources.approvals, ensure_ascii=False))
    approvals["levels"][normalized] = {
        "decision": "approved",
        "reviewer": reviewer,
        "reviewedScenarioCount": 20,
        "candidateSetSha256": candidate_set_hash(candidates),
        "approvedAt": datetime.now(timezone.utc).isoformat(),
        "promotedAt": None,
    }
    return approvals


def assert_level_approved(
    *,
    level: str,
    candidates: Sequence[Mapping[str, Any]],
    sources: CorpusSources,
) -> None:
    row = _map(sources.approvals.get("levels", {}).get(level), f"approvals.{level}")
    if row.get("decision") != "approved" or row.get("reviewer") != APPROVAL_REVIEWER:
        raise CorpusError(f"{level.upper()} has no Jin approval")
    if row.get("reviewedScenarioCount") != 20:
        raise CorpusError(f"{level.upper()} approval does not cover all 20 scenarios")
    if row.get("candidateSetSha256") != candidate_set_hash(candidates):
        raise CorpusError(f"{level.upper()} candidates changed after approval")
    index = LEVELS.index(level)
    for earlier in LEVELS[:index]:
        earlier_row = _map(sources.approvals.get("levels", {}).get(earlier), f"approvals.{earlier}")
        if (
            earlier_row.get("decision") != "approved"
            or not str(earlier_row.get("promotedAt") or "").strip()
        ):
            raise CorpusError(f"promotion order requires {earlier.upper()} promotion first")


def _replace_level_curriculum(
    curriculum: dict[str, Any],
    *,
    level: str,
    candidates: Sequence[Mapping[str, Any]],
    sources: CorpusSources,
) -> dict[str, Any]:
    result = json.loads(json.dumps(curriculum, ensure_ascii=False))
    blueprint = {
        str(item.get("unitId")): item
        for item in sources.course_unit_blueprint
        if str(item.get("level", "")).lower() == level
    }
    units = result.get("courseUnits")
    if not isinstance(units, list):
        raise CorpusError("curriculum courseUnits must be a list")
    unit_ids = set(blueprint)
    required_by_unit: dict[str, list[str]] = {}
    for unit in units:
        if not isinstance(unit, dict) or unit.get("id") not in unit_ids:
            continue
        item = blueprint[str(unit["id"])]
        unit["title"] = item["title"]
        unit["canDo"] = item["canDo"]
        unit["checkpointContentIds"] = [f"scenario:{item['checkpointScenarioId']}"]
        required_by_unit[str(unit["id"])] = list(unit.get("requiredConceptIds", []))

    briefs_by_id = {brief.scenario_id: brief for brief in sources.briefs if brief.level == level}
    existing_links = result.get("contentLinks")
    if not isinstance(existing_links, list):
        raise CorpusError("curriculum contentLinks must be a list")
    retained = [
        link
        for link in existing_links
        if not (
            isinstance(link, dict)
            and link.get("contentKind") == "scenario"
            and link.get("courseUnitId") in unit_ids
        )
    ]
    new_links: list[dict[str, Any]] = []
    for payload in candidates:
        scenario_id = _nonempty(payload.get("scenarioId"), "candidate.scenarioId")
        brief = briefs_by_id[scenario_id]
        new_links.append(
            {
                "contentKind": "scenario",
                "contentId": scenario_id,
                "courseUnitId": brief.course_unit_id,
                "conceptIds": required_by_unit.get(brief.course_unit_id, []),
                "role": "assess" if brief.checkpoint_for_unit else "practice",
            }
        )
    result["contentLinks"] = retained + new_links
    result["scenarioCorpusGeneration"] = sources.manifest.generation_id
    return result


def _refresh_scenario_audit_counts(
    *,
    data_dir: Path,
    scenarios: Sequence[Mapping[str, Any]],
) -> None:
    """Refresh only the scenario counts in a staged audit manifest."""

    path = data_dir / "content_audit_manifest.json"
    audit = _map(read_json(path), "content_audit_manifest")
    sources = audit.get("sources")
    if not isinstance(sources, list):
        raise CorpusError("content_audit_manifest.sources must be a list")
    expected = {
        "scenario": len(scenarios),
        "scenarioQuest": sum(
            len(item.get("quests", []))
            for item in scenarios
            if isinstance(item.get("quests"), list)
        ),
    }
    seen: set[str] = set()
    for row in sources:
        if not isinstance(row, dict):
            continue
        kind = row.get("kind")
        if kind in expected:
            row["count"] = expected[str(kind)]
            seen.add(str(kind))
    if seen != set(expected):
        raise CorpusError(
            f"content_audit_manifest is missing scenario count rows: {sorted(set(expected) - seen)}"
        )
    path.write_text(json_text(audit), encoding="utf-8")


def _stable_content_link_id(link: Mapping[str, Any]) -> str:
    """Mirror Dart stableContentId for the ASCII scenario-link wire contract."""

    fields = [
        str(link.get("contentKind") or ""),
        str(link.get("contentId") or ""),
        str(link.get("courseUnitId") or ""),
        "|".join(str(item) for item in link.get("conceptIds", [])),
        str(link.get("role") or ""),
    ]
    payload = json.dumps(fields, ensure_ascii=False, separators=(",", ":"))
    return f"link:{hashlib.sha256(payload.encode('utf-8')).hexdigest()[:24]}"


def _validate_staged_corpus_contract(
    *,
    curriculum: Mapping[str, Any],
    scenarios: Sequence[Mapping[str, Any]],
    sources: CorpusSources,
) -> dict[str, Any]:
    """Validate the 48-unit, 120-scene and immutable runtime-wire contract."""

    scenario_ids = {
        _nonempty(item.get("id"), "scenario.id") for item in scenarios
    }
    if len(scenarios) != sources.manifest.expected_total:
        raise CorpusError(
            f"staged corpus must contain exactly {sources.manifest.expected_total} scenarios"
        )
    if len(scenario_ids) != len(scenarios):
        raise CorpusError("staged corpus contains duplicate scenario IDs")

    course_units = curriculum.get("courseUnits")
    if not isinstance(course_units, list):
        raise CorpusError("curriculum courseUnits must be a list")
    blueprint_units = {
        _nonempty(item.get("unitId"), "blueprint.unitId")
        for item in sources.course_unit_blueprint
    }
    runtime_units = {
        _nonempty(item.get("id"), "courseUnit.id")
        for item in course_units
        if isinstance(item, dict)
    }
    if len(course_units) != 48 or len(blueprint_units) != 48:
        raise CorpusError(
            f"course contract requires 48 units; runtime={len(course_units)}, blueprint={len(blueprint_units)}"
        )
    if runtime_units != blueprint_units:
        raise CorpusError(
            "course unit IDs differ from the locked 48-unit blueprint; "
            f"missing={sorted(blueprint_units - runtime_units)[:5]}, "
            f"extra={sorted(runtime_units - blueprint_units)[:5]}"
        )

    raw_links = curriculum.get("contentLinks")
    if not isinstance(raw_links, list):
        raise CorpusError("curriculum contentLinks must be a list")
    scenario_links = [
        _map(link, "curriculum scenario link")
        for link in raw_links
        if isinstance(link, dict) and link.get("contentKind") == "scenario"
    ]
    if len(scenario_links) != len(scenarios):
        raise CorpusError(
            "staged curriculum must contain one scenario link per scene; "
            f"links={len(scenario_links)}, scenarios={len(scenarios)}"
        )

    links_by_scenario: dict[str, list[dict[str, Any]]] = {}
    links_by_unit: dict[str, list[dict[str, Any]]] = {}
    for link in scenario_links:
        content_id = _nonempty(link.get("contentId"), "scenario link contentId")
        unit_id = _nonempty(link.get("courseUnitId"), "scenario link courseUnitId")
        if content_id not in scenario_ids:
            raise CorpusError(f"orphan scenario content link: {content_id}")
        if unit_id not in runtime_units:
            raise CorpusError(f"scenario link points to unknown course unit: {unit_id}")
        links_by_scenario.setdefault(content_id, []).append(link)
        links_by_unit.setdefault(unit_id, []).append(link)

    multiply_linked = sorted(
        scenario_id
        for scenario_id, links in links_by_scenario.items()
        if len(links) != 1
    )
    missing_links = sorted(scenario_ids - set(links_by_scenario))
    empty_units = sorted(runtime_units - set(links_by_unit))
    if multiply_linked or missing_links or empty_units:
        raise CorpusError(
            "scenario/course link coverage failed; "
            f"multiplyLinked={multiply_linked[:5]}, missing={missing_links[:5]}, "
            f"emptyUnits={empty_units[:5]}"
        )

    checkpoint_ids: list[str] = []
    for raw_unit in course_units:
        unit = _map(raw_unit, "courseUnit")
        unit_id = _nonempty(unit.get("id"), "courseUnit.id")
        checkpoints = unit.get("checkpointContentIds")
        if not isinstance(checkpoints, list) or len(checkpoints) != 1:
            raise CorpusError(f"{unit_id} must have exactly one canonical checkpoint")
        checkpoint = _nonempty(checkpoints[0], f"{unit_id}.checkpoint")
        if not checkpoint.startswith("scenario:"):
            raise CorpusError(f"{unit_id} checkpoint is not a scenario: {checkpoint}")
        scenario_id = checkpoint.removeprefix("scenario:")
        if scenario_id not in scenario_ids:
            raise CorpusError(f"{unit_id} checkpoint is orphaned: {scenario_id}")
        if not any(
            link.get("contentId") == scenario_id and link.get("role") == "assess"
            for link in links_by_unit[unit_id]
        ):
            raise CorpusError(
                f"{unit_id} checkpoint has no assess scenario link: {scenario_id}"
            )
        checkpoint_ids.append(scenario_id)

    quest_ids: list[str] = []
    for scenario in scenarios:
        for raw_quest in scenario.get("quests", []):
            quest = _map(raw_quest, "scenario quest")
            quest_ids.append(_nonempty(quest.get("id"), "scenario quest id"))
    duplicate_quests = sorted(
        quest_id for quest_id, count in Counter(quest_ids).items() if count > 1
    )
    if duplicate_quests:
        raise CorpusError(f"duplicate quest IDs: {duplicate_quests[:10]}")

    wire_link_ids: dict[str, str] = {}
    for scenario_id, contract in RUNTIME_WIRE_LINKS.items():
        links = [
            link
            for link in links_by_scenario.get(scenario_id, [])
            if link.get("courseUnitId") == contract["courseUnitId"]
            and link.get("role") == "assess"
        ]
        if len(links) != 1:
            raise CorpusError(
                f"wire scenario {scenario_id} has no unique assess link for "
                f"{contract['courseUnitId']}"
            )
        computed = _stable_content_link_id(links[0])
        expected = str(contract["contentLinkId"])
        if computed != expected:
            raise CorpusError(
                f"wire content link drift for {scenario_id}: {computed} != {expected}"
            )
        wire_link_ids[scenario_id] = computed

    return {
        "courseUnitCount": len(course_units),
        "scenarioLinkCount": len(scenario_links),
        "checkpointCount": len(checkpoint_ids),
        "questCount": len(quest_ids),
        "wireScenarioIds": sorted(RUNTIME_WIRE_SCENARIO_IDS),
        "wireContentLinkIds": wire_link_ids,
    }


def preflight_corpus(
    *,
    candidate_directory: Path,
    root: Path = ROOT,
) -> dict[str, Any]:
    """Stage and validate the exact 120-scene corpus without approval or writes."""

    sources = load_sources(root)
    validate_portfolio(root).require_ok()
    candidates = load_corpus_candidates(candidate_directory, root=root)
    scenarios = [
        _map(payload.get("scenario"), "candidate.scenario")
        for payload in candidates
    ]
    curriculum = _map(
        read_json(root / "assets/data/curriculum_manifest.json"),
        "curriculum",
    )
    for level in LEVELS:
        level_candidates = [
            payload
            for payload in candidates
            if str(
                _map(payload.get("scenario"), "candidate.scenario").get("level", "")
            ).lower()
            == level
        ]
        curriculum = _replace_level_curriculum(
            curriculum,
            level=level,
            candidates=level_candidates,
            sources=sources,
        )
    contract = _validate_staged_corpus_contract(
        curriculum=curriculum,
        scenarios=scenarios,
        sources=sources,
    )
    tts_manifest = build_tts_pending_manifest(candidates, root=root)

    import scenario_store
    from validate_content import ContentValidator

    with tempfile.TemporaryDirectory(prefix="canonical-corpus-preflight-") as temp:
        stage_root = Path(temp) / "repo"
        stage_data = stage_root / "assets/data"
        stage_data.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(root / "assets/data", stage_data)
        grammar_source = root / "functions/analyze_korean_text/grammar_patterns.json"
        grammar_target = stage_root / "functions/analyze_korean_text/grammar_patterns.json"
        grammar_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(grammar_source, grammar_target)
        counts = scenario_store.write_shards(scenarios, data=stage_data, version=2)
        _refresh_scenario_audit_counts(data_dir=stage_data, scenarios=scenarios)
        (stage_data / "curriculum_manifest.json").write_text(
            json_text(curriculum), encoding="utf-8"
        )
        issues = ContentValidator(stage_root).validate()
        errors = [
            str(issue)
            for issue in issues
            if getattr(issue, "severity", "error") == "error"
        ]
        if errors:
            raise CorpusError(f"staged corpus validation failed: {errors[:10]}")

    expected_counts = {level: 20 for level in LEVELS}
    if counts != expected_counts:
        raise CorpusError(f"staged shard counts drifted: {counts} != {expected_counts}")
    return {
        "generationId": sources.manifest.generation_id,
        "candidateCount": len(candidates),
        "scenarioCounts": counts,
        "candidateSetSha256": candidate_set_hash(candidates),
        "ttsPendingCount": tts_manifest["count"],
        **contract,
        "approvalRecorded": False,
        "runtimeWritten": False,
        "releaseReady": False,
    }


def preflight_level(
    *,
    level: str,
    candidate_directory: Path,
    root: Path = ROOT,
) -> dict[str, Any]:
    """Run the exact staged runtime content gate without approving or writing.

    Editorial candidates need this check before Jin reviews them.  Promotion
    remains impossible here: this function neither reads an approval receipt
    as authority nor writes runtime shards, curriculum, TTS, or approval data.
    """

    normalized = level.lower()
    if normalized not in LEVELS:
        raise CorpusError(f"unknown level {level}")
    sources = load_sources(root)
    validate_portfolio(root).require_ok()
    candidates = load_level_candidates(candidate_directory, normalized, root=root)
    scenario_records = [_map(payload.get("scenario"), "candidate.scenario") for payload in candidates]
    tts_manifest = build_tts_pending_manifest(candidates, root=root)

    import scenario_store
    from validate_content import ContentValidator

    live_scenarios = scenario_store.load_scenarios(root / "assets/data")
    merged = [item for item in live_scenarios if str(item.get("level", "")).lower() != normalized]
    merged.extend(scenario_records)
    curriculum = _map(read_json(root / "assets/data/curriculum_manifest.json"), "curriculum")
    next_curriculum = _replace_level_curriculum(
        curriculum,
        level=normalized,
        candidates=candidates,
        sources=sources,
    )

    with tempfile.TemporaryDirectory(prefix="canonical-scenario-preflight-") as temp:
        stage_root = Path(temp) / "repo"
        stage_data = stage_root / "assets/data"
        stage_data.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(root / "assets/data", stage_data)
        grammar_source = root / "functions/analyze_korean_text/grammar_patterns.json"
        grammar_target = stage_root / "functions/analyze_korean_text/grammar_patterns.json"
        grammar_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(grammar_source, grammar_target)
        counts = scenario_store.write_shards(merged, data=stage_data, version=2)
        _refresh_scenario_audit_counts(data_dir=stage_data, scenarios=merged)
        (stage_data / "curriculum_manifest.json").write_text(
            json_text(next_curriculum), encoding="utf-8"
        )
        issues = ContentValidator(stage_root).validate()
        errors = [str(issue) for issue in issues if getattr(issue, "severity", "error") == "error"]
        if errors:
            raise CorpusError(f"staged content validation failed: {errors[:10]}")

    return {
        "level": normalized,
        "generationId": sources.manifest.generation_id,
        "candidateCount": len(candidates),
        "scenarioCounts": counts,
        "candidateSetSha256": candidate_set_hash(candidates),
        "ttsPendingCount": tts_manifest["count"],
        "approvalRecorded": False,
        "runtimeWritten": False,
        "releaseReady": False,
    }


def promote_level(
    *,
    level: str,
    candidate_directory: Path,
    tts_manifest_output: Path,
    tts_readiness_receipt: Path | None = None,
    runtime_write_reviewer: str | None = None,
    root: Path = ROOT,
    write: bool = False,
) -> dict[str, Any]:
    """Validate and optionally replace one runtime shard plus its course links.

    The caller must explicitly pass ``write=True``.  A dry run never changes
    runtime assets.  No TTS synthesis, upload, Firebase write, or deployment is
    performed in either mode.
    """

    normalized = level.lower()
    tts_target = (
        tts_manifest_output
        if tts_manifest_output.is_absolute()
        else root / tts_manifest_output
    )
    if normalized not in LEVELS:
        raise CorpusError(f"unknown level {level}")
    sources = load_sources(root)
    validate_portfolio(root).require_ok()
    candidates = load_level_candidates(candidate_directory, normalized, root=root)
    assert_level_approved(level=normalized, candidates=candidates, sources=sources)
    scenario_records = [_map(payload.get("scenario"), "candidate.scenario") for payload in candidates]
    tts_manifest = build_tts_pending_manifest(candidates, root=root)
    readiness_receipt: dict[str, Any] | None = None
    if write:
        readiness_receipt = assert_tts_ready_for_promotion(
            level=normalized,
            candidates=candidates,
            manifest=tts_manifest,
            receipt_path=tts_readiness_receipt,
            runtime_write_reviewer=runtime_write_reviewer,
            root=root,
        )

    import scenario_store
    from validate_content import ContentValidator

    live_scenarios = scenario_store.load_scenarios(root / "assets/data")
    merged = [item for item in live_scenarios if str(item.get("level", "")).lower() != normalized]
    merged.extend(scenario_records)
    curriculum = _map(read_json(root / "assets/data/curriculum_manifest.json"), "curriculum")
    next_curriculum = _replace_level_curriculum(
        curriculum,
        level=normalized,
        candidates=candidates,
        sources=sources,
    )

    with tempfile.TemporaryDirectory(prefix="canonical-scenario-promotion-") as temp:
        stage_root = Path(temp) / "repo"
        stage_data = stage_root / "assets/data"
        stage_data.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(root / "assets/data", stage_data)
        grammar_source = root / "functions/analyze_korean_text/grammar_patterns.json"
        grammar_target = stage_root / "functions/analyze_korean_text/grammar_patterns.json"
        grammar_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(grammar_source, grammar_target)
        counts = scenario_store.write_shards(merged, data=stage_data, version=2)
        _refresh_scenario_audit_counts(data_dir=stage_data, scenarios=merged)
        (stage_data / "curriculum_manifest.json").write_text(
            json_text(next_curriculum), encoding="utf-8"
        )
        issues = ContentValidator(stage_root).validate()
        errors = [str(issue) for issue in issues if getattr(issue, "severity", "error") == "error"]
        if errors:
            raise CorpusError(f"staged content validation failed: {errors[:5]}")

        result = {
            "level": normalized,
            "generationId": sources.manifest.generation_id,
            "scenarioCounts": counts,
            "candidateSetSha256": candidate_set_hash(candidates),
            "ttsPendingCount": tts_manifest["count"],
            "ttsReady": readiness_receipt is not None,
            "releaseReady": False,
            "written": write,
        }
        if not write:
            return result

        approval_path = _canonical_dir(root) / "approvals.json"
        target_paths = [
            root / "assets/data" / scenario_store.shard_name(item)
            for item in LEVELS
        ] + [
            root / "assets/data/curriculum_manifest.json",
            root / "assets/data/content_audit_manifest.json",
            tts_target,
            approval_path,
        ]
        backups = {path: path.read_bytes() if path.exists() else None for path in target_paths}
        try:
            for item in LEVELS:
                source = stage_data / scenario_store.shard_name(item)
                target = root / "assets/data" / scenario_store.shard_name(item)
                temporary = target.with_suffix(target.suffix + ".canonical.tmp")
                temporary.write_bytes(source.read_bytes())
                os.replace(temporary, target)
            curriculum_target = root / "assets/data/curriculum_manifest.json"
            curriculum_temp = curriculum_target.with_suffix(".json.canonical.tmp")
            curriculum_temp.write_text(json_text(next_curriculum), encoding="utf-8")
            os.replace(curriculum_temp, curriculum_target)
            audit_target = root / "assets/data/content_audit_manifest.json"
            audit_temp = audit_target.with_suffix(".json.canonical.tmp")
            audit_temp.write_bytes(
                (stage_data / "content_audit_manifest.json").read_bytes()
            )
            os.replace(audit_temp, audit_target)
            tts_target.parent.mkdir(parents=True, exist_ok=True)
            tts_temp = tts_target.with_suffix(tts_target.suffix + ".tmp")
            tts_temp.write_text(json_text(tts_manifest), encoding="utf-8")
            os.replace(tts_temp, tts_target)
            promoted_approvals = json.loads(
                json.dumps(sources.approvals, ensure_ascii=False)
            )
            promoted_approvals["levels"][normalized]["promotedAt"] = datetime.now(
                timezone.utc
            ).isoformat()
            promoted_approvals["levels"][normalized]["runtimeWriteAuthorizedBy"] = (
                runtime_write_reviewer
            )
            promoted_approvals["levels"][normalized]["ttsReadinessReceiptSha256"] = (
                hashlib.sha256(
                    json.dumps(
                        readiness_receipt,
                        ensure_ascii=False,
                        sort_keys=True,
                        separators=(",", ":"),
                    ).encode("utf-8")
                ).hexdigest()
            )
            approval_temp = approval_path.with_suffix(".json.canonical.tmp")
            approval_temp.write_text(
                json_text(promoted_approvals), encoding="utf-8"
            )
            os.replace(approval_temp, approval_path)
        except Exception:
            for path, data in backups.items():
                if data is None:
                    if path.exists():
                        path.unlink()
                else:
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(data)
            raise
        return result
