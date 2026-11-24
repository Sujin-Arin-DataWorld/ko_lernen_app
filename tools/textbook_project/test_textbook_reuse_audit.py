#!/usr/bin/env python3
import csv
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "docs" / "textbook_project" / "data"
AUDIT = DATA / "TEXTBOOK_REUSE_AUDIT_FIRST_PASS.csv"
SUMMARY = DATA / "TEXTBOOK_REUSE_AUDIT_FIRST_PASS_SUMMARY.json"

EXPECTED_TOTAL = 5961
EXPECTED_DECISIONS = {
    "KEEP": 5813,
    "REWRITE": 128,
    "RELEVEL": 12,
    "REJECT": 8,
}
VALID = set(EXPECTED_DECISIONS)
REJECT_TARGETS = {"말의 자리", "전통의 선택", "망각의 예절", "말의 위계"}


def main():
    rows = list(csv.DictReader(AUDIT.open(encoding="utf-8-sig", newline="")))
    summary = json.loads(SUMMARY.read_text(encoding="utf-8"))

    assert len(rows) == EXPECTED_TOTAL, len(rows)
    assert summary["total"] == EXPECTED_TOTAL

    counts = Counter(r["reuseDecision"] for r in rows)
    assert set(counts) <= VALID, counts
    assert dict(counts) == EXPECTED_DECISIONS, counts
    assert summary["decisionCounts"] == EXPECTED_DECISIONS

    missing_reason = [r["sourceId"] for r in rows if not r["reasonCodes"]]
    assert not missing_reason, missing_reason[:10]

    stale = [
        r["sourceId"]
        for r in rows
        if "MANUAL_NATURALNESS_OR_ITEM_REVIEW_FLAG" in r["reasonCodes"]
    ]
    assert not stale, stale[:10]

    rejects = [r for r in rows if r["reuseDecision"] == "REJECT"]
    assert len(rejects) == 8
    assert {r["lexemeHint"] for r in rejects} == REJECT_TARGETS

    canonical = [r for r in rows if r["surface"] == "canonical_scenario"]
    assert len(canonical) == 120
    assert all(r["reuseDecision"] == "KEEP" for r in canonical)

    # Historical level-candidate conflicts alone must never override the current Level Bible.
    bad_historical = [
        r["sourceId"]
        for r in rows
        if r["reuseDecision"] == "RELEVEL"
        and "HISTORICAL_LEVEL_EVIDENCE_CONFLICT_ADVISORY" in r["reasonCodes"]
        and "TARGET_VOCAB_ABOVE_EXERCISE_LEVEL" not in r["reasonCodes"]
        and "SMALLTALK_PENDING_LEVEL_ROUTING_FLAG" not in r["reasonCodes"]
    ]
    assert not bad_historical, bad_historical[:10]

    print(
        "PASS "
        + " ".join(f"{k}={v}" for k, v in EXPECTED_DECISIONS.items())
        + f" total={EXPECTED_TOTAL}"
    )


if __name__ == "__main__":
    main()
