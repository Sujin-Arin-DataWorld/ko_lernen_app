"""Validate coverage, dialogue grounding and serialization of listening lessons.

These checks prove data contracts, not native-speaker approval or distractor
ambiguity judgments. Run this after any catalog or scenario-corpus change.
"""
import collections
import hashlib
import json
import re
import unicodedata
from pathlib import Path

from author_listening_lessons import LEVELS, LANGS, ROOT, build, load_sources


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        assert key not in result, f"Duplicate JSON key: {key}"
        result[key] = value
    return result


def validate():
    path = ROOT / "assets/data/listening_lessons.json"
    raw = path.read_text(encoding="utf-8")
    data = json.loads(raw, object_pairs_hook=unique_object)
    assert data["version"] == 1
    assert data == build(), "Catalog differs from the reproducible authored source"
    sources = {s["id"]: s for s in load_sources()}
    lessons = data["lessons"]
    assert len(lessons) == len(sources) == 178
    assert len({l["id"] for l in lessons}) == 178
    assert collections.Counter(cid for l in lessons for cid in l["contentIds"]) == collections.Counter(sources.keys())
    question_ids = set()

    def localized(obj, label):
        assert set(obj) == set(LANGS), label
        for lang, value in obj.items():
            assert isinstance(value, str) and value and value == value.strip(), (label, lang)

    def strings(value):
        if isinstance(value, str):
            assert "\ufffd" not in value
            assert value == unicodedata.normalize("NFC", value), value
            assert not any(ord(c) < 32 for c in value), value
            assert not re.search(r"\b(?:TODO|TBD|PLACEHOLDER)\b", value)
        elif isinstance(value, dict):
            for nested in value.values():
                strings(nested)
        elif isinstance(value, list):
            for nested in value:
                strings(nested)

    strings(data)
    for lesson in lessons:
        sid, = lesson["contentIds"]
        source = sources[sid]
        dialog = source["dialog"]
        utterances = [line["ko"] for line in dialog]
        assert lesson["id"] == f'listening.{source["level"]}.{sid}'
        assert lesson["kind"] == "listening"
        assert lesson["level"] == source["level"]
        assert lesson["topicId"] == source["shelf"]
        for field in ("title", "intro"):
            localized(lesson[field], f'{sid}.{field}')
            assert lesson[field] == {lang: source[field][lang] for lang in LANGS}
        assert len(lesson["questions"]) == 4
        assert [q["skill"] for q in lesson["questions"]] == ["situation", "meaning", "sentence", "response"]
        for q in lesson["questions"]:
            assert q["id"] not in question_ids
            question_ids.add(q["id"])
            assert q["id"] == f'{lesson["id"]}.{q["skill"]}'
            assert q["sourceIds"] == [sid]
            for field in ("prompt", "explanation"):
                localized(q[field], f'{q["id"]}.{field}')
            assert q["evidenceKo"] in utterances, q["id"]
            assert q["evidenceKo"] in q["explanation"]["ko"], q["id"]
            if "audioKo" in q:
                assert q["audioKo"] in utterances, q["id"]
            if q["type"] == "order":
                assert q["skill"] == "sentence"
                assert q["targetKo"] in utterances
                assert q["audioKo"] == q["targetKo"] == q["evidenceKo"]
                assert len(q["targetKo"].split()) >= 2
                assert "options" not in q and "correctIndex" not in q
            else:
                assert q["type"] == "choice"
                assert len(q["options"]) == 3
                assert isinstance(q["correctIndex"], int) and 0 <= q["correctIndex"] < 3
                assert "targetKo" not in q
                for option in q["options"]:
                    localized(option, q["id"])
                for lang in LANGS:
                    assert len({o[lang].casefold() for o in q["options"]}) == 3, (q["id"], lang)
                if q["skill"] == "meaning" or (q["skill"] == "response" and "audioKo" in q):
                    answer = q["options"][q["correctIndex"]]
                    assert answer["ko"] == q["evidenceKo"]
                    assert any(all(line[lang] == answer[lang] for lang in LANGS) for line in dialog)
                if q["skill"] == "meaning":
                    assert all(any(all(line[lang] == option[lang] for lang in LANGS)
                                       for line in dialog) for option in q["options"])
                    assert q["audioKo"] == q["evidenceKo"]
                if q["skill"] == "response":
                    assert "immediately after" not in q["prompt"]["en"]
                    assert "purpose" in q["explanation"]["en"] or "goal" in q["explanation"]["en"] or "conditions" in q["prompt"]["en"]
                    if "audioKo" in q:
                        assert any(a["ko"] == q["audioKo"] and b["ko"] == q["evidenceKo"]
                                   and a["speaker"] != b["speaker"]
                                   for index, b in enumerate(dialog)
                                   for a in dialog[:index]), q["id"]
                    else:
                        assert source["level"] in ("b2", "c1", "c2")
                        assert "Imagine" in q["prompt"]["en"]
                        # Corrective follow-ups are authored propositions, not
                        # context-dependent agreement tokens transplanted from
                        # the source dialogue. Evidence remains exact above.
                        answer = q["options"][q["correctIndex"]]
                        assert not re.match(r"^(네[,. ]|맞습니다|좋아요|그럼[,. ]|그러게|그래서)", answer["ko"]), q["id"]
                        assert not re.match(r"^(Yes[,. ]|That's right|Right[,.]|Good[,.])", answer["en"]), q["id"]
                        assert not re.match(r"^(Ja[,. ]|Das stimmt|Gut[,. ])", answer["de"]), q["id"]
        if source["level"] in ("b2", "c1", "c2"):
            q = lesson["questions"][0]
            assert "의도" in q["prompt"]["ko"]
            assert all(o["ko"] != source["intro"]["ko"] for o in q["options"])
    assert len(question_ids) == 712
    return {
        "lessons": len(lessons), "questions": len(question_ids),
        "levels": dict(collections.Counter(l["level"] for l in lessons)),
        "skills": dict(collections.Counter(q["skill"] for l in lessons for q in l["questions"])),
        "advancedInferenceItems": 90,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "status": "STRUCTURAL_PASS; model-authored language QA, no human approval claimed",
    }


if __name__ == "__main__":
    print(json.dumps(validate(), ensure_ascii=False, indent=2))
