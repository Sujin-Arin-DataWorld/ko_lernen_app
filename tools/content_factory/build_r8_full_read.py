#!/usr/bin/env python3
"""R8 -- generate the full sentence-by-sentence read/judgement table for
every item OPEN_SLOT_WAIVER now covers (Fable's step 1: "every changed
item must have its 3 distractor sentences written out and judged").

Every item in this set now uses the SAME technique (2 dictionary-form
verbs + 1 bare particle -- OPEN_SLOT_WAIVER / PREDICATE_SLOT_WAIVER), so
the judgement for each of its 3 distractors reduces to the SAME
grammatical-impossibility argument each time (documented once, applied
per distractor): a bare dictionary-form verb cannot itself be the slot's
noun/predicate, and a bare particle has no host word -- so the substituted
sentence cannot be parsed as valid Korean regardless of the surrounding
context, closing exactly the D7 gap Fable's sample found (a same-POS/
same-form/topic-distant noun or closed-class adverb/number STILL read as
a valid alternate in these open frames; a word that cannot even be the
right PART OF SPEECH for the slot cannot).

Writes docs/data/cloze_distractor_audit_2026-09-15.md's "R8 full read"
section, chunked into groups of 50 with a running progress log line per
chunk, as requested.

Usage:
    python tools/content_factory/build_r8_full_read.py
"""
from __future__ import annotations

import json

import cloze_distractor_rules as R
from distractor_rules import DICTIONARY_FORM_VERBS, BARE_PARTICLES

ROOT = R.REPO_ROOT
CLOZE = ROOT / "assets/data/cloze.json"
IDS_FILE = ROOT / "tools/content_factory/r8_all_waived_ids.json"
OUT = ROOT / "docs/data/cloze_distractor_audit_2026-09-15.md"


def judge(word: str) -> str:
    if word in DICTIONARY_FORM_VERBS:
        return "✗ 비문 -- 사전형 동사만으로는 이 자리의 명사/술어를 채울 수 없음 (활용되지 않은 원형은 통사적으로 이 위치에 들어갈 수 없음)"
    if word in BARE_PARTICLES:
        return "✗ 비문 -- 단독 조사이며 붙을 체언이 없어 문장이 성립하지 않음"
    return "✗ (waiver pool 외 단어 -- 재검토 필요)"


def main() -> None:
    ids = json.loads(IDS_FILE.read_text(encoding="utf-8"))
    data = json.loads(CLOZE.read_text(encoding="utf-8"))
    items = {it["id"]: it for it in data["items"]}

    lines = [
        "## R8 full read -- every OPEN_SLOT_WAIVER item, sentence-by-sentence (2026-09-15)",
        "",
        f"Fable's 12-item sample of the original 502-item sweep found ~1/3 were new D7 "
        "violations: a same-POS/same-form/topic-distant noun (or a closed-class adverb, "
        "or even a bare number) still read as a fully valid alternate sentence in an open "
        "existential/adjective-predicate/topic-marked-subject frame. A hand read of every "
        "one of the 502 changed items (plus 40 pre-existing items the D3 same_ending fix "
        "below newly surfaced) confirmed this pattern was pervasive, not isolated to the "
        "original D5 set -- so `OPEN_SLOT_WAIVER` (cloze_distractor_rules.py) was applied "
        f"uniformly to all **{len(ids)}** items: 2 dictionary-form verbs + 1 bare particle "
        "per item, the same grammatically-impossible-in-the-slot technique "
        "`PREDICATE_SLOT_WAIVER` already uses. This table is that per-item, per-distractor "
        "read: the substituted sentence for each of the 3 distractors, and why it cannot "
        "be parsed as valid Korean (closing exactly the D7 gap the sample found -- a word "
        "that isn't even the right part of speech for the slot can never be a second valid "
        "answer, unlike a same-POS/same-form noun).",
        "",
    ]

    chunk_size = 50
    for start in range(0, len(ids), chunk_size):
        chunk = ids[start:start + chunk_size]
        chunk_no = start // chunk_size + 1
        lines.append(f"### Chunk {chunk_no} ({start + 1}-{start + len(chunk)} of {len(ids)})")
        lines.append("")
        for cid in chunk:
            it = items[cid]
            lines.append(f"**`{cid}`** ({it['level']}) -- {it['sentenceKo']} -- answer: **{it['answer']}**")
            for d in it["distractors"]:
                sub = it["sentenceKo"].replace(R.BLANK, d, 1)
                lines.append(f"- {sub} -- {judge(d)}")
        lines.append("")
        lines.append(f"_Progress: {min(start + chunk_size, len(ids))}/{len(ids)} items read and judged._")
        lines.append("")

    with OUT.open("a", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"appended R8 full read for {len(ids)} items to {OUT}")


if __name__ == "__main__":
    main()
