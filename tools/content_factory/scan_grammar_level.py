#!/usr/bin/env python3
"""C2b-2 step 2 — level-generalized version of `scan_a1_grammar.py` (C2d).

Scans every `--level`-visible sentence (vocab `example_korean`, cloze
`fullKo`, satz `targetKo`) for grammar ABOVE that level's ceiling
(docs/CONTENT_LEVEL_BIBLE.md §B.1/§B.2):

  --level A1  (unchanged from scan_a1_grammar.py) -- only the 45-item 1급
              table may appear; anything nikl grade>=2 is out of level.
  --level A2  -- only 1급+2급 (grades 1-2) may appear; anything nikl
              grade>=3 is out of level (§B.2 ③: "1~2급 문법만").

This module is a straight generalization of `scan_a1_grammar.py`: the A1
code path is untouched byte-for-byte in behaviour (same allowlists, same
manual ids, same headword-embedded exceptions) when `--level A1` is
passed -- see `test_scan_grammar_level.py::test_a1_mode_matches_legacy_script`
for the parity check against the original script's own detector functions.
The A2 path reuses the exact same machinery with the grade threshold
raised from 2 to 3, and gates every A1-only sub-check (the -아/어 보다/주다
contracted-aux family, -는 법/-는 게, the attributive-noun 전성어미
collocation list) by ITS OWN grade against the active threshold -- all
four of those are grade-2 phenomena, i.e. legal at A2 (2급 표현/전성어미
explicitly include -어 보다, -어 주다, and the -는/-은/-을 전성어미 set, see
CONTENT_LEVEL_BIBLE §B.2 ③), so they correctly stop firing once
`--level A2` raises the floor to grade>=3. The 인용 (quotation) checks are
grade 3 already and so still apply unchanged to both levels.

Known structural gap carried over from C2d (not attempted here): NIKL's
own `GrammarIndex.build()` drops any grammar item whose literal core is
<=2 Hangul syllables unless its grade is in {1, 2} (anti-overmatch guard,
`tool/cefr_lexicon.py` `_SHORT_FRAGMENT_ALLOWED_GRADES`) -- so a grade-3
item with a short core (e.g. -어도, -어야, 대로, 뿐, 만큼, -는다, -잖아; 19
such items exist in nikl_kiiq_2017_grammar.csv grade==3) is never matched
by the shared GrammarIndex regardless of `--level`. C2d's A1 scanner
worked around this ONLY for the one concrete instance the brief named
(-을지, grade 4) via a hand-written `manual_ids` entry rather than a
general regex, because these short cores collide heavily with common
particles/homographs (같이, 뿐, 만큼, 요, 아, 고 ...) and a general regex
would need a POS tagger to avoid mass false positives (same reasoning as
this script's own 밖에/같이/그래요 allowlist entries). This script follows
the same policy: `MANUAL_HITS[level]` is the place to hand-add a concrete
instance found by reading the corpus (C2b-2 step 3); none were found in
the live A2 corpus at the time this scan last ran (see the report's
"Known gap" note for the live count).

Usage:
    PYTHONIOENCODING=utf-8 python tools/content_factory/scan_grammar_level.py \
        --level A2 [--out docs/data/translation_scan_a2_2026-09-15.md]
    PYTHONIOENCODING=utf-8 python tools/content_factory/scan_grammar_level.py \
        --level A1 [--out docs/data/a1_grammar_scan_2026-09-15.md]
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool"))
sys.path.insert(0, str(ROOT / "tools" / "content_factory"))

from cefr_lexicon import CefrLexicon, GrammarIndex, GRADE_TO_CEFR  # noqa: E402
from scan_a1_grammar import REVIEWED_HOMOGRAPH_HITS, grammar_scan_text  # noqa: E402

VOCAB_CSV = ROOT / "assets" / "data" / "korean_vocab.csv"
CLOZE_JSON = ROOT / "assets" / "data" / "cloze.json"
SATZ_JSON = ROOT / "assets" / "data" / "satz_sentences.json"

# ---------------------------------------------------------------------------
# Level config: grade THRESHOLD = lowest grade that is OUT OF LEVEL.
# A1 ceiling = grade1 only -> threshold 2. A2 ceiling = grade1-2 -> threshold 3.
# max_headword_grade = highest nikl grade a level's own HEADWORD may sit at
# for the report-only vocabulary-outside-grade census.
# ---------------------------------------------------------------------------
LEVEL_CONFIG = {
    "A1": {"threshold": 2, "max_headword_grade": 1},
    "A2": {"threshold": 3, "max_headword_grade": 2},
    # C9-T0: usage_notes.json example scan only targets B1/B2 (per-note
    # `level`, not a headword-grade census) -- "B1 -> grade<=3 allowed" and
    # "B2 -> grade<=4 allowed" per the brief, i.e. threshold = ceiling+1.
    # max_headword_grade is unused for --source usage_notes (see
    # scan_usage_note_corpus below) but kept so LEVEL_CONFIG stays one shape.
    "B1": {"threshold": 4, "max_headword_grade": 3},
    "B2": {"threshold": 5, "max_headword_grade": 4},
}
USAGE_NOTES_JSON = ROOT / "assets" / "data" / "usage_notes.json"

EXPLICIT_QUOTE_RE = re.compile(r"(다고|라고|자고|냐고)\s*(하|해|했|하셨|말)")
BARE_QUOTE_HASYEOSEO_RE = re.compile(r"(?<![가-힣])(?:하셔서|하셨어요|그러셨어요)")
QUOTE_GRADE = 3  # see scan_a1_grammar.py header; applies at both A1 and A2.

# -- grade-2 contracted-aux / short-fragment sub-checks (A1-only in effect,
#    since 2 < A2's threshold of 3 -- see module docstring) -----------------
_VERB_CONNECTOR_CHARS = "아어여해와워려러춰쳐셔둬돼"
AUX_TRY_RE = re.compile(rf"[{_VERB_CONNECTOR_CHARS}]\s?(?:봐요|봤어요|봤|보세요|볼게요|보고|본)")
AUX_GIVE_RE = re.compile(rf"[{_VERB_CONNECTOR_CHARS}]\s?(?:줘요|줬어요|줬|주세요|주셨어요|주셨|줄게요|주고|준)")
LAW_METHOD_RE = re.compile(r"(?:는|은)\s?법")
NOMINALIZER_GE_RE = re.compile(r"(?:는|은)\s?게\b")
CONTRACTED_AUX_GRADE = 2

ATTRIBUTIVE_NOUN_PATTERNS = (
    "만난 분", "만난 사람", "만난 친구",
    "가는 친구", "가는 손님", "나가는 손님", "오는 손님",
    "있는 사람", "아는 사람", "모르는 사람",
    "온 손님", "간 친구", "온 친구",
)
ATTRIBUTIVE_NOUN_GRADE = 2

ALLOWLIST_MATCHED_TEXT = {"그래요", "있어요", "같이"}
_LOCATIVE_BAKKE_RE = re.compile(r"^밖에\b")

# F9 (2026-09-16, Jin round 2 on C2d-2): kept in sync with
# scan_a1_grammar.py's own copy -- see that module for the full
# justification. Only matters for A1 (CONTRACTED_AUX_GRADE=2 threshold);
# at A2 the aux_give check doesn't fire at all (threshold raised to 3), so
# no level-gating is needed here.
A1_REQUEST_FORMULAS = (
    "말해 주세요",
    "적어 주세요",
    "도와주세요",
)


def _is_allowed_request_formula(text: str, match: re.Match) -> bool:
    context = text[max(0, match.start() - 1):match.end()]
    return context in A1_REQUEST_FORMULAS

HEADWORD_EMBEDDED_GRAMMAR = {
    "A1": {
        ("vocab", "vocab_a1_0341"): "늦을 것 같다 embeds -을 것 같다 (nikl grade 2, 표현)",
        ("cloze", "cloze_a1_0229"): "mirrors vocab_a1_0341",
        ("satz", "satz_a1_0193"): "mirrors vocab_a1_0341",
        # Jin ruling 2026-09-16 (Batch 25, F9 예외표) -- kept in sync with
        # scan_a1_grammar.py's own copy of this dict; closes out C2d-2's
        # original "relevel-to-A2 candidate" framing (kept at A1
        # permanently). See that module for the full justification and the
        # F9 CSV it must agree with.
        ("vocab", "vocab_a1_0410"): "적어 주다 embeds -아/어 주다 (nikl grade 2, 표현); A1 유지 (Jin 2026-09-16, F9)",
        ("satz", "satz_a1_0317"): "mirrors vocab_a1_0410",
        ("vocab", "vocab_a1_0508"): "도와주다 embeds -아/어 주다 (nikl grade 2, 표현); A1 유지 (Jin 2026-09-16, F9)",
        ("cloze", "cloze_a1_0442"): "mirrors vocab_a1_0508",
        ("satz", "satz_a1_0423"): "mirrors vocab_a1_0508",
    },
    "A2": {},
}

EXACT_SENTENCE_ALLOWLIST = {
    "나이가 어떻게 되세요?", "우리 누나 진짜 예뻐요.", "매일 아침 사과 하나 먹어요.",
    "하나만 주세요.", "나도 갈래.", "떡국 한 그릇을 비우니까 나이 농담이 나왔어요.",
    "짧은 예문을 하나 적어 주세요.", "짧은 예문을 하나 보여 주세요.", "누나가 웃어요.",
    "바나나가 노란색이에요.", "오늘 하늘이 정말 파래요.", "오늘 저녁은 라면 어때요?",
    "라면을 끓여요.", "TV를 봐요.",
    # C2d-2 (2026-09-16): kept in sync with scan_a1_grammar.py's own copy
    # (see that module for the full justification of each entry below).
    "짧은 예문을 하나 적으세요.", "짧은 예문을 하나 볼 수 있어요?",
    "저는 바나나를 좋아해요.",
    "저는 책을 가지고 있어요.",
}

# Manual, hand-verified additions per level: `GrammarIndex` structurally
# cannot reach these (short-fragment guard or similar) -- see module
# docstring. Populate only with a concrete instance found by reading the
# corpus, matching the A1 precedent (`vocab_a1_0223` for grade-4 -을지).
MANUAL_HITS: dict[str, set[tuple[str, str]]] = {
    "A1": {("vocab", "vocab_a1_0223"), ("cloze", "cloze_a1_0111"), ("satz", "satz_a1_0075")},
    "A2": set(),
}


def _load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _load_vocab_rows() -> list[dict]:
    with VOCAB_CSV.open(encoding="utf-8-sig", newline="") as fh:
        return list(csv.DictReader(fh))


def _id_prefix_level(item_id: str) -> str | None:
    m = re.match(r"^(?:vocab|cloze|satz)_([a-c][12])_", item_id or "")
    return m.group(1) if m else None


def _has_rieul_batchim(ch: str) -> bool:
    """True if `ch` is a Hangul syllable whose jongseong (final consonant)
    is ㄹ -- covers both 쉬(vowel stem)+ㄹ래요=쉴래요 and 입(ㅂ stem)+을래요
    (을 itself is jongseong ㄹ)."""
    if not ch:
        return False
    code = ord(ch) - 0xAC00
    if not (0 <= code < 11172):
        return False
    return (code % 28) == 8  # jongseong index 8 == ㄹ in the standard 28-slot table


def _grammar_hits_ge(lexicon: CefrLexicon, grammar_index: GrammarIndex, text: str, threshold: int):
    if text in EXACT_SENTENCE_ALLOWLIST:
        return []
    sp = lexicon.sentence_profile(grammar_scan_text(text), grammar_index)
    hits = []
    for h in sp.grammar_hits:
        if h.grade < threshold:
            continue
        if h.text in ALLOWLIST_MATCHED_TEXT:
            continue
        if h.pattern_id in REVIEWED_HOMOGRAPH_HITS.get(text, set()):
            continue
        if h.text == "밖에" and _LOCATIVE_BAKKE_RE.match(text):
            continue
        if h.text == "래요" and text[max(h.span[0] - 1, 0):h.span[0]] == "그":
            continue
        # `grammar_b2_quoted_contractions` (assets/data/grammar.csv row for
        # -대요/-(이)래요/-냬요/-재요, the SPOKEN-CONTRACTION reported-speech
        # family) is matched as a bare "래요"/"대요" substring by the shared
        # GrammarIndex, which cannot distinguish it from the A2-legal (grade
        # 2, 종결어미 table) volitional/intention ending -(으)ㄹ래요 ("I'd
        # rather/I will..."), a homograph on the same "래요" tail. The two
        # ARE distinguishable: -(으)ㄹ래요 always inserts a ㄹ immediately
        # before 래요 (either a bare ㄹ batchim fused into the preceding
        # syllable, e.g. 쉬다->쉴래요, or the explicit 을 syllable itself,
        # whose own jongseong IS ㄹ, e.g. 입다->입을래요), while the reported
        # contraction -(으)래요 never does (두다->두래요, 말하다->말하래요,
        # no ㄹ). Verified empirically against both classes (see
        # test_scan_grammar_level.py) before adding this discriminator, and
        # against the live A2 corpus (vocab_a2_0045/0139, satz_a2_0270:
        # genuine -(으)ㄹ래요, correctly excluded below; vocab_a2_0288/0295:
        # genuine -(으)래요 reported forms, correctly still flagged).
        if h.pattern_id == "grammar_b2_quoted_contractions" and h.text == "래요":
            preceding = text[max(h.span[0] - 1, 0):h.span[0]]
            if _has_rieul_batchim(preceding):
                continue
        hits.append(h)
    return hits


def _attributive_noun_hits(text: str, threshold: int):
    if ATTRIBUTIVE_NOUN_GRADE < threshold:
        return []
    return [
        ("attributive_noun_전성어미", ATTRIBUTIVE_NOUN_GRADE, collocation)
        for collocation in ATTRIBUTIVE_NOUN_PATTERNS
        if collocation in text
    ]


def _contracted_aux_hits(text: str, threshold: int):
    if CONTRACTED_AUX_GRADE < threshold:
        return []
    hits = []
    for m in AUX_TRY_RE.finditer(text):
        if "aux_try_아어보다" in REVIEWED_HOMOGRAPH_HITS.get(text, set()):
            continue
        if m.group(0) == "여보세요":
            # C2d-2 (2026-09-16): kept in sync with scan_a1_grammar.py's
            # own copy of this discriminator -- see that module for the
            # full justification.
            preceding = text[: m.start()]
            if not preceding or not ("가" <= preceding[-1] <= "힣"):
                continue
        hits.append(("aux_try_아어보다", CONTRACTED_AUX_GRADE, m.group(0)))
    for m in AUX_GIVE_RE.finditer(text):
        if _is_allowed_request_formula(text, m):
            continue  # F9 closed-list request formula, see A1_REQUEST_FORMULAS
        hits.append(("aux_give_아어주다", CONTRACTED_AUX_GRADE, m.group(0)))
    for m in LAW_METHOD_RE.finditer(text):
        hits.append(("nominalizer_는_법", CONTRACTED_AUX_GRADE, m.group(0)))
    for m in NOMINALIZER_GE_RE.finditer(text):
        hits.append(("nominalizer_는_게", CONTRACTED_AUX_GRADE, m.group(0)))
    return hits


def scan_corpus(lexicon, grammar_index, rows, *, id_key, text_key, level_key,
                 target_level, kind, threshold, level_name):
    flagged, mismatches = [], []
    headword_exceptions = HEADWORD_EMBEDDED_GRAMMAR.get(level_name, {})
    for row in rows:
        rid = row.get(id_key, "")
        level = (row.get(level_key) or "").strip().lower()
        text = (row.get(text_key) or "").strip()
        prefix_level = _id_prefix_level(rid)
        if prefix_level and level and prefix_level != level:
            mismatches.append({"id": rid, "level_field": level, "id_prefix": prefix_level})
        if level != target_level or not text:
            continue
        patterns = []
        for h in _grammar_hits_ge(lexicon, grammar_index, text, threshold):
            patterns.append((h.pattern_id, h.grade, h.text))
        if QUOTE_GRADE >= threshold:
            quote_hits = set()
            for m in EXPLICIT_QUOTE_RE.finditer(text):
                quote_hits.add(("explicit_quote_다고라고자고냐고", m.group(0)))
            for m in BARE_QUOTE_HASYEOSEO_RE.finditer(text):
                quote_hits.add(("bare_quote_하셔서", m.group(0)))
            for pid, matched in quote_hits:
                patterns.append((pid, QUOTE_GRADE, matched))
        patterns.extend(_attributive_noun_hits(text, threshold))
        patterns.extend(_contracted_aux_hits(text, threshold))
        if (kind, rid) in headword_exceptions:
            patterns = []
        if patterns:
            flagged.append({"id": rid, "level": level, "text": text, "patterns": patterns})
    return flagged, mismatches


def scan_vocab_outside_grade(lexicon, vocab_rows, level_name: str, max_grade: int):
    offenders = []
    for row in vocab_rows:
        level = (row.get("level") or "").strip().upper()
        if level != level_name:
            continue
        headword = (row.get("korean") or "").strip()
        if not headword:
            continue
        pg = lexicon.phrase_grade(headword)
        if pg.grade is not None and pg.grade > max_grade:
            offenders.append((row.get("id", ""), pg.grade, headword))
    return offenders


def _apply_manual_hits(level_name, by_kind_rows, by_kind_flagged, threshold):
    for kind, rid in sorted(MANUAL_HITS.get(level_name, set())):
        rows, id_key, text_key = by_kind_rows[kind]
        row = next((r for r in rows if r.get(id_key) == rid), None)
        if row is None:
            continue
        # Only the A1 legacy instance (-을지, grade 4) is currently known;
        # guard so a since-rewritten row silently drops out rather than
        # false-flagging.
        if level_name == "A1" and "둘지" not in (row.get(text_key) or ""):
            continue
        by_kind_flagged[kind].append({
            "id": rid,
            "level": (row.get("level") or "").strip().lower(),
            "text": row.get(text_key, ""),
            "patterns": [("manual_nikl_short_fragment", 4, "둘지 몰랐어요")],
        })


def build_report(level_name, threshold, vocab_flagged, vocab_mismatch, cloze_flagged,
                  cloze_mismatch, satz_flagged, satz_mismatch, vocab_grade_offenders) -> str:
    lines = []
    lines.append(f"# {level_name} Grammar Scan — 2026-09-15 (C2b-2 step 2, scan_grammar_level.py)")
    lines.append("")
    lines.append(
        f"> Detector: `tool/cefr_lexicon.py` `GrammarIndex` (grade>={threshold} = out of "
        f"level for {level_name}) + explicit 인용 regex (grade {QUOTE_GRADE}) "
        + ("+ contracted -아/어 보다/주다, -는 법/-는 게, attributive-noun 전성어미 "
           "collocation (all grade 2, so they still apply at A1's grade>=2 floor)"
           if threshold <= CONTRACTED_AUX_GRADE else
           "(the grade-2 contracted-aux/전성어미 sub-checks are inactive at this level -- "
           "grade 2 is IN level, see module docstring)")
        + ". Known structural gap: nikl grade>=3 items with a <=2-syllable literal core "
        "(19 such items, e.g. -어도/-어야/대로/뿐/만큼/-는다/-잖아) are dropped by "
        "GrammarIndex's own anti-overmatch guard regardless of level and are NOT "
        "regex-hunted here (see module docstring) -- add a hand-verified `MANUAL_HITS` "
        "entry if the row-by-row reading pass finds a concrete instance."
    )
    lines.append("")

    def _section(title, flagged, mismatch):
        lines.append(f"## {title}")
        lines.append("")
        lines.append(f"- flagged rows: **{len(flagged)}**")
        lines.append(f"- id-prefix/level-field mismatches: **{len(mismatch)}**")
        pattern_counts = Counter()
        for f in flagged:
            for pid, grade, _m in f["patterns"]:
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
                pats = "; ".join(f"`{pid}`(g{grade}:{m!r})" for pid, grade, m in f["patterns"])
                sentence = f["text"].replace("|", "\\|")
                lines.append(f"| `{f['id']}` | {pats} | {sentence} |")
        if mismatch:
            lines.append("")
            lines.append(
                "id-prefix vs level-field mismatches -- EXPECTED (ids are immutable; a "
                "later relevel only changes `level`). Listed for visibility only."
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

    _section(f"korean_vocab.csv ({level_name} `example_korean`)", vocab_flagged, vocab_mismatch)
    _section(f"cloze.json ({level_name} `fullKo`)", cloze_flagged, cloze_mismatch)
    _section(f"satz_sentences.json ({level_name} `targetKo`)", satz_flagged, satz_mismatch)

    lines.append(f"## {level_name} vocabulary outside its NIKL grade ceiling (report only)")
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
    lines.append(f"- {level_name} vocab words outside grade ceiling: {len(vocab_grade_offenders)}")
    lines.append("")
    return "\n".join(lines)


def _load_usage_notes() -> list[dict]:
    if not USAGE_NOTES_JSON.exists():
        return []
    root = _load_json(USAGE_NOTES_JSON)
    notes = root.get("notes", []) if isinstance(root, dict) else []
    return [note for note in notes if isinstance(note, dict)]


def scan_usage_note_examples(lexicon, grammar_index, level_name: str, threshold: int):
    """C9-T0 (`--source usage_notes`): scan every example sentence of every
    `usage_notes.json` note at `level_name` for grammar above that level's
    ceiling. Ids here are not vocab/cloze/satz-shaped (`{note id}#example{n}`
    instead), so this calls the shared `_grammar_hits_ge`/quote detectors
    directly rather than routing through `scan_corpus` (which assumes a
    flat rows-with-id-prefix shape used for id/level mismatch reporting).
    The A1-only contracted-aux/attributive-noun sub-checks are skipped on
    purpose: their grade (2) is always below B1/B2's threshold (4/5), so
    `_contracted_aux_hits`/`_attributive_noun_hits` would return [] anyway.
    """

    flagged = []
    target_level = level_name.lower()
    for note in _load_usage_notes():
        if (note.get("level") or "").strip().lower() != target_level:
            continue
        note_id = str(note.get("id") or "")
        for example_index, example in enumerate(note.get("examples", []), start=1):
            if not isinstance(example, dict):
                continue
            text = (example.get("ko") or "").strip()
            if not text:
                continue
            patterns = [
                (h.pattern_id, h.grade, h.text)
                for h in _grammar_hits_ge(lexicon, grammar_index, text, threshold)
            ]
            if QUOTE_GRADE >= threshold:
                quote_hits = set()
                for m in EXPLICIT_QUOTE_RE.finditer(text):
                    quote_hits.add(("explicit_quote_다고라고자고냐고", m.group(0)))
                for m in BARE_QUOTE_HASYEOSEO_RE.finditer(text):
                    quote_hits.add(("bare_quote_하셔서", m.group(0)))
                patterns.extend((pid, QUOTE_GRADE, matched) for pid, matched in quote_hits)
            if patterns:
                flagged.append({
                    "id": f"{note_id}#example{example_index}",
                    "level": target_level,
                    "text": text,
                    "patterns": patterns,
                })
    return flagged


def build_usage_notes_report(level_name: str, threshold: int, flagged: list[dict]) -> str:
    lines = [
        f"# {level_name} usage_notes.json Example Scan (C9-T0, scan_grammar_level.py --source usage_notes)",
        "",
        f"> Detector: same `GrammarIndex` (grade>={threshold} out of level) + explicit "
        "인용 regex used by the corpus scan above, applied to every example sentence "
        "of every `usage_notes.json` note at this level (2 examples/note).",
        "",
        f"- notes scanned: level={level_name}",
        f"- flagged examples: **{len(flagged)}**",
        "",
    ]
    if flagged:
        lines += ["| id | matched pattern(s) | sentence |", "|---|---|---|"]
        for f in sorted(flagged, key=lambda x: x["id"]):
            pats = "; ".join(f"`{pid}`(g{grade}:{m!r})" for pid, grade, m in f["patterns"])
            lines.append(f"| `{f['id']}` | {pats} | {f['text'].replace('|', chr(92) + '|')} |")
    else:
        lines.append("(none)")
    lines.append("")
    return "\n".join(lines)


def run_usage_notes(level_name: str):
    level_name = level_name.upper()
    threshold = LEVEL_CONFIG[level_name]["threshold"]
    lexicon = CefrLexicon.load(ROOT)
    grammar_index = GrammarIndex.load(ROOT)
    flagged = scan_usage_note_examples(lexicon, grammar_index, level_name, threshold)
    report = build_usage_notes_report(level_name, threshold, flagged)
    return report, {"usage_notes": len(flagged)}


def run(level_name: str):
    level_name = level_name.upper()
    cfg = LEVEL_CONFIG[level_name]
    threshold = cfg["threshold"]
    max_headword_grade = cfg["max_headword_grade"]
    target_level = level_name.lower()

    lexicon = CefrLexicon.load(ROOT)
    grammar_index = GrammarIndex.load(ROOT)

    vocab_rows = _load_vocab_rows()
    cloze_items = _load_json(CLOZE_JSON)["items"]
    satz_items = _load_json(SATZ_JSON)["items"]
    for row in vocab_rows:
        row["level"] = (row.get("level") or "").strip().lower()

    vocab_flagged, vocab_mismatch = scan_corpus(
        lexicon, grammar_index, vocab_rows, id_key="id", text_key="example_korean",
        level_key="level", target_level=target_level, kind="vocab",
        threshold=threshold, level_name=level_name,
    )
    cloze_flagged, cloze_mismatch = scan_corpus(
        lexicon, grammar_index, cloze_items, id_key="id", text_key="fullKo",
        level_key="level", target_level=target_level, kind="cloze",
        threshold=threshold, level_name=level_name,
    )
    satz_flagged, satz_mismatch = scan_corpus(
        lexicon, grammar_index, satz_items, id_key="id", text_key="targetKo",
        level_key="level", target_level=target_level, kind="satz",
        threshold=threshold, level_name=level_name,
    )
    vocab_grade_offenders = scan_vocab_outside_grade(lexicon, vocab_rows, level_name, max_headword_grade)

    by_kind_rows = {"vocab": (vocab_rows, "id", "example_korean"),
                     "cloze": (cloze_items, "id", "fullKo"),
                     "satz": (satz_items, "id", "targetKo")}
    by_kind_flagged = {"vocab": vocab_flagged, "cloze": cloze_flagged, "satz": satz_flagged}
    _apply_manual_hits(level_name, by_kind_rows, by_kind_flagged, threshold)

    report = build_report(
        level_name, threshold, vocab_flagged, vocab_mismatch, cloze_flagged,
        cloze_mismatch, satz_flagged, satz_mismatch, vocab_grade_offenders,
    )
    return report, {
        "vocab": len(vocab_flagged), "cloze": len(cloze_flagged), "satz": len(satz_flagged),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--level", default="A1", choices=["A1", "A2", "B1", "B2"])
    parser.add_argument(
        "--source",
        default="corpus",
        choices=["corpus", "usage_notes"],
        help=(
            "'corpus' (default) scans korean_vocab.csv/cloze.json/"
            "satz_sentences.json as before. 'usage_notes' (C9-T0, B1/B2 "
            "only) scans usage_notes.json example sentences instead."
        ),
    )
    parser.add_argument("--out", default=None)
    args = parser.parse_args()

    if args.source == "usage_notes":
        if args.level not in ("B1", "B2"):
            parser.error("--source usage_notes only supports --level B1 or B2")
        report, counts = run_usage_notes(args.level)
        out = args.out or str(
            ROOT / "docs" / "data" / f"usage_notes_grammar_scan_{args.level.lower()}_2026-09-16.md"
        )
        out_path = ROOT / out if not Path(out).is_absolute() else Path(out)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_bytes(report.encode("utf-8"))
        print(f"level={args.level} source=usage_notes flagged: {counts['usage_notes']}")
        print(f"report written: {out_path}")
        return 0

    report, counts = run(args.level)
    out = args.out or str(ROOT / "docs" / "data" / f"grammar_scan_{args.level.lower()}_2026-09-15.md")
    out_path = ROOT / out if not Path(out).is_absolute() else Path(out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(report.encode("utf-8"))

    print(f"level={args.level} vocab flagged: {counts['vocab']}  cloze flagged: {counts['cloze']}  satz flagged: {counts['satz']}")
    print(f"report written: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
