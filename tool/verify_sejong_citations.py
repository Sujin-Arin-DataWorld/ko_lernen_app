"""Q-S / Q-S2 anti-hallucination gate: re-verify every Sejong-book citation.

Every factual claim about a Sejong textbook produced anywhere in the Q-S /
Q-S2 audit (syllabus JSON, comparison tables, the level-map, the final
report) must carry a `file` + `page` (1-based) and, where it quotes book
text, the quoted string. This script is the single source of truth for "is
that citation real".

Two citation kinds, two verification paths:

  - EXACT (no "tag" field, or `"tag": "exact"`): the source PDF has a real
    PyMuPDF text layer on that page (Q-S, 2026-09-16). Re-opens the actual
    PDF (never trusts the scratchpad extract or memory), pulls that page's
    text with PyMuPDF, whitespace-normalizes both sides, and requires the
    quote to be an exact substring.

  - OCR (`"tag": "ocr"`, added Q-S2, 2026-09-16): the source PDF is a scanned
    image with NO PyMuPDF text layer -- the only text available is what
    `tool/sejong/ocr_sejong_pages.py` produced with Windows.Media.Ocr and
    saved to the out-of-repo scratchpad (`<page>.txt` per file). OCR is not
    pixel-perfect (see that script's docstring for confirmed misread
    patterns), so an exact-substring check would fail on correct citations
    for trivial character-level reasons. Instead this re-opens the actual
    OCR text file for that page (never trusts the syllabus JSON or memory)
    and requires the quote to match some contiguous span of it with
    normalized Levenshtein similarity >= 0.9 (whitespace/punctuation
    stripped from both sides first) -- documented, fixed threshold, not
    tuned per-citation.

Citations live in `docs/data/sejong/citations*.jsonl`, one JSON object per
line:
    {"id": "...", "file": "<pdf filename>", "page": <int>, "quote": "<string
     that must appear on that page, exactly or fuzzily depending on tag>",
     "context": "<where this fact is used>", "tag": "exact"|"ocr"}
`tag` defaults to "exact" when absent (all Q-S-phase citations predate the
OCR tag and are exact).

Usage:
    python tool/verify_sejong_citations.py
Exit code is 0 iff every citation verifies; the last stdout line is always
"citations verified TOTAL_OK/TOTAL (exact EOK/ETOTAL, ocr OOK/OTOTAL)".
"""
from __future__ import annotations

import glob
import json
import os
import re
import sys

import fitz  # PyMuPDF

SEJONG_DIR = r"C:\Users\vjinn\ELibrary\Downloads\세종학당 학국어 레벨별 학습자료 참고"
HERE = os.path.dirname(os.path.abspath(__file__))  # .../tool
REPO_ROOT = os.path.dirname(HERE)  # repo root
CITATIONS_DIR = os.path.join(REPO_ROOT, "docs", "data", "sejong")
CITATIONS_GLOB = "citations*.jsonl"  # citations.jsonl (Phase 2) + citations_*.jsonl (level-map, Phase 3, report, ocr)

OCR_SCRATCH_ROOT = (
    r"C:\Users\vjinn\AppData\Local\Temp\claude\\"
    r"C--Users-vjinn-OneDrive-Desktop-hangulsori-ko-lernen-app\\"
    r"9ba4cf1a-a043-4558-928b-92a864ff3701\scratchpad\sejong_ocr"
)
# filename -> book_key, must match tool/sejong/ocr_sejong_pages.py::BOOKS
OCR_FILE_TO_BOOK_KEY = {
    "세종학당 한국어 입문(영어)_(low file size).pdf": "ipmun",
    "세종학당 한국어 1 익힘책_한국어.pdf": "b1_workbook",
    "세종학당 한국어 2 익힘책_영어.pdf": "b2_workbook",
    "세종학당 한국어 3A(영어)_(low file size).pdf": "b3a",
    "세종학당 한국어 3B(영어)_(low file size).pdf": "b3b",
    "세종학당 한국어4A_영어.pdf": "b4a",
    "세종학당 한국어 4B(영어)_(low file size).pdf": "b4b",
}

FUZZY_THRESHOLD = 0.9

_WS_RE = re.compile(r"\s+")
_PUNCT_RE = re.compile(r"[.,!?;:'\"()\[\]{}·…~/『』「」《》〈〉%]")
_page_text_cache: dict[tuple[str, int], str] = {}
_doc_cache: dict[str, "fitz.Document"] = {}
_ocr_text_cache: dict[tuple[str, int], str | None] = {}


def normalize(s: str) -> str:
    return _WS_RE.sub(" ", s or "").strip()


def normalize_fuzzy(s: str) -> str:
    """Whitespace AND punctuation stripped -- used only for the OCR fuzzy
    path, where punctuation is one of the least reliable things OCR gets
    right and shouldn't count against a match."""
    s = _PUNCT_RE.sub("", s or "")
    s = _WS_RE.sub("", s)
    return s.strip()


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


def get_ocr_page_text(filename: str, page: int) -> str | None:
    key = (filename, page)
    if key in _ocr_text_cache:
        return _ocr_text_cache[key]
    book_key = OCR_FILE_TO_BOOK_KEY.get(filename)
    if book_key is None:
        _ocr_text_cache[key] = None
        return None
    path = os.path.join(OCR_SCRATCH_ROOT, book_key, f"{page}.txt")
    if not os.path.isfile(path):
        _ocr_text_cache[key] = None
        return None
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    norm = normalize_fuzzy(text)
    _ocr_text_cache[key] = norm
    return norm


def levenshtein(a: str, b: str) -> int:
    if a == b:
        return 0
    la, lb = len(a), len(b)
    if la == 0:
        return lb
    if lb == 0:
        return la
    prev = list(range(lb + 1))
    for i, ca in enumerate(a, start=1):
        cur = [i] + [0] * lb
        for j, cb in enumerate(b, start=1):
            cost = 0 if ca == cb else 1
            cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
        prev = cur
    return prev[lb]


def levenshtein_similarity(a: str, b: str) -> float:
    if not a and not b:
        return 1.0
    dist = levenshtein(a, b)
    return 1.0 - dist / max(len(a), len(b))


def fuzzy_contains(quote_norm: str, page_norm: str, threshold: float = FUZZY_THRESHOLD) -> tuple[bool, float]:
    """Best-effort: is some contiguous span of page_norm within
    Levenshtein similarity >= threshold of quote_norm? Both inputs must
    already be normalize_fuzzy()'d. Slides windows of a few lengths around
    len(quote_norm) across the page text -- page texts here are single
    OCR'd pages (a few hundred to a couple thousand chars), so this is cheap."""
    if not quote_norm:
        return False, 0.0
    if quote_norm in page_norm:
        return True, 1.0
    L = len(quote_norm)
    best = 0.0
    for wlen in sorted({max(1, L - 2), max(1, L - 1), L, L + 1, L + 2}):
        limit = len(page_norm) - wlen + 1
        if limit <= 0:
            continue
        for i in range(limit):
            window = page_norm[i:i + wlen]
            sim = levenshtein_similarity(quote_norm, window)
            if sim > best:
                best = sim
                if best >= threshold:
                    return True, best
    return best >= threshold, best


def load_citations(directory: str, pattern: str) -> list[dict]:
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
        print("citations verified 0/0 (exact 0/0, ocr 0/0)")
        return 0

    exact_total = ocr_total = exact_ok = ocr_ok = 0
    failures = []

    for c in citations:
        cid = c.get("id", f"line{c.get('_line')}")
        filename = c.get("file")
        page = c.get("page")
        quote = c.get("quote", "")
        tag = c.get("tag", "exact")

        if not filename or not isinstance(page, int):
            failures.append((cid, tag, "missing file/page"))
            continue

        if tag == "ocr":
            ocr_total += 1
            page_text = get_ocr_page_text(filename, page)
            if page_text is None:
                failures.append((cid, tag, f"no OCR text found for {filename} page {page}"))
                continue
            norm_quote = normalize_fuzzy(quote)
            if not norm_quote:
                failures.append((cid, tag, "empty quote"))
                continue
            matched, score = fuzzy_contains(norm_quote, page_text)
            if matched:
                ocr_ok += 1
            else:
                failures.append((cid, tag, f"best fuzzy similarity {score:.2f} < {FUZZY_THRESHOLD} on {filename} p.{page}: {quote!r}"))
        else:
            exact_total += 1
            page_text = get_page_text(filename, page)
            if page_text is None:
                failures.append((cid, tag, f"could not open {filename} page {page}"))
                continue
            norm_quote = normalize(quote)
            if not norm_quote:
                failures.append((cid, tag, "empty quote"))
                continue
            if norm_quote in page_text:
                exact_ok += 1
            else:
                failures.append((cid, tag, f"quote not found on {filename} p.{page}: {quote!r}"))

    total = exact_total + ocr_total
    ok = exact_ok + ocr_ok

    print(f"Checked {total} citations from {os.path.join(CITATIONS_DIR, CITATIONS_GLOB)}")
    if failures:
        print(f"\n{len(failures)} FAILED citation(s):")
        for cid, tag, reason in failures:
            print(f"  - [{tag}] {cid}: {reason}")
        print(
            "\nPer protocol these must be DELETED from every downstream "
            "document (syllabus JSON, comparison tables, report), not "
            "'fixed'."
        )

    print(f"\ncitations verified {ok}/{total} (exact {exact_ok}/{exact_total}, ocr {ocr_ok}/{ocr_total})")
    return 0 if ok == total else 1


if __name__ == "__main__":
    raise SystemExit(main())
