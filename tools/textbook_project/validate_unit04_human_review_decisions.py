#!/usr/bin/env python3
import hashlib
import json
from pathlib import Path

import jsonschema

ROOT=Path(__file__).resolve().parents[2]
DOC=ROOT/"docs"/"textbook_project"
PACKET=DOC/"production"/"human_review_packets"/"unit04"
SCHEMA=DOC/"schemas"/"HUMAN_REVIEW_DECISION.schema.json"
DECISIONS=PACKET/"REVIEW_DECISIONS.json"
MANIFEST=PACKET/"MANIFEST.json"

def load_json(p):
    return json.loads(p.read_text(encoding="utf-8-sig"))

def sha256(p):
    h=hashlib.sha256()
    h.update(p.read_bytes())
    return h.hexdigest()

def main():
    schema=load_json(SCHEMA)
    d=load_json(DECISIONS)
    m=load_json(MANIFEST)
    jsonschema.validate(d,schema)

    assert d["unitId"]==m["unitId"]
    assert d["snapshot"]["sourceCommit"]==m["sourceCommit"]
    assert d["snapshot"]["manifestSha256"]==sha256(MANIFEST)

    decisions=[lane["decision"] for lane in d["lanes"].values()]
    allowed={"APPROVE","APPROVE_WITH_EDITS","HOLD"}

    if d["status"]=="OPEN":
        # Open state may contain no decisions or partial reviewer work.
        assert all(x=="" or x in allowed for x in decisions)
    elif d["status"]=="CHANGES_REQUESTED":
        assert any(x in {"APPROVE_WITH_EDITS","HOLD"} for x in decisions)
    elif d["status"]=="HUMAN_REVIEWED_READY_FOR_PILOT":
        assert all(x in {"APPROVE","APPROVE_WITH_EDITS"} for x in decisions)
        assert not any(x=="HOLD" for x in decisions)
        assert all(x!="" for x in decisions)
        assert d["pilotGate"]["decision"]=="READY"

        # A reviewer identity/code and date are required once a lane is counted as reviewed.
        for name,lane in d["lanes"].items():
            assert lane["reviewerCode"].strip(), (name,"reviewerCode missing")
            assert lane["date"].strip(), (name,"date missing")
            # No blank required check once the lane is approved.
            blank=[k for k,v in lane["checks"].items() if v==""]
            assert not blank, (name,"blank checks",blank)

    print(
        f"PASS unit04_review_decisions status={d['status']} "
        f"lane_decisions={','.join(x or 'OPEN' for x in decisions)}"
    )

if __name__=="__main__":
    main()
