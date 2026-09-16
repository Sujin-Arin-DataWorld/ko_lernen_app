"""Q-S Phase 1: inventory + raw text extraction for the Sejong Institute textbook PDFs.

Reads the 26 PDFs Jin placed in
`C:\\Users\\vjinn\\ELibrary\\Downloads\\세종학당 학국어 레벨별 학습자료 참고\\`
READ-ONLY (never moves/modifies them). For every page in every PDF it records
whether a usable text layer exists, writes the raw per-page text OUTSIDE the
repo (scratchpad), and produces:

  docs/data/sejong/inventory_2026-09-16.md   -- human-readable inventory
  docs/data/sejong/inventory_2026-09-16.json -- machine-readable inventory
                                                 (consumed by later phases)

Copyright note: only structured facts (page counts, extractable %, short
samples <=15 words) are committed to the repo. Full page text is written only
to the out-of-repo scratchpad directory.
"""
from __future__ import annotations

import json
import os
import re
import sys
import unicodedata
from datetime import date

import fitz  # PyMuPDF

SEJONG_DIR = r"C:\Users\vjinn\ELibrary\Downloads\세종학당 학국어 레벨별 학습자료 참고"
SCRATCH_ROOT = (
    r"C:\Users\vjinn\AppData\Local\Temp\claude\\"
    r"C--Users-vjinn-OneDrive-Desktop-hangulsori-ko-lernen-app\\"
    r"9ba4cf1a-a043-4558-928b-92a864ff3701\scratchpad\sejong_text"
)
OUT_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "docs", "data", "sejong",
)
REPORT_DATE = "2026-09-16"

MIN_CHARS_FOR_TEXT_PAGE = 20  # a page needs at least this many stripped chars
HANGUL_RE = re.compile(r"[\uac00-\ud7a3]")


def safe_name(filename: str) -> str:
    base = os.path.splitext(filename)[0]
    base = unicodedata.normalize("NFC", base)
    base = re.sub(r"[^0-9A-Za-z가-힣_\-]+", "_", base)
    return base.strip("_")[:80] or "file"


def ranges_from_flags(flags: list[bool]) -> list[tuple[int, int, bool]]:
    """Collapse a list of booleans (1-based pages) into (start, end, value) runs."""
    out = []
    if not flags:
        return out
    start = 1
    cur = flags[0]
    for i in range(1, len(flags)):
        if flags[i] != cur:
            out.append((start, i, cur))
            start = i + 1
            cur = flags[i]
    out.append((start, len(flags), cur))
    return out


def fmt_ranges(ranges: list[tuple[int, int, bool]]) -> str:
    parts = []
    for start, end, val in ranges:
        label = "text" if val else "NO_TEXT"
        if start == end:
            parts.append(f"{start}:{label}")
        else:
            parts.append(f"{start}-{end}:{label}")
    return "; ".join(parts)


def process_pdf(path: str) -> dict:
    filename = os.path.basename(path)
    size_bytes = os.path.getsize(path)
    result = {
        "file": filename,
        "size_bytes": size_bytes,
        "size_mb": round(size_bytes / (1024 * 1024), 1),
        "error": None,
    }
    out_dir = os.path.join(SCRATCH_ROOT, safe_name(filename))
    os.makedirs(out_dir, exist_ok=True)

    try:
        doc = fitz.open(path)
    except Exception as exc:  # noqa: BLE001
        result["error"] = f"OPEN_FAILED: {exc}"
        result["page_count"] = 0
        result["text_flags"] = []
        result["samples"] = []
        return result

    n = doc.page_count
    text_flags: list[bool] = []
    hangul_flags: list[bool] = []
    samples: list[str] = []

    combined_path = os.path.join(out_dir, "_all_pages.txt")
    with open(combined_path, "w", encoding="utf-8") as combined_f:
        for i in range(n):
            page = doc.load_page(i)
            try:
                text = page.get_text("text")
            except Exception as exc:  # noqa: BLE001
                text = ""
                result.setdefault("page_errors", []).append(f"page {i+1}: {exc}")
            stripped = text.strip()
            has_text = len(stripped) >= MIN_CHARS_FOR_TEXT_PAGE
            has_hangul = bool(HANGUL_RE.search(stripped))
            text_flags.append(has_text)
            hangul_flags.append(has_hangul)

            combined_f.write(f"\n----- PAGE {i+1} (1-based) -----\n")
            combined_f.write(text)

            if has_text and len(samples) < 3:
                for line in stripped.splitlines():
                    line = line.strip()
                    if len(line) >= 4:
                        samples.append(f"p.{i+1}: {line[:60]}")
                        break

    doc.close()

    n_text = sum(text_flags)
    n_hangul = sum(hangul_flags)
    result["page_count"] = n
    result["pages_with_text"] = n_text
    result["pages_with_hangul"] = n_hangul
    result["extractable_pct"] = round(100.0 * n_text / n, 1) if n else 0.0
    result["text_flags"] = text_flags
    result["ranges"] = fmt_ranges(ranges_from_flags(text_flags))
    result["samples"] = samples
    result["scratch_dir"] = out_dir
    return result


def classify_book(filename: str) -> dict:
    """Best-effort, filename-only classification. No content inference."""
    fn = filename
    level = None
    for lv in ["입문", "1", "2", "3A", "3B", "4A", "4B", "5A", "5B", "6A", "6B"]:
        pass
    # level tokens must be matched carefully (order matters: 3A before 3, etc.)
    level_patterns = [
        ("입문", r"입문"),
        ("3A", r"3A"),
        ("3B", r"3B"),
        ("4A", r"4A"),
        ("4B", r"4B"),
        ("5A", r"5A"),
        ("5B", r"5B"),
        ("6A", r"6A"),
        ("6B", r"6B"),
        ("1", r"(?<![0-9A-Za-z])1(?![0-9A-Za-z권])"),
        ("2", r"(?<![0-9A-Za-z])2(?![0-9A-Za-z권])"),
    ]
    for lv, pat in level_patterns:
        if re.search(pat, fn):
            level = lv
            break

    if "어휘사전" in fn:
        kind = "vocab_dictionary"
    elif "핸드북" in fn:
        kind = "handbook_vocab_grammar"
    elif "연습문제" in fn:
        kind = "exercise_book"
    elif "익힘책" in fn:
        kind = "workbook"
    else:
        kind = "main_textbook"

    lang = "한국어" if ("한국어)" in fn and "영어" not in fn) or fn.endswith("한국어.pdf") or "_한국어" in fn else (
        "영어" if "영어" in fn else "unspecified"
    )

    return {"level_guess": level, "kind": kind, "lang_guess": lang}


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    if not os.path.isdir(SEJONG_DIR):
        print(f"ERROR: Sejong directory not found: {SEJONG_DIR}", file=sys.stderr)
        return 1

    pdfs = sorted(
        f for f in os.listdir(SEJONG_DIR) if f.lower().endswith(".pdf")
    )
    if not pdfs:
        print("ERROR: no PDFs found", file=sys.stderr)
        return 1

    inventory = []
    for fn in pdfs:
        path = os.path.join(SEJONG_DIR, fn)
        print(f"Processing: {fn} ...", flush=True)
        rec = process_pdf(path)
        rec.update(classify_book(fn))
        inventory.append(rec)
        print(
            f"  pages={rec.get('page_count')} extractable={rec.get('extractable_pct')}% "
            f"error={rec.get('error')}",
            flush=True,
        )

    json_path = os.path.join(OUT_DIR, f"inventory_{REPORT_DATE}.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(
            {
                "generated": REPORT_DATE,
                "source_dir": SEJONG_DIR,
                "file_count": len(inventory),
                "files": [
                    {k: v for k, v in rec.items() if k != "text_flags"}
                    for rec in inventory
                ],
            },
            f,
            ensure_ascii=False,
            indent=2,
        )

    total_pages = sum(r.get("page_count", 0) for r in inventory)
    total_text_pages = sum(r.get("pages_with_text", 0) for r in inventory)
    overall_pct = round(100.0 * total_text_pages / total_pages, 1) if total_pages else 0.0

    md_lines = []
    md_lines.append("# Sejong Institute Textbook Inventory — Q-S Phase 1")
    md_lines.append("")
    md_lines.append(f"Generated: {REPORT_DATE}. Source directory (read-only, never modified):")
    md_lines.append(f"`{SEJONG_DIR}`")
    md_lines.append("")
    md_lines.append(
        f"**{len(inventory)} PDF files found** (the Q-S brief assumed 24 — see "
        "discrepancy notes below). Raw extracted text is kept OUTSIDE this "
        "repo in the session scratchpad; only structured facts and short samples "
        "(<=15 words) are committed here."
    )
    md_lines.append("")
    md_lines.append(
        f"**Overall extractable share: {total_text_pages}/{total_pages} pages "
        f"= {overall_pct}%** (a page counts as extractable if PyMuPDF's text layer "
        f"yields >= {MIN_CHARS_FOR_TEXT_PAGE} stripped characters)."
    )
    md_lines.append("")
    md_lines.append(
        f"Notes on discrepancy from the brief's assumed file list ({len(inventory)} vs "
        "24 assumed): the folder contains **two extra 핸드북(실용 한국어 어휘와 문법) "
        "volumes for level 2 and 3** not named in the brief, and does **not** contain "
        "full-size 교재 for 입문/1/2/3A/3B as separate clean files (only 익힘책, "
        "연습문제, and 'low file size' 교재 variants for some levels exist) — instead "
        "it holds the two-volume **세종한국어 회화 익힘책 영어판 1-1/1-2** (a "
        "*conversation* workbook set, distinct in title from `세종학당 한국어 1 "
        "익힘책`) which is well text-extractable and is the same title "
        "`docs/data/level_bible/F4_sejong1_units.md` was built from. This inventory "
        "reflects what is actually on disk; conclusions in later phases are scoped to "
        "files that exist and are extractable."
    )
    md_lines.append("")
    md_lines.append(
        "**Extractability is highly uneven.** Most 익힘책/연습문제/교재 PDFs for "
        "levels 입문, 2, 3A, 3B, 4A, 4B are scanned image pages with 0% text layer "
        "(PyMuPDF finds no embedded text at all) — this is a scanner/print-to-PDF "
        "artifact of those specific files, not a statement about the books' content. "
        "By contrast 어휘사전(영어판) (100%), 세종한국어 회화 익힘책 1-1/1-2 (97.1%), "
        "익힘책 5A/5B/6A/6B (96.2%), and 한국어_5B (92.4%) have strong text layers. "
        "This means Phase 2/3 syllabus extraction and comparison below is **only "
        "possible for levels 입문(vocab dict only)/1/5/6**, plus a thin sliver of "
        "level 2 via the 1.6%-extractable handbook; **levels 3(B1) and 4(B2) have no "
        "extractable Sejong source text at all in this folder** and are reported as "
        "NOT_EXTRACTABLE, excluded from every content conclusion."
    )
    md_lines.append("")
    md_lines.append(
        "| File | Kind | Level guess | Size (MB) | Pages | Text-layer pages | "
        "Extractable % | Sample lines (<=15 words each) |"
    )
    md_lines.append("|---|---|---|---|---|---|---|---|")
    for rec in inventory:
        samples = "<br>".join(rec.get("samples", [])) or "(none extracted)"
        err = f" **ERROR: {rec['error']}**" if rec.get("error") else ""
        md_lines.append(
            f"| {rec['file']} | {rec['kind']} | {rec.get('level_guess') or '?'} | "
            f"{rec['size_mb']} | {rec.get('page_count', 0)} | "
            f"{rec.get('pages_with_text', 0)} | {rec.get('extractable_pct', 0)}%{err} | "
            f"{samples} |"
        )
    md_lines.append("")
    md_lines.append("## Per-file text-layer page ranges (1-based, yes/no)")
    md_lines.append("")
    for rec in inventory:
        md_lines.append(f"- **{rec['file']}**: {rec.get('ranges', '(n/a)')}")
    md_lines.append("")
    md_lines.append(
        "## NOT_EXTRACTABLE policy\n\n"
        "Any page range flagged `NO_TEXT` above is image-only or garbled for "
        "PyMuPDF's text extraction. Those ranges are excluded from all Phase "
        "2-4 conclusions and are reported as \"not found in extracted text of "
        "<file>\", never as \"not taught\"."
    )

    md_path = os.path.join(OUT_DIR, f"inventory_{REPORT_DATE}.md")
    with open(md_path, "w", encoding="utf-8") as f:
        f.write("\n".join(md_lines) + "\n")

    print(f"\nWrote {json_path}\nWrote {md_path}")
    print(f"TOTAL pages={total_pages} extractable={total_text_pages} ({overall_pct}%)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
