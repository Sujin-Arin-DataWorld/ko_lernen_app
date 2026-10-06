"""Read-only export of every published record used by C free learning."""
import ast
import csv
import hashlib
import json
import re
from collections import Counter, defaultdict
from pathlib import Path
from urllib.parse import urlencode, quote

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SOURCES, LEDGER, ASSETS = {}, [], set()


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def read(path):
    raw = (ROOT / path).read_bytes()
    SOURCES[path] = digest(raw)
    return raw.decode("utf-8-sig")


def corpus(path):
    return json.loads(read(path))


def rows(path):
    return list(csv.DictReader(read(path).splitlines()))


def route(view, module, id="", **more):
    return "screen.html?" + urlencode({"view": view, "m": module, **({"id": id} if id else {}), **more})


def record(module, kind, item, source, pointer, url, identity="authored_id", id=None, version=None):
    LEDGER.append({"module": module, "kind": kind, "id": id or item["id"], "identity": identity,
                   "source": source, "pointer": pointer, "sourceHash": SOURCES[source],
                   "recordHash": digest(json.dumps(item, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()),
                   "version": item.get("revision", item.get("contentRevision", version)), "url": url})


def asset(path):
    if path and (ROOT / path).is_file():
        ASSETS.add(path)
        return path
    return None


vocab_path = "assets/data/korean_vocab.csv"
vocab = rows(vocab_path)
pack_manifest = corpus("docs/assets/VOCAB_PACK_CARD_MANIFEST.json")
pack_art = {p["packId"]: p["primaryAsset"] for p in pack_manifest["packs"]}
pack_service = read("lib/services/vocab_pack_service.dart")
labels = {}
for match in re.finditer(r"'([^']+)':\s*\(('(?:[^'\\]|\\.)*'),\s*('(?:[^'\\]|\\.)*')\)", pack_service):
    labels[match[1]] = {"de": ast.literal_eval(match[2]), "en": ast.literal_eval(match[3])}
grouped = defaultdict(list)
for index, word in enumerate(vocab):
    grouped[word["pack_id"]].append(word)
    record("words", "word", word, vocab_path, f"/csv/{index+2}", route("card", "words", word["pack_id"], item=word["id"]))
packs = []
for pack_id, members in grouped.items():
    words = sorted(members, key=lambda w: int(w["pack_order"] or 0))
    base, sub = (re.sub(r"_\d+$", "", pack_id), re.search(r"_(\d+)$", pack_id))
    title = labels.get(base, {"de": words[0]["topic"] or pack_id, "en": pack_id})
    title = {k: v + (f" ({sub[1]})" if sub else "") for k, v in title.items()}
    pack = {"id": pack_id, "level": words[0]["level"], "title": title, "topic": words[0]["topic"],
            "wordIds": [w["id"] for w in words], "normalIds": [w["id"] for w in words if w["is_review_boss"] != "true"],
            "bossIds": [w["id"] for w in words if w["is_review_boss"] == "true"], "art": asset(pack_art.get(pack_id))}
    packs.append(pack)
    record("words", "pack", pack, vocab_path, f"/pack_id={pack_id}", route("detail", "words", pack_id), "derived_group")

grammar_path = "assets/data/grammar.csv"
grammar = rows(grammar_path)
for i, row in enumerate(grammar):
    record("grammar", "grammar", row, grammar_path, f"/csv/{i+2}", route("detail", "grammar", row["id"]))
pron_path = "assets/data/pronunciation_phrases.json"
pron = corpus(pron_path)
for i, item in enumerate(pron["phrases"]):
    record("pronunciation", "phrase", item, pron_path, f"/phrases/{i}", route("detail", "pronunciation", item["id"]), version=pron["version"])

scenarios = []
for level in ["a1", "a2", "b1", "b2", "c1", "c2"]:
    path = f"assets/data/scenarios_{level}.json"
    source = corpus(path)
    for i, item in enumerate(source["scenarios"]):
        record("scenarios", "scenario", item, path, f"/scenarios/{i}", route("detail", "scenarios", item["id"]), version=source["version"])
        for field in ["vocab", "dialog", "quests", "rollenspiel"]:
            values = item.get(field, [])
            if not isinstance(values, list):
                continue
            for n, child in enumerate(values):
                if not isinstance(child, dict):
                    child = {"text": child}
                cid = child.get("id", f"{item['id']}:{field}:{n}")
                view = "practice" if field == "quests" else "scenario"
                stage = {"vocab": "vocab", "dialog": "dialog", "rollenspiel": "role", "quests": "quests"}[field]
                record("scenarios", field, child, path, f"/scenarios/{i}/{field}/{n}", route(view, "scenarios", item["id"], stage=stage, item=cid, at=n),
                       "authored_id" if child.get("id") else "source_pointer", id=cid, version=source["version"])
        asset(f"assets/illustrations/scenes/{item.get('backdrop')}.png")
        scenarios.append(item)

listen_path = "assets/data/listening_lessons.json"
listening = corpus(listen_path)
for i, lesson in enumerate(listening["lessons"]):
    record("listening", "lesson", lesson, listen_path, f"/lessons/{i}", route("detail", "listening", lesson["id"]), version=listening["version"])
    for n, question in enumerate(lesson["questions"]):
        record("listening", "question", question, listen_path, f"/lessons/{i}/questions/{n}", route("practice", "listening", lesson["id"], item=question["id"]), version=listening["version"])

relation_path = "assets/data/word_relations.json"
relations = corpus(relation_path)
for i, cluster in enumerate(relations["clusters"]):
    record("relations", "cluster", cluster, relation_path, f"/clusters/{i}", route("detail", "relations", cluster["id"]), version=relations["version"])
    for field in ["synonyms", "antonyms", "related", "expressions"]:
        for n, child in enumerate(cluster[field]):
            cid = f"{cluster['id']}:{field}:{n}"
            record("relations", field, child, relation_path, f"/clusters/{i}/{field}/{n}", route("detail", "relations", cluster["id"], item=cid), "source_pointer", id=cid, version=relations["version"])

extras = []
for kind, path, key in [("usage", "assets/data/usage_notes.json", "notes"), ("culture", "assets/data/culture_notes.json", "notes"),
                         ("media", "assets/data/media_phrases.json", "phrases"), ("patterns", "assets/data/grammar_patterns.json", None)]:
    src = corpus(path)
    values = src[key] if key else src
    for n, value in enumerate(values):
        cid = f"{kind}:{value.get('id', n)}"
        item = {"id": cid, "kind": kind, "data": value}
        extras.append(item)
        record("extras", kind, value, path, f"/{key}/{n}" if key else f"/{n}", route("extra", "extras", cid),
               "authored_id" if value.get("id") else "source_pointer", id=cid, version=src.get("version", src.get("schemaVersion")) if isinstance(src, dict) else None)

manifest = corpus("assets/data/tts_canonical_manifest.json")
voices = {k: set(v) for k, v in manifest["voices"].items()}
audio = {}


def register_audio(text):
    if not isinstance(text, str) or not text.strip():
        return
    text = text.strip()
    voice = "male" if hashlib.sha1(f"hangul-sori-auto-voice-v1|{text}".encode()).digest()[0] % 2 else "female"
    key = hashlib.sha1(f"{voice}|{text}".encode()).hexdigest()
    path = f"tts/{manifest['cacheRevision']}/{voice}/{key}.mp3"
    audio[text] = {"voice": voice, "hash": key, "canonical": key in voices[voice],
                   "url": "https://firebasestorage.googleapis.com/v0/b/ko-lernen-app.firebasestorage.app/o/" + quote(path, safe="") + "?alt=media" if key in voices[voice] else None}


for item in vocab:
    register_audio(item["korean"])
    register_audio(item["example_korean"])
for item in grammar:
    register_audio(item["example_korean"])
for item in pron["phrases"]:
    register_audio(item["ko"])
for scenario in scenarios:
    for line in scenario.get("dialog", []):
        register_audio(line.get("ko"))
    for quest in scenario.get("quests", []):
        register_audio(quest["data"].get("audioKo", quest["data"].get("targetKo")))
for lesson in listening["lessons"]:
    for question in lesson["questions"]:
        register_audio(question.get("audioKo"))
for cluster in relations["clusters"]:
    register_audio(cluster["sourceKo"])
    for field in ["synonyms", "antonyms", "related", "expressions"]:
        for node in cluster[field]:
            register_audio(node["ko"])

for path in ["lib/models/vocab_pack.dart", "lib/services/grammar_choice_quiz.dart", "lib/services/review_deck_service.dart",
             "lib/services/word_relation_service.dart", "lib/services/tts_cache_key.dart", "lib/services/tts_service.dart",
             "lib/features/content_learning/content_learning_catalog.dart", "lib/services/scenario_loader.dart"]:
    read(path)
for path in ["assets/illustrations/concept_c/material_atlas.png", "assets/illustrations/concept_c/book_v2.png",
             "assets/illustrations/concept_c/cloud_v2.png", "assets/illustrations/concept_c/seal_v2.png",
             "assets/illustrations/activities/vocab_packs.webp", "assets/illustrations/activities/review.webp",
             "assets/illustrations/activities/grammar.webp", "assets/illustrations/activities/pronunciation.webp",
             "assets/illustrations/activities/listening.webp", "assets/illustrations/activities/scenarios.webp",
             "assets/illustrations/activities/word_web.webp", "assets/fonts/Paperlogy/Paperlogy-Regular.ttf",
             "assets/fonts/Paperlogy/Paperlogy-SemiBold.ttf", "assets/fonts/Paperlogy/Paperlogy-Bold.ttf",
             "assets/fonts/NotoSansKR/NotoSansKR-Variable.ttf"]:
    asset(path)

assert len(vocab) == len({v["id"] for v in vocab}) == 2968
assert len(packs) == 254 and len(grammar) == 264 and len(pron["phrases"]) == 84
assert len(scenarios) == len(listening["lessons"]) == 186 and len(relations["clusters"]) == 114
by_scenario = {s["id"]: s for s in scenarios}
assert all(cid in by_scenario for l in listening["lessons"] for cid in l["contentIds"])
assert len({r['module']+'|'+r['kind']+'|'+r['id'] for r in LEDGER}) == len(LEDGER)
counts = {"vocab": len(vocab), "packs": len(packs), "grammar": len(grammar), "pronunciation": len(pron["phrases"]),
          "listening": len(listening["lessons"]), "listeningQuestions": sum(len(l["questions"]) for l in listening["lessons"]),
          "scenarios": len(scenarios), "scenarioQuests": sum(len(s["quests"]) for s in scenarios), "relations": len(relations["clusters"]),
          "extras": dict(Counter(e["kind"] for e in extras)), "triggerRows": len(LEDGER),
          "questTypes": dict(Counter(q["type"] for s in scenarios for q in s["quests"]))}
payload = {"schemaVersion": 1, "sourceHead": "a1d798bda6a36ff4dd95faa16e14484ad7b1a2f5", "counts": counts,
           "vocab": vocab, "packs": packs, "grammar": grammar, "pronunciation": pron["phrases"],
           "listening": listening["lessons"], "scenarios": scenarios, "relations": relations["clusters"], "extras": extras,
           "audio": audio, "sourceHashes": SOURCES, "assetHashes": {p: digest((ROOT/p).read_bytes()) for p in sorted(ASSETS)},
           "boundary": {"storageNamespace": "hangulsori.c-free-learning.20261005.v1", "realAccountWrites": False,
                        "paidServices": False, "scoreOrRewards": False, "audioPolicy": "read existing canonical v3 audio only; never synthesize"}}
(HERE / "content.json").write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
(HERE / "trigger-ledger.json").write_text(json.dumps({"counts": counts, "records": LEDGER}, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
print(json.dumps({**counts, "audioKeys": len(audio), "canonicalAudio": sum(a["canonical"] for a in audio.values()), "sourceFiles": len(SOURCES), "assets": len(ASSETS)}, ensure_ascii=False))
