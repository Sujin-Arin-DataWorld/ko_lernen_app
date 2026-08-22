#!/usr/bin/env python3
"""Build review-only Batch 17: B2-C2 social hot-topic practice.

This is a clean-room authoring batch.  It emits drafts, review ledgers and one
manifest only.  It never writes assets/data, lib, Firebase or TTS output.
"""

from __future__ import annotations

from collections import Counter
import csv
import json
from pathlib import Path
import sys
from typing import Any, Iterable

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from data.batch_17_records import (
    CLOZE_TOPIC_BY_SCENE,
    KOREAN_GRAMMAR_EXPLANATIONS,
    SATZ_VOCAB_BY_SCENE,
    SCENES,
    SMALLTALK_CATEGORIES_BY_SCENE,
)

ROOT = SCRIPT_DIR.parents[1]
BLANK = "＿＿＿"
LEVELS = ("b2", "c1", "c2")
THEMES = ("housing", "work_ai", "migration_demography", "k_culture")
REVIEW_HEADER = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]

DRAFT_PATHS = {
    "scenario": Path("tools/content_factory/drafts/c1_batch17_scenarios_b2_c2.json"),
    "smalltalk": Path("tools/content_factory/drafts/c2_batch17_smalltalk_b2_c2.json"),
    "cloze": Path("tools/content_factory/drafts/c2_batch17_cloze_b2_c2.json"),
    "satz": Path("tools/content_factory/drafts/c2_batch17_satz_b2_c2.json"),
    "pronunciation": Path("tools/content_factory/drafts/c4_batch17_pronunciation_b2_c2.json"),
}
REVIEW_PATHS = {
    "scenario": Path("tools/content_factory/review/c1_batch17_scenarios.csv"),
    "smalltalk": Path("tools/content_factory/review/c2_batch17_smalltalk.csv"),
    "cloze": Path("tools/content_factory/review/c2_batch17_cloze.csv"),
    "satz": Path("tools/content_factory/review/c2_batch17_satz.csv"),
    "pronunciation": Path("tools/content_factory/review/c4_batch17_pronunciation.csv"),
}
MANIFEST_PATH = Path("tools/content_factory/drafts/batch_17_manifest.json")

ID_STARTS = {
    "smalltalk": {"b2": 101, "c1": 33, "c2": 33},
    "cloze": {"b2": 362, "c1": 221, "c2": 221},
    "satz": {"b2": 520, "c1": 223, "c2": 223},
    "pronunciation": {"b2": 5, "c1": 5, "c2": 5},
}
COLLECTIONS = {
    "scenario": "scenarios",
    "smalltalk": "phrases",
    "cloze": "items",
    "satz": "items",
    "pronunciation": "phrases",
}
SMALLTALK_RELATIONSHIP_MAP = {
    "friends": "close_friend",
    "neighbors": "peer",
    "event_volunteers": "peer",
    "culture_project_team": "coworker",
    "governance_board": "coworker",
    "editorial_meeting": "coworker",
    "conference_panel": "coworker",
}


class Batch17Error(ValueError):
    """Raised when an authoring or loader contract would be broken."""


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _mapped_unit(raw: Any) -> str:
    if isinstance(raw, str):
        return raw.strip()
    if isinstance(raw, dict):
        return str(raw.get("courseUnitId") or "").strip()
    return ""


def _levels(records: Iterable[dict[str, Any]]) -> dict[str, int]:
    counts = Counter(str(record["level"]).lower() for record in records)
    return {level: counts[level] for level in LEVELS if counts[level]}


def _check_unique(label: str, values: Iterable[str]) -> None:
    values = list(values)
    duplicates = sorted(value for value, count in Counter(values).items() if count > 1)
    if duplicates:
        raise Batch17Error(f"{label}: duplicate values {duplicates}")


def _quest(scene: dict[str, Any], suffix: str, kind: str, data: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": f"quest_{scene['id']}_{suffix}",
        "type": kind,
        "conceptIds": list(scene["conceptIds"]),
        "data": data,
    }


def _quests(scene: dict[str, Any]) -> list[dict[str, Any]]:
    dialog = scene["dialog"]
    exercises = scene["exercises"]
    gap = exercises[0]
    sentence = gap["ko"].replace(gap["answer"], "___", 1)
    return [
        _quest(scene, "hear", "hoerverstehen", {
            "audioKo": dialog[2]["ko"],
            "options": [
                {"de": dialog[index]["de"], "en": dialog[index]["en"]}
                for index in (0, 2, 4, 6)
            ],
            "correctIndex": 1,
        }),
        _quest(scene, "tr", "uebersetzen", {
            "promptDe": dialog[6]["de"],
            "promptEn": dialog[6]["en"],
            "options": [{"ko": dialog[index]["ko"]} for index in (0, 4, 6, 2)],
            "correctIndex": 2,
        }),
        _quest(scene, "gap", "luecken", {
            "sentence": sentence,
            "options": [gap["answer"], *gap["distractors"]],
            "correctIndex": 0,
        }),
        _quest(scene, "build", "satzBauen", {
            "targetKo": exercises[1]["ko"],
            "promptDe": exercises[1]["de"],
            "promptEn": exercises[1]["en"],
            "distractors": list(exercises[1]["satzDistractors"]),
            "audioKo": exercises[1]["ko"],
        }),
        _quest(scene, "dict", "diktat", {
            "targetKo": exercises[2]["ko"],
            "audioKo": exercises[2]["ko"],
            "promptDe": exercises[2]["de"],
            "promptEn": exercises[2]["en"],
        }),
    ]


def _grammar_rows(root: Path) -> dict[str, dict[str, str]]:
    with (root / "assets/data/grammar.csv").open(encoding="utf-8-sig", newline="") as handle:
        return {row["id"]: row for row in csv.DictReader(handle)}


def _grammar_block(scene: dict[str, Any], grammar: dict[str, dict[str, str]]) -> dict[str, Any]:
    grammar_id = scene["grammarIds"][0]
    row = grammar.get(grammar_id)
    if row is None:
        raise Batch17Error(f"{scene['id']}: unknown grammar {grammar_id}")
    return {
        "title": {
            "ko": row["pattern"],
            "de": f"{row['pattern']}: {row['type_de']}",
            "en": f"{row['pattern']}: {row['type_en']}",
        },
        "explanation": {
            "ko": KOREAN_GRAMMAR_EXPLANATIONS[grammar_id],
            "de": row["explanation_de"],
            "en": row["explanation_en"],
        },
    }


def _validate_source_contracts(root: Path, scenes: list[dict[str, Any]]) -> None:
    if len(scenes) != 12:
        raise Batch17Error(f"expected 12 scenarios, got {len(scenes)}")
    _check_unique("scenario id", (scene["id"] for scene in scenes))
    _check_unique("scenario intent", (scene["intent"] for scene in scenes))
    distribution = Counter((scene["level"], scene["theme"]) for scene in scenes)
    expected = {(level, theme): 1 for level in LEVELS for theme in THEMES}
    if distribution != Counter(expected):
        raise Batch17Error(f"level/theme matrix mismatch: {distribution}")

    curriculum = _read_json(root / "assets/data/curriculum_manifest.json")
    units = {unit["id"]: unit for unit in curriculum["courseUnits"]}
    categories = {entry["id"] for entry in _read_json(root / "assets/data/smalltalk.json")["categories"]}
    grammar = _grammar_rows(root)

    live_vocab: dict[tuple[str, str], list[str]] = {}
    with (root / "assets/data/korean_vocab.csv").open(encoding="utf-8-sig", newline="") as handle:
        for row in csv.DictReader(handle):
            key = (row["level"].lower(), row["korean"])
            live_vocab.setdefault(key, []).append(row["pack_id"])

    for scene in scenes:
        level = scene["level"]
        unit = units.get(scene["courseUnitId"])
        if unit is None or unit["level"] != level:
            raise Batch17Error(f"{scene['id']}: invalid course unit")
        if not set(scene["conceptIds"]).issubset(set(unit["requiredConceptIds"])):
            raise Batch17Error(f"{scene['id']}: concept outside course unit")
        if len(scene["dialog"]) != 8 or len(scene["exercises"]) != 3 or len(scene["smalltalk"]) != 2:
            raise Batch17Error(f"{scene['id']}: needs 8 turns, 3 exercises and 2 smalltalk records")
        if len(scene["vocab"]) < 6 or len(set(scene["vocab"])) != len(scene["vocab"]):
            raise Batch17Error(f"{scene['id']}: needs six distinct local vocabulary notes")
        for grammar_id in scene["grammarIds"]:
            if grammar.get(grammar_id, {}).get("level", "").lower() != level:
                raise Batch17Error(f"{scene['id']}: grammar level mismatch {grammar_id}")
        categories_for_scene = SMALLTALK_CATEGORIES_BY_SCENE[scene["id"]]
        if len(categories_for_scene) != 2 or not set(categories_for_scene).issubset(categories):
            raise Batch17Error(f"{scene['id']}: invalid smalltalk categories")
        for index, item in enumerate(scene["exercises"]):
            if item["ko"].count(item["answer"]) != 1:
                raise Batch17Error(f"{scene['id']} exercise {index}: answer must occur exactly once")
            if len(item["distractors"]) != 3 or len(set(item["distractors"])) != 3:
                raise Batch17Error(f"{scene['id']} exercise {index}: needs three distinct cloze distractors")
            if item["answer"] in item["distractors"]:
                raise Batch17Error(f"{scene['id']} exercise {index}: answer repeats as distractor")
            if len(item["satzDistractors"]) != 2 or len(set(item["satzDistractors"])) != 2:
                raise Batch17Error(f"{scene['id']} exercise {index}: needs two Satz distractors")
        for vocab_ko in SATZ_VOCAB_BY_SCENE[scene["id"]]:
            if len(live_vocab.get((level, vocab_ko), [])) != 1:
                raise Batch17Error(f"{scene['id']}: Satz source must resolve once: {vocab_ko}")

        topic_key = f"{level}:{CLOZE_TOPIC_BY_SCENE[scene['id']].lower()}"
        topic_unit = _mapped_unit(curriculum["clozeTopicUnitMap"].get(topic_key))
        if topic_unit != scene["courseUnitId"]:
            raise Batch17Error(f"{scene['id']}: cloze topic routes to {topic_unit!r}")
        for category in categories_for_scene:
            key = f"{level}:{category}"
            if not _mapped_unit(curriculum["smalltalkCategoryUnitMap"].get(key)):
                raise Batch17Error(f"{scene['id']}: smalltalk category is unrouted: {key}")


def _review_rows(kind: str, records: list[dict[str, Any]], notes: dict[str, str]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for record in records:
        if kind == "scenario":
            tri = record["title"]
        elif kind == "smalltalk":
            tri = record
        elif kind == "cloze":
            tri = {"ko": record["fullKo"], "de": record["de"], "en": record["en"]}
        elif kind == "satz":
            tri = {"ko": record["targetKo"], "de": record["promptDe"], "en": record["promptEn"]}
        else:
            tri = record
        rows.append({
            "id": record["id"],
            "level": record["level"].upper(),
            "ko": tri["ko"], "de": tri["de"], "en": tri["en"],
            "field_notes": notes[record["id"]],
            "상태": "draft", "jin_memo": "",
        })
    return rows


def _write_json(root: Path, path: Path, collection: str, records: list[dict[str, Any]], comment: str) -> None:
    payload = {"version": 1, "_comment": comment, collection: records}
    (root / path).write_text(json.dumps(payload, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")


def _write_review(root: Path, path: Path, rows: list[dict[str, str]]) -> None:
    with (root / path).open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=REVIEW_HEADER)
        writer.writeheader()
        writer.writerows(rows)


def build(root: Path = ROOT) -> dict[str, int]:
    existing_manifest: dict[str, Any] | None = None
    manifest_path = root / MANIFEST_PATH
    if manifest_path.is_file():
        candidate = _read_json(manifest_path)
        if candidate.get("status") == "merged":
            # A source rebuild must not erase the human approval ledger or turn
            # an already promoted manifest back into a pending draft.  Draft
            # payloads remain reproducible; the promotion records stay frozen.
            existing_manifest = candidate

    scenes = sorted(SCENES, key=lambda scene: (LEVELS.index(scene["level"]), THEMES.index(scene["theme"])))
    _validate_source_contracts(root, scenes)
    grammar = _grammar_rows(root)

    records: dict[str, list[dict[str, Any]]] = {kind: [] for kind in DRAFT_PATHS}
    notes: dict[str, str] = {}
    counters = {kind: dict(values) for kind, values in ID_STARTS.items()}

    for scene in scenes:
        level = scene["level"]
        seed_id = f"seed_batch17_{level}_{scene['theme']}"
        scenario = {
            key: scene[key]
            for key in (
                "id", "level", "emoji", "register", "speechStyle", "relationshipContext",
                "intent", "courseUnitId", "conceptIds", "sidekick", "xpReward", "title",
                "intro", "grammarIds", "dialog",
            )
        }
        scenario["surfaceFormIds"] = []
        scenario["vocab"] = [{"korean": value} for value in scene["vocab"]]
        scenario["grammarBlock"] = _grammar_block(scene, grammar)
        scenario["quests"] = _quests(scene)
        if scene.get("culturalNote"):
            scenario["culturalNote"] = scene["culturalNote"]
        records["scenario"].append(scenario)
        notes[scene["id"]] = (
            f"rights: original_clean_room; theme={scene['theme']}; "
            f"unit={scene['courseUnitId']}; turns=8; quests=5; review_gate=Jin"
        )

        for index, item in enumerate(scene["smalltalk"]):
            number = counters["smalltalk"][level]
            counters["smalltalk"][level] += 1
            record = dict(item)
            record["id"] = f"smalltalk_{level}_{number:04d}"
            record["level"] = level
            record["category"] = SMALLTALK_CATEGORIES_BY_SCENE[scene["id"]][index]
            record["relationshipContext"] = SMALLTALK_RELATIONSHIP_MAP.get(
                record["relationshipContext"], record["relationshipContext"]
            )
            records["smalltalk"].append(record)
            notes[record["id"]] = (
                f"rights: original_clean_room; sourceSeedId={seed_id}; "
                f"canonicalScenarioId={scene['id']}; category={record['category']}"
            )

        for index, item in enumerate(scene["exercises"]):
            common = {
                "sourceSeedId": seed_id,
                "courseUnitId": scene["courseUnitId"],
                "conceptIds": list(scene["conceptIds"]),
                "canonicalScenarioId": scene["id"],
            }
            cloze_number = counters["cloze"][level]
            counters["cloze"][level] += 1
            cloze = {
                "id": f"cloze_{level}_{cloze_number:04d}", "level": level,
                "sentenceKo": item["ko"].replace(item["answer"], BLANK, 1),
                "answer": item["answer"], "fullKo": item["ko"],
                "de": item["de"], "en": item["en"],
                "distractors": list(item["distractors"]),
                "topic": CLOZE_TOPIC_BY_SCENE[scene["id"]],
                **common,
            }
            records["cloze"].append(cloze)
            notes[cloze["id"]] = (
                f"rights: original_clean_room; answer={item['answer']}; "
                f"topic_route={cloze['topic']}; scenario={scene['id']}"
            )

            satz_number = counters["satz"][level]
            counters["satz"][level] += 1
            satz = {
                "id": f"satz_{level}_{satz_number:04d}", "level": level,
                "targetKo": item["ko"], "promptDe": item["de"], "promptEn": item["en"],
                "distractors": list(item["satzDistractors"]),
                "vocabKo": SATZ_VOCAB_BY_SCENE[scene["id"]][index],
                **common,
            }
            records["satz"].append(satz)
            notes[satz["id"]] = (
                f"rights: original_clean_room; vocab_route={satz['vocabKo']}; "
                f"scenario={scene['id']}"
            )

            pronunciation_number = counters["pronunciation"][level]
            counters["pronunciation"][level] += 1
            pronunciation = {
                "id": f"pronunciation_{level}_{pronunciation_number:04d}", "level": level,
                "ko": item["ko"], "de": item["de"], "en": item["en"],
                "focus": item["focus"], **common,
            }
            records["pronunciation"].append(pronunciation)
            notes[pronunciation["id"]] = (
                f"rights: original_clean_room; focus={item['focus']}; "
                f"scenario={scene['id']}; tts=not_generated"
            )

    all_ids = [record["id"] for values in records.values() for record in values]
    all_quest_ids = [quest["id"] for scene in records["scenario"] for quest in scene["quests"]]
    _check_unique("record id", all_ids)
    _check_unique("quest id", all_quest_ids)

    _write_json(root, DRAFT_PATHS["scenario"], "scenarios", records["scenario"], "Review-only Batch 17 B2-C2 social-topic scenarios.")
    _write_json(root, DRAFT_PATHS["smalltalk"], "phrases", records["smalltalk"], "Review-only Batch 17 B2-C2 social-topic smalltalk.")
    _write_json(root, DRAFT_PATHS["cloze"], "items", records["cloze"], "Review-only Batch 17 B2-C2 social-topic cloze.")
    _write_json(root, DRAFT_PATHS["satz"], "items", records["satz"], "Review-only Batch 17 B2-C2 social-topic Satzbau.")
    _write_json(root, DRAFT_PATHS["pronunciation"], "phrases", records["pronunciation"], "Review-only Batch 17 B2-C2 social-topic pronunciation.")

    if existing_manifest is None:
        for kind, path in REVIEW_PATHS.items():
            _write_review(root, path, _review_rows(kind, records[kind], notes))

    artifacts = [
        {
            "kind": kind, "draft": DRAFT_PATHS[kind].as_posix(),
            "review": REVIEW_PATHS[kind].as_posix(), "collection": COLLECTIONS[kind],
            "count": len(records[kind]), "levels": _levels(records[kind]),
        }
        for kind in ("scenario", "smalltalk", "cloze", "satz", "pronunciation")
    ]
    manifest = {
        "version": 1, "batch": "17", "status": "review_only_draft",
        "provenance": {
            "scope": "Original B2-C2 practice for 2026 Germany/Korea social topics: housing and living costs, work and AI, migration and demography, K-culture and platforms.",
            "rights": "original_clean_room", "requiresJinReview": True,
            "contentRevision": "v2",
            "humanization": {
                "skill": "beyond-humanizer",
                "installedRef": "beyond-humanizer-v2@2dde092f",
                "pass": "v2_full_trilingual_review",
                "appliedAt": "2026-08-22",
                "contract": "same communication event; preserve facts, roles, register, CEFR task and schema across KO/DE/EN",
            },
            "startingMainSha": "d71945dbe260168d7d41c77d3140a8b1d0e072bc",
            "researchAndDesign": "docs/B2_C2_2026_HOT_TOPICS_CONTENT_TRACK.md",
            "sourcePolicy": "Official sources inform topic selection and communicative tasks; no source wording, tables, questions, IDs or unit sequence is copied.",
        },
        "artifacts": artifacts,
        "recordCount": sum(len(values) for values in records.values()),
        "questCount": len(all_quest_ids),
        "contentLinks": [
            {
                "contentKind": "scenario", "contentId": scene["id"],
                "courseUnitId": scene["courseUnitId"], "conceptIds": list(scene["conceptIds"]),
                "role": "practice",
            }
            for scene in records["scenario"]
        ],
        "courseExposure": {
            "scenario": "explicit_content_link",
            "smalltalk": "existing_level_category_map",
            "cloze": "existing_level_topic_map",
            "satz": "existing_vocab_pack_map",
            "pronunciation": "standalone_cumulative_through_learner_level",
        },
        "backdrops": {scene["id"]: source["backdrop"] for scene, source in zip(records["scenario"], scenes)},
        "nonMergeGuards": [
            "Jin approval required before any apply or integration command",
            "no TTS synthesis or Firebase writes",
            "no assets/data, lib or runtime manifest edits from this builder",
        ],
    }
    if existing_manifest is None:
        manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    else:
        for key in ("batch", "recordCount", "questCount", "contentLinks", "backdrops"):
            if existing_manifest.get(key) != manifest.get(key):
                raise Batch17Error(f"promoted manifest drift after rebuild: {key}")
        if existing_manifest.get("artifacts") != manifest.get("artifacts"):
            raise Batch17Error("promoted manifest drift after rebuild: artifacts")
    return {kind: len(values) for kind, values in records.items()} | {"quests": len(all_quest_ids)}


def main() -> int:
    counts = build()
    print("OK: Batch 17 review-only drafts staged: " + ", ".join(f"{key}={value}" for key, value in counts.items()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
