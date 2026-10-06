#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PACK = ROOT / "docs" / "textbook_project" / "research" / "TIER1_NATIVE_USAGE_BATCH02_20261006.json"

def main():
    d = json.loads(PACK.read_text(encoding="utf-8-sig"))
    assert d["status"] == "EVIDENCE_PACK_BROAD_PASS_COMPLETE"
    assert len(d["topics"]) == 4

    sources = d["sources"]
    for topic in d["topics"]:
        for lang in ("ko","en","de"):
            p = topic[lang]
            assert p["status"] == "broad_pass_complete", (topic["topicId"], lang)
            assert len(p["sourceRefs"]) >= 3, (topic["topicId"], lang, "sources")
            assert len(p["patterns"]) >= 8, (topic["topicId"], lang, "patterns")
            assert len(set(p["registerLanes"])) >= 2, (topic["topicId"], lang, "registers")
            assert p["avoidTranslationese"], (topic["topicId"], lang, "translationese")
            assert p["speechSurfaceNotes"], (topic["topicId"], lang, "speech surface")
            assert all(ref in sources for ref in p["sourceRefs"]), (topic["topicId"], lang, "missing source ref")
            for pat in p["patterns"]:
                for key in ("surfacePattern","function","registerLane","tone"):
                    assert str(pat.get(key,"")).strip(), (topic["topicId"], lang, key)
        assert topic["crossLanguage"]["categoryShiftRisks"], topic["topicId"]

    health = next(t for t in d["topics"] if t["topicId"] == "health_body")
    for lang in ("ko","en","de"):
        assert health[lang].get("authoritativeTerminology"), ("health terminology", lang)
        assert any(sources[r]["genre"] == "authoritative_health" for r in health[lang]["sourceRefs"])

    print("PASS topics=4 languages=12 health_authority=3 multi_genre=true")

if __name__ == "__main__":
    main()
