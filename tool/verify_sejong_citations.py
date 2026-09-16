"""Q-S anti-hallucination gate: re-verify every Sejong-book citation.

Every factual claim about a Sejong textbook produced anywhere in the Q-S audit
(syllabus JSON, comparison tables, the level-map, the final report) must carry
a `file` + `page` (1-based) and, where it quotes book text, the quoted string.
This script is the single source of truth for "is that citation real": it
re-opens the actual PDF (never trusts the scratchpad extract or memory),
pulls that page's text with PyMuPDF, whitespace-normalizes both sides, and
checks the quote is a substring of the page text.

Citations live in `docs/data/sejong/citations.jsonl`, one JSON object per
line:
    {"id": "...", "file": "<pdf filename>", "page": <int>, "quote": "<string
     that must appear on that page verbatim, whitespace aside>", "context":
     "<where this fact is used>"}

For citations whose fact is not a literal quote (e.g. "this grammar label is
printed on this page" style claims where `quote` IS the label), the same
substring check applies -- the label string itself must occur on the page.

Usage:
    python tool/verify_sejong_citations.py
Exit code is 0 iff every citation verifies; the last stdout line is always
"citations verified N/N".
"""
from __future__ import annotations

import json
import os
import re
import sys

import fitz  # PyMuPDF

SEJONG_DIR = r"C:\Users\vjinn\ELibrary\Downloads\세종학당 학국어 레벨별 학습자료 참고"
HERE = os.path.dirname(os.path.abspath(__file__))  # .../tool
REPO_ROOT = os.path.dirname(HERE)  # repo root
CITATIONS_DIR = os.path.join(REPO_ROOT, "docs", "data", "sejong")
CITATIONS_GLOB = "citations*.jsonl"  # citations.jsonl (Phase 2) + citations_*.jsonl (level-map, Phase 3, report)

_WS_RE = re.compile(r"\s+")
_page_text_cache: dict[tuple[str, int], str] = {}
_doc_cache: dict[str, "fitz.Document"] = {}


def normalize(s: str) -> str:
    return _WS_RE.sub(" ", s or "").strip()


def get_page_text(filename: str, page: int) -> str | None:
    key = (filename, page)
    if key in _page_text_cache:
        return _page_text_cache[key]
    path = os.path.join(SEJONG_DIR, filename)
    if not os.path.isfile(path):
        _page_text_cache[key] = None
        return None
    doc = _doc_cache.get(filename)
    if doc is None:
        try:
            doc = fitz.open(path)
        except Exception:
            _page_text_cache[key] = None
            return None
        _doc_cache[filename] = doc
    if page < 1 or page > doc.page_count:
        _page_text_cache[key] = None
        return None
    text = doc.load_page(page - 1).get_text("text")
    norm = normalize(text)
    _page_text_cache[key] = norm
    return norm


def load_citations(directory: str, pattern: str) -> list[dict]:
    import glob
    out = []
    for path in sorted(glob.glob(os.path.join(directory, pattern))):
        with open(path, "r", encoding="utf-8") as f:
            for lineno, line in enumerate(f, start=1):
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError as exc:
                    print(f"FATAL: {path}:{lineno} invalid JSON: {exc}", file=sys.stderr)
                    sys.exit(2)
                obj["_line"] = f"{os.path.basename(path)}:{lineno}"
                out.append(obj)
    return out


def main() -> int:
    citations = load_citations(CITATIONS_DIR, CITATIONS_GLOB)
    if not citations:
        print("No citations file found or it is empty.")
        print("citations verified 0/0")
        return 0

    total = len(citations)
    ok = 0
    failures = []

    for c in citations:
        cid = c.get("id", f"line{c.get('_line')}")
        filename = c.get("file")
        page = c.get("page")
        quote = c.get("quote", "")

        if not filename or not isinstance(page, int):
            failures.append((cid, "missing file/page"))
            continue

        page_text = get_page_text(filename, page)
        if page_text is None:
            failures.append((cid, f"could not open {filename} page {page}"))
            continue

        norm_quote = normalize(quote)
        if not norm_quote:
            failures.append((cid, "empty quote"))
            continue

        if norm_quote in page_text:
            ok += 1
        else:
            failures.append((cid, f"quote not found on {filename} p.{page}: {quote!r}"))

    print(f"Checked {total} citations from {os.path.join(CITATIONS_DIR, CITATIONS_GLOB)}")
    if failures:
        print(f"\n{len(failures)} FAILED citation(s):")
        for cid, reason in failures:
            print(f"  - {cid}: {reason}")
        print(
            "\nPer protocol these must be DELETED from every downstream "
            "document (syllabus JSON, comparison tables, report), not "
            "'fixed'."
        )

    print(f"\ncitations verified {ok}/{total}")
    return 0 if ok == total else 1


if __name__ == "__main__":
    raise SystemExit(main())
