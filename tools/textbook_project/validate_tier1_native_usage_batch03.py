#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PACK = ROOT / "docs" / "textbook_project" / "research" / "TIER1_NATIVE_USAGE_BATCH03_1A_READINESS_20261006.json"

EXPECTED_TOPICS = {
    "personal_identification",
    "communication_phone_digital",
    "language_learning_communication_repair",
    "social_etiquette_customs",
}

def main():
    d = json.loads(PACK.read_text(encoding="utf-8-sig"))
    assert d["status"] == "EVIDENCE_PACK_BROAD_PASS_COMPLETE"
    assert {t["topicId"] for t in d["topics"]} == EXPECTED_TOPICS
    sources = d["sources"]

    for topic in d["topics"]:
        for lang in ("ko", "en", "de"):
            p = topic[lang]
            assert p["status"] == "broad_pass_complete", (topic["topicId"], lang)
            assert len(p["sourceRefs"]) >= 3, (topic["topicId"], lang, "sources")
            assert len(p["patterns"]) >= 8, (topic["topicId"], lang, "patterns")
            assert len(set(p["registerLanes"])) >= 2, (topic["topicId"], lang, "registers")
            assert p["avoidTranslationese"], (topic["topicId"], lang, "translationese")
            assert p["speechSurfaceNotes"], (topic["topicId"], lang, "speech")
            for ref in p["sourceRefs"]:
                assert ref in sources, (topic["topicId"], lang, ref)
            for pat in p["patterns"]:
                for key in ("surfacePattern", "function", "registerLane", "tone"):
                    assert str(pat.get(key, "")).strip(), (topic["topicId"], lang, key)
        assert topic["crossLanguage"]["categoryShiftRisks"], topic["topicId"]

    repair = next(t for t in d["topics"] if t["topicId"] == "language_learning_communication_repair")
    for lang in ("ko", "en", "de"):
        functions = {p["function"] for p in repair[lang]["patterns"]}
        assert "repeat_request" in functions
        assert "meaning_request" in functions
        assert "confirmation" in functions

    etiquette = next(t for t in d["topics"] if t["topicId"] == "social_etiquette_customs")
    assert any(p["function"] == "register_negotiation" for p in etiquette["ko"]["patterns"])
    assert any(p["function"] == "register_negotiation" for p in etiquette["de"]["patterns"])

    print("PASS topics=4 languages=12 1A_readiness=true repair_functions=true register_negotiation=true")

if __name__ == "__main__":
    main()
