#!/usr/bin/env python3
"""Build the deterministic, network-free scenario-art generation manifest."""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import date
from pathlib import Path
from typing import Iterable, Mapping, Optional

from PIL import Image

import style_lock

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "assets" / "data"
INVENTORY_PATH = ROOT / "docs" / "data" / "scene_asset_inventory.json"
DEFAULT_OUTPUT_PATH = ROOT / "docs" / "data" / "scene_art_generation_manifest.json"
STYLE_CONTRACT_RELATIVE = Path("docs") / "assets" / "STYLE_LOCK.json"
STYLE_CONTRACT_PATH = ROOT / STYLE_CONTRACT_RELATIVE
SCENE_STYLE_FAMILY = "F-E-scene-poster"
SCENE_STYLE_IDENTIFIER = "scene-poster/faceted-heritage-2.5d-v1"

CATEGORY_ORDER = [
    "office",
    "home",
    "cafe",
    "station",
    "market",
    "convenience",
    "restaurant",
    "pharmacy",
    "directions",
    "hotel",
    "taxi",
    "airport",
    "bank",
    "salon",
    "theme_park",
]
LEVEL_ORDER = ["a1", "a2", "b1", "b2", "c1", "c2"]
EXPECTED_CATEGORY_COUNTS = {
    "office": 172,
    "home": 86,
    "cafe": 36,
    "station": 27,
    "market": 22,
    "theme_park": 6,
    "convenience": 14,
    "restaurant": 13,
    "pharmacy": 9,
    "directions": 8,
    "hotel": 8,
    "taxi": 7,
    "airport": 5,
    "bank": 3,
    "salon": 3,
}

CATEGORY_SETTING_KO = {
    "office": "한국의 사무실 또는 공공 업무 공간",
    "home": "현대 한국의 집 안 생활 공간",
    "cafe": "한국의 카페 내부",
    "station": "한국의 기차역 또는 지하철역",
    "market": "한국의 전통시장 또는 상점가",
    "theme_park": "한국의 현대 놀이공원 안",
    "convenience": "한국의 편의점 내부",
    "restaurant": "한국의 식당 내부",
    "pharmacy": "한국의 약국 내부",
    "directions": "한국의 거리와 길찾기 지점",
    "hotel": "한국의 호텔 로비 또는 객실",
    "taxi": "한국의 택시 안팎",
    "airport": "한국의 공항 내부",
    "bank": "한국의 은행 내부",
    "salon": "한국의 미용실 내부",
}
SPEAKER_LABEL_KO = {
    "user": "학습자",
    "jieun": "지은",
    "minsu": "민수",
    "yuna": "유나",
    "jinho": "진호",
    "junho": "준호",
    "jihye": "지혜",
    "subin": "수빈",
    "officer": "담당 직원",
    "partner": "대화 상대",
}

_HANGUL = re.compile(r"[가-힣]")
_QUEST_ANCHOR_KEYS = (
    "targetKo",
    "audioKo",
    "sentence",
    "particlePop",
    "prefix",
)


def _sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _relative(path: Path, root: Path) -> str:
    return path.resolve().relative_to(root.resolve()).as_posix()


def _shard_paths(root: Path) -> list[Path]:
    return sorted(
        (root / "assets" / "data").glob("scenarios_*.json"),
        key=lambda path: path.name,
    )


def _clean_text(value: object) -> str:
    if not isinstance(value, str):
        return ""
    return " ".join(value.strip().split())


def _unique_nonempty(values: Iterable[str]) -> list[str]:
    result = []
    seen = set()
    for value in values:
        cleaned = _clean_text(value)
        if cleaned and cleaned not in seen:
            seen.add(cleaned)
            result.append(cleaned)
    return result


def _with_terminal(text: str) -> str:
    return text if text.endswith((".", "?", "!", "…", "。")) else f"{text}."


def _quest_anchor_ko(scenario: Mapping[str, object]) -> str:
    for quest in scenario.get("quests", []) or []:
        if not isinstance(quest, dict):
            continue
        data = quest.get("data")
        if not isinstance(data, dict):
            continue
        for key in _QUEST_ANCHOR_KEYS:
            value = _clean_text(data.get(key))
            if value and _HANGUL.search(value):
                return value
        for option in data.get("options", []) or []:
            if isinstance(option, dict):
                value = _clean_text(option.get("ko"))
                if value and _HANGUL.search(value):
                    return value
    return ""


def semantic_summary_ko(scenario: Mapping[str, object]) -> str:
    title = _clean_text((scenario.get("title") or {}).get("ko"))
    dialog_lines = _unique_nonempty(
        item.get("ko")
        for item in scenario.get("dialog", []) or []
        if isinstance(item, dict)
    )
    if not title or not _HANGUL.search(title):
        raise ValueError(f"Scenario {scenario.get('id')!r} has no Korean title")
    if not dialog_lines:
        raise ValueError(f"Scenario {scenario.get('id')!r} has no Korean dialog")
    summary = (
        f"{_with_terminal(title)} 대화 핵심: "
        f"{_with_terminal(' / '.join(dialog_lines[:2]))}"
    )
    goal = _quest_anchor_ko(scenario)
    if goal:
        summary += f" 학습 목표 발화: {_with_terminal(goal)}"
    return summary


def _participants(scenario: Mapping[str, object]) -> list[dict]:
    speaker_ids = _unique_nonempty(
        item.get("speaker")
        for item in scenario.get("dialog", []) or []
        if isinstance(item, dict)
    )
    if not speaker_ids:
        raise ValueError(f"Scenario {scenario.get('id')!r} has no participants")
    return [
        {
            "speakerId": speaker_id,
            "labelKo": SPEAKER_LABEL_KO.get(speaker_id, speaker_id),
        }
        for speaker_id in speaker_ids
    ]


def _props_ko(scenario: Mapping[str, object]) -> list[str]:
    values = _unique_nonempty(
        item.get("korean")
        for item in scenario.get("vocab", []) or []
        if isinstance(item, dict)
    )
    if not values:
        raise ValueError(f"Scenario {scenario.get('id')!r} has no Korean visual cues")
    return values[:5]


def _load_scene_style_family(project_root: Path) -> dict:
    """Load and fail-closed validate the scene-only STYLE_LOCK family."""
    style_path = project_root / STYLE_CONTRACT_RELATIVE
    lock = style_lock.load_style_lock(style_path)
    family = lock["families"].get(SCENE_STYLE_FAMILY)
    if not isinstance(family, dict):
        raise ValueError(f"STYLE_LOCK is missing {SCENE_STYLE_FAMILY}")
    if family.get("identifier") != SCENE_STYLE_IDENTIFIER:
        raise ValueError(
            f"{SCENE_STYLE_FAMILY} identifier must be {SCENE_STYLE_IDENTIFIER!r}"
        )

    scope = family.get("scope")
    if not isinstance(scope, dict):
        raise ValueError(f"{SCENE_STYLE_FAMILY}.scope must be an object")
    expected_scope = {
        "runtimeRoot": "assets/illustrations/scenes/",
        "reviewRoot": "assets_unused/pending_review/scenes/",
    }
    for key, expected in expected_scope.items():
        if scope.get(key) != expected:
            raise ValueError(f"{SCENE_STYLE_FAMILY}.scope.{key} must be {expected!r}")
    applies_only_to = scope.get("appliesOnlyTo")
    if not isinstance(applies_only_to, list) or not applies_only_to:
        raise ValueError(f"{SCENE_STYLE_FAMILY}.scope.appliesOnlyTo must be a list")
    allowed_prefixes = tuple(expected_scope.values())
    if any(not str(pattern).startswith(allowed_prefixes) for pattern in applies_only_to):
        raise ValueError(f"{SCENE_STYLE_FAMILY} may apply only to scene asset roots")

    output = family.get("canonicalOutput")
    if not isinstance(output, dict):
        raise ValueError(f"{SCENE_STYLE_FAMILY}.canonicalOutput must be an object")
    expected_output = {
        "aspectRatio": "3:2",
        "width": 1536,
        "height": 1024,
        "format": "PNG",
        "modes": ["RGB", "RGBA"],
        "generatorFallbackAspectRatio": "4:3",
    }
    for key, expected in expected_output.items():
        if output.get(key) != expected:
            raise ValueError(
                f"{SCENE_STYLE_FAMILY}.canonicalOutput.{key} must be {expected!r}"
            )

    anchors = family.get("anchors")
    if not isinstance(anchors, list) or len(anchors) != 3 or len(set(anchors)) != 3:
        raise ValueError(f"{SCENE_STYLE_FAMILY} must declare exactly 3 unique anchors")
    for relative in anchors:
        anchor_path = project_root / relative
        if not anchor_path.is_file():
            raise ValueError(f"Missing approved scene-style anchor: {relative}")
        with Image.open(anchor_path) as image:
            image.load()
            if image.format != output["format"]:
                raise ValueError(f"{relative} must be a {output['format']} file")
            if image.size != (output["width"], output["height"]):
                raise ValueError(
                    f"{relative} must be {output['width']}x{output['height']}"
                )
            if image.mode not in output["modes"]:
                raise ValueError(f"{relative} has unsupported mode {image.mode!r}")

    anchor_by_category = family.get("approvedAnchorByCategory")
    if not isinstance(anchor_by_category, dict):
        raise ValueError(
            f"{SCENE_STYLE_FAMILY}.approvedAnchorByCategory must be an object"
        )
    if set(anchor_by_category) != set(CATEGORY_ORDER):
        raise ValueError(
            f"{SCENE_STYLE_FAMILY}.approvedAnchorByCategory must cover every category"
        )
    if not set(anchor_by_category.values()).issubset(set(anchors)):
        raise ValueError("Every scene category must map to an approved family anchor")
    if set(anchor_by_category.values()) != set(anchors):
        raise ValueError("Every approved family anchor must own at least one category")

    skeleton = family.get("promptSkeleton")
    required_tokens = {"{SUBJECT}", "{REFERENCE_IMAGE}", "{FORBIDDEN}"}
    if not isinstance(skeleton, str) or any(token not in skeleton for token in required_tokens):
        raise ValueError(
            f"{SCENE_STYLE_FAMILY}.promptSkeleton must contain {sorted(required_tokens)}"
        )
    content = family.get("content")
    forbidden = content.get("forbidden") if isinstance(content, dict) else None
    if not isinstance(forbidden, list) or not forbidden or any(
        not isinstance(value, str) or not value for value in forbidden
    ):
        raise ValueError(f"{SCENE_STYLE_FAMILY}.content.forbidden must be a string list")
    return family


def _prompt(
    *,
    scenario_id: str,
    semantic_summary: str,
    setting_ko: str,
    participants: list[dict],
    props_ko: list[str],
    category: str,
    family: Mapping[str, object],
    reference_path: str,
) -> str:
    participant_labels = ", ".join(item["labelKo"] for item in participants)
    prop_labels = ", ".join(props_ko)
    subject = f"""Canonical Korean-learning scenario: {scenario_id}.

KOREAN SEMANTIC ANCHOR (depict this exact situation, not a generic {category} scene):
{semantic_summary}

REQUIRED SETTING: {setting_ko}.
REQUIRED PARTICIPANTS: {participant_labels}. Keep their roles and interaction legible without speech bubbles. A dedicated scenario poster includes only these required participants.
REQUIRED SCENARIO-SPECIFIC VISUAL CUES: {prop_labels}. Use only cues that make physical sense in the scene."""
    content = family["content"]
    forbidden = ", ".join(content["forbidden"])
    prompt = str(family["promptSkeleton"])
    prompt = prompt.replace("{SUBJECT}", subject)
    prompt = prompt.replace("{REFERENCE_IMAGE}", reference_path)
    prompt = prompt.replace("{FORBIDDEN}", forbidden)
    if any(token in prompt for token in ("{SUBJECT}", "{REFERENCE_IMAGE}", "{FORBIDDEN}")):
        raise ValueError("Scene poster prompt skeleton contains unresolved tokens")
    return prompt


def _load_rows(root: Path) -> tuple[list[dict], dict[str, str]]:
    rows = []
    hashes = {}
    for shard_path in _shard_paths(root):
        relative = _relative(shard_path, root)
        digest = _sha256_file(shard_path)
        hashes[relative] = digest
        payload = json.loads(shard_path.read_text(encoding="utf-8"))
        scenarios = payload.get("scenarios", []) if isinstance(payload, dict) else payload
        for scenario in scenarios or []:
            if not isinstance(scenario, dict):
                raise ValueError(f"{relative} contains a non-object scenario")
            rows.append(
                {
                    "sourceShard": shard_path.name,
                    "sourceSha256": digest,
                    "scenario": scenario,
                }
            )
    return rows, hashes


def _validate_inventory_alignment(root: Path, scenario_ids: list[str]) -> None:
    inventory_path = root / "docs" / "data" / "scene_asset_inventory.json"
    inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
    inventory_ids = [row.get("id") for row in inventory.get("scenarios", [])]
    if sorted(inventory_ids) != sorted(scenario_ids):
        raise ValueError("Scene asset inventory IDs drift from canonical scenario shards")


def build_manifest(
    root: Path | str = ROOT,
    *,
    generation_overrides: Optional[Mapping[str, Mapping[str, object]]] = None,
) -> dict:
    project_root = Path(root)
    scene_family = _load_scene_style_family(project_root)
    scene_scope = scene_family["scope"]
    scene_output = scene_family["canonicalOutput"]
    scene_camera = scene_family["camera"]
    scene_content = scene_family["content"]
    scene_anchor_by_category = scene_family["approvedAnchorByCategory"]
    source_rows, generated_from = _load_rows(project_root)
    scenario_ids = [
        _clean_text(item["scenario"].get("id"))
        for item in source_rows
    ]
    if any(not scenario_id for scenario_id in scenario_ids):
        raise ValueError("Canonical scenario shard contains an empty ID")
    duplicates = sorted(
        scenario_id
        for scenario_id, count in Counter(scenario_ids).items()
        if count > 1
    )
    if duplicates:
        raise ValueError(f"Duplicate canonical scenario IDs: {duplicates}")
    _validate_inventory_alignment(project_root, scenario_ids)

    prepared = []
    for source in source_rows:
        scenario = source["scenario"]
        scenario_id = _clean_text(scenario.get("id"))
        category = _clean_text(scenario.get("backdrop"))
        level = _clean_text(scenario.get("level")).lower()
        if category not in CATEGORY_ORDER:
            raise ValueError(f"{scenario_id}: unsupported scene category {category!r}")
        if level not in LEVEL_ORDER:
            raise ValueError(f"{scenario_id}: unsupported level {level!r}")
        reference_path = scene_anchor_by_category[category]
        if not (project_root / reference_path).is_file():
            raise ValueError(f"{scenario_id}: missing approved scene anchor {reference_path}")
        summary = semantic_summary_ko(scenario)
        participants = _participants(scenario)
        props_ko = _props_ko(scenario)
        setting_ko = CATEGORY_SETTING_KO[category]
        prompt = _prompt(
            scenario_id=scenario_id,
            semantic_summary=summary,
            setting_ko=setting_ko,
            participants=participants,
            props_ko=props_ko,
            category=category,
            family=scene_family,
            reference_path=reference_path,
        )
        prompt_sha = hashlib.sha256(prompt.encode("utf-8")).hexdigest()
        prepared.append(
            {
                "id": scenario_id,
                "level": level,
                "category": category,
                "sourceShard": source["sourceShard"],
                "sourceSha256": source["sourceSha256"],
                "semanticSummaryKo": summary,
                "requiredSettingKo": setting_ko,
                "requiredParticipants": participants,
                "requiredPropsKo": props_ko,
                "forbiddenTextAndLogos": list(scene_content["forbidden"]),
                "styleReferenceIdentifiers": [
                    SCENE_STYLE_IDENTIFIER,
                    f"approved-scene-anchor/{Path(reference_path).stem}",
                ],
                "referenceImagePath": reference_path,
                "targetPath": f"{scene_scope['reviewRoot']}{scenario_id}.png",
                "priority": CATEGORY_ORDER.index(category) + 1,
                "priorityOrder": 0,
                "focalPoint": copy.deepcopy(scene_camera["focalPointDefault"]),
                "cropReviewProfiles": ["compact", "medium", "expanded"],
                "prompt": prompt,
                "promptSha256": prompt_sha,
                "generation": {
                    "status": "not_generated",
                    "generator": None,
                    "generatorResultId": None,
                    "manifestPromptSha256": prompt_sha,
                    "sourcePromptSha256": prompt_sha,
                    "normalizedSha256": None,
                    "dimensions": None,
                    "mode": None,
                    "alpha": None,
                    "automatedIssues": [],
                    "visualReview": "not_started",
                    "runtimeEligible": False,
                    "cropProfile": None,
                    "attempts": [],
                    "reviewNotes": [],
                    "generatedOn": None,
                    "normalizer": None,
                },
            }
        )

    prepared.sort(
        key=lambda row: (
            CATEGORY_ORDER.index(row["category"]),
            LEVEL_ORDER.index(row["level"]),
            row["id"],
        )
    )
    for index, row in enumerate(prepared, start=1):
        row["priorityOrder"] = index

    overrides = dict(generation_overrides or {})
    known_ids = {row["id"] for row in prepared}
    unknown_ids = sorted(set(overrides) - known_ids)
    if unknown_ids:
        raise ValueError(f"Generation override references unknown scenario IDs: {unknown_ids}")
    for row in prepared:
        override = overrides.get(row["id"])
        if override is None:
            continue
        if not isinstance(override, Mapping):
            raise ValueError(f"Generation override must be an object: {row['id']}")
        generation = copy.deepcopy(dict(override))
        previous_prompt_sha = generation.get("manifestPromptSha256")
        if previous_prompt_sha != row["promptSha256"]:
            generation["previousManifestPromptSha256"] = previous_prompt_sha
            generation["manifestPromptSha256"] = row["promptSha256"]
            generation["status"] = "generated_invalid"
            automated_issues = list(generation.get("automatedIssues") or [])
            if "style_contract_prompt_drift" not in automated_issues:
                automated_issues.append("style_contract_prompt_drift")
            generation["automatedIssues"] = automated_issues
            generation["visualReview"] = "invalidated"
            generation["runtimeEligible"] = False
            review_notes = list(generation.get("reviewNotes") or [])
            note = (
                f"Invalidated by {SCENE_STYLE_IDENTIFIER}; regenerate from the "
                "current manifest prompt before visual review."
            )
            if note not in review_notes:
                review_notes.append(note)
            generation["reviewNotes"] = review_notes
        row["generation"] = generation

    category_counts = Counter(row["category"] for row in prepared)
    actual_counts = {
        category: category_counts.get(category, 0)
        for category in CATEGORY_ORDER
    }
    if actual_counts != EXPECTED_CATEGORY_COUNTS:
        raise ValueError(
            f"Canonical scene category counts drifted: expected "
            f"{EXPECTED_CATEGORY_COUNTS}, got {actual_counts}"
        )
    prompts_by_category: dict[str, set[str]] = defaultdict(set)
    for row in prepared:
        prompt = row["prompt"]
        if prompt in prompts_by_category[row["category"]]:
            raise ValueError(
                f"Category {row['category']} has a byte-identical prompt: {row['id']}"
            )
        prompts_by_category[row["category"]].add(prompt)

    style_path = project_root / STYLE_CONTRACT_RELATIVE
    inventory_path = project_root / "docs" / "data" / "scene_asset_inventory.json"
    return {
        "schemaVersion": 1,
        "generatedFrom": {
            key: generated_from[key] for key in sorted(generated_from)
        },
        "styleContract": {
            "identifier": SCENE_STYLE_IDENTIFIER,
            "family": SCENE_STYLE_FAMILY,
            "path": _relative(style_path, project_root),
            "sha256": _sha256_file(style_path),
            "scope": copy.deepcopy(scene_scope),
            "canonicalOutput": copy.deepcopy(scene_output),
            "approvedAnchors": list(scene_family["anchors"]),
        },
        "canonicalInventory": {
            "path": _relative(inventory_path, project_root),
            "sha256": _sha256_file(inventory_path),
        },
        "scenarioCount": len(prepared),
        "categoryOrder": list(CATEGORY_ORDER),
        "categoryCounts": actual_counts,
        "entries": prepared,
    }


def _validate_sha256(value: str, field: str) -> str:
    if not re.fullmatch(r"[0-9a-f]{64}", value):
        raise ValueError(f"{field} must be a lowercase SHA-256 hex digest")
    return value


def _validate_attempts(attempts: Iterable[Mapping[str, object]]) -> list[dict]:
    result = []
    for index, attempt in enumerate(attempts):
        if not isinstance(attempt, Mapping):
            raise ValueError(f"attempt {index} must be an object")
        result_id = _clean_text(attempt.get("resultId"))
        prompt_sha = _clean_text(attempt.get("promptSha256"))
        outcome = _clean_text(attempt.get("outcome"))
        issues = attempt.get("issues")
        if not result_id:
            raise ValueError(f"attempt {index} has no resultId")
        _validate_sha256(prompt_sha, f"attempt {index} promptSha256")
        if outcome not in {"selected", "rejected"}:
            raise ValueError(f"attempt {index} outcome must be selected or rejected")
        if not isinstance(issues, list) or any(not isinstance(issue, str) for issue in issues):
            raise ValueError(f"attempt {index} issues must be a string list")
        result.append(
            {
                "resultId": result_id,
                "promptSha256": prompt_sha,
                "outcome": outcome,
                "issues": list(issues),
            }
        )
    return result


def record_generation_result(
    manifest: dict,
    *,
    scenario_id: str,
    normalized_file: Path | str,
    generator: str,
    result_id: str,
    source_prompt_sha256: str,
    crop_profile: str,
    attempts: Iterable[Mapping[str, object]],
    review_notes: Iterable[str] = (),
    generated_on: Optional[str] = None,
) -> None:
    rows = manifest.get("entries", [])
    row = next((item for item in rows if item.get("id") == scenario_id), None)
    if row is None:
        raise ValueError(f"Cannot record unknown scenario ID: {scenario_id}")
    path = Path(normalized_file)
    if path.name != f"{scenario_id}.png":
        raise ValueError(
            f"Normalized filename must match scenario ID: expected {scenario_id}.png"
        )
    if not path.is_file():
        raise FileNotFoundError(f"Normalized scene image does not exist: {path}")
    generator = _clean_text(generator)
    result_id = _clean_text(result_id)
    if not generator or not result_id:
        raise ValueError("generator and result_id are required")
    _validate_sha256(source_prompt_sha256, "source_prompt_sha256")
    if crop_profile not in {"compact", "medium", "expanded"}:
        raise ValueError("crop_profile must be compact, medium, or expanded")
    normalized_attempts = _validate_attempts(attempts)
    selected = [
        attempt for attempt in normalized_attempts if attempt["outcome"] == "selected"
    ]
    if len(selected) != 1 or selected[0]["resultId"] != result_id:
        raise ValueError("attempts must contain exactly one selected final result")

    automated_issues = []
    with Image.open(path) as image:
        image_format = image.format
        image.load()
        width, height = image.size
        mode = image.mode
        alpha = "A" in image.getbands() or "transparency" in image.info
    if image_format != "PNG":
        automated_issues.append("non_png")
    style_contract = manifest.get("styleContract") or {}
    canonical_output = style_contract.get("canonicalOutput") or {}
    expected_size = (
        canonical_output.get("width"),
        canonical_output.get("height"),
    )
    expected_modes = set(canonical_output.get("modes") or [])
    if (width, height) != expected_size:
        automated_issues.append("invalid_dimensions")
    if mode not in expected_modes:
        automated_issues.append("unexpected_color_mode")
    digest = _sha256_file(path)
    for other in rows:
        if other.get("id") == scenario_id:
            continue
        other_generation = other.get("generation") or {}
        if other_generation.get("normalizedSha256") == digest:
            automated_issues.append(f"duplicate_content:{other['id']}")

    notes = [_clean_text(note) for note in review_notes]
    if any(not note for note in notes):
        raise ValueError("review_notes cannot contain empty values")
    row["generation"] = {
        "status": (
            "generated_pending_review"
            if not automated_issues
            else "generated_invalid"
        ),
        "generator": generator,
        "generatorResultId": result_id,
        "manifestPromptSha256": row["promptSha256"],
        "sourcePromptSha256": source_prompt_sha256,
        "normalizedSha256": digest,
        "dimensions": [width, height],
        "mode": mode,
        "alpha": alpha,
        "automatedIssues": automated_issues,
        "visualReview": "pending",
        "runtimeEligible": False,
        "cropProfile": crop_profile,
        "attempts": normalized_attempts,
        "reviewNotes": notes,
        "generatedOn": generated_on or date.today().isoformat(),
        "normalizer": "tool/scene_poster_normalize.py",
    }


def _load_generation_overrides(path: Path) -> dict[str, dict]:
    if not path.is_file():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    overrides = {}
    for row in payload.get("entries", []):
        if not isinstance(row, dict):
            continue
        generation = row.get("generation")
        if (
            isinstance(generation, dict)
            and generation.get("status") != "not_generated"
        ):
            overrides[row.get("id")] = generation
    return overrides


def render_manifest_json(manifest: Mapping[str, object]) -> str:
    return json.dumps(manifest, ensure_ascii=False, indent=2) + "\n"


def _resolve_output(raw: Path) -> Path:
    return raw if raw.is_absolute() else ROOT / raw


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_PATH,
        help="Manifest path relative to the repository root",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Do not write; fail when the checked-in manifest differs",
    )
    parser.add_argument(
        "--record-result",
        metavar="SCENARIO_ID",
        help="Record one normalized pending-review generation result",
    )
    parser.add_argument("--normalized-file", type=Path)
    parser.add_argument("--generator")
    parser.add_argument("--result-id")
    parser.add_argument("--source-prompt-sha256")
    parser.add_argument(
        "--crop-profile",
        choices=("compact", "medium", "expanded"),
    )
    parser.add_argument(
        "--attempt-json",
        action="append",
        default=[],
        help="Repeatable JSON object with resultId, promptSha256, outcome, issues",
    )
    parser.add_argument(
        "--review-note",
        action="append",
        default=[],
    )
    parser.add_argument("--generated-on")
    return parser


def main(argv: Optional[list[str]] = None) -> int:
    args = _parser().parse_args(argv)
    output_path = _resolve_output(args.output)
    try:
        overrides = _load_generation_overrides(output_path)
        manifest = build_manifest(ROOT, generation_overrides=overrides)
        if args.record_result:
            if args.check:
                raise ValueError("--record-result cannot be combined with --check")
            required = {
                "--normalized-file": args.normalized_file,
                "--generator": args.generator,
                "--result-id": args.result_id,
                "--source-prompt-sha256": args.source_prompt_sha256,
                "--crop-profile": args.crop_profile,
            }
            missing = [flag for flag, value in required.items() if value is None]
            if missing:
                raise ValueError(
                    f"--record-result requires: {', '.join(missing)}"
                )
            attempts = [json.loads(raw) for raw in args.attempt_json]
            normalized_file = (
                args.normalized_file
                if args.normalized_file.is_absolute()
                else ROOT / args.normalized_file
            )
            record_generation_result(
                manifest,
                scenario_id=args.record_result,
                normalized_file=normalized_file,
                generator=args.generator,
                result_id=args.result_id,
                source_prompt_sha256=args.source_prompt_sha256,
                crop_profile=args.crop_profile,
                attempts=attempts,
                review_notes=args.review_note,
                generated_on=args.generated_on,
            )
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"[build_scene_art_manifest] error: {error}", file=sys.stderr)
        return 1
    rendered = render_manifest_json(manifest)
    if args.check:
        try:
            current = output_path.read_bytes()
        except OSError:
            current = None
        if current != rendered.encode("utf-8"):
            print(
                f"[build_scene_art_manifest] drift: {_relative(output_path, ROOT)}",
                file=sys.stderr,
            )
            return 1
        verb = "checked"
    else:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with output_path.open("w", encoding="utf-8", newline="\n") as handle:
            handle.write(rendered)
        verb = "recorded" if args.record_result else "wrote"
    print(
        f"[build_scene_art_manifest] {verb}: "
        f"{manifest['scenarioCount']} scenarios -> {_relative(output_path, ROOT)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
