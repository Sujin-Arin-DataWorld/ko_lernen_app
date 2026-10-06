from __future__ import annotations

import csv
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
VOCAB = ROOT / "assets/data/korean_vocab.csv"
CLOZE = ROOT / "assets/data/cloze.json"
SATZ = ROOT / "assets/data/satz_sentences.json"
COVERAGE = ROOT / "tools/content_factory/review/global_localization_coverage_20261006.json"
REPORT = ROOT / "tools/content_factory/review/global_localization_derived_reconciliation_20261006.json"

KNOWN_OWNER_CORRECTIONS = {
    "vocab_a1_0218": {
        "example_english": "I wasn't sure how to address them, so I asked Sujin.",
        "example_german": "Die Anrede war schwierig, also habe ich Sujin gefragt.",
        "reason": "The KO example is about difficulty choosing a form of address; the previous EN/DE examples described honorific speech in front of parents and were semantically unrelated.",
    }
}


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: Any) -> None:
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def load_vocab() -> tuple[list[str], list[dict[str, str]]]:
    with VOCAB.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        return list(reader.fieldnames or []), list(reader)


def write_vocab(fields: list[str], rows: list[dict[str, str]]) -> None:
    with VOCAB.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    fields, vocab_rows = load_vocab()
    vocab = {row["id"]: row for row in vocab_rows}
    for ident, correction in KNOWN_OWNER_CORRECTIONS.items():
        row = vocab[ident]
        row["example_english"] = correction["example_english"]
        row["example_german"] = correction["example_german"]
    write_vocab(fields, vocab_rows)

    coverage = load_json(COVERAGE)
    owner_links = {
        row["itemId"]: row.get("ownerId") or ""
        for row in coverage["records"]
        if row.get("surfaceType") in {"cloze_translation", "satz_prompt"}
    }
    cloze = load_json(CLOZE)
    satz = load_json(SATZ)
    cloze_by_id = {row["id"]: row for row in cloze["items"]}
    satz_by_id = {row["id"]: row for row in satz["items"]}

    unresolved: list[str] = []
    mismatched_ko: list[str] = []
    resolved = 0
    for item_id, owner_id in owner_links.items():
        if not owner_id:
            unresolved.append(item_id)
            continue
        base_owner = owner_id.split("#", 1)[0]
        owner = vocab.get(base_owner)
        if owner is None:
            unresolved.append(item_id)
            continue
        expected_ko = owner["example_korean"]
        expected_en = owner["example_english"]
        expected_de = owner["example_german"]
        if item_id.startswith("cloze_"):
            item = cloze_by_id[item_id]
            if item["fullKo"] != expected_ko:
                mismatched_ko.append(item_id)
                continue
            item["en"] = expected_en
            item["de"] = expected_de
        elif item_id.startswith("satz_"):
            item = satz_by_id[item_id]
            if item["targetKo"] != expected_ko:
                mismatched_ko.append(item_id)
                continue
            item["promptEn"] = expected_en
            item["promptDe"] = expected_de
        else:
            unresolved.append(item_id)
            continue
        resolved += 1

    write_json(CLOZE, cloze)
    write_json(SATZ, satz)

    drift: list[str] = []
    for item_id, owner_id in owner_links.items():
        if not owner_id:
            continue
        owner = vocab.get(owner_id.split("#", 1)[0])
        if owner is None:
            continue
        if item_id.startswith("cloze_"):
            item = cloze_by_id[item_id]
            if (
                item["fullKo"] == owner["example_korean"]
                and (item["en"] != owner["example_english"] or item["de"] != owner["example_german"])
            ):
                drift.append(item_id)
        elif item_id.startswith("satz_"):
            item = satz_by_id[item_id]
            if (
                item["targetKo"] == owner["example_korean"]
                and (item["promptEn"] != owner["example_english"] or item["promptDe"] != owner["example_german"])
            ):
                drift.append(item_id)

    report = {
        "schemaVersion": 1,
        "generatedDate": "2026-10-06",
        "status": "G3_DERIVED_RECONCILIATION",
        "ownerFirstPolicy": True,
        "knownOwnerCorrections": KNOWN_OWNER_CORRECTIONS,
        "summary": {
            "derivedSurfaceCount": len(owner_links),
            "resolvedOwnerCount": resolved,
            "unresolvedOwnerCount": len(unresolved),
            "koOwnerMismatchCount": len(mismatched_ko),
            "postReconcileDriftCount": len(drift),
        },
        "unresolvedOwnerIds": sorted(unresolved),
        "koOwnerMismatchIds": sorted(mismatched_ko),
        "postReconcileDriftIds": sorted(drift),
    }
    write_json(REPORT, report)
    print(json.dumps(report["summary"], ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
