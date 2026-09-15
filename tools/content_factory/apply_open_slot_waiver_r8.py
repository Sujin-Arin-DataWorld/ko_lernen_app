#!/usr/bin/env python3
"""R8 (Fable, 2026-09-15) -- apply OPEN_SLOT_WAIVER to the 502 items the
C2c sweep changed on fd6ca9a2.

Fable's 12-item sample found ~1/3 were new D7 violations: a same-POS/
same-form/topic-distant noun (or a closed-class adverb, or even a bare
NUMBER word) STILL reads as a fully valid alternate sentence in an open
existential/adjective-predicate/topic-marked-subject frame ("다양한 X이
있어요", "정말 X.", "X은 부담이 된다고 ..." all accept nearly any noun or
adverb of the right shape). A hand read of the full 502-item list (see
docs/data/cloze_distractor_audit_2026-09-15.md, "R8 full read") confirmed
this pattern holds for the large majority of items across every rule that
triggered a change (not just the original D5 set) -- every semantic-class
or closed-class substitution tried (abstract nouns, numbers, position
words, generic adverbs) had at least one item where the resulting
sentence still read as natural Korean.

Given that pattern's breadth, this applies OPEN_SLOT_WAIVER -- the
PREDICATE_SLOT_WAIVER technique (a distractor that is GRAMMATICALLY
IMPOSSIBLE in the slot, not just semantically implausible) -- uniformly to
all 502 items: 2 dictionary-form verbs + 1 bare particle, deterministic
per item (seeded by id), respecting D6 (not in the sentence remainder, no
duplicates). This is the only technique demonstrated safe against the
open-slot pattern in this corpus's cloze frames (와, 있어요, 없어요, 좋아요,
정말/진짜/별로 + adjective, topic-marked subject, ...).

Usage:
    python tools/content_factory/apply_open_slot_waiver_r8.py            # dry run
    python tools/content_factory/apply_open_slot_waiver_r8.py --apply
"""
from __future__ import annotations

import hashlib
import json
import random
import sys
from pathlib import Path

import cloze_distractor_rules as R
from distractor_rules import DICTIONARY_FORM_VERBS, BARE_PARTICLES

ROOT = R.REPO_ROOT
CLOZE = ROOT / "assets/data/cloze.json"
IDS_FILE = Path(__file__).parent / "r8_changed_ids.json"

VERB_POOL = sorted(DICTIONARY_FORM_VERBS)
PARTICLE_POOL = sorted(BARE_PARTICLES)


def pick_waiver_distractors(cloze_id: str, sentence_ko: str) -> list[str]:
    remainder = R.sentence_remainder(sentence_ko)
    seed = int(hashlib.sha1((cloze_id + "-openslot").encode()).hexdigest(), 16)
    rng = random.Random(seed)
    verbs = [v for v in VERB_POOL if v not in remainder]
    particles = [p for p in PARTICLE_POOL if p not in remainder]
    rng.shuffle(verbs)
    rng.shuffle(particles)
    chosen = verbs[:2] + particles[:1]
    if len(chosen) < 3:
        # extremely unlikely (would need >11 verbs or all 7 particles
        # literally present in the sentence) -- fall back to the full
        # pool ignoring the remainder filter rather than under-fill.
        chosen = (verbs or VERB_POOL)[:2] + (particles or PARTICLE_POOL)[:1]
    return chosen


def main(apply: bool) -> None:
    ids = json.loads(IDS_FILE.read_text(encoding="utf-8"))
    data = json.loads(CLOZE.read_text(encoding="utf-8"))
    items = {it["id"]: it for it in data["items"]}

    changed = 0
    for cid in ids:
        it = items[cid]
        new_distractors = pick_waiver_distractors(cid, it["sentenceKo"])
        assert len(set(new_distractors)) == 3, (cid, new_distractors)
        assert it["answer"] not in new_distractors, (cid, new_distractors)
        if new_distractors != it["distractors"]:
            it["distractors"] = new_distractors
            changed += 1

    print(f"OPEN_SLOT_WAIVER applied/verified for {len(ids)} items; {changed} distractor arrays actually changed")

    if apply:
        CLOZE.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"written {CLOZE}")


if __name__ == "__main__":
    main(apply="--apply" in sys.argv)
