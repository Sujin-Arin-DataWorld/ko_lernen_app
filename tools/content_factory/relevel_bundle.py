#!/usr/bin/env python3
"""Atomic bundle-level relevel transaction (plan §4.3, §3.E; task T2.3).

Moves a *bundle* (a vocab pack plus every cloze/satz/smalltalk/scenario item
tied to it) from one CEFR level to another in one all-or-nothing transaction:
CSV/JSON edits happen in a staged copy of ``assets/data``, the staged copy is
checked by ``ContentValidator`` and by ``check_can_do_consistency`` (a Python
re-implementation of ``CanonicalCourseSegmentLoader``'s Dart checks -- see
that class's ``_requireExactContentCoverage``/``_validateCoverageAudit`` in
``lib/services/canonical_course_segment_loader.dart``), and only a clean
stage is copied back over the real repository. IDs never change (plan
"ID는 불변") -- only ``level``/``pack_id``/course-unit routing move, recorded
in ``tools/content_factory/relevel_ledger.json``.

L2a is vocab-pack-only: every move's ``scenarios`` and ``smalltalk`` lists
must be empty (scenario/smalltalk bundle moves are PR-L2b, not implemented
here), and ``cloze``/``satz`` must be the literal string ``"auto"`` (match by
content, not by explicit id list -- also not implemented here).

Usage::

    python tools/content_factory/relevel_bundle.py \\
        tools/content_factory/relevel/relevel_bundle_L2a.json [--apply] \\
        [--report docs/data/relevel_L2a_report.md]

Default is a dry run: the plan is computed and printed (the stage is built
and validated, so a dry run proves the move is safe -- it just never writes
back to the real repository, the ledger, or the Dart files).
"""

from __future__ import annotations

import argparse
import ast
import csv
import hashlib
import json
import os
import re
import shutil
import sys
import tempfile
from collections import Counter
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import materialize_canonical_scenarios as materializer
import relevel_ledger
import scenario_store
from relevel_ledger import Ledger, LedgerEntry
from shelf_assignment import SHELF_SLUGS
from validate_content import ContentValidator, LOWER_LEVELS, VOCAB_HEADER

# a1 < a2 < ... < c2, used only for the scenario-move grammarIds "not above
# the target level" warning (plan §4.3 step 1) -- LOWER_LEVELS itself is an
# unordered frozenset, so this is a separate, deliberately-ordered tuple.
LEVEL_ORDER: dict[str, int] = {level: index for index, level in enumerate(
    ("a1", "a2", "b1", "b2", "c1", "c2")
)}

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_LEDGER_PATH = SCRIPT_DIR / "relevel_ledger.json"
PACK_PROGRESS_ALIASES_PATH = ROOT / "lib" / "data" / "pack_progress_aliases.dart"
VOCAB_PACK_SERVICE_PATH = ROOT / "lib" / "services" / "vocab_pack_service.dart"
PACK_ARTWORK_CATALOG_PATH = ROOT / "lib" / "data" / "pack_artwork_catalog.dart"
DANCHEONG_STAMP_PATH = ROOT / "lib" / "widgets" / "sori" / "dancheong_stamp.dart"
ARTWORK_ASSET_DIR = ROOT / "assets" / "illustrations" / "packs"
PACK_SOURCE_DIR = ROOT / "tools" / "content_factory" / "data" / "packs"
CANONICAL_SCENARIOS_DIR = ROOT / "tools" / "content_factory" / "canonical_scenarios"
CANONICAL_AUTHORED_DIR = CANONICAL_SCENARIOS_DIR / "authored"
SCENARIO_BRIEFS_PATH = CANONICAL_SCENARIOS_DIR / "scenario_briefs.json"
REVIEW_CANDIDATES_DIR = ROOT / "tools" / "content_factory" / "review" / "canonical_120_v1" / "candidates"

CLOZE_JSON = "cloze.json"
SATZ_JSON = "satz_sentences.json"
CURRICULUM_JSON = "curriculum_manifest.json"
CAN_DO_SEGMENTS_JSON = "can_do_segments.json"
CAN_DO_AUTHORITIES_JSON = "can_do_content_authorities.json"


class RelevelError(ValueError):
    """A malformed bundle file, or a staged transaction that fails validation.

    Fail-closed: raised *before* anything in the real repository is touched.
    """


# ───────────────────────── bundle JSON shape ──────────────────────────────


@dataclass(frozen=True)
class Move:
    bundle: str
    from_level: str
    to_level: str
    new_pack_id: str
    course_unit_id: str
    concept_ids: tuple[str, ...]
    scenarios: tuple[Any, ...]
    cloze: str
    satz: str
    smalltalk: tuple[str, ...]
    reason: str
    # Optional (T2.3-R1 STEP 1b/1c, Fable rulings): when given, canDoClusterId
    # pins the exact contentCluster instead of running the slug-overlap
    # heuristic, and packOrder pins the exact packOrderInLevel slot instead
    # of appending at max+1 for the target level (see choose_target_cluster
    # and edit_vocab_pack_service/_bump_order_entries).
    can_do_cluster_id: str | None = None
    pack_order: int | None = None

    @classmethod
    def from_dict(cls, raw: Any) -> "Move":
        if not isinstance(raw, dict):
            raise RelevelError(f"each move must be an object, got {raw!r}")
        required = (
            "bundle", "from", "to", "newPackId", "courseUnitId", "conceptIds",
            "scenarios", "cloze", "satz", "smalltalk", "reason",
        )
        missing = [key for key in required if key not in raw]
        if missing:
            raise RelevelError(f"move {raw.get('bundle')!r} missing field(s) {missing}")

        bundle = raw["bundle"]
        from_level = raw["from"]
        to_level = raw["to"]
        new_pack_id = raw["newPackId"]
        course_unit_id = raw["courseUnitId"]
        concept_ids = raw["conceptIds"]
        scenarios = raw["scenarios"]
        cloze = raw["cloze"]
        satz = raw["satz"]
        smalltalk = raw["smalltalk"]
        reason = raw["reason"]

        for label, value in (("bundle", bundle), ("newPackId", new_pack_id),
                              ("courseUnitId", course_unit_id), ("reason", reason)):
            if not isinstance(value, str) or not value.strip():
                raise RelevelError(f"move {bundle!r}: {label} must be a nonempty string")
        if from_level not in LOWER_LEVELS or to_level not in LOWER_LEVELS:
            raise RelevelError(
                f"move {bundle!r}: from/to must be one of {sorted(LOWER_LEVELS)}, "
                f"got from={from_level!r} to={to_level!r}"
            )
        if from_level == to_level:
            raise RelevelError(f"move {bundle!r}: from and to are both {from_level!r}")
        if not bundle.startswith(f"{from_level}_"):
            raise RelevelError(f"move {bundle!r}: bundle id does not start with {from_level!r}_")
        if not new_pack_id.startswith(f"{to_level}_"):
            raise RelevelError(f"move {bundle!r}: newPackId {new_pack_id!r} does not start with {to_level!r}_")
        if (not isinstance(concept_ids, list) or not concept_ids
                or any(not isinstance(c, str) or not c.strip() for c in concept_ids)):
            raise RelevelError(f"move {bundle!r}: conceptIds must be a nonempty list of strings")
        if not isinstance(scenarios, list):
            raise RelevelError(f"move {bundle!r}: scenarios must be a list")
        if not isinstance(smalltalk, list):
            raise RelevelError(f"move {bundle!r}: smalltalk must be a list")
        if scenarios:
            raise NotImplementedError(
                f"move {bundle!r} has {len(scenarios)} scenario(s) -- scenario bundle "
                "moves are PR-L2b, not implemented by relevel_bundle.py yet. L2a "
                "requires every move's `scenarios` to be []."
            )
        if smalltalk:
            raise NotImplementedError(
                f"move {bundle!r} has {len(smalltalk)} smalltalk id(s) -- smalltalk "
                "bundle moves are PR-L2b, not implemented by relevel_bundle.py yet. "
                "L2a requires every move's `smalltalk` to be []."
            )
        if cloze != "auto":
            raise NotImplementedError(
                f"move {bundle!r}: cloze={cloze!r} -- only the literal \"auto\" "
                "matching mode is implemented."
            )
        if satz != "auto":
            raise NotImplementedError(
                f"move {bundle!r}: satz={satz!r} -- only the literal \"auto\" "
                "matching mode is implemented."
            )

        can_do_cluster_id = raw.get("canDoClusterId")
        if can_do_cluster_id is not None and (
            not isinstance(can_do_cluster_id, str) or not can_do_cluster_id.strip()
        ):
            raise RelevelError(f"move {bundle!r}: canDoClusterId must be a nonempty string when present")

        pack_order = raw.get("packOrder")
        if pack_order is not None and (
            not isinstance(pack_order, int) or isinstance(pack_order, bool) or pack_order < 1
        ):
            raise RelevelError(f"move {bundle!r}: packOrder must be a positive integer when present")

        return cls(
            bundle=bundle,
            from_level=from_level,
            to_level=to_level,
            new_pack_id=new_pack_id,
            course_unit_id=course_unit_id,
            concept_ids=tuple(concept_ids),
            scenarios=tuple(scenarios),
            cloze=cloze,
            satz=satz,
            smalltalk=tuple(smalltalk),
            reason=reason,
            can_do_cluster_id=can_do_cluster_id,
            pack_order=pack_order,
        )


@dataclass(frozen=True)
class ScenarioMove:
    """One scenario-level relevel (plan §4.3 step 4, LCP PR-L2a2 / T2.4b-1).

    Unlike ``Move`` (a whole vocab-pack bundle plus its derived cloze/satz),
    a scenario is a single leaf content object -- there is no ``newPackId``,
    no ``cloze``/``satz``/``smalltalk`` match-by-content step, and the id
    never changes (scenario ids already carry no level segment, so there is
    nothing analogous to rename).
    """

    id: str
    from_level: str
    to_level: str
    shelf: str
    course_unit_id: str
    concept_ids: tuple[str, ...]
    reason: str
    # Optional: keep the scenario's current backdrop when absent.
    backdrop: str | None = None
    # Required only when the scenario turns out to have a can-do reference
    # (checked once the live can_do_content_authorities.json is read, not
    # here at parse time -- see _migrate_can_do_scenarios).
    can_do_cluster_id: str | None = None

    @classmethod
    def from_dict(cls, raw: Any) -> "ScenarioMove":
        if not isinstance(raw, dict):
            raise RelevelError(f"each scenarioMove must be an object, got {raw!r}")
        required = ("id", "from", "to", "shelf", "courseUnitId", "conceptIds", "reason")
        missing = [key for key in required if key not in raw]
        if missing:
            raise RelevelError(f"scenarioMove {raw.get('id')!r} missing field(s) {missing}")

        ident = raw["id"]
        from_level = raw["from"]
        to_level = raw["to"]
        shelf = raw["shelf"]
        course_unit_id = raw["courseUnitId"]
        concept_ids = raw["conceptIds"]
        reason = raw["reason"]

        for label, value in (("id", ident), ("shelf", shelf),
                              ("courseUnitId", course_unit_id), ("reason", reason)):
            if not isinstance(value, str) or not value.strip():
                raise RelevelError(f"scenarioMove {ident!r}: {label} must be a nonempty string")
        if from_level not in LOWER_LEVELS or to_level not in LOWER_LEVELS:
            raise RelevelError(
                f"scenarioMove {ident!r}: from/to must be one of {sorted(LOWER_LEVELS)}, "
                f"got from={from_level!r} to={to_level!r}"
            )
        if from_level == to_level:
            raise RelevelError(f"scenarioMove {ident!r}: from and to are both {from_level!r}")
        if (not isinstance(concept_ids, list) or not concept_ids
                or any(not isinstance(c, str) or not c.strip() for c in concept_ids)):
            raise RelevelError(f"scenarioMove {ident!r}: conceptIds must be a nonempty list of strings")

        if not shelf.startswith(f"{to_level}_"):
            raise RelevelError(
                f"scenarioMove {ident!r}: shelf {shelf!r} does not start with {to_level!r}_"
            )
        slug = shelf[len(to_level) + 1:]
        if slug not in SHELF_SLUGS.get(to_level, ()):
            raise RelevelError(
                f"scenarioMove {ident!r}: shelf slug {slug!r} is not one of "
                f"shelf_assignment.SHELF_SLUGS[{to_level!r}] {SHELF_SLUGS.get(to_level, ())}"
            )

        backdrop = raw.get("backdrop")
        if backdrop is not None and (not isinstance(backdrop, str) or not backdrop.strip()):
            raise RelevelError(f"scenarioMove {ident!r}: backdrop must be a nonempty string when present")

        can_do_cluster_id = raw.get("canDoClusterId")
        if can_do_cluster_id is not None and (
            not isinstance(can_do_cluster_id, str) or not can_do_cluster_id.strip()
        ):
            raise RelevelError(f"scenarioMove {ident!r}: canDoClusterId must be a nonempty string when present")

        return cls(
            id=ident,
            from_level=from_level,
            to_level=to_level,
            shelf=shelf,
            course_unit_id=course_unit_id,
            concept_ids=tuple(concept_ids),
            reason=reason,
            backdrop=backdrop,
            can_do_cluster_id=can_do_cluster_id,
        )


@dataclass(frozen=True)
class BundleFile:
    batch: str
    moves: tuple[Move, ...]
    scenario_moves: tuple[ScenarioMove, ...] = ()


def load_bundle_from_dict(raw: Any, *, source: str = "<bundle>") -> BundleFile:
    if not isinstance(raw, dict):
        raise RelevelError(f"{source}: root must be an object")
    batch = raw.get("batch")
    if not isinstance(batch, str) or not batch.strip():
        raise RelevelError(f"{source}: batch must be a nonempty string")

    raw_moves = raw.get("moves", [])
    if not isinstance(raw_moves, list):
        raise RelevelError(f"{source}: moves must be a list")
    raw_scenario_moves = raw.get("scenarioMoves", [])
    if not isinstance(raw_scenario_moves, list):
        raise RelevelError(f"{source}: scenarioMoves must be a list")
    # A bundle may have `moves: []` and only `scenarioMoves` (PR-L2a2, plan
    # §4.3 step 4) -- but never neither, or there is nothing to do.
    if not raw_moves and not raw_scenario_moves:
        raise RelevelError(f"{source}: at least one of moves/scenarioMoves must be nonempty")

    moves = tuple(Move.from_dict(item) for item in raw_moves)
    bundle_ids = [move.bundle for move in moves]
    if len(bundle_ids) != len(set(bundle_ids)):
        raise RelevelError(f"{source}: duplicate bundle id in moves")
    new_pack_ids = [move.new_pack_id for move in moves]
    if len(new_pack_ids) != len(set(new_pack_ids)):
        raise RelevelError(f"{source}: duplicate newPackId in moves")

    scenario_moves = tuple(ScenarioMove.from_dict(item) for item in raw_scenario_moves)
    scenario_ids = [move.id for move in scenario_moves]
    if len(scenario_ids) != len(set(scenario_ids)):
        raise RelevelError(f"{source}: duplicate id in scenarioMoves")

    return BundleFile(batch=batch, moves=moves, scenario_moves=scenario_moves)


def load_bundle(path: Path) -> BundleFile:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except OSError as error:
        raise RelevelError(f"cannot read {path}: {error}") from error
    except json.JSONDecodeError as error:
        raise RelevelError(f"cannot parse {path}: {error}") from error
    return load_bundle_from_dict(raw, source=str(path))


# ───────────────────────── generic file IO ────────────────────────────────


def _read_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise RelevelError(f"cannot read {path}: {error}") from error


def _write_json(path: Path, value: Any) -> None:
    # write_bytes, not write_text: on Windows, Path.write_text (text mode)
    # translates every "\n" to os.linesep ("\r\n"), which is exactly how a
    # previous run produced CRLF JSON output (T2.3-R1 STEP 1a).
    content = json.dumps(value, ensure_ascii=False, indent=2) + "\n"
    path.write_bytes(content.encode("utf-8"))


def _normalize_newlines(text: str) -> str:
    """Collapse any CRLF/CR the source file may already have on disk (e.g. a
    Windows checkout with autocrlf) to bare LF, *before* any Dart-literal
    parsing or splicing touches it. Without this, bytes read via
    ``Path.read_bytes().decode(...)`` (no universal-newline translation)
    keep the original file's CRLF for untouched lines while every newly
    spliced-in entry is LF-only -- the "mixed" line-ending defect T2.3-R1
    STEP 1a fixes. Safe to call on already-LF text (no-op)."""

    return text.replace("\r\n", "\n").replace("\r", "\n")


def _load_vocab_csv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as handle:
        reader = csv.reader(handle)
        header = next(reader)
        if header != VOCAB_HEADER:
            raise RelevelError(f"{path}: unexpected CSV header {header!r}")
        return [dict(zip(header, row)) for row in reader if row]


def _write_vocab_csv(path: Path, rows: list[dict[str, str]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, quoting=csv.QUOTE_MINIMAL, lineterminator="\n")
        writer.writerow(VOCAB_HEADER)
        for row in rows:
            writer.writerow([row[column] for column in VOCAB_HEADER])


def pack_base(pack_id: str) -> str:
    """Base pack id (drop a trailing numeric ``_N`` segment).

    Exact mirror of ``ContentValidator._pack_base`` / ``VocabPackService.
    _baseId`` (Dart) -- the same string both maps' keys and both validators'
    cross-checks use, so this must not drift from either.
    """

    parts = pack_id.strip().lower().split("_")
    if len(parts) > 1 and parts[-1].isdigit():
        parts.pop()
    return "_".join(parts)


def _fingerprint(value: object) -> str:
    """sha256 of the canonical (sorted-key, compact) JSON form of ``value``.

    Exact mirror of ``tool/refresh_can_do_vocab_fingerprints.py``'s
    ``_fingerprint`` and ``lib/services/canonical_course_segment_loader.
    dart``'s ``_jsonFingerprint``/``_canonicalizeJson`` -- all three must
    agree since the Dart loader is the ultimate consumer.
    """

    canonical = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


# ───────────────────────── per-move plan report ───────────────────────────


@dataclass
class PackMoveReport:
    bundle: str
    new_pack_id: str
    from_level: str
    to_level: str
    course_unit_id: str
    n_words: int = 0
    n_cloze: int = 0
    n_satz: int = 0
    source_cluster_id: str | None = None
    target_cluster_id: str | None = None
    target_segment_id: str | None = None
    cluster_choice_note: str = ""
    cluster_candidates: tuple[str, ...] = ()
    has_dedicated_artwork: bool = False
    # tools/content_factory/data/packs/<bundle>.json -- the Batch 09/10 4x-
    # expansion archival authoring source build_level_content_4x.load_packs()
    # reads (task T2.9a). Not every pack has one (see sync_pack_source_files).
    has_pack_source: bool = False


@dataclass
class ScenarioMoveReport:
    scenario_id: str
    from_level: str
    to_level: str
    course_unit_id: str
    shelf: str
    content_links_updated: int = 0
    can_do_note: str = ""
    source_cluster_id: str | None = None
    target_cluster_id: str | None = None
    shelf_assignment_note: str = ""
    ab_specs_note: str = ""
    grammar_level_warnings: list[str] = field(default_factory=list)
    # task T2.9a: canonical_scenarios/ + review/canonical_120_v1/candidates/
    # sync notes (see sync_canonical_authored_scenarios/edit_scenario_briefs_
    # source/sync_review_candidate_scenarios below) -- all default to a
    # "not present, no-op" note since not every scenarioMove necessarily has
    # a canonical_120_v1-pipeline source to sync (e.g. a test fixture that
    # never provisions canonical_scenarios/ at all).
    canonical_authored_note: str = "canonical_scenarios/authored/ not found -- no-op"
    scenario_brief_note: str = "scenario_briefs.json not found -- no-op"
    review_candidate_note: str = "review candidate not found -- no-op"


@dataclass
class MigrationReport:
    batch: str
    packs: list[PackMoveReport] = field(default_factory=list)
    cloze_topic_keys_added: list[str] = field(default_factory=list)
    cloze_topic_keys_removed: list[str] = field(default_factory=list)
    content_links_rewritten: int = 0
    vocab_pack_unit_map_renames: list[tuple[str, str]] = field(default_factory=list)
    dart_display_map_renames: list[tuple[str, str]] = field(default_factory=list)
    dart_order_map_renames: list[tuple[str, str, int]] = field(default_factory=list)
    dart_artwork_renames: list[tuple[str, str]] = field(default_factory=list)
    artwork_files_renamed: list[tuple[str, str]] = field(default_factory=list)
    dancheong_motif_renames: list[tuple[str, str, str]] = field(default_factory=list)
    pack_sources_synced: list[tuple[str, str]] = field(default_factory=list)
    # (scenario_id, from_level, to_level) for each review/canonical_120_v1/
    # candidates/<level>/<id>.json sync_review_candidate_scenarios actually
    # moved -- new-file bookkeeping for migrate()'s rollback, same role as
    # pack_sources_synced above.
    review_candidates_synced: list[tuple[str, str, str]] = field(default_factory=list)
    aliases_added: list[tuple[str, str]] = field(default_factory=list)
    test_references: dict[str, list[str]] = field(default_factory=dict)
    scenarios: list[ScenarioMoveReport] = field(default_factory=list)


# ───────────────────────── vocab / cloze / satz ───────────────────────────


def _migrate_vocab(
    vocab_rows: list[dict[str, str]],
    move: Move,
    ledger: Ledger,
    batch: str,
) -> tuple[list[dict[str, str]], set[str], set[str], Ledger]:
    """Rename ``move.bundle``'s rows in place; return (matched rows, their
    example_korean set, their korean set, ledger with vocab entries added).

    Row position, ``id``, ``pack_order`` and ``is_review_boss`` are untouched
    -- only ``level``/``pack_id`` move (plan §4.3 step 1)."""

    matched = [row for row in vocab_rows if row["pack_id"] == move.bundle]
    if not matched:
        raise RelevelError(f"move {move.bundle!r}: no korean_vocab.csv rows have pack_id={move.bundle!r}")
    example_ko = {row["example_korean"] for row in matched}
    korean = {row["korean"] for row in matched}
    for row in matched:
        if row["level"].strip().upper() != move.from_level.upper():
            raise RelevelError(
                f"move {move.bundle!r}: row {row['id']} level {row['level']!r} "
                f"disagrees with move.from={move.from_level!r}"
            )
        row["level"] = move.to_level.upper()
        row["pack_id"] = move.new_pack_id
        ledger = ledger.append(LedgerEntry(
            id=row["id"], kind="vocab", from_level=move.from_level, to_level=move.to_level,
            movedAt=date.today().isoformat(), batch=batch, reason=move.reason,
        ))
    return matched, example_ko, korean, ledger


def _migrate_cloze(
    cloze_items: list[dict[str, Any]],
    move: Move,
    example_ko: set[str],
    ledger: Ledger,
    batch: str,
) -> tuple[list[dict[str, Any]], Ledger]:
    matched = [
        item for item in cloze_items
        if item.get("level") == move.from_level and item.get("fullKo") in example_ko
    ]
    for item in matched:
        item["level"] = move.to_level
        ledger = ledger.append(LedgerEntry(
            id=item["id"], kind="cloze", from_level=move.from_level, to_level=move.to_level,
            movedAt=date.today().isoformat(), batch=batch, reason=move.reason,
        ))
    return matched, ledger


def _migrate_satz(
    satz_items: list[dict[str, Any]],
    move: Move,
    korean: set[str],
    ledger: Ledger,
    batch: str,
) -> tuple[list[dict[str, Any]], Ledger]:
    matched = [
        item for item in satz_items
        if item.get("level") == move.from_level and item.get("vocabKo") in korean
    ]
    for item in matched:
        item["level"] = move.to_level
        ledger = ledger.append(LedgerEntry(
            id=item["id"], kind="satz", from_level=move.from_level, to_level=move.to_level,
            movedAt=date.today().isoformat(), batch=batch, reason=move.reason,
        ))
    return matched, ledger


def _refresh_game_meta(root: dict[str, Any], collection: str) -> None:
    meta = root.get("meta")
    items = root.get(collection)
    if not isinstance(meta, dict) or not isinstance(items, list):
        return
    per_level = {level: 0 for level in LOWER_LEVELS}
    for item in items:
        if isinstance(item, dict) and item.get("level") in per_level:
            per_level[str(item["level"])] += 1
    meta["total"] = len(items)
    meta["perLevel"] = {level: per_level[level] for level in ("a1", "a2", "b1", "b2", "c1", "c2")}


# ───────────────────────── curriculum_manifest.json ───────────────────────


def _migrate_curriculum_manifest(
    manifest: dict[str, Any],
    moves: tuple[Move, ...],
    moved_vocab_ids_by_move: dict[str, set[str]],
    moved_cloze_by_move: dict[str, list[dict[str, Any]]],
    all_cloze_items: list[dict[str, Any]],
    report: MigrationReport,
) -> None:
    """Plan §4.3 step 5: vocabPackUnitMap key rename, clozeTopicUnitMap
    add/prune, contentLinks rewrite for any moved vocab id, and a
    conceptIds-vs-requiredConceptIds sanity check for every move."""

    units = {
        unit["id"]: unit
        for unit in manifest.get("courseUnits", [])
        if isinstance(unit, dict) and isinstance(unit.get("id"), str)
    }
    for move in moves:
        unit = units.get(move.course_unit_id)
        if unit is None:
            raise RelevelError(f"move {move.bundle!r}: unknown courseUnitId {move.course_unit_id!r}")
        required = set(unit.get("requiredConceptIds") or [])
        missing = [c for c in move.concept_ids if c not in required]
        if missing:
            raise RelevelError(
                f"move {move.bundle!r}: conceptIds {missing} are not in "
                f"{move.course_unit_id!r}.requiredConceptIds {sorted(required)}"
            )

    vocab_map = manifest.get("vocabPackUnitMap")
    if not isinstance(vocab_map, dict):
        raise RelevelError("curriculum_manifest.json: vocabPackUnitMap must be an object")
    for move in moves:
        old_key = pack_base(move.bundle)
        new_key = pack_base(move.new_pack_id)
        if old_key not in vocab_map:
            raise RelevelError(f"move {move.bundle!r}: vocabPackUnitMap has no key {old_key!r}")
        if new_key in vocab_map:
            raise RelevelError(f"move {move.bundle!r}: vocabPackUnitMap already has key {new_key!r}")
        del vocab_map[old_key]
        vocab_map[new_key] = move.course_unit_id
        report.vocab_pack_unit_map_renames.append((old_key, new_key))

    cloze_map = manifest.get("clozeTopicUnitMap")
    if not isinstance(cloze_map, dict):
        raise RelevelError("curriculum_manifest.json: clozeTopicUnitMap must be an object")
    for move in moves:
        topics = sorted({item["topic"] for item in moved_cloze_by_move[move.bundle]})
        for topic in topics:
            key = f"{move.to_level}:{topic.lower()}"
            if key not in cloze_map:
                cloze_map[key] = move.course_unit_id
                report.cloze_topic_keys_added.append(key)
    # Prune every (from-level, topic) key that has zero remaining live cloze
    # items -- other packs may still share the same topic word, so this is a
    # per-key recount over the *final* cloze corpus, not a per-move delete.
    stale_candidates = set()
    for move in moves:
        for item in moved_cloze_by_move[move.bundle]:
            stale_candidates.add((move.from_level, item["topic"]))
    for from_level, topic in sorted(stale_candidates):
        remaining = any(
            item.get("level") == from_level and item.get("topic") == topic
            for item in all_cloze_items
        )
        key = f"{from_level}:{topic.lower()}"
        if not remaining and key in cloze_map:
            del cloze_map[key]
            report.cloze_topic_keys_removed.append(key)

    links = manifest.get("contentLinks")
    if not isinstance(links, list):
        raise RelevelError("curriculum_manifest.json: contentLinks must be an array")
    # No vocab-kind contentLinks exist in the live corpus today (verified
    # during T2.2/T2.3 research -- vocab ids are never contentLinks targets),
    # but plan §4.3 step 5 asks for this rewrite to be implemented in case a
    # future batch adds one. courseUnitId is the only field a relevel can
    # invalidate; contentId is immutable and contentKind/role do not change.
    unit_by_vocab_id = {
        vocab_id: move.course_unit_id
        for move in moves
        for vocab_id in moved_vocab_ids_by_move[move.bundle]
    }
    for link in links:
        if not isinstance(link, dict) or link.get("contentKind") != "vocab":
            continue
        new_unit = unit_by_vocab_id.get(link.get("contentId"))
        if new_unit is not None:
            link["courseUnitId"] = new_unit
            report.content_links_rewritten += 1


# ───────────────────────── scenario moves (PR-L2a2, T2.4b-1) ──────────────


def _migrate_scenario_object(
    scenario: dict[str, Any], move: ScenarioMove, report: ScenarioMoveReport,
) -> None:
    """Mutate one scenario object in place (plan §4.3 step 4): only
    level/shelf/courseUnitId/conceptIds(/backdrop when given) change --
    title/intro/dialog/quests/vocab/grammarIds/... are all preserved."""

    if str(scenario.get("level", "")).strip().lower() != move.from_level:
        raise RelevelError(
            f"scenarioMove {move.id!r}: scenario level {scenario.get('level')!r} "
            f"disagrees with move.from={move.from_level!r}"
        )
    scenario["level"] = move.to_level
    scenario["shelf"] = move.shelf
    scenario["courseUnitId"] = move.course_unit_id
    scenario["conceptIds"] = list(move.concept_ids)
    if move.backdrop is not None:
        scenario["backdrop"] = move.backdrop

    # grammarIds levels <= to-level, warn only (plan §4.3 step 1) -- a
    # scenario can legitimately keep using an *easier* grammar point after
    # moving up a level; one above the new level is a content smell, not a
    # blocking error, since Fable's judgment call may still be correct.
    grammar_ids = scenario.get("grammarIds")
    to_rank = LEVEL_ORDER[move.to_level]
    for grammar_id in grammar_ids if isinstance(grammar_ids, list) else ():
        if not isinstance(grammar_id, str):
            continue
        parts = grammar_id.split("_")
        grammar_level = parts[1] if len(parts) >= 2 else None
        grammar_rank = LEVEL_ORDER.get(grammar_level) if grammar_level else None
        if grammar_rank is not None and grammar_rank > to_rank:
            report.grammar_level_warnings.append(
                f"grammarId {grammar_id!r} is level {grammar_level!r}, above "
                f"the new level {move.to_level!r} (warn only)"
            )


def _migrate_curriculum_manifest_scenarios(
    curriculum: dict[str, Any],
    scenario_moves: tuple[ScenarioMove, ...],
    report: MigrationReport,
) -> None:
    """Plan §4.3 step 4(2): every contentLinks entry with contentKind==
    "scenario" and contentId==id gets courseUnitId/conceptIds updated; the
    moved id must not appear anywhere else in the manifest this tool does
    not handle (e.g. a courseUnit's checkpointContentIds)."""

    units = {
        unit["id"]: unit
        for unit in curriculum.get("courseUnits", [])
        if isinstance(unit, dict) and isinstance(unit.get("id"), str)
    }
    for move in scenario_moves:
        unit = units.get(move.course_unit_id)
        if unit is None:
            raise RelevelError(f"scenarioMove {move.id!r}: unknown courseUnitId {move.course_unit_id!r}")
        required = set(unit.get("requiredConceptIds") or [])
        missing = [c for c in move.concept_ids if c not in required]
        if missing:
            raise RelevelError(
                f"scenarioMove {move.id!r}: conceptIds {missing} are not in "
                f"{move.course_unit_id!r}.requiredConceptIds {sorted(required)}"
            )

    links = curriculum.get("contentLinks")
    if not isinstance(links, list):
        raise RelevelError("curriculum_manifest.json: contentLinks must be an array")
    by_id = {move.id: move for move in scenario_moves}
    updated_by_id: dict[str, int] = {move.id: 0 for move in scenario_moves}
    for link in links:
        if not isinstance(link, dict) or link.get("contentKind") != "scenario":
            continue
        move = by_id.get(link.get("contentId"))
        if move is None:
            continue
        link["courseUnitId"] = move.course_unit_id
        link["conceptIds"] = list(move.concept_ids)
        updated_by_id[move.id] += 1

    reports_by_id = {r.scenario_id: r for r in report.scenarios}
    for move in scenario_moves:
        pack_report = reports_by_id.get(move.id)
        if pack_report is not None:
            pack_report.content_links_updated = updated_by_id[move.id]

    # After the contentLinks rewrite above, the moved id must not appear
    # anywhere else in the manifest -- this tool only knows how to rewrite
    # contentLinks, so any other reference (a courseUnit's
    # checkpointContentIds "scenario:<id>", etc.) must fail closed rather
    # than silently go stale.
    rest = {k: v for k, v in curriculum.items() if k != "contentLinks"}
    text = json.dumps(rest, ensure_ascii=False)
    for move in scenario_moves:
        if move.id in text:
            raise RelevelError(
                f"scenarioMove {move.id!r}: appears elsewhere in curriculum_manifest.json "
                "outside contentLinks (e.g. checkpointContentIds) -- not handled by this tool"
            )


# ───────────────────────── can-do cluster/segment choice ──────────────────


def _unit_slug(course_unit_id: str) -> str:
    """``b1_06_life_capstone`` -> ``life_capstone`` (drop level + 2-digit order)."""

    return "_".join(course_unit_id.split("_")[2:])


def _cluster_slug(cluster_id: str) -> str:
    """``cluster_b1_life_course_narrative_v1`` -> ``life_course_narrative``
    (drop the ``cluster_`` prefix, the level token, and the ``_vN`` suffix)."""

    body = re.sub(r"^cluster_", "", cluster_id)
    body = re.sub(r"_v\d+$", "", body)
    return "_".join(body.split("_")[1:])


def _find_cluster_containing(
    clusters_by_id: dict[str, dict[str, Any]], kind: str, ident: str
) -> dict[str, Any] | None:
    for cluster in clusters_by_id.values():
        for ref in cluster.get("contentReferences", []):
            if isinstance(ref, dict) and ref.get("kind") == kind and ref.get("id") == ident:
                return cluster
    return None


def _segment_for_cluster(
    segments: list[dict[str, Any]], cluster_id: str
) -> dict[str, Any] | None:
    for segment in segments:
        if cluster_id in (segment.get("contentClusterIds") or []):
            return segment
    return None


def choose_target_cluster(
    segments: list[dict[str, Any]],
    clusters_by_id: dict[str, dict[str, Any]],
    target_unit: str,
    to_level: str,
    explicit_cluster_id: str | None = None,
) -> tuple[str, tuple[str, ...], str]:
    """Pick the contentCluster a moved vocabPack should join (plan §4.3 step
    6a): "find the contentCluster with level==to and the unit's concept/
    seed; if several, choose the one whose id contains the unit slug; report
    the choice."

    Candidates are every level==``to_level`` cluster owned (via
    ``segment.contentClusterIds``) by a level==``to_level`` segment whose
    ``parentCourseUnitId == target_unit``.

    When ``explicit_cluster_id`` is given (the bundle's ``canDoClusterId``,
    T2.3-R1 STEP 1b -- a Fable ruling), it must be one of these candidates
    (``RelevelError`` naming them otherwise); the note records this as an
    explicit ruling, not a guess.

    Otherwise a course unit routinely owns several segments/clusters (A2+
    segment ids are named after a scenario, not the unit -- see
    ``build_can_do_segments.py``'s ``AB_SPECS``), so "contains the unit
    slug" is implemented as a heuristic: most unit-slug tokens (``_``-split)
    shared with the candidate cluster's own slug wins; ties (including an
    all-zero-overlap tie) break by highest ``revision`` then lexicographic
    cluster id, both deterministic. Every heuristic choice's ``note`` starts
    with ``"HEURISTIC:"`` and, when non-unique, lists the candidates --
    this is a guess over genuinely ambiguous, unlabelled data, not a
    certainty, and Fable should confirm or supply an explicit ruling.
    """

    candidate_ids: list[str] = []
    for segment in segments:
        if segment.get("parentCourseUnitId") != target_unit or segment.get("level") != to_level:
            continue
        for cluster_id in segment.get("contentClusterIds") or []:
            cluster = clusters_by_id.get(cluster_id)
            if cluster is not None and cluster.get("level") == to_level:
                candidate_ids.append(cluster_id)
    if not candidate_ids:
        raise RelevelError(
            f"no level={to_level!r} contentCluster is owned by a segment with "
            f"parentCourseUnitId={target_unit!r}"
        )

    if explicit_cluster_id is not None:
        if explicit_cluster_id not in candidate_ids:
            raise RelevelError(
                f"canDoClusterId {explicit_cluster_id!r} is not one of the candidate "
                f"contentClusters for courseUnitId={target_unit!r} to={to_level!r}: "
                f"{candidate_ids}"
            )
        return explicit_cluster_id, tuple(candidate_ids), "explicit (Fable ruling)"

    if len(candidate_ids) == 1:
        return candidate_ids[0], tuple(candidate_ids), "HEURISTIC: unique candidate"

    unit_tokens = set(_unit_slug(target_unit).split("_"))

    def sort_key(cluster_id: str) -> tuple[int, int, str]:
        overlap = len(unit_tokens & set(_cluster_slug(cluster_id).split("_")))
        revision = int(clusters_by_id[cluster_id]["revision"])
        return (-overlap, -revision, cluster_id)

    ranked = sorted(candidate_ids, key=sort_key)
    best = ranked[0]
    best_overlap = len(unit_tokens & set(_cluster_slug(best).split("_")))
    note = (
        f"HEURISTIC: {len(candidate_ids)} candidates for unit slug tokens {sorted(unit_tokens)}; "
        f"chose {best!r} by slug-token overlap={best_overlap}, then revision desc, then id asc "
        "-- Fable should confirm this is the right canDo home"
    )
    return best, tuple(candidate_ids), note


# ───────────────────────── can-do JSON migration ───────────────────────────


def _migrate_can_do(
    authorities: dict[str, Any],
    segments_doc: dict[str, Any],
    moves: tuple[Move, ...],
    vocab_by_id: dict[str, dict[str, str]],
    report: MigrationReport,
) -> None:
    """Plan §4.3 step 6a/6b/6c inside the stage. ``vocab_by_id`` must already
    reflect the post-move level/pack_id (it is read from the CSV *after*
    ``_migrate_vocab`` has run) since the recomputed fingerprint has to match
    what ``check_can_do_consistency``/the Dart loader will see."""

    clusters = segments_doc.get("contentClusters")
    segments = segments_doc.get("segments")
    if not isinstance(clusters, list) or not isinstance(segments, list):
        raise RelevelError("can_do_segments.json: contentClusters/segments must be arrays")
    clusters_by_id = {c["id"]: c for c in clusters}

    direct_refs = authorities.get("contentReferences")
    if not isinstance(direct_refs, list):
        raise RelevelError("can_do_content_authorities.json: contentReferences must be a list")
    direct_by_key = {(r.get("kind"), r.get("id")): r for r in direct_refs if isinstance(r, dict)}

    coverage = authorities.get("coverage")
    if not isinstance(coverage, dict):
        raise RelevelError("can_do_content_authorities.json: coverage must be an object")
    inherited = coverage.get("inheritedContentReferences")
    if not isinstance(inherited, list):
        raise RelevelError("can_do_content_authorities.json: coverage.inheritedContentReferences must be a list")

    seeds = authorities.get("sourceSeeds")
    if not isinstance(seeds, list):
        raise RelevelError("can_do_content_authorities.json: sourceSeeds must be a list")
    seeds_by_id = {s.get("id"): s for s in seeds if isinstance(s, dict)}

    reports_by_bundle = {r.bundle: r for r in report.packs}

    for move in moves:
        direct = direct_by_key.get(("vocabPack", move.bundle))
        if direct is None:
            raise RelevelError(f"move {move.bundle!r}: no direct vocabPack authority reference")
        source_cluster = _find_cluster_containing(clusters_by_id, "vocabPack", move.bundle)
        if source_cluster is None:
            raise RelevelError(f"move {move.bundle!r}: no contentCluster references vocabPack {move.bundle!r}")

        target_cluster_id, candidates, note = choose_target_cluster(
            segments, clusters_by_id, move.course_unit_id, move.to_level,
            move.can_do_cluster_id,
        )
        target_cluster = clusters_by_id[target_cluster_id]
        target_segment = _segment_for_cluster(segments, target_cluster_id)
        if target_segment is None:
            raise RelevelError(f"move {move.bundle!r}: cluster {target_cluster_id!r} is owned by no segment")

        seed_id = direct.get("sourceSeedId")

        # 1. direct vocabPack authority row: id/level/courseUnitId only
        # (sourceSeedId is untouched -- plan §4.3 step 6a).
        direct["id"] = move.new_pack_id
        direct["level"] = move.to_level
        direct["courseUnitId"] = move.course_unit_id
        del direct_by_key[("vocabPack", move.bundle)]
        direct_by_key[("vocabPack", move.new_pack_id)] = direct

        # 2. cluster.contentReferences: move the one {kind, id} entry.
        source_refs = source_cluster["contentReferences"]
        moved = [r for r in source_refs if r.get("kind") == "vocabPack" and r.get("id") == move.bundle]
        if len(moved) != 1:
            raise RelevelError(
                f"move {move.bundle!r}: expected exactly one vocabPack contentReference "
                f"in {source_cluster['id']!r}, found {len(moved)}"
            )
        source_cluster["contentReferences"] = [r for r in source_refs if r is not moved[0]]
        moved[0]["id"] = move.new_pack_id
        target_cluster["contentReferences"].append(moved[0])

        # 3. cluster.sourceSeedIds: move the seed id string (its own text is
        # untouched -- it still spells the *old* pack id, matching plan
        # §4.3 step 6a's literal scope for the direct reference's
        # sourceSeedId field). Its *authority row*'s level must move to
        # to_level though: course_segment_catalog.dart's
        # _validateContentClusters requires every seed a cluster lists to
        # have exactly that cluster's own level ("source seed ... has level
        # X, expected Y" FormatException otherwise).
        source_seed_ids = source_cluster["sourceSeedIds"]
        if seed_id not in source_seed_ids:
            raise RelevelError(
                f"move {move.bundle!r}: seed {seed_id!r} not found in "
                f"{source_cluster['id']!r}.sourceSeedIds"
            )
        source_cluster["sourceSeedIds"] = [s for s in source_seed_ids if s != seed_id]
        target_cluster["sourceSeedIds"].append(seed_id)
        seed_authority = seeds_by_id.get(seed_id)
        if seed_authority is None:
            raise RelevelError(f"move {move.bundle!r}: seed {seed_id!r} has no sourceSeeds authority row")
        seed_authority["level"] = move.to_level

        # 4. bump both clusters' revision.
        source_cluster["revision"] = int(source_cluster["revision"]) + 1
        if target_cluster is not source_cluster:
            target_cluster["revision"] = int(target_cluster["revision"]) + 1

        # 5. inherited cloze/satz rows for this pack.
        pack_inherited = [r for r in inherited if r.get("sourceId") == move.bundle]
        if not pack_inherited:
            raise RelevelError(f"move {move.bundle!r}: no inherited coverage rows have sourceId={move.bundle!r}")
        for row in pack_inherited:
            row["sourceId"] = move.new_pack_id
            row["level"] = move.to_level
            row["courseUnitId"] = move.course_unit_id
            row["canDoSegmentId"] = target_segment["id"]
            vocab_row = vocab_by_id.get(row.get("sourceVocabId"))
            if vocab_row is None:
                raise RelevelError(
                    f"move {move.bundle!r}: inherited row {row.get('id')!r} references "
                    f"unknown vocab id {row.get('sourceVocabId')!r}"
                )
            row["sourceVocabFingerprintSha256"] = _fingerprint(vocab_row)

        pack_report = reports_by_bundle.get(move.bundle)
        if pack_report is not None:
            pack_report.source_cluster_id = source_cluster["id"]
            pack_report.target_cluster_id = target_cluster["id"]
            pack_report.target_segment_id = target_segment["id"]
            pack_report.cluster_choice_note = note
            pack_report.cluster_candidates = candidates

    # 6. recompute coverage counts exactly as the Dart loader counts them.
    direct_counts = Counter(r.get("kind") for r in direct_refs if isinstance(r, dict))
    recorded_direct = coverage.get("directReferenceCounts")
    if isinstance(recorded_direct, dict):
        coverage["directReferenceCounts"] = {
            kind: direct_counts.get(kind, 0) for kind in recorded_direct
        }
    inherited_counts = Counter(r.get("kind") for r in inherited if isinstance(r, dict))
    recorded_inherited = coverage.get("inheritedReferenceCounts")
    if isinstance(recorded_inherited, dict):
        coverage["inheritedReferenceCounts"] = {
            kind: inherited_counts.get(kind, 0) for kind in recorded_inherited
        }


def _find_cluster_containing_seed(
    clusters_by_id: dict[str, dict[str, Any]], seed_id: str
) -> dict[str, Any] | None:
    for cluster in clusters_by_id.values():
        if seed_id in (cluster.get("sourceSeedIds") or []):
            return cluster
    return None


def _migrate_can_do_scenarios(
    authorities: dict[str, Any],
    segments_doc: dict[str, Any],
    scenario_moves: tuple[ScenarioMove, ...],
    report: MigrationReport,
) -> None:
    """Plan §4.3 step 4(3): if can_do_content_authorities.json has a direct
    ``{kind:"scenario", id}`` reference, or a ``sourceSeeds`` row whose id
    *contains* the scenario id, migrate it like a vocabPack's direct
    reference (id/level/courseUnitId, cluster contentReferences +
    sourceSeedIds move to ``canDoClusterId`` with revision bumps, seed
    level, coverage counts) -- ``canDoClusterId`` is REQUIRED once any such
    reference exists (no heuristic fallback, unlike vocab-pack moves: a
    scenario's can-do home cannot be guessed from a slug-overlap score).
    A scenario with neither is a no-op here: "no can-do references" is
    reported and nothing in these two documents is touched (the L2a2 case).
    """

    clusters = segments_doc.get("contentClusters")
    segments = segments_doc.get("segments")
    if not isinstance(clusters, list) or not isinstance(segments, list):
        raise RelevelError("can_do_segments.json: contentClusters/segments must be arrays")
    clusters_by_id = {c["id"]: c for c in clusters}

    direct_refs = authorities.get("contentReferences")
    if not isinstance(direct_refs, list):
        raise RelevelError("can_do_content_authorities.json: contentReferences must be a list")
    direct_by_key = {(r.get("kind"), r.get("id")): r for r in direct_refs if isinstance(r, dict)}

    coverage = authorities.get("coverage")
    if not isinstance(coverage, dict):
        raise RelevelError("can_do_content_authorities.json: coverage must be an object")
    inherited = coverage.get("inheritedContentReferences")
    if not isinstance(inherited, list):
        raise RelevelError("can_do_content_authorities.json: coverage.inheritedContentReferences must be a list")

    seeds = authorities.get("sourceSeeds")
    if not isinstance(seeds, list):
        raise RelevelError("can_do_content_authorities.json: sourceSeeds must be a list")
    seeds_by_id = {s.get("id"): s for s in seeds if isinstance(s, dict)}

    reports_by_id = {r.scenario_id: r for r in report.scenarios}

    for move in scenario_moves:
        pack_report = reports_by_id.get(move.id)
        direct = direct_by_key.get(("scenario", move.id))
        seed_hits = [s for s in seeds if move.id in (s.get("id") or "")]
        if direct is None and not seed_hits:
            if pack_report is not None:
                pack_report.can_do_note = "no can-do references"
            continue

        if move.can_do_cluster_id is None:
            raise RelevelError(
                f"scenarioMove {move.id!r}: has can-do references, canDoClusterId is required"
            )
        target_cluster_id, _candidates, _note = choose_target_cluster(
            segments, clusters_by_id, move.course_unit_id, move.to_level,
            move.can_do_cluster_id,
        )
        target_cluster = clusters_by_id[target_cluster_id]
        target_segment = _segment_for_cluster(segments, target_cluster_id)
        if target_segment is None:
            raise RelevelError(f"scenarioMove {move.id!r}: cluster {target_cluster_id!r} is owned by no segment")

        source_cluster = None
        handled_seed_ids: set[str] = set()
        if direct is not None:
            source_cluster = _find_cluster_containing(clusters_by_id, "scenario", move.id)
            if source_cluster is None:
                raise RelevelError(
                    f"scenarioMove {move.id!r}: has a direct scenario authority reference "
                    "but no contentCluster references it"
                )
            seed_id = direct.get("sourceSeedId")

            direct["level"] = move.to_level
            direct["courseUnitId"] = move.course_unit_id

            source_refs = source_cluster["contentReferences"]
            moved_refs = [r for r in source_refs if r.get("kind") == "scenario" and r.get("id") == move.id]
            if len(moved_refs) != 1:
                raise RelevelError(
                    f"scenarioMove {move.id!r}: expected exactly one scenario contentReference "
                    f"in {source_cluster['id']!r}, found {len(moved_refs)}"
                )
            source_cluster["contentReferences"] = [r for r in source_refs if r is not moved_refs[0]]
            target_cluster["contentReferences"].append(moved_refs[0])

            if seed_id is not None and seed_id in source_cluster["sourceSeedIds"]:
                source_cluster["sourceSeedIds"] = [s for s in source_cluster["sourceSeedIds"] if s != seed_id]
                target_cluster["sourceSeedIds"].append(seed_id)
            seed_authority = seeds_by_id.get(seed_id)
            if seed_authority is not None:
                seed_authority["level"] = move.to_level
            handled_seed_ids.add(seed_id)

        # A seed whose id merely *contains* the scenario id but is not the
        # direct reference's own sourceSeedId: bump its own level, and if a
        # cluster happens to list it, relocate that listing too. Orphaned,
        # defensive data-hygiene path -- not exercised by any live scenario
        # today (every direct reference's sourceSeedId already textually
        # contains its scenario id).
        for seed in seed_hits:
            seed_id = seed.get("id")
            if seed_id in handled_seed_ids:
                continue
            seed["level"] = move.to_level
            owner = _find_cluster_containing_seed(clusters_by_id, seed_id)
            if owner is not None:
                owner["sourceSeedIds"] = [s for s in owner["sourceSeedIds"] if s != seed_id]
                target_cluster["sourceSeedIds"].append(seed_id)
                if owner is not target_cluster and owner is not source_cluster:
                    owner["revision"] = int(owner["revision"]) + 1

        if source_cluster is not None:
            source_cluster["revision"] = int(source_cluster["revision"]) + 1
        if target_cluster is not source_cluster:
            target_cluster["revision"] = int(target_cluster["revision"]) + 1

        if pack_report is not None:
            pack_report.can_do_note = (
                "migrated (direct reference)" if direct is not None else "migrated (orphaned seed only)"
            )
            pack_report.source_cluster_id = source_cluster["id"] if source_cluster is not None else None
            pack_report.target_cluster_id = target_cluster["id"]

    # Recompute coverage counts exactly as the Dart loader counts them --
    # unconditionally, even when every move above was a no-op, so a
    # scenario-only batch still leaves this document self-consistent.
    direct_counts = Counter(r.get("kind") for r in direct_refs if isinstance(r, dict))
    recorded_direct = coverage.get("directReferenceCounts")
    if isinstance(recorded_direct, dict):
        coverage["directReferenceCounts"] = {
            kind: direct_counts.get(kind, 0) for kind in recorded_direct
        }
    inherited_counts = Counter(r.get("kind") for r in inherited if isinstance(r, dict))
    recorded_inherited = coverage.get("inheritedReferenceCounts")
    if isinstance(recorded_inherited, dict):
        coverage["inheritedReferenceCounts"] = {
            kind: inherited_counts.get(kind, 0) for kind in recorded_inherited
        }


# ───────────────────────── can-do consistency check ───────────────────────


def check_can_do_consistency(stage_root: Path) -> list[str]:
    """Python re-implementation of the checks
    ``CanonicalCourseSegmentLoader`` (lib/services/
    canonical_course_segment_loader.dart:122-363) performs at app startup --
    run against the *stage*, before anything is copied back to the real
    repository, so a broken can-do graph fails ``relevel_bundle.py`` instead
    of failing at runtime in the app (plan §8 risk: "can-do 권한 파일 런타임
    FormatException").

    Returns an empty list iff the loader would accept
    ``can_do_segments.json``/``can_do_content_authorities.json`` as-is:
      1. union(cluster.sourceSeedIds) == set(sourceSeeds ids)
      2. union(cluster.contentReferences as "kind:id") == set(direct
         contentReferences as "kind:id")
      3. coverage.directReferenceCounts == counted contentReferences per kind
      4. for every inherited row: its child key is not also a direct key;
         its source is a direct vocabPack authority with the same level/
         courseUnitId recorded on the row; the live CSV row's fingerprint
         equals the row's sourceVocabFingerprintSha256; canDoSegmentId names
         a segment whose level/parentCourseUnitId match the row; that
         segment's own cluster(s) contain the source vocabPack reference
      5. coverage.inheritedReferenceCounts == actual inherited row counts
    """

    issues: list[str] = []
    data = stage_root / "assets" / "data"
    try:
        authorities = _read_json(data / CAN_DO_AUTHORITIES_JSON)
        segments_doc = _read_json(data / CAN_DO_SEGMENTS_JSON)
        vocab_rows = _load_vocab_csv(data / "korean_vocab.csv")
    except RelevelError as error:
        return [str(error)]

    vocab_by_id = {row["id"]: row for row in vocab_rows if row.get("id")}
    clusters = segments_doc.get("contentClusters")
    segments = segments_doc.get("segments")
    if not isinstance(clusters, list) or not isinstance(segments, list):
        return ["can_do_segments.json: contentClusters/segments must be arrays"]
    clusters_by_id = {
        c["id"]: c for c in clusters if isinstance(c, dict) and isinstance(c.get("id"), str)
    }
    segments_by_id = {
        s["id"]: s for s in segments if isinstance(s, dict) and isinstance(s.get("id"), str)
    }

    def ref_key(kind: Any, ident: Any) -> str:
        return f"{kind}:{ident}"

    # 1. seed coverage.
    expected_seed_ids = {
        seed_id for cluster in clusters for seed_id in cluster.get("sourceSeedIds", [])
    }
    seeds = authorities.get("sourceSeeds")
    if not isinstance(seeds, list):
        issues.append("can_do_content_authorities.json: sourceSeeds must be a list")
        seeds = []
    authority_seed_ids = {s.get("id") for s in seeds if isinstance(s, dict)}
    if expected_seed_ids != authority_seed_ids:
        issues.append(
            "seed coverage mismatch: only-in-clusters="
            f"{sorted(expected_seed_ids - authority_seed_ids)[:5]} only-in-authorities="
            f"{sorted(authority_seed_ids - expected_seed_ids)[:5]}"
        )
    seeds_by_id = {s.get("id"): s for s in seeds if isinstance(s, dict)}
    for cluster in clusters:
        cluster_level = cluster.get("level")
        for seed_id in cluster.get("sourceSeedIds", []):
            seed_authority = seeds_by_id.get(seed_id)
            if seed_authority is not None and seed_authority.get("level") != cluster_level:
                issues.append(
                    f"cluster {cluster.get('id')!r}: source seed {seed_id!r} has level "
                    f"{seed_authority.get('level')!r}, expected {cluster_level!r} "
                    "(course_segment_catalog.dart _validateContentClusters)"
                )

    # 2. reference-key coverage.
    expected_keys = {
        ref_key(ref.get("kind"), ref.get("id"))
        for cluster in clusters
        for ref in cluster.get("contentReferences", [])
        if isinstance(ref, dict)
    }
    direct_refs = authorities.get("contentReferences")
    if not isinstance(direct_refs, list):
        issues.append("can_do_content_authorities.json: contentReferences must be a list")
        direct_refs = []
    direct_by_key = {
        ref_key(r.get("kind"), r.get("id")): r for r in direct_refs if isinstance(r, dict)
    }
    if expected_keys != set(direct_by_key):
        issues.append(
            "content reference coverage mismatch: only-in-clusters="
            f"{sorted(expected_keys - set(direct_by_key))[:5]} only-in-authorities="
            f"{sorted(set(direct_by_key) - expected_keys)[:5]}"
        )

    # 3. directReferenceCounts.
    direct_counts = Counter(r.get("kind") for r in direct_refs if isinstance(r, dict))
    coverage = authorities.get("coverage")
    if not isinstance(coverage, dict):
        issues.append("can_do_content_authorities.json: coverage must be an object")
        coverage = {}
    recorded_direct = coverage.get("directReferenceCounts")
    actual_direct = {kind: direct_counts.get(kind, 0) for kind in (recorded_direct or {})}
    if recorded_direct != actual_direct:
        issues.append(
            f"coverage.directReferenceCounts mismatch: recorded={recorded_direct} actual={actual_direct}"
        )

    # 4. per inherited row, plus 5. inheritedReferenceCounts.
    inherited = coverage.get("inheritedContentReferences")
    if not isinstance(inherited, list):
        issues.append("can_do_content_authorities.json: coverage.inheritedContentReferences must be a list")
        inherited = []
    inherited_counts: Counter[Any] = Counter()
    for row in inherited:
        if not isinstance(row, dict):
            issues.append(f"inheritedContentReferences: non-object row {row!r}")
            continue
        row_id = row.get("id")
        child_key = ref_key(row.get("kind"), row_id)
        if child_key in direct_by_key:
            issues.append(f"inherited child {child_key!r} is also a direct reference")
            continue
        inherited_counts[row.get("kind")] += 1

        source = direct_by_key.get(ref_key("vocabPack", row.get("sourceId")))
        if source is None:
            issues.append(f"inherited row {row_id!r}: unknown vocabPack source {row.get('sourceId')!r}")
            continue
        if source.get("level") != row.get("level") or source.get("courseUnitId") != row.get("courseUnitId"):
            issues.append(
                f"inherited row {row_id!r}: source authority mismatch (source level="
                f"{source.get('level')!r} courseUnitId={source.get('courseUnitId')!r}, row level="
                f"{row.get('level')!r} courseUnitId={row.get('courseUnitId')!r})"
            )

        vocab_row = vocab_by_id.get(row.get("sourceVocabId"))
        if vocab_row is None or _fingerprint(vocab_row) != row.get("sourceVocabFingerprintSha256"):
            issues.append(
                f"inherited row {row_id!r}: sourceVocabFingerprintSha256 does not match "
                f"the live korean_vocab.csv row for {row.get('sourceVocabId')!r}"
            )

        segment = segments_by_id.get(row.get("canDoSegmentId"))
        if (
            segment is None
            or segment.get("level") != row.get("level")
            or segment.get("parentCourseUnitId") != row.get("courseUnitId")
        ):
            issues.append(
                f"inherited row {row_id!r}: canDoSegmentId {row.get('canDoSegmentId')!r} "
                "does not own this row's level/courseUnitId"
            )
            continue
        owns_source = any(
            any(
                ref.get("kind") == "vocabPack" and ref.get("id") == row.get("sourceId")
                for ref in clusters_by_id.get(cluster_id, {}).get("contentReferences", [])
            )
            for cluster_id in segment.get("contentClusterIds") or []
        )
        if not owns_source:
            issues.append(
                f"inherited row {row_id!r}: segment {segment['id']!r} does not own "
                f"source {row.get('sourceId')!r}"
            )

    recorded_inherited = coverage.get("inheritedReferenceCounts")
    actual_inherited = {kind: inherited_counts.get(kind, 0) for kind in (recorded_inherited or {})}
    if recorded_inherited != actual_inherited:
        issues.append(
            f"coverage.inheritedReferenceCounts mismatch: recorded={recorded_inherited} actual={actual_inherited}"
        )

    return issues


# ───────────────────────── Dart Map/Set literal editing ───────────────────
#
# vocab_pack_service.dart's packDisplayMap/packOrderInLevel and pack_artwork_
# catalog.dart's dedicatedPackIds are hand-maintained `const` literals, not
# generated files -- editing them means a *targeted* text transform that
# leaves every other byte alone, not a full Dart-source rewrite. Every entry
# in all three literals starts a line with `'<lowercase_snake_key>'`
# (verified against the real files during T2.3 research), so entries are
# found by that leading pattern and their value is captured by paren-depth
# scanning -- this handles single-line (`'key': ('DE', 'EN'),`), multi-line
# record, bare-int (`'key': 1,`), and bare-set (`'key',`) entries uniformly
# without needing to know which literal shape is in play.

_DART_KEY_START_RE = re.compile(r"(?m)^([ \t]*)'([a-z0-9_]+)'")


def _parse_dart_entries(body: str) -> tuple[list[str], list[tuple[str, str, str]]]:
    """Split a Dart Map/Set literal body into (connectives, entries).

    ``entries`` is ``(key, indent, value_text)`` in source order, where
    ``value_text`` is everything from right after the key's closing quote
    through the entry's own terminating comma (inclusive) -- ``: (...)  ,``
    for a record map entry, ``: 1,`` for an int map entry, or just ``,`` for
    a bare set entry. ``len(connectives) == len(entries) + 1``; the original
    ``body`` is
    ``connectives[0] + entries[0].value_text-joined-raw + connectives[1] + ...``
    i.e. ``"".join(indent+"'"+key+"'"+value for ... ) `` interleaved with
    ``connectives`` reconstructs it exactly (see ``_rebuild_dart_entries``).
    A comment or blank line between two entries lives in the connective
    *before* the later entry, so removing an entry can never drag a
    following section-header comment along with it, and inserting an entry
    right after an existing one can never push it past that comment either.
    """

    matches = list(_DART_KEY_START_RE.finditer(body))
    if not matches:
        return [body], []
    starts = [m.start() for m in matches]
    entries: list[tuple[str, str, str]] = []
    ends: list[int] = []
    for index, match in enumerate(matches):
        indent = match.group(1)
        key = match.group(2)
        limit = starts[index + 1] if index + 1 < len(starts) else len(body)
        cursor = match.end()
        if cursor < limit and body[cursor] == ":":
            cursor += 1
            while cursor < limit and body[cursor] in " \t\n":
                cursor += 1
            if cursor < limit and body[cursor] == "(":
                depth = 0
                while cursor < limit:
                    char = body[cursor]
                    if char == "(":
                        depth += 1
                        cursor += 1
                    elif char == ")":
                        depth -= 1
                        cursor += 1
                        if depth == 0:
                            break
                    else:
                        cursor += 1
            else:
                while cursor < limit and body[cursor] != ",":
                    cursor += 1
        if cursor < limit and body[cursor] == ",":
            cursor += 1
        entries.append((key, indent, body[match.end():cursor]))
        ends.append(cursor)
    connectives = [body[: starts[0]]]
    for index in range(len(starts)):
        next_start = starts[index + 1] if index + 1 < len(starts) else len(body)
        connectives.append(body[ends[index]: next_start])
    return connectives, entries


def _rebuild_dart_entries(connectives: list[str], entries: list[tuple[str, str, str]]) -> str:
    out = [connectives[0]]
    for (key, indent, value_text), connective in zip(entries, connectives[1:]):
        out.append(f"{indent}'{key}'{value_text}")
        out.append(connective)
    return "".join(out)


def dart_entry_exists(body: str, key: str) -> bool:
    _, entries = _parse_dart_entries(body)
    return any(existing_key == key for existing_key, _, _ in entries)


def dart_rename_entry(
    body: str,
    old_key: str,
    new_key: str,
    target_level: str,
    *,
    new_value_text: str | None = None,
) -> tuple[str, str]:
    """Rename ``old_key`` to ``new_key`` in a Dart Map/Set literal body,
    relocating the entry to just after the last existing entry whose key
    starts with ``{target_level}_`` (or to the very end if the target level
    has no entries yet). The value text is carried over byte-for-byte unless
    ``new_value_text`` overrides it (``packOrderInLevel`` needs a fresh
    ``: <int>,`` -- the old order number belongs to a different level's
    1..N sequence and would collide).

    Returns ``(new_body, old_value_text)`` -- the caller may want the old
    value (e.g. the ``(DE, EN)`` label, or the old order number) for its own
    report. Raises ``RelevelError`` if ``old_key`` is absent or ``new_key``
    is already present.
    """

    connectives, entries = _parse_dart_entries(body)
    old_index = next((i for i, (k, _, _) in enumerate(entries) if k == old_key), None)
    if old_index is None:
        raise RelevelError(f"Dart literal has no entry for key {old_key!r}")
    if any(k == new_key for k, _, _ in entries):
        raise RelevelError(f"Dart literal already has an entry for key {new_key!r}")
    _, indent, old_value_text = entries[old_index]
    value_text = old_value_text if new_value_text is None else new_value_text

    remaining_entries = entries[:old_index] + entries[old_index + 1:]
    remaining_connectives = connectives[:old_index] + connectives[old_index + 1:]

    anchor = None
    for index, (key, _, _) in enumerate(remaining_entries):
        if key.startswith(f"{target_level}_"):
            anchor = index
    new_entry = (new_key, indent, value_text)
    if anchor is None:
        new_entries = remaining_entries + [new_entry]
        new_connectives = remaining_connectives[:-1] + ["\n"] + [remaining_connectives[-1]]
    else:
        new_entries = remaining_entries[: anchor + 1] + [new_entry] + remaining_entries[anchor + 1:]
        new_connectives = (
            remaining_connectives[: anchor + 1] + ["\n"] + remaining_connectives[anchor + 1:]
        )
    return _rebuild_dart_entries(new_connectives, new_entries), old_value_text


def _max_order_for_level(order_body: str, level: str) -> int:
    _, entries = _parse_dart_entries(order_body)
    values = [
        int(match.group(1))
        for key, _, value_text in entries
        if key.startswith(f"{level}_")
        for match in (re.match(r":\s*(\d+)\s*,", value_text),)
        if match is not None
    ]
    return max(values) if values else 0


def _bump_order_entries(order_body: str, level: str, threshold: int) -> str:
    """+1 every ``packOrderInLevel`` entry whose key starts with
    ``{level}_`` and whose current order is ``>= threshold`` (T2.3-R1 STEP
    1c: an explicit ``packOrder`` move field is an insert-and-shift, not an
    append -- the caller inserts its own new entry at exactly ``threshold``
    right after calling this, so no other same-level entry may keep that
    value). Scans the whole map body (every level's entries live in one
    flat Dart map, interleaved), same as ``_max_order_for_level``."""

    connectives, entries = _parse_dart_entries(order_body)
    bumped_entries = []
    for key, indent, value_text in entries:
        if key.startswith(f"{level}_"):
            match = re.match(r":\s*(\d+)\s*,", value_text)
            if match is not None and int(match.group(1)) >= threshold:
                value_text = f": {int(match.group(1)) + 1},"
        bumped_entries.append((key, indent, value_text))
    return _rebuild_dart_entries(connectives, bumped_entries)


def _extract_dart_block(text: str, open_marker: str, close_pattern: str) -> tuple[str, str, str]:
    """(prefix-through-open-marker, block body, close-marker-through-suffix)."""

    if open_marker not in text:
        raise RelevelError(f"Dart source is missing the literal {open_marker!r}")
    start = text.index(open_marker) + len(open_marker)
    match = re.search(close_pattern, text[start:], re.M)
    if match is None:
        raise RelevelError(f"Dart source: no {close_pattern!r} found after {open_marker!r}")
    end = start + match.start()
    return text[:start], text[start:end], text[end:]


DISPLAY_MAP_OPEN = "static const Map<String, (String, String)> packDisplayMap = {"
ORDER_MAP_OPEN = "static const Map<String, int> packOrderInLevel = {"
ARTWORK_SET_OPEN = "static const dedicatedPackIds = <String>{"
_CLOSE_BRACE_RE = r"^  \};"


def edit_vocab_pack_service(text: str, moves: tuple[Move, ...], report: MigrationReport) -> str:
    """plan §4.3 step 7: rename ``packDisplayMap``/``packOrderInLevel`` base
    keys, preserving the (DE, EN) label and moving each renamed order entry
    to ``max(existing order for the target level) + 1``."""

    before, display_body, middle = _extract_dart_block(text, DISPLAY_MAP_OPEN, _CLOSE_BRACE_RE)
    for move in moves:
        old_key, new_key = pack_base(move.bundle), pack_base(move.new_pack_id)
        display_body, _ = dart_rename_entry(display_body, old_key, new_key, move.to_level)
        report.dart_display_map_renames.append((old_key, new_key))
    text = before + display_body + middle

    before2, order_body, after2 = _extract_dart_block(text, ORDER_MAP_OPEN, _CLOSE_BRACE_RE)
    new_keys_in_order: list[tuple[str, str]] = []
    for move in moves:
        old_key, new_key = pack_base(move.bundle), pack_base(move.new_pack_id)
        if move.pack_order is not None:
            order_body = _bump_order_entries(order_body, move.to_level, move.pack_order)
            new_order = move.pack_order
        else:
            new_order = _max_order_for_level(order_body, move.to_level) + 1
        order_body, _ = dart_rename_entry(
            order_body, old_key, new_key, move.to_level, new_value_text=f": {new_order},",
        )
        new_keys_in_order.append((old_key, new_key))

    # T2.3-R2: a later move's explicit `packOrder` insert can `_bump_order_
    # entries` an *earlier* move's already-inserted entry right back out of
    # the slot this loop just recorded for it (two same-level inserts where
    # the second one's target is <= the first one's) -- so the report must
    # re-read each renamed key's FINAL value from the fully-edited map,
    # never the value that was only true at the moment its own move ran.
    _, final_entries = _parse_dart_entries(order_body)
    final_order_by_key = {
        key: int(match.group(1))
        for key, _, value_text in final_entries
        for match in (re.match(r":\s*(\d+)\s*,", value_text),)
        if match is not None
    }
    for old_key, new_key in new_keys_in_order:
        report.dart_order_map_renames.append((old_key, new_key, final_order_by_key[new_key]))
    return before2 + order_body + after2


def edit_pack_artwork_catalog(
    text: str, moves: tuple[Move, ...], report: MigrationReport
) -> str:
    """plan §4.3 step 7: rename exact ids present in ``dedicatedPackIds``.

    A pack absent from the set has no dedicated artwork -- nothing to edit
    for it (``PackArtworkCatalog.assetFor`` falls back to the Dancheong
    motif stamp, unaffected by a pack-id rename)."""

    before, body, after = _extract_dart_block(text, ARTWORK_SET_OPEN, _CLOSE_BRACE_RE)
    for move in moves:
        if not dart_entry_exists(body, move.bundle):
            for pack_report in report.packs:
                if pack_report.bundle == move.bundle:
                    pack_report.has_dedicated_artwork = False
            continue
        body, _ = dart_rename_entry(body, move.bundle, move.new_pack_id, move.to_level)
        report.dart_artwork_renames.append((move.bundle, move.new_pack_id))
        for pack_report in report.packs:
            if pack_report.bundle == move.bundle:
                pack_report.has_dedicated_artwork = True
    return before + body + after


MOTIF_SWITCH_OPEN = "return switch (base) {"


def edit_dancheong_motifs(text: str, moves: tuple[Move, ...], report: MigrationReport) -> str:
    """T2.3-R1/R2 STEP 1d: rename base-id string literals inside
    ``motifForPackId``'s switch (lib/widgets/sori/dancheong_stamp.dart) so a
    moved pack keeps its dedicated Dancheong motif instead of silently
    falling back to a different one when its base id no longer matches any
    case.

    Patterns are a single literal (``'<base>' => <motif>,``) or an
    OR-joined list (``'<base>' || '<other>' => <motif>,``, possibly split
    across lines) -- only the exact quoted old base id is swapped for the
    new one, byte-for-byte everywhere else (including any other side of an
    OR pattern), since a plain substring match on the quoted token can never
    collide with a *longer* base id that merely starts with the same text
    (its closing quote sits in a different place: the quote that closes
    ``'a2_housing_search'`` never lines up with the ``_`` that follows the
    same prefix inside ``'a2_housing_search_2026'``). A base id absent from
    the switch is not an error -- that pack has no dedicated motif entry
    and already falls through to ``_``; this is recorded, not raised.

    Dart's ``_baseOf`` strips only ONE trailing all-digit segment, so a
    base id that itself ends in one (a "_2026" revision year, most often)
    is ambiguous: a sibling live pack id with no further numeric suffix
    bases to ``pack_base(old_base)`` instead of ``old_base`` itself. The
    switch already pairs both shapes in one OR-group (e.g.
    ``'a2_housing_search' || 'a2_housing_search_2026' => ...``) wherever
    this applies, so once the primary literal is renamed, also rename its
    generic sibling -- ``pack_base(old_base)`` to ``pack_base(new_base)``
    -- inside this same switch body, but only when that stripped form
    actually differs from ``old_base`` (most base ids do not end in a
    digit segment at all) and is actually present."""

    before, body, after = _extract_dart_block(text, MOTIF_SWITCH_OPEN, _CLOSE_BRACE_RE)
    for move in moves:
        old_base, new_base = pack_base(move.bundle), pack_base(move.new_pack_id)
        old_literal = f"'{old_base}'"
        if old_literal not in body:
            report.dancheong_motif_renames.append((old_base, new_base, "no motif entry"))
            continue
        body = body.replace(old_literal, f"'{new_base}'", 1)
        report.dancheong_motif_renames.append((old_base, new_base, "renamed"))

        generic_old, generic_new = pack_base(old_base), pack_base(new_base)
        if generic_old == old_base:
            continue  # old_base doesn't end in a digit segment -- no ambiguity to cover
        generic_literal = f"'{generic_old}'"
        if generic_literal not in body:
            continue  # this family has no paired generic-form entry -- nothing to rename
        body = body.replace(generic_literal, f"'{generic_new}'", 1)
        report.dancheong_motif_renames.append((generic_old, generic_new, "renamed (generic sibling)"))
    return before + body + after


def rename_artwork_files(
    moves: tuple[Move, ...], report: MigrationReport, artwork_asset_dir: Path = ARTWORK_ASSET_DIR
) -> None:
    """Physically rename the WebP each renamed ``dedicatedPackIds`` entry
    points to (``PackArtworkCatalog.assetFor`` derives ``<packId>.webp``
    from the id -- the id and the filename must move together)."""

    renamed_ids = {old for old, _ in report.dart_artwork_renames}
    for move in moves:
        if move.bundle not in renamed_ids:
            continue
        source = artwork_asset_dir / f"{move.bundle}.webp"
        target = artwork_asset_dir / f"{move.new_pack_id}.webp"
        if not source.exists():
            raise RelevelError(f"move {move.bundle!r}: dedicated artwork {source} is missing on disk")
        if target.exists():
            raise RelevelError(f"move {move.bundle!r}: artwork target {target} already exists")
        os.rename(source, target)
        report.artwork_files_renamed.append((move.bundle, move.new_pack_id))


# ───────────────────────── pack authoring source sync (T2.9a) ─────────────
#
# tools/content_factory/data/packs/<packId>.json is the archived, per-pack
# authoring source build_level_content_4x.load_packs() reads (Batch 09/10's
# 4x vocab-pack expansion only -- not every bundle move has one of these;
# most packs, e.g. the partner-family ones, were authored some other way
# and simply have no file here). Before this task, a pack-level relevel
# left this file's packId/level/unit/concept pointing at the pack's OLD
# identity forever -- load_packs()'s own cross-check against live
# korean_vocab.csv (test_level_content_4x.PackSourceTest.
# test_authored_packs_are_unique_korea_level_sets) then saw the pack's
# words as if they belonged to some *other*, untracked live pack_id (the
# new one), and flagged them as a headword collision against themselves.


def sync_pack_source_files(
    moves: tuple[Move, ...], report: MigrationReport, pack_source_dir: Path = PACK_SOURCE_DIR,
) -> None:
    """Rename+update each moved pack's archived authoring source (if any):
    ``<bundle>.json`` -> ``<newPackId>.json``, with ``packId``/``level``/
    ``unit``/``concept`` rewritten to the pack's new identity. ``unit``/
    ``concept`` are this schema's (singular) names for what a Move's
    ``courseUnitId``/``conceptIds`` are elsewhere in this module.

    Deliberately narrow, mirroring _migrate_scenario_object's "only routing
    fields change" policy: the 12 authored ``words`` rows themselves (and
    ``orderInLevel``, a purely archival "the Nth pack authored at its
    *original* level" note with no live-content role -- nothing reads it
    outside this file's own internal sort) are left untouched, even for a
    word tool/relevel_vocab.py later relevel-moves out of or into this
    exact pack; that per-word ledger is not replayed against this frozen
    authoring snapshot (see task T2.9a's report for the reasoning).

    A bundle whose ``<bundle>.json`` does not exist here is a silent no-op
    -- exactly like rename_artwork_files() skips a pack with no dedicated
    artwork. Idempotent: a bundle already synced (its old-named file
    already renamed away) is a no-op too, on either call site below --
    ``migrate()``'s own apply step, or a retroactive `--sync-pack-sources`
    replay of a bundle that already went through ``migrate()`` once, with
    or without this step existing yet.
    """

    reports_by_bundle = {pack.bundle: pack for pack in report.packs}
    for move in moves:
        source_path = pack_source_dir / f"{move.bundle}.json"
        pack_report = reports_by_bundle.get(move.bundle)
        if not source_path.exists():
            continue
        if pack_report is not None:
            pack_report.has_pack_source = True
        payload = _read_json(source_path)
        if not isinstance(payload, dict):
            raise RelevelError(f"pack source {source_path}: root must be an object")
        if payload.get("packId") != move.bundle:
            raise RelevelError(
                f"pack source {source_path}: packId {payload.get('packId')!r} != "
                f"move bundle {move.bundle!r}"
            )
        if payload.get("level") != move.from_level:
            raise RelevelError(
                f"pack source {source_path}: level {payload.get('level')!r} != "
                f"move from={move.from_level!r}"
            )
        if len(move.concept_ids) != 1:
            raise RelevelError(
                f"move {move.bundle!r}: pack source {source_path} has a single 'concept' "
                f"field, but this move's conceptIds has {len(move.concept_ids)} entries "
                f"{list(move.concept_ids)!r} -- cannot sync it unambiguously"
            )
        target_path = pack_source_dir / f"{move.new_pack_id}.json"
        if target_path.exists():
            raise RelevelError(
                f"move {move.bundle!r}: pack source sync target {target_path} already exists"
            )
        payload["packId"] = move.new_pack_id
        payload["level"] = move.to_level
        payload["unit"] = move.course_unit_id
        payload["concept"] = move.concept_ids[0]
        _write_json(target_path, payload)
        source_path.unlink()
        report.pack_sources_synced.append((move.bundle, move.new_pack_id))


def sync_pack_sources(
    bundle: BundleFile, *, root: Path = ROOT, apply: bool,
) -> MigrationReport:
    """Standalone entry point (task T2.9a part (b)): retroactively apply
    sync_pack_source_files() to a bundle whose pack moves already landed in
    assets/data via migrate() before this sync step existed (LCP PR-L2a
    batches L2a, L2a3) -- CLI: ``--sync-pack-sources [--apply]``.

    Touches only tools/content_factory/data/packs/ -- never assets/data,
    the ledger, or any Dart/``.py`` source -- so replaying an
    already-migrated bundle here is safe (idempotent per
    sync_pack_source_files's own docstring), and a dry run is a pure
    read-only preview (``has_pack_source`` alone; nothing under apply-only
    branches runs).
    """

    pack_source_dir = root / "tools" / "content_factory" / "data" / "packs"
    report = MigrationReport(batch=f"{bundle.batch}-sync-pack-sources")
    for move in bundle.moves:
        report.packs.append(PackMoveReport(
            bundle=move.bundle, new_pack_id=move.new_pack_id,
            from_level=move.from_level, to_level=move.to_level,
            course_unit_id=move.course_unit_id,
        ))
    for pack_report in report.packs:
        pack_report.has_pack_source = (pack_source_dir / f"{pack_report.bundle}.json").exists()
    if apply:
        sync_pack_source_files(bundle.moves, report, pack_source_dir)
    return report


# ───────────────────────── canonical scenario source sync (T2.9a) ─────────
#
# A scenario move (ScenarioMove) previously patched only the *live*
# scenario object (_migrate_scenario_object above). The canonical_120_v1
# pipeline's own upstream sources -- canonical_scenarios/authored/<level>.
# json (raw ko/de/en dialog; materialize_canonical_scenarios.py's "sole
# semantic source"), canonical_scenarios/scenario_briefs.json (level/
# portfolioBucket/courseUnitId routing brief), and the materialized
# review/canonical_120_v1/candidates/<level>/<id>.json candidate itself --
# were left describing the scenario's *old* level. scenario_corpus_pipeline
# .preflight_corpus() stages a fresh corpus from exactly that candidates
# directory and cross-checks it against relevel_ledger.json, so a stale
# candidate there fails with "ledger to=X does not match live scenario
# level Y" even though the *live* scenario (assets/data/scenarios_*.json)
# was already correctly moved. Worse: a future `materialize_canonical_
# scenarios.py` re-run from the stale authored/briefs sources would
# regenerate the *same* wrong-level candidate again.
#
# All three sync functions below are graceful no-ops when their target
# directory/file does not exist at all -- not every scenarioMove
# necessarily has a canonical_120_v1-pipeline source (a test fixture that
# never provisions canonical_scenarios/, or a scenario moved before that
# pipeline existed), matching sync_pack_source_files' same philosophy for
# a bundle move with no data/packs/ source.


def _balanced_object_spans(text: str, start: int = 0, end: int | None = None) -> list[tuple[int, int]]:
    """Every top-level ``{...}`` object's ``(start, end)`` span within
    ``text[start:end]``, in source order, tracked with a string-aware
    brace depth counter -- a ``{``/``}``/``,`` inside a quoted string
    (Korean dialogue, an escaped quote) never miscounts."""

    if end is None:
        end = len(text)
    spans: list[tuple[int, int]] = []
    index = start
    while index < end:
        if text[index] != "{":
            index += 1
            continue
        span_start = index
        depth = 0
        in_string = False
        escape = False
        while index < end:
            ch = text[index]
            if in_string:
                if escape:
                    escape = False
                elif ch == "\\":
                    escape = True
                elif ch == '"':
                    in_string = False
            else:
                if ch == '"':
                    in_string = True
                elif ch == "{":
                    depth += 1
                elif ch == "}":
                    depth -= 1
                    if depth == 0:
                        index += 1
                        spans.append((span_start, index))
                        break
            index += 1
        else:
            raise RelevelError(f"unbalanced braces scanning a JSON object starting at {span_start}")
    return spans


def _locate_scenarios_array(text: str, path: Path) -> tuple[int, int]:
    """Return the ``(start, end)`` span of a canonical_scenarios/authored/
    <level>.json file's top-level ``"scenarios": [...]`` array *body*
    (just inside its own brackets, not including ``[``/``]`` themselves),
    with a string-aware bracket-depth scan (same reasoning as
    ``_balanced_object_spans``)."""

    marker = '"scenarios": ['
    marker_pos = text.find(marker)
    if marker_pos == -1:
        raise RelevelError(f'{path}: could not find a "scenarios": [ array')
    open_pos = marker_pos + len(marker) - 1
    depth = 0
    in_string = False
    escape = False
    index = open_pos
    while index < len(text):
        ch = text[index]
        if in_string:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
        else:
            if ch == '"':
                in_string = True
            elif ch == "[":
                depth += 1
            elif ch == "]":
                depth -= 1
                if depth == 0:
                    return open_pos + 1, index
        index += 1
    raise RelevelError(f'{path}: unbalanced brackets in "scenarios" array')


def _remove_json_array_entry(array_body: str, ident: str) -> tuple[str, str, str]:
    """Remove one ``{"id": "<ident>", ...}`` top-level object from a JSON
    array's body text, returning ``(new_body, entry_text, indent)`` --
    ``entry_text`` is that object's exact original text (byte-for-byte,
    starting at its own ``{``, no leading indentation) for re-insertion
    elsewhere via ``_append_json_array_entry``, and ``indent`` is the
    exact leading whitespace that preceded it on its own line (so the
    caller can reproduce it there too). Every *other* entry's formatting
    is fully preserved -- unlike a ``json.loads()``/``json.dumps()`` round
    trip, which would collapse this file's hand-formatted single-line
    title/intro/dialog-turn objects into full multi-line ``indent=2``
    blocks (T2.9a: the bug this function exists to avoid)."""

    anchor = f'"id": "{ident}"'
    for start, stop in _balanced_object_spans(array_body):
        if anchor not in array_body[start:stop]:
            continue
        entry_text = array_body[start:stop]
        line_start = array_body.rfind("\n", 0, start) + 1
        indent = array_body[line_start:start]
        after = array_body[stop:]
        after_lstripped = after.lstrip()
        if after_lstripped.startswith(","):
            # Not the array's last entry: drop this whole line (back to its
            # own leading indentation) through the trailing comma that
            # follows its closing brace, plus that comma's own trailing
            # newline, so no blank line is left behind.
            comma_pos = stop + (len(after) - len(after_lstripped))
            rest = array_body[comma_pos + 1:]
            newline_pos = rest.find("\n")
            remainder = rest[newline_pos + 1:] if newline_pos != -1 else ""
            new_body = array_body[:line_start] + remainder
        else:
            # The array's last entry (no trailing comma of its own): strip
            # the *previous* entry's now-dangling trailing comma instead.
            prefix = array_body[:line_start]
            prefix_rstripped = prefix.rstrip()
            if prefix_rstripped.endswith(","):
                prefix = prefix_rstripped[:-1] + prefix[len(prefix_rstripped):]
            new_body = prefix + after
        return new_body, entry_text, indent
    raise RelevelError(f"id {ident!r} not found in canonical authored source")


def _append_json_array_entry(array_body: str, entry_text: str, indent: str) -> str:
    """Insert ``entry_text`` (an exact span from ``_remove_json_array_entry``)
    as the new last element of a JSON array's body text, reproducing the
    same ``,\\n<indent>`` separator every other entry already uses."""

    spans = _balanced_object_spans(array_body)
    if not spans:
        raise RelevelError("cannot append to a canonical authored source with zero scenarios")
    _, last_end = spans[-1]
    return array_body[:last_end] + ",\n" + indent + entry_text + array_body[last_end:]


def sync_canonical_authored_scenarios(
    scenario_moves: tuple[ScenarioMove, ...],
    report: MigrationReport,
    authored_dir: Path = CANONICAL_AUTHORED_DIR,
) -> None:
    """Move each relocated scenario's raw ko/de/en dialog entry between
    canonical_scenarios/authored/<level>.json's ``scenarios`` arrays,
    unedited (id/title/intro/dialog only -- this file carries no level/
    shelf/courseUnitId/conceptIds fields of its own to route; those are
    scenario_briefs.json's/the candidate's job, below). Edits the array's
    source text directly (``_remove_json_array_entry``/
    ``_append_json_array_entry``) rather than a full JSON parse+rewrite,
    so every untouched scenario's hand-collapsed formatting survives
    byte-for-byte -- the same reasoning as ``edit_scenario_briefs_source``.
    """

    if not authored_dir.exists():
        return
    reports_by_id = {r.scenario_id: r for r in report.scenarios}
    by_from_level: dict[str, list[ScenarioMove]] = {}
    for move in scenario_moves:
        by_from_level.setdefault(move.from_level, []).append(move)

    removed_entries: dict[str, tuple[str, str]] = {}
    for from_level, moves in by_from_level.items():
        path = authored_dir / f"{from_level}.json"
        text = _normalize_newlines(path.read_text(encoding="utf-8"))
        array_start, array_end = _locate_scenarios_array(text, path)
        body = text[array_start:array_end]
        for move in moves:
            body, entry_text, indent = _remove_json_array_entry(body, move.id)
            removed_entries[move.id] = (entry_text, indent)
            pack_report = reports_by_id.get(move.id)
            if pack_report is not None:
                pack_report.canonical_authored_note = (
                    f"authored/{from_level}.json -> authored/{move.to_level}.json"
                )
        text = text[:array_start] + body + text[array_end:]
        path.write_bytes(text.encode("utf-8"))

    entries_by_to_level: dict[str, list[tuple[str, str]]] = {}
    for move in scenario_moves:
        entries_by_to_level.setdefault(move.to_level, []).append(removed_entries[move.id])

    for to_level, entries in entries_by_to_level.items():
        path = authored_dir / f"{to_level}.json"
        text = _normalize_newlines(path.read_text(encoding="utf-8"))
        array_start, array_end = _locate_scenarios_array(text, path)
        body = text[array_start:array_end]
        for entry_text, indent in entries:
            body = _append_json_array_entry(body, entry_text, indent)
        text = text[:array_start] + body + text[array_end:]
        path.write_bytes(text.encode("utf-8"))


def _bucket_for_shelf(level: str, shelf: str) -> str:
    """Reverse-lookup materialize_canonical_scenarios.SHELF_BY_BUCKET[level]
    for the (single, unambiguous) portfolioBucket that derives ``shelf`` --
    excluding that table's catch-all "regression" bucket, which no real
    relevel targets and which can otherwise collide with a real bucket for
    the same shelf slug (e.g. a2's "study_work_digital_media" and
    "regression" both derive "a2_work")."""

    table = materializer.SHELF_BY_BUCKET.get(level)
    if table is None:
        raise RelevelError(
            f"materialize_canonical_scenarios.SHELF_BY_BUCKET has no level {level!r}"
        )
    candidates = [bucket for bucket, value in table.items() if value == shelf and bucket != "regression"]
    if len(candidates) != 1:
        raise RelevelError(
            f"cannot uniquely resolve a portfolioBucket for level={level!r} shelf={shelf!r} "
            f"in materialize_canonical_scenarios.SHELF_BY_BUCKET (candidates={candidates!r})"
        )
    return candidates[0]


_SCENARIO_BRIEF_LINE_RE = re.compile(r'^(\s*)(\{"id":"([^"]+)".*\})(,?)\s*$')


def edit_scenario_briefs_source(
    text: str, scenario_moves: tuple[ScenarioMove, ...], report: MigrationReport,
) -> str:
    """Rewrite each moved scenario's one-line brief entry in
    canonical_scenarios/scenario_briefs.json's hand-authored, one-compact-
    JSON-object-per-line format: level/portfolioBucket/courseUnitId only --
    titleKo/setting/relationship/mustIncludeKo/... untouched (the same
    "only routing fields change" policy as _migrate_scenario_object).
    Line-based, not a full json.loads()/json.dumps() round trip of the
    whole (7000+ line) file, so every untouched entry's exact formatting
    survives byte-for-byte -- the same approach this module already uses
    for shelf_assignment.py/build_can_do_segments.py.

    portfolioBucket is *derived*, not authored here: see
    _bucket_for_shelf -- so the materializer, re-run later, reproduces the
    exact shelf this move already committed the live scenario to.
    """

    if not scenario_moves:
        return text
    by_id = {move.id: move for move in scenario_moves}
    reports_by_id = {r.scenario_id: r for r in report.scenarios}
    found: set[str] = set()
    lines = text.split("\n")
    for index, line in enumerate(lines):
        match = _SCENARIO_BRIEF_LINE_RE.match(line)
        if match is None:
            continue
        indent, obj_text, scenario_id, trailing_comma = match.groups()
        move = by_id.get(scenario_id)
        if move is None:
            continue
        entry = json.loads(obj_text)
        if entry.get("level") != move.from_level:
            raise RelevelError(
                f"scenarioMove {move.id!r}: scenario_briefs.json level "
                f"{entry.get('level')!r} disagrees with move.from={move.from_level!r}"
            )
        bucket = _bucket_for_shelf(move.to_level, move.shelf)
        entry["level"] = move.to_level
        entry["portfolioBucket"] = bucket
        entry["courseUnitId"] = move.course_unit_id
        rebuilt = json.dumps(entry, ensure_ascii=False, separators=(",", ":"))
        lines[index] = f"{indent}{rebuilt}{trailing_comma}"
        found.add(scenario_id)
        pack_report = reports_by_id.get(scenario_id)
        if pack_report is not None:
            pack_report.scenario_brief_note = f"level={move.to_level!r} portfolioBucket={bucket!r}"
    missing = sorted(set(by_id) - found)
    if missing:
        raise RelevelError(f"scenario_briefs.json: scenario id(s) not found: {missing}")
    return "\n".join(lines)


def sync_review_candidate_scenarios(
    scenario_moves: tuple[ScenarioMove, ...],
    report: MigrationReport,
    candidates_dir: Path = REVIEW_CANDIDATES_DIR,
) -> None:
    """Move+patch each relocated scenario's materialized review candidate
    (review/canonical_120_v1/candidates/<level>/<id>.json) exactly the way
    _migrate_scenario_object() patches the live scenario object: its
    ``scenario`` sub-object's level/shelf/courseUnitId/conceptIds only --
    title/intro/dialog/quests/vocab/grammarIds/xpReward/emoji/... all stay
    untouched, so a later materialize_canonical_scenarios.py re-run from
    the now-synced canonical_scenarios/ source reproduces this exact file.

    A missing candidate for one particular scenario (not every
    scenarioMove's id necessarily has one) is its own graceful per-move
    no-op, distinct from `candidates_dir` not existing at all.
    """

    if not candidates_dir.exists():
        return
    reports_by_id = {r.scenario_id: r for r in report.scenarios}
    for move in scenario_moves:
        source_path = candidates_dir / move.from_level / f"{move.id}.json"
        if not source_path.exists():
            continue
        payload = _read_json(source_path)
        scenario = payload.get("scenario")
        if not isinstance(scenario, dict):
            raise RelevelError(f"{source_path}: scenario must be an object")
        if str(scenario.get("level", "")).strip().lower() != move.from_level:
            raise RelevelError(
                f"scenarioMove {move.id!r}: candidate level {scenario.get('level')!r} "
                f"disagrees with move.from={move.from_level!r}"
            )
        scenario["level"] = move.to_level
        scenario["shelf"] = move.shelf
        scenario["courseUnitId"] = move.course_unit_id
        scenario["conceptIds"] = list(move.concept_ids)
        target_path = candidates_dir / move.to_level / f"{move.id}.json"
        if target_path.exists():
            raise RelevelError(
                f"scenarioMove {move.id!r}: review candidate target {target_path} already exists"
            )
        target_path.parent.mkdir(parents=True, exist_ok=True)
        _write_json(target_path, payload)
        source_path.unlink()
        report.review_candidates_synced.append((move.id, move.from_level, move.to_level))
        pack_report = reports_by_id.get(move.id)
        if pack_report is not None:
            pack_report.review_candidate_note = f"{move.from_level}/ -> {move.to_level}/{move.id}.json"


# ───────────────────────── shelf_assignment.py editing (PR-L2a2) ──────────
#
# ``shelf_assignment.ASSIGNMENT``'s shape is the same editing problem as the
# Dart Map literals above -- a hand-maintained ``"key": (tuple, of, quoted,
# strings),`` literal with embedded comments -- so this reuses the exact
# same entry-parsing strategy, just with Python's double-quoted keys
# instead of Dart's single-quoted ones (a fresh, tiny parser rather than
# parameterizing ``_parse_dart_entries``/``_rebuild_dart_entries``, so nothing
# about the already-proven Dart editing path changes).

_PY_DOUBLE_QUOTE_KEY_START_RE = re.compile(r'(?m)^([ \t]*)"([a-z0-9_]+)"')


def _parse_py_dict_entries(body: str) -> tuple[list[str], list[tuple[str, str, str]]]:
    """Same contract as ``_parse_dart_entries``, for a double-quoted-key
    Python dict literal body (``shelf_assignment.ASSIGNMENT``).

    Unlike every Dart literal this module edits (each entry always sits on
    one line: ``'key': (...)  ,`` or bare ``'key',``), ``ASSIGNMENT``'s
    values are *multi-line* tuples whose own elements are themselves
    quoted strings starting their own line (``"a1_bus_late",`` indented
    under ``"a1_transit": (``) -- those element lines would themselves
    false-match a naive "every regex hit is a new top-level key" scan
    (``_parse_dart_entries``'s ``finditer``-then-slice approach). This
    walks the body sequentially instead: each entry's own paren-depth scan
    determines exactly where its value ends, and the *next* search starts
    only from there, so an element line nested inside an still-open value
    is consumed as part of that value and never independently matched.
    """

    entries: list[tuple[str, str, str]] = []
    connectives: list[str] = []
    cursor = 0
    section_start = 0
    while True:
        match = _PY_DOUBLE_QUOTE_KEY_START_RE.search(body, cursor)
        if match is None:
            break
        indent = match.group(1)
        key = match.group(2)
        value_end = match.end()
        if value_end < len(body) and body[value_end] == ":":
            value_end += 1
            while value_end < len(body) and body[value_end] in " \t\n":
                value_end += 1
            if value_end < len(body) and body[value_end] == "(":
                depth = 0
                while value_end < len(body):
                    char = body[value_end]
                    if char == "(":
                        depth += 1
                        value_end += 1
                    elif char == ")":
                        depth -= 1
                        value_end += 1
                        if depth == 0:
                            break
                    else:
                        value_end += 1
            else:
                while value_end < len(body) and body[value_end] != ",":
                    value_end += 1
        if value_end < len(body) and body[value_end] == ",":
            value_end += 1
        connectives.append(body[section_start: match.start()])
        entries.append((key, indent, body[match.end(): value_end]))
        section_start = value_end
        cursor = value_end
    connectives.append(body[section_start:])
    return connectives, entries


def _rebuild_py_dict_entries(connectives: list[str], entries: list[tuple[str, str, str]]) -> str:
    out = [connectives[0]]
    for (key, indent, value_text), connective in zip(entries, connectives[1:]):
        out.append(f'{indent}"{key}"{value_text}')
        out.append(connective)
    return "".join(out)


def _remove_string_from_py_tuple(value_text: str, item: str) -> str:
    token = f'"{item}"'
    if token not in value_text:
        raise RelevelError(f"{item!r} not found in tuple text {value_text!r}")
    index = value_text.index(token)
    before, after = value_text[:index], value_text[index + len(token):]
    after_stripped = after.lstrip(" \t")
    if after_stripped.startswith(","):
        after = after_stripped[1:]
    else:
        before = before.rstrip(" \t")
        if before.endswith(","):
            before = before[:-1]
    return before + after


def _add_string_to_py_tuple(value_text: str, item: str) -> str:
    """Insert ``item`` right after the last existing element's trailing
    comma (every element in this file's style, including the last, already
    ends with one) -- avoids having to reproduce this tuple's own
    per-shelf line-wrapping/indentation style to append cleanly."""

    close_index = value_text.rindex(")")
    cursor = close_index
    while cursor > 0 and value_text[cursor - 1] in " \t\n":
        cursor -= 1
    return value_text[:cursor] + f' "{item}",' + value_text[cursor:]


def edit_shelf_assignment_source(
    text: str, scenario_moves: tuple[ScenarioMove, ...], report: MigrationReport,
) -> str:
    """Plan §4.3 step 4(4): if ``shelf_assignment.ASSIGNMENT`` (equivalently
    ``SHELF_BY_ID``) already has an entry for a moved scenario id, relocate
    it from its current shelf's tuple to the move's target shelf's tuple.
    Reports either way, per the plan: most scenarios have never been
    entered into this appendix table at all (``ContentValidator`` validates
    each scenario's own ``shelf`` field, not this table -- see
    ``shelf_assignment.py``'s own docstring, "SHELF_BY_ID 는 은퇴한 레거시
    코퍼스의 불변 이관 지도"), so "not tracked, no update" is the common,
    expected outcome, not a failure.
    """

    if not scenario_moves:
        return text
    before, body, after = _extract_dart_block(
        text, "ASSIGNMENT: dict[str, tuple[str, ...]] = {", r"^\}",
    )
    connectives, entries = _parse_py_dict_entries(body)
    entries_by_key = {key: index for index, (key, _, _) in enumerate(entries)}
    reports_by_id = {r.scenario_id: r for r in report.scenarios}

    for move in scenario_moves:
        pack_report = reports_by_id.get(move.id)
        token = f'"{move.id}"'
        source_index = next(
            (i for i, (_, _, value_text) in enumerate(entries) if token in value_text), None,
        )
        if source_index is None:
            if pack_report is not None:
                pack_report.shelf_assignment_note = "not tracked in shelf_assignment.py ASSIGNMENT -- no update"
            continue
        if move.shelf not in entries_by_key:
            raise RelevelError(
                f"scenarioMove {move.id!r}: shelf_assignment.py ASSIGNMENT has no "
                f"entry for target shelf {move.shelf!r}"
            )
        source_key, source_indent, source_value = entries[source_index]
        entries[source_index] = (source_key, source_indent, _remove_string_from_py_tuple(source_value, move.id))
        target_index = entries_by_key[move.shelf]
        target_key, target_indent, target_value = entries[target_index]
        entries[target_index] = (target_key, target_indent, _add_string_to_py_tuple(target_value, move.id))
        if pack_report is not None:
            pack_report.shelf_assignment_note = f"moved {source_key!r} -> {move.shelf!r}"

    return before + _rebuild_py_dict_entries(connectives, entries) + after


# ───────────────────────── build_can_do_segments.py editing (PR-L2a2) ─────


def edit_build_can_do_segments_source(
    text: str, scenario_moves: tuple[ScenarioMove, ...], report: MigrationReport,
) -> str:
    """Plan §4.3 step 4(5): a ``_scenario_spec(...)`` entry in ``AB_SPECS``
    at the FROM level that lists a moved scenario id is removed; if
    ``AB_SPECS`` already anchors the TO-level target course unit (some spec
    whose ``parent==courseUnitId`` and ``level==to``), a fresh
    ``_scenario_spec`` entry for the moved id is inserted right after the
    *last* such anchor (by source order). Otherwise the id is only removed
    (report only) -- the moved scenario stays safely routed by
    ``UNIT_DEFAULT_ROUTE`` fallback either way (``_expand_ab_practice``'s
    scenario loop), it just has no *explicit* AB_SPECS anchor of its own.

    ``build_can_do_segments.py``'s own generator (``build_assets()``) is
    frozen post-``canonical_120_v1`` (``test_build_can_do_segments.py``'s
    ``CanDoSegmentGeneratorTest`` is entirely ``skipIf``'d there) -- this
    edit exists to keep ``AB_SPECS``/``A1_PRACTICE`` consistent with the
    live scenario corpus for ``ABSpecScenarioReferencesLiveTest`` (which is
    *not* skipped), not because the frozen generator runs day to day. A
    removed key some *other* routing table (``UNIT_DEFAULT_ROUTE``/
    ``PACK_ROUTES``/...) still points at by name is therefore only
    reported, not repaired here.
    """

    if not scenario_moves:
        return text
    tree = ast.parse(text)
    ab_specs_value = None
    for node in ast.walk(tree):
        if (
            isinstance(node, ast.AnnAssign)
            and isinstance(node.target, ast.Name)
            and node.target.id == "AB_SPECS"
            and isinstance(node.value, ast.Tuple)
        ):
            ab_specs_value = node.value
            break
    if ab_specs_value is None:
        raise RelevelError("build_can_do_segments.py: cannot find `AB_SPECS: ... = (...)`")

    def _spec_info(node: ast.expr) -> dict[str, Any] | None:
        if (
            not isinstance(node, ast.Call) or not isinstance(node.func, ast.Name)
            or node.func.id not in ("_scenario_spec", "_named_spec")
            or len(node.args) < 3
            or not all(isinstance(node.args[i], ast.Constant) for i in (0, 1, 2))
        ):
            return None
        return {
            "call": node, "func": node.func.id, "key": node.args[0].value,
            "level": node.args[1].value, "parent": node.args[2].value,
        }

    specs = [info for elt in ab_specs_value.elts for info in (_spec_info(elt),) if info is not None]
    known_keys = {info["key"] for info in specs}

    lines = text.split("\n")
    deletions: list[tuple[int, int]] = []
    insertions: list[tuple[int, str]] = []
    reports_by_id = {r.scenario_id: r for r in report.scenarios}

    for move in scenario_moves:
        pack_report = reports_by_id.get(move.id)
        removed = next(
            (
                info for info in specs
                if info["func"] == "_scenario_spec" and info["level"] == move.from_level
                and len(info["call"].args) >= 4 and isinstance(info["call"].args[3], ast.Constant)
                and info["call"].args[3].value == move.id
            ),
            None,
        )
        note_parts: list[str] = []
        if removed is None:
            note_parts.append("not present in AB_SPECS")
        else:
            deletions.append((removed["call"].lineno, removed["call"].end_lineno))
            note_parts.append(f"removed key={removed['key']!r} (from-level {move.from_level!r})")
            if text.count(f'"{removed["key"]}"') > 1:
                note_parts.append(
                    f"NOTE: {removed['key']!r} is still referenced elsewhere in this file "
                    "(e.g. UNIT_DEFAULT_ROUTE/PACK_ROUTES) -- harmless while the generator "
                    "is frozen, worth a look if it is ever unfrozen"
                )

            anchor = None
            for info in specs:
                if info["parent"] == move.course_unit_id and info["level"] == move.to_level and (
                    anchor is None or info["call"].lineno > anchor["call"].lineno
                ):
                    anchor = info
            if anchor is None:
                note_parts.append(
                    f"no AB_SPECS anchor at {move.to_level!r}/{move.course_unit_id!r} "
                    "-- relies on UNIT_DEFAULT_ROUTE fallback only"
                )
            else:
                new_key = f"{move.to_level}_{move.id}"
                suffix = 2
                while new_key in known_keys:
                    new_key = f"{move.to_level}_{move.id}_{suffix}"
                    suffix += 1
                known_keys.add(new_key)
                mode_arg = (
                    removed["call"].args[4].value
                    if len(removed["call"].args) >= 5 and isinstance(removed["call"].args[4], ast.Constant)
                    else None
                )
                indent = re.match(r"[ \t]*", lines[anchor["call"].lineno - 1]).group(0)
                mode_text = f', "{mode_arg}"' if mode_arg is not None else ""
                new_line = (
                    f'{indent}_scenario_spec("{new_key}", "{move.to_level}", '
                    f'"{move.course_unit_id}", "{move.id}"{mode_text}),'
                )
                insertions.append((anchor["call"].end_lineno, new_line))
                note_parts.append(f"added key={new_key!r} after anchor={anchor['key']!r}")

        if pack_report is not None:
            pack_report.ab_specs_note = "; ".join(note_parts)

    edits = [(start, "delete", end) for start, end in deletions]
    edits += [(after_line, "insert", new_text) for after_line, new_text in insertions]
    for anchor_line, kind, payload in sorted(edits, key=lambda e: e[0], reverse=True):
        if kind == "delete":
            del lines[anchor_line - 1: payload]
        else:
            lines.insert(anchor_line, payload)
    return "\n".join(lines)


# ───────────────────────── progress aliases (Dart) ─────────────────────────


ALIASES_HEADER = (
    "// Auto-appended by tools/content_factory/relevel_bundle.py -- do not hand-edit.\n"
    "//\n"
    "// A relevel changes a vocab pack's `pack_id` (plan §3.E), so a learner's\n"
    "// stored PackProgress under the *old* id would otherwise look unrelated\n"
    "// to the pack under its *new* id. `{new: old}` lets\n"
    "// lib/services/pack_progress_service.dart carry that progress forward\n"
    "// once (T2.6 wires the actual lookup; this file only holds the data).\n"
    "const Map<String, String> kPackProgressAliases = {\n"
    "};\n"
)


def append_pack_progress_aliases(path: Path, moves: tuple[Move, ...], report: MigrationReport) -> None:
    # write_bytes throughout (never write_text/open(path, "a")): on Windows
    # both translate "\n" -> "\r\n" (T2.3-R1 STEP 1a).
    if not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(ALIASES_HEADER.encode("utf-8"))
    text = _normalize_newlines(path.read_bytes().decode("utf-8"))
    before, body, after = _extract_dart_block(text, "kPackProgressAliases = {", r"^\};")
    for move in moves:
        if dart_entry_exists(body, move.new_pack_id):
            raise RelevelError(f"pack_progress_aliases.dart already has an entry for {move.new_pack_id!r}")
        stripped = body.rstrip("\n")
        body = stripped + f"\n  '{move.new_pack_id}': '{move.bundle}',\n"
        report.aliases_added.append((move.new_pack_id, move.bundle))
    path.write_bytes((before + body + after).encode("utf-8"))


# ───────────────────────── test-reference grep ─────────────────────────────


def find_test_references(root: Path, old_ids: list[str]) -> dict[str, list[str]]:
    """For every old pack id, every ``test/`` or ``tools/`` file (source
    only) that mentions it literally -- plan §4.3 step 8/9: Fable must
    review these by hand since a pack-id rename does not auto-update a
    hard-coded string literal in a test."""

    hits: dict[str, list[str]] = {ident: [] for ident in old_ids}
    search_dirs = [root / "test", root / "tools" / "content_factory"]
    for base in search_dirs:
        if not base.exists():
            continue
        for path in sorted(base.rglob("*")):
            if not path.is_file() or path.suffix not in (".dart", ".py"):
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError):
                continue
            relative = path.relative_to(root).as_posix()
            for ident in old_ids:
                if ident in text:
                    hits[ident].append(relative)
    return hits


# ───────────────────────── orchestration ───────────────────────────────────


_SCENARIO_SHARD_NAMES = tuple(scenario_store.shard_name(level) for level in LOWER_LEVELS)

# All six scenario shards are always listed here, not just the from/to
# levels a given bundle's scenarioMoves touch: scenario_store.write_shards()
# rewrites every shard from the merged in-memory list every time it runs
# (it is the *only* writer this codebase allows -- see scenario_store.py's
# own docstring), and for a `moves`-only bundle (no scenarioMoves,
# write_shards() never called) the stage's shard bytes are simply an
# untouched copy of the originals, so copying them "back" is a real write
# of byte-identical content -- a no-op in effect, not a behavior change.
_STAGED_DATA_FILES = (
    "korean_vocab.csv", CLOZE_JSON, SATZ_JSON, CURRICULUM_JSON,
    CAN_DO_AUTHORITIES_JSON, CAN_DO_SEGMENTS_JSON, *_SCENARIO_SHARD_NAMES,
)


def _atomic_write_bytes(path: Path, content: bytes) -> None:
    temporary = path.with_name(f".{path.name}.relevel-bundle.tmp")
    try:
        temporary.write_bytes(content)
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def migrate(
    *,
    root: Path = ROOT,
    bundle: BundleFile,
    ledger_path: Path = DEFAULT_LEDGER_PATH,
    apply: bool,
) -> MigrationReport:
    """Run every move in ``bundle`` as one staged, all-or-nothing transaction
    (plan §4.3). Always builds and validates the stage (so a dry run proves
    the moves are safe); only writes back to ``root``/``ledger_path``/the
    Dart files when ``apply`` is true and the stage is clean.

    Every real-repository path this function writes to (the Dart files, the
    artwork directory) is derived from ``root`` rather than the module-level
    ``ROOT``-anchored constants, so a test can pass a temp-directory ``root``
    without ever touching this checkout's actual Dart sources.
    """

    vocab_pack_service_path = root / "lib" / "services" / "vocab_pack_service.dart"
    pack_artwork_catalog_path = root / "lib" / "data" / "pack_artwork_catalog.dart"
    dancheong_stamp_path = root / "lib" / "widgets" / "sori" / "dancheong_stamp.dart"
    pack_progress_aliases_path = root / "lib" / "data" / "pack_progress_aliases.dart"
    artwork_asset_dir = root / "assets" / "illustrations" / "packs"
    # Root-relative, like the three Dart paths above (and for the same
    # reason -- a test must be able to sandbox its own throwaway copies of
    # these instead of ever touching this checkout's real .py sources).
    shelf_assignment_path = root / "tools" / "content_factory" / "shelf_assignment.py"
    build_can_do_segments_path = root / "tools" / "content_factory" / "build_can_do_segments.py"
    pack_source_dir = root / "tools" / "content_factory" / "data" / "packs"
    canonical_authored_dir = root / "tools" / "content_factory" / "canonical_scenarios" / "authored"
    scenario_briefs_path = root / "tools" / "content_factory" / "canonical_scenarios" / "scenario_briefs.json"
    review_candidates_dir = root / "tools" / "content_factory" / "review" / "canonical_120_v1" / "candidates"

    ledger = relevel_ledger.load_ledger(ledger_path)
    report = MigrationReport(batch=bundle.batch)
    for move in bundle.moves:
        report.packs.append(PackMoveReport(
            bundle=move.bundle, new_pack_id=move.new_pack_id,
            from_level=move.from_level, to_level=move.to_level,
            course_unit_id=move.course_unit_id,
        ))
    for scenario_move in bundle.scenario_moves:
        report.scenarios.append(ScenarioMoveReport(
            scenario_id=scenario_move.id, from_level=scenario_move.from_level,
            to_level=scenario_move.to_level, course_unit_id=scenario_move.course_unit_id,
            shelf=scenario_move.shelf,
        ))

    with tempfile.TemporaryDirectory(prefix="relevel-bundle-") as directory:
        stage = Path(directory) / "repo"
        shutil.copytree(root / "assets" / "data", stage / "assets" / "data")
        stage_manifest_dir = stage / "tools" / "content_factory"
        stage_manifest_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy2(
            root / "tools" / "content_factory" / "content_audit_manifest.json",
            stage_manifest_dir / "content_audit_manifest.json",
        )
        grammar_mirror_target = stage / "functions" / "analyze_korean_text" / "grammar_patterns.json"
        grammar_mirror_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(
            root / "functions" / "analyze_korean_text" / "grammar_patterns.json",
            grammar_mirror_target,
        )
        data = stage / "assets" / "data"

        vocab_rows = _load_vocab_csv(data / "korean_vocab.csv")
        cloze_root = _read_json(data / CLOZE_JSON)
        satz_root = _read_json(data / SATZ_JSON)
        curriculum = _read_json(data / CURRICULUM_JSON)
        authorities = _read_json(data / CAN_DO_AUTHORITIES_JSON)
        segments_doc = _read_json(data / CAN_DO_SEGMENTS_JSON)

        cloze_items = cloze_root.get("items") if isinstance(cloze_root, dict) else None
        satz_items = satz_root.get("items") if isinstance(satz_root, dict) else None
        if not isinstance(cloze_items, list) or not isinstance(satz_items, list):
            raise RelevelError("cloze.json/satz_sentences.json must contain an items array")

        moved_vocab_ids_by_move: dict[str, set[str]] = {}
        moved_cloze_by_move: dict[str, list[dict[str, Any]]] = {}

        for move in bundle.moves:
            matched_vocab, example_ko, korean, ledger = _migrate_vocab(vocab_rows, move, ledger, bundle.batch)
            moved_vocab_ids_by_move[move.bundle] = {row["id"] for row in matched_vocab}
            matched_cloze, ledger = _migrate_cloze(cloze_items, move, example_ko, ledger, bundle.batch)
            matched_satz, ledger = _migrate_satz(satz_items, move, korean, ledger, bundle.batch)
            moved_cloze_by_move[move.bundle] = matched_cloze

            pack_report = next(p for p in report.packs if p.bundle == move.bundle)
            pack_report.n_words = len(matched_vocab)
            pack_report.n_cloze = len(matched_cloze)
            pack_report.n_satz = len(matched_satz)

        _refresh_game_meta(cloze_root, "items")
        _refresh_game_meta(satz_root, "items")

        _migrate_curriculum_manifest(
            curriculum, bundle.moves, moved_vocab_ids_by_move, moved_cloze_by_move, cloze_items, report,
        )
        _migrate_curriculum_manifest_scenarios(curriculum, bundle.scenario_moves, report)

        vocab_by_id = {row["id"]: row for row in vocab_rows if row.get("id")}
        _migrate_can_do(authorities, segments_doc, bundle.moves, vocab_by_id, report)
        _migrate_can_do_scenarios(authorities, segments_doc, bundle.scenario_moves, report)

        scenarios_list: list[dict[str, Any]] | None = None
        if bundle.scenario_moves:
            scenarios_root = scenario_store.load_root(data)
            scenarios_list = scenarios_root.get("scenarios")
            if not isinstance(scenarios_list, list):
                raise RelevelError("scenario shards: root must contain a scenarios array")
            scenarios_by_id = {
                s["id"]: s for s in scenarios_list
                if isinstance(s, dict) and isinstance(s.get("id"), str)
            }
            scenario_reports_by_id = {r.scenario_id: r for r in report.scenarios}
            for scenario_move in bundle.scenario_moves:
                scenario = scenarios_by_id.get(scenario_move.id)
                if scenario is None:
                    raise RelevelError(
                        f"scenarioMove {scenario_move.id!r}: no scenario with this id in the live shards"
                    )
                _migrate_scenario_object(scenario, scenario_move, scenario_reports_by_id[scenario_move.id])
                ledger = ledger.append(LedgerEntry(
                    id=scenario_move.id, kind="scenario", from_level=scenario_move.from_level,
                    to_level=scenario_move.to_level, movedAt=date.today().isoformat(),
                    batch=bundle.batch, reason=scenario_move.reason,
                ))
            scenario_store.write_shards(scenarios_list, data)

        _write_vocab_csv(data / "korean_vocab.csv", vocab_rows)
        _write_json(data / CLOZE_JSON, cloze_root)
        _write_json(data / SATZ_JSON, satz_root)
        _write_json(data / CURRICULUM_JSON, curriculum)
        _write_json(data / CAN_DO_AUTHORITIES_JSON, authorities)
        _write_json(data / CAN_DO_SEGMENTS_JSON, segments_doc)

        cando_issues = check_can_do_consistency(stage)
        content_issues = ContentValidator(stage, ledger=ledger).validate()
        if cando_issues or content_issues:
            detail = "\n".join(
                [f"can-do: {issue}" for issue in cando_issues]
                + [f"{issue.source}: {issue.message}" for issue in content_issues]
            )
            raise RelevelError(f"staged relevel failed validation:\n{detail}")

        # Read-only artwork lookup (this Dart source lives outside assets/data,
        # so it is not part of the staged/validated content tree) -- computed
        # in both dry-run and apply so the printed plan is accurate either way.
        artwork_text = pack_artwork_catalog_path.read_text(encoding="utf-8")
        _, artwork_body, _ = _extract_dart_block(artwork_text, ARTWORK_SET_OPEN, _CLOSE_BRACE_RE)
        for pack_report in report.packs:
            pack_report.has_dedicated_artwork = dart_entry_exists(artwork_body, pack_report.bundle)
            pack_report.has_pack_source = (pack_source_dir / f"{pack_report.bundle}.json").exists()

        # Same read-only-preview reasoning as the artwork lookup above, for
        # the two scenario-move side files: a dry run should show the same
        # shelf_assignment.py/AB_SPECS notes --apply would produce, not
        # leave them blank until the real write. (--apply repeats this
        # same, deterministic computation once more just below when it
        # actually writes the files -- a little redundant CPU, not a
        # behavior difference, and far simpler than threading the
        # computed text through to be reused there.)
        if bundle.scenario_moves:
            shelf_preview = edit_shelf_assignment_source(
                _normalize_newlines(shelf_assignment_path.read_text(encoding="utf-8")),
                bundle.scenario_moves, report,
            )
            del shelf_preview  # preview only -- never written outside --apply
            ab_specs_preview = edit_build_can_do_segments_source(
                _normalize_newlines(build_can_do_segments_path.read_text(encoding="utf-8")),
                bundle.scenario_moves, report,
            )
            del ab_specs_preview
            # Unlike the two .py sources above, scenario_briefs.json is
            # optional here (task T2.9a): not every root provisioning
            # scenario moves also provisions canonical_scenarios/ (e.g. the
            # existing ScenarioRelevelBundleFixture test root does not), so
            # this preview -- like sync_canonical_authored_scenarios/
            # sync_review_candidate_scenarios' own apply-time calls below --
            # is a graceful no-op when the file is absent, not a hard
            # requirement.
            if scenario_briefs_path.exists():
                briefs_preview = edit_scenario_briefs_source(
                    _normalize_newlines(scenario_briefs_path.read_text(encoding="utf-8")),
                    bundle.scenario_moves, report,
                )
                del briefs_preview

        if not apply:
            return report

        outputs = {
            root / "assets" / "data" / name: (data / name).read_bytes()
            for name in _STAGED_DATA_FILES
        }
        dart_paths = (vocab_pack_service_path, pack_artwork_catalog_path, dancheong_stamp_path)
        # Read/written only when there is a scenario move to act on -- a
        # `moves`-only bundle (the existing PR-L2a shape, still exercised by
        # test fixtures that never provision these two .py files at all)
        # must not require shelf_assignment.py/build_can_do_segments.py to
        # exist at `root` when it has no reason to touch either.
        py_source_paths = (shelf_assignment_path, build_can_do_segments_path) if bundle.scenario_moves else ()
        # Only the moved bundles that actually have one of these (most do
        # not -- see sync_pack_source_files) are captured, so a bundle with
        # zero pack sources touches nothing extra here, same as py_source_paths.
        pack_source_paths = tuple(
            path for move in bundle.moves
            if (path := pack_source_dir / f"{move.bundle}.json").exists()
        )
        # Canonical scenario source sync (task T2.9a) -- see the "canonical
        # scenario source sync" section above for what each syncs and why
        # every one of these three is optional (graceful no-op) rather
        # than a hard requirement like py_source_paths' two files.
        canonical_authored_paths = ()
        scenario_briefs_paths = ()
        review_candidate_source_paths = ()
        if bundle.scenario_moves:
            if canonical_authored_dir.exists():
                touched_levels = {
                    level for move in bundle.scenario_moves for level in (move.from_level, move.to_level)
                }
                canonical_authored_paths = tuple(
                    path for level in touched_levels
                    if (path := canonical_authored_dir / f"{level}.json").exists()
                )
            if scenario_briefs_path.exists():
                scenario_briefs_paths = (scenario_briefs_path,)
            if review_candidates_dir.exists():
                review_candidate_source_paths = tuple(
                    path for move in bundle.scenario_moves
                    if (path := review_candidates_dir / move.from_level / f"{move.id}.json").exists()
                )
        originals = {
            path: path.read_bytes()
            for path in (
                *outputs, *dart_paths, *py_source_paths, *pack_source_paths,
                *canonical_authored_paths, *scenario_briefs_paths, *review_candidate_source_paths,
            )
        }
        ledger_existed = ledger_path.exists()
        ledger_original = ledger_path.read_bytes() if ledger_existed else None
        aliases_existed = pack_progress_aliases_path.exists()
        aliases_original = pack_progress_aliases_path.read_bytes() if aliases_existed else None

        def _rollback() -> None:
            for path, content in originals.items():
                _atomic_write_bytes(path, content)
            if ledger_original is not None:
                _atomic_write_bytes(ledger_path, ledger_original)
            elif ledger_path.exists():
                ledger_path.unlink()
            if aliases_original is not None:
                _atomic_write_bytes(pack_progress_aliases_path, aliases_original)
            elif pack_progress_aliases_path.exists():
                pack_progress_aliases_path.unlink()
            for old_id, new_id in report.artwork_files_renamed:
                new_path = artwork_asset_dir / f"{new_id}.webp"
                old_path = artwork_asset_dir / f"{old_id}.webp"
                if new_path.exists() and not old_path.exists():
                    os.rename(new_path, old_path)
            # The `originals` loop above already restores each synced pack
            # source's *old*-named file from its captured pre-mutation
            # bytes; it never touches the *new*-named file sync_pack_source_
            # files() created, which did not exist before this transaction.
            for _old_bundle, new_pack_id in report.pack_sources_synced:
                new_path = pack_source_dir / f"{new_pack_id}.json"
                if new_path.exists():
                    new_path.unlink()
            # Same reasoning as the pack-source cleanup just above:
            # canonical_authored_paths/scenario_briefs_paths are restored by
            # the generic `originals` loop (existing files edited in
            # place), but sync_review_candidate_scenarios() writes a *new*
            # <to_level>/<id>.json that never existed before this
            # transaction -- delete it too.
            for scenario_id, _from_level, to_level in report.review_candidates_synced:
                new_path = review_candidates_dir / to_level / f"{scenario_id}.json"
                if new_path.exists():
                    new_path.unlink()

        try:
            for path, content in outputs.items():
                _atomic_write_bytes(path, content)
            final_issues = ContentValidator(root, ledger=ledger).validate()
            if final_issues:
                detail = "\n".join(f"{issue.source}: {issue.message}" for issue in final_issues)
                raise RelevelError(f"post-write content validation failed:\n{detail}")

            ledger.save(ledger_path)

            new_vps_text = edit_vocab_pack_service(
                _normalize_newlines(originals[vocab_pack_service_path].decode("utf-8")),
                bundle.moves, report,
            )
            _atomic_write_bytes(vocab_pack_service_path, new_vps_text.encode("utf-8"))

            new_pac_text = edit_pack_artwork_catalog(
                _normalize_newlines(originals[pack_artwork_catalog_path].decode("utf-8")),
                bundle.moves, report,
            )
            _atomic_write_bytes(pack_artwork_catalog_path, new_pac_text.encode("utf-8"))
            rename_artwork_files(bundle.moves, report, artwork_asset_dir)
            sync_pack_source_files(bundle.moves, report, pack_source_dir)

            new_dancheong_text = edit_dancheong_motifs(
                _normalize_newlines(originals[dancheong_stamp_path].decode("utf-8")),
                bundle.moves, report,
            )
            _atomic_write_bytes(dancheong_stamp_path, new_dancheong_text.encode("utf-8"))

            append_pack_progress_aliases(pack_progress_aliases_path, bundle.moves, report)

            if bundle.scenario_moves:
                new_shelf_text = edit_shelf_assignment_source(
                    _normalize_newlines(originals[shelf_assignment_path].decode("utf-8")),
                    bundle.scenario_moves, report,
                )
                _atomic_write_bytes(shelf_assignment_path, new_shelf_text.encode("utf-8"))

                new_ab_specs_text = edit_build_can_do_segments_source(
                    _normalize_newlines(originals[build_can_do_segments_path].decode("utf-8")),
                    bundle.scenario_moves, report,
                )
                _atomic_write_bytes(build_can_do_segments_path, new_ab_specs_text.encode("utf-8"))

                # Canonical scenario source sync (task T2.9a). Each is its
                # own graceful no-op when its target is absent at `root`
                # (see the "canonical scenario source sync" section above),
                # so this never requires canonical_scenarios/ or the
                # review candidates directory to exist, unlike the two .py
                # sources just above.
                sync_canonical_authored_scenarios(bundle.scenario_moves, report, canonical_authored_dir)
                if scenario_briefs_path.exists():
                    new_briefs_text = edit_scenario_briefs_source(
                        _normalize_newlines(originals[scenario_briefs_path].decode("utf-8")),
                        bundle.scenario_moves, report,
                    )
                    _atomic_write_bytes(scenario_briefs_path, new_briefs_text.encode("utf-8"))
                sync_review_candidate_scenarios(bundle.scenario_moves, report, review_candidates_dir)
        except Exception as error:
            rollback_error = None
            try:
                _rollback()
            except OSError as failure:
                rollback_error = failure
            suffix = f"; ROLLBACK ALSO FAILED: {rollback_error}" if rollback_error else " (rolled back)"
            raise RelevelError(f"relevel --apply failed: {error}{suffix}") from error

        report.test_references = find_test_references(root, [move.bundle for move in bundle.moves])
        return report


# ───────────────────────── plan / report rendering ─────────────────────────


def format_plan(report: MigrationReport, *, apply: bool) -> str:
    lines = [
        f"batch {report.batch}: {len(report.packs)} move(s), {len(report.scenarios)} scenarioMove(s), "
        f"{'APPLIED' if apply else 'dry-run (nothing written)'}",
        "",
    ]
    for scenario in report.scenarios:
        lines.append(
            f"  scenario {scenario.scenario_id}  ({scenario.from_level}->{scenario.to_level}, "
            f"unit={scenario.course_unit_id}, shelf={scenario.shelf})"
        )
        lines.append(
            f"    contentLinks updated={scenario.content_links_updated} can-do: {scenario.can_do_note} "
            f"({scenario.source_cluster_id} -> {scenario.target_cluster_id})"
        )
        lines.append(
            f"    shelf_assignment.py: {scenario.shelf_assignment_note} | "
            f"AB_SPECS: {scenario.ab_specs_note}"
        )
        for warning in scenario.grammar_level_warnings:
            lines.append(f"    WARNING: {warning}")
    if report.scenarios:
        lines.append("")
    for pack in report.packs:
        lines.append(
            f"  {pack.bundle} -> {pack.new_pack_id}  ({pack.from_level}->{pack.to_level}, "
            f"unit={pack.course_unit_id})"
        )
        lines.append(
            f"    words={pack.n_words} cloze={pack.n_cloze} satz={pack.n_satz} "
            f"artwork={'yes' if pack.has_dedicated_artwork else 'no'} "
            f"pack_source={'yes' if pack.has_pack_source else 'no'}"
        )
        lines.append(
            f"    cando cluster: {pack.source_cluster_id} -> {pack.target_cluster_id} "
            f"(segment {pack.target_segment_id}; {pack.cluster_choice_note})"
        )
        if len(pack.cluster_candidates) > 1:
            lines.append(f"    cando candidates were: {list(pack.cluster_candidates)}")
    lines.append("")
    lines.append(f"vocabPackUnitMap renames: {len(report.vocab_pack_unit_map_renames)}")
    lines.append(
        f"clozeTopicUnitMap: +{len(report.cloze_topic_keys_added)} added "
        f"{report.cloze_topic_keys_added}, -{len(report.cloze_topic_keys_removed)} removed "
        f"{report.cloze_topic_keys_removed}"
    )
    lines.append(f"contentLinks rewritten: {report.content_links_rewritten}")
    lines.append(f"Dart packDisplayMap renames: {report.dart_display_map_renames}")
    lines.append(f"Dart packOrderInLevel renames: {report.dart_order_map_renames}")
    lines.append(f"Dart dedicatedPackIds renames: {report.dart_artwork_renames}")
    lines.append(f"artwork .webp files renamed: {report.artwork_files_renamed}")
    lines.append(f"pack authoring sources synced: {report.pack_sources_synced}")
    lines.append(f"Dancheong motif renames: {report.dancheong_motif_renames}")
    lines.append(f"pack_progress_aliases.dart entries added: {report.aliases_added}")
    if report.test_references:
        lines.append("")
        lines.append("old pack ids referenced by test/ or tools/content_factory/ (Fable must review):")
        for ident, files in report.test_references.items():
            if files:
                lines.append(f"  {ident}: {files}")
    if report.scenarios and apply:
        # Plan §4.3 step 4(7): a scenario move changes which shard a
        # scenario's dialog lives in, which shifts that shard's own
        # content hash -- every OTHER scenario in the same shard (not
        # just the moved one) needs its tts_first_line_manifest.json
        # `sourceSha256` refreshed, and the canonical manifest mirrors
        # that same shard data. This tool never shells out to run them
        # itself (a relevel apply and a TTS/manifest rebuild are separate,
        # separately-reviewable operations) -- it only prints the exact
        # commands the operator must run next.
        lines.append("")
        lines.append("scenario move(s) applied -- run these follow-ups next:")
        lines.append("  python tool/generate_tts.py --write-first-line-manifest assets/data/tts_first_line_manifest.json")
        lines.append("  python tool/generate_tts.py --check-first-line-manifest assets/data/tts_first_line_manifest.json")
        lines.append("  python functions/tts/build_canonical_manifest.py")
        lines.append("  python functions/tts/build_canonical_manifest.py --check")
    return "\n".join(lines)


REPORT_SECTION_HEADER = "## 실행 결과"


def append_report_section(path: Path, report: MigrationReport, *, apply: bool) -> None:
    # Per-batch header (T2.4b-1 plan step 4: "the report tool must ADD a
    # second section for batch L2a2 without destroying the L2a section") --
    # each batch owns its own "## 실행 결과 (<batch>)" block, so re-running
    # one batch never disturbs another's.
    section_header = f"{REPORT_SECTION_HEADER} ({report.batch})"
    lines = [
        section_header,
        "",
        f"모드: {'--apply (실제 반영됨)' if apply else 'dry-run (아무 파일도 바뀌지 않음)'}",
        "",
    ]
    if report.scenarios:
        lines.append("| scenario | from->to | unit | shelf | contentLinks | can-do | shelf_assignment.py | AB_SPECS |")
        lines.append("|---|---|---|---|---|---|---|---|")
        for scenario in report.scenarios:
            lines.append(
                f"| `{scenario.scenario_id}` | {scenario.from_level}->{scenario.to_level} | "
                f"`{scenario.course_unit_id}` | `{scenario.shelf}` | {scenario.content_links_updated} | "
                f"{scenario.can_do_note} | {scenario.shelf_assignment_note} | {scenario.ab_specs_note} |"
            )
        for scenario in report.scenarios:
            for warning in scenario.grammar_level_warnings:
                lines.append(f"- WARNING `{scenario.scenario_id}`: {warning}")
        lines.append("")
    if report.packs:
        lines.append("| pack | words | cloze | satz | cando cluster (from -> to) | segment | note |")
        lines.append("|---|---|---|---|---|---|---|")
    for pack in report.packs:
        lines.append(
            f"| `{pack.bundle}`->`{pack.new_pack_id}` | {pack.n_words} | {pack.n_cloze} | "
            f"{pack.n_satz} | `{pack.source_cluster_id}` -> `{pack.target_cluster_id}` | "
            f"`{pack.target_segment_id}` | {pack.cluster_choice_note} |"
        )
    lines.append("")
    lines.append(
        f"vocabPackUnitMap 개명 {len(report.vocab_pack_unit_map_renames)}건, "
        f"clozeTopicUnitMap +{len(report.cloze_topic_keys_added)}/"
        f"-{len(report.cloze_topic_keys_removed)}, contentLinks 재작성 "
        f"{report.content_links_rewritten}건."
    )
    lines.append("")
    lines.append("Dart 편집:")
    lines.append(f"- `packDisplayMap` 개명: {report.dart_display_map_renames}")
    lines.append(f"- `packOrderInLevel` 개명(새 순번): {report.dart_order_map_renames}")
    lines.append(f"- `dedicatedPackIds` 개명 + 아트워크 파일 rename: {report.dart_artwork_renames}")
    lines.append(f"- `kPackProgressAliases` 추가: {report.aliases_added}")
    lines.append("")
    lines.append("`test/`·`tools/content_factory/`에서 옛 pack id를 참조하는 파일 (Fable 확인 필요):")
    any_hits = False
    for ident, files in report.test_references.items():
        if files:
            any_hits = True
            lines.append(f"- `{ident}`: {files}")
    if not any_hits:
        lines.append("- (없음)")
    if report.scenarios and apply:
        lines.append("")
        lines.append("시나리오 이동이 적용됨 -- 다음 후속 명령을 실행할 것:")
        lines.append("```")
        lines.append("python tool/generate_tts.py --write-first-line-manifest assets/data/tts_first_line_manifest.json")
        lines.append("python tool/generate_tts.py --check-first-line-manifest assets/data/tts_first_line_manifest.json")
        lines.append("python functions/tts/build_canonical_manifest.py")
        lines.append("python functions/tts/build_canonical_manifest.py --check")
        lines.append("```")
    lines.append("")
    section_text = "\n".join(lines) + "\n"

    # Read-modify-write, not open(path, "a"): (1) "a" text-mode still
    # translates "\n" -> "\r\n" on Windows (T2.3-R1 STEP 1a) and (2) a
    # second run must *replace only this batch's own* "## 실행 결과 (<batch>)"
    # section, leaving every other batch's section in the same file alone
    # (T2.4b-1 plan step 4: a second batch, e.g. L2a2, ADDS a section next
    # to L2a's, it does not destroy it) -- re-running --apply for one batch
    # after a fix is the normal workflow here, not an edge case.
    if path.exists():
        existing = _normalize_newlines(path.read_bytes().decode("utf-8"))
    else:
        existing = ""
    this_batch_header_re = re.compile(r"(?m)^" + re.escape(section_header) + r"\s*$")
    any_header_re = re.compile(r"(?m)^## ")
    match = this_batch_header_re.search(existing)
    if match is None:
        # No section for this batch yet -- append after everything else.
        prefix = existing.rstrip("\n")
        new_content = f"{prefix}\n\n{section_text}" if prefix else section_text
    else:
        # Cut out just this batch's own block (its header through the next
        # "## "-headed section, or EOF) and splice the fresh version back
        # into that same spot, keeping every other batch's block exactly
        # where it was. `section_text` is used byte-for-byte (never
        # re-stripped/re-joined) so a same-batch rerun with an unchanged
        # report reproduces the exact same bytes -- idempotency (plan
        # T2.4b-1 step 4) needs this, not just "the right content".
        next_header = any_header_re.search(existing, match.end())
        block_end = next_header.start() if next_header is not None else len(existing)
        before = existing[: match.start()].rstrip("\n")
        after = existing[block_end:]  # untouched: starts right at "## " or is ""
        tail = section_text + after
        new_content = f"{before}\n\n{tail}" if before else tail
    path.write_bytes(new_content.encode("utf-8"))


# ───────────────────────── CLI ──────────────────────────────────────────────


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("bundle_path", type=Path, help="tools/content_factory/relevel/relevel_bundle_<batch>.json")
    parser.add_argument("--apply", action="store_true", help="write the staged relevel (default: dry run)")
    parser.add_argument("--report", type=Path, default=None, help="markdown file to append a 실행 결과 section to")
    parser.add_argument(
        "--sync-pack-sources", action="store_true",
        help=(
            "retroactive mode (task T2.9a): only rename+update this bundle's "
            "tools/content_factory/data/packs/<id>.json archival sources -- "
            "idempotent, does not touch assets/data/the ledger/Dart sources -- "
            "for a bundle that was already migrate()'d before this sync step "
            "existed (LCP PR-L2a batches L2a, L2a3)"
        ),
    )
    args = parser.parse_args(argv)

    try:
        bundle = load_bundle(args.bundle_path)
        if args.sync_pack_sources:
            sync_report = sync_pack_sources(bundle, apply=args.apply)
            print(
                f"batch {sync_report.batch}: {len(sync_report.packs)} pack(s), "
                f"{'APPLIED' if args.apply else 'dry-run (nothing written)'}"
            )
            synced = dict(sync_report.pack_sources_synced)
            for pack in sync_report.packs:
                if pack.bundle in synced:
                    status = f"synced -> {synced[pack.bundle]}.json"
                elif not pack.has_pack_source:
                    status = "no pack source file -- no-op"
                else:
                    status = "would sync (dry-run)"
                print(f"  {pack.bundle} -> {pack.new_pack_id}: {status}")
            return 0
        report = migrate(bundle=bundle, apply=args.apply)
    except (RelevelError, NotImplementedError) as error:
        print(f"ERROR: {error}")
        return 1

    print(format_plan(report, apply=args.apply))
    if args.report is not None:
        append_report_section(args.report, report, apply=args.apply)
        print(f"\nappended 실행 결과 to {args.report}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
