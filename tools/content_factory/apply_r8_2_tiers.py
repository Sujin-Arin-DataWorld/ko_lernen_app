#!/usr/bin/env python3
"""R8-2 -- apply the two-tier distractor scheme to all 542 items.

Tier A (default): same-POS/same-form, semantically-incompatible distractors
(from build_r8_2_tier_picks.py's candidate pools -- CONCRETE_TOPICS
cross-domain nouns, or cross-topic same-ending predicates).
Tier B (OPEN_SLOT_WAIVER, last resort): 2 dictionary-form verbs + 1 bare
particle, for frames build_r8_2_tier_picks.likely_open_frame flags as
having no selectional restriction at all.
Mixed: when only 1-2 Tier-A candidates are usable, fill the rest with the
waiver pool (2A+1 waiver, or 1A+2 waiver) rather than force a 3rd weak
Tier-A pick.

Per-item overrides (from the sentence-by-sentence read, see the audit
doc's "R8-2 full read") are applied AFTER the automatic pass, via
OVERRIDES below -- keyed by cloze id, value is either "tier_b" (force
full waiver) or a list of specific words to use as Tier-A picks instead
of the automatic top-N choice.

Usage:
    python tools/content_factory/apply_r8_2_tiers.py            # dry run
    python tools/content_factory/apply_r8_2_tiers.py --apply
"""
from __future__ import annotations

import hashlib
import json
import random
import sys
from pathlib import Path

import cloze_distractor_rules as R
from build_r8_2_tier_picks import waiver_pick

ROOT = R.REPO_ROOT
CLOZE = ROOT / "assets/data/cloze.json"
IDS_FILE = Path(__file__).parent / "r8_all_waived_ids.json"
CANDS_FILE = Path(__file__).parent / "r8_2_candidates.json"
OVERRIDES_FILE = Path(__file__).parent / "r8_2_overrides.json"


def choose_for_item(cid: str, it: dict, cand_info: dict, overrides: dict) -> tuple[list[str], str, list[str]]:
    """Returns (distractors, tier_label, tier_a_words)."""
    remainder = R.sentence_remainder(it["sentenceKo"])
    override = overrides.get(cid)

    if override == "tier_b" or (override is None and cand_info["open_guess"]):
        d = waiver_pick(cid, remainder, 3)
        return d, "B", []

    if isinstance(override, list):
        tier_a = [w for w in override if w != it["answer"] and w not in remainder]
    else:
        tier_a = [w for w in cand_info["candidates"] if w not in remainder][:3]

    tier_a = list(dict.fromkeys(tier_a))  # dedupe, keep order
    if len(tier_a) >= 3:
        return tier_a[:3], "A", tier_a[:3]

    need = 3 - len(tier_a)
    filler = waiver_pick(cid + "-fill", remainder, need)
    filler = [w for w in filler if w not in tier_a]
    while len(filler) < need:
        # extremely rare fallback
        extra_seed = int(hashlib.sha1((cid + "-fill2").encode()).hexdigest(), 16)
        rng = random.Random(extra_seed)
        pool = [w for w in (list(R.DICTIONARY_FORM_VERBS) + list(R.BARE_PARTICLES)) if w not in tier_a and w not in filler]
        rng.shuffle(pool)
        filler += pool[: need - len(filler)]
    result = tier_a + filler[:need]
    label = "mixed" if tier_a else "B"
    return result, label, tier_a


def main(apply: bool) -> None:
    ids = json.loads(IDS_FILE.read_text(encoding="utf-8"))
    cands = json.loads(CANDS_FILE.read_text(encoding="utf-8"))
    overrides = json.loads(OVERRIDES_FILE.read_text(encoding="utf-8")) if OVERRIDES_FILE.exists() else {}
    data = json.loads(CLOZE.read_text(encoding="utf-8"))
    items = {it["id"]: it for it in data["items"]}

    tally = {"A": 0, "B": 0, "mixed": 0}
    rows = []
    for cid in ids:
        it = items[cid]
        distractors, label, tier_a_words = choose_for_item(cid, it, cands[cid], overrides)
        assert len(set(distractors)) == 3, (cid, distractors)
        assert it["answer"] not in distractors, (cid, distractors)
        tally[label] += 1
        rows.append((cid, label, tier_a_words, distractors))
        it["distractors"] = distractors

    total = len(ids)
    print(f"Tier A: {tally['A']} ({100*tally['A']/total:.1f}%)  "
          f"Tier B: {tally['B']} ({100*tally['B']/total:.1f}%)  "
          f"mixed: {tally['mixed']} ({100*tally['mixed']/total:.1f}%)")
    b_like = tally["B"]  # pure Tier B only counts against the 40% cap; mixed keeps >=1 Tier-A word
    print(f"Pure Tier B share: {100*b_like/total:.1f}% (target <=40%)")

    if apply:
        CLOZE.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        tiers_out = {cid: label for cid, label, _, _ in rows}
        (Path(__file__).parent / "r8_2_tiers.json").write_text(
            json.dumps(tiers_out, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        print(f"written {CLOZE}")


if __name__ == "__main__":
    main(apply="--apply" in sys.argv)
