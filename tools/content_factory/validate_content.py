#!/usr/bin/env python3
"""Fail-fast validation for the bundled learning-content graph.

This is deliberately dependency-free so an editor can run it before Flutter.
It validates the on-disk assets, not AI output: draft content must first pass
Jin's review and then be applied by ``apply_review.py``.

Usage:
    python3 tools/content_factory/validate_content.py
    python3 tools/content_factory/validate_content.py --json
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "assets" / "data"

LOWER_LEVELS = frozenset(("a1", "a2", "b1", "b2", "c1", "c2"))
UPPER_LEVELS = frozenset(level.upper() for level in LOWER_LEVELS)
SILBEN_REQUIRED_LEVELS = frozenset(("A1", "A2", "B1", "B2"))
SCENARIO_STYLES = frozenset(("polite", "casual", "business", "intimate"))
CONTENT_KINDS = frozenset(
    ("vocab", "grammar", "scenario", "smalltalk", "cloze", "satz")
)
CONTENT_LINK_ROLES = frozenset(("introduce", "practice", "assess", "review"))
VOCAB_HEADER = [
    "korean",
    "romanization",
    "german",
    "level",
    "pos_de",
    "example_korean",
    "example_german",
    "topic",
    "pack_id",
    "pack_order",
    "is_review_boss",
    "english",
    "pos_en",
    "example_english",
    "id",
]
GRAMMAR_HEADER = [
    "pattern",
    "level",
    "type_de",
    "explanation_de",
    "example_korean",
    "example_german",
    "note",
    "type_en",
    "explanation_en",
    "example_en",
    "note_en",
    "id",
    "quiz_focus_de",
    "quiz_focus_en",
    "quiz_enabled",
    "quiz_distractor_ids",
]

# These shipped rows predate the level-ID contract.  Keeping the exception
# explicit means future generated rows cannot silently repeat the mistake.
LEGACY_VOCAB_LEVEL_EXCEPTIONS = frozenset(
    (
        "vocab_b1_0013",
        "vocab_b1_0192",
        "vocab_b1_0195",
        "vocab_b2_0089",
        "vocab_b2_0094",
        "vocab_b2_0095",
        "vocab_b2_0109",
        "vocab_b2_0110",
        "vocab_b2_0111",
        "vocab_b2_0112",
        "vocab_b2_0113",
        "vocab_b2_0116",
        "vocab_b2_0117",
        "vocab_b2_0118",
        "vocab_b2_0145",
        "vocab_b2_0146",
    )
)

# Existing content was authored before the hearing-quest requirement.  Every
# new scenario must have one; this baseline allowlist makes that ratchet real.
LEGACY_SCENARIOS_WITHOUT_HEARING = frozenset(("hotel_checkin",))

REQUIRED_MANIFEST_KINDS = frozenset(
    (
        "vocab",
        "grammar",
        "scenario",
        "scenarioQuest",
        "smalltalk",
        "cloze",
        "satz",
        "silben",
        "kkeunmari",
        "grammarPattern",
        "pronunciation",
    )
)

MANIFEST_SOURCE_FILES = {
    "vocab": "korean_vocab.csv",
    "grammar": "grammar.csv",
    "scenario": "scenarios.json",
    "scenarioQuest": "scenarios.json",
    "smalltalk": "smalltalk.json",
    "cloze": "cloze.json",
    "satz": "satz_sentences.json",
    "silben": "silben_puzzles.json",
    "kkeunmari": "kkeunmari_pool.json",
    "grammarPattern": "grammar_patterns.json",
    "pronunciation": "pronunciation_phrases.json",
}


@dataclass(frozen=True)
class Issue:
    source: str
    message: str

    def to_json(self) -> dict[str, str]:
        return {"source": self.source, "message": self.message}


class ContentValidator:
    def __init__(self, root: Path = ROOT) -> None:
        self.root = root
        self.data = root / "assets" / "data"
        self.issues: list[Issue] = []

    def issue(self, source: str, message: str) -> None:
        self.issues.append(Issue(source, message))

    def load_json(self, name: str) -> Any:
        path = self.data / name
        try:
            with path.open(encoding="utf-8") as handle:
                return json.load(handle)
        except (OSError, json.JSONDecodeError) as error:
            self.issue(name, f"cannot load JSON: {error}")
            return None

    def load_csv(self, name: str) -> tuple[list[str], list[dict[str, str]]]:
        path = self.data / name
        try:
            with path.open(encoding="utf-8", newline="") as handle:
                reader = csv.DictReader(handle)
                header = list(reader.fieldnames or [])
                rows = list(reader)
        except OSError as error:
            self.issue(name, f"cannot load CSV: {error}")
            return [], []
        for number, row in enumerate(rows, start=2):
            if None in row:
                self.issue(name, f"row {number} has more columns than its header")
        return header, rows

    def validate(self) -> list[Issue]:
        vocab = self.validate_vocab()
        grammar = self.validate_grammar()
        scenarios = self.validate_scenarios(grammar)
        self.validate_cloze()
        self.validate_satz(vocab)
        self.validate_smalltalk()
        self.validate_silben()
        self.validate_kkeunmari()
        self.validate_grammar_patterns()
        self.validate_pronunciation()
        self.validate_curriculum_graph()
        self.validate_audit_manifest(vocab, grammar, scenarios)
        return self.issues

    def validate_vocab(self) -> dict[str, str]:
        name = "korean_vocab.csv"
        header, rows = self.load_csv(name)
        if header != VOCAB_HEADER:
            self.issue(name, f"expected exact 15-column header, got {header!r}")
            return {}

        by_id: dict[str, str] = {}
        by_korean: set[str] = set()
        packs: dict[str, list[dict[str, str]]] = defaultdict(list)
        for number, row in enumerate(rows, start=2):
            label = f"row {number}"
            if any(not (row.get(field) or "").strip() for field in VOCAB_HEADER):
                self.issue(name, f"{label} has an empty required field")
            level = (row.get("level") or "").upper()
            if level not in UPPER_LEVELS:
                self.issue(name, f"{label} has invalid level {row.get('level')!r}")
            ident = (row.get("id") or "").strip()
            if not re.fullmatch(r"vocab_(a1|a2|b1|b2|c1|c2)_\d+", ident):
                self.issue(name, f"{label} has invalid vocab id {ident!r}")
            elif ident.split("_")[1].upper() != level and ident not in LEGACY_VOCAB_LEVEL_EXCEPTIONS:
                self.issue(name, f"{label} id level disagrees with row level: {ident} vs {level}")
            if ident in by_id:
                self.issue(name, f"duplicate id {ident!r} at {label} and {by_id[ident]}")
            else:
                by_id[ident] = label
            korean = (row.get("korean") or "").strip()
            if korean and korean in by_korean:
                self.issue(name, f"duplicate Korean headword {korean!r} at {label}")
            by_korean.add(korean)
            pack_id = (row.get("pack_id") or "").strip()
            if not pack_id.startswith(f"{level.lower()}_"):
                self.issue(name, f"{label} pack_id {pack_id!r} does not match {level}")
            try:
                if int(row.get("pack_order") or "") < 1:
                    raise ValueError
            except ValueError:
                self.issue(name, f"{label} has invalid pack_order {row.get('pack_order')!r}")
            if (row.get("is_review_boss") or "").lower() not in ("true", "false"):
                self.issue(name, f"{label} is_review_boss must be true or false")
            packs[pack_id].append(row)

        for pack_id, words in sorted(packs.items()):
            levels = {(word.get("level") or "").strip() for word in words}
            if len(levels) != 1:
                self.issue(name, f"pack {pack_id!r} mixes levels {sorted(levels)}")
            bosses = sum(
                (word.get("is_review_boss") or "").lower() == "true"
                for word in words
            )
            if bosses not in (2, 3):
                self.issue(name, f"pack {pack_id!r} has {bosses} Boss words; expected 2 or 3")
        return {row["korean"]: row["level"].lower() for row in rows if row.get("korean")}

    def validate_grammar(self) -> dict[str, dict[str, str]]:
        name = "grammar.csv"
        header, rows = self.load_csv(name)
        if header != GRAMMAR_HEADER:
            self.issue(name, f"expected exact 16-column header, got {header!r}")
            return {}
        by_id: dict[str, dict[str, str]] = {}
        for number, row in enumerate(rows, start=2):
            label = f"row {number}"
            if any(not (row.get(field) or "").strip() for field in GRAMMAR_HEADER[:15]):
                self.issue(name, f"{label} has an empty required field")
            ident = (row.get("id") or "").strip()
            level = (row.get("level") or "").lower()
            if not re.fullmatch(r"grammar_(a1|a2|b1|b2|c1|c2)_[a-z0-9_]+", ident):
                self.issue(name, f"{label} has invalid grammar id {ident!r}")
            elif ident.split("_")[1] != level:
                self.issue(
                    name,
                    f"{label} id level disagrees with row level: {ident} vs {level}",
                )
            if ident in by_id:
                self.issue(name, f"duplicate id {ident!r}")
            else:
                by_id[ident] = row
            if (row.get("level") or "").upper() not in UPPER_LEVELS:
                self.issue(name, f"{label} has invalid level {row.get('level')!r}")
            enabled = (row.get("quiz_enabled") or "").lower()
            if enabled not in ("true", "false"):
                self.issue(name, f"{label} quiz_enabled must be true or false")
            if self._occurrences(row.get("example_german", ""), row.get("quiz_focus_de", "")) != 1:
                self.issue(name, f"{label} quiz_focus_de must occur once in example_german")
            if self._occurrences(row.get("example_en", ""), row.get("quiz_focus_en", "")) != 1:
                self.issue(name, f"{label} quiz_focus_en must occur once in example_en")
            distractors = self._split_ids(row.get("quiz_distractor_ids", ""))
            if enabled == "true" and (len(distractors) != 3 or len(set(distractors)) != 3 or ident in distractors):
                self.issue(name, f"{label} enabled quiz needs three unique non-self distractors")
            if enabled == "false" and distractors:
                self.issue(name, f"{label} disabled quiz must not expose distractors")
        for ident, row in by_id.items():
            if row.get("quiz_enabled", "").lower() != "true":
                continue
            for distractor_id in self._split_ids(row.get("quiz_distractor_ids", "")):
                distractor = by_id.get(distractor_id)
                if distractor is None:
                    self.issue(name, f"{ident} references unknown distractor {distractor_id}")
                    continue
                if distractor.get("level") != row.get("level"):
                    self.issue(name, f"{ident} distractor {distractor_id} is not same-level")
                if distractor.get("quiz_enabled") != "true":
                    self.issue(name, f"{ident} distractor {distractor_id} is not quiz-enabled")
        return by_id

    def validate_scenarios(
        self,
        grammar: dict[str, dict[str, str]],
    ) -> list[dict[str, Any]]:
        name = "scenarios.json"
        root = self.load_json(name)
        if not isinstance(root, dict) or not isinstance(root.get("scenarios"), list):
            self.issue(name, "root must contain a scenarios array")
            return []
        version = root.get("version")
        if type(version) is not int or version < 1:
            self.issue(name, "root version must be a positive integer")
        manifest = self.load_json("curriculum_manifest.json")
        unit_ids = {
            str(unit.get("id"))
            for unit in (manifest.get("courseUnits", []) if isinstance(manifest, dict) else [])
            if isinstance(unit, dict)
        }
        seen: set[str] = set()
        scenarios: list[dict[str, Any]] = []
        for index, scenario in enumerate(root["scenarios"]):
            label = f"scenario {index}"
            if not isinstance(scenario, dict):
                self.issue(name, f"{label} is not an object")
                continue
            scenarios.append(scenario)
            raw_ident = scenario.get("id")
            if not isinstance(raw_ident, str):
                self.issue(name, f"{label} id must be a string")
                ident = f"<invalid scenario {index}>"
            else:
                ident = raw_ident.strip()
            if not re.fullmatch(r"[a-z0-9_]+", ident):
                self.issue(name, f"{label} has invalid id {ident!r}")
            if ident in seen:
                self.issue(name, f"duplicate id {ident!r}")
            seen.add(ident)
            level = scenario.get("level")
            if not isinstance(level, str) or level.lower() not in LOWER_LEVELS:
                self.issue(name, f"{ident} level must be an A1-C2 string")
            self._localized(name, f"{ident}.title", scenario.get("title"), require_ko=False)
            self._localized(name, f"{ident}.intro", scenario.get("intro"), require_ko=False)
            self._localized(name, f"{ident}.grammarBlock.title", self._nested(scenario, "grammarBlock", "title"), require_ko=False)
            self._localized(name, f"{ident}.grammarBlock.explanation", self._nested(scenario, "grammarBlock", "explanation"), require_ko=False)
            vocab = scenario.get("vocab")
            dialog = scenario.get("dialog")
            quests = scenario.get("quests")
            grammar_ids = scenario.get("grammarIds")
            if not isinstance(vocab, list) or len(vocab) < 6:
                self.issue(name, f"{ident} needs at least six vocab entries")
            else:
                self._validate_scenario_vocab(name, ident, vocab)
            if not isinstance(dialog, list) or len(dialog) < 6:
                self.issue(name, f"{ident} needs at least six dialog lines")
            if not isinstance(quests, list) or len(quests) < 3:
                self.issue(name, f"{ident} needs at least three quests")
                quests = []
            if not isinstance(grammar_ids, list) or not grammar_ids:
                self.issue(name, f"{ident} needs at least one grammar id")
            else:
                for grammar_id in grammar_ids:
                    if not isinstance(grammar_id, str) or not grammar_id.strip():
                        self.issue(name, f"{ident} has a non-string grammar id")
                    elif grammar_id not in grammar:
                        self.issue(
                            name,
                            f"{ident} references unknown grammar id {grammar_id!r}",
                        )
            for line_number, line in enumerate(dialog if isinstance(dialog, list) else []):
                if not isinstance(line, dict) or any(
                    not self._is_nonempty_string(line.get(field))
                    for field in ("speaker", "ko", "de", "en")
                ):
                    self.issue(name, f"{ident}.dialog[{line_number}] must have speaker/ko/de/en")
            for quest_number, quest in enumerate(quests):
                self._validate_quest(name, ident, quest_number, quest)
            if ident not in LEGACY_SCENARIOS_WITHOUT_HEARING and not any(
                isinstance(quest, dict) and quest.get("type") == "hoerverstehen" for quest in quests
            ):
                self.issue(name, f"{ident} must include a hoerverstehen quest")
            raw_course_unit_id = scenario.get("courseUnitId")
            course_unit_id = (
                raw_course_unit_id.strip()
                if isinstance(raw_course_unit_id, str)
                else ""
            )
            if not course_unit_id or course_unit_id not in unit_ids:
                self.issue(name, f"{ident} references missing courseUnitId {course_unit_id!r}")
        return scenarios

    def _validate_scenario_vocab(
        self,
        source: str,
        scenario_id: str,
        entries: list[Any],
    ) -> None:
        """Validate the runtime ``VocabRef`` shape, not only its list length.

        ``Scenario.fromJson`` casts every entry to ``Map<String, dynamic>``.
        A scalar entry therefore discards the *whole* scenario in
        ``ScenarioLoader``.  Keep that failure inside the content gate instead
        of allowing a reviewed draft to remove a learner-facing mission.
        """

        for index, entry in enumerate(entries):
            label = f"{scenario_id}.vocab[{index}]"
            if not isinstance(entry, dict):
                self.issue(source, f"{label} must be an object")
                continue
            korean = entry.get("korean")
            if not isinstance(korean, str) or not korean.strip():
                self.issue(source, f"{label}.korean must be a nonempty string")
            for field in ("aliases", "variants"):
                if field not in entry:
                    continue
                values = entry[field]
                if not isinstance(values, list) or any(
                    not isinstance(value, str) or not value.strip()
                    for value in values
                ):
                    self.issue(source, f"{label}.{field} must be an array of nonempty strings")
            if "note" in entry:
                self._localized(
                    source,
                    f"{label}.note",
                    entry["note"],
                    require_ko=False,
                )

    def validate_cloze(self) -> None:
        name = "cloze.json"
        root = self.load_json(name)
        items = root.get("items") if isinstance(root, dict) else None
        if not isinstance(items, list):
            self.issue(name, "root must contain an items array")
            return
        self._validate_game_meta(name, root, items)
        self._validate_game_items(name, items, kind="cloze")

    def validate_satz(self, vocab_levels: dict[str, str]) -> None:
        name = "satz_sentences.json"
        root = self.load_json(name)
        items = root.get("items") if isinstance(root, dict) else None
        if not isinstance(items, list):
            self.issue(name, "root must contain an items array")
            return
        self._validate_game_meta(name, root, items)
        seen: set[str] = set()
        for index, item in enumerate(items):
            label = f"item {index}"
            if not isinstance(item, dict):
                self.issue(name, f"{label} is not an object")
                continue
            raw_ident = item.get("id")
            if not isinstance(raw_ident, str):
                self.issue(name, f"{label} id must be a string")
                ident = f"<invalid satz {index}>"
            else:
                ident = raw_ident.strip()
            if ident in seen:
                self.issue(name, f"duplicate id {ident!r}")
            seen.add(ident)
            raw_level = item.get("level")
            level = raw_level.lower() if isinstance(raw_level, str) else ""
            if level not in LOWER_LEVELS:
                self.issue(name, f"{ident} level must be an A1-C2 string")
            if not re.fullmatch(r"satz_(a1|a2|b1|b2|c1|c2)_\d+", ident):
                self.issue(name, f"{ident} has invalid satz id")
            elif ident.split("_")[1] != level:
                self.issue(name, f"{ident} id level disagrees with {level}")
            for field in ("targetKo", "promptDe", "promptEn", "vocabKo"):
                if not self._is_nonempty_string(item.get(field)):
                    self.issue(name, f"{ident} {field} must be a nonempty string")
            distractors = item.get("distractors")
            if (
                not isinstance(distractors, list)
                or len(distractors) < 2
                or any(not self._is_nonempty_string(value) for value in distractors)
            ):
                self.issue(name, f"{ident} needs at least two nonempty string distractors")
            vocab_level = vocab_levels.get(item.get("vocabKo", ""))
            if vocab_level != level:
                self.issue(name, f"{ident} vocabKo must match exactly one same-level vocab row")

    def _validate_game_meta(
        self,
        source: str,
        root: dict[str, Any],
        items: list[Any],
    ) -> None:
        meta = root.get("meta")
        if not isinstance(meta, dict):
            self.issue(source, "root must contain a meta object")
            return
        if meta.get("total") != len(items):
            self.issue(source, "meta.total must equal the items array length")
        expected = {level: 0 for level in ("a1", "a2", "b1", "b2", "c1", "c2")}
        for item in items:
            if isinstance(item, dict) and item.get("level") in expected:
                expected[str(item["level"])] += 1
        if meta.get("perLevel") != expected:
            self.issue(source, "meta.perLevel must contain exact A1-C2 item counts")

    def validate_smalltalk(self) -> None:
        name = "smalltalk.json"
        root = self.load_json(name)
        if not isinstance(root, dict):
            self.issue(name, "root must be an object")
            return
        version = root.get("version")
        if type(version) is not int or version < 1:
            self.issue(name, "root version must be a positive integer")
        items = root.get("phrases") if isinstance(root, dict) else None
        if not isinstance(items, list):
            self.issue(name, "root must contain a phrases array")
            return
        categories = root.get("categories") if isinstance(root, dict) else None
        category_ids = self._validate_smalltalk_categories(name, categories)
        if not category_ids:
            self.issue(name, "root must contain categorized phrase metadata")
        seen: set[str] = set()
        for index, item in enumerate(items):
            if not isinstance(item, dict):
                self.issue(name, f"phrase {index} is not an object")
                continue
            raw_ident = item.get("id")
            if not isinstance(raw_ident, str):
                self.issue(name, f"phrase {index} id must be a string")
                ident = f"<invalid smalltalk {index}>"
            else:
                ident = raw_ident.strip()
            if ident in seen:
                self.issue(name, f"duplicate id {ident!r}")
            seen.add(ident)
            raw_level = item.get("level")
            level = raw_level.lower() if isinstance(raw_level, str) else ""
            if level not in LOWER_LEVELS:
                self.issue(name, f"{ident} level must be an A1-C2 string")
            if not re.fullmatch(r"smalltalk_(a1|a2|b1|b2|c1|c2)_\d+", ident):
                self.issue(name, f"{ident} has invalid smalltalk id")
            elif ident.split("_")[1] != level:
                self.issue(name, f"{ident} id level disagrees with {level}")
            for field in ("category", "kind", "ko", "de", "en"):
                if not self._is_nonempty_string(item.get(field)):
                    self.issue(name, f"{ident} {field} must be a nonempty string")
            category = item.get("category")
            if isinstance(category, str) and category.strip() not in category_ids:
                self.issue(name, f"{ident} references an unknown category")
            if item.get("kind") not in {"opener", "question", "reaction"}:
                self.issue(name, f"{ident} has unsupported kind {item.get('kind')!r}")
            if item.get("relationshipContext") not in {
                "peer",
                "classmate",
                "coworker",
                "close_friend",
                "family",
                "service",
            }:
                self.issue(name, f"{ident} has invalid relationshipContext")
            self._validate_smalltalk_turns(
                name,
                f"{ident}.safeAlternativeQuestions",
                item.get("safeAlternativeQuestions"),
                only_question=True,
            )
            self._validate_smalltalk_turns(
                name,
                f"{ident}.followUp",
                [item.get("followUp")],
            )
            reply = item.get("reply")
            if item.get("kind") == "question" and reply is None:
                self.issue(name, f"{ident} question needs a reply")
            if reply is not None:
                self._validate_localized_object(name, f"{ident}.reply", reply)

    def _validate_smalltalk_categories(self, source: str, categories: Any) -> set[str]:
        if not isinstance(categories, list):
            return set()
        ids: set[str] = set()
        for index, category in enumerate(categories):
            label = f"category {index}"
            if not isinstance(category, dict):
                self.issue(source, f"{label} is not an object")
                continue
            ident = category.get("id")
            if not self._is_nonempty_string(ident):
                self.issue(source, f"{label}.id must be a nonempty string")
                continue
            if ident in ids:
                self.issue(source, f"duplicate category id {ident!r}")
            ids.add(ident)
            if not self._is_nonempty_string(category.get("emoji")):
                self.issue(source, f"{label}.emoji must be a nonempty string")
            self._localized(source, f"{label}.label", category.get("label"), require_ko=True)
        return ids

    def _validate_smalltalk_turns(
        self,
        source: str,
        label: str,
        turns: Any,
        *,
        only_question: bool = False,
    ) -> None:
        if not isinstance(turns, list) or not turns:
            self.issue(source, f"{label} must be a nonempty array")
            return
        for index, turn in enumerate(turns):
            turn_label = f"{label}[{index}]"
            if not isinstance(turn, dict):
                self.issue(source, f"{turn_label} must be an object")
                continue
            kind = turn.get("turnKind")
            if kind not in {"question", "response", "reaction"}:
                self.issue(source, f"{turn_label}.turnKind is invalid")
            elif only_question and kind != "question":
                self.issue(source, f"{turn_label}.turnKind must be question")
            self._validate_localized_object(source, turn_label, turn)

    def _validate_localized_object(self, source: str, label: str, value: Any) -> None:
        if not isinstance(value, dict):
            self.issue(source, f"{label} must be an object")
            return
        for field in ("ko", "de", "en"):
            if not self._is_nonempty_string(value.get(field)):
                self.issue(source, f"{label}.{field} must be a nonempty string")

    def validate_silben(self) -> None:
        name = "silben_puzzles.json"
        root = self.load_json(name)
        if not isinstance(root, dict):
            self.issue(name, "root must be an object")
            return
        version = root.get("version")
        if type(version) is not int or version < 1:
            self.issue(name, "root version must be a positive integer")
        levels = root.get("levels") if isinstance(root, dict) else None
        if not isinstance(levels, dict):
            self.issue(name, "root must contain a levels object")
            return
        missing_levels = SILBEN_REQUIRED_LEVELS - set(levels)
        if missing_levels:
            self.issue(name, f"missing CEFR level keys: {', '.join(sorted(missing_levels))}")
        seen_ids: set[str] = set()
        for level, puzzles in levels.items():
            if not isinstance(level, str) or level not in UPPER_LEVELS:
                self.issue(name, f"invalid level key {level!r}")
            if not isinstance(puzzles, list):
                self.issue(name, f"{level} must be an array")
                continue
            for puzzle_index, puzzle in enumerate(puzzles):
                if not isinstance(puzzle, dict):
                    self.issue(name, f"{level} contains a non-object puzzle")
                    continue
                raw_ident = puzzle.get("id")
                if not isinstance(raw_ident, str):
                    self.issue(name, f"{level} puzzle {puzzle_index} id must be a string")
                    ident = f"<invalid silben {level}:{puzzle_index}>"
                else:
                    ident = raw_ident.strip()
                if ident in seen_ids:
                    self.issue(name, f"duplicate puzzle id {ident!r}")
                seen_ids.add(ident)
                if not isinstance(level, str) or not re.fullmatch(
                    rf"skz_{level.lower()}_\d+", ident
                ):
                    self.issue(name, f"{ident} does not match level {level}")
                rows, cols = puzzle.get("rows"), puzzle.get("cols")
                if (
                    type(rows) is not int
                    or type(cols) is not int
                    or rows < 1
                    or cols < 1
                ):
                    self.issue(name, f"{ident} needs positive rows and cols")
                    continue
                cells: dict[tuple[int, int], str] = {}
                answers: set[str] = set()
                words = puzzle.get("words")
                if not isinstance(words, list) or not words:
                    self.issue(name, f"{ident} needs a nonempty words array")
                    words = []
                for word_index, word in enumerate(words):
                    if not isinstance(word, dict):
                        self.issue(name, f"{ident} has a non-object word")
                        continue
                    answer = word.get("answer")
                    if not self._is_nonempty_string(answer):
                        self.issue(name, f"{ident} word {word_index} answer must be a nonempty string")
                        continue
                    if not answer or answer in answers:
                        self.issue(name, f"{ident} has an empty or duplicate answer {answer!r}")
                    answers.add(answer)
                    direction = word.get("dir")
                    if direction not in ("h", "v"):
                        self.issue(name, f"{ident}:{answer} has invalid dir {direction!r}")
                        continue
                    row, col = word.get("row"), word.get("col")
                    if type(row) is not int or type(col) is not int:
                        self.issue(name, f"{ident}:{answer} needs integer row/col")
                        continue
                    for field in ("german", "exampleKo", "exampleDe"):
                        if not self._is_nonempty_string(word.get(field)):
                            self.issue(
                                name,
                                f"{ident}:{answer} {field} must be a nonempty string",
                            )
                    for offset, character in enumerate(answer):
                        point = (row, col + offset) if direction == "h" else (row + offset, col)
                        if not (0 <= point[0] < rows and 0 <= point[1] < cols):
                            self.issue(name, f"{ident}:{answer} leaves the grid at {point}")
                            continue
                        previous = cells.setdefault(point, character)
                        if previous != character:
                            self.issue(name, f"{ident}:{answer} conflicts at {point}: {previous!r} vs {character!r}")
                pool = puzzle.get("pool")
                if (
                    not isinstance(pool, list)
                    or not pool
                    or any(not self._is_nonempty_string(item) for item in pool)
                ):
                    self.issue(name, f"{ident} needs a nonempty syllable pool")
                    continue
                available = Counter(pool)
                for syllable in cells.values():
                    if available[syllable] < 1:
                        self.issue(
                            name,
                            f"{ident} pool is missing solution syllable {syllable!r}",
                        )
                    else:
                        available[syllable] -= 1

    def validate_kkeunmari(self) -> None:
        name = "kkeunmari_pool.json"
        root = self.load_json(name)
        words = root.get("words") if isinstance(root, dict) else None
        if not isinstance(words, list):
            self.issue(name, "root must contain a words array")
            return
        seen: set[str] = set()
        by_first: Counter[str] = Counter()
        for item in words:
            raw_word = item.get("word") if isinstance(item, dict) else None
            if isinstance(raw_word, str) and raw_word:
                by_first[raw_word[0]] += 1
        for index, item in enumerate(words):
            if not isinstance(item, dict):
                self.issue(name, f"word {index} is not an object")
                continue
            raw_word = item.get("word")
            if not self._is_nonempty_string(raw_word):
                self.issue(name, f"word {index} word must be a nonempty string")
                continue
            word = raw_word
            if word in seen:
                self.issue(name, f"empty or duplicate word {word!r}")
            seen.add(word)
            raw_level = item.get("level")
            if not isinstance(raw_level, str) or raw_level.upper() not in UPPER_LEVELS:
                self.issue(name, f"{word} level must be an A1-C2 string")
            first = item.get("first")
            last = item.get("last")
            if not self._is_nonempty_string(first):
                self.issue(name, f"{word} first must be a nonempty string")
            elif first != word[0]:
                self.issue(name, f"{word} first syllable is incorrect")
            if not self._is_nonempty_string(last):
                self.issue(name, f"{word} last must be a nonempty string")
            elif last != word[-1]:
                self.issue(name, f"{word} last syllable is incorrect")
            if not isinstance(item.get("german"), str):
                self.issue(name, f"{word} german must be a string")
            if not isinstance(item.get("topic"), str):
                self.issue(name, f"{word} topic must be a string")
            next_count = item.get("next_count")
            if type(next_count) is not int or next_count < 0:
                self.issue(name, f"{word} has invalid next_count")
                continue
            # A word is not a valid reply to itself, but it is only present in
            # this next-syllable bucket when its first and last syllables are
            # the same.  Older data stores the global count with exactly that
            # self-edge removed.
            expected = by_first[word[-1]] - (1 if word[0] == word[-1] else 0)
            if next_count != expected:
                self.issue(name, f"{word} next_count is {next_count}, expected {expected}")
            if not isinstance(item.get("is_dead_end"), bool):
                self.issue(name, f"{word} is_dead_end must be bool")
            elif item["is_dead_end"] != (next_count == 0):
                self.issue(name, f"{word} is_dead_end disagrees with next_count")

    def validate_grammar_patterns(self) -> None:
        name = "grammar_patterns.json"
        items = self.load_json(name)
        if not isinstance(items, list):
            self.issue(name, "root must be an array")
            return
        seen: set[str] = set()
        for index, item in enumerate(items):
            if not isinstance(item, dict):
                self.issue(name, f"item {index} is not an object")
                continue
            raw_ident = item.get("id")
            if not isinstance(raw_ident, str):
                self.issue(name, f"item {index} id must be a string")
                ident = f"<invalid grammar pattern {index}>"
            else:
                ident = raw_ident.strip()
            if not re.fullmatch(r"g_[a-z0-9_]+", ident):
                self.issue(name, f"{ident} has invalid grammar pattern id")
            if not ident or ident in seen:
                self.issue(name, f"empty or duplicate id {ident!r}")
            seen.add(ident)
            level = item.get("level")
            if not isinstance(level, str) or level not in UPPER_LEVELS:
                self.issue(name, f"{ident} level must be an A1-C2 uppercase string")
            for field in ("regex", "name_de", "name_en", "explanation_de", "explanation_en"):
                if not self._is_nonempty_string(item.get(field)):
                    self.issue(name, f"{ident} {field} must be a nonempty string")
            try:
                re.compile(item.get("regex", ""))
            except re.error as error:
                self.issue(name, f"{ident} regex does not compile: {error}")
            except TypeError:
                # The type error is already reported above; preserve a useful
                # fail-fast message instead of leaking an implementation trace.
                self.issue(name, f"{ident} regex must be a string")

        source_path = self.data / name
        mirror_path = self.root / "functions" / "analyze_korean_text" / name
        try:
            source_bytes = source_path.read_bytes()
            mirror_bytes = mirror_path.read_bytes()
        except OSError as error:
            self.issue(name, f"cannot read Cloud Function mirror: {error}")
            return
        if source_bytes != mirror_bytes:
            self.issue(
                name,
                "must byte-match functions/analyze_korean_text/grammar_patterns.json",
            )
        try:
            mirror_items = json.loads(mirror_bytes)
        except json.JSONDecodeError as error:
            self.issue(name, f"Cloud Function mirror contains invalid JSON: {error}")
            return
        if mirror_items != items:
            self.issue(
                name,
                "must have JSON-equivalent Cloud Function grammar patterns",
            )

    def validate_pronunciation(self) -> None:
        name = "pronunciation_phrases.json"
        root = self.load_json(name)
        if not isinstance(root, dict):
            self.issue(name, "root must be an object")
            return
        version = root.get("version")
        if type(version) is not int or version < 1:
            self.issue(name, "root version must be a positive integer")
        items = root.get("phrases") if isinstance(root, dict) else None
        if not isinstance(items, list):
            self.issue(name, "root must contain a phrases array")
            return
        seen: set[str] = set()
        for index, item in enumerate(items):
            if not isinstance(item, dict):
                self.issue(name, f"phrase {index} is not an object")
                continue
            raw_ident = item.get("id")
            if not isinstance(raw_ident, str):
                self.issue(name, f"phrase {index} id must be a string")
                ident = f"<invalid pronunciation {index}>"
            else:
                ident = raw_ident.strip()
            if not re.fullmatch(r"pronunciation_(a1|a2|b1|b2|c1|c2)_\d+", ident):
                self.issue(name, f"invalid id {ident!r}")
            if ident in seen:
                self.issue(name, f"duplicate id {ident!r}")
            seen.add(ident)
            raw_level = item.get("level")
            level = raw_level.lower() if isinstance(raw_level, str) else ""
            if level not in LOWER_LEVELS:
                self.issue(name, f"{ident} level must be an A1-C2 string")
            elif ident.startswith("pronunciation_") and ident.split("_")[1] != level:
                self.issue(name, f"{ident} id level disagrees with {level}")
            for field in ("ko", "de", "en", "focus"):
                if not self._is_nonempty_string(item.get(field)):
                    self.issue(name, f"{ident} {field} must be a nonempty string")

    def validate_curriculum_graph(self) -> None:
        """Fail closed when a reviewed source item has no curriculum route.

        The Flutter catalog performs deeper UI-level checks, but review merges
        happen through this dependency-free script.  In particular, C3 cannot
        append a new vocabulary pack and leave it invisible to the course
        graph.  Keep the source-to-manifest references here so a successful
        ``apply_review.py --apply`` is not a false promise.
        """

        name = "curriculum_manifest.json"
        manifest = self.load_json(name)
        if not isinstance(manifest, dict):
            self.issue(name, "root must be an object")
            return

        unit_concepts = self._curriculum_units(name, manifest)
        concept_ids = self._curriculum_ids(name, manifest, "concepts")
        surface_ids = self._curriculum_ids(name, manifest, "surfaceForms")
        if not unit_concepts or not concept_ids:
            return

        for unit_id, required in unit_concepts.items():
            for concept_id in required:
                if concept_id not in concept_ids:
                    self.issue(
                        name,
                        f"course unit {unit_id!r} references unknown concept {concept_id!r}",
                    )

        _, vocab_rows = self.load_csv("korean_vocab.csv")
        vocab_ids = {
            row.get("id", "").strip()
            for row in vocab_rows
            if self._is_nonempty_string(row.get("id"))
        }
        vocab_packs = {
            self._pack_base(row.get("pack_id", ""))
            for row in vocab_rows
            if self._is_nonempty_string(row.get("pack_id"))
        }
        _, grammar_rows = self.load_csv("grammar.csv")
        grammar_ids = {
            row.get("id", "").strip()
            for row in grammar_rows
            if self._is_nonempty_string(row.get("id"))
        }
        # A malformed header is already reported by validate_grammar; this
        # graph pass still reads defensively during an attempted transaction.

        vocab_map = manifest.get("vocabPackUnitMap")
        mapped_vocab_packs = self._validate_curriculum_string_map(
            name,
            "vocabPackUnitMap",
            vocab_map,
            set(unit_concepts),
        )
        for pack in sorted(vocab_packs - mapped_vocab_packs):
            self.issue(name, f"missing vocabPackUnitMap entry for source pack {pack!r}")

        grammar_rules = self._validate_curriculum_rule_map(
            name,
            "grammarRuleMap",
            manifest.get("grammarRuleMap"),
            unit_concepts,
            concept_ids,
        )
        for grammar_id in sorted(grammar_ids - grammar_rules):
            self.issue(name, f"missing grammarRuleMap entry for {grammar_id!r}")

        smalltalk = self.load_json("smalltalk.json")
        smalltalk_items = (
            smalltalk.get("phrases", []) if isinstance(smalltalk, dict) else []
        )
        smalltalk_ids, smalltalk_keys = self._semantic_source_keys(
            "smalltalk.json",
            smalltalk_items,
            label="phrase",
            semantic_field="category",
        )
        smalltalk_rules = self._validate_curriculum_rule_map(
            name,
            "smalltalkCategoryUnitMap",
            manifest.get("smalltalkCategoryUnitMap"),
            unit_concepts,
            concept_ids,
        )
        for key in sorted(smalltalk_keys - smalltalk_rules):
            self.issue(name, f"missing smalltalkCategoryUnitMap entry for {key!r}")
        self._validate_curriculum_rule_map(
            name,
            "smalltalkCheckpointPhraseMap",
            manifest.get("smalltalkCheckpointPhraseMap"),
            unit_concepts,
            concept_ids,
            known_source_ids=smalltalk_ids,
        )

        cloze = self.load_json("cloze.json")
        cloze_items = cloze.get("items", []) if isinstance(cloze, dict) else []
        cloze_ids, cloze_keys = self._semantic_source_keys(
            "cloze.json",
            cloze_items,
            label="item",
            semantic_field="topic",
        )
        cloze_map = self._validate_curriculum_string_map(
            name,
            "clozeTopicUnitMap",
            manifest.get("clozeTopicUnitMap"),
            set(unit_concepts),
        )
        for key in sorted(cloze_keys - cloze_map):
            self.issue(name, f"missing clozeTopicUnitMap entry for {key!r}")

        scenarios_root = self.load_json("scenarios.json")
        scenarios = (
            scenarios_root.get("scenarios", [])
            if isinstance(scenarios_root, dict)
            else []
        )
        scenario_ids = self._validate_scenario_graph_metadata(
            "scenarios.json",
            scenarios,
            unit_concepts,
            concept_ids,
            surface_ids,
        )

        satz = self.load_json("satz_sentences.json")
        satz_items = satz.get("items", []) if isinstance(satz, dict) else []
        satz_ids = self._ids_from_records("satz_sentences.json", satz_items, "item")

        source_ids_by_kind = {
            "vocab": vocab_ids,
            "grammar": grammar_ids,
            "smalltalk": smalltalk_ids,
            "cloze": cloze_ids,
            "satz": satz_ids,
            "scenario": scenario_ids,
        }
        raw_units = manifest.get("courseUnits")
        if isinstance(raw_units, list):
            for index, unit in enumerate(raw_units):
                if not isinstance(unit, dict):
                    continue
                unit_id = str(unit.get("id") or f"<unit {index}>")
                checkpoints = unit.get("checkpointContentIds")
                if not isinstance(checkpoints, list) or not checkpoints:
                    self.issue(name, f"course unit {unit_id!r} needs checkpointContentIds")
                    continue
                for checkpoint in checkpoints:
                    if not isinstance(checkpoint, str) or checkpoint.count(":") != 1:
                        self.issue(name, f"course unit {unit_id!r} has invalid checkpoint {checkpoint!r}")
                        continue
                    kind, source_id = checkpoint.split(":", 1)
                    known_ids = source_ids_by_kind.get(kind)
                    if known_ids is None or source_id not in known_ids:
                        self.issue(name, f"course unit {unit_id!r} references missing checkpoint {checkpoint!r}")

        self._validate_explicit_content_links(
            name,
            manifest.get("contentLinks"),
            unit_concepts,
            concept_ids,
            source_ids_by_kind,
        )

    def _curriculum_units(
        self,
        source: str,
        manifest: dict[str, Any],
    ) -> dict[str, set[str]]:
        raw_units = manifest.get("courseUnits")
        if not isinstance(raw_units, list):
            self.issue(source, "courseUnits must be an array")
            return {}
        units: dict[str, set[str]] = {}
        for index, unit in enumerate(raw_units):
            label = f"courseUnits[{index}]"
            if not isinstance(unit, dict):
                self.issue(source, f"{label} must be an object")
                continue
            ident = unit.get("id")
            if not self._is_nonempty_string(ident):
                self.issue(source, f"{label}.id must be a nonempty string")
                continue
            if ident in units:
                self.issue(source, f"duplicate course unit id {ident!r}")
            level = unit.get("level")
            if not isinstance(level, str) or level.lower() not in LOWER_LEVELS:
                self.issue(source, f"course unit {ident!r} has invalid level")
            concepts = unit.get("requiredConceptIds")
            if not isinstance(concepts, list) or not concepts or any(
                not self._is_nonempty_string(value) for value in concepts
            ):
                self.issue(
                    source,
                    f"course unit {ident!r} needs nonempty requiredConceptIds",
                )
                units[ident] = set()
            else:
                units[ident] = set(concepts)
        return units

    def _curriculum_ids(
        self,
        source: str,
        manifest: dict[str, Any],
        field: str,
    ) -> set[str]:
        values = manifest.get(field)
        if not isinstance(values, list):
            self.issue(source, f"{field} must be an array")
            return set()
        return self._ids_from_records(source, values, field)

    def _ids_from_records(self, source: str, records: Any, label: str) -> set[str]:
        if not isinstance(records, list):
            self.issue(source, f"{label} must be an array")
            return set()
        ids: set[str] = set()
        for index, record in enumerate(records):
            item_label = f"{label}[{index}]"
            if not isinstance(record, dict):
                self.issue(source, f"{item_label} must be an object")
                continue
            ident = record.get("id")
            if not self._is_nonempty_string(ident):
                self.issue(source, f"{item_label}.id must be a nonempty string")
                continue
            if ident in ids:
                self.issue(source, f"duplicate {label} id {ident!r}")
            ids.add(ident)
        return ids

    def _validate_curriculum_string_map(
        self,
        source: str,
        label: str,
        raw: Any,
        known_units: set[str],
    ) -> set[str]:
        if not isinstance(raw, dict):
            self.issue(source, f"{label} must be an object")
            return set()
        keys: set[str] = set()
        for raw_key, raw_unit in raw.items():
            if not self._is_nonempty_string(raw_key):
                self.issue(source, f"{label} has a non-string key")
                continue
            key = raw_key.strip().lower()
            keys.add(key)
            if not self._is_nonempty_string(raw_unit) or raw_unit not in known_units:
                self.issue(source, f"{label}[{key!r}] references an unknown course unit")
        return keys

    def _validate_curriculum_rule_map(
        self,
        source: str,
        label: str,
        raw: Any,
        units: dict[str, set[str]],
        known_concepts: set[str],
        *,
        known_source_ids: set[str] | None = None,
    ) -> set[str]:
        if not isinstance(raw, dict):
            self.issue(source, f"{label} must be an object")
            return set()
        keys: set[str] = set()
        for raw_key, rule in raw.items():
            if not self._is_nonempty_string(raw_key):
                self.issue(source, f"{label} has a non-string key")
                continue
            key = raw_key.strip()
            keys.add(key)
            if known_source_ids is not None and key not in known_source_ids:
                self.issue(source, f"{label} references unknown source id {key!r}")
            if not isinstance(rule, dict):
                self.issue(source, f"{label}[{key!r}] must be an object")
                continue
            unit = rule.get("courseUnitId")
            if not self._is_nonempty_string(unit) or unit not in units:
                self.issue(source, f"{label}[{key!r}] references an unknown course unit")
                continue
            concepts = rule.get("conceptIds")
            if not isinstance(concepts, list) or not concepts or any(
                not self._is_nonempty_string(value) for value in concepts
            ):
                self.issue(source, f"{label}[{key!r}] needs nonempty conceptIds")
                continue
            for concept in concepts:
                if concept not in known_concepts:
                    self.issue(source, f"{label}[{key!r}] references unknown concept {concept!r}")
                elif concept not in units[unit]:
                    self.issue(
                        source,
                        f"{label}[{key!r}] concept {concept!r} is unrelated to {unit!r}",
                    )
        return keys

    def _semantic_source_keys(
        self,
        source: str,
        records: Any,
        *,
        label: str,
        semantic_field: str,
    ) -> tuple[set[str], set[str]]:
        ids = self._ids_from_records(source, records, label)
        keys: set[str] = set()
        if not isinstance(records, list):
            return ids, keys
        for index, record in enumerate(records):
            if not isinstance(record, dict):
                continue
            level = record.get("level")
            value = record.get(semantic_field)
            if not self._is_nonempty_string(level) or not self._is_nonempty_string(value):
                self.issue(
                    source,
                    f"{label}[{index}] needs string level and {semantic_field} for graph mapping",
                )
                continue
            keys.add(f"{level.strip().lower()}:{value.strip().lower()}")
        return ids, keys

    def _validate_scenario_graph_metadata(
        self,
        source: str,
        records: Any,
        units: dict[str, set[str]],
        known_concepts: set[str],
        known_surfaces: set[str],
    ) -> set[str]:
        scenario_ids = self._ids_from_records(source, records, "scenario")
        if not isinstance(records, list):
            return scenario_ids
        for index, scenario in enumerate(records):
            if not isinstance(scenario, dict):
                continue
            ident = scenario.get("id")
            label = ident if self._is_nonempty_string(ident) else f"scenario {index}"
            unit = scenario.get("courseUnitId")
            if not self._is_nonempty_string(unit) or unit not in units:
                self.issue(source, f"{label} references an unknown courseUnitId")
            for field in ("register", "speechStyle"):
                value = scenario.get(field)
                if not isinstance(value, str) or value not in SCENARIO_STYLES:
                    self.issue(source, f"{label} {field} must be a known speech-style string")
            for field in ("relationshipContext", "intent"):
                if not self._is_nonempty_string(scenario.get(field)):
                    self.issue(source, f"{label} {field} must be a nonempty string")
            concepts = scenario.get("conceptIds")
            if not isinstance(concepts, list) or not concepts or any(
                not self._is_nonempty_string(value) for value in concepts
            ):
                self.issue(source, f"{label} needs nonempty conceptIds")
            else:
                for concept in concepts:
                    if concept not in known_concepts:
                        self.issue(source, f"{label} references unknown concept {concept!r}")
            surfaces = scenario.get("surfaceFormIds")
            if not isinstance(surfaces, list) or any(
                not self._is_nonempty_string(value) for value in surfaces
            ):
                self.issue(source, f"{label} surfaceFormIds must be an array of strings")
            else:
                for surface in surfaces:
                    if surface not in known_surfaces:
                        self.issue(source, f"{label} references unknown surface form {surface!r}")
        return scenario_ids

    def _validate_explicit_content_links(
        self,
        source: str,
        raw: Any,
        units: dict[str, set[str]],
        known_concepts: set[str],
        known_sources: dict[str, set[str]],
    ) -> None:
        if not isinstance(raw, list):
            self.issue(source, "contentLinks must be an array")
            return
        seen: set[tuple[str, str, str, str]] = set()
        for index, link in enumerate(raw):
            label = f"contentLinks[{index}]"
            if not isinstance(link, dict):
                self.issue(source, f"{label} must be an object")
                continue
            kind = link.get("contentKind")
            content_id = link.get("contentId")
            unit = link.get("courseUnitId")
            role = link.get("role")
            if not isinstance(kind, str) or kind not in CONTENT_KINDS:
                self.issue(source, f"{label} has invalid contentKind")
                continue
            if not self._is_nonempty_string(content_id) or content_id not in known_sources[kind]:
                self.issue(source, f"{label} references an unknown {kind} source id")
            if not self._is_nonempty_string(unit) or unit not in units:
                self.issue(source, f"{label} references an unknown course unit")
            if not isinstance(role, str) or role not in CONTENT_LINK_ROLES:
                self.issue(source, f"{label} has invalid role")
            concepts = link.get("conceptIds")
            if not isinstance(concepts, list) or not concepts or any(
                not self._is_nonempty_string(value) for value in concepts
            ):
                self.issue(source, f"{label} needs nonempty conceptIds")
            else:
                for concept in concepts:
                    if concept not in known_concepts:
                        self.issue(source, f"{label} references unknown concept {concept!r}")
            if all(isinstance(value, str) for value in (kind, content_id, unit, role)):
                key = (kind, content_id, unit, role)
                if key in seen:
                    self.issue(source, f"duplicate content link {key!r}")
                seen.add(key)

    @staticmethod
    def _pack_base(pack_id: str) -> str:
        parts = pack_id.strip().lower().split("_")
        if len(parts) > 1 and parts[-1].isdigit():
            parts.pop()
        return "_".join(parts)

    def validate_audit_manifest(
        self,
        vocab_levels: dict[str, str],
        grammar: dict[str, dict[str, str]],
        scenarios: list[dict[str, Any]],
    ) -> None:
        name = "content_audit_manifest.json"
        root = self.load_json(name)
        if not isinstance(root, dict) or not isinstance(root.get("sources"), list):
            self.issue(name, "root must contain a sources array")
            return
        counts = self.inventory_counts(vocab_levels, grammar, scenarios)
        declared: dict[str, int] = {}
        for source in root["sources"]:
            if not isinstance(source, dict):
                self.issue(name, "source entry is not an object")
                continue
            kind = str(source.get("kind", ""))
            count = source.get("count")
            if kind in declared:
                self.issue(name, f"duplicate kind {kind!r}")
            if not isinstance(count, int):
                self.issue(name, f"{kind!r} count must be an integer")
                continue
            expected_source = MANIFEST_SOURCE_FILES.get(kind)
            if expected_source is not None and source.get("source") != expected_source:
                self.issue(
                    name,
                    f"{kind!r} source must be {expected_source!r}",
                )
            if not isinstance(source.get("requiresExplicitId"), bool):
                self.issue(name, f"{kind!r} requiresExplicitId must be bool")
            declared[kind] = count
        missing = REQUIRED_MANIFEST_KINDS - declared.keys()
        extras = declared.keys() - REQUIRED_MANIFEST_KINDS
        if missing:
            self.issue(name, f"missing source kinds: {', '.join(sorted(missing))}")
        if extras:
            self.issue(name, f"unknown source kinds: {', '.join(sorted(extras))}")
        for kind, actual in counts.items():
            if declared.get(kind) != actual:
                self.issue(name, f"{kind} count is {declared.get(kind)!r}, actual is {actual}")

        graph = root.get("graph")
        if not isinstance(graph, dict):
            self.issue(name, "graph must be an object")
            return
        curriculum = self.load_json("curriculum_manifest.json")
        course_units = (
            curriculum.get("courseUnits") if isinstance(curriculum, dict) else None
        )
        form_families = (
            curriculum.get("formFamilies") if isinstance(curriculum, dict) else None
        )
        if not isinstance(course_units, list):
            self.issue(name, "curriculum_manifest.json courseUnits must be an array")
            return
        if not isinstance(form_families, list):
            self.issue(name, "curriculum_manifest.json formFamilies must be an array")
            return
        if graph.get("courseUnits") != len(course_units):
            self.issue(
                name,
                "graph courseUnits is "
                f"{graph.get('courseUnits')!r}, actual is {len(course_units)}",
            )
        actual_by_level = Counter(
            str(unit.get("level", "")).strip().lower()
            for unit in course_units
            if isinstance(unit, dict)
        )
        expected_by_level = {
            level: actual_by_level.get(level, 0) for level in sorted(LOWER_LEVELS)
        }
        declared_by_level = graph.get("courseUnitsByLevel")
        if declared_by_level != expected_by_level:
            self.issue(
                name,
                "graph courseUnitsByLevel is "
                f"{declared_by_level!r}, actual is {expected_by_level!r}",
            )
        if graph.get("formFamilies") != len(form_families):
            self.issue(
                name,
                "graph formFamilies is "
                f"{graph.get('formFamilies')!r}, actual is {len(form_families)}",
            )

    def inventory_counts(
        self,
        vocab_levels: dict[str, str] | None = None,
        grammar: dict[str, dict[str, str]] | None = None,
        scenarios: list[dict[str, Any]] | None = None,
    ) -> dict[str, int]:
        if vocab_levels is None:
            _, rows = self.load_csv("korean_vocab.csv")
            vocab_count = len(rows)
        else:
            vocab_count = len(vocab_levels)
        if grammar is None:
            _, rows = self.load_csv("grammar.csv")
            grammar_count = len(rows)
        else:
            grammar_count = len(grammar)
        if scenarios is None:
            root = self.load_json("scenarios.json")
            scenarios = root.get("scenarios", []) if isinstance(root, dict) else []
        cloze = self.load_json("cloze.json")
        satz = self.load_json("satz_sentences.json")
        smalltalk = self.load_json("smalltalk.json")
        silben = self.load_json("silben_puzzles.json")
        kkeunmari = self.load_json("kkeunmari_pool.json")
        patterns = self.load_json("grammar_patterns.json")
        pronunciation = self.load_json("pronunciation_phrases.json")
        silben_levels = silben.get("levels", {}) if isinstance(silben, dict) else {}
        return {
            "vocab": vocab_count,
            "grammar": grammar_count,
            "scenario": len(scenarios),
            "scenarioQuest": sum(len(item.get("quests", [])) for item in scenarios if isinstance(item, dict)),
            "smalltalk": len(smalltalk.get("phrases", [])) if isinstance(smalltalk, dict) else 0,
            "cloze": len(cloze.get("items", [])) if isinstance(cloze, dict) else 0,
            "satz": len(satz.get("items", [])) if isinstance(satz, dict) else 0,
            "silben": sum(len(items) for items in silben_levels.values() if isinstance(items, list)),
            "kkeunmari": len(kkeunmari.get("words", [])) if isinstance(kkeunmari, dict) else 0,
            "grammarPattern": len(patterns) if isinstance(patterns, list) else 0,
            "pronunciation": len(pronunciation.get("phrases", [])) if isinstance(pronunciation, dict) else 0,
        }

    def _validate_game_items(self, name: str, items: Any, *, kind: str) -> None:
        if not isinstance(items, list):
            return
        seen: set[str] = set()
        for index, item in enumerate(items):
            if not isinstance(item, dict):
                self.issue(name, f"item {index} is not an object")
                continue
            raw_ident = item.get("id")
            if not isinstance(raw_ident, str):
                self.issue(name, f"item {index} id must be a string")
                ident = f"<invalid {kind} {index}>"
            else:
                ident = raw_ident.strip()
            if ident in seen:
                self.issue(name, f"duplicate id {ident!r}")
            seen.add(ident)
            raw_level = item.get("level")
            level = raw_level.lower() if isinstance(raw_level, str) else ""
            if level not in LOWER_LEVELS:
                self.issue(name, f"{ident} level must be an A1-C2 string")
            if not re.fullmatch(r"cloze_(a1|a2|b1|b2|c1|c2)_\d+", ident):
                self.issue(name, f"{ident} has invalid cloze id")
            elif ident.split("_")[1] != level:
                self.issue(name, f"{ident} id level disagrees with {level}")
            if kind == "cloze":
                for field in ("sentenceKo", "answer", "fullKo", "de", "en", "topic"):
                    if not self._is_nonempty_string(item.get(field)):
                        self.issue(name, f"{ident} {field} must be a nonempty string")
                distractors = item.get("distractors")
                if (
                    not isinstance(distractors, list)
                    or len(distractors) < 2
                    or any(not self._is_nonempty_string(value) for value in distractors)
                ):
                    self.issue(name, f"{ident} needs at least two nonempty string distractors")
                sentence = item.get("sentenceKo")
                full = item.get("fullKo")
                answer = item.get("answer")
                if (
                    self._is_nonempty_string(sentence)
                    and self._is_nonempty_string(full)
                    and self._is_nonempty_string(answer)
                    and full.replace(answer, "＿＿＿", 1) != sentence
                ):
                    self.issue(name, f"{ident} sentenceKo must be fullKo with one answer replacement")

    def _validate_quest(self, source: str, scenario_id: str, number: int, quest: Any) -> None:
        label = f"{scenario_id}.quests[{number}]"
        if not isinstance(quest, dict):
            self.issue(source, f"{label} is not an object")
            return
        kind = quest.get("type")
        data = quest.get("data")
        if kind not in {"hoerverstehen", "luecken", "uebersetzen", "particlePop", "batchimDrop", "satzBauen", "diktat", "schreiben"}:
            self.issue(source, f"{label} has unsupported type {kind!r}")
            return
        if not isinstance(data, dict):
            self.issue(source, f"{label} data is not an object")
            return
        if kind == "hoerverstehen":
            self._require_fields(source, label, data, ("audioKo",))
            self._localized_options(source, label, data)
        elif kind == "uebersetzen":
            self._require_fields(source, label, data, ("promptDe", "promptEn"))
            self._korean_options(source, label, data)
        elif kind == "luecken":
            if "___" not in str(data.get("sentence", "")):
                self.issue(source, f"{label} luecken sentence must contain ___")
            self._string_options(source, label, data)
        elif kind == "particlePop":
            if not (str(data.get("prefix", "")) + str(data.get("suffix", ""))).strip():
                self.issue(source, f"{label} particlePop needs prefix or suffix")
            self._require_fields(source, label, data, ("explanationDe", "explanationEn"))
            self._string_options(source, label, data)
        elif kind == "batchimDrop":
            self._require_fields(source, label, data, ("audioKo", "targetWord", "explanationDe", "explanationEn"))
            target = str(data.get("targetWord", ""))
            index = data.get("targetSyllableIndex")
            if not isinstance(index, int) or not 0 <= index < len(target):
                self.issue(source, f"{label} targetSyllableIndex is out of range")
            self._string_options(source, label, data)
        elif kind in {"satzBauen", "diktat"}:
            self._require_fields(source, label, data, ("targetKo", "promptDe", "promptEn"))
            if kind == "satzBauen" and not isinstance(data.get("distractors"), list):
                self.issue(source, f"{label} satzBauen needs distractors")
        elif kind == "schreiben" and not data:
            self.issue(source, f"{label} schreiben needs data")

    def _localized_options(self, source: str, label: str, data: dict[str, Any]) -> None:
        options = data.get("options")
        if not isinstance(options, list) or len(options) < 4:
            self.issue(source, f"{label} needs at least four localized options")
            return
        for option in options:
            if not isinstance(option, dict) or any(not str(option.get(key, "")).strip() for key in ("de", "en")):
                self.issue(source, f"{label} has an incomplete localized option")
        self._correct_index(source, label, data, options)

    def _korean_options(self, source: str, label: str, data: dict[str, Any]) -> None:
        options = data.get("options")
        if not isinstance(options, list) or len(options) < 4:
            self.issue(source, f"{label} needs at least four Korean options")
            return
        for option in options:
            if not isinstance(option, dict) or not str(option.get("ko", "")).strip():
                self.issue(source, f"{label} has an incomplete Korean option")
        self._correct_index(source, label, data, options)

    def _string_options(self, source: str, label: str, data: dict[str, Any]) -> None:
        options = data.get("options")
        if not isinstance(options, list) or len(options) < 4 or any(not str(option).strip() for option in options):
            self.issue(source, f"{label} needs at least four nonempty options")
            return
        self._correct_index(source, label, data, options)

    def _correct_index(self, source: str, label: str, data: dict[str, Any], options: list[Any]) -> None:
        index = data.get("correctIndex")
        if not isinstance(index, int) or not 0 <= index < len(options):
            self.issue(source, f"{label} has an invalid correctIndex")

    def _localized(self, source: str, label: str, value: Any, *, require_ko: bool) -> None:
        if not isinstance(value, dict):
            self.issue(source, f"{label} must be localized text")
            return
        keys = ("ko", "de", "en") if require_ko else ("de", "en")
        for key in keys:
            if not self._is_nonempty_string(value.get(key)):
                self.issue(source, f"{label}.{key} must be a nonempty string")

    @staticmethod
    def _nested(value: dict[str, Any], *keys: str) -> Any:
        current: Any = value
        for key in keys:
            if not isinstance(current, dict):
                return None
            current = current.get(key)
        return current

    def _require_fields(self, source: str, label: str, data: dict[str, Any], fields: Iterable[str]) -> None:
        for field in fields:
            if not self._is_nonempty_string(data.get(field)):
                self.issue(source, f"{label} {field} must be a nonempty string")

    @staticmethod
    def _is_nonempty_string(value: Any) -> bool:
        return isinstance(value, str) and bool(value.strip())

    @staticmethod
    def _split_ids(value: str) -> list[str]:
        return [item.strip() for item in value.split("|") if item.strip()]

    @staticmethod
    def _occurrences(source: str, needle: str) -> int:
        if not needle:
            return 0
        return source.count(needle)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="emit machine-readable results")
    args = parser.parse_args(argv)
    validator = ContentValidator()
    issues = validator.validate()
    if args.json:
        print(json.dumps({"ok": not issues, "issues": [issue.to_json() for issue in issues]}, ensure_ascii=False, indent=2))
    elif issues:
        for issue in issues:
            print(f"ERROR: {issue.source}: {issue.message}", file=sys.stderr)
    else:
        print("OK: Content validation passed.")
    return 0 if not issues else 1


if __name__ == "__main__":
    raise SystemExit(main())
