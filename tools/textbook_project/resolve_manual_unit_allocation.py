#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "docs" / "textbook_project" / "data"
BASE = DATA / "TEXTBOOK_SOURCE_POOL_ALLOCATION_1A_6B.csv"
ARCH = DATA / "TEXTBOOK_BOOK_ARCHITECTURE_1A_6B.json"
CLOZE = ROOT / "assets" / "data" / "cloze.json"

OUT = DATA / "TEXTBOOK_SOURCE_POOL_ALLOCATION_RESOLVED_1A_6B.csv"
QUEUE = DATA / "TEXTBOOK_MANUAL_UNIT_ALLOCATION_RESOLUTION_20261006.csv"
SUMMARY = DATA / "TEXTBOOK_SOURCE_POOL_ALLOCATION_RESOLVED_SUMMARY.json"
REPORT = ROOT / "docs" / "textbook_project" / "MANUAL_UNIT_ALLOCATION_RESOLUTION_20261006.md"

LEGACY_TOPIC_TO_UNIT = {
    ("B1", "Wohnen & Vertrag"): "b1_05_complaint_resolution",
    ("B2", "Formelle Vereinbarungen"): "b2_03_precise_requests",
    ("B2", "Formelle Beschwerde & Abhilfe"): "b2_04_complaint_resolution",
    ("B2", "Sprache & Gesellschaft"): "b2_06_advanced_capstone",
    ("C1", "Risiko & öffentliche Information"): "c1_01_evidence_public_reasoning",
    ("C2", "Sprache, Deutung & Macht"): "c2_06_fandom_discourse_power",
    ("C2", "Technikethik & Verantwortung"): "c2_03_automation_redress",
    ("A1", "Wochenendzusage"): "a1_16_survival_capstone",
    ("B1", "Handytarif"): "b1_02_indirect_speech",
    ("B1", "Bankschalter"): "b1_05_complaint_resolution",
    ("B1", "Fundsachen"): "b1_05_complaint_resolution",
    ("B1", "Dienstmail"): "b1_03_work_softening",
    ("C2", "Framinganalyse"): "c2_01_interpretation_institutions",
    ("A1", "Begrüßung"): "a1_01_greetings_hangul",
}

SMALLTALK_UNIT = {
    "smalltalk.a1.emergency.help": "a1_10_health_safety",
    "smalltalk.a1.partner_family.photos": "a1_13_register_switching",
    "smalltalk.a1.theme_park_date.rides": "a1_11_titles_relationships",
    "smalltalk.a1.theme_park_date.break": "a1_11_titles_relationships",
    "smalltalk.a1.theme_park_date.memory": "a1_11_titles_relationships",
    "smalltalk.a2.emergency.report": "a2_05_delivery_services",
    "smalltalk.a2.partner_family.speech": "a2_03_chat_relationships",
    "smalltalk.a2.theme_park_date.snack": "a2_02_plans_proposals",
    "smalltalk.a2.theme_park_date.photos": "a2_02_plans_proposals",
    "smalltalk.a2.theme_park_date.waterqueue": "a2_02_plans_proposals",
    "smalltalk.b1.job_hunting.requirements": "b1_03_work_softening",
    "smalltalk.b1.emergency.preparedness": "b1_06_life_capstone",
    "smalltalk.b1.theme_park_date.thrill": "b1_04_relationships",
    "smalltalk.b1.theme_park_date.afterride": "b1_04_relationships",
    "smalltalk.b2.emergency.information": "b2_06_advanced_capstone",
    "smalltalk.c1.emergency.warnings": "c1_01_evidence_public_reasoning",
    "smalltalk.c2.emergency.power": "c2_04_sanction_accountability",
}

SMALLTALK_OPTIONAL_BOOK = {
    "smalltalk.b2.theme_park_date.preferences": "4B",
    "smalltalk.b2.theme_park_date.belongings": "4B",
    "smalltalk.b2.theme_park_date.afterwards": "4B",
    "smalltalk.c1.theme_park_date.return": "4B",
    "smalltalk.c1.theme_park_date.uncertainty": "5B",
    "smalltalk.c2.theme_park_date.anticipation": "6B",
    "smalltalk.c2.theme_park_date.sharedmemory": "6B",
}


def load_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def load_csv(path):
    return list(csv.DictReader(path.open(encoding="utf-8-sig", newline="")))


def main():
    rows = load_csv(BASE)
    arch = load_json(ARCH)
    unit_to_book = {u["unitId"]: u["book"] for u in arch["units"]}
    cloze_by_id = {x["id"]: x for x in load_json(CLOZE)["items"]}

    resolutions = []
    unresolved = []

    for row in rows:
        if row["allocationState"] != "MANUAL_UNIT_REVIEW":
            continue

        source_id = row["sourceId"]
        level = row["finalTextbookLevel"]
        unit = ""
        book = ""
        state = ""
        reason = ""
        evidence = ""

        if row["surface"] == "cloze":
            legacy = cloze_by_id[source_id].get("topic", "")
            unit = LEGACY_TOPIC_TO_UNIT.get((level, legacy), "")
            if unit:
                book = unit_to_book[unit]
                state = "ALLOCATED_LEGACY_BRIDGE"
                reason = "CURATED_LEGACY_TOPIC_BRIDGE"
                evidence = legacy
            else:
                unresolved.append(source_id)

        elif row["surface"] == "smalltalk_lesson":
            if source_id in SMALLTALK_UNIT:
                unit = SMALLTALK_UNIT[source_id]
                book = unit_to_book[unit]
                state = "ALLOCATED_CURATED_SMALLTALK"
                reason = "CURATED_SMALLTALK_FUNCTION_ROUTING"
                evidence = source_id
            elif source_id in SMALLTALK_OPTIONAL_BOOK:
                book = SMALLTALK_OPTIONAL_BOOK[source_id]
                state = "OPTIONAL_BOOK_BANK_CURATED"
                reason = "NO_STRONG_MACRO_UNIT_FIT_KEEP_AS_BOOK_RECYCLE_BANK"
                evidence = source_id
            else:
                unresolved.append(source_id)

        else:
            unresolved.append(source_id)

        if source_id not in unresolved:
            resolutions.append(
                {
                    "sourceId": source_id,
                    "surface": row["surface"],
                    "level": level,
                    "resolvedBook": book,
                    "resolvedUnitId": unit,
                    "resolvedAllocationState": state,
                    "resolutionReason": reason,
                    "evidence": evidence,
                }
            )

    if unresolved:
        raise SystemExit(f"Unresolved manual allocation rows: {unresolved}")

    resolution_by_id = {(r["surface"], r["sourceId"]): r for r in resolutions}
    resolved_rows = []
    for row in rows:
        key = (row["surface"], row["sourceId"])
        rr = resolution_by_id.get(key)
        if rr:
            row = dict(row)
            row["book"] = rr["resolvedBook"]
            row["preferredUnitId"] = rr["resolvedUnitId"]
            row["allocationState"] = rr["resolvedAllocationState"]
            row["allocationConfidence"] = (
                "high"
                if rr["resolvedAllocationState"] != "OPTIONAL_BOOK_BANK_CURATED"
                else "medium"
            )
            row["allocationReason"] = rr["resolutionReason"]
        resolved_rows.append(row)

    fields = list(resolved_rows[0].keys())
    with OUT.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(resolved_rows)

    qfields = list(resolutions[0].keys())
    with QUEUE.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=qfields)
        w.writeheader()
        w.writerows(resolutions)

    states = Counter(r["allocationState"] for r in resolved_rows)
    books = defaultdict(Counter)
    for r in resolved_rows:
        if r["book"]:
            books[r["book"]][r["textbookRole"]] += 1

    summary = {
        "schemaVersion": 1,
        "date": "2026-10-06",
        "total": len(resolved_rows),
        "manualBefore": 107,
        "manualAfter": states.get("MANUAL_UNIT_REVIEW", 0),
        "resolutionRows": len(resolutions),
        "legacyTopicBridgeRows": sum(
            r["resolvedAllocationState"] == "ALLOCATED_LEGACY_BRIDGE"
            for r in resolutions
        ),
        "curatedSmalltalkUnitRows": sum(
            r["resolvedAllocationState"] == "ALLOCATED_CURATED_SMALLTALK"
            for r in resolutions
        ),
        "curatedOptionalBookRows": sum(
            r["resolvedAllocationState"] == "OPTIONAL_BOOK_BANK_CURATED"
            for r in resolutions
        ),
        "allocationStateCounts": dict(states),
        "bookRoleCounts": {k: dict(v) for k, v in sorted(books.items())},
        "policy": {
            "canonicalTaxonomyMutated": False,
            "legacyLabelsUsedOnlyAsAllocationEvidence": True,
            "weakThemeParkAdvancedSmalltalkKeptOptional": True,
        },
    }
    SUMMARY.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    lines = [
        "# Manual Unit Allocation Resolution — 2026-10-06",
        "",
        "The base allocation left **107** rows unresolved rather than forcing them into a macro-unit.",
        "All 107 are now resolved without mutating the canonical 32-topic taxonomy.",
        "",
        f"- Legacy-topic bridge: **{summary['legacyTopicBridgeRows']}**",
        f"- Curated smalltalk to macro-unit: **{summary['curatedSmalltalkUnitRows']}**",
        f"- Curated advanced theme-park smalltalk to optional book bank: **{summary['curatedOptionalBookRows']}**",
        f"- Remaining manual rows: **{summary['manualAfter']}**",
        "",
        "## Why legacy topics were allowed here",
        "",
        "The cloze rows were not semantically blank. They retained stable legacy domain labels such as Wohnen & Vertrag, Formelle Vereinbarungen, Sprache & Gesellschaft, and Risiko & öffentliche Information. These labels are not promoted back into the canonical taxonomy; they are used only as traceable allocation evidence.",
        "",
        "## Optional rather than forced",
        "",
        "Higher-level theme-park/date smalltalk that has no strong macro-unit fit remains in the relevant B-book optional/recycle bank instead of distorting the curriculum spine.",
    ]
    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(
        json.dumps(
            {
                "resolved": len(resolutions),
                "manualAfter": summary["manualAfter"],
                "legacyBridge": summary["legacyTopicBridgeRows"],
                "smalltalkUnit": summary["curatedSmalltalkUnitRows"],
                "optionalBook": summary["curatedOptionalBookRows"],
            },
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main()
