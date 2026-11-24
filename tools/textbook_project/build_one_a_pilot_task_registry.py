#!/usr/bin/env python3
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
DOC=ROOT/"docs"/"textbook_project"
TASKS=DOC/"production"/"ONE_A_TASK_REGISTRY_20261006.json"
CONTRACTS=DOC/"data"/"ONE_A_UNIT_CONTRACTS_20261006.json"
REVIEWS=DOC/"production"/"ONE_A_REVIEW_CONTRACTS_20261006.json"
OUT=DOC/"production"/"ONE_A_PILOT_TASK_REGISTRY_20261006.json"

def load_json(p):
    return json.loads(p.read_text(encoding="utf-8-sig"))

def unit_code(order):
    return f"U{order:02d}"

def source_task(tasks, task_id):
    x=next((t for t in tasks if t["taskId"]==task_id),None)
    assert x, task_id
    return x

def make_unit_pilot(u,tasks):
    uc=unit_code(u["order"])
    targets=list(dict.fromkeys(
        u["coreChunks"]
        + [x["form"] for x in u["productiveGrammar"]]
        + [e for x in u.get("formulaicProduction",[]) for e in x.get("examples",[])]
    ))[:8]
    success=u["assessment"]["success"]
    specs=[
        ("B0","baseline",f"1A.{uc}.SB.T01",False,
         "Before teaching, attempt the scene meaning/task with no model. Record what the learner can already do.",
         "Vor dem Unterricht die Situationsaufgabe ohne Modell versuchen. Vorwissen und spontane Strategie notieren."),
        ("I0","immediate_post",f"1A.{uc}.SB.T11",False,
         "Immediately after the unit, complete the exit task without looking back at the explanation.",
         "Direkt nach der Einheit die Abschlussaufgabe ohne Zurückblättern lösen."),
        ("D1","delayed_24h",f"1A.{uc}.WB.T08",True,
         "After about 24 hours, retrieve the same function with changed names/items/times. Do not show the original model.",
         "Nach etwa 24 Stunden dieselbe Funktion mit veränderten Namen/Gegenständen/Zeiten abrufen. Das Originalmodell nicht zeigen."),
        ("D7","delayed_7d",f"1A.{uc}.WB.T08",True,
         "After about 7 days, perform the function in a new scene. Use no unit heading or translation cue unless needed.",
         "Nach etwa 7 Tagen die Funktion in einer neuen Situation ausführen. Keine Kapitelüberschrift oder Übersetzungshilfe zeigen, solange sie nicht nötig ist."),
        ("TR","transfer",f"1A.{uc}.SB.T10",True,
         "Transfer the unit function into a neighboring real-life context and keep the interaction going.",
         "Die Funktion der Einheit in eine benachbarte Alltagssituation übertragen und die Interaktion aufrechterhalten.")
    ]
    out=[]
    for code,stage,source_id,changed,en,de in specs:
        src=source_task(tasks,source_id)
        out.append({
            "pilotTaskId":f"1A.PILOT.{uc}.{code}",
            "sourceTaskId":source_id,
            "unitId":u["unitId"],
            "stage":stage,
            "l1Scope":["en","de"],
            "instructionEn":en,
            "instructionDe":de,
            "targetRefs":targets or src.get("targetRefs",[]),
            "promptLevelDefault":0,
            "changedContextRequired":changed,
            "successSignal":success,
            "status":"model_reviewed"
        })
    return out

def make_review_pilot(reviews,tasks):
    out=[]
    for r in reviews["reviews"]:
        rid=r["reviewId"]
        interaction=next((t for t in r["tasks"] if t["taskType"]=="interaction"), None)
        if interaction is None:
            interaction=next(t for t in r["tasks"] if t["taskType"]=="speaking")
        out.append({
            "pilotTaskId":f"1A.PILOT.{rid}.TR",
            "sourceTaskId":interaction["taskId"],
            "unitId":f"a1_review_{rid.lower()}",
            "stage":"transfer",
            "l1Scope":["en","de"],
            "instructionEn":"Complete the paired-unit interaction without being told which unit each expression comes from.",
            "instructionDe":"Bearbeite die Interaktionsaufgabe der beiden Einheiten, ohne dass angegeben wird, aus welchem Kapitel die Ausdrücke stammen.",
            "targetRefs":interaction["targetRefs"],
            "promptLevelDefault":0,
            "changedContextRequired":True,
            "successSignal":"Combines language from both reviewed units in one coherent interaction.",
            "status":"model_reviewed"
        })
    final=reviews["finalReview"]["tasks"]
    for i,t in enumerate(final,1):
        out.append({
            "pilotTaskId":f"1A.PILOT.FINAL.F{i:02d}",
            "sourceTaskId":t["taskId"],
            "unitId":"a1_review_final",
            "stage":"transfer",
            "l1Scope":["en","de"],
            "instructionEn":t["promptEn"],
            "instructionDe":t["promptDe"],
            "targetRefs":t.get("targetRefs",[]) or ["1A_integrated_transfer"],
            "promptLevelDefault":0,
            "changedContextRequired":True,
            "successSignal":"Completes the integrated 1A task without unit labels.",
            "status":"model_reviewed"
        })
    return out

def main():
    task_data=load_json(TASKS)
    tasks=task_data["tasks"]
    contracts=load_json(CONTRACTS)
    reviews=load_json(REVIEWS)

    registry=[]
    for u in contracts["units"]:
        registry.extend(make_unit_pilot(u,tasks))
    registry.extend(make_review_pilot(reviews,tasks))

    ids=[x["pilotTaskId"] for x in registry]
    assert len(ids)==len(set(ids))
    source_ids={t["taskId"] for t in tasks}
    assert all(x["sourceTaskId"] in source_ids for x in registry)

    stages={}
    for x in registry:
        stages[x["stage"]]=stages.get(x["stage"],0)+1

    out={
        "schemaVersion":1,
        "date":"2026-10-06",
        "book":"1A",
        "status":"MODEL_REVIEWED_PILOT_READY_REGISTRY",
        "unitPilotTasks":40,
        "pairReviewPilotTasks":4,
        "finalTransferTasks":6,
        "totalPilotTasks":len(registry),
        "stageCounts":stages,
        "tasks":registry
    }
    OUT.write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"total":len(registry),"stages":stages},ensure_ascii=False))

if __name__=="__main__":
    main()
