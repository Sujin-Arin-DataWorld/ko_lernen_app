"""Deterministic audit for canonical scenario scene assets.

The runtime scenario shards are the authority. Every scenario may resolve to a
scenario-specific poster first and to an approved category poster as a runtime
fallback. Dedicated art is strict: exact canonical filename, 1536x1024 PNG,
RGB/RGBA, readable, unique bytes, and unambiguous scenario ID. Category
fallbacks are separately locked to the same technical output contract and to
their explicitly approved SHA-256 bytes.

Default mode rewrites the canonical JSON inventory and Markdown report.
`--check` performs the same scan without writing and fails on either strict
asset issues or byte drift in the checked-in outputs.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Mapping, Optional

from PIL import Image, UnidentifiedImageError

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "assets" / "data"
POSTER_DIR = ROOT / "assets" / "illustrations" / "scenes"
LOOP_DIR = ROOT / "assets" / "video" / "loops"
REPORT_PATH = ROOT / "docs" / "data" / "scene_asset_report.md"
INVENTORY_PATH = ROOT / "docs" / "data" / "scene_asset_inventory.json"
GENERATION_MANIFEST_PATH = ROOT / "docs" / "data" / "scene_art_generation_manifest.json"
RESOLVER_PATH = ROOT / "lib" / "services" / "scene_asset_resolver.dart"
CATEGORY_POSTER_LOCK_PATH = (
    ROOT / "docs" / "data" / "scene_category_poster_lock.json"
)

LOOP_SCENE_PREFIX = "scene_"
DEDICATED_SIZE = (1536, 1024)
DEDICATED_MODES = frozenset({"RGB", "RGBA"})
SCHEMA_VERSION = 1
CATEGORY_POSTER_ALIASES = {"theme_park": "market"}
CATEGORY_POSTER_PROFILE = "scene-poster/faceted-heritage-2.5d-v1"
CATEGORY_POSTER_LOCK_SCHEMA_VERSION = 1
APPROVED_CONTENT_EXCEPTION_RULES = frozenset(
    {"no_readable_text", "no_ui"}
)


@dataclass(frozen=True)
class ScenarioRef:
    shard: str
    scenario_id: str
    level: str
    backdrop: str


def dedicated_poster_name(scenario_id: str) -> str:
    return f"{scenario_id}.png"


def category_poster_name(backdrop: str) -> str:
    return f"{backdrop}.png"


def dedicated_loop_name(scenario_id: str) -> str:
    return f"{LOOP_SCENE_PREFIX}{scenario_id}.mp4"


def category_loop_name(backdrop: str) -> str:
    return f"{LOOP_SCENE_PREFIX}{backdrop}.mp4"


def resolve_poster(
    scenario_id: str,
    backdrop: str,
    poster_files: frozenset[str],
) -> tuple[str, Optional[str]]:
    """Reconstruct the dedicated-first Dart poster resolver."""
    dedicated = dedicated_poster_name(scenario_id)
    if dedicated in poster_files:
        return ("dedicated", dedicated)
    if backdrop:
        candidate = category_poster_name(backdrop)
        if candidate in poster_files:
            return ("fallback", candidate)
        alias = CATEGORY_POSTER_ALIASES.get(backdrop)
        if alias is not None:
            alias_candidate = category_poster_name(alias)
            if alias_candidate in poster_files:
                return ("fallback", alias_candidate)
        return ("broken_fallback", candidate)
    return ("missing", None)


def resolve_loop(
    scenario_id: str,
    backdrop: str,
    loop_files: frozenset[str],
) -> tuple[str, Optional[str]]:
    """Reconstruct the safe dedicated/category loop resolver."""
    dedicated = dedicated_loop_name(scenario_id)
    if dedicated in loop_files:
        return ("dedicated", dedicated)
    if backdrop:
        candidate = category_loop_name(backdrop)
        if candidate in loop_files:
            return ("fallback", candidate)
        return ("none_fallback", None)
    return ("none", None)


def _sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _sha256_file(path: Path) -> str:
    return _sha256_bytes(path.read_bytes())


def _sha256_text_file(path: Path) -> str:
    normalized = (
        path.read_text(encoding="utf-8")
        .replace("\r\n", "\n")
        .replace("\r", "\n")
    )
    return _sha256_bytes(normalized.encode("utf-8"))


def _project_path(path: Path, project_root: Path) -> str:
    try:
        return path.resolve().relative_to(project_root.resolve()).as_posix()
    except ValueError:
        return path.resolve().as_posix()


def _color_space(mode: str, info: Mapping[str, object]) -> str:
    if "srgb" in info:
        return "sRGB"
    if info.get("icc_profile"):
        return "embedded-ICC"
    if mode in DEDICATED_MODES:
        # PNG RGB samples without an embedded profile are interpreted as sRGB
        # by Flutter. The normalizer writes this same explicit pixel space.
        return "sRGB"
    if mode == "P":
        return "indexed"
    if mode in {"1", "L", "LA", "I", "F"}:
        return "grayscale"
    return "unknown"


def inspect_png(path: Path) -> dict:
    """Return deterministic byte and decoded-image metadata for *path*."""
    digest: Optional[str]
    try:
        digest = _sha256_file(path)
    except OSError:
        digest = None

    try:
        with Image.open(path) as image:
            image_format = image.format
            image.load()
            mode = image.mode
            width, height = image.size
            info = dict(image.info)
            return {
                "readable": True,
                "isPng": image_format == "PNG",
                "width": width,
                "height": height,
                "mode": mode,
                "colorSpace": _color_space(mode, info),
                "alpha": "A" in image.getbands() or "transparency" in info,
                "sha256": digest,
                "error": None,
            }
    except (OSError, SyntaxError, ValueError, UnidentifiedImageError) as error:
        return {
            "readable": False,
            "isPng": False,
            "width": None,
            "height": None,
            "mode": None,
            "colorSpace": None,
            "alpha": None,
            "sha256": digest,
            "error": type(error).__name__,
        }


def load_category_poster_lock(
    path: Path = CATEGORY_POSTER_LOCK_PATH,
) -> Mapping[str, object]:
    """Load the manually approved category-poster byte lock."""
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, Mapping):
        raise ValueError("Category-poster lock must be a JSON object.")
    return data


def find_category_poster_lock_issues(
    category_lock: Mapping[str, object],
    poster_dir: Path | str,
    required_categories: Iterable[str],
    *,
    project_root: Path | str = ROOT,
) -> list[dict]:
    """Verify canonical category posters against the approved byte lock."""
    root = Path(project_root)
    directory = Path(poster_dir)
    issues: list[dict] = []
    expected_categories = set(required_categories)

    if category_lock.get("schemaVersion") != CATEGORY_POSTER_LOCK_SCHEMA_VERSION:
        issues.append(
            _issue(
                "category_poster_lock_invalid",
                "Category-poster lock has an unsupported schema version.",
                path=_project_path(CATEGORY_POSTER_LOCK_PATH, ROOT),
            )
        )
    if category_lock.get("profileIdentifier") != CATEGORY_POSTER_PROFILE:
        issues.append(
            _issue(
                "category_poster_lock_invalid",
                "Category-poster lock profile does not match the scene-poster SSoT.",
                path=_project_path(CATEGORY_POSTER_LOCK_PATH, ROOT),
            )
        )
    if category_lock.get("runtimeRoot") != "assets/illustrations/scenes/":
        issues.append(
            _issue(
                "category_poster_lock_invalid",
                "Category-poster lock points at an unexpected runtime root.",
                path=_project_path(CATEGORY_POSTER_LOCK_PATH, ROOT),
            )
        )
    if category_lock.get("canonicalOutput") != {
        "width": DEDICATED_SIZE[0],
        "height": DEDICATED_SIZE[1],
        "format": "PNG",
        "modes": ["RGB", "RGBA"],
    }:
        issues.append(
            _issue(
                "category_poster_lock_invalid",
                "Category-poster lock output contract does not match the canonical scene contract.",
                path=_project_path(CATEGORY_POSTER_LOCK_PATH, ROOT),
            )
        )

    raw_categories = category_lock.get("categories")
    if not isinstance(raw_categories, list):
        return _dedupe_issues(
            [
                *issues,
                _issue(
                    "category_poster_lock_invalid",
                    "Category-poster lock has no categories list.",
                    path=_project_path(CATEGORY_POSTER_LOCK_PATH, ROOT),
                ),
            ]
        )

    entries_by_id: dict[str, list[Mapping[str, object]]] = defaultdict(list)
    for raw_entry in raw_categories:
        if not isinstance(raw_entry, Mapping):
            issues.append(
                _issue(
                    "category_poster_lock_invalid",
                    "Category-poster lock contains a non-object entry.",
                    path=_project_path(CATEGORY_POSTER_LOCK_PATH, ROOT),
                )
            )
            continue
        category_id = raw_entry.get("id")
        if not isinstance(category_id, str) or not category_id:
            issues.append(
                _issue(
                    "category_poster_lock_invalid",
                    "Category-poster lock entry has no valid category ID.",
                    path=_project_path(CATEGORY_POSTER_LOCK_PATH, ROOT),
                )
            )
            continue
        entries_by_id[category_id].append(raw_entry)

    locked_categories = set(entries_by_id)
    if not expected_categories.issubset(locked_categories):
        issues.append(
            _issue(
                "category_poster_set_drift",
                "Canonical scenario backdrops are missing from the approved category-poster lock.",
                path=_project_path(CATEGORY_POSTER_LOCK_PATH, ROOT),
                expected=sorted(expected_categories),
                actual=sorted(locked_categories),
            )
        )

    for category_id in sorted(entries_by_id):
        entries = entries_by_id[category_id]
        if len(entries) != 1:
            issues.append(
                _issue(
                    "category_poster_lock_invalid",
                    f"Category {category_id!r} appears {len(entries)} times in the lock.",
                    id=category_id,
                    path=_project_path(CATEGORY_POSTER_LOCK_PATH, ROOT),
                )
            )
            continue
        entry = entries[0]
        expected_relative = f"assets/illustrations/scenes/{category_id}.png"
        if entry.get("path") != expected_relative:
            issues.append(
                _issue(
                    "category_poster_path_drift",
                    "Locked category poster path does not match its canonical ID.",
                    id=category_id,
                    path=str(entry.get("path") or ""),
                )
            )

        raw_exceptions = entry.get("approvedContentExceptions")
        if not isinstance(raw_exceptions, list):
            issues.append(
                _issue(
                    "category_poster_exception_invalid",
                    "Approved content exceptions must be a list.",
                    id=category_id,
                    path=expected_relative,
                )
            )
        else:
            for exception in raw_exceptions:
                if (
                    not isinstance(exception, Mapping)
                    or exception.get("rule") not in APPROVED_CONTENT_EXCEPTION_RULES
                    or not isinstance(exception.get("detail"), str)
                    or not str(exception.get("detail")).strip()
                ):
                    issues.append(
                        _issue(
                            "category_poster_exception_invalid",
                            "Content exception is not a narrowly approved rule with a reason.",
                            id=category_id,
                            path=expected_relative,
                        )
                    )

        path = directory / category_poster_name(category_id)
        metadata = inspect_png(path)
        relative = _project_path(path, root)
        if not metadata["readable"]:
            issues.append(
                _issue(
                    "category_poster_unreadable",
                    "Locked category poster is missing or cannot be decoded.",
                    id=category_id,
                    path=relative,
                )
            )
            continue
        if not metadata["isPng"]:
            issues.append(
                _issue(
                    "category_poster_format_drift",
                    "Locked category poster contents are not PNG.",
                    id=category_id,
                    path=relative,
                )
            )
        if (metadata["width"], metadata["height"]) != DEDICATED_SIZE:
            issues.append(
                _issue(
                    "category_poster_dimensions_drift",
                    "Locked category poster is not 1536x1024.",
                    id=category_id,
                    path=relative,
                    actual=[metadata["width"], metadata["height"]],
                )
            )
        if metadata["mode"] not in DEDICATED_MODES:
            issues.append(
                _issue(
                    "category_poster_mode_drift",
                    "Locked category poster is not RGB/RGBA.",
                    id=category_id,
                    path=relative,
                    actual=metadata["mode"],
                )
            )
        expected_digest = entry.get("sha256")
        if (
            not isinstance(expected_digest, str)
            or len(expected_digest) != 64
            or any(character not in "0123456789abcdef" for character in expected_digest)
        ):
            issues.append(
                _issue(
                    "category_poster_lock_invalid",
                    "Locked SHA-256 must be 64 lowercase hexadecimal characters.",
                    id=category_id,
                    path=expected_relative,
                )
            )
        elif metadata["sha256"] != expected_digest:
            issues.append(
                _issue(
                    "category_poster_hash_drift",
                    "Category poster bytes differ from the explicitly approved lock.",
                    id=category_id,
                    path=relative,
                    expected=expected_digest,
                    actual=metadata["sha256"],
                )
            )

    return _dedupe_issues(issues)


def _issue(code: str, message: str, **details: object) -> dict:
    issue = {"code": code}
    for key in ("id", "path", "shard", "duplicateOf", "locations"):
        if key in details:
            issue[key] = details[key]
    issue["message"] = message
    for key in sorted(set(details) - set(issue)):
        issue[key] = details[key]
    return issue


def _issue_sort_key(issue: Mapping[str, object]) -> tuple[str, ...]:
    return (
        str(issue.get("code", "")),
        str(issue.get("id", "")),
        str(issue.get("path", "")),
        str(issue.get("shard", "")),
        json.dumps(issue.get("locations", []), ensure_ascii=False, sort_keys=True),
        str(issue.get("message", "")),
    )


def _dedupe_issues(issues: Iterable[dict]) -> list[dict]:
    unique: dict[str, dict] = {}
    for issue in issues:
        key = json.dumps(issue, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
        unique[key] = issue
    return sorted(unique.values(), key=_issue_sort_key)


def scan_scene_inventory(
    refs: Iterable[ScenarioRef],
    poster_dir: Path | str,
    *,
    fallback_dir: Path | str | None = None,
    project_root: Path | str = ROOT,
    generated_from: Optional[Mapping[str, str]] = None,
    review_mode: bool = False,
    category_lock: Optional[Mapping[str, object]] = None,
) -> dict:
    """Build the canonical poster inventory from explicit, testable inputs."""
    root = Path(project_root)
    dedicated_directory = Path(poster_dir)
    fallback_directory = (
        Path(fallback_dir) if fallback_dir is not None else dedicated_directory
    )
    sorted_refs = sorted(
        refs,
        key=lambda ref: (ref.shard, ref.scenario_id, ref.level, ref.backdrop),
    )
    dedicated_files = (
        sorted(
            (
                path
                for path in dedicated_directory.iterdir()
                if path.is_file() and path.name != ".gitkeep"
            ),
            key=lambda p: p.name,
        )
        if dedicated_directory.is_dir()
        else []
    )
    same_directory = (
        dedicated_directory.resolve() == fallback_directory.resolve()
    )
    fallback_files = (
        dedicated_files
        if same_directory
        else (
            sorted(
                (
                    path
                    for path in fallback_directory.iterdir()
                    if path.is_file() and path.name != ".gitkeep"
                ),
                key=lambda path: path.name,
            )
            if fallback_directory.is_dir()
            else []
        )
    )
    dedicated_by_name = {path.name: path for path in dedicated_files}
    fallback_by_name = {path.name: path for path in fallback_files}
    scenario_ids = {ref.scenario_id for ref in sorted_refs}
    backdrops = {ref.backdrop for ref in sorted_refs if ref.backdrop}
    fallback_backdrops = backdrops | {
        CATEGORY_POSTER_ALIASES[backdrop]
        for backdrop in backdrops
        if backdrop in CATEGORY_POSTER_ALIASES
    }
    dedicated_png_names = {
        path.name for path in dedicated_files if path.suffix.lower() == ".png"
    }
    fallback_png_names = {
        path.name for path in fallback_files if path.suffix.lower() == ".png"
    }
    poster_files = frozenset(
        dedicated_png_names
        | (
            fallback_png_names
            if same_directory
            else {
                category_poster_name(backdrop)
                for backdrop in fallback_backdrops
                if category_poster_name(backdrop) in fallback_png_names
            }
        )
    )
    locked_category_ids = {
        str(entry.get("id"))
        for entry in (category_lock or {}).get("categories", [])
        if isinstance(entry, Mapping) and isinstance(entry.get("id"), str)
    }
    allowed_stems = (
        scenario_ids | fallback_backdrops | locked_category_ids
        if same_directory and not review_mode
        else scenario_ids
    )
    issues: list[dict] = []
    if category_lock is not None:
        issues.extend(
            find_category_poster_lock_issues(
                category_lock,
                fallback_directory,
                backdrops,
                project_root=root,
            )
        )

    refs_by_id: dict[str, list[ScenarioRef]] = defaultdict(list)
    for ref in sorted_refs:
        refs_by_id[ref.scenario_id].append(ref)
    duplicate_ids = {sid for sid, owned in refs_by_id.items() if len(owned) > 1}
    for scenario_id in sorted(duplicate_ids):
        owned = refs_by_id[scenario_id]
        issues.append(
            _issue(
                "duplicate_scenario_id",
                f"Scenario ID {scenario_id!r} is declared {len(owned)} times.",
                id=scenario_id,
                locations=[
                    {"shard": ref.shard, "level": ref.level}
                    for ref in sorted(owned, key=lambda item: (item.shard, item.level))
                ],
            )
        )

    for path in dedicated_files:
        relative = _project_path(path, root)
        if path.suffix != ".png":
            issues.append(
                _issue(
                    "non_png_image",
                    "Scene poster directory contains a file that is not a lowercase .png.",
                    path=relative,
                )
            )
            issues.append(
                _issue(
                    "filename_id_mismatch",
                    "Scene poster filename does not match the canonical <scenario-id>.png contract.",
                    path=relative,
                )
            )
            if path.stem not in allowed_stems:
                issues.append(
                    _issue(
                        "orphan_dedicated_scene_asset",
                        "Scene poster is not owned by a canonical scenario ID or backdrop.",
                        path=relative,
                    )
                )
            continue
        if path.stem not in allowed_stems:
            issues.append(
                _issue(
                    "orphan_dedicated_scene_asset",
                    "Scene poster is not owned by a canonical scenario ID or backdrop.",
                    path=relative,
                )
            )
            issues.append(
                _issue(
                    "filename_id_mismatch",
                    "Scene poster filename does not match any canonical scenario ID.",
                    path=relative,
                )
            )

    rows: list[dict] = []
    row_metadata: list[dict] = []
    for ref in sorted_refs:
        status, resolved_name = resolve_poster(
            ref.scenario_id,
            ref.backdrop,
            poster_files,
        )
        dedicated_path = dedicated_directory / dedicated_poster_name(ref.scenario_id)
        if status == "dedicated" and resolved_name:
            resolved_path = dedicated_by_name.get(resolved_name, dedicated_path)
        elif resolved_name:
            resolved_path = fallback_by_name.get(
                resolved_name,
                fallback_directory / resolved_name,
            )
        else:
            resolved_path = None
        metadata = (
            inspect_png(resolved_path)
            if resolved_path is not None and resolved_path.is_file()
            else {
                "readable": False,
                "isPng": False,
                "width": None,
                "height": None,
                "mode": None,
                "colorSpace": None,
                "alpha": None,
                "sha256": None,
                "error": None,
            }
        )
        runtime_eligible = status in {"dedicated", "fallback"}
        if review_mode and status == "dedicated":
            runtime_eligible = False

        if status == "broken_fallback":
            issues.append(
                _issue(
                    "broken_category_fallback",
                    f"Backdrop {ref.backdrop!r} resolves to a missing category poster.",
                    id=ref.scenario_id,
                    path=_project_path(resolved_path, root),
                    shard=ref.shard,
                )
            )
            runtime_eligible = False
        elif status == "missing":
            runtime_eligible = False
        elif not metadata["readable"]:
            issues.append(
                _issue(
                    "unreadable_image",
                    f"Resolved scene poster cannot be decoded ({metadata['error'] or 'unknown error'}).",
                    id=ref.scenario_id,
                    path=_project_path(resolved_path, root),
                    shard=ref.shard,
                )
            )
            runtime_eligible = False
        elif not metadata["isPng"]:
            issues.append(
                _issue(
                    "non_png_image",
                    "Resolved scene poster has non-PNG file contents.",
                    id=ref.scenario_id,
                    path=_project_path(resolved_path, root),
                    shard=ref.shard,
                )
            )
            runtime_eligible = False

        if status == "dedicated" and metadata["readable"] and metadata["isPng"]:
            if (metadata["width"], metadata["height"]) != DEDICATED_SIZE:
                issues.append(
                    _issue(
                        "invalid_dedicated_dimensions",
                        (
                            f"Dedicated poster is {metadata['width']}x{metadata['height']}; "
                            f"expected {DEDICATED_SIZE[0]}x{DEDICATED_SIZE[1]}."
                        ),
                        id=ref.scenario_id,
                        path=_project_path(resolved_path, root),
                        shard=ref.shard,
                    )
                )
                runtime_eligible = False
            if metadata["mode"] not in DEDICATED_MODES:
                issues.append(
                    _issue(
                        "unexpected_color_mode",
                        (
                            f"Dedicated poster mode is {metadata['mode']!r}; "
                            f"expected one of {sorted(DEDICATED_MODES)}."
                        ),
                        id=ref.scenario_id,
                        path=_project_path(resolved_path, root),
                        shard=ref.shard,
                    )
                )
                runtime_eligible = False

        if ref.scenario_id in duplicate_ids:
            runtime_eligible = False

        row = {
            "shard": ref.shard,
            "id": ref.scenario_id,
            "level": ref.level,
            "backdrop": ref.backdrop,
            "dedicatedPath": _project_path(dedicated_path, root),
            "resolvedPath": (
                _project_path(resolved_path, root) if resolved_path is not None else None
            ),
            "status": status,
            "width": metadata["width"],
            "height": metadata["height"],
            "mode": metadata["mode"],
            "colorSpace": metadata["colorSpace"],
            "alpha": metadata["alpha"],
            "sha256": metadata["sha256"],
            "duplicateOf": None,
            "runtimeEligible": runtime_eligible,
        }
        rows.append(row)
        row_metadata.append(metadata)

    hash_rows: dict[str, list[int]] = defaultdict(list)
    for index, (row, metadata) in enumerate(zip(rows, row_metadata)):
        if (
            row["status"] == "dedicated"
            and metadata["readable"]
            and metadata["isPng"]
            and row["sha256"]
        ):
            hash_rows[row["sha256"]].append(index)
    for digest in sorted(hash_rows):
        indices = hash_rows[digest]
        distinct_ids = sorted({rows[index]["id"] for index in indices})
        if len(distinct_ids) < 2:
            continue
        original = distinct_ids[0]
        for duplicate_id in distinct_ids[1:]:
            for index in indices:
                row = rows[index]
                if row["id"] != duplicate_id:
                    continue
                row["duplicateOf"] = original
                row["runtimeEligible"] = False
            issues.append(
                _issue(
                    "duplicate_dedicated_content",
                    f"Dedicated poster bytes duplicate scenario {original!r}.",
                    id=duplicate_id,
                    duplicateOf=original,
                    path=next(
                        row["resolvedPath"]
                        for row in rows
                        if row["id"] == duplicate_id
                    ),
                )
            )

    issues = _dedupe_issues(issues)
    return {
        "schemaVersion": SCHEMA_VERSION,
        "auditMode": "pending_review" if review_mode else "runtime",
        "generatedFrom": {
            key: generated_from[key] for key in sorted(generated_from or {})
        },
        "scenarioCount": len(rows),
        "dedicatedCount": sum(row["status"] == "dedicated" for row in rows),
        "fallbackCount": sum(row["status"] == "fallback" for row in rows),
        "missingCount": sum(
            row["status"] in {"broken_fallback", "missing"} for row in rows
        ),
        "issues": issues,
        "scenarios": rows,
    }


def render_inventory_json(inventory: Mapping[str, object]) -> str:
    return json.dumps(inventory, ensure_ascii=False, indent=2) + "\n"


def find_generation_manifest_issues(
    inventory: Mapping[str, object],
    generation_manifest: Mapping[str, object],
) -> list[dict]:
    """Cross-check pending-review image metadata against its provenance ledger."""
    raw_entries = generation_manifest.get("entries")
    if not isinstance(raw_entries, list):
        return [
            _issue(
                "generation_manifest_invalid",
                "Scene-art generation manifest has no entries list.",
                path=_project_path(GENERATION_MANIFEST_PATH, ROOT),
            )
        ]

    entries_by_id: dict[str, list[Mapping[str, object]]] = defaultdict(list)
    issues: list[dict] = []
    for raw_entry in raw_entries:
        if not isinstance(raw_entry, Mapping):
            issues.append(
                _issue(
                    "generation_manifest_invalid",
                    "Scene-art generation manifest contains a non-object entry.",
                    path=_project_path(GENERATION_MANIFEST_PATH, ROOT),
                )
            )
            continue
        scenario_id = str(raw_entry.get("id") or "").strip()
        if not scenario_id:
            issues.append(
                _issue(
                    "generation_manifest_invalid",
                    "Scene-art generation manifest contains an entry without an ID.",
                    path=_project_path(GENERATION_MANIFEST_PATH, ROOT),
                )
            )
            continue
        entries_by_id[scenario_id].append(raw_entry)

    inventory_rows = inventory.get("scenarios")
    if not isinstance(inventory_rows, list):
        return _dedupe_issues(
            [
                *issues,
                _issue(
                    "generation_manifest_invalid",
                    "Scene inventory has no scenarios list to compare.",
                ),
            ]
        )
    inventory_by_id = {
        str(row.get("id") or ""): row
        for row in inventory_rows
        if isinstance(row, Mapping) and row.get("id")
    }

    for scenario_id in sorted(entries_by_id):
        owned = entries_by_id[scenario_id]
        if len(owned) > 1:
            issues.append(
                _issue(
                    "generation_manifest_duplicate_id",
                    f"Scene-art generation manifest declares {scenario_id!r} more than once.",
                    id=scenario_id,
                )
            )
        if scenario_id not in inventory_by_id:
            issues.append(
                _issue(
                    "generation_manifest_orphan_entry",
                    "Scene-art generation manifest ID is not canonical.",
                    id=scenario_id,
                )
            )

    allowed_generated_statuses = {
        "generated_pending_review",
        "generated_invalid",
    }
    for scenario_id in sorted(inventory_by_id):
        row = inventory_by_id[scenario_id]
        entries = entries_by_id.get(scenario_id, [])
        if not entries:
            issues.append(
                _issue(
                    "generation_manifest_entry_missing",
                    "Canonical scenario has no scene-art generation manifest entry.",
                    id=scenario_id,
                )
            )
            continue
        entry = entries[0]
        generation = entry.get("generation")
        if not isinstance(generation, Mapping):
            issues.append(
                _issue(
                    "generation_manifest_invalid",
                    "Scene-art generation entry has no generation object.",
                    id=scenario_id,
                )
            )
            continue

        status = generation.get("status")
        has_pending_file = row.get("status") == "dedicated"
        if has_pending_file and status == "not_generated":
            issues.append(
                _issue(
                    "generation_manifest_unrecorded_file",
                    "Pending-review poster exists but its generation is not recorded.",
                    id=scenario_id,
                    path=str(row.get("resolvedPath") or ""),
                )
            )
            continue
        if not has_pending_file and status in allowed_generated_statuses:
            issues.append(
                _issue(
                    "generation_manifest_file_missing",
                    "Generation manifest records a result without a pending-review poster.",
                    id=scenario_id,
                    path=str(entry.get("targetPath") or ""),
                )
            )
            continue
        if not has_pending_file:
            if status != "not_generated":
                issues.append(
                    _issue(
                        "generation_manifest_invalid_status",
                        f"Generation status {status!r} is not recognized.",
                        id=scenario_id,
                    )
                )
            continue
        if status not in allowed_generated_statuses:
            issues.append(
                _issue(
                    "generation_manifest_invalid_status",
                    f"Generation status {status!r} is not valid for an existing poster.",
                    id=scenario_id,
                    path=str(row.get("resolvedPath") or ""),
                )
            )
            continue

        target_path = entry.get("targetPath")
        if target_path != row.get("resolvedPath"):
            issues.append(
                _issue(
                    "generation_manifest_target_drift",
                    "Generation target path differs from the audited pending-review file.",
                    id=scenario_id,
                    path=str(row.get("resolvedPath") or ""),
                    recordedTarget=target_path,
                )
            )

        expected_metadata = {
            "normalizedSha256": row.get("sha256"),
            "dimensions": [row.get("width"), row.get("height")],
            "mode": row.get("mode"),
            "alpha": row.get("alpha"),
            "runtimeEligible": False,
        }
        drifted_fields = sorted(
            key
            for key, expected in expected_metadata.items()
            if generation.get(key) != expected
        )
        if drifted_fields:
            issues.append(
                _issue(
                    "generation_manifest_metadata_drift",
                    "Generation metadata differs from the audited pending-review poster.",
                    id=scenario_id,
                    path=str(row.get("resolvedPath") or ""),
                    fields=drifted_fields,
                )
            )

    return _dedupe_issues(issues)


def find_output_drift(expected_outputs: Mapping[Path | str, str]) -> list[dict]:
    issues = []
    for raw_path, expected in sorted(
        expected_outputs.items(),
        key=lambda item: Path(item[0]).as_posix(),
    ):
        path = Path(raw_path)
        expected_bytes = expected.encode("utf-8")
        try:
            actual_bytes = path.read_bytes()
        except OSError:
            actual_bytes = None
        if actual_bytes != expected_bytes:
            issues.append(
                _issue(
                    "manifest_drift",
                    "Checked-in generated output differs from the canonical scan.",
                    path=path.as_posix(),
                )
            )
    return _dedupe_issues(issues)


def strict_exit_code(
    inventory: Mapping[str, object],
    drift_issues: Iterable[Mapping[str, object]] = (),
) -> int:
    return 1 if inventory.get("issues") or list(drift_issues) else 0


def _scenario_shard_paths(data_dir: Path = DATA_DIR) -> list[Path]:
    return sorted(data_dir.glob("scenarios_*.json"), key=lambda path: path.name)


def _load_scenario_refs(data_dir: Path = DATA_DIR) -> list[ScenarioRef]:
    refs = []
    for path in _scenario_shard_paths(data_dir):
        data = json.loads(path.read_text(encoding="utf-8"))
        scenarios = data.get("scenarios", []) if isinstance(data, dict) else data
        for scenario in scenarios or []:
            refs.append(
                ScenarioRef(
                    shard=path.name,
                    scenario_id=str(scenario.get("id") or "?").strip() or "?",
                    level=str(scenario.get("level") or "?").strip() or "?",
                    backdrop=str(scenario.get("backdrop") or "").strip(),
                )
            )
    return sorted(
        refs,
        key=lambda ref: (ref.shard, ref.scenario_id, ref.level, ref.backdrop),
    )


def _generated_from() -> dict[str, str]:
    paths = [
        *_scenario_shard_paths(),
        RESOLVER_PATH,
        CATEGORY_POSTER_LOCK_PATH,
    ]
    return {
        _project_path(path, ROOT): _sha256_text_file(path)
        for path in sorted(paths, key=lambda item: _project_path(item, ROOT))
    }


def _load_category_lock_with_issues() -> tuple[Optional[Mapping[str, object]], list[dict]]:
    try:
        return load_category_poster_lock(), []
    except (OSError, ValueError, json.JSONDecodeError) as error:
        return None, [
            _issue(
                "category_poster_lock_unreadable",
                f"Category-poster lock cannot be read ({type(error).__name__}).",
                path=_project_path(CATEGORY_POSTER_LOCK_PATH, ROOT),
            )
        ]


def _scan_loop_summary(refs: Iterable[ScenarioRef]) -> dict:
    all_files = (
        sorted(path.name for path in LOOP_DIR.iterdir() if path.is_file())
        if LOOP_DIR.is_dir()
        else []
    )
    loop_files = sorted(
        name
        for name in all_files
        if name.startswith(LOOP_SCENE_PREFIX) and name.lower().endswith(".mp4")
    )
    loop_set = frozenset(loop_files)
    counts: Counter[str] = Counter()
    referenced_ids = set()
    referenced_backdrops = set()
    for ref in refs:
        referenced_ids.add(ref.scenario_id)
        if ref.backdrop:
            referenced_backdrops.add(ref.backdrop)
        status, _ = resolve_loop(ref.scenario_id, ref.backdrop, loop_set)
        counts[status] += 1
    orphan = sorted(
        name
        for name in loop_files
        if name[len(LOOP_SCENE_PREFIX) : -4] not in referenced_ids
        and name[len(LOOP_SCENE_PREFIX) : -4] not in referenced_backdrops
    )
    return {
        "sceneFileCount": len(loop_files),
        "nonSceneFileCount": len(set(all_files) - set(loop_files)),
        "statusCounts": {
            key: counts.get(key, 0)
            for key in ("dedicated", "fallback", "none_fallback", "none")
        },
        "orphanFiles": orphan,
    }


def _escape_cell(value: object) -> str:
    return (
        str(value)
        .replace("|", "\\|")
        .replace("\r\n", " ")
        .replace("\n", " ")
        .replace("\r", " ")
    )


def render_report(
    inventory: Mapping[str, object],
    loop_summary: Optional[Mapping[str, object]] = None,
) -> str:
    scenarios = list(inventory["scenarios"])
    issues = list(inventory["issues"])
    by_shard = Counter(row["shard"] for row in scenarios)
    by_backdrop = Counter(
        row["backdrop"] for row in scenarios if row["status"] == "fallback"
    )
    lines = [
        "# 시나리오 씬 에셋 감사 리포트",
        "",
        "`python -X utf8 tool/audit_scene_assets.py`로 결정적으로 생성한다. 직접 편집하지 않는다.",
        "",
        "전용 포스터는 시나리오 ID와 같은 파일명, 1536×1024 PNG, RGB/RGBA, 고유",
        "바이트를 요구한다. 카테고리 포스터 15장도 같은 기술 규격과 승인된",
        "SHA-256 바이트를 요구하며 런타임 폴백으로 사용한다.",
        "",
        "## 요약",
        "",
        f"- canonical 시나리오: **{inventory['scenarioCount']}개**",
        f"- 전용 포스터: **{inventory['dedicatedCount']}개**",
        f"- 카테고리 폴백: **{inventory['fallbackCount']}개**",
        f"- 누락/깨진 폴백: **{inventory['missingCount']}개**",
        f"- 엄격 이슈: **{len(issues)}건**",
        "",
        "## 엄격 이슈",
        "",
    ]
    if issues:
        lines.extend(["| 코드 | 시나리오 | 경로 | 설명 |", "|---|---|---|---|"])
        for issue in issues:
            lines.append(
                f"| {_escape_cell(issue['code'])} | {_escape_cell(issue.get('id', ''))} | "
                f"{_escape_cell(issue.get('path', ''))} | {_escape_cell(issue['message'])} |"
            )
    else:
        lines.append("0건.")
    lines.extend(["", "## 샤드별 시나리오", ""])
    for shard in sorted(by_shard):
        lines.append(f"- {shard}: {by_shard[shard]}개")
    lines.extend(["", "## 카테고리 런타임 폴백", ""])
    if by_backdrop:
        for backdrop in sorted(by_backdrop):
            lines.append(f"- {backdrop}: {by_backdrop[backdrop]}개")
    else:
        lines.append("0개.")

    if loop_summary is not None:
        status_counts = loop_summary["statusCounts"]
        lines.extend(
            [
                "",
                "## 기존 비디오 루프 참조 상태 (감사 전용)",
                "",
                f"- scene_*.mp4: {loop_summary['sceneFileCount']}개",
                f"- 규약 밖 루프 파일: {loop_summary['nonSceneFileCount']}개",
                f"- 전용 루프 해석: {status_counts['dedicated']}개",
                f"- 카테고리 루프 해석: {status_counts['fallback']}개",
                f"- 루프 없는 안전 폴백: {status_counts['none_fallback']}개",
                f"- backdrop 없는 루프 없음: {status_counts['none']}개",
                f"- 고아 scene 루프: {len(loop_summary['orphanFiles'])}개",
            ]
        )

    lines.extend(["", "## 생성 근거 SHA-256", ""])
    for path, digest in inventory["generatedFrom"].items():
        lines.append(f"- `{path}`: `{digest}`")

    lines.extend(
        [
            "",
            "## 시나리오별 해석",
            "",
            "| 샤드 | ID | 레벨 | backdrop | 상태 | 해석 경로 | 크기/모드 | SHA-256 | runtimeEligible |",
            "|---|---|---|---|---|---|---|---|---|",
        ]
    )
    for row in scenarios:
        dimensions = (
            f"{row['width']}×{row['height']} {row['mode']}"
            if row["width"] is not None
            else ""
        )
        digest = row["sha256"] or ""
        lines.append(
            f"| {_escape_cell(row['shard'])} | {_escape_cell(row['id'])} | "
            f"{_escape_cell(row['level'])} | {_escape_cell(row['backdrop'])} | "
            f"{_escape_cell(row['status'])} | {_escape_cell(row['resolvedPath'] or '')} | "
            f"{_escape_cell(dimensions)} | {_escape_cell(digest)} | "
            f"{str(row['runtimeEligible']).lower()} |"
        )
    return "\n".join(lines) + "\n"


def _write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)


def _resolve_cli_path(raw: str) -> Path:
    path = Path(raw)
    return path if path.is_absolute() else ROOT / path


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="Do not write; fail on strict issues or generated-output drift.",
    )
    parser.add_argument(
        "--json",
        default=_project_path(INVENTORY_PATH, ROOT),
        metavar="PATH",
        help="Inventory JSON path relative to the repository root.",
    )
    parser.add_argument(
        "--pending-review",
        nargs="?",
        const="assets_unused/pending_review/scenes",
        metavar="PATH",
        help=(
            "Read-only audit of dedicated pending-review posters over runtime "
            "category fallbacks. Defaults to assets_unused/pending_review/scenes."
        ),
    )
    return parser


def main(argv: Optional[list[str]] = None) -> int:
    args = _parser().parse_args(argv)
    refs = _load_scenario_refs()
    category_lock, category_lock_issues = _load_category_lock_with_issues()
    if args.pending_review is not None:
        pending_dir = _resolve_cli_path(args.pending_review)
        inventory = scan_scene_inventory(
            refs,
            pending_dir,
            fallback_dir=POSTER_DIR,
            project_root=ROOT,
            generated_from=_generated_from(),
            review_mode=True,
            category_lock=category_lock,
        )
        try:
            generation_manifest = json.loads(
                GENERATION_MANIFEST_PATH.read_text(encoding="utf-8")
            )
            manifest_issues = find_generation_manifest_issues(
                inventory,
                generation_manifest,
            )
        except (OSError, ValueError, json.JSONDecodeError) as error:
            manifest_issues = [
                _issue(
                    "generation_manifest_unreadable",
                    f"Scene-art generation manifest cannot be read ({type(error).__name__}).",
                    path=_project_path(GENERATION_MANIFEST_PATH, ROOT),
                )
            ]
        inventory["issues"] = _dedupe_issues(
            [
                *inventory["issues"],
                *category_lock_issues,
                *manifest_issues,
            ]
        )
        result = strict_exit_code(inventory)
        print(
            "[audit_scene_assets] pending-review checked: "
            f"{inventory['scenarioCount']} scenarios, "
            f"{inventory['dedicatedCount']} dedicated, "
            f"{inventory['fallbackCount']} fallback, "
            f"{inventory['missingCount']} missing, "
            f"{len(inventory['issues'])} strict issues"
        )
        for issue in inventory["issues"]:
            location = issue.get("path") or issue.get("id") or ""
            print(f"  - {issue['code']}: {location}: {issue['message']}")
        return result

    inventory = scan_scene_inventory(
        refs,
        POSTER_DIR,
        project_root=ROOT,
        generated_from=_generated_from(),
        category_lock=category_lock,
    )
    inventory["issues"] = _dedupe_issues(
        [*inventory["issues"], *category_lock_issues]
    )
    loop_summary = _scan_loop_summary(refs)
    json_path = _resolve_cli_path(args.json)
    json_text = render_inventory_json(inventory)
    report_text = render_report(inventory, loop_summary)
    expected = {json_path: json_text, REPORT_PATH: report_text}

    if args.check:
        drift = find_output_drift(expected)
    else:
        for path, output_text in expected.items():
            _write_text(path, output_text)
        drift = []

    result = strict_exit_code(inventory, drift)
    verb = "checked" if args.check else "wrote"
    print(
        "[audit_scene_assets] "
        f"{verb}: {inventory['scenarioCount']} scenarios, "
        f"{inventory['dedicatedCount']} dedicated, "
        f"{inventory['fallbackCount']} fallback, "
        f"{inventory['missingCount']} missing, "
        f"{len(inventory['issues'])} strict issues, "
        f"{len(drift)} drift issues"
    )
    for issue in [*inventory["issues"], *drift]:
        location = issue.get("path") or issue.get("id") or ""
        print(f"  - {issue['code']}: {location}: {issue['message']}")
    return result


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
