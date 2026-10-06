#!/usr/bin/env python3
import csv, json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
P = ROOT / "docs" / "textbook_project" / "data" / "ONE_A_UNIT_CONTRACTS_20261006.json"
ALLOC = ROOT / "docs" / "textbook_project" / "data" / "TEXTBOOK_SOURCE_POOL_ALLOCATION_RESOLVED_1A_6B.csv"
ERR = ROOT / "docs" / "textbook_project" / "data" / "A1_LEARNER_ERROR_MATRIX_EN_DE_20261006.json"

BATCHES = [
    ROOT / "docs" / "textbook_project" / "research" / "TIER1_NATIVE_USAGE_BATCH01_20261006.json",
    ROOT / "docs" / "textbook_project" / "research" / "TIER1_NATIVE_USAGE_BATCH02_20261006.json",
    ROOT / "docs" / "textbook_project" / "research" / "TIER1_NATIVE_USAGE_BATCH03_1A_READINESS_20261006.json",
    ROOT / "docs" / "textbook_project" / "research" / "TIER1_NATIVE_USAGE_BATCH04_NUMBERS_TIME_20261006.json",
]

EXPECTED_UNITS = [
    "a1_01_greetings_hangul",
    "a1_02_self_intro_identity",
    "a1_03_topic_subject_particles",
    "a1_04_order_request_object",
    "a1_05_numbers_time",
    "a1_06_transport_directions",
    "a1_07_contact_address",
    "a1_08_clarify_repair",
]

def load_json(p):
    return json.loads(p.read_text(encoding="utf-8-sig"))

def main():
    d = load_json(P)
    assert d["book"] == "1A" and d["level"] == "A1"
    units = d["units"]
    assert [u["unitId"] for u in units] == EXPECTED_UNITS
    assert [u["order"] for u in units] == list(range(1,9))

    alloc_rows = list(csv.DictReader(ALLOC.open(encoding="utf-8-sig", newline="")))
    source_ids = {r["sourceId"] for r in alloc_rows}
    unit_sources = {}
    for u in EXPECTED_UNITS:
        unit_sources[u] = {r["sourceId"] for r in alloc_rows if r["preferredUnitId"] == u}
        assert unit_sources[u], u

    err = load_json(ERR)
    error_ids = {x["id"] for lang in ("en","de") for x in err[lang]}

    native_topics = set()
    for p in BATCHES:
        native_topics.update(t["topicId"] for t in load_json(p)["topics"])

    required_fields = [
        "canDo","communicativeProblem","relationship","authoritativeScenarioIds",
        "nativeUsageTopics","targetFunctions","productiveGrammar","coreChunks",
        "pronunciation","pragmatics","culture","inputTasks","outputTasks",
        "readingTasks","writingTasks","interactionTask","assessment",
        "productionCeiling"
    ]

    for u in units:
        uid = u["unitId"]
        for f in required_fields:
            assert u.get(f), (uid, f)

        for sid in u["authoritativeScenarioIds"]:
            assert sid in source_ids, (uid, "authoritative", sid)
            assert sid in unit_sources[uid], (uid, "wrong unit", sid)

        for sid in u.get("supplementarySourceIds", []):
            assert sid in source_ids, (uid, "supplementary", sid)

        for topic in u["nativeUsageTopics"]:
            assert topic in native_topics, (uid, "missing native usage", topic)

        for rid in u.get("enLearnerRisks", []) + u.get("deLearnerRisks", []):
            assert rid in error_ids, (uid, "bad risk id", rid)

        a = u["assessment"]
        assert a.get("mustProduce") and a.get("mustRecognize") and a.get("success")

        formulaic = u.get("formulaicProduction", [])
        f_forms = {x["form"] for x in formulaic}
        r_forms = {x["form"] for x in u.get("recognitionOnly", [])}
        assert not (f_forms & r_forms), (uid, "formulaic/recognition overlap", f_forms & r_forms)
        for x in formulaic:
            assert x.get("examples"), (uid, "formulaic examples missing", x["form"])
            for example in x["examples"]:
                assert example in u["coreChunks"], (uid, "formulaic example not in core", example)

    contact = next(x for x in units if x["unitId"]=="a1_07_contact_address")
    assert {"-세요?","-(으)ㄹ까요?","-ㄹ게요","-(으)ㄹ 것 같아요"} == {
        x["form"] for x in contact.get("formulaicProduction", [])
    }
    assert {x["form"] for x in contact["recognitionOnly"]} == {"-(으)실래요?"}

    repair = units[-1]
    rec_forms = {x["form"] for x in repair["recognitionOnly"]}
    assert {"-는데요","계신지","몰랐어요","-ㄹ게요","뭐라고요?"} <= rec_forms
    prod_forms = {x["form"] for x in repair["productiveGrammar"]}
    assert not ({"-는데요","계신지","-ㄹ게요"} & prod_forms)

    order = next(x for x in units if x["unitId"]=="a1_04_order_request_object")
    assert "food_drink" in order["nativeUsageTopics"]
    assert "bunshik_tteokbokki" in order["authoritativeScenarioIds"]

    print(f"PASS book=1A units={len(units)} native_topics={len(native_topics)} error_ids={len(error_ids)}")

if __name__ == "__main__":
    main()
