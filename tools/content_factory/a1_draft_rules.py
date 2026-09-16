#!/usr/bin/env python3
"""Shared A1-draft-batch authoring/regression helpers.

Extracted from tools/content_factory/test_batch_26_draft.py (Batch 27,
2026-09-15) so a batch's regression test doesn't have to re-copy the same
~200 lines of helper-word scanning, eojeol counting, frame-key hashing and
opener-pragmatics checks every round. Behavior is unchanged from the
Batch 26 test's inline version -- every function here is a straight
extraction, generalized to take the batch's own draft paths/headwords as
parameters instead of hardcoding "batch_26".

Used by test_batch_26_draft.py's successor tests (Batch 27+) and by any
future A1 reinforcement batch's own draft generator/regression test.
"""

from __future__ import annotations

import csv
import json
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
VOCAB_CSV = REPO_ROOT / "assets/data/korean_vocab.csv"
CHARACTER_PROFILES = (
    REPO_ROOT / "tools/content_factory/canonical_scenarios/character_profiles.json"
)
NIKL_GRADE1_CSV = REPO_ROOT / "tools/content_factory/lexicon/nikl_kiiq_2017_vocab.csv"

VOCAB_COLUMNS = [
    "korean", "romanization", "german", "level", "pos_de", "example_korean",
    "example_german", "topic", "pack_id", "pack_order", "is_review_boss",
    "english", "pos_en", "example_english", "id",
]

FORBIDDEN_GRAMMAR_PATTERNS = [
    re.compile(r"다고"),
    re.compile(r"라고\s*하"),
    re.compile(r"ㄹ지"),
    re.compile(r"더라도"),
    re.compile(r"는\s*바람에"),
    re.compile(r"아/어\s*보다"),
    re.compile(r"[가-힣]\s*본\s*적"),  # -은 적 있다/없다 (A2)
    re.compile(r"을게요"),
    re.compile(r"ㄹ게요"),
    re.compile(r"을래요"),
    re.compile(r"ㄹ래요"),
    re.compile(r"으면\b"),
    # -으면/-면 conditional (mid-sentence). Negative lookbehind excludes the
    # lexicalized connective 그러면 ("then/in that case") -- Batch 30
    # (2026-09-16): 그러면 is itself a NIKL grade-1 headword (부사, not a
    # verb-stem+conditional construction), and the plain [가-힣]면\s pattern
    # would otherwise always flag its own example sentence as a false
    # positive. Strictly narrows the match set (can only newly PASS
    # something that used to fail, never break anything that used to pass).
    re.compile(r"(?<!그)[가-힣]면\s"),
    re.compile(r"네요"),
    re.compile(r"는데"),
    re.compile(r"아\s*보다"),
    re.compile(r"어\s*보다"),
    re.compile(r"아\s*주세요"),
    re.compile(r"어\s*주세요"),
    re.compile(r"아\s*줘요"),
    re.compile(r"어\s*줘요"),
    re.compile(r"아\s*줄"),
    re.compile(r"어\s*줄"),
]

ROMANIZATION_RE = re.compile(r"^[a-z ]+$")

# eojeol (어절) = whitespace-separated token, punctuation stripped before counting
_PUNCT_RE = re.compile(r"[!?.,＿]")

SINO_NUMERALS = [
    "일", "이", "삼", "사", "오", "육", "칠", "팔", "구", "십",
    "백", "천", "만",
]
SINO_NUMERAL_AGE_RE = re.compile(
    "(?:" + "|".join(SINO_NUMERALS) + r")\s*살\b"
)


def eojeol_count(sentence: str) -> int:
    stripped = _PUNCT_RE.sub("", sentence)
    return len([t for t in stripped.split(" ") if t])


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def load_vocab_rows(path: Path):
    with path.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def frame_key(example_korean: str, headword: str) -> str:
    """Replace the (first occurrence of the) headword with a placeholder so
    two sentences that differ only by which vocab word they use collapse to
    the same key."""
    return example_korean.replace(headword, "￿", 1)


def load_nikl_grade1() -> set[str]:
    with NIKL_GRADE1_CSV.open(encoding="utf-8", newline="") as f:
        return {r["headword"] for r in csv.DictReader(f) if r["grade"] == "1"}


# Common particle/ending suffixes, longest-first, stripped (with a "stem+다"
# fallback for regular verbs/adjectives) to approximate a dictionary form.
# Best-effort, not a full analyzer.
HELPER_SUFFIXES = sorted([
    "이에요", "예요", "습니다", "합니다", "습니까", "으세요", "세요", "으십시오",
    "을까요", "ㄹ까요", "할까요", "출까요", "칠까요", "갈까요", "올까요", "볼까요",
    "았어요", "었어요", "했어요", "왔어요", "갔어요", "샀어요", "있어요", "없어요",
    "아요", "어요", "해요", "라요",
    "고", "지만", "지만은", "어서", "으니까", "으러", "러", "으려고",
    "에서", "에게", "한테", "에게서", "한테서", "에",
    "으로", "로",
    "이랑", "랑", "하고", "과", "와",
    "이", "가", "을", "를", "은", "는", "도", "만", "의", "이다",
    "게", "히",
], key=len, reverse=True)

CLOSED_CLASS_PRONOUNS = {"저", "제", "이", "그", "저는", "제가", "우리"}
GRAMMAR_AUXILIARIES = {
    "싶다",  # -고 싶다, grammar grade 1
    # Batch 29 (2026-09-16): 않다 (-지 않아요) and 수 (-(으)ㄹ 수 있어요) are
    # both explicitly-permitted 1급 용언 endings for this batch's verb/
    # adjective rows, but neither the negation auxiliary 않다 nor the bound
    # noun 수 ("way, ability") appears as its own headword in the NIKL
    # grade-1 CSV (조사/의존명사 grammar function words are inconsistently
    # covered there) -- added here so the shared helper-word scanner
    # doesn't flag them as unresolved vocabulary in every batch that uses
    # these two endings.
    "않다", "수",
}


def build_helper_word_scanner(
    own_rows: list[dict],
    extra_headword_csvs: list[Path] | None = None,
    conjugation_overrides: dict[str, str] | None = None,
) -> set[str]:
    """Build the "safe word" set for a batch's own helper-word scan:
    NIKL grade-1 headwords, the live A1 CSV, this batch's own headwords,
    any prior batches' draft headwords (extra_headword_csvs), canonical
    persona names, closed-class pronouns and grammar auxiliaries."""
    nikl = load_nikl_grade1()
    live_rows = load_vocab_rows(VOCAB_CSV)
    live_a1 = {r["korean"] for r in live_rows if r["level"] == "A1"}
    headwords = {r["korean"] for r in own_rows}
    for p in extra_headword_csvs or []:
        if p.exists():
            headwords |= {r["korean"] for r in load_vocab_rows(p)}
    persona_names = {
        c["displayNames"]["ko"]
        for c in load_json(CHARACTER_PROFILES)["recurringCharacters"]
    }
    safe = (
        nikl | live_a1 | headwords | persona_names
        | CLOSED_CLASS_PRONOUNS | GRAMMAR_AUXILIARIES
    )
    return safe


def unresolved_helper_tokens(
    example_korean: str, safe_words: set[str],
    conjugation_overrides: dict[str, str] | None = None,
):
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


REACTION_OPENERS = ["와", "아", "음", "네", "좋아요"]


def reaction_opener_counts(rows: list[dict]) -> dict:
    from collections import Counter
    counts: Counter = Counter()
    for row in rows:
        ex = row["example_korean"]
        for op in REACTION_OPENERS:
            if ex.startswith(op + ",") or ex.startswith(op + "!") or ex.startswith(op + "..."):
                counts[op] += 1
                break
    return dict(counts)


_WA_DEMONSTRATIVE_RE = re.compile(r"^와[,!]\s*[이그저][가-힣]")


def wa_opener_admires_something_present(example_korean: str) -> bool:
    """True if a '와' opener (if present) is valid -- i.e. followed by a
    demonstrative + noun/adjective exclamation, not a bare invitation."""
    ex = example_korean
    if not (ex.startswith("와,") or ex.startswith("와!")):
        return True
    has_demonstrative = bool(_WA_DEMONSTRATIVE_RE.match(ex))
    is_bare_invitation_question = ex.rstrip().endswith("까요?")
    return not (is_bare_invitation_question and not has_demonstrative)


def is_bare_ne_or_joayo_opener(example_korean: str) -> bool:
    ex = example_korean
    return ex.startswith("네,") or ex.startswith("좋아요,")


# {1,5}: covers every canonical persona name length, including the
# 1-syllable "준" and the 5-syllable "크리스티안" -- Batch 26's original
# {2,4} cap silently mismatched 5-syllable names (e.g. "크리스티안 씨" would
# extract "리스티안", not "크리스티안"), which Batch 26 never hit only
# because it happened not to write that exact name-plus-씨 string anywhere
# (Batch 27 authoring, 2026-09-15).
# \s+ (one-or-more), not \s* -- Batch 29 (2026-09-16): \s* let this match
# inside an unrelated compound word that merely happens to end in the
# syllable 씨 with no space before it, e.g. "날씨" (weather) tokenizes as
# "날" + "씨" and was misread as the name "날" before the honorific 씨. The
# app's own convention always writes a real name address with a space
# before 씨 (every canonical persona example is "레나 씨", "마야 씨", ...,
# never a glued "레나씨"), so requiring at least one space is a strictly
# more correct match with no loss of true positives across Batch 25-28's
# own content (spot-checked: none rely on a zero-space glued name+씨).
NAME_BEFORE_SSI_RE = re.compile(r"([가-힣]{1,5})\s+씨")


def names_before_ssi(example_korean: str):
    return [m.group(1) for m in NAME_BEFORE_SSI_RE.finditer(example_korean)]


# ---------------------------------------------------------------------------
# Particle-form leak (Fable coordinator review of PR #344, 2026-09-15).
#
# When a cloze `answer` is a headword+particle fold (e.g. "생활이", "잠을",
# "드라마를", "주에" -- used throughout Batch 26-28 to fold a 1-syllable
# headword or to avoid a batchim-alternating particle sitting exposed right
# after the blank), the DISTRACTOR strings must carry a particle too, and
# the correct allomorph for each distractor's OWN final sound (마시다 ->
# "사과를"/"우유를"/"안경을", never bare "사과"/"우유"/"안경"). Otherwise the
# answer is the only option with a particle attached and is trivially
# identifiable by FORM alone, regardless of Korean comprehension -- live A1
# content already does this correctly (cloze_a1_0169: 잎을 vs 송편을/귀성을/
# 명절 증후군을). Batch 27 and Batch 28 both had rows where the fold applied
# to the answer but not to the distractors; see distractor_particle_mismatches
# below, wired into each batch's own regression test.
from distractor_rules import ALTERNATING_PARTICLES, batchim_class  # noqa: E402


def particle_suffix_of_answer(headword: str, answer: str):
    """If `answer` is exactly `headword` plus a trailing suffix (a
    particle/copula fold), return that suffix; otherwise None (e.g. answer
    is a conjugated predicate for the predicate-slot waiver, not a fold,
    or answer == headword with nothing appended)."""
    if answer.startswith(headword) and len(answer) > len(headword):
        return answer[len(headword):]
    return None


def distractor_particle_mismatches(headword: str, answer: str, distractors):
    """Return the subset of `distractors` that do NOT carry a particle
    consistent with the fold in `answer` (empty list = all consistent, or
    the rule doesn't apply because `answer` isn't a headword+particle
    fold). For an alternating particle (이에요/예요, 이/가, 을/를, 은/는,
    과/와, 으로/로) each distractor must end with the allomorph that
    matches ITS OWN final-sound class, not necessarily the same literal
    text as the answer's suffix. For any other (non-alternating: 에/에서/
    한테/도/...) suffix, every distractor must end with that exact same
    text."""
    suffix = particle_suffix_of_answer(headword, answer)
    if not suffix:
        return []
    for cform, vform, kind in ALTERNATING_PARTICLES:
        if suffix not in (cform, vform):
            continue
        bad = []
        for d in distractors:
            if d.endswith(cform) and len(d) > len(cform):
                base = d[: -len(cform)]
                if batchim_class(base, kind) != "consonant":
                    bad.append(d)
            elif d.endswith(vform) and len(d) > len(vform):
                base = d[: -len(vform)]
                if batchim_class(base, kind) == "consonant":
                    bad.append(d)
            else:
                bad.append(d)
        return bad
    # Non-alternating particle (에/에서/한테/도/...): exact suffix match.
    return [d for d in distractors if not d.endswith(suffix)]


def attach_matching_particle(word: str, headword: str, answer: str) -> str:
    """Build the distractor form of `word` that carries the same particle
    as `answer` (a headword+particle fold) -- the inverse helper used to
    FIX a distractor list, mirroring distractor_particle_mismatches'
    matching logic. Returns `word` unchanged if `answer` isn't a fold."""
    suffix = particle_suffix_of_answer(headword, answer)
    if not suffix:
        return word
    for cform, vform, kind in ALTERNATING_PARTICLES:
        if suffix not in (cform, vform):
            continue
        cls = batchim_class(word, kind)
        return word + (cform if cls == "consonant" else vform)
    return word + suffix
