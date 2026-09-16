"""Q-S Phase 2: syllabus extraction from the Sejong Institute textbooks.

Only two families of source PDF in the folder have a usable text layer for
lesson content (see docs/data/sejong/inventory_2026-09-16.md for the full
extractability breakdown):

  A) `세종한국어 회화 익힘책_영어판_{1,2,3,4}-{1,2}.pdf` (8 files, ~97% text)
     -- a *conversation* workbook series, TOPIK levels 1-4, each level split
     into two half-volumes (-1 = units 1-7, -2 = units 8-14). This is the
     same title `docs/data/level_bible/F4_sejong1_units.md` was built from.
     Every unit has:
       - a title + 기능/주제 (can-do) line in the body
       - a 부록 "어휘 색인" (vocab index) page: `N과 / NN쪽 / word<TAB>gloss`
       - a 부록 "문법 설명" (grammar explanation) page: bare label line,
         followed by a KO paragraph starting `'<label>'는/은 ...`, then an EN
         paragraph
     We map these 4 levels directly to our CEFR levels A1/A2/B1/B2 (Sejong's
     own §A mapping in CONTENT_LEVEL_BIBLE.md), NOT to the 입문/3A/3B/4A/4B
     file-naming the Q-S brief assumed -- those main-course files are 0%
     text (scanned images) and cannot be split at the A/B sub-level without
     them. This is a deliberate, documented deviation from the brief.

  B) `세종학당 한국어 익힘책_{5A,5B,6A,6B}.pdf` (4 files, 96.2% text) -- the
     *main*-course workbook for TOPIK 5/6 (~C1/C2). Different house style,
     no separate vocab/grammar index appendix. Units have "익히기 N"
     sub-sections; grammar patterns are introduced as `의미\n'<label>'...`
     (same quoted-label convention as family A). There is no clean headword
     vocab list here (vocab is embedded as bracketed collocations in
     exercises) -- vocab extraction for C1/C2 is therefore NOT attempted;
     this is reported as a scope limitation, not silently skipped.

Every extracted fact is written with its PDF filename + 1-based page number
into `docs/data/sejong/citations.jsonl` (append-only across the whole Q-S
run) so `tool/verify_sejong_citations.py` can re-check it against the actual
PDF text.

Output: `docs/data/sejong/syllabus_sejong{1,2,3,4,5,6}.json`
"""
from __future__ import annotations

import json
import os
import re
import sys

SCRATCH_ROOT = (
    r"C:\Users\vjinn\AppData\Local\Temp\claude\\"
    r"C--Users-vjinn-OneDrive-Desktop-hangulsori-ko-lernen-app\\"
    r"9ba4cf1a-a043-4558-928b-92a864ff3701\scratchpad\sejong_text"
)
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT_DIR = os.path.join(REPO_ROOT, "docs", "data", "sejong")
CITATIONS_PATH = os.path.join(OUT_DIR, "citations.jsonl")

PAGE_MARK_RE = re.compile(r"----- PAGE (\d+) \(1-based\) -----\n")
HANGUL_RE = re.compile(r"[가-힣]")


def load_pages(scratch_dirname: str) -> dict[int, str]:
    path = os.path.join(SCRATCH_ROOT, scratch_dirname, "_all_pages.txt")
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    parts = PAGE_MARK_RE.split(content)
    # parts = ["", "1", text1, "2", text2, ...]
    pages: dict[int, str] = {}
    for i in range(1, len(parts), 2):
        page_no = int(parts[i])
        text = parts[i + 1]
        pages[page_no] = text
    return pages


_citation_records: list[dict] = []


def cite(cid: str, filename: str, page: int, quote: str, context: str) -> dict:
    words = quote.split()
    if len(words) > 15:
        quote = " ".join(words[:15])
    rec = {"id": cid, "file": filename, "page": page, "quote": quote, "context": context}
    _citation_records.append(rec)
    return {"page": page, "quote": quote}


# ---------------------------------------------------------------------------
# Family A: 세종한국어 회화 익힘책 (levels 1-4)
# ---------------------------------------------------------------------------

HOEHWA_FILES = {
    1: ["세종한국어 회화 익힘책_영어판_1-1.pdf", "세종한국어 회화 익힘책_영어판_1-2.pdf"],
    2: ["세종한국어 회화 익힘책_영어판_2-1.pdf", "세종한국어 회화 익힘책_영어판_2-2.pdf"],
    3: ["세종한국어 회화 익힘책_영어판_3-1.pdf", "세종한국어 회화 익힘책_영어판_3-2.pdf"],
    4: ["세종한국어 회화 익힘책_영어판_4-1.pdf", "세종한국어 회화 익힘책_영어판_4-2.pdf"],
}
HOEHWA_SCRATCH = {
    "세종한국어 회화 익힘책_영어판_1-1.pdf": "세종한국어_회화_익힘책_영어판_1-1",
    "세종한국어 회화 익힘책_영어판_1-2.pdf": "세종한국어_회화_익힘책_영어판_1-2",
    "세종한국어 회화 익힘책_영어판_2-1.pdf": "세종한국어_회화_익힘책_영어판_2-1",
    "세종한국어 회화 익힘책_영어판_2-2.pdf": "세종한국어_회화_익힘책_영어판_2-2",
    "세종한국어 회화 익힘책_영어판_3-1.pdf": "세종한국어_회화_익힘책_영어판_3-1",
    "세종한국어 회화 익힘책_영어판_3-2.pdf": "세종한국어_회화_익힘책_영어판_3-2",
    "세종한국어 회화 익힘책_영어판_4-1.pdf": "세종한국어_회화_익힘책_영어판_4-1",
    "세종한국어 회화 익힘책_영어판_4-2.pdf": "세종한국어_회화_익힘책_영어판_4-2",
}

UNIT_HEADER_RE = re.compile(r"^(\d+)\.\s*(.+?)\s*$")
CANDO_RE = re.compile(r".*(수 있어요|수 있습니다|수 있다)\.?\s*$")
DIALOGUE_RE = re.compile(r"^가\s*[:：]\s*(.+[요다까]\??)\s*$")


def parse_toc(pages: dict[int, str]) -> list[tuple[int, str]]:
    """Return [(unit_no, title), ...] from the TOC page (page 5, both -1/-2 files)."""
    text = pages.get(5, "")
    units = []
    for line in text.splitlines():
        m = UNIT_HEADER_RE.match(line.strip())
        if m:
            units.append((int(m.group(1)), m.group(2).strip()))
    return units


APPENDIX_SECTION_ORDER = ["확인 문제 듣기 지문", "정답", "문법 설명", "발음 설명", "어휘 색인"]


def find_section_pages(pages: dict[int, str], label: str) -> list[int]:
    """Pages belonging to an appendix section identified by its running
    label (e.g. "문법 설명"). The label string is not reliably printed on
    EVERY page of its own section (observed: some volumes print it as a
    footer on every page, others only on the section's first page or two,
    dropping it on the last page before the next section starts) -- so we
    do not just look for pages that literally contain the label. Instead we
    use the fixed, known appendix order these books always follow and take
    everything from the first page containing `label` up to (but not
    including) the first page containing the NEXT label in that order. This
    also naturally excludes the earlier TOC mention (front matter is always
    pno<=9, excluded outright).
    """
    def first_page(lbl: str) -> int | None:
        for pno in sorted(pages):
            if pno > 9 and lbl in pages[pno]:
                return pno
        return None

    start = first_page(label)
    if start is None:
        return []

    try:
        idx = APPENDIX_SECTION_ORDER.index(label)
    except ValueError:
        idx = -1
    end = None
    if idx != -1:
        for nxt_label in APPENDIX_SECTION_ORDER[idx + 1:]:
            p = first_page(nxt_label)
            if p is not None:
                end = p - 1
                break
    if end is None or end < start:
        end = max(pages)
    return list(range(start, end + 1))


def parse_vocab_index(pages: dict[int, str], vocab_pages: list[int]) -> dict[int, list[dict]]:
    """{unit_no: [{"korean":..., "gloss":..., "page":...}, ...]}"""
    out: dict[int, list[dict]] = {}
    cur_unit = None
    for pno in vocab_pages:
        raw = pages[pno]
        norm = raw.replace("\t\n", "\t")
        lines = norm.splitlines()
        i = 0
        while i < len(lines):
            line = lines[i].strip("\ufeff\x08 \u2002\t")
            m = re.match(r"^(\d+)과$", line)
            if m:
                cur_unit = int(m.group(1))
                out.setdefault(cur_unit, [])
                i += 1
                # next line is usually "NN쪽" (page ref in the paired main
                # textbook) -- skip it
                if i < len(lines) and re.match(r"^\d+쪽$", lines[i].strip()):
                    i += 1
                continue
            if "\t" in line and cur_unit is not None:
                # Usually one `Korean\tGloss` pair, but longer verb-phrase
                # vocab (unit 9+) sometimes has several entries merged onto
                # one extracted line by the PDF's column layout, e.g.
                # "야구를 보다\tto see a baseball game\t요리를 배우다\tto learn
                # to cook\t...". Walk the whole tab-split token stream as an
                # alternating (Korean, gloss) sequence instead of a single
                # partition, so later pairs in a merged line aren't lost or
                # mis-attached.
                tokens = [t.strip() for t in line.split("\t")]
                kr = tokens[0]
                j = 1
                while j < len(tokens) and kr:
                    gloss = tokens[j]
                    unit_hdr = re.match(r"^(\d+)과$", gloss)
                    page_ref = re.match(r"^\d+쪽$", gloss)
                    if unit_hdr:
                        cur_unit = int(unit_hdr.group(1))
                        out.setdefault(cur_unit, [])
                        kr = tokens[j + 1] if j + 1 < len(tokens) else None
                        j += 2
                        continue
                    if page_ref:
                        j += 1
                        continue
                    if gloss:
                        out[cur_unit].append({"korean": kr, "gloss": gloss, "page": pno})
                    kr = tokens[j + 1] if j + 1 < len(tokens) else None
                    j += 2
            i += 1
    return out


LABEL_LINE_MAX = 30


def parse_grammar_section(pages: dict[int, str], grammar_pages: list[int]) -> dict[int, list[dict]]:
    """{unit_no: [{"label":..., "page":...}, ...]}.

    Every grammar-explanation paragraph in these books restates its own
    label wrapped in curly quotes at the start of the paragraph, e.g.
    "‘을/를’은 문장의 목적어임을 ...". But a quoted word can also start a
    line purely because a long sentence happens to WRAP there mid-sentence
    (e.g. "...붙고 받침이 없는 명사에는
‘예요’가 붙는다." -- "예요" here is not a label, just
    the tail end of a sentence about the real label "이에요/예요"). We
    distinguish a genuine label restatement from a mid-sentence wrap by
    requiring the PRECEDING line to look like a paragraph boundary: empty,
    a unit header, or itself a short "bare label" line (<=16 chars, no
    Hangul, no trailing sentence-final punctuation) -- the two-line
    "bare label 
 quoted restatement" pattern these books always use for a
    genuine new grammar item. We also require the captured label itself to
    contain at least one Hangul character (rules out English words that
    happen to be quoted, e.g. ‘with’, inside the EN paragraph).
    """
    out: dict[int, list[dict]] = {}
    cur_unit = None
    for pno in grammar_pages:
        raw = pages[pno]
        lines_ = raw.splitlines()
        for i, line in enumerate(lines_):
            stripped = line.strip("﻿  	")
            m = re.match(r"^(\d+)과\s+(.+)$", stripped)
            if m:
                cur_unit = int(m.group(1))
                out.setdefault(cur_unit, [])
                continue
            if cur_unit is None:
                continue
            lm = QUOTED_LABEL_RE.match(stripped)
            if not lm:
                continue
            label = lm.group(1).strip()
            if not label or len(label) > LABEL_LINE_MAX or not HANGUL_RE.search(label):
                continue
            prev = lines_[i - 1].strip() if i > 0 else ""
            is_boundary = (
                prev == ""
                or re.match(r"^\d+과", prev)
                or (len(prev) <= 18 and not prev.endswith((".", "?", ":")))
            )
            if not is_boundary:
                continue
            if not any(g["label"] == label for g in out[cur_unit]):
                out[cur_unit].append({"label": label, "page": pno})
    return out


def _ws_norm(s: str) -> str:
    """Collapse all whitespace runs (regular space, tab, NBSP U+00A0, thin
    space U+2005, etc.) to a single ASCII space. The TOC and the unit body
    page were observed to typeset the same title with different whitespace
    characters between words (TOC: NBSP; body: regular space), which broke
    an exact substring match for the first several units of each volume."""
    return re.sub(r"[\s  -​]+", " ", s).strip()


def find_unit_body(pages: dict[int, str], title: str) -> tuple[int, str] | None:
    """First page (>page 9, before any appendix section) where the unit
    title occurs (whitespace-normalized match, see _ws_norm); returns
    (page_no, page_text)."""
    norm_title = _ws_norm(title)
    for pno in sorted(pages):
        if pno <= 9:
            continue
        text = pages[pno]
        if norm_title and norm_title in _ws_norm(text):
            tail = text[-80:]
            if "확인 문제" in tail or "정답" in tail or "문법 설명" in tail or "발음 설명" in tail or "어휘 색인" in tail:
                continue
            return pno, text
    return None


def extract_cando_and_dialogue(pages: dict[int, str], start_page: int) -> tuple[str | None, int | None, list[dict]]:
    cando_lines: list[tuple[int, str]] = []
    for pno in sorted(p for p in pages if start_page <= p <= start_page + 1):
        for line in pages[pno].splitlines():
            cando_lines.append((pno, line))

    cando = None
    cando_page = None
    for pno, line in cando_lines:
        s = line.strip()
        if CANDO_RE.match(s) and 4 <= len(s.split()) <= 12:
            cando = s
            cando_page = pno
            break

    # Dialogue exercises (가:/나: turns) can appear several pages into a
    # unit (어휘 연습 -> 어휘 확장 -> 표현 연습 1/2 -> 발음 -> 읽고써요 -> 확인해요 -> 활동지),
    # so use a wider window than the can-do line's.
    dialogue_lines: list[tuple[int, str]] = []
    for pno in sorted(p for p in pages if start_page <= p <= start_page + 9):
        for line in pages[pno].splitlines():
            dialogue_lines.append((pno, line))

    dialogues = []
    seen = set()
    for pno, line in dialogue_lines:
        m = DIALOGUE_RE.match(line.strip())
        if m and len(m.group(1).split()) <= 15:
            q = line.strip()
            if q in seen:
                continue
            seen.add(q)
            dialogues.append({"quote": q, "page": pno})
            if len(dialogues) >= 2:
                break
    return cando, cando_page, dialogues


def build_hoehwa_level(level_no: int, files: list[str]) -> dict:
    units_out: dict[int, dict] = {}
    for fname in files:
        scratch = HOEHWA_SCRATCH[fname]
        pages = load_pages(scratch)
        toc = parse_toc(pages)
        vocab_pages = find_section_pages(pages, "어휘 색인")
        grammar_pages = find_section_pages(pages, "문법 설명")
        vocab_by_unit = parse_vocab_index(pages, vocab_pages)
        grammar_by_unit = parse_grammar_section(pages, grammar_pages)

        for unit_no, title in toc:
            body = find_unit_body(pages, title)
            cando, cando_page, dialogues = (None, None, [])
            body_page = None
            if body:
                body_page, _ = body
                cando, cando_page, dialogues = extract_cando_and_dialogue(pages, body_page)

            unit_key = unit_no
            rec = {
                "unit": unit_key,
                "title": None,
                "title_page": None,
                "cando": None,
                "cando_page": None,
                "vocab": [],
                "grammar": [],
                "dialogue_quotes": [],
                "source_file": fname,
            }
            cid_base = f"sejong{level_no}_u{unit_key}"

            if body_page:
                rec["title"] = title
                rec["title_page"] = cite(f"{cid_base}_title", fname, body_page, title, f"level {level_no} unit {unit_key} title")["page"]
            if cando and cando_page:
                rec["cando"] = cando
                rec["cando_page"] = cite(f"{cid_base}_cando", fname, cando_page, cando, f"level {level_no} unit {unit_key} can-do")["page"]

            for j, d in enumerate(dialogues):
                q = cite(f"{cid_base}_dlg{j}", fname, d["page"], d["quote"], f"level {level_no} unit {unit_key} dialogue quote")
                rec["dialogue_quotes"].append(q)

            for j, v in enumerate(vocab_by_unit.get(unit_no, [])):
                c = cite(f"{cid_base}_voc{j}_{v['korean']}", fname, v["page"], v["korean"], f"level {level_no} unit {unit_key} vocab")
                rec["vocab"].append({"korean": v["korean"], "gloss_en": v["gloss"], "page": c["page"]})

            for j, g in enumerate(grammar_by_unit.get(unit_no, [])):
                c = cite(f"{cid_base}_gram{j}_{g['label']}", fname, g["page"], g["label"], f"level {level_no} unit {unit_key} grammar label")
                rec["grammar"].append({"label": g["label"], "page": c["page"]})

            units_out[unit_key] = rec

    return {
        "level_label": f"sejong_hoehwa_{level_no}",
        "cefr_approx": {1: "A1", 2: "A2", 3: "B1", 4: "B2"}[level_no],
        "source_series": "세종한국어 회화 익힘책 (영어판)",
        "source_files": files,
        "units": [units_out[k] for k in sorted(units_out)],
    }


# ---------------------------------------------------------------------------
# Family B: 세종학당 한국어 익힘책 5A/5B/6A/6B (levels 5-6, C1/C2)
# ---------------------------------------------------------------------------

MAIN_WORKBOOK_FILES = {
    5: ["세종학당 한국어 익힘책_5A.pdf", "세종학당 한국어 익힘책_5B.pdf"],
    6: ["세종학당 한국어 익힘책_6A.pdf", "세종학당 한국어 익힘책_6B.pdf"],
}
MAIN_WORKBOOK_SCRATCH = {
    "세종학당 한국어 익힘책_5A.pdf": "세종학당_한국어_익힘책_5A",
    "세종학당 한국어 익힘책_5B.pdf": "세종학당_한국어_익힘책_5B",
    "세종학당 한국어 익힘책_6A.pdf": "세종학당_한국어_익힘책_6A",
    "세종학당 한국어 익힘책_6B.pdf": "세종학당_한국어_익힘책_6B",
}
MAIN_TOC_UNIT_RE = re.compile(r"^(\d+)과\s*$")


def parse_main_toc(pages: dict[int, str]) -> list[tuple[int, str, int]]:
    """(unit_no, title, printed_page) from the TOC (page 5)."""
    text = pages.get(5, "")
    lines = [l.strip() for l in text.splitlines()]
    out = []
    i = 0
    while i < len(lines):
        m = MAIN_TOC_UNIT_RE.match(lines[i])
        if m:
            unit_no = int(m.group(1))
            title = lines[i + 1].strip() if i + 1 < len(lines) else ""
            # scan forward a couple lines for the trailing page number
            page_no = None
            for j in range(i + 2, min(i + 5, len(lines))):
                if re.match(r"^\d+$", lines[j]):
                    page_no = int(lines[j])
                    break
            out.append((unit_no, title, page_no))
            i += 1
            continue
        i += 1
    return out


QUOTED_LABEL_RE = re.compile(r"^[\u2018']([^\u2019'\n]{1,20})[\u2019']")


def parse_main_workbook_grammar(pages: dict[int, str]) -> dict[int, list[dict]]:
    """Grammar labels via the '의미\\n'<label>'...' convention, scoped per
    unit by nearest preceding unit-title occurrence."""
    # Build ordered page list, find unit start pages by locating each TOC
    # title's first occurrence in the body.
    toc = parse_main_toc(pages)
    unit_start_page: dict[int, int] = {}
    for unit_no, title, _ in toc:
        if not title:
            continue
        for pno in sorted(p for p in pages if p > 5):
            if title in pages[pno]:
                unit_start_page[unit_no] = pno
                break

    ordered_units = sorted(unit_start_page.items(), key=lambda kv: kv[1])
    out: dict[int, list[dict]] = {u: [] for u, _ in ordered_units}

    for idx, (unit_no, start) in enumerate(ordered_units):
        end = ordered_units[idx + 1][1] if idx + 1 < len(ordered_units) else start + 6
        for pno in sorted(p for p in pages if start <= p < end):
            lines = pages[pno].splitlines()
            for i, line in enumerate(lines):
                if line.strip() == "의미" and i + 1 < len(lines):
                    m = QUOTED_LABEL_RE.match(lines[i + 1].strip())
                    if m:
                        label = m.group(1)
                        if not any(g["label"] == label for g in out[unit_no]):
                            out[unit_no].append({"label": label, "page": pno})
    return out


def build_main_workbook_level(level_no: int, files: list[str]) -> dict:
    units_out: dict[int, dict] = {}
    for fname in files:
        scratch = MAIN_WORKBOOK_SCRATCH[fname]
        pages = load_pages(scratch)
        toc = parse_main_toc(pages)
        grammar_by_unit = parse_main_workbook_grammar(pages)

        for unit_no, title, printed_page in toc:
            # locate actual PDF page of the unit's first body occurrence
            body_page = None
            for pno in sorted(p for p in pages if p > 5):
                if title and title in pages[pno]:
                    body_page = pno
                    break
            cid_base = f"sejong{level_no}_{fname[:2]}_u{unit_no}"
            rec = {
                "unit": unit_no,
                "title": None,
                "title_page": None,
                "grammar": [],
                "vocab": [],  # not extracted for this family; see NOTE
                "vocab_note": (
                    "NOT_EXTRACTED: this workbook has no separate headword "
                    "vocab-index appendix; vocabulary appears only as "
                    "collocations embedded in cloze exercises, which was out "
                    "of scope for automated extraction this session."
                ),
                "source_file": fname,
            }
            if body_page:
                rec["title"] = title
                rec["title_page"] = cite(
                    cid_base + "_title", fname, body_page, title,
                    f"level {level_no} unit {unit_no} title",
                )["page"]
            for j, g in enumerate(grammar_by_unit.get(unit_no, [])):
                c = cite(
                    f"{cid_base}_gram{j}_{g['label']}", fname, g["page"], g["label"],
                    f"level {level_no} unit {unit_no} grammar label",
                )
                rec["grammar"].append({"label": g["label"], "page": c["page"]})
            units_out[unit_no] = rec

    return {
        "level_label": f"sejong_main_{level_no}",
        "cefr_approx": {5: "C1", 6: "C2"}[level_no],
        "source_series": "세종학당 한국어 익힘책 (main course workbook)",
        "source_files": files,
        "units": [units_out[k] for k in sorted(units_out)],
    }


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)

    for level_no, files in HOEHWA_FILES.items():
        data = build_hoehwa_level(level_no, files)
        out_path = os.path.join(OUT_DIR, f"syllabus_sejong{level_no}.json")
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        n_gram = sum(len(u["grammar"]) for u in data["units"])
        n_voc = sum(len(u["vocab"]) for u in data["units"])
        print(f"sejong{level_no} ({data['cefr_approx']}): {len(data['units'])} units, "
              f"{n_gram} grammar labels, {n_voc} vocab items -> {out_path}")

    for level_no, files in MAIN_WORKBOOK_FILES.items():
        data = build_main_workbook_level(level_no, files)
        out_path = os.path.join(OUT_DIR, f"syllabus_sejong{level_no}.json")
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        n_gram = sum(len(u["grammar"]) for u in data["units"])
        print(f"sejong{level_no} ({data['cefr_approx']}): {len(data['units'])} units, "
              f"{n_gram} grammar labels (vocab NOT_EXTRACTED) -> {out_path}")

    # append citations (idempotent per run: this script always regenerates
    # the whole file since it's the only citation producer for syllabus data)
    with open(CITATIONS_PATH, "w", encoding="utf-8") as f:
        for rec in _citation_records:
            f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    print(f"\nWrote {len(_citation_records)} citations -> {CITATIONS_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
