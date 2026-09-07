"""Tests for tool/ingest_nikl_grade_lists.py.

Builds tiny synthetic xlsx fixtures via `zipfile` (no openpyxl — it isn't
installed) to exercise the '/' -split, homograph-suffix, and grade-parsing
rules without depending on the real (gitignored) NIKL source files.
`tool/test_cefr_lexicon.py` and the real ingest run
(`ingest_nikl_grade_lists.py --kiiq ... --check`) cover the full
10,635/336/40,000-row source files.
"""

from __future__ import annotations

import csv
import io
import sys
import tempfile
import unittest
import xml.sax.saxutils as saxutils
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import ingest_nikl_grade_lists as ingest_mod  # noqa: E402


def _escape(text: str) -> str:
    return saxutils.escape(str(text))


def _build_minimal_xlsx(path: Path, sheets: dict[str, list[list[str]]]) -> None:
    """Write a minimal valid .xlsx with the given sheets (name -> rows of str).

    All non-empty cells are written as shared strings (sufficient for these
    tests — no formulas, no inline strings, no numeric-typed cells needed).
    """
    shared: list[str] = []
    shared_index: dict[str, int] = {}

    def sst_index(value: str) -> int:
        if value not in shared_index:
            shared_index[value] = len(shared)
            shared.append(value)
        return shared_index[value]

    sheet_names = list(sheets.keys())

    sheets_xml_parts = []
    for i, name in enumerate(sheet_names, start=1):
        sheets_xml_parts.append(
            f'<sheet name="{_escape(name)}" sheetId="{i}" r:id="rId{i}"/>'
        )
    workbook_xml = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        f"<sheets>{''.join(sheets_xml_parts)}</sheets></workbook>"
    )

    rels_parts = []
    for i in range(1, len(sheet_names) + 1):
        rels_parts.append(
            f'<Relationship Id="rId{i}" '
            'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
            f'Target="worksheets/sheet{i}.xml"/>'
        )
    rels_xml = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        f"{''.join(rels_parts)}</Relationships>"
    )

    content_types_xml = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        "</Types>"
    )

    root_rels_xml = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" '
        'Target="xl/workbook.xml"/></Relationships>'
    )

    sheet_xmls = []
    for name in sheet_names:
        rows_xml = []
        for r_idx, row in enumerate(sheets[name], start=1):
            cells_xml = []
            for c_idx, value in enumerate(row):
                if value == "":
                    continue
                col_letter = chr(ord("A") + c_idx)
                ref = f"{col_letter}{r_idx}"
                idx = sst_index(str(value))
                cells_xml.append(f'<c r="{ref}" t="s"><v>{idx}</v></c>')
            rows_xml.append(f'<row r="{r_idx}">{"".join(cells_xml)}</row>')
        sheet_xml = (
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
            f"<sheetData>{''.join(rows_xml)}</sheetData></worksheet>"
        )
        sheet_xmls.append(sheet_xml)

    sst_parts = [f"<si><t>{_escape(s)}</t></si>" for s in shared]
    shared_strings_xml = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        f'count="{len(shared)}" uniqueCount="{len(shared)}">{"".join(sst_parts)}</sst>'
    )

    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", content_types_xml)
        z.writestr("_rels/.rels", root_rels_xml)
        z.writestr("xl/workbook.xml", workbook_xml)
        z.writestr("xl/_rels/workbook.xml.rels", rels_xml)
        z.writestr("xl/sharedStrings.xml", shared_strings_xml)
        for i, sheet_xml in enumerate(sheet_xmls, start=1):
            z.writestr(f"xl/worksheets/sheet{i}.xml", sheet_xml)


_VOCAB_HEADER = [
    "전체번호",
    "등급별번호",
    "등급",
    "어휘",
    "품사",
    "길잡이말",
    "어휘교육내용개발(1-4단계)",
    "등급",
]
_GRAMMAR_HEADER = [
    "전체 번호",
    "등급별 번호",
    "등급",
    "분류",
    "대표형",
    "관련형",
    "의미",
    "국제통용 (2단계)",
    "문법.표현 교육내용개발(1-4단계)",
    "메모",
]
_BASIC_HEADER = ["등급", "어휘", "표준동형어번호수정", "품사", "어종", "원어", "의미", "분야"]


def _make_kiiq_fixture(path: Path) -> None:
    vocab_rows = [
        _VOCAB_HEADER,
        # '/'-joined headword AND pos, positionally paired.
        ["1", "1", "1급", "오늘02/오늘01", "부사/명사", "오늘 날씨가 좋다", "초급", "1급"],
        # simple single-homograph headword.
        ["2", "2", "1급", "감사01", "명사", "감사 인사를 하다", "초급", "1급"],
        # no homograph suffix at all -> homograph 0.
        ["3", "3", "2급", "가게", "명사", "가게에 가다", "중급", "2급"],
    ]
    grammar_rows = [
        _GRAMMAR_HEADER,
        ["1", "1", "1급", "조사", "이", "가", "", "초급", "초급", ""],
    ]
    _build_minimal_xlsx(path, {"어휘": vocab_rows, "문법": grammar_rows})


def _make_basic_fixture(path: Path) -> None:
    rows = [
        _BASIC_HEADER,
        ["1등급", "가", "1", "명사", "고유어", "", "", ""],
        ["1등급", "가게", "0", "명사", "고유어", "", "", ""],
    ]
    _build_minimal_xlsx(path, {"전체(1~5등급), 40,000개": rows})


class SplitHomographTests(unittest.TestCase):
    def test_two_digit_suffix_is_extracted(self) -> None:
        self.assertEqual(ingest_mod.split_homograph("감사01"), ("감사", 1))

    def test_no_suffix_defaults_to_zero(self) -> None:
        self.assertEqual(ingest_mod.split_homograph("가게"), ("가게", 0))

    def test_strips_whitespace(self) -> None:
        self.assertEqual(ingest_mod.split_homograph("  가게  "), ("가게", 0))


class SplitKiiqVocabEntryTests(unittest.TestCase):
    def test_slash_joined_headword_and_pos_pair_positionally(self) -> None:
        rows = ingest_mod.split_kiiq_vocab_entry(
            1, "오늘02/오늘01", "부사/명사", "오늘 날씨가 좋다", "초급"
        )
        self.assertEqual(len(rows), 2)
        self.assertEqual(
            (rows[0].headword, rows[0].homograph, rows[0].pos), ("오늘", 2, "부사")
        )
        self.assertEqual(
            (rows[1].headword, rows[1].homograph, rows[1].pos), ("오늘", 1, "명사")
        )

    def test_single_headword_is_one_row(self) -> None:
        rows = ingest_mod.split_kiiq_vocab_entry(1, "감사01", "명사", "감사 인사를 하다", "초급")
        self.assertEqual(len(rows), 1)
        self.assertEqual((rows[0].headword, rows[0].homograph), ("감사", 1))

    def test_pos_slash_mismatched_arity_keeps_pos_whole(self) -> None:
        # Real 2017-list quirk (3 rows): pos is '/'-joined but headword is not.
        rows = ingest_mod.split_kiiq_vocab_entry(3, "스무째00", "수사·관형사/명사", "", "고급")
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].pos, "수사·관형사/명사")


class GradeParsingTests(unittest.TestCase):
    def test_parses_grade_from_geup(self) -> None:
        self.assertEqual(ingest_mod.parse_grade("1급"), 1)

    def test_parses_grade_from_deunggeup(self) -> None:
        self.assertEqual(ingest_mod.parse_grade("5등급"), 5)


class IngestIntegrationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.kiiq = self.root / "kiiq.xlsx"
        self.basic = self.root / "basic.xlsx"
        self.out_dir = self.root / "lexicon"
        _make_kiiq_fixture(self.kiiq)
        _make_basic_fixture(self.basic)

    def test_vocab_csv_is_split_deterministic_and_sorted(self) -> None:
        summary = ingest_mod.ingest(self.kiiq, self.basic, self.out_dir)

        # pre-split: 3 raw rows; post-split: 4 (오늘02/오늘01 -> 2).
        self.assertEqual(summary.counts_by_grade["kiiq_vocab_pre_split"], {1: 2, 2: 1})
        self.assertEqual(summary.counts_by_grade["kiiq_vocab_post_split"], {1: 3, 2: 1})

        text = (self.out_dir / "nikl_kiiq_2017_vocab.csv").read_text(encoding="utf-8")
        rows = list(csv.reader(io.StringIO(text)))
        self.assertEqual(rows[0], ["grade", "headword", "homograph", "pos", "guide", "band"])
        # deterministic sort: (grade, headword, homograph) — 감사 < 오늘 (ㄱ < ㅇ).
        self.assertEqual(
            rows[1:],
            [
                ["1", "감사", "1", "명사", "감사 인사를 하다", "초급"],
                ["1", "오늘", "1", "명사", "오늘 날씨가 좋다", "초급"],
                ["1", "오늘", "2", "부사", "오늘 날씨가 좋다", "초급"],
                ["2", "가게", "0", "명사", "가게에 가다", "중급"],
            ],
        )
        # LF line endings, no CRLF.
        raw = (self.out_dir / "nikl_kiiq_2017_vocab.csv").read_bytes()
        self.assertNotIn(b"\r\n", raw)

    def test_grammar_csv_matches_golden_row(self) -> None:
        ingest_mod.ingest(self.kiiq, self.basic, self.out_dir)
        text = (self.out_dir / "nikl_kiiq_2017_grammar.csv").read_text(encoding="utf-8")
        rows = list(csv.reader(io.StringIO(text)))
        self.assertEqual(
            rows[0],
            ["grade", "category", "form", "variants", "meaning", "band_2stage", "band_1to4"],
        )
        self.assertEqual(rows[1], ["1", "조사", "이", "가", "", "초급", "초급"])

    def test_basic_2023_csv_matches_golden_row(self) -> None:
        ingest_mod.ingest(self.kiiq, self.basic, self.out_dir)
        text = (self.out_dir / "nikl_basic_2023_vocab.csv").read_text(encoding="utf-8")
        rows = list(csv.reader(io.StringIO(text)))
        self.assertEqual(rows[0], ["grade", "headword", "homograph", "pos", "origin"])
        self.assertIn(["1", "가게", "0", "명사", "고유어"], rows[1:])

    def test_aliases_csv_has_exact_initial_rows(self) -> None:
        ingest_mod.ingest(self.kiiq, self.basic, self.out_dir)
        text = (self.out_dir / "aliases.csv").read_text(encoding="utf-8")
        rows = list(csv.reader(io.StringIO(text)))
        self.assertEqual(rows[0], ["app_form", "lexicon_form", "note"])
        self.assertEqual(rows[1], ["핸드폰", "휴대폰", "구어 별칭"])
        self.assertEqual(rows[4], ["화이팅", "", "감탄 표현, A1 유지 예외"])
        self.assertEqual(len(rows) - 1, len(ingest_mod.ALIAS_ROWS))

    def test_check_passes_after_write(self) -> None:
        ingest_mod.ingest(self.kiiq, self.basic, self.out_dir)
        # Should not raise.
        ingest_mod.ingest(self.kiiq, self.basic, self.out_dir, check=True)

    def test_check_fails_after_tampering(self) -> None:
        ingest_mod.ingest(self.kiiq, self.basic, self.out_dir)
        target = self.out_dir / "nikl_kiiq_2017_vocab.csv"
        target.write_text(target.read_text(encoding="utf-8") + "extra,row,here\n", encoding="utf-8")
        with self.assertRaises(ingest_mod.LexiconCheckError):
            ingest_mod.ingest(self.kiiq, self.basic, self.out_dir, check=True)

    def test_check_fails_when_output_missing(self) -> None:
        with self.assertRaises(ingest_mod.LexiconCheckError):
            ingest_mod.ingest(self.kiiq, self.basic, self.out_dir, check=True)

    def test_cli_check_exit_code_2_on_mismatch(self) -> None:
        ingest_mod.main(
            [
                "--kiiq",
                str(self.kiiq),
                "--basic",
                str(self.basic),
                "--out",
                str(self.out_dir),
            ]
        )
        target = self.out_dir / "aliases.csv"
        target.write_text("tampered\n", encoding="utf-8")
        exit_code = ingest_mod.main(
            [
                "--kiiq",
                str(self.kiiq),
                "--basic",
                str(self.basic),
                "--out",
                str(self.out_dir),
                "--check",
            ]
        )
        self.assertEqual(exit_code, 2)


if __name__ == "__main__":
    unittest.main()
