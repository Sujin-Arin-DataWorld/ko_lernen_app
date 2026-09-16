"""Q-S2 Phase 2: syllabus extraction from OCR'd Sejong MAIN-SERIES textbooks.

Q-S (Phase 1, 2026-09-16) found the 세종학당 한국어 main-course 교재 for
입문/1/2/3A/3B/4A/4B were 0% text-layer (scanned images) and substituted the
세종한국어 회화 series for A1-B2. Q-S2 OCR's the actual main-series books
(see tool/sejong/ocr_sejong_pages.py; engine = Windows.Media.Ocr "ko",
2,017/2,017 target pages OCR'd, 0 failures) and rebuilds A1-B2 syllabus data
FROM THE REAL MAIN SERIES for the first time.

Source books actually on disk (confirmed 2026-09-16 -- see module docstring
of ocr_sejong_pages.py for the full discrepancy note):
  - A1 (Sejong 1): NO standalone 교재 file exists in the folder -- only the
    익힘책 (workbook), `세종학당 한국어 1 익힘책_한국어.pdf`. Used here as
    the best-available main-series substitute. House style: unit answer key
    has "어휘 연습" (vocab practice) numbered answers, but grammar practice
    is unlabeled ("문법 연습 #1/#2/#3" -- no inline pattern string). Grammar
    extraction was NOT attempted for A1 from this OCR pass (reported as a
    scope limitation); vocabulary WAS extracted.
  - A2 (Sejong 2): same situation, `세종학당 한국어 2 익힘책_영어.pdf`.
  - B1 (Sejong 3): `세종학당 한국어 3A/3B(영어)_(low file size).pdf` --
    genuine main-course 교재. House style: unit answer key has an explicit
    "문법 (LABEL)" / "부가문법(LABEL)" line per grammar point (directly
    citable) AND an "어휘" numbered vocab-answer list. Both grammar AND
    vocab extracted -- this is the FIRST time B1 main-series content has
    been extractable at all (Q-S Phase 1: 0% text, NOT_EXTRACTABLE).
  - B2 (Sejong 4): same house style, `세종학당 한국어4A_영어.pdf` +
    `세종학당 한국어 4B(영어)_(low file size).pdf`.
  - 입문 (below-A1): OCR'd in full (261/261 pages) but is a Hangul
    alphabet/writing-practice primer (consonant/vowel drill tables), not a
    CEFR-comparable grammar/vocab syllabus. No grammar/vocab extraction
    attempted -- this is a genuine content-type mismatch, not a gap.

OCR-noise handling (documented, not silently "fixed"): candidate
character-level OCR misreads were tested by cropping the actual page render
(200dpi PNG) around the offending token's bounding box and visually
inspecting the crop BEFORE being trusted as a blanket substitution rule.
Two rules survived that test; a third was falsified and deliberately
dropped:
  1. KEPT (confirmed twice: b3a p.231 "슨다" is genuinely "-는다"; b4a
     p.230 "슨 김에" is genuinely "-는 김에"): a leading "슨" immediately
     before another syllable is Windows OCR's misread of "-는" (hyphen
     dropped, initial consonant ㄴ misread as ㅅ).
  2. KEPT (confirmed: b3a p.230 "-어0F" is genuinely "-어야"): the
     substring "0F" inside a label is a misread of "야".
  3. REJECTED: a leading "떠" looked like it might always mean "-어"
     (b3a p.229 "떠도" -> genuinely "-어도"), but a second sample falsified
     this as a general rule (b4a p.231 "떠니" -> genuinely "-더니", a
     *different* source consonant, ㄷ not ㅇ). "떠" is ambiguous between two
     distinct grammar patterns and is deliberately left un-normalized.
Any label still containing "떠", or any other non-hangul-punct garbage,
after rules 1-2 returns `normalized: null` (kept in `raw_ocr`, excluded from
the grammar comparison) -- reported as OCR noise, not guessed at.

Every fact is written to `docs/data/sejong/citations_ocr.jsonl` with a
`"tag": "ocr"` field so `tool/verify_sejong_citations.py` checks it with the
fuzzy (Levenshtein similarity >= 0.9) matcher against the OCR text, not the
(nonexistent) PyMuPDF text layer.

Output:
  docs/data/sejong/syllabus_sejong{1,2,3,4}_ocr.json
  docs/data/sejong/citations_ocr.jsonl
"""
from __future__ import annotations

import json
import os
import re

SCRATCH_ROOT = (
    r"C:\Users\vjinn\AppData\Local\Temp\claude\\"
    r"C--Users-vjinn-OneDrive-Desktop-hangulsori-ko-lernen-app\\"
    r"9ba4cf1a-a043-4558-928b-92a864ff3701\scratchpad\sejong_ocr"
)
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT_DIR = os.path.join(REPO_ROOT, "docs", "data", "sejong")
CITATIONS_PATH = os.path.join(OUT_DIR, "citations_ocr.jsonl")

# level -> list of (book_key, pdf filename, role)
LEVEL_BOOKS = {
    "A1": [("b1_workbook", "세종학당 한국어 1 익힘책_한국어.pdf", "workbook_substitute")],
    "A2": [("b2_workbook", "세종학당 한국어 2 익힘책_영어.pdf", "workbook_substitute")],
    "B1": [
        ("b3a", "세종학당 한국어 3A(영어)_(low file size).pdf", "main_textbook"),
        ("b3b", "세종학당 한국어 3B(영어)_(low file size).pdf", "main_textbook"),
    ],
    "B2": [
        ("b4a", "세종학당 한국어4A_영어.pdf", "main_textbook"),
        ("b4b", "세종학당 한국어 4B(영어)_(low file size).pdf", "main_textbook"),
    ],
}
SEJONG_N = {"A1": 1, "A2": 2, "B1": 3, "B2": 4}

GRAMMAR_LABEL_RE = re.compile(r"(부가\s*문법)\s*\(([^)]{1,40})\)|(문법)\s*\(([^)]{1,40})\)")
UNIT_HEADER_RE = re.compile(r"(\d{1,2})과[\s\.\u2022]")

_citations: list[dict] = []


def cite(cid: str, filename: str, page: int, quote: str, context: str) -> None:
    words = quote.split()
    if len(words) > 15:
        quote = " ".join(words[:15])
    _citations.append({"id": cid, "file": filename, "page": page, "quote": quote, "context": context, "tag": "ocr"})


def load_pages(book_key: str) -> dict[int, str]:
    d = os.path.join(SCRATCH_ROOT, book_key)
    pages = {}
    for fn in os.listdir(d):
        if fn.endswith(".txt"):
            page = int(fn[:-4])
            with open(os.path.join(d, fn), "r", encoding="utf-8") as f:
                pages[page] = f.read()
    return pages


def normalize_label(raw: str) -> str | None:
    """Apply only the 2 surviving, visually-confirmed OCR fixes (see module
    docstring for the crop-based verification and the rejected 3rd rule).
    Returns None if the label is still suspicious afterwards -- excluded
    from comparison but kept in raw_ocr for the record."""
    s = raw.strip()
    # rule 1: leading 슨 + more text => "-는" + rest.
    if s.startswith("슨") and len(s) > 1:
        s = "-는" + s[1:]
    # rule 2: 0F -> 야 anywhere in the label.
    s = s.replace("0F", "야").replace("0f", "야")

    # sanity check: must be mostly Hangul/dash/punct/digits-as-suffix, and
    # must not still contain the ambiguous, deliberately-unfixed "떠" prefix.
    bad = re.sub(r"[\uac00-\ud7a3\u1100-\u11ff\-()\s,./?!0-9]", "", s)
    if bad or s.startswith("떠"):
        return None
    return s


def extract_grammar(book_key: str, filename: str, level: str, pages: dict[int, str]) -> list[dict]:
    items = []
    seen_raw = set()
    for page in sorted(pages):
        text = pages[page]
        for m in GRAMMAR_LABEL_RE.finditer(text):
            is_extra = m.group(1) is not None
            raw_label = (m.group(2) or m.group(4) or "").strip()
            if not raw_label or raw_label in seen_raw:
                continue
            seen_raw.add(raw_label)
            norm = normalize_label(raw_label)
            quote = ("부가문법" if is_extra else "문법") + f"({raw_label})"
            cite(f"ocr_gram_{book_key}_{page}_{len(items)}", filename, page, quote,
                 f"{level} grammar label extracted from OCR answer-key, book={book_key}")
            items.append({
                "raw_ocr": raw_label,
                "normalized": norm,
                "is_additional_grammar": is_extra,
                "page": page,
                "source_file": filename,
                "book_key": book_key,
            })
    return items


VOCAB_HEADER_RE = re.compile(r"어휘(?:\s*연습)?")
SECTION_STOP_RE = re.compile(r"문법|부가\s*문법|듣기|말하기|읽기|쓰기|과제")
MARKER_RE = re.compile(r"(\d+)\)|(기)(?=\s|[가-힣])")
# Circled-letter/number glyphs used by a DIFFERENT exercise type (matching
# exercises: "1) <choice A> <choice B>" where choices are labelled with
# circled Hangul consonant markers, e.g. b1_workbook p.193 "1) <circled>
# shinbal <circled>gabang"). Any captured item containing one of these is a
# mis-parsed multiple-choice pair, not a target-vocabulary word, and the
# whole run is dropped (confirmed by reading the actual page text).
CIRCLED_GLYPH_RE = re.compile("[①-⓿㈀-㋿]")
# The group-1/group-2 divider inside "어휘 N 1) w1 기 w2 3) w3 4) w4 N 1)..."
# is a bare digit with NO closing paren (e.g. the "2" in "...4) 회장 2 1)
# 가입했어요..." on b3a p.228). Because the next real marker the scanner
# stops at is the following group's "1)", that bare divider digit ends up
# trailing the last captured item's text ("회장 2") -- strip it.
TRAILING_DIVIDER_DIGIT_RE = re.compile(r"\s+\d+$")


def extract_vocab_items_from_span(span: str) -> list[str]:
    matches = list(MARKER_RE.finditer(span))
    items: list[str] = []
    expected = 1
    for i, m in enumerate(matches):
        num = 2 if m.group(2) else int(m.group(1))
        if num != expected:
            if items:
                break
            else:
                continue  # keep scanning for the start of the run
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else min(len(span), start + 40)
        text = span[start:end].strip()
        text = TRAILING_DIVIDER_DIGIT_RE.sub("", text).strip()
        if not text or len(text) > 20 or re.search(r"[.?!]", text) or text.count(" ") > 2:
            break
        if CIRCLED_GLYPH_RE.search(text):
            break  # mis-parsed matching-exercise choice pair, not vocab -- stop this run
        items.append(text)
        expected = num + 1
        if expected > 8:
            break
    return items


def extract_vocab(book_key: str, filename: str, level: str, pages: dict[int, str]) -> list[dict]:
    items = []
    seen = set()
    sorted_pages = sorted(pages)
    for page in sorted_pages:
        text = pages[page]
        for hm in VOCAB_HEADER_RE.finditer(text):
            span = text[hm.end():hm.end() + 300]
            stop = SECTION_STOP_RE.search(span)
            if stop:
                span = span[:stop.start()]
            words = extract_vocab_items_from_span(span)
            for w in words:
                w_clean = re.sub(r"^[\d.\)]+", "", w).strip()
                w_clean = re.sub(r"\s+p\d+$", "", w_clean).strip()
                w_clean = re.sub(r"\s+\d+\s*쪽$", "", w_clean).strip()
                if not w_clean or w_clean in seen:
                    continue
                if not re.search(r"[\uac00-\ud7a3]", w_clean):
                    continue
                if len(w_clean) < 2:
                    continue
                seen.add(w_clean)
                cite(f"ocr_vocab_{book_key}_{page}_{len(items)}", filename, page, w_clean,
                     f"{level} vocabulary answer-key word, book={book_key}")
                items.append({"korean": w_clean, "page": page, "source_file": filename, "book_key": book_key})
    return items


def build_level(level: str) -> dict:
    books = LEVEL_BOOKS[level]
    grammar_items: list[dict] = []
    vocab_items: list[dict] = []
    unit_pages: dict[str, int] = {}
    for book_key, filename, role in books:
        pages = load_pages(book_key)
        if not pages:
            continue
        for page in sorted(pages):
            for um in UNIT_HEADER_RE.finditer(pages[page]):
                unit_pages.setdefault(f"{book_key}_{um.group(1)}", page)
        if role == "main_textbook":
            grammar_items.extend(extract_grammar(book_key, filename, level, pages))
        vocab_items.extend(extract_vocab(book_key, filename, level, pages))

    return {
        "level": level,
        "sejong_n": SEJONG_N[level],
        "source_files": [f for _, f, _ in books],
        "source_role": books[0][2],
        "engine": "windows_media_ocr_ko",
        "grammar": grammar_items,
        "vocab": vocab_items,
        "note": (
            "Grammar extraction not attempted (different house style: "
            "'문법 연습 #N' without inline pattern label)."
            if books[0][2] == "workbook_substitute" else
            "Grammar + vocab both extracted from the actual main-course 교재 "
            "answer-key appendix (first time B-level main series is "
            "extractable at all)."
        ),
    }


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    summary = {}
    for level in ["A1", "A2", "B1", "B2"]:
        data = build_level(level)
        n = SEJONG_N[level]
        out_path = os.path.join(OUT_DIR, f"syllabus_sejong{n}_ocr.json")
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        n_gram_norm = sum(1 for g in data["grammar"] if g["normalized"])
        n_gram_raw_only = len(data["grammar"]) - n_gram_norm
        summary[level] = {
            "grammar_total": len(data["grammar"]),
            "grammar_normalized": n_gram_norm,
            "grammar_ocr_noise_excluded": n_gram_raw_only,
            "vocab_total": len(data["vocab"]),
        }
        print(f"{level}: grammar={len(data['grammar'])} (normalized={n_gram_norm}, "
              f"excluded_as_noise={n_gram_raw_only}) vocab={len(data['vocab'])}")

    with open(CITATIONS_PATH, "w", encoding="utf-8") as f:
        for c in _citations:
            f.write(json.dumps(c, ensure_ascii=False) + "\n")
    print(f"\nWrote {len(_citations)} OCR citations to {CITATIONS_PATH}")
    with open(os.path.join(OUT_DIR, "ocr_syllabus_summary.json"), "w", encoding="utf-8") as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
