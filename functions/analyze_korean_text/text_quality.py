"""Deterministic quality gate for mixed-language textbook OCR.

The book scanner is meant to analyse Korean source text.  Textbook pages often
contain German or English instructions next to that source, and OCR can also
emit characters from an unrelated script.  This module keeps the Korean source
segments, while preserving Latin words that are embedded in a Korean sentence
(for example, ``Berlin에`` or ``K-pop을``).

No user text is logged here.  Callers should surface the returned warnings so a
learner can retake or edit a low-quality scan instead of silently saving it.
"""

from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass

_HANGUL_SUPPORTED_RE = re.compile(
    r"[\u1100-\u11ff\u3130-\u318f\ua960-\ua97f\uac00-\ud7a3\ud7b0-\ud7ff]"
)
_HANGUL_SYLLABLE_RE = re.compile(r"[\uac00-\ud7a3]")
_SENTENCE_BOUNDARY_RE = re.compile(r"(?<=[.!?。！？])\s+")
_LATIN_LABEL_PREFIX_RE = re.compile(
    r"^[^\u1100-\u11ff\u3130-\u318f\ua960-\ua97f\uac00-\ud7a3\ud7b0-\ud7ff]*"
    r"[:：=|]\s*"
    r"(?=[\s\S]*[\u1100-\u11ff\u3130-\u318f\ua960-\ua97f\uac00-\ud7a3\ud7b0-\ud7ff])"
)
_LATIN_BRACKET_PREFIX_RE = re.compile(
    r"^\s*[\[(][^\]\)]*[\])]\s*"
    r"(?=[\s\S]*[\u1100-\u11ff\u3130-\u318f\ua960-\ua97f\uac00-\ud7a3\ud7b0-\ud7ff])"
)
_LATIN_BRACKET_SUFFIX_RE = re.compile(
    r"\s*[\[(][^\u1100-\u11ff\u3130-\u318f\ua960-\ua97f\uac00-\ud7a3\ud7b0-\ud7ff]*"
    r"[\])]\s*$"
)
_LATIN_TRAILING_GLOSS_RE = re.compile(
    r"(?:\s+[-\u2013\u2014]\s+|\s*[:;|=]\s*)"
    r"[A-Za-z\u00c0-\u024f][A-Za-z\u00c0-\u024f0-9\s.,!?\'\"/\-\u2013\u2014]*$"
)
@dataclass(frozen=True)
class PreparedKoreanText:
    """Korean analysis input and stable machine-readable quality warnings."""

    text: str
    warnings: tuple[str, ...]


def contains_hangul(text: str) -> bool:
    """Return whether NFC text contains an analysable Hangul syllable."""

    normalized = unicodedata.normalize("NFC", text or "")
    return _HANGUL_SYLLABLE_RE.search(normalized) is not None


def _is_supported_character(character: str) -> bool:
    """Apply the same explicit textbook-character ranges as the Dart client.

    Format/control characters are rejected before this function is called.
    CJK punctuation is allowed, while CJK ideographs and unrelated scripts are
    deliberately excluded.
    """

    if character.isspace():
        return True
    if _HANGUL_SUPPORTED_RE.search(character):
        return True
    codepoint = ord(character)
    return (
        0x0020 <= codepoint <= 0x024F
        or 0x0300 <= codepoint <= 0x036F
        or 0x1D00 <= codepoint <= 0x1EFF
        or 0x2000 <= codepoint <= 0x206F
        or 0x20A0 <= codepoint <= 0x20CF
        or 0x2100 <= codepoint <= 0x214F
        or 0x3000 <= codepoint <= 0x303F
        or 0xFF01 <= codepoint <= 0xFF65
    )


def _is_forbidden_format_character(character: str) -> bool:
    codepoint = ord(character)
    return (
        codepoint in {0x00AD, 0x061C, 0x200B, 0x200C, 0x200D, 0x200E, 0x200F, 0xFEFF}
        or 0x202A <= codepoint <= 0x202E
        or 0x2060 <= codepoint <= 0x206F
        or (unicodedata.category(character).startswith("C") and character not in "\r\n\t")
    )


def _filter_supported_characters(text: str) -> tuple[str, bool]:
    filtered: list[str] = []
    removed = False
    replacing_unsupported_run = False
    last_was_whitespace = True
    for character in text:
        if _is_forbidden_format_character(character):
            removed = True
            continue
        if not _is_supported_character(character):
            removed = True
            replacing_unsupported_run = True
            continue

        is_whitespace = character.isspace()
        if (
            replacing_unsupported_run
            and not last_was_whitespace
            and not is_whitespace
            and filtered
        ):
            filtered.append(" ")
            last_was_whitespace = True
        replacing_unsupported_run = False

        if is_whitespace:
            if not last_was_whitespace and filtered:
                filtered.append("\n" if character in "\r\n" else " ")
                last_was_whitespace = True
        else:
            filtered.append(character)
            last_was_whitespace = False
    return "".join(filtered).strip(), removed


def _trim_non_korean_affixes(segment: str) -> tuple[str, bool]:
    """Remove clear translated labels around an otherwise Korean segment."""

    original = segment
    segment = _LATIN_LABEL_PREFIX_RE.sub("", segment, count=1)

    prefix_match = _LATIN_BRACKET_PREFIX_RE.match(segment)
    if prefix_match and not contains_hangul(prefix_match.group(0)):
        segment = segment[prefix_match.end():]

    suffix_match = _LATIN_BRACKET_SUFFIX_RE.search(segment)
    if suffix_match and contains_hangul(segment[:suffix_match.start()]):
        segment = segment[:suffix_match.start()]

    trailing_match = _LATIN_TRAILING_GLOSS_RE.search(segment)
    if trailing_match and contains_hangul(segment[:trailing_match.start()]):
        segment = segment[:trailing_match.start()]

    segment = re.sub(r"\s+", " ", segment).strip()
    return segment, segment != original.strip()


def prepare_korean_analysis_text(raw_text: str) -> PreparedKoreanText:
    """Prepare OCR text for Korean-only linguistic analysis.

    Pure German/English lines and sentence segments are ignored.  Latin text is
    retained when it belongs to the same Korean segment. Unsupported-script
    letters are removed before any downstream morphology or translation call.
    """

    normalized = unicodedata.normalize("NFC", raw_text or "")
    normalized = normalized.replace("\r\n", "\n").replace("\r", "\n")
    filtered, unexpected_script_removed = _filter_supported_characters(normalized)

    kept: list[str] = []
    non_korean_ignored = False
    for line in filtered.splitlines():
        line = re.sub(r"[ \t]+", " ", line).strip()
        if not line:
            continue
        for segment in _SENTENCE_BOUNDARY_RE.split(line):
            segment = segment.strip()
            if not segment:
                continue
            segment, affix_removed = _trim_non_korean_affixes(segment)
            if affix_removed:
                non_korean_ignored = True
            if contains_hangul(segment):
                kept.append(segment)
            else:
                non_korean_ignored = True

    prepared_text = "\n".join(kept).strip()
    warnings: list[str] = []
    if non_korean_ignored:
        warnings.append("non_korean_segments_ignored")
    if unexpected_script_removed:
        warnings.append("unexpected_script_filtered")
    if not prepared_text:
        warnings.append("no_korean_text")

    return PreparedKoreanText(prepared_text, tuple(warnings))


def split_korean_sentences(text: str) -> list[str]:
    """Split reflowed Korean source without treating every OCR line as a sentence."""

    prepared = prepare_korean_analysis_text(text).text
    if not prepared:
        return []
    reflowed = re.sub(r"(?<![.!?。！？])\n+", " ", prepared)
    return [
        part.strip()
        for part in _SENTENCE_BOUNDARY_RE.split(reflowed)
        if contains_hangul(part)
    ]
