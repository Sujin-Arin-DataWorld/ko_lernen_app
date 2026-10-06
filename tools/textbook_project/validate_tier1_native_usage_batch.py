#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PACK = ROOT / "docs" / "textbook_project" / "research" / "TIER1_NATIVE_USAGE_BATCH01_20261006.json"


def main():
    d = json.loads(PACK.read_text(encoding="utf-8-sig"))
    assert d["status"] == "EVIDENCE_PACK_BROAD_PASS_COMPLETE"
    assert len(d["topics"]) == 3

    source_ids = set(d["sources"])
    for topic in d["topics"]:
        for lang in ("ko", "en", "de"):
            p = topic[lang]
            assert p["status"] == "broad_pass_complete", (topic["topicId"], lang)
            assert len(p["sourceRefs"]) >= 3, (topic["topicId"], lang, "sources")
            assert len(set(p["registerLanes"])) >= 2, (topic["topicId"], lang, "lanes")
            assert len(p["patterns"]) >= 8, (topic["topicId"], lang, "patterns")
            assert p["avoidTranslationese"], (topic["topicId"], lang, "translationese")
            assert all(ref in source_ids for ref in p["sourceRefs"])
            for pat in p["patterns"]:
                assert pat["surfacePattern"].strip()
                assert pat["function"].strip()
                assert pat["registerLane"].strip()
                assert pat["tone"].strip()

        assert topic["crossLanguage"]["categoryShiftRisks"]

    print("PASS topics=3 languages=9 min_sources=3 min_patterns=8")


if __name__ == "__main__":
    main()
