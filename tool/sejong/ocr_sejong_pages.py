"""Q-S2: chunked OCR driver for the scanned (0%-text-layer) Sejong main-series
textbooks, using the local Windows built-in OCR engine (Windows.Media.Ocr,
`ko` recognizer -- confirmed present on this machine via
`OcrEngine.AvailableRecognizerLanguages` / `TryCreateFromLanguage("ko")`;
no cloud OCR is used anywhere in this pipeline).

Why this engine: it was first in the required try-order and it works (no
DISM/admin install needed -- `Get-WindowsCapability` requires elevation on
this machine, but the WinRT recognizer for `ko` is already present and
loadable without it). `easyocr` / `rapidocr_onnxruntime` were not installed
and were not needed once Windows OCR was confirmed available.

Known limitation (documented, not silently worked around): Windows.Media.Ocr
does not expose per-word/per-line confidence scores anywhere in its public
API (verified by reflection: OcrWord has only Text/BoundingRect). This driver
computes a *proxy* quality score per page from the recognized character
distribution -- the fraction of non-whitespace characters that are Hangul
syllables/jamo, ASCII letters, digits, or common CJK punctuation, versus
"garbage" characters (encoding artifacts, private-use-area glyphs, etc.).
This proxy is reported everywhere as "ocr_quality_proxy", never relabeled as
"confidence".

Design (per Q-S2 brief): never run one command >10 min. This script processes
one bounded chunk (default 100 pages) per invocation and persists a
resumable per-book progress.json so repeated invocations continue where the
last one left off. It does not call itself in a loop; the caller (agent
session) invokes it repeatedly with --start advancing, or omits --start to
auto-resume from the first not-yet-done page.

Layout (OUTSIDE the repo -- copyright: raw page renders/text never committed):
  <SCRATCH_ROOT>/<book_key>/render/<page>.png   -- PyMuPDF page render, 200dpi
  <SCRATCH_ROOT>/<book_key>/<page>.raw.json     -- raw Windows OCR result (ps1 output)
  <SCRATCH_ROOT>/<book_key>/<page>.json         -- final structured result (+ proxy score)
  <SCRATCH_ROOT>/<book_key>/<page>.txt          -- plain OCR text for that page
  <SCRATCH_ROOT>/<book_key>/progress.json       -- resumable progress + stats
  <SCRATCH_ROOT>/<book_key>/crops/<page>.png    -- saved for the 20 "consequential claim" pages only

Usage:
    python tool/sejong/ocr_sejong_pages.py --book seomun --count 100
    python tool/sejong/ocr_sejong_pages.py --book seomun --start 101 --count 100
    python tool/sejong/ocr_sejong_pages.py --list         # show all books + progress
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
import unicodedata

import fitz  # PyMuPDF

SEJONG_DIR = r"C:\Users\vjinn\ELibrary\Downloads\세종학당 학국어 레벨별 학습자료 참고"
SCRATCH_ROOT = (
    r"C:\Users\vjinn\AppData\Local\Temp\claude\\"
    r"C--Users-vjinn-OneDrive-Desktop-hangulsori-ko-lernen-app\\"
    r"9ba4cf1a-a043-4558-928b-92a864ff3701\scratchpad\sejong_ocr"
)
HERE = os.path.dirname(os.path.abspath(__file__))
PS1_PATH = os.path.join(HERE, "ocr_batch.ps1")
DPI = 200

# Main-series 교재 (Q-S2 scope). Levels 1 and 2 have NO standalone 교재 file
# in the folder (confirmed against the Q-S Phase-1 inventory and a fresh
# `find`/`ls` of the folder on 2026-09-16) -- only their 익힘책 exist. Those
# 익힘책 are used here as the best-available main-series substitute for
# those two levels and are labeled as such everywhere downstream.
BOOKS = {
    "ipmun":  {"file": "세종학당 한국어 입문(영어)_(low file size).pdf", "level": "below-A1 (입문)", "role": "main_textbook"},
    "b1_workbook": {"file": "세종학당 한국어 1 익힘책_한국어.pdf", "level": "A1 (1)", "role": "workbook_substitute_for_missing_textbook"},
    "b2_workbook": {"file": "세종학당 한국어 2 익힘책_영어.pdf", "level": "A2 (2)", "role": "workbook_substitute_for_missing_textbook"},
    "b3a": {"file": "세종학당 한국어 3A(영어)_(low file size).pdf", "level": "B1 (3A)", "role": "main_textbook"},
    "b3b": {"file": "세종학당 한국어 3B(영어)_(low file size).pdf", "level": "B1 (3B)", "role": "main_textbook"},
    "b4a": {"file": "세종학당 한국어4A_영어.pdf", "level": "B2 (4A)", "role": "main_textbook"},
    "b4b": {"file": "세종학당 한국어 4B(영어)_(low file size).pdf", "level": "B2 (4B)", "role": "main_textbook"},
}

HANGUL_SYLLABLE_RE = re.compile(r"[\uac00-\ud7a3]")
HANGUL_JAMO_RE = re.compile(r"[\u1100-\u11ff\u3130-\u318f]")
LATIN_DIGIT_RE = re.compile(r"[A-Za-z0-9]")
COMMON_PUNCT_RE = re.compile(r"[\s.,!?%()\[\]{}:;\"'\-·…~/『』「」《》〈〉,。、·%＋+=]")


def safe_name(filename: str) -> str:
    base = os.path.splitext(filename)[0]
    base = unicodedata.normalize("NFC", base)
    base = re.sub(r"[^0-9A-Za-z가-힣_\-]+", "_", base)
    return base.strip("_")[:80] or "file"


def ocr_quality_proxy(text: str) -> float:
    """Proxy for OCR quality (NOT an engine confidence -- see module docstring).

    Fraction of non-whitespace characters that fall in an expected script
    class (Hangul syllable/jamo, Latin letter, digit, or common punctuation).
    A page of near-total garbage (encoding artifacts, private-use glyphs)
    scores near 0; clean recognized Korean/English text scores near 1.
    """
    chars = [c for c in text if not c.isspace()]
    if not chars:
        return 0.0
    good = 0
    for c in chars:
        if HANGUL_SYLLABLE_RE.match(c) or HANGUL_JAMO_RE.match(c) or LATIN_DIGIT_RE.match(c) or COMMON_PUNCT_RE.match(c):
            good += 1
    return round(good / len(chars), 4)


def load_progress(book_dir: str, book_key: str, filename: str, total_pages: int) -> dict:
    path = os.path.join(book_dir, "progress.json")
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            prog = json.load(f)
        return prog
    return {
        "book_key": book_key,
        "file": filename,
        "total_pages": total_pages,
        "engine": "windows_media_ocr_ko",
        "dpi": DPI,
        "done_pages": {},  # page(str) -> {"chars": n, "ocr_quality_proxy": q}
        "failed_pages": [],
        "started": time.strftime("%Y-%m-%d %H:%M:%S"),
        "last_updated": None,
    }


def save_progress(book_dir: str, prog: dict) -> None:
    path = os.path.join(book_dir, "progress.json")
    prog["last_updated"] = time.strftime("%Y-%m-%d %H:%M:%S")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(prog, f, ensure_ascii=False, indent=2)


def render_pages(pdf_path: str, render_dir: str, pages: list[int], dpi: int) -> None:
    os.makedirs(render_dir, exist_ok=True)
    to_render = [p for p in pages if not os.path.exists(os.path.join(render_dir, f"{p}.png"))]
    if not to_render:
        return
    doc = fitz.open(pdf_path)
    zoom = dpi / 72.0
    mat = fitz.Matrix(zoom, zoom)
    for p in to_render:
        page = doc.load_page(p - 1)  # 0-based
        pix = page.get_pixmap(matrix=mat)
        pix.save(os.path.join(render_dir, f"{p}.png"))
    doc.close()


def run_ocr_batch(manifest: list[dict], out_dir: str, timeout_s: int = 540) -> str:
    manifest_path = os.path.join(out_dir, "_manifest_chunk.json")
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False)
    cmd = [
        "powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass",
        "-File", PS1_PATH,
        "-ManifestPath", manifest_path,
        "-OutDir", out_dir,
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout_s, encoding="utf-8", errors="replace")
    if proc.returncode != 0:
        print("POWERSHELL STDERR:\n", proc.stderr, file=sys.stderr)
    return proc.stdout


def process_chunk(book_key: str, start: int | None, count: int, dpi: int = DPI) -> None:
    if book_key not in BOOKS:
        print(f"Unknown book key: {book_key}. Known: {list(BOOKS)}", file=sys.stderr)
        sys.exit(2)
    meta = BOOKS[book_key]
    filename = meta["file"]
    pdf_path = os.path.join(SEJONG_DIR, filename)
    if not os.path.isfile(pdf_path):
        print(f"ERROR: PDF not found: {pdf_path}", file=sys.stderr)
        sys.exit(2)

    doc = fitz.open(pdf_path)
    total_pages = doc.page_count
    doc.close()

    book_dir = os.path.join(SCRATCH_ROOT, book_key)
    os.makedirs(book_dir, exist_ok=True)
    render_dir = os.path.join(book_dir, "render")

    prog = load_progress(book_dir, book_key, filename, total_pages)

    if start is None:
        # auto-resume: first page not in done_pages
        start = 1
        while str(start) in prog["done_pages"] and start <= total_pages:
            start += 1

    end = min(start + count - 1, total_pages)
    if start > total_pages:
        print(f"[{book_key}] already complete: {len(prog['done_pages'])}/{total_pages} pages done.")
        return

    target_pages = [p for p in range(start, end + 1) if str(p) not in prog["done_pages"]]
    print(f"[{book_key}] {filename}\n  total_pages={total_pages} chunk={start}-{end} to_process={len(target_pages)}")

    if not target_pages:
        print(f"[{book_key}] chunk {start}-{end} already done.")
        return

    t0 = time.time()
    render_pages(pdf_path, render_dir, target_pages, dpi)
    t1 = time.time()
    print(f"  render done in {t1 - t0:.1f}s")

    manifest = [{"page": p, "png": os.path.join(render_dir, f"{p}.png")} for p in target_pages]
    stdout = run_ocr_batch(manifest, book_dir)
    t2 = time.time()
    print(f"  ocr done in {t2 - t1:.1f}s :: {stdout.strip()}")

    ok = 0
    fail = 0
    for p in target_pages:
        raw_path = os.path.join(book_dir, f"{p}.raw.json")
        if not os.path.exists(raw_path):
            prog["failed_pages"].append(p)
            fail += 1
            continue
        with open(raw_path, "r", encoding="utf-8-sig") as f:
            raw = json.load(f)
        text = raw.get("text", "") or ""
        if raw.get("error"):
            prog["failed_pages"].append(p)
            fail += 1
            continue
        q = ocr_quality_proxy(text)
        # final structured json (line boxes, no fabricated confidence)
        final = {
            "page": p,
            "file": filename,
            "engine": "windows_media_ocr_ko",
            "dpi": dpi,
            "text_angle": raw.get("text_angle"),
            "image_width": raw.get("image_width"),
            "image_height": raw.get("image_height"),
            "ocr_quality_proxy": q,
            "lines": raw.get("lines", []),
        }
        with open(os.path.join(book_dir, f"{p}.json"), "w", encoding="utf-8") as f:
            json.dump(final, f, ensure_ascii=False, indent=1)
        with open(os.path.join(book_dir, f"{p}.txt"), "w", encoding="utf-8") as f:
            f.write(text)
        prog["done_pages"][str(p)] = {"chars": len(text.strip()), "ocr_quality_proxy": q}
        os.remove(raw_path)
        ok += 1

    save_progress(book_dir, prog)
    print(f"  chunk result: ok={ok} fail={fail} total_done={len(prog['done_pages'])}/{total_pages}")


def list_status() -> None:
    for key, meta in BOOKS.items():
        book_dir = os.path.join(SCRATCH_ROOT, key)
        prog_path = os.path.join(book_dir, "progress.json")
        pdf_path = os.path.join(SEJONG_DIR, meta["file"])
        total = "?"
        if os.path.isfile(pdf_path):
            try:
                d = fitz.open(pdf_path)
                total = d.page_count
                d.close()
            except Exception:
                pass
        done = 0
        failed = 0
        mean_q = None
        if os.path.exists(prog_path):
            with open(prog_path, "r", encoding="utf-8") as f:
                prog = json.load(f)
            done = len(prog.get("done_pages", {}))
            failed = len(prog.get("failed_pages", []))
            qs = [v["ocr_quality_proxy"] for v in prog.get("done_pages", {}).values()]
            mean_q = round(sum(qs) / len(qs), 4) if qs else None
        exists = "EXISTS" if os.path.isfile(pdf_path) else "MISSING"
        print(f"{key:14s} [{meta['level']:12s}] {meta['file']:55s} {exists:8s} total={total} done={done} failed={failed} mean_quality_proxy={mean_q}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--book", type=str)
    ap.add_argument("--start", type=int, default=None)
    ap.add_argument("--count", type=int, default=100)
    ap.add_argument("--dpi", type=int, default=DPI)
    ap.add_argument("--list", action="store_true")
    args = ap.parse_args()

    if args.list or not args.book:
        list_status()
        return 0

    process_chunk(args.book, args.start, args.count, args.dpi)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
