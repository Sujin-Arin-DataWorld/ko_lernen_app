#!/usr/bin/env python3
"""C2c -- audit every live cloze item's distractors against D1-D6.

Applies the mechanical rules in `cloze_distractor_rules.py` to every item in
assets/data/cloze.json (~1,959 items, all 6 levels) and writes a per-rule,
per-level count table plus the flagged item list to
docs/data/cloze_distractor_audit_2026-09-15.md.

D5 (open noun slots) is DETECTION only here -- which items have the
sentence shape (existential/adjective-predicate/좋아해요-object) that needs
a human/LLM read for semantic-class incompatibility. It is reported
separately from the D1/D2/D3/D4/D6 mechanical violation counts because it
is not itself a mechanical pass/fail.

D7 (never a second valid answer) is not separately audited -- it is the
umbrella judgement the D5 human read and the fixer's re-pick discipline
serve, not a mechanical rule.

Usage:
    python tools/content_factory/audit_cloze_distractors.py
"""
from __future__ import annotations

import json
from collections import Counter, defaultdict
from pathlib import Path

import cloze_distractor_rules as R

ROOT = R.REPO_ROOT
CLOZE = ROOT / "assets/data/cloze.json"
REPORT = ROOT / "docs/data/cloze_distractor_audit_2026-09-15.md"


def audit_item(it: dict, vocab: R.VocabIndex) -> dict:
    sentence = it["sentenceKo"]
    answer = it["answer"]
    distractors = it["distractors"]

    d1_kind, d1_required = R.detect_required_class(sentence, answer)
    d1_bad = []
    if d1_required is not None:
        d1_bad = [
            d for d in distractors
            if R.batchim_class(d, d1_kind) is not None
            and R.batchim_class(d, d1_kind) != d1_required
        ]

    d2_bad = R.check_d2_particle_form(answer, distractors, vocab)

    d3_bad, d3_unresolved, d3_answer_pos = R.check_d3_pos_form(
        answer, distractors, vocab, cloze_id=it["id"]
    )

    d4_bad = R.check_d4_activity_noun(sentence, distractors, vocab)

    d5_open_slot = R.is_open_noun_slot(sentence, answer)

    d6 = R.check_d6_exposure_and_dupes(sentence, answer, distractors)

    any_mechanical = bool(d1_bad or d2_bad or d3_bad or d4_bad or d6["exposed"] or d6["duplicates"] or d6["equals_answer"])

    return {
        "id": it["id"],
        "level": it["level"],
        "d1_bad": d1_bad,
        "d2_bad": d2_bad,
        "d3_bad": d3_bad,
        "d3_unresolved": d3_unresolved,
        "d3_answer_pos": d3_answer_pos,
        "d4_bad": d4_bad,
        "d5_open_slot": d5_open_slot,
        "d6_exposed": d6["exposed"],
        "d6_duplicates": d6["duplicates"],
        "d6_equals_answer": d6["equals_answer"],
        "any_mechanical": any_mechanical,
    }


def main() -> dict:
    data = json.loads(CLOZE.read_text(encoding="utf-8"))
    items = data["items"]
    vocab = R.VocabIndex(R.load_vocab_rows())

    reuse = R.ReuseTracker()
    for it in items:
        reuse.record(it["level"], it["distractors"])

    results = [audit_item(it, vocab) for it in items]

    per_level_rule_counts: dict[str, Counter] = defaultdict(Counter)
    flagged_ids_by_rule: dict[str, list[str]] = defaultdict(list)
    d5_ids_by_level: dict[str, list[str]] = defaultdict(list)
    d3_unresolved_count = 0
    any_flagged: list[dict] = []

    for r in results:
        lv = r["level"]
        if r["d1_bad"]:
            per_level_rule_counts[lv]["D1"] += 1
            flagged_ids_by_rule["D1"].append(r["id"])
        if r["d2_bad"]:
            per_level_rule_counts[lv]["D2"] += 1
            flagged_ids_by_rule["D2"].append(r["id"])
        if r["d3_bad"]:
            per_level_rule_counts[lv]["D3"] += 1
            flagged_ids_by_rule["D3"].append(r["id"])
        if r["d3_unresolved"]:
            d3_unresolved_count += 1
        if r["d4_bad"]:
            per_level_rule_counts[lv]["D4"] += 1
            flagged_ids_by_rule["D4"].append(r["id"])
        if r["d5_open_slot"]:
            per_level_rule_counts[lv]["D5_open_slot(detect-only)"] += 1
            d5_ids_by_level[lv].append(r["id"])
        if r["d6_exposed"]:
            per_level_rule_counts[lv]["D6_exposed"] += 1
            flagged_ids_by_rule["D6_exposed"].append(r["id"])
        if r["d6_duplicates"]:
            per_level_rule_counts[lv]["D6_duplicate"] += 1
            flagged_ids_by_rule["D6_duplicate"].append(r["id"])
        if r["d6_equals_answer"]:
            per_level_rule_counts[lv]["D6_equals_answer"] += 1
            flagged_ids_by_rule["D6_equals_answer"].append(r["id"])
        if r["any_mechanical"]:
            any_flagged.append(r)

    over_cap = {lv: sorted(reuse.over_cap(lv)) for lv in R.LEVEL_ORDER if reuse.over_cap(lv)}

    lines = []
    lines.append("# Cloze distractor hygiene audit -- 2026-09-15 (C2c)")
    lines.append("")
    lines.append(
        f"Live corpus: `assets/data/cloze.json`, {len(items)} items, "
        f"{len(R.LEVEL_ORDER)} levels. Rules D1-D6 per "
        "`tools/content_factory/cloze_distractor_rules.py`. D5 is detection "
        "only (needs a human/LLM read); D7 is the umbrella judgement rule, "
        "not separately audited."
    )
    lines.append("")
    lines.append(f"**Total items with >=1 mechanical (D1/D2/D3/D4/D6) violation: {len(any_flagged)}**")
    lines.append("")
    lines.append(f"D3 answer POS unresolved by the suffix-stripping heuristic (not flagged, excluded from D3): {d3_unresolved_count}")
    lines.append("")

    lines.append("## Counts per rule per level")
    lines.append("")
    rule_names = ["D1", "D2", "D3", "D4", "D5_open_slot(detect-only)", "D6_exposed", "D6_duplicate", "D6_equals_answer"]
    header = "| level | " + " | ".join(rule_names) + " | items |"
    lines.append(header)
    lines.append("|---" * (len(rule_names) + 2) + "|")
    totals = Counter()
    level_item_counts = Counter(it["level"] for it in items)
    for lv in R.LEVEL_ORDER:
        row = [lv]
        for rn in rule_names:
            c = per_level_rule_counts[lv][rn]
            totals[rn] += c
            row.append(str(c))
        row.append(str(level_item_counts[lv]))
        lines.append("| " + " | ".join(row) + " |")
    total_row = ["**all**"] + [str(totals[rn]) for rn in rule_names] + [str(len(items))]
    lines.append("| " + " | ".join(total_row) + " |")
    lines.append("")

    if over_cap:
        lines.append("## D6 reuse-cap violations (>6 uses of one distractor word within a level)")
        lines.append("")
        for lv, words in over_cap.items():
            for w in words:
                lines.append(f"- {lv}: `{w}` used {reuse.count(lv, w)}x")
        lines.append("")

    lines.append("## Flagged item list (mechanical, D1/D2/D3/D4/D6)")
    lines.append("")
    for r in any_flagged:
        reasons = []
        if r["d1_bad"]:
            reasons.append(f"D1={r['d1_bad']}")
        if r["d2_bad"]:
            reasons.append(f"D2={r['d2_bad']}")
        if r["d3_bad"]:
            reasons.append(f"D3={r['d3_bad']}")
        if r["d4_bad"]:
            reasons.append(f"D4={r['d4_bad']}")
        if r["d6_exposed"]:
            reasons.append(f"D6_exposed={r['d6_exposed']}")
        if r["d6_duplicates"]:
            reasons.append("D6_duplicate")
        if r["d6_equals_answer"]:
            reasons.append(f"D6_equals_answer={r['d6_equals_answer']}")
        lines.append(f"- `{r['id']}` ({r['level']}): " + "; ".join(reasons))
    lines.append("")

    lines.append("## D5 open-slot items (need human/LLM read, step 2)")
    lines.append("")
    lines.append(f"Total: {sum(len(v) for v in d5_ids_by_level.values())}")
    lines.append("")
    for lv in R.LEVEL_ORDER:
        ids = d5_ids_by_level.get(lv, [])
        if ids:
            lines.append(f"- {lv} ({len(ids)}): {', '.join(ids)}")
    lines.append("")

    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")

    summary = {
        "total_items": len(items),
        "total_flagged_mechanical": len(any_flagged),
        "per_rule_totals": dict(totals),
        "d5_open_slot_total": sum(len(v) for v in d5_ids_by_level.values()),
        "d3_unresolved": d3_unresolved_count,
        "over_cap": over_cap,
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return summary


if __name__ == "__main__":
    main()
