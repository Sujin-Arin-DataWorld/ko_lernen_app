#!/usr/bin/env python3
"""Fail-closed, read-only validation for the Batch 01 B1/B2 review draft.

``validate_content.py`` intentionally validates only the checked-in app
assets.  Batch 01 must be provable *before* Jin changes a review status or an
approved record is appended, so this tool builds a disposable overlay of the
current assets plus every Batch 01 candidate.  It also supplies the declared
curriculum companion mappings to that overlay and runs the normal full graph
validator against it.

No source file is written.  The only files created live in a temporary
directory that is removed before this process exits.

Usage:
    python3 tools/content_factory/validate_batch_01.py
    python3 tools/content_factory/validate_batch_01.py --manifest \
      tools/content_factory/drafts/batch_01_manifest.json
"""

from __future__ import annotations

import argparse
import csv
import json
import shutil
import tempfile
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

import plan_pack_assignments as pack_planner
from validate_content import ContentValidator, GRAMMAR_HEADER, VOCAB_HEADER


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MANIFEST = Path("tools/content_factory/drafts/batch_01_manifest.json")
REVIEW_HEADER = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]


@dataclass(frozen=True)
class ArtifactSpec:
    kind: str
    draft: Path
    review: Path
    target: str
    collection: str | None
    header: tuple[str, ...] | None
    count: int
    levels: dict[str, int]


ARTIFACT_SPECS: dict[str, ArtifactSpec] = {
    "vocab": ArtifactSpec(
        kind="vocab",
        draft=Path("tools/content_factory/drafts/c3_batch01_vocab_b1_b2.csv"),
        review=Path("tools/content_factory/review/c3_batch01_vocab.csv"),
        target="korean_vocab.csv",
        collection=None,
        header=tuple(VOCAB_HEADER),
        count=24,
        levels={"b1": 12, "b2": 12},
    ),
    "grammar": ArtifactSpec(
        kind="grammar",
        draft=Path("tools/content_factory/drafts/c4_batch01_grammar_b1_b2.csv"),
        review=Path("tools/content_factory/review/c4_batch01_grammar.csv"),
        target="grammar.csv",
        collection=None,
        header=tuple(GRAMMAR_HEADER),
        count=8,
        levels={"b1": 4, "b2": 4},
    ),
    "smalltalk": ArtifactSpec(
        kind="smalltalk",
        draft=Path("tools/content_factory/drafts/c2_batch01_smalltalk_b1_b2.json"),
        review=Path("tools/content_factory/review/c2_batch01_smalltalk.csv"),
        target="smalltalk.json",
        collection="phrases",
        header=None,
        count=16,
        levels={"b1": 8, "b2": 8},
    ),
    "cloze": ArtifactSpec(
        kind="cloze",
        draft=Path("tools/content_factory/drafts/c2_batch01_cloze_b1_b2.json"),
        review=Path("tools/content_factory/review/c2_batch01_cloze.csv"),
        target="cloze.json",
        collection="items",
        header=None,
        count=24,
        levels={"b1": 12, "b2": 12},
    ),
    "satz": ArtifactSpec(
        kind="satz",
        draft=Path("tools/content_factory/drafts/c2_batch01_satz_b1_b2.json"),
        review=Path("tools/content_factory/review/c2_batch01_satz.csv"),
        target="satz_sentences.json",
        collection="items",
        header=None,
        count=24,
        levels={"b1": 12, "b2": 12},
    ),
}

EXPECTED_IDS: dict[str, set[str]] = {
    "vocab": {
        *(f"vocab_b1_{number:04d}" for number in range(248, 260)),
        *(f"vocab_b2_{number:04d}" for number in range(205, 217)),
    },
    "grammar": {
        "grammar_b1_tendency",
        "grammar_b1_prepared_state",
        "grammar_b1_near_miss",
        "grammar_b1_state_while",
        "grammar_b2_formal_reason",
        "grammar_b2_formal_arrangement",
        "grammar_b2_formal_reference",
        "grammar_b2_inclusion",
    },
    "smalltalk": {
        *(f"smalltalk_b1_{number:04d}" for number in range(37, 45)),
        *(f"smalltalk_b2_{number:04d}" for number in range(37, 45)),
    },
    "cloze": {
        *(f"cloze_b1_{number:04d}" for number in range(56, 68)),
        *(f"cloze_b2_{number:04d}" for number in range(58, 70)),
    },
    "satz": {
        *(f"satz_b1_{number:04d}" for number in range(50, 62)),
        *(f"satz_b2_{number:04d}" for number in range(42, 54)),
    },
}


@dataclass(frozen=True)
class ArtifactPayload:
    spec: ArtifactSpec
    draft_path: Path
    review_path: Path
    records: tuple[dict[str, Any], ...]


@dataclass(frozen=True)
class CurriculumAdditions:
    vocab_pack_unit_map: dict[str, str]
    grammar_rule_map: dict[str, dict[str, Any]]
    smalltalk_category_unit_map: dict[str, dict[str, Any]]
    cloze_topic_unit_map: dict[str, str]
    vocab_packs: tuple[dict[str, Any], ...]


@dataclass(frozen=True)
class BatchValidationResult:
    record_count: int
    inventory_counts: dict[str, int]
    planned_pack_ids: tuple[str, ...]


class BatchValidationError(ValueError):
    """One or more non-reviewable Batch 01 contract violations."""

    def __init__(self, messages: str | Iterable[str]) -> None:
        if isinstance(messages, str):
            messages = [messages]
        self.messages = tuple(messages)
        super().__init__("\n".join(self.messages))


def _fail(message: str) -> None:
    raise BatchValidationError(message)


def _read_json(path: Path) -> Any:
    try:
        with path.open(encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, json.JSONDecodeError) as error:
        _fail(f"{path}: cannot load JSON: {error}")


def _write_json(path: Path, value: Any) -> None:
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def _read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    try:
        with path.open(encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            header = list(reader.fieldnames or [])
            if not header or any(not field for field in header):
                _fail(f"{path}: CSV header must contain nonempty columns")
            if len(header) != len(set(header)):
                _fail(f"{path}: CSV header contains duplicate columns")
            rows: list[dict[str, str]] = []
            for row_number, row in enumerate(reader, start=2):
                if None in row:
                    _fail(f"{path}:{row_number}: row has more columns than its header")
                missing = [field for field in header if row.get(field) is None]
                if missing:
                    _fail(
                        f"{path}:{row_number}: row is missing columns: {', '.join(missing)}",
                    )
                rows.append({field: row[field] for field in header})
    except (OSError, csv.Error) as error:
        _fail(f"{path}: cannot load CSV: {error}")
    return header, rows


def _write_csv(path: Path, header: Iterable[str], rows: Iterable[dict[str, Any]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=list(header),
            extrasaction="raise",
            lineterminator="\n",
        )
        writer.writeheader()
        writer.writerows(rows)


def _required_string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        _fail(f"{label} must be a nonempty string")
    return value.strip()


def _level(value: Any, label: str) -> str:
    normalized = _required_string(value, label).lower()
    if normalized not in {"a1", "a2", "b1", "b2"}:
        _fail(f"{label} must be an A1–B2 level")
    return normalized


def _positive_int_text(value: Any, label: str) -> int:
    text = _required_string(value, label)
    try:
        parsed = int(text)
    except ValueError as error:
        raise BatchValidationError(f"{label} must be an integer") from error
    if parsed < 1:
        _fail(f"{label} must be positive")
    return parsed


def _resolve_under_root(root: Path, relative: Any, label: str) -> Path:
    if not isinstance(relative, str) or not relative.strip():
        _fail(f"{label} must be a nonempty repository-relative path")
    raw = Path(relative)
    if raw.is_absolute():
        _fail(f"{label} must not be absolute")
    path = (root / raw).resolve()
    try:
        path.relative_to(root.resolve())
    except ValueError:
        _fail(f"{label} escapes the repository root")
    return path


def _pack_base(pack_id: str) -> str:
    parts = pack_id.strip().lower().split("_")
    if len(parts) > 1 and parts[-1].isdigit():
        parts.pop()
    return "_".join(parts)


def _copy_json(value: Any) -> Any:
    """Copy only JSON-shaped data; keeps the overlay separate from source data."""

    return json.loads(json.dumps(value, ensure_ascii=False))


def _parse_manifest(root: Path, manifest_path: Path) -> tuple[dict[str, Any], dict[str, dict[str, Any]]]:
    manifest = _read_json(manifest_path)
    if not isinstance(manifest, dict):
        _fail(f"{manifest_path}: root must be an object")
    if manifest.get("version") != 1:
        _fail(f"{manifest_path}: version must be 1")
    if manifest.get("batch") != "01":
        _fail(f"{manifest_path}: batch must be the string '01'")
    if manifest.get("status") != "review_only_draft":
        _fail(f"{manifest_path}: status must be review_only_draft before Jin review")
    provenance = manifest.get("provenance")
    if not isinstance(provenance, dict) or provenance.get("requiresJinReview") is not True:
        _fail(f"{manifest_path}: provenance.requiresJinReview must be true")

    artifacts = manifest.get("artifacts")
    if not isinstance(artifacts, list):
        _fail(f"{manifest_path}: artifacts must be an array")
    by_kind: dict[str, dict[str, Any]] = {}
    for index, artifact in enumerate(artifacts):
        if not isinstance(artifact, dict):
            _fail(f"{manifest_path}: artifacts[{index}] must be an object")
        kind = _required_string(artifact.get("kind"), f"{manifest_path}: artifacts[{index}].kind")
        if kind in by_kind:
            _fail(f"{manifest_path}: duplicate artifact kind {kind!r}")
        if kind not in ARTIFACT_SPECS:
            _fail(f"{manifest_path}: unsupported Batch 01 artifact kind {kind!r}")
        by_kind[kind] = artifact
    if set(by_kind) != set(ARTIFACT_SPECS):
        _fail(
            f"{manifest_path}: artifacts must be exactly {', '.join(sorted(ARTIFACT_SPECS))}",
        )
    if manifest.get("recordCount") != 96:
        _fail(f"{manifest_path}: recordCount must be 96")

    for kind, spec in ARTIFACT_SPECS.items():
        artifact = by_kind[kind]
        if artifact.get("draft") != str(spec.draft):
            _fail(f"{manifest_path}: {kind}.draft must be {spec.draft}")
        if artifact.get("review") != str(spec.review):
            _fail(f"{manifest_path}: {kind}.review must be {spec.review}")
        if artifact.get("count") != spec.count:
            _fail(f"{manifest_path}: {kind}.count must be {spec.count}")
        if artifact.get("levels") != spec.levels:
            _fail(f"{manifest_path}: {kind}.levels must be {spec.levels}")
    return manifest, by_kind


def _load_artifact(root: Path, spec: ArtifactSpec, entry: dict[str, Any]) -> ArtifactPayload:
    draft_path = _resolve_under_root(root, entry["draft"], f"{spec.kind}.draft")
    review_path = _resolve_under_root(root, entry["review"], f"{spec.kind}.review")
    if not draft_path.is_file():
        _fail(f"{draft_path}: draft file does not exist")
    if not review_path.is_file():
        _fail(f"{review_path}: review ledger does not exist")

    if spec.header is not None:
        header, rows = _read_csv(draft_path)
        if header != list(spec.header):
            _fail(f"{draft_path}: header must exactly match the app {spec.kind} schema")
        records: list[dict[str, Any]] = rows
    else:
        payload = _read_json(draft_path)
        if not isinstance(payload, dict):
            _fail(f"{draft_path}: root must be an object")
        if spec.kind == "smalltalk" and (
            type(payload.get("version")) is not int or payload["version"] < 1
        ):
            _fail(f"{draft_path}: smalltalk draft needs a positive integer version")
        raw_records = payload.get(spec.collection or "")
        if not isinstance(raw_records, list) or any(
            not isinstance(record, dict) for record in raw_records
        ):
            _fail(f"{draft_path}: {spec.collection} must be an array of objects")
        records = list(raw_records)

    return ArtifactPayload(
        spec=spec,
        draft_path=draft_path,
        review_path=review_path,
        records=tuple(records),
    )


def _record_level_counts(records: Iterable[dict[str, Any]], label: str) -> Counter[str]:
    result: Counter[str] = Counter()
    for index, record in enumerate(records):
        result[_level(record.get("level"), f"{label}[{index}].level")] += 1
    return result


def _validate_artifact_records(payload: ArtifactPayload) -> None:
    spec = payload.spec
    if len(payload.records) != spec.count:
        _fail(f"{payload.draft_path}: expected {spec.count} records, got {len(payload.records)}")
    actual_levels = dict(_record_level_counts(payload.records, str(payload.draft_path)))
    if actual_levels != spec.levels:
        _fail(f"{payload.draft_path}: expected levels {spec.levels}, got {actual_levels}")
    ids: list[str] = []
    for index, record in enumerate(payload.records):
        ident = _required_string(record.get("id"), f"{payload.draft_path}[{index}].id")
        ids.append(ident)
    if len(ids) != len(set(ids)):
        _fail(f"{payload.draft_path}: draft has duplicate IDs")
    expected_ids = EXPECTED_IDS[spec.kind]
    if set(ids) != expected_ids:
        missing = sorted(expected_ids - set(ids))
        unexpected = sorted(set(ids) - expected_ids)
        details: list[str] = []
        if missing:
            details.append("missing " + ", ".join(missing))
        if unexpected:
            details.append("unexpected " + ", ".join(unexpected))
        _fail(f"{payload.draft_path}: Batch 01 ID contract failed ({'; '.join(details)})")


_REVIEW_COPY_FIELDS: dict[str, tuple[tuple[str, str], ...]] = {
    # The review ledger is an approval *view* of a schema-complete draft, not
    # a second editable source.  Keep its visible DE/EN/Korean copy aligned
    # with the exact field that will be appended on approval.
    "vocab": (("ko", "korean"), ("de", "german"), ("en", "english")),
    "grammar": (("ko", "pattern"), ("de", "type_de"), ("en", "type_en")),
    "smalltalk": (("ko", "ko"), ("de", "de"), ("en", "en")),
    "cloze": (("ko", "fullKo"), ("de", "de"), ("en", "en")),
    "satz": (("ko", "targetKo"), ("de", "promptDe"), ("en", "promptEn")),
}


def _project_review_copy(
    payload: ArtifactPayload,
    record: dict[str, Any],
    *,
    index: int,
) -> dict[str, str]:
    """Return the one canonical ledger copy projection for a draft record."""

    fields = _REVIEW_COPY_FIELDS.get(payload.spec.kind)
    if fields is None:
        _fail(f"{payload.draft_path}: no review-copy projection for {payload.spec.kind}")
    projection: dict[str, str] = {}
    for review_field, draft_field in fields:
        raw_value = record.get(draft_field)
        value = _required_string(
            raw_value,
            f"{payload.draft_path}[{index}].{draft_field}",
        )
        if raw_value != value:
            _fail(
                f"{payload.draft_path}[{index}].{draft_field} must not have leading or trailing whitespace",
            )
        projection[review_field] = value
    return projection


def _validate_review_ledger(payload: ArtifactPayload) -> None:
    header, rows = _read_csv(payload.review_path)
    if header != REVIEW_HEADER:
        _fail(f"{payload.review_path}: header must exactly be {REVIEW_HEADER}")
    if len(rows) != len(payload.records):
        _fail(
            f"{payload.review_path}: expected {len(payload.records)} review rows, got {len(rows)}",
        )
    expected_ids = [
        _required_string(record.get("id"), f"{payload.draft_path}[{index}].id")
        for index, record in enumerate(payload.records)
    ]
    expected_levels = [
        _level(record.get("level"), f"{payload.draft_path}[{index}].level").upper()
        for index, record in enumerate(payload.records)
    ]
    review_ids: list[str] = []
    for index, row in enumerate(rows, start=2):
        ident = _required_string(row.get("id"), f"{payload.review_path}:{index}.id")
        review_ids.append(ident)
        if row.get("상태") != "draft":
            _fail(f"{payload.review_path}:{index}: 상태 must be exactly 'draft' before Jin review")
        if not _required_string(row.get("field_notes"), f"{payload.review_path}:{index}.field_notes"):
            _fail(f"{payload.review_path}:{index}: field_notes must not be empty")
    if len(review_ids) != len(set(review_ids)):
        _fail(f"{payload.review_path}: duplicate review ID")
    if review_ids != expected_ids:
        _fail(f"{payload.review_path}: review IDs must exactly match draft IDs in order")
    for record_index, (record, row, expected_level) in enumerate(
        zip(payload.records, rows, expected_levels),
    ):
        row_number = record_index + 2
        if row["level"] != expected_level:
            _fail(
                f"{payload.review_path}:{row_number}: level must match its schema-complete draft record",
            )
        expected_copy = _project_review_copy(payload, record, index=record_index)
        for field, expected_value in expected_copy.items():
            actual_value = row.get(field)
            _required_string(actual_value, f"{payload.review_path}:{row_number}.{field}")
            if actual_value != expected_value:
                _fail(
                    f"{payload.review_path}:{row_number}.{field} must exactly match "
                    f"{payload.draft_path}[{record_index}]'s canonical draft projection",
                )


def _course_catalog(root: Path) -> tuple[dict[str, dict[str, Any]], set[str]]:
    manifest = _read_json(root / "assets" / "data" / "curriculum_manifest.json")
    if not isinstance(manifest, dict):
        _fail("curriculum_manifest.json: root must be an object")
    units_raw = manifest.get("courseUnits")
    concepts_raw = manifest.get("concepts")
    if not isinstance(units_raw, list) or not isinstance(concepts_raw, list):
        _fail("curriculum_manifest.json: courseUnits and concepts must be arrays")
    units: dict[str, dict[str, Any]] = {}
    for index, unit in enumerate(units_raw):
        if not isinstance(unit, dict):
            _fail(f"curriculum_manifest.json: courseUnits[{index}] must be an object")
        ident = _required_string(unit.get("id"), f"courseUnits[{index}].id")
        if ident in units:
            _fail(f"curriculum_manifest.json: duplicate course unit {ident!r}")
        units[ident] = unit
    concepts = {
        _required_string(concept.get("id"), f"concepts[{index}].id")
        for index, concept in enumerate(concepts_raw)
        if isinstance(concept, dict)
    }
    if len(concepts) != len(concepts_raw):
        _fail("curriculum_manifest.json: every concept must be an object with an id")
    return units, concepts


def _validate_course_binding(
    entry: dict[str, Any],
    *,
    label: str,
    level: str,
    units: dict[str, dict[str, Any]],
    concepts: set[str],
) -> tuple[str, list[str]]:
    unit_id = _required_string(entry.get("courseUnitId"), f"{label}.courseUnitId")
    unit = units.get(unit_id)
    if unit is None:
        _fail(f"{label}: unknown courseUnitId {unit_id!r}")
    if _level(unit.get("level"), f"course unit {unit_id}.level") != level:
        _fail(f"{label}: course unit {unit_id!r} does not match {level.upper()}")
    raw_concepts = entry.get("conceptIds")
    if not isinstance(raw_concepts, list) or not raw_concepts:
        _fail(f"{label}.conceptIds must be a nonempty array")
    required = unit.get("requiredConceptIds")
    if not isinstance(required, list):
        _fail(f"course unit {unit_id}: requiredConceptIds must be an array")
    binding_concepts: list[str] = []
    for concept in raw_concepts:
        concept_id = _required_string(concept, f"{label}.conceptIds item")
        if concept_id not in concepts:
            _fail(f"{label}: unknown concept {concept_id!r}")
        if concept_id not in required:
            _fail(f"{label}: concept {concept_id!r} is unrelated to {unit_id!r}")
        binding_concepts.append(concept_id)
    if len(binding_concepts) != len(set(binding_concepts)):
        _fail(f"{label}.conceptIds must not duplicate a concept")
    return unit_id, binding_concepts


def _expect_mapping_keys(
    entries: Any,
    *,
    label: str,
    expected: set[str],
    key_for_entry: Any,
) -> list[dict[str, Any]]:
    if not isinstance(entries, list):
        _fail(f"{label} must be an array")
    keyed: dict[str, dict[str, Any]] = {}
    for index, entry in enumerate(entries):
        if not isinstance(entry, dict):
            _fail(f"{label}[{index}] must be an object")
        key = key_for_entry(entry, index)
        if key in keyed:
            _fail(f"{label} has duplicate key {key!r}")
        keyed[key] = entry
    if set(keyed) != expected:
        missing = sorted(expected - set(keyed))
        unexpected = sorted(set(keyed) - expected)
        details: list[str] = []
        if missing:
            details.append("missing " + ", ".join(missing))
        if unexpected:
            details.append("unexpected " + ", ".join(unexpected))
        _fail(f"{label} does not cover the Batch 01 sources ({'; '.join(details)})")
    return [keyed[key] for key in sorted(keyed)]


def _validate_companions(
    root: Path,
    manifest: dict[str, Any],
    payloads: dict[str, ArtifactPayload],
) -> CurriculumAdditions:
    units, concepts = _course_catalog(root)
    vocab_records = payloads["vocab"].records
    grammar_records = payloads["grammar"].records
    smalltalk_records = payloads["smalltalk"].records
    cloze_records = payloads["cloze"].records
    satz_records = payloads["satz"].records

    records_by_pack: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for index, row in enumerate(vocab_records):
        pack_id = _required_string(row.get("pack_id"), f"vocab[{index}].pack_id")
        records_by_pack[pack_id].append(row)
    vocab_pack_ids = set(records_by_pack)

    def vocab_key(entry: dict[str, Any], index: int) -> str:
        return _required_string(entry.get("packId"), f"vocabPacks[{index}].packId")

    vocab_packs = _expect_mapping_keys(
        manifest.get("vocabPacks"),
        label="vocabPacks",
        expected=vocab_pack_ids,
        key_for_entry=vocab_key,
    )
    vocab_map: dict[str, str] = {}
    for entry in vocab_packs:
        pack_id = _required_string(entry.get("packId"), "vocabPacks.packId")
        rows = records_by_pack[pack_id]
        level = _level(entry.get("level"), f"vocabPacks[{pack_id}].level")
        row_levels = {_level(row.get("level"), f"{pack_id}.level") for row in rows}
        if row_levels != {level}:
            _fail(f"vocabPacks[{pack_id}]: declared level disagrees with its draft rows")
        orders = sorted(
            _positive_int_text(row.get("pack_order"), f"{pack_id}.pack_order")
            for row in rows
        )
        expected_range = [1, len(rows)]
        if entry.get("orderRange") != expected_range or orders != list(range(1, len(rows) + 1)):
            _fail(f"vocabPacks[{pack_id}]: orderRange and draft pack_order must be 1..{len(rows)}")
        actual_bosses = sorted(
            _positive_int_text(row.get("pack_order"), f"{pack_id}.pack_order")
            for row in rows
            if str(row.get("is_review_boss", "")).lower() == "true"
        )
        if entry.get("reviewBossOrders") != actual_bosses:
            _fail(f"vocabPacks[{pack_id}]: reviewBossOrders disagrees with draft rows")
        if type(entry.get("orderInLevel")) is not int or entry["orderInLevel"] < 1:
            _fail(f"vocabPacks[{pack_id}].orderInLevel must be a positive integer")
        labels = entry.get("displayLabel")
        if not isinstance(labels, dict):
            _fail(f"vocabPacks[{pack_id}].displayLabel must be an object")
        for language in ("ko", "de", "en"):
            _required_string(labels.get(language), f"vocabPacks[{pack_id}].displayLabel.{language}")
        _required_string(entry.get("motif"), f"vocabPacks[{pack_id}].motif")
        curriculum = entry.get("curriculum")
        if not isinstance(curriculum, dict):
            _fail(f"vocabPacks[{pack_id}].curriculum must be an object")
        unit_id, _ = _validate_course_binding(
            curriculum,
            label=f"vocabPacks[{pack_id}].curriculum",
            level=level,
            units=units,
            concepts=concepts,
        )
        base = _pack_base(pack_id)
        if base in vocab_map:
            _fail(f"vocabPacks: duplicate base pack id {base!r}")
        vocab_map[base] = unit_id

    grammar_by_id = {
        _required_string(record.get("id"), f"grammar[{index}].id"): record
        for index, record in enumerate(grammar_records)
    }

    def grammar_key(entry: dict[str, Any], index: int) -> str:
        return _required_string(entry.get("id"), f"grammarIntents[{index}].id")

    grammar_entries = _expect_mapping_keys(
        manifest.get("grammarIntents"),
        label="grammarIntents",
        expected=set(grammar_by_id),
        key_for_entry=grammar_key,
    )
    grammar_map: dict[str, dict[str, Any]] = {}
    for entry in grammar_entries:
        ident = _required_string(entry.get("id"), "grammarIntents.id")
        level = _level(entry.get("level"), f"grammarIntents[{ident}].level")
        if _level(grammar_by_id[ident].get("level"), f"grammar {ident}.level") != level:
            _fail(f"grammarIntents[{ident}]: level disagrees with the grammar draft")
        unit_id, concept_ids = _validate_course_binding(
            entry,
            label=f"grammarIntents[{ident}]",
            level=level,
            units=units,
            concepts=concepts,
        )
        grammar_map[ident] = {"courseUnitId": unit_id, "conceptIds": concept_ids}

    def smalltalk_source_key(record: dict[str, Any], index: int) -> str:
        level = _level(record.get("level"), f"smalltalk[{index}].level")
        category = _required_string(record.get("category"), f"smalltalk[{index}].category").lower()
        return f"{level}:{category}"

    smalltalk_source_keys = {
        smalltalk_source_key(record, index)
        for index, record in enumerate(smalltalk_records)
    }

    def smalltalk_mapping_key(entry: dict[str, Any], index: int) -> str:
        level = _level(entry.get("level"), f"smalltalkCategoryMappings[{index}].level")
        category = _required_string(entry.get("category"), f"smalltalkCategoryMappings[{index}].category").lower()
        return f"{level}:{category}"

    smalltalk_entries = _expect_mapping_keys(
        manifest.get("smalltalkCategoryMappings"),
        label="smalltalkCategoryMappings",
        expected=smalltalk_source_keys,
        key_for_entry=smalltalk_mapping_key,
    )
    smalltalk_map: dict[str, dict[str, Any]] = {}
    for entry in smalltalk_entries:
        key = smalltalk_mapping_key(entry, -1)
        level = key.split(":", 1)[0]
        unit_id, concept_ids = _validate_course_binding(
            entry,
            label=f"smalltalkCategoryMappings[{key}]",
            level=level,
            units=units,
            concepts=concepts,
        )
        smalltalk_map[key] = {"courseUnitId": unit_id, "conceptIds": concept_ids}

    def cloze_source_key(record: dict[str, Any], index: int) -> str:
        level = _level(record.get("level"), f"cloze[{index}].level")
        topic = _required_string(record.get("topic"), f"cloze[{index}].topic").lower()
        return f"{level}:{topic}"

    cloze_source_keys = {
        cloze_source_key(record, index) for index, record in enumerate(cloze_records)
    }

    def cloze_mapping_key(entry: dict[str, Any], index: int) -> str:
        level = _level(entry.get("level"), f"clozeTopicMappings[{index}].level")
        topic = _required_string(entry.get("topic"), f"clozeTopicMappings[{index}].topic").lower()
        return f"{level}:{topic}"

    cloze_entries = _expect_mapping_keys(
        manifest.get("clozeTopicMappings"),
        label="clozeTopicMappings",
        expected=cloze_source_keys,
        key_for_entry=cloze_mapping_key,
    )
    cloze_map: dict[str, str] = {}
    for entry in cloze_entries:
        key = cloze_mapping_key(entry, -1)
        level = key.split(":", 1)[0]
        unit_id, _ = _validate_course_binding(
            entry,
            label=f"clozeTopicMappings[{key}]",
            level=level,
            units=units,
            concepts=concepts,
        )
        cloze_map[key] = unit_id

    vocab_by_korean = {
        _required_string(record.get("korean"), f"vocab[{index}].korean"): record
        for index, record in enumerate(vocab_records)
    }
    satz_groups: Counter[tuple[str, str]] = Counter()
    for index, record in enumerate(satz_records):
        level = _level(record.get("level"), f"satz[{index}].level")
        vocab_ko = _required_string(record.get("vocabKo"), f"satz[{index}].vocabKo")
        vocab = vocab_by_korean.get(vocab_ko)
        if vocab is None:
            _fail(f"satz[{index}]: vocabKo {vocab_ko!r} must refer to a Batch 01 vocab row")
        if _level(vocab.get("level"), f"vocab {vocab_ko}.level") != level:
            _fail(f"satz[{index}]: vocabKo {vocab_ko!r} is not same-level")
        satz_groups[(level, _required_string(vocab.get("pack_id"), f"vocab {vocab_ko}.pack_id"))] += 1

    dependencies = manifest.get("satzDependencies")
    if not isinstance(dependencies, list):
        _fail("satzDependencies must be an array")
    declared_dependencies: dict[tuple[str, str], int] = {}
    for index, dependency in enumerate(dependencies):
        if not isinstance(dependency, dict):
            _fail(f"satzDependencies[{index}] must be an object")
        level = _level(dependency.get("level"), f"satzDependencies[{index}].level")
        pack_id = _required_string(dependency.get("vocabPackId"), f"satzDependencies[{index}].vocabPackId")
        count = dependency.get("count")
        if type(count) is not int or count < 1:
            _fail(f"satzDependencies[{index}].count must be a positive integer")
        key = (level, pack_id)
        if key in declared_dependencies:
            _fail(f"satzDependencies has duplicate {key!r}")
        declared_dependencies[key] = count
    if dict(satz_groups) != declared_dependencies:
        _fail(
            f"satzDependencies must exactly describe derived Satz rows; expected {dict(satz_groups)}",
        )

    return CurriculumAdditions(
        vocab_pack_unit_map=vocab_map,
        grammar_rule_map=grammar_map,
        smalltalk_category_unit_map=smalltalk_map,
        cloze_topic_unit_map=cloze_map,
        vocab_packs=tuple(vocab_packs),
    )


def _run_pack_preflight(
    root: Path,
    payload: ArtifactPayload,
    manifest_path: Path,
) -> tuple[str, ...]:
    """Run the shared planner against this very manifest, without writes."""

    try:
        plans = pack_planner.validate_plan(payload.draft_path, manifest_path, root=root)
    except pack_planner.PackAssignmentError as error:
        _fail(f"vocabulary pack preflight failed: {error}")
    planned_ids = tuple(sorted(pack_id for plan in plans for pack_id in plan.pack_ids))
    expected_ids = tuple(
        sorted(
            _required_string(entry.get("packId"), "vocabPacks.packId")
            for entry in _read_json(manifest_path).get("vocabPacks", [])
            if isinstance(entry, dict)
        ),
    )
    if planned_ids != expected_ids:
        _fail("vocabulary pack preflight did not return exactly the manifest packs")
    return planned_ids


def _add_new_mapping(target: dict[str, Any], key: str, value: Any, label: str) -> None:
    if key in target:
        _fail(f"overlay curriculum already has {label} entry for {key!r}")
    target[key] = value


def _write_overlay(
    root: Path,
    overlay_root: Path,
    payloads: dict[str, ArtifactPayload],
    additions: CurriculumAdditions,
) -> dict[str, int]:
    source_data = root / "assets" / "data"
    overlay_data = overlay_root / "assets" / "data"
    try:
        shutil.copytree(source_data, overlay_data)
        mirror_source = root / "functions" / "analyze_korean_text" / "grammar_patterns.json"
        mirror_target = overlay_root / "functions" / "analyze_korean_text" / "grammar_patterns.json"
        mirror_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(mirror_source, mirror_target)
    except OSError as error:
        _fail(f"cannot create disposable Batch 01 overlay: {error}")

    for spec in ARTIFACT_SPECS.values():
        payload = payloads[spec.kind]
        target = overlay_data / spec.target
        if spec.header is not None:
            header, current = _read_csv(target)
            if header != list(spec.header):
                _fail(f"{target}: current header disagrees with Batch 01 {spec.kind} schema")
            _write_csv(target, header, [*current, *payload.records])
            continue
        target_root = _read_json(target)
        if not isinstance(target_root, dict) or not isinstance(target_root.get(spec.collection or ""), list):
            _fail(f"{target}: current root must contain {spec.collection!r} array")
        target_root[spec.collection or ""] = [
            *target_root[spec.collection or ""],
            *[_copy_json(record) for record in payload.records],
        ]
        _write_json(target, target_root)

    curriculum_path = overlay_data / "curriculum_manifest.json"
    curriculum = _read_json(curriculum_path)
    if not isinstance(curriculum, dict):
        _fail(f"{curriculum_path}: root must be an object")
    for field in (
        "vocabPackUnitMap",
        "grammarRuleMap",
        "smalltalkCategoryUnitMap",
        "clozeTopicUnitMap",
    ):
        if not isinstance(curriculum.get(field), dict):
            _fail(f"{curriculum_path}: {field} must be an object")
    for key, value in additions.vocab_pack_unit_map.items():
        _add_new_mapping(curriculum["vocabPackUnitMap"], key, value, "vocabPackUnitMap")
    for key, value in additions.grammar_rule_map.items():
        _add_new_mapping(curriculum["grammarRuleMap"], key, value, "grammarRuleMap")
    for key, value in additions.smalltalk_category_unit_map.items():
        _add_new_mapping(
            curriculum["smalltalkCategoryUnitMap"],
            key,
            value,
            "smalltalkCategoryUnitMap",
        )
    for key, value in additions.cloze_topic_unit_map.items():
        _add_new_mapping(curriculum["clozeTopicUnitMap"], key, value, "clozeTopicUnitMap")
    _write_json(curriculum_path, curriculum)

    audit_path = overlay_data / "content_audit_manifest.json"
    audit = _read_json(audit_path)
    if not isinstance(audit, dict) or not isinstance(audit.get("sources"), list):
        _fail(f"{audit_path}: sources must be an array")
    counter = ContentValidator(overlay_root)
    counts = counter.inventory_counts()
    for source in audit["sources"]:
        if not isinstance(source, dict):
            _fail(f"{audit_path}: every source must be an object")
        kind = source.get("kind")
        if kind in counts:
            source["count"] = counts[kind]
    _write_json(audit_path, audit)
    return counts


def validate_batch_01(
    *,
    root: Path = ROOT,
    manifest_path: Path | None = None,
) -> BatchValidationResult:
    """Validate the complete Batch 01 draft without changing repository files."""

    root = root.resolve()
    if manifest_path is None:
        manifest_path = root / DEFAULT_MANIFEST
    elif not manifest_path.is_absolute():
        manifest_path = root / manifest_path
    manifest_path = manifest_path.resolve()
    try:
        manifest_path.relative_to(root)
    except ValueError:
        _fail("manifest path must stay under the repository root")

    manifest, entries = _parse_manifest(root, manifest_path)
    payloads: dict[str, ArtifactPayload] = {}
    for kind, spec in ARTIFACT_SPECS.items():
        payload = _load_artifact(root, spec, entries[kind])
        _validate_artifact_records(payload)
        _validate_review_ledger(payload)
        payloads[kind] = payload
    if sum(len(payload.records) for payload in payloads.values()) != 96:
        _fail("Batch 01 artifacts must total exactly 96 records")

    additions = _validate_companions(root, manifest, payloads)
    planned_pack_ids = _run_pack_preflight(root, payloads["vocab"], manifest_path)

    with tempfile.TemporaryDirectory(prefix="batch01-content-overlay-") as temporary:
        overlay_root = Path(temporary) / "repo"
        inventory_counts = _write_overlay(root, overlay_root, payloads, additions)
        issues = ContentValidator(overlay_root).validate()
    if issues:
        raise BatchValidationError(
            [f"overlay {issue.source}: {issue.message}" for issue in issues],
        )
    return BatchValidationResult(
        record_count=96,
        inventory_counts=inventory_counts,
        planned_pack_ids=planned_pack_ids,
    )


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--manifest",
        default=str(DEFAULT_MANIFEST),
        help="repository-relative Batch 01 manifest path",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    try:
        result = validate_batch_01(manifest_path=Path(args.manifest))
    except BatchValidationError as error:
        for message in error.messages:
            print(f"✗ {message}")
        return 1
    print(
        "✓ Batch 01 pre-review overlay passed: "
        f"{result.record_count} records; pack plans {', '.join(result.planned_pack_ids)}; "
        "no repository source files were written.",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
