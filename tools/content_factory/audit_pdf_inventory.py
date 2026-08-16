#!/usr/bin/env python3
"""Measure PDF extraction coverage without emitting or retaining source text.

The output contains only file metadata, hashes, page/text/image counts, and a
one-way normalized-text fingerprint for duplicate triage. Extracted text is
kept in memory only and is never printed or written.

Use the bundled workspace Python because it supplies ``pypdf``::

    <bundled-python> tools/content_factory/audit_pdf_inventory.py <pdf> ...
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import statistics
import sys
from typing import Any, Iterable


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _normalized_text(value: str) -> str:
    return re.sub(r"\s+", "", value).casefold()


def _image_count(page: Any) -> int:
    """Count top-level image XObjects without decoding or exporting images."""

    try:
        resources = page.get("/Resources") or {}
        xobjects = resources.get("/XObject") or {}
        return sum(
            1
            for raw in xobjects.values()
            if getattr(raw, "get_object", lambda: raw)().get("/Subtype") == "/Image"
        )
    except (AttributeError, KeyError, TypeError, ValueError):
        return 0


def classify_text_layer(char_counts: Iterable[int]) -> str:
    counts = list(char_counts)
    if not counts:
        return "image"
    substantial = sum(count >= 80 for count in counts)
    readable = sum(count >= 20 for count in counts)
    coverage = readable / len(counts)
    substantial_coverage = substantial / len(counts)
    median = statistics.median(counts)
    if coverage >= 0.85 and substantial_coverage >= 0.70 and median >= 100:
        return "text"
    if coverage <= 0.10 and substantial <= 1 and median < 10:
        return "image"
    return "mixed"


def audit_pdf(path: Path) -> dict[str, Any]:
    try:
        from pypdf import PdfReader
    except ImportError as error:  # pragma: no cover - environment guard
        raise RuntimeError("pypdf is required; run with the bundled workspace Python") from error

    reader = PdfReader(path)
    counts: list[int] = []
    line_counts: list[int] = []
    image_counts: list[int] = []
    fingerprint = hashlib.sha256()
    extraction_errors = 0
    for page in reader.pages:
        try:
            text = page.extract_text() or ""
        except Exception:  # pypdf may reject a malformed page while later pages remain usable
            text = ""
            extraction_errors += 1
        normalized = _normalized_text(text)
        counts.append(len(normalized))
        line_counts.append(sum(bool(line.strip()) for line in text.splitlines()))
        image_counts.append(_image_count(page))
        fingerprint.update(normalized.encode("utf-8"))
        fingerprint.update(b"\x00")

    mode = classify_text_layer(counts)
    return {
        "file_name": path.name,
        "sha256": _sha256(path),
        "size_bytes": path.stat().st_size,
        "page_count": len(reader.pages),
        "text_layer_mode": mode,
        "ocr_required": mode != "text",
        "text_page_count": sum(count >= 20 for count in counts),
        "substantial_text_page_count": sum(count >= 80 for count in counts),
        "empty_text_page_count": sum(count == 0 for count in counts),
        "text_char_total": sum(counts),
        "text_char_median": int(statistics.median(counts)) if counts else 0,
        "text_line_total": sum(line_counts),
        "image_xobject_total": sum(image_counts),
        "pages_with_images": sum(count > 0 for count in image_counts),
        "extraction_error_count": extraction_errors,
        "normalized_text_sha256": fingerprint.hexdigest() if sum(counts) else None,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pdfs", nargs="+", type=Path)
    parser.add_argument("--indent", type=int, default=2)
    args = parser.parse_args(argv)

    missing = [str(path) for path in args.pdfs if not path.is_file()]
    if missing:
        print(f"ERROR: missing PDF(s): {', '.join(missing)}", file=sys.stderr)
        return 2
    try:
        records = [audit_pdf(path.resolve()) for path in args.pdfs]
    except (RuntimeError, OSError, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(json.dumps(records, ensure_ascii=False, indent=args.indent))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
