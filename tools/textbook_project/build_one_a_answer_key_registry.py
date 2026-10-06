#!/usr/bin/env python3
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
DOC=ROOT/"docs"/"textbook_project"
TASKS=DOC/"production"/"ONE_A_TASK_REGISTRY_20261006.json"
CONTRACTS=DOC/"data"/"ONE_A_UNIT_CONTRACTS_20261006.json"
REVIEWS=DOC/"production"/"ONE_A_REVIEW_CONTRACTS_20261006.json"
SEED=DOC/"production"/"UNIT04_ANSWER_KEY_SEED_20261006.json"
OUT=DOC/"production"/"ONE_A_ANSWER_KEY_REGISTRY_20261006.json"

def load_json(p):
    return json.loads(p.read_text(encoding="utf-8-sig"))

def rubric_for(task_type):
    return {
        "meaning":["communicative function","meaning preserved"],
        "form":["target form","meaning preserved"],
        "listening":["key information","target recognition"],
        "reading":["information extraction","meaning"],
        "writing":["communicative goal","target language","register"],
        "speaking":["communicative goal","target language","intelligibility"],
        "interaction":["goal completion","appropriate register","interaction continuation"],
        "retrieval":["independent retrieval","meaning","target form"],
        "transfer_diagnostic":["function preserved","natural L1 realization"],
        "pronunciation":["intelligibility","target contrast"],
        "self_check":[]
    }.get(task_type,["task completion"])

def review_lookup(reviews):
    out={}
    for r in reviews["reviews"]:
        unit_id=f"a1_review_{r['reviewId'].lower()}"
        for t in r["tasks"]:
            out[t["taskId"]]=(unit_id,t)
    for t in reviews["finalReview"]["tasks"]:
        out[t["taskId"]]=("a1_review_final",t)
    return out

def unit_lookup(contracts):
    return {u["unitId"]:u for u in contracts["units"]}

def unit_entry(task,u):
    policy=task["answerPolicy"]
    ttype=task["taskType"]
    base={
        "itemId":task["taskId"],
        "unitId":task["unitId"],
        "edition":"shared",
        "taskType":ttype,
        "answerType":"rubric",
        "exactAnswers":[],
        "acceptedVariants":[],
        "unacceptableButPlausible":[],
        "rationale":"",
        "feedbackEn":"",
        "feedbackDe":"",
        "scoring":{"maxPoints":2,"partialCredit":True,"rubricDimensions":rubric_for(ttype)},
        "sourceRefs":task.get("sourceRefs",[]),
        "transferRiskRefs":task.get("transferRiskRefs",[]),
        "reviewStatus":"model_reviewed",
        "reviewNote":"Generated from stable 1A task registry; human/pilot validation still required."
    }

    chunks=u["coreChunks"]
    formulaic=[e for f in u.get("formulaicProduction",[]) for e in f.get("examples",[])]

    if policy=="multiple_accepted":
        base["answerType"]="multiple_accepted"
        base["acceptedVariants"]=list(dict.fromkeys(chunks+formulaic))[:10]
        base["rationale"]="Several unit-consistent Korean responses may be correct; judge function and target form, not one memorized sentence."
        base["feedbackEn"]="A different answer can be correct if it accomplishes the same function with unit-level Korean."
        base["feedbackDe"]="Eine andere Antwort kann richtig sein, wenn sie dieselbe Funktion mit Koreanisch auf Einheitsniveau erfüllt."
        base["scoring"]={"maxPoints":2,"partialCredit":True,"rubricDimensions":["communicative function","unit target form"]}
    elif policy=="sample_only":
        base["answerType"]="sample_only"
        base["rationale"]="This is a noticing/meaning task with more than one defensible observation; use unit context as the model."
        base["feedbackEn"]="Compare your answer with the scene and the unit’s communicative goal."
        base["feedbackDe"]="Vergleiche deine Antwort mit der Szene und dem kommunikativen Ziel der Einheit."
        base["scoring"]={"maxPoints":0,"partialCredit":False,"rubricDimensions":[]}
    elif policy=="self_check":
        base["answerType"]="open"
        base["rationale"]="Self-check is reflective and is not scored as right/wrong."
        base["feedbackEn"]="Mark the level of support you needed and revisit the retrieval task later."
        base["feedbackDe"]="Markiere, wie viel Hilfe du gebraucht hast, und wiederhole die Abrufaufgabe später."
        base["scoring"]={"maxPoints":0,"partialCredit":False,"rubricDimensions":[]}
    else:
        base["answerType"]="rubric"
        base["rationale"]="Score whether the learner completes the communicative task at the unit’s production ceiling."
        base["feedbackEn"]="Prioritize meaning, target language and interaction over reproducing one model sentence."
        base["feedbackDe"]="Bewerte Bedeutung, Zielsprache und Interaktion höher als das exakte Nachsprechen eines Mustersatzes."
    return base

def review_entry(task,unit_id,t):
    policy=t["answerPolicy"]
    base={
        "itemId":task["taskId"],
        "unitId":unit_id,
        "edition":"shared",
        "taskType":task["taskType"],
        "answerType":"rubric",
        "exactAnswers":[],
        "acceptedVariants":[],
        "unacceptableButPlausible":[],
        "rationale":"",
        "feedbackEn":"",
        "feedbackDe":"",
        "scoring":{"maxPoints":2,"partialCredit":True,"rubricDimensions":t.get("rubricDimensions",rubric_for(task["taskType"]))},
        "sourceRefs":t.get("sourceRefs",[]),
        "transferRiskRefs":[],
        "reviewStatus":"model_reviewed",
        "reviewNote":"Review-task key generated from review contract."
    }
    if policy=="closed":
        base["answerType"]="exact"
        base["exactAnswers"]=t["exactAnswers"]
        base["rationale"]="The review contract defines one deterministic answer for this closed task."
        base["feedbackEn"]="Check the target function/form from the paired units."
        base["feedbackDe"]="Prüfe die Zielfunktion/-form aus den beiden wiederholten Einheiten."
        base["scoring"]={"maxPoints":1,"partialCredit":False,"rubricDimensions":[]}
    elif policy=="multiple_accepted":
        base["answerType"]="multiple_accepted"
        base["acceptedVariants"]=t["acceptedAnswers"]
        base["rationale"]="Several natural L1 realizations are accepted because the task tests function, not literal translation."
        base["feedbackEn"]="Use a natural service equivalent rather than a word-for-word translation."
        base["feedbackDe"]="Verwende eine natürliche Serviceformel statt einer Wort-für-Wort-Übersetzung."
        base["scoring"]={"maxPoints":2,"partialCredit":True,"rubricDimensions":["function preserved","natural realization"]}
    else:
        base["answerType"]="rubric"
        base["rationale"]="Open review task; score task completion and the listed dimensions."
        base["feedbackEn"]="Complete the communicative goal with language from the reviewed units."
        base["feedbackDe"]="Erfülle das kommunikative Ziel mit Sprache aus den wiederholten Einheiten."
    return base

def main():
    tasks=load_json(TASKS)["tasks"]
    contracts=load_json(CONTRACTS)
    reviews=load_json(REVIEWS)
    seed=load_json(SEED)["entries"]
    units=unit_lookup(contracts)
    rlookup=review_lookup(reviews)
    entries=[]

    for task in tasks:
        if task["surface"]=="review":
            unit_id,t=rlookup[task["taskId"]]
            entries.append(review_entry(task,unit_id,t))
        else:
            entries.append(unit_entry(task,units[task["unitId"]]))

    # Preserve the six more granular Unit 04 seed items as sub-item keys.
    existing={e["itemId"] for e in entries}
    for e in seed:
        if e["itemId"] not in existing:
            entries.append(e)

    closed_task_ids={
        t["taskId"] for t in tasks
        if t["answerPolicy"]=="closed"
    }
    exact_ids={
        e["itemId"] for e in entries
        if e["answerType"]=="exact" and e.get("exactAnswers")
    }
    assert closed_task_ids <= exact_ids, sorted(closed_task_ids-exact_ids)

    out={
        "schemaVersion":1,
        "date":"2026-10-06",
        "book":"1A",
        "status":"MODEL_REVIEWED_FULL_TASK_COVERAGE",
        "taskRegistryCount":len(tasks),
        "answerEntryCount":len(entries),
        "closedTaskCount":len(closed_task_ids),
        "closedTaskCoverage":len(closed_task_ids & exact_ids),
        "entries":entries
    }
    OUT.write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({
        "taskRegistry":len(tasks),
        "answerEntries":len(entries),
        "closed":len(closed_task_ids),
        "closedCovered":len(closed_task_ids & exact_ids)
    }))

if __name__=="__main__":
    main()
