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
import re
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


@dataclass(frozen=True)
class ArtifactContract:
    """The app-asset shape that a review-only artifact will eventually target."""

    target: str
    collection: str | None
    header: tuple[str, ...] | None


ARTIFACT_CONTRACTS: dict[str, ArtifactContract] = {
    "vocab": ArtifactContract(
        target="korean_vocab.csv",
        collection=None,
        header=tuple(VOCAB_HEADER),
    ),
    "grammar": ArtifactContract(
        target="grammar.csv",
        collection=None,
        header=tuple(GRAMMAR_HEADER),
    ),
    "smalltalk": ArtifactContract(
        target="smalltalk.json",
        collection="phrases",
        header=None,
    ),
    "cloze": ArtifactContract(
        target="cloze.json",
        collection="items",
        header=None,
    ),
    "satz": ArtifactContract(
        target="satz_sentences.json",
        collection="items",
        header=None,
    ),
}


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
    course_units: tuple[dict[str, Any], ...]
    concepts: tuple[dict[str, Any], ...]


@dataclass(frozen=True)
class BatchValidationResult:
    record_count: int
    inventory_counts: dict[str, int]
    planned_pack_ids: tuple[str, ...]


@dataclass(frozen=True)
class PredecessorReviewBatch:
    """Validated review-only facts reserved by an earlier pending batch.

    A predecessor is not part of ``assets/data`` yet, so the normal overlay
    cannot discover collisions with it by itself.  Keep the schema-complete
    records and their future curriculum additions available long enough to
    fail the later batch before either batch reaches an integration change.
    """

    manifest_path: Path
    batch: str
    payloads: dict[str, ArtifactPayload]
    additions: CurriculumAdditions


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
    if normalized not in {"a1", "a2", "b1", "b2", "c1", "c2"}:
        _fail(f"{label} must be an A1-C2 level")
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


def _parse_manifest(
    root: Path,
    manifest_path: Path,
    *,
    enforce_batch_01_contract: bool,
) -> tuple[dict[str, Any], dict[str, dict[str, Any]], dict[str, ArtifactSpec]]:
    """Read a review-only batch manifest without relying on its file name.

    Batch 01 remains deliberately immutable, but later batches use the same
    overlay graph with their own paths, counts, and reserved ID ranges.  All
    currently supported review batches contain the five authored asset kinds;
    specialised assets (scenarios, puzzles, grammar-pattern mirrors) keep
    their dedicated pipelines.
    """

    manifest = _read_json(manifest_path)
    if not isinstance(manifest, dict):
        _fail(f"{manifest_path}: root must be an object")
    if manifest.get("version") != 1:
        _fail(f"{manifest_path}: version must be 1")
    batch = _required_string(manifest.get("batch"), f"{manifest_path}: batch")
    if re.fullmatch(r"\d{2,}", batch) is None:
        _fail(f"{manifest_path}: batch must be a zero-padded numeric string")
    if enforce_batch_01_contract and batch != "01":
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
        if kind not in ARTIFACT_CONTRACTS:
            _fail(f"{manifest_path}: unsupported review-batch artifact kind {kind!r}")
        by_kind[kind] = artifact
    if set(by_kind) != set(ARTIFACT_SPECS):
        _fail(
            f"{manifest_path}: artifacts must be exactly {', '.join(sorted(ARTIFACT_CONTRACTS))}",
        )
    record_count = manifest.get("recordCount")
    if type(record_count) is not int or record_count < 1:
        _fail(f"{manifest_path}: recordCount must be a positive integer")
    if enforce_batch_01_contract and record_count != 96:
        _fail(f"{manifest_path}: recordCount must be 96")

    dynamic_specs: dict[str, ArtifactSpec] = {}
    for kind, artifact in by_kind.items():
        contract = ARTIFACT_CONTRACTS[kind]
        draft = Path(_required_string(artifact.get("draft"), f"{manifest_path}: {kind}.draft"))
        review = Path(_required_string(artifact.get("review"), f"{manifest_path}: {kind}.review"))
        count = artifact.get("count")
        if type(count) is not int or count < 1:
            _fail(f"{manifest_path}: {kind}.count must be a positive integer")
        raw_levels = artifact.get("levels")
        if not isinstance(raw_levels, dict) or not raw_levels:
            _fail(f"{manifest_path}: {kind}.levels must be a nonempty object")
        levels: dict[str, int] = {}
        for level, level_count in raw_levels.items():
            normalized = _level(level, f"{manifest_path}: {kind}.levels key")
            if type(level_count) is not int or level_count < 1:
                _fail(f"{manifest_path}: {kind}.levels[{level!r}] must be a positive integer")
            if normalized in levels:
                _fail(f"{manifest_path}: {kind}.levels duplicates {normalized.upper()}")
            levels[normalized] = level_count
        if sum(levels.values()) != count:
            _fail(f"{manifest_path}: {kind}.levels must total its count")
        dynamic_specs[kind] = ArtifactSpec(
            kind=kind,
            draft=draft,
            review=review,
            target=contract.target,
            collection=contract.collection,
            header=contract.header,
            count=count,
            levels=levels,
        )

    if enforce_batch_01_contract:
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
    return manifest, by_kind, dynamic_specs


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


def _validate_artifact_records(
    payload: ArtifactPayload,
    *,
    expected_ids: set[str] | None = None,
) -> None:
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
    if expected_ids is not None and set(ids) != expected_ids:
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


def _numbered_derivation_ids(
    entry: dict[str, Any],
    *,
    key: str,
    kind: str,
    level: str,
    label: str,
) -> list[str]:
    raw_range = entry.get(key)
    if (
        not isinstance(raw_range, list)
        or len(raw_range) != 2
        or any(type(value) is not int or value < 1 for value in raw_range)
        or raw_range[0] > raw_range[1]
    ):
        _fail(f"{label}.{key} must be an ascending two-number ID range")
    return [
        f"{kind}_{level}_{number:04d}"
        for number in range(raw_range[0], raw_range[1] + 1)
    ]


def _validate_sentence_derivations(
    manifest: dict[str, Any],
    payloads: dict[str, ArtifactPayload],
) -> None:
    """Keep authored game translations tied to their canonical vocab example.

    Cloze and Satzbau are deliberately derived from a vocabulary example in
    Batch 01/02.  A manifest-owned numeric correspondence avoids silently
    drifting punctuation, terminology, or an entire translation after a later
    edit.  The field is optional for batches that do not claim this one-to-one
    derivation, but current content batches require full coverage.
    """

    raw_sets = manifest.get("sentenceDerivationSets")
    if raw_sets is None:
        return
    if not isinstance(raw_sets, list) or not raw_sets:
        _fail("sentenceDerivationSets must be a nonempty array when present")
    by_kind = {
        kind: {
            _required_string(record.get("id"), f"{kind} draft id"): record
            for record in payloads[kind].records
        }
        for kind in ("vocab", "cloze", "satz")
    }
    used_ids: dict[str, set[str]] = {kind: set() for kind in by_kind}
    for index, entry in enumerate(raw_sets):
        label = f"sentenceDerivationSets[{index}]"
        if not isinstance(entry, dict):
            _fail(f"{label} must be an object")
        level = _level(entry.get("level"), f"{label}.level")
        vocab_ids = _numbered_derivation_ids(
            entry,
            key="vocabIdRange",
            kind="vocab",
            level=level,
            label=label,
        )
        cloze_ids = _numbered_derivation_ids(
            entry,
            key="clozeIdRange",
            kind="cloze",
            level=level,
            label=label,
        )
        satz_ids = _numbered_derivation_ids(
            entry,
            key="satzIdRange",
            kind="satz",
            level=level,
            label=label,
        )
        if len(vocab_ids) != len(cloze_ids) or len(vocab_ids) != len(satz_ids):
            _fail(f"{label}: vocab/cloze/satz ID ranges must have equal lengths")
        for vocab_id, cloze_id, satz_id in zip(vocab_ids, cloze_ids, satz_ids):
            try:
                vocab = by_kind["vocab"][vocab_id]
                cloze = by_kind["cloze"][cloze_id]
                satz = by_kind["satz"][satz_id]
            except KeyError as error:
                _fail(f"{label}: missing declared derivation source {error.args[0]!r}")
            for kind, ident, record in (
                ("vocab", vocab_id, vocab),
                ("cloze", cloze_id, cloze),
                ("satz", satz_id, satz),
            ):
                if _level(record.get("level"), f"{ident}.level") != level:
                    _fail(f"{label}: {ident} does not match {level.upper()}")
                if ident in used_ids[kind]:
                    _fail(f"{label}: {ident} appears in more than one derivation set")
                used_ids[kind].add(ident)
            expected = (
                ("Korean", vocab.get("example_korean"), cloze.get("fullKo"), satz.get("targetKo")),
                ("German", vocab.get("example_german"), cloze.get("de"), satz.get("promptDe")),
                ("English", vocab.get("example_english"), cloze.get("en"), satz.get("promptEn")),
            )
            for language, source, cloze_value, satz_value in expected:
                if source != cloze_value or source != satz_value:
                    _fail(
                        f"{label}: {vocab_id}/{cloze_id}/{satz_id} {language} "
                        "must exactly share the canonical vocabulary example",
                    )
    if manifest.get("requiresCompleteSentenceDerivations") is True:
        for kind, records in by_kind.items():
            if set(records) != used_ids[kind]:
                missing = sorted(set(records) - used_ids[kind])
                _fail(
                    "sentenceDerivationSets must cover every "
                    f"{kind} record (missing {', '.join(missing)})",
                )


def _course_catalog(
    root: Path,
    batch_manifest: dict[str, Any],
) -> tuple[
    dict[str, dict[str, Any]],
    set[str],
    tuple[dict[str, Any], ...],
    tuple[dict[str, Any], ...],
]:
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
    concept_levels: dict[str, str] = {}
    for index, concept in enumerate(concepts_raw):
        if not isinstance(concept, dict):
            continue
        concept_id = _required_string(concept.get("id"), f"concepts[{index}].id")
        if concept_id in concept_levels:
            _fail(f"curriculum_manifest.json: duplicate concept {concept_id!r}")
        concept_levels[concept_id] = _level(
            concept.get("level"),
            f"concepts[{index}].level",
        )
    if len(concept_levels) != len(concepts_raw):
        _fail("curriculum_manifest.json: every concept must be an object with an id")

    raw_extensions = batch_manifest.get("curriculumExtensions")
    if raw_extensions is None:
        return units, set(concept_levels), (), ()
    if not isinstance(raw_extensions, dict):
        _fail("curriculumExtensions must be an object")
    extension_concepts = raw_extensions.get("concepts")
    extension_units = raw_extensions.get("courseUnits")
    if not isinstance(extension_concepts, list) or not isinstance(extension_units, list):
        _fail("curriculumExtensions.concepts and courseUnits must be arrays")
    if any(not isinstance(entry, dict) for entry in extension_concepts):
        _fail("curriculumExtensions.concepts must contain only objects")
    if any(not isinstance(entry, dict) for entry in extension_units):
        _fail("curriculumExtensions.courseUnits must contain only objects")

    copied_concepts: list[dict[str, Any]] = []
    for index, concept in enumerate(extension_concepts):
        concept_id = _required_string(
            concept.get("id"),
            f"curriculumExtensions.concepts[{index}].id",
        )
        if concept_id in concept_levels:
            _fail(f"curriculumExtensions duplicates concept {concept_id!r}")
        level = _level(
            concept.get("level"),
            f"curriculumExtensions.concepts[{index}].level",
        )
        concept_levels[concept_id] = level
        copied_concepts.append(_copy_json(concept))

    copied_units: list[dict[str, Any]] = []
    for index, unit in enumerate(extension_units):
        unit_id = _required_string(
            unit.get("id"),
            f"curriculumExtensions.courseUnits[{index}].id",
        )
        if unit_id in units:
            _fail(f"curriculumExtensions duplicates course unit {unit_id!r}")
        level = _level(
            unit.get("level"),
            f"curriculumExtensions.courseUnits[{index}].level",
        )
        required = unit.get("requiredConceptIds")
        if (
            not isinstance(required, list)
            or not required
            or any(not isinstance(value, str) or not value.strip() for value in required)
        ):
            _fail(
                f"curriculumExtensions.courseUnits[{index}].requiredConceptIds "
                "must be a nonempty string array",
            )
        for concept_id in required:
            if concept_id not in concept_levels:
                _fail(
                    f"curriculumExtensions course unit {unit_id!r} references "
                    f"unknown concept {concept_id!r}",
                )
            if concept_levels[concept_id] != level:
                _fail(
                    f"curriculumExtensions course unit {unit_id!r} and concept "
                    f"{concept_id!r} have different levels",
                )
        units[unit_id] = unit
        copied_units.append(_copy_json(unit))
    return (
        units,
        set(concept_levels),
        tuple(copied_units),
        tuple(copied_concepts),
    )


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
    units, concepts, extension_units, extension_concepts = _course_catalog(
        root,
        manifest,
    )
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

    smalltalk_by_id = {
        _required_string(record.get("id"), f"smalltalk[{index}].id"): record
        for index, record in enumerate(smalltalk_records)
    }

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

    # Newly declared course units must end in one real, same-level assessment
    # from this reviewed batch. This prevents an advanced unit from appearing
    # in the path while its completion trigger still points at legacy content.
    for index, unit in enumerate(extension_units):
        unit_id = _required_string(
            unit.get("id"),
            f"curriculumExtensions.courseUnits[{index}].id",
        )
        unit_level = _level(
            unit.get("level"),
            f"curriculumExtensions.courseUnits[{index}].level",
        )
        raw_required = unit.get("requiredConceptIds")
        required = list(raw_required) if isinstance(raw_required, list) else []
        checkpoints = unit.get("checkpointContentIds")
        if (
            not isinstance(checkpoints, list)
            or len(checkpoints) != 1
            or not isinstance(checkpoints[0], str)
            or checkpoints[0].count(":") != 1
        ):
            _fail(
                f"curriculumExtensions course unit {unit_id!r} must declare "
                "exactly one kind:id checkpoint",
            )
        kind, source_id = checkpoints[0].split(":", 1)
        if kind == "grammar":
            source = grammar_by_id.get(source_id)
            rule = grammar_map.get(source_id)
            if source is None or rule is None:
                _fail(f"course unit {unit_id!r} checkpoint references unknown grammar {source_id!r}")
            source_level = _level(source.get("level"), f"grammar {source_id}.level")
        elif kind == "smalltalk":
            source = smalltalk_by_id.get(source_id)
            if source is None:
                _fail(f"course unit {unit_id!r} checkpoint references unknown smalltalk {source_id!r}")
            semantic_key = smalltalk_source_key(source, -1)
            rule = smalltalk_map.get(semantic_key)
            source_level = _level(source.get("level"), f"smalltalk {source_id}.level")
        else:
            _fail(
                f"course unit {unit_id!r} checkpoint kind must be grammar or smalltalk, got {kind!r}",
            )
        if source_level != unit_level:
            _fail(f"course unit {unit_id!r} checkpoint must stay in {unit_level.upper()}")
        if rule is None or rule.get("courseUnitId") != unit_id:
            _fail(f"course unit {unit_id!r} checkpoint is not mapped back to that unit")
        if set(rule.get("conceptIds") or []) != set(required):
            _fail(f"course unit {unit_id!r} checkpoint must assess its exact required concepts")

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
        course_units=extension_units,
        concepts=extension_concepts,
    )


def _run_pack_preflight(
    root: Path,
    payload: ArtifactPayload,
    manifest_path: Path,
    *,
    predecessor_manifest_paths: Iterable[Path] = (),
) -> tuple[str, ...]:
    """Run the shared planner against this very manifest, without writes."""

    try:
        plans = pack_planner.validate_plan(
            payload.draft_path,
            manifest_path,
            root=root,
            reserved_metadata_paths=predecessor_manifest_paths,
        )
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
        if target[key] != value:
            _fail(
                f"overlay curriculum has a conflicting {label} entry for {key!r}",
            )
        return
    target[key] = value


def _write_overlay(
    root: Path,
    overlay_root: Path,
    specs: dict[str, ArtifactSpec],
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

    for spec in specs.values():
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
    for field, records in (
        ("concepts", additions.concepts),
        ("courseUnits", additions.course_units),
    ):
        current_records = curriculum.get(field)
        if not isinstance(current_records, list):
            _fail(f"{curriculum_path}: {field} must be an array")
        existing_ids = {
            record.get("id")
            for record in current_records
            if isinstance(record, dict)
        }
        for record in records:
            ident = record.get("id")
            if ident in existing_ids:
                _fail(f"overlay curriculum duplicates {field} id {ident!r}")
            current_records.append(_copy_json(record))
            existing_ids.add(ident)
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


def _resolve_predecessor_manifests(root: Path, manifest: dict[str, Any]) -> tuple[Path, ...]:
    """Resolve declared earlier review batches without allowing path escape."""

    raw_paths = manifest.get("predecessorManifests", [])
    if raw_paths is None:
        raw_paths = []
    if not isinstance(raw_paths, list) or any(
        not isinstance(path, str) or not path.strip() for path in raw_paths
    ):
        _fail("predecessorManifests must be an array of repository-relative paths")
    resolved: list[Path] = []
    for index, raw_path in enumerate(raw_paths):
        path = _resolve_under_root(root, raw_path, f"predecessorManifests[{index}]")
        if not path.is_file():
            _fail(f"predecessorManifests[{index}]: file does not exist: {raw_path}")
        if path in resolved:
            _fail(f"predecessorManifests has duplicate path {raw_path!r}")
        resolved.append(path)
    return tuple(resolved)


def _load_predecessor_review_batches(
    root: Path,
    *,
    current_manifest_path: Path,
    current_batch: str,
    manifest_paths: Iterable[Path],
) -> tuple[PredecessorReviewBatch, ...]:
    """Load predecessor drafts as reservations, without creating an overlay.

    ``plan_pack_assignments.py`` deliberately reads only predecessor pack
    metadata because it needs to reserve future UI order.  The review-batch
    validator has a wider responsibility: no later unmerged batch may reuse
    an earlier draft record, vocabulary headword, or incompatible curriculum
    mapping.  Read the same schema-complete draft/review pair here so those
    reservations are checked before the current batch can be called valid.
    """

    current_number = int(current_batch)
    predecessors: list[PredecessorReviewBatch] = []
    for manifest_path in manifest_paths:
        if manifest_path == current_manifest_path:
            _fail("predecessorManifests must not contain the current manifest")
        manifest, entries, specs = _parse_manifest(
            root,
            manifest_path,
            enforce_batch_01_contract=False,
        )
        predecessor_batch = _required_string(
            manifest.get("batch"),
            f"{manifest_path}: batch",
        )
        if int(predecessor_batch) >= current_number:
            _fail(
                f"{manifest_path}: predecessor batch {predecessor_batch} must be earlier "
                f"than current batch {current_batch}",
            )

        payloads: dict[str, ArtifactPayload] = {}
        for kind, spec in specs.items():
            payload = _load_artifact(root, spec, entries[kind])
            _validate_artifact_records(payload)
            _validate_review_ledger(payload)
            payloads[kind] = payload
        actual_count = sum(len(payload.records) for payload in payloads.values())
        if actual_count != manifest["recordCount"]:
            _fail(
                f"{manifest_path}: recordCount must equal the artifact total "
                f"({actual_count})",
            )
        _validate_sentence_derivations(manifest, payloads)
        predecessors.append(
            PredecessorReviewBatch(
                manifest_path=manifest_path,
                batch=predecessor_batch,
                payloads=payloads,
                additions=_validate_companions(root, manifest, payloads),
            ),
        )
    return tuple(predecessors)


def _curriculum_mapping_groups(
    additions: CurriculumAdditions,
) -> dict[str, dict[str, Any]]:
    """Expose the four future curriculum maps under their asset field names."""

    return {
        "vocabPackUnitMap": additions.vocab_pack_unit_map,
        "grammarRuleMap": additions.grammar_rule_map,
        "smalltalkCategoryUnitMap": additions.smalltalk_category_unit_map,
        "clozeTopicUnitMap": additions.cloze_topic_unit_map,
    }


def _validate_predecessor_reservations(
    *,
    current_manifest_path: Path,
    current_payloads: dict[str, ArtifactPayload],
    current_additions: CurriculumAdditions,
    predecessors: Iterable[PredecessorReviewBatch],
) -> None:
    """Reject later drafts that collide with still-unmerged predecessors.

    Identical companion entries intentionally remain legal: two batches can
    author phrases in the same category if that category is owned by the same
    curriculum unit.  A different value for an already-reserved key would
    make the eventual multi-file integration order-dependent, so fail closed.
    """

    reserved_ids: dict[str, str] = {}
    reserved_korean: dict[str, str] = {}
    reserved_mappings: dict[str, dict[str, tuple[Any, str]]] = {
        name: {} for name in _curriculum_mapping_groups(current_additions)
    }

    for predecessor in predecessors:
        source_label = f"Batch {predecessor.batch} ({predecessor.manifest_path})"
        for payload in predecessor.payloads.values():
            for index, record in enumerate(payload.records):
                ident = _required_string(
                    record.get("id"),
                    f"{payload.draft_path}[{index}].id",
                )
                existing_source = reserved_ids.get(ident)
                if existing_source is not None:
                    _fail(
                        f"predecessor manifests reuse draft ID {ident!r}: "
                        f"{existing_source} and {source_label}",
                    )
                reserved_ids[ident] = source_label

        for index, record in enumerate(predecessor.payloads["vocab"].records):
            korean = _required_string(
                record.get("korean"),
                f"{predecessor.payloads['vocab'].draft_path}[{index}].korean",
            )
            existing_source = reserved_korean.get(korean)
            if existing_source is not None:
                _fail(
                    f"predecessor manifests reuse vocabulary Korean headword {korean!r}: "
                    f"{existing_source} and {source_label}",
                )
            reserved_korean[korean] = source_label

        for map_name, entries in _curriculum_mapping_groups(predecessor.additions).items():
            reserved_group = reserved_mappings[map_name]
            for key, value in entries.items():
                existing = reserved_group.get(key)
                if existing is not None and existing[0] != value:
                    _fail(
                        f"predecessor manifests have conflicting {map_name} entry "
                        f"for {key!r}: {existing[1]} and {source_label}",
                    )
                reserved_group[key] = (value, source_label)

    for payload in current_payloads.values():
        for index, record in enumerate(payload.records):
            ident = _required_string(record.get("id"), f"{payload.draft_path}[{index}].id")
            existing_source = reserved_ids.get(ident)
            if existing_source is not None:
                _fail(
                    f"{current_manifest_path}: draft ID {ident!r} reuses predecessor "
                    f"draft ID from {existing_source}",
                )

    for index, record in enumerate(current_payloads["vocab"].records):
        korean = _required_string(
            record.get("korean"),
            f"{current_payloads['vocab'].draft_path}[{index}].korean",
        )
        existing_source = reserved_korean.get(korean)
        if existing_source is not None:
            _fail(
                f"{current_manifest_path}: vocabulary Korean headword {korean!r} "
                f"reuses predecessor draft headword from {existing_source}",
            )

    for map_name, entries in _curriculum_mapping_groups(current_additions).items():
        for key, value in entries.items():
            existing = reserved_mappings[map_name].get(key)
            if existing is not None and existing[0] != value:
                _fail(
                    f"{current_manifest_path}: conflicting predecessor {map_name} "
                    f"entry for {key!r} from {existing[1]}",
                )


def validate_review_batch(
    *,
    root: Path = ROOT,
    manifest_path: Path,
    enforce_batch_01_contract: bool = False,
) -> BatchValidationResult:
    """Validate a complete review-only B1/B2 batch without writing sources.

    It supports future batches with their own file names, record counts, ID
    ranges, and pending predecessor pack reservations.  The caller opts into
    the immutable Batch 01 contract only for its historic fixed handoff.
    """

    root = root.resolve()
    if not manifest_path.is_absolute():
        manifest_path = root / manifest_path
    manifest_path = manifest_path.resolve()
    try:
        manifest_path.relative_to(root)
    except ValueError:
        _fail("manifest path must stay under the repository root")

    manifest, entries, specs = _parse_manifest(
        root,
        manifest_path,
        enforce_batch_01_contract=enforce_batch_01_contract,
    )
    payloads: dict[str, ArtifactPayload] = {}
    for kind, spec in specs.items():
        payload = _load_artifact(root, spec, entries[kind])
        _validate_artifact_records(
            payload,
            expected_ids=EXPECTED_IDS[kind] if enforce_batch_01_contract else None,
        )
        _validate_review_ledger(payload)
        payloads[kind] = payload
    actual_count = sum(len(payload.records) for payload in payloads.values())
    if actual_count != manifest["recordCount"]:
        _fail(
            f"{manifest_path}: recordCount must equal the artifact total "
            f"({actual_count})",
        )

    _validate_sentence_derivations(manifest, payloads)
    additions = _validate_companions(root, manifest, payloads)
    predecessor_manifest_paths = _resolve_predecessor_manifests(root, manifest)
    predecessors = _load_predecessor_review_batches(
        root,
        current_manifest_path=manifest_path,
        current_batch=manifest["batch"],
        manifest_paths=predecessor_manifest_paths,
    )
    _validate_predecessor_reservations(
        current_manifest_path=manifest_path,
        current_payloads=payloads,
        current_additions=additions,
        predecessors=predecessors,
    )
    planned_pack_ids = _run_pack_preflight(
        root,
        payloads["vocab"],
        manifest_path,
        predecessor_manifest_paths=predecessor_manifest_paths,
    )

    with tempfile.TemporaryDirectory(prefix="review-batch-content-overlay-") as temporary:
        overlay_root = Path(temporary) / "repo"
        inventory_counts = _write_overlay(root, overlay_root, specs, payloads, additions)
        issues = ContentValidator(overlay_root).validate()
    if issues:
        raise BatchValidationError(
            [f"overlay {issue.source}: {issue.message}" for issue in issues],
        )
    return BatchValidationResult(
        record_count=actual_count,
        inventory_counts=inventory_counts,
        planned_pack_ids=planned_pack_ids,
    )


def validate_batch_01(
    *,
    root: Path = ROOT,
    manifest_path: Path | None = None,
) -> BatchValidationResult:
    """Validate the historic immutable Batch 01 handoff without writes."""

    return validate_review_batch(
        root=root,
        manifest_path=manifest_path or DEFAULT_MANIFEST,
        enforce_batch_01_contract=True,
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
