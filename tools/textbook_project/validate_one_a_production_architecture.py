#!/usr/bin/env python3
import csv
import json
from collections import Counter
from pathlib import Path

import jsonschema

ROOT=Path(__file__).resolve().parents[2]
DOC=ROOT/"docs"/"textbook_project"
PROD=DOC/"production"
SCHEMAS=DOC/"schemas"

ARCH=PROD/"ONE_A_PRODUCTION_ARCHITECTURE_20261006.json"
ANSWER=PROD/"UNIT04_ANSWER_KEY_SEED_20261006.json"
PILOT=PROD/"ONE_A_LEARNER_PILOT_EVENT_EXAMPLES_20261006.json"
CROSSLINKS=PROD/"ONE_A_PRINT_APP_CROSSLINKS_20261006.json"
ALLOC=DOC/"data"/"TEXTBOOK_SOURCE_POOL_ALLOCATION_RESOLVED_1A_6B.csv"

ANSWER_SCHEMA=SCHEMAS/"ANSWER_KEY_ENTRY.schema.json"
PILOT_SCHEMA=SCHEMAS/"LEARNER_PILOT_EVENT.schema.json"
CROSSLINK_SCHEMA=SCHEMAS/"PRINT_APP_CROSSLINK.schema.json"

EXPECTED_UNITS={
    "a1_01_greetings_hangul",
    "a1_02_self_intro_identity",
    "a1_03_topic_subject_particles",
    "a1_04_order_request_object",
    "a1_05_numbers_time",
    "a1_06_transport_directions",
    "a1_07_contact_address",
    "a1_08_clarify_repair",
}

def load_json(p):
    return json.loads(p.read_text(encoding="utf-8-sig"))

def main():
    arch=load_json(ARCH)

    student=arch["studentBook"]
    workbook=arch["workbook"]

    assert student["targetPages"]==sum(x["pages"] for x in student["breakdown"])
    assert workbook["targetPages"]==sum(x["pages"] for x in workbook["breakdown"])
    assert student["targetPages"]==144
    assert workbook["targetPages"]==96
    assert student["targetPages"] % student["signaturePlanningMultiple"] == 0
    assert workbook["targetPages"] % workbook["signaturePlanningMultiple"] == 0
    assert student["unitBudget"]["pagesPerUnit"]==14
    assert len(student["unitBudget"]["spreads"])==7
    assert workbook["unitBudget"]["pagesPerUnit"]==10

    density=arch["exerciseDensity"]
    assert density["studentBook"]["maximumClosedFormatShare"] <= 0.40
    assert density["studentBook"]["minimumProductiveShare"] >= 0.35
    assert density["studentBook"]["minimumInteractionRetrievalShare"] >= 0.25
    assert density["workbook"]["minimumFreeProductionBlocks"] >= 1
    assert density["workbook"]["minimumDelayedRetrievalBlocks"] >= 1

    answer_schema=load_json(ANSWER_SCHEMA)
    answer=load_json(ANSWER)
    assert answer["unitId"]=="a1_04_order_request_object"
    assert len(answer["entries"])>=6
    for entry in answer["entries"]:
        jsonschema.validate(entry,answer_schema)

    pilot_schema=load_json(PILOT_SCHEMA)
    pilot=load_json(PILOT)
    assert len(pilot["events"])>=2
    for event in pilot["events"]:
        jsonschema.validate(event,pilot_schema)
        assert "name" not in event and "email" not in event

    cross_schema=load_json(CROSSLINK_SCHEMA)
    cross=load_json(CROSSLINKS)
    assert cross["status"]=="CONTENT_IDS_VERIFIED_APP_ROUTE_PENDING"
    rows=list(csv.DictReader(ALLOC.open(encoding="utf-8-sig",newline="")))
    valid_ids={r["sourceId"] for r in rows}

    roles=Counter()
    units=set()
    for link in cross["links"]:
        jsonschema.validate(link,cross_schema)
        units.add(link["unitId"])
        roles[link["linkRole"]]+=1
        assert all(cid in valid_ids for cid in link["appContentIds"]), link
        assert link["resolverMode"]=="CONTENT_ID_LOOKUP"
        assert link["deeplinkKey"] is None
        assert link["status"]=="verified_content_ids"

    assert units==EXPECTED_UNITS
    assert roles["core_dialogue"]==8
    assert roles["listening"]==8
    assert roles["recycling"]==8

    checklist=PROD/"ONE_A_HUMAN_REVIEW_CHECKLIST_20261006.md"
    protocol=PROD/"ONE_A_LEARNER_PILOT_PROTOCOL_20261006.md"
    csv_template=PROD/"ONE_A_LEARNER_PILOT_LOG_TEMPLATE.csv"
    for p in (checklist,protocol,csv_template):
        assert p.exists() and p.stat().st_size>100, p

    headers=next(csv.reader(csv_template.open(encoding="utf-8-sig",newline="")))
    required_headers={
        "participantCode","cohortId","l1","unitId","taskId","attemptStage",
        "timestamp","responseMode","targetIds","result","errorType",
        "transferRiskRef","selfCorrected","promptLevel","comprehensionBreakdown"
    }
    assert required_headers <= set(headers)

    print(
        "PASS "
        f"student_pages={student['targetPages']} workbook_pages={workbook['targetPages']} "
        f"answer_entries={len(answer['entries'])} pilot_examples={len(pilot['events'])} "
        f"crosslinks={len(cross['links'])} units={len(units)}"
    )

if __name__=="__main__":
    main()
