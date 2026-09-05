#!/usr/bin/env python3
"""W10 PR-A T-G4 -- 문법 카드 앞/뒷면 감사 (지시서 1.11 "front and back look
the same").

`assets/data/grammar.csv` 각 행에 대해 카드 앞면(front)과 뒷면(back)에 실제로
찍히는 텍스트를 만든 뒤, 뒷면이 앞면 위에 아무것도 더하지 않는 행을 찾는다.

파생 규칙은 Dart 원본을 그대로 옮긴 것이며, 새 규칙을 만들지 않는다:

  - `lib/models/grammar_study_copy.dart:24-65`
    (`GrammarStudyCopy.fromGrammar`) -- CSV의 `explanation_de` 를 첫 `.`
    에서 잘라 `title`/`rest` 로 나누고, `rest` 를 `·` 로 쪼개 `rules` 로
    만든다 (라인 33). `·` 가 있는데 `rest` 가 비면 `explanation_de` 전체를
    `·` 로 쪼개 첫 조각을 title, 나머지를 rules 로 다시 만든다 (라인
    34-40). `example_korean`/`example_german` 은 `splitStudyPhrases`
    (라인 101-118, ` / ` 우선, 아니면 `|`) 로 각각 쪼개 `examples` 로 짝
    짓는다 (라인 42-50). `note` 컬럼은 이미 title 또는 어느 rule 과 같은
    내용이면 버린다 (`_sameClause`, 라인 52-57, 131-135).
  - `lib/screens/grammar_screen.dart:1718-1828` (`_Front`) -- 보여주는
    것: level 칩, `pattern`, `copy.title`(비어 있으면 `type_de`),
    `copy.examples.first` (한국어 + 글로스) 하나, 정적 힌트 문구.
  - `lib/screens/grammar_screen.dart:1830-1913` (`_Back`) -- 보여주는
    것: level 칩, `pattern`(동일), `copy.title`(비어 있지 않을 때만, 앞면과
    동일 텍스트), `copy.rules[i]`/`copy.examples[i]` 쌍을
    `max(len(rules), len(examples))` 만큼, 마지막으로 `copy.note`.

즉 뒷면 고유 콘텐츠는 `rules`, `examples[1:]`(둘째 예문부터), `note` 뿐이다
-- `pattern`/`title`/`examples[0]` 은 앞면과 완전히 같은 텍스트라 "추가"가
아니다. 이 도구는 그래서 다음일 때만 `back_adds_nothing = true` 로 표시한다:

    len(rules) == 0  AND  len(examples) <= 1  AND  note == ""

애매했던 지점 (모듈 docstring에 문서화, 지시서 요구):
  - `explanation_de`/`example_german`/`note` (DE 3종)을 정본으로 썼다.
    `Grammar.explanationFor`/`exampleFor`/`noteFor` 는 `lang=='en'` 이고
    EN 컬럼이 채워져 있을 때만 EN 으로 바꿔치기하는데(`lib/models/grammar.
    dart:104-116`), EN 컬럼은 선택 사항이라 DE 가 유일하게 항상 채워진
    정본이다. 언어 간 결과가 갈리는 행이 있으면 이 스크립트가 놓친다 --
    2026-09-05 시점 실제 리포트에는 0건.

사용법:
    .venv\\Scripts\\python.exe -X utf8 tool/audit_grammar_card_faces.py
    .venv\\Scripts\\python.exe -X utf8 tool/audit_grammar_card_faces.py --check
"""

from __future__ import annotations

import argparse
import csv
import re
from collections import OrderedDict
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
GRAMMAR_CSV = REPO / "assets/data/grammar.csv"
REPORT_MD = REPO / "docs/data/grammar_card_faces_report.md"

REPORT_DATE = "2026-09-05"

_CLAUSE_SPLIT_RE = re.compile(r"\s*·\s*")
_WS_RE = re.compile(r"\s+")


@dataclass
class GrammarCardFaces:
    row_id: str
    pattern: str
    level: str
    title: str
    rules: list[str]
    examples: list[tuple[str, str]]  # (korean, gloss)
    note: str
    front_parts: list[str] = field(default_factory=list)
    back_parts: list[str] = field(default_factory=list)
    back_adds_nothing: bool = False


def split_study_phrases(raw: str) -> list[str]:
    """Mirrors `splitStudyPhrases` in grammar_study_copy.dart:102-118."""
    trimmed = raw.strip()
    if not trimmed:
        return []
    if " / " in trimmed:
        splitter = " / "
    elif "|" in trimmed:
        splitter = "|"
    else:
        return [trimmed]
    return [p.strip() for p in trimmed.split(splitter) if p.strip()]


def split_clauses(raw: str) -> list[str]:
    """Mirrors `_splitClauses` in grammar_study_copy.dart:120-129."""
    if not raw:
        return []
    return [p.strip() for p in _CLAUSE_SPLIT_RE.split(raw) if p.strip()]


def _same_clause(a: str, b: str) -> bool:
    """Mirrors `_sameClause` in grammar_study_copy.dart:131-135."""
    left = _WS_RE.sub("", a)
    right = _WS_RE.sub("", b)
    return left == right or left in right or right in left


def derive_faces(row: dict[str, str]) -> GrammarCardFaces:
    """Mirrors `GrammarStudyCopy.fromGrammar` (grammar_study_copy.dart:24-65)
    using the DE columns as the canonical language -- see module docstring.
    """
    pattern = row.get("pattern", "").strip()
    level = row.get("level", "").strip()
    type_de = row.get("type_de", "").strip()
    raw = row.get("explanation_de", "").strip()

    title = raw
    rest = ""
    dot = raw.find(".")
    if 0 <= dot <= 72:
        title = raw[: dot + 1].strip()
        rest = raw[dot + 1 :].strip()

    rules = split_clauses(rest)
    if not rules and "·" in raw:
        parts = split_clauses(raw)
        if parts:
            title = parts[0]
            rules = parts[1:]

    korean = split_study_phrases(row.get("example_korean", ""))
    glosses = split_study_phrases(row.get("example_german", ""))
    examples = [
        (korean[i], glosses[i] if i < len(glosses) else "")
        for i in range(len(korean))
    ]

    note = row.get("note", "").strip()
    if note and (
        any(_same_clause(rule, note) for rule in rules) or (title and note in title)
    ):
        note = ""

    # -- 앞면 (grammar_screen.dart:1718-1828) --
    front_parts = [pattern, title or type_de]
    if examples:
        k, g = examples[0]
        front_parts.append(k)
        if g:
            front_parts.append(g)

    # -- 뒷면 (grammar_screen.dart:1830-1913) --
    back_parts = [pattern]
    if title:
        back_parts.append(title)
    pair_count = max(len(rules), len(examples))
    for i in range(pair_count):
        if i < len(rules):
            back_parts.append(rules[i])
        if i < len(examples):
            k, g = examples[i]
            back_parts.append(k)
            if g:
                back_parts.append(g)
    if note:
        back_parts.append(note)

    back_adds_nothing = len(rules) == 0 and len(examples) <= 1 and not note

    return GrammarCardFaces(
        row_id=row.get("id", "").strip(),
        pattern=pattern,
        level=level,
        title=title,
        rules=rules,
        examples=examples,
        note=note,
        front_parts=front_parts,
        back_parts=back_parts,
        back_adds_nothing=back_adds_nothing,
    )


def load_rows(csv_path: Path) -> list[dict[str, str]]:
    with csv_path.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        return [row for row in reader if any(v.strip() for v in row.values())]


def audit(rows: list[dict[str, str]]) -> list[GrammarCardFaces]:
    return [derive_faces(row) for row in rows]


def group_by_level(
    faces: list[GrammarCardFaces],
) -> "OrderedDict[str, list[GrammarCardFaces]]":
    by_level: "OrderedDict[str, list[GrammarCardFaces]]" = OrderedDict()
    for f in faces:
        by_level.setdefault(f.level or "(no level)", []).append(f)
    return by_level


def level_summary(
    by_level: "OrderedDict[str, list[GrammarCardFaces]]",
) -> list[tuple[str, int, int, float]]:
    """Returns (level, rows, flagged, pct) sorted by level name."""
    out = []
    for level in sorted(by_level.keys()):
        group = by_level[level]
        n = len(group)
        flagged = sum(1 for f in group if f.back_adds_nothing)
        pct = (flagged / n * 100.0) if n else 0.0
        out.append((level, n, flagged, pct))
    return out


def write_report(faces: list[GrammarCardFaces], out_path: Path) -> None:
    by_level = group_by_level(faces)
    summary = level_summary(by_level)
    total = len(faces)
    total_flagged = sum(1 for f in faces if f.back_adds_nothing)

    lines = [
        "# Grammar Card Faces Report (auto-generated)",
        "",
        f"> 생성: `python tool/audit_grammar_card_faces.py` -- {REPORT_DATE}",
        "> 직접 편집 금지. 재생성은 스크립트를 다시 실행할 것.",
        "",
        "지시서 1.11 (\"front and back look the same\") 감사 -- 뒷면이 앞면 위에",
        "규칙(rule)·둘째 이상 예문·note 중 아무것도 더하지 않는 카드를 찾는다.",
        "파생 규칙은 `tool/audit_grammar_card_faces.py` 모듈 docstring 참고.",
        "",
        f"**총 문법 카드**: {total}",
        f"**뒷면이 앞면과 동일(back_adds_nothing)**: {total_flagged}",
        "",
        "## 레벨별 요약",
        "",
        "| level | rows | flagged | pct |",
        "| --- | ---: | ---: | ---: |",
    ]
    for level, n, flagged, pct in summary:
        lines.append(f"| {level} | {n} | {flagged} | {pct:.1f}% |")
    lines.append("")

    for level, n, flagged, pct in summary:
        lines.append(f"## {level} -- flagged {flagged}/{n}")
        lines.append("")
        if flagged == 0:
            lines.append("_(없음)_")
            lines.append("")
            continue
        for f in by_level[level]:
            if not f.back_adds_nothing:
                continue
            lines.append(f"- `{f.row_id}` -- {f.pattern}")
        lines.append("")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--csv", type=Path, default=GRAMMAR_CSV)
    parser.add_argument("--out", type=Path, default=REPORT_MD)
    parser.add_argument(
        "--check",
        action="store_true",
        help="레벨별 요약만 stdout에 출력하고 리포트는 그대로 생성한다 (항상 exit 0 -- report-only tool).",
    )
    args = parser.parse_args(argv)

    rows = load_rows(args.csv)
    faces = audit(rows)
    write_report(faces, args.out)

    by_level = group_by_level(faces)
    summary = level_summary(by_level)
    total = len(faces)
    total_flagged = sum(1 for f in faces if f.back_adds_nothing)

    if args.check:
        print(f"total rows: {total}  flagged (back_adds_nothing): {total_flagged}")
        print(f"{'level':<10}{'rows':>6}{'flagged':>9}{'pct':>8}")
        for level, n, flagged, pct in summary:
            print(f"{level:<10}{n:>6}{flagged:>9}{pct:>7.1f}%")
    else:
        print(f"report -> {args.out}")
        print(f"total rows: {total}  flagged (back_adds_nothing): {total_flagged}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
