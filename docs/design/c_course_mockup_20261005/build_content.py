"""Export a read-only C course prototype from the current canonical sources.

No account, course-progress, audio-generation or reward service is invoked.
Run from any directory: python -X utf8 <this file>
"""
import csv
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def read_json(relative):
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def sha(relative):
    return hashlib.sha256((ROOT / relative).read_bytes()).hexdigest()


def pack_base(pack_id):
    parts = pack_id.lower().split("_")
    return "_".join(parts[:-1]) if parts[-1].isdigit() else pack_id.lower()


manifest_path = "assets/data/curriculum_manifest.json"
vocab_path = "assets/data/korean_vocab.csv"
scenario_path = "assets/data/scenarios_a1.json"
manifest = read_json(manifest_path)
with (ROOT / vocab_path).open(encoding="utf-8-sig", newline="") as stream:
    vocab = list(csv.DictReader(stream))
units = manifest["courseUnits"]
unit_ids = {unit["id"] for unit in units}
assert len(units) == len(unit_ids) == 48
for unit in units:
    assert all(item in unit_ids for item in unit.get("prerequisiteUnitIds", []))
    related_vocab = [item for item in vocab if manifest["vocabPackUnitMap"].get(pack_base(item["pack_id"])) == unit["id"]]
    unit["vocabIds"] = [item["id"] for item in related_vocab]
    unit["packIds"] = list(dict.fromkeys(item["pack_id"] for item in related_vocab))
    unit["explicitLinks"] = [link for link in manifest["contentLinks"] if link["courseUnitId"] == unit["id"]]
    unit["grammarIds"] = [key for key, rule in manifest["grammarRuleMap"].items() if rule.get("courseUnitId") == unit["id"]]

sample_unit = units[0]
sample = next(item for item in read_json(scenario_path)["scenarios"] if item["id"] == "airport_arrival")
assert sample["courseUnitId"] == sample_unit["id"]
assert "scenario:" + sample["id"] in sample_unit["checkpointContentIds"]
assert any(link["contentId"] == sample["id"] and link["role"] == "assess" for link in sample_unit["explicitLinks"])
sample_vocab = [item for item in vocab if item["id"] in sample_unit["vocabIds"]]
phase_path = "assets/data/learning_phases.json"
task_path = "assets/data/phase_tasks.json"
phases = read_json(phase_path)
tasks = read_json(task_path)
task_ids = {item["id"] for item in tasks["tasks"]}
assert len(phases["phases"]) == 30
assert len(tasks["tasks"]) == len(task_ids) == 902
assert {item for phase in phases["phases"] for item in phase["taskIds"]} == task_ids
assert all(item in unit_ids for phase in phases["phases"] for item in phase["practiceUnitIds"])
task_index = [{
    "id": item["id"], "phaseId": item["phaseId"], "level": item["level"],
    "title": item["title"], "contentRevision": item["contentRevision"],
    "rubricVersion": item["rubricVersion"], "skill": item["skill"], "mode": item["mode"],
    "source": task_path, "jsonPointer": f"/tasks/{index}",
} for index, item in enumerate(tasks["tasks"])]
scenario_paths = [f"assets/data/scenarios_{level}.json" for level in ["a1", "a2", "b1", "b2", "c1", "c2"]]
smalltalk_path = "assets/data/smalltalk.json"
smalltalk_lessons_path = "assets/data/smalltalk_lessons.json"
grammar_path = "assets/data/grammar.csv"
reference_sources = {}
for path in scenario_paths:
    corpus = read_json(path)
    for index, item in enumerate(corpus["scenarios"]):
        reference_sources[("scenario", item["id"])] = {"source": path, "jsonPointer": f"/scenarios/{index}", "sourceVersion": corpus.get("version")}
smalltalk = read_json(smalltalk_path)
for index, item in enumerate(smalltalk["phrases"]):
    reference_sources[("smalltalk", item["id"])] = {"source": smalltalk_path, "jsonPointer": f"/phrases/{index}", "sourceVersion": smalltalk["version"]}
explicit_content_index = []
for link in manifest["contentLinks"]:
    source = reference_sources.get((link["contentKind"], link["contentId"]))
    assert source, f"Existing course link has no source: {link}"
    explicit_content_index.append({**link, **source})
scenario_ids = {key[1] for key in reference_sources if key[0] == "scenario"}
unresolved_checkpoints = [{"unitId": unit["id"], "contentKey": key, "status": "existing_id_unresolved_preserved"}
                          for unit in units for key in unit.get("checkpointContentIds", [])
                          if key.startswith("scenario:") and key.split(":", 1)[1] not in scenario_ids]

assets = {
    "materials": "assets/illustrations/concept_c/material_atlas.png",
    "book": "assets/illustrations/concept_c/book_v2.png",
    "cloud": "assets/illustrations/concept_c/cloud_v2.png",
    "seal": "assets/illustrations/concept_c/seal_v2.png",
    "stampbook": "assets/illustrations/concept_c/stampbook_v2.png",
    "coin": "assets/illustrations/concept_c/coin_v2.png",
    "taego": "assets/illustrations/companions/canonical/taego_guide.png",
    "airport": "assets/illustrations/scenes/airport.png",
    "paperlogyRegular": "assets/fonts/Paperlogy/Paperlogy-Regular.ttf",
    "paperlogyBold": "assets/fonts/Paperlogy/Paperlogy-Bold.ttf",
    "paperlogySemiBold": "assets/fonts/Paperlogy/Paperlogy-SemiBold.ttf",
    "noto": "assets/fonts/NotoSansKR/NotoSansKR-Variable.ttf",
    "maru": "assets/fonts/MaruBuri/MaruBuri-Regular.otf",
}
payload = {
    "schemaVersion": 1,
    "kind": "read_only_interactive_mockup",
    "canonicalVersion": manifest["version"],
    "units": units,
    "sampleUnitId": sample_unit["id"],
    "sampleScenario": sample,
    "sampleVocab": sample_vocab,
    "canonicalMappings": {key: value for key, value in manifest.items() if key != "courseUnits"},
    "explicitContentIndex": explicit_content_index,
    "learningPhases": phases,
    "phaseTaskIndex": task_index,
    "unresolvedCheckpoints": unresolved_checkpoints,
    "assets": assets,
    "sourceHashes": {item: sha(item) for item in [manifest_path, vocab_path, phase_path, task_path, smalltalk_path, smalltalk_lessons_path, grammar_path, *scenario_paths, *assets.values()]},
    "runtimeContracts": {
        "path": {"route": "/path"},
        "mission": {"route": "/course/mission", "argument": "courseUnitId"},
        "vocab": {"route": "/vocab/pack", "argument": "VocabPackRouteArguments + CoursePracticeContext"},
        "scenario": {"route": "/scenario", "argument": "CoursePracticeContext.fromLink(exact assess link)"},
        "learningPhases": {"route": "/course/phases", "detailRoute": "/course/phase", "taskRoute": "/learning-phase/task", "role": "related practice retains its original evaluation contract"},
        "result": {"source": "existing activity result + CourseAttemptCompanion", "unitCompletion": "CourseMasteryService exact evidence contract"},
    },
    "boundaries": {
        "writesRealAccount": False,
        "awardsXPOrRewards": False,
        "grantsUnitUnlock": False,
        "audio": "No replacement voice or generated audio; audio-unavailable and transcript states are reviewable.",
        "lessonCoverage": "48 unit previews; all 30 phases and 902 task IDs/revisions remain in the connection index. Interactive tasks sample airport_arrival only; existing activity renderers remain separate.",
        "demoStorage": "Namespaced browser sessionStorage only; never a real course-completion record.",
    },
}
(HERE / "content.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"units": len(units), "explicitLinks": sum(len(unit["explicitLinks"]) for unit in units), "phases": len(phases["phases"]), "taskIds": len(task_ids), "unresolvedCheckpoints": unresolved_checkpoints, "sampleScenario": sample["id"], "sampleQuests": len(sample["quests"]), "referencedAssetHashes": len(assets), "output": str(HERE / "content.json")}, ensure_ascii=False))
