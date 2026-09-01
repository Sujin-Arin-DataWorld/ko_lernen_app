#!/usr/bin/env python3
"""Inventory every shipped learning-content data surface.

This is a scope and integrity gate, not a translator.  It prevents a copy
review from silently covering only the familiar five game files while a
learner-facing course label, culture note, pronunciation prompt, or relation
example remains outside review.

Usage:
    python tools/content_factory/audit_content_text.py
    python tools/content_factory/audit_content_text.py --json
    python tools/content_factory/audit_content_text.py --check
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import sys
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "assets" / "data"


@dataclass(frozen=True)
class ContentSurface:
    """One app-shipped content file and the runtime contract that consumes it."""

    name: str
    kind: str
    consumer: str
    record_paths: tuple[str, ...]
    review_scope: str


# Keep this explicit.  A new file in assets/data must be classified deliberately
# instead of being assumed to be a harmless implementation detail.
SURFACES: tuple[ContentSurface, ...] = (
    ContentSurface(
        "can_do_content_authorities.json",
        "course-proof authority",
        "CanonicalCourseSegmentLoader",
        ("sourceSeeds", "contentReferences"),
        "IDs and course ownership; no learner prose",
    ),
    ContentSurface(
        "can_do_segments.json",
        "course can-do catalog",
        "CanonicalCourseSegmentLoader",
        ("segments", "contentClusters", "trackEditions", "releaseTracks"),
        "KO/DE/EN title and can-do descriptions",
    ),
    ContentSurface(
        "cloze.json",
        "cloze game",
        "ClozeLoader / DailyChallengeScreen",
        ("items",),
        "KO answer context, DE/EN gloss, distractor uniqueness",
    ),
    # F6 (2026-09-01): content_audit_manifest.json은 번들 제외를 위해
    # assets/data/ 밖 tools/content_factory/ 로 옮겼다 — 이 감사기는
    # assets/data/ 만 훑으므로(build_inventory 참고) 더는 대상이 아니다.
    ContentSurface(
        "culture_notes.json",
        "culture notes",
        "CultureNotesService",
        ("notes",),
        "KO/DE/EN cultural mediation",
    ),
    ContentSurface(
        "curriculum_manifest.json",
        "curriculum graph",
        "CurriculumCatalog",
        ("courseUnits", "concepts", "surfaceForms", "formFamilies", "contentLinks"),
        "KO/DE/EN unit, concept, and form explanations",
    ),
    ContentSurface(
        "grammar.csv",
        "grammar catalog",
        "DataLoader / GrammarScreen",
        ("rows",),
        "KO examples and independent DE/EN explanations",
    ),
    ContentSurface(
        "grammar_patterns.json",
        "book-analysis grammar support",
        "BookAnalysisService",
        ("root",),
        "DE/EN pattern names and explanations",
    ),
    ContentSurface(
        "kkeunmari_pool.json",
        "word-chain pool",
        "KkeunmariEngine",
        ("words",),
        "curated Korean headwords and German glosses",
    ),
    ContentSurface(
        "korean_vocab.csv",
        "vocabulary catalog and packs",
        "DataLoader / VocabPackService / ReviewDeckService",
        ("rows",),
        "headwords, examples, and independent DE/EN glosses",
    ),
    ContentSurface(
        "media_phrases.json",
        "media phrase activity",
        "DataLoader",
        ("phrases",),
        "KO/DE/EN phrase meaning and context",
    ),
    ContentSurface(
        "pronunciation_phrases.json",
        "pronunciation activity",
        "PronunciationPhraseLoader",
        ("phrases",),
        "KO prompt and DE/EN learner guidance",
    ),
    ContentSurface(
        "satz_sentences.json",
        "sentence-building game",
        "SatzLoader / SatzArcadeScreen",
        ("items",),
        "target Ko, DE/EN prompt, and token assembly contract",
    ),
    ContentSurface(
        "scenarios_a1.json",
        "scenario shard",
        "ScenarioLoader",
        ("scenarios",),
        "dialogue, quests, and localized scenario metadata",
    ),
    ContentSurface(
        "scenarios_a2.json",
        "scenario shard",
        "ScenarioLoader",
        ("scenarios",),
        "dialogue, quests, and localized scenario metadata",
    ),
    ContentSurface(
        "scenarios_b1.json",
        "scenario shard",
        "ScenarioLoader",
        ("scenarios",),
        "dialogue, quests, and localized scenario metadata",
    ),
    ContentSurface(
        "scenarios_b2.json",
        "scenario shard",
        "ScenarioLoader",
        ("scenarios",),
        "dialogue, quests, and localized scenario metadata",
    ),
    ContentSurface(
        "scenarios_c1.json",
        "scenario shard",
        "ScenarioLoader",
        ("scenarios",),
        "dialogue, quests, and localized scenario metadata",
    ),
    ContentSurface(
        "scenarios_c2.json",
        "scenario shard",
        "ScenarioLoader",
        ("scenarios",),
        "dialogue, quests, and localized scenario metadata",
    ),
    ContentSurface(
        "silben_puzzles.json",
        "syllable puzzle",
        "SilbenPuzzleLoader",
        ("levels",),
        "Korean answers and German examples",
    ),
    ContentSurface(
        "smalltalk.json",
        "small-talk activity",
        "SmalltalkLoader",
        ("categories", "phrases"),
        "turn intent, relationship, safe alternatives, and follow-ups",
    ),
    ContentSurface(
        "word_relations.json",
        "word-web activity",
        "WordRelationService",
        ("clusters",),
        "synonyms, antonyms, relations, and example sentences",
    ),
)

# Only fields that can appear as learner-facing or pedagogical copy belong in
# the text count.  This whitelist deliberately excludes semantic hashes,
# lineage IDs, routes, and other opaque strings from the can-do authority
# ledger: they are data, but not copy a humanizer should rewrite.
COPY_KEYS = frozenset({
    "answer", "audioKo", "body", "canDo", "de", "description", "en",
    "english", "exampleDe", "exampleEn", "exampleKo", "example_english",
    "example_german", "example_korean", "explanation", "explanation_de",
    "explanation_en", "followUp", "fullKo", "german", "grammarBlock",
    "korean", "ko", "label", "meaning", "name_de", "name_en", "note",
    "note_en", "options", "pattern", "prefix", "promptDe", "promptEn",
    "quiz_focus_de", "quiz_focus_en", "reply", "sentence", "sentenceKo",
    "suffix", "targetKo", "targetWord", "title", "type_de", "type_en",
    "usageContext", "vocabKo", "word",
})
UNRESOLVED_MARKER = re.compile(r"(?:^|\W)(?:TODO|TBD|FIXME)(?:$|\W)", re.IGNORECASE)

LANGUAGE_KEYS = {
    "ko": frozenset({
        "answer", "audioKo", "exampleKo", "example_korean", "fullKo",
        "ko", "korean", "sentenceKo", "targetKo", "targetWord",
        "vocabKo", "word",
    }),
    "de": frozenset({
        "de", "exampleDe", "example_german", "german", "name_de",
        "promptDe", "quiz_focus_de", "type_de",
    }),
    "en": frozenset({
        "en", "english", "exampleEn", "example_english", "name_en",
        "note_en", "promptEn", "quiz_focus_en", "type_en",
    }),
}
MULTILINGUAL_KEY_GROUPS = (
    (("ko",), ("de",), ("en",)),
    (("korean",), ("german",), ("english",)),
    (("exampleKo",), ("exampleDe",), ("exampleEn",)),
    (("example_korean",), ("example_german",), ("example_english", "example_en")),
    (("targetKo",), ("promptDe",), ("promptEn",)),
    (("fullKo",), ("de",), ("en",)),
)
MULTILINGUAL_EXEMPT_FILES = frozenset({"kkeunmari_pool.json", "silben_puzzles.json"})
RECORD_ID_KEYS = ("id", "scenarioId", "unitId", "conceptId", "word", "pattern")


def _read_surface(path: Path) -> Any:
    if path.suffix == ".csv":
        with path.open(encoding="utf-8-sig", newline="") as handle:
            return list(csv.DictReader(handle))
    return json.loads(path.read_text(encoding="utf-8"))


def _language_for_key(key: str) -> str:
    for language, keys in LANGUAGE_KEYS.items():
        if key in keys:
            return language
    return "shared"


def _record_context(
    value: dict[str, Any],
    *,
    record_id: str,
    level: str,
) -> tuple[str, str]:
    next_id = record_id
    for key in RECORD_ID_KEYS:
        candidate = value.get(key)
        if isinstance(candidate, str) and candidate.strip():
            next_id = candidate.strip()
            break
    candidate_level = value.get("level")
    next_level = (
        candidate_level.strip().lower()
        if isinstance(candidate_level, str) and candidate_level.strip()
        else level
    )
    return next_id, next_level


def collect_copy_leaves(value: Any, *, file_name: str) -> list[dict[str, Any]]:
    """Return a deterministic coverage record for every learner-copy leaf."""
    leaves: list[dict[str, Any]] = []

    def visit(
        item: Any,
        *,
        path: str,
        key: str,
        record_id: str,
        level: str,
    ) -> None:
        if isinstance(item, dict):
            next_id, next_level = _record_context(
                item,
                record_id=record_id,
                level=level,
            )
            for child_key, child in item.items():
                visit(
                    child,
                    path=f"{path}.{child_key}",
                    key=child_key,
                    record_id=next_id,
                    level=next_level,
                )
            return
        if isinstance(item, list):
            for index, child in enumerate(item):
                visit(
                    child,
                    path=f"{path}[{index}]",
                    key=key,
                    record_id=record_id,
                    level=level,
                )
            return
        if not isinstance(item, str) or key not in COPY_KEYS:
            return
        encoded = item.encode("utf-8")
        leaves.append({
            "file": file_name,
            "recordId": record_id or path.rsplit(".", 1)[0],
            "level": level or "unscoped",
            "fieldPath": path,
            "field": key,
            "language": _language_for_key(key),
            "text": item,
            "sha256": hashlib.sha256(encoded).hexdigest(),
            "coverageState": "catalogued" if item.strip() else "catalogued_blank",
        })

    visit(value, path="$", key="", record_id="", level="")
    return leaves


def find_incomplete_language_triplets(
    value: Any,
    *,
    file_name: str,
) -> list[dict[str, Any]]:
    """Find direct learner objects whose nonblank Korean lacks DE or EN."""
    gaps: list[dict[str, Any]] = []

    if file_name in MULTILINGUAL_EXEMPT_FILES:
        return gaps

    def first_text(item: dict[str, Any], keys: tuple[str, ...]) -> str | None:
        for key in keys:
            candidate = item.get(key)
            if isinstance(candidate, str):
                return candidate
        return None

    def visit(item: Any, *, path: str, record_id: str, level: str) -> None:
        if isinstance(item, dict):
            next_id, next_level = _record_context(
                item,
                record_id=record_id,
                level=level,
            )
            for ko_keys, de_keys, en_keys in MULTILINGUAL_KEY_GROUPS:
                ko_value = first_text(item, ko_keys)
                de_value = first_text(item, de_keys)
                en_value = first_text(item, en_keys)
                if not ko_value or not ko_value.strip():
                    continue
                # A Korean-only schema node (for example a grammatical surface
                # form) is not a partial translation.  Once either target
                # language is present, however, both are required.
                if de_value is None and en_value is None:
                    continue
                missing = [
                    language for language, target in (("de", de_value), ("en", en_value))
                    if not target or not target.strip()
                ]
                if missing:
                    gaps.append({
                        "file": file_name,
                        "recordId": next_id or path,
                        "level": next_level or "unscoped",
                        "objectPath": path,
                        "missingLanguages": missing,
                    })
            for child_key, child in item.items():
                visit(
                    child,
                    path=f"{path}.{child_key}",
                    record_id=next_id,
                    level=next_level,
                )
            return
        if isinstance(item, list):
            for index, child in enumerate(item):
                visit(
                    child,
                    path=f"{path}[{index}]",
                    record_id=record_id,
                    level=level,
                )

    visit(value, path="$", record_id="", level="")
    return gaps


def _records(value: Any, path: str) -> Iterable[dict[str, Any]]:
    if path == "rows":
        return value if isinstance(value, list) else ()
    if path == "root":
        return value if isinstance(value, list) else ()
    if path == "levels":
        if not isinstance(value, dict) or not isinstance(value.get("levels"), dict):
            return ()
        return (
            record
            for records in value["levels"].values()
            if isinstance(records, list)
            for record in records
            if isinstance(record, dict)
        )
    if not isinstance(value, dict):
        return ()
    records = value.get(path)
    return records if isinstance(records, list) else ()


def _text_audit(value: Any, *, key: str = "") -> tuple[int, int, list[str]]:
    """Return copy leaves, blank copy leaves, and unresolved-marker paths."""
    if isinstance(value, dict):
        totals = [_text_audit(item, key=item_key) for item_key, item in value.items()]
    elif isinstance(value, list):
        totals = [_text_audit(item, key=key) for item in value]
    elif isinstance(value, str) and key in COPY_KEYS:
        return (1, int(not value.strip()), [key] if UNRESOLVED_MARKER.search(value) else [])
    else:
        return (0, 0, [])
    return (
        sum(total[0] for total in totals),
        sum(total[1] for total in totals),
        [marker for total in totals for marker in total[2]],
    )


def _level_counts(records: Iterable[dict[str, Any]]) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for record in records:
        level = record.get("level")
        if isinstance(level, str) and level:
            counts[level.lower()] += 1
    return dict(sorted(counts.items()))


def build_inventory(root: Path = ROOT) -> dict[str, Any]:
    data_dir = root / "assets" / "data"
    actual = {path.name for path in data_dir.iterdir() if path.suffix in {".csv", ".json"}}
    expected = {surface.name for surface in SURFACES}
    files: list[dict[str, Any]] = []

    for surface in SURFACES:
        path = data_dir / surface.name
        if not path.exists():
            files.append({"path": surface.name, "error": "missing"})
            continue
        value = _read_surface(path)
        record_sets = [list(_records(value, record_path)) for record_path in surface.record_paths]
        records = [record for record_set in record_sets for record in record_set]
        text_values, blank_values, markers = _text_audit(value)
        leaves = collect_copy_leaves(value, file_name=surface.name)
        language_counts = Counter(leaf["language"] for leaf in leaves)
        leaf_level_counts = Counter(leaf["level"] for leaf in leaves)
        multilingual_gaps = find_incomplete_language_triplets(
            value,
            file_name=surface.name,
        )
        ledger_material = "\n".join(
            f'{leaf["file"]}|{leaf["recordId"]}|{leaf["fieldPath"]}|{leaf["sha256"]}'
            for leaf in leaves
        )
        files.append({
            "path": surface.name,
            "kind": surface.kind,
            "consumer": surface.consumer,
            "recordCollections": list(surface.record_paths),
            "recordCount": len(records),
            "levelCounts": _level_counts(records),
            "textValueCount": text_values,
            "blankTextValueCount": blank_values,
            "copyLeafCountsByLanguage": dict(sorted(language_counts.items())),
            "copyLeafCountsByLevel": dict(sorted(leaf_level_counts.items())),
            "leafLedgerSha256": hashlib.sha256(ledger_material.encode("utf-8")).hexdigest(),
            "multilingualGaps": multilingual_gaps,
            "unresolvedMarkers": markers,
            "reviewScope": surface.review_scope,
        })

    return {
        "schemaVersion": 1,
        "dataDirectory": "assets/data",
        "coveredFiles": len(files),
        "unclassifiedFiles": sorted(actual - expected),
        "missingFiles": sorted(expected - actual),
        "files": files,
        "totals": {
            "records": sum(item.get("recordCount", 0) for item in files),
            "textValues": sum(item.get("textValueCount", 0) for item in files),
            "blankTextValues": sum(item.get("blankTextValueCount", 0) for item in files),
            "multilingualGaps": sum(len(item.get("multilingualGaps", ())) for item in files),
            "unresolvedMarkers": sum(len(item.get("unresolvedMarkers", ())) for item in files),
        },
    }


def _print_human(inventory: dict[str, Any]) -> None:
    print(
        "{covered} shipped data files | {records} records | {text} text values".format(
            covered=inventory["coveredFiles"],
            records=inventory["totals"]["records"],
            text=inventory["totals"]["textValues"],
        )
    )
    for item in inventory["files"]:
        print(
            "- {path}: {records} records; {text} text values; {consumer}".format(
                path=item["path"],
                records=item.get("recordCount", "missing"),
                text=item.get("textValueCount", "-"),
                consumer=item.get("consumer", "unclassified"),
            )
        )
    if inventory["unclassifiedFiles"]:
        print("UNCLASSIFIED: " + ", ".join(inventory["unclassifiedFiles"]))
    if inventory["missingFiles"]:
        print("MISSING: " + ", ".join(inventory["missingFiles"]))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="emit machine-readable inventory")
    parser.add_argument("--check", action="store_true", help="fail on uncovered data or unresolved markers")
    args = parser.parse_args(argv)
    inventory = build_inventory()
    if args.json:
        print(json.dumps(inventory, ensure_ascii=False, indent=2))
    else:
        _print_human(inventory)
    if args.check and (
        inventory["unclassifiedFiles"]
        or inventory["missingFiles"]
        or inventory["totals"]["multilingualGaps"]
        or inventory["totals"]["unresolvedMarkers"]
    ):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
