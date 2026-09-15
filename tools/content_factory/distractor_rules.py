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
