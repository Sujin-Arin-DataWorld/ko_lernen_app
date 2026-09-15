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
# PREDICATE_SLOT_WAIVER (Fable R8 review of PR #340, 2026-09-15)
# ---------------------------------------------------------------------------
# The "same POS / same conjugation shape" distractor convention breaks down
# for a cloze item whose blank spans an entire minimal-response predicate
# (a short reply's whole verb/copula phrase, e.g. "예, ＿＿＿." -> 알겠습니다)
# or an otherwise wide-open slot where almost any real word of the expected
# shape also produces a fully valid, coherent Korean sentence -- e.g.
# "가족이 ＿＿＿." with 세 명이에요 vs 선생님이에요/의사예요/학생이에요 (all
# grammatical copula sentences), or "내일 ＿＿＿." with 꼭 오세요 vs 빨리
# 가세요/같이 드세요 (both well-formed imperatives). Picking another
# same-shape predicate/phrase as a distractor there almost always yields
# ANOTHER valid sentence, violating the primary rule: a distractor must
# NEVER yield a valid sentence.
#
# For these items the same-POS/same-conjugation rule is waived, and instead
# each distractor is deliberately built to be UNGRAMMATICAL in that exact
# slot, via one of three techniques:
#   (i)   a bare dictionary-form verb where a conjugated predicate is
#         required (가다, 먹다, 오다, 읽다, 쓰다, 타다, 보다, 돕다) --
#         "예, 가다." has no valid conjugation, so it cannot stand as the
#         sentence's predicate.
#   (ii)  a bare noun with no copula, dropped into a slot that requires a
#         complete predicate or an attached particle (책상, 우산, 컴퓨터,
#         가방, 자동차, 휴대폰, 지갑, 시계) -- "가족이 책상." is missing
#         "이에요"/"예요" and cannot stand alone as a finished sentence.
#   (iii) a bare particle or adverb with nothing to attach to (에서, 에게,
#         한테, 가끔, 자주, 항상, 좀) -- "음, 잘 에서." has no host word for
#         the particle and completes nothing.
#
# `PREDICATE_SLOT_WAIVER` maps each waived Batch 25 cloze id to the short
# reason its answer is an open predicate/phrase slot. `waived_distractor_ok`
# checks a candidate distractor is drawn from one of the three techniques
# above (used by the regression test, not by content generation itself --
# these were hand-picked, not auto-generated).
PREDICATE_SLOT_WAIVER = {
    "cloze_a1_0398": "저는 ＿＿＿ 좋아해요. -- 좋아하다 accepts almost any object noun+를/을; no real word is a selectional violation there.",
    "cloze_a1_0407": "가족이 ＿＿＿. -- answer spans the full copula predicate (세 명이에요); any profession/role noun+이에요 is also grammatical.",
    "cloze_a1_0413": "예, ＿＿＿. -- answer spans the full minimal-response predicate (알겠습니다); any -습니다 reply predicate is also grammatical.",
    "cloze_a1_0415": "와, ＿＿＿! -- answer spans the full exclamation predicate (좋아요); any -아/어요 adjective exclamation is also grammatical.",
    "cloze_a1_0416": "음, ＿＿＿. -- answer spans the full minimal-response predicate (모르겠어요); any -어요 reply predicate is also grammatical.",
    "cloze_a1_0419": "내일 ＿＿＿. -- answer spans the full imperative predicate (꼭 오세요); any -세요 imperative is also grammatical.",
    "cloze_a1_0437": "＿＿＿ 친구를 만나요. -- any time-word+에 fits this frame equally well; no real time word is a selectional violation there.",
    "cloze_a1_0440": "제 ＿＿＿ 다섯 살이에요. -- any family-member noun+은/는 fits equally well; no real family word is a selectional violation there.",
}

DICTIONARY_FORM_VERBS = frozenset({
    "가다", "오다", "보다", "읽다", "쓰다", "타다", "입다", "알다", "모르다",
    "돕다", "팔다", "고르다", "빌리다", "끝나다", "다니다", "먹다", "마시다", "자다",
})
BARE_NOUNS_NO_COPULA = frozenset({
    "책상", "우산", "컴퓨터", "가방", "자동차", "휴대폰", "지갑", "시계", "열쇠",
})
BARE_PARTICLES_OR_ADVERBS = frozenset({
    "에서", "에게", "한테", "가끔", "자주", "항상", "좀", "빨리", "다시",
})


def waived_distractor_ok(word: str) -> bool:
    """True if `word` is drawn from one of the three PREDICATE_SLOT_WAIVER
    techniques (bare dictionary-form verb / bare noun without copula / bare
    particle-adverb) -- i.e. it cannot itself complete the slot as a valid
    predicate, regardless of same-POS/same-conjugation matching."""
    return (
        word in DICTIONARY_FORM_VERBS
        or word in BARE_NOUNS_NO_COPULA
        or word in BARE_PARTICLES_OR_ADVERBS
    )
