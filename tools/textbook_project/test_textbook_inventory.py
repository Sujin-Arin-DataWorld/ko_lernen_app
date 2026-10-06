#!/usr/bin/env python3
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOC = ROOT / "docs" / "textbook_project"
INV = DOC / "data" / "APP_CONTENT_INVENTORY.csv"
SUMMARY = DOC / "data" / "APP_CONTENT_INVENTORY_SUMMARY.json"
TAXONOMY = ROOT / "tools" / "content_factory" / "cefr_matrix" / "taxonomy.json"

EXPECTED_TOTAL = 5961
EXPECTED_SURFACES = {
    "live_scenario": 191,
    "canonical_scenario": 120,
    "smalltalk_lesson": 209,
    "listening_lesson": 191,
    "cloze": 2365,
    "sentence_building": 2885,
}


def main():
    rows = list(csv.DictReader(INV.open(encoding="utf-8-sig", newline="")))
    summary = json.loads(SUMMARY.read_text(encoding="utf-8"))
    taxonomy = json.loads(TAXONOMY.read_text(encoding="utf-8-sig"))
    valid_topics = {t["id"] for t in taxonomy["topics"]}

    assert len(rows) == EXPECTED_TOTAL, (len(rows), EXPECTED_TOTAL)
    assert summary["totalTracked"] == EXPECTED_TOTAL
    assert summary["canonicalTopicCount"] == 32

    counts = {}
    for surface in EXPECTED_SURFACES:
        counts[surface] = sum(1 for r in rows if r["surface"] == surface)
    assert counts == EXPECTED_SURFACES, counts

    invalid = [r for r in rows if r["canonicalTopicId"] and r["canonicalTopicId"] not in valid_topics]
    assert not invalid, invalid[:3]

    silent_unmapped = [r for r in rows if not r["canonicalTopicId"] and not r["unmappedReason"]]
    assert not silent_unmapped, silent_unmapped[:3]

    sentence_unmapped = [
        r for r in rows if r["surface"] == "sentence_building" and not r["canonicalTopicId"]
    ]
    assert not sentence_unmapped, sentence_unmapped[:3]

    assert summary["mappedCount"] + summary["unmappedCount"] == EXPECTED_TOTAL
    print(
        "PASS "
        f"total={EXPECTED_TOTAL} mapped={summary['mappedCount']} "
        f"unmapped={summary['unmappedCount']} topics={len(valid_topics)}"
    )


if __name__ == "__main__":
    main()
