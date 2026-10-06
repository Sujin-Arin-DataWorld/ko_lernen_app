#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "docs" / "textbook_project" / "data" / "ONE_A_UNIT_CONTRACTS_20261006.json"
OUT = ROOT / "docs" / "textbook_project" / "ONE_A_UNIT_CONTRACTS_20261006.md"

def main():
    d=json.loads(SRC.read_text(encoding="utf-8-sig"))
    lines=[
        "# Korean 1A Unit Contracts — 2026-10-06","",
        "Status: canonical publishing draft","",
        "These contracts separate what appears in authentic input from what A1 learners must produce.",
        "Dialogue occurrence never automatically becomes a grammar target.","",
        "## Overview","",
        "| # | Unit | Can-do focus | Authority |",
        "|---:|---|---|---|"
    ]
    for u in d["units"]:
        focus=u["canDo"][0]
        auth=", ".join(u["authoritativeScenarioIds"])
        lines.append(f"| {u['order']} | **{u['unitId']}** — {u['titleKo']} | {focus} | {auth} |")
    for u in d["units"]:
        lines += [
            "",f"## {u['order']}. {u['titleKo']}","",
            f"**Unit ID:** {u['unitId']}","",
            f"**Communicative problem:** {u['communicativeProblem']}","",
            "**Can-do**"
        ]
        lines += [f"- {x}" for x in u["canDo"]]
        lines += ["","**Productive language**"]
        lines += [f"- {x['form']} — {x['function']}" for x in u["productiveGrammar"]]
        lines += ["","**Core chunks**"]
        lines += [f"- {x}" for x in u["coreChunks"]]
        if u.get("recognitionOnly"):
            lines += ["","**Recognition/context only**"]
            lines += [f"- {x['form']} — {x['reason']}" for x in u["recognitionOnly"]]
        lines += ["","**Pragmatics / culture**"]
        lines += [f"- {x}" for x in u["pragmatics"]]
        lines += [f"- {x}" for x in u["culture"]]
        lines += ["","**EN learner risks**"]
        lines += [f"- {x}" for x in u.get("enLearnerRisks",[])] or ["- none recorded"]
        lines += ["","**DE learner risks**"]
        lines += [f"- {x}" for x in u.get("deLearnerRisks",[])] or ["- none recorded"]
        lines += ["","**Assessment**"]
        lines += [f"- Must produce: {x}" for x in u["assessment"]["mustProduce"]]
        lines += [f"- Must recognize: {x}" for x in u["assessment"]["mustRecognize"]]
        lines += [f"- Success: {u['assessment']['success']}"]
        lines += ["","**Production ceiling**",u["productionCeiling"]]
    OUT.write_text("\n".join(lines)+"\n",encoding="utf-8")
    print(f"PASS rendered_units={len(d['units'])} output={OUT}")

if __name__=="__main__":
    main()
