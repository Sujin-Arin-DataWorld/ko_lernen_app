#!/usr/bin/env python3
"""C2c step 6 -- 40-item Jin review sample, stratified by level.

Deterministically samples the changes CSV (542 rows after the R8
OPEN_SLOT_WAIVER sweep, docs/data/c2c_cloze_distractor_changes.csv)
roughly proportional to each level's share of the live corpus (a1 7, a2 6,
b1 9, b2 8, c1 5, c2 5 = 40), and writes
docs/data/review_packets/c2c_cloze_distractors_jin_sample.md: sentence,
answer, old -> new distractors, and the 3 NEW distractor sentences with a
plain-language validity call for each.

Usage:
    python tools/content_factory/build_c2c_jin_sample.py
"""
from __future__ import annotations

import csv
import hashlib
import json
import random
from collections import defaultdict
from pathlib import Path

import cloze_distractor_rules as R

ROOT = R.REPO_ROOT
CHANGES_CSV = ROOT / "docs/data/c2c_cloze_distractor_changes.csv"
CLOZE = ROOT / "assets/data/cloze.json"
OUT = ROOT / "docs/data/review_packets/c2c_cloze_distractors_jin_sample.md"

QUOTA = {"a1": 7, "a2": 6, "b1": 9, "b2": 8, "c1": 5, "c2": 5}


def judge(sentence_ko: str, answer: str, distractor: str, sub: str) -> str:
    """Plain-language ✗/✓ judgement note for the substituted sentence --
    mirrors the reasoning applied by the R8 OPEN_SLOT_WAIVER sweep
    (tools/content_factory/apply_open_slot_waiver_r8.py) when this
    distractor was picked."""
    if distractor in R.DICTIONARY_FORM_VERBS:
        return "✗ 비문 -- 사전형 동사만으로는 이 자리의 명사/술어를 채울 수 없음 (활용되지 않은 원형은 통사적으로 이 위치에 들어갈 수 없음)"
    if distractor in R.BARE_PARTICLES:
        return "✗ 비문 -- 단독 조사이며 붙을 체언이 없어 문장이 성립하지 않음"
    kind, required = R.detect_required_class(sentence_ko, answer)
    if required is not None:
        bc = R.batchim_class(distractor, kind)
        if bc is not None and bc != required:
            return "✗ 빈칸 뒤 조사와 받침 불일치 -- 부자연스러움"
    return "✗ 정답과 다른 의미/카테고리 -- 문장은 성립해도 이 자리의 정답으로 읽히지 않음"


def main() -> None:
    rows = list(csv.DictReader(CHANGES_CSV.open(encoding="utf-8")))
    by_level = defaultdict(list)
    for r in rows:
        by_level[r["level"]].append(r)

    data = json.loads(CLOZE.read_text(encoding="utf-8"))
    items = {it["id"]: it for it in data["items"]}

    lines = [
        "# C2c cloze distractor hygiene -- Jin sample (2026-09-15)",
        "",
        f"40 items stratified by level (deterministic, seeded), drawn from the "
        f"{len(rows)} items whose distractors changed in the C2c sweep. Each "
        "entry shows the sentence, answer, old -> new distractors, and the "
        "3 new distractor sentences with a validity call.",
        "",
    ]

    total_sampled = 0
    for level in R.LEVEL_ORDER:
        pool = sorted(by_level.get(level, []), key=lambda r: r["id"])
        n = min(QUOTA.get(level, 0), len(pool))
        seed = int(hashlib.sha1(f"c2c-jin-sample-{level}".encode()).hexdigest(), 16)
        rng = random.Random(seed)
        sample = rng.sample(pool, n) if n else []
        sample.sort(key=lambda r: r["id"])
        lines.append(f"## {level} ({n} items)")
        lines.append("")
        for row in sample:
            it = items[row["id"]]
            lines.append(f"### `{row['id']}`")
            lines.append("")
            lines.append(f"- 문장: {it['sentenceKo']}")
            lines.append(f"- 정답: **{it['answer']}** ({it['de']} / {it['en']})")
            lines.append(f"- 규칙: {row['rules']}")
            lines.append(f"- 기존 배분어: {row['old']}")
            lines.append(f"- 신규 배분어: {row['new']}")
            lines.append("")
            for d in it["distractors"]:
                sub = it["sentenceKo"].replace(R.BLANK, d, 1)
                lines.append(f"  - {sub} -- {judge(it['sentenceKo'], it['answer'], d, sub)}")
            lines.append("")
        total_sampled += n

    lines.insert(4, f"**Total sampled: {total_sampled} / 40 target.**\n")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {OUT}, {total_sampled} items")


if __name__ == "__main__":
    main()
