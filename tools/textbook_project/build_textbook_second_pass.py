#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOC = ROOT / "docs" / "textbook_project"
DATA = DOC / "data"

FIRST = DATA / "TEXTBOOK_REUSE_AUDIT_FIRST_PASS.csv"
LEX = DATA / "TEXTBOOK_LEXICAL_REWRITE_RESOLUTION_20261006.csv"
SMALL = DATA / "TEXTBOOK_SMALLTALK_REWRITE_RESOLUTION_20261006.csv"
SCEN = DATA / "TEXTBOOK_SCENARIO_REWRITE_RESOLUTION_20261006.csv"
RELEVEL = DATA / "TEXTBOOK_RELEVEL_RESOLUTION_20261006.csv"
REJECT_REPL = DATA / "TEXTBOOK_REJECT_REPLACEMENTS_20261006.json"

OUT = DATA / "TEXTBOOK_REUSE_AUDIT_SECOND_PASS.csv"
SUMMARY = DATA / "TEXTBOOK_REUSE_AUDIT_SECOND_PASS_SUMMARY.json"
REPORT = DOC / "TEXTBOOK_REUSE_AUDIT_SECOND_PASS.md"


def load_csv(path: Path):
    return list(csv.DictReader(path.open(encoding="utf-8-sig", newline="")))


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def main():
    rows = load_csv(FIRST)
    lex = {r["lexeme"]: r for r in load_csv(LEX)}
    small = {r["lessonId"]: r for r in load_csv(SMALL)}
    scen = {r["scenarioId"]: r for r in load_csv(SCEN)}
    relevel = {r["sourceId"]: r for r in load_csv(RELEVEL)}

    replacement_src = set()
    for concept in load_json(REJECT_REPL).get("replacements", []):
        replacement_src.update(concept.get("sourceIds", []))

    out = []
    unresolved = []

    for row in rows:
        first = row["reuseDecision"]
        second = first
        resolution = "UNCHANGED_FROM_FIRST_PASS"
        final_level = row["currentLevel"]
        notes = ""

        if first == "REWRITE":
            if row.get("lexemeHint"):
                rr = lex.get(row["lexemeHint"])
                if not rr:
                    unresolved.append(row["sourceId"])
                elif rr["resolution"].startswith("KEEP_"):
                    second = "KEEP"
                    resolution = "FALSE_POSITIVE_LEXICAL_FLAG_CLOSED"
                    notes = rr["resolution"]
                elif rr["resolution"] in {"NORMALIZE_TARGET", "MOVE_TO_CULTURE_NOTE"}:
                    second = "REWRITE"
                    resolution = "LEXICAL_OVERRIDE_READY"
                    notes = rr["replacementTarget"]
                else:
                    unresolved.append(row["sourceId"])

            elif row["surface"] == "smalltalk_lesson":
                rr = small.get(row["sourceId"])
                if not rr:
                    unresolved.append(row["sourceId"])
                else:
                    second = rr["decision"]
                    resolution = (
                        "SMALLTALK_OVERRIDE_READY"
                        if second == "REWRITE"
                        else "HISTORICAL_SMALLTALK_FLAG_CLOSED"
                    )
                    notes = rr["reasonCode"]

            elif row["surface"] in {"live_scenario", "listening_lesson"}:
                root_id = row["sourceId"] if row["surface"] == "live_scenario" else row["linkId"]
                rr = scen.get(root_id)
                if not rr:
                    unresolved.append(row["sourceId"])
                else:
                    second = rr["decision"]
                    resolution = (
                        "SCENARIO_OVERRIDE_READY"
                        if second == "REWRITE"
                        else "DIRECT_SECOND_PASS_SCENARIO_KEEP"
                    )
                    notes = rr["reasonCode"]

            else:
                unresolved.append(row["sourceId"])

        elif first == "RELEVEL":
            rr = relevel.get(row["sourceId"])
            if not rr:
                unresolved.append(row["sourceId"])
            else:
                second = rr["finalDecision"]
                final_level = rr["finalLevel"]
                resolution = (
                    "LEVEL_MOVE_CONFIRMED"
                    if second == "RELEVEL"
                    else "LEVEL_FALSE_POSITIVE_CLOSED"
                )
                notes = rr["reasonCode"]

        elif first == "REJECT":
            if row["sourceId"] in replacement_src:
                second = "REJECT"
                resolution = "ORIGINAL_RETIRED_REPLACEMENT_READY"
                notes = "replacement concept prepared"
            else:
                unresolved.append(row["sourceId"])

        out.append(
            {
                **row,
                "secondPassDecision": second,
                "secondPassResolution": resolution,
                "finalTextbookLevel": final_level,
                "secondPassNotes": notes,
                "secondPassDate": "2026-10-06",
            }
        )

    if unresolved:
        raise SystemExit(f"Unresolved second-pass rows: {unresolved[:20]} total={len(unresolved)}")

    fields = list(out[0].keys())
    with OUT.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(out)

    counts = Counter(r["secondPassDecision"] for r in out)
    resolutions = Counter(r["secondPassResolution"] for r in out)
    by_surface = defaultdict(Counter)
    by_level = defaultdict(Counter)
    for r in out:
        by_surface[r["surface"]][r["secondPassDecision"]] += 1
        by_level[r["finalTextbookLevel"]][r["secondPassDecision"]] += 1

    summary = {
        "schemaVersion": 1,
        "date": "2026-10-06",
        "stage": "SECOND_PASS_RESOLVED",
        "total": len(out),
        "decisionCounts": dict(counts),
        "resolutionCounts": dict(resolutions),
        "bySurface": {k: dict(v) for k, v in sorted(by_surface.items())},
        "byFinalTextbookLevel": {k: dict(v) for k, v in sorted(by_level.items())},
        "rewriteRowsWithOverrideReady": counts.get("REWRITE", 0),
        "unpreparedRewriteRows": 0,
        "confirmedRelevelRows": counts.get("RELEVEL", 0),
        "retiredOriginalRowsWithReplacement": resolutions.get(
            "ORIGINAL_RETIRED_REPLACEMENT_READY", 0
        ),
        "policy": {
            "firstPassKeepStillNeedsPublicationPassForExerciseBank": True,
            "appLiveAssetsMutated": False,
            "textbookOverridesAreSeparate": True,
        },
    }
    SUMMARY.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    lines = [
        "# Textbook Reuse Audit — Second Pass Resolution",
        "",
        "Date: 2026-10-06",
        "",
        f"Total rows resolved: **{len(out):,}**",
        "",
        "## Final second-pass decisions",
        "",
        "| Decision | Count |",
        "|---|---:|",
    ]
    for decision in ("KEEP", "REWRITE", "RELEVEL", "REJECT"):
        lines.append(f"| {decision} | {counts.get(decision, 0):,} |")

    lines += [
        "",
        "## What changed from first pass",
        "",
        f"- First-pass false positives closed into KEEP: **{resolutions.get('FALSE_POSITIVE_LEXICAL_FLAG_CLOSED',0) + resolutions.get('HISTORICAL_SMALLTALK_FLAG_CLOSED',0) + resolutions.get('DIRECT_SECOND_PASS_SCENARIO_KEEP',0) + resolutions.get('LEVEL_FALSE_POSITIVE_CLOSED',0):,}**",
        f"- Actual rewrite rows with prepared textbook overrides: **{counts.get('REWRITE',0):,}**",
        f"- Actual level moves: **{counts.get('RELEVEL',0):,}**",
        f"- Retired original rows with replacement concepts ready: **{resolutions.get('ORIGINAL_RETIRED_REPLACEMENT_READY',0):,}**",
        "",
        "## Key rules confirmed",
        "",
        "- Historical audit notes do not override current repaired copy.",
        "- A phrase is not rejected merely because it is multiword.",
        "- Lexical string equality does not imply sense identity.",
        "- A1 survival chunks and narrow situational vocabulary may precede the general deck level.",
        "- Easier vocabulary at a higher level is normal spiral recycling.",
        "- App live assets were not overwritten; textbook overrides are maintained separately.",
        "",
        "## Override sources",
        "",
        "- data/TEXTBOOK_REJECT_REPLACEMENTS_20261006.json",
        "- data/TEXTBOOK_LEXICAL_OVERRIDES_20261006.json",
        "- data/TEXTBOOK_SMALLTALK_OVERRIDES_20261006.json",
        "- data/TEXTBOOK_SCENARIO_OVERRIDES_20261006.json",
        "- data/TEXTBOOK_RELEVEL_RESOLUTION_20261006.csv",
    ]
    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(json.dumps(summary, ensure_ascii=False))


if __name__ == "__main__":
    main()
