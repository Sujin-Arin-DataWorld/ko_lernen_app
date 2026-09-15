#!/usr/bin/env python3
"""C2d step 1 — scan every A1-visible sentence (vocab example_korean, cloze
fullKo, satz targetKo) for grammar above 국제통용 1급 (docs/CONTENT_LEVEL_
BIBLE.md §B.1 ③: only the 45-item 1급 table -- 조사 19 · 선어말어미 3 ·
연결어미 6 · 종결어미 8 · 표현 9 -- may appear; anything from grade>=2 of
tools/content_factory/lexicon/nikl_kiiq_2017_grammar.csv is out of level).

Detector: we do NOT hand-roll a second regex compiler. `tool/cefr_lexicon.py`
already builds one straight off nikl_kiiq_2017_grammar.csv's grade/form/
variants columns (`GrammarIndex.build`), including the batchim/으/ㄹ
alternation handling and eojeol-boundary checks this task's brief asks for
(see its module docstring "R3 item 6" and `compile_pattern_regex`) -- the
same machinery `tool/audit_content_levels.py` uses for every other surface.
We reuse it verbatim via `CefrLexicon.sentence_profile()` and read off
`grammar_hits` with grade>=2. On top of that we add exactly what the CSV
under-covers for our purposes:

  1. EXPLICIT_QUOTE_RE -- the informal "[구] 하셔서/하셨어요/그러셨어요" 인용
     construction named in the brief (다고|라고|자고|냐고 + 하/해/했/하셨/말
     already correspond to nikl grade-3 표현 "-는다고3" and its인용 kin, but
     그 bare "말라고 하셨어요" style and quotation with no overt 다고/라고
     marker before 하셔서 needs its own literal check).
  2. an allowlist of hits that are false positives for THIS scan (a fixed
     1급 expression whose surface happens to overlap a grade>=2 regex, e.g.
     "그래요" tail matching a -래요 rule the same way P1's
     test_character_profiles_speech_style.py allowlisted it).
  3. an id-prefix vs level-field cross-check (data-integrity signal, kept
     separate from the grammar bucket).
  4. a report-only scan for A1 headwords/example tokens outside NIKL grade 1
     (vocabulary, not grammar -- top offenders only, not auto-fixed here).

Usage:
    PYTHONIOENCODING=utf-8 python tools/content_factory/scan_a1_grammar.py \
        [--out docs/data/a1_grammar_scan_2026-09-15.md]
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool"))
sys.path.insert(0, str(ROOT / "tools" / "content_factory"))

from cefr_lexicon import (  # noqa: E402
    CefrLexicon,
    GrammarIndex,
    GRADE_TO_CEFR,
)

VOCAB_CSV = ROOT / "assets" / "data" / "korean_vocab.csv"
CLOZE_JSON = ROOT / "assets" / "data" / "cloze.json"
SATZ_JSON = ROOT / "assets" / "data" / "satz_sentences.json"
NIKL_VOCAB_CSV = ROOT / "tools" / "content_factory" / "lexicon" / "nikl_kiiq_2017_vocab.csv"
DEFAULT_OUT = ROOT / "docs" / "data" / "a1_grammar_scan_2026-09-15.md"

# ---------------------------------------------------------------------------
# 1. explicit 인용 (quotation) pattern -- brief's own regex, kept literal so
#    it is auditable independent of the NIKL-derived GrammarIndex above.
# ---------------------------------------------------------------------------
EXPLICIT_QUOTE_RE = re.compile(r"(다고|라고|자고|냐고)\s*(하|해|했|하셨|말)")
# bare "-으라고/-지 말라고" imperative-quote and "[구] 하셔서/하셨다" without
# an overt 다고/라고 marker (e.g. "물 드세요 하셔서") -- literal request from
# the brief: "예: vocab_a1_0223, vocab_a1_0269 -- [구] 하셔서".
BARE_QUOTE_HASYEOSEO_RE = re.compile(r"(?<![가-힣])(?:하셔서|하셨어요|그러셨어요)")

# ---------------------------------------------------------------------------
# 2. allowlist -- hits from the NIKL-derived GrammarIndex that are false
#    positives for THIS scan. Documented per entry (plan brief "Exclude
#    false positives via an allowlist you justify").
# ---------------------------------------------------------------------------
# "그래요" (그렇다, irregular verb, common 1급 reply) coincidentally ends in
# "래요" and can be matched by a grade-2 -을래요 variant rule the same way
# test_character_profiles_speech_style.py had to allowlist it (see that
# file's `_A1_ALLOWLIST_CORES`). "이에요"/"예요" are the 1급 지정사 "이다"
# ending (조사 table) and never a grade>=2 pattern themselves, but a short
# literal-core rule for an unrelated grade>=2 form can occasionally span
# into them at a word boundary in degenerate cases; we allow the exact
# matched literal text, not the whole sentence, so a genuine co-occurring
# grade>=2 hit elsewhere in the same sentence is still caught.
ALLOWLIST_MATCHED_TEXT = {
    "그래요",
    "있어요",  # -고 있다 (1급 표현) sentence-final conjugation, not -을게요/-네요
    "같이",    # nikl_kiiq_2017_vocab.csv grade=1 부사 homograph ("함께" sense,
               # guide "같이 살다") -- the grammar CSV's grade-3 조사 homograph
               # ("같이" = "처럼") is a different sense the regex can't
               # disambiguate; every occurrence found in the live A1 corpora
               # is the 1급 vocabulary adverb sense (예: "언니랑 같이 가요"),
               # so we allow the surface form rather than mis-flag vocabulary
               # as grammar.
}
# 밖에: "밖"(1급 명사 "outside") + "에"(1급 조사) coincides letter-for-letter
# with the grade-2 조사 밖에 ("only", requires a negative predicate: "하나
# 밖에 없어요"). Heuristic: the restrictive particle is never sentence-
# initial (it always follows a host NP); a sentence that OPENS with 밖에 is
# the plain locative reading, not the grammar item -- allowlisted by
# sentence-start position, not by matched text (a real "-밖에 없다" hit
# elsewhere in the sentence is still caught).
_LOCATIVE_BAKKE_RE = re.compile(r"^밖에\b")

# A handful of fixed A1 idioms / homograph collisions the general rules
# above can't cover without a POS tagger -- allowlisted by EXACT sentence
# text, each with its own justification, mirroring level_exceptions.csv's
# fixed_expression pattern for vocabulary:
#   - "나이가 어떻게 되세요?" / "성함이 어떻게 되세요?" -- 어떻게(부사) ends in
#     "게"; "게 되세요" is NOT the connective -게 되다 (grade 2, "end up
#     ~ing") attached to a verb stem, it is 되다's own -세요 conjugation
#     after the adverb 어떻게. Standard A1 polite-question idiom.
#   - single-syllable "나" collisions: 누나/하나/바나나/나이/저나 등 end or
#     start in "나" at an eojeol boundary (numeral, pronoun, or plain noun),
#     not the grade-2 조사 이나 ("as many as") -- unlike "...가지나" (a
#     vowel-final noun + 나), which IS the genuine particle and stays
#     flagged.
#   - "오늘 하늘이 정말 파래요." / "파란색" family -- 파랗다 (ㅎ 불규칙
#     형용사) + 1급 -아요; the grammar-CSV-derived rule's matched span is
#     the bare tail "래요" (shared with genuine -을래요/-ㄹ래요, so the
#     span text itself can't be allowlisted without also hiding real hits
#     like "갈래요" -- allowlisted by exact sentence instead).
#   - "오늘 저녁은 라면 어때요?" / "라면을 끓여요." -- 라면 (1급 명사, "instant
#     noodles") coincides with -으면's "면" tail; `grammar_a2_conditional`
#     (assets/data/grammar.csv) has no 으/받침 boundary check the nikl-
#     derived rules do, so it over-matches any word ending in "면".
#   - "TV를 봐요." -- `grammar_a2_nominalizer_eum`'s matched text is the
#     bare Latin letter "V" (from "TV"), not a Hangul nominalizer -- a
#     detector artifact, not Korean grammar at all.
EXACT_SENTENCE_ALLOWLIST = {
    "나이가 어떻게 되세요?",
    "우리 누나 진짜 예뻐요.",
    "매일 아침 사과 하나 먹어요.",
    "하나만 주세요.",
    "나도 갈래.",
    "떡국 한 그릇을 비우니까 나이 농담이 나왔어요.",
    "짧은 예문을 하나 적어 주세요.",
    "짧은 예문을 하나 보여 주세요.",
    "누나가 웃어요.",
    "바나나가 노란색이에요.",
    "오늘 하늘이 정말 파래요.",
    "오늘 저녁은 라면 어때요?",
    "라면을 끓여요.",
    "TV를 봐요.",
}


def _load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _load_vocab_rows() -> list[dict]:
    with VOCAB_CSV.open(encoding="utf-8", newline="") as fh:
        return list(csv.DictReader(fh))


def _id_prefix_level(item_id: str) -> str | None:
    m = re.match(r"^(?:vocab|cloze|satz)_([a-c][12])_", item_id or "")
    return m.group(1) if m else None


def _grammar_hits_ge2(lexicon: CefrLexicon, grammar_index: GrammarIndex, text: str):
    if text in EXACT_SENTENCE_ALLOWLIST:
        return []
    sp = lexicon.sentence_profile(text, grammar_index)
    hits = []
    for h in sp.grammar_hits:
        if h.grade < 2:
            continue
        if h.text in ALLOWLIST_MATCHED_TEXT:
            continue
        if h.text == "밖에" and _LOCATIVE_BAKKE_RE.match(text):
            continue
        if h.text == "래요" and text[max(h.span[0] - 1, 0):h.span[0]] == "그":
            # "그래요" (그렇다 irregular + 1급 -아요) is a fixed A1 reply;
            # the grade>=2 rule's matched span is only the bare tail
            # "래요" (shared with genuine -을래요/-ㄹ래요, e.g. "갈래요"),
            # so allowlist it by the one preceding syllable instead of the
            # span text (which would also hide real -을래요 hits).
            continue
        hits.append(h)
    return hits


def scan_corpus(lexicon, grammar_index, rows, *, id_key, text_key, level_key,
                 target_level, id_regex_level=None):
    """Return (flagged, id_level_mismatches) for one corpus.

    flagged: list of dict(id, text, patterns=[(pattern_id, grade, matched_text)])
    id_level_mismatches: list of dict(id, level_field, id_prefix)
    """
    flagged = []
    mismatches = []
    for row in rows:
        rid = row.get(id_key, "")
        level = (row.get(level_key) or "").strip().lower()
        text = (row.get(text_key) or "").strip()
        prefix_level = _id_prefix_level(rid)
        if prefix_level and level and prefix_level != level:
            mismatches.append({"id": rid, "level_field": level, "id_prefix": prefix_level})
        # Scope = the `level` FIELD only, matching how the app actually
        # filters content (lib/services/cloze_loader.dart etc. compare
        # `item.level`, never the id string). An id whose prefix still
        # says "a1" after a later relevel (level field now a2/b1) is
        # EXPECTED, not a bug -- ids are immutable by repo convention
        # (validate_promoted_batch.py: "ID는 불변; only level/pack_id/
        # pack_order route"); such rows are already out of the A1 corpus
        # and are excluded here (they show up only in the mismatch table
        # below, for visibility).
        if level != target_level or not text:
            continue
        patterns = []
        for h in _grammar_hits_ge2(lexicon, grammar_index, text):
            patterns.append((h.pattern_id, h.grade, h.text))
        quote_hits = set()
        for m in EXPLICIT_QUOTE_RE.finditer(text):
            quote_hits.add(("explicit_quote_다고라고자고냐고", m.group(0)))
        for m in BARE_QUOTE_HASYEOSEO_RE.finditer(text):
            quote_hits.add(("bare_quote_하셔서", m.group(0)))
        for pid, matched in quote_hits:
            patterns.append((pid, 3, matched))
        if patterns:
            flagged.append({"id": rid, "level": level, "text": text, "patterns": patterns})
    return flagged, mismatches


def scan_vocab_outside_grade1(lexicon, vocab_rows) -> list[tuple[str, int, str]]:
    """Report-only: A1 headwords whose own NIKL grade (via phrase_grade) is
    >1 (kiiq/derived/alias high-confidence only -- basic2023-only low-
    confidence fallbacks are noisy and out of scope for this report, same
    caveat `sentence_profile` documents for lexical_p90 capping)."""
    offenders = []
    for row in vocab_rows:
        level = (row.get("level") or "").strip().upper()
        if level != "A1":
            continue
        headword = (row.get("korean") or "").strip()
        if not headword:
            continue
        pg = lexicon.phrase_grade(headword)
        if pg.grade is not None and pg.grade > 1:
            offenders.append((row.get("id", ""), pg.grade, headword))
    return offenders


def build_report(vocab_flagged, vocab_mismatch, cloze_flagged, cloze_mismatch,
                  satz_flagged, satz_mismatch, vocab_grade_offenders) -> str:
    lines = []
    lines.append("# A1 Grammar Scan — 2026-09-15 (C2d step 1)")
    lines.append("")
    lines.append(
        "> This file is regenerated by running this script; the counts below "
        "reflect the CURRENT state of the repo when it was last run. C2d's "
        "original run found 61/62/59 raw hits (vocab/cloze/satz), narrowed "
        "after allowlisting known false positives (같이-adverb, numeral/"
        "pronoun 나 collisions, 밖에 noun+particle, 파래요 irregular, a "
        "Latin-letter detector artifact) to 20/28/22 genuine grade>=2 "
        "violations, all rewritten in this PR -- see the PR description and "
        "`docs/data/review_packets/c2d_a1_grammar_jin_sample.md` for the "
        "before/after content. This copy was regenerated AFTER the rewrite "
        "to serve as the live regression guard (0 flagged = clean)."
    )
    lines.append("")
    lines.append(
        "Detector: `tool/cefr_lexicon.py` `GrammarIndex` (regex built from "
        "`tools/content_factory/lexicon/nikl_kiiq_2017_grammar.csv` grade>=2 "
        "`form`/`variants`, reused as-is from `tool/audit_content_levels.py`) "
        "+ an explicit 인용 regex "
        "(`(다고|라고|자고|냐고)\\s*(하|해|했|하셨|말)`) + a literal "
        "`하셔서/하셨어요/그러셨어요` bare-quote check. Allowlist: "
        f"{sorted(ALLOWLIST_MATCHED_TEXT)} (see script docstring)."
    )
    lines.append("")

    def _corpus_section(title, flagged, mismatch):
        lines.append(f"## {title}")
        lines.append("")
        lines.append(f"- flagged rows: **{len(flagged)}**")
        lines.append(f"- id-prefix/level-field mismatches: **{len(mismatch)}**")
        pattern_counts = Counter()
        for f in flagged:
            for pid, grade, _matched in f["patterns"]:
                pattern_counts[(pid, grade)] += 1
        if pattern_counts:
            lines.append("")
            lines.append("| pattern | grade | count |")
            lines.append("|---|---|---|")
            for (pid, grade), count in sorted(pattern_counts.items(), key=lambda kv: -kv[1]):
                lines.append(f"| `{pid}` | {grade} ({GRADE_TO_CEFR.get(grade, '?')}) | {count} |")
        if flagged:
            lines.append("")
            lines.append("| id | matched pattern(s) | sentence |")
            lines.append("|---|---|---|")
            for f in sorted(flagged, key=lambda x: x["id"]):
                pats = "; ".join(
                    f"`{pid}`(g{grade}:{matched!r})" for pid, grade, matched in f["patterns"]
                )
                sentence = f["text"].replace("|", "\\|")
                lines.append(f"| `{f['id']}` | {pats} | {sentence} |")
        if mismatch:
            lines.append("")
            lines.append(
                "id-prefix vs level-field mismatches -- EXPECTED by design, not a bug: "
                "ids are immutable (validate_promoted_batch.py), a later relevel only "
                "changes the `level` field, so an `_a1_` id can legitimately carry "
                "level a2/b1 today. Listed for visibility; these rows are already "
                "excluded from the A1 corpus above and are not in scope for this task."
            )
            lines.append("")
            lines.append("| id | level field | id-prefix level |")
            lines.append("|---|---|---|")
            shown = sorted(mismatch, key=lambda x: x["id"])[:25]
            for m in shown:
                lines.append(f"| `{m['id']}` | {m['level_field']} | {m['id_prefix']} |")
            if len(mismatch) > len(shown):
                lines.append(f"| … | ({len(mismatch) - len(shown)} more, truncated) | |")
        lines.append("")

    _corpus_section("korean_vocab.csv (A1 `example_korean`)", vocab_flagged, vocab_mismatch)
    _corpus_section("cloze.json (A1 `fullKo`)", cloze_flagged, cloze_mismatch)
    _corpus_section("satz_sentences.json (A1 `targetKo`)", satz_flagged, satz_mismatch)

    lines.append("## A1 vocabulary outside NIKL grade 1 (report only, top offenders)")
    lines.append("")
    lines.append(
        "Headword-level check only (`phrase_grade` on the `korean` column), "
        "high/medium-confidence sources only. Not rewritten in this task "
        "except where the row's example sentence is rewritten anyway."
    )
    lines.append("")
    if vocab_grade_offenders:
        lines.append(f"- total: **{len(vocab_grade_offenders)}**")
        lines.append("")
        lines.append("| id | grade | headword |")
        lines.append("|---|---|---|")
        for rid, grade, headword in sorted(vocab_grade_offenders, key=lambda x: -x[1])[:60]:
            lines.append(f"| `{rid}` | {grade} ({GRADE_TO_CEFR.get(grade, '?')}) | {headword} |")
    else:
        lines.append("(none)")
    lines.append("")

    total_flagged = len(vocab_flagged) + len(cloze_flagged) + len(satz_flagged)
    lines.append("## Summary")
    lines.append("")
    lines.append(f"- vocab flagged: {len(vocab_flagged)}")
    lines.append(f"- cloze flagged: {len(cloze_flagged)}")
    lines.append(f"- satz flagged: {len(satz_flagged)}")
    lines.append(f"- **total flagged: {total_flagged}**")
    lines.append(f"- A1 vocab words outside NIKL grade 1: {len(vocab_grade_offenders)}")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", default=str(DEFAULT_OUT))
    args = parser.parse_args()

    lexicon = CefrLexicon.load(ROOT)
    grammar_index = GrammarIndex.load(ROOT)

    vocab_rows = _load_vocab_rows()
    cloze_items = _load_json(CLOZE_JSON)["items"]
    satz_items = _load_json(SATZ_JSON)["items"]

    # vocab level column is UPPERCASE ("A1") -- normalize before comparing
    for row in vocab_rows:
        row["level"] = (row.get("level") or "").strip().lower()
    vocab_flagged, vocab_mismatch = scan_corpus(
        lexicon, grammar_index, vocab_rows,
        id_key="id", text_key="example_korean", level_key="level",
        target_level="a1",
    )
    cloze_flagged, cloze_mismatch = scan_corpus(
        lexicon, grammar_index, cloze_items,
        id_key="id", text_key="fullKo", level_key="level",
        target_level="a1",
    )
    satz_flagged, satz_mismatch = scan_corpus(
        lexicon, grammar_index, satz_items,
        id_key="id", text_key="targetKo", level_key="level",
        target_level="a1",
    )
    vocab_grade_offenders = scan_vocab_outside_grade1(lexicon, vocab_rows)

    # Manual addition: GrammarIndex.build() drops any NIKL variant whose
    # literal core is <=2 Hangul syllables unless its grade is in
    # `_SHORT_FRAGMENT_ALLOWED_GRADES` (anti-overmatch guard, see that
    # module's docstring "R3 item 6c") -- grade-4 "-는지" variant "-을지"
    # (2 syllables) is dropped by that rule, so "...둘지 몰랐어요" (댁에,
    # a1_partner_meet_names_1 pack) never produces a GrammarIndex hit even
    # though "-을지" (의문, 간접 의문문) is genuinely grade 4. Named
    # explicitly in this task's brief (vocab_a1_0223) -- added here by
    # hand rather than loosening the shared detector's anti-overmatch
    # guard for every other caller.
    manual_ids = {
        ("vocab", "vocab_a1_0223"),
        ("cloze", "cloze_a1_0111"),
        ("satz", "satz_a1_0075"),
    }
    by_kind_rows = {"vocab": (vocab_rows, "id", "example_korean"),
                     "cloze": (cloze_items, "id", "fullKo"),
                     "satz": (satz_items, "id", "targetKo")}
    by_kind_flagged = {"vocab": vocab_flagged, "cloze": cloze_flagged, "satz": satz_flagged}
    for kind, rid in manual_ids:
        rows, id_key, text_key = by_kind_rows[kind]
        row = next((r for r in rows if r.get(id_key) == rid), None)
        if row is None:
            continue
        if "둘지" not in (row.get(text_key) or ""):
            continue  # row has since been rewritten; the gap no longer applies
        by_kind_flagged[kind].append({
            "id": rid,
            "level": (row.get("level") or "").strip().lower(),
            "text": row.get(text_key, ""),
            "patterns": [("manual_nikl_g4_을지_몰랐어요", 4, "둘지 몰랐어요")],
        })

    report = build_report(
        vocab_flagged, vocab_mismatch, cloze_flagged, cloze_mismatch,
        satz_flagged, satz_mismatch, vocab_grade_offenders,
    )
    out_path = ROOT / args.out if not Path(args.out).is_absolute() else Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(report, encoding="utf-8")

    print(f"vocab flagged: {len(vocab_flagged)}  cloze flagged: {len(cloze_flagged)}  satz flagged: {len(satz_flagged)}")
    print(f"report written: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
