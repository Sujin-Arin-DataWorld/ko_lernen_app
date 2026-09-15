#!/usr/bin/env python3
"""C2c step 2 -- D5 open-noun-slot semantic-incompatibility read + re-pick.

D5 targets cloze items whose blank is a noun slot next to an EXISTENTIAL
(있어요/없어요), ADJECTIVE-PREDICATE (예뻐요/좋아요/커요/맛있어요/재미있어요)
or 좋아해요-OBJECT frame. These frames accept almost any grammatically
well-formed concrete noun ("계란이 맛있어요" is a perfectly natural sentence
even though the item's real answer is "과일") -- so "never forms a valid
sentence" (the technique used for D1-D4) isn't achievable here. The rule's
own remedy is instead SEMANTIC-CLASS incompatibility: a distractor from a
visibly different topic/category than the answer (so a learner reading the
sentence in isolation doesn't mistake it for an equally-plausible answer),
preferring an ABSTRACT-topic noun where the item's level has one in the
live vocabulary (B1+ only -- korean_vocab.csv's "Abstrakte Begriffe"/
"Denken"/"Gesellschaft"/"Diskurs & Macht" topics have no A1/A2 entries).

Every one of the 115 D5 items (docs/data/cloze_distractor_audit_2026-09-15.md)
was read by hand (substituted sentence for each of its 3 distractors,
tools/content_factory/d5_substituted.tsv) before this script was written;
the read found the SAME pattern on almost every item: whichever distractor
shares the answer's korean_vocab.csv `topic` (or, for the shortest bare
"＿＿＿가 있어요."-shaped items, ANY ordinary concrete noun regardless of
topic) reads as a fully natural alternate sentence. This script applies
that finding uniformly: replace a distractor when (a) its topic matches
the answer's topic, or (b) the item is one of the maximally-open bare
frames (<=3 eojeol) and the distractor is an ordinary concrete noun (not
already a closed-class number/color/position word, which -- per the
manual read -- reads as an obviously "different kind of thing" rather
than a plausible answer even inside a bare frame).

A1/A2 items (no abstract vocabulary exists at that level) get Zahlen/
Position/Farben words from a topic that differs from the answer's own --
closed, small classes a learner recognizes as "a different kind of
answer" on sight, which is the best achievable "category-mismatched"
remedy the rule allows for at those levels; this residual risk is
honestly documented in the review packet rather than claimed as fully
eliminated (same practice as Batch 28's OPEN_SLOT_ROWS, 2026-09-15).

Usage:
    python tools/content_factory/fix_cloze_d5_c2c.py            # dry run
    python tools/content_factory/fix_cloze_d5_c2c.py --apply
"""
from __future__ import annotations

import hashlib
import json
import random
import re
import sys
from pathlib import Path

import cloze_distractor_rules as R

ROOT = R.REPO_ROOT
CLOZE = ROOT / "assets/data/cloze.json"
AUDIT = ROOT / "docs/data/cloze_distractor_audit_2026-09-15.md"
NOTES = ROOT / "docs/data/c2c_d5_read_notes.md"

ABSTRACT_NOUNS = {
    "b1": ["경우", "전체", "정도", "종류", "느낌", "부분", "내용", "주제",
           "가능성", "한계", "균형", "영향", "문화", "사회", "정치", "경제",
           "교육", "기술"],
    "b2": ["핵심", "유형", "자료", "비결", "개념", "요소", "원리", "가치",
           "본질", "특징", "관점", "논리", "결론", "근거", "전제", "맥락",
           "통계", "가설", "갈등", "가치관", "현상", "복지", "민주주의",
           "자유", "투자", "수익", "비용", "경쟁력", "위기", "정책", "제도",
           "의무", "평등", "차별", "인권", "양극화"],
    "c2": ["담론", "결집", "배제", "낙인", "정당화", "위계", "동조", "발화",
           "함의", "잣대", "비난", "우세"],
}
CLOSED_CLASS_A_LEVEL = {
    "Zahlen": ["일", "이", "삼", "사", "오", "육", "칠", "팔", "구", "십"],
    "Position": ["위", "아래", "앞", "뒤", "옆", "안", "밖", "왼쪽", "오른쪽"],
    "Farben": ["빨간색", "파란색", "초록색", "노란색", "흰색", "검은색"],
}


def abstract_pool(level_rank: int) -> list[str]:
    pool: list[str] = []
    for lv, words in ABSTRACT_NOUNS.items():
        if R.level_rank(lv) <= level_rank:
            pool.extend(words)
    return pool


def is_maximally_open(sentence_ko: str) -> bool:
    """True for a bare frame like "＿＿＿가 있어요." -- <=3 eojeol (blank
    counted as one token), so almost nothing besides the blank and its
    predicate constrains what the answer could plausibly be."""
    return len(sentence_ko.replace(R.BLANK, "X").split()) <= 3


def parse_d5_ids() -> list[str]:
    text = AUDIT.read_text(encoding="utf-8")
    m = re.search(r"## D5 open-slot items.*", text, re.S)
    ids = []
    for line in m.group(0).splitlines():
        line = line.strip()
        if line.startswith("- "):
            ids.extend(x.strip() for x in line.split(":", 1)[1].split(","))
    return ids


def topic_of(word: str, vocab: R.VocabIndex):
    rows = vocab.by_word.get(word)
    return rows[0].get("topic") if rows else None


def main(apply: bool) -> None:
    data = json.loads(CLOZE.read_text(encoding="utf-8"))
    items = {it["id"]: it for it in data["items"]}
    vocab = R.VocabIndex(R.load_vocab_rows())
    d5_ids = parse_d5_ids()

    notes = ["# C2c D5 read notes -- 2026-09-15", "", f"Items read: {len(d5_ids)}", ""]
    changed = 0
    for cid in d5_ids:
        it = items[cid]
        answer, sentence, level = it["answer"], it["sentenceKo"], it["level"]
        level_rank = R.level_rank(level)
        a_topic = topic_of(answer, vocab)
        d1_kind, required_class = R.detect_required_class(sentence, answer)
        remainder = R.sentence_remainder(sentence)
        open_frame = is_maximally_open(sentence)

        old = list(it["distractors"])
        keep, bad = [], []
        for d in old:
            d_topic = topic_of(d, vocab)
            same_topic = a_topic is not None and d_topic == a_topic
            concrete_in_open_frame = (
                open_frame and d not in sum(CLOSED_CLASS_A_LEVEL.values(), [])
                and d not in abstract_pool(level_rank)
            )
            (bad if (same_topic or concrete_in_open_frame) else keep).append(d)

        need = 3 - len(keep)
        if need <= 0:
            notes.append(f"- `{cid}` ({level}): kept as-is, no distractor read as a same-topic/open-frame concrete match.")
            continue

        seed = int(hashlib.sha1((cid + "-d5").encode()).hexdigest(), 16)
        rng = random.Random(seed)
        if level_rank >= R.level_rank("b1"):
            pool = [w for w in abstract_pool(level_rank) if w != answer]
        else:
            other_topics = [t for t in CLOSED_CLASS_A_LEVEL if t != a_topic]
            pool = [w for t in other_topics for w in CLOSED_CLASS_A_LEVEL[t] if w != answer]
        rng.shuffle(pool)

        chosen = []
        for c in pool:
            if len(chosen) >= need:
                break
            if c in keep or c in chosen or c in remainder:
                continue
            if required_class is not None:
                bc = R.batchim_class(c, d1_kind)
                if bc is not None and bc != required_class:
                    continue
            chosen.append(c)

        new_distractors = keep + chosen
        if len(new_distractors) < 3 or set(new_distractors) == set(old):
            notes.append(f"- `{cid}` ({level}): UNRESOLVED (need={need}, pool={len(pool)}) -- left as-is, flagged for manual follow-up.")
            continue

        it["distractors"] = new_distractors
        changed += 1
        notes.append(
            f"- `{cid}` ({level}): {sentence} -- answer `{answer}` (topic {a_topic!r}). "
            f"replaced {bad} -> {chosen}; kept {keep}."
        )

    notes.append("")
    notes.append(f"Items changed: {changed} / {len(d5_ids)}")
    print(f"D5 items changed: {changed} / {len(d5_ids)}")

    if apply:
        CLOZE.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        NOTES.write_text("\n".join(notes) + "\n", encoding="utf-8")
        print(f"written {CLOZE} and {NOTES}")


if __name__ == "__main__":
    main(apply="--apply" in sys.argv)
