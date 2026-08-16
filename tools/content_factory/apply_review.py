#!/usr/bin/env python3
"""Apply only Jin-approved records from a reviewed, schema-complete draft.

The review sheet is an approval ledger, not a lossy content transport.  Its
``id`` and ``상태``/``status`` columns select records from ``--draft``; the
draft itself must preserve the exact CSV or JSON shape consumed by the app.
That avoids silently inventing fields while turning a compact review CSV into
a scenario, game item, or vocabulary row.

Examples:
    # Preview is the default: no target or manifest is changed.
    python3 tools/content_factory/apply_review.py \
      tools/content_factory/review/c1_b1_vocab.csv \
      --draft /tmp/c1_b1_vocab_draft.csv \
      --target assets/data/korean_vocab.csv

    # A new vocab pack additionally needs its read-only Batch manifest before
    # it can be written. Existing-pack maintenance does not need this flag.
    python3 tools/content_factory/apply_review.py \
      tools/content_factory/review/c1_b1_vocab.csv \
      --draft /tmp/c1_b1_vocab_draft.csv \
      --target assets/data/korean_vocab.csv \
      --pack-metadata /tmp/c1_b1_batch_manifest.json --apply

No network calls are made.  ``--apply`` is deliberately explicit because
approved content changes learner-facing assets and progress denominators.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import subprocess
import sys
from pathlib import Path
import tempfile
from typing import Any, Iterable

from validate_content import ContentValidator


ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "assets" / "data"
MANIFEST_PATH = DATA_DIR / "content_audit_manifest.json"

# The key names are the canonical containers in the checked-in asset files.
# kkeunmari intentionally has no generic path here: its records have no stable
# IDs and must stay on its dedicated generator/review flow. Grammar patterns
# are also deliberately excluded: their asset has a Cloud Function mirror and
# must use a future paired, deployment-aware C4 transaction rather than an
# asset-only append that this tool is forbidden to perform.
JSON_COLLECTIONS = {
    "scenarios.json": ("scenario", "scenarios"),
    "cloze.json": ("cloze", "items"),
    "satz_sentences.json": ("satz", "items"),
    "smalltalk.json": ("smalltalk", "phrases"),
    "pronunciation_phrases.json": ("pronunciation", "phrases"),
}
CSV_KINDS = {
    "korean_vocab.csv": "vocab",
    "grammar.csv": "grammar",
}

APPROVED_STATUSES = frozenset(("approved", "ok"))
REJECTED_STATUSES = frozenset(("rejected", "no"))


class ReviewError(ValueError):
    """A safe-to-show review or draft problem."""


def normalize_status(value: str | None) -> str:
    """Map the handoff vocabulary into the canonical approval state.

    ``draft`` and ``fix: …`` remain pending.  This accepts the Fable work
    order's generic terms and Jin's concise sheet terms without making an
    unrecognised word an accidental approval.
    """

    cleaned = (value or "").strip().casefold()
    if cleaned in APPROVED_STATUSES:
        return "approved"
    if cleaned in REJECTED_STATUSES:
        return "rejected"
    if cleaned.startswith("fix:"):
        return "fix"
    return "draft"


def _resolve_input(path_value: str | Path) -> Path:
    path = Path(path_value)
    if not path.is_absolute():
        path = ROOT / path
    return path.resolve()


def _resolve_target(path_value: str | Path) -> Path:
    """Return one canonical, reviewable asset path.

    Checking only that a path is *somewhere* below assets/data/ would let a
    same-named file in a subdirectory pass the filename dispatcher.  The
    review tool is deliberately narrower: it may append only to the exact
    checked-in assets whose schemas it knows how to preserve.
    """

    target = _resolve_input(path_value)
    allowed = {
        DATA_DIR.resolve() / name
        for name in (*CSV_KINDS.keys(), *JSON_COLLECTIONS.keys())
    }
    if target not in allowed:
        supported = ", ".join(sorted(path.name for path in allowed))
        raise ReviewError(
            "--target must be one of the canonical assets/data files: "
            f"{supported}"
        )
    if not target.is_file():
        raise ReviewError(f"target file does not exist: {target}")
    return target


def _read_review(path: Path) -> tuple[set[str], list[str]]:
    try:
        with path.open(encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            fields = reader.fieldnames or []
            if "id" not in fields:
                raise ReviewError(f"{path}: review sheet needs an id column")
            has_korean_status = "상태" in fields
            has_english_status = "status" in fields
            if has_korean_status and has_english_status:
                raise ReviewError(f"{path}: use either 상태 or status, not both")
            status_column = "상태" if has_korean_status else "status" if has_english_status else None
            if status_column is None:
                raise ReviewError(f"{path}: review sheet needs 상태 or status column")
            approved: set[str] = set()
            pending: list[str] = []
            seen_ids: dict[str, int] = {}
            for row_number, row in enumerate(reader, start=2):
                if None in row:
                    raise ReviewError(f"{path}:{row_number}: row has more columns than its header")
                ident = (row.get("id") or "").strip()
                if not ident:
                    raise ReviewError(f"{path}:{row_number}: id must not be empty")
                if ident in seen_ids:
                    raise ReviewError(
                        f"{path}:{row_number}: duplicate review id {ident!r} "
                        f"(first seen at row {seen_ids[ident]})"
                    )
                seen_ids[ident] = row_number
                state = normalize_status(row.get(status_column))
                if state == "approved":
                    approved.add(ident)
                else:
                    pending.append(f"{ident} ({state})")
    except (OSError, csv.Error) as error:
        raise ReviewError(f"cannot read review sheet {path}: {error}") from error
    return approved, pending


def _read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    try:
        with path.open(encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            header = list(reader.fieldnames or [])
            if not header or any(not field for field in header) or len(header) != len(set(header)):
                raise ReviewError(f"{path}: CSV header must contain unique, nonempty columns")
            rows = list(reader)
            for row_number, row in enumerate(rows, start=2):
                if None in row:
                    raise ReviewError(f"{path}:{row_number}: row has more columns than its header")
                missing = [field for field in header if row.get(field) is None]
                if missing:
                    raise ReviewError(
                        f"{path}:{row_number}: row is missing columns: {', '.join(missing)}"
                    )
            return header, rows
    except (OSError, csv.Error) as error:
        raise ReviewError(f"cannot read CSV {path}: {error}") from error


def _load_json(path: Path) -> Any:
    try:
        with path.open(encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, json.JSONDecodeError) as error:
        raise ReviewError(f"cannot load JSON {path}: {error}") from error


def _records_from_json(payload: Any, collection: str | None, label: str) -> list[dict[str, Any]]:
    records = payload if collection is None else payload.get(collection) if isinstance(payload, dict) else None
    if not isinstance(records, list) or any(not isinstance(record, dict) for record in records):
        container = "the root array" if collection is None else f"a {collection!r} array"
        raise ReviewError(f"{label}: expected {container} of objects")
    return records


def _index_by_id(records: Iterable[dict[str, Any]], label: str) -> dict[str, dict[str, Any]]:
    indexed: dict[str, dict[str, Any]] = {}
    for number, record in enumerate(records, start=1):
        raw_ident = record.get("id")
        if not isinstance(raw_ident, str) or not raw_ident.strip():
            raise ReviewError(f"{label}:{number}: record needs a nonempty string id")
        ident = raw_ident.strip()
        if ident in indexed:
            raise ReviewError(f"{label}:{number}: duplicate id {ident!r}")
        indexed[ident] = record
    return indexed


def _write_text_atomically(path: Path, text: str) -> None:
    try:
        descriptor, temporary_name = tempfile.mkstemp(
            prefix=f".{path.name}.",
            suffix=".review-tmp",
            dir=path.parent,
            text=True,
        )
    except OSError as error:
        raise ReviewError(f"cannot create temporary file for {path}: {error}") from error
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="") as handle:
            handle.write(text)
        os.replace(temporary, path)
    except OSError as error:
        try:
            temporary.unlink(missing_ok=True)
        except OSError:
            pass
        raise ReviewError(f"cannot atomically write {path}: {error}") from error


def _csv_text(header: list[str], rows: list[dict[str, str]]) -> str:
    from io import StringIO

    buffer = StringIO(newline="")
    # The checked-in content CSVs use LF.  Without this explicit setting the
    # csv module emits CRLF and an approved append would rewrite every
    # unchanged line in a 900+ row asset.
    writer = csv.DictWriter(
        buffer,
        fieldnames=header,
        extrasaction="raise",
        lineterminator="\n",
    )
    writer.writeheader()
    writer.writerows(rows)
    return buffer.getvalue()


def _json_text(payload: Any) -> str:
    return json.dumps(payload, ensure_ascii=False, indent=2) + "\n"


def _target_kind(target: Path) -> tuple[str, str | None]:
    if target.name in CSV_KINDS:
        return CSV_KINDS[target.name], "csv"
    if target.name in JSON_COLLECTIONS:
        kind, collection = JSON_COLLECTIONS[target.name]
        return kind, collection
    supported = ", ".join(sorted((*CSV_KINDS, *JSON_COLLECTIONS)))
    raise ReviewError(f"unsupported target {target.name!r}; supported: {supported}")


def _merge_csv(target: Path, draft: Path, approved: set[str]) -> tuple[str, int, set[str]]:
    target_header, target_rows = _read_csv(target)
    draft_header, draft_rows = _read_csv(draft)
    if target_header != draft_header:
        raise ReviewError("CSV draft header must exactly match the target header")
    if "id" not in target_header:
        raise ReviewError("CSV target must have an id column")
    current = _index_by_id(target_rows, str(target))
    candidates = _index_by_id(draft_rows, str(draft))
    missing = approved - candidates.keys()
    if missing:
        raise ReviewError(f"approved IDs absent from draft: {', '.join(sorted(missing))}")
    duplicate = approved & current.keys()
    if duplicate:
        raise ReviewError(f"approved IDs already exist in target: {', '.join(sorted(duplicate))}")
    new_vocab_pack_ids: set[str] = set()
    if target.name == "korean_vocab.csv":
        new_vocab_pack_ids = _validate_new_vocab_packs(target_rows, draft_rows, approved)
    additions = [row for row in draft_rows if row["id"].strip() in approved]
    return _csv_text(target_header, [*target_rows, *additions]), len(additions), new_vocab_pack_ids


def _validate_new_vocab_packs(
    target_rows: list[dict[str, str]],
    draft_rows: list[dict[str, str]],
    approved: set[str],
) -> set[str]:
    """Fail closed for every previously unseen vocabulary pack in a draft.

    A vocabulary row is not independently usable: the app groups it by
    ``pack_id`` and expects its deliberate word count, ordering, and Boss set.
    New packs must be structurally complete even when a preview has no
    approved rows. A reviewer may leave an *entire* new pack pending, and may
    approve another complete new pack in the same draft, but may not publish
    only a few rows from one new pack. Existing packs intentionally stay
    outside this ratchet so their explicit append/maintenance workflow works.
    """

    existing_pack_ids = {
        (row.get("pack_id") or "").strip()
        for row in target_rows
    }
    by_pack: dict[str, list[tuple[int, dict[str, str]]]] = {}
    for number, row in enumerate(draft_rows, start=2):
        pack_id = (row.get("pack_id") or "").strip()
        if not pack_id:
            raise ReviewError(
                "korean_vocab.csv draft needs a nonempty pack_id "
                f"at row {number}",
            )
        by_pack.setdefault(pack_id, []).append((number, row))

    new_pack_ids: set[str] = set()
    for pack_id, pack_rows in sorted(by_pack.items()):
        if pack_id in existing_pack_ids:
            continue
        new_pack_ids.add(pack_id)
        word_count = len(pack_rows)
        if word_count not in (11, 12):
            raise ReviewError(
                f"new vocab pack {pack_id!r} has {word_count} rows; expected 11 or 12",
            )
        orders: list[int] = []
        boss_orders: list[int] = []
        draft_ids: list[str] = []
        for row_number, row in pack_rows:
            ident = (row.get("id") or "").strip()
            draft_ids.append(ident)
            try:
                order = int((row.get("pack_order") or "").strip())
            except ValueError as error:
                raise ReviewError(
                    f"new vocab pack {pack_id!r} row {row_number} has invalid pack_order",
                ) from error
            orders.append(order)
            boss = (row.get("is_review_boss") or "").strip().lower()
            if boss not in ("true", "false"):
                raise ReviewError(
                    f"new vocab pack {pack_id!r} row {row_number} "
                    "is_review_boss must be true or false",
                )
            if boss == "true":
                boss_orders.append(order)
        if sorted(orders) != list(range(1, word_count + 1)):
            raise ReviewError(
                f"new vocab pack {pack_id!r} pack_order must be contiguous 1..{word_count}",
            )
        if len(boss_orders) not in (2, 3):
            raise ReviewError(
                f"new vocab pack {pack_id!r} has {len(boss_orders)} Boss rows; expected 2 or 3",
            )
        expected_boss_orders = list(range(word_count - len(boss_orders) + 1, word_count + 1))
        if sorted(boss_orders) != expected_boss_orders:
            raise ReviewError(
                f"new vocab pack {pack_id!r} Boss rows must occupy final pack_order values",
            )
        approved_ids = set(draft_ids) & approved
        if not approved_ids or approved_ids == set(draft_ids):
            continue
        pending_ids = sorted(set(draft_ids) - approved_ids)
        raise ReviewError(
            "partial approval is not allowed for new vocab pack "
            f"{pack_id!r}; approve every draft row or none. "
            f"Still pending: {', '.join(pending_ids)}",
        )
    return new_pack_ids


def _validate_new_vocab_pack_metadata(draft: Path, metadata: Path) -> None:
    """Run the read-only cross-file vocabulary pack-assignment preflight."""

    try:
        from plan_pack_assignments import PackAssignmentError, validate_plan
    except ImportError as error:
        raise ReviewError(f"cannot load pack assignment preflight: {error}") from error
    try:
        validate_plan(draft, metadata, root=ROOT)
    except PackAssignmentError as error:
        raise ReviewError(f"pack metadata preflight rejected the draft: {error}") from error


def _merge_json(target: Path, draft: Path, approved: set[str], collection: str | None) -> tuple[str, int]:
    target_payload = _load_json(target)
    draft_payload = _load_json(draft)
    target_records = _records_from_json(target_payload, collection, str(target))
    draft_records = _records_from_json(draft_payload, collection, str(draft))
    current = _index_by_id(target_records, str(target))
    candidates = _index_by_id(draft_records, str(draft))
    missing = approved - candidates.keys()
    if missing:
        raise ReviewError(f"approved IDs absent from draft: {', '.join(sorted(missing))}")
    duplicate = approved & current.keys()
    if duplicate:
        raise ReviewError(f"approved IDs already exist in target: {', '.join(sorted(duplicate))}")
    additions = [record for record in draft_records if record["id"].strip() in approved]
    if collection is None:
        payload: Any = [*target_records, *additions]
    else:
        if not isinstance(target_payload, dict):
            raise ReviewError(f"{target}: expected an object root")
        payload = {**target_payload, collection: [*target_records, *additions]}
    return _json_text(payload), len(additions)


def _bump_manifest(kind: str) -> str:
    manifest = _load_json(MANIFEST_PATH)
    if not isinstance(manifest, dict) or not isinstance(manifest.get("sources"), list):
        raise ReviewError("content_audit_manifest.json must contain sources")
    counts = ContentValidator(ROOT).inventory_counts()
    if kind not in counts:
        raise ReviewError(f"no inventory counter is defined for {kind!r}")
    matching_sources: list[dict[str, Any]] = []
    for source in manifest["sources"]:
        if not isinstance(source, dict):
            raise ReviewError("content_audit_manifest.json contains a non-object source")
        if str(source.get("kind", "")) == kind:
            matching_sources.append(source)
    if len(matching_sources) != 1:
        raise ReviewError(
            f"content_audit_manifest.json must contain exactly one {kind!r} source"
        )
    matching_sources[0]["count"] = counts[kind]
    return _json_text(manifest)


def _run_validator() -> None:
    command = [sys.executable, str(Path(__file__).with_name("validate_content.py"))]
    try:
        result = subprocess.run(command, cwd=ROOT, text=True, capture_output=True)
    except OSError as error:
        raise ReviewError(f"cannot run validate_content.py: {error}") from error
    if result.returncode != 0:
        details = (result.stdout + result.stderr).strip()
        raise ReviewError(f"validate_content.py rejected the merge:\n{details}")


def apply_review(
    review: Path,
    draft: Path,
    target: Path,
    *,
    apply: bool,
    pack_metadata: Path | None = None,
) -> tuple[int, list[str]]:
    review = _resolve_input(review)
    draft = _resolve_input(draft)
    target = _resolve_target(target)
    if pack_metadata is not None:
        pack_metadata = _resolve_input(pack_metadata)
        if not pack_metadata.is_file():
            raise ReviewError(f"pack metadata file does not exist: {pack_metadata}")
        if target.name != "korean_vocab.csv":
            raise ReviewError("--pack-metadata is only valid with assets/data/korean_vocab.csv")
    if draft == target:
        raise ReviewError("--draft must be a separate schema-complete source file")
    if draft.suffix.lower() != target.suffix.lower():
        raise ReviewError("draft and target must use the same CSV or JSON format")
    approved, pending = _read_review(review)
    kind, collection_or_format = _target_kind(target)
    new_vocab_pack_ids: set[str] = set()
    if target.suffix == ".csv":
        merged_text, count, new_vocab_pack_ids = _merge_csv(target, draft, approved)
    else:
        merged_text, count = _merge_json(target, draft, approved, collection_or_format)
    if new_vocab_pack_ids and pack_metadata is not None:
        _validate_new_vocab_pack_metadata(draft, pack_metadata)
    if not apply:
        return count, pending
    if new_vocab_pack_ids and pack_metadata is None:
        raise ReviewError(
            "--pack-metadata is required with --apply when a draft introduces a new vocab pack",
        )
    if count == 0:
        return 0, pending

    try:
        original_target = target.read_text(encoding="utf-8")
        original_manifest = MANIFEST_PATH.read_text(encoding="utf-8")
    except OSError as error:
        raise ReviewError(f"cannot snapshot review transaction: {error}") from error
    try:
        _write_text_atomically(target, merged_text)
        _write_text_atomically(MANIFEST_PATH, _bump_manifest(kind))
        _run_validator()
    except Exception as error:
        try:
            _write_text_atomically(target, original_target)
            _write_text_atomically(MANIFEST_PATH, original_manifest)
        except ReviewError as rollback_error:
            raise ReviewError(
                f"review merge failed ({error}); rollback also failed: {rollback_error}"
            ) from error
        if isinstance(error, ReviewError):
            raise
        raise ReviewError(f"review merge failed: {error}") from error
    return count, pending


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("review", help="review CSV containing id and 상태/status")
    parser.add_argument("--draft", required=True, help="schema-complete CSV or JSON draft")
    parser.add_argument("--target", required=True, help="asset under assets/data/")
    parser.add_argument(
        "--pack-metadata",
        help="read-only pack assignment metadata; required to apply a new vocab pack",
    )
    parser.add_argument("--apply", action="store_true", help="write instead of previewing")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    try:
        count, pending = apply_review(
            Path(args.review),
            Path(args.draft),
            Path(args.target),
            apply=args.apply,
            pack_metadata=Path(args.pack_metadata) if args.pack_metadata else None,
        )
    except ReviewError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    if args.apply:
        if count == 0:
            print("no approved rows; no asset was changed")
        else:
            print(f"applied {count} approved record(s); manifest and full validator passed")
    else:
        print(f"preview: {count} approved record(s) would be appended; no files changed")
        print("re-run with --apply only after reviewing this preview.")
    if pending:
        print("not applied: " + ", ".join(pending), file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
