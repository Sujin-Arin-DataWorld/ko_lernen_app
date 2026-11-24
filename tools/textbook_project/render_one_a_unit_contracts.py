#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "docs" / "textbook_project" / "data" / "ONE_A_UNIT_CONTRACTS_20261006.json"
GRAMMAR = ROOT / "docs" / "textbook_project" / "data" / "ONE_A_OFFICIAL_GRAMMAR_REGISTRY_20261006.json"
OUT = ROOT / "docs" / "textbook_project" / "ONE_A_UNIT_CONTRACTS_20261006.md"

def grammar_line(item, registry):
    entries = registry["grammarEntries"]
    sources = registry["officialSources"]
    refs = item.get("grammarRefs", [])
    assert refs, item
    explanations = []
    source_labels = []
    for gid in refs:
        entry = entries[gid]
        explanations.append(entry["officialExplanationKo"])
        for sid in entry["sourceIds"]:
            src = sources[sid]
            label = f"{sid}: {src['title']} ({src['publisher']})"
            if label not in source_labels:
                source_labels.append(label)
    return (
        f"- {item['form']} — {' '.join(explanations)}\n"
        f"  - 공식 근거: {'; '.join(source_labels)}"
    )

def scoped_item_line(item, registry):
    refs = item.get("grammarRefs", [])
    if refs:
        return grammar_line(item, registry)
    assert item.get("chunkOnlyNoGrammarExplanation") is True, item
    examples = " / ".join(item.get("examples", []))
    suffix = f" — {examples}" if examples else ""
    return (
        f"- {item['form']}{suffix}\n"
        "  - 고정 청크/인식 항목: 이 항목에서 일반 문법 규칙을 만들지 않음"
    )

def main():
    d = json.loads(SRC.read_text(encoding="utf-8-sig"))
    grammar = json.loads(GRAMMAR.read_text(encoding="utf-8-sig"))

    lines = [
        "# Korean 1A Unit Contracts — 2026-10-06",
        "",
        "Status: canonical publishing draft",
        "",
        "These contracts separate authentic input from learner production.",
        "Grammar explanations in this rendered contract are sourced only from the official grammar registry.",
        "Native-usage evidence and EN/DE localization are separate layers.",
        "",
        "## Overview",
        "",
        "| # | Unit | Can-do focus | Authority |",
        "|---:|---|---|---|",
    ]

    for u in d["units"]:
        focus = u["canDo"][0]
        auth = ", ".join(u["authoritativeScenarioIds"])
        lines.append(
            f"| {u['order']} | **{u['unitId']}** — {u['titleKo']} | {focus} | {auth} |"
        )

    for u in d["units"]:
        lines += [
            "",
            f"## {u['order']}. {u['titleKo']}",
            "",
            f"**Unit ID:** {u['unitId']}",
            "",
            f"**Communicative problem:** {u['communicativeProblem']}",
            "",
            "**Can-do**",
        ]
        lines += [f"- {x}" for x in u["canDo"]]

        lines += ["", "**Productive grammar — official-source layer**"]
        lines += [grammar_line(x, grammar) for x in u["productiveGrammar"]]

        if u.get("formulaicProduction"):
            lines += ["", "**Formulaic production — use now, analyze later**"]
            lines += [scoped_item_line(x, grammar) for x in u["formulaicProduction"]]

        lines += ["", "**Core chunks**"]
        lines += [f"- {x}" for x in u["coreChunks"]]

        if u.get("recognitionOnly"):
            lines += ["", "**Recognition/context only**"]
            lines += [scoped_item_line(x, grammar) for x in u["recognitionOnly"]]

        lines += ["", "**Pragmatics / culture**"]
        lines += [f"- {x}" for x in u["pragmatics"]]
        lines += [f"- {x}" for x in u["culture"]]

        lines += ["", "**EN learner risks**"]
        lines += [f"- {x}" for x in u.get("enLearnerRisks", [])] or ["- none recorded"]

        lines += ["", "**DE learner risks**"]
        lines += [f"- {x}" for x in u.get("deLearnerRisks", [])] or ["- none recorded"]

        lines += ["", "**Assessment**"]
        lines += [f"- Must produce: {x}" for x in u["assessment"]["mustProduce"]]
        lines += [f"- Must recognize: {x}" for x in u["assessment"]["mustRecognize"]]
        lines += [f"- Success: {u['assessment']['success']}"]

        lines += ["", "**Production ceiling**", u["productionCeiling"]]

    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"PASS rendered_units={len(d['units'])} official_grammar_only=true output={OUT}")

if __name__ == "__main__":
    main()
