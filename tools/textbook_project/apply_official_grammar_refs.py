#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
P = ROOT / "docs" / "textbook_project" / "data" / "ONE_A_UNIT_CONTRACTS_20261006.json"

PRODUCTIVE_MAP = {
    "-아/어 주세요": ["G_REQUEST_AEO_JUSEYO"],
    "은/는": ["G_TOPIC_EUNNEUN"],
    "이에요/예요": ["G_COPULA_IDA"],
    "N에서 왔어요": ["G_ESEO"],
    "이/가": ["G_SUBJECT_IGA"],
    "에 있다": ["G_E_LOCATION_TIME_DESTINATION", "G_EXIST_ITDA"],
    "을/를": ["G_OBJECT_EULREUL"],
    "N 주세요": ["G_SERVICE_JUSEYO"],
    "안 + adjective/verb": ["G_SHORT_NEGATION_AN"],
    "N시에": ["G_E_LOCATION_TIME_DESTINATION"],
    "아니에요": ["G_ANIDA"],
    "에": ["G_E_LOCATION_TIME_DESTINATION"],
    "(으)로": ["G_EURO"],
    "있어요": ["G_EXIST_ITDA"],
    "무슨 N": ["G_MUSEUN"],
}

FORMULAIC_MAP = {
    "-(으)ㄹ까요?": ["G_PROPOSAL_LKKAYO"],
    "-ㄹ게요": ["G_INTENTION_LGEYO"],
    "-(으)ㄹ 것 같아요": ["G_CONJECTURE_GEOT_GATDA"],
}

RECOGNITION_MAP = {
    "이에요/예요": ["G_COPULA_IDA"],
    "-(으)시-": ["G_SUBJECT_HONORIFIC_SI"],
    "-(으)셨어요": ["G_SUBJECT_HONORIFIC_SI"],
    "-ㄹ게요": ["G_INTENTION_LGEYO"],
    "-는데요": ["G_NDEYO"],
    "계신지": ["G_GYESIDA", "G_NJI"],
}

def main():
    d = json.loads(P.read_text(encoding="utf-8-sig"))

    for u in d["units"]:
        for x in u.get("productiveGrammar", []):
            refs = PRODUCTIVE_MAP.get(x["form"])
            if not refs:
                raise SystemExit(f"Missing productive mapping: {u['unitId']} {x['form']}")
            x["grammarRefs"] = refs
            x["grammarSourcePolicy"] = "official_only"

        u["recognitionOnly"] = [
            x for x in u.get("recognitionOnly", [])
            if x["form"] != "합니다체 어미 전반"
        ]

        for x in u.get("formulaicProduction", []):
            if u["unitId"] == "a1_07_contact_address" and x["form"] == "-세요?":
                x["form"] = "카톡 하세요?"
                x["reason"] = (
                    "fixed learner-use chunk; no generalized -세요? grammar rule "
                    "is introduced here"
                )
            refs = FORMULAIC_MAP.get(x["form"])
            if refs:
                x["grammarRefs"] = refs
                x["grammarSourcePolicy"] = "official_only"
                x.pop("chunkOnlyNoGrammarExplanation", None)
            else:
                x["chunkOnlyNoGrammarExplanation"] = True
                x.pop("grammarRefs", None)
                x.pop("grammarSourcePolicy", None)

        for x in u.get("recognitionOnly", []):
            refs = RECOGNITION_MAP.get(x["form"])
            if refs:
                x["grammarRefs"] = refs
                x["grammarSourcePolicy"] = "official_only"
                x.pop("chunkOnlyNoGrammarExplanation", None)
            else:
                x["chunkOnlyNoGrammarExplanation"] = True
                x.pop("grammarRefs", None)
                x.pop("grammarSourcePolicy", None)

    d["globalRules"]["grammarSourcePolicy"] = (
        "grammar definitions/functions/constraints use official NIKL/Korean Basic "
        "Dictionary sources only; usage corpus and localization are separate evidence layers"
    )
    registry = "docs/textbook_project/data/ONE_A_OFFICIAL_GRAMMAR_REGISTRY_20261006.json"
    if registry not in d["governingSources"]:
        d["governingSources"].append(registry)

    P.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"PASS units={len(d['units'])} official_refs_applied=true")

if __name__ == "__main__":
    main()
