"""Ingest NIKL (국립국어원) grade-list spreadsheets into deterministic lexicon CSVs.

Converts two source files into the CSVs under
``tools/content_factory/lexicon/`` that :mod:`tool.cefr_lexicon` reads:

* ``kiiq_2017_grades.xlsx`` — 2017 국제 통용 한국어 표준 교육과정(4단계) 어휘·문법
  grade lists (sheets ``어휘`` and ``문법``).
* ``basic_vocab_2023.xlsx`` — 2023 국어 기초 어휘 선정 및 어휘 등급화 연구
  (sheet ``전체(1~5등급), 40,000개``).

Both xlsx files are parsed with the standard library only (``zipfile`` +
``xml.etree.ElementTree``) — ``openpyxl`` is not installed in this
environment. See docs/CONTENT_LEVEL_BIBLE.md §3.C for the normalisation
contract this module implements, and
``tools/content_factory/lexicon/README.md`` for provenance/licence and the
regeneration command.

Normalisation rules (plan §3.C / §4.1):

* Whitespace (including embedded newlines from wrapped spreadsheet cells)
  is stripped from every field.
* A headword field joined with ``/`` (e.g. ``오늘02/오늘01``) is split into
  one row per part. When the paired 품사(pos) field is also ``/``-joined
  with the same number of parts, the parts are paired positionally;
  otherwise the whole pos string is repeated for every headword part (this
  also covers the rare case — 3 rows in the 2017 list — where pos is
  ``/``-joined but the headword is not, since positional pairing would be
  meaningless there).
* A trailing 2-digit homograph number is extracted from each headword part
  (``감사01`` → headword ``감사``, homograph ``1``); a headword with no
  such suffix gets homograph ``0``. A known data quirk: ~30 entries in the
  2017 vocab list join homograph variants with ``∙`` (and an embedded
  newline) instead of ``/`` (e.g. ``독립적01∙\\n독립적02``) — since only
  ``/`` is a documented split point, these are NOT split further; the
  trailing-digit rule still strips the last homograph suffix it finds.
  Flagged in the ingest report; see the module docstring's "known quirks"
  note reproduced in the CLI's summary output.
* Grade is parsed as the leading integer before ``급``/``등급`` (``1급`` →
  ``1``, ``1등급`` → ``1``).
* Output rows are sorted deterministically.
"""

from __future__ import annotations

import argparse
import csv
import io
import re
import sys
import xml.etree.ElementTree as ET
import zipfile
from dataclasses import dataclass, field
from pathlib import Path

# --------------------------------------------------------------------------
# Minimal xlsx reader (zipfile + xml.etree.ElementTree only).
# --------------------------------------------------------------------------

_SS_NS = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
_PKG_REL_NS = "{http://schemas.openxmlformats.org/package/2006/relationships}"
_DOC_REL_NS = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}"

_COL_LETTERS_RE = re.compile(r"^([A-Z]+)")
_GRADE_RE = re.compile(r"(\d+)")
_HOMOGRAPH_RE = re.compile(r"^(.*?)(\d{2})$")


class XlsxFormatError(ValueError):
    """Raised when a source workbook does not have the expected shape."""


def _column_index(cell_ref: str) -> int:
    """Convert an Excel cell reference (e.g. ``'AB12'``) to a 0-based column index."""
    match = _COL_LETTERS_RE.match(cell_ref)
    if not match:
        raise XlsxFormatError(f"cell reference has no column letters: {cell_ref!r}")
    index = 0
    for ch in match.group(1):
        index = index * 26 + (ord(ch) - ord("A") + 1)
    return index - 1


def _load_shared_strings(archive: zipfile.ZipFile) -> list[str]:
    try:
        raw = archive.read("xl/sharedStrings.xml")
    except KeyError:
        return []
    root = ET.fromstring(raw)
    strings: list[str] = []
    for si in root.findall(f"{_SS_NS}si"):
        strings.append("".join(t.text or "" for t in si.iter(f"{_SS_NS}t")))
    return strings


def _sheet_target(archive: zipfile.ZipFile, sheet_name: str) -> str:
    workbook = ET.fromstring(archive.read("xl/workbook.xml"))
    sheets_el = workbook.find(f"{_SS_NS}sheets")
    rel_id = None
    if sheets_el is not None:
        for sheet in sheets_el:
            if sheet.get("name") == sheet_name:
                rel_id = sheet.get(f"{_DOC_REL_NS}id")
                break
    if rel_id is None:
        available = (
            [s.get("name") for s in sheets_el] if sheets_el is not None else []
        )
        raise XlsxFormatError(
            f"sheet {sheet_name!r} not found; available sheets: {available!r}"
        )
    rels = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
    for rel in rels.findall(f"{_PKG_REL_NS}Relationship"):
        if rel.get("Id") == rel_id:
            return "xl/" + rel.get("Target")
    raise XlsxFormatError(f"relationship id {rel_id!r} not found in workbook rels")


def read_xlsx_sheet(path: Path, sheet_name: str, ncols: int) -> list[list[str]]:
    """Read one worksheet of the xlsx at `path` as a list of rows.

    Each row is a list exactly `ncols` long (0-based columns A..); missing
    or empty cells become ``''``. Handles shared strings (``t="s"``) and
    inline strings (``t="inlineStr"``); everything else (numeric cells,
    formula-result strings) is taken as the raw ``<v>`` text.
    """
    with zipfile.ZipFile(path) as archive:
        shared = _load_shared_strings(archive)
        target = _sheet_target(archive, sheet_name)
        sheet_root = ET.fromstring(archive.read(target))
        sheet_data = sheet_root.find(f"{_SS_NS}sheetData")
        rows: list[list[str]] = []
        if sheet_data is None:
            return rows
        for row_el in sheet_data.findall(f"{_SS_NS}row"):
            values = [""] * ncols
            for cell in row_el.findall(f"{_SS_NS}c"):
                ref = cell.get("r")
                if ref is None:
                    continue
                idx = _column_index(ref)
                if idx >= ncols:
                    continue
                cell_type = cell.get("t")
                if cell_type == "s":
                    v = cell.find(f"{_SS_NS}v")
                    values[idx] = shared[int(v.text)] if v is not None and v.text else ""
                elif cell_type == "inlineStr":
                    is_el = cell.find(f"{_SS_NS}is")
                    values[idx] = (
                        "".join(t.text or "" for t in is_el.iter(f"{_SS_NS}t"))
                        if is_el is not None
                        else ""
                    )
                else:
                    v = cell.find(f"{_SS_NS}v")
                    values[idx] = v.text if v is not None and v.text is not None else ""
            rows.append(values)
        return rows


# --------------------------------------------------------------------------
# Field normalisation.
# --------------------------------------------------------------------------


def _clean(value: str) -> str:
    """Strip leading/trailing whitespace and collapse embedded newlines."""
    return " ".join(value.split())


def parse_grade(text: str) -> int:
    """Extract the leading grade integer from text like ``'1급'``/``'1등급'``."""
    match = _GRADE_RE.match(text.strip())
    if not match:
        raise XlsxFormatError(f"could not parse a grade integer from {text!r}")
    return int(match.group(1))


def split_homograph(token: str) -> tuple[str, int]:
    """Split a trailing 2-digit homograph suffix off `token`.

    ``'감사01'`` -> ``('감사', 1)``; ``'가게'`` -> ``('가게', 0)``.
    """
    token = _clean(token)
    match = _HOMOGRAPH_RE.match(token)
    if match:
        return match.group(1), int(match.group(2))
    return token, 0


@dataclass(frozen=True)
class VocabRow:
    grade: int
    headword: str
    homograph: int
    pos: str
    guide: str
    band: str


def split_kiiq_vocab_entry(
    grade: int, headword_field: str, pos_field: str, guide_field: str, band_field: str
) -> list[VocabRow]:
    """Expand one 어휘 sheet row into one or more :class:`VocabRow`.

    Implements the ``/``-split + positional-pos-pairing + trailing-homograph
    rules documented in the module docstring.
    """
    headword_field = _clean(headword_field)
    pos_field = _clean(pos_field)
    guide = _clean(guide_field)
    band = _clean(band_field)

    headword_parts = [h for h in (p.strip() for p in headword_field.split("/")) if h]
    if not headword_parts:
        return []

    if "/" in pos_field:
        pos_parts = [p.strip() for p in pos_field.split("/")]
    else:
        pos_parts = []

    if len(pos_parts) == len(headword_parts):
        pos_list = pos_parts
    else:
        # Either pos has no '/', or it has a mismatched arity (3 rows in the
        # real 2017 list: pos is '/'-joined but headword is a single token —
        # positional pairing would be meaningless, so keep pos whole).
        pos_list = [pos_field] * len(headword_parts)

    rows = []
    for token, pos in zip(headword_parts, pos_list):
        headword, homograph = split_homograph(token)
        rows.append(
            VocabRow(
                grade=grade,
                headword=headword,
                homograph=homograph,
                pos=pos,
                guide=guide,
                band=band,
            )
        )
    return rows


@dataclass(frozen=True)
class GrammarRow:
    grade: int
    category: str
    form: str
    variants: str
    meaning: str
    band_2stage: str
    band_1to4: str


@dataclass(frozen=True)
class Basic2023Row:
    grade: int
    headword: str
    homograph: int
    pos: str
    origin: str


# --------------------------------------------------------------------------
# Per-source parsers.
# --------------------------------------------------------------------------

_KIIQ_VOCAB_SHEET = "어휘"
_KIIQ_VOCAB_NCOLS = 8  # A..H: 전체번호,등급별번호,등급,어휘,품사,길잡이말,어휘교육내용개발(1-4단계),등급
_KIIQ_GRAMMAR_SHEET = "문법"
_KIIQ_GRAMMAR_NCOLS = 10  # A..J
_BASIC_2023_SHEET = "전체(1~5등급), 40,000개"
_BASIC_2023_NCOLS = 8  # A..H: 등급,어휘,표준동형어번호수정,품사,어종,원어,의미,분야


def parse_kiiq_vocab(path: Path) -> list[VocabRow]:
    """Parse the 어휘 sheet of the 2017 kiiq workbook into `VocabRow`s (post-split)."""
    raw_rows = read_xlsx_sheet(path, _KIIQ_VOCAB_SHEET, _KIIQ_VOCAB_NCOLS)
    if not raw_rows:
        raise XlsxFormatError(f"{path}: sheet {_KIIQ_VOCAB_SHEET!r} is empty")
    out: list[VocabRow] = []
    for raw in raw_rows[1:]:  # skip header
        grade_text, headword, pos, guide, band = raw[2], raw[3], raw[4], raw[5], raw[6]
        if not _clean(headword):
            continue
        grade = parse_grade(grade_text)
        out.extend(split_kiiq_vocab_entry(grade, headword, pos, guide, band))
    return out


def parse_kiiq_grammar(path: Path) -> list[GrammarRow]:
    """Parse the 문법 sheet of the 2017 kiiq workbook into `GrammarRow`s."""
    raw_rows = read_xlsx_sheet(path, _KIIQ_GRAMMAR_SHEET, _KIIQ_GRAMMAR_NCOLS)
    if not raw_rows:
        raise XlsxFormatError(f"{path}: sheet {_KIIQ_GRAMMAR_SHEET!r} is empty")
    out: list[GrammarRow] = []
    for raw in raw_rows[1:]:
        grade_text, category, form_, variants, meaning, band_2stage, band_1to4 = (
            raw[2],
            raw[3],
            raw[4],
            raw[5],
            raw[6],
            raw[7],
            raw[8],
        )
        if not _clean(form_) and not _clean(category):
            continue
        out.append(
            GrammarRow(
                grade=parse_grade(grade_text),
                category=_clean(category),
                form=_clean(form_),
                variants=_clean(variants),
                meaning=_clean(meaning),
                band_2stage=_clean(band_2stage),
                band_1to4=_clean(band_1to4),
            )
        )
    return out


def parse_basic_2023_vocab(path: Path) -> list[Basic2023Row]:
    """Parse the '전체(1~5등급), 40,000개' sheet of the 2023 basic-vocab workbook."""
    raw_rows = read_xlsx_sheet(path, _BASIC_2023_SHEET, _BASIC_2023_NCOLS)
    if not raw_rows:
        raise XlsxFormatError(f"{path}: sheet {_BASIC_2023_SHEET!r} is empty")
    out: list[Basic2023Row] = []
    for raw in raw_rows[1:]:
        grade_text, headword, homograph_text, pos, origin = (
            raw[0],
            raw[1],
            raw[2],
            raw[3],
            raw[4],
        )
        headword = _clean(headword)
        if not headword:
            continue
        homograph_text = _clean(homograph_text)
        homograph = int(homograph_text) if homograph_text else 0
        out.append(
            Basic2023Row(
                grade=parse_grade(grade_text),
                headword=headword,
                homograph=homograph,
                pos=_clean(pos),
                origin=_clean(origin),
            )
        )
    return out


# --------------------------------------------------------------------------
# aliases.csv — fixed initial content (Fable ruling 2026-09-07, plan §6/T1.1).
# --------------------------------------------------------------------------

ALIAS_ROWS: list[tuple[str, str, str]] = [
    ("핸드폰", "휴대폰", "구어 별칭"),
    ("엄마", "어머니", "동급"),
    ("아빠", "아버지", "동급"),
    ("화이팅", "", "감탄 표현, A1 유지 예외"),
    ("잘 자요", "자다", ""),
    ("안녕히 가세요", "안녕히", ""),
    ("안녕히 계세요", "안녕히", ""),
    ("처음 뵙겠습니다", "뵙다", ""),
    ("만나서 반가워요", "반갑다", ""),
    ("잘 부탁드려요", "부탁하다", ""),
    ("별말씀을요", "", "관용 표현 A1"),
    ("천만에요", "", "관용 표현 A1"),
    ("실례합니다", "실례하다", ""),
    ("잠시만요", "잠시", ""),
    ("잠깐만요", "잠깐", ""),
    ("남자친구", "남자 친구", ""),
    ("여자친구", "여자 친구", ""),
    ("핸드폰 번호", "휴대폰", ""),
]


# --------------------------------------------------------------------------
# CSV writing.
# --------------------------------------------------------------------------


def _render_csv(header: list[str], rows: list[list[object]]) -> bytes:
    """Render `header` + `rows` as canonical UTF-8 CSV bytes (LF, QUOTE_MINIMAL)."""
    buf = io.StringIO(newline="")
    writer = csv.writer(buf, lineterminator="\n", quoting=csv.QUOTE_MINIMAL)
    writer.writerow(header)
    for row in rows:
        writer.writerow(row)
    return buf.getvalue().encode("utf-8")


# --------------------------------------------------------------------------
# Orchestration.
# --------------------------------------------------------------------------


@dataclass
class IngestSummary:
    """Summary of one `ingest()` run.

    `counts_by_grade` keys: 'kiiq_vocab_pre_split', 'kiiq_vocab_post_split',
    'kiiq_grammar', 'basic_2023' -> {grade_int: row_count}.
    `rows_written` keys: the 5 output CSV stems -> row count written
    (post-split for kiiq vocab, i.e. matches 'kiiq_vocab_post_split' total).
    """

    counts_by_grade: dict[str, dict[int, int]] = field(default_factory=dict)
    rows_written: dict[str, int] = field(default_factory=dict)


class LexiconCheckError(RuntimeError):
    """Raised by `ingest(..., check=True)` when a recomputed output differs."""


_OUTPUT_FILES = {
    "nikl_kiiq_2017_vocab": ["grade", "headword", "homograph", "pos", "guide", "band"],
    "nikl_kiiq_2017_grammar": [
        "grade",
        "category",
        "form",
        "variants",
        "meaning",
        "band_2stage",
        "band_1to4",
    ],
    "nikl_basic_2023_vocab": ["grade", "headword", "homograph", "pos", "origin"],
    "aliases": ["app_form", "lexicon_form", "note"],
}


def _pre_split_counts(path: Path) -> dict[int, int]:
    raw_rows = read_xlsx_sheet(path, _KIIQ_VOCAB_SHEET, _KIIQ_VOCAB_NCOLS)
    counts: dict[int, int] = {}
    for raw in raw_rows[1:]:
        headword = _clean(raw[3])
        if not headword:
            continue
        grade = parse_grade(raw[2])
        counts[grade] = counts.get(grade, 0) + 1
    return counts


def _grade_counts(rows: list, grade_attr: str = "grade") -> dict[int, int]:
    counts: dict[int, int] = {}
    for row in rows:
        grade = getattr(row, grade_attr)
        counts[grade] = counts.get(grade, 0) + 1
    return counts


def _build_outputs(
    kiiq: Path, basic: Path
) -> tuple[dict[str, bytes], IngestSummary]:
    """Compute every output CSV's canonical bytes and the run's summary, in memory."""
    vocab_rows = parse_kiiq_vocab(kiiq)
    grammar_rows = parse_kiiq_grammar(kiiq)
    basic_rows = parse_basic_2023_vocab(basic)

    vocab_sorted = sorted(vocab_rows, key=lambda r: (r.grade, r.headword, r.homograph))
    grammar_sorted = sorted(
        grammar_rows, key=lambda r: (r.grade, r.category, r.form, r.variants)
    )
    basic_sorted = sorted(basic_rows, key=lambda r: (r.grade, r.headword, r.homograph))

    outputs = {
        "nikl_kiiq_2017_vocab": _render_csv(
            _OUTPUT_FILES["nikl_kiiq_2017_vocab"],
            [[r.grade, r.headword, r.homograph, r.pos, r.guide, r.band] for r in vocab_sorted],
        ),
        "nikl_kiiq_2017_grammar": _render_csv(
            _OUTPUT_FILES["nikl_kiiq_2017_grammar"],
            [
                [r.grade, r.category, r.form, r.variants, r.meaning, r.band_2stage, r.band_1to4]
                for r in grammar_sorted
            ],
        ),
        "nikl_basic_2023_vocab": _render_csv(
            _OUTPUT_FILES["nikl_basic_2023_vocab"],
            [[r.grade, r.headword, r.homograph, r.pos, r.origin] for r in basic_sorted],
        ),
        "aliases": _render_csv(_OUTPUT_FILES["aliases"], [list(r) for r in ALIAS_ROWS]),
    }

    summary = IngestSummary(
        counts_by_grade={
            "kiiq_vocab_pre_split": _pre_split_counts(kiiq),
            "kiiq_vocab_post_split": _grade_counts(vocab_sorted),
            "kiiq_grammar": _grade_counts(grammar_sorted),
            "basic_2023": _grade_counts(basic_sorted),
        },
        rows_written={
            "nikl_kiiq_2017_vocab": len(vocab_sorted),
            "nikl_kiiq_2017_grammar": len(grammar_sorted),
            "nikl_basic_2023_vocab": len(basic_sorted),
            "aliases": len(ALIAS_ROWS),
        },
    )
    return outputs, summary


def ingest(
    kiiq: Path, basic: Path, out_dir: Path, check: bool = False
) -> IngestSummary:
    """Ingest the 2 source files into the 4 lexicon CSVs under `out_dir`.

    With `check=True`, nothing is written: every output is recomputed in
    memory and compared byte-for-byte against the file already on disk at
    `out_dir`; raises :class:`LexiconCheckError` listing every mismatching
    or missing file. Otherwise, writes all 4 CSVs and returns the summary.
    """
    outputs, summary = _build_outputs(kiiq, basic)

    if check:
        mismatches: list[str] = []
        for stem, data in outputs.items():
            out_path = out_dir / f"{stem}.csv"
            if not out_path.exists():
                mismatches.append(f"{out_path}: missing")
                continue
            on_disk = out_path.read_bytes()
            if on_disk != data:
                mismatches.append(f"{out_path}: content differs from recomputed output")
        if mismatches:
            raise LexiconCheckError("; ".join(mismatches))
        return summary

    for stem, data in outputs.items():
        out_path = out_dir / f"{stem}.csv"
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_bytes(data)
    return summary


# --------------------------------------------------------------------------
# CLI.
# --------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kiiq", required=True, type=Path)
    parser.add_argument("--basic", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument(
        "--check",
        action="store_true",
        help="recompute in memory and exit 2 if any output CSV differs byte-for-byte",
    )
    args = parser.parse_args(argv)

    try:
        summary = ingest(args.kiiq, args.basic, args.out, check=args.check)
    except LexiconCheckError as exc:
        print(f"CHECK FAILED: {exc}", file=sys.stderr)
        return 2
    except XlsxFormatError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    action = "verified" if args.check else "wrote"
    print(f"{action} lexicon CSVs under {args.out}")
    for source, counts in summary.counts_by_grade.items():
        ordered = {g: counts[g] for g in sorted(counts)}
        print(f"  {source}: {ordered}")
    for stem, count in summary.rows_written.items():
        print(f"  {stem}.csv: {count} rows")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
