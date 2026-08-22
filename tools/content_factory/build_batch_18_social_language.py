#!/usr/bin/env python3
"""Build review-gated Batch 18 B2-C2 language and derived games.

The source in ``data.batch_18_social_language`` is original clean-room content.
Each vocabulary example produces exactly one Cloze and one Satzbau item so the
three live surfaces cannot silently drift apart.  This builder writes drafts,
review ledgers and a manifest only; live promotion is handled atomically by
``integrate_review_batches.py`` after explicit approval.
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

from data.batch_18_social_language import GRAMMAR, SMALLTALK, VOCAB


ROOT = SCRIPT_DIR.parents[1]
BLANK = "＿＿＿"
LEVELS = ("b2", "c1", "c2")
THEMES = ("housing", "work_ai", "migration", "k_culture")
ROWS_PER_PACK = 12

VOCAB_HEADER = [
    "korean", "romanization", "german", "level", "pos_de", "example_korean",
    "example_german", "topic", "pack_id", "pack_order", "is_review_boss",
    "english", "pos_en", "example_english", "id",
]
GRAMMAR_HEADER = [
    "pattern", "level", "type_de", "explanation_de", "example_korean", "example_german",
    "note", "type_en", "explanation_en", "example_en", "note_en", "id",
    "quiz_focus_de", "quiz_focus_en", "quiz_enabled", "quiz_distractor_ids",
]
REVIEW_HEADER = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]

DRAFT_PATHS = {
    "vocab": Path("tools/content_factory/drafts/c3_batch18_vocab_b2_c1_c2.csv"),
    "grammar": Path("tools/content_factory/drafts/c4_batch18_grammar_b2_c1_c2.csv"),
    "smalltalk": Path("tools/content_factory/drafts/c2_batch18_smalltalk_b2_c1_c2.json"),
    "cloze": Path("tools/content_factory/drafts/c2_batch18_cloze_b2_c1_c2.json"),
    "satz": Path("tools/content_factory/drafts/c2_batch18_satz_b2_c1_c2.json"),
}
REVIEW_PATHS = {
    "vocab": Path("tools/content_factory/review/c3_batch18_vocab.csv"),
    "grammar": Path("tools/content_factory/review/c4_batch18_grammar.csv"),
    "smalltalk": Path("tools/content_factory/review/c2_batch18_smalltalk.csv"),
    "cloze": Path("tools/content_factory/review/c2_batch18_cloze.csv"),
    "satz": Path("tools/content_factory/review/c2_batch18_satz.csv"),
}
MANIFEST_PATH = Path("tools/content_factory/drafts/batch_18_manifest.json")
PACKET_PATH = Path("tools/content_factory/review/batch_18_review_packet.md")

LEVEL_CONFIG: dict[str, dict[str, Any]] = {
    "b2": {
        "vocabStart": 623, "clozeStart": 374, "satzStart": 532, "smalltalkStart": 109,
        "packId": "b2_2026_social_topics_1", "orderInLevel": 46,
        "topic": "Gesellschaft & Alltag 2026",
        "displayLabel": {"ko": "2026 사회·생활", "de": "Gesellschaft & Alltag 2026", "en": "Society & Daily Life 2026"},
        "courseUnitId": "b2_06_advanced_capstone", "conceptIds": ["concept_b2_advanced"],
        "motif": "chilbo", "motifEnum": "DancheongMotif.chilbo",
        "grammarDistractors": ["grammar_b2_formal_reason", "grammar_b2_formal_arrangement", "grammar_b2_formal_reference"],
    },
    "c1": {
        "vocabStart": 217, "clozeStart": 233, "satzStart": 235, "smalltalkStart": 41,
        "packId": "c1_2026_social_topics_1", "orderInLevel": 19,
        "topic": "Gesellschaft im Wandel",
        "displayLabel": {"ko": "사회 변화와 근거", "de": "Gesellschaft im Wandel", "en": "Society in Transition"},
        "courseUnitId": "c1_02_inclusive_sustainable_systems", "conceptIds": ["concept_c1_inclusive_systems"],
        "motif": "taegeuk", "motifEnum": "DancheongMotif.taegeuk",
        "grammarDistractors": ["grammar_c1_limited_to", "grammar_c1_not_necessarily", "grammar_c1_insufficient_for"],
    },
    "c2": {
        "vocabStart": 217, "clozeStart": 233, "satzStart": 235, "smalltalkStart": 41,
        "packId": "c2_2026_social_topics_1", "orderInLevel": 19,
        "topic": "Diskurs, Macht & Verantwortung",
        "displayLabel": {"ko": "담론·권력·책임", "de": "Diskurs, Macht & Verantwortung", "en": "Discourse, Power & Responsibility"},
        "courseUnitId": "c2_01_interpretation_institutions", "conceptIds": ["concept_c2_discourse_institutions"],
        "motif": "manja", "motifEnum": "DancheongMotif.manja",
        "grammarDistractors": ["grammar_c2_no_more_than_doing", "grammar_c2_merely_on_grounds", "grammar_c2_as_if_framing"],
    },
}

THEME_ROUTES: dict[tuple[str, str], tuple[str, list[str]]] = {
    ("b2", "housing"): ("b2_03_precise_requests", ["concept_b2_precise_requests"]),
    ("b2", "work_ai"): ("b2_05_interview", ["concept_b2_interview"]),
    ("b2", "migration"): ("b2_02_professional_opinion", ["concept_b2_opinion"]),
    ("b2", "k_culture"): ("b2_06_advanced_capstone", ["concept_b2_advanced"]),
    ("c1", "housing"): ("c1_02_inclusive_sustainable_systems", ["concept_c1_inclusive_systems"]),
    ("c1", "work_ai"): ("c1_01_evidence_public_reasoning", ["concept_c1_evidence_reasoning"]),
    ("c1", "migration"): ("c1_02_inclusive_sustainable_systems", ["concept_c1_inclusive_systems"]),
    ("c1", "k_culture"): ("c1_05_fan_labor_sustainability", ["concept_c1_fan_labor"]),
    ("c2", "housing"): ("c2_01_interpretation_institutions", ["concept_c2_discourse_institutions"]),
    ("c2", "work_ai"): ("c2_02_technology_public_ethics", ["concept_c2_accountable_systems"]),
    ("c2", "migration"): ("c2_01_interpretation_institutions", ["concept_c2_discourse_institutions"]),
    ("c2", "k_culture"): ("c2_06_fandom_discourse_power", ["concept_c2_fandom_discourse"]),
}

SMALLTALK_ROUTES: dict[tuple[str, str], tuple[str, list[str]]] = {
    ("b2", "moving"): ("b2_06_advanced_capstone", ["concept_b2_advanced"]),
    ("b2", "job_hunting"): ("b2_05_interview", ["concept_b2_interview"]),
    ("b2", "daily"): ("b2_02_professional_opinion", ["concept_b2_opinion"]),
    ("b2", "kpop"): ("b2_02_professional_opinion", ["concept_b2_opinion"]),
    ("c1", "moving"): ("c1_02_inclusive_sustainable_systems", ["concept_c1_inclusive_systems"]),
    ("c1", "job_hunting"): ("c1_01_evidence_public_reasoning", ["concept_c1_evidence_reasoning"]),
    ("c1", "daily"): ("c1_02_inclusive_sustainable_systems", ["concept_c1_inclusive_systems"]),
    ("c1", "kpop"): ("c1_05_fan_labor_sustainability", ["concept_c1_fan_labor"]),
    ("c2", "moving"): ("c2_01_interpretation_institutions", ["concept_c2_discourse_institutions"]),
    ("c2", "job_hunting"): ("c2_02_technology_public_ethics", ["concept_c2_accountable_systems"]),
    ("c2", "daily"): ("c2_02_technology_public_ethics", ["concept_c2_accountable_systems"]),
    ("c2", "kpop"): ("c2_06_fandom_discourse_power", ["concept_c2_fandom_discourse"]),
}


class Batch18Error(ValueError):
    """Raised when Batch 18 would break an authoring or integration contract."""


def _levels(records: Iterable[dict[str, Any]]) -> dict[str, int]:
    counts = Counter(str(record["level"]).lower() for record in records)
    return {level: counts[level] for level in LEVELS if counts[level]}


def _check_unique(label: str, values: Iterable[str]) -> None:
    counts = Counter(values)
    duplicates = sorted(value for value, count in counts.items() if count > 1)
    if duplicates:
        raise Batch18Error(f"{label}: duplicate values {duplicates}")


def _tuple_localized(values: object) -> dict[str, str]:
    if not isinstance(values, tuple) or len(values) != 3:
        raise Batch18Error("smalltalk localized tuple must contain ko, de and en")
    return {"ko": str(values[0]), "de": str(values[1]), "en": str(values[2])}


def _vocab_rows() -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for level in LEVELS:
        config = LEVEL_CONFIG[level]
        records = VOCAB[level]
        if len(records) != ROWS_PER_PACK:
            raise Batch18Error(f"{level}: expected {ROWS_PER_PACK} vocabulary records")
        for index, item in enumerate(records, start=1):
            if item["example_korean"].count(item["korean"]) != 1:
                raise Batch18Error(f"{item['korean']}: headword must appear exactly once")
            rows.append({
                "korean": item["korean"], "romanization": item["romanization"],
                "german": item["german"], "level": level.upper(), "pos_de": item["pos_de"],
                "example_korean": item["example_korean"], "example_german": item["example_german"],
                "topic": config["topic"], "pack_id": config["packId"], "pack_order": str(index),
                "is_review_boss": "true" if index >= 10 else "false",
                "english": item["english"], "pos_en": item["pos_en"],
                "example_english": item["example_english"],
                "id": f"vocab_{level}_{config['vocabStart'] + index - 1:04d}",
            })
    return rows


def _grammar_rows() -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for source in GRAMMAR:
        level = source["level"].lower()
        row = {key: str(value) for key, value in source.items() if key != "theme"}
        row["quiz_enabled"] = "true"
        row["quiz_distractor_ids"] = "|".join(LEVEL_CONFIG[level]["grammarDistractors"])
        if row["example_german"].count(row["quiz_focus_de"]) != 1:
            raise Batch18Error(f"{row['id']}: German quiz focus must appear exactly once")
        if row["example_en"].count(row["quiz_focus_en"]) != 1:
            raise Batch18Error(f"{row['id']}: English quiz focus must appear exactly once")
        rows.append(row)
    return rows


def _smalltalk_rows() -> list[dict[str, Any]]:
    counters = {level: LEVEL_CONFIG[level]["smalltalkStart"] for level in LEVELS}
    rows: list[dict[str, Any]] = []
    for source in SMALLTALK:
        level = str(source["level"]).lower()
        number = counters[level]
        counters[level] += 1
        rows.append({
            "id": f"smalltalk_{level}_{number:04d}", "category": source["category"],
            "level": level, "kind": "question", "ko": source["ko"],
            "de": source["de"], "en": source["en"],
            "reply": _tuple_localized(source["reply"]), "relationshipContext": "coworker",
            "safeAlternativeQuestions": [
                {"turnKind": "question", **_tuple_localized(source["alternative"])}
            ],
            "followUp": {"turnKind": "reaction", **_tuple_localized(source["follow_up"])},
        })
    return rows


def _derived_rows(vocab_rows: list[dict[str, str]]) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    cloze_rows: list[dict[str, Any]] = []
    satz_rows: list[dict[str, Any]] = []
    satz_pool = ["무심코", "단순히", "일방적으로", "형식상", "자동으로", "예외 없이"]
    for level in LEVELS:
        level_rows = [row for row in vocab_rows if row["level"].lower() == level]
        answers = [row["korean"] for row in level_rows]
        config = LEVEL_CONFIG[level]
        for index, row in enumerate(level_rows):
            answer = row["korean"]
            full = row["example_korean"]
            distractors = [answers[(index + offset) % len(answers)] for offset in (1, 4, 7)]
            if answer in distractors or len(set(distractors)) != 3:
                raise Batch18Error(f"{answer}: invalid Cloze distractors")
            source_seed = f"seed_batch18_{level}_{VOCAB[level][index]['theme']}"
            common = {
                "sourceSeedId": source_seed,
                "courseUnitId": config["courseUnitId"],
                "conceptIds": list(config["conceptIds"]),
            }
            cloze_rows.append({
                "id": f"cloze_{level}_{config['clozeStart'] + index:04d}", "level": level,
                "sentenceKo": full.replace(answer, BLANK, 1), "answer": answer, "fullKo": full,
                "de": row["example_german"], "en": row["example_english"],
                "distractors": distractors, "topic": config["topic"], **common,
            })
            satz_distractors = [word for word in satz_pool if word not in full][:2]
            if len(satz_distractors) != 2:
                raise Batch18Error(f"{answer}: could not assign Satz distractors")
            satz_rows.append({
                "id": f"satz_{level}_{config['satzStart'] + index:04d}", "level": level,
                "targetKo": full, "promptDe": row["example_german"], "promptEn": row["example_english"],
                "distractors": satz_distractors, "vocabKo": answer, **common,
            })
    return cloze_rows, satz_rows


def _write_json(root: Path, path: Path, collection: str, records: list[dict[str, Any]]) -> None:
    payload = {"version": 1, "_comment": "Original review-gated Batch 18 social-language content.", collection: records}
    (root / path).write_text(json.dumps(payload, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")


def _triage(kind: str, record: dict[str, Any]) -> tuple[str, str, str]:
    if kind == "vocab":
        return record["korean"], record["german"], record["english"]
    if kind == "grammar":
        return record["pattern"], record["type_de"], record["type_en"]
    if kind == "smalltalk":
        return record["ko"], record["de"], record["en"]
    if kind == "cloze":
        return record["fullKo"], record["de"], record["en"]
    return record["targetKo"], record["promptDe"], record["promptEn"]


def _review_notes(kind: str, record: dict[str, Any]) -> str:
    if kind == "vocab":
        return f"rights: original_clean_room; pack={record['pack_id']}; order={record['pack_order']}; boss={record['is_review_boss']}"
    if kind == "grammar":
        return f"rights: original_clean_room; focus_de={record['quiz_focus_de']}; focus_en={record['quiz_focus_en']}"
    if kind == "smalltalk":
        return f"rights: original_clean_room; category={record['category']}; kind={record['kind']}; Beyond=v2"
    if kind == "cloze":
        return f"rights: original_clean_room; answer={record['answer']}; topic={record['topic']}; derived=1:1"
    return f"rights: original_clean_room; vocabKo={record['vocabKo']}; derived=1:1"


def _write_review(root: Path, path: Path, kind: str, records: list[dict[str, Any]]) -> None:
    with (root / path).open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=REVIEW_HEADER)
        writer.writeheader()
        for record in records:
            ko, de, en = _triage(kind, record)
            writer.writerow({
                "id": record["id"], "level": str(record["level"]).upper(),
                "ko": ko, "de": de, "en": en, "field_notes": _review_notes(kind, record),
                "상태": "draft", "jin_memo": "",
            })


def _write_packet(root: Path, records: dict[str, list[dict[str, Any]]], status: str) -> None:
    lines = [
        "# Batch 18 B2–C2 사회 언어 리뷰 패킷", "",
        f"- 상태: `{status}`", "- 권리: original clean-room", "- Humanization: Beyond revision v2 (installed skill ref v5)",
        "- 범위: 어휘 36, 문법 12, 스몰톡 12, 빈칸 36, 문장 배열 36", "",
        "| 종류 | B2 | C1 | C2 | 합계 |", "|---|---:|---:|---:|---:|",
    ]
    for kind in ("vocab", "grammar", "smalltalk", "cloze", "satz"):
        counts = _levels(records[kind])
        lines.append(f"| {kind} | {counts.get('b2', 0)} | {counts.get('c1', 0)} | {counts.get('c2', 0)} | {len(records[kind])} |")
    lines += ["", "검수 기준: KO/DE/EN이 같은 발화 사건을 나타내며, 역할·격식·사실·CEFR 기능·고유 ID·로더 필드를 유지한다.", ""]
    (root / PACKET_PATH).write_text("\n".join(lines), encoding="utf-8")


def build(root: Path = ROOT) -> dict[str, int]:
    existing_manifest: dict[str, Any] | None = None
    manifest_file = root / MANIFEST_PATH
    if manifest_file.is_file():
        candidate = json.loads(manifest_file.read_text(encoding="utf-8"))
        if candidate.get("status") == "merged":
            existing_manifest = candidate

    vocab_rows = _vocab_rows()
    grammar_rows = _grammar_rows()
    smalltalk_rows = _smalltalk_rows()
    cloze_rows, satz_rows = _derived_rows(vocab_rows)
    records: dict[str, list[dict[str, Any]]] = {
        "vocab": vocab_rows, "grammar": grammar_rows, "smalltalk": smalltalk_rows,
        "cloze": cloze_rows, "satz": satz_rows,
    }

    _check_unique("record id", [record["id"] for values in records.values() for record in values])
    _check_unique("headword", [record["korean"] for record in vocab_rows])
    if set(item["theme"] for values in VOCAB.values() for item in values) != set(THEMES):
        raise Batch18Error("vocabulary theme matrix is incomplete")

    live_vocab: dict[str, dict[str, str]] = {}
    with (root / "assets/data/korean_vocab.csv").open(encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            live_vocab[row["korean"]] = row
    unexpected_vocab = [row["korean"] for row in vocab_rows if row["korean"] in live_vocab and existing_manifest is None]
    if unexpected_vocab:
        raise Batch18Error(f"headwords already live: {unexpected_vocab}")

    with (root / "assets/data/grammar.csv").open(encoding="utf-8", newline="") as handle:
        live_grammar_ids = {row["id"] for row in csv.DictReader(handle)}
    new_grammar_ids = {row["id"] for row in grammar_rows}
    collision = sorted(new_grammar_ids & live_grammar_ids) if existing_manifest is None else []
    if collision:
        raise Batch18Error(f"grammar ids already live: {collision}")
    for row in grammar_rows:
        distractors = row["quiz_distractor_ids"].split("|")
        if len(distractors) != 3 or len(set(distractors)) != 3:
            raise Batch18Error(f"{row['id']}: needs three distinct grammar distractors")
        missing = [ident for ident in distractors if ident not in live_grammar_ids]
        if missing:
            raise Batch18Error(f"{row['id']}: missing live grammar distractors {missing}")

    with (root / DRAFT_PATHS["vocab"]).open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=VOCAB_HEADER)
        writer.writeheader(); writer.writerows(vocab_rows)
    with (root / DRAFT_PATHS["grammar"]).open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=GRAMMAR_HEADER)
        writer.writeheader(); writer.writerows(grammar_rows)
    _write_json(root, DRAFT_PATHS["smalltalk"], "phrases", smalltalk_rows)
    _write_json(root, DRAFT_PATHS["cloze"], "items", cloze_rows)
    _write_json(root, DRAFT_PATHS["satz"], "items", satz_rows)

    if existing_manifest is None:
        for kind, path in REVIEW_PATHS.items():
            _write_review(root, path, kind, records[kind])

    collections = {"smalltalk": "phrases", "cloze": "items", "satz": "items"}
    artifacts = [
        {
            "kind": kind, "draft": DRAFT_PATHS[kind].as_posix(), "review": REVIEW_PATHS[kind].as_posix(),
            **({"collection": collections[kind]} if kind in collections else {}),
            "count": len(records[kind]), "levels": _levels(records[kind]),
        }
        for kind in ("vocab", "grammar", "smalltalk", "cloze", "satz")
    ]
    grammar_by_id = {item["id"]: item for item in GRAMMAR}
    manifest = {
        "version": 1, "batch": "18", "status": "review_only_draft",
        "provenance": {
            "scope": "Original B2-C2 vocabulary, grammar and short-form games for 2026 social topics.",
            "rights": "original_clean_room", "requiresJinReview": True,
            "contentRevision": "v2",
            "humanization": {
                "skill": "beyond-humanizer", "installedRef": "beyond-humanizer-v5-2026-08-21",
                "pass": "v2_full_trilingual_review", "appliedAt": "2026-08-22",
                "contract": "same communication event; preserve facts, roles, register, CEFR task and schema across KO/DE/EN",
            },
            "researchAndDesign": "docs/B2_C2_2026_HOT_TOPICS_CONTENT_TRACK.md",
            "sourcePolicy": "Official sources informed topic selection only; all learning text and exercises are original.",
        },
        "artifacts": artifacts,
        "recordCount": sum(len(values) for values in records.values()),
        "grammarIntents": [
            {
                "id": row["id"], "level": row["level"].lower(),
                "courseUnitId": THEME_ROUTES[(row["level"].lower(), grammar_by_id[row["id"]]["theme"])][0],
                "conceptIds": THEME_ROUTES[(row["level"].lower(), grammar_by_id[row["id"]]["theme"])][1],
            }
            for row in grammar_rows
        ],
        "vocabPacks": [
            {
                "packId": config["packId"], "level": level, "orderInLevel": config["orderInLevel"],
                "orderRange": [1, ROWS_PER_PACK], "reviewBossOrders": [10, 11, 12],
                "displayLabel": config["displayLabel"],
                "curriculum": {"courseUnitId": config["courseUnitId"], "conceptIds": config["conceptIds"]},
                "motif": config["motif"], "motifEnum": config["motifEnum"],
            }
            for level, config in LEVEL_CONFIG.items()
        ],
        "smalltalkCategoryMappings": [
            {"level": level, "category": category, "courseUnitId": route[0], "conceptIds": route[1]}
            for (level, category), route in SMALLTALK_ROUTES.items()
        ],
        "clozeTopicMappings": [
            {
                "level": level, "topic": config["topic"], "courseUnitId": config["courseUnitId"],
                "conceptIds": config["conceptIds"],
            }
            for level, config in LEVEL_CONFIG.items()
        ],
        "satzDependencies": [
            {"level": level, "vocabPackId": config["packId"], "count": ROWS_PER_PACK}
            for level, config in LEVEL_CONFIG.items()
        ],
        "requiresCompleteSentenceDerivations": True,
        "sentenceDerivationSets": [
            {
                "level": level,
                "vocabIdRange": [config["vocabStart"], config["vocabStart"] + ROWS_PER_PACK - 1],
                "clozeIdRange": [config["clozeStart"], config["clozeStart"] + ROWS_PER_PACK - 1],
                "satzIdRange": [config["satzStart"], config["satzStart"] + ROWS_PER_PACK - 1],
            }
            for level, config in LEVEL_CONFIG.items()
        ],
        "nonMergeGuards": [
            "Jin approval required before --apply", "no TTS synthesis or Firebase writes",
            "live assets and Dart pack mappings may change only through atomic review-batch integration",
        ],
    }
    if existing_manifest is None:
        manifest_file.write_text(json.dumps(manifest, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        packet_status = "review_only_draft"
    else:
        for key in (
            "batch", "artifacts", "recordCount", "grammarIntents", "vocabPacks",
            "smalltalkCategoryMappings", "clozeTopicMappings", "satzDependencies",
            "sentenceDerivationSets",
        ):
            if existing_manifest.get(key) != manifest.get(key):
                raise Batch18Error(f"promoted manifest drift after rebuild: {key}")
        packet_status = "merged"
    _write_packet(root, records, packet_status)
    return {kind: len(values) for kind, values in records.items()} | {"records": manifest["recordCount"]}


def main() -> int:
    counts = build()
    print("OK: Batch 18 review-only drafts staged: " + ", ".join(f"{key}={value}" for key, value in counts.items()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
