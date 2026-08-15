#!/usr/bin/env python3
"""Read-only preflight for a new vocabulary-pack draft.

This tool deliberately plans and checks a pack assignment without changing an
app asset.  It exists because a vocabulary pack has contracts outside its CSV
rows: the future UI label, an already shipped stamp motif, and a curriculum
unit must all be named before Jin can approve the content.

Usage:
    python3 tools/content_factory/plan_pack_assignments.py \
      --draft tools/content_factory/drafts/batch_01_vocab.csv \
      --metadata tools/content_factory/drafts/batch_01_pack_metadata.json \
      --reserved-metadata tools/content_factory/drafts/batch_01_manifest.json

The metadata file is a small JSON document:

    {
      "vocabPacks": [{
        "packId": "b1_housing_contract_1",
        "level": "b1",
        "orderRange": [1, 12],
        "reviewBossOrders": [10, 11, 12],
        "displayLabel": {
          "ko": "주거와 계약",
          "de": "Wohnen & Vertrag",
          "en": "Housing & Contracts"
        },
        "motif": "gwigap",
        "curriculum": {
          "courseUnitId": "b1_05_complaint_resolution",
          "conceptIds": ["concept_b1_complaint_resolution"]
        }
      }]
    }

``vocabPacks`` is the Batch 01 single-source manifest. The planner derives
the pack base and next UI order from the repository. The earlier minimal
``packs`` format remains accepted for compatibility, but new batches should
not duplicate mapping facts in both files.

When an earlier review-only batch has not reached the app asset yet, repeat
``--reserved-metadata`` for each of its ``vocabPacks`` manifests.  Their
declared ``orderInLevel`` values reserve a contiguous prefix immediately
after the live UI order, so a later batch plans the following slot without
pretending that the earlier batch was already merged.

IMPORTANT: this is not a replacement for ``apply_review.py``.  It never
writes files and must never invoke ``scripts/build_vocab_packs.py``.  That
legacy migration script only understands the old 11-column vocabulary schema
and can destroy the current 15-column asset.
"""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass, replace
import json
import re
import sys
from pathlib import Path
from typing import Any, Iterable

from validate_content import LOWER_LEVELS, VOCAB_HEADER


ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "assets" / "data"
VOCAB_PATH = DATA_DIR / "korean_vocab.csv"
CURRICULUM_PATH = DATA_DIR / "curriculum_manifest.json"
PACK_SERVICE_PATH = ROOT / "lib" / "services" / "vocab_pack_service.dart"
STAMP_PATH = ROOT / "lib" / "widgets" / "sori" / "dancheong_stamp.dart"

VOCAB_ID_RE = re.compile(r"vocab_(a1|a2|b1|b2|c1|c2)_\d+")
PACK_BASE_RE = re.compile(r"(a1|a2|b1|b2|c1|c2)_[a-z0-9]+(?:_[a-z0-9]+)*")


class PackAssignmentError(ValueError):
    """A draft or metadata problem that Jin can fix before merge."""


@dataclass(frozen=True)
class PackPlan:
    """The validated, read-only handoff for one base pack."""

    pack_id_base: str
    level: str
    order_in_level: int
    label_de: str
    label_en: str
    motif: str
    curriculum_unit_id: str
    pack_ids: tuple[str, ...]


def _read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    try:
        with path.open(encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            header = list(reader.fieldnames or [])
            rows = list(reader)
    except (OSError, csv.Error) as error:
        raise PackAssignmentError(f"cannot read CSV {path}: {error}") from error
    if header != VOCAB_HEADER:
        raise PackAssignmentError(
            f"{path}: expected the exact 15-column korean_vocab.csv header",
        )
    for row_number, row in enumerate(rows, start=2):
        if None in row:
            raise PackAssignmentError(f"{path}:{row_number}: row has more columns than its header")
        missing = [field for field in VOCAB_HEADER if not (row.get(field) or "").strip()]
        if missing:
            raise PackAssignmentError(
                f"{path}:{row_number}: empty required field(s): {', '.join(missing)}",
            )
    return header, rows


def _read_json(path: Path) -> Any:
    try:
        with path.open(encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, json.JSONDecodeError) as error:
        raise PackAssignmentError(f"cannot read JSON {path}: {error}") from error


def _pack_base(pack_id: str) -> str:
    """Return the display/motif base for ``b1_topic_1`` and legacy bases."""

    parts = pack_id.split("_")
    if parts and parts[-1].isdigit():
        return "_".join(parts[:-1])
    return pack_id


def _require_string(payload: dict[str, Any], key: str, label: str) -> str:
    value = payload.get(key)
    if not isinstance(value, str) or not value.strip():
        raise PackAssignmentError(f"{label}: {key} must be a nonempty string")
    return value.strip()


def _positive_integer_list(value: Any, *, label: str) -> list[int]:
    if not isinstance(value, list) or any(type(item) is not int or item < 1 for item in value):
        raise PackAssignmentError(f"{label} must be an array of positive integers")
    return value


def _normalise_vocab_pack_manifest_entry(
    entry: dict[str, Any],
    index: int,
    *,
    source_label: str = "metadata",
) -> dict[str, Any]:
    """Convert Batch 01's single-source manifest shape into planner fields."""

    label = f"{source_label} vocabPacks[{index}]"
    pack_id = _require_string(entry, "packId", label)
    level = _require_string(entry, "level", label).lower()
    if level not in LOWER_LEVELS:
        raise PackAssignmentError(f"{label}: level must be one of A1-C2")
    if not PACK_BASE_RE.fullmatch(pack_id) or not pack_id.startswith(f"{level}_"):
        raise PackAssignmentError(f"{label}: invalid or level-mismatched packId {pack_id!r}")
    pack_id_base = _pack_base(pack_id)
    if pack_id_base == pack_id:
        raise PackAssignmentError(
            f"{label}: packId must include its numeric sub-pack suffix: {pack_id!r}",
        )

    order_range = _positive_integer_list(entry.get("orderRange"), label=f"{label}.orderRange")
    if len(order_range) != 2 or order_range[0] != 1 or order_range[1] not in (11, 12):
        raise PackAssignmentError(
            f"{label}: orderRange must be [1, 11] or [1, 12]",
        )
    boss_orders = _positive_integer_list(
        entry.get("reviewBossOrders"),
        label=f"{label}.reviewBossOrders",
    )
    if len(boss_orders) not in (2, 3) or len(set(boss_orders)) != len(boss_orders):
        raise PackAssignmentError(f"{label}: reviewBossOrders must contain two or three unique orders")
    expected_boss_orders = list(range(order_range[1] - len(boss_orders) + 1, order_range[1] + 1))
    if sorted(boss_orders) != expected_boss_orders:
        raise PackAssignmentError(
            f"{label}: reviewBossOrders must be the final {len(boss_orders)} values in orderRange",
        )

    display_label = entry.get("displayLabel")
    if not isinstance(display_label, dict):
        raise PackAssignmentError(f"{label}: displayLabel must contain ko, de, and en")
    _require_string(display_label, "ko", f"{label}.displayLabel")
    label_de = _require_string(display_label, "de", f"{label}.displayLabel")
    label_en = _require_string(display_label, "en", f"{label}.displayLabel")

    curriculum = entry.get("curriculum")
    if not isinstance(curriculum, dict):
        raise PackAssignmentError(f"{label}: curriculum must contain courseUnitId and conceptIds")
    curriculum_unit_id = _require_string(curriculum, "courseUnitId", f"{label}.curriculum")
    concept_ids = curriculum.get("conceptIds")
    if (
        not isinstance(concept_ids, list)
        or not concept_ids
        or any(not isinstance(concept_id, str) or not concept_id.strip() for concept_id in concept_ids)
    ):
        raise PackAssignmentError(f"{label}.curriculum: conceptIds must be a nonempty string array")

    return {
        "packIdBase": pack_id_base,
        "level": level,
        "orderInLevel": entry.get("orderInLevel"),
        "label": {"de": label_de, "en": label_en},
        "motif": entry.get("motif"),
        "curriculumUnitId": curriculum_unit_id,
        "_format": "vocabPacks",
        "_source_label": label,
        "_manifest_pack_id": pack_id,
        "_manifest_order_range": tuple(order_range),
        "_manifest_boss_orders": tuple(sorted(boss_orders)),
    }


def _load_metadata(
    path: Path,
    *,
    source_label: str = "metadata",
) -> list[dict[str, Any]]:
    """Accept the legacy minimal ``packs`` file or Batch 01's richer manifest."""

    payload = _read_json(path)
    if not isinstance(payload, dict):
        raise PackAssignmentError(f"{path}: metadata root must be an object")
    legacy_packs = payload.get("packs")
    manifest_packs = payload.get("vocabPacks")
    if legacy_packs is not None and manifest_packs is not None:
        raise PackAssignmentError(f"{path}: use either packs or vocabPacks, not both")
    if legacy_packs is not None:
        if type(payload.get("version")) is not int or payload["version"] < 1:
            raise PackAssignmentError(f"{path}: version must be a positive integer")
        if not isinstance(legacy_packs, list) or not legacy_packs:
            raise PackAssignmentError(f"{path}: packs must be a nonempty array")
        if any(not isinstance(item, dict) for item in legacy_packs):
            raise PackAssignmentError(f"{path}: every packs item must be an object")
        return [
            {
                **item,
                "_format": "packs",
                "_source_label": f"{source_label} packs[{index}]",
            }
            for index, item in enumerate(legacy_packs)
        ]
    if manifest_packs is not None:
        if "version" in payload and (type(payload["version"]) is not int or payload["version"] < 1):
            raise PackAssignmentError(f"{path}: version must be a positive integer when present")
        if not isinstance(manifest_packs, list) or not manifest_packs:
            raise PackAssignmentError(f"{path}: vocabPacks must be a nonempty array")
        if any(not isinstance(item, dict) for item in manifest_packs):
            raise PackAssignmentError(f"{path}: every vocabPacks item must be an object")
        return [
            _normalise_vocab_pack_manifest_entry(
                item,
                index,
                source_label=source_label,
            )
            for index, item in enumerate(manifest_packs)
        ]
    raise PackAssignmentError(f"{path}: metadata needs a packs or vocabPacks array")


def _load_reserved_metadata(path: Path) -> list[dict[str, Any]]:
    """Load a pending predecessor manifest, refusing the legacy shape.

    A reservation is an externally visible promise about a future UI order.
    It therefore needs the richer ``vocabPacks`` schema, including its
    explicit pack identity and complete multilingual label, rather than the
    old compatibility-only ``packs`` metadata format.
    """

    payload = _read_json(path)
    if not isinstance(payload, dict):
        raise PackAssignmentError(f"{path}: reserved metadata root must be an object")
    if payload.get("packs") is not None or payload.get("vocabPacks") is None:
        raise PackAssignmentError(
            f"{path}: reserved metadata must contain a vocabPacks array, not legacy packs",
        )
    return _load_metadata(path, source_label=f"reserved metadata {path}")


def _pack_order_map(path: Path) -> dict[str, int]:
    """Read the current UI's level order without importing or running Dart."""

    try:
        source = path.read_text(encoding="utf-8")
    except OSError as error:
        raise PackAssignmentError(f"cannot read current pack order map {path}: {error}") from error
    marker = "static const Map<String, int> packOrderInLevel = {"
    start = source.find(marker)
    if start < 0:
        raise PackAssignmentError(f"{path}: cannot find packOrderInLevel")
    end = source.find("\n  };", start)
    if end < 0:
        raise PackAssignmentError(f"{path}: cannot find the end of packOrderInLevel")
    body = source[start:end]
    entries = {
        match.group(1): int(match.group(2))
        for match in re.finditer(r"'([a-z0-9_]+)'\s*:\s*(\d+),", body)
    }
    if not entries:
        raise PackAssignmentError(f"{path}: packOrderInLevel contains no entries")
    return entries


def _known_motifs(path: Path) -> set[str]:
    try:
        source = path.read_text(encoding="utf-8")
    except OSError as error:
        raise PackAssignmentError(f"cannot read Dancheong motif enum {path}: {error}") from error
    match = re.search(r"enum\s+DancheongMotif\s*\{(?P<body>.*?)\n\}", source, re.DOTALL)
    if match is None:
        raise PackAssignmentError(f"{path}: cannot find DancheongMotif enum")
    motifs = {
        item.group(1)
        for item in re.finditer(r"^\s*([a-z][a-z0-9_]*)\s*,", match.group("body"), re.MULTILINE)
    }
    if not motifs:
        raise PackAssignmentError(f"{path}: DancheongMotif enum contains no values")
    return motifs


def _curriculum_units(path: Path) -> dict[str, str]:
    payload = _read_json(path)
    units = payload.get("courseUnits") if isinstance(payload, dict) else None
    if not isinstance(units, list):
        raise PackAssignmentError(f"{path}: courseUnits must be an array")
    result: dict[str, str] = {}
    for number, unit in enumerate(units, start=1):
        if not isinstance(unit, dict):
            raise PackAssignmentError(f"{path}: courseUnits[{number}] must be an object")
        ident = unit.get("id")
        level = unit.get("level")
        if not isinstance(ident, str) or not isinstance(level, str):
            raise PackAssignmentError(f"{path}: courseUnits[{number}] needs string id and level")
        result[ident] = level.lower()
    return result


def _curriculum_extension_units(path: Path) -> dict[str, str]:
    """Read review-only course units declared by an advanced batch manifest."""

    payload = _read_json(path)
    extensions = payload.get("curriculumExtensions") if isinstance(payload, dict) else None
    if extensions is None:
        return {}
    if not isinstance(extensions, dict):
        raise PackAssignmentError(f"{path}: curriculumExtensions must be an object")
    units = extensions.get("courseUnits")
    if not isinstance(units, list):
        raise PackAssignmentError(
            f"{path}: curriculumExtensions.courseUnits must be an array",
        )
    result: dict[str, str] = {}
    for number, unit in enumerate(units, start=1):
        if not isinstance(unit, dict):
            raise PackAssignmentError(
                f"{path}: curriculumExtensions.courseUnits[{number}] must be an object",
            )
        ident = unit.get("id")
        level = unit.get("level")
        if not isinstance(ident, str) or not ident.strip():
            raise PackAssignmentError(
                f"{path}: curriculumExtensions.courseUnits[{number}] needs an id",
            )
        if not isinstance(level, str) or level.lower() not in LOWER_LEVELS:
            raise PackAssignmentError(
                f"{path}: curriculumExtensions.courseUnits[{number}] has an invalid level",
            )
        if ident in result:
            raise PackAssignmentError(
                f"{path}: duplicate curriculum extension unit {ident!r}",
            )
        result[ident] = level.lower()
    return result


def _validate_metadata_entry(
    entry: dict[str, Any],
    *,
    index: int,
    known_motifs: set[str],
    curriculum_units: dict[str, str],
) -> tuple[str, str, int | None, str, str, str, str]:
    label = str(entry.get("_source_label") or f"metadata packs[{index}]")
    pack_id_base = _require_string(entry, "packIdBase", label)
    level = _require_string(entry, "level", label).lower()
    if level not in LOWER_LEVELS:
        raise PackAssignmentError(f"{label}: level must be one of A1-C2")
    if not PACK_BASE_RE.fullmatch(pack_id_base):
        raise PackAssignmentError(f"{label}: packIdBase has an invalid shape: {pack_id_base!r}")
    if _pack_base(pack_id_base) != pack_id_base:
        raise PackAssignmentError(
            f"{label}: packIdBase must omit a numeric sub-pack suffix: {pack_id_base!r}",
        )
    if not pack_id_base.startswith(f"{level}_"):
        raise PackAssignmentError(f"{label}: packIdBase does not match level {level}")

    order = entry.get("orderInLevel")
    if order is None and entry.get("_format") == "vocabPacks":
        pass
    elif type(order) is not int or order < 1:
        raise PackAssignmentError(f"{label}: orderInLevel must be a positive integer")

    labels = entry.get("label")
    if not isinstance(labels, dict):
        raise PackAssignmentError(f"{label}: label must be an object with de and en")
    label_de = _require_string(labels, "de", f"{label}.label")
    label_en = _require_string(labels, "en", f"{label}.label")

    motif = _require_string(entry, "motif", label)
    if motif not in known_motifs:
        raise PackAssignmentError(
            f"{label}: motif {motif!r} is not an existing DancheongMotif "
            f"({', '.join(sorted(known_motifs))})",
        )
    curriculum_unit_id = _require_string(entry, "curriculumUnitId", label)
    unit_level = curriculum_units.get(curriculum_unit_id)
    if unit_level is None:
        raise PackAssignmentError(
            f"{label}: unknown curriculumUnitId {curriculum_unit_id!r}",
        )
    if unit_level != level:
        raise PackAssignmentError(
            f"{label}: curriculum unit {curriculum_unit_id!r} is {unit_level}, not {level}",
        )
    return (
        pack_id_base,
        level,
        order,
        label_de,
        label_en,
        motif,
        curriculum_unit_id,
    )


def _reserved_plans_by_level(
    paths: Iterable[Path],
    *,
    known_motifs: set[str],
    curriculum_units: dict[str, str],
    current_order_map: dict[str, int],
    existing_pack_bases: set[str],
    current_metadata_bases: set[str],
) -> dict[str, list[PackPlan]]:
    """Validate pending batch manifests and return their reserved UI slots.

    A predecessor is not part of the live CSV or Dart order map yet.  It must
    nevertheless be just as valid as a current manifest, cannot reuse a
    current or current-batch base, and must reserve every next slot in order.
    This is deliberately metadata-only and never opens or writes a draft.
    """

    reserved_by_base: dict[str, PackPlan] = {}
    reserved_orders_by_level: dict[str, dict[int, str]] = {}

    for raw_path in paths:
        path = Path(raw_path).resolve()
        entries = _load_reserved_metadata(path)
        for index, entry in enumerate(entries):
            (
                pack_id_base,
                level,
                order,
                label_de,
                label_en,
                motif,
                curriculum_unit_id,
            ) = _validate_metadata_entry(
                entry,
                index=index,
                known_motifs=known_motifs,
                curriculum_units=curriculum_units,
            )
            label = str(entry.get("_source_label") or f"reserved metadata {path}")
            if entry.get("_format") != "vocabPacks":
                raise PackAssignmentError(
                    f"{label}: reserved metadata must use vocabPacks",
                )
            if order is None:
                raise PackAssignmentError(
                    f"{label}: reserved vocabPacks requires a declared orderInLevel",
                )
            if pack_id_base in existing_pack_bases or pack_id_base in current_order_map:
                raise PackAssignmentError(
                    f"{label}: reserved packIdBase already exists in live content: "
                    f"{pack_id_base!r}",
                )
            if pack_id_base in current_metadata_bases:
                raise PackAssignmentError(
                    f"{label}: reserved packIdBase conflicts with current metadata: "
                    f"{pack_id_base!r}",
                )
            if pack_id_base in reserved_by_base:
                raise PackAssignmentError(
                    f"duplicate reserved metadata packIdBase {pack_id_base!r}",
                )
            orders_for_level = reserved_orders_by_level.setdefault(level, {})
            existing_base = orders_for_level.get(order)
            if existing_base is not None:
                raise PackAssignmentError(
                    f"duplicate reserved {level} orderInLevel {order}: "
                    f"{existing_base!r} and {pack_id_base!r}",
                )
            plan = PackPlan(
                pack_id_base=pack_id_base,
                level=level,
                order_in_level=order,
                label_de=label_de,
                label_en=label_en,
                motif=motif,
                curriculum_unit_id=curriculum_unit_id,
                pack_ids=(),
            )
            reserved_by_base[pack_id_base] = plan
            orders_for_level[order] = pack_id_base

    result: dict[str, list[PackPlan]] = {}
    for level, orders_for_level in reserved_orders_by_level.items():
        existing_orders = [
            order
            for base, order in current_order_map.items()
            if base.startswith(f"{level}_")
        ]
        live_last_order = max(existing_orders) if existing_orders else 0
        expected_orders = list(
            range(live_last_order + 1, live_last_order + len(orders_for_level) + 1),
        )
        actual_orders = sorted(orders_for_level)
        if actual_orders != expected_orders:
            raise PackAssignmentError(
                f"reserved {level} orderInLevel must form the contiguous prefix "
                f"after live order: expected {expected_orders}, got {actual_orders}",
            )
        result[level] = [
            reserved_by_base[orders_for_level[order]] for order in actual_orders
        ]
    return result


def _validate_draft_rows(
    rows: list[dict[str, str]],
    *,
    existing_rows: list[dict[str, str]],
) -> dict[str, list[dict[str, str]]]:
    if not rows:
        raise PackAssignmentError("vocab draft must contain at least one row")
    existing_ids = {(row.get("id") or "").strip() for row in existing_rows}
    existing_korean = {(row.get("korean") or "").strip() for row in existing_rows}
    seen_ids: set[str] = set()
    seen_korean: set[str] = set()
    by_pack: dict[str, list[dict[str, str]]] = {}

    for row_number, row in enumerate(rows, start=2):
        label = f"draft row {row_number}"
        ident = row["id"].strip()
        level = row["level"].strip().lower()
        korean = row["korean"].strip()
        pack_id = row["pack_id"].strip()
        if level not in LOWER_LEVELS:
            raise PackAssignmentError(f"{label}: invalid level {row['level']!r}")
        if VOCAB_ID_RE.fullmatch(ident) is None or ident.split("_")[1] != level:
            raise PackAssignmentError(f"{label}: invalid or level-mismatched vocab id {ident!r}")
        if ident in seen_ids or ident in existing_ids:
            raise PackAssignmentError(f"{label}: vocab id already exists: {ident!r}")
        if korean in seen_korean or korean in existing_korean:
            raise PackAssignmentError(f"{label}: Korean headword already exists: {korean!r}")
        if PACK_BASE_RE.fullmatch(pack_id) is None or not pack_id.startswith(f"{level}_"):
            raise PackAssignmentError(f"{label}: invalid or level-mismatched pack_id {pack_id!r}")
        try:
            order = int(row["pack_order"])
        except ValueError as error:
            raise PackAssignmentError(f"{label}: pack_order must be an integer") from error
        if order < 1:
            raise PackAssignmentError(f"{label}: pack_order must be positive")
        if row["is_review_boss"].strip().lower() not in {"true", "false"}:
            raise PackAssignmentError(f"{label}: is_review_boss must be true or false")
        seen_ids.add(ident)
        seen_korean.add(korean)
        by_pack.setdefault(pack_id, []).append(row)
    return by_pack


def validate_plan(
    draft_path: Path,
    metadata_path: Path,
    *,
    root: Path = ROOT,
    reserved_metadata_paths: Iterable[Path] = (),
) -> list[PackPlan]:
    """Validate a proposed vocabulary batch without writing any file.

    ``root`` is injectable for tests.  Production callers should leave it at
    the repository root so the current static assets are the source of truth.
    ``reserved_metadata_paths`` can name earlier review-only ``vocabPacks``
    manifests whose contiguous future UI slots must be treated as occupied.
    """

    root = root.resolve()
    reserved_metadata_paths = tuple(Path(path) for path in reserved_metadata_paths)
    _, existing_rows = _read_csv(root / "assets" / "data" / "korean_vocab.csv")
    _, draft_rows = _read_csv(draft_path.resolve())
    draft_by_pack = _validate_draft_rows(draft_rows, existing_rows=existing_rows)
    metadata_entries = _load_metadata(metadata_path.resolve())
    known_motifs = _known_motifs(root / "lib" / "widgets" / "sori" / "dancheong_stamp.dart")
    curriculum_units = _curriculum_units(root / "assets" / "data" / "curriculum_manifest.json")
    for source_path in (metadata_path.resolve(), *[path.resolve() for path in reserved_metadata_paths]):
        for unit_id, level in _curriculum_extension_units(source_path).items():
            existing_level = curriculum_units.get(unit_id)
            if existing_level is not None and existing_level != level:
                raise PackAssignmentError(
                    f"{source_path}: curriculum unit {unit_id!r} conflicts with level "
                    f"{existing_level}",
                )
            curriculum_units[unit_id] = level
    current_order_map = _pack_order_map(root / "lib" / "services" / "vocab_pack_service.dart")

    existing_pack_ids = {(row.get("pack_id") or "").strip() for row in existing_rows}
    existing_pack_bases = {_pack_base(pack_id) for pack_id in existing_pack_ids}
    metadata_by_base: dict[str, PackPlan] = {}
    metadata_source_by_base: dict[str, dict[str, Any]] = {}
    for index, entry in enumerate(metadata_entries):
        (
            pack_id_base,
            level,
            order,
            label_de,
            label_en,
            motif,
            curriculum_unit_id,
        ) = _validate_metadata_entry(
            entry,
            index=index,
            known_motifs=known_motifs,
            curriculum_units=curriculum_units,
        )
        if pack_id_base in metadata_by_base:
            raise PackAssignmentError(f"duplicate metadata packIdBase {pack_id_base!r}")
        if pack_id_base in existing_pack_bases or pack_id_base in current_order_map:
            raise PackAssignmentError(f"packIdBase already exists: {pack_id_base!r}")
        metadata_by_base[pack_id_base] = PackPlan(
            pack_id_base=pack_id_base,
            level=level,
            # The richer Batch 01 manifest owns intra-pack ranges and leaves
            # this future UI-map value to the planner.  Zero is an internal
            # sentinel only; the returned plan always has a real next order.
            order_in_level=order if order is not None else 0,
            label_de=label_de,
            label_en=label_en,
            motif=motif,
            curriculum_unit_id=curriculum_unit_id,
            pack_ids=(),
        )
        metadata_source_by_base[pack_id_base] = entry

    reserved_by_level = _reserved_plans_by_level(
        reserved_metadata_paths,
        known_motifs=known_motifs,
        curriculum_units=curriculum_units,
        current_order_map=current_order_map,
        existing_pack_bases=existing_pack_bases,
        current_metadata_bases=set(metadata_by_base),
    )

    # A review draft can legitimately also contain approved additions to an
    # *existing* pack.  Those rows are not a new pack assignment and therefore
    # intentionally stay outside this planner.  ``apply_review.py`` uses this
    # behavior to preserve existing-pack maintenance workflows while requiring
    # metadata for every actually new pack_id.
    draft_pack_ids_by_base: dict[str, list[str]] = {}
    for pack_id, rows in sorted(draft_by_pack.items()):
        if pack_id in existing_pack_ids:
            continue
        base = _pack_base(pack_id)
        plan = metadata_by_base.get(base)
        if plan is None:
            raise PackAssignmentError(
                f"draft pack {pack_id!r} has no matching metadata packIdBase {base!r}",
            )
        levels = {row["level"].strip().lower() for row in rows}
        if levels != {plan.level}:
            raise PackAssignmentError(
                f"draft pack {pack_id!r} level {sorted(levels)} does not match metadata {plan.level}",
            )
        word_count = len(rows)
        if word_count not in {11, 12}:
            raise PackAssignmentError(
                f"draft pack {pack_id!r} has {word_count} rows; expected 11 or 12",
            )
        orders = sorted(int(row["pack_order"]) for row in rows)
        expected_orders = list(range(1, word_count + 1))
        if orders != expected_orders:
            raise PackAssignmentError(
                f"draft pack {pack_id!r} pack_order must be exactly 1..{word_count}",
            )
        boss_orders = sorted(
            int(row["pack_order"])
            for row in rows
            if row["is_review_boss"].strip().lower() == "true"
        )
        if len(boss_orders) not in {2, 3}:
            raise PackAssignmentError(
                f"draft pack {pack_id!r} has {len(boss_orders)} Boss rows; expected 2 or 3",
            )
        expected_boss_orders = list(range(word_count - len(boss_orders) + 1, word_count + 1))
        if boss_orders != expected_boss_orders:
            raise PackAssignmentError(
                f"draft pack {pack_id!r} Boss rows must be the final {len(boss_orders)} pack_order values",
            )
        source_entry = metadata_source_by_base[base]
        if source_entry.get("_format") == "vocabPacks":
            expected_pack_id = source_entry["_manifest_pack_id"]
            if pack_id != expected_pack_id:
                raise PackAssignmentError(
                    f"{source_entry['_source_label']}: packId {expected_pack_id!r} "
                    f"does not match draft pack {pack_id!r}",
                )
            if (orders[0], orders[-1]) != source_entry["_manifest_order_range"]:
                raise PackAssignmentError(
                    f"{source_entry['_source_label']}: orderRange "
                    f"{list(source_entry['_manifest_order_range'])} does not match "
                    f"draft orders [{orders[0]}, {orders[-1]}]",
                )
            if tuple(boss_orders) != source_entry["_manifest_boss_orders"]:
                raise PackAssignmentError(
                    f"{source_entry['_source_label']}: reviewBossOrders "
                    f"{list(source_entry['_manifest_boss_orders'])} do not match "
                    f"draft Boss orders {boss_orders}",
                )
        draft_pack_ids_by_base.setdefault(base, []).append(pack_id)

    if set(draft_pack_ids_by_base) != set(metadata_by_base):
        unused = sorted(set(metadata_by_base) - set(draft_pack_ids_by_base))
        raise PackAssignmentError(
            "metadata packIdBase has no draft rows: " + ", ".join(unused),
        )

    plans: list[PackPlan] = []
    for level in sorted({plan.level for plan in metadata_by_base.values()}):
        plans_for_level = [
            plan for plan in metadata_by_base.values() if plan.level == level
        ]
        existing_orders = [
            order
            for base, order in current_order_map.items()
            if base.startswith(f"{level}_")
        ]
        reserved_for_level = reserved_by_level.get(level, [])
        reserved_orders = {plan.order_in_level for plan in reserved_for_level}
        declared_reserved_collisions = sorted(
            {
                plan.order_in_level
                for plan in plans_for_level
                if plan.order_in_level != 0 and plan.order_in_level in reserved_orders
            },
        )
        if declared_reserved_collisions:
            raise PackAssignmentError(
                f"{level}: metadata orderInLevel conflicts with reserved predecessor "
                f"order(s) {declared_reserved_collisions}",
            )
        next_order = (max(existing_orders) if existing_orders else 0) + len(reserved_for_level) + 1
        expected_orders = list(range(next_order, next_order + len(plans_for_level)))
        declared_orders = [plan.order_in_level for plan in plans_for_level]
        if any(order == 0 for order in declared_orders):
            if any(order != 0 for order in declared_orders):
                raise PackAssignmentError(
                    f"{level}: metadata must either declare every orderInLevel or omit all of them",
                )
            assigned_orders = expected_orders
        else:
            plans_for_level = sorted(plans_for_level, key=lambda plan: plan.order_in_level)
            actual_orders = [plan.order_in_level for plan in plans_for_level]
            if actual_orders != expected_orders:
                raise PackAssignmentError(
                    f"{level} orderInLevel must use the next unused sequence "
                    f"{expected_orders}, got {actual_orders}",
                )
            assigned_orders = actual_orders
        for plan, assigned_order in zip(plans_for_level, assigned_orders):
            plans.append(
                replace(
                    plan,
                    order_in_level=assigned_order,
                    pack_ids=tuple(sorted(draft_pack_ids_by_base[plan.pack_id_base])),
                ),
            )
    return plans


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--draft", required=True, help="schema-complete vocab CSV draft")
    parser.add_argument("--metadata", required=True, help="JSON pack-assignment metadata")
    parser.add_argument(
        "--reserved-metadata",
        "--predecessor-metadata",
        action="append",
        default=[],
        dest="reserved_metadata",
        metavar="PATH",
        help=(
            "repeat for each earlier pending vocabPacks manifest whose declared "
            "orderInLevel reserves the preceding slot"
        ),
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    print(
        "READ-ONLY: never run scripts/build_vocab_packs.py; it can damage the "
        "current 15-column korean_vocab.csv.",
        file=sys.stderr,
    )
    try:
        plans = validate_plan(
            Path(args.draft),
            Path(args.metadata),
            reserved_metadata_paths=[Path(path) for path in args.reserved_metadata],
        )
    except PackAssignmentError as error:
        print(f"✗ {error}", file=sys.stderr)
        return 1
    print("✓ vocabulary pack assignment preflight passed; no files were changed")
    for plan in plans:
        print(
            f"- {plan.pack_id_base}: {', '.join(plan.pack_ids)} · {plan.level.upper()} "
            f"#{plan.order_in_level} · {plan.label_de} / {plan.label_en} · "
            f"motif={plan.motif} · curriculum={plan.curriculum_unit_id}",
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
