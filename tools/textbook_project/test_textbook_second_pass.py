#!/usr/bin/env python3
import csv
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "docs" / "textbook_project" / "data"

SECOND = DATA / "TEXTBOOK_REUSE_AUDIT_SECOND_PASS.csv"
SUMMARY = DATA / "TEXTBOOK_REUSE_AUDIT_SECOND_PASS_SUMMARY.json"
LEX_RES = DATA / "TEXTBOOK_LEXICAL_REWRITE_RESOLUTION_20261006.csv"
LEX_OVR = DATA / "TEXTBOOK_LEXICAL_OVERRIDES_20261006.json"
LEX_MATERIALIZED = DATA / "TEXTBOOK_LEXICAL_MATERIALIZED_20261006.json"
SMALL_RES = DATA / "TEXTBOOK_SMALLTALK_REWRITE_RESOLUTION_20261006.csv"
SMALL_OVR = DATA / "TEXTBOOK_SMALLTALK_OVERRIDES_20261006.json"
SCEN_RES = DATA / "TEXTBOOK_SCENARIO_REWRITE_RESOLUTION_20261006.csv"
SCEN_OVR = DATA / "TEXTBOOK_SCENARIO_OVERRIDES_20261006.json"
LISTEN_OVR = DATA / "TEXTBOOK_LISTENING_OVERRIDES_20261006.json"
OVERRIDE_MANIFEST = DATA / "TEXTBOOK_OVERRIDE_MANIFEST_20261006.json"
RELEVEL_RES = DATA / "TEXTBOOK_RELEVEL_RESOLUTION_20261006.csv"
REJECT_REPL = DATA / "TEXTBOOK_REJECT_REPLACEMENTS_20261006.json"

EXPECTED = {"KEEP": 5914, "REWRITE": 37, "RELEVEL": 2, "REJECT": 8}
LEVEL_MOVES = {
    "smalltalk.c1.theme_park_date.return": "B2",
    "smalltalk.c2.partner_family.decisions": "C1",
}


def load_csv(path):
    return list(csv.DictReader(path.open(encoding="utf-8-sig", newline="")))


def load_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def main():
    rows = load_csv(SECOND)
    summary = load_json(SUMMARY)

    assert len(rows) == 5961
    counts = Counter(r["secondPassDecision"] for r in rows)
    assert dict(counts) == EXPECTED, counts
    assert summary["decisionCounts"] == EXPECTED
    assert summary["unpreparedRewriteRows"] == 0

    # Lexical first-pass false positives / rewrites are fully resolved.
    lex_res = load_csv(LEX_RES)
    assert len(lex_res) == 46
    assert len({r["lexeme"] for r in lex_res}) == 46
    lex_counts = Counter(r["resolution"] for r in lex_res)
    assert sum(lex_counts.values()) == 46
    assert lex_counts["NORMALIZE_TARGET"] == 17
    assert lex_counts["MOVE_TO_CULTURE_NOTE"] == 1

    lexical_rewrite_rows = [
        r for r in rows if r["secondPassResolution"] == "LEXICAL_OVERRIDE_READY"
    ]
    assert len(lexical_rewrite_rows) == 31
    lex_override = load_json(LEX_OVR)
    assert lex_override["count"] == 18
    lex_override_src = {
        sid for e in lex_override["entries"] for sid in e.get("sourceIds", [])
    }
    assert lex_override_src == {r["sourceId"] for r in lexical_rewrite_rows}

    materialized = load_json(LEX_MATERIALIZED)
    assert materialized["count"] == 31
    assert materialized["clozeCount"] == 13
    assert materialized["sentenceBuildingCount"] == 18
    assert {x["sourceId"] for x in materialized["items"]} == lex_override_src
    for item in materialized["items"]:
        rep = item["replacement"]
        if item["surface"] == "cloze":
            assert rep["sentenceKo"].count("＿＿＿") == 1
            assert rep["fullKo"] == rep["sentenceKo"].replace("＿＿＿", rep["answer"])
            assert rep["answer"] not in rep["distractors"]
            assert len(set(rep["distractors"])) == len(rep["distractors"])
            assert rep["de"] and rep["en"]
        else:
            assert rep["targetKo"] and rep["promptDe"] and rep["promptEn"]

    # Smalltalk: 28 historical flags resolved to 26 current KEEP + 2 real rewrites.
    small_res = load_csv(SMALL_RES)
    assert len(small_res) == 28
    assert Counter(r["decision"] for r in small_res) == {"KEEP": 26, "REWRITE": 2}
    small_override_ids = {x["lessonId"] for x in load_json(SMALL_OVR)["lessons"]}
    assert small_override_ids == {
        "smalltalk.b2.phone.complaint",
        "smalltalk.b2.partner_family.schedule",
    }

    # Scenario roots: 13 directly read; 11 KEEP, 2 rewritten.
    scen_res = load_csv(SCEN_RES)
    assert len(scen_res) == 13
    assert Counter(r["decision"] for r in scen_res) == {"KEEP": 11, "REWRITE": 2}
    scenario_payload = load_json(SCEN_OVR)
    scen_override_ids = {x["scenarioId"] for x in scenario_payload["scenarios"]}
    assert scen_override_ids == {
        "a1_message_contact_after_class_2026",
        "c2_public_redress_briefing_2026",
    }
    for scenario in scenario_payload["scenarios"]:
        assert scenario["dialog"]
        for turn in scenario["dialog"]:
            assert turn["ko"] and turn["de"] and turn["en"]

    listening_payload = load_json(LISTEN_OVR)
    assert {x["sourceId"] for x in listening_payload["lessons"]} == {
        "listening.a1.a1_message_contact_after_class_2026",
        "listening.c2.c2_public_redress_briefing_2026",
    }
    for lesson in listening_payload["lessons"]:
        assert len(lesson["questions"]) >= 4
        for question in lesson["questions"]:
            if "options" in question:
                assert 0 <= question["correctIndex"] < len(question["options"])
    scen_rewrite_rows = [
        r for r in rows if r["secondPassResolution"] == "SCENARIO_OVERRIDE_READY"
    ]
    assert len(scen_rewrite_rows) == 4  # 2 live scenarios + 2 linked listening lessons
    for r in scen_rewrite_rows:
        root_id = r["sourceId"] if r["surface"] == "live_scenario" else r["linkId"]
        assert root_id in scen_override_ids

    # Relevel: only two real moves after sense/task-level review.
    relevel_res = load_csv(RELEVEL_RES)
    assert len(relevel_res) == 12
    assert Counter(r["finalDecision"] for r in relevel_res) == {"KEEP": 10, "RELEVEL": 2}
    move_rows = [r for r in rows if r["secondPassDecision"] == "RELEVEL"]
    assert {r["sourceId"]: r["finalTextbookLevel"] for r in move_rows} == LEVEL_MOVES

    # Reject originals stay retired but every one has a prepared replacement.
    reject_rows = [r for r in rows if r["secondPassDecision"] == "REJECT"]
    assert len(reject_rows) == 8
    reject_src = {
        sid
        for concept in load_json(REJECT_REPL)["replacements"]
        for sid in concept["sourceIds"]
    }
    assert reject_src == {r["sourceId"] for r in reject_rows}
    assert all(
        r["secondPassResolution"] == "ORIGINAL_RETIRED_REPLACEMENT_READY"
        for r in reject_rows
    )

    # Every second-pass REWRITE is backed by a prepared override lane.
    rewrite_rows = [r for r in rows if r["secondPassDecision"] == "REWRITE"]
    assert len(rewrite_rows) == 37
    assert {
        r["secondPassResolution"] for r in rewrite_rows
    } <= {
        "LEXICAL_OVERRIDE_READY",
        "SMALLTALK_OVERRIDE_READY",
        "SCENARIO_OVERRIDE_READY",
    }

    manifest = load_json(OVERRIDE_MANIFEST)
    assert manifest["rewriteCoverage"] == {
        "expected": 37,
        "covered": 37,
        "uncovered": 0,
        "duplicateCoverage": 0,
        "byLane": {
            "lexical_materialized": 31,
            "smalltalk_override": 2,
            "scenario_override": 2,
            "listening_override": 2,
        },
    }
    assert manifest["rejectReplacementCoverage"] == {
        "expected": 8,
        "covered": 8,
        "uncovered": 0,
    }

    print(
        "PASS second-pass "
        f"KEEP={EXPECTED['KEEP']} REWRITE={EXPECTED['REWRITE']} "
        f"RELEVEL={EXPECTED['RELEVEL']} REJECT={EXPECTED['REJECT']} "
        "overrides_ready=37 reject_replacements=8"
    )


if __name__ == "__main__":
    main()
