#!/usr/bin/env python3
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
DOC=ROOT/"docs"/"textbook_project"
CONTRACTS=DOC/"data"/"ONE_A_UNIT_CONTRACTS_20261006.json"
REVIEWS=DOC/"production"/"ONE_A_REVIEW_CONTRACTS_20261006.json"
OUT=DOC/"production"/"ONE_A_TASK_REGISTRY_20261006.json"

SB_TEMPLATE=[
    ("T01","meaning","scene_meaning","p1-2","rubric",True,["baseline","guided"]),
    ("T02","meaning","core_chunk_noticing","p3-4","sample_only",False,[]),
    ("T03","form","minimal_form_controlled","p5-6","multiple_accepted",True,["guided","immediate_post"]),
    ("T04","transfer_diagnostic","native_use_contrast","p7-8","rubric",True,["guided"]),
    ("T05","pronunciation","pronunciation_focus","p7-8","rubric",True,["guided"]),
    ("T06","listening","listening_core","p9","rubric",True,["baseline","immediate_post"]),
    ("T07","reading","reading_core","p10","rubric",True,["immediate_post"]),
    ("T08","speaking","guided_output","p11","rubric",True,["guided","immediate_post"]),
    ("T09","writing","short_writing","p12","rubric",True,["immediate_post"]),
    ("T10","interaction","interaction_mission","p13","rubric",True,["immediate_post","transfer"]),
    ("T11","retrieval","exit_retrieval","p14","rubric",True,["immediate_post","delayed_24h","delayed_7d"]),
]
WB_TEMPLATE=[
    ("T01","meaning","meaning_function","p1","sample_only",False,[]),
    ("T02","form","rebuild_chunk","p2","multiple_accepted",True,["guided","immediate_post"]),
    ("T03","form","controlled_variation","p3","multiple_accepted",True,["guided","immediate_post"]),
    ("T04","meaning","recognition_only_check","p4","sample_only",True,["guided"]),
    ("T05","listening","listening_grid","p5","rubric",True,["immediate_post"]),
    ("T06","transfer_diagnostic","l1_transfer_diagnostic","p6","rubric",True,["immediate_post","transfer"]),
    ("T07","interaction","interaction_free","p7-8","rubric",True,["transfer"]),
    ("T08","retrieval","delayed_retrieval","p9","rubric",True,["delayed_24h","delayed_7d"]),
    ("T09","self_check","self_check","p10","self_check",False,[]),
]

def load_json(p):
    return json.loads(p.read_text(encoding="utf-8-sig"))

def make_unit_tasks(u):
    out=[]
    order=u["order"]
    unit_code=f"U{order:02d}"
    target_refs=list(dict.fromkeys(
        [x["form"] for x in u["productiveGrammar"]]
        + [x["form"] for x in u.get("formulaicProduction",[])]
        + u["coreChunks"]
    ))
    source_refs=u["authoritativeScenarioIds"]+u.get("supplementarySourceIds",[])
    transfer_refs=u.get("enLearnerRisks",[])+u.get("deLearnerRisks",[])

    for suffix,ttype,key,page,policy,pilot,stages in SB_TEMPLATE:
        out.append({
            "taskId":f"1A.{unit_code}.SB.{suffix}",
            "unitId":u["unitId"],
            "surface":"student_book",
            "taskType":ttype,
            "taskKey":key,
            "plannedPageSlot":f"{unit_code}:{page}",
            "editionScope":["en","de"],
            "answerPolicy":policy,
            "targetRefs":target_refs[:8],
            "sourceRefs":source_refs[:5],
            "transferRiskRefs":transfer_refs,
            "pilotEligible":pilot,
            "pilotStages":stages,
            "status":"model_reviewed"
        })
    for suffix,ttype,key,page,policy,pilot,stages in WB_TEMPLATE:
        out.append({
            "taskId":f"1A.{unit_code}.WB.{suffix}",
            "unitId":u["unitId"],
            "surface":"workbook",
            "taskType":ttype,
            "taskKey":key,
            "plannedPageSlot":f"{unit_code}-WB:{page}",
            "editionScope":["en","de"],
            "answerPolicy":policy,
            "targetRefs":target_refs[:8],
            "sourceRefs":source_refs[:5],
            "transferRiskRefs":transfer_refs,
            "pilotEligible":pilot,
            "pilotStages":stages,
            "status":"model_reviewed"
        })
    return out

def make_review_tasks(reviews):
    out=[]
    for r in reviews["reviews"]:
        unit_id=f"a1_review_{r['reviewId'].lower()}"
        for t in r["tasks"]:
            out.append({
                "taskId":t["taskId"],
                "unitId":unit_id,
                "surface":"review",
                "taskType":t["taskType"],
                "taskKey":t["taskId"].split(".")[-1].lower(),
                "plannedPageSlot":f"{r['reviewId']}:p1-2",
                "editionScope":["en","de"],
                "answerPolicy":t["answerPolicy"],
                "targetRefs":t.get("targetRefs",[]),
                "sourceRefs":t.get("sourceRefs",[]),
                "transferRiskRefs":[],
                "pilotEligible":t["taskType"] in {"interaction","retrieval","transfer_diagnostic","listening"},
                "pilotStages":["transfer"] if t["taskType"]=="interaction" else (["delayed_24h","delayed_7d"] if t["taskType"]=="retrieval" else []),
                "status":"model_reviewed"
            })
    final=reviews["finalReview"]
    for t in final["tasks"]:
        out.append({
            "taskId":t["taskId"],
            "unitId":"a1_review_final",
            "surface":"review",
            "taskType":t["taskType"],
            "taskKey":t["taskId"].split(".")[-1].lower(),
            "plannedPageSlot":"FINAL:p1-4",
            "editionScope":["en","de"],
            "answerPolicy":t["answerPolicy"],
            "targetRefs":t.get("targetRefs",[]),
            "sourceRefs":t.get("sourceRefs",[]),
            "transferRiskRefs":[],
            "pilotEligible":True,
            "pilotStages":["transfer","delayed_7d"],
            "status":"model_reviewed"
        })
    return out

def main():
    contracts=load_json(CONTRACTS)
    reviews=load_json(REVIEWS)
    tasks=[]
    for u in contracts["units"]:
        tasks.extend(make_unit_tasks(u))
    tasks.extend(make_review_tasks(reviews))
    ids=[t["taskId"] for t in tasks]
    assert len(ids)==len(set(ids))
    out={
        "schemaVersion":1,
        "date":"2026-10-06",
        "book":"1A",
        "status":"MODEL_REVIEWED_STABLE_TASK_IDS",
        "idPolicy":{
            "stableAcrossLayoutChanges":True,
            "pageSlotIsMetadataNotIdentity":True,
            "pattern":"1A.Uxx.SB/WB.Txx or 1A.Rxx.RV.Txx"
        },
        "taskCount":len(tasks),
        "unitTaskCount":sum(1 for t in tasks if t["unitId"].startswith("a1_0")),
        "reviewTaskCount":sum(1 for t in tasks if t["surface"]=="review"),
        "tasks":tasks
    }
    OUT.write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"tasks":len(tasks),"unit":out["unitTaskCount"],"review":out["reviewTaskCount"]}))

if __name__=="__main__":
    main()
