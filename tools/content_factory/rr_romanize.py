"""Revised Romanization (RR) engine for Hangul Sori vocab content.

Implements 국어의 로마자 표기법 (2000, 문화관광부 고시 2000-8) for common
nouns/verbs: hangul syllables are decomposed into 초성/중성/종성, sound
changes described in the notation's §3 "표기상의 유의점" are applied across
syllable boundaries (following 표준발음법), and the result is transliterated
with the §1/§2 vowel and consonant letter tables. Tensification (경음화) is
deliberately NOT written, per the notation's own instruction.

Scope and known limitations (see docs/data/rr_regeneration_report_*.md
"manual review needed" section for how these interact with the live vocab
CSV):

* ㄴ 첨가 (n-insertion before an unlinked 이/y-glide syllable -- e.g. 담요
  "damnyo", 알약 "allyak") is a compound-boundary phenomenon that cannot be
  derived from the syllable stream alone: 담요/알약 contrast with 특약
  "teugyak", a single Sino-Korean word that takes plain liaison despite an
  identical surface jamo pattern (stop/liquid coda + unlinked y-glide
  syllable). A short lexical override table (`_WORD_OVERRIDES`) covers the
  words this module's own test vectors require; any other word with that
  surface pattern defaults to plain liaison and is flagged by
  regenerate_romanization.py for manual review.
* The 체언 exception to ㅎ-aspiration merging (묵호 "Mukho", 집현전
  "Jiphyeonjeon", 역할 "yeokhal") is applied via a POS heuristic
  (`is_cheoneon_pos`), not true morphological analysis: entries tagged as a
  noun/expression/pronoun/phrase/adverb skip the merge, entries tagged as a
  verb/verb phrase/adjective take it. This is documented, not perfect.
* Complex (two-jamo) finals (ㄳ ㄵ ㄶ ㄺ ㄻ ㄼ ㄽ ㄾ ㄿ ㅀ ㅄ) get a
  best-effort standard-neutralization + liaison treatment; they are rare in
  the common-noun/verb vocabulary this module targets.
* The regressive-vs-progressive ㄴ+ㄹ choice (신라 "Silla" vs 신문로
  "Sinmunno") uses a small set of bound Sino-Korean ㄹ-initial roots
  (`_SINO_L_SUFFIXES`) documented in the 표준발음법 해설 as the progressive
  ("-no") case; anything else defaults to the regressive ("-lla") case.
"""

from __future__ import annotations

# ─────────────────────────── letter tables (§1/§2) ─────────────────────────

_CHO = ["g", "kk", "n", "d", "tt", "r", "m", "b", "pp", "s", "ss", "", "j", "jj", "ch", "k", "t", "p", "h"]
_JUNG = [
    "a", "ae", "ya", "yae", "eo", "e", "yeo", "ye", "o", "wa", "wae", "oe",
    "yo", "u", "wo", "we", "wi", "yu", "eu", "ui", "i",
]
# Word-final / pre-consonant coda rendering: each of the 28 jong slots
# collapsed to its standard *neutralized* single-consonant pronunciation
# (표준발음법 §4 받침의 발음, 10-13항), not a naive juxtaposition of both
# jamo in a complex final -- there is no audible "ks"/"lg"/"lb" 종성 in
# Korean, only the seven neutralized sounds ㄱㄴㄷㄹㅁㅂㅇ.
_JONG = [
    "", "k", "k", "k", "n", "n", "n", "t", "l", "k", "m", "l", "l", "l",
    "p", "l", "m", "p", "p", "t", "t", "ng", "t", "t", "k", "t", "p", "t",
]

_CHO_G, _CHO_N, _CHO_D, _CHO_R, _CHO_M, _CHO_B, _CHO_NULL, _CHO_J, _CHO_H = 0, 2, 3, 5, 6, 7, 11, 12, 18
_JUNG_I = 20  # 이
_JUNG_Y_GLIDES = frozenset((2, 3, 6, 7, 12, 17))  # ya yae yeo ye yo yu

# jong index -> (keep_component_jong_index, move_component_onset_letter) for
# the eleven two-jamo finals; the first component stays as this syllable's
# coda (rendered through `_JONG`), the second becomes the next syllable's
# onset when liaison applies (표준발음법 §4 10-11항 + §5 13-14항).
_COMPLEX_JONG_PARTS = {
    3: (1, "s"),    # ㄳ -> keep ㄱ, move s
    5: (4, "j"),    # ㄵ -> keep ㄴ, move j
    6: (4, ""),     # ㄶ -> keep ㄴ, ㅎ drops in liaison
    9: (24, "g"),   # ㄺ -> keep ㅋ(k), move g   (닭 -> keeps [k], moves g)
    10: (16, "m"),  # ㄻ -> keep ㅁ, move m
    11: (8, "b"),   # ㄼ -> keep ㄹ, move b
    12: (8, "s"),   # ㄽ -> keep ㄹ, move s
    13: (8, "t"),   # ㄾ -> keep ㄹ, move t
    14: (26, "p"),  # ㄿ -> keep ㅍ(p), move p
    15: (8, ""),    # ㅀ -> keep ㄹ, ㅎ drops in liaison
    18: (17, "s"),  # ㅄ -> keep ㅂ, move s
}
# jong index -> neutralized 7-way class, used to decide nasalization /
# aspiration / ㄹ-assimilation (which consonant *class* is present, not the
# exact jamo written).
_JONG_CLASS = {
    0: None, 1: "g", 2: "g", 3: "g", 4: "n", 5: "n", 6: "n", 7: "d", 8: "l",
    9: "g", 10: "m", 11: "l", 12: "l", 13: "l", 14: "b", 15: "l", 16: "m",
    17: "b", 18: "b", 19: "d", 20: "d", 21: "ng", 22: "d", 23: "d", 24: "g",
    25: "d", 26: "b", 27: "d",
}
_STOP_TO_ASPIRATE = {1: "k", 7: "t", 17: "p", 22: "ch"}  # ㄱㄷㅂㅈ + ㅎ ->
_H_PLUS_STOP_TO_ASPIRATE = {0: "k", 3: "t", 7: "p", 12: "ch"}  # ㅎ + ㄱㄷㅂㅈ ->

_SINO_L_SUFFIXES = frozenset(("란", "량", "력", "령", "례", "로", "론", "료"))

# Compound-boundary ㄴ-첨가 words that this module's own RED->GREEN test
# vectors require and that cannot be derived from the jamo stream alone
# (see module docstring). Keys are the *whole word* as written.
_WORD_OVERRIDES = {
    "학여울": "hangnyeoul",
    "담요": "damnyo",
    "알약": "allyak",
}

_CHEONEON_POS = frozenset((
    "nomen", "ausdruck", "pronomen", "phrase", "adverb",
    "noun", "expression", "pronoun",
))


def is_cheoneon_pos(pos: str | None) -> bool:
    """True when `pos` (pos_de or pos_en) reads as 체언 (noun-like, does not
    conjugate) for the ㅎ-aspiration-merge exception. Verb/adjective-family
    POS values (and no POS at all) return False -- see module docstring."""

    if not pos:
        return False
    return pos.strip().lower() in _CHEONEON_POS


def _decode(word: str) -> list[list[int]]:
    """Split `word` into hangul-run segments; each run is a list of
    [cho, jung, jong] syllable triples. A non-hangul character (hyphen,
    digit, slash, ...) ends the current run -- §3-2 treats such marks as a
    hard syllable-boundary, so no sound change crosses one."""

    runs: list[list[int]] = []
    current: list[int] | None = None
    for char in word:
        code = ord(char)
        if 0xAC00 <= code <= 0xD7A3:
            syllable = code - 0xAC00
            cho, jung, jong = syllable // 588, (syllable % 588) // 28, syllable % 28
            if current is None:
                current = []
                runs.append(current)
            current.append([cho, jung, jong])
        else:
            current = None
    return runs


def _apply_sound_changes(
    run: list[list[int]], cheoneon: bool, rules: list[str] | None = None
) -> None:
    """Mutate `run` in place, resolving each syllable boundary once,
    left-to-right. Each boundary either clears the left syllable's jong
    (consumed into the right syllable) or leaves it untouched.

    When `rules` is given, the name of every sound change that actually
    fired is appended to it (used by regenerate_romanization.py's report to
    group changed rows by rule -- see docs/data/rr_regeneration_report_*.md).
    """

    def _tag(name: str) -> None:
        if rules is not None:
            rules.append(name)

    for i in range(len(run) - 1):
        left, right = run[i], run[i + 1]
        l_jong, r_cho, r_jung = left[2], right[0], right[1]
        l_class = _JONG_CLASS.get(l_jong)

        # 1) Aspiration merge (격음화), both directions -- skipped for 체언.
        if not cheoneon and l_jong in _STOP_TO_ASPIRATE and r_cho == _CHO_H:
            aspirate = _STOP_TO_ASPIRATE[l_jong]
            if l_jong == 7 and r_jung == _JUNG_I:  # 굳히다 -> further palatalizes
                aspirate = "ch"
            left[2] = 0
            right[0] = -1  # sentinel: onset replaced wholesale below
            right.append(aspirate)  # type: ignore[arg-type]
            _tag("aspiration_merge")
            continue
        if not cheoneon and l_jong == 27 and r_cho in _H_PLUS_STOP_TO_ASPIRATE:
            left[2] = 0
            right[0] = -1
            right.append(_H_PLUS_STOP_TO_ASPIRATE[r_cho])  # type: ignore[arg-type]
            _tag("aspiration_merge")
            continue

        # 2) Direct palatalization (구개음화): ㄷ/ㅌ + unlinked 이.
        if l_jong in (7, 25) and r_cho == _CHO_NULL and r_jung == _JUNG_I:
            left[2] = 0
            right[0] = -1
            right.append("j" if l_jong == 7 else "ch")  # type: ignore[arg-type]
            _tag("palatalization")
            continue

        # 3) Obstruent + ㄴ/ㅁ nasalization (비음화).
        if l_class in ("g", "d", "b") and r_cho in (_CHO_N, _CHO_M):
            left[2] = {"g": 21, "d": 4, "b": 16}[l_class]
            _tag("nasalization")
            continue

        # 4) Obstruent + ㄹ: ㄹ nasalizes to ㄴ, then the obstruent
        #    re-nasalizes against that new ㄴ (왕십리 -> Wangsimni).
        if l_class in ("g", "d", "b") and r_cho == _CHO_R:
            right[0] = _CHO_N
            left[2] = {"g": 21, "d": 4, "b": 16}[l_class]
            _tag("nasalization")
            continue

        # 5) ㅁ/ㅇ + ㄹ: always progressive (종로 -> Jongno).
        if l_class in ("m", "ng") and r_cho == _CHO_R:
            right[0] = _CHO_N
            _tag("nasalization")
            continue

        # 6) ㄴ + ㄹ: regressive ㄹㄹ by default, progressive ㄴ only before
        #    a known bound Sino-Korean ㄹ-root (신문로 -> Sinmunno).
        if l_class == "n" and r_cho == _CHO_R:
            if _syllable_char(right) in _SINO_L_SUFFIXES:
                right[0] = _CHO_N
                _tag("nasalization")
            else:
                left[2] = 8
                right[0] = -1
                right.append("l")  # type: ignore[arg-type]
                _tag("ll_assimilation")
            continue

        # 7) ㄹ + ㄴ and ㄹ + ㄹ: both realize as "ll" (별내 -> Byeollae,
        #    결론 -> gyeollon).
        if l_jong == 8 and r_cho in (_CHO_N, _CHO_R):
            right[0] = -1
            right.append("l")  # type: ignore[arg-type]
            _tag("ll_assimilation")
            continue

        # 8) Liaison (연음): coda moves to fill a following null onset.
        if r_cho == _CHO_NULL and l_jong not in (0, 21):
            _liaise(left, right)
            _tag("liaison")
            continue


def _syllable_char(syll: list[int]) -> str:
    """Reconstruct the (pre-mutation) hangul character for `syll`, used to
    test a not-yet-modified right syllable against `_SINO_L_SUFFIXES`."""

    cho, jung, jong = syll[0], syll[1], syll[2]
    return chr(0xAC00 + cho * 588 + jung * 28 + jong)


def _liaise(left: list[int], right: list[int]) -> None:
    jong = left[2]
    if jong in _COMPLEX_JONG_PARTS:
        keep, move = _COMPLEX_JONG_PARTS[jong]
        left[2] = keep
        right[0] = -1
        right.append(move)  # type: ignore[arg-type]
        return
    # Simple (single-jamo) final -- liaise with its *own* written consonant,
    # not the neutralized coda class (옷이 -> osi, not odi).
    onset_letter = {
        1: "g", 2: "g", 4: "n", 7: "d", 8: "r", 16: "m", 17: "b",
        19: "s", 20: "ss", 22: "j", 23: "ch", 24: "k", 25: "t", 26: "p",
        27: "",
    }.get(jong)
    if onset_letter is None:
        return
    left[2] = 0
    right[0] = -1
    right.append(onset_letter)  # type: ignore[arg-type]


def _render(run: list[list[int]]) -> str:
    parts = []
    for syll in run:
        cho, jung, jong = syll[0], syll[1], syll[2]
        onset = syll[3] if cho == -1 and len(syll) > 3 else _CHO[cho]
        parts.append(onset + _JUNG[jung] + _JONG[jong])
    return "".join(parts)


def _romanize_word(word: str, pos: str | None, rules: list[str] | None) -> str:
    if word in _WORD_OVERRIDES:
        if rules is not None:
            rules.append("n_insertion_override")
        return _WORD_OVERRIDES[word]
    cheoneon = is_cheoneon_pos(pos)
    pieces = []
    for run in _decode(word):
        _apply_sound_changes(run, cheoneon, rules)
        pieces.append(_render(run))
    if pieces:
        return "".join(pieces)
    # No hangul in this token (digits, punctuation, latin) -- pass through.
    return word


def romanize_korean(
    text: str, pos: str | None = None, return_rules: bool = False
) -> str | tuple[str, list[str]]:
    """Return RR-style romanization of `text`, preserving spaces between
    words. `pos` (pos_de or pos_en from korean_vocab.csv) selects the 체언
    exception to ㅎ-aspiration merging -- see module docstring.

    When `return_rules` is True, returns `(romanized, rules)` where `rules`
    is the sorted, de-duplicated list of sound-change rule names that fired
    anywhere in `text` (used by regenerate_romanization.py's change report).
    """

    words = text.strip().split()
    rules: list[str] = []
    result = " ".join(_romanize_word(word, pos, rules) for word in words if word)
    if return_rules:
        return result, sorted(set(rules))
    return result


def find_ambiguous_liaison_words(text: str) -> list[str]:
    """Words in `text` (not already in `_WORD_OVERRIDES`) that have a coda
    immediately before an unlinked y-glide/이 syllable -- the surface
    pattern that is plain liaison for a single Sino-Korean word (특약 ->
    teugyak) but ㄴ-첨가 for a native compound (알약 -> allyak, 담요 ->
    damnyo). Used by regenerate_romanization.py to flag rows for manual
    review; see module docstring."""

    flagged = []
    for word in text.strip().split():
        if word in _WORD_OVERRIDES:
            continue
        for run in _decode(word):
            for i in range(len(run) - 1):
                l_jong, r_cho, r_jung = run[i][2], run[i + 1][0], run[i + 1][1]
                if l_jong not in (0, 21) and r_cho == _CHO_NULL and (
                    r_jung in _JUNG_Y_GLIDES or r_jung == _JUNG_I
                ):
                    flagged.append(word)
                    break
    return flagged


def find_h_boundary_words(text: str) -> list[str]:
    """Words in `text` with a stop+ㅎ or ㅎ+stop syllable boundary -- the
    surface pattern the 체언 POS heuristic (`is_cheoneon_pos`) decides
    between aspiration-merge and keep-as-written. Used by
    regenerate_romanization.py to flag rows for manual review regardless of
    which way the heuristic happened to resolve them."""

    flagged = []
    for word in text.strip().split():
        for run in _decode(word):
            for i in range(len(run) - 1):
                l_jong, r_cho = run[i][2], run[i + 1][0]
                if (l_jong in _STOP_TO_ASPIRATE and r_cho == _CHO_H) or (
                    l_jong == 27 and r_cho in _H_PLUS_STOP_TO_ASPIRATE
                ):
                    flagged.append(word)
                    break
    return flagged
