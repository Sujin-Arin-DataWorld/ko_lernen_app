#!/usr/bin/env python3
"""C2b-1 step 1 — lint scan of `assets/data/korean_vocab.csv` A1 rows'
DE/EN translation pairs against their KO source (headword `german`/
`english` glosses + `example_korean`/`example_german`/`example_english`).

This is a REGEX/heuristic net, not a substitute for reading every row (the
C2b-1 brief is explicit that most of the audit's worst defects were
semantic, not pattern-matchable) — it exists to (a) give a fast, reusable,
re-runnable ratchet other content batches can point at, and (b) surface a
concrete subset of rows for the human/model reading pass to start from.

Rules (R1-R8), each applied to the row's `german`+`example_german` (DE) and
`english`+`example_english` (EN) fields unless noted:

  R1  english_in_de       -- an unambiguous English-only function word in a
                             DE field (word-boundary, case-insensitive).
                             The word list is deliberately narrow: German
                             homographs of common English function words
                             (an, in, was, will, der/die/das, ist, so, ...)
                             are EXCLUDED on purpose (documented below) to
                             keep false positives near zero.
  R2  de_calque_fronting  -- German infinitive-fronting calque of the shape
                             "zu <verb> <vereinbarten|beschlossen|...> wir"
                             (a literal EN word-order calque: "to discuss
                             X we agreed" -> "X zu besprechen vereinbarten
                             wir"), named explicitly in the audit.
  R3  headword_missing    -- the vocab headword (or its predicate stem, i.e.
                             with a trailing 다/하다/되다/이다 stripped) does
                             not appear anywhere in `example_korean`.
  R4  length_ratio        -- DE or EN word count is <40% or >250% of the KO
                             어절 (whitespace-token) count of `example_korean`
                             -- catches truncated or padded translations.
  R5  du_sie_mixed        -- both an informal (du/dich/dir/dein...) and an
                             unambiguous formal-address (Sie/Ihnen/Ihr...,
                             never sentence-initial, since a sentence-
                             initial "Sie" is ambiguous with "sie" = she/
                             they capitalized only by position) marker
                             appear in the same DE text.
  R6  em_en_dash          -- a U+2013/U+2014 dash character anywhere in a
                             DE or EN field.
  R7  de_en_identical     -- `example_german` and `example_english` are the
                             identical string (English leaked into the
                             German field verbatim, or vice versa).
  R8  question_mismatch   -- `example_korean` ends in "?" but the matching
                             DE/EN example does not (or vice versa).

Usage:
    PYTHONIOENCODING=utf-8 python tools/content_factory/scan_translation_pairs.py \
        [--level A1] [--out docs/data/translation_scan_a1_2026-09-15.md]
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VOCAB_CSV = ROOT / "assets" / "data" / "korean_vocab.csv"
DEFAULT_OUT = ROOT / "docs" / "data" / "translation_scan_a1_2026-09-15.md"

# ---------------------------------------------------------------------------
# R1 -- unambiguous English-only function words. Every entry here is a token
# that literally cannot occur as a standalone German word (checked against
# a German function-word list by hand). Deliberately EXCLUDED because they
# collide with real German words: an, in, was, will, ist(no -- "is" IS
# included, "ist" is not the same token), so, man, die, der, das, wir, sind,
# war, hat, bin, kann, soll, alt, art, bald, gut, mit(!= "with"), and
# crucially "also" (real German connector "so/therefore", NOT the English
# "also" -- false-positived on vocab_a1_0218/0249's genuinely correct
# German before this exclusion was added) and "okay" (an accepted German
# colloquial loanword, "es ist okay" is normal German, not a leak).
# ---------------------------------------------------------------------------
_EN_FUNCTION_WORDS = (
    "the", "and", "with", "you", "your", "yours", "is", "are", "have", "has",
    "this", "that's", "for", "don't", "doesn't", "isn't", "aren't", "it's",
    "i'm", "you're", "we're", "they're", "because", "about", "from", "what",
    "when", "where", "which", "please", "thanks", "thank", "hello",
    "really", "actually", "going", "want", "wants", "like", "likes",
    "here", "there", "today", "tomorrow", "yesterday", "friend", "family",
    "time", "very", "much", "many", "some", "any", "all", "but", "not",
)
_EN_WORD_RE = {w: re.compile(rf"(?<![\w])" + re.escape(w) + r"(?![\w])", re.IGNORECASE)
               for w in _EN_FUNCTION_WORDS}

# ---------------------------------------------------------------------------
# R2 -- fronted-infinitive-clause calque. Literal pattern from the audit,
# plus a small curated extension list of semantically-similar "we agreed/
# decided/promised/planned/..." verbs that produce the same EN-word-order
# calque when a translator fronts the infinitive clause the way English
# allows ("to X, we agreed") but German does not for this class of verb.
# ---------------------------------------------------------------------------
_CALQUE_VERBS = (
    "vereinbarten", "beschlossen", "versprachen", "planten",
    "entschieden", "verabredeten",
)
_DE_CALQUE_RE = re.compile(
    r"\bzu\s+\w+\s+(?:" + "|".join(_CALQUE_VERBS) + r")\s+wir\b",
    re.IGNORECASE,
)

# ---------------------------------------------------------------------------
# R3 -- predicate-stem headword check.
# ---------------------------------------------------------------------------
_PREDICATE_SUFFIXES = ("하다", "되다", "이다", "다")


def _headword_stem(headword: str) -> str:
    h = headword.strip()
    for suf in _PREDICATE_SUFFIXES:
        if h.endswith(suf) and len(h) > len(suf):
            return h[: -len(suf)]
    return h


# ---------------------------------------------------------------------------
# R5 -- du/Sie mixing.
# ---------------------------------------------------------------------------
_DU_RE = re.compile(r"\b(du|dich|dir|dein\w*|deine\w*)\b", re.IGNORECASE)
# Formal-address forms only count when NOT the first word of the sentence
# (a capitalized sentence-initial "Sie" is ambiguous with "sie" = she/they).
_SIE_RE = re.compile(r"\b(Sie|Ihnen|Ihr\w*|Ihre\w*)\b")


def _has_mixed_du_sie(text: str) -> bool:
    if not text:
        return False
    has_du = bool(_DU_RE.search(text))
    if not has_du:
        return False
    for m in _SIE_RE.finditer(text):
        if m.start() == 0:
            continue  # sentence-initial -- ambiguous, not counted
        # must be capitalized "Sie"/"Ihnen"/"Ihr..." (formal), not a
        # lowercase "sie" (she/they) which _SIE_RE's pattern excludes
        # by construction (it only matches the capitalized literal).
        return True
    return False


# ---------------------------------------------------------------------------
# R6 -- dashes.
# ---------------------------------------------------------------------------
_DASH_RE = re.compile("[–—]")

# ---------------------------------------------------------------------------
# R8 -- question mismatch.
# ---------------------------------------------------------------------------


def _is_question(text: str) -> bool:
    return text.strip().endswith("?")


def _eojeol_count(text: str) -> int:
    return len([t for t in text.strip().split() if t])


def _word_count(text: str) -> int:
    # strip trailing punctuation-only tokens' punctuation for a fairer count
    return len([t for t in re.split(r"\s+", text.strip()) if t])


# ---------------------------------------------------------------------------
# Documented exceptions -- verified false positives from the C2b-1
# (2026-09-15) full manual read of every A1 row. Kept here (not silently
# dropped from scan_row(), which stays an honest raw heuristic for the
# report) so the live ratchet test can assert "0 UNEXPLAINED hits" instead
# of "0 hits" -- see tools/content_factory/test_scan_translation_pairs.py.
#
# R3 (26 ids): every one of these is the headword correctly used in a
# NATURALLY CONJUGATED form that Korean's irregular conjugation classes
# change beyond a simple 다/하다/되다/이다-suffix strip: ㅂ-irregular
# (귀엽다->귀여워요, 시끄럽다->시끄러워요, 어렵다->어려워요, 쉽다->쉬워요,
# 돕다->도와요, 도와주다->도와줘요), ㄷ-irregular (듣다->들어요, 묻다-
# >물어요), 으-deletion (크다->커요, 쓰다->써요, 고르다->골랐어요), ㄹ-final
# elision before -으세요 (살다->사세요), vowel-stem fusion with -아/어
# (오다->와요, 보다->봐요, 주다->줄 거예요, 하다->해요), and 이->여
# contraction (빌리다->빌려요, 기다리다->기다려요, 내리다->내려요,
# 다니다->다녀요, 인사드리다->인사드렸어요). None of these are translation
# defects; a real morphological analyzer would resolve every one, but this
# scanner deliberately stays a plain substring check (see script docstring)
# and documents the resulting false positives here instead.
R3_VERIFIED_FALSE_POSITIVES = {
    "vocab_a1_0054", "vocab_a1_0088", "vocab_a1_0090", "vocab_a1_0093",
    "vocab_a1_0094", "vocab_a1_0095", "vocab_a1_0104", "vocab_a1_0106",
    "vocab_a1_0107", "vocab_a1_0116", "vocab_a1_0122", "vocab_a1_0124",
    "vocab_a1_0125", "vocab_a1_0126", "vocab_a1_0127", "vocab_a1_0213",
    "vocab_a1_0258", "vocab_a1_0411", "vocab_a1_0435", "vocab_a1_0451",
    "vocab_a1_0455", "vocab_a1_0507", "vocab_a1_0508", "vocab_a1_0511",
    "vocab_a1_0512", "vocab_a1_0513",
}
# R4 (24 ids): every one of these is a natural KO->DE/EN expansion --
# Korean elides subjects, objects, and connective glue that German/English
# must supply explicitly (e.g. "늦어서 죄송합니다." (2 eojeol) ->
# "Entschuldigen Sie, dass ich zu spät bin." (7 words)). Manually read and
# judged against the KO source; none change or lose meaning.
# vocab_a1_0171 is a special case: its two-SENTENCE redundancy (the actual
# defect the ratio anomaly was proxying for) was already fixed in this same
# pass (one sentence instead of two, see docs/data/
# c2b1_a1_translation_changes.csv) -- it stays flagged only because a
# single natural German sentence for a 3-eojeol idiom still runs to 9
# words, which is correct, not a residual defect.
R4_VERIFIED_FALSE_POSITIVES = {
    "vocab_a1_0005", "vocab_a1_0040", "vocab_a1_0069", "vocab_a1_0070",
    "vocab_a1_0106", "vocab_a1_0130", "vocab_a1_0131", "vocab_a1_0157",
    "vocab_a1_0163", "vocab_a1_0171", "vocab_a1_0194", "vocab_a1_0222",
    "vocab_a1_0256", "vocab_a1_0259", "vocab_a1_0268", "vocab_a1_0317",
    "vocab_a1_0392", "vocab_a1_0397", "vocab_a1_0400", "vocab_a1_0403",
    "vocab_a1_0406", "vocab_a1_0419", "vocab_a1_0437", "vocab_a1_0458",
}
DOCUMENTED_FALSE_POSITIVES = {
    ("R3", i) for i in R3_VERIFIED_FALSE_POSITIVES
} | {
    ("R4", i) for i in R4_VERIFIED_FALSE_POSITIVES
}


def is_documented_false_positive(rule_id: str, row_id: str) -> bool:
    return (rule_id, row_id) in DOCUMENTED_FALSE_POSITIVES


def load_rows() -> list[dict]:
    with VOCAB_CSV.open(encoding="utf-8-sig", newline="") as fh:
        return list(csv.DictReader(fh))


def scan_row(row: dict) -> list[tuple[str, str]]:
    """Return [(rule_id, detail), ...] for one vocab row."""
    hits: list[tuple[str, str]] = []
    german = row.get("german") or ""
    english = row.get("english") or ""
    ex_de = row.get("example_german") or ""
    ex_en = row.get("example_english") or ""
    ex_ko = row.get("example_korean") or ""
    headword = row.get("korean") or ""

    # R1
    for field_name, field_val in (("german", german), ("example_german", ex_de)):
        for w, pat in _EN_WORD_RE.items():
            if pat.search(field_val):
                hits.append(("R1", f"{field_name}: english token {w!r}"))

    # R2
    if _DE_CALQUE_RE.search(ex_de):
        hits.append(("R2", "example_german: fronted-infinitive calque"))

    # R3
    stem = _headword_stem(headword)
    if headword and ex_ko and headword not in ex_ko and (not stem or stem not in ex_ko):
        hits.append(("R3", f"headword {headword!r} (stem {stem!r}) not in example_korean"))

    # R4
    ko_n = _eojeol_count(ex_ko)
    if ko_n:
        de_n = _word_count(ex_de)
        en_n = _word_count(ex_en)
        if ex_de and not (0.4 * ko_n <= de_n <= 2.5 * ko_n):
            hits.append(("R4", f"example_german word count {de_n} vs KO eojeol {ko_n}"))
        if ex_en and not (0.4 * ko_n <= en_n <= 2.5 * ko_n):
            hits.append(("R4", f"example_english word count {en_n} vs KO eojeol {ko_n}"))

    # R5
    if _has_mixed_du_sie(ex_de) or _has_mixed_du_sie(german):
        hits.append(("R5", "du/Sie mixed"))

    # R6
    for field_name, field_val in (
        ("german", german), ("english", english),
        ("example_german", ex_de), ("example_english", ex_en),
    ):
        if _DASH_RE.search(field_val):
            hits.append(("R6", f"{field_name}: em/en dash"))

    # R7 -- full example sentences identical is always suspicious. The short
    # headword GLOSS fields being identical is only suspicious past a short
    # length: single-word DE/EN cognates (Bus/Bus, Park/Park, Name/Name,
    # Hanbok/Hanbok, Korea/Korea, Minute/Minute) are genuine shared
    # loanwords/cognates between German and English, not English leaking
    # into the German gloss -- so a short (<=8-char) identical gloss is not
    # flagged; anything longer identical is (a whole identical PHRASE gloss
    # is not plausibly a coincidental cognate).
    if ex_de and ex_en and ex_de.strip().lower() == ex_en.strip().lower():
        hits.append(("R7", "example_german == example_english"))
    if german and english and german.strip().lower() == english.strip().lower() and len(german.strip()) > 8:
        hits.append(("R7", "german == english (gloss, len>8)"))

    # R8
    if ex_ko and ex_de:
        ko_q, de_q = _is_question(ex_ko), _is_question(ex_de)
        if ko_q != de_q:
            hits.append(("R8", f"KO question={ko_q} vs DE question={de_q}"))
    if ex_ko and ex_en:
        ko_q, en_q = _is_question(ex_ko), _is_question(ex_en)
        if ko_q != en_q:
            hits.append(("R8", f"KO question={ko_q} vs EN question={en_q}"))

    return hits


def build_report(level: str, flagged: list[dict], total_rows: int) -> str:
    lines = []
    lines.append(f"# Translation Pair Scan — {level} — 2026-09-15 (C2b-1 step 1)")
    lines.append("")
    lines.append(
        "> Regenerated by `tools/content_factory/scan_translation_pairs.py`. "
        "This is a heuristic net (R1-R8, see script docstring), not a "
        "substitute for the row-by-row reading pass — most of the audit's "
        "worst defects (meaning mismatch, idiom mistranslation, register) "
        "are semantic and NOT caught here. Use this to prioritize, not to "
        "gate."
    )
    lines.append("")
    lines.append(f"- rows scanned (`level == {level}`): **{total_rows}**")
    lines.append(f"- rows with >=1 hit: **{len(flagged)}**")
    unexplained_total = sum(
        1 for f in flagged for r, _d in f["hits"] if not is_documented_false_positive(r, f["id"])
    )
    lines.append(
        f"- hits with NO documented-false-positive explanation: **{unexplained_total}** "
        "(everything else below was read and judged during the C2b-1 2026-09-15 pass; "
        "see script's DOCUMENTED_FALSE_POSITIVES for the per-rule reasoning)"
    )
    lines.append("")

    rule_counts = Counter()
    for f in flagged:
        for rule_id, _detail in f["hits"]:
            rule_counts[rule_id] += 1
    lines.append("| rule | hits | documented false positives |")
    lines.append("|---|---|---|")
    for rule_id in ("R1", "R2", "R3", "R4", "R5", "R6", "R7", "R8"):
        doc_count = sum(1 for (r, _i) in DOCUMENTED_FALSE_POSITIVES if r == rule_id)
        lines.append(f"| {rule_id} | {rule_counts.get(rule_id, 0)} | {doc_count} |")
    lines.append("")

    for rule_id in ("R1", "R2", "R3", "R4", "R5", "R6", "R7", "R8"):
        rows = [f for f in flagged if any(h[0] == rule_id for h in f["hits"])]
        if not rows:
            continue
        lines.append(f"## {rule_id} ({len(rows)} rows)")
        lines.append("")
        lines.append("| id | headword | verified? | detail | example_korean | example_german | example_english |")
        lines.append("|---|---|---|---|---|---|---|")
        for f in sorted(rows, key=lambda x: x["id"]):
            details = "; ".join(d for r, d in f["hits"] if r == rule_id)
            verified = "false positive" if is_documented_false_positive(rule_id, f["id"]) else "**UNEXPLAINED**"
            ko = f["example_korean"].replace("|", "\\|")
            de = f["example_german"].replace("|", "\\|")
            en = f["example_english"].replace("|", "\\|")
            lines.append(f"| `{f['id']}` | {f['korean']} | {verified} | {details} | {ko} | {de} | {en} |")
        lines.append("")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--level", default="A1")
    parser.add_argument("--out", default=str(DEFAULT_OUT))
    args = parser.parse_args()

    rows = load_rows()
    level_rows = [r for r in rows if (r.get("level") or "").strip().upper() == args.level.upper()]

    flagged = []
    for row in level_rows:
        hits = scan_row(row)
        if hits:
            flagged.append({
                "id": row.get("id", ""),
                "korean": row.get("korean", ""),
                "example_korean": row.get("example_korean", ""),
                "example_german": row.get("example_german", ""),
                "example_english": row.get("example_english", ""),
                "hits": hits,
            })

    report = build_report(args.level.upper(), flagged, len(level_rows))
    out_path = ROOT / args.out if not Path(args.out).is_absolute() else Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(report, encoding="utf-8")

    total_hits = sum(len(f["hits"]) for f in flagged)
    unexplained = sum(
        1 for f in flagged for r, _d in f["hits"] if not is_documented_false_positive(r, f["id"])
    )
    print(f"rows scanned: {len(level_rows)}  flagged rows: {len(flagged)}  total hits: {total_hits}  unexplained: {unexplained}")
    print(f"report written: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
