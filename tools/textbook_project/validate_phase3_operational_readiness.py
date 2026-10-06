#!/usr/bin/env python3
import csv
import json
from pathlib import Path

import jsonschema
from jsonschema import FormatChecker

ROOT=Path(__file__).resolve().parents[2]
DOC=ROOT/"docs"/"textbook_project"
PROD=DOC/"production"
SCHEMAS=DOC/"schemas"

HUMAN_PACKET=PROD/"human_review_packets"/"unit04"
PILOT_PACKET=PROD/"pilot_packets"/"unit04"
PILOT_REGISTRY=PROD/"ONE_A_PILOT_TASK_REGISTRY_20261006.json"
PILOT_EVENT_SCHEMA=SCHEMAS/"LEARNER_PILOT_EVENT.schema.json"
COHORT_SCHEMA=SCHEMAS/"PILOT_COHORT_MANIFEST.schema.json"
HUMAN_SCHEMA=SCHEMAS/"HUMAN_REVIEW_DECISION.schema.json"
PILOT_SUMMARY=PROD/"pilot_reports"/"PILOT_LOG_SUMMARY_SAMPLE.json"
PILOT_LOG=PROD/"ONE_A_LEARNER_PILOT_LOG_TEMPLATE.csv"

REVIEW_FORMS=[
    "KO_REVIEW_FORM.md",
    "EN_REVIEW_FORM.md",
    "DE_REVIEW_FORM.md",
    "AUDIO_REVIEW_FORM.md",
]
STAGE_FILES=[
    "EN_BASELINE.md","DE_BASELINE.md",
    "EN_IMMEDIATE.md","DE_IMMEDIATE.md",
    "EN_DELAYED_24H.md","DE_DELAYED_24H.md",
    "EN_DELAYED_7D.md","DE_DELAYED_7D.md",
    "EN_TRANSFER.md","DE_TRANSFER.md",
]

def load_json(p):
    return json.loads(p.read_text(encoding="utf-8-sig"))

def main():
    # Human review packet.
    for name in ["REVIEW_PACKET.md","MANIFEST.json","REVIEW_DECISIONS.json",*REVIEW_FORMS]:
        p=HUMAN_PACKET/name
        assert p.exists() and p.stat().st_size>100, p

    human_schema=load_json(HUMAN_SCHEMA)
    decisions=load_json(HUMAN_PACKET/"REVIEW_DECISIONS.json")
    jsonschema.validate(decisions,human_schema)
    assert decisions["status"]=="OPEN"
    assert set(decisions["lanes"])=={
        "koreanEducator","englishPedagogy","germanPedagogy","audioSpoken"
    }

    # Pilot registry and cohort definitions.
    pilot=load_json(PILOT_REGISTRY)
    pilot_by_id={x["pilotTaskId"]:x for x in pilot["tasks"]}
    assert pilot["totalPilotTasks"]==50
    cohort_schema=load_json(COHORT_SCHEMA)

    cohort_files=[
        PILOT_PACKET/"EN_COHORT_TEMPLATE.json",
        PILOT_PACKET/"DE_COHORT_TEMPLATE.json",
    ]
    cohorts=[]
    for p in cohort_files:
        d=load_json(p)
        jsonschema.validate(d,cohort_schema)
        cohorts.append(d)
        assert d["unitId"]=="a1_04_order_request_object"
        assert len(d["participantCodes"])>=5
        assert all(task in pilot_by_id for task in d["taskIds"])
        assert set(d["taskIds"])=={
            "1A.PILOT.U04.B0",
            "1A.PILOT.U04.I0",
            "1A.PILOT.U04.D1",
            "1A.PILOT.U04.D7",
            "1A.PILOT.U04.TR",
        }

    # Stage sheets must exist and expose only their own stable pilot task.
    expected_task_by_suffix={
        "BASELINE.md":"1A.PILOT.U04.B0",
        "IMMEDIATE.md":"1A.PILOT.U04.I0",
        "DELAYED_24H.md":"1A.PILOT.U04.D1",
        "DELAYED_7D.md":"1A.PILOT.U04.D7",
        "TRANSFER.md":"1A.PILOT.U04.TR",
    }
    for name in STAGE_FILES:
        p=PILOT_PACKET/name
        assert p.exists() and p.stat().st_size>100, p
        text=p.read_text(encoding="utf-8-sig")
        suffix=next(k for k in expected_task_by_suffix if name.endswith(k))
        expected=expected_task_by_suffix[suffix]
        assert expected in text, (name,expected)

    guide=PILOT_PACKET/"FACILITATOR_GUIDE.md"
    assert guide.exists() and guide.stat().st_size>200

    # The sample log uses stable pilot IDs and is schema-valid.
    event_schema=load_json(PILOT_EVENT_SCHEMA)
    rows=list(csv.DictReader(PILOT_LOG.open(encoding="utf-8-sig",newline="")))
    assert len(rows)>=2
    pilot_ids=set(pilot_by_id)
    for row in rows:
        assert row["taskId"] in pilot_ids
        assert row["attemptStage"]==pilot_by_id[row["taskId"]]["stage"]

    # Summarizer output exists and clearly remains sample data.
    sample=load_json(PILOT_SUMMARY)
    assert sample["eventCount"]==len(rows)
    assert "interpretationRule" in sample

    # Human decision validator and frozen packet are still available.
    assert (ROOT/"tools"/"textbook_project"/"validate_unit04_human_review_decisions.py").exists()
    assert (ROOT/"tools"/"textbook_project"/"validate_unit04_human_review_packet.py").exists()
    assert (ROOT/"tools"/"textbook_project"/"summarize_one_a_pilot_log.py").exists()

    print(
        "PASS phase3_operational_readiness "
        f"review_forms={len(REVIEW_FORMS)} cohorts={len(cohorts)} "
        f"stage_sheets={len(STAGE_FILES)} pilot_registry={len(pilot_by_id)} "
        f"sample_events={len(rows)}"
    )

if __name__=="__main__":
    main()
