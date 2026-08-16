"""Revised Romanization helpers for Hangul Sori content drafts."""

from __future__ import annotations

CHO = (
    "g",
    "kk",
    "n",
    "d",
    "tt",
    "r",
    "m",
    "b",
    "pp",
    "s",
    "ss",
    "",
    "j",
    "jj",
    "ch",
    "k",
    "t",
    "p",
    "h",
)
JUNG = (
    "a",
    "ae",
    "ya",
    "yae",
    "eo",
    "e",
    "yeo",
    "ye",
    "o",
    "wa",
    "wae",
    "oe",
    "yo",
    "u",
    "wo",
    "we",
    "wi",
    "yu",
    "eu",
    "ui",
    "i",
)
JONG = (
    "",
    "g",
    "kk",
    "ks",
    "n",
    "nj",
    "nh",
    "d",
    "l",
    "lg",
    "lm",
    "lb",
    "ls",
    "lt",
    "lp",
    "lh",
    "m",
    "b",
    "ps",
    "s",
    "ss",
    "ng",
    "j",
    "ch",
    "k",
    "t",
    "p",
    "h",
)


def has_batchim(syllable: str) -> bool:
    if not syllable:
        return False
    code = ord(syllable[-1])
    if 0xAC00 <= code <= 0xD7A3:
        return (code - 0xAC00) % 28 != 0
    return False


def particle(word: str, after_batchim: str, after_vowel: str) -> str:
    return after_batchim if has_batchim(word) else after_vowel


def eul_reul(word: str) -> str:
    return particle(word, "을", "를")


def i_ga(word: str) -> str:
    return particle(word, "이", "가")


def eun_neun(word: str) -> str:
    return particle(word, "은", "는")


def euro_ro(word: str) -> str:
    if not word:
        return "로"
    code = ord(word[-1])
    if 0xAC00 <= code <= 0xD7A3:
        jong = (code - 0xAC00) % 28
        if jong == 0 or jong == 8:  # no batchim or ㄹ
            return "로"
    return "으로"


def ieyo_yeyo(word: str) -> str:
    return particle(word, "이에요", "예요")


def romanize_syllable(char: str) -> str:
    code = ord(char)
    if not (0xAC00 <= code <= 0xD7A3):
        return char
    value = code - 0xAC00
    cho = value // 588
    jung = (value % 588) // 28
    jong = value % 28
    return f"{CHO[cho]}{JUNG[jung]}{JONG[jong]}"


def romanize(text: str) -> str:
    """Lowercase RR with spaces preserved; skip punctuation."""
    chunks: list[str] = []
    current: list[str] = []
    for char in text.strip():
        if char.isspace():
            if current:
                chunks.append("".join(current))
                current = []
            continue
        if 0xAC00 <= ord(char) <= 0xD7A3:
            current.append(romanize_syllable(char))
        elif char.isalpha():
            current.append(char.lower())
    if current:
        chunks.append("".join(current))
    return " ".join(chunk for chunk in chunks if chunk)
