"""Shared authoring helpers for review-only Batch 17.

The helpers keep Korean, German and English together at the smallest authored
unit.  They do not translate or invent text at build time.
"""

from __future__ import annotations

from typing import Any


def tri(ko: str, de: str, en: str) -> dict[str, str]:
    return {"ko": ko, "de": de, "en": en}


def turn(speaker: str, ko: str, de: str, en: str) -> dict[str, str]:
    return {"speaker": speaker, **tri(ko, de, en)}


def exercise(
    ko: str,
    de: str,
    en: str,
    *,
    answer: str,
    distractors: list[str],
    satz_distractors: list[str],
    focus: str,
) -> dict[str, Any]:
    return {
        **tri(ko, de, en),
        "answer": answer,
        "distractors": distractors,
        "satzDistractors": satz_distractors,
        "focus": focus,
    }


def smalltalk(
    *,
    category: str,
    kind: str,
    relationship: str,
    ko: str,
    de: str,
    en: str,
    reply: tuple[str, str, str],
    alternative: tuple[str, str, str],
    follow_up: tuple[str, str, str],
) -> dict[str, Any]:
    return {
        "category": category,
        "kind": kind,
        "relationshipContext": relationship,
        **tri(ko, de, en),
        "reply": tri(*reply),
        "safeAlternativeQuestions": [
            {"turnKind": "question", **tri(*alternative)}
        ],
        "followUp": {"turnKind": "reaction", **tri(*follow_up)},
    }
