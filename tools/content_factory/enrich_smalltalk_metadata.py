#!/usr/bin/env python3
"""Add relationship-safe conversation metadata to the small-talk corpus.

This tool enriches the checked-in asset in place without rebuilding the corpus,
so source IDs and native-reviewed wording remain intact.

Usage:
    python tools/content_factory/enrich_smalltalk_metadata.py --write
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets" / "data" / "smalltalk.json"
RELATIONSHIP_CONTEXTS = {
    "peer",
    "classmate",
    "coworker",
    "close_friend",
    "family",
    "service",
}
TURN_KINDS = {"question", "response", "reaction"}


def turn(kind: str, ko: str, de: str, en: str) -> dict[str, str]:
    return {"turnKind": kind, "ko": ko, "de": de, "en": en}


DEFAULT_CONTEXT_BY_CATEGORY = {
    "work_study": "coworker",
    "family": "family",
    "hospital": "service",
    "dating": "close_friend",
}

DEFAULT_TURNS = {
    "peer": {
        "alternative": turn(
            "question",
            "요즘 어떻게 지내세요?",
            "Wie geht es dir in letzter Zeit?",
            "How have you been lately?",
        ),
        "follow_up": turn("reaction", "그렇군요.", "Ach so.", "I see."),
    },
    "classmate": {
        "alternative": turn(
            "question",
            "수업은 어때요?",
            "Wie läuft der Kurs?",
            "How is the class going?",
        ),
        "follow_up": turn("reaction", "그렇군요.", "Ach so.", "I see."),
    },
    "coworker": {
        "alternative": turn(
            "question",
            "요즘 일은 어때요?",
            "Wie läuft die Arbeit gerade?",
            "How is work going lately?",
        ),
        "follow_up": turn("reaction", "그렇군요.", "Ach so.", "I see."),
    },
    "close_friend": {
        "alternative": turn(
            "question",
            "요즘 어떻게 지내?",
            "Wie geht's dir in letzter Zeit?",
            "How have you been lately?",
        ),
        "follow_up": turn("reaction", "아, 그렇구나.", "Ach so.", "Oh, I see."),
    },
    "family": {
        "alternative": turn(
            "question",
            "요즘 잘 지내?",
            "Geht es dir gut in letzter Zeit?",
            "Have you been doing well lately?",
        ),
        "follow_up": turn("reaction", "아, 그렇구나.", "Ach so.", "Oh, I see."),
    },
    "service": {
        "alternative": turn(
            "question",
            "필요하신 점이 있으세요?",
            "Kann ich Ihnen bei etwas helfen?",
            "Is there anything I can help you with?",
        ),
        "follow_up": turn(
            "response",
            "네, 알겠습니다.",
            "Ja, verstanden.",
            "Yes, I understand.",
        ),
    },
}

# The same invitation intent is practiced through four register choices. These
# keep the existing IDs and corpus size stable while making relationship and
# safe alternatives explicit for A2.
REGISTER_OVERRIDES: dict[str, dict[str, Any]] = {
    "smalltalk_a2_0003": {
        "kind": "question",
        "ko": "이번 주말에 같이 산책할까요?",
        "de": "Wollen wir dieses Wochenende zusammen spazieren gehen?",
        "en": "Shall we go for a walk together this weekend?",
        "reply": {
            "ko": "네, 좋아요. 같이 걸어요.",
            "de": "Ja, gern. Gehen wir zusammen.",
            "en": "Yes, sounds good. Let's go for a walk.",
        },
        "relationshipContext": "classmate",
        "safeAlternativeQuestions": [
            turn(
                "question",
                "이번 주말에 시간 괜찮으세요?",
                "Haben Sie dieses Wochenende Zeit?",
                "Do you have time this weekend?",
            ),
        ],
        "followUp": turn(
            "reaction",
            "좋아요. 시간 정해 봐요.",
            "Gerne. Lassen wir uns eine Zeit ausmachen.",
            "Great. Let's pick a time.",
        ),
    },
    "smalltalk_a2_0004": {
        "kind": "question",
        "ko": "점심 같이 먹을래요?",
        "de": "Wollen wir zusammen Mittag essen?",
        "en": "Would you like to have lunch together?",
        "reply": {
            "ko": "좋아요. 같이 먹어요.",
            "de": "Gerne. Essen wir zusammen.",
            "en": "Sure. Let's eat together.",
        },
        "relationshipContext": "peer",
        "safeAlternativeQuestions": [
            turn(
                "question",
                "점심 시간 괜찮으세요?",
                "Passt Ihnen die Mittagspause?",
                "Does lunchtime work for you?",
            ),
        ],
        "followUp": turn(
            "reaction",
            "좋아요. 어디로 갈까요?",
            "Gut. Wohin gehen wir?",
            "Great. Where should we go?",
        ),
    },
    "smalltalk_a2_0015": {
        "kind": "question",
        "ko": "주말에 같이 뭐 할래?",
        "de": "Was wollen wir am Wochenende zusammen machen?",
        "en": "What do you want to do together this weekend?",
        "reply": {
            "ko": "좋아. 전시회 보러 가고 싶어.",
            "de": "Ja. Ich hätte Lust auf eine Ausstellung.",
            "en": "Yeah. I'd like to go to an exhibition.",
        },
        "relationshipContext": "close_friend",
        "safeAlternativeQuestions": [
            turn(
                "question",
                "이번 주말에 시간 있어?",
                "Hast du dieses Wochenende Zeit?",
                "Are you free this weekend?",
            ),
        ],
        "followUp": turn(
            "reaction",
            "좋아. 같이 알아보자.",
            "Super. Suchen wir zusammen etwas aus.",
            "Great. Let's look for something together.",
        ),
    },
    "smalltalk_a2_0022": {
        "kind": "opener",
        "ko": "오늘은 여기서 같이 공부하자.",
        "de": "Lass uns heute hier zusammen lernen.",
        "en": "Let's study here together today.",
        "reply": None,
        "relationshipContext": "close_friend",
        "safeAlternativeQuestions": [
            turn(
                "question",
                "오늘은 여기서 같이 공부할래?",
                "Wollen wir heute hier zusammen lernen?",
                "Want to study here together today?",
            ),
        ],
        "followUp": turn(
            "reaction",
            "좋아, 그럼 시작하자.",
            "Klar, dann legen wir los.",
            "Okay, then let's start.",
        ),
    },
}


def is_complete_turn(value: object, *, question_only: bool = False) -> bool:
    if not isinstance(value, dict):
        return False
    if value.get("turnKind") not in TURN_KINDS:
        return False
    if question_only and value.get("turnKind") != "question":
        return False
    return all(str(value.get(language, "")).strip() for language in ("ko", "de", "en"))


def enrich_phrase(phrase: dict[str, Any]) -> None:
    category = phrase.get("category")
    context = phrase.get("relationshipContext")
    if context not in RELATIONSHIP_CONTEXTS:
        context = DEFAULT_CONTEXT_BY_CATEGORY.get(category, "peer")
    phrase["relationshipContext"] = context

    alternatives = phrase.get("safeAlternativeQuestions")
    if not isinstance(alternatives, list) or not alternatives or not all(
        is_complete_turn(item, question_only=True) for item in alternatives
    ):
        phrase["safeAlternativeQuestions"] = [DEFAULT_TURNS[context]["alternative"]]

    if not is_complete_turn(phrase.get("followUp")):
        phrase["followUp"] = DEFAULT_TURNS[context]["follow_up"]

    override = REGISTER_OVERRIDES.get(phrase["id"])
    if override is None:
        return
    for key, value in override.items():
        if key == "reply" and value is None:
            phrase.pop("reply", None)
        else:
            phrase[key] = value


def load_source() -> dict[str, Any]:
    with SOURCE.open(encoding="utf-8") as file:
        source = json.load(file)
    if not isinstance(source, dict) or not isinstance(source.get("phrases"), list):
        raise ValueError(f"{SOURCE} must contain a top-level phrases list")
    return source


def validate(source: dict[str, Any]) -> None:
    phrases = source["phrases"]
    ids = [phrase.get("id") for phrase in phrases if isinstance(phrase, dict)]
    if len(ids) != len(phrases) or any(not isinstance(item, str) or not item for item in ids):
        raise ValueError("every small-talk phrase must have a non-empty explicit id")
    if len(set(ids)) != len(ids):
        raise ValueError("small-talk phrase ids must be unique")
    missing_overrides = set(REGISTER_OVERRIDES) - set(ids)
    if missing_overrides:
        raise ValueError(f"missing A2 register IDs: {sorted(missing_overrides)}")

    for phrase in phrases:
        if not isinstance(phrase, dict):
            raise ValueError("every phrase must be an object")
        phrase_id = phrase["id"]
        if phrase.get("relationshipContext") not in RELATIONSHIP_CONTEXTS:
            raise ValueError(f"invalid relationship context: {phrase_id}")
        alternatives = phrase.get("safeAlternativeQuestions")
        if not isinstance(alternatives, list) or not alternatives or not all(
            is_complete_turn(item, question_only=True) for item in alternatives
        ):
            raise ValueError(f"invalid safe alternative: {phrase_id}")
        if not is_complete_turn(phrase.get("followUp")):
            raise ValueError(f"invalid follow-up: {phrase_id}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--write", action="store_true", help="write the enriched source asset"
    )
    args = parser.parse_args()

    source = load_source()
    for phrase in source["phrases"]:
        if not isinstance(phrase, dict):
            raise ValueError("every phrase must be an object")
        enrich_phrase(phrase)
    validate(source)

    print(
        f"validated {len(source['phrases'])} small-talk nodes with relationship "
        "context, safe alternative questions, and follow-up turns"
    )
    if args.write:
        with SOURCE.open("w", encoding="utf-8", newline="\n") as file:
            # Preserve the corpus's existing one-space JSON indentation so the
            # metadata enrichment stays reviewable as an additive diff.
            json.dump(source, file, ensure_ascii=False, indent=1)
            file.write("\n")
        print(f"wrote {SOURCE}")
    else:
        print("dry run; pass --write to update the asset")


if __name__ == "__main__":
    main()
