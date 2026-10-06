#!/usr/bin/env python3
import csv, json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
CONTRACTS=ROOT/"docs"/"textbook_project"/"data"/"ONE_A_UNIT_CONTRACTS_20261006.json"
ALLOC=ROOT/"docs"/"textbook_project"/"data"/"TEXTBOOK_SOURCE_POOL_ALLOCATION_RESOLVED_1A_6B.csv"
OUT=ROOT/"docs"/"textbook_project"/"production"/"ONE_A_PRINT_APP_CROSSLINKS_20261006.json"

def load_json(p):
    return json.loads(p.read_text(encoding="utf-8-sig"))

def main():
    contracts=load_json(CONTRACTS)
    rows=list(csv.DictReader(ALLOC.open(encoding="utf-8-sig",newline="")))
    all_ids={r["sourceId"] for r in rows}
    links=[]

    for u in contracts["units"]:
        uid=u["unitId"]
        order=u["order"]
        prefix=f"a1_0{order}_"
        unit_rows=[r for r in rows if r["preferredUnitId"].startswith(prefix)]

        authoritative=u["authoritativeScenarioIds"][0]
        assert authoritative in all_ids

        links.append({
            "crosslinkId":f"{uid}.core_dialogue",
            "unitId":uid,
            "printAnchor":"scene/core_dialogue",
            "linkRole":"core_dialogue",
            "appContentIds":[authoritative],
            "resolverMode":"CONTENT_ID_LOOKUP",
            "deeplinkKey":None,
            "offlineFallback":"Print dialogue remains complete without app access.",
            "contentVersion":"2026-10-06-phase2c",
            "lastVerified":"2026-10-06",
            "status":"verified_content_ids"
        })

        listening=[
            r["sourceId"] for r in unit_rows
            if r["surface"]=="listening_lesson"
            and r["textbookRole"]=="CORE"
            and r["secondPassDecision"]!="REJECT"
        ]
        if listening:
            links.append({
                "crosslinkId":f"{uid}.listening",
                "unitId":uid,
                "printAnchor":"listening/core",
                "linkRole":"listening",
                "appContentIds":listening[:2],
                "resolverMode":"CONTENT_ID_LOOKUP",
                "deeplinkKey":None,
                "offlineFallback":"Printed transcript/task remains usable; audio requires app or separately distributed audio.",
                "contentVersion":"2026-10-06-phase2c",
                "lastVerified":"2026-10-06",
                "status":"verified_content_ids"
            })

        practice=[]
        for surface in ("cloze","sentence_building"):
            candidates=[
                r for r in unit_rows
                if r["surface"]==surface
                and r["finalTextbookLevel"]=="A1"
                and r["textbookRole"] in {"RECYCLE","OPTIONAL"}
                and r["secondPassDecision"]=="KEEP"
            ]
            practice.extend(r["sourceId"] for r in candidates[:2])

        if practice:
            links.append({
                "crosslinkId":f"{uid}.practice",
                "unitId":uid,
                "printAnchor":"practice/recycle",
                "linkRole":"recycling",
                "appContentIds":practice,
                "resolverMode":"CONTENT_ID_LOOKUP",
                "deeplinkKey":None,
                "offlineFallback":"Print workbook provides a smaller curated practice set.",
                "contentVersion":"2026-10-06-phase2c",
                "lastVerified":"2026-10-06",
                "status":"verified_content_ids"
            })

        extras=[
            sid for sid in u.get("supplementarySourceIds",[])
            if sid in all_ids and not sid.startswith("listening.")
        ]
        if extras:
            links.append({
                "crosslinkId":f"{uid}.extension",
                "unitId":uid,
                "printAnchor":"extension/extra_scene",
                "linkRole":"extension",
                "appContentIds":extras[:2],
                "resolverMode":"CONTENT_ID_LOOKUP",
                "deeplinkKey":None,
                "offlineFallback":"Extension is optional; core print progression does not depend on it.",
                "contentVersion":"2026-10-06-phase2c",
                "lastVerified":"2026-10-06",
                "status":"verified_content_ids"
            })

    out={
        "schemaVersion":1,
        "date":"2026-10-06",
        "book":"1A",
        "status":"CONTENT_IDS_VERIFIED_APP_ROUTE_PENDING",
        "policy":{
            "printMustRemainUsableOffline":True,
            "qrOrDeepLinkNeverRequiredForCoreCanDo":True,
            "appRoutesAreNotInventedHere":True,
            "resolver":"App must resolve stable content IDs to current routes."
        },
        "links":links
    }
    OUT.write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"links":len(links),"units":len(contracts["units"])},ensure_ascii=False))

if __name__=="__main__":
    main()
