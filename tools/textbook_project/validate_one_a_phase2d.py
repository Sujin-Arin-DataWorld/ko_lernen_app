#!/usr/bin/env python3
import json
from collections import Counter, defaultdict
from pathlib import Path

import jsonschema

ROOT=Path(__file__).resolve().parents[2]
DOC=ROOT/"docs"/"textbook_project"
PROD=DOC/"production"
SCHEMA=DOC/"schemas"

TASKS=PROD/"ONE_A_TASK_REGISTRY_20261006.json"
ANSWERS=PROD/"ONE_A_ANSWER_KEY_REGISTRY_20261006.json"
PILOT=PROD/"ONE_A_PILOT_TASK_REGISTRY_20261006.json"
REVIEWS=PROD/"ONE_A_REVIEW_CONTRACTS_20261006.json"
REVIEW_DIR=PROD/"reviews"
PACKET=PROD/"human_review_packets"/"unit04"

TASK_SCHEMA=SCHEMA/"TASK_REGISTRY_ENTRY.schema.json"
ANSWER_SCHEMA=SCHEMA/"ANSWER_KEY_ENTRY.schema.json"
PILOT_SCHEMA=SCHEMA/"PILOT_TASK_ENTRY.schema.json"

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
    task_schema=load_json(TASK_SCHEMA)
    answer_schema=load_json(ANSWER_SCHEMA)
    pilot_schema=load_json(PILOT_SCHEMA)

    task_data=load_json(TASKS)
    tasks=task_data["tasks"]
    assert task_data["taskCount"]==190
    assert task_data["unitTaskCount"]==160
    assert task_data["reviewTaskCount"]==30

    task_ids=set()
    unit_counts=defaultdict(Counter)
    for t in tasks:
        jsonschema.validate(t,task_schema)
        assert t["taskId"] not in task_ids, t["taskId"]
        task_ids.add(t["taskId"])
        unit_counts[t["unitId"]][t["surface"]]+=1

    for uid in EXPECTED_UNITS:
        assert unit_counts[uid]["student_book"]==11, (uid,unit_counts[uid])
        assert unit_counts[uid]["workbook"]==9, (uid,unit_counts[uid])

    answer_data=load_json(ANSWERS)
    entries=answer_data["entries"]
    assert answer_data["taskRegistryCount"]==190
    assert answer_data["answerEntryCount"]==196
    answer_ids=set()
    task_answer_ids=set()
    exact_ids=set()
    for e in entries:
        jsonschema.validate(e,answer_schema)
        assert e["itemId"] not in answer_ids, e["itemId"]
        answer_ids.add(e["itemId"])
        if e["itemId"] in task_ids:
            task_answer_ids.add(e["itemId"])
        if e["answerType"]=="exact" and e.get("exactAnswers"):
            exact_ids.add(e["itemId"])

    assert task_answer_ids==task_ids, sorted(task_ids-task_answer_ids)[:10]
    closed_ids={t["taskId"] for t in tasks if t["answerPolicy"]=="closed"}
    assert len(closed_ids)==16
    assert closed_ids <= exact_ids
    assert answer_data["closedTaskCoverage"]==16

    review_data=load_json(REVIEWS)
    pair_tasks=sum(len(r["tasks"]) for r in review_data["reviews"])
    final_tasks=len(review_data["finalReview"]["tasks"])
    assert pair_tasks==24
    assert final_tasks==6
    for r in review_data["reviews"]:
        en=(REVIEW_DIR/f"{r['reviewId']}_EN.md").read_text(encoding="utf-8-sig")
        de=(REVIEW_DIR/f"{r['reviewId']}_DE.md").read_text(encoding="utf-8-sig")
        for t in r["tasks"]:
            assert t["taskId"] in en
            assert t["taskId"] in de
    final_en=(REVIEW_DIR/"FINAL_EN.md").read_text(encoding="utf-8-sig")
    final_de=(REVIEW_DIR/"FINAL_DE.md").read_text(encoding="utf-8-sig")
    for t in review_data["finalReview"]["tasks"]:
        assert t["taskId"] in final_en and t["taskId"] in final_de

    pilot_data=load_json(PILOT)
    pilot_tasks=pilot_data["tasks"]
    assert pilot_data["totalPilotTasks"]==50
    stage_counts=Counter()
    pilot_ids=set()
    for p in pilot_tasks:
        jsonschema.validate(p,pilot_schema)
        assert p["pilotTaskId"] not in pilot_ids
        pilot_ids.add(p["pilotTaskId"])
        assert p["sourceTaskId"] in task_ids
        stage_counts[p["stage"]]+=1
    assert stage_counts==Counter({
        "baseline":8,
        "immediate_post":8,
        "delayed_24h":8,
        "delayed_7d":8,
        "transfer":18,
    }), stage_counts

    assert (PACKET/"REVIEW_PACKET.md").exists()
    decisions=load_json(PACKET/"REVIEW_DECISIONS.json")
    assert decisions["status"]=="OPEN"
    assert decisions["allowedDecisions"]==["APPROVE","APPROVE_WITH_EDITS","HOLD"]

    print(
        "PASS "
        f"tasks={len(tasks)} answers={len(entries)} closed={len(closed_ids)}/{len(closed_ids)} "
        f"pair_review_tasks={pair_tasks} final_review_tasks={final_tasks} "
        f"pilot_tasks={len(pilot_tasks)} human_packet=open"
    )

if __name__=="__main__":
    main()
