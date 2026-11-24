#!/usr/bin/env python3
from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "docs" / "textbook_project" / "data"

SECOND = DATA / "TEXTBOOK_REUSE_AUDIT_SECOND_PASS.csv"
LEXICAL = DATA / "TEXTBOOK_LEXICAL_MATERIALIZED_20261006.json"
SMALLTALK = DATA / "TEXTBOOK_SMALLTALK_OVERRIDES_20261006.json"
SCENARIO = DATA / "TEXTBOOK_SCENARIO_OVERRIDES_20261006.json"
LISTENING = DATA / "TEXTBOOK_LISTENING_OVERRIDES_20261006.json"
REJECT = DATA / "TEXTBOOK_REJECT_REPLACEMENTS_20261006.json"
OUT = DATA / "TEXTBOOK_OVERRIDE_MANIFEST_20261006.json"


def load_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    second = list(csv.DictReader(SECOND.open(encoding="utf-8-sig", newline="")))
    rewrite_expected = {
        r["sourceId"] for r in second if r["secondPassDecision"] == "REWRITE"
    }
    reject_expected = {
        r["sourceId"] for r in second if r["secondPassDecision"] == "REJECT"
    }

    lexical_ids = {x["sourceId"] for x in load_json(LEXICAL)["items"]}
    smalltalk_ids = {x["lessonId"] for x in load_json(SMALLTALK)["lessons"]}
    scenario_ids = {x["scenarioId"] for x in load_json(SCENARIO)["scenarios"]}
    listening_ids = {x["sourceId"] for x in load_json(LISTENING)["lessons"]}

    lanes = {
        "lexical_materialized": lexical_ids,
        "smalltalk_override": smalltalk_ids,
        "scenario_override": scenario_ids,
        "listening_override": listening_ids,
    }

    combined = set()
    duplicates = set()
    for ids in lanes.values():
        duplicates |= combined & ids
        combined |= ids

    if duplicates:
        raise SystemExit(f"Duplicate rewrite coverage: {sorted(duplicates)}")
    if combined != rewrite_expected:
        raise SystemExit(
            f"Rewrite coverage mismatch missing={sorted(rewrite_expected-combined)} "
            f"extra={sorted(combined-rewrite_expected)}"
        )

    reject_ids = {
        sid
        for concept in load_json(REJECT)["replacements"]
        for sid in concept.get("sourceIds", [])
    }
    if reject_ids != reject_expected:
        raise SystemExit(
            f"Reject replacement mismatch missing={sorted(reject_expected-reject_ids)} "
            f"extra={sorted(reject_ids-reject_expected)}"
        )

    files = [LEXICAL, SMALLTALK, SCENARIO, LISTENING, REJECT]
    payload = {
        "schemaVersion": 1,
        "date": "2026-10-06",
        "status": "COMPLETE_TEXTBOOK_OVERRIDE_COVERAGE",
        "rewriteCoverage": {
            "expected": len(rewrite_expected),
            "covered": len(combined),
            "uncovered": 0,
            "duplicateCoverage": 0,
            "byLane": {name: len(ids) for name, ids in lanes.items()},
        },
        "rejectReplacementCoverage": {
            "expected": len(reject_expected),
            "covered": len(reject_ids),
            "uncovered": 0,
        },
        "files": [
            {
                "path": p.relative_to(ROOT).as_posix(),
                "sha256": sha256(p),
            }
            for p in files
        ],
        "rewriteSourceIds": sorted(combined),
        "rejectSourceIds": sorted(reject_ids),
        "policy": {
            "appLiveAssetsMutated": False,
            "textbookOverridesAreCanonicalForPublishingTrack": True,
            "ttsOwnership": "Jin",
        },
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        f"PASS rewrite_covered={len(combined)} reject_replacements={len(reject_ids)} "
        f"manifest={OUT}"
    )


if __name__ == "__main__":
    main()
