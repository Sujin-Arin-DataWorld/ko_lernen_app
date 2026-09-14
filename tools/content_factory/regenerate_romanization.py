#!/usr/bin/env python3
"""Regenerate the `romanization` column of assets/data/korean_vocab.csv
using the RR sound-change engine in rr_romanize.py (task C2a).

Idempotent: recomputes only the `romanization` field for every row, leaves
every other column and the row/column order untouched, and writes the CSV
back through `build_level_content_4x._write_csv` (the repo's existing
korean_vocab.csv writer -- LF line endings, no header/quoting changes) only
when at least one row actually changed. Also writes a Markdown change report
to docs/data/.

Usage:
    python tools/content_factory/regenerate_romanization.py
    python tools/content_factory/regenerate_romanization.py --dry-run
"""

from __future__ import annotations

import argparse
import csv
import sys
from collections import Counter, defaultdict
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from build_level_content_4x import _write_csv  # existing writer helper, reused unchanged
from rr_romanize import (
    find_ambiguous_liaison_words,
    find_h_boundary_words,
    romanize_korean,
)
from validate_content import VOCAB_HEADER

ROOT = Path(__file__).resolve().parents[2]
VOCAB_CSV = ROOT / "assets" / "data" / "korean_vocab.csv"
REPORT_PATH = ROOT / "docs" / "data" / "rr_regeneration_report_2026-09-15.md"


def _load_rows() -> list[dict[str, str]]:
    with VOCAB_CSV.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames != VOCAB_HEADER:
            raise SystemExit(
                f"{VOCAB_CSV} header {reader.fieldnames} does not match "
                f"validate_content.VOCAB_HEADER {VOCAB_HEADER}"
            )
        return list(reader)


def regenerate(rows: list[dict[str, str]]) -> tuple[list[dict[str, str]], list[dict[str, str]]]:
    """Return (new_rows, changes). `changes` entries have id/korean/before/after/rules."""

    changes: list[dict[str, str]] = []
    for row in rows:
        before = row["romanization"]
        after, rules = romanize_korean(row["korean"], pos=row.get("pos_de"), return_rules=True)
        if after != before:
            changes.append(
                {
                    "id": row["id"],
                    "korean": row["korean"],
                    "before": before,
                    "after": after,
                    "rules": rules or ["base_letter_correction"],
                }
            )
            row["romanization"] = after
    return rows, changes


def _manual_review_rows(rows: list[dict[str, str]]) -> dict[str, list[dict[str, str]]]:
    ambiguous_liaison = []
    h_boundary = []
    for row in rows:
        korean = row["korean"]
        liaison_hits = find_ambiguous_liaison_words(korean)
        if liaison_hits:
            ambiguous_liaison.append({"id": row["id"], "korean": korean, "words": ", ".join(liaison_hits)})
        h_hits = find_h_boundary_words(korean)
        if h_hits:
            h_boundary.append(
                {
                    "id": row["id"],
                    "korean": korean,
                    "words": ", ".join(h_hits),
                    "pos_de": row.get("pos_de", ""),
                    "romanization": row["romanization"],
                }
            )
    return {"liaison": ambiguous_liaison, "h_boundary": h_boundary}


def _write_report(
    total_rows: int, changes: list[dict[str, str]], manual_review: dict[str, list[dict[str, str]]]
) -> None:
    by_rule: dict[str, list[dict[str, str]]] = defaultdict(list)
    for change in changes:
        for rule in change["rules"]:
            by_rule[rule].append(change)

    lines = [
        "# RR romanization regeneration report (2026-09-15, task C2a)",
        "",
        f"- Total vocab rows: {total_rows}",
        f"- Rows with a changed `romanization` value: {len(changes)}",
        f"- Rows flagged for manual review (ambiguous liaison/n-insertion): {len(manual_review['liaison'])}",
        f"- Rows flagged for manual review (체언 ㅎ-aspiration heuristic applies): {len(manual_review['h_boundary'])}",
        "",
        "## Changes by rule",
        "",
    ]
    for rule in sorted(by_rule):
        entries = by_rule[rule]
        lines.append(f"### {rule} ({len(entries)} rows)")
        lines.append("")
        lines.append("| id | korean | before | after | rule |")
        lines.append("|---|---|---|---|---|")
        for change in entries:
            lines.append(
                f"| {change['id']} | {change['korean']} | {change['before']} | "
                f"{change['after']} | {', '.join(change['rules'])} |"
            )
        lines.append("")

    lines.append("## Manual review needed")
    lines.append("")
    lines.append(
        "### Ambiguous liaison vs. ㄴ-insertion "
        f"({len(manual_review['liaison'])} rows)"
    )
    lines.append("")
    lines.append(
        "A coda sits directly before an unlinked y-glide/이 syllable. This "
        "module defaults to plain liaison (matches 특약 -> teugyak); a native "
        "compound reading (like 알약 -> allyak) would need a lexical override. "
        "Jin: please confirm each word's reading."
    )
    lines.append("")
    if manual_review["liaison"]:
        lines.append("| id | korean | flagged word(s) |")
        lines.append("|---|---|---|")
        for entry in manual_review["liaison"]:
            lines.append(f"| {entry['id']} | {entry['korean']} | {entry['words']} |")
    else:
        lines.append("(none)")
    lines.append("")

    lines.append(
        "### 체언 ㅎ-aspiration heuristic applies "
        f"({len(manual_review['h_boundary'])} rows)"
    )
    lines.append("")
    lines.append(
        "A stop+ㅎ or ㅎ+stop syllable boundary exists; the POS-based "
        "`is_cheoneon_pos` heuristic (Nomen/Ausdruck/Pronomen/Phrase/Adverb "
        "-> keep ㅎ, Verb/Verbphrase/Adjektiv -> merge) decided the outcome "
        "below. Flagged regardless of whether the row's romanization changed, "
        "since a wrong POS classification would silently produce the wrong "
        "reading either way."
    )
    lines.append("")
    if manual_review["h_boundary"]:
        lines.append("| id | korean | pos_de | flagged word(s) | current romanization |")
        lines.append("|---|---|---|---|---|")
        for entry in manual_review["h_boundary"]:
            lines.append(
                f"| {entry['id']} | {entry['korean']} | {entry['pos_de']} | "
                f"{entry['words']} | {entry['romanization']} |"
            )
    else:
        lines.append("(none)")
    lines.append("")

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="Report changes without writing the CSV.")
    args = parser.parse_args()

    rows = _load_rows()
    new_rows, changes = regenerate(rows)
    manual_review = _manual_review_rows(new_rows)

    print(f"total rows: {len(rows)}")
    print(f"changed rows: {len(changes)}")
    print(f"manual review (liaison): {len(manual_review['liaison'])}")
    print(f"manual review (h-boundary): {len(manual_review['h_boundary'])}")
    print("changes by rule:")
    rule_counts = Counter(rule for change in changes for rule in change["rules"])
    for rule, count in sorted(rule_counts.items()):
        print(f"  {rule}: {count}")

    _write_report(len(rows), changes, manual_review)
    print(f"wrote {REPORT_PATH.relative_to(ROOT)}")

    if args.dry_run:
        print("--dry-run: not writing CSV")
        return 0

    if changes:
        _write_csv(VOCAB_CSV, VOCAB_HEADER, new_rows)
        print(f"wrote {VOCAB_CSV.relative_to(ROOT)}")
    else:
        print("no changes -- CSV not rewritten")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
