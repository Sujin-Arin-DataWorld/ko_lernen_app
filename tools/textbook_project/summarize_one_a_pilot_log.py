#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
from collections import Counter, defaultdict
from pathlib import Path

import jsonschema
from jsonschema import FormatChecker

ROOT=Path(__file__).resolve().parents[2]
DOC=ROOT/"docs"/"textbook_project"
PROD=DOC/"production"
EVENT_SCHEMA=DOC/"schemas"/"LEARNER_PILOT_EVENT.schema.json"
PILOT_REGISTRY=PROD/"ONE_A_PILOT_TASK_REGISTRY_20261006.json"
COHORT_SCHEMA=DOC/"schemas"/"PILOT_COHORT_MANIFEST.schema.json"
DEFAULT_LOG=PROD/"ONE_A_LEARNER_PILOT_LOG_TEMPLATE.csv"
DEFAULT_OUT_JSON=PROD/"pilot_reports"/"PILOT_LOG_SUMMARY_SAMPLE.json"
DEFAULT_OUT_MD=PROD/"pilot_reports"/"PILOT_LOG_SUMMARY_SAMPLE.md"

def load_json(p:Path):
    return json.loads(p.read_text(encoding="utf-8-sig"))

def parse_bool(v):
    if isinstance(v,bool):
        return v
    s=str(v).strip().lower()
    if s in {"true","1","yes"}: return True
    if s in {"false","0","no"}: return False
    raise ValueError(f"invalid boolean: {v}")

def opt_float(v):
    s=str(v or "").strip()
    return None if not s else float(s)

def opt_int(v):
    s=str(v or "").strip()
    return None if not s else int(s)

def normalize_row(row):
    return {
        "participantCode":row["participantCode"].strip(),
        "cohortId":row["cohortId"].strip(),
        "l1":row["l1"].strip(),
        "unitId":row["unitId"].strip(),
        "taskId":row["taskId"].strip(),
        "attemptStage":row["attemptStage"].strip(),
        "timestamp":row["timestamp"].strip(),
        "responseMode":row["responseMode"].strip(),
        "targetIds":[x for x in row.get("targetIds","").split("|") if x],
        "result":row["result"].strip(),
        "errorType":row["errorType"].strip(),
        "transferRiskRef":row.get("transferRiskRef","").strip() or None,
        "selfCorrected":parse_bool(row["selfCorrected"]),
        "promptLevel":int(row["promptLevel"]),
        "comprehensionBreakdown":parse_bool(row["comprehensionBreakdown"]),
        "completionSeconds":opt_float(row.get("completionSeconds")),
        "confidence1to5":opt_int(row.get("confidence1to5")),
        "teacherNote":row.get("teacherNote",""),
        "recordingRef":row.get("recordingRef","").strip() or None,
    }

def cohort_templates():
    folder=PROD/"pilot_packets"/"unit04"
    files=[folder/"EN_COHORT_TEMPLATE.json",folder/"DE_COHORT_TEMPLATE.json"]
    schema=load_json(COHORT_SCHEMA)
    out={}
    for p in files:
        d=load_json(p)
        jsonschema.validate(d,schema,format_checker=FormatChecker())
        out[d["cohortId"]]=d
    return out

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--log",default=str(DEFAULT_LOG))
    ap.add_argument("--out-json",default=str(DEFAULT_OUT_JSON))
    ap.add_argument("--out-md",default=str(DEFAULT_OUT_MD))
    args=ap.parse_args()

    log_path=Path(args.log)
    event_schema=load_json(EVENT_SCHEMA)
    pilot=load_json(PILOT_REGISTRY)
    pilot_by_id={x["pilotTaskId"]:x for x in pilot["tasks"]}
    cohorts=cohort_templates()

    raw=list(csv.DictReader(log_path.open(encoding="utf-8-sig",newline="")))
    events=[]
    for i,row in enumerate(raw,2):
        e=normalize_row(row)
        jsonschema.validate(e,event_schema,format_checker=FormatChecker())
        assert e["taskId"] in pilot_by_id, (i,"unknown pilot task",e["taskId"])
        pt=pilot_by_id[e["taskId"]]
        assert e["attemptStage"]==pt["stage"], (i,"stage mismatch",e["taskId"],e["attemptStage"],pt["stage"])
        assert e["unitId"]==pt["unitId"], (i,"unit mismatch",e["unitId"],pt["unitId"])
        assert e["cohortId"] in cohorts, (i,"unknown cohort",e["cohortId"])
        c=cohorts[e["cohortId"]]
        assert e["participantCode"] in c["participantCodes"], (i,"participant not in cohort",e["participantCode"])
        assert e["l1"]==c["edition"], (i,"l1/edition mismatch",e["l1"],c["edition"])
        assert e["taskId"] in c["taskIds"], (i,"task not scheduled for cohort",e["taskId"])
        events.append(e)

    by_stage=defaultdict(Counter)
    by_l1=defaultdict(Counter)
    errors=Counter()
    transfer=Counter()
    prompts=Counter()
    self_correct=Counter()
    breakdown=Counter()

    for e in events:
        by_stage[e["attemptStage"]][e["result"]]+=1
        by_l1[e["l1"]][e["result"]]+=1
        errors[e["errorType"]]+=1
        if e["transferRiskRef"]:
            transfer[e["transferRiskRef"]]+=1
        prompts[e["promptLevel"]]+=1
        self_correct[e["selfCorrected"]]+=1
        breakdown[e["comprehensionBreakdown"]]+=1

    independent=sum(1 for e in events if e["result"]=="correct" and e["promptLevel"]==0)
    delayed=[e for e in events if e["attemptStage"] in {"delayed_24h","delayed_7d"}]
    delayed_independent=sum(1 for e in delayed if e["result"]=="correct" and e["promptLevel"]==0)

    summary={
        "schemaVersion":1,
        "sourceLog":str(log_path),
        "eventCount":len(events),
        "cohorts":sorted({e["cohortId"] for e in events}),
        "participants":sorted({e["participantCode"] for e in events}),
        "byStage":{k:dict(v) for k,v in sorted(by_stage.items())},
        "byL1":{k:dict(v) for k,v in sorted(by_l1.items())},
        "errorTypes":dict(errors.most_common()),
        "transferRiskRefs":dict(transfer.most_common()),
        "promptLevels":{str(k):v for k,v in sorted(prompts.items())},
        "selfCorrected":{"true":self_correct[True],"false":self_correct[False]},
        "comprehensionBreakdown":{"true":breakdown[True],"false":breakdown[False]},
        "independentCorrectCount":independent,
        "delayedEventCount":len(delayed),
        "delayedIndependentCorrectCount":delayed_independent,
        "interpretationRule":"Small discovery pilots identify problems; do not generalize cohort percentages to all EN/DE learners."
    }

    out_json=Path(args.out_json)
    out_json.parent.mkdir(parents=True,exist_ok=True)
    out_json.write_text(json.dumps(summary,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")

    lines=[
        "# 1A Pilot Log Summary","",
        f"Events: **{len(events)}**",
        f"Participants: **{len(summary['participants'])}**",
        f"Independent correct (prompt 0): **{independent}**","",
        "## By stage","",
        "| Stage | correct | partial | incorrect | not attempted |",
        "|---|---:|---:|---:|---:|",
    ]
    for stage,c in sorted(by_stage.items()):
        lines.append(f"| {stage} | {c['correct']} | {c['partial']} | {c['incorrect']} | {c['not_attempted']} |")
    lines += ["","## Error types",""]
    for k,v in errors.most_common():
        lines.append(f"- {k}: {v}")
    lines += ["","## Transfer-risk observations",""]
    if transfer:
        for k,v in transfer.most_common():
            lines.append(f"- {k}: {v}")
    else:
        lines.append("- none logged")
    lines += [
        "",
        "## Delayed retrieval",
        "",
        f"- delayed events: {len(delayed)}",
        f"- independent correct: {delayed_independent}",
        "",
        "## Interpretation caution",
        "",
        "This is a discovery-pilot summary. Do not present small-cohort percentages as universal learner facts.",
    ]
    Path(args.out_md).write_text("\n".join(lines)+"\n",encoding="utf-8")
    print(json.dumps({"events":len(events),"participants":len(summary["participants"]),"independentCorrect":independent},ensure_ascii=False))

if __name__=="__main__":
    main()
