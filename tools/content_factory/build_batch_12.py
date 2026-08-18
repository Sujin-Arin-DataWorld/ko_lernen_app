#!/usr/bin/env python3
"""Emit the review-only Batch 12 drafts: eight new C1/C2 course units in four slices.

Slices are an authoring rhythm, not four deliverables. The review overlay accepts
exactly one artifact per kind, so every slice lands in one draft file per kind and
one manifest. Cloze and Satzbau are derived 1:1 from the vocabulary examples, so the
sentences never drift apart. Preview only: nothing is written under assets/ or lib/.
"""

from __future__ import annotations

import csv
import importlib
import json
from pathlib import Path
import sys
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

SLICE_MODULES = [
    "data.batch_12_slice1_records",
    "data.batch_12_slice2_records",
    "data.batch_12_slice3_records",
    "data.batch_12_slice4_records",
]

GRAMMAR_HEADER = [
    "pattern", "level", "type_de", "explanation_de", "example_korean", "example_german",
    "note", "type_en", "explanation_en", "example_en", "note_en", "id",
    "quiz_focus_de", "quiz_focus_en", "quiz_enabled", "quiz_distractor_ids",
]

ROOT = SCRIPT_DIR.parents[1]
DRAFTS = Path("tools/content_factory/drafts")
REVIEW = Path("tools/content_factory/review")
VOCAB_HEADER = [
    "korean", "romanization", "german", "level", "pos_de", "example_korean",
    "example_german", "topic", "pack_id", "pack_order", "is_review_boss",
    "english", "pos_en", "example_english", "id",
]
REVIEW_HEADER = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]
BLANK = "＿＿＿"
ROWS_PER_PACK = 12


class SliceError(ValueError):
    """Raised when a slice would emit a record that cannot pass review."""


class Slice:
    """One authoring slice: two course units, one per level."""

    def __init__(self, number: int, module_name: str) -> None:
        module = importlib.import_module(module_name)
        self.number = number
        self.units = module.UNITS
        self.concepts = module.CONCEPTS
        self.packs = module.PACKS
        self.grammar = module.GRAMMAR
        self.smalltalk = module.SMALLTALK
        self.vocab = {"c1": module.VOCAB_C1, "c2": module.VOCAB_C2}

    def records_for(self, pack: dict[str, Any]) -> list[dict[str, Any]]:
        return self.vocab[pack["level"]]

    def smalltalk_category(self, level: str) -> str:
        categories = {item["category"] for item in self.smalltalk if item["level"] == level}
        if len(categories) != 1:
            raise SliceError(
                f"slice {self.number} {level}: smalltalk needs one category, got {sorted(categories)}"
            )
        return categories.pop()


def _vocab_rows(pack: dict[str, Any], records: list[dict[str, Any]]) -> list[dict[str, str]]:
    if len(records) != ROWS_PER_PACK:
        raise SliceError(f"{pack['packId']}: needs exactly {ROWS_PER_PACK} words")
    level = pack["level"]
    rows: list[dict[str, str]] = []
    for index, item in enumerate(records, start=1):
        if item["ex_ko"].count(item["korean"]) != 1:
            raise SliceError(f"{item['korean']}: headword must appear once in its example")
        rows.append({
            "korean": item["korean"],
            "romanization": item["rom"],
            "german": item["de"],
            "level": level.upper(),
            "pos_de": item.get("pos", "Nomen"),
            "example_korean": item["ex_ko"],
            "example_german": item["ex_de"],
            "topic": pack["topic"],
            "pack_id": pack["packId"],
            "pack_order": str(index),
            "is_review_boss": "true" if item["boss"] else "false",
            "english": item["en"],
            "pos_en": item.get("pos_en", "Noun"),
            "example_english": item["ex_en"],
            "id": f"vocab_{level}_{pack['vocabStart'] + index - 1:04d}",
        })
    bosses = [int(row["pack_order"]) for row in rows if row["is_review_boss"] == "true"]
    if bosses != [10, 11, 12]:
        raise SliceError(f"{pack['packId']}: boss orders must be 10, 11, 12")
    return rows


def _cloze_items(pack: dict[str, Any], records: list[dict[str, Any]]) -> list[dict[str, Any]]:
    level = pack["level"]
    items: list[dict[str, Any]] = []
    for index, item in enumerate(records, start=1):
        answer = item["korean"]
        full = item["ex_ko"]
        sentence = full.replace(answer, BLANK, 1)
        if sentence == full or BLANK not in sentence:
            raise SliceError(f"{answer}: cloze blank was not applied")
        distractors = item["cloze_distractors"]
        if len(distractors) != 3 or len(set(distractors)) != 3 or answer in distractors:
            raise SliceError(f"{answer}: cloze needs three distinct distractors")
        items.append({
            "id": f"cloze_{level}_{pack['clozeStart'] + index - 1:04d}",
            "level": level,
            "sentenceKo": sentence,
            "answer": answer,
            "fullKo": full,
            "de": item["ex_de"],
            "en": item["ex_en"],
            "distractors": distractors,
            "topic": pack["topic"],
        })
    return items


def _satz_items(pack: dict[str, Any], records: list[dict[str, Any]]) -> list[dict[str, Any]]:
    level = pack["level"]
    items: list[dict[str, Any]] = []
    for index, item in enumerate(records, start=1):
        target = item["ex_ko"]
        if len(target.split()) < 3:
            raise SliceError(f"{item['korean']}: Satz target needs at least three eojeol")
        distractors = item["satz_distractors"]
        if len(distractors) != 2 or len(set(distractors)) != 2:
            raise SliceError(f"{item['korean']}: Satz needs two distinct distractors")
        if set(target.split()) & set(distractors):
            raise SliceError(f"{item['korean']}: Satz distractor duplicates a target token")
        items.append({
            "id": f"satz_{level}_{pack['satzStart'] + index - 1:04d}",
            "level": level,
            "targetKo": target,
            "promptDe": item["ex_de"],
            "promptEn": item["ex_en"],
            "distractors": distractors,
            "vocabKo": item["korean"],
        })
    return items


def _write_review(root: Path, path: Path, rows: list[tuple[str, str, str, str, str, str]]) -> None:
    with (root / path).open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=REVIEW_HEADER)
        writer.writeheader()
        for ident, level, ko, de, en, notes in rows:
            writer.writerow({
                "id": ident, "level": level.upper(), "ko": ko, "de": de, "en": en,
                "field_notes": notes, "상태": "draft", "jin_memo": "",
            })


def _levels(values: list[dict[str, Any]]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for value in values:
        code = str(value["level"]).lower()
        counts[code] = counts.get(code, 0) + 1
    return counts


def _check_unique(label: str, values: list[str]) -> None:
    seen: set[str] = set()
    for value in values:
        if value in seen:
            raise SliceError(f"{label}: duplicate {value!r} across slices")
        seen.add(value)


def build(root: Path = ROOT) -> dict[str, int]:
    slices = [Slice(number, name) for number, name in enumerate(SLICE_MODULES, start=1)]

    # Packs are emitted level by level so the IDs in each draft file run ascending.
    plan = sorted(
        ((slice_, pack) for slice_ in slices for pack in slice_.packs),
        key=lambda entry: (entry[1]["level"], entry[1]["vocabStart"]),
    )

    units = [unit for slice_ in slices for unit in slice_.units]
    concepts = [concept for slice_ in slices for concept in slice_.concepts]
    grammar_rows = [entry for slice_ in slices for entry in slice_.grammar]
    smalltalk_rows = [item for slice_ in slices for item in slice_.smalltalk]

    _check_unique("courseUnitId", [unit["id"] for unit in units])
    _check_unique("conceptId", [concept["id"] for concept in concepts])
    _check_unique("packId", [pack["packId"] for _, pack in plan])
    _check_unique("grammarId", [entry["id"] for entry in grammar_rows])
    _check_unique("smalltalkId", [item["id"] for item in smalltalk_rows])
    _check_unique(
        "checkpointContentId",
        [content_id for unit in units for content_id in unit["checkpointContentIds"]],
    )
    # A course unit owns its smalltalk category, so two units of one level cannot share one.
    for level in ("c1", "c2"):
        _check_unique(
            f"{level} smalltalk category",
            [slice_.smalltalk_category(level) for slice_ in slices],
        )

    declared_concepts = {concept["id"] for concept in concepts}
    for unit in units:
        if not unit["checkpointContentIds"]:
            raise SliceError(f"{unit['id']}: a course unit needs a checkpoint")
        unknown = [cid for cid in unit["requiredConceptIds"] if cid not in declared_concepts]
        if unknown:
            raise SliceError(f"{unit['id']}: undeclared concepts {unknown}")

    vocab_rows: list[dict[str, str]] = []
    cloze_items: list[dict[str, Any]] = []
    satz_items: list[dict[str, Any]] = []
    derivations: list[dict[str, Any]] = []

    for slice_, pack in plan:
        records = slice_.records_for(pack)
        vocab_rows.extend(_vocab_rows(pack, records))
        cloze_items.extend(_cloze_items(pack, records))
        satz_items.extend(_satz_items(pack, records))
        derivations.append({
            "level": pack["level"],
            "vocabIdRange": [pack["vocabStart"], pack["vocabStart"] + ROWS_PER_PACK - 1],
            "clozeIdRange": [pack["clozeStart"], pack["clozeStart"] + ROWS_PER_PACK - 1],
            "satzIdRange": [pack["satzStart"], pack["satzStart"] + ROWS_PER_PACK - 1],
        })

    _check_unique("headword", [row["korean"] for row in vocab_rows])
    live: dict[str, str] = {}
    with (root / "assets/data/korean_vocab.csv").open(encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            live[row["korean"]] = row["level"]
    clash = [row["korean"] for row in vocab_rows if row["korean"] in live]
    if clash:
        raise SliceError(f"headwords already live: {clash}")

    live_grammar_ids: set[str] = set()
    with (root / "assets/data/grammar.csv").open(encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            live_grammar_ids.add(row["id"])
    for entry in grammar_rows:
        if entry["id"] in live_grammar_ids:
            raise SliceError(f"{entry['id']}: grammar id is already live")
        if entry["example_german"].count(entry["quiz_focus_de"]) != 1:
            raise SliceError(f"{entry['id']}: quiz_focus_de must appear once in example_german")
        if entry["example_en"].count(entry["quiz_focus_en"]) != 1:
            raise SliceError(f"{entry['id']}: quiz_focus_en must appear once in example_en")
        ids = entry["quiz_distractor_ids"].split("|")
        if len(ids) != 3 or len(set(ids)) != 3 or entry["id"] in ids:
            raise SliceError(f"{entry['id']}: needs three distinct distractor ids")
        missing = [ident for ident in ids if ident not in live_grammar_ids]
        if missing:
            raise SliceError(f"{entry['id']}: distractor ids are not live: {missing}")

    grammar_path = DRAFTS / "c4_batch12_grammar_c1_c2.csv"
    vocab_path = DRAFTS / "c3_batch12_vocab_c1_c2.csv"
    cloze_path = DRAFTS / "c2_batch12_cloze_c1_c2.json"
    satz_path = DRAFTS / "c2_batch12_satz_c1_c2.json"
    smalltalk_path = DRAFTS / "c2_batch12_smalltalk_c1_c2.json"

    with (root / vocab_path).open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=VOCAB_HEADER)
        writer.writeheader()
        writer.writerows(vocab_rows)

    with (root / grammar_path).open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=GRAMMAR_HEADER)
        writer.writeheader()
        writer.writerows(grammar_rows)

    for path, payload in (
        (cloze_path, {"items": cloze_items}),
        (satz_path, {"items": satz_items}),
        (smalltalk_path, {"version": 1, "phrases": smalltalk_rows}),
    ):
        (root / path).write_text(
            json.dumps(payload, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")

    _write_review(root, REVIEW / "c3_batch12_vocab_c1_c2.csv", [
        (row["id"], row["level"], row["korean"], row["german"], row["english"],
         f"rights: original; pack={row['pack_id']}; order={row['pack_order']}; boss={row['is_review_boss']}")
        for row in vocab_rows
    ])
    _write_review(root, REVIEW / "c4_batch12_grammar_c1_c2.csv", [
        (entry["id"], entry["level"], entry["pattern"], entry["type_de"], entry["type_en"],
         f"rights: original; focus_de={entry['quiz_focus_de']}; focus_en={entry['quiz_focus_en']}")
        for entry in grammar_rows
    ])
    _write_review(root, REVIEW / "c2_batch12_cloze_c1_c2.csv", [
        (item["id"], item["level"], item["fullKo"], item["de"], item["en"],
         f"rights: original; answer={item['answer']}; topic={item['topic']}")
        for item in cloze_items
    ])
    _write_review(root, REVIEW / "c2_batch12_satz_c1_c2.csv", [
        (item["id"], item["level"], item["targetKo"], item["promptDe"], item["promptEn"],
         f"rights: original; vocabKo={item['vocabKo']}")
        for item in satz_items
    ])
    _write_review(root, REVIEW / "c2_batch12_smalltalk_c1_c2.csv", [
        (item["id"], item["level"], item["ko"], item["de"], item["en"],
         f"rights: original; category={item['category']}; kind={item['kind']}")
        for item in smalltalk_rows
    ])

    manifest = {
        "version": 1,
        "batch": "12",
        "status": "review_only_draft",
        "provenance": {
            "scope": (
                "Original C1/C2 discourse vocabulary for eight new course units, "
                "with grammar, Cloze, Satzbau and smalltalk authored alongside."
            ),
            "rights": "original",
            "date": "2026-08-17",
            "requiresJinReview": True,
            "slices": "4 of 4 (two new course units per slice)",
            "originalPlan": "docs/superpowers/specs/2026-08-17-batch12-c1-c2-unit-extension-design.md",
            "blockedBy": "PR #62 must merge first: the new units use Batch 11 scenarios as checkpointContentIds.",
        },
        "predecessorManifests": [],
        "curriculumAdditions": {"courseUnits": units, "concepts": concepts},
        "artifacts": [
            {
                "kind": "vocab",
                "draft": vocab_path.as_posix(),
                "review": (REVIEW / "c3_batch12_vocab_c1_c2.csv").as_posix(),
                "count": len(vocab_rows),
                "levels": _levels([{"level": row["level"]} for row in vocab_rows]),
            },
            {
                "kind": "grammar",
                "draft": grammar_path.as_posix(),
                "review": (REVIEW / "c4_batch12_grammar_c1_c2.csv").as_posix(),
                "count": len(grammar_rows),
                "levels": _levels(grammar_rows),
            },
            {
                "kind": "smalltalk",
                "draft": smalltalk_path.as_posix(),
                "review": (REVIEW / "c2_batch12_smalltalk_c1_c2.csv").as_posix(),
                "count": len(smalltalk_rows),
                "levels": _levels(smalltalk_rows),
            },
            {
                "kind": "cloze",
                "draft": cloze_path.as_posix(),
                "review": (REVIEW / "c2_batch12_cloze_c1_c2.csv").as_posix(),
                "count": len(cloze_items),
                "levels": _levels(cloze_items),
            },
            {
                "kind": "satz",
                "draft": satz_path.as_posix(),
                "review": (REVIEW / "c2_batch12_satz_c1_c2.csv").as_posix(),
                "count": len(satz_items),
                "levels": _levels(satz_items),
            },
        ],
        "recordCount": (
            len(vocab_rows) + len(grammar_rows) + len(smalltalk_rows)
            + len(cloze_items) + len(satz_items)
        ),
        "grammarIntents": [
            {
                # 키는 "id" 다 — integrate_review_batches._add_mapping 이 그렇게 읽는다
                # (§411-420). "grammarId" 로 적으면 "malformed grammar intent" 로
                # 죽고, 그게 Batch 12 가 승격되지 못한 두 이유 중 하나였다
                # (다른 하나는 Batch 11 미승격, 2026-08-18 해소).
                "id": entry["id"],
                "level": entry["level"].lower(),
                "courseUnitId": next(
                    pack["courseUnitId"] for pack in slice_.packs
                    if pack["level"] == entry["level"].lower()
                ),
                "conceptIds": next(
                    pack["conceptIds"] for pack in slice_.packs
                    if pack["level"] == entry["level"].lower()
                ),
            }
            for slice_ in slices
            for entry in slice_.grammar
        ],
        "vocabPacks": [
            {
                "packId": pack["packId"],
                "level": pack["level"],
                "orderInLevel": pack["orderInLevel"],
                "orderRange": [1, ROWS_PER_PACK],
                "reviewBossOrders": [10, 11, 12],
                "displayLabel": pack["displayLabel"],
                "curriculum": {
                    "courseUnitId": pack["courseUnitId"],
                    "conceptIds": pack["conceptIds"],
                },
                "motif": "gwigap",
                "motifEnum": "DancheongMotif.gwigap",
            }
            for _, pack in plan
        ],
        "smalltalkCategoryMappings": [
            {
                "level": pack["level"],
                "category": slice_.smalltalk_category(pack["level"]),
                "courseUnitId": pack["courseUnitId"],
                "conceptIds": pack["conceptIds"],
            }
            for slice_, pack in plan
        ],
        "clozeTopicMappings": [
            {
                "level": pack["level"],
                "topic": pack["topic"],
                "courseUnitId": pack["courseUnitId"],
                "conceptIds": pack["conceptIds"],
            }
            for _, pack in plan
        ],
        "satzDependencies": [
            {"level": pack["level"], "vocabPackId": pack["packId"], "count": ROWS_PER_PACK}
            for _, pack in plan
        ],
        "requiresCompleteSentenceDerivations": True,
        "sentenceDerivationSets": derivations,
        "mergeOrder": [
            "course units and concepts with checkpointContentIds from Batch 11 scenarios",
            "vocab with vocabPackUnitMap companion mapping",
            "grammar with its course unit intents",
            "smalltalk with category companion mapping",
            "cloze with topic companion mapping",
            "satz after same-level vocabulary exists",
        ],
        "nonMergeGuards": [
            "Jin approval required before --apply",
            "PR #62 (Batch 11 scenarios) must merge before the new units validate",
            "no TTS synthesis or Firebase writes",
            "core_2026_v1 segments, editions and rewards stay untouched",
            "extension release tracks, segments and productive assessments follow in a later step",
        ],
    }
    (root / DRAFTS / "batch_12_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")

    return {
        "units": len(units),
        "vocab": len(vocab_rows),
        "grammar": len(grammar_rows),
        "cloze": len(cloze_items),
        "satz": len(satz_items),
        "smalltalk": len(smalltalk_rows),
        "records": manifest["recordCount"],
    }


def main() -> int:
    counts = build()
    print(
        f"OK: staged {counts['units']} review-only course units: "
        f"vocab {counts['vocab']}, grammar {counts['grammar']}, "
        f"cloze {counts['cloze']}, satz {counts['satz']}, "
        f"smalltalk {counts['smalltalk']} ({counts['records']} records)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
