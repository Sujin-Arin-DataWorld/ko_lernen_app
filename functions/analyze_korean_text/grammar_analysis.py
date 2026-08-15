"""Dependency-free language handling for deterministic grammar analysis."""

from __future__ import annotations

import json
import os
import re
from collections.abc import Sequence
from functools import lru_cache
from typing import Any


def normalize_language(value: object) -> str:
    """Return the app's supported language code, defaulting safely to German."""
    if not isinstance(value, str):
        return "de"
    normalized = value.strip().lower().replace("_", "-")
    if normalized == "en" or normalized.startswith("en-"):
        return "en"
    if normalized == "de" or normalized.startswith("de-"):
        return "de"
    return "de"


def localize_pos_tag(tag: str, language: object = "de") -> str:
    """Return the learner-facing part-of-speech label."""
    labels = {
        "de": {
            "NNG": "Nomen",
            "NNP": "Nomen",
            "VV": "Verb",
            "VA": "Adjektiv",
        },
        "en": {
            "NNG": "Noun",
            "NNP": "Noun",
            "VV": "Verb",
            "VA": "Adjective",
        },
    }
    lang = normalize_language(language)
    return labels[lang].get(tag, "Wort" if lang == "de" else "Word")


@lru_cache(maxsize=1)
def _load_grammar_patterns() -> list[dict[str, Any]]:
    path = os.path.join(os.path.dirname(__file__), "grammar_patterns.json")
    try:
        with open(path, encoding="utf-8") as pattern_file:
            return json.load(pattern_file)
    except (FileNotFoundError, json.JSONDecodeError, TypeError):
        return []


def _spans_overlap(first: tuple[int, int], second: tuple[int, int]) -> bool:
    return first[0] < second[1] and second[0] < first[1]


def _token_tag(token: object) -> str:
    return str(getattr(token, "tag", "")).split(".")[-1]


def _localized_pattern_result(
    pattern: dict[str, Any],
    matched: str,
    language: str,
) -> dict[str, Any]:
    pattern_id = str(pattern.get("id", ""))
    if language == "en":
        name = pattern.get("name_en") or f"Korean grammar ({pattern_id})"
        explanation = pattern.get("explanation_en") or (
            "This Korean grammar pattern was detected in the selected text."
        )
    else:
        name = pattern.get("name_de") or pattern_id
        explanation = pattern.get("explanation_de") or ""
    return {
        "id": pattern_id,
        # Legacy response keys stay stable for Flutter compatibility.
        "nameDe": name,
        "matched": matched,
        "level": pattern.get("level", "A2"),
        "explanationDe": explanation,
    }


def _attributive_candidates(
    text: str,
    tokens: Sequence[object],
    patterns: dict[str, dict[str, Any]],
    language: str,
) -> list[dict[str, Any]]:
    """Detect attributive endings from explicit morphology evidence.

    A surface ``는`` or ``은`` is ambiguous with particles.  We only emit a
    card for the strict ``VV/VA + ETM + noun`` sequence supplied by Kiwi.  This
    keeps topic/object particles fail-closed while distinguishing descriptive
    present ``좋은`` from action-verb past ``먹은``.
    """

    noun_tags = {"NNG", "NNP", "NNB", "NP", "NR"}
    seen: set[str] = set()
    results: list[dict[str, Any]] = []
    for index in range(1, len(tokens) - 1):
        stem = tokens[index - 1]
        ending = tokens[index]
        noun = tokens[index + 1]
        stem_tag = _token_tag(stem)
        if (
            stem_tag not in {"VV", "VA"}
            or _token_tag(ending) != "ETM"
            or _token_tag(noun) not in noun_tags
        ):
            continue

        ending_form = str(getattr(ending, "form", ""))
        if ending_form == "는" and stem_tag == "VV":
            pattern_id = "g_attribute_present"
        elif ending_form in {"ᆫ", "ㄴ", "은"}:
            pattern_id = (
                "g_attribute_present" if stem_tag == "VA" else "g_attribute_past"
            )
        elif ending_form in {"ᆯ", "ㄹ", "을"}:
            pattern_id = "g_attribute_future"
        else:
            continue
        if pattern_id in seen or pattern_id not in patterns:
            continue

        start = getattr(stem, "start", None)
        noun_start = getattr(noun, "start", None)
        noun_length = getattr(noun, "len", None)
        if (
            not isinstance(start, int)
            or not isinstance(noun_start, int)
            or not isinstance(noun_length, int)
        ):
            continue
        end = noun_start + noun_length
        if start < 0 or end <= start or end > len(text):
            continue
        matched = text[start:end].strip()
        if not matched:
            continue
        results.append(
            _localized_pattern_result(patterns[pattern_id], matched, language)
        )
        seen.add(pattern_id)
    return results


def detect_grammar(
    text: str,
    language: object = "de",
    *,
    tokens: Sequence[object] | None = None,
) -> list[dict[str, Any]]:
    """Detect grammar only when the configured detector has enough evidence.

    This lightweight path has regular-expression evidence only. Patterns such
    as Korean attributive endings are marked for a morphology detector and are
    therefore skipped instead of guessing from a surface syllable that may be
    a topic or object particle. A more specific overlapping pattern can also
    declare that it supersedes a generic one.
    """
    lang = normalize_language(language)
    all_patterns = _load_grammar_patterns()
    patterns_by_id = {
        str(pattern.get("id", "")): pattern
        for pattern in all_patterns
        if isinstance(pattern, dict)
    }
    candidates: list[
        tuple[dict[str, Any], re.Match[str], dict[str, Any]]
    ] = []
    seen: set[str] = set()
    for pattern in all_patterns:
        pattern_id = pattern.get("id", "")
        if pattern_id in seen:
            continue
        if pattern.get("detector", "regex") != "regex":
            continue
        regex = pattern.get("regex", "")
        if not regex:
            continue
        try:
            match = re.search(regex, text)
        except (re.error, TypeError):
            continue
        if match is None:
            continue

        seen.add(pattern_id)
        candidates.append(
            (
                pattern,
                match,
                _localized_pattern_result(pattern, match.group(0), lang),
            )
        )

    suppressed: set[int] = set()
    for specific_index, (specific, specific_match, _) in enumerate(candidates):
        raw_supersedes = specific.get("supersedes", [])
        if not isinstance(raw_supersedes, list):
            continue
        supersedes = {item for item in raw_supersedes if isinstance(item, str)}
        if not supersedes:
            continue
        for generic_index, (generic, generic_match, _) in enumerate(candidates):
            if generic_index == specific_index:
                continue
            if generic.get("id") not in supersedes:
                continue
            if _spans_overlap(specific_match.span(), generic_match.span()):
                suppressed.add(generic_index)

    results = [
        result
        for index, (_, _, result) in enumerate(candidates)
        if index not in suppressed
    ]
    if tokens:
        results.extend(
            _attributive_candidates(text, tokens, patterns_by_id, lang)
        )
    return results
