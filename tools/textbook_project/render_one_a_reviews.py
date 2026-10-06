#!/usr/bin/env python3
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/"docs"/"textbook_project"/"production"/"ONE_A_REVIEW_CONTRACTS_20261006.json"
OUT=ROOT/"docs"/"textbook_project"/"production"/"reviews"

def load_json(p):
    return json.loads(p.read_text(encoding="utf-8-sig"))

def task_block(t,lang):
    prompt=t["promptEn"] if lang=="en" else t["promptDe"]
    lines=[f"### {t['taskId']}","",prompt,""]
    if t.get("options"):
        for i,opt in enumerate(t["options"],1):
            lines.append(f"{i}. {opt}")
        lines.append("")
    if t["answerPolicy"] in {"rubric","multiple_accepted"}:
        label="Your response" if lang=="en" else "Deine Antwort"
        lines += [f"**{label}:**","", "______________________________",""]
    return "\n".join(lines)

def render_review(r,lang):
    title=f"Korean 1A Review {r['reviewId']}" if lang=="en" else f"Koreanisch 1A Wiederholung {r['reviewId']}"
    intro=(
        "This review mixes the previous two units. Do not solve it by remembering the page layout; retrieve the language from the situation."
        if lang=="en" else
        "Diese Wiederholung mischt die beiden vorherigen Einheiten. Löse die Aufgaben aus der Situation heraus, nicht aus der Erinnerung an die Seitenfolge."
    )
    lines=[f"# {title}","",intro,""]
    for t in r["tasks"]:
        lines.append(task_block(t,lang))
    return "\n".join(lines)+"\n"

def render_final(r,lang):
    title="Korean 1A Final Transfer Review" if lang=="en" else "Koreanisch 1A Abschließende Transfer-Wiederholung"
    intro=(
        "No unit labels are shown inside the tasks. Combine language from across 1A."
        if lang=="en" else
        "In den Aufgaben werden keine Kapitelnummern angezeigt. Verbinde Sprache aus dem gesamten 1A-Band."
    )
    lines=[f"# {title}","",intro,""]
    for t in r["tasks"]:
        lines.append(task_block(t,lang))
    return "\n".join(lines)+"\n"

def main():
    d=load_json(SRC)
    OUT.mkdir(parents=True,exist_ok=True)
    for r in d["reviews"]:
        (OUT/f"{r['reviewId']}_EN.md").write_text(render_review(r,"en"),encoding="utf-8")
        (OUT/f"{r['reviewId']}_DE.md").write_text(render_review(r,"de"),encoding="utf-8")
    final=d["finalReview"]
    (OUT/"FINAL_EN.md").write_text(render_final(final,"en"),encoding="utf-8")
    (OUT/"FINAL_DE.md").write_text(render_final(final,"de"),encoding="utf-8")
    print(f"PASS pair_reviews={len(d['reviews'])} final_tasks={len(final['tasks'])}")

if __name__=="__main__":
    main()
