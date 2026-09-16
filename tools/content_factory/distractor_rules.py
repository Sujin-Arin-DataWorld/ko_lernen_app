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
    "cloze_a1_0285": "실수해도 ＿＿＿. -- answer spans the full minimal-response predicate (문제없어요, existential-family 없어요); same pattern as cloze_a1_0413/0416 (C2c cloze distractor hygiene sweep, 2026-09-15).",
    # C3-T3 (2026-09-16): Batch 26/27 A1 reinforcement, discovered when the
    # freshly-merged C2c D3 rule was run against the new batches. Each
    # answer is a bare single-verb predicate closing a short exchange
    # (no object/particle after the blank); a same-conjugated-ending
    # distractor would itself be a fully grammatical, if nonsensical,
    # sentence-final predicate, whereas the batch's own bare
    # dictionary-form verbs are ungrammatical there -- the intended
    # PREDICATE_SLOT_WAIVER pattern.
    "cloze_a1_0523": "아, 텔레비전을 ＿＿＿. -- answer spans the full sentence-final predicate (켜요); a bare dictionary-form verb cannot close the slot.",
    "cloze_a1_0524": "크리스티안 씨, 지금 잘까요? 불을 ＿＿＿. -- answer spans the full sentence-final predicate (꺼요); a bare dictionary-form verb cannot close the slot.",
    "cloze_a1_0525": "와! 아기가 정말 많이 ＿＿＿. -- answer spans the full sentence-final predicate (웃어요); a bare dictionary-form verb cannot close the slot.",
    "cloze_a1_0586": "미안해요, 버스가 ＿＿＿. -- answer spans the full sentence-final predicate (늦었어요, past tense); a bare dictionary-form verb cannot close the slot.",
    "cloze_a1_0587": "선생님한테 다시 ＿＿＿. -- answer spans the full sentence-final predicate (물어요); a bare dictionary-form verb cannot close the slot.",
    "cloze_a1_0588": "제 대답이 ＿＿＿? -- answer spans the full sentence-final predicate (맞아요); a bare dictionary-form verb cannot close the slot.",
    # C3-T4 (2026-09-16): Batch 29 A1 reinforcement, documented in the
    # batch's own drafts/batch_29_a1_reinforcement_manifest.json
    # predicateSlotWaiverRows (R8 review, 2026-09-16) -- each is a
    # genuinely open predicate slot (invitation, minimal-response,
    # exclamatory, or copula-negation frame) with no real Tier-A
    # same-ending candidate pool, same class as the C3-T3 rows above.
    "cloze_a1_0653": "크리스티안 씨, 우리 같이 ＿＿＿? -- 놀다 invitation slot (-(으)ㄹ까요?); 가다/보다/먹다 등 다수의 초대 동사가 같은 어미로 자연스럽게 성립해 Tier A 후보를 못 채운다.",
    "cloze_a1_0668": "아이가 많이 ＿＿＿. -- 울다 manner-adverb slot; 웃다(정반의어) 등 다수의 아동 행위 동사가 같은 -아/어요 형으로 성립해 Tier A 후보를 못 채운다.",
    "cloze_a1_0671": "요즘 잘 ＿＿＿? -- 지내다 bare minimal-response frame (Fable's own explicit example of an allowed waiver).",
    "cloze_a1_0676": "우리는 같이 ＿＿＿. -- 춤추다 collective-activity slot, same class as 놀다 (다수의 -아/어요 형 동사가 '우리는 같이' 뒤에서 유효한 문장을 만든다).",
    "cloze_a1_0678": "정말 ＿＿＿. -- 고맙다 maximally open exclamatory frame ('정말 + 어떤 형용사든' 자체로 완전한 감탄문); Tier A 후보가 원천적으로 존재하지 않는다.",
    "cloze_a1_0693": "저는 학생이 ＿＿＿. -- 아니다 copula-negation predicate (X이/가 아니에요) unique shape; 학생이에 붙는 다른 형용사가 없어 Tier A 후보 풀 자체가 없다 (Batch 25 cloze_a1_0407과 동일 부류).",
}

DICTIONARY_FORM_VERBS = frozenset({
    "가다", "오다", "보다", "읽다", "쓰다", "타다", "입다", "알다", "모르다",
    "돕다", "팔다", "고르다", "빌리다", "끝나다", "다니다", "먹다", "마시다", "자다",
    # C3-T4 (2026-09-16): Batch 29's own waiver rows added a dictionary-
    # form verb (사다) and, for the first time, dictionary-form ADJECTIVE
    # waivers (고맙다/아니다's exclamatory and copula-negation frames) --
    # the module docstring above always described this pool as "(i) a
    # bare dictionary-form verb/adjective", but no adjective had needed
    # the waiver until now. `waived_distractor_ok` only checks flat set
    # membership, so these live in the same pool rather than a new one.
    "사다", "많다", "무겁다", "바쁘다", "비싸다", "쉽다", "작다",
})
BARE_PARTICLES = frozenset({
    "에서", "에게", "한테", "으로", "와", "과", "랑",
})
# C3-T5 (2026-09-16): Batch 30's pronoun-fold rows (그것/무엇/저것/어디/
# 언제) use a THIRD waiver shape -- not a bare dictionary-form verb/
# adjective and not a bare floating particle, but a pronoun of a
# DIFFERENT deictic class carrying the SAME particle as the answer (see
# tools/content_factory/drafts/batch_30_a1_reinforcement_manifest.json's
# posRules.pronouns). This still "cannot complete the slot as a valid
# predicate or elliptical answer" the pool's docstring requires: a
# temporal pronoun (언제) cannot take an instrumental/directional particle
# (로) and a demonstrative-thing pronoun (그것/무엇/저것) cannot directly
# precede a possessed noun without 의 -- both read as a category-violation
# 비문 regardless of any same-POS/same-form re-pick. Verified by
# test_batch_30_draft.py's
# test_remaining_rows_carry_a_particle_fold_consistent_with_their_own_final_sound.
PRONOUN_FOLD_CATEGORY_MISMATCHES = frozenset({
    "언제는", "무엇은", "어디는", "언제로", "무엇으로", "저것으로", "그는",
})
# The single, individually-justified bare-noun exception (see docstring
# above) -- keyed by cloze id, not a general pool.
NOUN_EXCEPTIONS = {
    "cloze_a1_0407": "휴대폰",
}


def waived_distractor_ok(word: str, cloze_id: str | None = None) -> bool:
    """True if `word` is drawn from the (i) dictionary-form-verb, (ii)
    bare-particle, or (iii) pronoun-fold-category-mismatch pool -- i.e. it
    cannot itself complete the slot as a valid predicate or a valid
    elliptical answer, regardless of same-POS/same-conjugation matching.
    `cloze_id`, if given, also allows that item's single documented
    NOUN_EXCEPTIONS word (if any)."""
    if (
        word in DICTIONARY_FORM_VERBS
        or word in BARE_PARTICLES
        or word in PRONOUN_FOLD_CATEGORY_MISMATCHES
    ):
        return True
    if cloze_id is not None and NOUN_EXCEPTIONS.get(cloze_id) == word:
        return True
    return False


# -- backward-compatible alias: old name, still importable --
BARE_NOUNS_NO_COPULA = frozenset(NOUN_EXCEPTIONS.values())
BARE_PARTICLES_OR_ADVERBS = BARE_PARTICLES
