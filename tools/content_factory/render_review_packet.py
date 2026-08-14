#!/usr/bin/env python3
"""Render a complete, read-only Markdown evidence packet for Jin's review.

The compact eight-column review CSV is intentionally only an approval ledger.
This command makes the full schema-complete draft, exact KO/DE/EN content,
answers, distractors, and existing review status visible in one Markdown file.
It validates the batch first and never changes app assets.

Usage:
    python3 tools/content_factory/render_review_packet.py \
      --manifest tools/content_factory/drafts/batch_01_manifest.json \
      --output tools/content_factory/review/batch_01_review_packet.md
"""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any

from validate_batch_01 import (
    REVIEW_HEADER,
    _load_artifact,
    _parse_manifest,
    _resolve_under_root,
    validate_review_batch,
)


ROOT = Path(__file__).resolve().parents[2]


def _read_review_rows(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if list(reader.fieldnames or []) != REVIEW_HEADER:
            raise ValueError(f"{path}: unexpected review header")
        return list(reader)


def _markdown_value(value: Any) -> str:
    if isinstance(value, str):
        return value
    return json.dumps(value, ensure_ascii=False, indent=2)


def _record_block(record: dict[str, Any]) -> str:
    """Show every authored field without losing nested game choices."""

    lines = ["| Field | Authored value |", "| --- | --- |"]
    for field, value in record.items():
        rendered = _markdown_value(value).replace("\n", "<br>").replace("|", "\\|")
        lines.append(f"| `{field}` | {rendered} |")
    return "\n".join(lines)


def render_packet(*, manifest_path: Path) -> str:
    root = ROOT.resolve()
    if not manifest_path.is_absolute():
        manifest_path = root / manifest_path
    manifest_path = manifest_path.resolve()
    validate_review_batch(root=root, manifest_path=manifest_path)
    manifest, entries, specs = _parse_manifest(
        root,
        manifest_path,
        enforce_batch_01_contract=False,
    )

    provenance = manifest.get("provenance") or {}
    lines = [
        f"# Batch {manifest['batch']} — Complete Review Packet",
        "",
        "> Generated read-only from the schema-complete draft and its approval ledger. "
        "Edit only the ledger's `상태` and `jin_memo`; fix content in the draft, then regenerate.",
        "",
        f"- Status: `{manifest['status']}`",
        f"- Records: **{manifest['recordCount']}**",
        f"- Scope: {provenance.get('scope', 'not declared')}",
        "",
    ]
    for kind in sorted(specs):
        payload = _load_artifact(root, specs[kind], entries[kind])
        review_rows = _read_review_rows(payload.review_path)
        lines.extend([f"## {kind.title()} ({len(payload.records)})", ""])
        for index, (record, review) in enumerate(zip(payload.records, review_rows), start=1):
            ident = record["id"]
            level = str(record["level"]).upper()
            lines.extend(
                [
                    f"### {index}. `{ident}` · {level}",
                    "",
                    _record_block(record),
                    "",
                    "**Jin approval ledger**",
                    "",
                    f"- 상태: `{review['상태'] or '(empty)'}`",
                    f"- field notes: {review['field_notes']}",
                    f"- Jin memo: {review['jin_memo'] or '—'}",
                    "",
                ],
            )
    return "\n".join(lines)


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True, help="review-only batch manifest")
    parser.add_argument(
        "--output",
        help="optional repository-relative Markdown output path; otherwise print to stdout",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    try:
        packet = render_packet(manifest_path=Path(args.manifest))
        if args.output:
            output = _resolve_under_root(ROOT, args.output, "output")
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text(packet + "\n", encoding="utf-8")
            print(f"✓ wrote read-only review packet: {output.relative_to(ROOT)}")
        else:
            print(packet)
    except (ValueError, OSError, json.JSONDecodeError) as error:
        print(f"✗ {error}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
