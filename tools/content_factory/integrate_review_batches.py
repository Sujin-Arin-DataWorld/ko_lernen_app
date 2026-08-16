#!/usr/bin/env python3
"""Atomically promote approved B1/B2 review batches into bundled app content.

This is the companion transaction intentionally kept out of
``apply_review.py``.  A learner-facing batch changes more than one target:
the five data assets, curriculum ownership maps, pack labels/order, card
motifs, and the audit inventory must move together.  It stages every output,
runs the complete validator, then either replaces all source files or restores
their original bytes on any error.

The ``--approve-all`` switch is deliberately separate from ``--apply``.  It
is only for an explicit Jin decision covering every row in every listed review
ledger; it records that decision in the same transaction as the asset merge.

Usage:
    python3 tools/content_factory/integrate_review_batches.py
    python3 tools/content_factory/integrate_review_batches.py --apply --approve-all \
      --restore-b2-recovery
"""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
from io import StringIO
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
from typing import Any, Iterable

from validate_content import ContentValidator, GRAMMAR_HEADER, VOCAB_HEADER
from validate_batch_01 import (
    BatchValidationError,
    REVIEW_HEADER,
    validate_batch_01,
    validate_review_batch,
)


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "assets" / "data"
DEFAULT_MANIFESTS = (
    Path("tools/content_factory/drafts/batch_01_manifest.json"),
    Path("tools/content_factory/drafts/batch_02_manifest.json"),
    Path("tools/content_factory/drafts/batch_03_manifest.json"),
)

# The following content was authored in the app repository and is an ancestor
# of main.  A later bulk asset rewrite dropped its rows while retaining the
# three Dart labels/order entries.  The recovery is intentionally limited to
# those exact original rows; it never imports external material or network data.
RECOVERY_REVISION = "5de45d6828542c43c0420779c0d0857c8193df1e"
RECOVERY_PACK_IDS = frozenset(
    ("b2_life_values", "b2_literature_emotion", "b2_language_change"),
)
RECOVERY_GRAMMAR_IDS = frozenset(
    (
        "grammar_b2_pretense_contrast",
        "grammar_b2_addition_even",
        "grammar_b2_indirect_speech",
        "grammar_b2_futility",
        "grammar_b2_unexpected_cause",
        "grammar_b2_worth_doing",
        "grammar_b2_practically",
    ),
)
RECOVERY_KKEUNMARI_WORDS = frozenset(("편견", "좌우명", "문학성", "대표작", "글귀", "신조어"))

RECOVERY_PACKS = {
    "b2_life_values": {
        "de": "Lebensphilosophie",
        "en": "Life Philosophy",
        "order": 18,
        "unit": "b2_02_professional_opinion",
        "concepts": ["concept_b2_opinion"],
        "motif": "taegeuk",
    },
    "b2_literature_emotion": {
        "de": "Literatur & Gefühle",
        "en": "Literature & Emotions",
        "order": 19,
        "unit": "b2_06_advanced_capstone",
        "concepts": ["concept_b2_advanced"],
        "motif": "chrysanthemum",
    },
    "b2_language_change": {
        "de": "Sprache & Wandel",
        "en": "Language & Change",
        "order": 20,
        "unit": "b2_02_professional_opinion",
        "concepts": ["concept_b2_opinion"],
        "motif": "chilbo",
    },
}
RECOVERY_GRAMMAR_MAP = {
    "grammar_b2_pretense_contrast": ("b2_02_professional_opinion", ["concept_b2_opinion"]),
    "grammar_b2_addition_even": ("b2_06_advanced_capstone", ["concept_b2_advanced"]),
    "grammar_b2_indirect_speech": ("b2_02_professional_opinion", ["concept_b2_opinion"]),
    "grammar_b2_futility": ("b2_06_advanced_capstone", ["concept_b2_advanced"]),
    "grammar_b2_unexpected_cause": ("b2_06_advanced_capstone", ["concept_b2_advanced"]),
    "grammar_b2_worth_doing": ("b2_06_advanced_capstone", ["concept_b2_advanced"]),
    "grammar_b2_practically": ("b2_06_advanced_capstone", ["concept_b2_advanced"]),
}

TARGETS = {
    "vocab": ("korean_vocab.csv", None, VOCAB_HEADER),
    "grammar": ("grammar.csv", None, GRAMMAR_HEADER),
    "smalltalk": ("smalltalk.json", "phrases", None),
    "cloze": ("cloze.json", "items", None),
    "satz": ("satz_sentences.json", "items", None),
}


class IntegrationError(ValueError):
    """A safe, actionable content-integration error."""


@dataclass(frozen=True)
class BatchPayload:
    manifest_path: Path
    manifest: dict[str, Any]
    artifacts: dict[str, tuple[Path, Path, list[dict[str, Any]]]]


def _under_root(root: Path, raw: str) -> Path:
    path = (root / raw).resolve()
    try:
        path.relative_to(root.resolve())
    except ValueError as error:
        raise IntegrationError(f"path escapes repository root: {raw}") from error
    return path


def _read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise IntegrationError(f"cannot read {path}: {error}") from error
    if not isinstance(value, dict):
        raise IntegrationError(f"{path}: root must be an object")
    return value


def _read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    try:
        with path.open(encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            header = list(reader.fieldnames or [])
            rows = list(reader)
    except (OSError, csv.Error) as error:
        raise IntegrationError(f"cannot read {path}: {error}") from error
    if not header or len(header) != len(set(header)) or any(not field for field in header):
        raise IntegrationError(f"{path}: CSV needs unique nonempty columns")
    for row_number, row in enumerate(rows, start=2):
        if None in row or any(row.get(field) is None for field in header):
            raise IntegrationError(f"{path}:{row_number}: malformed CSV row")
    return header, rows


def _csv_text(header: Iterable[str], rows: Iterable[dict[str, Any]]) -> str:
    output = StringIO(newline="")
    writer = csv.DictWriter(
        output,
        fieldnames=list(header),
        extrasaction="raise",
        lineterminator="\n",
    )
    writer.writeheader()
    writer.writerows(rows)
    return output.getvalue()


def _json_text(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2) + "\n"


def _read_review(path: Path, expected_ids: set[str]) -> list[dict[str, str]]:
    header, rows = _read_csv(path)
    if header != REVIEW_HEADER:
        raise IntegrationError(f"{path}: review header must exactly match the common ledger schema")
    seen = [row["id"].strip() for row in rows]
    if not all(seen) or len(seen) != len(set(seen)):
        raise IntegrationError(f"{path}: review IDs must be nonempty and unique")
    if set(seen) != expected_ids:
        raise IntegrationError(f"{path}: review IDs do not exactly match the schema-complete draft")
    return rows


def _load_batch(root: Path, relative_manifest: Path) -> BatchPayload:
    manifest_path = _under_root(root, str(relative_manifest))
    manifest = _read_json(manifest_path)
    if manifest.get("status") != "review_only_draft":
        raise IntegrationError(f"{relative_manifest}: expected review_only_draft before promotion")
    artifacts_raw = manifest.get("artifacts")
    if not isinstance(artifacts_raw, list):
        raise IntegrationError(f"{relative_manifest}: artifacts must be an array")
    entries = {entry.get("kind"): entry for entry in artifacts_raw if isinstance(entry, dict)}
    if set(entries) != set(TARGETS):
        raise IntegrationError(f"{relative_manifest}: must contain exactly the five supported artifact kinds")

    artifacts: dict[str, tuple[Path, Path, list[dict[str, Any]]]] = {}
    for kind, (target_name, collection, required_header) in TARGETS.items():
        entry = entries[kind]
        draft_raw = entry.get("draft")
        review_raw = entry.get("review")
        if not isinstance(draft_raw, str) or not isinstance(review_raw, str):
            raise IntegrationError(f"{relative_manifest}: {kind} needs draft and review paths")
        draft = _under_root(root, draft_raw)
        review = _under_root(root, review_raw)
        if required_header is not None:
            header, records = _read_csv(draft)
            if header != required_header:
                raise IntegrationError(f"{draft}: header disagrees with the live {kind} schema")
        else:
            source = _read_json(draft)
            records_raw = source.get(collection or "")
            if not isinstance(records_raw, list) or any(not isinstance(row, dict) for row in records_raw):
                raise IntegrationError(f"{draft}: {collection} must be an array of objects")
            records = [dict(row) for row in records_raw]
        count = entry.get("count")
        if count != len(records):
            raise IntegrationError(f"{draft}: manifest count does not match its records")
        ids = {str(row.get("id") or "").strip() for row in records}
        if len(ids) != len(records) or not all(ids):
            raise IntegrationError(f"{draft}: records need unique nonempty IDs")
        _read_review(review, ids)
        artifacts[kind] = (draft, review, records)
    return BatchPayload(manifest_path=manifest_path, manifest=manifest, artifacts=artifacts)


def _require_promotable_reviews(
    batches: Iterable[BatchPayload],
    *,
    approve_all: bool,
) -> None:
    for batch in batches:
        for _, review, _ in batch.artifacts.values():
            _, rows = _read_csv(review)
            statuses = {(row.get("상태") or "").strip().casefold() for row in rows}
            if approve_all:
                if statuses != {"draft"}:
                    raise IntegrationError(f"{review}: --approve-all requires every row to still be draft")
            elif statuses != {"approved"}:
                raise IntegrationError(f"{review}: every row must be approved before --apply")


def _preflight_review_batches(root: Path, manifests: Iterable[Path]) -> None:
    for manifest in manifests:
        try:
            if manifest.name == "batch_01_manifest.json":
                validate_batch_01(root=root, manifest_path=manifest)
            else:
                validate_review_batch(root=root, manifest_path=manifest)
        except BatchValidationError as error:
            joined = "\n".join(error.messages)
            raise IntegrationError(f"{manifest}: review preflight failed:\n{joined}") from error


def _base_pack_id(pack_id: str) -> str:
    parts = pack_id.split("_")
    return "_".join(parts[:-1]) if parts and parts[-1].isdigit() else pack_id


def _add_mapping(target: dict[str, Any], key: str, value: Any, label: str) -> None:
    if key in target and target[key] != value:
        raise IntegrationError(f"conflicting {label} mapping for {key!r}")
    target[key] = value


def _merge_curriculum_extensions(
    curriculum: dict[str, Any],
    batches: Iterable[BatchPayload],
) -> None:
    """Append manifest-owned concepts and course units before mapping content.

    Earlier review batches only targeted already-shipped A1-B2 units.  C1/C2
    is the first track that must create curriculum nodes in the same atomic
    transaction as its content.  Keep this fail-closed so a partial concept or
    unit can never be written ahead of its reviewed records.
    """

    concepts = curriculum.get("concepts")
    units = curriculum.get("courseUnits")
    if not isinstance(concepts, list) or not isinstance(units, list):
        raise IntegrationError(
            "curriculum_manifest.json: concepts and courseUnits must be arrays",
        )
    if any(not isinstance(item, dict) for item in concepts):
        raise IntegrationError("curriculum_manifest.json: concepts must contain objects")
    if any(not isinstance(item, dict) for item in units):
        raise IntegrationError("curriculum_manifest.json: courseUnits must contain objects")

    concept_by_id = {str(item.get("id") or "").strip(): item for item in concepts}
    unit_by_id = {str(item.get("id") or "").strip(): item for item in units}
    if "" in concept_by_id or len(concept_by_id) != len(concepts):
        raise IntegrationError("curriculum_manifest.json: concept IDs must be unique and nonempty")
    if "" in unit_by_id or len(unit_by_id) != len(units):
        raise IntegrationError("curriculum_manifest.json: course-unit IDs must be unique and nonempty")

    pending_concepts: list[dict[str, Any]] = []
    pending_units: list[dict[str, Any]] = []
    for batch in batches:
        raw = batch.manifest.get("curriculumExtensions")
        if raw is None:
            continue
        if not isinstance(raw, dict):
            raise IntegrationError(
                f"{batch.manifest_path}: curriculumExtensions must be an object",
            )
        raw_concepts = raw.get("concepts")
        raw_units = raw.get("courseUnits")
        if not isinstance(raw_concepts, list) or not isinstance(raw_units, list):
            raise IntegrationError(
                f"{batch.manifest_path}: curriculumExtensions needs concepts and courseUnits arrays",
            )
        for label, incoming, live, pending in (
            ("concept", raw_concepts, concept_by_id, pending_concepts),
            ("course unit", raw_units, unit_by_id, pending_units),
        ):
            for item in incoming:
                if not isinstance(item, dict):
                    raise IntegrationError(
                        f"{batch.manifest_path}: curriculum extension {label} must be an object",
                    )
                ident = str(item.get("id") or "").strip()
                if not ident:
                    raise IntegrationError(
                        f"{batch.manifest_path}: curriculum extension {label} needs an id",
                    )
                existing = live.get(ident)
                if existing is not None and existing != item:
                    raise IntegrationError(
                        f"{batch.manifest_path}: conflicting curriculum {label} {ident!r}",
                    )
                if existing is None:
                    copied = json.loads(json.dumps(item, ensure_ascii=False))
                    live[ident] = copied
                    pending.append(copied)

    concepts.extend(pending_concepts)
    units.extend(pending_units)


def _merge_batch_mappings(curriculum: dict[str, Any], batches: Iterable[BatchPayload]) -> dict[str, dict[str, Any]]:
    fields = ("vocabPackUnitMap", "grammarRuleMap", "smalltalkCategoryUnitMap", "clozeTopicUnitMap")
    for field in fields:
        if not isinstance(curriculum.get(field), dict):
            raise IntegrationError(f"curriculum_manifest.json: {field} must be an object")

    pack_entries: dict[str, dict[str, Any]] = {}
    for batch in batches:
        for item in batch.manifest.get("vocabPacks", []):
            if not isinstance(item, dict):
                raise IntegrationError(f"{batch.manifest_path}: vocabPacks entries must be objects")
            full_id = str(item.get("packId") or "").strip()
            base_id = _base_pack_id(full_id)
            course = item.get("curriculum")
            if not full_id or not isinstance(course, dict):
                raise IntegrationError(f"{batch.manifest_path}: malformed vocab pack declaration")
            unit = str(course.get("courseUnitId") or "").strip()
            if not unit:
                raise IntegrationError(f"{batch.manifest_path}: vocab pack needs courseUnitId")
            _add_mapping(curriculum["vocabPackUnitMap"], base_id, unit, "vocabPackUnitMap")
            if base_id in pack_entries and pack_entries[base_id] != item:
                raise IntegrationError(f"duplicate pack metadata for {base_id!r}")
            pack_entries[base_id] = item

        for item in batch.manifest.get("grammarIntents", []):
            if not isinstance(item, dict):
                raise IntegrationError(f"{batch.manifest_path}: grammarIntents entries must be objects")
            ident = str(item.get("id") or "").strip()
            value = {
                "courseUnitId": item.get("courseUnitId"),
                "conceptIds": item.get("conceptIds"),
            }
            if not ident or not value["courseUnitId"] or not value["conceptIds"]:
                raise IntegrationError(f"{batch.manifest_path}: malformed grammar intent")
            _add_mapping(curriculum["grammarRuleMap"], ident, value, "grammarRuleMap")

        for item in batch.manifest.get("smalltalkCategoryMappings", []):
            if not isinstance(item, dict):
                raise IntegrationError(f"{batch.manifest_path}: malformed smalltalk mapping")
            level = str(item.get("level") or "").lower()
            category = str(item.get("category") or "").strip()
            value = {"courseUnitId": item.get("courseUnitId"), "conceptIds": item.get("conceptIds")}
            if not level or not category or not value["courseUnitId"] or not value["conceptIds"]:
                raise IntegrationError(f"{batch.manifest_path}: incomplete smalltalk mapping")
            _add_mapping(curriculum["smalltalkCategoryUnitMap"], f"{level}:{category}", value, "smalltalkCategoryUnitMap")

        for item in batch.manifest.get("clozeTopicMappings", []):
            if not isinstance(item, dict):
                raise IntegrationError(f"{batch.manifest_path}: malformed cloze mapping")
            level = str(item.get("level") or "").lower()
            topic = str(item.get("topic") or "").strip().lower()
            unit = str(item.get("courseUnitId") or "").strip()
            if not level or not topic or not unit:
                raise IntegrationError(f"{batch.manifest_path}: incomplete cloze mapping")
            _add_mapping(curriculum["clozeTopicUnitMap"], f"{level}:{topic}", unit, "clozeTopicUnitMap")
    return pack_entries


def _git_show(root: Path, path: str) -> str:
    result = subprocess.run(
        ["git", "show", f"{RECOVERY_REVISION}:{path}"],
        cwd=root,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        raise IntegrationError(f"cannot recover repository-owned content: {result.stderr.strip()}")
    return result.stdout


def _legacy_recovery(root: Path) -> tuple[list[dict[str, str]], list[dict[str, str]], list[dict[str, Any]]]:
    vocab = [
        row
        for row in csv.DictReader(StringIO(_git_show(root, "assets/data/korean_vocab.csv")))
        if row.get("pack_id") in RECOVERY_PACK_IDS
    ]
    grammar = [
        row
        for row in csv.DictReader(StringIO(_git_show(root, "assets/data/grammar.csv")))
        if row.get("id") in RECOVERY_GRAMMAR_IDS
    ]
    pool = json.loads(_git_show(root, "assets/data/kkeunmari_pool.json"))
    words = pool.get("words") if isinstance(pool, dict) else None
    if not isinstance(words, list):
        raise IntegrationError("recovery pool does not contain words")
    kkeunmari = [
        dict(item)
        for item in words
        if isinstance(item, dict) and item.get("word") in RECOVERY_KKEUNMARI_WORDS
    ]
    if len(vocab) != 30 or len(grammar) != 7 or len(kkeunmari) != 6:
        raise IntegrationError("recovery revision does not contain the expected original B2 inventory")
    # The original ten-word packs predate the current Learn → Quiz → Boss
    # contract.  Preserve their authored words and examples, while marking the
    # final two rows in each existing pack as the required review-Boss words.
    for row in vocab:
        row["is_review_boss"] = "true" if int(row["pack_order"]) in {9, 10} else "false"

    # The same original grammar rows also predate the stricter DE/EN focus and
    # same-level distractor ratchets.  These replacements are all literal
    # substrings of the authored translations.  The two excluded duplicate
    # patterns (-다가는, -도록 하다) cannot remain distractors after Batch 01/03
    # become the canonical versions of those forms.
    quiz_repairs = {
        "grammar_b2_pretense_contrast": (
            "tat so, als wüsste er nichts",
            "pretended not to",
            "grammar_b2_inevitability|grammar_b2_only|grammar_b2_quoted_contractions",
        ),
        "grammar_b2_addition_even": (
            "sogar wenig Leute da",
            "there are even few people",
            "grammar_b2_pretense_contrast|grammar_b2_inevitability|grammar_b2_only",
        ),
        "grammar_b2_indirect_speech": (
            "dass er morgen kommt",
            "said he's coming",
            "grammar_b2_quoted_contractions|grammar_b2_pretense_contrast|grammar_b2_addition_even",
        ),
        "grammar_b2_futility": (
            "schon vorbei sein",
            "it'll already be over",
            "grammar_b2_addition_even|grammar_b2_pretense_contrast|grammar_b2_indirect_speech",
        ),
        "grammar_b2_unexpected_cause": (
            "plötzlich regnete",
            "suddenly rained",
            "grammar_b2_addition_even|grammar_b2_futility|grammar_b2_indirect_speech",
        ),
        "grammar_b2_worth_doing": (
            "sehenswert",
            "worth watching",
            "grammar_b2_futility|grammar_b2_not_only|grammar_b2_addition_even",
        ),
        "grammar_b2_practically": (
            "quasi gesund",
            "practically healthy",
            "grammar_b2_worth_doing|grammar_b2_not_only|grammar_b2_addition_even",
        ),
    }
    for row in grammar:
        focus_de, focus_en, distractors = quiz_repairs[row["id"]]
        row["quiz_focus_de"] = focus_de
        row["quiz_focus_en"] = focus_en
        row["quiz_distractor_ids"] = distractors
    return vocab, grammar, kkeunmari


def _assert_new_records(existing: Iterable[dict[str, Any]], incoming: Iterable[dict[str, Any]], *, kind: str) -> None:
    existing_ids = {str(row.get("id") or "") for row in existing}
    incoming_ids: set[str] = set()
    for row in incoming:
        ident = str(row.get("id") or "")
        if not ident or ident in existing_ids or ident in incoming_ids:
            raise IntegrationError(f"{kind}: duplicate or existing ID {ident!r}")
        incoming_ids.add(ident)


def _recompute_kkeunmari(words: list[dict[str, Any]]) -> None:
    by_first: dict[str, list[dict[str, Any]]] = {}
    for item in words:
        word = str(item.get("word") or "")
        if not word:
            raise IntegrationError("kkeunmari entry has an empty word")
        by_first.setdefault(word[0], []).append(item)
    for item in words:
        word = str(item["word"])
        next_count = len(by_first.get(word[-1], [])) - (1 if word[0] == word[-1] else 0)
        item["next_count"] = next_count
        item["is_dead_end"] = next_count == 0


def _ensure_pack_code(
    service_text: str,
    packs: dict[str, dict[str, Any]],
) -> str:
    for base, pack in packs.items():
        label = f"    '{base}': ('{pack['de']}', '{pack['en']}'),\n"
        if f"    '{base}':" not in service_text:
            anchor = "  };\n\n  /// 레벨 내 팩 학습 순서"
            if anchor not in service_text:
                raise IntegrationError("cannot locate pack display-map terminator")
            service_text = service_text.replace(anchor, label + anchor, 1)
        order = f"    '{base}': {pack['order']},\n"
        order_map = "static const Map<String, int> packOrderInLevel = {"
        start = service_text.index(order_map)
        if f"    '{base}':" not in service_text[start:]:
            anchor = "  };\n}\n"
            offset = service_text.find(anchor, start)
            if offset < 0:
                raise IntegrationError("cannot locate pack-order terminator")
            service_text = service_text[:offset] + order + service_text[offset:]
    return service_text


def _ensure_motifs(motif_text: str, packs: dict[str, dict[str, Any]]) -> str:
    missing = [base for base in packs if f"'{base}'" not in motif_text]
    if not missing:
        return motif_text
    lines = ["    // Reviewed A1-C2 content packs using the existing motif pipeline."]
    for base in missing:
        lines.append(f"    '{base}' => DancheongMotif.{packs[base]['motif']},")
    anchor = "    _ => DancheongMotif.lotus,"
    if anchor not in motif_text:
        raise IntegrationError("cannot locate Dancheong motif fallback")
    return motif_text.replace(anchor, "\n".join(lines) + "\n" + anchor, 1)


def _write_stage(
    root: Path,
    batches: list[BatchPayload],
    *,
    restore_b2_recovery: bool,
) -> tuple[dict[Path, str], dict[str, int]]:
    with tempfile.TemporaryDirectory(prefix="content-batch-integration-") as directory:
        stage = Path(directory) / "repo"
        shutil.copytree(root / "assets" / "data", stage / "assets" / "data")
        mirror_source = root / "functions" / "analyze_korean_text" / "grammar_patterns.json"
        mirror_target = stage / "functions" / "analyze_korean_text" / "grammar_patterns.json"
        mirror_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(mirror_source, mirror_target)

        staged_data = stage / "assets" / "data"
        for kind, (target_name, collection, header) in TARGETS.items():
            target = staged_data / target_name
            if header is not None:
                actual_header, current = _read_csv(target)
                if actual_header != header:
                    raise IntegrationError(f"{target}: live header differs from expected {kind} schema")
                incoming = [record for batch in batches for record in batch.artifacts[kind][2]]
                _assert_new_records(current, incoming, kind=kind)
                target.write_text(_csv_text(header, [*current, *incoming]), encoding="utf-8")
            else:
                current_root = _read_json(target)
                records = current_root.get(collection or "")
                if not isinstance(records, list):
                    raise IntegrationError(f"{target}: missing {collection} collection")
                incoming = [record for batch in batches for record in batch.artifacts[kind][2]]
                _assert_new_records(records, incoming, kind=kind)
                current_root[collection or ""] = [*records, *incoming]
                target.write_text(_json_text(current_root), encoding="utf-8")

        curriculum = _read_json(staged_data / "curriculum_manifest.json")
        _merge_curriculum_extensions(curriculum, batches)
        packs = _merge_batch_mappings(curriculum, batches)

        if restore_b2_recovery:
            recovery_vocab, recovery_grammar, recovery_words = _legacy_recovery(root)
            vocab_header, current_vocab = _read_csv(staged_data / "korean_vocab.csv")
            _assert_new_records(current_vocab, recovery_vocab, kind="recovery vocab")
            known_words = {str(row.get("korean") or "") for row in current_vocab}
            if known_words & {str(row.get("korean") or "") for row in recovery_vocab}:
                raise IntegrationError("recovery vocabulary duplicates an already-integrated Korean headword")
            (staged_data / "korean_vocab.csv").write_text(
                _csv_text(vocab_header, [*current_vocab, *recovery_vocab]), encoding="utf-8"
            )

            grammar_header, current_grammar = _read_csv(staged_data / "grammar.csv")
            _assert_new_records(current_grammar, recovery_grammar, kind="recovery grammar")
            existing_patterns = {str(row.get("pattern") or "") for row in current_grammar}
            if existing_patterns & {str(row.get("pattern") or "") for row in recovery_grammar}:
                raise IntegrationError("recovery grammar duplicates an already-integrated grammar pattern")
            (staged_data / "grammar.csv").write_text(
                _csv_text(grammar_header, [*current_grammar, *recovery_grammar]), encoding="utf-8"
            )

            pool = _read_json(staged_data / "kkeunmari_pool.json")
            words = pool.get("words")
            if not isinstance(words, list) or any(not isinstance(item, dict) for item in words):
                raise IntegrationError("kkeunmari pool must contain word objects")
            known_words = {str(item.get("word") or "") for item in words}
            if known_words & {str(item.get("word") or "") for item in recovery_words}:
                raise IntegrationError("recovery kkeunmari words already exist")
            words.extend(recovery_words)
            _recompute_kkeunmari(words)
            meta = pool.get("meta")
            if not isinstance(meta, dict):
                raise IntegrationError("kkeunmari pool meta must be an object")
            meta["total"] = len(words)
            (staged_data / "kkeunmari_pool.json").write_text(_json_text(pool), encoding="utf-8")

            for base, entry in RECOVERY_PACKS.items():
                _add_mapping(curriculum["vocabPackUnitMap"], base, entry["unit"], "vocabPackUnitMap")
                packs[base] = {
                    "displayLabel": {"de": entry["de"], "en": entry["en"]},
                    "orderInLevel": entry["order"],
                    "motif": entry["motif"],
                }
            for ident, (unit, concepts) in RECOVERY_GRAMMAR_MAP.items():
                _add_mapping(
                    curriculum["grammarRuleMap"],
                    ident,
                    {"courseUnitId": unit, "conceptIds": concepts},
                    "grammarRuleMap",
                )

        (staged_data / "curriculum_manifest.json").write_text(_json_text(curriculum), encoding="utf-8")

        audit = _read_json(staged_data / "content_audit_manifest.json")
        sources = audit.get("sources")
        if not isinstance(sources, list):
            raise IntegrationError("content audit manifest must contain sources")
        counts = ContentValidator(stage).inventory_counts()
        for source in sources:
            if isinstance(source, dict) and source.get("kind") in counts:
                source["count"] = counts[source["kind"]]
        graph = audit.get("graph")
        course_units = curriculum.get("courseUnits")
        if not isinstance(graph, dict) or not isinstance(course_units, list):
            raise IntegrationError(
                "content audit graph and curriculum courseUnits must be present"
            )
        graph["courseUnits"] = len(course_units)
        graph["courseUnitsByLevel"] = {
            level: sum(
                1
                for unit in course_units
                if isinstance(unit, dict)
                and str(unit.get("level", "")).strip().lower() == level
            )
            for level in ("a1", "a2", "b1", "b2", "c1", "c2")
        }
        (staged_data / "content_audit_manifest.json").write_text(_json_text(audit), encoding="utf-8")

        issues = ContentValidator(stage).validate()
        if issues:
            rendered = "\n".join(f"{issue.source}: {issue.message}" for issue in issues)
            raise IntegrationError(f"staged full content validation failed:\n{rendered}")

        pack_code: dict[str, dict[str, Any]] = {}
        for base, item in packs.items():
            labels = item.get("displayLabel")
            if not isinstance(labels, dict):
                raise IntegrationError(f"pack {base}: displayLabel must be an object")
            pack_code[base] = {
                "de": labels.get("de"),
                "en": labels.get("en"),
                "order": item.get("orderInLevel"),
                "motif": item.get("motif"),
            }
            if not all(isinstance(pack_code[base][key], str) and pack_code[base][key] for key in ("de", "en", "motif")) or not isinstance(pack_code[base]["order"], int):
                raise IntegrationError(f"pack {base}: incomplete display/order/motif metadata")

        outputs = {
            root / "assets" / "data" / filename: (staged_data / filename).read_text(encoding="utf-8")
            for filename in (
                "korean_vocab.csv",
                "grammar.csv",
                "smalltalk.json",
                "cloze.json",
                "satz_sentences.json",
                "kkeunmari_pool.json",
                "curriculum_manifest.json",
                "content_audit_manifest.json",
            )
        }
        service = root / "lib" / "services" / "vocab_pack_service.dart"
        motifs = root / "lib" / "widgets" / "sori" / "dancheong_stamp.dart"
        outputs[service] = _ensure_pack_code(service.read_text(encoding="utf-8"), pack_code)
        outputs[motifs] = _ensure_motifs(motifs.read_text(encoding="utf-8"), pack_code)
        return outputs, counts


def _promoted_ledger_text(path: Path) -> str:
    header, rows = _read_csv(path)
    if header != REVIEW_HEADER:
        raise IntegrationError(f"{path}: review header changed during integration")
    for row in rows:
        row["상태"] = "approved"
        row["jin_memo"] = "Jin explicit app-integration approval (2026-08-15)."
    return _csv_text(header, rows)


def _promoted_manifest_text(path: Path) -> str:
    manifest = _read_json(path)
    manifest["status"] = "merged"
    provenance = manifest.get("provenance")
    if not isinstance(provenance, dict):
        raise IntegrationError(f"{path}: provenance must be an object")
    provenance["approval"] = {
        "authority": "Jin",
        "approvedAt": "2026-08-15",
        "scope": "all records promoted to bundled app content",
    }
    provenance["mergedAt"] = "2026-08-15"
    return _json_text(manifest)


def _atomic_write(path: Path, text: str) -> None:
    temporary = path.with_name(f".{path.name}.content-integration.tmp")
    try:
        temporary.write_text(text, encoding="utf-8")
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def _atomic_restore(path: Path, data: bytes) -> None:
    """Restore the exact pre-transaction bytes, including original newlines."""

    temporary = path.with_name(f".{path.name}.content-integration.tmp")
    try:
        temporary.write_bytes(data)
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def _verify_written_tree(root: Path, outputs: dict[Path, str]) -> None:
    issues = ContentValidator(root).validate()
    if issues:
        rendered = "\n".join(f"{issue.source}: {issue.message}" for issue in issues)
        raise IntegrationError(f"post-write validation failed:\n{rendered}")
    service = outputs[root / "lib" / "services" / "vocab_pack_service.dart"]
    motifs = outputs[root / "lib" / "widgets" / "sori" / "dancheong_stamp.dart"]
    if "packDisplayMap" not in service or "packOrderInLevel" not in service or "motifForPackId" not in motifs:
        raise IntegrationError("post-write pack display/order/motif contracts are incomplete")


def integrate(
    *,
    root: Path = ROOT,
    manifests: Iterable[Path] = DEFAULT_MANIFESTS,
    apply: bool,
    approve_all: bool,
    restore_b2_recovery: bool,
) -> tuple[dict[str, int], int]:
    root = root.resolve()
    manifests = tuple(manifests)
    if approve_all and not apply:
        raise IntegrationError("--approve-all requires --apply; preview never changes a review ledger")
    batches = [_load_batch(root, manifest) for manifest in manifests]
    if apply:
        _require_promotable_reviews(batches, approve_all=approve_all)
    if approve_all:
        _preflight_review_batches(root, manifests)
    outputs, counts = _write_stage(root, batches, restore_b2_recovery=restore_b2_recovery)
    if not apply:
        return counts, sum(len(records) for batch in batches for _, _, records in batch.artifacts.values())

    if approve_all:
        for batch in batches:
            for _, review, _ in batch.artifacts.values():
                outputs[review] = _promoted_ledger_text(review)
            outputs[batch.manifest_path] = _promoted_manifest_text(batch.manifest_path)

    originals = {path: path.read_bytes() for path in outputs}
    try:
        for path, text in outputs.items():
            _atomic_write(path, text)
        _verify_written_tree(root, outputs)
    except Exception as error:
        rollback_errors: list[str] = []
        for path, data in originals.items():
            try:
                _atomic_restore(path, data)
            except OSError as rollback_error:
                rollback_errors.append(f"{path}: {rollback_error}")
        suffix = f"; rollback failed: {'; '.join(rollback_errors)}" if rollback_errors else ""
        if isinstance(error, IntegrationError):
            raise IntegrationError(f"content integration rolled back: {error}{suffix}") from error
        raise IntegrationError(f"content integration rolled back: {error}{suffix}") from error
    return counts, sum(len(records) for batch in batches for _, _, records in batch.artifacts.values())


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--manifest",
        action="append",
        dest="manifests",
        help="review-batch manifest; defaults to Batch 01, 02, and 03 in order",
    )
    parser.add_argument("--apply", action="store_true", help="write the validated staged integration")
    parser.add_argument(
        "--approve-all",
        action="store_true",
        help="record Jin's explicit all-row approval in the same --apply transaction",
    )
    parser.add_argument(
        "--restore-b2-recovery",
        action="store_true",
        help="restore the repository-owned B2 rows accidentally dropped by the later bulk rewrite",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    manifests = tuple(Path(value) for value in args.manifests) if args.manifests else DEFAULT_MANIFESTS
    try:
        counts, record_count = integrate(
            manifests=manifests,
            apply=args.apply,
            approve_all=args.approve_all,
            restore_b2_recovery=args.restore_b2_recovery,
        )
    except IntegrationError as error:
        print(f"✗ {error}", file=sys.stderr)
        return 1
    action = "applied" if args.apply else "preview"
    recovery = " + repository-owned B2 recovery" if args.restore_b2_recovery else ""
    print(f"✓ {action}: {record_count} reviewed records{recovery}; inventory {counts}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
