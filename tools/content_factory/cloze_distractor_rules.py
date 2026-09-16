#!/usr/bin/env python3
"""Level-agnostic cloze-distractor hygiene rules (C2c, 2026-09-15).

Extends `distractor_rules.py` (D1 받침-class + the A1 Batch 25/26/27
predicate-slot waiver) and the level-specific `ACTIVITY_NOUN_SET` curated on
the (unmerged, draft) `claude/c3-batch28-a1-20260915` branch into a
level-agnostic module any live-corpus tool can import, per Fable's C2c task
brief: "reuse, extend into a level-agnostic cloze_distractor_rules.py if
needed."

R8-2 (2026-09-15): added a two-tier scheme for D3-flagged/open-frame
distractor re-picks -- Tier A (default, `check_d3_pos_form`'s normal
POS/form matching against a semantically-clashing candidate) and Tier B
(`OPEN_SLOT_WAIVER`, a last resort for frames with no selectional
restriction at all -- see that dict's docstring and the audit report's
"R8-2" section for the full read that drove each assignment) plus
`MIXED_TIER_IDS` for the few items needing 2 Tier-A + 1 waiver word.

Implements the mechanical (deterministically checkable) half of D1-D6:
  D1  받침 class before an alternating particle right after the blank
      (이/가·을/를·은/는·과/와·(으)로, ㄹ-final counted on its own before
      으로/로) -- every distractor must match the answer's own class.
      -> reused straight from distractor_rules.detect_required_class /
         batchim_class (already level-agnostic: it looks only at the
         answer's/distractor's own final syllable, never at level).
  D2  particle form -- if `answer` itself ends in an attached particle/
      connective suffix (the blank spans more than the bare headword),
      every distractor must carry the SAME suffix string, not just any
      particle.
  D3  POS / conjugation-form match -- >=2/3 distractors share the answer's
      POS (per korean_vocab.csv `pos_de`) and, for a verb/adjective answer,
      the same conjugation suffix (resolved by stripping a common ending
      and checking the stem, or stem+다, against the vocab headwords) --
      unless the item is a known predicate-slot-waiver item, in which case
      only the waiver pool (bare dictionary-form verb/adjective or a bare
      particle) is accepted. Answers/distractors this heuristic cannot
      resolve to a vocab-backed POS are reported as "unresolved" rather
      than flagged, to avoid false positives from the suffix list's
      inherent incompleteness at B1+ (documented in the audit report).
  D4  N+하다 / 배우다 / 잘하다 activity-noun slots -- no distractor may be
      an activity noun: any live headword that appears with 하다 (i.e. any
      korean_vocab.csv `korean` value stripped of a trailing 하다 forms
      another live headword or is itself a live noun), plus the curated
      `ACTIVITY_NOUN_SET` pulled from Batch 28's mechanical rule.
  D5  open noun slots (existential 있어요/없어요, adjective predicates
      예뻐요/좋아요/커요/맛있어요/재미있어요, 좋아해요 objects) --
      detection only (which items have this sentence shape); the
      semantic-class-incompatibility judgement itself is not mechanical
      and is done by a human/LLM read of each flagged item (see the C2c
      task's step 2), not by this module.
  D6  no distractor in the sentence remainder; no duplicate distractors;
      reuse caps -- reuse tracking is corpus-wide (stateful), so it is
      implemented as a small class (`ReuseTracker`) rather than a pure
      function, unlike D1-D5.

D7 (never a second valid answer) is the umbrella judgement rule, not a
separate mechanical check -- it is what the D5 human read and the general
re-pick discipline in the fixer script are FOR, not something this module
audits on its own.
"""

from __future__ import annotations

import csv
from collections import defaultdict
from pathlib import Path
from typing import Iterable, Optional

from distractor_rules import (  # noqa: F401  (re-exported for convenience)
    ALTERNATING_PARTICLES,
    BARE_PARTICLES,
    DICTIONARY_FORM_VERBS,
    NOUN_EXCEPTIONS,
    PREDICATE_SLOT_WAIVER,
    RIEUL_JONG,
    batchim_class,
    detect_required_class,
    jong_index,
    # OPEN_SLOT_WAIVER is defined below, not imported -- it is a C2c-only
    # (level-agnostic, corpus-wide) registry, unlike PREDICATE_SLOT_WAIVER
    # which lives in distractor_rules.py as the original A1 Batch 25/26/27
    # curation.
    waived_distractor_ok,
)

REPO_ROOT = Path(__file__).resolve().parents[2]
VOCAB_CSV = REPO_ROOT / "assets/data/korean_vocab.csv"
BLANK = "＿＿＿"

LEVEL_ORDER = ["a1", "a2", "b1", "b2", "c1", "c2"]


def level_rank(level: str) -> int:
    lv = (level or "").strip().lower()
    return LEVEL_ORDER.index(lv) if lv in LEVEL_ORDER else len(LEVEL_ORDER)


# ---------------------------------------------------------------------------
# Vocab index
# ---------------------------------------------------------------------------


def load_vocab_rows(path: Path = VOCAB_CSV) -> list[dict]:
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


class VocabIndex:
    """Lookup helpers built once over korean_vocab.csv, shared by the
    audit and fixer scripts."""

    def __init__(self, rows: list[dict]):
        self.rows = rows
        self.by_word: dict[str, list[dict]] = defaultdict(list)
        self.by_level_pos: dict[tuple[str, str], list[dict]] = defaultdict(list)
        self.by_level: dict[str, list[dict]] = defaultdict(list)
        self.hada_activity_nouns: set[str] = set()
        for r in rows:
            word = r["korean"].strip()
            lv = r["level"].strip().lower()
            self.by_word[word].append(r)
            self.by_level_pos[(lv, r["pos_de"])].append(r)
            self.by_level[lv].append(r)
            if word.endswith("하다") and len(word) > 2:
                self.hada_activity_nouns.add(word[: -len("하다")])

    def pos_of(self, word: str) -> Optional[str]:
        rows = self.by_word.get(word)
        return rows[0]["pos_de"] if rows else None


# ---------------------------------------------------------------------------
# D2 -- particle form
# ---------------------------------------------------------------------------

# Genuine case/postposition particles only (longest-first so "에게서"/
# "한테서" aren't mis-stripped as "에게"/"한테" + 서). Deliberately excludes
# the copula "이에요"/"예요" and connective endings like "-고"/"-기로" --
# those attach to a full clause/predicate (multi-word "whole predicate"
# blanks, e.g. "결말을 유보하고", "직업이 뭐예요") and are judged by D3's
# ending_signature() instead, which compares the grammatical ending itself
# rather than requiring the literal particle string, and doesn't collide
# with case particles that happen to share a substring with a verb ending
# (e.g. "하고" is both the comitative particle "with" AND 하다+고 "-고"
# connective on a completely unrelated verb -- see cloze_c2_0024/0052).
PARTICLE_SUFFIXES = sorted(
    [
        "에게서", "한테서",
        "에서", "에게", "한테",
        "으로", "로",
        "이랑", "랑",
        "까지", "부터",
        "과", "와",
    ],
    key=len,
    reverse=True,
)


def matching_particle_suffix(answer: str, vocab: "VocabIndex") -> Optional[str]:
    """If `answer` is a single token (no space -- a multi-word answer is a
    whole-predicate/clause blank, not a noun+particle) that ends with a
    recognized case particle AND at least 2 characters remain before it (a
    real stem) AND the full `answer` string is NOT itself already a bare
    vocab headword (a word whose own last syllable happens to coincide
    with a particle, e.g. "교차로" ends in "로" but is not "교차" + the
    -로 particle), return that suffix string; else None."""
    a = (answer or "").strip()
    if " " in a or a in vocab.by_word:
        return None
    for suf in PARTICLE_SUFFIXES:
        if a.endswith(suf) and len(a) - len(suf) >= 2:
            return suf
    return None


def check_d2_particle_form(
    answer: str, distractors: Iterable[str], vocab: "VocabIndex"
) -> list[str]:
    """Distractors that fail to carry the same attached case-particle
    suffix as `answer`. Empty list if `answer` isn't itself particle-
    attached (matching_particle_suffix returns None) -- D2 doesn't apply."""
    suf = matching_particle_suffix(answer, vocab)
    if suf is None:
        return []
    return [d for d in distractors if not d.endswith(suf)]


# ---------------------------------------------------------------------------
# D3 -- POS / conjugation-form match
# ---------------------------------------------------------------------------

# Common conjugation endings, longest-first, stripped to approximate a
# dictionary-form stem (extends a1_draft_rules.HELPER_SUFFIXES with a few
# higher-level endings so B1+ verbs/adjectives resolve too where the
# corpus's own vocabulary still contains the dictionary form). Best-effort:
# an ending this list doesn't recognize resolves to "unresolved", not a
# false-positive violation.
ENDING_SUFFIXES = sorted(
    [
        "습니다", "합니다", "습니까", "으세요", "세요", "으십시오",
        "을까요", "ㄹ까요", "할까요",
        "았어요", "었어요", "했어요", "왔어요", "갔어요", "샀어요",
        "있어요", "없어요",
        "이에요", "예요",
        "아요", "어요", "해요", "라요",
        "았습니다", "었습니다", "했습니다",
        "고 있어요", "고 싶어요", "고 싶습니다",
        "지 않아요", "지 않습니다",
        "을 거예요", "ㄹ 거예요",
        "네요", "잖아요", "거든요", "더라고요",
        "은데요", "는데요", "ㄴ데요",
        "고", "지만", "어서", "아서", "으니까", "니까",
        "으러", "러", "으려고", "려고",
        "은", "는", "을", "ㄹ",
        "요",  # lowest-priority catch-all: bare polite -요 ending (surface
               # contraction, e.g. 가요/와요/타요, doesn't literally contain
               # 아요/어요 as a substring) -- coarser than the specific
               # endings above but still a genuine conjugation-shape signal,
               # only reached when nothing more specific matched.
        "다",  # dictionary-form ending, lowest priority after -요.
    ],
    key=len,
    reverse=True,
)


def ending_signature(word: str) -> Optional[str]:
    """The longest ENDING_SUFFIXES suffix `word` ends with, purely
    structurally (no vocab lookup) -- this is what makes it usable on
    multi-word phrase answers/distractors (e.g. "결말을 유보하고"), whose
    stems are never themselves vocab headwords. None if nothing matches."""
    for suf in ENDING_SUFFIXES:
        if word.endswith(suf) and len(word) > len(suf):
            return suf
    return None


def ending_signatures(word: str) -> set[str]:
    """Every ENDING_SUFFIXES suffix `word` ends with (not just the longest
    one). Needed because Korean past-tense/formal markers contract into a
    vowel-final stem's last syllable (바꾸다+었->바꿨, not a literal "었"
    substring), so a verb whose stem happens NOT to contract (들다+었->
    들었, literal "었" survives) matches a longer, more specific suffix
    than a same-tense verb whose stem DOES contract -- both are the exact
    same grammatical ending (같은 과거형 어미), just a different surface
    contraction. Comparing the single longest match per word would treat
    that contraction difference as a form mismatch; comparing the full set
    (see `same_ending`) still finds their shared shorter suffix (both end
    in plain "습니다"/"어요" etc. even when only one also matches a longer,
    more specific variant)."""
    return {suf for suf in ENDING_SUFFIXES if word.endswith(suf) and len(word) > len(suf)}


def same_ending(a: str, b: str) -> bool:
    """True if `a` and `b` share a genuine ENDING_SUFFIXES suffix.

    The bare "다" catch-all (dictionary-form ending) is deliberately
    excluded from ordinary matching: it is also the LITERAL LAST CHARACTER
    of the "-습니다"/"-ㅂ니다" formal register (실례합니다, 갑니다, ...),
    so without this guard a dictionary-form answer (전달하다) would
    spuriously "match" a completely different, formally-conjugated
    distractor (실례합니다) purely because both happen to end in the
    single character "다" -- not because they share any real grammatical
    ending (Fable R8 finding, cloze_b1_0184, 2026-09-15). "다" only counts
    as a genuine match when it is EACH word's *only* matching suffix --
    i.e. both are actually bare dictionary form, with no more specific
    ending recognized on either side."""
    sig_a, sig_b = ending_signatures(a), ending_signatures(b)
    shared = sig_a & sig_b
    if shared == {"다"}:
        return sig_a == {"다"} and sig_b == {"다"}
    return bool(shared - {"다"})


def rieul_adnominal_ending(word: str) -> bool:
    """True if `word`'s last syllable has jongseong ㄹ -- covers both
    surface realizations of the -(으)ㄹ future/probable adnominal ending
    (common before 수 있다/없다, 것, 거예요, ...): the literal "을" syllable
    after a consonant-final stem (가로막다 -> 가로막을), and the bare ㄹ
    fused onto a vowel-final stem's own last syllable (늘리다 -> 늘릴,
    하다 -> 할, 줄이다 -> 줄일) -- a plain substring search can never find
    that second form (there is no separate "ㄹ" syllable to match; the
    standalone jamo character doesn't occur in precomposed Hangul text),
    so without this, same-stem-shape distractors using the contracted form
    would wrongly fail to match an answer that happens to use the
    uncontracted "을" form, and vice versa. Only used as a same-ending
    fallback, never to trigger `ending_signature` itself, so a
    coincidentally ㄹ-final noun only ever causes an UNDER-flag (fewer
    violations caught), never a bad rewrite."""
    return bool(word) and jong_index(word[-1]) == RIEUL_JONG


def resolve_pos_and_form(word: str, vocab: VocabIndex):
    """Best-effort (pos_de, conjugation_suffix_or_None, matched_headword) for
    `word`. `conjugation_suffix` is None when `word` itself is a vocab
    headword (dictionary form / bare noun -- nothing conjugated to match),
    and a suffix string when `word` was resolved by stripping a known
    ending and finding the stem (or stem+다) among the vocab headwords.
    Returns (None, None, None) when nothing resolves."""
    if word in vocab.by_word:
        return vocab.pos_of(word), None, word
    for suf in ENDING_SUFFIXES:
        if word.endswith(suf) and len(word) > len(suf):
            stem = word[: -len(suf)]
            for cand in (stem, stem + "다"):
                if cand in vocab.by_word:
                    return vocab.pos_of(cand), suf, cand
    return None, None, None


VERB_LIKE_POS = {"Verb", "Adjektiv"}

# Coarse POS bucket for a word that carries no recognizable conjugation
# ending (ending_signature is None -- so it's some bare noun/adverb/
# pronoun/expression, never a verb/adjective surface form). korean_vocab.csv
# only has ~2,560 headwords, so a great many perfectly ordinary distractor
# nouns (e.g. "손상", "불편") are NOT themselves vocab rows -- requiring an
# exact vocab match here would flag them as a "POS mismatch" just because
# they're absent from the CSV, not because they're actually a different
# part of speech. Coarse-bucket by shape instead: a closed list catches the
# (rare, high-frequency) adverbs/pronouns; a multi-word answer is its own
# "EXPR" bucket; everything else defaults to NOUN, matching this
# vocabulary's actual composition (Nomen is the largest pos_de bucket by a
# wide margin) and erring toward NOT flagging when genuinely uncertain.
POS_TO_COARSE = {
    "Nomen": "NOUN", "Pronomen": "NOUN",
    "Verb": "VERBADJ", "Adjektiv": "VERBADJ", "Verbphrase": "VERBADJ",
    "Adverb": "ADV",
    # "Ausdruck"/"Phrase" in korean_vocab.csv is a catch-all for multi-word
    # headwords regardless of their syntactic role -- in practice the
    # overwhelming majority filling a cloze noun-object/subject slot (this
    # branch is only reached when the answer has NO recognizable
    # conjugation ending, i.e. it isn't a verb/adjective phrase -- those
    # are already handled by the `a_sig` branch above) are compound noun
    # phrases (e.g. "조정 신청", "하자 보수"), not idioms. Bucketing them
    # with NOUN rather than a separate EXPR avoids false POS-mismatches
    # against single-word Nomen distractors that fill the exact same slot.
    "Ausdruck": "NOUN", "Phrase": "NOUN",
}
CLOSED_ADV_WORDS = frozenset({
    "빨리", "천천히", "가끔", "항상", "다시", "아주", "바로", "주로",
    "이따가", "꼭", "좀", "함께", "참", "정말", "진짜", "아마", "거의",
    "자주", "보통", "오히려", "특히", "심지어", "마침내", "드디어", "혹시",
    "제발", "과연", "전혀", "별로", "무조건", "확실히", "이미", "벌써",
    "곧", "매우", "너무", "조금", "많이", "훨씬", "점점", "서로", "각자",
    "따로", "계속", "일단", "우선", "결국", "왜냐하면", "그래서", "그러나",
    "하지만", "그런데", "그리고",
})
CLOSED_PRONOUNS = frozenset({
    "저", "제", "저는", "제가", "우리", "저희", "이것", "그것", "저것",
    "여기", "거기", "저기",
})


def coarse_pos(word: str, vocab: VocabIndex) -> str:
    """NOUN / VERBADJ / ADV bucket for a word with no recognizable
    conjugation ending -- see module comment above for why this doesn't
    require an exact vocab match. A multi-word phrase not itself in the
    vocabulary defaults to NOUN too (same reasoning as the Ausdruck/Phrase
    mapping above: this branch is only reached when the phrase has no
    verb/adjective-shaped ending, so it's overwhelmingly a compound noun
    phrase)."""
    if word in vocab.by_word:
        return POS_TO_COARSE.get(vocab.pos_of(word), "NOUN")
    if word in CLOSED_ADV_WORDS:
        return "ADV"
    # Sino-Korean -적 productively forms adjective/adnominal words
    # (일방적, 부수적, 잠정적, ...) that aren't all individually vocab
    # headwords -- korean_vocab.csv tags the ones that ARE present as
    # Adjektiv (see "자의적"), so an out-of-vocab -적 word gets the same
    # bucket rather than defaulting to NOUN.
    if word.endswith("적") and len(word) >= 2:
        return "VERBADJ"
    return "NOUN"


def check_d3_pos_form(
    answer: str,
    distractors: list[str],
    vocab: VocabIndex,
    cloze_id: Optional[str] = None,
) -> tuple[list[str], bool, Optional[str]]:
    """Returns (non_matching_distractors, unresolved, answer_pos).

    `unresolved` is True only when the answer is a single token, absent
    from the vocabulary, not a closed-class adverb/pronoun, and carries no
    recognizable conjugation ending -- i.e. `coarse_pos` would have to
    guess NOUN by default with zero corroborating signal. Callers should
    not treat that as a rule violation. Waiver items (PREDICATE_SLOT_WAIVER)
    are judged by `waived_distractor_ok` instead of POS/form matching.

    Matching strategy (tightened 2026-09-15, Fable R8 -- a POS-only
    fallback let a dictionary-form answer like "전달하다" accept
    conjugated distractors such as "실례합니다"/"잘 다녀오겠습니다" as
    "matching" purely because both resolve to Verb in the vocabulary; that
    is not the same FORM, only the same part of speech, and the rule is
    explicit that verbs need the same ending): when the answer carries a
    recognizable conjugation ending (`ending_signature` resolves, e.g. any
    verb/adjective form, or a multi-word whole-predicate/clause answer
    like "결말을 유보하고"), "same conjugated form" is judged structurally
    -- same ending string, via `same_ending`/`rieul_adnominal_ending` --
    with NO further POS-only fallback; a distractor that doesn't share the
    answer's actual ending is a violation regardless of its POS. This
    works even when a distractor phrase's stem isn't itself a vocab
    headword (the normal case for hand-authored multi-word distractors).
    When the answer has no recognizable ending at all (a bare noun/
    adverb/etc.), matching falls back to `coarse_pos` bucket equality
    (NOUN/VERBADJ/ADV) rather than requiring an exact vocab match on both
    sides -- most distractor words in this corpus are NOT themselves
    vocab headwords."""
    a_pos, a_suf, _ = resolve_pos_and_form(answer, vocab)
    a_sig = ending_signature(answer)
    # A bare noun that happens to end in the same syllable as the -고
    # connective (연고 "ointment", 신고 "report", 채용 공고 "job
    # posting", ...) is not actually a conjugated form -- without this,
    # a_sig="고" would demand a same-ending VERB/CLAUSE match against
    # what are correctly noun-class Tier-A distractors (both here and in
    # the R8-2 candidate generator, which applies this identical, equally
    # narrow override -- see build_r8_2_tier_picks.py).
    if a_sig == "고" and answer in vocab.by_word and vocab.pos_of(answer) in (
        "Nomen", "Ausdruck", "Phrase", "Pronomen"
    ):
        a_sig = None
    # C3-T3 (2026-09-16): same override for "다" -- the comment above used
    # to claim Korean nouns essentially never coincidentally end in "다",
    # which was true of the corpus at the time but broke on Batch 26's
    # 캐나다/사이다/바다 (Nomen, all end in the syllable "다"): without
    # this, a_sig="다" demands a same-ending VERB match against correctly
    # noun-class country/drink/nature distractors, and -- worse -- lets an
    # unrelated bare dictionary-form VERB distractor (which also happens
    # to end in "다", e.g. "입다") pass purely by coincidence while the
    # genuinely correct noun distractors fail. Deliberately narrower than
    # the "고" override above: scoped to "Nomen" ONLY, not "Ausdruck"/
    # "Phrase" -- unlike -고 nominal expressions, many Ausdruck/Phrase
    # entries ending in "다" (e.g. "같이 웃다") are genuine verb-phrase
    # predicates in dictionary form, so including them here would
    # misroute real conjugated-predicate answers to noun matching (see
    # test_genuine_predicate_ending_in_da_is_not_misrouted). A real verb
    # dictionary-form answer resolves as Verb, not Nomen, so it is
    # untouched by this override either way.
    if a_sig == "다" and answer in vocab.by_word and vocab.pos_of(answer) == "Nomen":
        a_sig = None

    if cloze_id is not None and cloze_id in PREDICATE_SLOT_WAIVER:
        bad = [d for d in distractors if not waived_distractor_ok(d, cloze_id)]
        return bad, False, a_pos
    if cloze_id is not None and cloze_id in OPEN_SLOT_WAIVER:
        bad = [d for d in distractors if not waived_distractor_ok(d, cloze_id)]
        return bad, False, a_pos
    if cloze_id is not None and cloze_id in MIXED_TIER_IDS:
        # 2 Tier-A (same-ending, semantically clashing) distractors + 1
        # OPEN_SLOT_WAIVER word (Fable's "mixed composition... when only
        # two clashing candidates exist" allowance) -- a distractor
        # passes if it satisfies EITHER acceptance test.
        def _mixed_ok(d: str) -> bool:
            if waived_distractor_ok(d, cloze_id):
                return True
            if a_sig is not None:
                return same_ending(answer, d) or (
                    rieul_adnominal_ending(answer) and rieul_adnominal_ending(d)
                )
            return coarse_pos(d, vocab) == coarse_pos(answer, vocab)

        bad = [d for d in distractors if not _mixed_ok(d)]
        if len(distractors) - len(bad) >= 2:
            return [], False, a_pos
        return bad, False, a_pos

    unresolved = (
        a_sig is None
        and a_pos is None
        and " " not in answer
        and answer not in CLOSED_ADV_WORDS
        and answer not in CLOSED_PRONOUNS
    )
    if unresolved:
        return [], True, None

    def matches(d: str) -> bool:
        if a_sig is not None:
            if same_ending(answer, d):
                return True
            if rieul_adnominal_ending(answer) and rieul_adnominal_ending(d):
                return True
            return False
        # a_sig is None here -> answer has no recognizable ending (bare
        # noun/adverb/pronoun/expression); compare coarse POS buckets
        # instead of requiring both sides to be exact vocab headwords.
        return coarse_pos(d, vocab) == coarse_pos(answer, vocab)

    non_matching = [d for d in distractors if not matches(d)]
    # Rule: >= 2/3 distractors must match -> violation iff more than 1 fails.
    if len(distractors) - len(non_matching) >= 2:
        return [], False, a_pos
    return non_matching, False, a_pos


# ---------------------------------------------------------------------------
# OPEN_SLOT_WAIVER -- generalizes PREDICATE_SLOT_WAIVER's technique (Fable
# R8 ruling, 2026-09-15) from "answer = the whole predicate" to any slot a
# same-POS/same-form/topic-distant NOUN re-pick cannot safely close.
#
# The C2c sweep's own D5 human read (115 open-noun-slot items) and a
# 40-item Jin sample QA pass both turned up items where a mechanically
# "correct" re-pick (same batchim class, same POS, same conjugation form,
# even a topically-distant or abstract noun) STILL produced a fully valid
# alternate sentence -- e.g. "다양한 관점이 있어요" (answer) vs "다양한
# 느낌/비용이 있어요" (all still read as natural Korean; "다양한 X이
# 있어요" accepts nearly any plural-compatible noun regardless of how
# abstract or off-topic X is), or "늦게 와서 정말 죄송해요." (answer) vs
# "늦게 와서 정말 피곤해요." (same POS, same -해요 ending, still a
# completely natural sentence). No noun-semantic-class exclusion closes a
# slot that open -- the ONLY reliable technique is the same one
# PREDICATE_SLOT_WAIVER already uses: a distractor that is GRAMMATICALLY
# impossible in the slot (a bare dictionary-form verb/adjective where a
# noun or a conjugated predicate is required, or a bare particle with no
# host), which guarantees no valid parse regardless of how open the
# surrounding sentence is.
#
# Composition per item, mirroring PREDICATE_SLOT_WAIVER's own convention:
# 2 dictionary-form verbs/adjectives + 1 bare particle (or all 3
# dictionary-form when no safe bare-particle candidate exists for that
# slot's particle context).
#
# `OPEN_SLOT_WAIVER` maps each waived cloze id to the reason its answer's
# slot cannot be closed by any noun/adjective-class exclusion --
# determined by the full sentence-by-sentence read logged in
# docs/data/cloze_distractor_audit_2026-09-15.md (step "R8 full read").
OPEN_SLOT_WAIVER: dict[str, str] = {
    'cloze_a1_0007': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0008': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0009': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0013': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0018': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0021': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0022': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0031': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0038': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0040': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0066': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0070': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0077': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0080': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0081': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0083': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0085': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0086': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0090': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0091': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0092': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0098': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0099': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0100': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0101': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0109': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0110': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0115': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0135': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0162': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0187': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0190': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0195': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0211': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0213': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0222': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0225': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0226': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0227': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0228': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0230': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0241': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0255': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0265': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0267': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0280': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0281': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0285': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0286': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0287': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0288': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0290': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0291': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0306': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0307': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0308': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0309': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0311': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0313': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0316': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0322': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0327': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0332': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0355': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0398': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0399': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0401': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0402': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0408': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0409': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0410': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0411': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0412': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0414': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0420': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0427': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0429': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0432': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a1_0436': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0005': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0007': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0018': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0020': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0022': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0030': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0032': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0033': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0034': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0037': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0038': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0039': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0040': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0041': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0042': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0046': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0050': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0056': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0057': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0058': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0059': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0069': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0074': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0076': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0113': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0169': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0174': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0193': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0223': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_a2_0243': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0007': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0008': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0009': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0016': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0020': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0026': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0027': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0028': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0029': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0030': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0031': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0032': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0033': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0036': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0052': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0107': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0190': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0198': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0204': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0210': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0213': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0224': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0254': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0262': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b1_0274': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b2_0002': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b2_0007': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b2_0034': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b2_0040': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b2_0270': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b2_0292': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b2_0361': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_b2_0393': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_c1_0114': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    'cloze_c2_0221': 'R8-3 tier B (2026-09-15): truly bare frame with no selectional restriction, confirmed by the R8-2/R8-3 read (docs/data/cloze_distractor_audit_2026-09-15.md)',
    # C3-T5 (2026-09-16): Batch 30 A1 reinforcement (function words) -- a
    # sentence-initial discourse-connective slot (그래서/그러니까/그러면/
    # 그런데/그럼/그렇지만/그리고/하지만) accepts almost any OTHER connective
    # too, so distractors are Tier B (bare dictionary-form verb or bare
    # particle, never another connective) per posRules.adverbs_connective
    # in tools/content_factory/drafts/batch_30_a1_reinforcement_manifest.
    # json; verified by test_batch_30_draft.py's
    # test_connective_distractors_are_bare_dictionary_verb_or_particle.
    'cloze_a1_0714': 'C3-T5 tier B (2026-09-16): Batch 30 discourse-connective open frame, bare dictionary-verb/particle distractors (see manifest posRules.adverbs_connective)',
    'cloze_a1_0715': 'C3-T5 tier B (2026-09-16): Batch 30 discourse-connective open frame, bare dictionary-verb/particle distractors (see manifest posRules.adverbs_connective)',
    'cloze_a1_0716': 'C3-T5 tier B (2026-09-16): Batch 30 discourse-connective open frame, bare dictionary-verb/particle distractors (see manifest posRules.adverbs_connective)',
    'cloze_a1_0717': 'C3-T5 tier B (2026-09-16): Batch 30 discourse-connective open frame, bare dictionary-verb/particle distractors (see manifest posRules.adverbs_connective)',
    'cloze_a1_0718': 'C3-T5 tier B (2026-09-16): Batch 30 discourse-connective open frame, bare dictionary-verb/particle distractors (see manifest posRules.adverbs_connective)',
    'cloze_a1_0719': 'C3-T5 tier B (2026-09-16): Batch 30 discourse-connective open frame, bare dictionary-verb/particle distractors (see manifest posRules.adverbs_connective)',
    'cloze_a1_0720': 'C3-T5 tier B (2026-09-16): Batch 30 discourse-connective open frame, bare dictionary-verb/particle distractors (see manifest posRules.adverbs_connective)',
    # a1_0731: 그래/아 interjection response frame, bare dictionary-verb
    # distractors replacing only the interjection token (posRules.
    # numerals_interjections), verified by test_batch_30_draft.py's
    # test_tierb_interjection_distractors_are_bare_dictionary_verb.
    'cloze_a1_0731': 'C3-T5 tier B (2026-09-16): Batch 30 interjection response frame, bare dictionary-verb distractor (see manifest posRules.numerals_interjections)',
    # a1_0733/0740/0742 (D3) and a1_0734/0741 (D2): pronoun-fold rows
    # (그것/무엇/저것/어디/언제 fold-type headwords) whose distractors are a
    # pronoun of a DIFFERENT deictic class + the same particle -- an
    # intentional category-violation/particle-form 비문 per posRules.
    # pronouns, not a same-POS/same-form re-pick D2/D3 can recognize.
    # Verified by test_batch_30_draft.py's
    # test_remaining_rows_carry_a_particle_fold_consistent_with_their_own_final_sound.
    'cloze_a1_0733': 'C3-T5 tier B (2026-09-16): Batch 30 pronoun-fold category-mismatch distractor (see manifest posRules.pronouns)',
    'cloze_a1_0734': 'C3-T5 tier B (2026-09-16): Batch 30 pronoun-fold category-mismatch distractor (see manifest posRules.pronouns)',
    'cloze_a1_0740': 'C3-T5 tier B (2026-09-16): Batch 30 pronoun-fold category-mismatch distractor (see manifest posRules.pronouns)',
    'cloze_a1_0741': 'C3-T5 tier B (2026-09-16): Batch 30 pronoun-fold category-mismatch distractor (see manifest posRules.pronouns)',
    'cloze_a1_0742': 'C3-T5 tier B (2026-09-16): Batch 30 pronoun-fold category-mismatch distractor (see manifest posRules.pronouns)',
}

# R8-2 "mixed composition" items (Fable ruling 2026-09-15): 2 Tier-A
# (same-ending, semantically-clashing) distractors + 1 OPEN_SLOT_WAIVER
# word, used only when the read found exactly two safe clashing
# candidates. See `check_d3_pos_form`'s MIXED_TIER_IDS branch.
MIXED_TIER_IDS: dict[str, str] = {
    'cloze_a1_0188': 'R8-2 mixed composition (2026-09-15): thin same-ending pool; filled with >=1 OPEN_SLOT_WAIVER word alongside the Tier-A same-ending candidate(s)',
    'cloze_a1_0251': 'R8-2 mixed composition (2026-09-15): thin same-ending pool; filled with >=1 OPEN_SLOT_WAIVER word alongside the Tier-A same-ending candidate(s)',
    'cloze_a1_0275': 'R8-2 mixed composition (2026-09-15): thin same-ending pool; filled with >=1 OPEN_SLOT_WAIVER word alongside the Tier-A same-ending candidate(s)',
    'cloze_a1_0276': 'R8-2 mixed composition (2026-09-15): thin same-ending pool; filled with >=1 OPEN_SLOT_WAIVER word alongside the Tier-A same-ending candidate(s)',
    'cloze_a1_0314': 'R8-2 mixed composition (2026-09-15): thin same-ending pool; filled with >=1 OPEN_SLOT_WAIVER word alongside the Tier-A same-ending candidate(s)',
    'cloze_a1_0443': 'R8-2 mixed composition (2026-09-15): thin same-ending pool; filled with >=1 OPEN_SLOT_WAIVER word alongside the Tier-A same-ending candidate(s)',
}


def open_slot_distractor_ok(word: str, cloze_id: Optional[str] = None) -> bool:
    """Same acceptance test as `waived_distractor_ok` -- a bare
    dictionary-form verb/adjective or a bare particle, which cannot itself
    complete the slot as a valid noun or predicate. Kept as a distinct
    name (rather than just calling `waived_distractor_ok` at call sites)
    so OPEN_SLOT_WAIVER reads as its own rule in audit output, even though
    the underlying technique -- and its safety guarantee -- is identical."""
    return waived_distractor_ok(word, cloze_id)


# ---------------------------------------------------------------------------
# D4 -- N+하다 / 배우다 / 잘하다 activity-noun slots
# ---------------------------------------------------------------------------

# Curated in Batch 28's mechanical ACTIVITY_NOUN_SET rule (draft branch
# claude/c3-batch28-a1-20260915, tools/content_factory/test_batch_28_draft.py,
# commit b0670d2d "content(c3): Batch 28 R6/R8 fix -- mechanical
# ACTIVITY_NOUN_SET rule"). That batch is not yet live/merged, but the
# curated list itself is content-independent of promotion status -- these
# words function as N+하다 활동명사 regardless of which batch first named
# them.
ACTIVITY_NOUN_SET = frozenset({
    "샤워", "세수", "청소", "준비", "요리", "식사", "운전", "사용", "부탁",
    "초대", "운동", "아르바이트", "쇼핑", "태권도", "파티", "졸업", "방학",
    "의사", "영화배우", "종업원", "직원", "콘서트", "연극", "외국어",
    "이야기", "안내", "시작", "생활", "선물", "음식",
})

ACTIVITY_SLOT_VERBS = ("하다", "해요", "했어요", "배우다", "배워요", "배웠어요", "잘하다", "잘해요")
_D4_PARTICLES = ("을", "를", "이", "가", "은", "는")


def is_activity_slot(sentence_ko: str) -> bool:
    """True if the blank is DIRECTLY followed (optionally through a single
    particle) by a form of 하다/배우다/잘하다 -- i.e. the blank is the N in
    an N+하다/배우다/잘하다 frame. Anchored at the blank on purpose: a
    substring check anywhere in the sentence would false-positive on any
    unrelated -하다-derived verb later in the sentence (친절했어요,
    필요해요, 좋아해요, 성공했어요, ...), which share the "해요"/"했어요"
    tail with the genuine N+하다 frame this rule targets but aren't one."""
    idx = sentence_ko.find(BLANK)
    if idx < 0:
        return False
    rest = sentence_ko[idx + len(BLANK):].lstrip()
    for p in _D4_PARTICLES:
        if rest.startswith(p):
            rest = rest[len(p):].lstrip()
            break
    return any(rest.startswith(v) for v in ACTIVITY_SLOT_VERBS)


def check_d4_activity_noun(
    sentence_ko: str, distractors: Iterable[str], vocab: VocabIndex
) -> list[str]:
    """Distractors that are activity nouns, in an N+하다/배우다/잘하다 slot.
    Empty (no check) when the sentence isn't such a slot."""
    if not is_activity_slot(sentence_ko):
        return []
    activity_nouns = ACTIVITY_NOUN_SET | vocab.hada_activity_nouns
    return [d for d in distractors if d in activity_nouns]


# ---------------------------------------------------------------------------
# D5 -- open noun slot detection (existential / adjective predicate /
# 좋아해요 objects). Detection only -- the incompatibility judgement is a
# human/LLM read, not a mechanical check.
# ---------------------------------------------------------------------------

OPEN_SLOT_PREDICATES = (
    "있어요", "없어요", "예뻐요", "좋아요", "커요", "맛있어요", "재미있어요", "좋아해요",
)


def is_open_noun_slot(sentence_ko: str, answer: str) -> bool:
    """True when the sentence ENDS in one of the open-slot predicates (Korean
    is SOV -- these predicates are sentence-final) and the blank itself is
    a *different* slot (the predicate isn't the answer being blanked --
    i.e. this is a noun slot elsewhere in the sentence, not the predicate-
    slot-waiver case). Anchored at the sentence end rather than "appears
    anywhere" to avoid flagging unrelated sentences that merely mention one
    of these words mid-clause."""
    tail = sentence_ko.rstrip(" .!?…\"'")
    return any(tail.endswith(p) and answer != p for p in OPEN_SLOT_PREDICATES)


# ---------------------------------------------------------------------------
# D6 -- no distractor in the sentence remainder; no duplicates; reuse caps
# ---------------------------------------------------------------------------


def sentence_remainder(sentence_ko: str) -> str:
    return sentence_ko.replace(BLANK, "")


def check_d6_exposure_and_dupes(
    sentence_ko: str, answer: str, distractors: list[str]
) -> dict:
    """Returns {"exposed": [...], "duplicates": bool, "equals_answer": [...]}."""
    remainder = sentence_remainder(sentence_ko)
    exposed = [d for d in distractors if d and d in remainder]
    equals_answer = [d for d in distractors if d == answer]
    duplicates = len(set(distractors)) != len(distractors)
    return {"exposed": exposed, "duplicates": duplicates, "equals_answer": equals_answer}


class ReuseTracker:
    """D6 reuse cap: a distractor word may be reused at most 4x within an
    identifiable pack/batch, else 6x per level. cloze.json items carry no
    pack/batch id, only `level` and `topic` -- there is no reliable batch
    grouping at the item level, so this tracks per-level reuse (the
    documented "else" branch) and reports per-(level, word) counts for the
    audit; the fixer treats a word at its cap as unavailable for further
    reuse in that level."""

    LIMIT_PER_LEVEL = 6

    def __init__(self):
        self.counts: dict[tuple[str, str], int] = defaultdict(int)

    def record(self, level: str, distractors: Iterable[str]) -> None:
        lv = (level or "").strip().lower()
        for d in distractors:
            self.counts[(lv, d)] += 1

    def over_cap(self, level: str) -> set[str]:
        lv = (level or "").strip().lower()
        return {w for (l, w), n in self.counts.items() if l == lv and n > self.LIMIT_PER_LEVEL}

    def count(self, level: str, word: str) -> int:
        return self.counts.get(((level or "").strip().lower(), word), 0)
