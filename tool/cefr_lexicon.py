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

Formerly a known gap, now resolved by R7 item 8 (see
``tool/test_cefr_lexicon.py``'s
``test_cheunggan_soeum_now_resolves_via_r7_item8_compound_split`` and the
T1.2 report to Fable): the compound 층간소음 is not a headword in either
remaining source list AS A WHOLE WORD (verified by direct grep), so under
R3 ``word_grade('층간소음')`` returned ``unknown`` -- not the fabricated
``(3, 'B1', 'kiiq')`` some drafts of the brief assumed, but also not a
resolved grade. Flagged then for Fable's ruling (alias vs. accepted gap);
R7 item 8's generic compound split (§ below) is that ruling in code -- the
word now resolves via its two independently-real parts (층간, 소음)
instead, source='compound', confidence='medium'.

Level exception table (T2.5, PR-L2a, plan §3.E/§14, bible F9 "레벨 예외표")
----------------------------------------------------------------------------
``tools/content_factory/lexicon/level_exceptions.csv`` (header
``category,headword,allowed_level,note``, loaded by
:func:`load_level_exceptions`) lists specific headwords -- kinship
honorifics, learning-metalanguage nouns, signage/transaction vocabulary,
transparent loanwords, and 명절/제사 culture words that keep skewing too
high through kiiq's formal-register bias or basic2023's general-literacy
grade-5 tail (see the R3 item 2 note on 장모님 above) -- whose grade is
capped at a Fable-ruled ``allowed_level``, source='exception'. Checked as
the FIRST tier inside :meth:`CefrLexicon._kiiq_derived_chain` (see that
method's own docstring for why one hook point there reaches every
consumer: word_grade, phrase_grade, sentence_profile, and every
alias/multiword/compound path built on `_base_chain`), so it wins
unconditionally over kiiq/basic2023/derived for its exact headword --
the same override precedent as aliases.csv's empty-lexicon_form A1
exception. A multi-word fixed_expression row (e.g. "새해 복 많이
받으세요") additionally needs :meth:`CefrLexicon.phrase_grade`'s own
whole-phrase pre-check, since Korean eojeol-tokenization never re-joins
separate eojeols back into the original phrase for the per-token loop to
match against a multi-word CSV key.

The CSV also backs one general derivational rule, independent of any
specific listed headword: `X없어요`/`X없다`/`X없는` grades as X's own grade
when X (the noun with that suffix stripped) is itself a graded noun (예:
문제없어요 -- separately ALSO a literal fixed_expression CSV row, so it
resolves to A1 via the exception tier regardless -- decomposes as 문제's
own grade if reached via this rule instead). See
:meth:`CefrLexicon._negation_compound_lookup`.
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
# T2.5 (PR-L2a, plan §3.E/§14, bible F9 "레벨 예외표"): a small table of
# Fable-ruled grade CEILINGS for specific headwords, keyed by category
# (kinship/meta/signage_a1/signage_a2/loanword/culture_basic/
# culture_advanced/fixed_expression -- see the CSV's own rows). Unlike
# aliases.csv's empty-lexicon_form A1 exception (a single fixed grade,
# always 1), this table's `allowed_level` varies per row (A1 or A2) --
# see `load_level_exceptions`/`CefrLexicon._exception_lookup`.
LEVEL_EXCEPTIONS_CSV = LEXICON_DIR / "level_exceptions.csv"
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
    # R7 item 7: a closed-class, unambiguous token (Sejong 1 introduces
    # both numeral systems immediately) -- 'number' (pure ASCII digits)
    # has grade=None by design so never reaches this table (WordGrade.
    # confidence short-circuits to None whenever grade is None).
    "numeral": "high",
    # T2.5: a curated Fable ruling is MORE authoritative than any
    # automatic lookup tier, not less -- same 'high' treatment as
    # kiiq/derived/alias.
    "exception": "high",
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
    # R7 item 6 (second calibration round): plural marker + stacked
    # particle combinations found unresolved in cloze.json/korean_vocab.
    # "들" (plural) is single-pass-stripped here same as every other
    # particle; a token needing TWO strips (e.g. "사람들이" -> strip "이"
    # -> "사람들" -> strip "들" -> "사람") reaches the second strip via
    # word_grade()'s own R7-item-1 lemma-candidate fallback tier when the
    # once-stripped candidate ("사람들") is tried as its own word_grade()
    # lookup -- no recursive stripping was added to this tokenizer itself.
    "들", "에만", "에서만", "으로만", "로만", "까지만", "에게만", "한테만",
    "만큼", "조차", "마저", "밖에는",
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
    # R7 item 5 (sentence-unknown-ratio sweep, second calibration round):
    # more connective/final endings actually found unresolved in
    # cloze.json. Honorific -(으)시- and past -았/었/였- combinations are
    # added as their own PRE-COMBINED literal entries, matching this
    # table's existing style for every other honorific/tense combo above
    # (으시는/시는, 으셨어요/셨어요, …) rather than a generic recursive
    # strip -- this file has never done runtime suffix-chaining, only
    # closed per-combination literals.
    "도록", "길래", "시길래", "으시길래", "자", "자마자",
    "을지",  # ㄹ-stem/vowel-stem "-ㄹ지" is handled separately -- see
             # _RIEUL_FUSED_ENDING_TAILS below (embedded batchim, not a
             # literal standalone-jamo suffix -- see that table's docstring).
    "시기", "으시기", "나요", "은가요",
    "여야", "던", "더라고요", "네", "어도", "아도", "여도", "어서요",
    "는데요", "은데요", "습니다만", "다면", "라면", "려면", "면서도",
    "다가", "았다가", "었다가", "였다가",
    # T2.4a (B4): politeness 요 stacked on a quotative ending (간다고요,
    # 먹자고요, 뭐냐고요, 드시라고요) -- none of the bare quotative endings
    # just below (다고/자고/냐고/라고/으라고) themselves account for a
    # trailing 요, so a token like "간다고요" matched nothing here before
    # and fell through unresolved. "는다고요" additionally covers a
    # consonant-final stem's own quotative+요 (예: "먹는다고요").
    "다고요", "자고요", "냐고요", "라고요", "으라고요", "는다고요",
)

# Copula endings: the stem is the noun itself (이다 "to be" attaches to a
# noun), never a predicate that takes a bare "다" dictionary form. Kept as
# a literal subset of ENDINGS (so _ALL_SUFFIXES/_ENDING_SET still match
# them) but branched on separately in _lemma_candidates -- R3 item 4
# ("자리예요." -> 자리, not the nonsense "자리다").
_COPULA_ENDINGS: frozenset = frozenset({"예요", "이에요"})

# T2.4a (B2, "약은" -> 약(1급)+은, not 약다 5급): "은" is BOTH a listed
# particle (topic marker for a consonant-final noun) and a listed ending
# (past-/general-attributive, e.g. 먹은) -- a genuine ambiguity with no
# POS tagging available. The noun+particle reading must win the priority
# race here specifically, but this is NOT safely generalizable to every
# suffix that happens to share both roles: "는" is the identical kind of
# dual-role suffix, yet 가다's extremely common attributive "가는" MUST
# stay 가다, never regress to bare "가" (see `_RIEUL_ATTRIBUTIVE_
# EXCLUDED_LAST_CHARS`'s docstring for that exact, already-guarded
# collision -- confirmed by regression when this was first tried broadly:
# "가는" -> "가" and "오라고" -> "오" both silently went wrong, since
# "라고" is ALSO listed as both a particle and a quotative ending). A
# small, closed, hand-verified set -- the same trade-off this file's
# other collision tables already make -- rather than a blanket rule.
_NOUN_PARTICLE_PRIORITY_SUFFIXES: frozenset = frozenset({"은"})

# R3 item 4 ("따뜻해서" -> 따뜻하다, "서늘해서" -> 서늘하다): "해서" is
# stripped as one opaque 2-char ENDING (see ENDINGS above), which loses the
# "하" signal entirely from the remaining stem -- unlike "했어요" (where
# CONTRACTION_MAP's "했"->"하" entry fires on the 1-char remainder) there is
# no fragment left for any repair table to match. Handled directly in
# _lemma_candidates: for suf in this set, ALSO try stem + "하다" (only used
# -- per the brief's own phrasing, "when X하다 is in the lexicon" -- if that
# candidate actually resolves; harmless no-op otherwise).
#
# R7 (final-verification sweep, found while checking "말했어요" -> 말하다
# in a golden sentence): "했어요" is ALSO added here, correcting the R3
# comment above's assumption -- CONTRACTION_MAP's "했"->"하" entry only
# fires when "했" survives INTO the stem, which never happens for the
# literal 3-char ENDING "했어요" (했 is consumed BY that suffix, not left
# over after stripping it), so a bare 1-syllable remainder like "말" (from
# "말했어요") was landing on a real, unrelated, WRONG headword (말다) via
# the ordinary stem+다 fallback -- and, once R7 item 4 added an
# EARLIER-checked "stem already ends in batchim ㄹ -> also offer stem+다"
# candidate (for "만들어요" -> 만들다), that wrong "말다" reading started
# winning ahead of the correct "말하다" one reachable via the shorter
# "-어요" suffix, where CONTRACTION_MAP's "했" fragment DOES survive into
# ITS stem ("말했") and correctly fires. Adding "했어요" here restores
# "말하다" at the SAME early priority (see the item-4 addition's own
# `suf not in _HADA_FUSED_ENDINGS` guard, added at the same time) instead
# of depending on suffix-length ordering to surface it later.
_HADA_FUSED_ENDINGS: frozenset = frozenset({"해서", "해야", "했어요"})

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
    # sentences. Still hand-table entries, not covered by the R7 item 3
    # generic `_unfuse_tensed_vowel` below: that function's "stays" class
    # is scoped to vowel ㅐ only (see its table's comment) -- ㅏ (this
    # pair's vowel) was not in the R7 brief's scope, so 샀/보냈 keep their
    # own entries here rather than silently extending that table's scope.
    "샀": "사",
    "보냈": "보내",
    # R7 item 5 ("어때요?" -> 어떻다): 어떻다's ㅎ-irregular stem "어떠"
    # (see H_IRREGULAR_MAP's own "어떠"->"어떻다" entry, reached from the
    # ATTRIBUTIVE side, e.g. "어떤") fuses with -어(요) into "어때" (ㅓ+어
    # -> ㅐ), a vowel change specific to this closed ㅎ-irregular class
    # (그렇다/이렇다/저렇다 pattern the same way: 그래요/이래요/저래요) and
    # not a general contraction rule. Only 어때(요) is added here since it
    # is the one Fable's gap list actually flagged; 그래(요)/이래(요)/
    # 저래(요) are a plausible follow-up but unverified against real data,
    # so deliberately left out rather than guessed in.
    "어때": "어떻",
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
    # R7 item 4 (새로운/즐거운 attributives -> 새롭다/즐겁다): same
    # -워/-우 dual-form pattern as every entry above (the attributive
    # 관형형 -운 forms reach 새롭다/즐겁다 via `_jamo_attributive_repair`'s
    # existing batchim-strip-then-IRREGULAR_STEM_MAP lookup, e.g.
    # "새로운" -> strip ㄴ -> "새로우" -> this table -- no new code path
    # needed, only these two new rows).
    "새로워": "새롭다", "즐거워": "즐겁다",
    "새로우": "새롭다", "즐거우": "즐겁다",
    # T2.4a (B3, auditor false positives -- these nine ㅂ-irregular
    # adjectives were simply missing from the table, same -워/-우 pattern
    # as every entry above): 맵다 무겁다 가볍다 아름답다 반갑다 즐겁다
    # (already present) 귀엽다 뜨겁다 차갑다 시끄럽다.
    "매워": "맵다", "매우": "맵다",
    # Past tense "매웠어요" tense-fuses the vowel onto the batchim-ㅆ
    # syllable itself (매우+었 -> 매웠, not "매우어" -- `_unfuse_tensed_
    # vowel`'s generic ㅝ->ㅜ un-fuse would wrongly restore this to the
    # non-word "매우다"), so -- alone among this table's nine new B3
    # entries (the only one Fable's brief tests in the past tense) --
    # 매웠 needs its own direct fragment the same way 도왔 (below) does.
    "매웠": "맵다",
    "무거워": "무겁다", "무거우": "무겁다",
    "가벼워": "가볍다", "가벼우": "가볍다",
    "아름다워": "아름답다", "아름다우": "아름답다",
    "반가워": "반갑다", "반가우": "반갑다",
    "귀여워": "귀엽다", "귀여우": "귀엽다",
    "뜨거워": "뜨겁다", "뜨거우": "뜨겁다",
    "차가워": "차갑다", "차가우": "차갑다",
    "시끄러워": "시끄럽다", "시끄러우": "시끄럽다",
    # 돕다/곱다 are the two lexicalized ㅂ-irregulars that keep the
    # archaic BRIGHT-vowel harmony (오+아 -> 와, not the 우+어 -> 워
    # every other ㅂ-irregular above takes) -- 도와/도왔 do NOT fit the
    # -워/-우 pattern this table otherwise uses, so they need their own
    # literal fragments rather than falling out of that pattern. "도와주"
    # additionally covers the "Verb-아 주다" benefactive-auxiliary shape
    # (B3: "도와주세요" -> 돕다): `_auxiliary_main_verb_repair` only
    # matches a BARE-CITATION auxiliary ("도와주다"), never a further-
    # conjugated one like "도와주세요" (see that function's own
    # docstring), so the fragment left after ordinary ENDING-stripping
    # ("세요") needs this direct entry the same way every other irregular
    # fragment in this file does.
    "도와": "돕다", "도왔": "돕다", "도와주": "돕다",
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

# T2.5 (plan §3.E/§14, level_exceptions.csv's implicit lexicon rule): a
# noun X compounded directly with 없다 ("to lack/not have X" -- 문제없다,
# 상관없다, 걱정없다, ...) is graded as X's OWN grade, not X+없다's max --
# harmless simplification since 없다 itself is kiiq grade 1 (the floor of
# the whole scale), so max(X, 없다)==X always anyway. Longest-first so
# "없어요" (which itself ends in "없다"'s "없" + the -어요 ending, NOT a
# suffix of "없다" the literal 2-char string) is tried before the shorter
# "없다"/"없는" -- see `CefrLexicon._negation_compound_lookup`.
NEGATION_COMPOUND_SUFFIXES: Tuple[str, ...] = tuple(
    sorted(("없어요", "없다", "없는"), key=len, reverse=True)
)

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

# R7 item 3: generic jamo-arithmetic past-tense vowel-fusion repair, keyed
# on the FUSED (tensed) vowel index -> the un-fused vowel index to restore
# (the ㅆ batchim itself is always dropped by the caller,
# _unfuse_tensed_vowel). Generalizes the old ㅕ-only `_unfuse_tensed_yeo`
# to every fusion class actually seen in the remaining sentence-unknown-
# ratio gaps, instead of adding more one-off CONTRACTION_MAP entries per
# verb: ㅕ->ㅣ (드리다: 드렸->드리; 기다리다: 기다렸->기다리; 마시다: 마셨
# ->마시; 다니다: 다녔->다니), ㅝ->ㅜ (배우다: 배웠->배우; 멈추다: 췄->추;
# 나누다: 눴->누; 세우다: 웠->우), ㅘ->ㅗ, ㅙ/ㅚ->ㅚ (되다-like: 됐->되,
# already also in CONTRACTION_MAP -- ㅚ's own entry is a defensive no-op
# twin, since natural conjugation only ever produces the fused ㅙ form).
# ㅐ->ㅐ ("stays": 내다 -> 냈 -> 내) is NOT a fusion at all -- an ㅐ-final
# stem's vowel quality is unchanged by tensing, only the ㅆ batchim lands
# on it -- but is included as a same-vowel entry so the one code path
# below handles it too, rather than a separate special case.
_TENSED_VOWEL_UNFUSE = {6: 20, 14: 13, 9: 8, 10: 11, 11: 11, 1: 1}


def _unfuse_tensed_vowel(stem: str) -> Optional[str]:
    """If `stem`'s last character is a Hangul syllable whose batchim is
    the past-tense ㅆ marker AND whose vowel is one of
    `_TENSED_VOWEL_UNFUSE`'s keys, return `stem` with that syllable
    restored to its pre-tense form (batchim dropped, vowel un-fused per
    the table); else None. Same (code-0xAC00) jamo arithmetic as
    `expand_contractions`/`_strip_final_batchim` above."""
    if not stem:
        return None
    code = ord(stem[-1])
    if not (_S_BASE <= code < _S_BASE + _L_COUNT * _V_COUNT * _T_COUNT):
        return None
    s_index = code - _S_BASE
    lead = s_index // (_V_COUNT * _T_COUNT)
    vowel = (s_index % (_V_COUNT * _T_COUNT)) // _T_COUNT
    tail = s_index % _T_COUNT
    if tail != _TAIL_SSANGSIOT or vowel not in _TENSED_VOWEL_UNFUSE:
        return None
    target_vowel = _TENSED_VOWEL_UNFUSE[vowel]
    base_code = _S_BASE + (lead * _V_COUNT + target_vowel) * _T_COUNT
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


def _swap_final_batchim(token: str, from_tail: int, to_tail: int) -> Optional[str]:
    """R7 item 4: like `_strip_final_batchim`, but REPLACES the batchim
    with a different one instead of removing it -- needed for an ㄹ-stem's
    attributive form, where the dictionary stem's own ㄹ batchim (만들다's
    "들") is not just dropped but replaced BY the attributive ㄴ (-> "든"),
    so simply stripping "든"'s ㄴ (giving "드") loses the ㄹ for good. If
    `token`'s last character's batchim is exactly `from_tail`, return
    `token` with it swapped to `to_tail`; else None. Same jamo arithmetic
    as `_strip_final_batchim`/`expand_contractions`."""
    if not token:
        return None
    code = ord(token[-1])
    if not (_S_BASE <= code < _S_BASE + _L_COUNT * _V_COUNT * _T_COUNT):
        return None
    s_index = code - _S_BASE
    tail = s_index % _T_COUNT
    if tail != from_tail:
        return None
    base_code = code - tail + to_tail
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
    unfused_vowel = _unfuse_tensed_vowel(stem)
    if unfused_vowel is not None:
        return unfused_vowel + "다"
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
    # T2.4a (B4): the +요 variants just added to ENDINGS get the SAME
    # embedded-ㄴ-batchim post-processing (_jamo_attributive_repair /
    # _rieul_stem_attributive_repair) as their bare counterparts above --
    # e.g. "간다고요" strips "다고요" to stem "간" (된다고's own embedded-ㄴ
    # shape), which still needs the jamo-strip repair to reach "가다".
    "다고요", "자고요", "냐고요", "라고요", "으라고요", "는다고요",
})

# R7 item 9 ("입어보다" -> 입다, "먹어 봤어요" -> 먹다 [already correct --
# see below]): X-아/어/여 + one of these auxiliary verbs is graded as the
# MAIN verb, not the auxiliary. A SPACE-separated two-eojeol instance
# ("먹어 봤어요", "읽고 있어요") already resolves correctly with NO new
# code -- each eojeol is tokenized and lemmatized independently, and
# "먹어"/"읽고" already strip to 먹다/읽다 via the ordinary ENDINGS table,
# while "봤어요"/"있어요" independently resolve to 보다/있다 (real, if
# secondary, headwords in their own right) via existing mechanisms; this
# table is only needed for a SINGLE, UNSPACED eojeol where the auxiliary
# is fused directly onto the main verb.
AUXILIARY_VERBS: Tuple[str, ...] = (
    "보다", "주다", "지다", "있다", "놓다", "두다", "버리다", "내다",
)


def _auxiliary_main_verb_repair(source: str) -> Optional[str]:
    """R7 item 9: if `source` ends in one of `AUXILIARY_VERBS` in its own
    BARE CITATION form (uncontracted -- e.g. "입어보다", not a further-
    conjugated "입어봐요"), strip it and restore the remaining
    [main-verb-stem]+[아/어/여-connector] fragment the same way any other
    -아/어(요)-stripped fragment is restored: irregular-repair the WHOLE
    remainder first (catches a fused fragment like "와"/"봤" if the main
    verb itself happened to end that way), and if that fails, ALSO peel
    off a bare trailing 아/어/여 connector before falling back to plain
    concatenation -- without this second step, "입어보다"'s remainder
    "입어" would restore as the nonsense "입어다" instead of "입다" (this
    was caught empirically: `_lemma_fallback_chain`, used when
    `word_grade` is called directly on a bare headword like a vocab-list
    entry, resolves each candidate via `_base_chain`, which does NOT
    itself further lemmatize -- so a half-reduced "입어" candidate would
    silently fail there even though it eventually succeeds via the
    sentence-eojeol path's own extra recursion; producing the FULLY
    reduced form in one pass here avoids depending on that path
    difference at all). A further-conjugated auxiliary (봐요, 줬어요, …)
    is not matched here -- it is reached instead by the ordinary ENDING-
    stripping + CONTRACTION_MAP repair path already in this file (e.g.
    "봤" -> 보다 via CONTRACTION_MAP), which produces this SAME bare-
    citation "...보다" shape as an intermediate candidate that then
    recurses back through here."""
    for aux in AUXILIARY_VERBS:
        if source.endswith(aux) and len(source) > len(aux):
            remainder = source[: -len(aux)]
            repaired = _irregular_repair(remainder)
            if repaired is not None:
                return repaired
            for connector in ("아", "어", "여"):
                if remainder.endswith(connector) and len(remainder) > len(connector):
                    main_stem = remainder[: -len(connector)]
                    stem_repaired = _irregular_repair(main_stem)
                    return stem_repaired if stem_repaired is not None else main_stem + "다"
            return remainder + "다"
    return None


def _auxiliary_tensed_repair(stem: str) -> Optional[str]:
    """R7 item 9 ("편해졌어요" -> 편하다, via `stem` "편해졌" once the
    ordinary suffix loop has already stripped "-어요"): the auxiliary
    지다 ("become X") tense-fuses as 지+었->졌 (the same ㅕ+ㅆ jamo pattern
    `_unfuse_tensed_vowel` already restores for ordinary verbs), so a
    plain CONTRACTION_MAP/IRREGULAR_STEM_MAP scan never sees a "지다"
    fragment to recognise. Only 지다 is handled this way -- by far the
    most common of the eight in this fused shape ("-아/어지다" is the
    standard adjective/verb -> "become X" pattern); the other seven are
    not commonly seen tense-fused directly onto an already-ending-
    stripped stem the same way."""
    if not stem:
        return None
    unfused = _unfuse_tensed_vowel(stem)
    if unfused is None or not unfused.endswith("지") or len(unfused) < 2:
        return None
    remainder = unfused[:-1]
    repaired = _irregular_repair(remainder)
    if repaired is not None:
        return repaired
    return remainder + "다"


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


# R7 item 4 ("사는" -> 살다, "아는" -> 알다): a ㄹ-stem's PRESENT
# attributive drops the ㄹ before -는 with NO trace left behind (살다+는 ->
# 사는, not "삳는" or any other marked form) -- unlike the batchim-ㄴ case
# above, there is no batchim to jamo-decompose back into ㄹ, so a generic
# rule would have to GUESS "does this 1-syllable open stem + ㄹ + 다 spell
# a real word" for every plain "-는"-ending token. That guess is unsafe as
# a blanket rule: 가다's own "가는" (extremely common in this app's
# content -- see cloze.json) would wrongly resolve to 갈다 ("to
# replace/grind", also real), and this file's whole philosophy is to never
# guess when a real, different word is the likely result (module
# docstring, "재현율·투명성 우선"). Kept as a small, closed, hand-verified
# table instead -- the same trade-off this file already makes explicitly
# for D_IRREGULAR_MAP's 들/걸 collision and every other irregular-class
# table.
RIEUL_NEUN_MAP: Mapping[str, str] = {
    "아": "알다", "사": "살다",
}


# T2.4a (B4): a sentence-final BARE single-syllable banmal imperative
# ("레나, 여기 서.") carries no other suffix for `_lemma_candidates` to
# strip, so it generates no candidate for the intended verb at all -- and
# several of these syllables are ALSO real, unrelated, higher-grade kiiq
# headwords in their own right (bare "서" resolves via kiiq to a grade-3
# word before this fix) that would otherwise win outright. A small,
# closed table, checked at the SAME top priority as the proper-noun check
# in both `CefrLexicon.word_grade` and `_resolve_eojeol` (see their call
# sites) -- the same accepted collision-table trade-off this file already
# makes for every other closed, hand-verified table (D_IRREGULAR_MAP's
# 들/걸, RIEUL_NEUN_MAP just above, ...).
BANMAL_IMPERATIVE_MAP: Mapping[str, str] = {
    "가": "가다", "와": "오다", "서": "서다", "봐": "보다",
    "해": "하다", "자": "자다", "줘": "주다",
}


# 거/걸/걸로/이거/그거/저거/이게/그게/저게/뭘: colloquial contractions of
# 것/이것/그것/저것/뭐, all 1급 pronouns (docs/CONTENT_LEVEL_BIBLE.md §B
# "1급 밖 단어는 문화어·고유명사 하나까지만 허용", §D "문화어 1개 예외" -- a
# sentence built entirely of 1급 grammar/vocab must not get bumped to a
# higher level just because its speech is colloquial rather than written).
# A plain aliases.csv redirect row would NOT fix these: every one of these
# surface forms already resolves via its OWN (wrong-sense) kiiq/basic2023
# entry BEFORE a non-empty alias is ever consulted (word_grade's redirect-
# alias tier sits after kiiq/derived, unchanged since R3 -- see
# `word_grade`'s docstring) -- 거/이거/그거/저거/뭘 each collide with an
# unrelated, higher-grade kiiq headword of their own, 걸 collides with
# D_IRREGULAR_MAP's 걷다 stem-repair (comment above), 걸로 with a
# basic2023-only sense, and 이게 with 이다 (a grade-6 kiiq mis-hit). So this
# is a small, closed, hand-verified table checked at the SAME top priority
# as BANMAL_IMPERATIVE_MAP just above -- the accepted trade-off this file
# already uses for every other closed collision table -- rather than a
# aliases.csv row. 뭘 -> 뭐 (not 무엇): both grade 1급 already (checked
# empirically), 뭐 keeps the same colloquial register as 뭘 itself. 걸로's
# own contraction is 것 + 으로 (것 already contracted to 거/걸 before 로
# attaches); the target is still bare 것 since the trailing particle plays
# no role in grading (see `_strip_one_particle` elsewhere in this module).
#
# NOT named CONTRACTION_MAP: that name is already taken (module-level,
# defined earlier) by the UNRELATED 았/었 tense-marker fragment->root table
# ("갔"->"가" for 가다, etc.) that `_irregular_repair` and friends depend
# on -- a same-name second `CONTRACTION_MAP = {...}` here would silently
# shadow it at import time (Python module execution runs top to bottom;
# every later top-level assignment to the same name wins), breaking every
# past-tense verb this file resolves. Caught by test_all_golden_tokenizer_
# cases going from 25/25 to a wall of failures during development.
PRONOUN_CONTRACTION_MAP: Mapping[str, str] = {
    "거": "것", "걸": "것", "걸로": "것",
    "이거": "이것", "그거": "그것", "저거": "저것",
    "이게": "이것", "그게": "그것", "저게": "저것",
    "뭘": "뭐",
}


## R7 item 4: `_rieul_stem_attributive_repair` must NOT fire when `token`'s
# last character IS one of these -- both "는" (ㄴ+ㅡ+ㄴ) and "은" (ㅇ+ㅡ+ㄴ)
# coincidentally carry batchim ㄴ as part of their OWN jamo composition,
# even though they are (overwhelmingly, in this app's content) the topic
# particle or the plain present-tense ending, never a genuine fused
# attributive-ㄴ marker. Caught empirically: without this guard, "가는"
# (가다's extremely common "going", e.g. cloze.json's "가는 집이") swapped
# to "가늘" -> resolved to 가늘다 ("thin/slender") -- linguistically not
# even wrong (가늘다's own attributive genuinely can be "가는"), just far
# rarer than 가다's reading and a regression from unresolved to
# confidently-wrong for this app's actual sentences.
_RIEUL_ATTRIBUTIVE_EXCLUDED_LAST_CHARS: frozenset = frozenset({"는", "은"})


def _rieul_stem_attributive_repair(token: str) -> Optional[str]:
    """R7 item 4 ("만든" -> 만들다): an ㄹ-stem's batchim-ㄴ attributive
    form REPLACES the stem's own ㄹ batchim with ㄴ (만들 -> 만든), which
    `_jamo_attributive_repair`'s plain batchim-strip gets wrong (든 -> 드
    -> "만드다", a made-up non-word, since stripping only ever removes a
    batchim, never restores a DIFFERENT one). This tries the ㄴ->ㄹ swap
    instead (든 -> 들) -- but ONLY when `token` is at least 2 syllables
    (i.e. the swapped syllable has a preceding-syllable prefix) AND its
    last character is not itself a common batchim-ㄴ suffix (see
    `_RIEUL_ATTRIBUTIVE_EXCLUDED_LAST_CHARS`). A BARE 1-syllable batchim-ㄴ
    token is separately far too likely to be an ordinary, unrelated NOUN
    whose swapped reading also happens to be a real, common, different
    verb (checked: 돈 "money" -> 돌다 "to turn", 산 "mountain" -> 살다 "to
    live", 문 "door" -> 물다 "to bite" -- all real), so this repair is
    deliberately scoped OFF for 1-syllable tokens entirely; none of the R7
    goldens need one for this pattern (the 1-syllable "는"-suffixed
    present-attributive goldens 아는/사는 are the separate, small, curated
    RIEUL_NEUN_MAP above, for the identical collision reason, just one
    ending earlier)."""
    if len(token) < 2 or token[-1] in _RIEUL_ATTRIBUTIVE_EXCLUDED_LAST_CHARS:
        return None
    swapped = _swap_final_batchim(token, _TAIL_NIEUN, _TAIL_RIEUL)
    if swapped is None:
        return None
    return swapped + "다"


# R7 item 5 ("갈게요" -> 가다, "둘지" -> 두다): the "-(으)ㄹX" ending family
# (게요/까요/래요/지/…) is conventionally WRITTEN with a standalone jamo ㄹ
# (e.g. "-ㄹ게요"), but that jamo never appears literally in real
# conjugated text -- it is always embedded as a batchim inside the
# syllable just before X (가다 + -ㄹ게요 -> "갈게요", never "가+ㄹ+게요").
# A plain `endswith("ㄹ게요")` check (the pre-existing ENDINGS entries
# "ㄹ게요"/"ㄹ까요"/"ㄹ래요") can therefore never match real text -- verified
# directly: word_grade-via-_resolve_eojeol("갈게요") returned unknown
# before this fix, even though "먹을게요" (consonant stem, a LITERAL
# "을게요" match) already worked. Matching instead requires stripping an
# embedded ㄹ batchim from the syllable immediately before X.
_RIEUL_FUSED_ENDING_TAILS: Tuple[str, ...] = tuple(
    sorted(
        {
            "게요", "까요", "래요", "지",
            # T2.4a (B4, banmal "-을게/-ㄹ게": "갈게" -> 가다, "옮길게" ->
            # 옮기다): the bare (no politeness 요) future-intention
            # ending has the identical embedded-ㄹ-batchim shape as
            # "게요" just above, just without it. Safe to add unqualified
            # even though bare "게" is ALSO the ordinary adverbial "-게"
            # ending (짧게, 예쁘게, ...): for those, `before`'s last
            # character never carries a ㄹ batchim, so
            # `_strip_final_batchim` returns None and this function
            # falls through to that ordinary reading untouched (see this
            # function's own docstring for the len(before)==1 case,
            # unaffected either way since "짧"/"예쁘" are not in
            # `_RIEUL_FUSED_STRIP_PREFERRED_1SYL`).
            "게",
        },
        key=len, reverse=True,
    )
)

# For a 1-syllable `before` (the whole batchim-ㄹ syllable IS the entire
# remaining stem, e.g. "갈"), stripping the batchim is GENUINELY ambiguous
# with just keeping it (갈게요 is the identical surface form for BOTH 가다
# and 갈다 "to replace/grind" -- Korean's own ㄹ-stem morphology gives them
# no distinguishing mark). Checked concretely: stripping unconditionally
# would also turn 말다's "말게요"/"말지" into the wrong "마다" ("every") and
# 살다's "살게요"/"살지" into the wrong "사다" ("to buy") -- both real,
# common, WRONG words. Neither "always strip" nor "never strip" is
# universally correct; this is a small, closed, hand-verified table of the
# STRIP-preferred roots only (mirroring RIEUL_NEUN_MAP's identical
# reasoning one ending family over) -- every other 1-syllable batchim-ㄹ
# stem in this family is left to keep its batchim (the ordinary
# D_IRREGULAR_MAP-style repair or plain stem+다 fallback already handles
# those correctly, same as "들어요" -> 듣다).
_RIEUL_FUSED_STRIP_PREFERRED_1SYL: Mapping[str, str] = {
    "갈": "가", "둘": "두",
}


def _rieul_fused_ending_repair(source: str) -> Optional[str]:
    """Match one of `_RIEUL_FUSED_ENDING_TAILS` where the character just
    before the tail carries an embedded ㄹ batchim; return the repaired
    dictionary form, or None. A 2+-syllable `before` is repaired
    generically (irregular-table-checked, then plain stem+다); a
    1-syllable `before` only resolves via the small curated
    `_RIEUL_FUSED_STRIP_PREFERRED_1SYL` table (see its docstring for why a
    blanket rule is unsafe there)."""
    for tail in _RIEUL_FUSED_ENDING_TAILS:
        if source.endswith(tail) and len(source) > len(tail):
            before = source[: -len(tail)]
            if len(before) == 1:
                stripped_root = _RIEUL_FUSED_STRIP_PREFERRED_1SYL.get(before)
                if stripped_root is not None:
                    return stripped_root + "다"
                continue
            stripped = _strip_final_batchim(before, (_TAIL_RIEUL,))
            if stripped is not None:
                repaired = _irregular_repair(stripped)
                if repaired is not None:
                    return repaired
                return stripped + "다"
    return None


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


# R8 item 2 ("길이에요" -> 길, not 길다): a token ending in a CONJUGATED
# copula form (이다 "to be" attached to a noun) must offer the bare noun
# stem as a candidate BEFORE any of PASS 1's verb/adjective-conjugation
# repairs below run for that same suffix -- otherwise a stem that
# coincidentally carries a batchim ㄹ (e.g. "길" "road", stem of
# "길이에요") gets hijacked by the EARLIER "already-ㄹ-final-stem"
# heuristic (R7 item 4, added for "만들어요" -> "만들다") into the wrong,
# but real and independently resolvable, "길다" ("to be long") guess
# before the correct noun candidate is ever tried. A small, closed,
# literal list -- deliberately NOT folded into the shared ENDINGS table,
# which is also walked by mechanisms that have no business treating
# these as generic verb/adjective endings (PARTICLE-stack matching,
# clause counting via CONNECTIVE_ENDINGS, grammar-pattern compilation).
# Bare "이다" itself (the copula's own dictionary/citation form, e.g. a
# vocab-list entry "학생이다") is deliberately NOT in this list -- that is
# a HEADWORD-level concern (R8 item 4, `CefrLexicon._copula_headword_lookup`),
# not a sentence-eojeol tokenizer one.
_COPULA_ENDINGS_R8: Tuple[str, ...] = tuple(sorted({
    "이에요", "예요", "입니다", "이었어요", "였어요", "이라서", "이고",
    "이지만", "인데", "이니까", "이라고", "이야", "이죠", "이지요",
    "이네요", "입니까", "이었습니다",
    # T2.4a (B2, "문서인지" -> 문서(4급)+인지): 이다's indirect-question
    # ending -ㄴ지 ("whether/if it is") -- "문서인지" is 문서+이+ㄴ지, not
    # a compound of the noun 문서 with the SEPARATE, unrelated noun 인지
    # ("cognition"), which is what `_compound_split_lookup`'s generic
    # 2-way split fell back to before this entry existed (max(문서,인지)
    # instead of just 문서's own grade). A bare token "인지" (not longer
    # than the ending itself, i.e. the standalone noun) is unaffected --
    # `_copula_noun_stem` requires `len(token) > len(ending)`.
    "인지",
}, key=len, reverse=True))


def _copula_noun_stem(token: str) -> Optional[str]:
    """R8 item 2: the noun stem before the LONGEST matching copula ending
    in `_COPULA_ENDINGS_R8`, or None if none matches. See that table's
    docstring for why this is a dedicated check rather than a reuse of
    the shared ENDINGS table."""
    for ending in _COPULA_ENDINGS_R8:
        if token.endswith(ending) and len(token) > len(ending):
            return token[: -len(ending)]
    return None


# R8 item 3 ("알겠습니다" -> 알다): pre-final (선어말어미) markers that can
# stack BEHIND the final ending this file already strips as one suffix
# (습니다/네요/지요/어요/...), left stranded on the intermediate stem with
# no existing repair -- "알겠습니다" strips its final "습니다" down to
# "알겠", but "알겠" is not itself a headword and no irregular table
# matches it (겠 is not a conjugation fragment any of those tables know).
# 으셨/셨 (the already-fused honorific-시 + past-았/었, see the R3 item 4
# ENDINGS entries of the same spelling) are included here too so a
# further-stacked 겠/더/... behind THEM (e.g. "받으셨겠지요") also peels
# correctly -- see `_peel_prefinal_markers`.
_PREFINAL_MARKERS: Tuple[str, ...] = tuple(sorted({
    "았었", "었었", "으셨", "셨", "으시", "았", "었", "였", "겠", "더", "시",
}, key=len, reverse=True))


def _peel_prefinal_markers(stem: str, max_peels: int = 2) -> str:
    """R8 item 3: repeatedly strip the longest matching `_PREFINAL_MARKERS`
    suffix from `stem`, up to `max_peels` times (order-agnostic -- no
    fixed grammatical order is assumed, just "peel whatever matches, from
    the end, until nothing more does or the cap is hit"). Combined with
    the ONE final ending already stripped by the caller before `stem` is
    computed, this peels "up to three stacked endings" total, matching
    every golden case found (알겠습니다: 습니다+겠 = 2; 가시겠어요:
    어요+겠+시 = 3; 받으셨겠지요: 지요+겠+으셨 = 3). Returns `stem`
    unchanged (not a copy marker) if nothing matched, so callers can
    cheaply check `result != stem` to know whether any peel happened."""
    for _ in range(max_peels):
        for marker in _PREFINAL_MARKERS:
            if stem.endswith(marker) and len(stem) > len(marker):
                stem = stem[: -len(marker)]
                break
        else:
            break
    return stem


def _lemma_candidates(token: str) -> List[str]:
    """Return dictionary-form candidates for `token`, most-specific /
    highest-confidence first, ending with the token itself unchanged (last
    resort).

    Note (R8 item 1): `token` staying LAST here is deliberate and
    unchanged -- the "try the raw token as an exact headword first" fix
    lives in `CefrLexicon._resolve_eojeol` (a narrow exact-tiers-only
    check, run before this candidate list is even consulted), NOT here.
    An earlier version of that fix prepended `token` to THIS list
    instead, on the theory that `_resolve_eojeol`'s "first candidate
    whose `word_grade()` resolves wins" loop would then naturally try it
    first -- but `word_grade()` run on any string ALSO recurses through
    the lemma-fallback/numeral/multiword/basic2023/compound tiers (R7
    items 1/7/8), so the raw, least-reduced token would then almost
    ALWAYS resolve via that deep recursion, on the FIRST loop iteration,
    for essentially every conjugated word -- collapsing `_resolve_eojeol`
    onto `matched=token` (the unreduced surface form) instead of the
    properly-lemmatized candidate the rest of this file's tests depend on
    (caught by this rework's own regression run: ~85 previously-passing
    assertions on `.matched` broke instantly). See
    `_resolve_eojeol._exact_headword_lookup` for the actual fix.

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
        # R8 item 2: checked FIRST, ahead of every other PASS 1 repair --
        # see _COPULA_ENDINGS_R8's docstring for why this must win over
        # e.g. the ㄹ-final-stem heuristic further down.
        copula_stem = _copula_noun_stem(source)
        if copula_stem is not None:
            candidates.append(copula_stem)
        direct = _irregular_repair(source)
        if direct is not None:
            candidates.append(direct)
        direct_attributive = _jamo_attributive_repair(source)
        if direct_attributive is not None:
            candidates.append(direct_attributive)
        # R7 item 4 ("만든" -> 만들다): tried alongside (not instead of)
        # the plain batchim-strip above -- see _rieul_stem_attributive_
        # repair's docstring for why it is gated to >=2 syllables.
        direct_rieul_attributive = _rieul_stem_attributive_repair(source)
        if direct_rieul_attributive is not None:
            candidates.append(direct_rieul_attributive)
        # R7 item 5 ("갈게요" -> 가다, "둘지" -> 두다): see
        # _rieul_fused_ending_repair's docstring.
        rieul_fused = _rieul_fused_ending_repair(source)
        if rieul_fused is not None:
            candidates.append(rieul_fused)
        # R7 item 9 ("입어보다" -> 입다): see
        # _auxiliary_main_verb_repair's docstring.
        aux_main_verb = _auxiliary_main_verb_repair(source)
        if aux_main_verb is not None:
            candidates.append(aux_main_verb)
        for suf in _ALL_SUFFIXES:
            if suf in _ENDING_SET and source.endswith(suf) and len(source) > len(suf):
                stem = source[: -len(suf)]
                repaired = _irregular_repair(stem)
                if repaired is not None:
                    candidates.append(repaired)
                # R8 item 3 ("알겠습니다" -> 알다): peel any stacked
                # pre-final markers (겠/더/으시/았/었/였/...) left on
                # `stem` behind the final ending `suf` already stripped
                # above -- see `_peel_prefinal_markers`'s docstring.
                stacked_stem = _peel_prefinal_markers(stem)
                if stacked_stem != stem:
                    stacked_repaired = _irregular_repair(stacked_stem)
                    candidates.append(
                        stacked_repaired if stacked_repaired is not None else stacked_stem + "다"
                    )
                # R7 item 9 ("편해졌어요" -> 편하다): see
                # _auxiliary_tensed_repair's docstring.
                aux_tensed = _auxiliary_tensed_repair(stem)
                if aux_tensed is not None:
                    candidates.append(aux_tensed)
                # R7 item 4 ("만들어요" -> 만들다): a stem that ALREADY
                # ends in batchim ㄹ (e.g. "만들" after stripping "-어요")
                # is already a complete, valid regular citation stem
                # needing nothing but "다" -- but D_IRREGULAR_MAP's own
                # endswith("들") scan two lines up (see its docstring's
                # documented 들/걸 collision) fires first and returns the
                # wrong "만듣다" guess. That guess is harmless here (it
                # will not resolve in the lexicon, so `_resolve_eojeol`'s
                # loop simply moves on) as long as the correct "만들다" is
                # ALSO offered somewhere in the candidate list -- this is
                # what adds it. Guarded to skip _HADA_FUSED_ENDINGS (e.g.
                # "했어요"): those suffixes POSITIVELY confirm a X하다
                # fusion occurred, so a batchim-ㄹ stem left over from one
                # (말했어요 -> stem "말", batchim ㄹ) must NOT also get a
                # competing plain stem+다 candidate ("말다", a real,
                # different, WRONG verb) -- see _HADA_FUSED_ENDINGS'
                # updated docstring for the concrete regression this
                # caused before the guard was added.
                if (
                    suf not in _HADA_FUSED_ENDINGS
                    and stem
                    and _strip_final_batchim(stem, (_TAIL_RIEUL,)) is not None
                ):
                    candidates.append(stem + "다")
                if suf == "는" and stem in RIEUL_NEUN_MAP:
                    candidates.append(RIEUL_NEUN_MAP[stem])
                if suf in _QUOTATIVE_ENDINGS:
                    quotative_repaired = _jamo_attributive_repair(stem)
                    if quotative_repaired is not None:
                        candidates.append(quotative_repaired)
                    quotative_rieul = _rieul_stem_attributive_repair(stem)
                    if quotative_rieul is not None:
                        candidates.append(quotative_rieul)
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

    # PASS 2: generic suffix stripping (original behaviour, extended by
    # T2.4a items B2/B4 -- see the two inline comments below).
    for source in sources:
        for suf in _ALL_SUFFIXES:
            if source.endswith(suf) and len(source) > len(suf):
                stem = source[: -len(suf)]
                if suf in _COPULA_ENDINGS:
                    candidates.append(stem)
                elif suf in _ENDING_SET:
                    # T2.4a (B2): for the small, closed set of suffixes
                    # where the noun+particle reading must win -- see
                    # `_NOUN_PARTICLE_PRIORITY_SUFFIXES`'s own docstring
                    # for why this is NOT the same as "any suf in both
                    # _PARTICLE_SET and _ENDING_SET" -- offer the bare
                    # stem FIRST, ahead of the stem+다 guess.
                    if suf in _NOUN_PARTICLE_PRIORITY_SUFFIXES:
                        candidates.append(stem)
                    candidates.append(_restore_predicate(stem))
                    if suf in _QUOTATIVE_ENDINGS:
                        # T2.4a (B4, "뭐냐고요" -> 뭐, not 뭐다): a
                        # quotative also commonly reports a COPULA
                        # question ("뭐(이)냐고" = "asking what it is"),
                        # not a verb -- offer the bare stem too, AFTER
                        # the verb guess above, so it only wins when
                        # stem+다 is not itself a real word (뭐다 isn't;
                        # 가다/먹다 are, and their own jamo-repaired PASS 1
                        # candidates already resolve first regardless --
                        # see `_jamo_attributive_repair`'s call site
                        # above in PASS 1 -- so this never shadows a real
                        # verb reading).
                        candidates.append(stem)
                if suf in _PARTICLE_SET:
                    candidates.append(stem)
        # Fallback: bare trailing "요" not in the brief's ENDINGS list,
        # needed to reach CONTRACTION_MAP/IRREGULAR_STEM_MAP (see module
        # docstring / _FALLBACK_ENDING comment above).
        if source.endswith(_FALLBACK_ENDING) and len(source) > len(_FALLBACK_ENDING):
            stem = source[: -len(_FALLBACK_ENDING)]
            # T2.4a (B2/B4, "여기요" -> 여기(1급)+요; "전에요"/"후에요" ->
            # 전/후): politeness 요 also attaches directly to a bare noun
            # (no verb/adjective underneath at all) or to a noun+particle
            # ("전에" = 전 + locative 에). The bare-noun reading must be
            # tried BEFORE the stem+다 guess here (not just as a fallback
            # after it) -- "여기다" ("to regard/consider") is itself a
            # REAL, resolvable kiiq verb, so stem+다 does not merely fail
            # silently the way a made-up word would; it actively wins the
            # priority race at the wrong (much higher) grade unless the
            # noun reading is offered first. Try the stem AS-IS first
            # (protects a real multi-syllable noun that merely ENDS in a
            # particle-shaped syllable, e.g. "사과" ending in the
            # comitative particle 과, from ever reaching the particle-
            # strip below), then that SAME stem with one more trailing
            # particle stripped (`_strip_one_particle` already returns
            # its input unchanged when nothing matches, so this is a
            # no-op for any stem that doesn't end in a particle at all).
            candidates.append(stem)
            particle_stripped = _strip_one_particle(stem)
            if particle_stripped != stem:
                candidates.append(particle_stripped)
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


_QUOTATION_MARKS: str = "‘’“”'\""


def _strip_quotation_marks(text: str) -> str:
    """T2.4a (B5): remove every quotation-mark character (curly ‘’“” and
    straight '") from `text` globally, before eojeol-splitting. A
    boundary-only `.strip()` (already applied per-token afterwards by
    `_normalize_token` via TRAILING_PUNCT) can never catch a CLOSING quote
    that lands mid-eojeol -- Korean attaches a particle directly with no
    space, so `'여기 서'도 맞아?` splits on whitespace into "여기" and
    "서'도" (the closing quote sits between the verb and its particle, not
    at either end of that token). Removed outright, not replaced with a
    space, since nothing else separates the quote from its neighbours
    either."""
    for mark in _QUOTATION_MARKS:
        text = text.replace(mark, "")
    return text


def tokenize_eojeols(text: str) -> List[str]:
    """Whitespace eojeol split (quotation marks stripped first -- see
    `_strip_quotation_marks`; no other normalization -- callers strip
    remaining punctuation per-token as needed)."""
    return _strip_quotation_marks(text).split()


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

# T2.4a (B6): brand/product names -- excluded from grading (`grade=None`,
# `source='proper_noun'`) and from `SentenceProfile.unknown` the same way
# a character display name is, via the SAME `_match_proper_noun` mechanism
# (unioned into `load_character_names`'s returned set below). aliases.csv
# has no "excluded, ungraded" shape (every row there resolves to SOME
# grade -- see `_alias_lookup`: an empty `lexicon_form` means "A1
# exception", not "unranked"), so this is a dedicated set instead, per
# the brief's own fallback instruction. Documented in the F9 exception
# table (docs/data/level_bible/F9_exceptions.md, "브랜드/고유명사" section)
# alongside every other grade-list-independent exception category.
PROPER_NOUN_EXCLUSIONS: FrozenSet[str] = frozenset({
    "카카오톡", "카톡", "네이버", "인스타그램", "유튜브", "쿠팡", "배민",
    "지도앱",
})


def load_character_names(root: Path = REPO) -> FrozenSet[str]:
    """Every `recurringCharacters[].displayNames.ko` name from
    tools/content_factory/canonical_scenarios/character_profiles.json,
    unioned with EXTRA_PROPER_NOUNS (R3 item 5) and PROPER_NOUN_EXCLUSIONS
    (T2.4a item B6 -- brand/product names). Falls back to just those two
    fixed sets if the profiles file is missing or malformed -- proper-noun
    exclusion degrading gracefully is preferable to CefrLexicon.load()
    failing outright over an unrelated content-factory asset it does not
    otherwise depend on."""
    names = set(EXTRA_PROPER_NOUNS) | set(PROPER_NOUN_EXCLUSIONS)
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
# Numerals (R7 item 7)
# ---------------------------------------------------------------------------

# Sino-Korean numeral characters (한자어 수사): a token made ENTIRELY of
# these (십오 "15", 이십 "20", 백오십 "150") is a compound number, not a
# separate dictionary headword in either source list -- checked directly
# via the character SET, not a fixed word list, since sino compounds are
# productively formed (any digit-string-like combination is valid).
SINO_NUMERAL_CHARS: FrozenSet[str] = frozenset("영일이삼사오육칠팔구십백천만억")

# Native Korean numerals (고유어 수사) up to 99, plus the four determiner
# forms (한/두/세/네/스무) used directly before a counter word (두 개, 세
# 명, …) -- a CLOSED list (unlike the sino side, native numerals are not
# productively combined beyond this set in ordinary usage).
NATIVE_NUMERAL_WORDS: FrozenSet[str] = frozenset({
    "하나", "둘", "셋", "넷", "다섯", "여섯", "일곱", "여덟", "아홉", "열",
    "스물", "서른", "마흔", "쉰", "예순", "일흔", "여든", "아흔",
    "한", "두", "세", "네", "스무",
})

_ASCII_DIGITS_RE = re.compile(r"^[0-9]+$")

# T2.4a (B6): a token containing any Latin letter or ASCII digit (QR, 5G,
# a stray "3층" mixed with a Korean counter, ...) is excluded from grading
# the same way a proper noun or a bare-digit-string numeral is --
# `grade=None`, never reported in `SentenceProfile.unknown`. This file's
# grade lists are Korean-headword-only, so such a token was never going
# to resolve either way; the point is keeping it out of `unknown`, not
# finding it a grade. Broader than `_ASCII_DIGITS_RE` (which only matches
# a token that is ENTIRELY digits) -- checked for containment, not a full
# match, since "QR" itself has no digits at all.
_LATIN_OR_DIGIT_RE = re.compile(r"[A-Za-z0-9]")


def _is_latin_or_digit_token(token: str) -> bool:
    # A token that is PURELY ASCII digits ("3", "10") is excluded via the
    # pre-existing `_numeral_grade`/source='number' tier instead (checked
    # later, after kiiq/alias) -- that distinction is load-bearing for
    # `sentence_profile`'s "known-but-deliberately-ungraded" bookkeeping
    # even though the OUTCOME (excluded, never `unknown`) is identical
    # either way, so a pure-digit string must not be intercepted here.
    if _ASCII_DIGITS_RE.match(token):
        return False
    return bool(_LATIN_OR_DIGIT_RE.search(token))


def _numeral_grade(token: str) -> Optional["WordGrade"]:
    """R7 item 7: classify a numeral token, or return None (not a numeral
    -- callers fall through to the ordinary lookup chain). Three cases:

    * Pure ASCII digits ("3", "10") -> `source='number'`, `grade=None`:
      known-but-deliberately-ungraded. `sentence_profile` excludes these
      from `unknown` (same treatment as a proper noun) rather than
      reporting a digit string as an unresolved vocabulary gap.
    * An exact native-numeral word (하나, 두, …) -> grade 1, 'numeral'.
    * A token made ENTIRELY of `SINO_NUMERAL_CHARS`, AT LEAST 2 characters
      long -> grade 1, 'numeral'. The length-2 floor is a deliberate,
      evidence-based guard: a BARE 1-character sino digit is exactly the
      shape a real noun collapses to after this file's ordinary particle-
      stripping (사과 "apple" strips its "과" comitative particle down to
      "사", which IS the sino digit "4") -- caught concretely by this
      rework's own regression check (see the callers' docstrings for how
      this function is now ordered AFTER kiiq/derived/alias in
      `word_grade`, and only checked as a last-resort fallback -- not a
      short-circuit -- in `_resolve_eojeol`, for the identical reason:
      the equally-real collision between 네 "four" (a legitimate 1-char
      NATIVE numeral, exempt from this length floor since it is a closed,
      verified word list rather than a character class) and 네 "yes").

    Both numeral cases are grade 1 / 'high' confidence (via
    `_CONFIDENCE_BY_SOURCE`): Sejong 1 introduces both counting systems
    immediately, so neither is a meaningful vocabulary gap at any level."""
    if not token:
        return None
    if _ASCII_DIGITS_RE.match(token):
        return WordGrade(None, None, "number", token)
    if token in NATIVE_NUMERAL_WORDS:
        return WordGrade(1, "A1", "numeral", token)
    if len(token) >= 2 and all(ch in SINO_NUMERAL_CHARS for ch in token):
        return WordGrade(1, "A1", "numeral", token)
    return None


# ---------------------------------------------------------------------------
# Compounds / prefixes / nominaliser (R7 item 8)
# ---------------------------------------------------------------------------

# 부정/재귀 prefix characters that shift a resolvable root's grade UP by
# one (base grade + 1, capped at 6): 불확실("uncertain") is harder than its
# root 확실("certain"), 재검토("re-review") is (marginally) harder than
# 검토("review"), etc. NOT the same mechanism as DERIVED_SUFFIXES (which
# strips a suffix and takes the ROOT's own grade unchanged) -- these are
# PREFIXES, and the prefixed form is treated as one step harder, not
# grade-equivalent to its root.
COMPOUND_PREFIX_CHARS: FrozenSet[str] = frozenset("불비미재무초최신구")

_TAIL_MIEUM = 16  # ㅁ (nominalizer batchim, e.g. "돌봄")


def _nominalizer_repair(token: str) -> Optional[str]:
    """R7 item 8 ("돌봄" -> 돌보다): -음/-ㅁ nominalizes a verb/adjective
    stem. A CONSONANT-final stem's nominalizer is the literal 2-character
    "음" (already an ENDINGS entry, handled by the ordinary suffix-
    stripping loop), but a VOWEL-final stem's -ㅁ embeds directly as a
    batchim (돌보 + ㅁ -> 돌봄) -- the same "standalone jamo never appears
    in real text" issue as the "-(으)ㄹX" ending family (see
    `_rieul_fused_ending_repair`'s docstring). Gated to `len(token) >= 2`
    for the identical reason `_rieul_stem_attributive_repair` is: a BARE
    1-syllable ㅁ-batchim token is far too likely to be an ordinary,
    unrelated noun whose stripped reading also happens to be a real,
    common, different verb (checked: 봄 "spring" -> 보다 "to see", 꿈
    "dream" -> 꾸다 "to dream" -- itself not wrong, but 힘 "strength" ->
    "히다" is not even a real word, illustrating the guess is unreliable
    either way) -- and this repair is only ever consulted as a LAST-RESORT
    fallback (see `CefrLexicon._compound_fallback_chain`), tried after
    kiiq/basic2023 already had the chance to resolve the whole token
    directly, so an already-common 1-syllable word like 봄 or 그림 never
    even reaches here in the first place."""
    if len(token) < 2:
        return None
    stripped = _strip_final_batchim(token, (_TAIL_MIEUM,))
    if stripped is None:
        return None
    repaired = _irregular_repair(stripped)
    if repaired is not None:
        return repaired
    return stripped + "다"


# ---------------------------------------------------------------------------
# Dataclasses (plan §4.1 interface, extended under R3 -- see module docstring)
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class WordGrade:
    grade: Optional[int]
    cefr: Optional[str]
    source: Optional[str]  # 'kiiq'|'basic2023'|'alias'|'derived'|'proper_noun'|None
    matched: str
    # R7 item 2: per-instance override, used ONLY when a single `source`
    # value (e.g. 'derived') can legitimately carry two different
    # confidence levels depending on the specific resolution -- see
    # CefrLexicon._kiiq_derived_chain's docstring. None (the default) means
    # "no override", i.e. every pre-R7 construction site is unaffected and
    # confidence still comes purely from `source`.
    confidence_override: Optional[str] = None

    @property
    def confidence(self) -> Optional[str]:
        """'high' for kiiq/derived/alias, 'low' for basic2023, else None
        (R3 item 2), UNLESS `confidence_override` is set (R7 item 2).
        Derived from `source` rather than stored, so every WordGrade
        constructed anywhere in this module reports it correctly with no
        propagation step to forget."""
        if self.grade is None:
            return None
        if self.confidence_override is not None:
            return self.confidence_override
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
    # Bible §B "1급 밖 단어는 문화어·고유명사 하나까지만 허용" / §D "문화어 1개
    # 예외" (docs/CONTENT_LEVEL_BIBLE.md): the single highest-grade token,
    # excluded from `lexical_p90` below when the sentence has >=3 graded
    # content tokens -- (matched headword, its own grade), or None when the
    # sentence is too short for the allowance to apply. Never touches
    # grammar_max or any individual WordGrade/PhraseGrade -- see
    # sentence_profile()'s docstring.
    allowance: Optional[Tuple[str, int]] = None


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


def load_level_exceptions(root: Path = REPO) -> List[dict]:
    """T2.5: read tools/content_factory/lexicon/level_exceptions.csv
    (header ``category,headword,allowed_level,note``). Used both by
    :meth:`CefrLexicon.load` and by ``tool/build_level_bible_tables.py``'s
    F9 "레벨 예외표(등급 상한)" section, so both consumers stay in sync off
    the one CSV."""
    return _read_csv(root / "tools" / "content_factory" / "lexicon" / "level_exceptions.csv")


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
        exceptions: Mapping[str, Tuple[int, str, str]] = None,
    ) -> None:
        self._kiiq_any = kiiq_any
        self._basic_any = basic_any
        self._aliases = aliases
        self._proper_nouns = proper_nouns
        # T2.5: headword (single- or multi-word, exactly as spelled in
        # level_exceptions.csv) -> (allowed_grade, category, note).
        self._exceptions: Mapping[str, Tuple[int, str, str]] = exceptions or {}

    # -- loading ------------------------------------------------------

    @classmethod
    def load(cls, root: Path = REPO) -> "CefrLexicon":
        lex_dir = root / "tools" / "content_factory" / "lexicon"
        kiiq_rows = _read_csv(lex_dir / "nikl_kiiq_2017_vocab.csv")
        basic_rows = _read_csv(lex_dir / "nikl_basic_2023_vocab.csv")
        alias_rows = _read_csv(lex_dir / "aliases.csv")
        proper_nouns = load_character_names(root)
        exception_rows = load_level_exceptions(root)
        return cls.from_rows(kiiq_rows, basic_rows, alias_rows, proper_nouns, exception_rows)

    @classmethod
    def from_rows(
        cls,
        kiiq_rows: Iterable[Mapping[str, str]],
        basic_rows: Iterable[Mapping[str, str]],
        alias_rows: Iterable[Mapping[str, str]],
        proper_nouns: Iterable[str] = (),
        exception_rows: Iterable[Mapping[str, str]] = (),
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

        # T2.5: headword -> (allowed_grade, category, note). `headword` is
        # used verbatim as spelled in the CSV (single word or, for
        # fixed_expression rows like "새해 복 많이 받으세요", a full
        # space-joined phrase) -- see `_exception_lookup`/`phrase_grade`
        # for where each shape is matched.
        exceptions: dict = {}
        for row in exception_rows:
            headword = row["headword"].strip()
            allowed_grade = CEFR_TO_GRADE[row["allowed_level"].strip()]
            category = (row.get("category") or "").strip()
            note = (row.get("note") or "").strip()
            exceptions[headword] = (allowed_grade, category, note)

        return cls(kiiq_any, basic_any, aliases, frozenset(proper_nouns), exceptions)

    # -- internal lookup tiers -----------------------------------------

    def _derived_lookup(self, word: str) -> Optional[Tuple[int, str, str]]:
        for suf in DERIVED_SUFFIXES:
            if word.endswith(suf) and len(word) > len(suf):
                root = word[: -len(suf)]
                rows = self._kiiq_any.get(root)
                if rows:
                    # sorted ascending -> minimum; suffix returned too (R7
                    # item 2 needs it to scope the basic2023-min check to
                    # X하다/X되다 only -- see _kiiq_derived_chain).
                    return rows[0].grade, root, suf
        return None

    def _basic2023_lookup(self, word: str) -> Optional[int]:
        grades = self._basic_any.get(word)
        if not grades:
            return None
        return BASIC2023_TO_GRADE[min(grades)]

    def _exception_lookup(self, word: str) -> Optional[WordGrade]:
        """T2.5: exact-string match against ``level_exceptions.csv``
        (headword exactly as spelled there -- a single word already in its
        dictionary/citation form, e.g. 환승, 결제하다, or a full
        space-joined fixed expression, e.g. "새해 복 많이 받으세요"). This
        is a Fable RULING, not merely a fallback signal -- it wins
        unconditionally over kiiq/basic2023/derived for this exact
        headword (same precedent as aliases.csv's empty-lexicon_form A1
        exception, R7 item 10: "override whatever the grade lists say for
        this EXACT surface form"), which is why it is checked FIRST in
        `_kiiq_derived_chain` rather than computed as a min/ceiling against
        whatever kiiq/basic2023 would otherwise have said. Returns None
        (not a WordGrade) when `word` is not a listed headword, so callers
        can tell "no ruling applies" apart from "ruling gives grade=None"
        (the latter never actually occurs -- every CSV row has a real
        allowed_level -- but the Optional keeps the contract honest)."""
        entry = self._exceptions.get(word)
        if entry is None:
            return None
        allowed_grade, _category, _note = entry
        return WordGrade(allowed_grade, GRADE_TO_CEFR[allowed_grade], "exception", word)

    def _negation_compound_lookup(self, word: str) -> WordGrade:
        """T2.5 lexicon rule: `X없어요`/`X없다`/`X없는` -> X's own grade,
        when X (the noun with the suffix stripped) independently resolves
        via `_base_chain` (kiiq/derived, then basic2023 -- "graded noun"
        means either source, not kiiq-only). Mirrors `_derived_lookup`'s
        shape (strip a closed suffix, look up the root) but reuses
        `_base_chain` rather than a bare kiiq dict hit, since X is
        typically an ordinary noun that may only be basic2023-listed (see
        NEGATION_COMPOUND_SUFFIXES' own comment for why 없다's OWN grade,
        already the floor of the scale, never needs to be separately
        consulted here). source='derived' -- the same tag `_derived_lookup`
        uses for an identical "strip a productive suffix, grade the root"
        shape, so it gets the same 'high'-confidence treatment. Returns a
        grade=None WordGrade (never None itself) when no suffix matches or
        the stripped root doesn't resolve, so callers can chain it the same
        way as `_derived_lookup`'s sibling checks."""
        for suf in NEGATION_COMPOUND_SUFFIXES:
            if word.endswith(suf) and len(word) > len(suf):
                root = word[: -len(suf)]
                wg = self._base_chain(root)
                if wg.grade is not None:
                    return WordGrade(wg.grade, wg.cefr, "derived", root, wg.confidence_override)
        return WordGrade(None, None, None, word)

    def _kiiq_derived_chain(self, word: str) -> WordGrade:
        """Steps 1-2 (plan §3.C.1, R3-revised): kiiq (homograph-insensitive,
        minimum grade across every row sharing the headword — R3 item 1),
        then derived. No aliases, no multiword, no basic2023 fallback.

        R7 item 2: a derived X하다/X되다 root can carry a sense (e.g. 사양
        "specification", kiiq grade 6) unrelated to the one actually meant
        by the full X하다/X되다 form (사양하다 "to decline/refuse politely")
        -- caught by cross-checking against basic2023's entry for the FULL
        form when one exists: the reported grade becomes the min of the
        two, and confidence is downgraded to 'medium' (via
        WordGrade.confidence_override, not source -- this file's normal
        confidence-by-source table doesn't distinguish two derived results
        of different reliability) whenever the two disagree by >=2 grades
        or the root itself is ambiguous (more than one kiiq row) -- either
        signal means the derived sense is not confidently the one meant.
        Scoped to 하다/되다 only (the brief's own scope; 스럽다/적/히 roots
        are not cross-checked).

        T2.5: an exact `level_exceptions.csv` hit is checked FIRST (highest
        priority -- see `_exception_lookup`), and the X없다 negation-
        compound rule is tried LAST (after plain kiiq and DERIVED_SUFFIXES
        derivation have both failed -- see `_negation_compound_lookup`).
        This single method is called from `word_grade`, from
        `_exact_headword_lookup` (the narrow chain `_resolve_eojeol` uses
        first, i.e. what `phrase_grade`/`sentence_profile` actually reach
        per eojeol), and from `_base_chain` (hence every alias/multiword/
        prefix/compound-split consumer too) -- so hooking both new tiers
        in here, rather than separately in each caller, gives every
        consumer T2.5 coverage in one place."""
        exception = self._exception_lookup(word)
        if exception is not None:
            return exception
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
            grade, root, suf = derived
            confidence_override = None
            if suf in ("하다", "되다"):
                basic_grade = self._basic2023_lookup(word)
                if basic_grade is not None:
                    root_rows = self._kiiq_any.get(root) or ()
                    disagree = abs(grade - basic_grade) >= 2
                    ambiguous_root = len(root_rows) > 1
                    grade = min(grade, basic_grade)
                    if disagree or ambiguous_root:
                        confidence_override = "medium"
            return WordGrade(
                grade, GRADE_TO_CEFR[grade], "derived", root, confidence_override
            )
        negation = self._negation_compound_lookup(word)
        if negation.grade is not None:
            return negation
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
        # R7 item 2: propagate confidence_override too (unlike
        # _alias_lookup, multiword does NOT force source='multiword' --
        # it keeps best.source verbatim, so a 'medium'-confidence derived
        # sub-word must keep reporting 'medium' here, not silently
        # upgrade to 'high' by dropping the override).
        return WordGrade(best.grade, best.cefr, best.source, best.matched, best.confidence_override)

    def _lemma_fallback_chain(self, word: str) -> WordGrade:
        """R7 item 1: a bare headword lookup (word_grade called directly,
        not via _resolve_eojeol) may itself be an inflected/honorific
        surface form -- e.g. a vocab-list entry spelled "고마워요" or
        "감사합니다" rather than the dictionary form -- so once kiiq/
        derived/alias/multiword have all failed, retry with the SAME
        lemma-candidate resolution already used for sentence eojeols
        (`_lemma_candidates`) before giving up to the basic2023 fallback.
        Each candidate is resolved via `_base_chain` (kiiq/derived then
        basic2023), not the full `word_grade` chain -- the same
        already-gated, no-recursion-risk reason `_alias_lookup`/
        `_multiword_lookup` use `_base_chain` (see their docstrings): by
        construction `_lemma_candidates` always appends `word` itself as
        the last-resort candidate, and re-entering `word_grade` with the
        exact input that reached this tier would recurse forever, so that
        identity candidate is skipped outright instead."""
        for candidate in _lemma_candidates(word):
            if candidate == word:
                continue
            wg = self._base_chain(candidate)
            if wg.grade is not None:
                return wg
            # T2.4a (B4, "드시라고요" -> 드시다): a lemma candidate can
            # ITSELF only be resolvable via aliases.csv (e.g. "드시다",
            # which is neither a kiiq nor a basic2023 headword -- see
            # that alias row's own note) -- `_base_chain` alone never
            # checks aliases (by design, to stay non-recursive; see this
            # method's own docstring above), so check the alias table
            # directly here too. Still non-recursive: this is the exact
            # same lookup `_exact_headword_lookup`/`word_grade` already
            # do for a bare alias hit, not a call back into the full
            # `word_grade` chain -- `_alias_lookup` itself only ever
            # recurses through the already-safe `_base_chain`.
            if candidate in self._aliases:
                alias_wg = self._alias_lookup(candidate)
                if alias_wg.grade is not None:
                    return alias_wg
        return WordGrade(None, None, None, word)

    def _prefix_lookup(self, word: str) -> WordGrade:
        """R7 item 8: `word[0]` in COMPOUND_PREFIX_CHARS + a resolvable
        root -> root's grade + 1 (capped at 6), source='compound',
        confidence='medium'. The root is tried as-is, then with "하다"
        appended (many Korean adjectival/nominal roots are only
        headword-listed in their X하다 form -- e.g. 확실하다 is a kiiq
        headword but bare 확실 is not -- see _base_chain; this mirrors
        that same gap one level up), and -- since the nominal "-성"
        ("-ness/-ity") suffix is common on these SAME roots and is not
        itself in DERIVED_SUFFIXES -- with a trailing 성 additionally
        stripped first when present (불확실성 -> try 확실성, 확실성하다
        [neither real] -> try 확실 [not a headword bare], 확실하다
        [kiiq grade 4] -> resolves)."""
        if len(word) < 2 or word[0] not in COMPOUND_PREFIX_CHARS:
            return WordGrade(None, None, None, word)
        root = word[1:]
        root_candidates = [root, root + "하다"]
        if root.endswith("성") and len(root) > 1:
            bare = root[:-1]
            root_candidates.extend([bare, bare + "하다"])
        for candidate in root_candidates:
            wg = self._base_chain(candidate)
            if wg.grade is not None:
                grade = min(wg.grade + 1, 6)
                return WordGrade(grade, GRADE_TO_CEFR[grade], "compound", candidate, "medium")
        return WordGrade(None, None, None, word)

    def _compound_split_lookup(self, word: str) -> WordGrade:
        """R7 item 8: for an otherwise-unresolved token of >=3 Hangul
        syllables, try every 2-way split (word[:i], word[i:]) where BOTH
        parts independently resolve via `_base_chain`. Among all valid
        splits, pick the one that MAXIMISES the shorter part's length
        (the most balanced split -- 신용카드 splits 2+2 "신용"/"카드", not
        1+3), breaking a tie (both splits equally balanced) by the LOWER
        resulting grade -- checked concretely against 조회수, which splits
        both as 조/회수 (조 grade 4, 회수 grade 6 -- max 6) and 조회/수
        (조회 grade 5, 수 grade 2 -- max 5), equally balanced at
        shorter-part length 1; the grade-5 (조회+수, the semantically
        intended split -- "view count") reading is preferred over the
        grade-6 one purely by this tie-break, not by any semantic check
        (none is available here). grade = max(parts), source='compound',
        confidence='medium' (two independently-correct parts don't
        guarantee the compound's actual, possibly-drifted meaning)."""
        if len(word) < 3 or len(_HANGUL_SYLLABLE_RE.findall(word)) != len(word):
            return WordGrade(None, None, None, word)
        best: Optional[Tuple[str, str, int, int]] = None  # left, right, shorter_len, grade
        for i in range(1, len(word)):
            left, right = word[:i], word[i:]
            left_wg = self._base_chain(left)
            if left_wg.grade is None:
                continue
            right_wg = self._base_chain(right)
            if right_wg.grade is None:
                continue
            shorter_len = min(len(left), len(right))
            grade = max(left_wg.grade, right_wg.grade)
            if (
                best is None
                or shorter_len > best[2]
                or (shorter_len == best[2] and grade < best[3])
            ):
                best = (left, right, shorter_len, grade)
        if best is None:
            return WordGrade(None, None, None, word)
        left, right, _shorter_len, grade = best
        return WordGrade(
            grade, GRADE_TO_CEFR[grade], "compound", "%s+%s" % (left, right), "medium"
        )

    def _compound_fallback_chain(self, word: str) -> WordGrade:
        """R7 item 8: the combined last-resort tier tried (in `word_grade`)
        only after every other tier -- including basic2023 -- has already
        failed to resolve `word` as a whole. Order: nominaliser repair
        (`_nominalizer_repair`, cheapest and most specific -- only fires
        on an embedded ㅁ batchim), then the prefix table, then the
        generic 2-way compound split (broadest, tried last).

        Guarded to skip any `word` ending in "다": every item 8 golden is
        a NOUN (신용카드, 조회수, 확실성, …), and `word_grade` is invoked
        recursively for many SPECULATIVE candidate strings generated
        elsewhere in this file's suffix-stripping machinery (via
        `_resolve_eojeol`'s candidate loop) -- strings like "서늘다"
        (a failed -하다 restoration byproduct of "서늘해서"), "만듣다"
        (D_IRREGULAR_MAP's own documented 들/걸 false-positive on
        "만들어요"), or "무다" (an ordinary batchim-ㄴ noun-repair
        byproduct of "문") were previously harmless nonsense specifically
        BECAUSE they never resolved -- until the prefix table and
        compound split, being general decomposition mechanisms, started
        finding a spurious-but-real split for them too (checked
        concretely: all three regressed real tests before this guard was
        added). A well-formed verb/adjective dictionary form always ends
        in "다"; a compound NOUN never does -- so this guard closes that
        entire leak in one place without narrowing the six goldens above,
        none of which end in "다"."""
        if word.endswith("다"):
            return WordGrade(None, None, None, word)
        nominalized_root = _nominalizer_repair(word)
        if nominalized_root is not None:
            wg = self._base_chain(nominalized_root)
            if wg.grade is not None:
                return wg
        prefixed = self._prefix_lookup(word)
        if prefixed.grade is not None:
            return prefixed
        return self._compound_split_lookup(word)

    def _copula_headword_lookup(self, word: str) -> WordGrade:
        """R8 item 4 ("효율적이다" -> 효율적, B2; "학생이다" -> 학생, A1):
        a headword spelled in the copula's OWN citation/dictionary form
        (stem + 이다, e.g. a vocab-list entry for an X적이다-style formal
        adjective) is compositional -- 이다 ("to be") attaches to ANY
        noun, so it is essentially never itself a separate kiiq/
        basic2023 headword, even though the stem almost always is. Two
        checks, in order:

        1. `word`'s stem (word[:-2], dropping the literal "이다") IS
           itself a lexicon headword (kiiq/derived/basic2023, via
           `_base_chain`) -> use it as-is: source='derived' (reusing the
           existing X하다/X되다-derivation source tag -- same
           'high'-confidence treatment via `_CONFIDENCE_BY_SOURCE`, since
           this is the exact same "strip a compositional suffix, grade
           the root" shape), SAME grade as the stem's own. Verified
           against the real lexicon: 효율적/적극적/객관적/합리적 are direct
           kiiq headwords (grade 4/B2), 추상적 is kiiq grade 6/C2, and
           서정적 -- absent from kiiq -- is a basic2023 headword (grade 5 ->
           C2/6) -- `_base_chain` covers both sources uniformly.
        2. Only when (1) fails AND the stem itself ends in "적" (the
           common formal-register X적 adjective/noun pattern -- 효율적,
           객관적, 추상적, …): strip THAT "적" too and grade the further-
           reduced root. This extends coverage beyond what (1) already
           gets for free via `_kiiq_derived_chain`'s own internal
           DERIVED_SUFFIXES stripping (which only ever checks kiiq for
           the 적-stripped root, never basic2023) -- so this second check
           additionally covers a root that is basic2023-only. Reported at
           `confidence_override='medium'` (one compositional strip
           deeper than (1), a strictly weaker signal) rather than the
           'high' a direct stem hit gets.

        Inserted in `word_grade` BEFORE the basic2023 fallback tier (the
        brief's own ordering): a fused "...이다" spelling is unlikely to
        be independently listed in the general-literacy basic2023 list,
        so the stem's own grade is the meaningful signal to try first."""
        if not word.endswith("이다") or len(word) <= 2:
            return WordGrade(None, None, None, word)
        stem = word[:-2]
        stem_grade = self._base_chain(stem)
        if stem_grade.grade is not None:
            return WordGrade(stem_grade.grade, stem_grade.cefr, "derived", stem)
        if stem.endswith("적") and len(stem) > 1:
            root = stem[:-1]
            root_grade = self._base_chain(root)
            if root_grade.grade is not None:
                return WordGrade(root_grade.grade, root_grade.cefr, "derived", root, "medium")
        return WordGrade(None, None, None, word)

    def _exact_headword_lookup(self, word: str) -> WordGrade:
        """R8 item 1 (Fable direct-read finding): true EXACT-headword
        tiers only -- kiiq exact/homograph-min, kiiq-derived-suffix, and
        both alias forms (empty-lexicon_form A1 exception, and redirect) --
        mirroring the first few steps of `word_grade` verbatim, but
        DELIBERATELY STOPPING before its numeral/multiword/lemma-fallback/
        basic2023/compound tiers (R7 items 1/7/8). Those later tiers all
        do their OWN further lemmatization/guessing, so calling the FULL
        `word_grade` here instead (as an earlier version of this fix did)
        would make the raw, least-reduced token resolve via deep
        recursion on almost every call -- see `_lemma_candidates`'s
        docstring for the regression that caused. Used ONLY by
        `_resolve_eojeol`, to answer "is `token` itself, verbatim, a real
        dictionary headword" before any particle/ending stripping is even
        attempted."""
        normalized = _normalize_token(word)
        if not normalized:
            return WordGrade(None, None, None, word)
        alias_entry = self._aliases.get(normalized)
        if alias_entry is not None and alias_entry[0] is None:
            return WordGrade(1, "A1", "alias", normalized)
        kd = self._kiiq_derived_chain(normalized)
        if kd.grade is not None:
            return kd
        if normalized in self._aliases:
            return self._alias_lookup(normalized)
        return WordGrade(None, None, None, normalized)

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
        order given by plan §3.C.1 (R3-revised, R7 item 1 inserts the
        lemma-fallback tier; R7 item 7 inserts the numeral tier; R7 item 8
        inserts the compound/prefix/nominaliser tier): proper noun ->
        kiiq (homograph-insensitive minimum) -> derived -> aliases.csv ->
        numeral -> multiword -> lemma-candidate fallback -> basic2023 ->
        compound/prefix/nominaliser -> unknown."""
        normalized = _normalize_token(word)
        if not normalized:
            return WordGrade(None, None, None, word)
        proper = self._match_proper_noun(normalized)
        if proper is not None:
            return WordGrade(None, None, "proper_noun", proper)
        # T2.4a (B6): checked at the same early, unconditional priority as
        # the proper-noun check just above -- see `_is_latin_or_digit_token`.
        if _is_latin_or_digit_token(normalized):
            return WordGrade(None, None, "latin", normalized)
        # T2.4a (B4): a bare sentence-final banmal imperative (가/와/서/
        # 봐/해/자/줘) -- checked here too (not just in `_resolve_eojeol`)
        # because this method is what the candidate-resolution loop in
        # BOTH `_resolve_eojeol` and `_multiword_lookup`/`_lemma_fallback_
        # chain actually calls for each reduced candidate (e.g. "서" once
        # "서도" has had its "도" particle stripped) -- see
        # `BANMAL_IMPERATIVE_MAP`'s own docstring for why this must win
        # over several of these syllables' real, unrelated kiiq senses.
        banmal = BANMAL_IMPERATIVE_MAP.get(normalized)
        if banmal is not None:
            return self.word_grade(banmal)
        # Bible §B/§D contraction allowance -- see PRONOUN_CONTRACTION_MAP's
        # own docstring for why this cannot be a plain aliases.csv redirect.
        pronoun_contraction = PRONOUN_CONTRACTION_MAP.get(normalized)
        if pronoun_contraction is not None:
            return self.word_grade(pronoun_contraction)
        alias_entry = self._aliases.get(normalized)
        if alias_entry is not None and alias_entry[0] is None:
            # R7 item 10: an empty-lexicon_form alias ("A1 exception",
            # e.g. 화이팅/진지/약주/드시다) is checked BEFORE kiiq -- its
            # whole purpose is to override whatever the grade lists say
            # for this EXACT surface form, including a WRONG-REGISTER
            # direct kiiq hit (진지 is listed in kiiq only as a grade-5/C1
            # homograph of an unrelated, higher-register sense -- see
            # this module's own docstring). A non-empty ("redirect", e.g.
            # 엄마 -> 어머니) alias keeps its EXISTING position after
            # kiiq/derived, unchanged from R3 -- redirect aliases were
            # not part of this item's scope, and reordering them too was
            # not checked against the rest of aliases.csv.
            return WordGrade(1, "A1", "alias", normalized)
        kd = self._kiiq_derived_chain(normalized)
        if kd.grade is not None:
            return kd
        if normalized in self._aliases:
            # Once a word is a known alias key, aliases.csv is authoritative
            # (even a None-grade alias resolution reports source='alias'
            # rather than silently falling through to basic2023 on the
            # un-aliased original spelling).
            return self._alias_lookup(normalized)
        # R7 item 7: checked AFTER kiiq/derived/alias (not before -- see
        # _numeral_grade's docstring for the concrete collision this
        # ordering avoids, e.g. 네 "yes" is a real kiiq/alias entry that
        # must win over the native numeral 네 "four"). Compound sino
        # numerals (십오, 이십, …) are not separate kiiq/basic2023
        # headwords anyway, so nothing is lost by checking them this late.
        numeral = _numeral_grade(normalized)
        if numeral is not None:
            return numeral
        if " " in normalized:
            multiword_result = self._multiword_lookup(normalized)
            if multiword_result.grade is not None:
                return multiword_result
        lemma_fb = self._lemma_fallback_chain(normalized)
        if lemma_fb.grade is not None:
            return lemma_fb
        # R8 item 4: X이다/X적이다 headword-level copula-stem resolution,
        # inserted BEFORE basic2023 (the brief's own ordering) -- see
        # `_copula_headword_lookup`'s docstring.
        copula_headword = self._copula_headword_lookup(normalized)
        if copula_headword.grade is not None:
            return copula_headword
        fb = self._fallback_chain(normalized)
        if fb.grade is not None:
            return fb
        # R7 item 8: true last resort -- nominaliser repair / prefix table
        # / generic compound split, tried only once NOTHING else (kiiq,
        # derived, alias, numeral, multiword, lemma-candidate fallback,
        # basic2023) resolved `normalized` as a whole.
        compound = self._compound_fallback_chain(normalized)
        if compound.grade is not None:
            return compound
        return WordGrade(None, None, None, normalized)

    def phrase_grade(self, phrase: str) -> PhraseGrade:
        """Grade every eojeol of `phrase` via the full lemmatizer + full
        word_grade chain (including aliases), returning max over content
        words (plan §4.1: '내용어별 WordGrade + max'). Proper-noun tokens
        (R3 item 5) are excluded from `unknown`.

        T2.5: a MULTI-WORD level_exceptions.csv headword (fixed_expression
        rows like "새해 복 많이 받으세요") can never be matched by the
        per-eojeol loop below -- each eojeol is resolved independently
        (Korean eojeol == space-separated unit already), so the loop never
        re-joins them into the original phrase to check against a
        multi-word CSV key. Whole-phrase-vs-exception-table is therefore
        checked FIRST, short-circuiting the per-eojeol loop entirely when
        `phrase` (eojeol-normalized and rejoined with single spaces, so
        trailing punctuation/extra whitespace don't defeat the match) is
        itself exactly one of those headwords. A single-word exception
        headword passed as `phrase` also matches here (harmless -- the
        per-eojeol loop below would reach the identical grade/source via
        `_resolve_eojeol` -> `_kiiq_derived_chain` -> `_exception_lookup`
        anyway), just without generating a `words` tuple with one entry
        per eojeol -- see the synthetic single-WordGrade return below."""
        eojeols = [t for t in (_normalize_token(r) for r in tokenize_eojeols(phrase)) if t]
        whole_phrase_exception = self._exception_lookup(" ".join(eojeols))
        if whole_phrase_exception is not None:
            return PhraseGrade(
                whole_phrase_exception.grade,
                whole_phrase_exception.cefr,
                (whole_phrase_exception,),
                (),
            )
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
        wins" logic would otherwise skip right past them.

        R8 item 1 (Fable direct-read finding): `token` itself is checked
        NEXT, via `_exact_headword_lookup` -- a narrow, exact-tiers-only
        check (kiiq/derived/alias, NOT the full word_grade chain; see
        that method's docstring for why) -- so a bare headword that
        coincidentally ends in a character which is ALSO a listed
        particle/ending (사과 "apple"'s trailing 과, separately the
        comitative particle) resolves to itself before any particle/
        ending-stripped candidate from the loop below is even generated.

        Numerals (R7 item 7) are DELIBERATELY NOT a similar up-front
        short-circuit: `token` itself may have a real, unrelated kiiq/
        alias meaning that must win first (네 "yes" over the native
        numeral 네 "four" -- checked concretely; see `_numeral_grade`'s
        docstring), so the candidate loop below -- which already reaches
        `word_grade`'s own numeral tier, itself ordered after kiiq/
        derived/alias -- is given first try. Only the grade=None 'number'
        case (a bare ASCII digit string) needs a fallback check AFTER the
        loop: its grade is None BY DESIGN, so the loop's "first grade-not-
        None wins" logic skips past it same as it would a proper noun,
        and without this it would fall all the way through to plain
        unknown, losing the source='number' tag `sentence_profile` needs
        to exclude it from `unknown`."""
        proper = self._match_proper_noun(token)
        if proper is not None:
            return WordGrade(None, None, "proper_noun", proper)
        # T2.4a (B6): see `_is_latin_or_digit_token`'s docstring.
        if _is_latin_or_digit_token(token):
            return WordGrade(None, None, "latin", token)
        # T2.4a (B4): checked here too, BEFORE `_exact_headword_lookup` --
        # that method has its OWN narrow kiiq/derived/alias chain (it does
        # not call `word_grade`), so a bare "서" would otherwise resolve
        # to its real, unrelated, grade-3 kiiq sense right here, before
        # ever reaching the `word_grade`-level check above. See
        # `BANMAL_IMPERATIVE_MAP`'s docstring.
        banmal = BANMAL_IMPERATIVE_MAP.get(token)
        if banmal is not None:
            wg = self.word_grade(banmal)
            return WordGrade(wg.grade, wg.cefr, wg.source, token, wg.confidence_override)
        # See PRONOUN_CONTRACTION_MAP's own docstring.
        pronoun_contraction = PRONOUN_CONTRACTION_MAP.get(token)
        if pronoun_contraction is not None:
            wg = self.word_grade(pronoun_contraction)
            return WordGrade(wg.grade, wg.cefr, wg.source, token, wg.confidence_override)
        exact = self._exact_headword_lookup(token)
        if exact.grade is not None:
            return WordGrade(exact.grade, exact.cefr, exact.source, token, exact.confidence_override)
        for candidate in _lemma_candidates(token):
            wg = self.word_grade(candidate)
            if wg.grade is not None:
                # matched deliberately stays `candidate` (the shallow
                # surface->lemma mapping this loop tried), not wg.matched
                # (which may be a further-reduced root, e.g. a derived
                # chain) -- see the docstring above. confidence_override
                # (R7 item 2) IS propagated though, since it is not part
                # of that surface-form contract, just reliability metadata
                # that must survive however deep the resolution went.
                return WordGrade(wg.grade, wg.cefr, wg.source, candidate, wg.confidence_override)
        numeral = _numeral_grade(token)
        if numeral is not None:
            return numeral
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
            elif resolved.source == "number":
                # R7 item 7: pure ASCII digits are known-but-ungraded, not
                # an unresolved vocabulary gap -- excluded from `unknown`
                # the same way a proper noun is (grade=None by design).
                pass
            elif resolved.source == "latin":
                # T2.4a (B6): a token containing a Latin letter/digit --
                # same "known-but-deliberately-ungraded" treatment as a
                # proper noun or a bare-digit numeral above.
                pass
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
        # R7 item 2: 'medium'-confidence tokens (derived X하다/X되다 whose
        # kiiq-root sense disagreed with basic2023's grade for the full
        # form) are capped at grade 4, one tier looser than 'low''s cap at
        # 3 -- they are less suspect than a basic2023-only guess (a real
        # kiiq root sense DID match), just not fully trusted.
        capped_pairs = [
            (
                t,
                min(t.grade, 3) if t.confidence == "low"
                else min(t.grade, 4) if t.confidence == "medium"
                else t.grade,
            )
            for t in known_tokens
        ]

        # Bible §B/§D allowance: a sentence long enough to carry >=3 graded
        # content tokens gets to excuse exactly one -- its single
        # highest-(capped-)grade token -- from the percentile, mirroring
        # "1급 밖 단어 하나까지만 허용" at every level (not just A1's literal
        # wording). Ties break on first occurrence (stable `max`) -- a
        # deterministic, always-applied exclusion, not a "only if it would
        # otherwise fail" rescue: the Bible grants the allowance
        # unconditionally, so this does too. Only `lexical_p90`'s *inputs*
        # change here -- grammar_max/grammar_hits and every WordGrade in
        # `tokens` (so word/phrase grading elsewhere) are untouched.
        allowance: Optional[Tuple[str, int]] = None
        percentile_pairs = capped_pairs
        if len(capped_pairs) >= 3:
            excused_token, excused_capped = max(capped_pairs, key=lambda pair: pair[1])
            allowance = (excused_token.matched, excused_token.grade)
            excused_index = next(
                i for i, (t, _) in enumerate(capped_pairs) if t is excused_token
            )
            percentile_pairs = capped_pairs[:excused_index] + capped_pairs[excused_index + 1:]

        lexical_p90 = _percentile([grade for _, grade in percentile_pairs], 90)

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
            allowance=allowance,
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


_SENTENCE_PUNCT_TAIL = "?!.…"


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
    # PR-L3a (2026-09-08): a trailing "?"/"!"/"." in a pattern string is
    # sentence punctuation ("V-지요?", "V-나요?", NIKL variant "-세요."), not
    # regex syntax. Left in place, "?" made the last syllable optional
    # ("지요?" -> bare "지", matching 편지/까지) and "." became a wildcard, so
    # every A1 sentence with 까지/편지/하나 picked up a spurious A2 hit.
    tokens = [t.rstrip(_SENTENCE_PUNCT_TAIL) for t in pattern.split(" ")]
    tokens = [t for t in tokens if t]
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
