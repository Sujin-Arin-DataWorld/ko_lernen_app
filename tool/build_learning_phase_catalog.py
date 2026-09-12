"""Project the authored Phase goals and related live missions into a small asset.

Bindings are editorial practice suggestions, not equivalence or mastery claims.
Run with --check to enforce freshness without changing any files.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re

try:
    from tool import build_phase_tasks
except ModuleNotFoundError:
    import build_phase_tasks
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path("tools/content_factory/cefr_matrix/phases.json")
BINDINGS = Path("tools/content_factory/cefr_matrix/runtime_bindings.json")
OUTPUT = Path("assets/data/learning_phases.json")
LEVEL_COUNTS = {"A1": 4, "A2": 4, "B1": 5, "B2": 5, "C1": 6, "C2": 6}


def build(root: Path = ROOT) -> dict:
    def read(path: Path) -> dict:
        return json.loads((root / path).read_text(encoding="utf-8"))

    source = read(SOURCE)
    bindings = read(BINDINGS)["phases"]
    units = {u["id"]: u for u in read(Path("assets/data/curriculum_manifest.json"))["courseUnits"]}
    phases = source["phases"]
    expected = [f"KP{i:02}" for i in range(1, 31)]
    if [p["id"] for p in phases] != expected or [b["phaseId"] for b in bindings] != expected:
        raise ValueError("Source and bindings must contain KP01–KP30 once, in order")
    if {level: sum(p["level"] == level for p in phases) for level in LEVEL_COUNTS} != LEVEL_COUNTS:
        raise ValueError("Phase level distribution changed; review the live catalog")
    task_asset = root / "assets/data/phase_tasks.json"
    tasks = None
    if task_asset.is_file():
        tasks = build_phase_tasks.build(root)
        if json.loads(task_asset.read_text(encoding="utf-8")) != tasks:
            raise ValueError("Phase task asset is stale")
    output = []
    for phase, binding in zip(phases, bindings):
        ids = binding["practiceUnitIds"]
        if not ids or len(ids) != len(set(ids)):
            raise ValueError(f"{phase['id']}: related practice must be nonempty and unique")
        if any(uid not in units or units[uid]["level"].upper() != phase["level"] for uid in ids):
            raise ValueError(f"{phase['id']}: unknown or cross-level mission")
        for uid in ids:
            checkpoints = units[uid].get("checkpointContentIds", [])
            if len(checkpoints) != 1 or not re.fullmatch(r"scenario:.+", checkpoints[0]):
                raise ValueError(f"{uid}: no unique scenario for free practice")
        for field in (phase["title"], phase["coreGoal"], binding["practiceFocus"]):
            if any(not field.get(lang, "").strip() for lang in ("ko", "en", "de")):
                raise ValueError(f"{phase['id']}: incomplete localized text")
        artwork = binding["artwork"]
        asset = artwork.get("asset")
        if artwork["status"] == "pending":
            if asset is not None:
                raise ValueError("Pending artwork must use the preparing placeholder")
        elif artwork["status"] == "approved":
            if (not isinstance(asset, str) or not asset.startswith("assets/illustrations/")
                    or ".." in Path(asset).parts or not (root / asset).is_file()):
                raise ValueError("Approved artwork must point to a bundled illustration")
            spec = (root / "pubspec.yaml").read_text(encoding="utf-8")
            section = re.search(r"(?ms)^  assets:\n(.*?)(?=^  \w|\Z)", spec)
            entries = re.findall(r"(?m)^\s+-\s+['\"]?([^'\"#\s]+)", section[1] if section else "")
            if not any(asset == entry or (entry.endswith("/") and str(Path(asset).parent).replace("\\", "/") + "/" == entry) for entry in entries):
                raise ValueError("Approved artwork is not registered in pubspec assets")
        else:
            raise ValueError("Unknown artwork status")
        output.append({
            "id": phase["id"], "level": phase["level"], "levelPhase": phase["levelPhase"],
            "title": phase["title"], "goal": phase["coreGoal"],
            "practiceFocus": binding["practiceFocus"], "practiceUnitIds": ids,
            "illustrationAsset": asset,
        })
    if tasks is not None:
        for phase in output:
            phase["taskIds"] = [t["id"] for t in tasks["tasks"] if t["phaseId"] == phase["id"]]
            phase["taskCoverage"] = "partial" if phase["taskIds"] else "related_practice_only"
    result = {
        "schemaVersion": 2 if tasks is not None else 1,
        "sourceSha256": hashlib.sha256((root / SOURCE).read_bytes().replace(b"\r\n", b"\n")).hexdigest(),
        "coverage": "phase_tasks_partial" if tasks is not None else "related_practice_only",
        "phases": output,
    }
    if tasks is not None:
        result["phaseTaskSourceSha256"] = build_phase_tasks.fingerprint(tasks)
    return result


def render(root: Path = ROOT) -> str:
    return json.dumps(build(root), ensure_ascii=False, indent=2) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    text = render()
    target = ROOT / OUTPUT
    if args.check:
        if not target.is_file() or target.read_text(encoding="utf-8") != text:
            print(f"STALE: run python tool/build_learning_phase_catalog.py ({OUTPUT})")
            return 1
        print("Learning Phase catalog: 30 phases, valid live mission links, fresh")
    else:
        target.write_text(text, encoding="utf-8", newline="\n")
        print(f"Wrote {OUTPUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
