#!/usr/bin/env python3
import json
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[2]
DOC = ROOT / "docs" / "textbook_project"
REGISTRY = DOC / "data" / "ONE_A_OFFICIAL_GRAMMAR_REGISTRY_20261006.json"
CONTRACTS = DOC / "data" / "ONE_A_UNIT_CONTRACTS_20261006.json"

ALLOWED_HOSTS = {
    "korean.go.kr",
    "www.korean.go.kr",
    "krdict.korean.go.kr",
}

PROHIBITED_STUDENT_PHRASES = [
    "주세요 is not “Give me",
    "주세요 is not \"Give me",
    "There is no single fixed English translation for 주세요",
    "keine einzige deutsche Standardübersetzung",
    "Partikeln kann man einfach weglassen",
    "the noun can appear naturally without 을/를",
]

def load_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))

def host_of(url):
    return (urlparse(url).hostname or "").lower()

def main():
    reg = load_json(REGISTRY)
    contracts = load_json(CONTRACTS)

    assert reg["policyStatus"] == "OFFICIAL_GRAMMAR_ONLY"
    assert set(reg["policy"]["grammarDefinitionAllowedDomains"]) == ALLOWED_HOSTS

    sources = reg["officialSources"]
    entries = reg["grammarEntries"]

    # Every URL used as a grammar authority must be official.
    url_count = 0
    for sid, src in sources.items():
        assert src["publisher"] == "국립국어원", (sid, src.get("publisher"))
        urls = []
        for key in ("url", "landingUrl", "companionUrl"):
            value = src.get(key)
            if value:
                urls.append(value)
        assert urls, (sid, "no official URL")
        for url in urls:
            url_count += 1
            host = host_of(url)
            assert host in ALLOWED_HOSTS, (sid, host, url)

    # Grammar entries may cite only registry sources.
    for gid, entry in entries.items():
        assert entry.get("sourceIds"), (gid, "missing sourceIds")
        assert entry.get("officialExplanationKo"), (gid, "missing KO explanation")
        assert entry.get("explanationEn"), (gid, "missing EN explanation")
        assert entry.get("explanationDe"), (gid, "missing DE explanation")
        for sid in entry["sourceIds"]:
            assert sid in sources, (gid, sid)

    # Productive grammar must always be official-source traceable.
    productive_count = 0
    chunk_only_count = 0
    official_formulaic_count = 0
    official_recognition_count = 0

    for unit in contracts["units"]:
        uid = unit["unitId"]

        for item in unit.get("productiveGrammar", []):
            productive_count += 1
            assert item.get("grammarSourcePolicy") == "official_only", (uid, item)
            refs = item.get("grammarRefs")
            assert refs, (uid, "productive grammar missing official refs", item)
            for ref in refs:
                assert ref in entries, (uid, ref)

        for layer in ("formulaicProduction", "recognitionOnly"):
            for item in unit.get(layer, []):
                refs = item.get("grammarRefs", [])
                chunk_only = item.get("chunkOnlyNoGrammarExplanation") is True
                assert bool(refs) ^ chunk_only, (
                    uid,
                    layer,
                    "must have either official refs or chunk-only marker",
                    item,
                )
                if refs:
                    assert item.get("grammarSourcePolicy") == "official_only"
                    for ref in refs:
                        assert ref in entries, (uid, layer, ref)
                    if layer == "formulaicProduction":
                        official_formulaic_count += 1
                    else:
                        official_recognition_count += 1
                else:
                    chunk_only_count += 1

    # Critical audited forms.
    unit04 = next(u for u in contracts["units"] if u["unitId"] == "a1_04_order_request_object")
    prod04 = {x["form"]: x for x in unit04["productiveGrammar"]}
    assert "G_SERVICE_JUSEYO" in prod04["N 주세요"]["grammarRefs"]
    assert "G_OBJECT_EULREUL" in prod04["을/를"]["grammarRefs"]
    assert "G_SHORT_NEGATION_AN" in prod04["안 + adjective/verb"]["grammarRefs"]

    unit07 = next(u for u in contracts["units"] if u["unitId"] == "a1_07_contact_address")
    f07 = {x["form"]: x for x in unit07["formulaicProduction"]}
    assert "-세요?" not in f07
    assert f07["카톡 하세요?"].get("chunkOnlyNoGrammarExplanation") is True
    assert "G_PROPOSAL_LKKAYO" in f07["-(으)ㄹ까요?"]["grammarRefs"]
    assert "G_INTENTION_LGEYO" in f07["-ㄹ게요"]["grammarRefs"]
    assert "G_CONJECTURE_GEOT_GATDA" in f07["-(으)ㄹ 것 같아요"]["grammarRefs"]

    # Learner pages must not regress to old assistant-authored claims.
    learner_files = []
    for n in range(1, 9):
        folder = DOC / "pilot_1A" / f"unit{n:02d}"
        for name in ("STUDENT_EN.md", "STUDENT_DE.md"):
            p = folder / name
            assert p.exists(), p
            learner_files.append(p)

    unit04_master = DOC / "pilot_1A" / "unit04" / "STUDENT_MASTER.md"
    learner_files.append(unit04_master)

    for p in learner_files:
        text = p.read_text(encoding="utf-8-sig")
        for phrase in PROHIBITED_STUDENT_PHRASES:
            assert phrase not in text, (p, phrase)

    en04 = (DOC / "pilot_1A" / "unit04" / "STUDENT_EN.md").read_text(encoding="utf-8-sig")
    de04 = (DOC / "pilot_1A" / "unit04" / "STUDENT_DE.md").read_text(encoding="utf-8-sig")
    master04 = unit04_master.read_text(encoding="utf-8-sig")

    assert "Official grammar note — 주세요" in en04
    assert "Localization note — not a grammar definition" in en04
    assert "G_SERVICE_JUSEYO" in en04
    assert "Offizieller Grammatikhinweis — 주세요" in de04
    assert "Lokalisierungshinweis — keine Grammatikdefinition" in de04
    assert "G_SERVICE_JUSEYO" in de04
    assert "공식 문법 설명 — 주세요" in master04
    assert "번역·현지화" in master04

    # Generated learner pages should be driven by official registry explanations,
    # but should not expose internal source IDs.
    for n in (1, 2, 3, 5, 6, 7, 8):
        for lang in ("EN", "DE"):
            text = (DOC / "pilot_1A" / f"unit{n:02d}" / f"STUDENT_{lang}.md").read_text(
                encoding="utf-8-sig"
            )
            assert "Official grammar refs:" not in text
            assert "Official sources:" not in text

    # Teacher guides keep traceability.
    teacher_trace = 0
    for n in (1, 2, 3, 5, 6, 7, 8):
        text = (DOC / "pilot_1A" / f"unit{n:02d}" / "TEACHER_GUIDE.md").read_text(
            encoding="utf-8-sig"
        )
        if "Official sources:" in text:
            teacher_trace += 1
    assert teacher_trace == 7

    print(
        "PASS "
        f"official_sources={len(sources)} official_urls={url_count} "
        f"grammar_entries={len(entries)} productive={productive_count} "
        f"formulaic_official={official_formulaic_count} "
        f"recognition_official={official_recognition_count} "
        f"chunk_only={chunk_only_count} teacher_trace={teacher_trace}"
    )

if __name__ == "__main__":
    main()
