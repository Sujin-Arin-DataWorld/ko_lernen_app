"""Dependency-free language handling for deterministic grammar analysis."""

from __future__ import annotations

import json
import os
import re
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


def detect_grammar(text: str, language: object = "de") -> list[dict[str, Any]]:
    """Detect Korean grammar and localize its learner-facing explanation."""
    lang = normalize_language(language)
    output: list[dict[str, Any]] = []
    seen: set[str] = set()
    for pattern in _load_grammar_patterns():
        pattern_id = pattern.get("id", "")
        if pattern_id in seen:
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
        if lang == "en":
            name = pattern.get("name_en") or f"Korean grammar ({pattern_id})"
            explanation = pattern.get("explanation_en") or (
                "This Korean grammar pattern was detected in the selected text."
            )
        else:
            name = pattern.get("name_de") or pattern_id
            explanation = pattern.get("explanation_de") or ""
        output.append(
            {
                "id": pattern_id,
                # Legacy response keys stay stable for Flutter model compatibility.
                "nameDe": name,
                "matched": match.group(0),
                "level": pattern.get("level", "A2"),
                "explanationDe": explanation,
            }
        )
    return output
