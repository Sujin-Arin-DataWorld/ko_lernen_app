#!/usr/bin/env python3
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
P=ROOT/"docs"/"textbook_project"/"research"/"TIER1_NATIVE_USAGE_BATCH04_NUMBERS_TIME_20261006.json"

def main():
    d=json.loads(P.read_text(encoding="utf-8-sig"))
    assert d["status"]=="EVIDENCE_PACK_BROAD_PASS_COMPLETE"
    assert len(d["topics"])==1
    t=d["topics"][0]
    assert t["topicId"]=="numbers_time_dates"
    sources=d["sources"]
    required_functions={"ask_time","propose_time","confirm_time","delay_notice","status_update"}
    for lang in ("ko","en","de"):
        p=t[lang]
        assert p["status"]=="broad_pass_complete"
        assert len(p["sourceRefs"])>=3, (lang,"sourceRefs")
        assert len(p["patterns"])>=8, (lang,"patterns")
        assert len(set(p["registerLanes"]))>=2, (lang,"registers")
        assert p["avoidTranslationese"]
        assert p["speechSurfaceNotes"]
        assert all(x in sources for x in p["sourceRefs"])
        funcs={x["function"] for x in p["patterns"]}
        assert required_functions <= funcs, (lang, required_functions-funcs)
    assert t["crossLanguage"]["categoryShiftRisks"]
    print("PASS topic=numbers_time_dates languages=3 scheduling_functions=5")

if __name__=="__main__":
    main()
