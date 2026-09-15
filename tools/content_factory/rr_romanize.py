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
* ㅎ-aspiration merging (격음화) only fires for a coda immediately before or
  after the ㅎ that belongs to a verb/adjective's OWN stem or a native
  passive/causative infix: stem-final ㅎ/ㄶ/ㅀ + ㄱ/ㄷ/ㅈ ending (좋고
  "joko", 많다 "manta", 싫다 "silta") and stop coda + -히-/-혀- infix inside
  a verb (먹히다 "meokida", 잡혀 "japyeo"). A stop coda before the
  noun-forming auxiliary 하다 (반박하다 "banbakhada", not "banbakada") or a
  하다-stem's own -히 adverb (정확히 "jeonghwakhi") keeps ㅎ instead, even
  though the whole word's POS is "Verb" -- `_HADA_AUX_VOWELS` recognizes 하
  다-paradigm 하/해/했 (Sino-Korean-root + 하다, never a native infix, so
  this vowel test is POS-independent), a word-final 히 is treated as the
  parallel -히 adverb suffix, and `is_cheoneon_pos` is kept as a fallback
  for the cases neither surface pattern catches (묵호 "Mukho", 집현전
  "Jiphyeonjeon"). This is a lexical/surface heuristic, not true
  morphological analysis -- see `_apply_sound_changes` rule 1.
* Complex (two-jamo) finals (ㄳ ㄵ ㄶ ㄺ ㄻ ㄼ ㄽ ㄾ ㄿ ㅀ ㅄ) before a
  vowel-initial ending/particle keep their FIRST jamo as this syllable's own
  coda and move only the SECOND to the next onset (표준발음법 14항) --
  `_COMPLEX_JONG_PARTS`.
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
    9: (8, "g"),    # ㄺ -> keep ㄹ, move g   (읽음 표시 -> ilgeum pyosi)
    10: (8, "m"),   # ㄻ -> keep ㄹ, move m   (삶이 -> salmi)
    11: (8, "b"),   # ㄼ -> keep ㄹ, move b
    12: (8, "s"),   # ㄽ -> keep ㄹ, move s
    13: (8, "t"),   # ㄾ -> keep ㄹ, move t
    14: (8, "p"),   # ㄿ -> keep ㄹ, move p   (읊어 -> eulpeo)
    15: (8, ""),    # ㅀ -> keep ㄹ, ㅎ drops in liaison
    18: (17, "s"),  # ㅄ -> keep ㅂ, move s
}
# 표준발음법 14항: a two-jamo final before a vowel-initial ending/particle
# keeps its FIRST jamo as this syllable's own coda (§4 neutralized spelling,
# via `_JONG`) and moves only the SECOND jamo to the next syllable's onset --
# never the reverse. ㄺ/ㄻ/ㄿ all have ㄹ as their first jamo, so all three
# keep ㄹ (index 8, "l") exactly like ㄼ/ㄽ/ㄾ/ㅀ; the entries above used to
# keep the neutralized *stop/nasal* class instead (a rule that only applies
# word-finally or before a consonant, not before a vowel) which silently
# dropped the ㄹ liaison for 읽다/삶/읊다-family words (Codex review, PR #327).
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
# jong index -> (keep_jong_when_merging, aspirate_map) for the reverse
# direction (stem-final ㅎ/ㄶ/ㅀ + ㄱ/ㄷ/ㅈ ending, 표기법 §3-1-4 다만): the
# ㅎ always merges into the aspirate on the *next* syllable's onset, but a
# complex final (ㄶ/ㅀ) keeps its non-ㅎ component as this syllable's coda
# (많다 -> "man" + "ta", not "ma" + "nta").
_H_COMPLEX_KEEP = {27: 0, 6: 4, 15: 8}  # ㅎ->none, ㄶ->keep ㄴ, ㅀ->keep ㄹ
# 하다-paradigm vowel: 하/해/했 etc. are always the noun-forming auxiliary
# verb 하다 (Sino-Korean root + 하다), never a native verb's own passive/
# causative infix -- so a stop coda before one of these never merges,
# regardless of the whole word's POS (반박하다 "banbakhada", not
# "banbakada" -- Fable ruling 2026-09-15, 표기법 §3-1-4 다만 + NIKL/
# Wiktionary RR module precedent: 축하하다 "chukhahada", 도착하다
# "dochakhada").
_HADA_AUX_VOWELS = frozenset((0, 1))  # 아, 애 (하, 해/했)

_SINO_L_SUFFIXES = frozenset(("란", "량", "력", "령", "례", "로", "론", "료"))

# Compound-boundary ㄴ-첨가 (n-insertion) words that this module's own
# RED->GREEN test vectors require and that cannot be derived from the jamo
# stream alone (see module docstring): a coda + unlinked y-glide/이 syllable
# is plain liaison for a single (esp. Sino-Korean) word (특약 -> teugyak,
# 안약 -> anyak -- both Sino-Korean roots) but ㄴ-첨가 for a native/native+
# Sino compound recognized as such by 표준발음법 29항 (담요, 알약, 학여울,
# 한여름, 색연필, 집안일 -- 식용유 is the counter-example: no insertion,
# despite the identical surface jamo pattern, because 식용 + 유 is one
# established Sino-Korean unit). Keys are the *whole word* as written; only
# CSV words get an entry here (grepped against
# docs/data/rr_regeneration_report_2026-09-15.md's 146-row ambiguous-liaison
# table -- Codex review, PR #327), plus the handful this module's test
# vectors also need.
_WORD_OVERRIDES = {
    "학여울": "hangnyeoul",
    "담요": "damnyo",
    "알약": "allyak",
    "한여름": "hannyeoreum",
    "색연필": "saengnyeonpil",
    "솔잎": "sollip",
    "집안일": "jibannil",
    # 밟다's ㄼ is the one common lexical exception that keeps ㅂ instead of
    # the usual ㄹ (표준발음법 10항 다만): 밟히다 "balpida", not "*bolida".
    "밟히다": "balpida",
}

# 표준발음법 §15 받침 뒤에 모음으로 시작된 *실질형태소* (independent lexical
# morpheme, not a grammatical particle/ending) 가 결합되는 경우: the coda
# is first neutralized to its representative sound, THEN that neutralized
# consonant liaises into the next syllable -- unlike a grammatical
# suffix/particle, which liaises with the coda's own written jamo (읽어
# "ilgeo", 없이 "eopsi" keep the stem's own consonant because -어/-이 there
# are endings, not separate words). 맛없다 [마덥따]: 맛's own coda is ㅅ, but
# 없다 is an independent word, so 맛's ㅅ neutralizes to [ㄷ] before liaising
# -> "ma" + "deopda", not the plain-liaison "ma" + "seopda". 맛있다/맛있어요
# are the standard-pronunciation *exception* to this same environment
# ([마싣따], not *[마딛따]) and need no override -- the CSV's existing
# "masitda"/"masisseoyo" (plain liaison, ㅅ kept) are already correct.
_NEUTRALIZATION_OVERRIDES = {
    "맛없다": "madeopda",
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

        # 1a) Reverse aspiration merge: stem-final ㅎ/ㄶ/ㅀ + ㄱ/ㄷ/ㅈ ending
        #     (표기법 §3-1-4 다만) -- always fires, no POS gate needed: this
        #     shape only ever occurs at a native verb/adjective stem's own
        #     final consonant (좋다, 많다, 싫다, 않다, 괜찮다, 옳지 ...),
        #     never inside a noun. A complex final (ㄶ/ㅀ) keeps its non-ㅎ
        #     component as this syllable's coda (많다 -> "man" + "ta").
        if l_jong in _H_COMPLEX_KEEP and r_cho in _H_PLUS_STOP_TO_ASPIRATE:
            left[2] = _H_COMPLEX_KEEP[l_jong]
            right[0] = -1
            right.append(_H_PLUS_STOP_TO_ASPIRATE[r_cho])  # type: ignore[arg-type]
            _tag("aspiration_merge")
            continue

        # 1b) Forward aspiration merge: stop coda + ㅎ. This shape is
        #     ambiguous on jamo alone -- it merges for a native verb's own
        #     passive/causative -히-/-혀- infix (먹히다 "meokida", 잡혀
        #     "japyeo") but keeps ㅎ before the noun-forming auxiliary 하다
        #     (하/해/했, POS-independent: 반박하다 "banbakhada" even though
        #     the whole word is tagged Verb) or a 하다-stem's own
        #     word-final -히 adverb (정확히 "jeonghwakhi"), and keeps ㅎ for
        #     any other 체언 as a fallback (묵호 "Mukho", 집현전
        #     "Jiphyeonjeon") -- Fable ruling 2026-09-15 (표기법 §3-1-4
        #     다만 + NIKL/Wiktionary RR module precedent).
        if l_jong in _STOP_TO_ASPIRATE and r_cho == _CHO_H:
            is_word_final_h = (i + 1) == len(run) - 1
            certain = r_jung in _HADA_AUX_VOWELS or (r_jung == _JUNG_I and is_word_final_h)
            keep_h = certain or cheoneon
            if not certain:
                # Neither POS-independent sub-rule fired -- this boundary's
                # outcome rests entirely on the row-level `cheoneon` flag,
                # which for a multiword/expression row (수저 놓다, 역할을
                # 나누다, ...) is the whole row's POS, not this token's own
                # (Codex review, PR #327). regenerate_romanization.py uses
                # this tag to hold such rows at their live value instead of
                # trusting the per-row POS fallback for an embedded token.
                _tag("cheoneon_pos_fallback")
            if not keep_h:
                aspirate = _STOP_TO_ASPIRATE[l_jong]
                if l_jong == 7 and r_jung == _JUNG_I:  # 굳히다 -> further palatalizes
                    aspirate = "ch"
                left[2] = 0
                right[0] = -1  # sentinel: onset replaced wholesale below
                right.append(aspirate)  # type: ignore[arg-type]
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
    # not the neutralized coda class (옷이 -> osi, not odi). Tense finals
    # (ㄲ/ㅆ) keep their tenseness on the moved onset instead of collapsing
    # to the plain letter -- 섞이다 "seokkida", 밖에서 "bakkeseo", 깎아
    # "kkakka" (ㄲ -> "kk", matching the ㄲ *initial* consonant letter in
    # `_CHO`); ㅆ -> "ss" was already correct (있어요 "isseoyo").
    onset_letter = {
        1: "g", 2: "kk", 4: "n", 7: "d", 8: "r", 16: "m", 17: "b",
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
    if word in _NEUTRALIZATION_OVERRIDES:
        if rules is not None:
            rules.append("neutralization_override")
        return _NEUTRALIZATION_OVERRIDES[word]
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


# Sino-Korean words the ambiguous-liaison heuristic below over-flags (a coda
# immediately before a y-glide/이 syllable -- the same surface shape as a
# real ㄴ-첨가 candidate) but that are a single, well-established lexeme
# with unambiguous plain-liaison pronunciation, never a real insertion
# candidate. Listed here purely so regenerate_romanization.py's
# manual-review hold doesn't also block an unrelated certain-rule fix
# elsewhere in the same CSV row (e.g. 읽음 확인's ㄺ-liaison fix, blocked by
# 확인 alone) -- `_romanize_word` needs no entry for these since the
# default computation is already correct.
_CONFIRMED_PLAIN_LIAISON = frozenset(("확인",))

# Tense (경음) codas liaise with their own written jamo (섞이다 "seokkida",
# 있어요 "isseoyo") exactly like any other simple coda -- see the
# onset_letter table in `_liaise` -- and are never themselves a ㄴ-첨가
# candidate (사잇소리/ㄴ 첨가 examples are only ever documented for plain
# obstruent/sonorant finals). Excluded from the ambiguous-liaison flag below
# so a tense-coda fix isn't held back as "manual review".
_TENSE_JONG = frozenset((2, 20))  # ㄲ, ㅆ


def find_ambiguous_liaison_words(text: str) -> list[str]:
    """Words in `text` (not already resolved via `_WORD_OVERRIDES` or
    `_CONFIRMED_PLAIN_LIAISON`) that have a non-tense coda immediately
    before an unlinked y-glide/이 syllable -- the surface pattern that is
    plain liaison for a single Sino-Korean word (특약 -> teugyak) but
    ㄴ-첨가 for a native compound (알약 -> allyak, 담요 -> damnyo). Used by
    regenerate_romanization.py to flag rows for manual review; see module
    docstring."""

    flagged = []
    for word in text.strip().split():
        if word in _WORD_OVERRIDES or word in _CONFIRMED_PLAIN_LIAISON:
            continue
        for run in _decode(word):
            for i in range(len(run) - 1):
                l_jong, r_cho, r_jung = run[i][2], run[i + 1][0], run[i + 1][1]
                if (
                    l_jong not in (0, 21)
                    and l_jong not in _TENSE_JONG
                    and r_cho == _CHO_NULL
                    and (r_jung in _JUNG_Y_GLIDES or r_jung == _JUNG_I)
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
