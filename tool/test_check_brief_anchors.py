"""Tests for tool/check_brief_anchors.py.

Each test builds a tiny fixture repo under a tempdir (`--root`) plus an
in-memory brief markdown fixture, runs `check_brief_anchors.main([...])`
with stdout captured via `contextlib.redirect_stdout`, and asserts on the
returned exit code and the tab-separated rows it printed. No network, no
real repo assets -- tempfile fixtures only, per the CI contract
(`python -m unittest discover -s tool -p "test_*.py" -t .`).
"""

from __future__ import annotations

import io
import re
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_brief_anchors  # noqa: E402


def _mk(root: Path, rel: str, content: str) -> Path:
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    return path


def _lines_file(n: int, overrides: dict) -> str:
    out = [overrides.get(i, f"// filler {i}") for i in range(1, n + 1)]
    return "\n".join(out) + "\n"


def _run(root: Path, brief_text: str, window: int | None = None):
    with tempfile.TemporaryDirectory() as tmp:
        brief_path = Path(tmp) / "brief.md"
        brief_path.write_text(brief_text, encoding="utf-8")
        argv = [str(brief_path), "--root", str(root)]
        if window is not None:
            argv += ["--window", str(window)]
        buf = io.StringIO()
        with redirect_stdout(buf):
            code = check_brief_anchors.main(argv)
        out_lines = buf.getvalue().splitlines()
    summary = out_lines[-1] if out_lines else ""
    rows = [tuple(line.split("\t")) for line in out_lines[:-1]]
    return code, rows, summary


class CheckBriefAnchorsTest(unittest.TestCase):
    def test_1_identifier_found_near_anchor_is_ok(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _mk(root, "lib/a.dart", _lines_file(5, {3: "const int kFoo = 1;"}))
            code, rows, summary = _run(root, "check `lib/a.dart:3` sets `kFoo`\n")
        self.assertEqual(code, 0)
        self.assertEqual(len(rows), 1)
        status, brief_col, path_col, detail = rows[0]
        self.assertEqual(status, "OK")
        self.assertEqual(brief_col, "brief:1")
        self.assertEqual(path_col, "lib/a.dart:3")
        self.assertEqual(detail, "kFoo")
        self.assertEqual(summary, "OK 1 · DRIFT 0 · MISSING 0")

    def test_2_identifier_found_elsewhere_is_drift(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _mk(
                root,
                "lib/a.dart",
                _lines_file(90, {3: "const int kOther = 1;", 80: "final kFoo = 2;"}),
            )
            code, rows, summary = _run(root, "check `lib/a.dart:3` sets `kFoo`\n", window=25)
        self.assertEqual(code, 0)
        self.assertEqual(len(rows), 1)
        status, _, path_col, detail = rows[0]
        self.assertEqual(status, "DRIFT")
        self.assertEqual(path_col, "lib/a.dart:3")
        self.assertIn("80", detail)
        self.assertIn("DRIFT 1", summary)

    def test_3_identifier_missing_everywhere_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _mk(root, "lib/a.dart", _lines_file(5, {3: "const int kFoo = 1;"}))
            code, rows, summary = _run(root, "check `lib/a.dart:3` sets `kBar`\n")
        self.assertEqual(code, 1)
        self.assertEqual(len(rows), 1)
        status, _, path_col, detail = rows[0]
        self.assertEqual(status, "MISSING")
        self.assertEqual(path_col, "lib/a.dart:3")
        self.assertIn("kBar", detail)
        self.assertIn("not found", detail)
        self.assertIn("MISSING 1", summary)

    def test_4_missing_file_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            code, rows, summary = _run(root, "check `lib/missing_file.dart:1` sets `x`\n")
        self.assertEqual(code, 1)
        self.assertEqual(len(rows), 1)
        status, _, path_col, detail = rows[0]
        self.assertEqual(status, "MISSING")
        self.assertEqual(path_col, "lib/missing_file.dart")
        self.assertEqual(detail, "no such file")

    def test_5_anchor_beyond_eof_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _mk(root, "lib/a.dart", _lines_file(3, {}))
            code, rows, summary = _run(root, "check `lib/a.dart:999` sets nothing\n")
        self.assertEqual(code, 1)
        self.assertEqual(len(rows), 1)
        status, _, path_col, detail = rows[0]
        self.assertEqual(status, "MISSING")
        self.assertEqual(path_col, "lib/a.dart:999")
        self.assertEqual(detail, "EOF at 3")

    def test_6_bare_filename_unique_ok_ambiguous_drift(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _mk(root, "lib/dup.dart", "// lib copy\n")
            _mk(root, "test/dup.dart", "// test copy\n")
            _mk(root, "test/uniq.dart", "// unique\n")
            code, rows, summary = _run(root, "see `dup.dart` and `uniq.dart` too\n")
        self.assertEqual(code, 0)
        self.assertEqual(len(rows), 2)
        by_path = {r[2]: r for r in rows}
        self.assertEqual(by_path["dup.dart"][0], "DRIFT")
        self.assertIn("ambiguous", by_path["dup.dart"][3])
        self.assertIn("lib/dup.dart", by_path["dup.dart"][3])
        self.assertIn("test/dup.dart", by_path["dup.dart"][3])
        self.assertEqual(by_path["uniq.dart"][0], "OK")

    def test_7_l_forms_bind_and_bare_numbers_are_ignored(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _mk(root, "lib/b.dart", _lines_file(300, {}))
            brief = (
                "See `lib/b.dart`(L123-139 참고) 그리고 "
                "(import + L205) 위치. fields 258-282, ctor 264 부근.\n"
            )
            code, rows, summary = _run(root, brief)
        self.assertEqual(code, 0)
        self.assertEqual(len(rows), 2)
        cols = {r[2] for r in rows}
        self.assertEqual(cols, {"lib/b.dart:123-139", "lib/b.dart:205"})
        for row in rows:
            self.assertEqual(row[0], "OK")
        joined = "\n".join(rows[0]) + "\n".join(rows[1])
        self.assertNotIn("258", joined)
        self.assertNotIn("282", joined)
        self.assertNotIn("264", joined)

    def test_8_exit_code_and_summary_line_contract(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _mk(root, "lib/a.dart", _lines_file(5, {3: "const int kFoo = 1;"}))
            with tempfile.TemporaryDirectory() as briefdir:
                ok_brief = Path(briefdir) / "ok.md"
                ok_brief.write_text("check `lib/a.dart:3` sets `kFoo`\n", encoding="utf-8")
                buf = io.StringIO()
                with redirect_stdout(buf):
                    ok_code = check_brief_anchors.main([str(ok_brief), "--root", str(root)])
                ok_summary = buf.getvalue().splitlines()[-1]

                missing_brief = Path(briefdir) / "missing.md"
                missing_brief.write_text(
                    "check `lib/missing_file.dart:1` sets `x`\n", encoding="utf-8"
                )
                buf2 = io.StringIO()
                with redirect_stdout(buf2):
                    missing_code = check_brief_anchors.main(
                        [str(missing_brief), "--root", str(root)]
                    )
                missing_summary = buf2.getvalue().splitlines()[-1]

        self.assertEqual(ok_code, 0)
        self.assertEqual(missing_code, 1)
        pattern = r"^OK \d+ · DRIFT \d+ · MISSING \d+$"
        self.assertRegex(ok_summary, pattern)
        self.assertRegex(missing_summary, pattern)


if __name__ == "__main__":
    unittest.main()
