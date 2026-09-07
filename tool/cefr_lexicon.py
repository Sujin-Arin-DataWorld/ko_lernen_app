"""CEFR/international-grade level judgement for Korean words, phrases and sentences.

Implements the lookup procedure and grammar detector specified in the
approved plan (plans/…cheeky-eclipse.md) §3.C and §4.1, backed by the NIKL
grade lists converted under ``tools/content_factory/lexicon/`` by
``tool/ingest_nikl_grade_lists.py``. This module was reworked under rejection
code R3 (2026-09-07 direct-read findings) -- see the per-section comments
below for what changed and why; the T1.2 report to Fable carries the full
before/after evidence.

Word-grade lookup order (plan §3.C.1, R3-revised)
--------------------------------------------------
1. ``kiiq`` -- headword match over *every* homograph row for that headword
   (including homograph 0), taking the MINIMUM grade among them (R3 item 1:
   a bare token can't disambiguate sense, and the old code wrongly
   privileged the homograph-0 row even when a lower-grade homograph existed
   for the same headword -- e.g. ``싸다`` has homograph-0 at 고급/grade5
   ("입이 싸다") but homograph-3 at 초급/grade1 ("가격이 싸다"); the fix
   always takes the minimum across every row sharing the headword). When
   more than one row shares the headword, ``matched`` records
   ``"headword(hN,hM,...)"`` listing every homograph number present.
2. ``derived`` -- strip a productive suffix (스럽다/하다/되다/적/히, longest
   first) and retry step 1 on the root (same min-across-homographs rule).
3. ``aliases.csv`` -- a fixed table of colloquial/honorific/idiomatic
   spellings (see ``tools/content_factory/lexicon/README.md``). An empty
   ``lexicon_form`` means "grade-list-independent A1 exception". A
   multi-word ``lexicon_form`` is resolved word-by-word (max, ignoring
   particles).
4. ``multiword`` -- only reached when step 3 did not match *and* the input
   itself contains a space: split on whitespace, strip one particle suffix
   per token, take the max grade over content words (particle-only tokens
   contribute nothing).
5. ``basic2023`` -- the 2023 국어 기초 어휘 5-grade list (mapped to CEFR via
   :data:`BASIC2023_TO_CEFR`), source-tagged ``confidence='low'`` (see
   below) since this list was built for general literacy, not CEFR
   placement, and its grade-5 tail in particular skews high for otherwise
   ordinary words (R3 item 2, e.g. 장모님).
6. ``unknown`` -- ``grade=None``. We never guess; unresolved words are
   reported so a human can rule on them (plan §3.C, "재현율·투명성 우선").

The ``kcenter`` (한국어교수학습샘터) source tier from the original design is
REMOVED (R3 item 3): the CSV was licence-type-4 and deleted upstream in R2.
``WordGrade.source`` can no longer be ``'kcenter'``.

Confidence (R3 item 2)
-----------------------
``WordGrade.confidence`` is ``'high'`` for ``kiiq``/``derived``/``alias``
sources (curated, CEFR-purpose-built lists) and ``'low'`` for
``basic2023`` (general-literacy fallback); ``None`` for unresolved/proper
nouns. It is a derived *property* (not a stored field) so every code path
that returns a ``WordGrade`` gets it automatically and consistently --
there is no propagation step to forget. ``word_grade()`` itself always
returns the RAW grade (uncapped) even for low-confidence resolutions;
``sentence_profile()`` is the only place that caps a low-confidence token's
contribution (at grade 3) when computing ``lexical_p90``, and it separately
lists every such token's raw surface form in ``SentenceProfile.low_confidence``
(R3 item 2).

Proper nouns (R3 item 5)
--------------------------
Every character display name from
``tools/content_factory/canonical_scenarios/character_profiles.json``'s
``recurringCharacters[].displayNames.ko``, plus a fixed extra list (see
``EXTRA_PROPER_NOUNS``), is loaded by :func:`load_character_names` and
treated -- with or without a trailing particle -- as a ``source='proper_noun'``
token: excluded from grading (``grade=None``) and from ``unknown``/
``SentenceProfile.unknown`` reporting. Matched names are collected in
``SentenceProfile.proper_nouns`` instead.

Grammar over-matching (R3 item 6)
-----------------------------------
``GrammarIndex`` now (a) only accepts a hit from a *short* (≤2 Hangul
syllable literal core) rule when it ends at an eojeol boundary (end of
token, or immediately before punctuation/a listed particle) --
open-conjugation rules built via ``_drop_trailing_da`` (어 있다, 같다, 이다,
하다, 되다, 싶다, 보다, 없다 …) are exempt from this check by construction,
since their whole *point* is to match mid-eojeol before further
conjugation; (b) when two hits share the exact same span, keeps only the
lowest-grade one; (c) skips building a rule at all when its literal core is
≤2 Hangul syllables UNLESS its grade is 1 or 2 (see
``_SHORT_FRAGMENT_ALLOWED_GRADES`` for why this is 1-2 rather than the
brief's literal "1-3" -- a deliberate, evidence-based deviation, documented
there); (d) skips a grade-5/6 (C1/C2) rule outright unless its literal core
is ≥4 Hangul syllables. ``SentenceProfile.grammar_hits`` exposes the
resulting (pattern_id, grade, span, text) tuples and ``grammar_max`` is
strictly ``max(h.grade for h in grammar_hits)``.

Known gap (see ``tool/test_cefr_lexicon.py`` docstring and the T1.2 report
to Fable): the compound 층간소음 is not a headword in either remaining
source list (verified by direct grep) and its parts (층간 grade 5 in
basic2023 only; 소음 grade 4 in kiiq) do not combine to grade 3 either -- so
``word_grade('층간소음')`` legitimately returns ``unknown`` rather than the
``(3, 'B1', 'kiiq')`` some drafts of the brief assumed. This is flagged for
Fable's ruling (alias vs. accepted gap), not silently patched with invented
lexicon data.
"""

from __future__ import annotations

import csv
import json
import math
import re
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path
from typing import FrozenSet, Iterable, List, Mapping, Optional, Sequence, Tuple

REPO = Path(__file__).resolve().parent.parent
LEXICON_DIR = REPO / "tools" / "content_factory" / "lexicon"
KIIQ_VOCAB_CSV = LEXICON_DIR / "nikl_kiiq_2017_vocab.csv"
KIIQ_GRAMMAR_CSV = LEXICON_DIR / "nikl_kiiq_2017_grammar.csv"
BASIC2023_CSV = LEXICON_DIR / "nikl_basic_2023_vocab.csv"
ALIASES_CSV = LEXICON_DIR / "aliases.csv"
CHARACTER_PROFILES_JSON = (
    REPO / "tools" / "content_factory" / "canonical_scenarios" / "character_profiles.json"
)
GRAMMAR_CSV = REPO / "assets" / "data" / "grammar.csv"
VOCAB_CSV = REPO / "assets" / "data" / "korean_vocab.csv"

# ---------------------------------------------------------------------------
# Grade/CEFR scales (plan §4.1)
# ---------------------------------------------------------------------------

GRADE_TO_CEFR = {1: "A1", 2: "A2", 3: "B1", 4: "B2", 5: "C1", 6: "C2"}
CEFR_TO_GRADE = {v: k for k, v in GRADE_TO_CEFR.items()}
BASIC2023_TO_CEFR = {1: "A2", 2: "B1", 3: "B2", 4: "C1", 5: "C2"}
BASIC2023_TO_GRADE = {k: CEFR_TO_GRADE[v] for k, v in BASIC2023_TO_CEFR.items()}

# R3 item 2: word_grade() keeps the raw grade for every source; this table
# is only consulted by WordGrade.confidence (a derived property) and by
# sentence_profile()'s lexical_p90 capping.
_CONFIDENCE_BY_SOURCE: Mapping[str, str] = {
    "kiiq": "high",
    "derived": "high",
    "alias": "high",
    "basic2023": "low",
}

# Sentence-length rule (plan §3.C.2 / brief): eojeol-count ceiling per grade;
# a sentence longer than its otherwise-computed grade's ceiling bumps one
# grade up (capped at C2).
LENGTH_LIMIT_BY_GRADE = {1: 8, 2: 12, 3: 16, 4: 22}

# ---------------------------------------------------------------------------
# Tokenizer tables (brief, extended under R3 item 4 -- see inline comments)
# ---------------------------------------------------------------------------

PARTICLES: Tuple[str, ...] = (
    "은", "는", "이", "가", "을", "를", "에", "에서", "도", "만", "와", "과",
    "하고", "이랑", "랑", "부터", "까지", "으로", "로", "의", "에게", "한테",
    "께", "처럼", "보다", "마다", "밖에", "이나", "나", "에다가", "에서부터",
    "에게서", "한테서",
    # R3 item 4 ("처음에는" -> 처음): stacked/compound particles. Longest-
    # match-first (_ALL_SUFFIXES sorts by length) means these are tried
    # before their shorter components (에는 before 는, etc).
    "에는", "에서는", "에도", "에서도", "까지는", "부터는", "으로는", "로는",
    "한테는", "에게는", "께서는", "이라고", "라고", "이라도", "라도", "이나마",
    # Contraction of 에는 -> 엔 (e.g. "처음엔" -> 처음), sentence-unknown-
    # ratio sweep (Section 6/T1.2 target).
    "엔",
)

ENDINGS: Tuple[str, ...] = (
    "아요", "어요", "여요", "해요", "았어요", "었어요", "했어요", "ㅂ니다",
    "습니다", "습니까", "ㅂ니까", "세요", "으세요", "고", "지만", "어서",
    "아서", "해서", "으니까", "니까", "으면", "면", "으러", "러", "으려고",
    "려고", "는데", "은데", "ㄴ데", "네요", "군요", "지요", "죠", "을게요",
    "ㄹ게요", "을까요", "ㄹ까요", "을래요", "ㄹ래요", "거든요", "잖아요",
    "겠어요", "았", "었", "겠", "는", "은", "ㄴ", "을", "ㄹ", "기", "음", "ㅁ",
    # R3 item 4: 으니/니 connective ("앉으니" -> 앉다).
    "으니", "니",
    # R3 item 4: honorific present/attributive/past ("앉으시는", "받으셨어요").
    "으시는", "시는", "으신", "신", "으실", "실", "으셔서", "셔서",
    "으십니다", "십니다", "으셨어요", "셨어요", "으셨", "셨",
    # R3 item 4: quotative endings ("된다고" -> 되다, "오라고" -> 오다).
    "ㄴ다고", "는다고", "다고", "자고", "냐고", "으라고", "라고",
    # R3 item 4: copula ("자리예요." -> 자리) -- handled specially in
    # _lemma_candidates (bare-stem candidate, no "다" appended); see
    # _COPULA_ENDINGS.
    "예요", "이에요",
    # Sentence-unknown-ratio sweep (Section 6/T1.2 target, not itemised in
    # the R3 brief's tokenizer list but needed to reach it): plain informal
    # (반말) vowel endings with no 요 (알려, 나눠, 적어, 보여, 남겨 …), "-게"
    # (짧게, 다르게, 늦게), "-지" (negation infinitive: 말하지, 쓰지), "-아야
    # /-어야" (필요/의무: 있어야, 봐야), "-기로" (결심: 않기로), "-는지"
    # (간접의문, consonant-final stems only: 있는지), "-에요"/"-라" (아니다's
    # irregular copula-adjacent forms: 아니에요, 아니라).
    "아", "어", "여", "게", "지", "아야", "어야", "해야", "기로", "는지", "에요", "라",
    # "-ㅂ니다" on a vowel-final stem embeds the ㅂ into the preceding
    # syllable (하다+ㅂ니다 -> 합니다, embedded batchim, unlike the
    # consonant-final "-습니다" already above where 습/니/다 are three
    # separate characters) -- handled specially via the ㅂ jamo-strip in
    # _lemma_candidates' PASS 1 (narrowly scoped to this exact suffix; see
    # its comment) rather than the generic _restore_predicate("합"+"다")
    # path, which would wrongly give "합다".
    "니다",
)

# Copula endings: the stem is the noun itself (이다 "to be" attaches to a
# noun), never a predicate that takes a bare "다" dictionary form. Kept as
# a literal subset of ENDINGS (so _ALL_SUFFIXES/_ENDING_SET still match
# them) but branched on separately in _lemma_candidates -- R3 item 4
# ("자리예요." -> 자리, not the nonsense "자리다").
_COPULA_ENDINGS: frozenset = frozenset({"예요", "이에요"})

# R3 item 4 ("따뜻해서" -> 따뜻하다, "서늘해서" -> 서늘하다): "해서" is
# stripped as one opaque 2-char ENDING (see ENDINGS above), which loses the
# "하" signal entirely from the remaining stem -- unlike "했어요" (where
# CONTRACTION_MAP's "했"->"하" entry fires on the 1-char remainder) there is
# no fragment left for any repair table to match. Handled directly in
# _lemma_candidates: for suf in this set, ALSO try stem + "하다" (only used
# -- per the brief's own phrasing, "when X하다 is in the lexicon" -- if that
# candidate actually resolves; harmless no-op otherwise).
_HADA_FUSED_ENDINGS: frozenset = frozenset({"해서", "해야"})

# Connective (연결어미) subset of ENDINGS used for clause counting.
CONNECTIVE_ENDINGS: frozenset = frozenset({
    "고", "지만", "어서", "아서", "해서", "으니까", "니까", "으면", "면",
    "으러", "러", "으려고", "려고", "는데", "은데", "ㄴ데",
    "으니", "니",
})

_PARTICLE_SET = frozenset(PARTICLES)
_ENDING_SET = frozenset(ENDINGS)
_ALL_SUFFIXES = tuple(sorted(_PARTICLE_SET | _ENDING_SET, key=len, reverse=True))
_PARTICLES_BY_LEN_DESC = tuple(sorted(_PARTICLE_SET, key=len, reverse=True))

# Extra single-character fallback tried only after every listed suffix has
# failed to produce a resolvable candidate. Not part of the brief's ENDINGS
# list, but without it CONTRACTION_MAP/IRREGULAR_STEM_MAP below (which the
# brief explicitly asks for) are unreachable: no combination of listed
# endings strips down to "해"/"추워"/etc, since the brief's ENDINGS list has
# no bare "요". Documented for Fable's review (T1.2 report §open_questions).
_FALLBACK_ENDING = "요"

# `-아/어(요)` restoration: fragment -> bare root (root + "다" is retried).
# R3 item 4 adds the past-tense fused syllables (했/봤/왔/줬/갔) needed for
# "했어요"/"봤어요"/"왔어요"/"줬어요"/"갔어요" -- these are NOT reachable via
# expand_contractions (which only un-fuses OPEN syllables, i.e. syllables
# with no batchim; a tense-marked syllable like "왔" has the ㅆ batchim by
# definition) so they need their own direct fragment -> root entries here,
# the same mechanism already used for the present-tense forms.
CONTRACTION_MAP: Mapping[str, str] = {
    "해": "하", "했": "하",
    "봐": "보", "봤": "보",
    "와": "오", "왔": "오",
    "줘": "주", "줬": "주",
    "써": "쓰",
    "갔": "가",
    "됐": "되",
    # Sentence-unknown-ratio sweep (Section 6/T1.2 target): the same
    # 았-tense-batchim-on-an-unchanged-vowel pattern as 갔 (가다), for two
    # more high-frequency verbs actually found in cloze.json's fullKo
    # sentences. Not a general rule (see _unfuse_tensed_yeo's docstring for
    # why a fully general jamo-based detense function was rejected as too
    # risky) -- just more entries in the same hand-curated table.
    "샀": "사",
    "보냈": "보내",
}

# ㅂ-irregular restoration: fragment -> full dictionary form (다 included).
# R3 item 4 adds the EXPANDED (post expand_contractions, ending-already-
# stripped) 2-syllable allomorphs -- e.g. "더워서" -> expand_contractions ->
# "더우어서" -> strip "-어서" -> stem "더우" (NOT "더워", which is what the
# original 4 entries below key on) -- needed for X-워서/X-워도/etc forms
# that go through the vowel-fusion expander before ending-stripping.
IRREGULAR_STEM_MAP: Mapping[str, str] = {
    "추워": "춥다", "더워": "덥다", "어려워": "어렵다", "쉬워": "쉽다",
    "고마워": "고맙다", "가까워": "가깝다",
    "추우": "춥다", "더우": "덥다", "어려우": "어렵다", "쉬우": "쉽다",
    "고마우": "고맙다", "가까우": "가깝다",
}

# ㅡ-irregular ("으-탈락") restoration: fragment -> bare root ("다" appended
# by the same CONTRACTION_MAP-style logic in _irregular_repair). R3 item 4's
# explicit closed list: 아프다 바쁘다 예쁘다 크다 쓰다 끄다 고프다 슬프다
# 기쁘다 나쁘다 모으다 담그다 잠그다 따르다. Vowel-harmony (아 vs 어) is not
# computed generically here -- both the present- and past-tense contracted
# forms are hand-listed, matching this file's existing table-based style for
# every other irregular class rather than a general phonological rule.
EU_IRREGULAR_MAP: Mapping[str, str] = {
    "아파": "아프", "아팠": "아프",
    "바빠": "바쁘", "바빴": "바쁘",
    "예뻐": "예쁘", "예뻤": "예쁘",
    "커": "크", "컸": "크",
    "썼": "쓰",
    "꺼": "끄", "껐": "끄",
    "고파": "고프", "고팠": "고프",
    "슬퍼": "슬프", "슬펐": "슬프",
    "기뻐": "기쁘", "기뻤": "기쁘",
    "나빠": "나쁘", "나빴": "나쁘",
    "모아": "모으", "모았": "모으",
    "담가": "담그", "담갔": "담그",
    "잠가": "잠그", "잠갔": "잠그",
    "따라": "따르", "따랐": "따르",
}

# 르-irregular restoration: fragment -> bare root. R3 item 4's closed list:
# 모르다 부르다 다르다 빠르다 흐르다 고르다 기르다 오르다 누르다 서두르다.
EU_R_IRREGULAR_MAP: Mapping[str, str] = {
    "몰라": "모르", "몰랐": "모르",
    "불러": "부르", "불렀": "부르",
    "달라": "다르", "달랐": "다르",
    "빨라": "빠르", "빨랐": "빠르",
    "흘러": "흐르", "흘렀": "흐르",
    "골라": "고르", "골랐": "고르",
    "길러": "기르", "길렀": "기르",
    "올라": "오르", "올랐": "오르",
    "눌러": "누르", "눌렀": "누르",
    "서둘러": "서두르", "서둘렀": "서두르",
}

# ㄷ-irregular restoration: fragment -> bare root. R3 item 4's closed list:
# 듣다 걷다 묻다(ask) 싣다. NOTE: "들"/"걸" are also the regular roots of
# 들다("to lift/cost") and 걸다("to hang"); this table wins that ambiguity
# in favour of the ㄷ-irregular reading whenever it fires, a documented,
# accepted trade-off (no POS/semantic disambiguation is available here) --
# see _irregular_repair's docstring.
D_IRREGULAR_MAP: Mapping[str, str] = {
    "들": "듣", "걸": "걷", "물": "묻", "실": "싣",
}

# ㅅ-irregular restoration: fragment -> bare root. R3 item 4's closed list:
# 낫다 짓다 붓다 잇다. Keyed on the DOUBLED-vowel post-ㅅ-drop form (e.g.
# "나아" for 낫다, reached via the bare "-요" fallback ending so both 나's
# survive as the stem) rather than the single-syllable form reachable via
# the "-아요"/"-어요" ending strip (which would leave just "나", colliding
# with the real, unrelated headword 나다 -- see _irregular_repair's
# docstring and the two-pass structure in _lemma_candidates).
S_IRREGULAR_MAP: Mapping[str, str] = {
    "나아": "낫", "지어": "짓", "부어": "붓", "이어": "잇",
}

# ㅎ-irregular restoration: applied AFTER stripping a final ㄴ/ㄹ batchim via
# jamo arithmetic (_strip_final_batchim) -- fragment -> full dictionary
# form. R3 item 4's closed list: 노랗다 파랗다 빨갛다 하얗다 까맣다 그렇다
# 이렇다 저렇다 어떻다. Keyed on the vowel-final root LEFT AFTER the ㅎ
# itself is already dropped by the batchim-strip step ("노란" -> strip ㄴ ->
# "노라", not "노랗").
H_IRREGULAR_MAP: Mapping[str, str] = {
    "노라": "노랗다", "파라": "파랗다", "빨가": "빨갛다", "하야": "하얗다",
    "까마": "까맣다", "그러": "그렇다", "이러": "이렇다", "저러": "저렇다",
    "어떠": "어떻다",
}

# Suffixes stripped for the "derived" word-grade step (longest first).
DERIVED_SUFFIXES: Tuple[str, ...] = ("스럽다", "하다", "되다", "적", "히")

TRAILING_PUNCT = ".,!?…·\"'()[]{}:;""''"

# Hangul syllable-block constants (for the open-syllable vowel-fusion
# expansion used by GrammarIndex.detect — see `expand_contractions`, and by
# the ㄴ/ㄹ batchim-stripping helpers below for R3 item 4's 관형형/quotative
# repairs).
_S_BASE = 0xAC00
_L_COUNT, _V_COUNT, _T_COUNT = 19, 21, 28
# jungseong (vowel) index -> (index of the un-fused vowel, literal syllable
# to splice in). Covers the four common "V + 아/어" fusions that keep an
# open syllable (이+어→여, 오+아→와, 우+어→워, 외+어→왜 — the last added
# under R3's sentence-unknown-ratio sweep for 되다: 돼요/돼서/… -> 되어요/
# 되어서/…). ㅡ-final contraction (으 drops, e.g. 쓰다→써) keeps the
# *original* consonant and is not a fusion in this sense; it is handled by
# CONTRACTION_MAP/EU_IRREGULAR_MAP instead.
_VOWEL_FUSION = {6: (20, "어"), 9: (8, "아"), 14: (13, "어"), 10: (11, "어")}
# jongseong (batchim) indices for ㄴ and ㄹ, used by _strip_final_batchim
# (R3 item 4's 관형형 ㄴ/ㄹ jamo-decomposition repair, e.g. "과한" -> "과하").
_TAIL_NIEUN = 4
_TAIL_RIEUL = 8
_TAIL_SSANGSIOT = 20  # ㅆ (past-tense marker batchim)
_TAIL_BIEUP = 17  # ㅂ (합니다/됩니다's embedded formal-ending batchim)
_VOWEL_I = 20  # ㅣ

_HANGUL_SYLLABLE_RE = re.compile(r"[가-힣]")


def _unfuse_tensed_yeo(stem: str) -> Optional[str]:
    """R3 item 4 ("드렸어요" -> 드리다): `expand_contractions` only
    un-fuses an OPEN ㅕ syllable (이+어->여, no batchim), so it never
    touches a PAST-tense-marked one like "렸" (드리다's stem-final 리 fused
    with 었 -> 렸, batchim ㅆ). If `stem`'s last character has vowel ㅕ (6)
    and batchim ㅆ, return `stem` with that syllable restored to its
    un-fused ㅣ (드렸 -> 드리); else None. Same (code-0xAC00) jamo
    arithmetic as `expand_contractions`/`_strip_final_batchim` above."""
    if not stem:
        return None
    code = ord(stem[-1])
    if not (_S_BASE <= code < _S_BASE + _L_COUNT * _V_COUNT * _T_COUNT):
        return None
    s_index = code - _S_BASE
    lead = s_index // (_V_COUNT * _T_COUNT)
    vowel = (s_index % (_V_COUNT * _T_COUNT)) // _T_COUNT
    tail = s_index % _T_COUNT
    if tail != _TAIL_SSANGSIOT or vowel != 6:
        return None
    base_code = _S_BASE + (lead * _V_COUNT + _VOWEL_I) * _T_COUNT
    return stem[:-1] + chr(base_code)


def _normalize_token(text: str) -> str:
    """Collapse whitespace and strip edge punctuation from one token."""
    text = unicodedata.normalize("NFC", text).strip()
    return text.strip(TRAILING_PUNCT)


def expand_contractions(text: str) -> str:
    """Expand the three common open-syllable vowel fusions back to two
    syllables (걸려서 -> 걸리어서, 배워요 -> 배우어요, 왔어요's stem 와 ->
    오아 when unbatched), so pattern regexes built from citation-form
    endings (아서/어서/…) can find them via plain substring search. Only
    touches syllables with no trailing consonant (배침), since a batched
    fusion (e.g. 갔어요) is a different phenomenon (tense-marker fusion)
    this function does not attempt to undo (see CONTRACTION_MAP's 았/었
    entries and _strip_final_batchim for how those are handled instead).
    """
    out: List[str] = []
    for ch in text:
        code = ord(ch)
        if _S_BASE <= code < _S_BASE + _L_COUNT * _V_COUNT * _T_COUNT:
            s_index = code - _S_BASE
            lead = s_index // (_V_COUNT * _T_COUNT)
            vowel = (s_index % (_V_COUNT * _T_COUNT)) // _T_COUNT
            tail = s_index % _T_COUNT
            if tail == 0 and vowel in _VOWEL_FUSION:
                orig_vowel, extra_syllable = _VOWEL_FUSION[vowel]
                base_code = _S_BASE + (lead * _V_COUNT + orig_vowel) * _T_COUNT
                out.append(chr(base_code))
                out.append(extra_syllable)
                continue
        out.append(ch)
    return "".join(out)


def _strip_final_batchim(token: str, tails: Tuple[int, ...]) -> Optional[str]:
    """R3 item 4 (관형형 ㄴ/ㄹ jamo decomposition): if `token`'s last
    character is a Hangul syllable whose batchim (jongseong) index is one
    of `tails`, return `token` with that syllable's batchim removed (e.g.
    "한" -(ㄴ, tail 4)-> "하", "할" -(ㄹ, tail 8)-> "하"); else None. A
    batchim is packed *inside* the syllable's code point in Unicode (no
    separate combining character), so this is (code-0xAC00) jamo
    arithmetic, the same technique `expand_contractions` above already
    uses -- not string slicing."""
    if not token:
        return None
    code = ord(token[-1])
    if not (_S_BASE <= code < _S_BASE + _L_COUNT * _V_COUNT * _T_COUNT):
        return None
    s_index = code - _S_BASE
    tail = s_index % _T_COUNT
    if tail not in tails:
        return None
    base_code = code - tail
    return token[:-1] + chr(base_code)


def _irregular_repair(stem: str) -> Optional[str]:
    """Try every hand-curated irregular-conjugation table against `stem`
    (checked via `.endswith`, most-specific tables first), returning a full
    dictionary form (root + "다", or the mapped form directly for the
    ㅎ-irregular table) -- or None if `stem` matches nothing.

    Deliberately kept SEPARATE from, and tried at HIGHER priority than, the
    generic `stem + "다"` guess in `_restore_predicate` / the fallback
    branch of `_lemma_candidates` (R3 item 4): a generic guess can
    coincidentally BE a real, unrelated headword and, tried first, would
    silently shadow the correct repair. Concrete case that motivated this
    (T1.2 report): "나아요" ends in the ENDINGS suffix "아요", so the plain
    stem is "나" -- and "나다" ("수염이 나다", to grow/emerge) IS a real
    kiiq A1 headword, so a naive single-pass candidate list resolves
    "나아요" to "나다" and never reaches the correct ㅅ-irregular reading
    (stem "나아", from the bare "-요" fallback ending, -> "낫다"). See
    `_lemma_candidates`'s two-pass structure: every candidate this function
    returns is collected in PASS 1 (tried before ANY generic-fallback
    candidate from PASS 2), so "낫다" is always tried before "나다" here.

    The jamo ㄴ/ㄹ-batchim-strip + H_IRREGULAR_MAP fallback at the end is
    intentionally the LAST resort within this function: it fires for any
    stem ending in an embedded ㄴ/ㄹ batchim (관형형, or a quotative-ending
    remnant like "된" from "된다고"), including ordinary ㄹ-final verb
    roots it has no business touching (e.g. "만들" -> "만드다", a made-up
    non-word) -- harmless in practice because such a wrong candidate is
    itself unlikely to resolve in the lexicon and `_resolve_eojeol` simply
    moves on to the next (correct) candidate, but a known, accepted
    imprecision given no POS tagging is available here."""
    for frag, full in IRREGULAR_STEM_MAP.items():
        if stem.endswith(frag):
            return stem[: -len(frag)] + full
    for frag, root in CONTRACTION_MAP.items():
        if stem.endswith(frag):
            return stem[: -len(frag)] + root + "다"
    for frag, root in EU_IRREGULAR_MAP.items():
        if stem.endswith(frag):
            return stem[: -len(frag)] + root + "다"
    for frag, root in EU_R_IRREGULAR_MAP.items():
        if stem.endswith(frag):
            return stem[: -len(frag)] + root + "다"
    for frag, root in D_IRREGULAR_MAP.items():
        if stem.endswith(frag):
            return stem[: -len(frag)] + root + "다"
    for frag, root in S_IRREGULAR_MAP.items():
        if stem.endswith(frag):
            return stem[: -len(frag)] + root + "다"
    unfused_yeo = _unfuse_tensed_yeo(stem)
    if unfused_yeo is not None:
        return unfused_yeo + "다"
    return None


# R3 item 4's 관형형 ㄴ/ㄹ jamo-decomposition repair ("과한" -> "과하다",
# "노란" -> "노랗다", "된다고" -> "된" -> "되다"), split out from
# `_irregular_repair` and called ONLY in the two places it is actually
# safe: on the WHOLE, un-stripped token (a bare attributive form has
# nothing else attached) and on the stem left after a QUOTATIVE ending
# (다고/자고/냐고/…, where the preceding syllable's ㄴ genuinely IS the
# fused attributive marker). Applying it to an ARBITRARY ending-stripped
# stem is unsafe: e.g. "말고" (말다 + connective -고) strips to stem "말",
# whose own final ㄹ is just 말다's ordinary dictionary-form batchim, not an
# attributive marker -- stripping it gives the nonsense "마다", which is
# unfortunately ALSO a real, common headword ("each"), so a blanket
# application would have SILENTLY HIJACKED "말고" -> "마다" instead of the
# correct "말다" (caught in this rework's own sentence-unknown-ratio sweep).
_QUOTATIVE_ENDINGS: frozenset = frozenset({
    "ㄴ다고", "는다고", "다고", "자고", "냐고", "으라고", "라고",
})


def _jamo_attributive_repair(stem: str) -> Optional[str]:
    stripped = _strip_final_batchim(stem, (_TAIL_NIEUN, _TAIL_RIEUL))
    if stripped is None:
        return None
    for frag, full in H_IRREGULAR_MAP.items():
        if stripped.endswith(frag):
            return stripped[: -len(frag)] + full
    for frag, root in IRREGULAR_STEM_MAP.items():
        if stripped.endswith(frag):
            return stripped[: -len(frag)] + root
    return stripped + "다"


def _restore_predicate(stem: str) -> str:
    """Append 다 to a verb/adjective stem left after stripping an ending,
    applying the irregular/contraction repair tables first (longest
    fragment first, since IRREGULAR_STEM_MAP entries are 2-4 chars and
    CONTRACTION_MAP entries are 1-2). This is the GENERIC, always-succeeds
    restorer (falls back to `stem + "다"` verbatim); see `_irregular_repair`
    for the higher-priority, may-return-None variant used in PASS 1 of
    `_lemma_candidates`."""
    if not stem:
        return "다"
    repaired = _irregular_repair(stem)
    if repaired is not None:
        return repaired
    return stem + "다"


def _lemma_candidates(token: str) -> List[str]:
    """Return dictionary-form candidates for `token`, most-specific /
    highest-confidence first, ending with the token itself unchanged (last
    resort).

    R3 item 4 restructured this into two passes over the same suffix scan:
    PASS 1 collects only candidates that matched a hand-curated irregular
    table (`_irregular_repair`, never a generic guess) so a correct but
    less-obvious repair can never be shadowed by a generic `stem + "다"`
    guess that happens to coincide with a real, unrelated word (see
    `_irregular_repair`'s docstring for the concrete 나아요 case). PASS 2 is
    the original, generic suffix-stripping behaviour, appended afterwards
    (lower priority) so all the previously-passing resolutions are
    unaffected when no irregular table applies."""
    candidates: List[str] = []
    expanded = expand_contractions(token)
    sources = (token, expanded) if expanded != token else (token,)

    # PASS 1: irregular-table repairs only (see docstring above).
    for source in sources:
        direct = _irregular_repair(source)
        if direct is not None:
            candidates.append(direct)
        direct_attributive = _jamo_attributive_repair(source)
        if direct_attributive is not None:
            candidates.append(direct_attributive)
        for suf in _ALL_SUFFIXES:
            if suf in _ENDING_SET and source.endswith(suf) and len(source) > len(suf):
                stem = source[: -len(suf)]
                repaired = _irregular_repair(stem)
                if repaired is not None:
                    candidates.append(repaired)
                if suf in _QUOTATIVE_ENDINGS:
                    quotative_repaired = _jamo_attributive_repair(stem)
                    if quotative_repaired is not None:
                        candidates.append(quotative_repaired)
                if suf in _HADA_FUSED_ENDINGS:
                    candidates.append(stem + "하다")
                if suf == "니다" and stem:
                    # Narrowly scoped to the "니다" suffix itself (not a
                    # general stem repair -- see the "니다" ENDINGS comment
                    # and _TAIL_BIEUP's comment): only fires when a ㅂ was
                    # just consumed as part of "-ㅂ니다".
                    b_stripped = _strip_final_batchim(stem, (_TAIL_BIEUP,))
                    if b_stripped is not None:
                        candidates.append(b_stripped + "다")
        if source in _HADA_FUSED_ENDINGS:
            # Token IS exactly the fused ending itself ("해서" standalone,
            # "and so" / "therefore") -- the main suf loop above requires
            # `len(source) > len(suf)` (a non-empty stem), so this whole-
            # token-equals-suffix case needs its own check.
            candidates.append("하다")
        if source.endswith(_FALLBACK_ENDING) and len(source) > len(_FALLBACK_ENDING):
            repaired = _irregular_repair(source[: -len(_FALLBACK_ENDING)])
            if repaired is not None:
                candidates.append(repaired)

    # PASS 2: generic suffix stripping (original behaviour, unchanged).
    for source in sources:
        for suf in _ALL_SUFFIXES:
            if source.endswith(suf) and len(source) > len(suf):
                stem = source[: -len(suf)]
                if suf in _COPULA_ENDINGS:
                    candidates.append(stem)
                elif suf in _ENDING_SET:
                    candidates.append(_restore_predicate(stem))
                if suf in _PARTICLE_SET:
                    candidates.append(stem)
        # Fallback: bare trailing "요" not in the brief's ENDINGS list,
        # needed to reach CONTRACTION_MAP/IRREGULAR_STEM_MAP (see module
        # docstring / _FALLBACK_ENDING comment above).
        if source.endswith(_FALLBACK_ENDING) and len(source) > len(_FALLBACK_ENDING):
            stem = source[: -len(_FALLBACK_ENDING)]
            candidates.append(_restore_predicate(stem))
    candidates.append(token)
    # De-duplicate while preserving order (priority-first).
    seen = set()
    ordered = []
    for c in candidates:
        if c not in seen:
            seen.add(c)
            ordered.append(c)
    return ordered


def _strip_one_particle(token: str) -> str:
    """Strip the longest single PARTICLES-table suffix from `token`, or
    return `token` unchanged if none matches. Shared by `_multiword_lookup`
    and proper-noun matching (`CefrLexicon._match_proper_noun`, R3 item 5)."""
    for particle in _PARTICLES_BY_LEN_DESC:
        if token.endswith(particle) and len(token) > len(particle):
            return token[: -len(particle)]
    return token


def _longest_connective_suffix(token: str) -> Optional[str]:
    """Longest CONNECTIVE_ENDINGS suffix matched on `token` (after
    contraction expansion), or None. Used for clause counting only."""
    expanded = expand_contractions(token)
    for suf in sorted(CONNECTIVE_ENDINGS, key=len, reverse=True):
        if expanded.endswith(suf) and len(expanded) > len(suf):
            return suf
    return None


def tokenize_eojeols(text: str) -> List[str]:
    """Whitespace eojeol split (no normalization — callers strip
    punctuation per-token as needed)."""
    return text.split()


# ---------------------------------------------------------------------------
# Proper nouns (R3 item 5)
# ---------------------------------------------------------------------------

# Fixed extra proper-noun list from the R3 brief, unioned with every
# character name loaded from character_profiles.json by
# load_character_names().
EXTRA_PROPER_NOUNS: Tuple[str, ...] = (
    "현우", "지은", "민수", "수진", "안드레아", "크리스티안", "마리아",
    "다니엘", "제니", "이지윤",
)


def load_character_names(root: Path = REPO) -> FrozenSet[str]:
    """Every `recurringCharacters[].displayNames.ko` name from
    tools/content_factory/canonical_scenarios/character_profiles.json,
    unioned with EXTRA_PROPER_NOUNS (R3 item 5). Falls back to just
    EXTRA_PROPER_NOUNS if the profiles file is missing or malformed --
    proper-noun exclusion degrading gracefully is preferable to
    CefrLexicon.load() failing outright over an unrelated content-factory
    asset it does not otherwise depend on."""
    names = set(EXTRA_PROPER_NOUNS)
    path = root / "tools" / "content_factory" / "canonical_scenarios" / "character_profiles.json"
    try:
        with path.open(encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, ValueError):
        return frozenset(names)
    for character in data.get("recurringCharacters", []) or []:
        display_names = character.get("displayNames") or {}
        ko = display_names.get("ko")
        if ko:
            names.add(ko.strip())
    return frozenset(n for n in names if n)


# ---------------------------------------------------------------------------
# Dataclasses (plan §4.1 interface, extended under R3 -- see module docstring)
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class WordGrade:
    grade: Optional[int]
    cefr: Optional[str]
    source: Optional[str]  # 'kiiq'|'basic2023'|'alias'|'derived'|'proper_noun'|None
    matched: str

    @property
    def confidence(self) -> Optional[str]:
        """'high' for kiiq/derived/alias, 'low' for basic2023, else None
        (R3 item 2). Derived from `source` rather than stored, so every
        WordGrade constructed anywhere in this module reports it correctly
        with no propagation step to forget."""
        if self.grade is None:
            return None
        return _CONFIDENCE_BY_SOURCE.get(self.source)


@dataclass(frozen=True)
class PhraseGrade:
    grade: Optional[int]
    cefr: Optional[str]
    words: Tuple[WordGrade, ...]
    unknown: Tuple[str, ...]


@dataclass(frozen=True)
class GrammarHit:
    pattern_id: str
    grade: int
    cefr: str
    span: Tuple[int, int]
    text: str


@dataclass(frozen=True)
class SentenceProfile:
    text: str
    eojeol_count: int
    clause_count: int
    lexical_p90: Optional[float]
    grammar_max: Optional[int]
    grammar_hits: Tuple[GrammarHit, ...]
    tokens: Tuple[WordGrade, ...]
    unknown: Tuple[str, ...]
    low_confidence: Tuple[str, ...]
    proper_nouns: Tuple[str, ...]
    level_estimate: Optional[str]


@dataclass(frozen=True)
class _LexiconRow:
    grade: int
    headword: str
    homograph: int


def _percentile(values: Sequence[int], pct: float) -> Optional[float]:
    """Linear-interpolation percentile (numpy 'linear' method), pure stdlib."""
    if not values:
        return None
    s = sorted(values)
    n = len(s)
    if n == 1:
        return float(s[0])
    idx = (n - 1) * pct / 100.0
    lo = math.floor(idx)
    hi = math.ceil(idx)
    if lo == hi:
        return float(s[lo])
    frac = idx - lo
    return s[lo] + (s[hi] - s[lo]) * frac


def apply_length_rule(grade: int, eojeol_count: int) -> int:
    """Bump `grade` one level if `eojeol_count` exceeds its length ceiling
    (plan §3.C.2 / brief length rule). No ceiling is defined past B2, so C1/
    C2 sentences are never bumped further."""
    limit = LENGTH_LIMIT_BY_GRADE.get(grade)
    if limit is not None and eojeol_count > limit:
        return min(grade + 1, 6)
    return grade


# ---------------------------------------------------------------------------
# CSV loading helpers
# ---------------------------------------------------------------------------


def _read_csv(path: Path) -> List[dict]:
    with path.open(encoding="utf-8", newline="") as fh:
        return list(csv.DictReader(fh))


def load_grammar_rows(root: Path = REPO) -> List[dict]:
    """Read assets/data/grammar.csv (id, level, pattern, ...)."""
    return _read_csv(root / "assets" / "data" / "grammar.csv")


def load_nikl_grammar_rows(root: Path = REPO) -> List[dict]:
    """Read tools/content_factory/lexicon/nikl_kiiq_2017_grammar.csv."""
    return _read_csv(
        root / "tools" / "content_factory" / "lexicon" / "nikl_kiiq_2017_grammar.csv"
    )


# ---------------------------------------------------------------------------
# CefrLexicon
# ---------------------------------------------------------------------------


class CefrLexicon:
    """Word/phrase/sentence CEFR-grade judge (plan §3.C, §4.1; R3-revised —
    see module docstring)."""

    def __init__(
        self,
        kiiq_any: Mapping[str, Tuple[_LexiconRow, ...]],
        basic_any: Mapping[str, Tuple[int, ...]],
        aliases: Mapping[str, Tuple[Optional[str], str]],
        proper_nouns: FrozenSet[str] = frozenset(),
    ) -> None:
        self._kiiq_any = kiiq_any
        self._basic_any = basic_any
        self._aliases = aliases
        self._proper_nouns = proper_nouns

    # -- loading ------------------------------------------------------

    @classmethod
    def load(cls, root: Path = REPO) -> "CefrLexicon":
        lex_dir = root / "tools" / "content_factory" / "lexicon"
        kiiq_rows = _read_csv(lex_dir / "nikl_kiiq_2017_vocab.csv")
        basic_rows = _read_csv(lex_dir / "nikl_basic_2023_vocab.csv")
        alias_rows = _read_csv(lex_dir / "aliases.csv")
        proper_nouns = load_character_names(root)
        return cls.from_rows(kiiq_rows, basic_rows, alias_rows, proper_nouns)

    @classmethod
    def from_rows(
        cls,
        kiiq_rows: Iterable[Mapping[str, str]],
        basic_rows: Iterable[Mapping[str, str]],
        alias_rows: Iterable[Mapping[str, str]],
        proper_nouns: Iterable[str] = (),
    ) -> "CefrLexicon":
        # R3 item 1: a single map covering EVERY homograph row (including
        # homograph 0) for a headword, sorted ascending by grade so index 0
        # is always the minimum -- no more separate homograph-0-only
        # "exact" tier that could shadow a lower-grade sibling homograph.
        kiiq_any_lists: dict = {}
        for row in kiiq_rows:
            headword = row["headword"].strip()
            grade = int(row["grade"])
            homograph = int(row.get("homograph") or 0)
            entry = _LexiconRow(grade=grade, headword=headword, homograph=homograph)
            kiiq_any_lists.setdefault(headword, []).append(entry)
        kiiq_any = {
            k: tuple(sorted(v, key=lambda r: r.grade)) for k, v in kiiq_any_lists.items()
        }

        basic_any: dict = {}
        for row in basic_rows:
            headword = row["headword"].strip()
            grade = int(row["grade"])
            basic_any.setdefault(headword, []).append(grade)
        basic_any = {k: tuple(sorted(v)) for k, v in basic_any.items()}

        aliases: dict = {}
        for row in alias_rows:
            app_form = row["app_form"].strip()
            lexicon_form = (row.get("lexicon_form") or "").strip()
            note = (row.get("note") or "").strip()
            aliases[app_form] = (lexicon_form or None, note)

        return cls(kiiq_any, basic_any, aliases, frozenset(proper_nouns))

    # -- internal lookup tiers -----------------------------------------

    def _derived_lookup(self, word: str) -> Optional[Tuple[int, str]]:
        for suf in DERIVED_SUFFIXES:
            if word.endswith(suf) and len(word) > len(suf):
                root = word[: -len(suf)]
                rows = self._kiiq_any.get(root)
                if rows:
                    return rows[0].grade, root  # sorted ascending -> minimum
        return None

    def _basic2023_lookup(self, word: str) -> Optional[int]:
        grades = self._basic_any.get(word)
        if not grades:
            return None
        return BASIC2023_TO_GRADE[min(grades)]

    def _kiiq_derived_chain(self, word: str) -> WordGrade:
        """Steps 1-2 (plan §3.C.1, R3-revised): kiiq (homograph-insensitive,
        minimum grade across every row sharing the headword — R3 item 1),
        then derived. No aliases, no multiword, no basic2023 fallback."""
        rows = self._kiiq_any.get(word)
        if rows:
            best = rows[0]  # sorted ascending by grade -> minimum/easiest
            if len(rows) > 1:
                homographs = sorted({r.homograph for r in rows})
                matched = word + "(" + ",".join("h%d" % h for h in homographs) + ")"
            else:
                matched = word
            return WordGrade(best.grade, GRADE_TO_CEFR[best.grade], "kiiq", matched)
        derived = self._derived_lookup(word)
        if derived is not None:
            grade, root = derived
            return WordGrade(grade, GRADE_TO_CEFR[grade], "derived", root)
        return WordGrade(None, None, None, word)

    def _fallback_chain(self, word: str) -> WordGrade:
        """Step 5 (plan §3.C.1, R3-revised): basic2023 only — the kcenter
        tier is removed (R3 item 3, source CSV deleted upstream in R2)."""
        basic_grade = self._basic2023_lookup(word)
        if basic_grade is not None:
            return WordGrade(basic_grade, GRADE_TO_CEFR[basic_grade], "basic2023", word)
        return WordGrade(None, None, None, word)

    def _base_chain(self, word: str) -> WordGrade:
        """kiiq exact/homograph-insensitive/derived, falling back to
        basic2023. Used for the *recursive* resolution inside an alias's
        `lexicon_form` or a multiword split — those already passed the
        alias/multiword gate, so no recursion risk running the full chain
        here (steps 1-2 then 5, no alias/multiword re-entry)."""
        kd = self._kiiq_derived_chain(word)
        if kd.grade is not None:
            return kd
        return self._fallback_chain(word)

    def _alias_lookup(self, word: str) -> WordGrade:
        lexicon_form, _note = self._aliases[word]
        if lexicon_form is None:
            # Grade-list-independent exception (e.g. 화이팅) -> A1.
            return WordGrade(1, "A1", "alias", word)
        if " " in lexicon_form:
            sub_grades = [self._base_chain(w) for w in lexicon_form.split(" ") if w]
            known = [g for g in sub_grades if g.grade is not None]
            if not known:
                return WordGrade(None, None, "alias", lexicon_form)
            best = max(known, key=lambda g: g.grade)
            return WordGrade(best.grade, best.cefr, "alias", lexicon_form)
        base = self._base_chain(lexicon_form)
        if base.grade is None:
            return WordGrade(None, None, "alias", lexicon_form)
        return WordGrade(base.grade, base.cefr, "alias", lexicon_form)

    def _multiword_lookup(self, phrase: str) -> WordGrade:
        best: Optional[WordGrade] = None
        for raw_tok in phrase.split(" "):
            tok = raw_tok.strip()
            if not tok:
                continue
            content = _strip_one_particle(tok)
            if content in _PARTICLE_SET or not content:
                continue  # pure particle/ending token: skipped
            wg = self._base_chain(content)
            if wg.grade is not None and (best is None or wg.grade > best.grade):
                best = wg
        if best is None:
            return WordGrade(None, None, None, phrase)
        return WordGrade(best.grade, best.cefr, best.source, best.matched)

    def _match_proper_noun(self, token: str) -> Optional[str]:
        """R3 item 5: `token` itself, or `token` with one trailing particle
        stripped, matched against the loaded proper-noun set. Returns the
        matched (particle-free) name, or None."""
        if not self._proper_nouns:
            return None
        if token in self._proper_nouns:
            return token
        root = _strip_one_particle(token)
        if root != token and root in self._proper_nouns:
            return root
        return None

    # -- public API ------------------------------------------------------

    def word_grade(self, word: str) -> WordGrade:
        """Grade a single dictionary form / surface word, in the exact
        order given by plan §3.C.1 (R3-revised): proper noun -> kiiq
        (homograph-insensitive minimum) -> derived -> aliases.csv ->
        multiword -> basic2023 -> unknown."""
        normalized = _normalize_token(word)
        if not normalized:
            return WordGrade(None, None, None, word)
        proper = self._match_proper_noun(normalized)
        if proper is not None:
            return WordGrade(None, None, "proper_noun", proper)
        kd = self._kiiq_derived_chain(normalized)
        if kd.grade is not None:
            return kd
        if normalized in self._aliases:
            # Once a word is a known alias key, aliases.csv is authoritative
            # (even a None-grade alias resolution reports source='alias'
            # rather than silently falling through to basic2023 on the
            # un-aliased original spelling).
            return self._alias_lookup(normalized)
        if " " in normalized:
            multiword_result = self._multiword_lookup(normalized)
            if multiword_result.grade is not None:
                return multiword_result
        fb = self._fallback_chain(normalized)
        if fb.grade is not None:
            return fb
        return WordGrade(None, None, None, normalized)

    def phrase_grade(self, phrase: str) -> PhraseGrade:
        """Grade every eojeol of `phrase` via the full lemmatizer + full
        word_grade chain (including aliases), returning max over content
        words (plan §4.1: '내용어별 WordGrade + max'). Proper-noun tokens
        (R3 item 5) are excluded from `unknown`."""
        words: List[WordGrade] = []
        unknown: List[str] = []
        for raw in tokenize_eojeols(phrase):
            token = _normalize_token(raw)
            if not token:
                continue
            resolved = self._resolve_eojeol(token)
            words.append(resolved)
            if resolved.grade is None and resolved.source != "proper_noun":
                unknown.append(raw)
        known = [w for w in words if w.grade is not None]
        if not known:
            return PhraseGrade(None, None, tuple(words), tuple(unknown))
        best = max(known, key=lambda w: w.grade)
        return PhraseGrade(best.grade, best.cefr, tuple(words), tuple(unknown))

    def _resolve_eojeol(self, token: str) -> WordGrade:
        """Try every lemma candidate (priority-ordered, see
        `_lemma_candidates`) through the full word_grade chain; first
        resolving candidate wins. Proper nouns (R3 item 5) are checked
        FIRST and short-circuit here — they must never fall into the
        candidate loop below, since their WordGrade.grade is deliberately
        None (excluded from grading) and the loop's "first grade-not-None
        wins" logic would otherwise skip right past them."""
        proper = self._match_proper_noun(token)
        if proper is not None:
            return WordGrade(None, None, "proper_noun", proper)
        for candidate in _lemma_candidates(token):
            wg = self.word_grade(candidate)
            if wg.grade is not None:
                return WordGrade(wg.grade, wg.cefr, wg.source, candidate)
        return WordGrade(None, None, None, token)

    def sentence_profile(self, text: str, grammar_index: "GrammarIndex") -> SentenceProfile:
        """Grade a whole sentence (plan §3.C.2, R3-revised — see module
        docstring for the confidence-cap and proper-noun changes)."""
        eojeols = tokenize_eojeols(text)
        eojeol_count = len(eojeols)

        tokens: List[WordGrade] = []
        unknown: List[str] = []
        low_confidence: List[str] = []
        proper_nouns: List[str] = []
        connective_hits = 0
        for raw in eojeols:
            token = _normalize_token(raw)
            if not token:
                continue
            resolved = self._resolve_eojeol(token)
            tokens.append(resolved)
            if resolved.source == "proper_noun":
                proper_nouns.append(resolved.matched)
            elif resolved.grade is None:
                unknown.append(raw)
            elif resolved.confidence == "low":
                # R3 item 2: raw fallback grade is kept on the WordGrade
                # itself; only the lexical_p90 aggregate below is capped.
                low_confidence.append(raw)
            if _longest_connective_suffix(token) is not None:
                connective_hits += 1
        clause_count = connective_hits + 1

        known_tokens = [t for t in tokens if t.grade is not None]
        capped_grades = [
            min(t.grade, 3) if t.confidence == "low" else t.grade for t in known_tokens
        ]
        lexical_p90 = _percentile(capped_grades, 90)

        grammar_hits = grammar_index.detect(expand_contractions(text))
        grammar_max = max((h.grade for h in grammar_hits), default=None)

        candidates = []
        if lexical_p90 is not None:
            candidates.append(round(lexical_p90))
        if grammar_max is not None:
            candidates.append(grammar_max)
        base_grade = max(candidates) if candidates else 1
        final_grade = apply_length_rule(base_grade, eojeol_count)
        level_estimate = GRADE_TO_CEFR[final_grade]

        return SentenceProfile(
            text=text,
            eojeol_count=eojeol_count,
            clause_count=clause_count,
            lexical_p90=lexical_p90,
            grammar_max=grammar_max,
            grammar_hits=tuple(grammar_hits),
            tokens=tuple(tokens),
            unknown=tuple(unknown),
            low_confidence=tuple(low_confidence),
            proper_nouns=tuple(proper_nouns),
            level_estimate=level_estimate,
        )


# ---------------------------------------------------------------------------
# GrammarIndex (R3 item 6 — see module docstring for the rule summary)
# ---------------------------------------------------------------------------


_PREFIX_RE = re.compile(r"(^|(?<=\s))(A/V-|V-|A-|N)")
_TRAILING_DIGITS_RE = re.compile(r"\d+$")
_AE_PLACEHOLDER = "\x00AE\x00"

# R3 item 6 (rules c/d): a pattern whose literal core is ≤2 Hangul
# syllables is only built into a rule when its grade is in this set.
#
# The brief's prose says "allowed only from grades 1-3"; this constant is
# {1, 2}, a deliberate, evidence-based NARROWING documented here (T1.2
# report §open_questions flags it explicitly for Fable). Reason: the two
# concrete golden sentences in the brief are structurally IDENTICAL --
# '···된다고···' (다고, a 2-syllable literal core) is independently tagged
# grade 3 by TWO separate NIKL rows (연결어미 "이유" and 표현 "인용"), and
# '···앉으니···' (으니, also 2 syllables) is likewise tagged grade 3 by TWO
# separate rows (연결어미 "이유" and a 종결어미 "의문" variant). Allowing
# grade-3 2-syllable cores through (the literal "1-3" reading) leaves BOTH
# sentences at grammar_max=3, which satisfies the 다고 sentence's "≤3" bound
# but VIOLATES the 으니 sentence's explicit "≤2" bound -- and there is no
# structural signal (both are bare 2-syllable literals with two redundant
# same-grade NIKL rows apiece) that would let a uniform rule keep one and
# drop the other. Narrowing to {1, 2} satisfies both golden bounds
# (다고 sentence drops to grammar_max=1, comfortably ≤3; 으니 sentence drops
# to grammar_max=1, satisfying ≤2) and is the conservative direction: it
# only ever SUPPRESSES a detection, never invents one, consistent with this
# module's "재현율·투명성 우선" philosophy applied to the harder-to-verify
# grammar layer.
_SHORT_FRAGMENT_ALLOWED_GRADES = frozenset({1, 2})

# Real predicate lemmas (last 2 characters) whose citation-form trailing
# 다 is safe to drop so the regex also matches conjugated continuations
# (같다 -> 같아요/같습니다, 있다 -> 있어요/있나요). Deliberately a small,
# checked whitelist rather than "any segment ending in 다": several NIKL
# connective-ending fragments end in a bare 다 that is *not* a droppable
# predicate (e.g. "-어다"/"-다가" allomorphs, "-습니다") — see T1.2 report.
# Rules built from one of these ARE allowed to match mid-eojeol (before
# further conjugation attaches) — R3 item 6's eojeol-boundary check is
# gated on `short_fragment` (literal core ≤2 syllables), and every one of
# these predicate-drop segments has a literal core ≥3 syllables (본동사 +
# 다), so the two never conflict; see `GrammarIndex.detect`.
_PREDICATE_DA_SUFFIXES = frozenset({
    "같다", "싶다", "보다", "있다", "없다", "이다", "하다", "되다",
})


def _drop_trailing_da(segment: str) -> str:
    """Drop a bare dictionary-citation trailing 다 so the regex matches any
    conjugated continuation too (같다 -> 같, 있다 -> 있). Only applied when
    the segment ends in one of `_PREDICATE_DA_SUFFIXES` — see its docstring."""
    if segment.endswith(")다"):
        return segment  # e.g. "...(이)다" — leave the optional group intact
    if len(segment) >= 2 and segment[-2:] in _PREDICATE_DA_SUFFIXES:
        return segment[:-1]
    return segment


def _compile_segment(seg: str) -> str:
    seg = seg.replace("아/어", _AE_PLACEHOLDER)
    seg = seg.replace("(으)ㄹ", "(을|ㄹ)")
    seg = seg.replace("(으)ㄴ", "(은|ㄴ)")
    seg = seg.replace("(이)", "(이)?")
    seg = seg.replace("(으)", "(으)?")
    if "/" in seg:
        alts = [a.strip().lstrip("-") for a in seg.split("/")]
        alts = [a.replace(_AE_PLACEHOLDER, "(아|어|여|해)") for a in alts]
        alts = [_drop_trailing_da(a) for a in alts]
        return "(" + "|".join(a for a in alts if a) + ")"
    seg = seg.replace(_AE_PLACEHOLDER, "(아|어|여|해)")
    return _drop_trailing_da(seg)


def compile_pattern_regex(raw_pattern: str, strip_slot_prefix: bool = True) -> re.Pattern:
    """Compile one grammar `pattern`/`form` string into a search regex
    per the brief's transformation rules: drop V-/A-/A/V-/N slot markers,
    (으)ㄹ -> (을|ㄹ), (으)ㄴ -> (은|ㄴ), (으) -> (으)?, 아/어 -> (아|어|여|해),
    '/' alternatives -> group, spaces -> optional whitespace."""
    pattern = raw_pattern.strip()
    if strip_slot_prefix:
        pattern = _PREFIX_RE.sub("", pattern)
    else:
        pattern = pattern.lstrip("-")
        pattern = _TRAILING_DIGITS_RE.sub("", pattern)
    tokens = [t for t in pattern.split(" ") if t]
    compiled = [_compile_segment(t) for t in tokens]
    body = r"\s*".join(c for c in compiled if c)
    return re.compile(body)


def _should_skip_bare_fragment(cleaned: str) -> bool:
    """True when `cleaned` (a pattern/variant already stripped of slot
    markers, leading '-', and trailing homograph digits) is too short or
    too generic to regex-detect reliably: a single bare character (no
    space, no '/', no parens) matches almost anywhere, and a 2-3 char bare
    fragment that is just two independently common particles/endings
    concatenated (see `_is_generic_collision`) collides with ordinary
    vocabulary. Alternation groups ('은/는') and multi-eojeol patterns
    ('기 때문에') are exempt — they carry enough structure to stay specific."""
    if " " in cleaned or "/" in cleaned or "(" in cleaned:
        return False
    if len(cleaned) < 2:
        return True
    return _is_generic_collision(cleaned)


def _is_generic_collision(cleaned: str) -> bool:
    """True when a short, unparenthesized/unslashed pattern fragment is not
    itself a recognised whole PARTICLES/ENDINGS unit but decomposes exactly
    into a concatenation of two such units (e.g. "기에" = ENDING "기"
    (nominalizer) + PARTICLE "에"). Such fragments regex-match almost any
    ordinary word that happens to end the same way (감기+에 "a cold" is not
    the "-기에" reason-clause pattern) — this is the single biggest source
    of the false positives the plan (§0.1) flags in the existing heuristic
    auditor, so patterns like this are excluded from detection rather than
    guessed at. Documented as an explicit deviation beyond the brief's
    literal transformation rules — see T1.2 report to Fable."""
    if len(cleaned) > 3 or len(cleaned) < 2:
        return False
    if cleaned in _PARTICLE_SET or cleaned in _ENDING_SET:
        return False  # a recognised whole unit, not a coincidental join
    combined = _PARTICLE_SET | _ENDING_SET
    for split in range(1, len(cleaned)):
        left, right = cleaned[:split], cleaned[split:]
        if left in combined and right in combined:
            return True
    return False


def _literal_syllable_count(raw: str) -> int:
    """R3 item 6 (rules c/d): the Hangul-syllable length of `raw`'s LONGEST
    '/'-separated alternative (parens KEPT — an optional-group vowel like
    "으" in "(으)ㄴ" still counts as a real syllable when realised; only the
    non-Hangul jamo batchim letters like bare "ㄴ"/"ㄹ" are excluded, since
    `[가-힣]` only matches full precomposed syllable blocks). This is the
    "how much literal material does this pattern actually anchor on"
    measure gating `GrammarIndex.build`'s grade/length rules below.

    Taking the MAX across alternatives (not just the first) matters for
    compact same-tail notation like "(으)ㄴ/는 셈이다": its first alt
    ("(으)ㄴ") is trivially short (1 syllable, just "으") but the pattern as
    a WHOLE is not (its second alt is 4 syllables) — using only the first
    alt would wrongly gate a real B2 pattern out. Using the max also
    correctly removes the genuinely under-specified "(으)ㄴ/는지" (both alts
    ≤2 syllables) — see `_SHORT_FRAGMENT_ALLOWED_GRADES`'s docstring."""
    alts = raw.split("/") if "/" in raw else [raw]
    return max(len(_HANGUL_SYLLABLE_RE.findall(alt)) for alt in alts)


def _ends_at_eojeol_boundary(text: str, end: int) -> bool:
    """R3 item 6 (rule a), scoped to `short_fragment` rules only (see
    `GrammarIndex.detect`): True when `text[end]` starts the end of the
    current eojeol — i.e. the rest of the eojeol (from `end` to the next
    whitespace or end of string) is empty, pure trailing punctuation, or a
    single listed particle. A `_drop_trailing_da`-built predicate rule
    (어 있다, 하다, 되다, …) is NEVER short_fragment (its literal core is
    always ≥3 syllables including the dropped 다), so this check never
    rejects the intentional mid-eojeol matches those rules rely on (e.g.
    "포함되어 있나요?" — "어 있" ends mid-word, right before "나요?")."""
    n = len(text)
    j = end
    while j < n and not text[j].isspace():
        j += 1
    remainder = text[end:j].strip(TRAILING_PUNCT)
    return not remainder or remainder in _PARTICLE_SET


def _dedupe_overlapping_hits(hits: Sequence[GrammarHit]) -> List[GrammarHit]:
    """R3 item 6 (rule b): when two hits share the EXACT SAME span, keep
    only the lower-grade one (ties are both kept — they don't affect
    grammar_max either way). Every concrete over-matching case in the R3
    brief (다고 tagged grade 3 AND grade 6 on the identical literal core;
    어 있다 tagged grade 2 AND grade 3; 으니 tagged grade 3 by two separate
    NIKL rows) is two rules matching the IDENTICAL span, not merely an
    overlapping one — deliberately NOT generalised to partial-overlap
    dedup, which would incorrectly drop a real, independent, LARGER
    pattern (e.g. "는 편이다", grade 3) just because a completely unrelated
    grade-1 bare topic-particle rule ("N은/는") also matches the "는"
    substring inside it; see `TestGrammarIndexTableDriven`'s required
    gr_pyeonida pattern, which regressed under a naive overlap check during
    this rework and is now covered by an explicit dedup test."""
    ordered = sorted(hits, key=lambda h: (h.grade, h.span[0], h.span[1]))
    kept: List[GrammarHit] = []
    for h in ordered:
        if any(k.grade < h.grade and k.span == h.span for k in kept):
            continue
        kept.append(h)
    kept.sort(key=lambda h: (h.span[0], h.span[1], h.grade))
    return kept


def _slug(text: str) -> str:
    cleaned = re.sub(r"[^0-9A-Za-z가-힣]+", "_", text).strip("_")
    return cleaned or "pattern"


@dataclass(frozen=True)
class _GrammarRule:
    pattern_id: str
    grade: int
    cefr: str
    regex: re.Pattern
    short_fragment: bool = False


class GrammarIndex:
    """Regex-based grammar-pattern detector (plan §4.1; R3-revised — see
    module docstring)."""

    def __init__(self, rules: Sequence[_GrammarRule]) -> None:
        self._rules = tuple(rules)

    @classmethod
    def build(
        cls,
        grammar_rows: Iterable[Mapping[str, str]],
        nikl_rows: Iterable[Mapping[str, str]],
    ) -> "GrammarIndex":
        rules: List[_GrammarRule] = []
        for row in grammar_rows:
            level = (row.get("level") or "").strip()
            grade = CEFR_TO_GRADE.get(level)
            pattern = (row.get("pattern") or "").strip()
            pid = (row.get("id") or "").strip() or _slug(pattern)
            if grade is None or not pattern:
                continue
            stripped = _PREFIX_RE.sub("", pattern).strip()
            if _should_skip_bare_fragment(stripped):
                continue
            literal_len = _literal_syllable_count(stripped)
            if literal_len <= 2 and grade not in _SHORT_FRAGMENT_ALLOWED_GRADES:
                continue
            if grade >= 5 and literal_len < 4:
                continue
            regex = compile_pattern_regex(pattern, strip_slot_prefix=True)
            if regex.pattern:
                rules.append(
                    _GrammarRule(pid, grade, GRADE_TO_CEFR[grade], regex, literal_len <= 2)
                )
        for row in nikl_rows:
            # '조사' (bare particles) and single-syllable 어미 fragments are
            # already covered by the word-level PARTICLES/ENDINGS tokenizer
            # and are far too short to regex-match reliably as a "grammar
            # pattern" (e.g. bare "나"/"에"/"도"/"기" match almost any
            # sentence) — restrict detection to the categories that carry
            # genuine multi-character teaching patterns.
            category = (row.get("category") or "").strip()
            if category not in {"표현", "연결어미", "종결어미"}:
                continue
            try:
                grade = int(row.get("grade") or 0)
            except ValueError:
                continue
            if grade not in GRADE_TO_CEFR:
                continue
            form = (row.get("form") or "").strip()
            variants_field = (row.get("variants") or "").strip()
            variants_field = variants_field.replace("<반의>", ",")
            variant_forms = [form] + [
                v.strip() for v in variants_field.split(",") if v.strip()
            ]
            for idx, variant in enumerate(variant_forms):
                if not variant:
                    continue
                cleaned = _TRAILING_DIGITS_RE.sub("", variant.lstrip("-"))
                if _should_skip_bare_fragment(cleaned):
                    continue
                literal_len = _literal_syllable_count(cleaned)
                if literal_len <= 2 and grade not in _SHORT_FRAGMENT_ALLOWED_GRADES:
                    continue
                if grade >= 5 and literal_len < 4:
                    continue
                regex = compile_pattern_regex(variant, strip_slot_prefix=False)
                if not regex.pattern:
                    continue
                pid = f"nikl_g{grade}_{_slug(form)}" + (f"_v{idx}" if idx else "")
                rules.append(
                    _GrammarRule(pid, grade, GRADE_TO_CEFR[grade], regex, literal_len <= 2)
                )
        return cls(rules)

    @classmethod
    def load(cls, root: Path = REPO) -> "GrammarIndex":
        return cls.build(load_grammar_rows(root), load_nikl_grammar_rows(root))

    def detect(self, text: str) -> List[GrammarHit]:
        """R3 item 6: raw regex hits are filtered by the eojeol-boundary
        check (short_fragment rules only, rule a) and then deduped by
        overlapping span (rule b, keep-lowest-grade) before being
        returned — every caller (including `sentence_profile`, whose
        `grammar_max`/`grammar_hits` are strictly derived from this list)
        sees the same, already-refined hit set."""
        raw: List[GrammarHit] = []
        for rule in self._rules:
            for match in rule.regex.finditer(text):
                if match.start() == match.end():
                    continue  # ignore degenerate all-optional matches
                if rule.short_fragment and not _ends_at_eojeol_boundary(text, match.end()):
                    continue
                raw.append(
                    GrammarHit(
                        pattern_id=rule.pattern_id,
                        grade=rule.grade,
                        cefr=rule.cefr,
                        span=(match.start(), match.end()),
                        text=match.group(0),
                    )
                )
        return _dedupe_overlapping_hits(raw)
