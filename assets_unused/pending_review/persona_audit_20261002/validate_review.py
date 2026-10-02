"""Validate review data and prove canonical persona/content/model files are unchanged."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--comparison-root", type=Path, default=REPO, help="Optional second checkout to compare; defaults to this checkout")
MAIN = parser.parse_args().comparison_root.resolve()
def read(name):
    return json.loads((ROOT / name).read_text(encoding="utf-8"))
audit, proposal, coverage = read("persona_usage.json"), read("persona_proposal.json"), read("life_coverage.json")
checks = []
def check(label, ok):
    checks.append({"check": label, "passed": bool(ok)})
    if not ok:
        raise AssertionError(label)
old = {c["id"]: c for c in audit["characters"]}
new = {c["id"]: c for c in proposal["characters"]}
check("all 11 stable persona ids preserved", set(old) == set(new) and len(new) == 11)
check("ten adult ages preserved; Jun 9 source -> 16 recommendation", all(new[i]["age"] == old[i]["fixedFacts"]["age"] for i in old if i != "jun") and old["jun"]["fixedFacts"]["age"] == 9 and new["jun"]["age"] == 16)
check("all persona voice contracts preserved", all(new[i]["voice"] == old[i]["voice"] for i in old))
check("proposal explicitly unpromoted", proposal["status"] == "RECOMMENDATION_ONLY_NOT_CANONICAL")
edge_keys = [tuple(sorted((r["a"], r["b"]))) for r in proposal["relationships"]]
check("27 unique relationships with valid endpoints", len(edge_keys) == len(set(edge_keys)) == 27 and all(r["a"] in new and r["b"] in new and r["a"] != r["b"] for r in proposal["relationships"]))
expected_new = {tuple(sorted(x)) for x in [("minho", "christian"), ("dongsun", "maya"), ("byeongcheol", "hyuna")]}
actual_new = {tuple(sorted((r["a"], r["b"]))) for r in proposal["relationships"] if r["status"] == "proposed_new"}
check("only three newly invented pairings", actual_new == expected_new)
check("existing 23 graph pairs retained", {tuple(sorted((r["a"], r["b"]))) for r in audit["relationshipGraph"]["edges"]}.issubset(set(edge_keys)))
restored = [r for r in proposal["relationships"] if r["status"] == "existing_missing_graph"]
check("Lena-Maya is profile relation restoration", len(restored) == 1 and set((restored[0]["a"], restored[0]["b"])) == {"lena", "maya"})
profile = json.loads((REPO / "tools/content_factory/canonical_scenarios/character_profiles.json").read_text(encoding="utf-8"))
# runtimeRoleProfiles may be an id-keyed mapping or a list of profile records.
if isinstance(profile["runtimeRoleProfiles"], list):
    generic = {x["id"] for x in profile["runtimeRoleProfiles"]}
else:
    generic = set(profile["runtimeRoleProfiles"])
additional = {x["id"] for x in proposal["genericRoles"]["proposedAdditional"]}
allowed = set(new) | generic | additional
topics = coverage["topics"]
check("54 unique proposed topics across 9 categories", len(topics) == len({t["id"] for t in topics}) == 54 and len(coverage["categories"]) == 9)
check("topic actor references valid", all(set(t["actors"]) <= allowed for t in topics))
check("priority references valid", all(set(x["topics"]) <= {t["id"] for t in topics} for x in coverage["priorities"]))
check("all four previously unused family personas have proposed topics", all(any(i in t["actors"] for t in topics) for i in ("jun", "minho", "dongsun", "byeongcheol")))
check("178 actual source scenes retained", audit["sceneCount"] == 178)
proof = []
for source in audit["sources"]:
    rel = source["path"]
    for repo in (REPO, MAIN):
        digest = hashlib.sha256((repo / rel).read_bytes()).hexdigest()
        check("source unchanged: " + repo.name + "/" + rel, digest == source["sha256"])
    proof.append(source)
for rel in ("lib/models/scenario_character.dart", "lib/models/scenario.dart", "assets/illustrations/mascot/tiger_front.png", "assets/illustrations/mascot/magpie_front.png", "assets/illustrations/listening/a1_greetings_2.webp"):
    f = REPO / rel
    if f.exists():
        expected = subprocess.run(["git", "rev-parse", "HEAD:" + rel], cwd=REPO, check=True, capture_output=True, text=True).stdout.strip()
        actual = subprocess.run(["git", "hash-object", "--path=" + rel, rel], cwd=REPO, check=True, capture_output=True, text=True).stdout.strip()
        main_actual = subprocess.run(["git", "hash-object", "--path=" + rel, rel], cwd=MAIN, check=True, capture_output=True, text=True).stdout.strip()
        check("runtime model/asset Git content preserved: " + rel, actual == expected == main_actual)
check("8 explicit draft dialogue samples", len(read("scene_samples.json")["samples"]) == 8)
check("review viewer exists and embeds proposal status", (ROOT / "review.html").exists() and proposal["status"] in (ROOT / "review.html").read_text(encoding="utf-8"))
out = {"status": "passed", "checks": checks, "sources": proof, "scope": "review artifact consistency and unchanged source bytes; not Flutter/runtime/CEFR/TTS QA"}
(ROOT / "validation.json").write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"status": "passed", "checks": len(checks), "personas": len(new), "relationships": len(edge_keys), "topics": len(topics)},ensure_ascii=False))
