#!/usr/bin/env python3
"""Shared A2-draft-batch authoring/regression helpers.

Generalizes `a1_draft_rules.py` (Batch 26+, extracted from
test_batch_26_draft.py) to the A2(2급) ceiling for Batch 31 (the first A2
reinforcement batch in the C3 series) instead of forking a byte-for-byte
copy: every level-AGNOSTIC helper (eojeol counting, JSON/CSV loading, frame
hashing, opener-pragmatics checks, name-before-씨 extraction, the particle
distractor-particle-mismatches fold check imported from `distractor_rules`)
is imported straight from `a1_draft_rules` unchanged, since none of that
logic is actually A1-specific -- it only ever looked A1-specific because it
was extracted from an A1 test file. Only the two genuinely level-specific
pieces are redefined here:

  1. The vocabulary ceiling: A1 helper words must resolve to NIKL grade-1 /
     live-A1 exactly (0 tolerance); A2 helper words must resolve to NIKL
     grade<=2 OR any live vocabulary (any level -- once a word is already
     taught at some level in the app it is fair game as a helper word) OR
     this batch's own headwords, with a **<=1 unresolved word per sentence**
     tolerance (docs/CONTENT_LEVEL_BIBLE.md §B.2 ⑤: "2급 밖 단어 ≤1"),
     not A1's stricter 0-tolerance rule.
  2. The forbidden-grammar regex list: A1's list encodes "nothing above
     NIKL grade 1 may appear" (i.e. it forbids every 2급 pattern outright).
     A2's list only needs to forbid patterns at or above grade 3 that a
     lightweight regex can usefully catch as a fast pre-check; the
     authoritative gate is the CefrLexicon-based scan (see
     `scan_grammar_level.py --level A2`, reused directly by
     test_batch_31_draft.py) since it already knows the full 45-item
     1+2급 grammar table and every A1 quirk (attributive-noun collocations,
     contracted -아/어 보다/주다, homograph discriminators like
     -(으)ㄹ래요 vs the B2 quoted-contraction "-래요" family) -- this
     module's regex list is deliberately small and only catches the
     handful of grade>=3 items GrammarIndex structurally cannot see at all
     (its own <=2-syllable short-fragment anti-overmatch guard: 잖아, 뿐,
     만큼, 대로, -어도, -어야, -는다 ... see scan_grammar_level.py's module
     docstring "Known structural gap").
"""

from __future__ import annotations

import csv
import re
from pathlib import Path

# Re-export every level-agnostic helper unchanged.
from a1_draft_rules import (  # noqa: F401
    CHARACTER_PROFILES,
    REPO_ROOT,
    ROMANIZATION_RE,
    SINO_NUMERAL_AGE_RE,
    SINO_NUMERALS,
    VOCAB_CSV,
    VOCAB_COLUMNS,
    attach_matching_particle,
    distractor_particle_mismatches,
    eojeol_count,
    frame_key,
    is_bare_ne_or_joayo_opener,
    load_json,
    load_vocab_rows,
    names_before_ssi,
    particle_suffix_of_answer,
    reaction_opener_counts,
    wa_opener_admires_something_present,
)

NIKL_VOCAB_CSV = REPO_ROOT / "tools/content_factory/lexicon/nikl_kiiq_2017_vocab.csv"

# ---------------------------------------------------------------------------
# A2 forbidden-grammar regex (grade>=3 short-fragment items GrammarIndex's
# own anti-overmatch guard cannot see -- see module docstring point 2).
# Deliberately NOT a full 1/2급-vs-3급+ grammar detector: that job belongs to
# scan_grammar_level.py's CefrLexicon-based scan, reused directly by the
# batch's own test (test_a2_grammar_scan_returns_zero below / in
# test_batch_31_draft.py). This list only plugs the specific structural gap
# that scanner's own docstring names.
# ---------------------------------------------------------------------------
FORBIDDEN_GRAMMAR_PATTERNS = [
    re.compile(r"잖아"),      # grade 3, short-fragment gap
    re.compile(r"[가-힣]뿐"),  # grade 3, short-fragment gap ("뿐" alone collides with too much)
    re.compile(r"만큼"),      # grade 3, short-fragment gap
    re.compile(r"[가-힣]대로"),  # grade 3, short-fragment gap
    re.compile(r"어도\b"),    # grade 3, short-fragment gap (concessive -아도/-어도)
    re.compile(r"어야\b"),    # grade 3/4, short-fragment gap (-아야/-어야 "must")
    re.compile(r"다고\s*하"),
    re.compile(r"라고\s*하"),
    re.compile(r"ㄹ지"),
    re.compile(r"더라도"),
    re.compile(r"는\s*바람에"),
]


def load_nikl_grade_le2() -> set[str]:
    with NIKL_VOCAB_CSV.open(encoding="utf-8-sig", newline="") as f:
        return {r["headword"] for r in csv.DictReader(f) if r["grade"] in ("1", "2")}


# Reuse the level-agnostic suffix-stripping table from a1_draft_rules (it
# never referenced a grade anywhere), plus a couple of extra A2-legal
# endings (-을게(요)/-을래(요)/-네요/-는데/-으면/-거나/-게/-다가/-으면서/
# -어 있다/-어 보다/-어 주다/-은 적이 있다/-는 것 같다/-기로 하다/-기 때문에)
# so a sentence that legitimately uses 2급 grammar doesn't get its helper
# words flagged as unresolved just because the ending-stripping table only
# knew 1급 endings.
from a1_draft_rules import HELPER_SUFFIXES as _A1_HELPER_SUFFIXES  # noqa: E402

HELPER_SUFFIXES = sorted(
    set(_A1_HELPER_SUFFIXES)
    | {
        "을게요", "ㄹ게요", "을게", "ㄹ게",
        "을래요", "ㄹ래요", "을래", "ㄹ래",
        "네요", "는데요", "은데요", "ㄴ데요", "는데", "은데", "ㄴ데",
        "으면", "면", "거나", "다가", "으면서", "면서",
        "아 있어요", "어 있어요", "아 있다", "어 있다",
        "아 봤어요", "어 봤어요", "아 보다", "어 보다",
        "아 줬어요", "어 줬어요", "아 주다", "어 주다", "아 줄게요", "어 줄게요",
        "은 적이 있어요", "ㄴ 적이 있어요", "는 적이 있어요",
        "는 것 같아요", "은 것 같아요", "ㄴ 것 같아요", "을 것 같아요", "ㄹ 것 같아요",
        "기로 했어요", "기로 하다",
        "기 때문에",
        "아 놓을게요", "어 놓을게요", "아 놓다", "어 놓다",
        "아서", "부터",
    },
    key=len,
    reverse=True,
)

CLOSED_CLASS_PRONOUNS = {"저", "제", "이", "그", "저는", "제가", "우리"}
GRAMMAR_AUXILIARIES = {"싶다", "않다", "수", "것", "적", "만"}

# Canon-approved A2 persona idioms (docs/CONTENT_PERSONA_VOICE.md §2: "A2 =
# 반말 전환·짧은 관용표현") -- fixed expressions tied to a specific
# character's speech-style marker, not ordinary graded vocabulary, so they
# are exempted from the NIKL-grade/live-vocab resolution the same way a
# persona's own name is.
PERSONA_IDIOMS = {"대박", "그럼 그렇지"}


def build_helper_word_scanner(
    own_rows: list[dict],
    extra_headword_csvs: list[Path] | None = None,
) -> set[str]:
    """Build the "safe word" set for an A2 batch's own helper-word scan:
    NIKL grade<=2 headwords, the ENTIRE live vocabulary (any level -- once
    a word is taught anywhere in the app it is a safe helper word for a
    higher-or-equal level's examples too), this batch's own headwords, any
    prior A2 batches' draft headwords, canonical persona names, closed-class
    pronouns and grammar auxiliaries."""
    nikl = load_nikl_grade_le2()
    live_rows = load_vocab_rows(VOCAB_CSV)
    live_any = {r["korean"] for r in live_rows}
    headwords = {r["korean"] for r in own_rows}
    for p in extra_headword_csvs or []:
        if p.exists():
            headwords |= {r["korean"] for r in load_vocab_rows(p)}
    persona_names = {
        c["displayNames"]["ko"]
        for c in load_json(CHARACTER_PROFILES)["recurringCharacters"]
    }
    return (
        nikl | live_any | headwords | persona_names
        | CLOSED_CLASS_PRONOUNS | GRAMMAR_AUXILIARIES | PERSONA_IDIOMS
    )


_PUNCT_RE = re.compile(r"[!?.,＿]")


def unresolved_helper_tokens(example_korean: str, safe_words: set[str],
                              conjugation_overrides: dict[str, str] | None = None):
    """Same best-effort stem-stripping approach as a1_draft_rules, using
    the A2-extended HELPER_SUFFIXES table above."""
    overrides = conjugation_overrides or {}
    tokens = _PUNCT_RE.sub("", example_korean).replace("…", "").split(" ")
    unresolved = []
    for t in tokens:
        if not t:
            continue
        if t in safe_words:
            continue
        override = overrides.get(t)
        if override and override in safe_words:
            continue
        candidates = set()
        for suf in HELPER_SUFFIXES:
            if t.endswith(suf) and len(t) > len(suf):
                stem = t[: -len(suf)]
                candidates.add(stem)
                candidates.add(stem + "다")
        if candidates & safe_words:
            continue
        unresolved.append(t)
    return unresolved
