"""Compact Revised Romanization helper for Hangul Sori draft rows."""

from __future__ import annotations

_CHO = ["g", "kk", "n", "d", "tt", "r", "m", "b", "pp", "s", "ss", "", "j", "jj", "ch", "k", "t", "p", "h"]
_JUNG = [
    "a", "ae", "ya", "yae", "eo", "e", "yeo", "ye", "o", "wa", "wae", "oe",
    "yo", "u", "wo", "we", "wi", "yu", "eu", "ui", "i",
]
_JONG = [
    "", "k", "k", "ks", "n", "nj", "nh", "t", "l", "lg", "lm", "lb", "ls", "lt",
    "lp", "lh", "m", "p", "ps", "t", "t", "ng", "t", "t", "k", "t", "p", "t",
]


def romanize_korean(text: str) -> str:
    """Return lowercase RR-style romanization with spaces preserved."""

    pieces: list[str] = []
    for char in text.strip():
        code = ord(char)
        if 0xAC00 <= code <= 0xD7A3:
            syllable = code - 0xAC00
            cho, jung, jong = syllable // 588, (syllable % 588) // 28, syllable % 28
            pieces.append(_CHO[cho] + _JUNG[jung] + _JONG[jong])
        elif char.isspace():
            pieces.append(" ")
        elif char in "-/":
            pieces.append(char)
    compact = "".join(pieces)
    return " ".join(part for part in compact.split() if part)
