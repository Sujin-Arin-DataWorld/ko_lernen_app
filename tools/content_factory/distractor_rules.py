#!/usr/bin/env python3
"""Shared cloze-distractor hygiene rules.

Extracted from tools/content_factory/test_batch_26_draft.py (Fable R8-2,
2026-09-15) so the same batchim-class contract can be imported by both a
batch's draft generator/fixer script and its regression test, instead of
being copy-pasted per batch. Behavior is unchanged from the Batch 26 test's
inline version.

When ＿＿＿ (the cloze blank) is immediately followed by a batchim-
alternating particle (이/가, 을/를, 은/는, 과/와, 이에요/예요, 으로/로 — a
ㄹ-final counted as its own class before 으로/로), every distractor must
share the answer's final-consonant class, or the fixed particle shown in the
sentence gives away whether the real answer has batchim before the learner
even considers the vocabulary.
"""

from __future__ import annotations

# index of ㄹ among the 28 possible Hangul syllable finals (jongseong)
RIEUL_JONG = 8

# (consonant_form, vowel_form, particle_kind) -- the 3-syllable copula is
# checked before the bare 이/가 subject particle since "이에요" also starts
# with "이".
ALTERNATING_PARTICLES = [
    ("이에요", "예요", "binary"),
    ("이", "가", "binary"),
    ("을", "를", "binary"),
    ("은", "는", "binary"),
    ("과", "와", "binary"),
    ("으로", "로", "roro"),
]


def jong_index(ch: str):
    code = ord(ch) - 0xAC00
    return code % 28 if 0 <= code < 11172 else None


def batchim_class(word: str, particle_kind: str):
    """particle_kind: 'binary' (이/가, 을/를, 은/는, 과/와, 이에요/예요) or
    'roro' (으로/로, where a ㄹ-final counts as its own class)."""
    j = jong_index(word[-1])
    if j is None:
        return None
    if particle_kind == "roro":
        if j == 0:
            return "vowel"
        return "rieul" if j == RIEUL_JONG else "consonant"
    return "consonant" if j != 0 else "vowel"


def detect_required_class(sentence_ko: str, answer: str):
    """If the text right after the ＿＿＿ blank is a batchim-alternating
    particle, return (kind, required_class) for the answer's own class;
    otherwise (None, None)."""
    idx = sentence_ko.index("＿＿＿")
    after = sentence_ko[idx + 3:]
    for cform, vform, kind in ALTERNATING_PARTICLES:
        if after.startswith(cform) or after.startswith(vform):
            return kind, batchim_class(answer, kind)
    return None, None


# -- backward-compatible aliases matching the names test_batch_26_draft.py
#    used before this extraction --
_RIEUL_JONG = RIEUL_JONG
_ALTERNATING_PARTICLES = ALTERNATING_PARTICLES
_jong_index = jong_index
_batchim_class = batchim_class
_detect_required_class = detect_required_class


# ---------------------------------------------------------------------------
# PREDICATE_SLOT_WAIVER (Fable R8 review of PR #340, 2026-09-15; narrowed in
# a second R8 pass the same day)
# ---------------------------------------------------------------------------
# The "same POS / same conjugation shape" distractor convention breaks down
# for a cloze item whose blank spans an entire minimal-response predicate
# (a short reply's whole verb/copula phrase, e.g. "예, ＿＿＿." -> 알겠습니다)
# or an otherwise wide-open slot where almost any real word of the expected
# shape also produces a fully valid, coherent Korean sentence -- e.g.
# "가족이 ＿＿＿." with 세 명이에요 vs 선생님이에요/의사예요/학생이에요 (all
# grammatical copula sentences). Picking another same-shape predicate/phrase
# as a distractor there almost always yields ANOTHER valid sentence,
# violating the primary rule: a distractor must NEVER yield a valid
# sentence.
#
# First pass (2026-09-15): waived same-POS/conjugation and allowed bare
# nouns/adverbs alongside dictionary-form verbs and particles. Second pass
# the same day narrowed this further: in a sentence-INITIAL response slot
# ("예, ＿＿＿." / "음, ＿＿＿." / "내일 ＿＿＿.") a bare noun or adverb is
# itself a VALID elliptical answer in Korean ("예, 가끔." = "Yes,
# sometimes."; "내일 좀." = "Tomorrow, a bit."), and "저는 빨리 좋아해요"
# (adverb + verb) is fully grammatical -- so nouns/adverbs are NOT safe
# distractors for these items either.
#
# The waiver pool is now exactly two techniques:
#   (i)  a bare dictionary-form verb/adjective where a conjugated predicate
#        is required (가다, 먹다, 오다, 읽다, 쓰다, 타다, 보다, 돕다, ...) --
#        "예, 가다." has no valid conjugation, so it cannot stand as the
#        sentence's predicate, and (unlike a noun) it cannot be read as an
#        elliptical answer either.
#   (ii) a bare grammatical particle with nothing to attach to (에서, 에게,
#        한테, 으로, 와, 과, 랑) -- "예, 에서." has no host word for the
#        particle and completes nothing, in an elliptical reading or
#        otherwise.
# Composition per item: 2 dictionary-form + 1 particle, or 3
# dictionary-form.
#
# A bare noun is allowed ONLY as a single, individually-justified exception
# where the slot sits inside a sentence with no separate predicate anywhere
# (the blank IS the entire predicate, not an interjection-response
# fragment) AND the preceding word is a real subject/topic that
# grammatically demands a predicate to complete the clause -- there a bare
# noun genuinely leaves the sentence unparsable, with no elliptical
# reading available (unlike an interjection, a subject cannot itself stand
# as a complete utterance). Only cloze_a1_0407 qualifies (가족이 [subject]
# + 휴대폰 [bare noun] has no predicate at all, and "가족이" cannot itself
# be read as a complete utterance the way "예," can) -- see NOUN_EXCEPTIONS.
#
# `PREDICATE_SLOT_WAIVER` maps each waived Batch 25 cloze id to the short
# reason its answer is an open predicate/phrase slot. `waived_distractor_ok`
# checks a candidate distractor is drawn from pool (i)/(ii), or is that
# item's documented NOUN_EXCEPTIONS entry (used by the regression test, not
# by content generation itself -- these were hand-picked, not
# auto-generated).
PREDICATE_SLOT_WAIVER = {
    "cloze_a1_0398": "저는 ＿＿＿ 좋아해요. -- 좋아하다 accepts almost any object noun+를/을; no real word is a selectional violation there.",
    "cloze_a1_0407": "가족이 ＿＿＿. -- answer spans the full copula predicate (세 명이에요); any profession/role noun+이에요 is also grammatical.",
    "cloze_a1_0413": "예, ＿＿＿. -- answer spans the full minimal-response predicate (알겠습니다); a bare noun/adverb here is a valid elliptical answer.",
    "cloze_a1_0415": "와, ＿＿＿! -- answer spans the full exclamation predicate (좋아요); a bare noun/adverb here is a valid elliptical exclamation.",
    "cloze_a1_0416": "음, ＿＿＿. -- answer spans the full minimal-response predicate (모르겠어요); a bare noun/adverb here is a valid elliptical answer.",
    "cloze_a1_0419": "내일 ＿＿＿. -- answer spans the full imperative predicate (꼭 오세요); a bare noun/adverb here is a valid elliptical answer.",
    "cloze_a1_0437": "＿＿＿ 친구를 만나요. -- any time-word+에 fits this frame equally well; no real time word is a selectional violation there.",
    "cloze_a1_0440": "제 ＿＿＿ 다섯 살이에요. -- any family-member noun+은/는 fits equally well; no real family word is a selectional violation there.",
}

DICTIONARY_FORM_VERBS = frozenset({
    "가다", "오다", "보다", "읽다", "쓰다", "타다", "입다", "알다", "모르다",
    "돕다", "팔다", "고르다", "빌리다", "끝나다", "다니다", "먹다", "마시다", "자다",
})
BARE_PARTICLES = frozenset({
    "에서", "에게", "한테", "으로", "와", "과", "랑",
})
# The single, individually-justified bare-noun exception (see docstring
# above) -- keyed by cloze id, not a general pool.
NOUN_EXCEPTIONS = {
    "cloze_a1_0407": "휴대폰",
}


def waived_distractor_ok(word: str, cloze_id: str | None = None) -> bool:
    """True if `word` is drawn from the (i) dictionary-form-verb or (ii)
    bare-particle pool -- i.e. it cannot itself complete the slot as a
    valid predicate or a valid elliptical answer, regardless of same-POS/
    same-conjugation matching. `cloze_id`, if given, also allows that
    item's single documented NOUN_EXCEPTIONS word (if any)."""
    if word in DICTIONARY_FORM_VERBS or word in BARE_PARTICLES:
        return True
    if cloze_id is not None and NOUN_EXCEPTIONS.get(cloze_id) == word:
        return True
    return False


# -- backward-compatible alias: old name, still importable --
BARE_NOUNS_NO_COPULA = frozenset(NOUN_EXCEPTIONS.values())
BARE_PARTICLES_OR_ADVERBS = BARE_PARTICLES
